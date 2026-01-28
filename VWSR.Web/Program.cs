using System.Globalization;
using Microsoft.AspNetCore.Localization;

var builder = WebApplication.CreateBuilder(args);

// Локализация: RU/EN для простого переключения языка.
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");

// Razor Pages + локализация страниц.
builder.Services
    .AddRazorPages()
    .AddViewLocalization()
    .AddDataAnnotationsLocalization();

// HTTP-клиент для обращения к нашему API.
builder.Services.AddHttpClient("api", client =>
{
    var baseUrl = builder.Configuration["Api:BaseUrl"] ?? "http://localhost:5000/";
    client.BaseAddress = new Uri(baseUrl);
});

var app = builder.Build();

// Языки интерфейса (требование Web-модуля).
var supportedCultures = new[]
{
    new CultureInfo("ru"),
    new CultureInfo("en")
};

var localizationOptions = new RequestLocalizationOptions
{
    DefaultRequestCulture = new RequestCulture("ru"),
    SupportedCultures = supportedCultures,
    SupportedUICultures = supportedCultures
};

// Переключение языка через ?culture=ru или ?culture=en.
localizationOptions.RequestCultureProviders.Insert(0, new QueryStringRequestCultureProvider());

// Конвейер обработки запросов.
if (!app.Environment.IsDevelopment())
{
    // Ошибки перенаправляем на главную (без отдельной Error-страницы).
    app.UseExceptionHandler("/Index");
    // HSTS включаем только вне разработки.
    app.UseHsts();
}

app.UseRequestLocalization(localizationOptions);
app.UseHttpsRedirection();

app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

app.Run();
