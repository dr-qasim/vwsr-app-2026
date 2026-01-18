namespace VWSR.Api.Contracts;

public sealed record CompanyListItem(
    int Id,
    string Name,
    string? Phone,
    string? Email,
    string? Address
);

public sealed record CompanyRequest(
    string Name,
    string? Phone,
    string? Email,
    string? Address
);
