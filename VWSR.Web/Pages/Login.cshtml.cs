using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace VWSR.Web.Pages;

public sealed class LoginModel : PageModel
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    public LoginModel(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    [BindProperty]
    public string Email { get; set; } = string.Empty;

    [BindProperty]
    public string Password { get; set; } = string.Empty;

    public string? Error { get; private set; }

    public void OnGet()
    {
        // Можно подставить значения из appsettings для ускорения.
        Email = _configuration["Api:UserEmail"] ?? string.Empty;
        Password = _configuration["Api:UserPassword"] ?? string.Empty;
    }

    public async Task<IActionResult> OnPostAsync()
    {
        try
        {
            var client = _httpClientFactory.CreateClient("api");

            // Простая авторизация через API.
            var response = await client.PostAsJsonAsync("api/auth/login", new { email = Email, password = Password });
            if (!response.IsSuccessStatusCode)
            {
                Error = "Неверный логин или пароль.";
                return Page();
            }

            var body = await response.Content.ReadAsStringAsync();
            var login = JsonSerializer.Deserialize<LoginResponse>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (login == null)
            {
                Error = "Ошибка при разборе ответа API.";
                return Page();
            }

            // Сохраняем токены и имя пользователя в сессии.
            HttpContext.Session.SetString("AccessToken", login.AccessToken);
            HttpContext.Session.SetString("RefreshToken", login.RefreshToken);
            HttpContext.Session.SetString("UserName", login.User?.FullName ?? login.User?.Email ?? string.Empty);

            // RedirectToPage проще и "правильнее" чем Response.Redirect.
            return RedirectToPage("/VendingMachines");
        }
        catch
        {
            // Если API не запущено или недоступно.
            Error = "Сервер API недоступен. Запустите VWSR.Api и попробуйте снова.";
            return Page();
        }
    }

    private sealed class LoginResponse
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public LoginUser? User { get; set; }
    }

    private sealed class LoginUser
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
    }
}
