namespace VWSR.Api.Contracts;

public sealed record LoginRequest(string Email, string Password);

public sealed record LoginResponse(string AccessToken, string RefreshToken, UserProfile User);

public sealed record RefreshRequest(string RefreshToken);

public sealed record LogoutRequest(string RefreshToken);

public sealed record UserProfile(int Id, string Email, string FullName, string Role, string? PhotoUrl);
