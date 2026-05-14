USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: kiem tra quyen cua customer bang EXECUTE AS USER.
- Khong can sua tham so, co the doi ten user customer01 neu muon.
- Tac dong du lieu: CHI DOC DU LIEU; lenh truy cap trai quyen duoc bat bang TRY...CATCH.
*/

PRINT N'Kiểm tra quyền Customer: chứng minh customer đọc view được phép nhưng không đọc trực tiếp bảng thanh toán.';

EXECUTE AS USER = 'customer01';

SELECT USER_NAME() AS CurrentDatabaseUser;

SELECT TOP 5 *
FROM AppView.vw_CustomerChargingHistory
ORDER BY StartTime DESC;

BEGIN TRY
    SELECT TOP 5 *
    FROM Payments.PaymentTransaction;
END TRY
BEGIN CATCH
    PRINT N'Expected error: customer cannot select Payments.PaymentTransaction directly.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

REVERT;
GO




