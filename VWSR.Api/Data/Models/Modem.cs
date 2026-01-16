using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class Modem
{
    public int ModemId { get; set; }

    public string ModemNumber { get; set; } = null!;

    public string? Imei { get; set; }

    public string? SimPhoneNumber { get; set; }

    public int? ProviderId { get; set; }

    public int? ConnectionTypeId { get; set; }

    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual ConnectionType? ConnectionType { get; set; }

    public virtual Provider? Provider { get; set; }

    public virtual ICollection<VendingMachine> VendingMachine { get; set; } = new List<VendingMachine>();
}
