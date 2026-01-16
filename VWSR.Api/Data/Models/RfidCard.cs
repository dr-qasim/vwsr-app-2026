using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class RfidCard
{
    public int RfidCardId { get; set; }

    public string CardCode { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public virtual ICollection<VendingMachineRfidCard> VendingMachineRfidCard { get; set; } = new List<VendingMachineRfidCard>();
}
