using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VWSR.Api.Contracts;
using VWSR.Api.Data;
using VWSR.Api.Data.Models;
using VWSR.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Минимальная настройка Swagger/OpenAPI.
builder.Services.AddEndpointsApiExplorer();


builder.Services.AddDbContext<AppDbContext>(options =>
{
    // Примеры для удаленного SQL Server в локальной сети:
    // 1) SQL-авторизация (логин/пароль SQL):
    // Server=192.168.1.10,1433;Database=VendingService;User Id=sa;Password=YourStrongPass123!;Encrypt=False;TrustServerCertificate=True
    //
    // 2) Windows-аутентификация (если права домена/сети настроены):
    // Server=192.168.1.10,1433;Database=VendingService;Trusted_Connection=True;Encrypt=False;TrustServerCertificate=True
    //
    // Если используется именованный экземпляр:
    // Server=192.168.1.10\\SQLEXPRESS;Database=VendingService;User Id=sa;Password=YourStrongPass123!;Encrypt=False;TrustServerCertificate=True
    
    var connectionString = builder.Configuration.GetConnectionString("Default");
    options.UseSqlServer(connectionString);
});

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(new DateOnlyJsonConverter());
});

builder.Services.AddSingleton<JwtTokenService>();
builder.Services.AddSingleton<RefreshTokenStore>();
builder.Services.AddSingleton<MonitoringStatusGenerator>();

var jwtKey = builder.Configuration["Jwt:Key"] ?? "ChangeThis_ToAStrongKey_AtLeast32Chars";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "VWSR.Api";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "VWSR.Clients";
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = signingKey,
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// Swagger включаем в режиме разработки.


app.UseAuthentication();
app.UseAuthorization();

var authGroup = app.MapGroup("/api/auth");

authGroup.MapPost("/login", async (
    LoginRequest request,
    AppDbContext db,
    JwtTokenService tokenService,
    RefreshTokenStore refreshTokenStore) =>
{
    var user = await db.UserAccount
        .Include(u => u.UserRole)
        .FirstOrDefaultAsync(u => u.Email == request.Email);

    if (user is null || !user.IsActive)
    {
        return Results.Unauthorized();
    }

    if (!PasswordHasher.Verify(request.Password, user.PasswordHash, user.PasswordSalt))
    {
        return Results.Unauthorized();
    }

    var accessToken = tokenService.CreateAccessToken(user);
    var refreshToken = tokenService.CreateRefreshToken();

    refreshTokenStore.Store(
        refreshToken,
        new RefreshTokenEntry(user.UserAccountId, tokenService.GetRefreshTokenExpiry()));

    var profile = new UserProfile(
        user.UserAccountId,
        user.Email,
        BuildFullName(user),
        user.UserRole.Name,
        user.PhotoUrl);

    return Results.Ok(new LoginResponse(accessToken, refreshToken, profile));
});

authGroup.MapPost("/refresh-token", async (
    RefreshRequest request,
    AppDbContext db,
    JwtTokenService tokenService,
    RefreshTokenStore refreshTokenStore) =>
{
    if (!refreshTokenStore.TryGet(request.RefreshToken, out var entry))
    {
        return Results.Unauthorized();
    }

    var user = await db.UserAccount
        .Include(u => u.UserRole)
        .FirstOrDefaultAsync(u => u.UserAccountId == entry.UserAccountId);

    if (user is null || !user.IsActive)
    {
        return Results.Unauthorized();
    }

    var accessToken = tokenService.CreateAccessToken(user);
    var newRefreshToken = tokenService.CreateRefreshToken();

    refreshTokenStore.Remove(request.RefreshToken);
    refreshTokenStore.Store(
        newRefreshToken,
        new RefreshTokenEntry(user.UserAccountId, tokenService.GetRefreshTokenExpiry()));

    var profile = new UserProfile(
        user.UserAccountId,
        user.Email,
        BuildFullName(user),
        user.UserRole.Name,
        user.PhotoUrl);

    return Results.Ok(new LoginResponse(accessToken, newRefreshToken, profile));
});

authGroup.MapPost("/logout", (LogoutRequest request, RefreshTokenStore refreshTokenStore) =>
{
    refreshTokenStore.Remove(request.RefreshToken);
    return Results.Ok();
});

