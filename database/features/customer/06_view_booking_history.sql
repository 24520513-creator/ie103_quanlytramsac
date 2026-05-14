USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem lich su booking cua customer.
- Tham so co the sua: @UserID de xem customer khac.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem lịch sử đặt sạc: khách hàng xem các booking đã tạo qua view dữ liệu.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');

SELECT TOP 20 *
FROM AppView.vw_CustomerBookingHistory
WHERE UserID = @UserID
ORDER BY CreatedAt DESC;
GO




