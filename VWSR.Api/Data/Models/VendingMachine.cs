using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class VendingMachine
{
    public int VendingMachineId { get; set; }

    public string Name { get; set; } = null!;

    public int VendingMachineModelId { get; set; }

    public int WorkModeId { get; set; }

    public int TimeZoneId { get; set; }

    public int VendingMachineStatusId { get; set; }

    public int ServicePriorityId { get; set; }

    public int ProductMatrixId { get; set; }

    public int? CompanyId { get; set; }

    public int? ModemId { get; set; }

    public string Address { get; set; } = null!;

    public string Place { get; set; } = null!;

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public string InventoryNumber { get; set; } = null!;

    public string SerialNumber { get; set; } = null!;

    public DateOnly ManufactureDate { get; set; }

    public DateOnly CommissioningDate { get; set; }

    public DateOnly? LastVerificationDate { get; set; }

    public int? VerificationIntervalMonths { get; set; }

    public DateOnly? NextVerificationDate { get; set; }

    public int? ResourceHours { get; set; }

    public DateOnly? NextServiceDate { get; set; }

    public byte? ServiceDurationHours { get; set; }

    public DateOnly? InventoryDate { get; set; }

    public int CountryId { get; set; }

    public int? LastVerificationUserAccountId { get; set; }

    public TimeOnly? WorkingTimeFrom { get; set; }

    public TimeOnly? WorkingTimeTo { get; set; }

    public int? CriticalValuesTemplateId { get; set; }

    public int? NotificationTemplateId { get; set; }

    public int? ManagerUserAccountId { get; set; }

    public int? EngineerUserAccountId { get; set; }

    public int? TechnicianOperatorUserAccountId { get; set; }

    public string? KitOnlineCashRegisterId { get; set; }

    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Company? Company { get; set; }

    public virtual Country Country { get; set; } = null!;

    public virtual CriticalValuesTemplate? CriticalValuesTemplate { get; set; }

    public virtual UserAccount? EngineerUserAccount { get; set; }

    public virtual UserAccount? LastVerificationUserAccount { get; set; }

    public virtual ICollection<Maintenance> Maintenance { get; set; } = new List<Maintenance>();

    public virtual UserAccount? ManagerUserAccount { get; set; }

    public virtual Modem? Modem { get; set; }

    public virtual NotificationTemplate? NotificationTemplate { get; set; }

    public virtual ProductMatrix ProductMatrix { get; set; } = null!;

    public virtual ICollection<Sale> Sale { get; set; } = new List<Sale>();

    public virtual ServicePriority ServicePriority { get; set; } = null!;

    public virtual ICollection<ServiceRequest> ServiceRequest { get; set; } = new List<ServiceRequest>();

    public virtual UserAccount? TechnicianOperatorUserAccount { get; set; }

    public virtual TimeZone TimeZone { get; set; } = null!;

    public virtual ICollection<VendingMachineEquipment> VendingMachineEquipment { get; set; } = new List<VendingMachineEquipment>();

    public virtual ICollection<VendingMachineEvent> VendingMachineEvent { get; set; } = new List<VendingMachineEvent>();

    public virtual VendingMachineModel VendingMachineModel { get; set; } = null!;

    public virtual ICollection<VendingMachineProduct> VendingMachineProduct { get; set; } = new List<VendingMachineProduct>();

    public virtual ICollection<VendingMachineRfidCard> VendingMachineRfidCard { get; set; } = new List<VendingMachineRfidCard>();

    public virtual VendingMachineStatus VendingMachineStatus { get; set; } = null!;

    public virtual ICollection<VendingMachineStatusHistory> VendingMachineStatusHistory { get; set; } = new List<VendingMachineStatusHistory>();

    public virtual WorkMode WorkMode { get; set; } = null!;

    public virtual ICollection<PaymentSystem> PaymentSystem { get; set; } = new List<PaymentSystem>();
}
