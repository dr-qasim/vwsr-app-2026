using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using VWSR.Api.Data.Models;
using TimeZoneEntity = VWSR.Api.Data.Models.TimeZone;

namespace VWSR.Api.Data;

public partial class AppDbContext : DbContext
{
    public AppDbContext()
    {
    }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Company> Company { get; set; }

    public virtual DbSet<ConnectionType> ConnectionType { get; set; }

    public virtual DbSet<Country> Country { get; set; }

    public virtual DbSet<CriticalValuesTemplate> CriticalValuesTemplate { get; set; }

    public virtual DbSet<EquipmentType> EquipmentType { get; set; }

    public virtual DbSet<EventSeverity> EventSeverity { get; set; }

    public virtual DbSet<EventType> EventType { get; set; }

    public virtual DbSet<Maintenance> Maintenance { get; set; }

    public virtual DbSet<Modem> Modem { get; set; }

    public virtual DbSet<NotificationTemplate> NotificationTemplate { get; set; }

    public virtual DbSet<PaymentSystem> PaymentSystem { get; set; }

    public virtual DbSet<Product> Product { get; set; }

    public virtual DbSet<ProductMatrix> ProductMatrix { get; set; }

    public virtual DbSet<Provider> Provider { get; set; }

    public virtual DbSet<RfidCard> RfidCard { get; set; }

    public virtual DbSet<RfidCardType> RfidCardType { get; set; }

    public virtual DbSet<Sale> Sale { get; set; }

    public virtual DbSet<SalePaymentMethod> SalePaymentMethod { get; set; }

    public virtual DbSet<ServicePriority> ServicePriority { get; set; }

    public virtual DbSet<ServiceRequest> ServiceRequest { get; set; }

    public virtual DbSet<ServiceRequestStatus> ServiceRequestStatus { get; set; }

    public virtual DbSet<ServiceRequestStatusHistory> ServiceRequestStatusHistory { get; set; }

    public virtual DbSet<ServiceRequestType> ServiceRequestType { get; set; }

    public virtual DbSet<TimeZoneEntity> TimeZone { get; set; }

    public virtual DbSet<UserAccount> UserAccount { get; set; }

    public virtual DbSet<UserRole> UserRole { get; set; }

    public virtual DbSet<VendingMachine> VendingMachine { get; set; }

    public virtual DbSet<VendingMachineEquipment> VendingMachineEquipment { get; set; }

    public virtual DbSet<VendingMachineEvent> VendingMachineEvent { get; set; }

    public virtual DbSet<VendingMachineIncome> VendingMachineIncome { get; set; }

    public virtual DbSet<VendingMachineManufacturer> VendingMachineManufacturer { get; set; }

    public virtual DbSet<VendingMachineModel> VendingMachineModel { get; set; }

    public virtual DbSet<VendingMachineProduct> VendingMachineProduct { get; set; }

    public virtual DbSet<VendingMachineRfidCard> VendingMachineRfidCard { get; set; }

    public virtual DbSet<VendingMachineStatus> VendingMachineStatus { get; set; }

    public virtual DbSet<VendingMachineStatusHistory> VendingMachineStatusHistory { get; set; }

    public virtual DbSet<WorkMode> WorkMode { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlServer("Name=ConnectionStrings:Default");
        }
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Company>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_Company_Name").IsUnique();

