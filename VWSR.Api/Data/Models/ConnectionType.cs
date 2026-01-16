using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class ConnectionType
{
    public int ConnectionTypeId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Modem> Modem { get; set; } = new List<Modem>();
}
