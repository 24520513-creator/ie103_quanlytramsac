USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem lich su sac cua customer.
- Tham so co the sua: @UserID.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem lịch sử sạc: khách hàng xem lại các phiên sạc, trạm, cổng, sản lượng và chi phí.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');

SELECT TOP 20 *
FROM AppView.vw_CustomerChargingHistory
WHERE UserID = @UserID
ORDER BY StartTime DESC;
GO




