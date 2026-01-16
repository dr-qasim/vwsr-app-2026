using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class RfidCardType
{
    public int RfidCardTypeId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<VendingMachineRfidCard> VendingMachineRfidCard { get; set; } = new List<VendingMachineRfidCard>();
}
