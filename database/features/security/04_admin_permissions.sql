USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: kiem tra quyen cua system admin bang EXECUTE AS USER.
- Khong can sua tham so, co the doi admin01 neu muon.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Kiểm tra quyền SystemAdmin: chứng minh quản trị viên xem được user-role và audit log.';

EXECUTE AS USER = 'admin01';

SELECT USER_NAME() AS CurrentDatabaseUser;

SELECT TOP 10 *
FROM AppView.vw_UserRoleSummary
ORDER BY UserID;

SELECT TOP 10 AuditID, SchemaName, TableName, ActionType, ChangedBy, ChangedAt
FROM Audit.AuditLog
ORDER BY AuditID DESC;

REVERT;
GO




