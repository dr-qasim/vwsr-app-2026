using VWSR.Api.Contracts;

namespace VWSR.Api.Services;

public sealed class MonitoringStatusGenerator
{
    private static readonly string[] ConnectionStates =
    [
        "Online",
        "Offline",
        "Weak"
    ];

    private static readonly string[] InfoStatuses =
    [
        "OK",
        "Low stock",
        "Cashbox full",
        "Service required"
    ];

    private static readonly string[] AdditionalStatuses =
    [
        "None",
        "Door open",
        "Temperature high",
        "Payment error"
    ];

    private static readonly string[] LoadNames =
    [
        "Coffee",
        "Sugar",
        "Milk",
        "Cups",
        "Lids"
    ];

    public GeneratedStatus Generate(int machineId)
    {
        var rand = new Random(machineId);
        var connectionState = ConnectionStates[rand.Next(ConnectionStates.Length)];
        var infoStatus = InfoStatuses[rand.Next(InfoStatuses.Length)];
        var additional = AdditionalStatuses[rand.Next(AdditionalStatuses.Length)];
        var cashInMachine = rand.Next(100, 5000);

        var loadItems = LoadNames
            .Select(name => new LoadItem(name, rand.Next(10, 100)))
            .ToArray();

        return new GeneratedStatus(
            connectionState,
            cashInMachine,
            infoStatus,
            additional,
            loadItems
        );
    }
}

public sealed record GeneratedStatus(
    string ConnectionState,
    int CashInMachine,
    string InfoStatus,
    string Additional,
    IReadOnlyList<LoadItem> LoadItems
);
