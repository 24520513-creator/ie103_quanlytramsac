USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: kiem tra seed data toi thieu sau khi chay script 09.
- Khong can sua tham so.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Kiểm tra dữ liệu nền: xác nhận dữ liệu mẫu tối thiểu đã sẵn sàng để chạy các feature demo.';

SELECT N'Users' AS DataGroup, COUNT(*) AS TotalRows FROM [Identity].UserAccount
UNION ALL SELECT N'Stations', COUNT(*) FROM Infrastructure.ChargingStation
UNION ALL SELECT N'Charging points', COUNT(*) FROM Infrastructure.ChargingPoint
UNION ALL SELECT N'Vehicles', COUNT(*) FROM Operations.Vehicle
UNION ALL SELECT N'Sessions', COUNT(*) FROM Operations.ChargingSession
UNION ALL SELECT N'Payments', COUNT(*) FROM Payments.PaymentTransaction
UNION ALL SELECT N'Invoices', COUNT(*) FROM Payments.Invoice
UNION ALL SELECT N'Maintenance tickets', COUNT(*) FROM Maintenance.MaintenanceTicket;

SELECT TOP 10 Username, FullName, AccountStatus
FROM [Identity].UserAccount
ORDER BY UserID;

SELECT TOP 10 StationCode, StationName, StationStatus
FROM Infrastructure.ChargingStation
ORDER BY StationID;
GO



