using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class ServiceRequestStatusHistory
{
    public int ServiceRequestStatusHistoryId { get; set; }

    public int ServiceRequestId { get; set; }

    public int ServiceRequestStatusId { get; set; }

    public int? ChangedByUserAccountId { get; set; }

    public DateTime ChangedAt { get; set; }

    public virtual UserAccount? ChangedByUserAccount { get; set; }

    public virtual ServiceRequest ServiceRequest { get; set; } = null!;

    public virtual ServiceRequestStatus ServiceRequestStatus { get; set; } = null!;
}
