using System;
using System.Collections.Generic;

namespace VWSR.Api.Data.Models;

public partial class UserRole
{
    public int UserRoleId { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<UserAccount> UserAccount { get; set; } = new List<UserAccount>();
}
