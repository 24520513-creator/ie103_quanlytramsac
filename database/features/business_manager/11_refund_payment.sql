USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: hoan tien co ban cho giao dich da thanh toan.
- Tham so co the sua: @TransactionID, @Reason.
- Chi giao dich Completed moi duoc chuyen sang Refunded.
- Tac dong du lieu: KHONG TAO BANG REFUND; chi cap nhat PaymentTransaction va Invoice sang Refunded.
*/

PRINT N'Hoàn tiền cơ bản: quản lý kinh doanh đổi trạng thái giao dịch và hóa đơn sang Refunded mà không tạo bảng refund riêng.';

DECLARE @TransactionID BIGINT = (
    SELECT TOP 1 TransactionID
    FROM Payments.PaymentTransaction
    WHERE TransactionStatus = N'Completed'
    ORDER BY TransactionID DESC
);

SELECT TransactionID, TransactionCode, PaymentMethod, Amount, TransactionStatus
FROM Payments.PaymentTransaction
WHERE TransactionID = @TransactionID;

EXEC Payments.sp_RefundPayment
    @TransactionID = @TransactionID,
    @Reason = N'FEATURE-DEMO refund approved by business manager.';

SELECT TransactionID, TransactionCode, PaymentMethod, Amount, TransactionStatus, Description
FROM Payments.PaymentTransaction
WHERE TransactionID = @TransactionID;

SELECT InvoiceID, InvoiceCode, TransactionID, InvoiceStatus
FROM Payments.Invoice
WHERE TransactionID = @TransactionID;
GO



