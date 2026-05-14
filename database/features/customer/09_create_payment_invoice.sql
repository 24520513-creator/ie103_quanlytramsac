USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao phien sac moi, thanh toan va lap hoa don.
- Tham so co the sua: @UserID, @VehicleID, @PointID, @PaymentMethod.
- @PaymentMethod hop le: N''CASH'', N''QR'', N''BANK_TRANSFER''.
- Tac dong du lieu: THEM THAT ChargingSession, PaymentTransaction va Invoice.
*/

PRINT N'Thanh toán và lập hóa đơn: khách hàng thanh toán phiên sạc đã hoàn tất và tạo hóa đơn tương ứng.';

DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
DECLARE @VehicleID INT = (SELECT TOP 1 VehicleID FROM Operations.Vehicle WHERE UserID = @UserID AND IsActive = 1 ORDER BY VehicleID DESC);
DECLARE @PointID INT = (SELECT TOP 1 PointID FROM AppView.vw_AvailableChargingPoints ORDER BY PointID);
DECLARE @Started TABLE (SessionID BIGINT, SessionCode NVARCHAR(40), UserID INT, StationID INT, PointID INT, SessionStatus NVARCHAR(30), StartTime DATETIME2);
DECLARE @SessionID BIGINT;

INSERT INTO @Started
EXEC Operations.sp_StartChargingSession @UserID = @UserID, @VehicleID = @VehicleID, @PointID = @PointID, @MeterStart = 2000.00;

SELECT @SessionID = SessionID FROM @Started;
EXEC Operations.sp_EndChargingSession @SessionID = @SessionID, @MeterEnd = 2018.25;

SELECT SessionID, SessionCode, CostTotal, SessionStatus
FROM Operations.ChargingSession
WHERE SessionID = @SessionID;

EXEC Payments.sp_CreatePayment
    @UserID = @UserID,
    @SessionID = @SessionID,
    @PaymentMethod = N'QR';

EXEC Payments.sp_CreateInvoice
    @SessionID = @SessionID;

SELECT *
FROM AppView.vw_InvoiceDetail
WHERE SessionCode IN (SELECT SessionCode FROM Operations.ChargingSession WHERE SessionID = @SessionID);
GO




