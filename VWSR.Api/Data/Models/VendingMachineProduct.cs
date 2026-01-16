using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class VendingMachineProduct
{
    public int VendingMachineId { get; set; }

    public int ProductId { get; set; }

    public int QuantityOnHand { get; set; }

    public int MinimumStock { get; set; }

    public decimal? AverageDailySales { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual Product Product { get; set; } = null!;

    public virtual VendingMachine VendingMachine { get; set; } = null!;
}
