/*
    VendingService (Microsoft SQL Server)
    Naming: PascalCase
    Normalization: 3NF (lookup tables for dropdowns, no denormalized FullName columns, etc.)
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF DB_ID(N'VendingService') IS NULL
BEGIN
    CREATE DATABASE [VendingService];
END
GO

USE [VendingService];
GO

/* =========================
   Lookup / reference tables
   ========================= */

IF OBJECT_ID(N'dbo.Country', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Country
    (
        CountryId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Country PRIMARY KEY,
        Name nvarchar(100) NOT NULL,
        IsoCode nchar(2) NULL,
        CONSTRAINT UQ_Country_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.TimeZone', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TimeZone
    (
        TimeZoneId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_TimeZone PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        UtcOffsetMinutes smallint NOT NULL,
        CONSTRAINT UQ_TimeZone_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.WorkMode', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.WorkMode
    (
        WorkModeId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_WorkMode PRIMARY KEY,
        Name nvarchar(100) NOT NULL,
        CONSTRAINT UQ_WorkMode_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.ServicePriority', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServicePriority
    (
        ServicePriorityId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ServicePriority PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        SortOrder int NOT NULL CONSTRAINT DF_ServicePriority_SortOrder DEFAULT (0),
        CONSTRAINT UQ_ServicePriority_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.ServiceRequestType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceRequestType
    (
        ServiceRequestTypeId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ServiceRequestType PRIMARY KEY,
        Name nvarchar(100) NOT NULL,
        CONSTRAINT UQ_ServiceRequestType_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.ServiceRequestStatus', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceRequestStatus
    (
        ServiceRequestStatusId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ServiceRequestStatus PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        SortOrder int NOT NULL CONSTRAINT DF_ServiceRequestStatus_SortOrder DEFAULT (0),
        CONSTRAINT UQ_ServiceRequestStatus_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineStatus', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineStatus
    (
        VendingMachineStatusId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_VendingMachineStatus PRIMARY KEY,
        Name nvarchar(100) NOT NULL,
        SortOrder int NOT NULL CONSTRAINT DF_VendingMachineStatus_SortOrder DEFAULT (0),
        CONSTRAINT UQ_VendingMachineStatus_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineManufacturer', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineManufacturer
    (
        VendingMachineManufacturerId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_VendingMachineManufacturer PRIMARY KEY,
        Name nvarchar(150) NOT NULL,
        CONSTRAINT UQ_VendingMachineManufacturer_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineModel', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineModel
    (
        VendingMachineModelId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_VendingMachineModel PRIMARY KEY,
        VendingMachineManufacturerId int NOT NULL,
        Name nvarchar(150) NOT NULL,
        CONSTRAINT FK_VendingMachineModel_VendingMachineManufacturer
            FOREIGN KEY (VendingMachineManufacturerId)
            REFERENCES dbo.VendingMachineManufacturer(VendingMachineManufacturerId),
        CONSTRAINT UQ_VendingMachineModel_Manufacturer_Name UNIQUE (VendingMachineManufacturerId, Name)
    );
END
GO

IF OBJECT_ID(N'dbo.Company', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Company
    (
        CompanyId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Company PRIMARY KEY,
        Name nvarchar(200) NOT NULL,
        Phone nvarchar(32) NULL,
        Email nvarchar(256) NULL,
        Address nvarchar(300) NULL,
        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_Company_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_Company_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.UserRole', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserRole
    (
        UserRoleId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_UserRole PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        CONSTRAINT UQ_UserRole_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.UserAccount', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserAccount
    (
        UserAccountId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_UserAccount PRIMARY KEY,
        Email nvarchar(256) NOT NULL,
        Phone nvarchar(32) NULL,
        LastName nvarchar(100) NOT NULL,
        FirstName nvarchar(100) NOT NULL,
        Patronymic nvarchar(100) NULL,
        PasswordHash nvarchar(255) NOT NULL,
        PasswordSalt nvarchar(255) NULL,
        PhotoUrl nvarchar(500) NULL,
        UserRoleId int NOT NULL,
        CompanyId int NULL,
        IsActive bit NOT NULL CONSTRAINT DF_UserAccount_IsActive DEFAULT (1),
        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_UserAccount_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_UserAccount_UserRole
            FOREIGN KEY (UserRoleId)
            REFERENCES dbo.UserRole(UserRoleId),
        CONSTRAINT FK_UserAccount_Company
            FOREIGN KEY (CompanyId)
            REFERENCES dbo.Company(CompanyId),
        CONSTRAINT UQ_UserAccount_Email UNIQUE (Email)
    );
END
GO

IF OBJECT_ID(N'dbo.UserAccountVendingMachineModel', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserAccountVendingMachineModel
    (
        UserAccountId int NOT NULL,
        VendingMachineModelId int NOT NULL,
        CONSTRAINT PK_UserAccountVendingMachineModel PRIMARY KEY (UserAccountId, VendingMachineModelId),
        CONSTRAINT FK_UserAccountVendingMachineModel_UserAccount
            FOREIGN KEY (UserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId),
        CONSTRAINT FK_UserAccountVendingMachineModel_VendingMachineModel
            FOREIGN KEY (VendingMachineModelId)
            REFERENCES dbo.VendingMachineModel(VendingMachineModelId)
    );
END
GO

IF OBJECT_ID(N'dbo.Provider', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Provider
    (
        ProviderId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Provider PRIMARY KEY,
        Name nvarchar(150) NOT NULL,
        CONSTRAINT UQ_Provider_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.ConnectionType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ConnectionType
    (
        ConnectionTypeId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConnectionType PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        CONSTRAINT UQ_ConnectionType_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.Modem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Modem
    (
        ModemId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Modem PRIMARY KEY,
        ModemNumber nvarchar(50) NOT NULL,
        Imei nvarchar(32) NULL,
        SimPhoneNumber nvarchar(32) NULL,
        ProviderId int NULL,
        ConnectionTypeId int NULL,
        Notes nvarchar(500) NULL,
        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_Modem_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Modem_Provider
            FOREIGN KEY (ProviderId)
            REFERENCES dbo.Provider(ProviderId),
        CONSTRAINT FK_Modem_ConnectionType
            FOREIGN KEY (ConnectionTypeId)
            REFERENCES dbo.ConnectionType(ConnectionTypeId),
        CONSTRAINT UQ_Modem_ModemNumber UNIQUE (ModemNumber),
        CONSTRAINT UQ_Modem_Imei UNIQUE (Imei)
    );
END
GO

IF OBJECT_ID(N'dbo.ProductMatrix', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductMatrix
    (
        ProductMatrixId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ProductMatrix PRIMARY KEY,
        Name nvarchar(150) NOT NULL,
        Description nvarchar(500) NULL,
        CONSTRAINT UQ_ProductMatrix_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.CriticalValuesTemplate', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CriticalValuesTemplate
    (
        CriticalValuesTemplateId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_CriticalValuesTemplate PRIMARY KEY,
        Name nvarchar(150) NOT NULL,
        Description nvarchar(500) NULL,
        CONSTRAINT UQ_CriticalValuesTemplate_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.NotificationTemplate', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NotificationTemplate
    (
        NotificationTemplateId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_NotificationTemplate PRIMARY KEY,
        Name nvarchar(150) NOT NULL,
        Description nvarchar(500) NULL,
        CONSTRAINT UQ_NotificationTemplate_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.PaymentSystem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentSystem
    (
        PaymentSystemId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_PaymentSystem PRIMARY KEY,
        Name nvarchar(100) NOT NULL,
        CONSTRAINT UQ_PaymentSystem_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.RfidCardType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RfidCardType
    (
        RfidCardTypeId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_RfidCardType PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        CONSTRAINT UQ_RfidCardType_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.RfidCard', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RfidCard
    (
        RfidCardId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_RfidCard PRIMARY KEY,
        CardCode nvarchar(50) NOT NULL,
        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_RfidCard_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_RfidCard_CardCode UNIQUE (CardCode)
    );
END
GO

IF OBJECT_ID(N'dbo.SalePaymentMethod', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalePaymentMethod
    (
        SalePaymentMethodId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_SalePaymentMethod PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        CONSTRAINT UQ_SalePaymentMethod_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.Product', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Product
    (
        ProductId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Product PRIMARY KEY,
        Name nvarchar(200) NOT NULL,
        Description nvarchar(1000) NULL,
        Price decimal(18,2) NOT NULL,
        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_Product_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT CK_Product_PriceNonNegative CHECK (Price >= 0),
        CONSTRAINT UQ_Product_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.EquipmentType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EquipmentType
    (
        EquipmentTypeId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EquipmentType PRIMARY KEY,
        Name nvarchar(100) NOT NULL,
        CONSTRAINT UQ_EquipmentType_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.EventSeverity', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EventSeverity
    (
        EventSeverityId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EventSeverity PRIMARY KEY,
        Name nvarchar(50) NOT NULL,
        SortOrder int NOT NULL CONSTRAINT DF_EventSeverity_SortOrder DEFAULT (0),
        CONSTRAINT UQ_EventSeverity_Name UNIQUE (Name)
    );
END
GO

IF OBJECT_ID(N'dbo.EventType', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EventType
    (
        EventTypeId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_EventType PRIMARY KEY,
        EventSeverityId int NOT NULL,
        Name nvarchar(150) NOT NULL,
        CONSTRAINT FK_EventType_EventSeverity
            FOREIGN KEY (EventSeverityId)
            REFERENCES dbo.EventSeverity(EventSeverityId),
        CONSTRAINT UQ_EventType_Name UNIQUE (Name)
    );
END
GO

/* =========================
   Core entities
   ========================= */

IF OBJECT_ID(N'dbo.VendingMachine', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachine
    (
        VendingMachineId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_VendingMachine PRIMARY KEY,
        -- В импортных ресурсах ID торгового автомата задан как GUID.
        -- Чтобы не ломать все связи (FK) в БД, храним GUID отдельно как "внешний" идентификатор.
        ExternalId uniqueidentifier NOT NULL CONSTRAINT DF_VendingMachine_ExternalId DEFAULT (newsequentialid()),
        Name nvarchar(200) NOT NULL,

        VendingMachineModelId int NOT NULL,
        WorkModeId int NOT NULL,
        TimeZoneId int NOT NULL,
        VendingMachineStatusId int NOT NULL,
        ServicePriorityId int NOT NULL,
        ProductMatrixId int NOT NULL,

        CompanyId int NULL,
        ModemId int NULL,

        Address nvarchar(300) NOT NULL,
        Place nvarchar(200) NOT NULL,
        Latitude decimal(9,6) NULL,
        Longitude decimal(9,6) NULL,

        InventoryNumber nvarchar(50) NOT NULL,
        SerialNumber nvarchar(50) NOT NULL,

        ManufactureDate date NOT NULL,
        CommissioningDate date NOT NULL,
        LastVerificationDate date NULL,
        VerificationIntervalMonths int NULL,
        NextVerificationDate AS
        (
            CASE
                WHEN LastVerificationDate IS NULL OR VerificationIntervalMonths IS NULL THEN NULL
                ELSE DATEADD(MONTH, VerificationIntervalMonths, LastVerificationDate)
            END
        ),
        ResourceHours int NULL,
        NextServiceDate date NULL,
        ServiceDurationHours tinyint NULL,
        InventoryDate date NULL,

        CountryId int NOT NULL,
        LastVerificationUserAccountId int NULL,

        WorkingTimeFrom time(0) NULL,
        WorkingTimeTo time(0) NULL,

        CriticalValuesTemplateId int NULL,
        NotificationTemplateId int NULL,

        ManagerUserAccountId int NULL,
        EngineerUserAccountId int NULL,
        TechnicianOperatorUserAccountId int NULL,

        KitOnlineCashRegisterId nvarchar(50) NULL,
        Notes nvarchar(1000) NULL,

        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_VendingMachine_CreatedAt DEFAULT (SYSDATETIME()),

        CONSTRAINT FK_VendingMachine_VendingMachineModel
            FOREIGN KEY (VendingMachineModelId)
            REFERENCES dbo.VendingMachineModel(VendingMachineModelId),
        CONSTRAINT FK_VendingMachine_WorkMode
            FOREIGN KEY (WorkModeId)
            REFERENCES dbo.WorkMode(WorkModeId),
        CONSTRAINT FK_VendingMachine_TimeZone
            FOREIGN KEY (TimeZoneId)
            REFERENCES dbo.TimeZone(TimeZoneId),
        CONSTRAINT FK_VendingMachine_VendingMachineStatus
            FOREIGN KEY (VendingMachineStatusId)
            REFERENCES dbo.VendingMachineStatus(VendingMachineStatusId),
        CONSTRAINT FK_VendingMachine_ServicePriority
            FOREIGN KEY (ServicePriorityId)
            REFERENCES dbo.ServicePriority(ServicePriorityId),
        CONSTRAINT FK_VendingMachine_ProductMatrix
            FOREIGN KEY (ProductMatrixId)
            REFERENCES dbo.ProductMatrix(ProductMatrixId),
        CONSTRAINT FK_VendingMachine_Company
            FOREIGN KEY (CompanyId)
            REFERENCES dbo.Company(CompanyId),
        CONSTRAINT FK_VendingMachine_Modem
            FOREIGN KEY (ModemId)
            REFERENCES dbo.Modem(ModemId),
        CONSTRAINT FK_VendingMachine_Country
            FOREIGN KEY (CountryId)
            REFERENCES dbo.Country(CountryId),
        CONSTRAINT FK_VendingMachine_LastVerificationUserAccount
            FOREIGN KEY (LastVerificationUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId),
        CONSTRAINT FK_VendingMachine_CriticalValuesTemplate
            FOREIGN KEY (CriticalValuesTemplateId)
            REFERENCES dbo.CriticalValuesTemplate(CriticalValuesTemplateId),
        CONSTRAINT FK_VendingMachine_NotificationTemplate
            FOREIGN KEY (NotificationTemplateId)
            REFERENCES dbo.NotificationTemplate(NotificationTemplateId),
        CONSTRAINT FK_VendingMachine_ManagerUserAccount
            FOREIGN KEY (ManagerUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId),
        CONSTRAINT FK_VendingMachine_EngineerUserAccount
            FOREIGN KEY (EngineerUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId),
        CONSTRAINT FK_VendingMachine_TechnicianOperatorUserAccount
            FOREIGN KEY (TechnicianOperatorUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId),

        /* Uniqueness */
        CONSTRAINT UQ_VendingMachine_ExternalId UNIQUE (ExternalId),
        CONSTRAINT UQ_VendingMachine_InventoryNumber UNIQUE (InventoryNumber),
        CONSTRAINT UQ_VendingMachine_SerialNumber UNIQUE (SerialNumber),

        /* SQL constraints from task statement */
        CONSTRAINT CK_VendingMachine_CommissioningDate_Range CHECK
        (
            CommissioningDate >= ManufactureDate
            AND CommissioningDate <= CAST(CreatedAt AS date)
        ),
        CONSTRAINT CK_VendingMachine_LastVerificationDate_Range CHECK
        (
            LastVerificationDate IS NULL
            OR
            (
                LastVerificationDate >= ManufactureDate
                AND LastVerificationDate <= CAST(GETDATE() AS date)
            )
        ),
        CONSTRAINT CK_VendingMachine_VerificationIntervalMonths_Positive CHECK
        (
            VerificationIntervalMonths IS NULL
            OR VerificationIntervalMonths > 0
        ),
        CONSTRAINT CK_VendingMachine_ResourceHours_Positive CHECK
        (
            ResourceHours IS NULL
            OR ResourceHours > 0
        ),
        CONSTRAINT CK_VendingMachine_NextServiceDate_AfterCreatedAt CHECK
        (
            NextServiceDate IS NULL
            OR NextServiceDate > CAST(CreatedAt AS date)
        ),
        CONSTRAINT CK_VendingMachine_ServiceDurationHours_Range CHECK
        (
            ServiceDurationHours IS NULL
            OR (ServiceDurationHours BETWEEN 1 AND 20)
        ),
        CONSTRAINT CK_VendingMachine_InventoryDate_Range CHECK
        (
            InventoryDate IS NULL
            OR
            (
                InventoryDate >= ManufactureDate
                AND InventoryDate <= CAST(GETDATE() AS date)
            )
        ),
        CONSTRAINT CK_VendingMachine_WorkingTime_Range CHECK
        (
            WorkingTimeFrom IS NULL
            OR WorkingTimeTo IS NULL
            OR WorkingTimeFrom < WorkingTimeTo
        ),
        CONSTRAINT CK_VendingMachine_Latitude_Range CHECK
        (
            Latitude IS NULL
            OR (Latitude BETWEEN -90 AND 90)
        ),
        CONSTRAINT CK_VendingMachine_Longitude_Range CHECK
        (
            Longitude IS NULL
            OR (Longitude BETWEEN -180 AND 180)
        )
    );
END
GO

/* =========================
   Schema upgrades (safe re-run)
   ========================= */

-- Добавляем внешний GUID для торгового автомата, если таблица уже существует (например, БД создана ранее).
IF OBJECT_ID(N'dbo.VendingMachine', N'U') IS NOT NULL AND COL_LENGTH('dbo.VendingMachine', 'ExternalId') IS NULL
BEGIN
    ALTER TABLE dbo.VendingMachine ADD ExternalId uniqueidentifier NULL;
END
GO

-- Важно: делаем отдельными batch, чтобы SQL Server корректно "увидел" новый столбец.
IF OBJECT_ID(N'dbo.VendingMachine', N'U') IS NOT NULL AND COL_LENGTH('dbo.VendingMachine', 'ExternalId') IS NOT NULL
BEGIN
    UPDATE dbo.VendingMachine
    SET ExternalId = NEWID()
    WHERE ExternalId IS NULL;
END
GO

IF OBJECT_ID(N'dbo.VendingMachine', N'U') IS NOT NULL
   AND EXISTS
   (
       SELECT 1
       FROM sys.columns
       WHERE object_id = OBJECT_ID(N'dbo.VendingMachine')
         AND name = N'ExternalId'
         AND is_nullable = 1
   )
BEGIN
    ALTER TABLE dbo.VendingMachine ALTER COLUMN ExternalId uniqueidentifier NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.VendingMachine', N'U') IS NOT NULL
   AND OBJECT_ID(N'DF_VendingMachine_ExternalId', N'D') IS NULL
BEGIN
    ALTER TABLE dbo.VendingMachine
        ADD CONSTRAINT DF_VendingMachine_ExternalId DEFAULT (NEWID()) FOR ExternalId;
END
GO

IF OBJECT_ID(N'dbo.VendingMachine', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.key_constraints
       WHERE [type] = 'UQ'
         AND parent_object_id = OBJECT_ID(N'dbo.VendingMachine')
         AND name = N'UQ_VendingMachine_ExternalId'
   )
BEGIN
    ALTER TABLE dbo.VendingMachine
        ADD CONSTRAINT UQ_VendingMachine_ExternalId UNIQUE (ExternalId);
END
GO

IF OBJECT_ID(N'dbo.VendingMachinePaymentSystem', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachinePaymentSystem
    (
        VendingMachineId int NOT NULL,
        PaymentSystemId int NOT NULL,
        CONSTRAINT PK_VendingMachinePaymentSystem PRIMARY KEY (VendingMachineId, PaymentSystemId),
        CONSTRAINT FK_VendingMachinePaymentSystem_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_VendingMachinePaymentSystem_PaymentSystem
            FOREIGN KEY (PaymentSystemId)
            REFERENCES dbo.PaymentSystem(PaymentSystemId)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineRfidCard', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineRfidCard
    (
        VendingMachineId int NOT NULL,
        RfidCardId int NOT NULL,
        RfidCardTypeId int NOT NULL,
        CONSTRAINT PK_VendingMachineRfidCard PRIMARY KEY (VendingMachineId, RfidCardId, RfidCardTypeId),
        CONSTRAINT FK_VendingMachineRfidCard_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_VendingMachineRfidCard_RfidCard
            FOREIGN KEY (RfidCardId)
            REFERENCES dbo.RfidCard(RfidCardId),
        CONSTRAINT FK_VendingMachineRfidCard_RfidCardType
            FOREIGN KEY (RfidCardTypeId)
            REFERENCES dbo.RfidCardType(RfidCardTypeId)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineProduct', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineProduct
    (
        VendingMachineId int NOT NULL,
        ProductId int NOT NULL,
        QuantityOnHand int NOT NULL,
        MinimumStock int NOT NULL,
        AverageDailySales decimal(10,2) NULL,
        UpdatedAt datetime2(0) NOT NULL CONSTRAINT DF_VendingMachineProduct_UpdatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_VendingMachineProduct PRIMARY KEY (VendingMachineId, ProductId),
        CONSTRAINT FK_VendingMachineProduct_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_VendingMachineProduct_Product
            FOREIGN KEY (ProductId)
            REFERENCES dbo.Product(ProductId),
        CONSTRAINT CK_VendingMachineProduct_QuantityOnHand_NonNegative CHECK (QuantityOnHand >= 0),
        CONSTRAINT CK_VendingMachineProduct_MinimumStock_NonNegative CHECK (MinimumStock >= 0),
        CONSTRAINT CK_VendingMachineProduct_AverageDailySales_NonNegative CHECK (AverageDailySales IS NULL OR AverageDailySales >= 0)
    );
END
GO

IF OBJECT_ID(N'dbo.Sale', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Sale
    (
        SaleId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sale PRIMARY KEY,
        VendingMachineId int NOT NULL,
        ProductId int NOT NULL,
        Quantity int NOT NULL,
        TotalAmount decimal(18,2) NOT NULL,
        SoldAt datetime2(0) NOT NULL CONSTRAINT DF_Sale_SoldAt DEFAULT (SYSDATETIME()),
        SalePaymentMethodId int NOT NULL,
        CONSTRAINT FK_Sale_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_Sale_Product
            FOREIGN KEY (ProductId)
            REFERENCES dbo.Product(ProductId),
        CONSTRAINT FK_Sale_SalePaymentMethod
            FOREIGN KEY (SalePaymentMethodId)
            REFERENCES dbo.SalePaymentMethod(SalePaymentMethodId),
        CONSTRAINT CK_Sale_Quantity_Positive CHECK (Quantity > 0),
        CONSTRAINT CK_Sale_TotalAmount_NonNegative CHECK (TotalAmount >= 0)
    );
END
GO

IF OBJECT_ID(N'dbo.Maintenance', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Maintenance
    (
        MaintenanceId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Maintenance PRIMARY KEY,
        VendingMachineId int NOT NULL,
        MaintenanceDate date NOT NULL,
        WorkDescription nvarchar(1000) NULL,
        Problems nvarchar(1000) NULL,
        ExecutorUserAccountId int NULL,
        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_Maintenance_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Maintenance_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_Maintenance_ExecutorUserAccount
            FOREIGN KEY (ExecutorUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId)
    );
END
GO

IF OBJECT_ID(N'dbo.ServiceRequest', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceRequest
    (
        ServiceRequestId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ServiceRequest PRIMARY KEY,
        VendingMachineId int NOT NULL,
        ServiceRequestTypeId int NOT NULL,
        ServiceRequestStatusId int NOT NULL,
        PlannedDate date NOT NULL,
        AssignedUserAccountId int NULL,
        SortOrder int NULL,
        Notes nvarchar(1000) NULL,
        DeclineReason nvarchar(500) NULL,
        CreatedAt datetime2(0) NOT NULL CONSTRAINT DF_ServiceRequest_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_ServiceRequest_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_ServiceRequest_ServiceRequestType
            FOREIGN KEY (ServiceRequestTypeId)
            REFERENCES dbo.ServiceRequestType(ServiceRequestTypeId),
        CONSTRAINT FK_ServiceRequest_ServiceRequestStatus
            FOREIGN KEY (ServiceRequestStatusId)
            REFERENCES dbo.ServiceRequestStatus(ServiceRequestStatusId),
        CONSTRAINT FK_ServiceRequest_AssignedUserAccount
            FOREIGN KEY (AssignedUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId)
    );
END
GO

IF OBJECT_ID(N'dbo.ServiceRequestStatusHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ServiceRequestStatusHistory
    (
        ServiceRequestStatusHistoryId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ServiceRequestStatusHistory PRIMARY KEY,
        ServiceRequestId int NOT NULL,
        ServiceRequestStatusId int NOT NULL,
        ChangedByUserAccountId int NULL,
        ChangedAt datetime2(0) NOT NULL CONSTRAINT DF_ServiceRequestStatusHistory_ChangedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_ServiceRequestStatusHistory_ServiceRequest
            FOREIGN KEY (ServiceRequestId)
            REFERENCES dbo.ServiceRequest(ServiceRequestId),
        CONSTRAINT FK_ServiceRequestStatusHistory_ServiceRequestStatus
            FOREIGN KEY (ServiceRequestStatusId)
            REFERENCES dbo.ServiceRequestStatus(ServiceRequestStatusId),
        CONSTRAINT FK_ServiceRequestStatusHistory_UserAccount
            FOREIGN KEY (ChangedByUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineEquipment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineEquipment
    (
        VendingMachineId int NOT NULL,
        EquipmentTypeId int NOT NULL,
        IsOperational bit NOT NULL,
        UpdatedAt datetime2(0) NOT NULL CONSTRAINT DF_VendingMachineEquipment_UpdatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_VendingMachineEquipment PRIMARY KEY (VendingMachineId, EquipmentTypeId),
        CONSTRAINT FK_VendingMachineEquipment_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_VendingMachineEquipment_EquipmentType
            FOREIGN KEY (EquipmentTypeId)
            REFERENCES dbo.EquipmentType(EquipmentTypeId)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineEvent', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineEvent
    (
        VendingMachineEventId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_VendingMachineEvent PRIMARY KEY,
        VendingMachineId int NOT NULL,
        EventTypeId int NOT NULL,
        OccurredAt datetime2(0) NOT NULL CONSTRAINT DF_VendingMachineEvent_OccurredAt DEFAULT (SYSDATETIME()),
        Message nvarchar(500) NULL,
        CONSTRAINT FK_VendingMachineEvent_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_VendingMachineEvent_EventType
            FOREIGN KEY (EventTypeId)
            REFERENCES dbo.EventType(EventTypeId)
    );
END
GO

IF OBJECT_ID(N'dbo.VendingMachineStatusHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.VendingMachineStatusHistory
    (
        VendingMachineStatusHistoryId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_VendingMachineStatusHistory PRIMARY KEY,
        VendingMachineId int NOT NULL,
        VendingMachineStatusId int NOT NULL,
        ChangedByUserAccountId int NULL,
        ChangedAt datetime2(0) NOT NULL CONSTRAINT DF_VendingMachineStatusHistory_ChangedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_VendingMachineStatusHistory_VendingMachine
            FOREIGN KEY (VendingMachineId)
            REFERENCES dbo.VendingMachine(VendingMachineId),
        CONSTRAINT FK_VendingMachineStatusHistory_VendingMachineStatus
            FOREIGN KEY (VendingMachineStatusId)
            REFERENCES dbo.VendingMachineStatus(VendingMachineStatusId),
        CONSTRAINT FK_VendingMachineStatusHistory_UserAccount
            FOREIGN KEY (ChangedByUserAccountId)
            REFERENCES dbo.UserAccount(UserAccountId)
    );
END
GO
/* =========================
   Views (derived data)
   ========================= */

IF OBJECT_ID(N'dbo.VendingMachineIncome', N'V') IS NULL
BEGIN
    EXEC(N'
        CREATE VIEW dbo.VendingMachineIncome
        AS
        SELECT
            vm.VendingMachineId,
            SUM(s.TotalAmount) AS TotalIncome
        FROM dbo.VendingMachine vm
        LEFT JOIN dbo.Sale s ON s.VendingMachineId = vm.VendingMachineId
        GROUP BY vm.VendingMachineId;
    ');
END
GO

/* =========================
   Seed data (lookups)
   ========================= */

MERGE dbo.Country AS target
USING (VALUES
    (N'Россия', N'RU')
) AS source (Name, IsoCode)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, IsoCode) VALUES (source.Name, source.IsoCode)
WHEN MATCHED THEN
    UPDATE SET IsoCode = source.IsoCode;
GO

MERGE dbo.TimeZone AS target
USING (VALUES
    (N'UTC+3', CAST(180 AS smallint)),
    (N'UTC+0', CAST(0 AS smallint))
) AS source (Name, UtcOffsetMinutes)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, UtcOffsetMinutes) VALUES (source.Name, source.UtcOffsetMinutes)
WHEN MATCHED AND target.UtcOffsetMinutes <> source.UtcOffsetMinutes THEN
    UPDATE SET UtcOffsetMinutes = source.UtcOffsetMinutes;
GO

MERGE dbo.WorkMode AS target
USING (VALUES
    (N'Стандартный')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.ServicePriority AS target
USING (VALUES
    (N'Низкий', 10),
    (N'Средний', 20),
    (N'Высокий', 30)
) AS source (Name, SortOrder)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, SortOrder) VALUES (source.Name, source.SortOrder)
WHEN MATCHED AND target.SortOrder <> source.SortOrder THEN
    UPDATE SET SortOrder = source.SortOrder;
GO

MERGE dbo.VendingMachineStatus AS target
USING (VALUES
    (N'Работает', 10),
    (N'Вышел из строя', 20),
    (N'В ремонте/на обслуживании', 30)
) AS source (Name, SortOrder)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, SortOrder) VALUES (source.Name, source.SortOrder)
WHEN MATCHED AND target.SortOrder <> source.SortOrder THEN
    UPDATE SET SortOrder = source.SortOrder;
GO

MERGE dbo.ServiceRequestType AS target
USING (VALUES
    (N'Плановое техническое обслуживание'),
    (N'Аварийное обслуживание')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.ServiceRequestStatus AS target
USING (VALUES
    (N'Авария', 5),
    (N'Новая', 10),
    (N'В работе', 20),
    (N'Отменена', 30),
    (N'Закрыта', 40)
) AS source (Name, SortOrder)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, SortOrder) VALUES (source.Name, source.SortOrder)
WHEN MATCHED AND target.SortOrder <> source.SortOrder THEN
    UPDATE SET SortOrder = source.SortOrder;
GO

MERGE dbo.ProductMatrix AS target
USING (VALUES
    (N'Не установлена', NULL)
) AS source (Name, Description)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, Description) VALUES (source.Name, source.Description);
GO

MERGE dbo.CriticalValuesTemplate AS target
USING (VALUES
    (N'Не установлен', NULL)
) AS source (Name, Description)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, Description) VALUES (source.Name, source.Description);
GO

MERGE dbo.NotificationTemplate AS target
USING (VALUES
    (N'Не установлен', NULL)
) AS source (Name, Description)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, Description) VALUES (source.Name, source.Description);
GO

MERGE dbo.PaymentSystem AS target
USING (VALUES
    (N'Монетоприемник'),
    (N'Купюроприемник'),
    (N'Модуль безналичной оплаты'),
    (N'QR-платежи')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.RfidCardType AS target
USING (VALUES
    (N'Обслуживание'),
    (N'Инкассация'),
    (N'Загрузка')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.SalePaymentMethod AS target
USING (VALUES
    (N'Наличные'),
    (N'Карта'),
    (N'QR')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.UserRole AS target
USING (VALUES
    (N'Администратор'),
    (N'Оператор'),
    (N'Менеджер'),
    (N'Инженер'),
    (N'Техник-оператор')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.Provider AS target
USING (VALUES
    (N'Не указан')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.ConnectionType AS target
USING (VALUES
    (N'MDB'),
    (N'EXE PH'),
    (N'EXE ST'),
    (N'Не указан')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.EventSeverity AS target
USING (VALUES
    (N'Критическая', 10),
    (N'Предупреждение', 20),
    (N'Информация', 30)
) AS source (Name, SortOrder)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, SortOrder) VALUES (source.Name, source.SortOrder)
WHEN MATCHED AND target.SortOrder <> source.SortOrder THEN
    UPDATE SET SortOrder = source.SortOrder;
GO

MERGE dbo.EventType AS target
USING
(
    SELECT es.EventSeverityId, v.Name
    FROM (VALUES
        (N'Критическая', N'Нет сдачи'),
        (N'Критическая', N'Замятие товара'),
        (N'Критическая', N'Перегрев'),
        (N'Предупреждение', N'Низкий запас товара'),
        (N'Предупреждение', N'Необходимость обслуживания'),
        (N'Информация', N'Успешная оплата'),
        (N'Информация', N'Выдача товара')
    ) AS v(SeverityName, Name)
    INNER JOIN dbo.EventSeverity es ON es.Name = v.SeverityName
) AS source (EventSeverityId, Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (EventSeverityId, Name) VALUES (source.EventSeverityId, source.Name);
GO

MERGE dbo.VendingMachineManufacturer AS target
USING (VALUES
    (N'Necta'),
    (N'Saeco'),
    (N'Bianchi'),
    (N'Unicum'),
    (N'Rheavendors'),
    (N'FAS'),
    (N'Jofemar')
) AS source (Name)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name) VALUES (source.Name);
GO

MERGE dbo.VendingMachineModel AS target
USING
(
    SELECT m.VendingMachineManufacturerId, v.Name
    FROM (VALUES
        (N'Saeco', N'Cristallo 400'),
        (N'Unicum', N'Rosso'),
        (N'Bianchi', N'BVM 972'),
        (N'Necta', N'Kikko Max'),
        (N'Rheavendors', N'Luce ES'),
        (N'FAS', N'Perla'),
        (N'Jofemar', N'Coffeemar G250'),
        (N'Necta', N'Kikko ES6'),
        (N'Unicum', N'Food Box')
    ) AS v(ManufacturerName, Name)
    INNER JOIN dbo.VendingMachineManufacturer m ON m.Name = v.ManufacturerName
) AS source (VendingMachineManufacturerId, Name)
ON target.VendingMachineManufacturerId = source.VendingMachineManufacturerId AND target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (VendingMachineManufacturerId, Name) VALUES (source.VendingMachineManufacturerId, source.Name);
GO

MERGE dbo.Company AS target
USING (VALUES
    (N'ООО Торговые Автоматы', NULL, NULL, NULL)
) AS source (Name, Phone, Email, Address)
ON target.Name = source.Name
WHEN NOT MATCHED THEN
    INSERT (Name, Phone, Email, Address) VALUES (source.Name, source.Phone, source.Email, source.Address);
GO
