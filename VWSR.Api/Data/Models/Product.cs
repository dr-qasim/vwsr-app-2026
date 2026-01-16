using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class Product
{
    public int ProductId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public decimal Price { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual ICollection<Sale> Sale { get; set; } = new List<Sale>();

    public virtual ICollection<VendingMachineProduct> VendingMachineProduct { get; set; } = new List<VendingMachineProduct>();
}
