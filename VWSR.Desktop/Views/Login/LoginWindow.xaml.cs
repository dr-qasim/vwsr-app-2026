using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows;

namespace VWSR.Desktop;

public partial class LoginWindow : Window
{
    private readonly HttpClient _httpClient = new();
    private readonly JsonSerializerOptions _jsonOptions = new() { PropertyNameCaseInsensitive = true };
    
    public LoginWindow()
    {
        InitializeComponent();
        _httpClient.BaseAddress = new Uri("http://localhost:5000/");
        // Сохраняем адрес API для остальных окон.
        Session.ApiBaseUrl = _httpClient.BaseAddress.ToString();
    }

    private async void LoginButton_Click(object sender, RoutedEventArgs e)
    {
        var email = EmailBox.Text?.Trim();
        var password = PasswordBox.Password;

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            StatusText.Text = "Введите электронную почту и пароль.";
            return;
        }

        LoginButton.IsEnabled = false;
        StatusText.Text = "  ...";

        try
        {
            var payload = new LoginRequest(email, password);
            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("api/auth/login", content);
            if (!response.IsSuccessStatusCode)
            {
                StatusText.Text = "Ошибка входа.";
                return;
            }

            var body = await response.Content.ReadAsStringAsync();
            var data = JsonSerializer.Deserialize<LoginResponse>(body, _jsonOptions);
            if (data is null)
            {
                StatusText.Text = "Ошибка входа.";
                return;
            }

            Session.AccessToken = data.AccessToken;
            Session.RefreshToken = data.RefreshToken;
            Session.User = data.User;

            StatusText.Text = "Вы успешно вошли.";

            var shell = new ShellWindow();
            shell.Show();
            Close();
        }
        catch (Exception ex)
        {
            StatusText.Text = $"Ошибка: {ex.Message}";
        }
        finally
        {
            LoginButton.IsEnabled = true;
        }
    }
}
