USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: kiem tra quyen cua business manager bang EXECUTE AS USER.
- Khong can sua tham so, co the doi business01 neu muon.
- Tac dong du lieu: Co lenh UPDATE test quyen nhung bi DENY va duoc bat loi; khong lam doi du lieu.
*/

PRINT N'Kiểm tra quyền BusinessManager: chứng minh quản lý kinh doanh xem doanh thu nhưng không cập nhật trực tiếp bảng trạm.';

EXECUTE AS USER = 'business01';

SELECT USER_NAME() AS CurrentDatabaseUser;

SELECT TOP 5 *
FROM AppView.vw_TopRevenueStations
ORDER BY RevenueTotal DESC;

BEGIN TRY
    UPDATE Infrastructure.ChargingStation
    SET StationStatus = StationStatus
    WHERE StationID = 1;
END TRY
BEGIN CATCH
    PRINT N'Expected error: business manager cannot update infrastructure tables directly.';
    SELECT ERROR_MESSAGE() AS ExpectedError;
END CATCH;

REVERT;
GO




