using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class VendingMachineEvent
{
    public int VendingMachineEventId { get; set; }

    public int VendingMachineId { get; set; }

    public int EventTypeId { get; set; }

    public DateTime OccurredAt { get; set; }

    public string? Message { get; set; }

    public virtual EventType EventType { get; set; } = null!;

    public virtual VendingMachine VendingMachine { get; set; } = null!;
}
