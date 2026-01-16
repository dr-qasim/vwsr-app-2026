using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class TimeZone
{
    public int TimeZoneId { get; set; }

    public string Name { get; set; } = null!;

    public short UtcOffsetMinutes { get; set; }

    public virtual ICollection<VendingMachine> VendingMachine { get; set; } = new List<VendingMachine>();
}
