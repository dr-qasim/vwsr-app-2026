using System;

namespace VWSR.Desktop;

public sealed record PagedResult<T>(int Total, int Page, int PageSize, T[] Items);

public sealed record VendingMachineListItem(
    int Id,
    string Name,
    string Model,
    string? Company,
    int ModemId,
    string Address,
    string Place,
    DateTime WorkingSince
);

public sealed record VendingMachineDetail(
    int Id,
    string Name,
    int VendingMachineModelId,
    int WorkModeId,
    int TimeZoneId,
    int VendingMachineStatusId,
    int ServicePriorityId,
    int ProductMatrixId,
    int? CompanyId,
    int ModemId,
    string Address,
    string Place,
    string InventoryNumber,
    string SerialNumber,
    DateOnly ManufactureDate,
    DateOnly CommissioningDate,
    DateOnly? LastVerificationDate,
    int? VerificationIntervalMonths,
    int? ResourceHours,
    DateOnly? NextServiceDate,
    byte? ServiceDurationHours,
    DateOnly? InventoryDate,
    int CountryId,
    int? LastVerificationUserAccountId,
    string? Notes
);

public sealed record VendingMachineCreateRequest(
    string Name,
    int VendingMachineModelId,
    int WorkModeId,
    int TimeZoneId,
    int VendingMachineStatusId,
    int ServicePriorityId,
    int ProductMatrixId,
    int? CompanyId,
    int? ModemId,
    string Address,
    string Place,
    string InventoryNumber,
    string SerialNumber,
    DateOnly ManufactureDate,
    DateOnly CommissioningDate,
    DateOnly? LastVerificationDate,
    int? VerificationIntervalMonths,
    int? ResourceHours,
    DateOnly? NextServiceDate,
    byte? ServiceDurationHours,
    DateOnly? InventoryDate,
    int CountryId,
    int? LastVerificationUserAccountId,
    string? Notes
);

public sealed record VendingMachineUpdateRequest(
    string Name,
    int VendingMachineModelId,
    int WorkModeId,
    int TimeZoneId,
    int VendingMachineStatusId,
    int ServicePriorityId,
    int ProductMatrixId,
    int? CompanyId,
    int? ModemId,
    string Address,
    string Place,
    string InventoryNumber,
    string SerialNumber,
    DateOnly ManufactureDate,
    DateOnly CommissioningDate,
    DateOnly? LastVerificationDate,
    int? VerificationIntervalMonths,
    int? ResourceHours,
    DateOnly? NextServiceDate,
    byte? ServiceDurationHours,
    DateOnly? InventoryDate,
    int CountryId,
    int? LastVerificationUserAccountId,
    string? Notes
);

public sealed class VendingMachineRow
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string Company { get; set; } = string.Empty;
    public int ModemId { get; set; }
    public string Address { get; set; } = string.Empty;
    public string Place { get; set; } = string.Empty;
    public DateTime WorkingSince { get; set; }
}
