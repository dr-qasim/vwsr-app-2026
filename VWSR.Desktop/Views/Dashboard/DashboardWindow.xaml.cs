using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace VWSR.Desktop;

public partial class DashboardWindow : Window
{
    private readonly List<SalesPoint> _salesPoints = new();
    private Point _dragStartPoint;
    private bool _sidebarCollapsed;

    public ObservableCollection<DashboardTile> Tiles { get; } = new();

    public DashboardWindow()
    {
        InitializeComponent();
        DataContext = this;

        SeedDashboard();
        LoadUserInfo();
    }

    private void SeedDashboard()
    {
        var efficiency = new DashboardTile
        {
            Key = "Efficiency",
            Title = "Эффективность сети",
            EfficiencyPercent = 78
        };

        var network = new DashboardTile
        {
            Key = "Network",
            Title = "Состояние сети",
            WorkingCount = 120,
            OfflineCount = 12,
            ServiceCount = 8,
            SelectedStatusText = "Выберите статус"
        };

        var summary = new DashboardTile
        {
            Key = "Summary",
            Title = "Сводка",
            SalesTotal = 125000,
            CashTotal = 43200,
            MaintenanceTotal = 9
        };

        var sales = new DashboardTile
        {
            Key = "Sales",
            Title = "Динамика продаж за последние 10 дней"
        };

        var news = new DashboardTile
        {
            Key = "News",
            Title = "Новости"
        };

        news.NewsItems.Add("Обновлен регламент обслуживания.");
        news.NewsItems.Add("Запущены новые точки в бизнес-центре.");
        news.NewsItems.Add("Плановые проверки на этой неделе.");

        Tiles.Add(efficiency);
        Tiles.Add(network);
        Tiles.Add(summary);
        Tiles.Add(sales);
        Tiles.Add(news);

        SeedSales();
        UpdateSalesChart(sales, "sum");
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

    private void LoadUserInfo()
    {
        var user = Session.User;
        if (user == null)
        {
            UserNameText.Text = "Гость";
            UserRoleText.Text = "";
            UserInitialsText.Text = "";
            return;
        }

        UserNameText.Text = BuildDisplayName(user.FullName);
        UserRoleText.Text = user.Role;
        UserInitialsText.Text = BuildInitials(user.FullName);

        if (!string.IsNullOrWhiteSpace(user.PhotoUrl))
        {
            try
            {
                UserPhoto.Source = new BitmapImage(new Uri(user.PhotoUrl, UriKind.Absolute));
                UserPhoto.Visibility = Visibility.Visible;
                PhotoPlaceholder.Visibility = Visibility.Collapsed;
            }
            catch
            {
                UserPhoto.Visibility = Visibility.Collapsed;
                PhotoPlaceholder.Visibility = Visibility.Visible;
            }
        }
    }

    private static string BuildDisplayName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
        {
            return string.Empty;
        }

        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0)
        {
            return fullName;
        }

        var surname = parts[0];
        var initials = parts.Skip(1)
            .Where(p => p.Length > 0)
            .Select(p => char.ToUpperInvariant(p[0]) + ".")
            .ToArray();

        return initials.Length == 0
            ? surname
            : $"{surname} {string.Join(string.Empty, initials)}";
    }

    private static string BuildInitials(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
        {
            return "";
        }

        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0)
        {
            return "";
        }

        var initials = parts
            .Take(2)
            .Where(p => p.Length > 0)
            .Select(p => char.ToUpperInvariant(p[0]))
            .ToArray();

        return string.Join(string.Empty, initials);
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
        if (sender is FrameworkElement element && element.DataContext is DashboardTile tile)
        {
            Tiles.Remove(tile);
        }
    }

    private void TilesList_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        _dragStartPoint = e.GetPosition(null);
    }

    private void TilesList_PreviewMouseMove(object sender, MouseEventArgs e)
    {
        if (e.LeftButton != MouseButtonState.Pressed)
        {
            return;
        }

        var currentPosition = e.GetPosition(null);
        if (Math.Abs(currentPosition.X - _dragStartPoint.X) < SystemParameters.MinimumHorizontalDragDistance &&
            Math.Abs(currentPosition.Y - _dragStartPoint.Y) < SystemParameters.MinimumVerticalDragDistance)
        {
            return;
        }

        var listBoxItem = FindAncestor<ListBoxItem>((DependencyObject)e.OriginalSource);
        if (listBoxItem == null)
        {
            return;
        }

        var tile = listBoxItem.DataContext as DashboardTile;
        if (tile != null)
        {
            DragDrop.DoDragDrop(listBoxItem, tile, DragDropEffects.Move);
        }
    }

    private void TilesList_Drop(object sender, DragEventArgs e)
    {
        if (!e.Data.GetDataPresent(typeof(DashboardTile)))
        {
            return;
        }

        var dropped = (DashboardTile)e.Data.GetData(typeof(DashboardTile))!;
        var targetItem = FindAncestor<ListBoxItem>((DependencyObject)e.OriginalSource);
        if (targetItem?.DataContext is not DashboardTile target)
        {
            return;
        }

        if (ReferenceEquals(dropped, target))
        {
            return;
        }

        var oldIndex = Tiles.IndexOf(dropped);
        var newIndex = Tiles.IndexOf(target);
        if (oldIndex < 0 || newIndex < 0)
        {
            return;
        }

        Tiles.Move(oldIndex, newIndex);
    }

    private static T? FindAncestor<T>(DependencyObject? current) where T : DependencyObject
    {
        while (current != null)
        {
            if (current is T typed)
            {
                return typed;
            }

            current = VisualTreeHelper.GetParent(current);
        }

        return null;
    }

    private void ToggleSidebar_Click(object sender, RoutedEventArgs e)
    {
        _sidebarCollapsed = !_sidebarCollapsed;
        SidebarColumn.Width = _sidebarCollapsed ? new GridLength(60) : new GridLength(220);
        MenuHeader.Visibility = _sidebarCollapsed ? Visibility.Collapsed : Visibility.Visible;
        AdminExpander.Visibility = _sidebarCollapsed ? Visibility.Collapsed : Visibility.Visible;
    }

    private void ProfileButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button button && button.ContextMenu != null)
        {
            button.ContextMenu.PlacementTarget = button;
            button.ContextMenu.IsOpen = true;
        }
    }

    private sealed class SalesPoint
    {
        public string Day { get; init; } = string.Empty;
        public int Sum { get; init; }
        public int Count { get; init; }
    }
}

public sealed class TileTemplateSelector : DataTemplateSelector
{
    public DataTemplate? EfficiencyTemplate { get; set; }
    public DataTemplate? NetworkStateTemplate { get; set; }
    public DataTemplate? SummaryTemplate { get; set; }
    public DataTemplate? SalesTemplate { get; set; }
    public DataTemplate? NewsTemplate { get; set; }

    public override DataTemplate SelectTemplate(object item, DependencyObject container)
    {
        if (item is not DashboardTile tile)
        {
            return base.SelectTemplate(item, container);
        }

        return tile.Key switch
        {
            "Efficiency" => EfficiencyTemplate,
            "Network" => NetworkStateTemplate,
            "Summary" => SummaryTemplate,
            "Sales" => SalesTemplate,
            "News" => NewsTemplate,
            _ => base.SelectTemplate(item, container)
        } ?? base.SelectTemplate(item, container);
    }
}
