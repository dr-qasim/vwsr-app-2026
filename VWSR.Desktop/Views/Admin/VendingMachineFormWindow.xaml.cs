using System;
using System.Globalization;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;

namespace VWSR.Desktop;

public partial class VendingMachineFormWindow : Window
{
    private readonly HttpClient _httpClient = new();
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };
    private readonly VendingMachineDetail? _detail;

    public VendingMachineFormWindow(VendingMachineDetail? detail)
    {
        InitializeComponent();
        _detail = detail;

        FillDefaults();
        if (_detail != null)
        {
            FillFromDetail(_detail);
        }
    }

    private void FillDefaults()
    {
        // Заполняем дефолты, чтобы меньше руками вводить.
        ModelIdBox.Text = "1";
        WorkModeIdBox.Text = "1";
        TimeZoneIdBox.Text = "1";
        StatusIdBox.Text = "1";
        ServicePriorityIdBox.Text = "1";
        ProductMatrixIdBox.Text = "1";
        CountryIdBox.Text = "1";
        ModemIdBox.Text = "-1";
        ManufactureDateBox.Text = DateTime.Today.ToString("dd.MM.yyyy");
        CommissioningDateBox.Text = DateTime.Today.ToString("dd.MM.yyyy");
    }

    private void FillFromDetail(VendingMachineDetail detail)
    {
        Title = "Редактирование ТА";
        NameBox.Text = detail.Name;
        ModelIdBox.Text = detail.VendingMachineModelId.ToString();
        WorkModeIdBox.Text = detail.WorkModeId.ToString();
        TimeZoneIdBox.Text = detail.TimeZoneId.ToString();
        StatusIdBox.Text = detail.VendingMachineStatusId.ToString();
        ServicePriorityIdBox.Text = detail.ServicePriorityId.ToString();
        ProductMatrixIdBox.Text = detail.ProductMatrixId.ToString();
        CompanyIdBox.Text = detail.CompanyId?.ToString() ?? string.Empty;
        ModemIdBox.Text = detail.ModemId.ToString();
        AddressBox.Text = detail.Address;
        PlaceBox.Text = detail.Place;
        InventoryNumberBox.Text = detail.InventoryNumber;
        SerialNumberBox.Text = detail.SerialNumber;
        ManufactureDateBox.Text = detail.ManufactureDate.ToString("dd.MM.yyyy");
        CommissioningDateBox.Text = detail.CommissioningDate.ToString("dd.MM.yyyy");
        LastVerificationDateBox.Text = detail.LastVerificationDate?.ToString("dd.MM.yyyy") ?? string.Empty;
        VerificationIntervalBox.Text = detail.VerificationIntervalMonths?.ToString() ?? string.Empty;
        ResourceHoursBox.Text = detail.ResourceHours?.ToString() ?? string.Empty;
        NextServiceDateBox.Text = detail.NextServiceDate?.ToString("dd.MM.yyyy") ?? string.Empty;
        ServiceDurationBox.Text = detail.ServiceDurationHours?.ToString() ?? string.Empty;
        InventoryDateBox.Text = detail.InventoryDate?.ToString("dd.MM.yyyy") ?? string.Empty;
        CountryIdBox.Text = detail.CountryId.ToString();
        LastVerificationUserBox.Text = detail.LastVerificationUserAccountId?.ToString() ?? string.Empty;
        NotesBox.Text = detail.Notes ?? string.Empty;
    }

    private async void Save_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            var request = BuildRequest();
            if (request == null)
            {
                return;
            }

            if (_detail == null)
            {
                await CreateMachine(request);
            }
            else
            {
                await UpdateMachine(_detail.Id, request);
            }

            DialogResult = true;
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }

    private VendingMachineCreateRequest? BuildRequest()
    {
        // Простой парсинг полей формы.
        if (string.IsNullOrWhiteSpace(NameBox.Text))
        {
            MessageBox.Show("Введите название.");
            return null;
        }

        if (!int.TryParse(ModelIdBox.Text, out var modelId))
        {
            MessageBox.Show("Проверьте Модель ID.");
            return null;
        }

        var workModeId = ParseInt(WorkModeIdBox.Text);
        var timeZoneId = ParseInt(TimeZoneIdBox.Text);
        var statusId = ParseInt(StatusIdBox.Text);
        var priorityId = ParseInt(ServicePriorityIdBox.Text);
        var matrixId = ParseInt(ProductMatrixIdBox.Text);
        var companyId = ParseNullableInt(CompanyIdBox.Text);
        var modemId = ParseNullableInt(ModemIdBox.Text);
        var countryId = ParseInt(CountryIdBox.Text);

        var manufactureDate = ParseDate(ManufactureDateBox.Text) ?? DateOnly.FromDateTime(DateTime.Today);
        var commissioningDate = ParseDate(CommissioningDateBox.Text) ?? manufactureDate;
        var lastVerificationDate = ParseDate(LastVerificationDateBox.Text);
        var nextServiceDate = ParseDate(NextServiceDateBox.Text);
        var inventoryDate = ParseDate(InventoryDateBox.Text);

        var verificationInterval = ParseNullableInt(VerificationIntervalBox.Text);
        var resourceHours = ParseNullableInt(ResourceHoursBox.Text);
        var serviceDuration = ParseNullableByte(ServiceDurationBox.Text);
        var lastVerificationUser = ParseNullableInt(LastVerificationUserBox.Text);

        return new VendingMachineCreateRequest(
            NameBox.Text.Trim(),
            modelId,
            workModeId,
            timeZoneId,
            statusId,
            priorityId,
            matrixId,
            companyId,
            modemId,
            AddressBox.Text.Trim(),
            PlaceBox.Text.Trim(),
            InventoryNumberBox.Text.Trim(),
            SerialNumberBox.Text.Trim(),
            manufactureDate,
            commissioningDate,
            lastVerificationDate,
            verificationInterval,
            resourceHours,
            nextServiceDate,
            serviceDuration,
            inventoryDate,
            countryId,
            lastVerificationUser,
            NotesBox.Text.Trim());
    }

    private async Task CreateMachine(VendingMachineCreateRequest request)
    {
        using var http = new HttpRequestMessage(HttpMethod.Post, Session.GetApiUrl("api/vending-machines"));
        ApplyAuth(http);
        http.Content = new StringContent(JsonSerializer.Serialize(request), Encoding.UTF8, "application/json");

        var response = await _httpClient.SendAsync(http);
        if (!response.IsSuccessStatusCode)
        {
            MessageBox.Show("Не удалось создать ТА.");
        }
    }

    private async Task UpdateMachine(Guid id, VendingMachineCreateRequest request)
    {
        var update = new VendingMachineUpdateRequest(
            request.Name,
            request.VendingMachineModelId,
            request.WorkModeId,
            request.TimeZoneId,
            request.VendingMachineStatusId,
            request.ServicePriorityId,
            request.ProductMatrixId,
            request.CompanyId,
            request.ModemId,
            request.Address,
            request.Place,
            request.InventoryNumber,
            request.SerialNumber,
            request.ManufactureDate,
            request.CommissioningDate,
            request.LastVerificationDate,
            request.VerificationIntervalMonths,
            request.ResourceHours,
            request.NextServiceDate,
            request.ServiceDurationHours,
            request.InventoryDate,
            request.CountryId,
            request.LastVerificationUserAccountId,
            request.Notes);

        using var http = new HttpRequestMessage(HttpMethod.Put, Session.GetApiUrl($"api/vending-machines/{id}"));
        ApplyAuth(http);
        http.Content = new StringContent(JsonSerializer.Serialize(update), Encoding.UTF8, "application/json");

        var response = await _httpClient.SendAsync(http);
        if (!response.IsSuccessStatusCode)
        {
            MessageBox.Show("Не удалось обновить ТА.");
        }
    }

    private void ApplyAuth(HttpRequestMessage request)
    {
        if (!string.IsNullOrWhiteSpace(Session.AccessToken))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", Session.AccessToken);
        }
    }

    private static int ParseInt(string? value)
    {
        return int.TryParse(value, out var result) ? result : 0;
    }

    private static int? ParseNullableInt(string? value)
    {
        if (!int.TryParse(value, out var result))
        {
            return null;
        }

        // 0 и отрицательные считаем как "не задано".
        return result > 0 ? result : null;
    }

    private static byte? ParseNullableByte(string? value)
    {
        return byte.TryParse(value, out var result) ? result : null;
    }

    private static DateOnly? ParseDate(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        if (DateOnly.TryParseExact(value, "dd.MM.yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out var date))
        {
            return date;
        }

        return DateOnly.TryParse(value, out date) ? date : null;
    }
}
