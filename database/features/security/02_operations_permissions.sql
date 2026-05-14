USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: kiem tra quyen cua operations staff bang EXECUTE AS USER.
- Khong can sua tham so, co the doi operator01 neu muon.
- Tac dong du lieu: CHI DOC DU LIEU; lenh truy cap trai quyen duoc bat bang TRY...CATCH.
*/

PRINT N'Kiểm tra quyền OperationsStaff: chứng minh nhân viên vận hành xem dữ liệu vận hành nhưng không đọc bảng định danh.';

EXECUTE AS USER = 'operator01';

SELECT USER_NAME() AS CurrentDatabaseUser;

SELECT TOP 5 *
FROM AppView.vw_StationStatusOverview
ORDER BY StationCode;

BEGIN TRY
    SELECT TOP 5 *
    FROM [Identity].UserAccount;
END TRY
BEGIN CATCH
    PRINT N'Expected error: operations staff cannot select Identity.UserAccount directly.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

REVERT;
GO




