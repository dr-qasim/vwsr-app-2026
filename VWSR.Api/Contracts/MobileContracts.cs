namespace VWSR.Api.Contracts;

public sealed record MobileRequestCard(
    int Id,
    string Number,
    string VendingMachineName,
    string ServiceType,
    string Status,
    DateOnly PlannedDate,
    string? Address
);

public sealed record MobileRequestDetail(
    int Id,
    string Number,
    string Status,
    string ServiceType,
    DateOnly PlannedDate,
    string? Notes,
    string? DeclineReason,
    string VendingMachineName,
    string? Address,
    string? Place,
    string? SerialNumber,
    string? InventoryNumber
);

public sealed record MobileStatusHistoryItem(
    string Status,
    DateTime ChangedAt,
    string? ChangedBy
);

public sealed record MobileDeclineRequest(string Reason);
