# -*- coding: utf-8 -*-
"""
Sinh thu muc SupportWritting/View ho tro viet bao cao (giong StorageProcedure).
Moi view: tieu de --AppView.vw_Name-- + source dinh nghia view + cau lenh test (SELECT).
View loc theo nguoi dung (RLS qua SESSION_CONTEXT) se kem buoc set context.
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "SupportWritting", "View")
SRC = os.path.join(ROOT, "database", "07_Create_AppViews.sql")
SRC_REL = "database/07_Create_AppViews.sql"

CUSTOMER_UID = 52   # customer01
FRANCHISE_UID = 37  # franchise01


def read(p):
    with open(p, "r", encoding="utf-8-sig") as f:
        return f.read()


def extract_view(name):
    """Trich 'CREATE OR ALTER VIEW AppView.<name>' den 'GO' ke tiep (khop chinh xac ten)."""
    token = "AppView." + name
    lines = read(SRC).splitlines()
    out, cap = [], False
    for ln in lines:
        if not cap:
            if "CREATE OR ALTER VIEW" in ln and token in ln:
                idx = ln.index(token) + len(token)
                nxt = ln[idx] if idx < len(ln) else ""
                if nxt.isalnum() or nxt == "_":
                    continue  # tranh khop nham ten co tien to trung
                cap = True
                out.append(ln)
            continue
        if ln.strip() == "GO":
            break
        out.append(ln)
    if not out:
        raise RuntimeError("Khong tim thay view: " + name)
    return "\n".join(out).rstrip()


def make_test(name, body):
    head = "USE EV_Charging_System;\nGO\n"
    if "SESSION_CONTEXT(N'UserID')" in body:
        if "FranchisePartner" in body:
            uid, role, who = FRANCHISE_UID, "FranchisePartner", "franchise01"
        else:
            uid, role, who = CUSTOMER_UID, "Customer", "customer01"
        head += (
            "-- View nay LOC theo nguoi dang nhap (RLS) -> phai set SESSION_CONTEXT truoc, neu khong se rong.\n"
            f"EXEC sys.sp_set_session_context @key = N'UserID',   @value = {uid};         -- {who}\n"
            f"EXEC sys.sp_set_session_context @key = N'RoleCode', @value = N'{role}';\n"
        )
    head += f"SELECT TOP (20) * FROM AppView.{name};"
    return head


GROUPS = [
    ("01_KhachHang", "4.5.4 Nhom View phuc vu khach hang", [
        "vw_CustomerChargingHistory", "vw_CustomerBookingHistory", "vw_InvoiceDetail",
        "vw_MyVehicles", "vw_MyChargingSummary", "vw_AvailableChargingPoints",
    ]),
    ("02_QuanLyKinhDoanh", "4.5.5 Nhom View phuc vu quan ly kinh doanh", [
        "vw_StationRevenueDaily", "vw_StationRevenueByYear", "vw_FranchiseRevenueMonthly",
        "vw_RegionRevenue", "vw_TopRevenueStations", "vw_TopCustomerUsage",
        "vw_PeakHourStatistics", "vw_ChargingSessionStatistics", "vw_CustomerGrowth",
        "vw_PaymentSummary", "vw_RefundablePayments", "vw_PricingPolicies",
        "vw_ProfitSharing", "vw_ConnectorUtilization", "vw_SystemOperationalKPI",
    ]),
    ("03_VanHanh", "4.5.6 Nhom View phuc vu van hanh he thong", [
        "vw_StationStatusOverview", "vw_ActiveChargingSessions", "vw_MaintenanceKPI",
        "vw_MaintenanceTickets", "vw_ErrorLogActive",
    ]),
    ("04_QuanTri", "4.5.7 Nhom View phuc vu quan tri he thong", [
        "vw_UserRoleSummary", "vw_AccountsByRole", "vw_AuditLogRecent",
    ]),
    ("05_FranchisePartner", "4.5.8 Nhom View phuc vu franchise partner", [
        "vw_MyFranchiseProfile", "vw_MyFranchiseContracts", "vw_MyFranchiseStations",
        "vw_MyRevenueSharePolicies", "vw_MyRevenueShareSettlements",
    ]),
    ("06_WebUI", "4.5.9 Nhom View ho tro Web UI", [
        "vw_WebLookupConnectorTypes", "vw_WebLookupCustomerVehicles", "vw_WebLookupAvailablePoints",
        "vw_WebLookupCustomerBookings", "vw_WebLookupCustomerSessions", "vw_WebLookupStations",
        "vw_WebLookupPoints", "vw_WebLookupActiveSessions", "vw_WebLookupOpenTickets",
        "vw_WebLookupOperationsStaff", "vw_WebLookupPricingPolicies", "vw_WebLookupRevenueSharePolicies",
        "vw_WebLookupFranchises", "vw_WebLookupRefundablePayments", "vw_WebLookupUsers",
        "vw_WebLookupAssignableRoles", "vw_WebLookupRemovableRoles",
    ]),
]

SEP = "=" * 78


def build():
    os.makedirs(OUT_DIR, exist_ok=True)
    index = ["# SupportWritting / View", "",
             "Soan lai source code View theo dung thu tu bao cao.",
             "Moi muc: tieu de View -> source dinh nghia View -> cau lenh test (SELECT).", ""]
    total = 0
    for fname, title, views in GROUPS:
        parts = [SEP, "-- " + title, SEP, ""]
        for v in views:
            total += 1
            body = extract_view(v)
            parts += ["", SEP, "-- AppView." + v, SEP, "",
                      "--" + SRC_REL, body, "",
                      "-- >>> TEST: cau lenh truy van view", make_test(v, body), ""]
        with open(os.path.join(OUT_DIR, fname + ".sql"), "w", encoding="utf-8") as f:
            f.write("\n".join(parts).rstrip() + "\n")
        index.append(f"- **{title}** -> `{fname}.sql` ({len(views)} view)")
        for v in views:
            index.append(f"  - AppView.{v}")
    with open(os.path.join(OUT_DIR, "README.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(index) + "\n")
    print("Da sinh", total, "view vao", os.path.relpath(OUT_DIR, ROOT).replace("\\", "/"))


if __name__ == "__main__":
    build()
