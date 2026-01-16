using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class VendingMachineModel
{
    public int VendingMachineModelId { get; set; }

    public int VendingMachineManufacturerId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<VendingMachine> VendingMachine { get; set; } = new List<VendingMachine>();

    public virtual VendingMachineManufacturer VendingMachineManufacturer { get; set; } = null!;

    public virtual ICollection<UserAccount> UserAccount { get; set; } = new List<UserAccount>();
}
