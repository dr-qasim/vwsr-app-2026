using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class VendingMachineIncome
{
    public int VendingMachineId { get; set; }

    public decimal? TotalIncome { get; set; }
}
