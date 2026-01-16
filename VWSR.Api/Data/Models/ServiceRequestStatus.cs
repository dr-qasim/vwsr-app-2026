using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class ServiceRequestStatus
{
    public int ServiceRequestStatusId { get; set; }

    public string Name { get; set; } = null!;

    public int SortOrder { get; set; }

    public virtual ICollection<ServiceRequest> ServiceRequest { get; set; } = new List<ServiceRequest>();

    public virtual ICollection<ServiceRequestStatusHistory> ServiceRequestStatusHistory { get; set; } = new List<ServiceRequestStatusHistory>();
}
