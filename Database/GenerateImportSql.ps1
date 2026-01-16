<#
    Generates Database/ImportData.sql from files in ../Import

    Usage (PowerShell 7+):
      pwsh -File .\Database\GenerateImportSql.ps1

    Default password for all imported users:
      P@ssw0rd!
#>

[CmdletBinding()]
param(
    [string]$ImportDir = (Join-Path $PSScriptRoot '..\Import'),
    [string]$OutputSqlPath = (Join-Path $PSScriptRoot 'ImportData.sql'),
    [string]$DefaultPassword = 'P@ssw0rd!'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Split-FullName {
    param([Parameter(Mandatory)][string]$FullName)

    $parts = ($FullName.Trim() -split '\s+')
    if ($parts.Count -lt 2) {
        throw "Invalid full name '$FullName'. Expected at least 2 parts."
    }

    $patronymic = $null
    if ($parts.Count -ge 3) {
        $patronymic = $parts[2]
    }

    [pscustomobject]@{
        LastName   = $parts[0]
        FirstName  = $parts[1]
        Patronymic = $patronymic
    }
}

function New-DeterministicPasswordHash {
    param(
        [Parameter(Mandatory)][string]$Password,
        [Parameter(Mandatory)][string]$SaltSeed
    )

    $saltSeedBytes = [Text.Encoding]::UTF8.GetBytes($SaltSeed)
    $sha = [Security.Cryptography.SHA256]::HashData($saltSeedBytes)
    $saltBytes = $sha[0..15]

    $hashBytes = [Security.Cryptography.Rfc2898DeriveBytes]::Pbkdf2(
        [Text.Encoding]::UTF8.GetBytes($Password),
        $saltBytes,
        100000,
        [Security.Cryptography.HashAlgorithmName]::SHA256,
        32
    )

    [pscustomobject]@{
        PasswordHash = [Convert]::ToBase64String($hashBytes)
        PasswordSalt = [Convert]::ToBase64String($saltBytes)
    }
}

function SqlN {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return 'NULL'
    }

    $escaped = $Value.Replace("'", "''")
    return "N'$escaped'"
}

function SqlGuid {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return 'NULL'
    }

    return "'$($Value.Trim())'"
}

function SqlDate {
    param([AllowNull()][DateTime]$Value)

    if ($null -eq $Value) {
        return 'NULL'
    }

    return "'$($Value.ToString('yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture))'"
}

function SqlDateTimeSeconds {
    param([AllowNull()][DateTime]$Value)

    if ($null -eq $Value) {
        return 'NULL'
    }

    $dt = [DateTime]::SpecifyKind($Value, [DateTimeKind]::Unspecified)
    $dt = $dt.AddTicks(-($dt.Ticks % [TimeSpan]::TicksPerSecond))
    return "'$($dt.ToString('yyyy-MM-ddTHH:mm:ss', [Globalization.CultureInfo]::InvariantCulture))'"
}

function SqlInt {
    param([AllowNull()]$Value)

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return 'NULL'
    }

    return ([int]$Value).ToString([Globalization.CultureInfo]::InvariantCulture)
}

function SqlDecimal {
    param([AllowNull()]$Value, [int]$Scale = 2)

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return 'NULL'
    }

    $number = [decimal]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture)
    $format = '0.' + ('0' * $Scale)
    return $number.ToString($format, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-ColumnIndex {
    param([Parameter(Mandatory)][string]$Letters)

    $idx = 0
    foreach ($ch in $Letters.ToUpperInvariant().ToCharArray()) {
        if ($ch -lt 'A' -or $ch -gt 'Z') {
            continue
        }
        $idx = ($idx * 26) + ([int][char]$ch - [int][char]'A' + 1)
    }
    return $idx - 1
}

function Read-MaintenanceXlsx {
    param([Parameter(Mandatory)][string]$Path)

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $Path))
    try {
        $sharedStringsEntry = $zip.GetEntry('xl/sharedStrings.xml')
        if ($null -eq $sharedStringsEntry) {
            throw "Missing xl/sharedStrings.xml in $Path"
        }

        $sr = [IO.StreamReader]::new($sharedStringsEntry.Open())
        try {
            $sharedText = $sr.ReadToEnd()
        }
        finally {
            $sr.Dispose()
        }

        $sharedDoc = New-Object System.Xml.XmlDocument
        $sharedDoc.LoadXml($sharedText)

        $sharedNs = New-Object System.Xml.XmlNamespaceManager($sharedDoc.NameTable)
        $sharedNs.AddNamespace('d', $sharedDoc.DocumentElement.NamespaceURI)

        $shared = @()
        foreach ($si in $sharedDoc.SelectNodes('/d:sst/d:si', $sharedNs)) {
            $text = ''
            foreach ($t in $si.SelectNodes('.//d:t', $sharedNs)) {
                $text += $t.InnerText
            }
            $shared += $text
        }

        $sheetEntry = $zip.GetEntry('xl/worksheets/sheet1.xml')
        if ($null -eq $sheetEntry) {
            throw "Missing xl/worksheets/sheet1.xml in $Path"
        }

        $sr2 = [IO.StreamReader]::new($sheetEntry.Open())
        try {
            $sheetText = $sr2.ReadToEnd()
        }
        finally {
            $sr2.Dispose()
        }

        $sheetDoc = New-Object System.Xml.XmlDocument
        $sheetDoc.LoadXml($sheetText)

        $sheetNs = New-Object System.Xml.XmlNamespaceManager($sheetDoc.NameTable)
        $sheetNs.AddNamespace('d', $sheetDoc.DocumentElement.NamespaceURI)

        $rows = @()
        $rowNodes = @($sheetDoc.SelectNodes('/d:worksheet/d:sheetData/d:row', $sheetNs))
        $isHeader = $true
        foreach ($row in $rowNodes) {
            if ($isHeader) {
                $isHeader = $false
                continue
            }

            $vals = @($null, $null, $null, $null, $null)
            foreach ($c in $row.SelectNodes('d:c', $sheetNs)) {
                $ref = $c.GetAttribute('r')
                if ([string]::IsNullOrWhiteSpace($ref)) {
                    continue
                }

                $letters = ($ref -replace '\d', '')
                $colIndex = Get-ColumnIndex -Letters $letters
                if ($colIndex -lt 0 -or $colIndex -gt 4) {
                    continue
                }

                $raw = $null
                $cellType = $c.GetAttribute('t')
                $vNode = $c.SelectSingleNode('d:v', $sheetNs)

                if ($cellType -eq 's') {
                    if ($null -ne $vNode) {
                        $sharedIndex = [int]$vNode.InnerText
                        $raw = $shared[$sharedIndex]
                    }
                }
                elseif ($cellType -eq 'inlineStr') {
                    $tNode = $c.SelectSingleNode('d:is/d:t', $sheetNs)
                    if ($null -ne $tNode) {
                        $raw = $tNode.InnerText
                    }
                }
                elseif ($null -ne $vNode) {
                    $raw = $vNode.InnerText
                }

                $vals[$colIndex] = $raw
            }

            if ([string]::IsNullOrWhiteSpace([string]$vals[0])) {
                continue
            }

            $excelDate = [double]::Parse([string]$vals[0], [Globalization.CultureInfo]::InvariantCulture)
            $date = [DateTime]::FromOADate($excelDate).Date

            $rows += [pscustomobject]@{
                Date             = $date
                IssuesFound      = [string]$vals[1]
                VendingMachineId = [string]$vals[2]
                FullName         = [string]$vals[3]
                WorkDescription  = [string]$vals[4]
            }
        }

        return $rows
    }
    finally {
        $zip.Dispose()
    }
}

