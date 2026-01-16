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

builder.Services.AddDbContext<AppDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("Default");
    options.UseSqlServer(connectionString);
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
            vm.VendingMachineId,
            vm.Name,
            vm.VendingMachineModel.Name,
            vm.Company != null ? vm.Company.Name : null,
            vm.ModemId ?? -1,
            vm.Address,
            vm.Place,
            vm.CreatedAt))
        .ToListAsync();

    return Results.Ok(new PagedResult<VendingMachineListItem>(total, page, pageSize, items));
});

vmGroup.MapGet("/{id:int}", async (int id, AppDbContext db) =>
{
    var vm = await db.VendingMachine.AsNoTracking().FirstOrDefaultAsync(v => v.VendingMachineId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    return Results.Ok(new VendingMachineDetail(
        vm.VendingMachineId,
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

    return Results.Created($"/api/vending-machines/{vm.VendingMachineId}", new { id = vm.VendingMachineId });
});

vmGroup.MapPut("/{id:int}", async (int id, VendingMachineUpdateRequest request, AppDbContext db) =>
{
    var vm = await db.VendingMachine.FirstOrDefaultAsync(v => v.VendingMachineId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    if (await db.VendingMachine.AnyAsync(v => v.SerialNumber == request.SerialNumber && v.VendingMachineId != id))
    {
        return Results.Conflict(new { message = "TA с такми номером уже существует." });
    }

    if (await db.VendingMachine.AnyAsync(v => v.InventoryNumber == request.InventoryNumber && v.VendingMachineId != id))
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

vmGroup.MapDelete("/{id:int}", async (int id, AppDbContext db) =>
{
    var vm = await db.VendingMachine.FirstOrDefaultAsync(v => v.VendingMachineId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    db.VendingMachine.Remove(vm);
    await db.SaveChangesAsync();

    return Results.Ok();
});

vmGroup.MapPost("/{id:int}/unlink-modem", async (int id, AppDbContext db) =>
{
    var vm = await db.VendingMachine.FirstOrDefaultAsync(v => v.VendingMachineId == id);

    if (vm is null)
    {
        return Results.NotFound();
    }

    vm.ModemId = null;
    await db.SaveChangesAsync();

    return Results.Ok(new { message = "Модем отвязан." });
});

var monitoringGroup = app.MapGroup("/api/monitoring").RequireAuthorization();

monitoringGroup.MapGet("/machines", async (
    AppDbContext db,
    MonitoringStatusGenerator generator,
    string? status,
    int? connectionTypeId,
    string? additionalStatus) =>
{
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

        if (connectionTypeId.HasValue && vm.Modem?.ConnectionTypeId != connectionTypeId.Value)
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
            vm.VendingMachineId,
            vm.Name,
            vm.Modem?.Provider?.Name ?? "-",
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

app.Run();

static string BuildFullName(UserAccount user)
{
    var parts = new[] { user.LastName, user.FirstName, user.Patronymic };
    return string.Join(" ", parts.Where(part => !string.IsNullOrWhiteSpace(part)));
}
