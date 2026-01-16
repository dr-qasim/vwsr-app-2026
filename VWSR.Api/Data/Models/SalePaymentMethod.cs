using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class SalePaymentMethod
{
    public int SalePaymentMethodId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Sale> Sale { get; set; } = new List<Sale>();
}
