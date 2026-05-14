USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: kiem tra database da tao du schema, table, view, procedure hay chua.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Kiểm tra cấu trúc database: xác nhận các schema, bảng, view và stored procedure đã được tạo đầy đủ.';

SELECT name AS SchemaName
FROM sys.schemas
WHERE name IN (N'Core', N'Identity', N'Infrastructure', N'Franchise', N'Operations', N'Payments', N'Maintenance', N'AppView', N'Audit')
ORDER BY name;

SELECT s.name AS SchemaName, o.name AS ObjectName, o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name IN (N'Identity', N'Infrastructure', N'Operations', N'Payments', N'Maintenance', N'Franchise', N'AppView')
  AND o.type IN (N'U', N'V', N'P')
ORDER BY s.name, o.type_desc, o.name;

SELECT
    SUM(CASE WHEN o.type = N'U' THEN 1 ELSE 0 END) AS TableCount,
    SUM(CASE WHEN o.type = N'V' THEN 1 ELSE 0 END) AS ViewCount,
    SUM(CASE WHEN o.type = N'P' THEN 1 ELSE 0 END) AS ProcedureCount
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name IN (N'Core', N'Identity', N'Infrastructure', N'Franchise', N'Operations', N'Payments', N'Maintenance', N'AppView', N'Audit');
GO




