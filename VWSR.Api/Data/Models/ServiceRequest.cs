using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class ServiceRequest
{
    public int ServiceRequestId { get; set; }

    public int VendingMachineId { get; set; }

    public int ServiceRequestTypeId { get; set; }

    public int ServiceRequestStatusId { get; set; }

    public DateOnly PlannedDate { get; set; }

    public int? AssignedUserAccountId { get; set; }

    public int? SortOrder { get; set; }

    public string? Notes { get; set; }

    public string? DeclineReason { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual UserAccount? AssignedUserAccount { get; set; }

    public virtual ServiceRequestStatus ServiceRequestStatus { get; set; } = null!;

    public virtual ICollection<ServiceRequestStatusHistory> ServiceRequestStatusHistory { get; set; } = new List<ServiceRequestStatusHistory>();

    public virtual ServiceRequestType ServiceRequestType { get; set; } = null!;

    public virtual VendingMachine VendingMachine { get; set; } = null!;
}
