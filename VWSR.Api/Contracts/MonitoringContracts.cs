namespace VWSR.Api.Contracts;

public sealed record MonitoringMachineItem(
    int Id,
    string Name,
    string Provider,
    string SystemTime,
    decimal AccountBalance,
    string ConnectionState,
    int CashInMachine,
    string Events,
    string Equipment,
    string InfoStatus,
    string Additional,
    IReadOnlyList<LoadItem> LoadItems
);

public sealed record LoadItem(string Name, int Percent);
