/*
    ImportData.sql (Microsoft SQL Server)
    Source: ../Import
    Generated: 2025-12-15 23:10:15
    Default password for imported users: P@ssw0rd!
*/

USE [VendingService];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    /* ===== Ensure required lookup values ===== */
    MERGE dbo.WorkMode AS target
    USING (VALUES
        (N'Стандартный'),
        (N'Тестовый')
    ) AS source (Name)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name) VALUES (source.Name);

    MERGE dbo.TimeZone AS target
    USING (VALUES
        (N'UTC+3', CAST(180 AS smallint)),
        (N'UTC+4', CAST(240 AS smallint)),
        (N'UTC+5', CAST(300 AS smallint)),
        (N'UTC+6', CAST(360 AS smallint))
    ) AS source (Name, UtcOffsetMinutes)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name, UtcOffsetMinutes) VALUES (source.Name, source.UtcOffsetMinutes)
    WHEN MATCHED AND target.UtcOffsetMinutes <> source.UtcOffsetMinutes THEN
        UPDATE SET UtcOffsetMinutes = source.UtcOffsetMinutes;

    MERGE dbo.CriticalValuesTemplate AS target
    USING (VALUES
        (N'Расширенный', NULL),
        (N'Стандартный', NULL)
    ) AS source (Name, Description)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name, Description) VALUES (source.Name, source.Description);

    MERGE dbo.NotificationTemplate AS target
    USING (VALUES
        (N'Расширенный', NULL),
        (N'Стандартный', NULL)
    ) AS source (Name, Description)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name, Description) VALUES (source.Name, source.Description);

    MERGE dbo.ServiceRequestType AS target
    USING (VALUES
        (N'Плановое техническое обслуживание'),
        (N'Аварийное обслуживание')
    ) AS source (Name)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name) VALUES (source.Name);

