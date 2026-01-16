using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class EventSeverity
{
    public int EventSeverityId { get; set; }

    public string Name { get; set; } = null!;

    public int SortOrder { get; set; }

    public virtual ICollection<EventType> EventType { get; set; } = new List<EventType>();
}
