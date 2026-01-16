using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class WorkMode
{
    public int WorkModeId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<VendingMachine> VendingMachine { get; set; } = new List<VendingMachine>();
}