function Normalize-PaymentSystemName {
    param([Parameter(Mandatory)][string]$Name)

    $n = $Name.Trim()
    if ($n -eq 'Модуль б/н оплаты') {
        return 'Модуль безналичной оплаты'
    }
    return $n
}

function Normalize-SalePaymentMethodName {
    param([Parameter(Mandatory)][string]$Name)

    $n = $Name.Trim()
    if ($n -ieq 'Qr-код' -or $n -ieq 'QR-код') {
        return 'QR'
    }
    return $n
}

function Map-VendingMachineStatusName {
    param([Parameter(Mandatory)][string]$Name)

    $n = $Name.Trim()
    switch ($n) {
        'Сломан' { return 'Вышел из строя' }
        'Обслуживается' { return 'В ремонте/на обслуживании' }
        default { return $n }
    }
}

if (!(Test-Path -LiteralPath $ImportDir)) {
    throw "ImportDir not found: $ImportDir"
}

$vendingMachines = Import-Csv -Path (Join-Path $ImportDir 'vending_machines.csv') -Delimiter ';' -Encoding 'windows-1251'
$sales = Import-Csv -Path (Join-Path $ImportDir 'sales.csv') -Delimiter ';' -Encoding 'windows-1251'
$products = Get-Content -Path (Join-Path $ImportDir 'products.json') -Raw | ConvertFrom-Json
$users = Get-ChildItem -Path (Join-Path $ImportDir 'users') -Filter '*.json' | ForEach-Object {
    Get-Content -Path $_.FullName -Raw | ConvertFrom-Json
}
$maintenance = Read-MaintenanceXlsx -Path (Join-Path $ImportDir 'maintenance.xlsx')

$productByExternalId = @{}
foreach ($p in $products) {
    $productByExternalId[[string]$p.id] = $p
}

$lines = New-Object System.Collections.Generic.List[string]

