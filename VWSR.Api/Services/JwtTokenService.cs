using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using VWSR.Api.Data.Models;

namespace VWSR.Api.Services;

public sealed class JwtTokenService
{
    private readonly IConfiguration _config;

    public JwtTokenService(IConfiguration config)
    {
        _config = config;
    }

    public string CreateAccessToken(UserAccount user)
    {
        var issuer = _config["Jwt:Issuer"] ?? "VWSR.Api";
        var audience = _config["Jwt:Audience"] ?? "VWSR.Clients";
        var keyValue = _config["Jwt:Key"] ?? "m7Rk9VdQ2pXcN4Tt8HfL1sZy6WnJ3aBv5KqU0eGx";
        var expiresMinutes = GetAccessTokenMinutes();

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.UserAccountId.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(ClaimTypes.NameIdentifier, user.UserAccountId.ToString()),
            new(ClaimTypes.Name, BuildFullName(user)),
            new(ClaimTypes.Role, user.UserRole?.Name ?? string.Empty)
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(keyValue));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expiresMinutes),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string CreateRefreshToken()
    {
        return Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    }

    public DateTime GetRefreshTokenExpiry()
    {
        var days = 7;
        if (int.TryParse(_config["Jwt:RefreshTokenDays"], out var parsed))
        {
            days = parsed;
        }

        return DateTime.UtcNow.AddDays(days);
    }

    private int GetAccessTokenMinutes()
    {
        if (int.TryParse(_config["Jwt:AccessTokenMinutes"], out var minutes))
        {
            return minutes;
        }

        return 60;
    }

    private static string BuildFullName(UserAccount user)
    {
        var parts = new[] { user.LastName, user.FirstName, user.Patronymic };
        return string.Join(" ", parts.Where(part => !string.IsNullOrWhiteSpace(part)));
    }
}
