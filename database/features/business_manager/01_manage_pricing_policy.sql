USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: tao chinh sach gia moi va vo hieu hoa chinh sach vua tao.
- Tham so co the sua: @PolicyCode, @PolicyName, @BasePricePerKWh, @PeakMultiplier, gio cao diem.
- Tac dong du lieu: THEM THAT PricingPolicy, sau do cap nhat IsActive = 0 cho policy vua tao.
*/

PRINT N'Quản lý chính sách giá: quản lý kinh doanh tạo chính sách giá mới và vô hiệu hóa chính sách khi cần.';

DECLARE @PolicyCode NVARCHAR(30) = N'FEATURE-DEMO-PRICE-' + RIGHT(REPLACE(CONVERT(NVARCHAR(36), NEWID()), N'-', N''), 6);
DECLARE @Created TABLE (PolicyID INT, PolicyCode NVARCHAR(30), PolicyName NVARCHAR(150), BasePricePerKWh DECIMAL(19,4), PeakMultiplier DECIMAL(5,2), IsActive BIT);
DECLARE @PolicyID INT;

SELECT TOP 10 PolicyID, PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, IsActive
FROM Operations.PricingPolicy
ORDER BY PolicyID DESC;

INSERT INTO @Created
EXEC Operations.sp_CreatePricingPolicy
    @PolicyCode = @PolicyCode,
    @PolicyName = N'FEATURE-DEMO flexible price',
    @BasePricePerKWh = 3900.00,
    @PeakMultiplier = 1.30,
    @PeakStartHour = '17:00',
    @PeakEndHour = '20:00',
    @AppliedFrom = '2026-06-01';

SELECT @PolicyID = PolicyID FROM @Created;
SELECT * FROM @Created;

EXEC Operations.sp_DeactivatePricingPolicy @PolicyID = @PolicyID;

SELECT PolicyID, PolicyCode, PolicyName, BasePricePerKWh, PeakMultiplier, IsActive
FROM Operations.PricingPolicy
WHERE PolicyID = @PolicyID;
GO



