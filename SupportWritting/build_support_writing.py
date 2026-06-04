# -*- coding: utf-8 -*-
"""
Sinh thu muc SupportWritting/StorageProcedure ho tro viet bao cao.
Moi stored procedure: tieu de --Schema.sp_Name-- + source dinh nghia SP + source test.
"""
import os

# Script nam trong SupportWritting/ ; ROOT la thu muc goc source code.
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "SupportWritting", "StorageProcedure")
SP_FILE = os.path.join(ROOT, "database", "05_Create_Stored_Procedures.sql")
AV_FILE = os.path.join(ROOT, "database", "07_Create_AppViews.sql")


def read(path):
    with open(path, "r", encoding="utf-8-sig") as f:
        return f.read()


def extract_sp(src_path, token):
    """Trich khoi 'CREATE OR ALTER PROCEDURE ...<token>...' den dong 'GO' ke tiep."""
    lines = read(src_path).splitlines()
    out, capturing = [], False
    for line in lines:
        if not capturing:
            if "CREATE OR ALTER PROCEDURE" in line and token in line:
                idx = line.index(token) + len(token)
                nxt = line[idx] if idx < len(line) else ""
                if nxt.isalnum() or nxt == "_":
                    continue  # tranh khop nham SP co tien to trung (vd ResetPassword vs ResetPasswordByToken)
                capturing = True
                out.append(line)
            continue
        if line.strip() == "GO":
            break
        out.append(line)
    if not out:
        raise RuntimeError("Khong tim thay SP: " + token)
    return "\n".join(out).rstrip() + "\nGO"


