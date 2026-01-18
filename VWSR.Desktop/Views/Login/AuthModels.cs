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
}
