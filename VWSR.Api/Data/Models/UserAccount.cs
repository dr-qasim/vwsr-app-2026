using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class UserAccount
{
    public int UserAccountId { get; set; }

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public string LastName { get; set; } = null!;

    public string FirstName { get; set; } = null!;

    public string? Patronymic { get; set; }

    public string PasswordHash { get; set; } = null!;

    public string? PasswordSalt { get; set; }

    public string? PhotoUrl { get; set; }

    public int UserRoleId { get; set; }

    public int? CompanyId { get; set; }

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Company? Company { get; set; }

    public virtual ICollection<Maintenance> Maintenance { get; set; } = new List<Maintenance>();

    public virtual ICollection<ServiceRequest> ServiceRequest { get; set; } = new List<ServiceRequest>();

    public virtual ICollection<ServiceRequestStatusHistory> ServiceRequestStatusHistory { get; set; } = new List<ServiceRequestStatusHistory>();

    public virtual UserRole UserRole { get; set; } = null!;

    public virtual ICollection<VendingMachine> VendingMachineEngineerUserAccount { get; set; } = new List<VendingMachine>();

    public virtual ICollection<VendingMachine> VendingMachineLastVerificationUserAccount { get; set; } = new List<VendingMachine>();

    public virtual ICollection<VendingMachine> VendingMachineManagerUserAccount { get; set; } = new List<VendingMachine>();

    public virtual ICollection<VendingMachineStatusHistory> VendingMachineStatusHistory { get; set; } = new List<VendingMachineStatusHistory>();

    public virtual ICollection<VendingMachine> VendingMachineTechnicianOperatorUserAccount { get; set; } = new List<VendingMachine>();

    public virtual ICollection<VendingMachineModel> VendingMachineModel { get; set; } = new List<VendingMachineModel>();
}
