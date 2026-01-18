using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;

namespace VWSR.Desktop;

public partial class DashboardPage : Page
{
    private readonly List<SalesPoint> _salesPoints = new();
    public DashboardTile EfficiencyTile { get; private set; } = new();
    public DashboardTile NetworkTile { get; private set; } = new();
    public DashboardTile SummaryTile { get; private set; } = new();
    public DashboardTile SalesTile { get; private set; } = new();
    public DashboardTile NewsTile { get; private set; } = new();

    public DashboardPage()
    {
        InitializeComponent();
        SeedDashboard();
        DataContext = this;
    }

    private void SeedDashboard()
    {
        EfficiencyTile = new DashboardTile
        {
            Key = "Efficiency",
            Title = "Эффективность сети",
            EfficiencyPercent = 78
        };

        NetworkTile = new DashboardTile
        {
            Key = "Network",
            Title = "Состояние сети",
            WorkingCount = 120,
            OfflineCount = 12,
            ServiceCount = 8,
            SelectedStatusText = "Выберите статус"
        };

        SummaryTile = new DashboardTile
        {
            Key = "Summary",
            Title = "Сводка",
            SalesTotal = 125000,
            CashTotal = 43200,
            MaintenanceTotal = 9
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

        NewsTile.NewsItems.Add("Обновлен регламент обслуживания.");
        NewsTile.NewsItems.Add("Запущены новые точки в бизнес-центре.");
        NewsTile.NewsItems.Add("Плановые проверки на этой неделе.");

        SeedSales();
        UpdateSalesChart(SalesTile, "sum");
    }

    private void SeedSales()
    {
        _salesPoints.Clear();
        var now = DateTime.Today;
        var rand = new Random(5);

        for (var i = 9; i >= 0; i--)
        {
            var day = now.AddDays(-i);
            _salesPoints.Add(new SalesPoint
            {
                Day = day.ToString("dd.MM"),
                Sum = rand.Next(8000, 22000),
                Count = rand.Next(40, 120)
            });
        }
    }

    private void UpdateSalesChart(DashboardTile tile, string mode)
    {
        tile.ChartItems.Clear();

        var max = mode == "sum"
            ? _salesPoints.Max(p => p.Sum)
            : _salesPoints.Max(p => p.Count);

        foreach (var point in _salesPoints)
        {
            var value = mode == "sum" ? point.Sum : point.Count;
            var height = max == 0 ? 10 : 120.0 * value / max;

            tile.ChartItems.Add(new ChartItem
            {
                Day = point.Day,
                BarHeight = height,
                ValueText = value.ToString()
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

    private sealed class SalesPoint
    {
        public string Day { get; init; } = string.Empty;
        public int Sum { get; init; }
        public int Count { get; init; }
    }
}