var vmGroup = app.MapGroup("/api/vending-machines").RequireAuthorization();

vmGroup.MapGet("/", async (
    AppDbContext db,
    string? search,
    int page = 1,
    int pageSize = 20) =>
{
    if (page < 1) page = 1;
    if (pageSize < 1) pageSize = 20;

    IQueryable<VendingMachine> query = db.VendingMachine
        .AsNoTracking()
        .Include(vm => vm.VendingMachineModel)
        .Include(vm => vm.Company)
        .Include(vm => vm.Modem);

    if (!string.IsNullOrWhiteSpace(search))
    {
        query = query.Where(vm => vm.Name.Contains(search));
    }

    var total = await query.CountAsync();

    var items = await query
        .OrderBy(vm => vm.VendingMachineId)
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .Select(vm => new VendingMachineListItem(
            vm.ExternalId,
            vm.Name,
            vm.VendingMachineModel.Name,
            vm.Company != null ? vm.Company.Name : null,
            vm.ModemId ?? -1,
            vm.Address,
            vm.Place,
            vm.CommissioningDate.ToDateTime(TimeOnly.MinValue)))
        .ToListAsync();

    return Results.Ok(new PagedResult<VendingMachineListItem>(total, page, pageSize, items));
});

vmGroup.MapGet("/{id:guid}", async (Guid id, AppDbContext db) =>
{
    var vm = await db.VendingMachine.AsNoTracking().FirstOrDefaultAsync(v => v.ExternalId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    return Results.Ok(new VendingMachineDetail(
        vm.ExternalId,
        vm.Name,
        vm.VendingMachineModelId,
        vm.WorkModeId,
        vm.TimeZoneId,
        vm.VendingMachineStatusId,
        vm.ServicePriorityId,
        vm.ProductMatrixId,
        vm.CompanyId,
        vm.ModemId ?? -1,
        vm.Address,
        vm.Place,
        vm.InventoryNumber,
        vm.SerialNumber,
        vm.ManufactureDate,
        vm.CommissioningDate,
        vm.LastVerificationDate,
        vm.VerificationIntervalMonths,
        vm.ResourceHours,
        vm.NextServiceDate,
        vm.ServiceDurationHours,
        vm.InventoryDate,
        vm.CountryId,
        vm.LastVerificationUserAccountId,
        vm.Notes));
});

vmGroup.MapPost("/", async (VendingMachineCreateRequest request, AppDbContext db) =>
{
    if (await db.VendingMachine.AnyAsync(vm => vm.SerialNumber == request.SerialNumber))
    {
        return Results.Conflict(new { message = "TA with this serial number already exists." });
    }

    if (await db.VendingMachine.AnyAsync(vm => vm.InventoryNumber == request.InventoryNumber))
    {
        return Results.Conflict(new { message = "TA with this inventory number already exists." });
    }

    var vm = new VendingMachine
    {
        // Внешний идентификатор (GUID). В UI/API будем показывать его как "Id".
        ExternalId = Guid.NewGuid(),
        Name = request.Name,
        VendingMachineModelId = request.VendingMachineModelId,
        WorkModeId = request.WorkModeId,
        TimeZoneId = request.TimeZoneId,
        VendingMachineStatusId = request.VendingMachineStatusId,
        ServicePriorityId = request.ServicePriorityId,
        ProductMatrixId = request.ProductMatrixId,
        CompanyId = request.CompanyId,
        ModemId = request.ModemId,
        Address = request.Address,
        Place = request.Place,
        InventoryNumber = request.InventoryNumber,
        SerialNumber = request.SerialNumber,
        ManufactureDate = request.ManufactureDate,
        CommissioningDate = request.CommissioningDate,
        LastVerificationDate = request.LastVerificationDate,
        VerificationIntervalMonths = request.VerificationIntervalMonths,
        ResourceHours = request.ResourceHours,
        NextServiceDate = request.NextServiceDate,
        ServiceDurationHours = request.ServiceDurationHours,
        InventoryDate = request.InventoryDate,
        CountryId = request.CountryId,
        LastVerificationUserAccountId = request.LastVerificationUserAccountId,
        Notes = request.Notes,
        CreatedAt = DateTime.UtcNow
    };

    db.VendingMachine.Add(vm);
    await db.SaveChangesAsync();

    return Results.Created($"/api/vending-machines/{vm.ExternalId}", new { id = vm.ExternalId });
});

vmGroup.MapPut("/{id:guid}", async (Guid id, VendingMachineUpdateRequest request, AppDbContext db) =>
{
    var vm = await db.VendingMachine.FirstOrDefaultAsync(v => v.ExternalId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    // Проверяем уникальность по внутреннему int-id, т.к. route теперь GUID.
    if (await db.VendingMachine.AnyAsync(v => v.SerialNumber == request.SerialNumber && v.VendingMachineId != vm.VendingMachineId))
    {
        return Results.Conflict(new { message = "TA с такми номером уже существует." });
    }

    if (await db.VendingMachine.AnyAsync(v => v.InventoryNumber == request.InventoryNumber && v.VendingMachineId != vm.VendingMachineId))
    {
        return Results.Conflict(new { message = "TA с такми инвентарным номером уже существует." });
    }

    vm.Name = request.Name;
    vm.VendingMachineModelId = request.VendingMachineModelId;
    vm.WorkModeId = request.WorkModeId;
    vm.TimeZoneId = request.TimeZoneId;
    vm.VendingMachineStatusId = request.VendingMachineStatusId;
    vm.ServicePriorityId = request.ServicePriorityId;
    vm.ProductMatrixId = request.ProductMatrixId;
    vm.CompanyId = request.CompanyId;
    vm.ModemId = request.ModemId;
    vm.Address = request.Address;
    vm.Place = request.Place;
    vm.InventoryNumber = request.InventoryNumber;
    vm.SerialNumber = request.SerialNumber;
    vm.ManufactureDate = request.ManufactureDate;
    vm.CommissioningDate = request.CommissioningDate;
    vm.LastVerificationDate = request.LastVerificationDate;
    vm.VerificationIntervalMonths = request.VerificationIntervalMonths;
    vm.ResourceHours = request.ResourceHours;
    vm.NextServiceDate = request.NextServiceDate;
    vm.ServiceDurationHours = request.ServiceDurationHours;
    vm.InventoryDate = request.InventoryDate;
    vm.CountryId = request.CountryId;
    vm.LastVerificationUserAccountId = request.LastVerificationUserAccountId;
    vm.Notes = request.Notes;

    await db.SaveChangesAsync();
    return Results.Ok();
});

vmGroup.MapDelete("/{id:guid}", async (Guid id, AppDbContext db) =>
{
    var vm = await db.VendingMachine.FirstOrDefaultAsync(v => v.ExternalId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    db.VendingMachine.Remove(vm);
    await db.SaveChangesAsync();

    return Results.Ok();
});

vmGroup.MapPost("/{id:guid}/unlink-modem", async (Guid id, AppDbContext db) =>
{
    var vm = await db.VendingMachine.FirstOrDefaultAsync(v => v.ExternalId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    vm.ModemId = null;
    await db.SaveChangesAsync();

    return Results.Ok(new { message = "Модем отвязан." });
});

var dashboardGroup = app.MapGroup("/api/dashboard").RequireAuthorization();

dashboardGroup.MapGet("/", async (AppDbContext db) =>
{
    // Простая агрегация данных для главной страницы.
    var totalMachines = await db.VendingMachine.AsNoTracking().CountAsync();

    var workingCount = await db.VendingMachine
        .AsNoTracking()
        .Include(vm => vm.VendingMachineStatus)
        .CountAsync(vm => EF.Functions.Like(vm.VendingMachineStatus.Name, "%Работает%"));

    var offlineCount = await db.VendingMachine
        .AsNoTracking()
        .Include(vm => vm.VendingMachineStatus)
        .CountAsync(vm =>
            EF.Functions.Like(vm.VendingMachineStatus.Name, "%Вышел%") ||
            EF.Functions.Like(vm.VendingMachineStatus.Name, "%Не работает%"));

    var serviceCount = await db.VendingMachine
        .AsNoTracking()
        .Include(vm => vm.VendingMachineStatus)
        .CountAsync(vm =>
            EF.Functions.Like(vm.VendingMachineStatus.Name, "%ремонт%") ||
            EF.Functions.Like(vm.VendingMachineStatus.Name, "%обслуж%"));

    var efficiency = totalMachines == 0
        ? 0
        : (int)Math.Round(workingCount * 100m / totalMachines);

    var salesTotal = await db.Sale
        .AsNoTracking()
        .SumAsync(s => (decimal?)s.TotalAmount) ?? 0m;

    var cashTotal = await db.VendingMachineIncome
        .AsNoTracking()
        .SumAsync(i => (decimal?)i.TotalIncome) ?? 0m;

    var maintenanceTotal = await db.Maintenance
        .AsNoTracking()
        .CountAsync();

    // График продаж за 10 дней.
    var startDate = DateTime.Today.AddDays(-9);
    var salesByDay = await db.Sale
        .AsNoTracking()
        .Where(s => s.SoldAt >= startDate)
        .GroupBy(s => s.SoldAt.Date)
        .Select(g => new
        {
            Day = g.Key,
            Sum = g.Sum(x => x.TotalAmount),
            Count = g.Sum(x => x.Quantity)
        })
        .ToListAsync();


    var salesPoints = new List<DashboardSalesPoint>();
    for (var i = 0; i < 10; i++)
    {
        var day = startDate.Date.AddDays(i);
        var item = salesByDay.FirstOrDefault(x => x.Day == day);
        salesPoints.Add(new DashboardSalesPoint(
            day.ToString("dd.MM"),
            item?.Sum ?? 0m,
            item?.Count ?? 0));
    }

    // Новости берем из последних событий, если их нет - даем заглушки.
    var news = await db.VendingMachineEvent
        .AsNoTracking()
        .OrderByDescending(e => e.OccurredAt)
        .Select(e => e.Message)
        .Where(m => !string.IsNullOrWhiteSpace(m))
        .Take(3)
        .ToListAsync();

    if (news.Count == 0)
    {
        news =
        [
            "Обновлен регламент обслуживания.",
            "Запущены новые точки в бизнес-центре.",
            "Плановые проверки на этой неделе."
        ];
    }

    return Results.Ok(new DashboardResponse(
        efficiency,
        workingCount,
        offlineCount,
        serviceCount,
        salesTotal,
        cashTotal,
        maintenanceTotal,
        salesPoints,
        news));
});

var companiesGroup = app.MapGroup("/api/companies").RequireAuthorization();

companiesGroup.MapGet("/", async (AppDbContext db, string? search) =>
{
    IQueryable<Company> query = db.Company.AsNoTracking();

    if (!string.IsNullOrWhiteSpace(search))
    {
        query = query.Where(c => c.Name.Contains(search));
    }

    var items = await query
        .OrderBy(c => c.Name)
        .Select(c => new CompanyListItem(
            c.CompanyId,
            c.Name,
            c.Phone,
            c.Email,
            c.Address))
        .ToListAsync();

    return Results.Ok(items);
});

companiesGroup.MapGet("/{id:int}", async (int id, AppDbContext db) =>
{
    var company = await db.Company.AsNoTracking().FirstOrDefaultAsync(c => c.CompanyId == id);
    if (company is null)
    {
        return Results.NotFound();
    }

    return Results.Ok(new CompanyListItem(
        company.CompanyId,
        company.Name,
        company.Phone,
        company.Email,
        company.Address));
});

companiesGroup.MapPost("/", async (CompanyRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Name))
    {
        return Results.BadRequest(new { message = "Название обязательно." });
    }

    if (await db.Company.AnyAsync(c => c.Name == request.Name))
    {
        return Results.Conflict(new { message = "Компания с таким названием уже существует." });
    }

    var company = new Company
    {
        Name = request.Name.Trim(),
        Phone = request.Phone,
        Email = request.Email,
        Address = request.Address,
        CreatedAt = DateTime.UtcNow
    };

    db.Company.Add(company);
    await db.SaveChangesAsync();

    return Results.Created($"/api/companies/{company.CompanyId}", new { id = company.CompanyId });
});

companiesGroup.MapPut("/{id:int}", async (int id, CompanyRequest request, AppDbContext db) =>
{
    var company = await db.Company.FirstOrDefaultAsync(c => c.CompanyId == id);
    if (company is null)
    {
        return Results.NotFound();
    }

    if (await db.Company.AnyAsync(c => c.Name == request.Name && c.CompanyId != id))
    {
        return Results.Conflict(new { message = "Компания с таким названием уже существует." });
    }

    company.Name = request.Name.Trim();
    company.Phone = request.Phone;
    company.Email = request.Email;
    company.Address = request.Address;

    await db.SaveChangesAsync();
    return Results.Ok();
});

companiesGroup.MapDelete("/{id:int}", async (int id, AppDbContext db) =>
{
    var company = await db.Company.FirstOrDefaultAsync(c => c.CompanyId == id);
    if (company is null)
    {
        return Results.NotFound();
    }

    var hasLinks = await db.VendingMachine.AnyAsync(vm => vm.CompanyId == id)
                   || await db.UserAccount.AnyAsync(u => u.CompanyId == id);
    if (hasLinks)
    {
        return Results.Conflict(new { message = "Нельзя удалить компанию с привязками." });
    }

    db.Company.Remove(company);
    await db.SaveChangesAsync();

    return Results.Ok();
});

var monitoringGroup = app.MapGroup("/api/monitoring").RequireAuthorization();

monitoringGroup.MapGet("/machines", async (
    AppDbContext db,
    MonitoringStatusGenerator generator,
    string? status,
    string? connectionTypeId,
    string? additionalStatus) =>
{
    int? parsedConnectionTypeId = null;
    if (!string.IsNullOrWhiteSpace(connectionTypeId))
    {
        if (!int.TryParse(connectionTypeId, out var parsed))
        {
            return Results.BadRequest(new { message = "Некорректный тип подключения." });
        }

        parsedConnectionTypeId = parsed;
    }

    var machines = await db.VendingMachine
        .AsNoTracking()
        .Include(vm => vm.VendingMachineStatus)
        .Include(vm => vm.Modem)
            .ThenInclude(m => m!.Provider)
        .Include(vm => vm.VendingMachineEvent)
        .Include(vm => vm.VendingMachineEquipment)
            .ThenInclude(e => e.EquipmentType)
        .ToListAsync();

    var incomeByMachine = await db.VendingMachineIncome
        .AsNoTracking()
        .ToDictionaryAsync(i => i.VendingMachineId, i => i.TotalIncome ?? 0m);

    var result = new List<MonitoringMachineItem>();

    foreach (var vm in machines)
    {
        if (!string.IsNullOrWhiteSpace(status) &&
            !string.Equals(vm.VendingMachineStatus.Name, status, StringComparison.OrdinalIgnoreCase))
        {
            continue;
        }

        if (parsedConnectionTypeId.HasValue && vm.Modem?.ConnectionTypeId != parsedConnectionTypeId.Value)
        {
            continue;
        }

        var generated = generator.Generate(vm.VendingMachineId);

        if (!string.IsNullOrWhiteSpace(additionalStatus) &&
            !string.Equals(generated.Additional, additionalStatus, StringComparison.OrdinalIgnoreCase))
        {
            continue;
        }

        var events = vm.VendingMachineEvent
            .OrderByDescending(e => e.OccurredAt)
            .Select(e => e.Message)
            .FirstOrDefault() ?? "-";

        var equipment = vm.VendingMachineEquipment.Count == 0
            ? "-"
            : string.Join(", ", vm.VendingMachineEquipment.Select(e => e.EquipmentType.Name));

        incomeByMachine.TryGetValue(vm.VendingMachineId, out var income);

        result.Add(new MonitoringMachineItem(
            vm.ExternalId,
            vm.Name,
            vm.Modem?.Provider?.Name ?? "-",
            vm.VendingMachineStatus.Name,
            DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
            income,
            generated.ConnectionState,
            generated.CashInMachine,
            events,
            equipment,
            generated.InfoStatus,
            generated.Additional,
            generated.LoadItems));
    }

    return Results.Ok(result);
});

var mobileGroup = app.MapGroup("/api/mobile").RequireAuthorization();

mobileGroup.MapGet("/requests", async (AppDbContext db, ClaimsPrincipal user) =>
{
    var userId = GetCurrentUserId(user);
    if (!userId.HasValue)
    {
        return Results.Unauthorized();
    }

    var requests = await db.ServiceRequest
        .AsNoTracking()
        .Include(r => r.ServiceRequestStatus)
        .Include(r => r.ServiceRequestType)
        .Include(r => r.VendingMachine)
        .Where(r => r.AssignedUserAccountId == userId.Value || r.AssignedUserAccountId == null)
        .OrderBy(r => r.PlannedDate)
        .ThenBy(r => r.ServiceRequestId)
        .Select(r => new MobileRequestCard(
            r.ServiceRequestId,
            $"SR-{r.ServiceRequestId}",
            r.VendingMachine.Name,
            r.ServiceRequestType.Name,
            r.ServiceRequestStatus.Name,
            r.PlannedDate,
            r.VendingMachine.Address))
        .ToListAsync();

    // Если нет назначенных/свободных нарядов, показываем общий список.
    if (requests.Count == 0)
    {
        requests = await db.ServiceRequest
            .AsNoTracking()
            .Include(r => r.ServiceRequestStatus)
            .Include(r => r.ServiceRequestType)
            .Include(r => r.VendingMachine)
            .OrderBy(r => r.PlannedDate)
            .ThenBy(r => r.ServiceRequestId)
            .Take(30)
            .Select(r => new MobileRequestCard(
                r.ServiceRequestId,
                $"SR-{r.ServiceRequestId}",
                r.VendingMachine.Name,
                r.ServiceRequestType.Name,
                r.ServiceRequestStatus.Name,
                r.PlannedDate,
                r.VendingMachine.Address))
            .ToListAsync();
    }

    return Results.Ok(requests);
});

mobileGroup.MapGet("/requests/{id:int}", async (int id, AppDbContext db, ClaimsPrincipal user) =>
{
    var userId = GetCurrentUserId(user);
    if (!userId.HasValue)
    {
        return Results.Unauthorized();
    }

    var request = await db.ServiceRequest
        .AsNoTracking()
        .Include(r => r.ServiceRequestStatus)
        .Include(r => r.ServiceRequestType)
        .Include(r => r.VendingMachine)
        .FirstOrDefaultAsync(r => r.ServiceRequestId == id);

    if (request is null)
    {
        return Results.NotFound();
    }

    if (request.AssignedUserAccountId.HasValue && request.AssignedUserAccountId.Value != userId.Value)
    {
        return Results.Forbid();
    }

    return Results.Ok(new MobileRequestDetail(
        request.ServiceRequestId,
        $"SR-{request.ServiceRequestId}",
        request.ServiceRequestStatus.Name,
        request.ServiceRequestType.Name,
        request.PlannedDate,
        request.Notes,
        request.DeclineReason,
        request.VendingMachine.Name,
        request.VendingMachine.Address,
        request.VendingMachine.Place,
        request.VendingMachine.SerialNumber,
        request.VendingMachine.InventoryNumber));
});

mobileGroup.MapGet("/requests/{id:int}/history", async (int id, AppDbContext db, ClaimsPrincipal user) =>
{
    var userId = GetCurrentUserId(user);
    if (!userId.HasValue)
    {
        return Results.Unauthorized();
    }

    var request = await db.ServiceRequest
        .AsNoTracking()
        .Include(r => r.ServiceRequestStatus)
        .FirstOrDefaultAsync(r => r.ServiceRequestId == id);

    if (request is null)
    {
        return Results.NotFound();
    }

    if (request.AssignedUserAccountId.HasValue && request.AssignedUserAccountId.Value != userId.Value)
    {
        return Results.Forbid();
    }

    var historyRows = await db.ServiceRequestStatusHistory
        .AsNoTracking()
        .Include(h => h.ServiceRequestStatus)
        .Include(h => h.ChangedByUserAccount)
        .Where(h => h.ServiceRequestId == id)
        .OrderByDescending(h => h.ChangedAt)
        .Select(h => new
        {
            Status = h.ServiceRequestStatus.Name,
            h.ChangedAt,
            h.ChangedByUserAccount
        })
        .ToListAsync();

    var history = historyRows
        .Select(row => new MobileStatusHistoryItem(
            row.Status,
            row.ChangedAt,
            BuildFullName(row.ChangedByUserAccount)))
        .ToList();

    if (history.Count == 0)
    {
        history.Add(new MobileStatusHistoryItem(
            request.ServiceRequestStatus.Name,
            request.CreatedAt,
            null));
    }

    return Results.Ok(history);
});

mobileGroup.MapPost("/requests/{id:int}/accept", async (int id, AppDbContext db, ClaimsPrincipal user) =>
{
    var userId = GetCurrentUserId(user);
    if (!userId.HasValue)
    {
        return Results.Unauthorized();
    }

    var request = await db.ServiceRequest.FirstOrDefaultAsync(r => r.ServiceRequestId == id);
    if (request is null)
    {
        return Results.NotFound();
    }

    if (request.AssignedUserAccountId.HasValue && request.AssignedUserAccountId.Value != userId.Value)
    {
        return Results.Forbid();
    }

    var workStatusId = await GetServiceRequestStatusId(db, "В работе");
    if (!workStatusId.HasValue)
    {
        return Results.BadRequest(new { message = "Не найден статус 'В работе'." });
    }

    request.ServiceRequestStatusId = workStatusId.Value;
    request.AssignedUserAccountId = userId.Value;
    request.DeclineReason = null;

    db.ServiceRequestStatusHistory.Add(new ServiceRequestStatusHistory
    {
        ServiceRequestId = request.ServiceRequestId,
        ServiceRequestStatusId = workStatusId.Value,
        ChangedByUserAccountId = userId.Value,
        ChangedAt = DateTime.UtcNow
    });

    await db.SaveChangesAsync();
    return Results.Ok(new { message = "Наряд принят." });
});

mobileGroup.MapPost("/requests/{id:int}/decline", async (
    int id,
    MobileDeclineRequest body,
    AppDbContext db,
    ClaimsPrincipal user) =>
{
    var userId = GetCurrentUserId(user);
    if (!userId.HasValue)
    {
        return Results.Unauthorized();
    }

    if (string.IsNullOrWhiteSpace(body.Reason))
    {
        return Results.BadRequest(new { message = "Укажите причину отказа." });
    }

    var request = await db.ServiceRequest.FirstOrDefaultAsync(r => r.ServiceRequestId == id);
    if (request is null)
    {
        return Results.NotFound();
    }

    if (request.AssignedUserAccountId.HasValue && request.AssignedUserAccountId.Value != userId.Value)
    {
        return Results.Forbid();
    }

    var cancelledStatusId = await GetServiceRequestStatusId(db, "Отменена");
    if (!cancelledStatusId.HasValue)
    {
        return Results.BadRequest(new { message = "Не найден статус 'Отменена'." });
    }

    request.ServiceRequestStatusId = cancelledStatusId.Value;
    request.AssignedUserAccountId = userId.Value;
    request.DeclineReason = body.Reason.Trim();

    db.ServiceRequestStatusHistory.Add(new ServiceRequestStatusHistory
    {
        ServiceRequestId = request.ServiceRequestId,
        ServiceRequestStatusId = cancelledStatusId.Value,
        ChangedByUserAccountId = userId.Value,
        ChangedAt = DateTime.UtcNow
    });

    await db.SaveChangesAsync();
    return Results.Ok(new { message = "Наряд отклонен." });
});

app.Run();

static string BuildFullName(UserAccount? user)
{
    if (user is null)
    {
        return string.Empty;
    }

    var parts = new[] { user.LastName, user.FirstName, user.Patronymic };
    return string.Join(" ", parts.Where(part => !string.IsNullOrWhiteSpace(part)));
}

static int? GetCurrentUserId(ClaimsPrincipal user)
{
    var idValue = user.FindFirstValue(ClaimTypes.NameIdentifier);
    return int.TryParse(idValue, out var userId) ? userId : null;
}

static async Task<int?> GetServiceRequestStatusId(AppDbContext db, string statusName)
{
    return await db.ServiceRequestStatus
        .AsNoTracking()
        .Where(s => s.Name == statusName)
        .Select(s => (int?)s.ServiceRequestStatusId)
        .FirstOrDefaultAsync();
}
