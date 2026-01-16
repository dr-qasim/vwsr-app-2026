using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class ServiceRequestType
{
    public int ServiceRequestTypeId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<ServiceRequest> ServiceRequest { get; set; } = new List<ServiceRequest>();
}
