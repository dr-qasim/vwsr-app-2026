using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class Maintenance
{
    public int MaintenanceId { get; set; }

    public int VendingMachineId { get; set; }

    public DateOnly MaintenanceDate { get; set; }

    public string? WorkDescription { get; set; }

    public string? Problems { get; set; }

    public int? ExecutorUserAccountId { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual UserAccount? ExecutorUserAccount { get; set; }

    public virtual VendingMachine VendingMachine { get; set; } = null!;
}
