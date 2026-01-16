using System.Security.Cryptography;
using System.Text;

namespace VWSR.Api.Services;

public static class PasswordHasher
{
    public static string HashPassword(string password, string salt)
    {
        var saltBytes = GetSaltBytes(salt);
        var hashBytes = Rfc2898DeriveBytes.Pbkdf2(
            password,
            saltBytes,
            10000,
            HashAlgorithmName.SHA256,
            32);
        return Convert.ToBase64String(hashBytes);
    }

    public static bool Verify(string password, string hash, string? salt)
    {
        if (string.IsNullOrWhiteSpace(hash))
        {
            return false;
        }

        if (string.IsNullOrWhiteSpace(salt))
        {
            if (SlowEquals(hash, password))
            {
                return true;
            }

            var simpleHash = Convert.ToBase64String(SHA256.HashData(Encoding.UTF8.GetBytes(password)));
            return SlowEquals(hash, simpleHash);
        }

        var computed = HashPassword(password, salt);
        return SlowEquals(hash, computed);
    }

    private static byte[] GetSaltBytes(string salt)
    {
        try
        {
            return Convert.FromBase64String(salt);
        }
        catch (FormatException)
        {
            return Encoding.UTF8.GetBytes(salt);
        }
    }

    private static bool SlowEquals(string a, string b)
    {
        var aBytes = Encoding.UTF8.GetBytes(a);
        var bBytes = Encoding.UTF8.GetBytes(b);
        var diff = aBytes.Length ^ bBytes.Length;
        var length = Math.Min(aBytes.Length, bBytes.Length);

        for (var i = 0; i < length; i++)
        {
            diff |= aBytes[i] ^ bBytes[i];
        }

        return diff == 0;
    }
}
