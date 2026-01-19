using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;

namespace VWSR.Desktop;

public partial class MonitoringPage : Page
{
    private readonly HttpClient _httpClient = new();
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };

    public ObservableCollection<MonitoringRow> Rows { get; } = new();

    public MonitoringPage()
    {
        InitializeComponent();
        DataContext = this;
    }

    private async void Apply_Click(object sender, RoutedEventArgs e)
    {
        await LoadMonitoring();
    }

    private void Clear_Click(object sender, RoutedEventArgs e)
    {
        // Сбрасываем фильтры, чтобы начать поиск заново.
        StatusBox.SelectedIndex = 0;
        AdditionalBox.SelectedIndex = 0;
        ConnectionTypeBox.Text = string.Empty;
    }

    private async Task LoadMonitoring()
    {
        try
        {
            // Фильтры применяем только по кнопке "Применить".
            var status = GetComboValue(StatusBox);
            var additional = GetComboValue(AdditionalBox);
            var connectionType = ConnectionTypeBox.Text?.Trim();

            var url = Session.GetApiUrl($"api/monitoring/machines?status={Uri.EscapeDataString(status ?? string.Empty)}" +
                      $"&connectionTypeId={Uri.EscapeDataString(connectionType ?? string.Empty)}" +
                      $"&additionalStatus={Uri.EscapeDataString(additional ?? string.Empty)}");

            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            ApplyAuth(request);

            var response = await _httpClient.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                MessageBox.Show("Не удалось получить данные мониторинга.");
                return;
            }

            var body = await response.Content.ReadAsStringAsync();
            var items = JsonSerializer.Deserialize<MonitoringMachineItem[]>(body, _jsonOptions) ?? Array.Empty<MonitoringMachineItem>();

            Rows.Clear();
            var index = 1;
            foreach (var item in items)
            {
                Rows.Add(new MonitoringRow
                {
                    RowNumber = index++,
                    Tp = item.Provider,
                    Connection = item.ConnectionState,
                    Load = string.Join(", ", item.LoadItems.Select(l => $"{l.Name} {l.Percent}%")),
                    Cash = item.CashInMachine.ToString(),
                    Events = item.Events,
                    Equipment = item.Equipment,
                    Info = item.InfoStatus,
                    Additional = item.Additional,
                    Time = item.SystemTime,
                    AccountBalance = item.AccountBalance.ToString("N0")
                });
            }

            UpdateSummary(items);
            EmptyText.Visibility = Rows.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка: {ex.Message}");
        }
    }

    private void UpdateSummary(MonitoringMachineItem[] items)
    {
        // Итоги после фильтрации.
        TotalCountText.Text = $"Итого автоматов: {items.Length}";
        var totalCash = items.Sum(i => i.CashInMachine);
        TotalCashText.Text = $"Денег в автоматах: {totalCash}";
    }

    private void ApplyAuth(HttpRequestMessage request)
    {
        if (!string.IsNullOrWhiteSpace(Session.AccessToken))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", Session.AccessToken);
        }
    }

    private static string? GetComboValue(ComboBox combo)
    {
        return (combo.SelectedItem as ComboBoxItem)?.Content?.ToString();
    }
}