MERGE dbo.ServiceRequestStatus AS target
USING (VALUES
        (N'Авария', 5),
        (N'Новая', 10),
        (N'В работе', 20),
        (N'Отменена', 30),
        (N'Закрыта', 40)
) AS source (Name, SortOrder)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name, SortOrder) VALUES (source.Name, source.SortOrder)
    WHEN MATCHED AND target.SortOrder <> source.SortOrder THEN
        UPDATE SET SortOrder = source.SortOrder;

    MERGE dbo.UserRole AS target
    USING (VALUES
        (N'Администратор'),
        (N'Оператор'),
        (N'Менеджер'),
        (N'Инженер'),
        (N'Техник-оператор'),
        (N'Франчайзи')
    ) AS source (Name)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name) VALUES (source.Name);

    MERGE dbo.Company AS target
    USING (VALUES
        (N'ООО ВендингСервис Плюс', NULL, NULL, NULL),
        (N'ООО Про Вендинг Групп', NULL, NULL, NULL),
        (N'ООО Торговые Аппараты', NULL, NULL, NULL)
    ) AS source (Name, Phone, Email, Address)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name, Phone, Email, Address) VALUES (source.Name, source.Phone, source.Email, source.Address);

    MERGE dbo.VendingMachineManufacturer AS target
    USING (VALUES
        (N'Bianchi'),
        (N'Necta'),
        (N'Rheavendors'),
        (N'Unicum')
    ) AS source (Name)
    ON target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (Name) VALUES (source.Name);

    MERGE dbo.VendingMachineModel AS target
    USING
    (
        SELECT m.VendingMachineManufacturerId, v.Name
        FROM (VALUES
            (N'Bianchi', N'BVM 972'),
            (N'Necta', N'Kikko ES6'),
            (N'Necta', N'Kikko Max'),
            (N'Rheavendors', N'Luce E5'),
            (N'Unicum', N'Food Box'),
            (N'Unicum', N'Rosso')
        ) AS v(ManufacturerName, Name)
        INNER JOIN dbo.VendingMachineManufacturer m ON m.Name = v.ManufacturerName
    ) AS source (VendingMachineManufacturerId, Name)
    ON target.VendingMachineManufacturerId = source.VendingMachineManufacturerId AND target.Name = source.Name
    WHEN NOT MATCHED THEN
        INSERT (VendingMachineManufacturerId, Name) VALUES (source.VendingMachineManufacturerId, source.Name);

    /* ===== Import users ===== */
    IF OBJECT_ID(N'tempdb..#UserImport') IS NOT NULL DROP TABLE #UserImport;
    CREATE TABLE #UserImport
    (
        ExternalId uniqueidentifier NOT NULL,
        Email nvarchar(256) NOT NULL,
        Phone nvarchar(32) NULL,
        LastName nvarchar(100) NOT NULL,
        FirstName nvarchar(100) NOT NULL,
        Patronymic nvarchar(100) NULL,
        RoleName nvarchar(50) NOT NULL,
        PasswordHash nvarchar(255) NOT NULL,
        PasswordSalt nvarchar(255) NOT NULL
    );

    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('01f0b7d3-9b64-49d0-b63e-9190d736d091', N'leonid_53@example.com', N'8 (090) 299-0930', N'Тимофеева', N'Наталья', N'Николаевна', N'Инженер', N'MKWOHD7/iKAYXB8+DkVpYuvVUNlgqiQLsDjty5W7kyY=', N'Y3Ad9CEiZtiubC+uQGgYOA==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('108519e5-d8b4-419a-ac60-4bedecc9e204', N'gleb_1990@example.com', N'+77443080370', N'Исаков', N'Варлаам', N'Викентьевич', N'Франчайзи', N'rKNfVqBt3HV4PkKuzCt8hrKhgq5maIKiFqxmMPjIHGU=', N'N49XZKxXD//nFGzpkiYkrw==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('20b7e4c6-0cba-4eb4-afa9-4d3a6a8d34c6', N'ladislav1994@example.com', N'8 (524) 644-9886', N'Родионов', N'Герман', N'Трофимович', N'Франчайзи', N'qbhRA7HeXIYo+j6c7/dZ1XRrAtF/DvG68NtfludkvEk=', N'qQut25E+u/f1lhJLDxZWBA==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('35886293-c787-4cde-b7fa-83fafc3f85b3', N'bvorobeva@example.com', N'8 (137) 651-90-60', N'Евдокимова', N'Ольга', N'Архиповна', N'Франчайзи', N'WsMlgOD5peTtGt3wc8v1PMiYBNdafWWq66QnZAgkqN8=', N'tDbFdmoQxxpEszugyhim9Q==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('379cd69b-c8c0-453c-b81b-a0dcf6e4c87c', N'kir1994@example.org', N'8 451 035 57 18', N'Медведев', N'Софрон', N'Ерофеевич', N'Оператор', N'+Y41wcUN+4ZRdjtZAu0xVTXlgJ4BLRf0rsnrGhMzQpw=', N'LGU2IYZRt50MKoJn9rdfvg==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('4c945c54-ac77-4334-bf64-cc5ccc7a6ed2', N'visheslav82@example.org', N'8 (306) 825-6208', N'Жданов', N'Будимир', N'Харламович', N'Франчайзи', N'D1v/p0GSRQQZPh4/aJBmb+1uT4yI1z2KEuv5khaOlpk=', N'1Xf4s5e70WpTGAYyjz5Pkg==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('6200eaa4-64f2-465f-8873-edcc30105bc7', N'evgraf13@example.net', N'8 (276) 045-94-68', N'Тихонов', N'Аверьян', N'Елисеевич', N'Франчайзи', N'1vEGAG9mgdkIjoZ1iOsRcnpPZ+1cVvdXo6rEpgTln1k=', N'fcs1KcIxUdC8meTTM9R5sA==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('62c8a8ea-a46a-4995-8794-3f649089315a', N'burovvsevolod@example.net', N'+7 140 463 65 52', N'Белов', N'Ян', N'Фадеевич', N'Франчайзи', N'+MJhtNhlHDml9t5KEKs5dJqImbM1LqkVP7zKk9JC/ms=', N'zHvWN0WIkIWKTO2iJO0AvA==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('6cccfbd6-11c7-4745-be39-6a1dfb3ea453', N'spartak_44@example.net', N'+7 783 514 09 48', N'Рыбаков', N'Ефрем', N'Алексеевич', N'Франчайзи', N'QDrYYYkbC/0D81ms7DundjlF09vIEv2gp2ZtxyXeT0I=', N'S7xoU/8luDSbGXMQ0oppCA==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('702076df-6488-46ba-b07c-faf826bea3b5', N'leonti_1971@example.com', N'8 (019) 101-95-72', N'Александров', N'Стоян', N'Алексеевич', N'Франчайзи', N'kxkYhy2zvOC7SibqWBlGyQm2UgAaDHlrdIG33BKj/s8=', N'2yCMPzuJmFyg3/H5rurrLw==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('7a051229-40bb-443e-80b8-024cb239f52b', N'epestova@example.net', N'+73700031752', N'Новиков', N'Ипполит', N'Власович', N'Менеджер', N'YxhUDCJ1s7Ef5WcQW4f6s0lQpZcIdbvB96EtZbAoi/U=', N'Kucu15SZbWciVjWZPIIX9A==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('8b3785df-b3fc-43e6-a8f6-221b584960de', N'noskovnikifor@example.com', N'+7 (252) 454-63-04', N'Баранов', N'Ефим', N'Фокич', N'Франчайзи', N'G7zD7xDJf+8QxLv/lRzql/w6huId9FtccsCZ7ueiX/0=', N'6fjkp6FNdZJL98ZVRgjhKw==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('ae13a1b0-0be5-460e-a362-638f935f1d75', N'spartak1991@example.org', N'+7 192 222 6547', N'Тетерина', N'Надежда', N'Федоровна', N'Франчайзи', N'AiWtsKa5lnQ5k6P2EuDfix9wAyipLVjamCyXIaXpqQE=', N'oTyH3nem2QlaTELLQuUybg==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('af4fbc9f-37ca-45ff-bb94-494c348d876f', N'eliseevnestor@example.com', N'+7 (247) 706-26-55', N'Степанова', N'Марфа', N'Юльевна', N'Инженер', N'SeMDNA19FigA6N4s9suzJHFehd56bQRpi5N0qRJZN1o=', N'ahjQPfSXXXGaNLvKo1oDKA==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('b38b5bfe-a0f9-481e-b2af-3c6bf43297d2', N'leonid72@example.com', N'8 (936) 706-43-27', N'Силин', N'Эрнст', N'Георгиевич', N'Инженер', N'oLSCqL0aJpoTJneBmsru31OvbsPcpDgbPIXRpdgVoQM=', N'XqTk90BumZBFP3KKPnLRiw==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('c59a07db-17d1-4769-9d5c-19c0ab4d435c', N'glebvolkov@example.net', N'+7 330 597 33 18', N'Воробьева', N'Таисия', N'Альбертовна', N'Менеджер', N'+G28lVQCMF4EXPlXPNorB9CJVE1D31iEkbKLa02xFoU=', N'2CRZGYSWtgiG0GcBzmwDMg==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('d82a5505-35aa-4243-873c-0488e61d62a5', N'fadeustinov@example.org', N'+7 180 580 5233', N'Степанов', N'Юлиан', N'Геннадиевич', N'Оператор', N'EoIw79jo5RVyNS6PfxoAq7f+Ki+8EjwCG1vydk76WgY=', N'Vm6w2V5Gvv9Z8hQmMhUoMw==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('da384682-1b30-466a-8482-2b7a7fc97e71', N'sevastjandavidov@example.com', N'+7 744 082 0443', N'Жуков', N'Милий', N'Григорьевич', N'Инженер', N'MBZNrAZLoLorPYlYOmaCgmkED7Lv+9zZ3LCCaAGnkNI=', N'Xtug0V37MjABC/OL8TTJ5g==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('ec90762d-3e3d-413a-b8c5-b86c93ddb52f', N'vorobevmiroslav@example.net', N'8 042 327 4787', N'Никонова', N'Олимпиада', N'Леонидовна', N'Оператор', N'NnSbnI2HNsHNQXyJ9XHh+HtSTaxZU26R66wyfp5wPHc=', N'TzV0NnUvlCCb/DpIhyJjRA==');
    INSERT INTO #UserImport (ExternalId, Email, Phone, LastName, FirstName, Patronymic, RoleName, PasswordHash, PasswordSalt) VALUES ('f9e38a01-137d-454e-93fe-6a736fcb06e5', N'ivanovgrigori@example.net', N'8 391 759 25 55', N'Прохорова', N'Элеонора', N'Егоровна', N'Франчайзи', N'WyALLrU5W9zmo8E7EMtAO0TGU4+CVoYDhIbt64oYHA4=', N'z8Phbcq8OIrEj7cRqjbQXg==');

    INSERT INTO dbo.UserAccount
    (Email, Phone, LastName, FirstName, Patronymic, PasswordHash, PasswordSalt, PhotoUrl, UserRoleId, CompanyId, IsActive, CreatedAt)
    SELECT
        ui.Email,
        ui.Phone,
        ui.LastName,
        ui.FirstName,
        ui.Patronymic,
        ui.PasswordHash,
        ui.PasswordSalt,
        NULL,
        ur.UserRoleId,
        NULL,
        1,
        SYSDATETIME()
    FROM #UserImport ui
    INNER JOIN dbo.UserRole ur ON ur.Name = ui.RoleName
    LEFT JOIN dbo.UserAccount ua ON ua.Email = ui.Email
    WHERE ua.UserAccountId IS NULL;

    IF OBJECT_ID(N'tempdb..#UserMap') IS NOT NULL DROP TABLE #UserMap;
    CREATE TABLE #UserMap (ExternalId uniqueidentifier NOT NULL PRIMARY KEY, UserAccountId int NOT NULL);
    INSERT INTO #UserMap (ExternalId, UserAccountId)
    SELECT ui.ExternalId, ua.UserAccountId
    FROM #UserImport ui
    INNER JOIN dbo.UserAccount ua ON ua.Email = ui.Email;

    /* ===== Import vending machines ===== */
    IF OBJECT_ID(N'tempdb..#VendingMachineImport') IS NOT NULL DROP TABLE #VendingMachineImport;
    CREATE TABLE #VendingMachineImport
    (
        ExternalId uniqueidentifier NOT NULL,
        Name nvarchar(200) NOT NULL,
        SerialNumber nvarchar(50) NOT NULL,
        InventoryNumber nvarchar(50) NOT NULL,
        ManufacturerName nvarchar(150) NOT NULL,
        ModelName nvarchar(150) NOT NULL,
        CompanyName nvarchar(200) NOT NULL,
        WorkModeName nvarchar(100) NOT NULL,
        TimeZoneName nvarchar(50) NOT NULL,
        StatusName nvarchar(100) NOT NULL,
        ServicePriorityName nvarchar(50) NOT NULL,
        Address nvarchar(300) NOT NULL,
        Place nvarchar(200) NOT NULL,
        Latitude decimal(9,6) NULL,
        Longitude decimal(9,6) NULL,
        WorkingTimeFrom time(0) NULL,
        WorkingTimeTo time(0) NULL,
        CriticalTemplateName nvarchar(150) NULL,
        NotificationTemplateName nvarchar(150) NULL,
        ManagerLastName nvarchar(100) NULL,
        ManagerFirstName nvarchar(100) NULL,
        ManagerPatronymic nvarchar(100) NULL,
        EngineerLastName nvarchar(100) NULL,
        EngineerFirstName nvarchar(100) NULL,
        EngineerPatronymic nvarchar(100) NULL,
        TechnicianLastName nvarchar(100) NULL,
        TechnicianFirstName nvarchar(100) NULL,
        TechnicianPatronymic nvarchar(100) NULL,
        KitOnlineCashRegisterId nvarchar(50) NULL,
        Notes nvarchar(1000) NULL,
        InstallDate date NOT NULL
    );

    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('dc92a945-80cf-4c86-8927-97026c6e82da', N'Офис Газпром', N'87654328', N'INV-87654328', N'Rheavendors', N'Luce E5', N'ООО Торговые Аппараты', N'Стандартный', N'UTC+5', N'В ремонте/на обслуживании', N'Средний', N'с. Бийск, ш. Астраханское, д. 22 к. 5, 022400', N'У входа', 83.357794, -63.240092, N'9:00', N'18:00', N'Расширенный', N'Стандартный', N'Новиков', N'Ипполит', N'Власович', N'Новиков', N'Ипполит', N'Власович', N'Воробьева', N'Таисия', N'Альбертовна', N'Kit-766268', N'Неисправен купюроприемник', '2023-06-02');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'БЦ Арма', N'98654398', N'INV-98654398', N'Unicum', N'Rosso', N'ООО Про Вендинг Групп', N'Тестовый', N'UTC+6', N'Вышел из строя', N'Высокий', N'п. Токсово, пр. Мостовой, д. 7 стр. 668, 578638', N'У входа', -25.735753, -67.520209, N'9:00', N'18:00', N'Стандартный', N'Расширенный', N'Воробьева', N'Таисия', N'Альбертовна', N'Силин', N'Эрнст', N'Георгиевич', N'Воробьева', N'Таисия', N'Альбертовна', N'Kit-232195', NULL, '2023-05-31');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Вокзал', N'76589076', N'INV-76589076', N'Bianchi', N'BVM 972', N'ООО ВендингСервис Плюс', N'Тестовый', N'UTC+3', N'В ремонте/на обслуживании', N'Низкий', N'г. Карабулак, наб. Трудовая, д. 4 к. 15, 495584', N'Офис', 75.504369, 33.272490, N'9:00', N'18:00', NULL, N'Расширенный', N'Новиков', N'Ипполит', N'Власович', N'Силин', N'Эрнст', N'Георгиевич', N'Воробьева', N'Таисия', N'Альбертовна', N'Kit-634265', NULL, '2024-09-11');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Фитнес-клуб Атлетика', N'87432986', N'INV-87432986', N'Bianchi', N'BVM 972', N'ООО Торговые Аппараты', N'Тестовый', N'UTC+5', N'Работает', N'Низкий', N'клх Чебоксары, ул. Чайкиной, д. 63, 919017', N'Офис', -27.117282, 97.259712, N'9:00', N'18:00', N'Стандартный', NULL, N'Новиков', N'Ипполит', N'Власович', N'Степанова', N'Марфа', N'Юльевна', N'Новиков', N'Ипполит', N'Власович', N'Kit-810157', N'Требуется обновление ПО', '2023-06-11');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'МФЦ', N'87309876', N'INV-87309876', N'Bianchi', N'BVM 972', N'ООО Торговые Аппараты', N'Стандартный', N'UTC+4', N'В ремонте/на обслуживании', N'Средний', N'д. Верхний Уфалей, наб. Белинского, д. 6 стр. 6, 518880', N'Холл', -2.842960, -145.137150, N'9:00', N'18:00', N'Стандартный', NULL, N'Воробьева', N'Таисия', N'Альбертовна', N'Силин', N'Эрнст', N'Георгиевич', N'Никонова', N'Олимпиада', N'Леонидовна', N'Kit-986460', NULL, '2024-01-05');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'БЦ Центральный', N'54298765', N'INV-54298765', N'Unicum', N'Rosso', N'ООО ВендингСервис Плюс', N'Тестовый', N'UTC+5', N'Вышел из строя', N'Высокий', N'г. Аша, пр. Кольцевой, д. 26 стр. 7, 571343', N'У входа', -89.600654, -95.036334, N'9:00', N'18:00', NULL, N'Стандартный', N'Воробьева', N'Таисия', N'Альбертовна', N'Степанова', N'Марфа', N'Юльевна', N'Новиков', N'Ипполит', N'Власович', N'Kit-824099', N'Необходимо пополнить товарную матрицу', '2025-02-24');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Офис Газпром', N'76589074', N'INV-76589074', N'Necta', N'Kikko ES6', N'ООО Торговые Аппараты', N'Стандартный', N'UTC+5', N'Работает', N'Средний', N'клх Быково (метеост.), пер. Каштановый, д. 1/6 к. 579, 035670', N'Холл', -37.748709, -36.631582, N'9:00', N'18:00', N'Расширенный', N'Стандартный', N'Воробьева', N'Таисия', N'Альбертовна', N'Жуков', N'Милий', N'Григорьевич', N'Новиков', N'Ипполит', N'Власович', N'Kit-192398', NULL, '2023-05-25');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Поликлиника №7', N'87654098', N'INV-87654098', N'Rheavendors', N'Luce E5', N'ООО Торговые Аппараты', N'Стандартный', N'UTC+3', N'Вышел из строя', N'Низкий', N'клх Курчатов, ш. Школьное, д. 954, 494797', N'Главный вход', 56.339718, 79.363367, N'9:00', N'18:00', N'Расширенный', N'Расширенный', N'Новиков', N'Ипполит', N'Власович', N'Жуков', N'Милий', N'Григорьевич', N'Воробьева', N'Таисия', N'Альбертовна', N'Kit-751595', N'Необходимо пополнить товарную матрицу', '2024-06-02');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('a977e322-192c-4567-9f5f-36f504bfc13d', N'Аэропорт', N'67905436', N'INV-67905436', N'Necta', N'Kikko Max', N'ООО ВендингСервис Плюс', N'Тестовый', N'UTC+4', N'В ремонте/на обслуживании', N'Низкий', N'д. Осташков, ш. Мелиоративное, д. 458 к. 532, 407622', N'У входа', 89.798638, -17.002600, N'9:00', N'18:00', N'Стандартный', N'Расширенный', N'Воробьева', N'Таисия', N'Альбертовна', N'Новиков', N'Ипполит', N'Власович', N'Новиков', N'Ипполит', N'Власович', N'Kit-114271', N'Требуется обновление ПО', '2024-09-25');
    INSERT INTO #VendingMachineImport (ExternalId, Name, SerialNumber, InventoryNumber, ManufacturerName, ModelName, CompanyName, WorkModeName, TimeZoneName, StatusName, ServicePriorityName, Address, Place, Latitude, Longitude, WorkingTimeFrom, WorkingTimeTo, CriticalTemplateName, NotificationTemplateName, ManagerLastName, ManagerFirstName, ManagerPatronymic, EngineerLastName, EngineerFirstName, EngineerPatronymic, TechnicianLastName, TechnicianFirstName, TechnicianPatronymic, KitOnlineCashRegisterId, Notes, InstallDate) VALUES ('70f22c9f-de0a-41a9-9a53-cabf42688d47', N'БЦ Арма', N'78529127', N'INV-78529127', N'Unicum', N'Food Box', N'ООО Торговые Аппараты', N'Тестовый', N'UTC+3', N'В ремонте/на обслуживании', N'Низкий', N'к. Гусь-Хрустальный, ш. З.Космодемьянской, д. 136 к. 4, 011188', N'У входа', -72.182146, 28.717243, N'9:00', N'18:00', N'Стандартный', NULL, N'Воробьева', N'Таисия', N'Альбертовна', N'Силин', N'Эрнст', N'Георгиевич', N'Новиков', N'Ипполит', N'Власович', N'Kit-783649', N'Требуется обновление ПО', '2023-07-26');

    INSERT INTO dbo.VendingMachine
    (
        ExternalId,
        Name,
        VendingMachineModelId,
        WorkModeId,
        TimeZoneId,
        VendingMachineStatusId,
        ServicePriorityId,
        ProductMatrixId,
        CompanyId,
        ModemId,
        Address,
        Place,
        Latitude,
        Longitude,
        InventoryNumber,
        SerialNumber,
        ManufactureDate,
        CommissioningDate,
        CountryId,
        WorkingTimeFrom,
        WorkingTimeTo,
        CriticalValuesTemplateId,
        NotificationTemplateId,
        ManagerUserAccountId,
        EngineerUserAccountId,
        TechnicianOperatorUserAccountId,
        KitOnlineCashRegisterId,
        Notes
    )
    SELECT
        i.ExternalId,
        i.Name,
        model.VendingMachineModelId,
        wm.WorkModeId,
        tz.TimeZoneId,
        st.VendingMachineStatusId,
        sp.ServicePriorityId,
        pm.ProductMatrixId,
        c.CompanyId,
        NULL,
        i.Address,
        i.Place,
        i.Latitude,
        i.Longitude,
        i.InventoryNumber,
        i.SerialNumber,
        i.InstallDate,
        i.InstallDate,
        country.CountryId,
        i.WorkingTimeFrom,
        i.WorkingTimeTo,
        ct.CriticalValuesTemplateId,
        nt.NotificationTemplateId,
        manager.UserAccountId,
        engineer.UserAccountId,
        tech.UserAccountId,
        i.KitOnlineCashRegisterId,
        i.Notes
    FROM #VendingMachineImport i
    INNER JOIN dbo.Company c ON c.Name = i.CompanyName
    INNER JOIN dbo.WorkMode wm ON wm.Name = i.WorkModeName
    INNER JOIN dbo.TimeZone tz ON tz.Name = i.TimeZoneName
    INNER JOIN dbo.VendingMachineStatus st ON st.Name = i.StatusName
    INNER JOIN dbo.ServicePriority sp ON sp.Name = i.ServicePriorityName
    INNER JOIN dbo.ProductMatrix pm ON pm.Name = N'Не установлена'
    INNER JOIN dbo.Country country ON country.Name = N'Россия'
    INNER JOIN dbo.VendingMachineManufacturer man ON man.Name = i.ManufacturerName
    INNER JOIN dbo.VendingMachineModel model ON model.VendingMachineManufacturerId = man.VendingMachineManufacturerId AND model.Name = i.ModelName
    LEFT JOIN dbo.CriticalValuesTemplate ct ON ct.Name = i.CriticalTemplateName
    LEFT JOIN dbo.NotificationTemplate nt ON nt.Name = i.NotificationTemplateName
    LEFT JOIN dbo.UserAccount manager ON manager.LastName = i.ManagerLastName AND manager.FirstName = i.ManagerFirstName AND ISNULL(manager.Patronymic, N'') = ISNULL(i.ManagerPatronymic, N'')
    LEFT JOIN dbo.UserAccount engineer ON engineer.LastName = i.EngineerLastName AND engineer.FirstName = i.EngineerFirstName AND ISNULL(engineer.Patronymic, N'') = ISNULL(i.EngineerPatronymic, N'')
    LEFT JOIN dbo.UserAccount tech ON tech.LastName = i.TechnicianLastName AND tech.FirstName = i.TechnicianFirstName AND ISNULL(tech.Patronymic, N'') = ISNULL(i.TechnicianPatronymic, N'')
    LEFT JOIN dbo.VendingMachine existing ON existing.SerialNumber = i.SerialNumber
    WHERE existing.VendingMachineId IS NULL;

    -- Если ТА уже существует в БД (по SerialNumber), обновляем внешний GUID из ресурсов.
    UPDATE vm
    SET vm.ExternalId = i.ExternalId
    FROM dbo.VendingMachine vm
    INNER JOIN #VendingMachineImport i ON i.SerialNumber = vm.SerialNumber
    WHERE vm.ExternalId <> i.ExternalId;

    IF OBJECT_ID(N'tempdb..#VendingMachineMap') IS NOT NULL DROP TABLE #VendingMachineMap;
    CREATE TABLE #VendingMachineMap (ExternalId uniqueidentifier NOT NULL PRIMARY KEY, VendingMachineId int NOT NULL);
    INSERT INTO #VendingMachineMap (ExternalId, VendingMachineId)
    SELECT i.ExternalId, vm.VendingMachineId
    FROM #VendingMachineImport i
    INNER JOIN dbo.VendingMachine vm ON vm.ExternalId = i.ExternalId;

    /* ===== Import vending machine payment systems ===== */
    IF OBJECT_ID(N'tempdb..#VendingMachinePaymentImport') IS NOT NULL DROP TABLE #VendingMachinePaymentImport;
    CREATE TABLE #VendingMachinePaymentImport (VendingMachineExternalId uniqueidentifier NOT NULL, PaymentSystemName nvarchar(100) NOT NULL);

    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('dc92a945-80cf-4c86-8927-97026c6e82da', N'Монетоприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('dc92a945-80cf-4c86-8927-97026c6e82da', N'Купюроприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Модуль безналичной оплаты');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'QR-платежи');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Монетоприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Купюроприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Монетоприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Купюроприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Модуль безналичной оплаты');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'QR-платежи');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Купюроприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Модуль безналичной оплаты');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Модуль безналичной оплаты');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'QR-платежи');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Купюроприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Модуль безналичной оплаты');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('a977e322-192c-4567-9f5f-36f504bfc13d', N'Модуль безналичной оплаты');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('a977e322-192c-4567-9f5f-36f504bfc13d', N'QR-платежи');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Монетоприемник');
    INSERT INTO #VendingMachinePaymentImport (VendingMachineExternalId, PaymentSystemName) VALUES ('70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Купюроприемник');

    INSERT INTO dbo.VendingMachinePaymentSystem (VendingMachineId, PaymentSystemId)
    SELECT m.VendingMachineId, ps.PaymentSystemId
    FROM #VendingMachinePaymentImport i
    INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId
    INNER JOIN dbo.PaymentSystem ps ON ps.Name = i.PaymentSystemName
    LEFT JOIN dbo.VendingMachinePaymentSystem existing ON existing.VendingMachineId = m.VendingMachineId AND existing.PaymentSystemId = ps.PaymentSystemId
    WHERE existing.VendingMachineId IS NULL;

    /* ===== Import RFID cards ===== */
    IF OBJECT_ID(N'tempdb..#VendingMachineRfidImport') IS NOT NULL DROP TABLE #VendingMachineRfidImport;
    CREATE TABLE #VendingMachineRfidImport (VendingMachineExternalId uniqueidentifier NOT NULL, CardCode nvarchar(50) NOT NULL, CardTypeName nvarchar(50) NOT NULL);

    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('dc92a945-80cf-4c86-8927-97026c6e82da', N'RFID-SVC-2702', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('dc92a945-80cf-4c86-8927-97026c6e82da', N'RFID-CC-9117', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('dc92a945-80cf-4c86-8927-97026c6e82da', N'RFID-LD-8466', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'RFID-SVC-2298', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'RFID-CC-6093', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'RFID-LD-4375', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'RFID-SVC-1443', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'RFID-CC-6695', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'RFID-LD-9239', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'RFID-SVC-6725', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'RFID-CC-6848', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'RFID-LD-4442', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'RFID-SVC-4718', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'RFID-CC-2315', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'RFID-LD-8493', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'RFID-SVC-8442', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'RFID-CC-2644', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'RFID-LD-2429', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'RFID-SVC-8423', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'RFID-CC-6344', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'RFID-LD-7762', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('4daae871-71ac-44da-8b58-dcf1a2ae907a', N'RFID-SVC-8550', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('4daae871-71ac-44da-8b58-dcf1a2ae907a', N'RFID-CC-7800', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('4daae871-71ac-44da-8b58-dcf1a2ae907a', N'RFID-LD-8282', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('a977e322-192c-4567-9f5f-36f504bfc13d', N'RFID-SVC-6096', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('a977e322-192c-4567-9f5f-36f504bfc13d', N'RFID-CC-6319', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('a977e322-192c-4567-9f5f-36f504bfc13d', N'RFID-LD-1061', N'Загрузка');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('70f22c9f-de0a-41a9-9a53-cabf42688d47', N'RFID-SVC-3463', N'Обслуживание');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('70f22c9f-de0a-41a9-9a53-cabf42688d47', N'RFID-CC-1074', N'Инкассация');
    INSERT INTO #VendingMachineRfidImport (VendingMachineExternalId, CardCode, CardTypeName) VALUES ('70f22c9f-de0a-41a9-9a53-cabf42688d47', N'RFID-LD-5972', N'Загрузка');

    INSERT INTO dbo.RfidCard (CardCode)
    SELECT DISTINCT i.CardCode
    FROM #VendingMachineRfidImport i
    LEFT JOIN dbo.RfidCard c ON c.CardCode = i.CardCode
    WHERE c.RfidCardId IS NULL;

    INSERT INTO dbo.VendingMachineRfidCard (VendingMachineId, RfidCardId, RfidCardTypeId)
    SELECT m.VendingMachineId, c.RfidCardId, t.RfidCardTypeId
    FROM #VendingMachineRfidImport i
    INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId
    INNER JOIN dbo.RfidCard c ON c.CardCode = i.CardCode
    INNER JOIN dbo.RfidCardType t ON t.Name = i.CardTypeName
    LEFT JOIN dbo.VendingMachineRfidCard existing ON existing.VendingMachineId = m.VendingMachineId AND existing.RfidCardId = c.RfidCardId AND existing.RfidCardTypeId = t.RfidCardTypeId
    WHERE existing.VendingMachineId IS NULL;

    /* ===== Import products + vending machine stock ===== */
    IF OBJECT_ID(N'tempdb..#ProductImport') IS NOT NULL DROP TABLE #ProductImport;
    CREATE TABLE #ProductImport
    (
        ExternalId uniqueidentifier NOT NULL,
        Name nvarchar(200) NOT NULL,
        Description nvarchar(1000) NULL,
        Price decimal(18,2) NOT NULL,
        VendingMachineExternalId uniqueidentifier NOT NULL,
        QuantityOnHand int NOT NULL,
        MinimumStock int NOT NULL,
        AverageDailySales decimal(10,2) NULL
    );

    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('224cdcde-36ee-45da-9ae5-2588df8f96fb', N'Грушевый латте', N'Имеет мягкий вкус с лёгкой фруктовой сладостью.', 68.57, 'dc92a945-80cf-4c86-8927-97026c6e82da', 33, 20, 7.37);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('6392ebd8-2359-40df-a4f8-fb02fc2932d2', N'Персиковый американо', N'Имеет фруктовый вкус с нежным ароматом персика.', 175.44, 'dc92a945-80cf-4c86-8927-97026c6e82da', 72, 18, 4.92);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('514fef90-eb36-454f-968c-a02b1dbcf7d8', N'Облепиховый латте', N'Имеет кисло-сладкий вкус с ягодным акцентом.', 81.20, 'dc92a945-80cf-4c86-8927-97026c6e82da', 66, 5, 7.20);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('c3737840-6332-4bc6-b5bc-80f92f074f58', N'Кремовый латте', N'Имеет мягкий, сливочный вкус.', 124.51, 'dc92a945-80cf-4c86-8927-97026c6e82da', 49, 6, 4.13);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('d27ea808-ee98-4fd0-b867-b5a4a0576c68', N'Карамельный макиато', N'Имеет вкус с нотками тёплой карамели.', 162.23, 'dc92a945-80cf-4c86-8927-97026c6e82da', 28, 13, 7.08);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('69b065b6-8e39-44ba-b3a1-f5ca5cf01d57', N'Крем-брюле латте', N'Имеет сливочно-карамельный вкус десерта.', 63.99, '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 74, 11, 6.94);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('5144585b-9434-4fc9-89bf-b88784ea791d', N'Пряный латте', N'Имеет яркий вкус с добавлением специй.', 70.10, '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 47, 12, 1.87);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('db33e8df-278c-472c-a45a-c3ddb7374b3a', N'Тростниковый американо', N'Имеет вкус с сахарной сладостью.', 72.23, '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 26, 19, 2.42);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('50c6dd4f-70f2-4ec1-a80c-0fc0069f08c2', N'Двойной эспрессо', N'Имеет крепкий и насыщенный вкус кофе.', 192.14, '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 48, 7, 3.25);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('8aba3e58-49f7-44f0-9f7b-f8ad1cd570dc', N'Мятный раф', N'Имеет освежающий вкус с мятным ароматом.', 195.03, '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 47, 20, 1.50);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('8b889b5b-7567-45fa-97c9-09e56237d033', N'Цитрусовый эспрессо', N'Имеет освежающий вкус с цитрусовой кислинкой.', 175.75, '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 83, 18, 8.94);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('341529cf-dffb-4813-9c77-76f39f4445c7', N'Бодрящий эспрессо', N'Имеет яркий и насыщенный вкус для энергии.', 181.49, '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 93, 18, 1.13);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('64ad7e60-59c1-4a36-9e09-4f0038143720', N'Эспрессо с лаймом', N'Имеет кисло-свежий вкус с лаймовыми нотками.', 166.78, '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 76, 6, 7.81);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('e9aa2886-0ba0-4b7a-96dc-078855f99872', N'Медовый раф', N'Имеет натуральный вкус с мёдовой сладостью.', 139.55, '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 79, 17, 8.87);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('2d79e75e-c6b8-4138-8c0c-403325bf6944', N'Молочный капучино', N'Имеет мягкий и сливочный вкус.', 93.59, '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 11, 14, 1.89);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('8a12f87f-7b45-4a03-bc7a-69e5fbccbc5a', N'Терпкий капучино', N'Имеет насыщенный вкус с яркой кислинкой.', 81.74, '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 72, 15, 3.60);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('afeeb9f2-2b7c-45c9-a063-b4a0d44dbb48', N'Кофе с маршмеллоу', N'Имеет сладкий вкус с нотками ванили и маршмеллоу.', 157.89, '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 43, 5, 2.93);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('e4cb82db-3355-4fef-b410-fab99949cb04', N'Черничный латте', N'Имеет ягодно-фруктовый вкус с черничной кислинкой.', 37.40, '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 88, 5, 8.39);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('5f1e4f5c-553b-4053-a26e-ed899ccfa7e0', N'Кофе с коньяком', N'Имеет глубокий вкус с алкогольной нотой.', 89.18, '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 48, 9, 5.52);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('1dd986b1-4f40-4db2-9dfe-5c1565cfd754', N'Ореховый американо', N'Имеет мягкий кофейный вкус с ореховым послевкусием.', 143.78, '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 89, 13, 8.90);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('396555b4-40d3-4917-9af1-2f43ba499d89', N'Кофе с розмарином', N'Имеет пряный вкус с лёгкой горчинкой розмарина.', 32.43, '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 39, 14, 4.94);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('bb2999ed-c6ae-4172-9343-60b1d1b7bd1f', N'Тыквенный спайс латте', N'Имеет вкус с ароматом тыквы и специй.', 155.87, '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 14, 17, 3.25);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('eda4394b-d645-4d19-9117-ffb79eeb3669', N'Классический эспрессо', N'Имеет традиционный сбалансированный вкус кофе.', 111.73, '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 81, 5, 2.07);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('1570c922-d706-46a4-bc41-329483be4822', N'Кленовый флет уайт', N'Имеет сладкий вкус с ароматом кленового сиропа.', 170.08, 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 96, 7, 5.16);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('2efef2da-8a8c-4d2f-bfea-0816d6b67303', N'Фундуковый мокко', N'Имеет вкус с ароматом жареного фундука.', 199.83, 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 92, 9, 8.03);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('5da14b84-a68f-488d-9e1e-e1ca615fb0d8', N'Кофе с карамелью', N'Имеет мягкий сладкий вкус карамели.', 172.86, 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 10, 13, 7.87);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('acdfa29d-f642-4ba7-939a-0c8262ff7c41', N'Шоколадный капучино', N'Имеет глубокий вкус с шоколадным оттенком.', 49.53, 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 87, 14, 5.30);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('65c81bfc-a283-4a14-a8f7-60800963d5b7', N'Кофе на овсяном молоке', N'Имеет вкус с молочной основой и лёгким ореховым оттенком.', 123.66, 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 79, 12, 7.68);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('a90eaff4-e8bd-400f-a4b9-63cc6e0bcb54', N'Арахисовый мокко', N'Имеет вкус с насыщенными нотками арахиса.', 134.51, 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 41, 8, 8.45);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('075ac323-7649-44e8-bbff-60cbda965c47', N'Фисташковый мокко', N'Имеет ореховый оттенок с нежной фисташковой ноткой.', 133.40, '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 81, 18, 5.55);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('e7cf5f27-b23e-484a-8a9f-6dc67503a89a', N'Лавандовый раф', N'Имеет мягкий цветочный аромат с лёгкими нотами лаванды.', 175.68, '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 58, 12, 7.81);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('f015385b-be00-4ec9-acbf-2fcf38b9d7fd', N'Французский ванильный латте', N'Имеет нежный вкус с ароматом ванили.', 154.46, '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 73, 12, 9.28);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('3dd6269e-af5b-451b-bd3b-552b73c1751d', N'Мятно-шоколадный макиато', N'Имеет глубокий вкус с шоколадным оттенком.', 69.03, '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 29, 5, 9.02);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('31995494-84d0-4cc8-8765-df869685e234', N'Ромовый флет уайт', N'Имеет сладкий вкус с лёгкой алкогольной ноткой рома.', 75.77, '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 96, 17, 7.98);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('ad2493e7-e1b8-4811-bd6c-5e38edeb0f99', N'Банановый капучино', N'Имеет сладкий вкус с банановыми нотками.', 190.44, '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 88, 12, 4.59);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('f3dc17fc-f9fe-4beb-93f4-a27a02adb152', N'Раф с халвой', N'Имеет вкус с орехово-сладкой ноткой халвы.', 121.71, '4daae871-71ac-44da-8b58-dcf1a2ae907a', 69, 15, 5.76);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('fa4180fd-2756-4f01-aaa0-aa051c939b1a', N'Медово-имбирный макиато', N'Имеет острый, бодрящий вкус с имбирным оттенком.', 107.50, '4daae871-71ac-44da-8b58-dcf1a2ae907a', 13, 17, 2.90);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('121d56e4-dc5b-43c3-8658-d1a00f8cbf76', N'Карамельно-соленый мокко', N'Имеет необычный вкус с оттенком морской соли.', 45.53, '4daae871-71ac-44da-8b58-dcf1a2ae907a', 92, 8, 8.15);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('b4f5fdc1-498b-4830-bb04-c3625a94d146', N'Ванильный флет уайт', N'Имеет нежный вкус с ароматом ванили.', 179.30, '4daae871-71ac-44da-8b58-dcf1a2ae907a', 49, 18, 7.56);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('836b11ff-ec22-4433-8f72-11ce31d21bd7', N'Ирисовый латте', N'Имеет сладкий вкус с карамельными нотками ириса.', 150.16, 'a977e322-192c-4567-9f5f-36f504bfc13d', 78, 17, 7.23);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('e8c1eb57-f3f2-48ad-b65f-b3cb39617849', N'Кофе по-венски', N'Имеет классический вкус с взбитыми сливками.', 181.28, 'a977e322-192c-4567-9f5f-36f504bfc13d', 95, 20, 8.69);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('3f9de4b4-8188-4bd9-8a98-55c4b27af3a9', N'Кофе с корицей', N'Ароматный кофейный напиток с уникальным вкусом.', 79.48, 'a977e322-192c-4567-9f5f-36f504bfc13d', 54, 13, 3.37);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('f6ffc6f0-c513-449c-bcc7-66505087e4f6', N'Кокосовый капучино', N'Имеет экзотический вкус с кокосовой сладостью.', 32.59, 'a977e322-192c-4567-9f5f-36f504bfc13d', 10, 7, 4.24);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('140d8dfd-14d6-46bd-a8a0-845d54d3df3e', N'Ягодный мокко', N'Имеет фруктовый оттенок с кисло-сладким вкусом ягод.', 95.79, '70f22c9f-de0a-41a9-9a53-cabf42688d47', 59, 16, 1.94);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('2c90df73-2310-4499-bd86-701ee38b0974', N'Миндальный латте', N'Имеет вкус с нотками сладкого миндаля.', 49.13, '70f22c9f-de0a-41a9-9a53-cabf42688d47', 41, 18, 7.03);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('4b5016ea-81a5-4ba4-97c2-5ff98123bac3', N'Имбирный кофе', N'Имеет острый, бодрящий вкус с имбирным оттенком.', 81.68, '70f22c9f-de0a-41a9-9a53-cabf42688d47', 26, 7, 7.39);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('069d1026-82b5-4365-8481-1b38fe50307c', N'Трюфельный макиато', N'Имеет интенсивный вкус с нотками шоколадного трюфеля.', 105.20, '70f22c9f-de0a-41a9-9a53-cabf42688d47', 29, 7, 1.14);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('9c11131a-5957-42d6-bbac-a20f9bc18418', N'Шафрановый раф', N'Имеет изысканный вкус с восточными нотками шафрана.', 131.32, '70f22c9f-de0a-41a9-9a53-cabf42688d47', 11, 16, 3.69);
    INSERT INTO #ProductImport (ExternalId, Name, Description, Price, VendingMachineExternalId, QuantityOnHand, MinimumStock, AverageDailySales) VALUES ('cca932b0-81f0-45a1-9af7-8fe57aa1873e', N'Грушевый латте +', N'Имеет мягкий вкус с лёгкой фруктовой сладостью.', 161.27, '70f22c9f-de0a-41a9-9a53-cabf42688d47', 72, 17, 9.48);

    INSERT INTO dbo.Product (Name, Description, Price)
    SELECT i.Name, i.Description, i.Price
    FROM #ProductImport i
    LEFT JOIN dbo.Product p ON p.Name = i.Name
    WHERE p.ProductId IS NULL;

    IF OBJECT_ID(N'tempdb..#ProductMap') IS NOT NULL DROP TABLE #ProductMap;
    CREATE TABLE #ProductMap (ExternalId uniqueidentifier NOT NULL PRIMARY KEY, ProductId int NOT NULL, VendingMachineExternalId uniqueidentifier NOT NULL);
    INSERT INTO #ProductMap (ExternalId, ProductId, VendingMachineExternalId)
    SELECT i.ExternalId, p.ProductId, i.VendingMachineExternalId
    FROM #ProductImport i
    INNER JOIN dbo.Product p ON p.Name = i.Name;

    MERGE dbo.VendingMachineProduct AS target
    USING
    (
        SELECT
            m.VendingMachineId,
            pm.ProductId,
            i.QuantityOnHand,
            i.MinimumStock,
            i.AverageDailySales
        FROM #ProductImport i
        INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId
        INNER JOIN dbo.Product pm ON pm.Name = i.Name
    ) AS source (VendingMachineId, ProductId, QuantityOnHand, MinimumStock, AverageDailySales)
    ON target.VendingMachineId = source.VendingMachineId AND target.ProductId = source.ProductId
    WHEN MATCHED THEN
        UPDATE SET
            QuantityOnHand = source.QuantityOnHand,
            MinimumStock = source.MinimumStock,
            AverageDailySales = source.AverageDailySales,
            UpdatedAt = SYSDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (VendingMachineId, ProductId, QuantityOnHand, MinimumStock, AverageDailySales)
        VALUES (source.VendingMachineId, source.ProductId, source.QuantityOnHand, source.MinimumStock, source.AverageDailySales);

    /* ===== Import sales ===== */
    IF OBJECT_ID(N'tempdb..#SaleImport') IS NOT NULL DROP TABLE #SaleImport;
    CREATE TABLE #SaleImport
    (
        SoldAt datetime2(0) NOT NULL,
        ProductExternalId uniqueidentifier NOT NULL,
        VendingMachineExternalId uniqueidentifier NOT NULL,
        Quantity int NOT NULL,
        TotalAmount decimal(18,2) NOT NULL,
        PaymentMethodName nvarchar(50) NOT NULL
    );

    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-11-27T14:47:37', 'a90eaff4-e8bd-400f-a4b9-63cc6e0bcb54', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 5, 672.55, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-16T04:40:42', 'f3dc17fc-f9fe-4beb-93f4-a27a02adb152', '4daae871-71ac-44da-8b58-dcf1a2ae907a', 5, 608.55, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-13T06:51:25', 'e9aa2886-0ba0-4b7a-96dc-078855f99872', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 2, 279.10, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-21T09:47:54', '50c6dd4f-70f2-4ec1-a80c-0fc0069f08c2', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 1, 192.14, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-02-02T16:49:46', 'e7cf5f27-b23e-484a-8a9f-6dc67503a89a', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 2, 351.36, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-30T14:21:42', 'acdfa29d-f642-4ba7-939a-0c8262ff7c41', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 2, 99.06, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-27T10:25:01', '4b5016ea-81a5-4ba4-97c2-5ff98123bac3', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 2, 163.36, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-18T13:27:48', 'a90eaff4-e8bd-400f-a4b9-63cc6e0bcb54', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 3, 403.53, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-27T01:39:03', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 4, 303.08, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-23T06:36:30', 'cca932b0-81f0-45a1-9af7-8fe57aa1873e', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 4, 645.08, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-10T21:09:02', '836b11ff-ec22-4433-8f72-11ce31d21bd7', 'a977e322-192c-4567-9f5f-36f504bfc13d', 1, 150.16, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-09T05:06:19', '3f9de4b4-8188-4bd9-8a98-55c4b27af3a9', 'a977e322-192c-4567-9f5f-36f504bfc13d', 2, 158.96, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-06T20:10:59', 'bb2999ed-c6ae-4172-9343-60b1d1b7bd1f', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 4, 623.48, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-11-26T13:50:48', '514fef90-eb36-454f-968c-a02b1dbcf7d8', 'dc92a945-80cf-4c86-8927-97026c6e82da', 1, 81.20, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-11-10T22:26:34', 'bb2999ed-c6ae-4172-9343-60b1d1b7bd1f', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 3, 467.61, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-07-28T18:30:49', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 3, 227.31, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-05-09T19:14:55', 'f6ffc6f0-c513-449c-bcc7-66505087e4f6', 'a977e322-192c-4567-9f5f-36f504bfc13d', 5, 162.95, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-27T13:43:08', '2c90df73-2310-4499-bd86-701ee38b0974', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 4, 196.52, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-17T23:02:06', 'fa4180fd-2756-4f01-aaa0-aa051c939b1a', '4daae871-71ac-44da-8b58-dcf1a2ae907a', 5, 537.50, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-07-29T08:54:31', '65c81bfc-a283-4a14-a8f7-60800963d5b7', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 4, 494.64, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-30T19:50:22', '121d56e4-dc5b-43c3-8658-d1a00f8cbf76', '4daae871-71ac-44da-8b58-dcf1a2ae907a', 2, 91.06, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-05-23T02:48:43', 'e8c1eb57-f3f2-48ad-b65f-b3cb39617849', 'a977e322-192c-4567-9f5f-36f504bfc13d', 1, 181.28, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-01T12:21:12', '8aba3e58-49f7-44f0-9f7b-f8ad1cd570dc', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 2, 390.06, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-22T23:02:03', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 1, 75.77, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-05-14T10:18:27', '836b11ff-ec22-4433-8f72-11ce31d21bd7', 'a977e322-192c-4567-9f5f-36f504bfc13d', 1, 150.16, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-28T02:20:57', '224cdcde-36ee-45da-9ae5-2588df8f96fb', 'dc92a945-80cf-4c86-8927-97026c6e82da', 4, 274.28, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-24T16:53:01', '075ac323-7649-44e8-bbff-60cbda965c47', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 1, 133.40, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-02T18:10:06', 'e4cb82db-3355-4fef-b410-fab99949cb04', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 2, 74.80, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-17T08:55:05', 'f6ffc6f0-c513-449c-bcc7-66505087e4f6', 'a977e322-192c-4567-9f5f-36f504bfc13d', 3, 97.77, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-24T05:59:56', '121d56e4-dc5b-43c3-8658-d1a00f8cbf76', '4daae871-71ac-44da-8b58-dcf1a2ae907a', 4, 182.12, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-30T01:59:16', 'bb2999ed-c6ae-4172-9343-60b1d1b7bd1f', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 1, 155.87, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-07T12:40:14', 'c3737840-6332-4bc6-b5bc-80f92f074f58', 'dc92a945-80cf-4c86-8927-97026c6e82da', 1, 124.51, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-21T18:28:21', 'db33e8df-278c-472c-a45a-c3ddb7374b3a', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 5, 361.15, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-07-15T00:37:10', '50c6dd4f-70f2-4ec1-a80c-0fc0069f08c2', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 4, 768.56, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-15T14:57:32', '65c81bfc-a283-4a14-a8f7-60800963d5b7', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 4, 494.64, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-02T07:53:11', '1570c922-d706-46a4-bc41-329483be4822', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 2, 340.16, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-20T23:51:59', 'afeeb9f2-2b7c-45c9-a063-b4a0d44dbb48', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 5, 789.45, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-02-25T22:16:48', '3dd6269e-af5b-451b-bd3b-552b73c1751d', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 3, 207.09, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-28T22:39:16', 'e4cb82db-3355-4fef-b410-fab99949cb04', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 1, 37.40, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-03T16:31:07', 'c3737840-6332-4bc6-b5bc-80f92f074f58', 'dc92a945-80cf-4c86-8927-97026c6e82da', 4, 498.04, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-05-02T13:24:24', '8b889b5b-7567-45fa-97c9-09e56237d033', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 1, 175.75, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-23T01:17:06', '8aba3e58-49f7-44f0-9f7b-f8ad1cd570dc', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 3, 585.09, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-31T14:19:03', '1570c922-d706-46a4-bc41-329483be4822', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 5, 850.40, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-28T09:21:11', 'f015385b-be00-4ec9-acbf-2fcf38b9d7fd', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 4, 617.84, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-17T12:11:58', 'cca932b0-81f0-45a1-9af7-8fe57aa1873e', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 1, 161.27, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-28T02:51:53', 'e4cb82db-3355-4fef-b410-fab99949cb04', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 5, 187.00, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-06-14T14:31:03', 'db33e8df-278c-472c-a45a-c3ddb7374b3a', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 5, 361.15, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-27T05:13:26', '1dd986b1-4f40-4db2-9dfe-5c1565cfd754', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 1, 143.78, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-06T07:30:51', 'd27ea808-ee98-4fd0-b867-b5a4a0576c68', 'dc92a945-80cf-4c86-8927-97026c6e82da', 3, 486.69, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-05T04:45:59', '5da14b84-a68f-488d-9e1e-e1ca615fb0d8', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 2, 345.72, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-04T10:53:23', 'e9aa2886-0ba0-4b7a-96dc-078855f99872', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 1, 139.55, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-21T19:39:48', '50c6dd4f-70f2-4ec1-a80c-0fc0069f08c2', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 2, 384.28, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-05-20T20:50:17', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 3, 227.31, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-02-22T11:06:44', 'e4cb82db-3355-4fef-b410-fab99949cb04', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 3, 112.20, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-06-05T03:20:55', '836b11ff-ec22-4433-8f72-11ce31d21bd7', 'a977e322-192c-4567-9f5f-36f504bfc13d', 4, 600.64, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-28T19:47:23', '1dd986b1-4f40-4db2-9dfe-5c1565cfd754', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 4, 575.12, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-02-09T12:09:11', '65c81bfc-a283-4a14-a8f7-60800963d5b7', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 1, 123.66, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-21T01:46:42', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 3, 227.31, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-21T18:07:12', '121d56e4-dc5b-43c3-8658-d1a00f8cbf76', '4daae871-71ac-44da-8b58-dcf1a2ae907a', 2, 91.06, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-28T04:10:08', '2c90df73-2310-4499-bd86-701ee38b0974', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 3, 147.39, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-16T23:37:32', '4b5016ea-81a5-4ba4-97c2-5ff98123bac3', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 2, 163.36, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-06-22T13:17:30', '224cdcde-36ee-45da-9ae5-2588df8f96fb', 'dc92a945-80cf-4c86-8927-97026c6e82da', 4, 274.28, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-07-20T14:47:19', '2c90df73-2310-4499-bd86-701ee38b0974', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 5, 245.65, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-05-16T02:51:44', '3f9de4b4-8188-4bd9-8a98-55c4b27af3a9', 'a977e322-192c-4567-9f5f-36f504bfc13d', 4, 317.92, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-02-14T21:23:05', '075ac323-7649-44e8-bbff-60cbda965c47', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 5, 667.00, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-28T07:41:10', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 2, 151.54, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-31T17:12:56', '069d1026-82b5-4365-8481-1b38fe50307c', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 5, 526.00, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-24T19:08:53', 'acdfa29d-f642-4ba7-939a-0c8262ff7c41', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 5, 247.65, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-11-09T08:41:20', 'c3737840-6332-4bc6-b5bc-80f92f074f58', 'dc92a945-80cf-4c86-8927-97026c6e82da', 3, 373.53, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-23T05:28:15', '836b11ff-ec22-4433-8f72-11ce31d21bd7', 'a977e322-192c-4567-9f5f-36f504bfc13d', 3, 450.48, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-23T22:25:32', 'e9aa2886-0ba0-4b7a-96dc-078855f99872', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 1, 139.55, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-15T17:59:35', '4b5016ea-81a5-4ba4-97c2-5ff98123bac3', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 5, 408.40, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-08T17:52:07', '50c6dd4f-70f2-4ec1-a80c-0fc0069f08c2', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 5, 960.70, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-09T19:24:05', 'd27ea808-ee98-4fd0-b867-b5a4a0576c68', 'dc92a945-80cf-4c86-8927-97026c6e82da', 4, 648.92, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-11-25T20:24:50', 'afeeb9f2-2b7c-45c9-a063-b4a0d44dbb48', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 4, 631.56, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-12-10T16:22:06', '341529cf-dffb-4813-9c77-76f39f4445c7', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 5, 907.45, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-07-31T23:44:44', 'bb2999ed-c6ae-4172-9343-60b1d1b7bd1f', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 2, 311.74, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-02-18T08:51:28', 'e4cb82db-3355-4fef-b410-fab99949cb04', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 1, 37.40, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-01-13T05:18:56', '396555b4-40d3-4917-9af1-2f43ba499d89', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 4, 129.72, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-28T20:39:06', '140d8dfd-14d6-46bd-a8a0-845d54d3df3e', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 2, 191.58, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-27T09:30:57', '224cdcde-36ee-45da-9ae5-2588df8f96fb', 'dc92a945-80cf-4c86-8927-97026c6e82da', 3, 205.71, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-12T08:11:21', '1dd986b1-4f40-4db2-9dfe-5c1565cfd754', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 5, 718.90, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-06T10:54:44', '8a12f87f-7b45-4a03-bc7a-69e5fbccbc5a', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 4, 326.96, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-06-16T04:10:11', '4b5016ea-81a5-4ba4-97c2-5ff98123bac3', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 1, 81.68, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-06-18T14:58:25', 'c3737840-6332-4bc6-b5bc-80f92f074f58', 'dc92a945-80cf-4c86-8927-97026c6e82da', 3, 373.53, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-15T15:31:43', '3f9de4b4-8188-4bd9-8a98-55c4b27af3a9', 'a977e322-192c-4567-9f5f-36f504bfc13d', 4, 317.92, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-29T19:13:41', '069d1026-82b5-4365-8481-1b38fe50307c', '70f22c9f-de0a-41a9-9a53-cabf42688d47', 4, 420.80, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-06-07T03:48:28', '341529cf-dffb-4813-9c77-76f39f4445c7', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 3, 544.47, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-04-19T00:54:32', '341529cf-dffb-4813-9c77-76f39f4445c7', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 5, 907.45, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-09-28T17:54:45', 'e9aa2886-0ba0-4b7a-96dc-078855f99872', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 4, 558.20, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-06-26T02:37:21', '8b889b5b-7567-45fa-97c9-09e56237d033', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', 3, 527.25, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-05-07T21:00:02', 'e8c1eb57-f3f2-48ad-b65f-b3cb39617849', 'a977e322-192c-4567-9f5f-36f504bfc13d', 3, 543.84, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-08-12T04:22:55', '2efef2da-8a8c-4d2f-bfea-0816d6b67303', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', 3, 599.49, N'Наличные');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-11-05T08:17:02', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 1, 75.77, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-21T17:18:19', 'b4f5fdc1-498b-4830-bb04-c3625a94d146', '4daae871-71ac-44da-8b58-dcf1a2ae907a', 4, 717.20, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-03-19T07:08:17', '2d79e75e-c6b8-4138-8c0c-403325bf6944', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', 4, 374.36, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-11-07T17:31:26', '5f1e4f5c-553b-4053-a26e-ed899ccfa7e0', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 5, 445.90, N'Карта');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-10-21T12:02:45', '1dd986b1-4f40-4db2-9dfe-5c1565cfd754', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', 5, 718.90, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2024-07-19T16:53:14', '50c6dd4f-70f2-4ec1-a80c-0fc0069f08c2', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', 2, 384.28, N'QR');
    INSERT INTO #SaleImport (SoldAt, ProductExternalId, VendingMachineExternalId, Quantity, TotalAmount, PaymentMethodName) VALUES ('2025-02-16T15:07:41', '31995494-84d0-4cc8-8765-df869685e234', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', 3, 227.31, N'Карта');

    INSERT INTO dbo.Sale (VendingMachineId, ProductId, Quantity, TotalAmount, SoldAt, SalePaymentMethodId)
    SELECT
        m.VendingMachineId,
        p.ProductId,
        i.Quantity,
        i.TotalAmount,
        i.SoldAt,
        spm.SalePaymentMethodId
    FROM #SaleImport i
    INNER JOIN #VendingMachineMap m ON m.ExternalId = i.VendingMachineExternalId
    INNER JOIN #ProductMap pm ON pm.ExternalId = i.ProductExternalId
    INNER JOIN dbo.Product p ON p.ProductId = pm.ProductId
    INNER JOIN dbo.SalePaymentMethod spm ON spm.Name = i.PaymentMethodName
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Sale s
        WHERE
            s.VendingMachineId = m.VendingMachineId
            AND s.ProductId = p.ProductId
            AND s.SoldAt = i.SoldAt
            AND s.Quantity = i.Quantity
            AND s.TotalAmount = i.TotalAmount
            AND s.SalePaymentMethodId = spm.SalePaymentMethodId
    );

    /* ===== Import maintenance ===== */
    IF OBJECT_ID(N'tempdb..#MaintenanceImport') IS NOT NULL DROP TABLE #MaintenanceImport;
    CREATE TABLE #MaintenanceImport
    (
        MaintenanceDate date NOT NULL,
        VendingMachineExternalId uniqueidentifier NOT NULL,
        Problems nvarchar(1000) NULL,
        WorkDescription nvarchar(1000) NULL,
        ExecutorLastName nvarchar(100) NULL,
        ExecutorFirstName nvarchar(100) NULL,
        ExecutorPatronymic nvarchar(100) NULL
    );

    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-13', 'a977e322-192c-4567-9f5f-36f504bfc13d', N'Зависла сессия оплаты', N'Замена дисплея', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-04-25', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Проблемы с термобумагой', N'Чистка внутренних узлов', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-07-12', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Проблемы с термобумагой', N'Ремонт купюроприемника', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-04-25', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Не закрывается люк обслуживания', N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-24', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Не закрывается люк обслуживания', N'Замена модема', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-01-01', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Зависла сессия оплаты', N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-10', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Не закрывается люк обслуживания', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-05-24', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Ошибка дисплея', N'Замена дисплея', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-03-11', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Протечка в отсеке с напитками', N'Настройка сетевого соединения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-15', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Сбой системы оплаты', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-04-22', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Зависла сессия оплаты', N'Обновление программного обеспечения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-24', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', NULL, N'Проверка телеметрии', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-10-04', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Зависла сессия оплаты', N'Замена дисплея', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-12', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Не работает модем', N'Обновление программного обеспечения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-12', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Зависла сессия оплаты', N'Настройка сетевого соединения', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-06', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Не работает модем', N'Перезагрузка системы', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-19', '4daae871-71ac-44da-8b58-dcf1a2ae907a', NULL, N'Замена модема', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-23', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Протечка в отсеке с напитками', N'Обновление программного обеспечения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-03-26', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Аппарат не выдает товар', N'Пополнение товара', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-03', 'a977e322-192c-4567-9f5f-36f504bfc13d', N'Проблемы с термобумагой', N'Ремонт купюроприемника', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-20', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Проблемы с термобумагой', N'Настройка сетевого соединения', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-17', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Не закрывается люк обслуживания', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-04-20', 'a977e322-192c-4567-9f5f-36f504bfc13d', NULL, N'Замена дисплея', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-28', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Аппарат не выдает товар', N'Замена дисплея', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-17', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Не работает модем', N'Настройка сетевого соединения', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-27', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Заклинил монетоприемник', N'Проверка телеметрии', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-13', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', NULL, N'Замена дисплея', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-26', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Не работает модем', N'Обновление программного обеспечения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-10-30', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Повреждён корпус', N'Проверка телеметрии', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-15', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Не закрывается люк обслуживания', N'Пополнение товара', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-05', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Заклинил монетоприемник', N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-01-19', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Заклинил монетоприемник', N'Замена модема', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-05', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Проблемы с термобумагой', N'Проверка телеметрии', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-29', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Не закрывается люк обслуживания', N'Ремонт купюроприемника', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-15', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Проблемы с термобумагой', N'Проверка телеметрии', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-13', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Не работает модем', N'Обновление программного обеспечения', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-07', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Не закрывается люк обслуживания', N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-10-12', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Проблемы с термобумагой', N'Проверка телеметрии', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-06', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Проблемы с термобумагой', N'Пополнение товара', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-10-13', 'a977e322-192c-4567-9f5f-36f504bfc13d', N'Не работает модем', N'Ремонт купюроприемника', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-19', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Не работает модем', N'Замена модема', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-27', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Сбой системы оплаты', N'Перезагрузка системы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-03-11', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Проблемы с термобумагой', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-04-29', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Не работает модем', N'Обновление программного обеспечения', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-13', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Ошибка дисплея', N'Перезагрузка системы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-10-30', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Не работает модем', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-30', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Аппарат не выдает товар', N'Проверка телеметрии', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-10-27', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Протечка в отсеке с напитками', N'Чистка внутренних узлов', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-29', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Не работает модем', N'Загрузка новой товарной матрицы', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-05-14', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Проблемы с термобумагой', N'Замена модема', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-09', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Не закрывается люк обслуживания', N'Обновление программного обеспечения', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-05-10', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Зависла сессия оплаты', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-30', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Не работает модем', N'Ремонт купюроприемника', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-10', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Сбой системы оплаты', N'Замена модема', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-05-24', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Сбой системы оплаты', N'Чистка внутренних узлов', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-01-05', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Повреждён корпус', N'Обновление программного обеспечения', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-07-28', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Аппарат не выдает товар', N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-25', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Не работает модем', N'Проверка телеметрии', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-08', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Не закрывается люк обслуживания', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-12', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Протечка в отсеке с напитками', N'Обновление программного обеспечения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-11', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Аппарат не выдает товар', N'Перезагрузка системы', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-11', 'a977e322-192c-4567-9f5f-36f504bfc13d', NULL, N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-22', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Повреждён корпус', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-07-13', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Не закрывается люк обслуживания', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-20', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Проблемы с термобумагой', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-28', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Аппарат не выдает товар', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-03-03', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Аппарат не выдает товар', N'Замена модема', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-01-07', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Заклинил монетоприемник', N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-02', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Протечка в отсеке с напитками', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-17', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', NULL, N'Ремонт купюроприемника', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-14', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Ошибка дисплея', N'Ремонт купюроприемника', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-04-14', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Заклинил монетоприемник', N'Чистка внутренних узлов', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-05-09', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Аппарат не выдает товар', N'Настройка сетевого соединения', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-07-14', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Проблемы с термобумагой', N'Обновление программного обеспечения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-18', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Не работает модем', N'Проверка телеметрии', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-04-10', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Повреждён корпус', N'Настройка сетевого соединения', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-31', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Протечка в отсеке с напитками', N'Замена дисплея', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-07-21', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Аппарат не выдает товар', N'Перезагрузка системы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-07-19', '4daae871-71ac-44da-8b58-dcf1a2ae907a', N'Аппарат не выдает товар', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-05-31', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Зависла сессия оплаты', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-26', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Не закрывается люк обслуживания', N'Ремонт купюроприемника', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-22', '70f22c9f-de0a-41a9-9a53-cabf42688d47', NULL, N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-01-22', 'a977e322-192c-4567-9f5f-36f504bfc13d', N'Ошибка дисплея', N'Замена дисплея', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-27', '166c8a3f-a211-4d25-b2d4-a5b0b5f067d5', N'Заклинил монетоприемник', N'Пополнение товара', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-11-10', 'e1d62e6a-5427-4dda-8209-bb584bfbc9e5', N'Аппарат не выдает товар', N'Перезагрузка системы', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-05-21', 'dc92a945-80cf-4c86-8927-97026c6e82da', NULL, N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-10-11', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', NULL, N'Перезагрузка системы', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-12', 'a977e322-192c-4567-9f5f-36f504bfc13d', N'Не работает модем', N'Ремонт купюроприемника', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-02', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Протечка в отсеке с напитками', N'Проверка телеметрии', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-02', '53e2ec2e-d407-4e9a-a1d9-5a9501e81ede', N'Заклинил монетоприемник', N'Пополнение товара', N'Никонова', N'Олимпиада', N'Леонидовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-09-08', 'a977e322-192c-4567-9f5f-36f504bfc13d', N'Проблемы с термобумагой', N'Загрузка новой товарной матрицы', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-02-27', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Сбой системы оплаты', N'Замена дисплея', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-08-19', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Не закрывается люк обслуживания', N'Загрузка новой товарной матрицы', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-20', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Зависла сессия оплаты', N'Чистка внутренних узлов', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-01-19', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Сбой системы оплаты', N'Проверка телеметрии', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-01-01', '70f22c9f-de0a-41a9-9a53-cabf42688d47', N'Протечка в отсеке с напитками', N'Замена модема', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-12-10', '89c05e76-6b7e-4d72-b97c-62ecb96b1370', N'Заклинил монетоприемник', N'Загрузка новой товарной матрицы', N'Новиков', N'Ипполит', N'Власович');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-06-04', 'dc92a945-80cf-4c86-8927-97026c6e82da', N'Зависла сессия оплаты', N'Ремонт купюроприемника', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2025-04-08', '0a9a91bf-0fcc-44ac-b3c2-88a33411413a', N'Повреждён корпус', N'Чистка внутренних узлов', N'Воробьева', N'Таисия', N'Альбертовна');
    INSERT INTO #MaintenanceImport (MaintenanceDate, VendingMachineExternalId, Problems, WorkDescription, ExecutorLastName, ExecutorFirstName, ExecutorPatronymic) VALUES ('2024-04-23', '7ed68dd4-ef8b-4124-9084-bc16ee8f10d3', N'Зависла сессия оплаты', N'Загрузка новой товарной матрицы', N'Воробьева', N'Таисия', N'Альбертовна');

    INSERT INTO dbo.Maintenance (VendingMachineId, MaintenanceDate, WorkDescription, Problems, ExecutorUserAccountId)
    SELECT
        vm.VendingMachineId,
        i.MaintenanceDate,
        i.WorkDescription,
        i.Problems,
        u.UserAccountId
    FROM #MaintenanceImport i
    INNER JOIN #VendingMachineMap vm ON vm.ExternalId = i.VendingMachineExternalId
    LEFT JOIN dbo.UserAccount u ON u.LastName = i.ExecutorLastName AND u.FirstName = i.ExecutorFirstName AND ISNULL(u.Patronymic, N'') = ISNULL(i.ExecutorPatronymic, N'')
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Maintenance m
        WHERE
            m.VendingMachineId = vm.VendingMachineId
            AND m.MaintenanceDate = i.MaintenanceDate
            AND ISNULL(m.Problems, N'') = ISNULL(i.Problems, N'')
            AND ISNULL(m.WorkDescription, N'') = ISNULL(i.WorkDescription, N'')
    );

    COMMIT;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
GO