$lines.Add('/*')
$lines.Add('    ImportData.sql (Microsoft SQL Server)')
$lines.Add('    Source: ../Import')
$lines.Add("    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("    Default password for imported users: $DefaultPassword")
$lines.Add('*/')
$lines.Add('')
$lines.Add('USE [VendingService];')
$lines.Add('GO')
$lines.Add('SET NOCOUNT ON;')
$lines.Add('SET XACT_ABORT ON;')
$lines.Add('GO')
$lines.Add('')
$lines.Add('BEGIN TRY')
$lines.Add('    BEGIN TRAN;')
$lines.Add('')

# ---- Lookups we know we need for the import
$lines.Add('    /* ===== Ensure required lookup values ===== */')

$lines.Add('    MERGE dbo.WorkMode AS target')
$lines.Add('    USING (VALUES')
foreach ($wm in ($vendingMachines.work_mode | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)) {
    $lines.Add("        (" + (SqlN $wm) + "),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('    ) AS source (Name)')
$lines.Add('    ON target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (Name) VALUES (source.Name);')
$lines.Add('')

$lines.Add('    MERGE dbo.TimeZone AS target')
$lines.Add('    USING (VALUES')
foreach ($tz in ($vendingMachines.timezone | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)) {
    $m = [regex]::Match($tz, '^UTC\s*([+-])\s*(\d+)$', 'IgnoreCase')
    if (!$m.Success) {
        continue
    }
    $sign = $m.Groups[1].Value
    $hours = [int]$m.Groups[2].Value
    $offset = $hours * 60
    if ($sign -eq '-') { $offset = -$offset }

    $lines.Add("        (" + (SqlN ("UTC$sign$hours")) + ", CAST($offset AS smallint)),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('    ) AS source (Name, UtcOffsetMinutes)')
$lines.Add('    ON target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (Name, UtcOffsetMinutes) VALUES (source.Name, source.UtcOffsetMinutes)')
$lines.Add('    WHEN MATCHED AND target.UtcOffsetMinutes <> source.UtcOffsetMinutes THEN')
$lines.Add('        UPDATE SET UtcOffsetMinutes = source.UtcOffsetMinutes;')
$lines.Add('')

$lines.Add('    MERGE dbo.CriticalValuesTemplate AS target')
$lines.Add('    USING (VALUES')
foreach ($ct in ($vendingMachines.critical_threshold_template | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)) {
    $lines.Add("        (" + (SqlN $ct) + ", NULL),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('    ) AS source (Name, Description)')
$lines.Add('    ON target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (Name, Description) VALUES (source.Name, source.Description);')
$lines.Add('')

$lines.Add('    MERGE dbo.NotificationTemplate AS target')
$lines.Add('    USING (VALUES')
foreach ($nt in ($vendingMachines.notification_template | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)) {
    $lines.Add("        (" + (SqlN $nt) + ", NULL),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('    ) AS source (Name, Description)')
$lines.Add('    ON target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (Name, Description) VALUES (source.Name, source.Description);')
$lines.Add('')

$lines.Add('    MERGE dbo.UserRole AS target')
$lines.Add('    USING (VALUES')
$requiredRoles = @('Администратор', 'Оператор', 'Менеджер', 'Инженер', 'Техник-оператор', 'Франчайзи')
foreach ($r in $requiredRoles) {
    $lines.Add("        (" + (SqlN $r) + "),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('    ) AS source (Name)')
$lines.Add('    ON target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (Name) VALUES (source.Name);')
$lines.Add('')

$lines.Add('    MERGE dbo.Company AS target')
$lines.Add('    USING (VALUES')
foreach ($c in ($vendingMachines.company | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)) {
    $lines.Add("        (" + (SqlN $c) + ", NULL, NULL, NULL),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('    ) AS source (Name, Phone, Email, Address)')
$lines.Add('    ON target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (Name, Phone, Email, Address) VALUES (source.Name, source.Phone, source.Email, source.Address);')
$lines.Add('')

$modelPairs = foreach ($vm in $vendingMachines) {
    $modelRaw = ([string]$vm.model).Trim()
    if ([string]::IsNullOrWhiteSpace($modelRaw)) { continue }
    $firstSpace = $modelRaw.IndexOf(' ')
    if ($firstSpace -lt 1) { continue }
    [pscustomobject]@{
        Manufacturer = $modelRaw.Substring(0, $firstSpace).Trim()
        Model        = $modelRaw.Substring($firstSpace + 1).Trim()
    }
}

$manufacturers = $modelPairs | Select-Object -ExpandProperty Manufacturer | Sort-Object -Unique
$lines.Add('    MERGE dbo.VendingMachineManufacturer AS target')
$lines.Add('    USING (VALUES')
foreach ($m in $manufacturers) {
    $lines.Add("        (" + (SqlN $m) + "),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('    ) AS source (Name)')
$lines.Add('    ON target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (Name) VALUES (source.Name);')
$lines.Add('')

$lines.Add('    MERGE dbo.VendingMachineModel AS target')
$lines.Add('    USING')
$lines.Add('    (')
$lines.Add('        SELECT m.VendingMachineManufacturerId, v.Name')
$lines.Add('        FROM (VALUES')
foreach ($p in ($modelPairs | Sort-Object Manufacturer, Model -Unique)) {
    $lines.Add("            (" + (SqlN $p.Manufacturer) + ", " + (SqlN $p.Model) + "),")
}
if ($lines[-1].EndsWith(',')) { $lines[-1] = $lines[-1].TrimEnd(',') }
$lines.Add('        ) AS v(ManufacturerName, Name)')
$lines.Add('        INNER JOIN dbo.VendingMachineManufacturer m ON m.Name = v.ManufacturerName')
$lines.Add('    ) AS source (VendingMachineManufacturerId, Name)')
$lines.Add('    ON target.VendingMachineManufacturerId = source.VendingMachineManufacturerId AND target.Name = source.Name')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (VendingMachineManufacturerId, Name) VALUES (source.VendingMachineManufacturerId, source.Name);')
$lines.Add('')

# ---- Users import
$lines.Add('    /* ===== Import users ===== */')
$lines.Add('    IF OBJECT_ID(N''tempdb..#UserImport'') IS NOT NULL DROP TABLE #UserImport;')
$lines.Add('    CREATE TABLE #UserImport')
$lines.Add('    (')
$lines.Add('        ExternalId uniqueidentifier NOT NULL,')
$lines.Add('        Email nvarchar(256) NOT NULL,')
$lines.Add('        Phone nvarchar(32) NULL,')
$lines.Add('        LastName nvarchar(100) NOT NULL,')
$lines.Add('        FirstName nvarchar(100) NOT NULL,')
$lines.Add('        Patronymic nvarchar(100) NULL,')
$lines.Add('        RoleName nvarchar(50) NOT NULL,')
$lines.Add('        PasswordHash nvarchar(255) NOT NULL,')
$lines.Add('        PasswordSalt nvarchar(255) NOT NULL')
$lines.Add('    );')
$lines.Add('')

foreach ($u in $users) {
    $nameParts = Split-FullName -FullName $u.full_name

    $roleName = 'Оператор'
    if ($u.role -eq 'Франчайзи') {
        $roleName = 'Франчайзи'
    }
    elseif ($u.is_manager) {
        $roleName = 'Менеджер'
    }
    elseif ($u.is_engineer) {
        $roleName = 'Инженер'
    }
    elseif ($u.is_operator) {
        $roleName = 'Оператор'
    }

    $pwd = New-DeterministicPasswordHash -Password $DefaultPassword -SaltSeed ([string]$u.id)

    $lines.Add(
        '    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES (' +
        (SqlGuid $u.id) + ', ' +
        (SqlN $u.email) + ', ' +
        (SqlN $u.phone) + ', ' +
        (SqlN $nameParts.LastName) + ', ' +
        (SqlN $nameParts.FirstName) + ', ' +
        (SqlN $nameParts.Patronymic) + ', ' +
        (SqlN $roleName) + ', ' +
        (SqlN $pwd.PasswordHash) + ', ' +
        (SqlN $pwd.PasswordSalt) +
        ');'
    )
}
$lines.Add('')

$lines.Add('    INSERT INTO dbo.UserAccount')
$lines.Add('    (Email, Phone, LastName, FirstName, Patronymic, PasswordHash, PasswordSalt, PhotoUrl, UserRoleId, CompanyId, IsActive, CreatedAt)')
$lines.Add('    SELECT')
$lines.Add('        ui.Email,')
$lines.Add('        ui.Phone,')
$lines.Add('        ui.LastName,')
$lines.Add('        ui.FirstName,')
$lines.Add('        ui.Patronymic,')
$lines.Add('        ui.PasswordHash,')
$lines.Add('        ui.PasswordSalt,')
$lines.Add('        NULL,')
$lines.Add('        ur.UserRoleId,')
$lines.Add('        NULL,')
$lines.Add('        1,')
$lines.Add('        SYSDATETIME()')
$lines.Add('    FROM #UserImport ui')
$lines.Add('    INNER JOIN dbo.UserRole ur ON ur.Name = ui.RoleName')
$lines.Add('    LEFT JOIN dbo.UserAccount ua ON ua.Email = ui.Email')
$lines.Add('    WHERE ua.UserAccountId IS NULL;')
$lines.Add('')

$lines.Add('    IF OBJECT_ID(N''tempdb..#UserMap'') IS NOT NULL DROP TABLE #UserMap;')
$lines.Add('    CREATE TABLE #UserMap (ExternalId uniqueidentifier NOT NULL PRIMARY KEY, UserAccountId int NOT NULL);')
$lines.Add('    INSERT INTO #UserMap (ExternalId, UserAccountId)')
$lines.Add('    SELECT ui.ExternalId, ua.UserAccountId')
$lines.Add('    FROM #UserImport ui')
$lines.Add('    INNER JOIN dbo.UserAccount ua ON ua.Email = ui.Email;')
$lines.Add('')

# ---- Vending machines import
$lines.Add('    /* ===== Import vending machines ===== */')
$lines.Add('    IF OBJECT_ID(N''tempdb..#VendingMachineImport'') IS NOT NULL DROP TABLE #VendingMachineImport;')
$lines.Add('    CREATE TABLE #VendingMachineImport')
$lines.Add('    (')
$lines.Add('        ExternalId uniqueidentifier NOT NULL,')
$lines.Add('        Name nvarchar(200) NOT NULL,')
$lines.Add('        SerialNumber nvarchar(50) NOT NULL,')
$lines.Add('        InventoryNumber nvarchar(50) NOT NULL,')
$lines.Add('        ManufacturerName nvarchar(150) NOT NULL,')
$lines.Add('        ModelName nvarchar(150) NOT NULL,')
$lines.Add('        CompanyName nvarchar(200) NOT NULL,')
$lines.Add('        WorkModeName nvarchar(100) NOT NULL,')
$lines.Add('        TimeZoneName nvarchar(50) NOT NULL,')
$lines.Add('        StatusName nvarchar(100) NOT NULL,')
$lines.Add('        ServicePriorityName nvarchar(50) NOT NULL,')
$lines.Add('        Address nvarchar(300) NOT NULL,')
$lines.Add('        Place nvarchar(200) NOT NULL,')
$lines.Add('        Latitude decimal(9,6) NULL,')
$lines.Add('        Longitude decimal(9,6) NULL,')
$lines.Add('        WorkingTimeFrom time(0) NULL,')
$lines.Add('        WorkingTimeTo time(0) NULL,')
$lines.Add('        CriticalTemplateName nvarchar(150) NULL,')
$lines.Add('        NotificationTemplateName nvarchar(150) NULL,')
$lines.Add('        ManagerLastName nvarchar(100) NULL,')
$lines.Add('        ManagerFirstName nvarchar(100) NULL,')
$lines.Add('        ManagerPatronymic nvarchar(100) NULL,')
$lines.Add('        EngineerLastName nvarchar(100) NULL,')
$lines.Add('        EngineerFirstName nvarchar(100) NULL,')
$lines.Add('        EngineerPatronymic nvarchar(100) NULL,')
$lines.Add('        TechnicianLastName nvarchar(100) NULL,')
$lines.Add('        TechnicianFirstName nvarchar(100) NULL,')
$lines.Add('        TechnicianPatronymic nvarchar(100) NULL,')
$lines.Add('        KitOnlineCashRegisterId nvarchar(50) NULL,')
$lines.Add('        Notes nvarchar(1000) NULL,')
$lines.Add('        InstallDate date NOT NULL')
$lines.Add('    );')
$lines.Add('')

foreach ($vm in $vendingMachines) {
    $modelRaw = ([string]$vm.model).Trim()
    $firstSpace = $modelRaw.IndexOf(' ')
    $manufacturer = $modelRaw.Substring(0, $firstSpace).Trim()
    $modelName = $modelRaw.Substring($firstSpace + 1).Trim()

    $coords = ([string]$vm.coordinates).Split(',')
    $lat = $null
    $lon = $null
    if ($coords.Count -ge 2) {
        $lat = $coords[0].Trim()
        $lon = $coords[1].Trim()
    }

    $workingFrom = $null
    $workingTo = $null
    $wh = ([string]$vm.working_hours).Trim()
    if ($wh -match '^\s*(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\s*$') {
        $workingFrom = $Matches[1]
        $workingTo = $Matches[2]
    }

    $installDate = [DateTime]::Parse([string]$vm.install_date, [Globalization.CultureInfo]::InvariantCulture).Date

    $managerLast = $null
    $managerFirst = $null
    $managerPatronymic = $null
    if (![string]::IsNullOrWhiteSpace([string]$vm.manager)) {
        $mp = Split-FullName -FullName $vm.manager
        $managerLast = $mp.LastName
        $managerFirst = $mp.FirstName
        $managerPatronymic = $mp.Patronymic
    }

    $engineerLast = $null
    $engineerFirst = $null
    $engineerPatronymic = $null
    if (![string]::IsNullOrWhiteSpace([string]$vm.engineer)) {
        $ep = Split-FullName -FullName $vm.engineer
        $engineerLast = $ep.LastName
        $engineerFirst = $ep.FirstName
        $engineerPatronymic = $ep.Patronymic
    }

    $technicianLast = $null
    $technicianFirst = $null
    $technicianPatronymic = $null
    if (![string]::IsNullOrWhiteSpace([string]$vm.technician)) {
        $tp = Split-FullName -FullName $vm.technician
        $technicianLast = $tp.LastName
        $technicianFirst = $tp.FirstName
        $technicianPatronymic = $tp.Patronymic
    }

    $lines.Add(
        '    INSERT INTO #VendingMachineImport (' +
        'ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, ' +
        'Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ' +
        'ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, ' +
        'KitOnlineCashRegisterId, Notes, InstallDate) VALUES (' +
        (SqlGuid $vm.id) + ', ' +
        (SqlN $vm.name) + ', ' +
        (SqlN $vm.serial_number) + ', ' +
        (SqlN ("INV-" + $vm.serial_number)) + ', ' +
        (SqlN $manufacturer) + ', ' +
        (SqlN $modelName) + ', ' +
        (SqlN $vm.company) + ', ' +
        (SqlN $vm.work_mode) + ', ' +
        (SqlN $vm.timezone) + ', ' +
        (SqlN (Map-VendingMachineStatusName $vm.status)) + ', ' +
        (SqlN $vm.service_priority) + ', ' +
        (SqlN $vm.location) + ', ' +
        (SqlN $vm.place) + ', ' +
        (SqlDecimal $lat 6) + ', ' +
        (SqlDecimal $lon 6) + ', ' +
        (SqlN $workingFrom) + ', ' +
        (SqlN $workingTo) + ', ' +
        (SqlN $vm.critical_threshold_template) + ', ' +
        (SqlN $vm.notification_template) + ', ' +
        (SqlN $managerLast) + ', ' +
        (SqlN $managerFirst) + ', ' +
        (SqlN $managerPatronymic) + ', ' +
        (SqlN $engineerLast) + ', ' +
        (SqlN $engineerFirst) + ', ' +
        (SqlN $engineerPatronymic) + ', ' +
        (SqlN $technicianLast) + ', ' +
        (SqlN $technicianFirst) + ', ' +
        (SqlN $technicianPatronymic) + ', ' +
        (SqlN $vm.kit_online_id) + ', ' +
        (SqlN $vm.notes) + ', ' +
        (SqlDate $installDate) +
        ');'
    )
}
$lines.Add('')

$lines.Add('    INSERT INTO dbo.VendingMachine')
$lines.Add('    (')
$lines.Add('        Name,')
$lines.Add('        VendingMachineModelId,')
$lines.Add('        WorkModeId,')
$lines.Add('        TimeZoneId,')
$lines.Add('        VendingMachineStatusId,')
$lines.Add('        ServicePriorityId,')
$lines.Add('        ProductMatrixId,')
$lines.Add('        CompanyId,')
$lines.Add('        ModemId,')
$lines.Add('        Address,')
$lines.Add('        Place,')
$lines.Add('        Latitude,')
$lines.Add('        Longitude,')
$lines.Add('        InventoryNumber,')
$lines.Add('        SerialNumber,')
$lines.Add('        ManufactureDate,')
$lines.Add('        CommissioningDate,')
$lines.Add('        CountryId,')
$lines.Add('        WorkingTimeFrom,')
$lines.Add('        WorkingTimeTo,')
$lines.Add('        CriticalValuesTemplateId,')
$lines.Add('        NotificationTemplateId,')
$lines.Add('        ManagerUserAccountId,')
$lines.Add('        EngineerUserAccountId,')
$lines.Add('        TechnicianOperatorUserAccountId,')
$lines.Add('        KitOnlineCashRegisterId,')
$lines.Add('        Notes')
$lines.Add('    )')
$lines.Add('    SELECT')
$lines.Add('        i.Name,')
$lines.Add('        model.VendingMachineModelId,')
$lines.Add('        wm.WorkModeId,')
$lines.Add('        tz.TimeZoneId,')
$lines.Add('        st.VendingMachineStatusId,')
$lines.Add('        sp.ServicePriorityId,')
$lines.Add('        pm.ProductMatrixId,')
$lines.Add('        c.CompanyId,')
$lines.Add('        NULL,')
$lines.Add('        i.Address,')
$lines.Add('        i.Place,')
$lines.Add('        i.Latitude,')
$lines.Add('        i.Longitude,')
$lines.Add('        i.InventoryNumber,')
$lines.Add('        i.SerialNumber,')
$lines.Add('        i.InstallDate,')
$lines.Add('        i.InstallDate,')
$lines.Add('        country.CountryId,')
$lines.Add('        i.WorkingTimeFrom,')
$lines.Add('        i.WorkingTimeTo,')
$lines.Add('        ct.CriticalValuesTemplateId,')
$lines.Add('        nt.NotificationTemplateId,')
$lines.Add('        manager.UserAccountId,')
$lines.Add('        engineer.UserAccountId,')
$lines.Add('        tech.UserAccountId,')
$lines.Add('        i.KitOnlineCashRegisterId,')
$lines.Add('        i.Notes')
$lines.Add('    FROM #VendingMachineImport i')
$lines.Add('    INNER JOIN dbo.Company c ON c.Name = i.CompanyName')
$lines.Add('    INNER JOIN dbo.WorkMode wm ON wm.Name = i.WorkModeName')
$lines.Add('    INNER JOIN dbo.TimeZone tz ON tz.Name = i.TimeZoneName')
$lines.Add('    INNER JOIN dbo.VendingMachineStatus st ON st.Name = i.StatusName')
$lines.Add('    INNER JOIN dbo.ServicePriority sp ON sp.Name = i.ServicePriorityName')
$lines.Add('    INNER JOIN dbo.ProductMatrix pm ON pm.Name = N''Не установлена''')
$lines.Add('    INNER JOIN dbo.Country country ON country.Name = N''Россия''')
$lines.Add('    INNER JOIN dbo.VendingMachineManufacturer man ON man.Name = i.ManufacturerName')
$lines.Add('    INNER JOIN dbo.VendingMachineModel model ON model.VendingMachineManufacturerId = man.VendingMachineManufacturerId AND model.Name = i.ModelName')
$lines.Add('    LEFT JOIN dbo.CriticalValuesTemplate ct ON ct.Name = i.CriticalTemplateName')
$lines.Add('    LEFT JOIN dbo.NotificationTemplate nt ON nt.Name = i.NotificationTemplateName')
$lines.Add('    LEFT JOIN dbo.UserAccount manager ON manager.LastName = i.ManagerLastName AND manager.FirstName = i.ManagerFirstName AND ISNULL(manager.Patronymic, N'''') = ISNULL(i.ManagerPatronymic, N'''')')
$lines.Add('    LEFT JOIN dbo.UserAccount engineer ON engineer.LastName = i.EngineerLastName AND engineer.FirstName = i.EngineerFirstName AND ISNULL(engineer.Patronymic, N'''') = ISNULL(i.EngineerPatronymic, N'''')')
$lines.Add('    LEFT JOIN dbo.UserAccount tech ON tech.LastName = i.TechnicianLastName AND tech.FirstName = i.TechnicianFirstName AND ISNULL(tech.Patronymic, N'''') = ISNULL(i.TechnicianPatronymic, N'''')')
$lines.Add('    LEFT JOIN dbo.VendingMachine existing ON existing.SerialNumber = i.SerialNumber')
$lines.Add('    WHERE existing.VendingMachineId IS NULL;')
$lines.Add('')

$lines.Add('    IF OBJECT_ID(N''tempdb..#VendingMachineMap'') IS NOT NULL DROP TABLE #VendingMachineMap;')
$lines.Add('    CREATE TABLE #VendingMachineMap (ExternalId uniqueidentifier NOT NULL PRIMARY KEY, VendingMachineId int NOT NULL);')
$lines.Add('    INSERT INTO #VendingMachineMap (ExternalId, VendingMachineId)')
$lines.Add('    SELECT i.ExternalId, vm.VendingMachineId')
$lines.Add('    FROM #VendingMachineImport i')
$lines.Add('    INNER JOIN dbo.VendingMachine vm ON vm.SerialNumber = i.SerialNumber;')
$lines.Add('')

# ---- Payment systems per machine
$lines.Add('    /* ===== Import vending machine payment systems ===== */')
$lines.Add('    IF OBJECT_ID(N''tempdb..#VendingMachinePaymentImport'') IS NOT NULL DROP TABLE #VendingMachinePaymentImport;')
$lines.Add('    CREATE TABLE #VendingMachinePaymentImport (VendingMachineExternalId uniqueidentifier NOT NULL, PaymentSystemName nvarchar(100) NOT NULL);')
$lines.Add('')

foreach ($vm in $vendingMachines) {
    $raw = [string]$vm.payment_type
    if ([string]::IsNullOrWhiteSpace($raw)) {
        continue
    }

    $parts = $raw.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($p in $parts) {
        $norm = Normalize-PaymentSystemName -Name $p
        $lines.Add('    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES (' + (SqlGuid $vm.id) + ', ' + (SqlN $norm) + ');')
    }
}
$lines.Add('')

$lines.Add('    INSERT INTO dbo.VendingMachinePaymentSystem (VendingMachineId, PaymentSystemId)')
$lines.Add('    SELECT m.VendingMachineId, ps.PaymentSystemId')
$lines.Add('    FROM #VendingMachinePaymentImport i')
$lines.Add('    INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId')
$lines.Add('    INNER JOIN dbo.PaymentSystem ps ON ps.Name = i.PaymentSystemName')
$lines.Add('    LEFT JOIN dbo.VendingMachinePaymentSystem existing ON existing.VendingMachineId = m.VendingMachineId AND existing.PaymentSystemId = ps.PaymentSystemId')
$lines.Add('    WHERE existing.VendingMachineId IS NULL;')
$lines.Add('')

# ---- RFID cards (optional)
$lines.Add('    /* ===== Import RFID cards ===== */')
$lines.Add('    IF OBJECT_ID(N''tempdb..#VendingMachineRfidImport'') IS NOT NULL DROP TABLE #VendingMachineRfidImport;')
$lines.Add('    CREATE TABLE #VendingMachineRfidImport (VendingMachineExternalId uniqueidentifier NOT NULL, CardCode nvarchar(50) NOT NULL, CardTypeName nvarchar(50) NOT NULL);')
$lines.Add('')

foreach ($vm in $vendingMachines) {
    if (![string]::IsNullOrWhiteSpace([string]$vm.rfid_service)) {
        $lines.Add('    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES (' + (SqlGuid $vm.id) + ', ' + (SqlN $vm.rfid_service) + ', N''Обслуживание'');')
    }
    if (![string]::IsNullOrWhiteSpace([string]$vm.rfid_cash_collection)) {
        $lines.Add('    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES (' + (SqlGuid $vm.id) + ', ' + (SqlN $vm.rfid_cash_collection) + ', N''Инкассация'');')
    }
    if (![string]::IsNullOrWhiteSpace([string]$vm.rfid_loading)) {
        $lines.Add('    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES (' + (SqlGuid $vm.id) + ', ' + (SqlN $vm.rfid_loading) + ', N''Загрузка'');')
    }
}
$lines.Add('')

$lines.Add('    INSERT INTO dbo.RfidCard (CardCode)')
$lines.Add('    SELECT DISTINCT i.CardCode')
$lines.Add('    FROM #VendingMachineRfidImport i')
$lines.Add('    LEFT JOIN dbo.RfidCard c ON c.CardCode = i.CardCode')
$lines.Add('    WHERE c.RfidCardId IS NULL;')
$lines.Add('')

$lines.Add('    INSERT INTO dbo.VendingMachineRfidCard (VendingMachineId, RfidCardId, RfidCardTypeId)')
$lines.Add('    SELECT m.VendingMachineId, c.RfidCardId, t.RfidCardTypeId')
$lines.Add('    FROM #VendingMachineRfidImport i')
$lines.Add('    INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId')
$lines.Add('    INNER JOIN dbo.RfidCard c ON c.CardCode = i.CardCode')
$lines.Add('    INNER JOIN dbo.RfidCardType t ON t.Name = i.CardTypeName')
$lines.Add('    LEFT JOIN dbo.VendingMachineRfidCard existing ON existing.VendingMachineId = m.VendingMachineId AND existing.RfidCardId = c.RfidCardId AND existing.RfidCardTypeId = t.RfidCardTypeId')
$lines.Add('    WHERE existing.VendingMachineId IS NULL;')
$lines.Add('')

# ---- Products + stock
$lines.Add('    /* ===== Import products + vending machine stock ===== */')
$lines.Add('    IF OBJECT_ID(N''tempdb..#ProductImport'') IS NOT NULL DROP TABLE #ProductImport;')
$lines.Add('    CREATE TABLE #ProductImport')
$lines.Add('    (')
$lines.Add('        ExternalId uniqueidentifier NOT NULL,')
$lines.Add('        Name nvarchar(200) NOT NULL,')
$lines.Add('        Description nvarchar(1000) NULL,')
$lines.Add('        Price decimal(18,2) NOT NULL,')
$lines.Add('        VendingMachineExternalId uniqueidentifier NOT NULL,')
$lines.Add('        QuantityOnHand int NOT NULL,')
$lines.Add('        MinimumStock int NOT NULL,')
$lines.Add('        AverageDailySales decimal(10,2) NULL')
$lines.Add('    );')
$lines.Add('')

foreach ($p in $products) {
    $lines.Add(
        '    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES (' +
        (SqlGuid $p.id) + ', ' +
        (SqlN $p.name) + ', ' +
        (SqlN $p.description) + ', ' +
        (SqlDecimal $p.price 2) + ', ' +
        (SqlGuid $p.vending_machine_id) + ', ' +
        (SqlInt $p.quantity_available) + ', ' +
        (SqlInt $p.min_stock) + ', ' +
        (SqlDecimal $p.sales_trend 2) +
        ');'
    )
}
$lines.Add('')

$lines.Add('    INSERT INTO dbo.Product (Name, Description, Price)')
$lines.Add('    SELECT i.Name, i.Description, i.Price')
$lines.Add('    FROM #ProductImport i')
$lines.Add('    LEFT JOIN dbo.Product p ON p.Name = i.Name')
$lines.Add('    WHERE p.ProductId IS NULL;')
$lines.Add('')

$lines.Add('    IF OBJECT_ID(N''tempdb..#ProductMap'') IS NOT NULL DROP TABLE #ProductMap;')
$lines.Add('    CREATE TABLE #ProductMap (ExternalId uniqueidentifier NOT NULL PRIMARY KEY, ProductId int NOT NULL, VendingMachineExternalId uniqueidentifier NOT NULL);')
$lines.Add('    INSERT INTO #ProductMap (ExternalId, ProductId, VendingMachineExternalId)')
$lines.Add('    SELECT i.ExternalId, p.ProductId, i.VendingMachineExternalId')
$lines.Add('    FROM #ProductImport i')
$lines.Add('    INNER JOIN dbo.Product p ON p.Name = i.Name;')
$lines.Add('')

$lines.Add('    MERGE dbo.VendingMachineProduct AS target')
$lines.Add('    USING')
$lines.Add('    (')
$lines.Add('        SELECT')
$lines.Add('            m.VendingMachineId,')
$lines.Add('            pm.ProductId,')
$lines.Add('            i.QuantityOnHand,')
$lines.Add('            i.MinimumStock,')
$lines.Add('            i.AverageDailySales')
$lines.Add('        FROM #ProductImport i')
$lines.Add('        INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId')
$lines.Add('        INNER JOIN dbo.Product pm ON pm.Name = i.Name')
$lines.Add('    ) AS source (VendingMachineId, ProductId, QuantityOnHand, MinimumStock, AverageDailySales)')
$lines.Add('    ON target.VendingMachineId = source.VendingMachineId AND target.ProductId = source.ProductId')
$lines.Add('    WHEN MATCHED THEN')
$lines.Add('        UPDATE SET')
$lines.Add('            QuantityOnHand = source.QuantityOnHand,')
$lines.Add('            MinimumStock = source.MinimumStock,')
$lines.Add('            AverageDailySales = source.AverageDailySales,')
$lines.Add('            UpdatedAt = SYSDATETIME()')
$lines.Add('    WHEN NOT MATCHED THEN')
$lines.Add('        INSERT (VendingMachineId, ProductId, QuantityOnHand, MinimumStock, AverageDailySales)')
$lines.Add('        VALUES (source.VendingMachineId, source.ProductId, source.QuantityOnHand, source.MinimumStock, source.AverageDailySales);')
$lines.Add('')

# ---- Sales
$lines.Add('    /* ===== Import sales ===== */')
$lines.Add('    IF OBJECT_ID(N''tempdb..#SaleImport'') IS NOT NULL DROP TABLE #SaleImport;')
$lines.Add('    CREATE TABLE #SaleImport')
$lines.Add('    (')
$lines.Add('        SoldAt datetime2(0) NOT NULL,')
$lines.Add('        ProductExternalId uniqueidentifier NOT NULL,')
$lines.Add('        VendingMachineExternalId uniqueidentifier NOT NULL,')
$lines.Add('        Quantity int NOT NULL,')
$lines.Add('        TotalAmount decimal(18,2) NOT NULL,')
$lines.Add('        PaymentMethodName nvarchar(50) NOT NULL')
$lines.Add('    );')
$lines.Add('')

foreach ($s in $sales) {
    $productExternalId = [string]$s.product_id
    if (!$productByExternalId.ContainsKey($productExternalId)) {
        continue
    }

    $machineExternalId = [string]$productByExternalId[$productExternalId].vending_machine_id
    $soldAt = [DateTime]::Parse([string]$s.timestamp, [Globalization.CultureInfo]::InvariantCulture)
    $method = Normalize-SalePaymentMethodName -Name $s.payment_method

    $lines.Add(
        '    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES (' +
        (SqlDateTimeSeconds $soldAt) + ', ' +
        (SqlGuid $productExternalId) + ', ' +
        (SqlGuid $machineExternalId) + ', ' +
        (SqlInt $s.quantity) + ', ' +
        (SqlDecimal $s.total_price 2) + ', ' +
        (SqlN $method) +
        ');'
    )
}
$lines.Add('')

$lines.Add('    INSERT INTO dbo.Sale (VendingMachineId, ProductId, Quantity, TotalAmount, SoldAt, SalePaymentMethodId)')
$lines.Add('    SELECT')
$lines.Add('        m.VendingMachineId,')
$lines.Add('        p.ProductId,')
$lines.Add('        i.Quantity,')
$lines.Add('        i.TotalAmount,')
$lines.Add('        i.SoldAt,')
$lines.Add('        spm.SalePaymentMethodId')
$lines.Add('    FROM #SaleImport i')
$lines.Add('    INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId')
$lines.Add('    INNER JOIN #ProductMap pm ON pm.ExternalId = i.ProductExternalId')
$lines.Add('    INNER JOIN dbo.Product p ON p.ProductId = pm.ProductId')
$lines.Add('    INNER JOIN dbo.SalePaymentMethod spm ON spm.Name = i.PaymentMethodName')
$lines.Add('    WHERE NOT EXISTS')
$lines.Add('    (')
$lines.Add('        SELECT 1')
$lines.Add('        FROM dbo.Sale s')
$lines.Add('        WHERE')
$lines.Add('            s.VendingMachineId = m.VendingMachineId')
$lines.Add('            AND s.ProductId = p.ProductId')
$lines.Add('            AND s.SoldAt = i.SoldAt')
$lines.Add('            AND s.Quantity = i.Quantity')
$lines.Add('            AND s.TotalAmount = i.TotalAmount')
$lines.Add('            AND s.SalePaymentMethodId = spm.SalePaymentMethodId')
$lines.Add('    );')
$lines.Add('')

# ---- Maintenance
$lines.Add('    /* ===== Import maintenance ===== */')
$lines.Add('    IF OBJECT_ID(N''tempdb..#MaintenanceImport'') IS NOT NULL DROP TABLE #MaintenanceImport;')
$lines.Add('    CREATE TABLE #MaintenanceImport')
$lines.Add('    (')
$lines.Add('        MaintenanceDate date NOT NULL,')
$lines.Add('        VendingMachineExternalId uniqueidentifier NOT NULL,')
$lines.Add('        Problems nvarchar(1000) NULL,')
$lines.Add('        WorkDescription nvarchar(1000) NULL,')
$lines.Add('        ExecutorLastName nvarchar(100) NULL,')
$lines.Add('        ExecutorFirstName nvarchar(100) NULL,')
$lines.Add('        ExecutorPatronymic nvarchar(100) NULL')
$lines.Add('    );')
$lines.Add('')

foreach ($m in $maintenance) {
    $executorLast = $null
    $executorFirst = $null
    $executorPatronymic = $null
    if (![string]::IsNullOrWhiteSpace([string]$m.FullName)) {
        $ex = Split-FullName -FullName $m.FullName
        $executorLast = $ex.LastName
        $executorFirst = $ex.FirstName
        $executorPatronymic = $ex.Patronymic
    }

    $lines.Add(
        '    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES (' +
        (SqlDate $m.Date) + ', ' +
        (SqlGuid $m.VendingMachineId) + ', ' +
        (SqlN $m.IssuesFound) + ', ' +
        (SqlN $m.WorkDescription) + ', ' +
        (SqlN $executorLast) + ', ' +
        (SqlN $executorFirst) + ', ' +
        (SqlN $executorPatronymic) +
        ');'
    )
}
$lines.Add('')

$lines.Add('    INSERT INTO dbo.Maintenance (VendingMachineId, MaintenanceDate, WorkDescription, Problems, ExecutorUserAccountId)')
$lines.Add('    SELECT')
$lines.Add('        vm.VendingMachineId,')
$lines.Add('        i.MaintenanceDate,')
$lines.Add('        i.WorkDescription,')
$lines.Add('        i.Problems,')
$lines.Add('        u.UserAccountId')
$lines.Add('    FROM #MaintenanceImport i')
$lines.Add('    INNER JOIN #VendingMachineMap vm ON vm.ExternalId = i.VendingMachineExternalId')
$lines.Add('    LEFT JOIN dbo.UserAccount u ON u.LastName = i.ExecutorLastName AND u.FirstName = i.ExecutorFirstName AND ISNULL(u.Patronymic, N'''') = ISNULL(i.ExecutorPatronymic, N'''')')
$lines.Add('    WHERE NOT EXISTS')
$lines.Add('    (')
$lines.Add('        SELECT 1')
$lines.Add('        FROM dbo.Maintenance m')
$lines.Add('        WHERE')
$lines.Add('            m.VendingMachineId = vm.VendingMachineId')
$lines.Add('            AND m.MaintenanceDate = i.MaintenanceDate')
$lines.Add('            AND ISNULL(m.Problems, N'''') = ISNULL(i.Problems, N'''')')
$lines.Add('            AND ISNULL(m.WorkDescription, N'''') = ISNULL(i.WorkDescription, N'''')')
$lines.Add('    );')
$lines.Add('')

$lines.Add('    COMMIT;')
$lines.Add('END TRY')
$lines.Add('BEGIN CATCH')
$lines.Add('    IF @@TRANCOUNT > 0 ROLLBACK;')
$lines.Add('    THROW;')
$lines.Add('END CATCH;')
$lines.Add('GO')

$outDir = Split-Path -Parent $OutputSqlPath
if (![string]::IsNullOrWhiteSpace($outDir) -and !(Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

Set-Content -Path $OutputSqlPath -Value $lines -Encoding UTF8
Write-Host "Generated: $OutputSqlPath"
