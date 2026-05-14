USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: chung minh customer khong doc duoc bang Identity.UserAccount truc tiep.
- Khong can sua tham so, co the doi user customer01 neu muon.
- Tac dong du lieu: CHI DOC/THU DOC DU LIEU; loi quyen duoc bat bang TRY...CATCH.
*/

PRINT N'Kiểm thử truy cập trái quyền: customer bị chặn khi đọc trực tiếp bảng định danh.';

EXECUTE AS USER = 'customer01';

SELECT USER_NAME() AS CurrentDatabaseUser;

BEGIN TRY
    SELECT TOP 5 *
    FROM [Identity].UserAccount;
END TRY
BEGIN CATCH
    PRINT N'Expected error: customer cannot read Identity.UserAccount.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

REVERT;
GO



