using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class PaymentSystem
{
    public int PaymentSystemId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<VendingMachine> VendingMachine { get; set; } = new List<VendingMachine>();
}
