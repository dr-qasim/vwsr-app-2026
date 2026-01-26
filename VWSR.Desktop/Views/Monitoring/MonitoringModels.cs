namespace VWSR.Desktop;

public sealed record MonitoringMachineItem(
    int Id,
    string Name,
    string Provider,
    string Status,
    string SystemTime,
    decimal AccountBalance,
    string ConnectionState,
    int CashInMachine,
    string Events,
    string Equipment,
    string InfoStatus,
    string Additional,
    LoadItem[] LoadItems
);

public sealed record LoadItem(string Name, int Percent);

public sealed class MonitoringRow
{
    public int RowNumber { get; set; }
    public string Tp { get; set; } = string.Empty;
    public string Connection { get; set; } = string.Empty;
    public string Load { get; set; } = string.Empty;
    public string Cash { get; set; } = string.Empty;
    public string Events { get; set; } = string.Empty;
    public string Equipment { get; set; } = string.Empty;
    public string Info { get; set; } = string.Empty;
    public string Additional { get; set; } = string.Empty;
    public string Time { get; set; } = string.Empty;
    public string AccountBalance { get; set; } = string.Empty;
}
