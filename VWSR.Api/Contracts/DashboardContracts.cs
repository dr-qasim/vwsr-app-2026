namespace VWSR.Api.Contracts;

public sealed record DashboardSalesPoint(
    string Day,
    decimal Sum,
    int Count
);

public sealed record DashboardResponse(
    int EfficiencyPercent,
    int WorkingCount,
    int OfflineCount,
    int ServiceCount,
    decimal SalesTotal,
    decimal CashTotal,
    int MaintenanceTotal,
    IReadOnlyList<DashboardSalesPoint> SalesPoints,
    IReadOnlyList<string> News
);
