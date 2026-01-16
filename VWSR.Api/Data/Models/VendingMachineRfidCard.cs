using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class VendingMachineRfidCard
{
    public int VendingMachineId { get; set; }

    public int RfidCardId { get; set; }

    public int RfidCardTypeId { get; set; }

    public virtual RfidCard RfidCard { get; set; } = null!;

    public virtual RfidCardType RfidCardType { get; set; } = null!;

    public virtual VendingMachine VendingMachine { get; set; } = null!;
}
