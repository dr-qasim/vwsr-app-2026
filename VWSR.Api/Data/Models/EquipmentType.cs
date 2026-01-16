using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class EquipmentType
{
    public int EquipmentTypeId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<VendingMachineEquipment> VendingMachineEquipment { get; set; } = new List<VendingMachineEquipment>();
}
