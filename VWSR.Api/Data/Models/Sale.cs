using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class Sale
{
    public int SaleId { get; set; }

    public int VendingMachineId { get; set; }

    public int ProductId { get; set; }

    public int Quantity { get; set; }

    public decimal TotalAmount { get; set; }

    public DateTime SoldAt { get; set; }

    public int SalePaymentMethodId { get; set; }

    public virtual Product Product { get; set; } = null!;

    public virtual SalePaymentMethod SalePaymentMethod { get; set; } = null!;

    public virtual VendingMachine VendingMachine { get; set; } = null!;
}
