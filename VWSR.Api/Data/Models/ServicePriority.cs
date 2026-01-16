using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class ServicePriority
{
    public int ServicePriorityId { get; set; }

    public string Name { get; set; } = null!;

    public int SortOrder { get; set; }

    public virtual ICollection<VendingMachine> VendingMachine { get; set; } = new List<VendingMachine>();
}