def rel(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


# (ten_hien_thi, token_tim, file_nguon, danh_sach_file_test, test_inline)
GROUPS = [
    ("01_Identity_QuanLyDinhDanh", "4.2.4 Nhom Stored Procedure quan ly dinh danh & phan quyen", [
        ("Identity.sp_CreateUser", "].sp_CreateUser", SP_FILE,
         ["database/features/system_admin/01_create_user.sql"], None),
        ("Identity.sp_RegisterCustomer", "].sp_RegisterCustomer", SP_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Khach hang tu dang ky tai khoan (vai tro Customer duoc gan tu dong)
EXEC [Identity].sp_RegisterCustomer
     @Username = N'demo_customer',
     @Email    = N'demo_customer@example.com',
     @Phone    = N'0900000001',
     @PasswordHash = N'$2a$11$hashGiaLapBcrypt................................',
     @FullName = N'Khach Hang Demo';
-- Ket qua mong doi: tra ve 1 dong UserAccount voi AccountStatus = 'Active'
-- Test am: chay lai voi cung Username/Email se nem loi 51101/51102 (da ton tai)
"""),
        ("Identity.sp_RequestPasswordReset", "].sp_RequestPasswordReset", SP_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Tao yeu cau dat lai mat khau cho mot user CO SAN (vd 'customer01').
-- Luu y 1: tham so cua EXEC khong nhan bieu thuc => gan DATEADD vao bien truoc.
-- Luu y 2: bao trong giao dich roi ROLLBACK de khong de lai token thua trong DB.
BEGIN TRAN;
    DECLARE @ExpiresAt DATETIME2 = DATEADD(MINUTE, 30, SYSDATETIME());
    EXEC [Identity].sp_RequestPasswordReset
         @Identifier = N'customer01',                 -- username/email/phone co that
         @TokenHash  = N'DEMO_RESET_TOKEN_001',
         @ExpiresAt  = @ExpiresAt;
    -- Ket qua mong doi: tra ve UserID va ghi 1 dong [Identity].AuthToken
    --                   (TokenType = 'PasswordReset') con hieu luc.
    SELECT TOP 5 AuthTokenID, UserID, TokenType, ExpiresAt, ConsumedAt
    FROM [Identity].AuthToken WHERE TokenHash = N'DEMO_RESET_TOKEN_001';
ROLLBACK;   -- huy thay doi demo
-- Test am: goi voi @Identifier khong ton tai => SP tra ve UserID = NULL (khong loi)
"""),
        ("Identity.sp_ResetPasswordByToken", "].sp_ResetPasswordByToken", SP_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Dat lai mat khau bang token hop le.
-- Demo tu chua: tao token bang sp_RequestPasswordReset roi dung chinh token do.
-- Bao trong giao dich + ROLLBACK de KHONG doi mat khau that cua tai khoan demo.
BEGIN TRAN;
    DECLARE @Exp DATETIME2 = DATEADD(MINUTE, 30, SYSDATETIME());
    EXEC [Identity].sp_RequestPasswordReset
         @Identifier = N'customer01',
         @TokenHash  = N'DEMO_RESET_TOKEN_002',
         @ExpiresAt  = @Exp;

    EXEC [Identity].sp_ResetPasswordByToken
         @TokenHash    = N'DEMO_RESET_TOKEN_002',
         @PasswordHash = N'$2a$11$hashMoiSauKhiReset........................';
    -- Ket qua mong doi: cap nhat PasswordHash + danh dau token ConsumedAt.
ROLLBACK;   -- huy thay doi demo
-- Test am: goi sp_ResetPasswordByToken voi token sai/het han/da dung
--          => THROW 51110 'Token dat lai mat khau khong hop le hoac da het han.'
"""),
        ("Identity.sp_VerifyEmailToken", "].sp_VerifyEmailToken", SP_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Xac thuc email qua token.
-- Demo tu chua: tao 1 token 'EmailVerification' cho user co san roi xac thuc.
-- Bao trong giao dich + ROLLBACK de khong de lai du lieu thua.
BEGIN TRAN;
    DECLARE @UserID INT = (SELECT UserID FROM [Identity].UserAccount WHERE Username = N'customer01');
    INSERT INTO [Identity].AuthToken (UserID, TokenType, TokenHash, ExpiresAt)
    VALUES (@UserID, N'EmailVerification', N'DEMO_EMAIL_TOKEN_001',
            DATEADD(MINUTE, 30, SYSDATETIME()));

    EXEC [Identity].sp_VerifyEmailToken @TokenHash = N'DEMO_EMAIL_TOKEN_001';
    -- Ket qua mong doi: token bi consume; neu account dang 'Pending' se chuyen 'Active'.
ROLLBACK;   -- huy thay doi demo
-- Test am: goi voi token sai/het han => THROW 51111 'Token xac minh email khong hop le...'
"""),
        ("Identity.sp_LockUser", "].sp_LockUser", SP_FILE,
         ["database/features/system_admin/02_lock_unlock_user.sql"], None),
        ("Identity.sp_UnlockUser", "].sp_UnlockUser", SP_FILE,
         ["database/features/system_admin/02_lock_unlock_user.sql"], None),
        ("Identity.sp_ResetPassword", "].sp_ResetPassword", SP_FILE,
         ["database/features/system_admin/03_reset_password.sql"], None),
        ("Identity.sp_AssignRole", "].sp_AssignRole", SP_FILE,
         ["database/features/system_admin/04_assign_remove_role.sql"], None),
        ("Identity.sp_RemoveRole", "].sp_RemoveRole", SP_FILE,
         ["database/features/system_admin/04_assign_remove_role.sql"], None),
    ]),
    ("02_Infrastructure_HaTangTramSac", "4.2.5 Nhom Stored Procedure quan ly ha tang tram sac", [
        ("Infrastructure.sp_CreateChargingStation", "sp_CreateChargingStation", SP_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Tao tram sac moi (gan voi franchise partner + dia chi co san).
-- Bao trong giao dich + ROLLBACK de khong chen tram rac vao DB.
BEGIN TRAN;
    DECLARE @FranchiseID INT = (SELECT TOP 1 FranchiseID FROM Franchise.FranchisePartner ORDER BY FranchiseID);
    DECLARE @AddressID   INT = (SELECT TOP 1 AddressID   FROM Core.Address ORDER BY AddressID);
    EXEC Infrastructure.sp_CreateChargingStation
         @StationCode = N'ST-DEMO-01',
         @StationName = N'Tram Sac Demo Quan 1',
         @FranchiseID = @FranchiseID,
         @AddressID   = @AddressID,
         @MaxPowerKW  = 150.00;
    -- Ket qua mong doi: tra ve tram vua tao voi StationStatus = 'Active'.
ROLLBACK;   -- huy thay doi demo
"""),
        ("Infrastructure.sp_CreateChargingPoint", "sp_CreateChargingPoint", SP_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Them tru sac vao mot tram da co.
-- Bao trong giao dich + ROLLBACK de khong chen tru sac rac vao DB.
BEGIN TRAN;
    DECLARE @StationID INT = (SELECT TOP 1 StationID FROM Infrastructure.ChargingStation ORDER BY StationID DESC);
    DECLARE @ConnID    INT = (SELECT TOP 1 ConnectorTypeID FROM Infrastructure.ConnectorType ORDER BY ConnectorTypeID);
    EXEC Infrastructure.sp_CreateChargingPoint
         @PointCode       = N'CP-DEMO-01',
         @StationID       = @StationID,
         @ConnectorTypeID = @ConnID,
         @PowerKW         = 60.00,
         @SerialNumber    = N'SN-DEMO-0001';
    -- Ket qua mong doi: tao tru sac moi voi trang thai 'Available'.
ROLLBACK;   -- huy thay doi demo
"""),
        ("Infrastructure.sp_UpdateStationStatus", "sp_UpdateStationStatus", SP_FILE,
         ["database/features/operations_staff/02_update_station_status.sql"], None),
        ("Infrastructure.sp_UpdateChargingPointStatus", "sp_UpdateChargingPointStatus", SP_FILE,
         ["database/features/operations_staff/03_update_point_status.sql"], None),
    ]),
    ("03_Operations_VanHanh", "4.2.6 Nhom Stored Procedure quan ly van hanh he thong", [
        ("Operations.sp_CreateVehicle", "sp_CreateVehicle", SP_FILE,
         ["database/features/customer/02_create_vehicle.sql"], None),
        ("Operations.sp_UpdateVehicle", "sp_UpdateVehicle", SP_FILE,
         ["database/features/customer/03_update_vehicle.sql"], None),
        ("Operations.sp_CreateBooking", "sp_CreateBooking", SP_FILE,
         ["database/features/customer/04_create_booking.sql"], None),
        ("Operations.sp_CancelBooking", "sp_CancelBooking", SP_FILE,
         ["database/features/customer/05_cancel_booking.sql"], None),
        ("Operations.sp_StartChargingSession", "sp_StartChargingSession", SP_FILE,
         ["database/features/customer/07_start_end_charging_session.sql"], None),
        ("Operations.sp_EndChargingSession", "sp_EndChargingSession", SP_FILE,
         ["database/features/customer/07_start_end_charging_session.sql"], None),
        ("Operations.sp_MarkChargingSessionFailed", "sp_MarkChargingSessionFailed", SP_FILE,
         ["database/features/operations_staff/05_mark_session_failed.sql"], None),
        ("Operations.sp_CreatePricingPolicy", "sp_CreatePricingPolicy", SP_FILE,
         ["database/features/business_manager/01_manage_pricing_policy.sql"], None),
        ("Operations.sp_DeactivatePricingPolicy", "sp_DeactivatePricingPolicy", SP_FILE,
         ["database/features/business_manager/01_manage_pricing_policy.sql"], None),
    ]),
    ("04_Payments_ThanhToanHoaDon", "4.2.7 Nhom Stored Procedure thanh toan va hoa don", [
        ("Payments.sp_CreatePayment", "sp_CreatePayment", SP_FILE,
         ["database/features/customer/09_create_payment_invoice.sql"], None),
        ("Payments.sp_RefundPayment", "sp_RefundPayment", SP_FILE,
         ["database/features/business_manager/11_refund_payment.sql"], None),
        ("Payments.sp_CreateInvoice", "sp_CreateInvoice", SP_FILE,
         ["database/features/customer/09_create_payment_invoice.sql"], None),
    ]),
    ("05_Maintenance_BaoTri", "4.2.8 Nhom Stored Procedure bao tri he thong", [
        ("Maintenance.sp_ReportError", "sp_ReportError", SP_FILE,
         ["database/features/operations_staff/06_report_error.sql"], None),
        ("Maintenance.sp_AssignTicket", "sp_AssignTicket", SP_FILE,
         ["database/features/operations_staff/07_assign_and_close_ticket.sql"], None),
        ("Maintenance.sp_ScheduleMaintenance", "sp_ScheduleMaintenance", SP_FILE,
         ["database/features/operations_staff/07_assign_and_close_ticket.sql"], None),
        ("Maintenance.sp_CloseTicket", "sp_CloseTicket", SP_FILE,
         ["database/features/operations_staff/07_assign_and_close_ticket.sql"], None),
    ]),
    ("06_Franchise_ChiaDoanhThu", "4.2.9 Nhom Stored Procedure franchise va chia doanh thu", [
        ("Franchise.sp_UpdateRevenueSharePolicy", "sp_UpdateRevenueSharePolicy", SP_FILE,
         ["database/features/business_manager/06_update_revenue_share_policy.sql"], None),
        ("Franchise.sp_CreateRevenueSettlement", "sp_CreateRevenueSettlement", SP_FILE,
         ["database/features/business_manager/07_create_revenue_settlement.sql"], None),
    ]),
    ("07_Reporting_BaoCao", "4.2.10 Nhom Reporting Procedure", [
        ("AppView.sp_GetStationRevenue", "sp_GetStationRevenue", AV_FILE,
         ["database/features/business_manager/02_view_station_revenue.sql"], None),
        ("AppView.sp_GetFranchiseProfitSharing", "sp_GetFranchiseProfitSharing", AV_FILE,
         ["database/features/business_manager/08_view_franchise_profit.sql"], None),
        ("AppView.sp_GetPaymentSummary", "sp_GetPaymentSummary", AV_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Tong hop thanh toan toan he thong (khong tham so)
EXEC AppView.sp_GetPaymentSummary;
-- Ket qua mong doi: cac dong tong hop theo phuong thuc / trang thai thanh toan
"""),
        ("AppView.sp_GetCustomerUsage", "sp_GetCustomerUsage", AV_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Top khach hang theo muc do su dung (mac dinh Top 10)
EXEC AppView.sp_GetCustomerUsage @Top = 5;
-- Ket qua mong doi: 5 khach hang co so phien/chi tieu cao nhat
"""),
        ("AppView.sp_GetOperationalKPI", "sp_GetOperationalKPI", AV_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Cac chi so KPI van hanh tong quan (khong tham so)
EXEC AppView.sp_GetOperationalKPI;
-- Ket qua mong doi: 1 dong cac chi so KPI (so tram, phien, doanh thu, ...)
"""),
        ("AppView.sp_GetTelemetryHealth", "sp_GetTelemetryHealth", AV_FILE,
         ["database/features/operations_staff/08_view_telemetry_health.sql"], None),
        ("AppView.sp_GetCurrentUserProfile", "sp_GetCurrentUserProfile", AV_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Lay ho so cua nguoi dung dang dang nhap (dua tren SESSION_CONTEXT/USER hien tai)
EXEC AppView.sp_GetCurrentUserProfile;
-- Ket qua mong doi: thong tin ho so cua chinh nguoi dung phien hien tai
"""),
        ("AppView.sp_GetMyFranchiseProfile", "sp_GetMyFranchiseProfile", AV_FILE,
         ["database/features/franchise_partner/01_view_my_profile.sql"], None),
        ("AppView.sp_GetMyFranchiseContracts", "sp_GetMyFranchiseContracts", AV_FILE,
         ["database/features/franchise_partner/02_view_my_contracts.sql"], None),
        ("AppView.sp_GetMyFranchiseStations", "sp_GetMyFranchiseStations", AV_FILE,
         ["database/features/franchise_partner/03_view_my_stations.sql"], None),
        ("AppView.sp_GetMyRevenueSharePolicies", "sp_GetMyRevenueSharePolicies", AV_FILE,
         ["database/features/franchise_partner/04_view_my_revenue_share_policy.sql"], None),
        ("AppView.sp_GetMyRevenueShareSettlements", "sp_GetMyRevenueShareSettlements", AV_FILE,
         ["database/features/franchise_partner/05_view_my_settlements.sql"], None),
        ("AppView.sp_ActivatePricingPolicy", "sp_ActivatePricingPolicy", SP_FILE, [],
         """USE EV_Charging_System;
GO
-- TEST: Kich hoat mot chinh sach gia (cac chinh sach trung pham vi se bi vo hieu).
-- Bao trong giao dich + ROLLBACK de khong doi trang thai du lieu that.
BEGIN TRAN;
    DECLARE @PolicyID INT = (SELECT TOP 1 PolicyID FROM Operations.PricingPolicy ORDER BY PolicyID DESC);
    EXEC AppView.sp_ActivatePricingPolicy @PolicyID = @PolicyID;
    -- Ket qua mong doi: PricingPolicy duoc chuyen sang trang thai dang ap dung.
ROLLBACK;   -- huy thay doi demo
"""),
    ]),
]

SEP = "=" * 78


def build():
    os.makedirs(OUT_DIR, exist_ok=True)
    index_lines = ["# SupportWritting / StorageProcedure",
                   "",
                   "Thu muc soan lai source code stored procedure theo dung thu tu bao cao.",
                   "Moi muc gom: tieu de SP -> source dinh nghia SP -> source test (co chu thich).",
                   ""]
    total = 0
    for fname, section_title, sps in GROUPS:
        parts = []
        parts.append(SEP)
        parts.append("-- " + section_title)
        parts.append(SEP)
        parts.append("")
        for display, token, src, test_files, test_inline in sps:
            total += 1
            parts.append("")
            parts.append(SEP)
            parts.append("-- " + display)
            parts.append(SEP)
            parts.append("")
            parts.append("--" + rel(src))
            parts.append(extract_sp(src, token))
            parts.append("")
            parts.append("-- >>> TEST: source kiem thu tinh nang")
            if test_inline:
                parts.append("-- (Demo test soan rieng cho bao cao - SP nay khong co file feature test rieng)")
                parts.append(test_inline.rstrip())
            else:
                for tf in test_files:
                    parts.append("-- (Trich tu " + tf + ")")
                    parts.append(read(os.path.join(ROOT, tf)).rstrip())
                    parts.append("")
            parts.append("")
        out_path = os.path.join(OUT_DIR, fname + ".sql")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write("\n".join(parts).rstrip() + "\n")
        index_lines.append("- **" + section_title + "** -> `" + fname + ".sql` (" + str(len(sps)) + " SP)")
        for display, *_ in sps:
            index_lines.append("  - " + display)
    with open(os.path.join(OUT_DIR, "README.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(index_lines) + "\n")
    print("Da sinh", total, "stored procedure vao", rel(OUT_DIR))


if __name__ == "__main__":
    build()
