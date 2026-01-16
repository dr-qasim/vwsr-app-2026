using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class VendingMachineStatusHistory
{
    public int VendingMachineStatusHistoryId { get; set; }

    public int VendingMachineId { get; set; }

    public int VendingMachineStatusId { get; set; }

    public int? ChangedByUserAccountId { get; set; }

    public DateTime ChangedAt { get; set; }

    public virtual UserAccount? ChangedByUserAccount { get; set; }

    public virtual VendingMachine VendingMachine { get; set; } = null!;

    public virtual VendingMachineStatus VendingMachineStatus { get; set; } = null!;
}
