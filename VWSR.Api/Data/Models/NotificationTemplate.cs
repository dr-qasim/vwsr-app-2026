using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class NotificationTemplate
{
    public int NotificationTemplateId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public virtual ICollection<VendingMachine> VendingMachine { get; set; } = new List<VendingMachine>();
}
