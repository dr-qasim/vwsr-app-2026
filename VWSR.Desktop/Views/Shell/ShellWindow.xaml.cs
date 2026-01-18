using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;

namespace VWSR.Desktop;

public partial class ShellWindow : Window
{
    private bool _sidebarCollapsed;

    public ShellWindow()
    {
        InitializeComponent();
        LoadUserInfo();
        OpenPage(new DashboardPage());
    }

    private void OpenDashboard_Click(object sender, RoutedEventArgs e)
    {
        OpenPage(new DashboardPage());
    }

    private void OpenMonitoring_Click(object sender, RoutedEventArgs e)
    {
        OpenPage(new MonitoringPage());
    }

    private void OpenAdmin_Click(object sender, RoutedEventArgs e)
    {
        OpenPage(new AdminPage());
    }

    private void ShowPlaceholder_Click(object sender, RoutedEventArgs e)
    {
        // Заглушка для пунктов, которые не реализованы в этом модуле.
        var text = (sender as FrameworkElement)?.Tag?.ToString() ?? "Раздел";
        MessageBox.Show($"{text}: в разработке.");
    }

    private void OpenPage(Page page)
    {
        ContentFrame.Navigate(page);
    }

    private void ToggleSidebar_Click(object sender, RoutedEventArgs e)
    {
        _sidebarCollapsed = !_sidebarCollapsed;
        SidebarColumn.Width = _sidebarCollapsed ? new GridLength(64) : new GridLength(250);

        // Прячем текст, чтобы остались только иконки.
        var visibility = _sidebarCollapsed ? Visibility.Collapsed : Visibility.Visible;
        NavHeader.Visibility = visibility;
        MenuHeader.Visibility = visibility;
        MenuTextDashboard.Visibility = visibility;
        MenuTextMonitoring.Visibility = visibility;
        MenuTextReports.Visibility = visibility;
        MenuTextInventory.Visibility = visibility;
        MenuTextAdmin.Visibility = visibility;
        AdminHeader.Visibility = visibility;
        MenuButtonCompanies.Visibility = visibility;
        MenuButtonUsers.Visibility = visibility;
        MenuButtonModems.Visibility = visibility;
    }

    private void ProfileButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button button && button.ContextMenu != null)
        {
            button.ContextMenu.PlacementTarget = button;
            button.ContextMenu.IsOpen = true;
        }
    }

    private void Logout_Click(object sender, RoutedEventArgs e)
    {
        // Простая реализация выхода.
        Session.AccessToken = null;
        Session.RefreshToken = null;
        Session.User = null;

        var login = new LoginWindow();
        login.Show();
        Close();
    }

    private void LoadUserInfo()
    {
        var user = Session.User;
        if (user == null)
        {
            UserNameText.Text = "Гость";
            UserRoleText.Text = string.Empty;
            UserInitialsText.Text = string.Empty;
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
            return string.Empty;
        }

        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var initials = parts
            .Take(2)
            .Where(p => p.Length > 0)
            .Select(p => char.ToUpperInvariant(p[0]))
            .ToArray();

        return string.Join(string.Empty, initials);
    }
}
