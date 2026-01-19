namespace VWSR.Desktop;

public sealed record LoginRequest(string Email, string Password);

public sealed record LoginResponse(string AccessToken, string RefreshToken, UserProfile User);

public sealed record UserProfile(int Id, string Email, string FullName, string Role, string? PhotoUrl);

public static class Session
{
    public static string? AccessToken { get; set; }
    public static string? RefreshToken { get; set; }
    public static UserProfile? User { get; set; }
    public static string? ApiBaseUrl { get; set; }

    public static Uri GetApiBaseUri()
    {
        // Если адрес не задан или кривой, используем локальный API.
        if (Uri.TryCreate(ApiBaseUrl, UriKind.Absolute, out var uri))
        {
            return uri;
        }

        ApiBaseUrl = "http://localhost:5000/";
        return new Uri(ApiBaseUrl);
    }

    public static string GetApiUrl(string relative)
    {
        // Быстро собираем абсолютный URL без BaseAddress.
        var baseUri = GetApiBaseUri();
        return new Uri(baseUri, relative).ToString();
    }
}
