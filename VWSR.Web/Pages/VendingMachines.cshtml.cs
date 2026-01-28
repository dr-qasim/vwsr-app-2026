using System.Globalization;
using System.Linq;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using ExcelDataReader;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using VWSR.Web.Infrastructure;

namespace VWSR.Web.Pages;

public sealed class VendingMachinesModel : PageModel
{
    // Кэш токена, чтобы не логиниться перед каждой строкой.
    private static string? _cachedToken;
    private static DateTime _tokenExpiresAt;

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly JsonSerializerOptions _jsonOptions;

    public VendingMachinesModel(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };
        _jsonOptions.Converters.Add(new DateOnlyJsonConverter());
    }

    [BindProperty]
    public IFormFile? UploadFile { get; set; }

    public string? Message { get; private set; }
    public int TotalCount { get; private set; }
    public int SuccessCount { get; private set; }
    public int ErrorCount => Errors.Count;
    public List<RowError> Errors { get; } = new();

    public async Task OnPostAsync()
    {
        // Основная логика импорта после загрузки файла.
        Errors.Clear();
        Message = null;
        TotalCount = 0;
        SuccessCount = 0;

        if (UploadFile == null || UploadFile.Length == 0)
        {
            Message = "Файл не выбран.";
            return;
        }

        var ext = Path.GetExtension(UploadFile.FileName).ToLowerInvariant();
        if (ext != ".csv" && ext != ".xlsx")
        {
            Message = "Нужен файл CSV или XLSX.";
            return;
        }

        // Читаем файл в список строк (словарь: колонка -> значение).
        var rows = ext == ".csv"
            ? await ReadCsvAsync(UploadFile)
            : ReadXlsx(UploadFile);

        if (rows.Count <= 1)
        {
            Message = "Файл пустой или неверный формат.";
            return;
        }

        TotalCount = rows.Count - 1;

        // Проверяем, что минимум 6 обязательных полей есть в заголовке.
        var header = rows[0];
        var columnMap = BuildColumnMap(header);
        var requiredColumns = new[]
        {
            "Name",
            "ModelId",
            "CompanyId",
            "Address",
            "Place",
            "InventoryNumber"
        };

        foreach (var col in requiredColumns)
        {
            if (!columnMap.ContainsKey(col))
            {
                Message = $"Нет обязательной колонки: {col}";
                return;
            }
        }

        // Проверка на дубли внутри файла.
        var inventoryNumbers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var serialNumbers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // Грузим строки с 1 (в данных), т.к. 0 - это заголовок.
        for (var i = 1; i < rows.Count; i++)
        {
            var row = rows[i];
            var rowNumber = i + 1; // для пользователя (1 - заголовок)

            var validationError = ValidateRow(row, columnMap, inventoryNumbers, serialNumbers);
            if (!string.IsNullOrWhiteSpace(validationError))
            {
                Errors.Add(new RowError(rowNumber, validationError));
                continue;
            }

            // Пытаемся отправить в БД через API.
            var created = await TryCreateMachineAsync(row, columnMap);
            if (!created.Success)
            {
                Errors.Add(new RowError(rowNumber, created.ErrorMessage ?? "Ошибка при сохранении в БД (API)."));
                continue;
            }

            SuccessCount++;
        }

        Message = Errors.Count == 0
            ? "Импорт завершен без ошибок."
            : "Импорт выполнен частично. Смотрите ошибки ниже.";
    }

    private async Task<CreateResult> TryCreateMachineAsync(Dictionary<string, string> row, Dictionary<string, int> map)
    {
        var client = _httpClientFactory.CreateClient("api");
        var token = await GetTokenAsync(client);
        if (string.IsNullOrWhiteSpace(token))
        {
            return CreateResult.Fail("Не удалось получить токен API.");
        }

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Берем обязательные значения из файла.
        var name = GetValue(row, map, "Name");
        var modelId = int.Parse(GetValue(row, map, "ModelId"), CultureInfo.InvariantCulture);
        var companyId = int.Parse(GetValue(row, map, "CompanyId"), CultureInfo.InvariantCulture);
        var address = GetValue(row, map, "Address");
        var place = GetValue(row, map, "Place");
        var inventoryNumber = GetValue(row, map, "InventoryNumber");
        var serialNumber = TryGetValue(row, map, "SerialNumber") ?? $"SN-{Guid.NewGuid():N}".Substring(0, 10);

        // Остальные поля - простые дефолты (чтобы новичок не писал много кода).
        var defaults = _configuration.GetSection("Api:Defaults");
        var request = new VendingMachineCreateRequest
        {
            Name = name,
            VendingMachineModelId = modelId,
            WorkModeId = defaults.GetValue("WorkModeId", 1),
            TimeZoneId = defaults.GetValue("TimeZoneId", 1),
            VendingMachineStatusId = defaults.GetValue("VendingMachineStatusId", 1),
            ServicePriorityId = defaults.GetValue("ServicePriorityId", 1),
            ProductMatrixId = defaults.GetValue("ProductMatrixId", 1),
            CompanyId = companyId,
            ModemId = null,
            Address = address,
            Place = place,
            InventoryNumber = inventoryNumber,
            SerialNumber = serialNumber,
            ManufactureDate = DateOnly.FromDateTime(DateTime.Today),
            CommissioningDate = DateOnly.FromDateTime(DateTime.Today),
            LastVerificationDate = null,
            VerificationIntervalMonths = null,
            ResourceHours = null,
            NextServiceDate = null,
            ServiceDurationHours = null,
            InventoryDate = null,
            CountryId = defaults.GetValue("CountryId", 1),
            LastVerificationUserAccountId = null,
            Notes = null
        };

        var response = await client.PostAsJsonAsync("api/vending-machines", request, _jsonOptions);
        if (response.IsSuccessStatusCode)
        {
            return CreateResult.Ok();
        }

        if (response.StatusCode == System.Net.HttpStatusCode.Conflict)
        {
            return CreateResult.Fail("Дубликат в БД (серийный или инвентарный номер).");
        }

        return CreateResult.Fail("Ошибка при сохранении в БД (API).");
    }

    private async Task<string?> GetTokenAsync(HttpClient client)
    {
        // Если токен еще живой - используем его.
        if (!string.IsNullOrWhiteSpace(_cachedToken) && _tokenExpiresAt > DateTime.UtcNow.AddMinutes(1))
        {
            return _cachedToken;
        }

        var email = _configuration["Api:UserEmail"];
        var password = _configuration["Api:UserPassword"];
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            return null;
        }

        // Авторизация в API для получения JWT.
        var response = await client.PostAsJsonAsync("api/auth/login", new { email, password });
        if (!response.IsSuccessStatusCode)
        {
            return null;
        }

        var body = await response.Content.ReadAsStringAsync();
        var login = JsonSerializer.Deserialize<LoginResponse>(body, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        if (login == null)
        {
            return null;
        }

        _cachedToken = login.AccessToken;
        _tokenExpiresAt = DateTime.UtcNow.AddMinutes(20);
        return _cachedToken;
    }

    private static string? ValidateRow(
        Dictionary<string, string> row,
        Dictionary<string, int> map,
        HashSet<string> inventoryNumbers,
        HashSet<string> serialNumbers)
    {
        // Минимум 6 полей: Name, ModelId, CompanyId, Address, Place, InventoryNumber.
        var required = new[]
        {
            "Name", "ModelId", "CompanyId", "Address", "Place", "InventoryNumber"
        };

        foreach (var col in required)
        {
            var value = TryGetValue(row, map, col);
            if (string.IsNullOrWhiteSpace(value))
            {
                return $"Пустое обязательное поле: {col}";
            }
        }

        if (!int.TryParse(GetValue(row, map, "ModelId"), out _))
        {
            return "ModelId должен быть числом.";
        }

        if (!int.TryParse(GetValue(row, map, "CompanyId"), out _))
        {
            return "CompanyId должен быть числом.";
        }

        var inventory = GetValue(row, map, "InventoryNumber");
        if (!inventoryNumbers.Add(inventory))
        {
            return "Дубликат инвентарного номера в файле.";
        }

        var serial = TryGetValue(row, map, "SerialNumber");
        if (!string.IsNullOrWhiteSpace(serial))
        {
            if (!serialNumbers.Add(serial))
            {
                return "Дубликат серийного номера в файле.";
            }
        }

        return null;
    }

    private static Dictionary<string, int> BuildColumnMap(Dictionary<string, string> headerRow)
    {
        // Нормализуем названия колонок, поддерживаем RU/EN.
        var map = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        foreach (var cell in headerRow.OrderBy(h => int.Parse(h.Key, CultureInfo.InvariantCulture)))
        {
            var key = NormalizeHeader(cell.Value);
            if (!string.IsNullOrWhiteSpace(key) && !map.ContainsKey(key))
            {
                map[key] = int.Parse(cell.Key, CultureInfo.InvariantCulture);
            }
        }

        return map;
    }

    private static string NormalizeHeader(string header)
    {
        var h = header.Trim().Trim('\uFEFF').ToLowerInvariant();
        return h switch
        {
            "name" or "название" => "Name",
            "modelid" or "модельid" or "модель" => "ModelId",
            "companyid" or "компанияid" or "компания" => "CompanyId",
            "address" or "адрес" => "Address",
            "place" or "место" => "Place",
            "inventorynumber" or "инвентарныйномер" or "инвентарный номер" => "InventoryNumber",
            "serialnumber" or "серийныйномер" or "серийный номер" => "SerialNumber",
            _ => string.Empty
        };
    }

    private static string GetValue(Dictionary<string, string> row, Dictionary<string, int> map, string key)
    {
        return TryGetValue(row, map, key) ?? string.Empty;
    }

    private static string? TryGetValue(Dictionary<string, string> row, Dictionary<string, int> map, string key)
    {
        if (!map.TryGetValue(key, out var index))
        {
            return null;
        }

        return row.TryGetValue(index.ToString(CultureInfo.InvariantCulture), out var value)
            ? value
            : null;
    }

    private static async Task<List<Dictionary<string, string>>> ReadCsvAsync(IFormFile file)
    {
        var rows = new List<Dictionary<string, string>>();

        await using var stream = file.OpenReadStream();
        using var reader = new StreamReader(stream, Encoding.UTF8, true);

        var headerLine = await reader.ReadLineAsync();
        if (string.IsNullOrWhiteSpace(headerLine))
        {
            return rows;
        }

        var delimiter = headerLine.Contains(';') ? ';' : ',';
        var headers = SplitCsvLine(headerLine, delimiter);
        rows.Add(ToRow(headers));

        string? line;
        while ((line = await reader.ReadLineAsync()) != null)
        {
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            var values = SplitCsvLine(line, delimiter);
            rows.Add(ToRow(values));
        }

        return rows;
    }

    private static List<Dictionary<string, string>> ReadXlsx(IFormFile file)
    {
        // ExcelDataReader требует регистрацию кодировок.
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);

        using var stream = file.OpenReadStream();
        using var reader = ExcelReaderFactory.CreateReader(stream);
        var dataSet = reader.AsDataSet();

        if (dataSet.Tables.Count == 0)
        {
            return new List<Dictionary<string, string>>();
        }

        var table = dataSet.Tables[0];
        if (table.Rows.Count == 0)
        {
            return new List<Dictionary<string, string>>();
        }

        var rows = new List<Dictionary<string, string>>();
        for (var r = 0; r < table.Rows.Count; r++)
        {
            var dict = new Dictionary<string, string>();
            for (var c = 0; c < table.Columns.Count; c++)
            {
                dict[c.ToString(CultureInfo.InvariantCulture)] = table.Rows[r][c]?.ToString()?.Trim() ?? string.Empty;
            }

            rows.Add(dict);
        }

        return rows;
    }

    private static Dictionary<string, string> ToRow(IReadOnlyList<string> values)
    {
        var dict = new Dictionary<string, string>();
        for (var i = 0; i < values.Count; i++)
        {
            dict[i.ToString(CultureInfo.InvariantCulture)] = values[i].Trim();
        }

        return dict;
    }

    private static List<string> SplitCsvLine(string line, char delimiter)
    {
        // Простая разбивка без сложных кавычек (достаточно для требований).
        return line.Split(delimiter).Select(v => v.Trim()).ToList();
    }

    private sealed class LoginResponse
    {
        public string AccessToken { get; set; } = string.Empty;
    }

    private sealed record CreateResult(bool Success, string? ErrorMessage)
    {
        public static CreateResult Ok() => new(true, null);
        public static CreateResult Fail(string message) => new(false, message);
    }

    public sealed record RowError(int RowNumber, string Message);

    private sealed class VendingMachineCreateRequest
    {
        public string Name { get; set; } = string.Empty;
        public int VendingMachineModelId { get; set; }
        public int WorkModeId { get; set; }
        public int TimeZoneId { get; set; }
        public int VendingMachineStatusId { get; set; }
        public int ServicePriorityId { get; set; }
        public int ProductMatrixId { get; set; }
        public int? CompanyId { get; set; }
        public int? ModemId { get; set; }
        public string Address { get; set; } = string.Empty;
        public string Place { get; set; } = string.Empty;
        public string InventoryNumber { get; set; } = string.Empty;
        public string SerialNumber { get; set; } = string.Empty;
        public DateOnly ManufactureDate { get; set; }
        public DateOnly CommissioningDate { get; set; }
        public DateOnly? LastVerificationDate { get; set; }
        public int? VerificationIntervalMonths { get; set; }
        public int? ResourceHours { get; set; }
        public DateOnly? NextServiceDate { get; set; }
        public byte? ServiceDurationHours { get; set; }
        public DateOnly? InventoryDate { get; set; }
        public int CountryId { get; set; }
        public int? LastVerificationUserAccountId { get; set; }
        public string? Notes { get; set; }
    }
}
