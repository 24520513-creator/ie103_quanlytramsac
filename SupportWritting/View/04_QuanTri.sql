==============================================================================
-- 4.5.7 Nhom View phuc vu quan tri he thong
==============================================================================


==============================================================================
-- AppView.vw_UserRoleSummary
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_UserRoleSummary
AS
SELECT
    u.UserID,
    u.Username,
    u.FullName,
    u.Email,
    u.Phone,
    u.AccountStatus,
    STRING_AGG(r.RoleCode, N', ') AS RoleCodes
FROM [Identity].UserAccount u
LEFT JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
LEFT JOIN [Identity].[Role] r ON r.RoleID = ur.RoleID
GROUP BY u.UserID, u.Username, u.FullName, u.Email, u.Phone, u.AccountStatus;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_UserRoleSummary;


==============================================================================
-- AppView.vw_AccountsByRole
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_AccountsByRole
AS
SELECT
    COALESCE(r.RoleCode, N'(Chưa gán)') AS RoleCode,
    u.AccountStatus,
    COUNT(DISTINCT u.UserID)            AS AccountCount
FROM [Identity].UserAccount u
LEFT JOIN [Identity].UserRole ur ON ur.UserID = u.UserID
LEFT JOIN [Identity].[Role] r    ON r.RoleID = ur.RoleID
GROUP BY COALESCE(r.RoleCode, N'(Chưa gán)'), u.AccountStatus;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_AccountsByRole;


==============================================================================
-- AppView.vw_AuditLogRecent
==============================================================================

--database/07_Create_AppViews.sql
CREATE OR ALTER VIEW AppView.vw_AuditLogRecent
AS
SELECT TOP (1000)
    AuditID,
    SchemaName,
    TableName,
    RecordID,
    ActionType,
    ChangedBy,
    ChangedAt,
    OldValues,
    NewValues
FROM Audit.AuditLog
ORDER BY ChangedAt DESC, AuditID DESC;

-- >>> TEST: cau lenh truy van view
USE EV_Charging_System;
GO
SELECT TOP (20) * FROM AppView.vw_AuditLogRecent;
