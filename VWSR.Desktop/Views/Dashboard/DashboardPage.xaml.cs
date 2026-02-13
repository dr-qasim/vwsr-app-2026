using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;

namespace VWSR.Desktop;

public partial class DashboardPage : Page
{
    private readonly HttpClient _httpClient = new();
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };
    private readonly List<SalesPoint> _salesPoints = new();
    public DashboardTile EfficiencyTile { get; private set; } = new();
    public DashboardTile NetworkTile { get; private set; } = new();
    public DashboardTile SummaryTile { get; private set; } = new();
    public DashboardTile SalesTile { get; private set; } = new();
    public DashboardTile NewsTile { get; private set; } = new();

    public DashboardPage()
    {
        InitializeComponent();
        DataContext = this;
        _ = LoadDashboard();
    }

    private void InitDashboard()
    {
        EfficiencyTile = new DashboardTile
        {
            Key = "Efficiency",
            Title = "Эффективность сети",
            EfficiencyPercent = 0
        };

        NetworkTile = new DashboardTile
        {
            Key = "Network",
            Title = "Состояние сети",
            WorkingCount = 0,
            OfflineCount = 0,
            ServiceCount = 0,
            SelectedStatusText = string.Empty
        };

        SummaryTile = new DashboardTile
        {
            Key = "Summary",
            Title = "Сводка",
            SalesTotal = 0,
            CashTotal = 0,
            MaintenanceTotal = 0
        };

        SalesTile = new DashboardTile
        {
            Key = "Sales",
            Title = "Динамика продаж за последние 10 дней"
        };

        NewsTile = new DashboardTile
        {
            Key = "News",
            Title = "Новости"
        };
    }

    private async Task LoadDashboard()
    {
        try
        {
            if (string.IsNullOrWhiteSpace(Session.AccessToken))
            {
                return;
            }

            // Запрос на API одной ручкой, чтобы не плодить много запросов.
            var url = Session.GetApiUrl("api/dashboard");
            using var request = new HttpRequestMessage(HttpMethod.Get, url);
            ApplyAuth(request);

            var response = await _httpClient.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                return;
            }

            var body = await response.Content.ReadAsStringAsync();
            var data = JsonSerializer.Deserialize<DashboardResponse>(body, _jsonOptions);
            if (data == null)
            {
                return;
            }

            ApplyDashboardData(data);
        }
        catch
        {
            // Если API недоступно, остаемся на нулевых данных.
            InitDashboard();
        }

    }

    private void ApplyDashboardData(DashboardResponse data)
    {
        // Обновляем блоки главной страницы реальными данными.
        EfficiencyTile.EfficiencyPercent = data.EfficiencyPercent;
        NetworkTile.WorkingCount = data.WorkingCount;
        NetworkTile.OfflineCount = data.OfflineCount;
        NetworkTile.ServiceCount = data.ServiceCount;
        NetworkTile.SelectedStatusText = string.Empty;

        SummaryTile.SalesTotal = data.SalesTotal;
        SummaryTile.CashTotal = data.CashTotal;
        SummaryTile.MaintenanceTotal = data.MaintenanceTotal;

        _salesPoints.Clear();
        if (data.SalesPoints != null)
        {
            foreach (var point in data.SalesPoints)
            {
                _salesPoints.Add(new SalesPoint
                {
                    Day = point.Day,
                    Sum = point.Sum,
                    Count = point.Count
                });
            }
        }

        NewsTile.NewsItems.Clear();
        if (data.News != null)
        {
            foreach (var item in data.News)
            {
                NewsTile.NewsItems.Add(item);
            }
        }

        UpdateSalesChart(SalesTile, "sum");

        // Простейшее обновление биндингов без сложного MVVM.
        DataContext = null;
        DataContext = this;
    }

    private void UpdateSalesChart(DashboardTile tile, string mode)
    {
        tile.ChartItems.Clear();

        if (_salesPoints.Count == 0)
        {
            return;
        }

        var max = mode == "sum"
            ? _salesPoints.Max(p => p.Sum)
            : _salesPoints.Max(p => p.Count);

        foreach (var point in _salesPoints)
        {
            var value = mode == "sum" ? point.Sum : point.Count;
            var maxValue = mode == "sum" ? (decimal)max : max;
            var height = maxValue == 0 ? 10 : 120.0 * (double)value / (double)maxValue;

            tile.ChartItems.Add(new ChartItem
            {
                Day = point.Day,
                BarHeight = height,
                ValueText = mode == "sum" ? value.ToString("N0") : value.ToString()
            });
        }
    }


    private void SalesFilterSum_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement element && element.DataContext is DashboardTile tile)
        {
            UpdateSalesChart(tile, "sum");
        }
    }

    private void SalesFilterCount_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement element && element.DataContext is DashboardTile tile)
        {
            UpdateSalesChart(tile, "count");
        }
    }

    private void NetworkStatus_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement element && element.DataContext is DashboardTile tile)
        {
            var key = (element.Tag?.ToString() ?? string.Empty).ToLowerInvariant();
            tile.SelectedStatusText = key switch
            {
                "working" => $"Работает: {tile.WorkingCount}",
                "offline" => $"Не работает: {tile.OfflineCount}",
                "service" => $"На обслуживании: {tile.ServiceCount}",
                _ => ""
            };
        }
    }

    private void HideTile_Click(object sender, RoutedEventArgs e)
    {
        // Скрываем плитку по имени (требование из критериев).
        if (sender is FrameworkElement element && element.Tag is string name)
        {
            if (FindName(name) is UIElement tile)
            {
                tile.Visibility = Visibility.Collapsed;
            }
        }
    }

    private void ShowAllTiles_Click(object sender, RoutedEventArgs e)
    {
        // Быстро показываем все плитки обратно.
        ShowTile(EfficiencyTileBorder);
        ShowTile(NetworkTileBorder);
        ShowTile(SummaryTileBorder);
        ShowTile(SalesTileBorder);
        ShowTile(NewsTileBorder);
    }

    private static void ShowTile(UIElement tile)
    {
        tile.Visibility = Visibility.Visible;
    }

    private void ApplyAuth(HttpRequestMessage request)
    {
        // Токен нужен, так как API защищен.
        if (!string.IsNullOrWhiteSpace(Session.AccessToken))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", Session.AccessToken);
        }
    }

        private sealed class SalesPoint
    {
        public string Day { get; init; } = string.Empty;
        public decimal Sum { get; init; }
        public int Count { get; init; }
    }
}
