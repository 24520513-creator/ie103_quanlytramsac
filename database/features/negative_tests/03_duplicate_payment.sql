USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: chung minh database chan thanh toan trung.
- Tham so co the sua: @SessionID, @UserID.
- Tac dong du lieu: KHONG THEM PAYMENT MOI khi loi dung ky vong xay ra.
*/

PRINT N'Kiểm thử thanh toán trùng: database từ chối tạo payment lần hai cho cùng một phiên đã thanh toán.';

DECLARE @SessionID BIGINT = (
    SELECT TOP 1 SessionID
    FROM Payments.PaymentTransaction
    WHERE TransactionStatus = N'Completed'
    ORDER BY TransactionID
);
DECLARE @UserID INT = (SELECT UserID FROM Operations.ChargingSession WHERE SessionID = @SessionID);

SELECT SessionID, COUNT(*) AS ExistingCompletedPayments
FROM Payments.PaymentTransaction
WHERE SessionID = @SessionID AND TransactionStatus = N'Completed'
GROUP BY SessionID;

BEGIN TRY
    EXEC Payments.sp_CreatePayment
        @UserID = @UserID,
        @SessionID = @SessionID,
        @PaymentMethod = N'CASH';
END TRY
BEGIN CATCH
    PRINT N'Expected error: session has already been paid.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

SELECT SessionID, COUNT(*) AS CompletedPaymentsAfter
FROM Payments.PaymentTransaction
WHERE SessionID = @SessionID AND TransactionStatus = N'Completed'
GROUP BY SessionID;
GO