            entity.Property(e => e.Address).HasMaxLength(300);
            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_Company_CreatedAt");
            entity.Property(e => e.Email).HasMaxLength(256);
            entity.Property(e => e.Name).HasMaxLength(200);
            entity.Property(e => e.Phone).HasMaxLength(32);
        });

        modelBuilder.Entity<ConnectionType>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_ConnectionType_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<Country>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_Country_Name").IsUnique();

            entity.Property(e => e.IsoCode)
                .HasMaxLength(2)
                .IsFixedLength();
            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<CriticalValuesTemplate>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_CriticalValuesTemplate_Name").IsUnique();

            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Name).HasMaxLength(150);
        });

        modelBuilder.Entity<EquipmentType>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_EquipmentType_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<EventSeverity>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_EventSeverity_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<EventType>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_EventType_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(150);

            entity.HasOne(d => d.EventSeverity).WithMany(p => p.EventType)
                .HasForeignKey(d => d.EventSeverityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_EventType_EventSeverity");
        });

        modelBuilder.Entity<Maintenance>(entity =>
        {
            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_Maintenance_CreatedAt");
            entity.Property(e => e.Problems).HasMaxLength(1000);
            entity.Property(e => e.WorkDescription).HasMaxLength(1000);

            entity.HasOne(d => d.ExecutorUserAccount).WithMany(p => p.Maintenance)
                .HasForeignKey(d => d.ExecutorUserAccountId)
                .HasConstraintName("FK_Maintenance_ExecutorUserAccount");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.Maintenance)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Maintenance_VendingMachine");
        });

        modelBuilder.Entity<Modem>(entity =>
        {
            entity.HasIndex(e => e.Imei, "UQ_Modem_Imei").IsUnique();

            entity.HasIndex(e => e.ModemNumber, "UQ_Modem_ModemNumber").IsUnique();

            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_Modem_CreatedAt");
            entity.Property(e => e.Imei).HasMaxLength(32);
            entity.Property(e => e.ModemNumber).HasMaxLength(50);
            entity.Property(e => e.Notes).HasMaxLength(500);
            entity.Property(e => e.SimPhoneNumber).HasMaxLength(32);

            entity.HasOne(d => d.ConnectionType).WithMany(p => p.Modem)
                .HasForeignKey(d => d.ConnectionTypeId)
                .HasConstraintName("FK_Modem_ConnectionType");

            entity.HasOne(d => d.Provider).WithMany(p => p.Modem)
                .HasForeignKey(d => d.ProviderId)
                .HasConstraintName("FK_Modem_Provider");
        });

        modelBuilder.Entity<NotificationTemplate>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_NotificationTemplate_Name").IsUnique();

            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Name).HasMaxLength(150);
        });

        modelBuilder.Entity<PaymentSystem>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_PaymentSystem_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<Product>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_Product_Name").IsUnique();

            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_Product_CreatedAt");
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.Name).HasMaxLength(200);
            entity.Property(e => e.Price).HasColumnType("decimal(18, 2)");
        });

        modelBuilder.Entity<ProductMatrix>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_ProductMatrix_Name").IsUnique();

            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.Name).HasMaxLength(150);
        });

        modelBuilder.Entity<Provider>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_Provider_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(150);
        });

        modelBuilder.Entity<RfidCard>(entity =>
        {
            entity.HasIndex(e => e.CardCode, "UQ_RfidCard_CardCode").IsUnique();

            entity.Property(e => e.CardCode).HasMaxLength(50);
            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_RfidCard_CreatedAt");
        });

        modelBuilder.Entity<RfidCardType>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_RfidCardType_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<Sale>(entity =>
        {
            entity.Property(e => e.SoldAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_Sale_SoldAt");
            entity.Property(e => e.TotalAmount).HasColumnType("decimal(18, 2)");

            entity.HasOne(d => d.Product).WithMany(p => p.Sale)
                .HasForeignKey(d => d.ProductId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Sale_Product");

            entity.HasOne(d => d.SalePaymentMethod).WithMany(p => p.Sale)
                .HasForeignKey(d => d.SalePaymentMethodId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Sale_SalePaymentMethod");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.Sale)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Sale_VendingMachine");
        });

        modelBuilder.Entity<SalePaymentMethod>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_SalePaymentMethod_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<ServicePriority>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_ServicePriority_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<ServiceRequest>(entity =>
        {
            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_ServiceRequest_CreatedAt");
            entity.Property(e => e.DeclineReason).HasMaxLength(500);
            entity.Property(e => e.Notes).HasMaxLength(1000);

            entity.HasOne(d => d.AssignedUserAccount).WithMany(p => p.ServiceRequest)
                .HasForeignKey(d => d.AssignedUserAccountId)
                .HasConstraintName("FK_ServiceRequest_AssignedUserAccount");

            entity.HasOne(d => d.ServiceRequestStatus).WithMany(p => p.ServiceRequest)
                .HasForeignKey(d => d.ServiceRequestStatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ServiceRequest_ServiceRequestStatus");

            entity.HasOne(d => d.ServiceRequestType).WithMany(p => p.ServiceRequest)
                .HasForeignKey(d => d.ServiceRequestTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ServiceRequest_ServiceRequestType");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.ServiceRequest)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ServiceRequest_VendingMachine");
        });

        modelBuilder.Entity<ServiceRequestStatus>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_ServiceRequestStatus_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<ServiceRequestStatusHistory>(entity =>
        {
            entity.Property(e => e.ChangedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_ServiceRequestStatusHistory_ChangedAt");

            entity.HasOne(d => d.ChangedByUserAccount).WithMany(p => p.ServiceRequestStatusHistory)
                .HasForeignKey(d => d.ChangedByUserAccountId)
                .HasConstraintName("FK_ServiceRequestStatusHistory_UserAccount");

            entity.HasOne(d => d.ServiceRequest).WithMany(p => p.ServiceRequestStatusHistory)
                .HasForeignKey(d => d.ServiceRequestId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ServiceRequestStatusHistory_ServiceRequest");

            entity.HasOne(d => d.ServiceRequestStatus).WithMany(p => p.ServiceRequestStatusHistory)
                .HasForeignKey(d => d.ServiceRequestStatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ServiceRequestStatusHistory_ServiceRequestStatus");
        });

        modelBuilder.Entity<ServiceRequestType>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_ServiceRequestType_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<TimeZoneEntity>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_TimeZone_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<UserAccount>(entity =>
        {
            entity.HasIndex(e => e.Email, "UQ_UserAccount_Email").IsUnique();

            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_UserAccount_CreatedAt");
            entity.Property(e => e.Email).HasMaxLength(256);
            entity.Property(e => e.FirstName).HasMaxLength(100);
            entity.Property(e => e.IsActive).HasDefaultValue(true, "DF_UserAccount_IsActive");
            entity.Property(e => e.LastName).HasMaxLength(100);
            entity.Property(e => e.PasswordHash).HasMaxLength(255);
            entity.Property(e => e.PasswordSalt).HasMaxLength(255);
            entity.Property(e => e.Patronymic).HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(32);
            entity.Property(e => e.PhotoUrl).HasMaxLength(500);

            entity.HasOne(d => d.Company).WithMany(p => p.UserAccount)
                .HasForeignKey(d => d.CompanyId)
                .HasConstraintName("FK_UserAccount_Company");

            entity.HasOne(d => d.UserRole).WithMany(p => p.UserAccount)
                .HasForeignKey(d => d.UserRoleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_UserAccount_UserRole");

            entity.HasMany(d => d.VendingMachineModel).WithMany(p => p.UserAccount)
                .UsingEntity<Dictionary<string, object>>(
                    "UserAccountVendingMachineModel",
                    r => r.HasOne<VendingMachineModel>().WithMany()
                        .HasForeignKey("VendingMachineModelId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_UserAccountVendingMachineModel_VendingMachineModel"),
                    l => l.HasOne<UserAccount>().WithMany()
                        .HasForeignKey("UserAccountId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_UserAccountVendingMachineModel_UserAccount"),
                    j =>
                    {
                        j.HasKey("UserAccountId", "VendingMachineModelId");
                    });
        });

        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_UserRole_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(50);
        });

        modelBuilder.Entity<VendingMachine>(entity =>
        {
            entity.HasIndex(e => e.ExternalId, "UQ_VendingMachine_ExternalId").IsUnique();

            entity.HasIndex(e => e.InventoryNumber, "UQ_VendingMachine_InventoryNumber").IsUnique();

            entity.HasIndex(e => e.SerialNumber, "UQ_VendingMachine_SerialNumber").IsUnique();

            entity.Property(e => e.Address).HasMaxLength(300);
            entity.Property(e => e.CreatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_VendingMachine_CreatedAt");
            entity.Property(e => e.ExternalId)
                .HasDefaultValueSql("(newsequentialid())", "DF_VendingMachine_ExternalId");
            entity.Property(e => e.InventoryNumber).HasMaxLength(50);
            entity.Property(e => e.KitOnlineCashRegisterId).HasMaxLength(50);
            entity.Property(e => e.Latitude).HasColumnType("decimal(9, 6)");
            entity.Property(e => e.Longitude).HasColumnType("decimal(9, 6)");
            entity.Property(e => e.Name).HasMaxLength(200);
            entity.Property(e => e.NextVerificationDate).HasComputedColumnSql("(case when [LastVerificationDate] IS NULL OR [VerificationIntervalMonths] IS NULL then NULL else dateadd(month,[VerificationIntervalMonths],[LastVerificationDate]) end)", false);
            entity.Property(e => e.Notes).HasMaxLength(1000);
            entity.Property(e => e.Place).HasMaxLength(200);
            entity.Property(e => e.SerialNumber).HasMaxLength(50);
            entity.Property(e => e.WorkingTimeFrom).HasPrecision(0);
            entity.Property(e => e.WorkingTimeTo).HasPrecision(0);

            entity.HasOne(d => d.Company).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.CompanyId)
                .HasConstraintName("FK_VendingMachine_Company");

            entity.HasOne(d => d.Country).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.CountryId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachine_Country");

            entity.HasOne(d => d.CriticalValuesTemplate).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.CriticalValuesTemplateId)
                .HasConstraintName("FK_VendingMachine_CriticalValuesTemplate");

            entity.HasOne(d => d.EngineerUserAccount).WithMany(p => p.VendingMachineEngineerUserAccount)
                .HasForeignKey(d => d.EngineerUserAccountId)
                .HasConstraintName("FK_VendingMachine_EngineerUserAccount");

            entity.HasOne(d => d.LastVerificationUserAccount).WithMany(p => p.VendingMachineLastVerificationUserAccount)
                .HasForeignKey(d => d.LastVerificationUserAccountId)
                .HasConstraintName("FK_VendingMachine_LastVerificationUserAccount");

            entity.HasOne(d => d.ManagerUserAccount).WithMany(p => p.VendingMachineManagerUserAccount)
                .HasForeignKey(d => d.ManagerUserAccountId)
                .HasConstraintName("FK_VendingMachine_ManagerUserAccount");

            entity.HasOne(d => d.Modem).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.ModemId)
                .HasConstraintName("FK_VendingMachine_Modem");

            entity.HasOne(d => d.NotificationTemplate).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.NotificationTemplateId)
                .HasConstraintName("FK_VendingMachine_NotificationTemplate");

            entity.HasOne(d => d.ProductMatrix).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.ProductMatrixId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachine_ProductMatrix");

            entity.HasOne(d => d.ServicePriority).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.ServicePriorityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachine_ServicePriority");

            entity.HasOne(d => d.TechnicianOperatorUserAccount).WithMany(p => p.VendingMachineTechnicianOperatorUserAccount)
                .HasForeignKey(d => d.TechnicianOperatorUserAccountId)
                .HasConstraintName("FK_VendingMachine_TechnicianOperatorUserAccount");

            entity.HasOne(d => d.TimeZone).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.TimeZoneId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachine_TimeZone");

            entity.HasOne(d => d.VendingMachineModel).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.VendingMachineModelId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachine_VendingMachineModel");

            entity.HasOne(d => d.VendingMachineStatus).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.VendingMachineStatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachine_VendingMachineStatus");

            entity.HasOne(d => d.WorkMode).WithMany(p => p.VendingMachine)
                .HasForeignKey(d => d.WorkModeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachine_WorkMode");

            entity.HasMany(d => d.PaymentSystem).WithMany(p => p.VendingMachine)
                .UsingEntity<Dictionary<string, object>>(
                    "VendingMachinePaymentSystem",
                    r => r.HasOne<PaymentSystem>().WithMany()
                        .HasForeignKey("PaymentSystemId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_VendingMachinePaymentSystem_PaymentSystem"),
                    l => l.HasOne<VendingMachine>().WithMany()
                        .HasForeignKey("VendingMachineId")
                        .OnDelete(DeleteBehavior.ClientSetNull)
                        .HasConstraintName("FK_VendingMachinePaymentSystem_VendingMachine"),
                    j =>
                    {
                        j.HasKey("VendingMachineId", "PaymentSystemId");
                    });
        });

        modelBuilder.Entity<VendingMachineEquipment>(entity =>
        {
            entity.HasKey(e => new { e.VendingMachineId, e.EquipmentTypeId });

            entity.Property(e => e.UpdatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_VendingMachineEquipment_UpdatedAt");

            entity.HasOne(d => d.EquipmentType).WithMany(p => p.VendingMachineEquipment)
                .HasForeignKey(d => d.EquipmentTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineEquipment_EquipmentType");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.VendingMachineEquipment)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineEquipment_VendingMachine");
        });

        modelBuilder.Entity<VendingMachineEvent>(entity =>
        {
            entity.Property(e => e.Message).HasMaxLength(500);
            entity.Property(e => e.OccurredAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_VendingMachineEvent_OccurredAt");

            entity.HasOne(d => d.EventType).WithMany(p => p.VendingMachineEvent)
                .HasForeignKey(d => d.EventTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineEvent_EventType");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.VendingMachineEvent)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineEvent_VendingMachine");
        });

        modelBuilder.Entity<VendingMachineIncome>(entity =>
        {
            entity
                .HasNoKey()
                .ToView("VendingMachineIncome");

            entity.Property(e => e.TotalIncome).HasColumnType("decimal(38, 2)");
        });

        modelBuilder.Entity<VendingMachineManufacturer>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_VendingMachineManufacturer_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(150);
        });

        modelBuilder.Entity<VendingMachineModel>(entity =>
        {
            entity.HasIndex(e => new { e.VendingMachineManufacturerId, e.Name }, "UQ_VendingMachineModel_Manufacturer_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(150);

            entity.HasOne(d => d.VendingMachineManufacturer).WithMany(p => p.VendingMachineModel)
                .HasForeignKey(d => d.VendingMachineManufacturerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineModel_VendingMachineManufacturer");
        });

        modelBuilder.Entity<VendingMachineProduct>(entity =>
        {
            entity.HasKey(e => new { e.VendingMachineId, e.ProductId });

            entity.Property(e => e.AverageDailySales).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.UpdatedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_VendingMachineProduct_UpdatedAt");

            entity.HasOne(d => d.Product).WithMany(p => p.VendingMachineProduct)
                .HasForeignKey(d => d.ProductId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineProduct_Product");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.VendingMachineProduct)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineProduct_VendingMachine");
        });

        modelBuilder.Entity<VendingMachineRfidCard>(entity =>
        {
            entity.HasKey(e => new { e.VendingMachineId, e.RfidCardId, e.RfidCardTypeId });

            entity.HasOne(d => d.RfidCard).WithMany(p => p.VendingMachineRfidCard)
                .HasForeignKey(d => d.RfidCardId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineRfidCard_RfidCard");

            entity.HasOne(d => d.RfidCardType).WithMany(p => p.VendingMachineRfidCard)
                .HasForeignKey(d => d.RfidCardTypeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineRfidCard_RfidCardType");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.VendingMachineRfidCard)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineRfidCard_VendingMachine");
        });

        modelBuilder.Entity<VendingMachineStatus>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_VendingMachineStatus_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<VendingMachineStatusHistory>(entity =>
        {
            entity.Property(e => e.ChangedAt)
                .HasPrecision(0)
                .HasDefaultValueSql("(sysdatetime())", "DF_VendingMachineStatusHistory_ChangedAt");

            entity.HasOne(d => d.ChangedByUserAccount).WithMany(p => p.VendingMachineStatusHistory)
                .HasForeignKey(d => d.ChangedByUserAccountId)
                .HasConstraintName("FK_VendingMachineStatusHistory_UserAccount");

            entity.HasOne(d => d.VendingMachine).WithMany(p => p.VendingMachineStatusHistory)
                .HasForeignKey(d => d.VendingMachineId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineStatusHistory_VendingMachine");

            entity.HasOne(d => d.VendingMachineStatus).WithMany(p => p.VendingMachineStatusHistory)
                .HasForeignKey(d => d.VendingMachineStatusId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_VendingMachineStatusHistory_VendingMachineStatus");
        });

        modelBuilder.Entity<WorkMode>(entity =>
        {
            entity.HasIndex(e => e.Name, "UQ_WorkMode_Name").IsUnique();

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
