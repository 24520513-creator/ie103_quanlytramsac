USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem chi tiet hoa don cua customer.
- Tham so co the sua: @UserID.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem chi tiết hóa đơn: khách hàng xem thông tin hóa đơn, giao dịch và phiên sạc liên quan.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');

SELECT TOP 20 *
FROM AppView.vw_InvoiceDetail
WHERE UserID = @UserID
ORDER BY IssuedAt DESC;
GO




