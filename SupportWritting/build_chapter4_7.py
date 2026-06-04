# -*- coding: utf-8 -*-
"""Gom day du source code cho muc 4.7 Backup/Restore/Import/Export -> 1 file SQL."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "SupportWritting", "Chapter4_7_BackupRestoreImportExport.sql")


def read(p):
    with open(os.path.join(ROOT, p), "r", encoding="utf-8-sig") as f:
        return f.read().rstrip()


def block(path, token):
    """Trich tu dong CREATE...<token> den 'GO' ke tiep."""
    lines = read(path).splitlines()
    out, cap = [], False
    for ln in lines:
        if not cap:
            if ("CREATE OR ALTER" in ln) and (token in ln):
                cap = True
                out.append(ln)
            continue
        out.append(ln)
        if ln.strip() == "GO":
            break
    return "\n".join(out)


SEP = "=" * 78
parts = []


def head(title):
    parts.append("")
    parts.append(SEP)
    parts.append("-- " + title)
    parts.append(SEP)


parts.append(SEP)
parts.append("-- 4.7  BACKUP, RESTORE, IMPORT & EXPORT DU LIEU")
parts.append("-- (Gom day du source code that tu cac file trong database/)")
parts.append(SEP)

# 4.7.1
head("4.7.1  Vai tro Backup/Restore -- nen tang: RECOVERY SIMPLE")
parts.append("-- Nguon: database/00_Drop_And_Create_Database.sql")
parts.append(read("database/00_Drop_And_Create_Database.sql"))

# 4.7.2 + 4.7.3
head("4.7.2 & 4.7.3  Script Backup & Restore Database")
parts.append("-- Nguon: database/12_Backup_Restore.sql")
parts.append(read("database/12_Backup_Restore.sql"))
parts.append("")
parts.append("-- Nguon (demo hien thi lenh qua result set):")
parts.append("-- database/features/system_admin/07_backup_restore_demo.sql")
parts.append(read("database/features/system_admin/07_backup_restore_demo.sql"))

# 4.7.4
head("4.7.4  Import du lieu vao he thong (BULK INSERT tu CSV)")
parts.append("-- Nguon: database/09_Seed_Demo_Data.sql")
parts.append(read("database/09_Seed_Demo_Data.sql"))

# 4.7.5
head("4.7.5  Export du lieu bao cao (Reporting Views + Procedures)")
parts.append("-- Nguon: database/07_Create_AppViews.sql")
parts.append("-- (a) Cac VIEW bao cao nen tang:")
for v in ["vw_CustomerChargingHistory", "vw_StationRevenueDaily", "vw_ProfitSharing",
          "vw_MaintenanceKPI", "vw_PaymentSummary"]:
    parts.append("")
    parts.append("-- View: AppView." + v)
    parts.append(block("database/07_Create_AppViews.sql", v))
parts.append("")
parts.append("-- (b) Cac REPORTING PROCEDURE (giao dien export bao cao):")
for sp in ["sp_GetStationRevenue", "sp_GetFranchiseProfitSharing", "sp_GetOperationalKPI",
           "sp_GetPaymentSummary", "sp_GetCustomerUsage", "sp_GetTelemetryHealth"]:
    parts.append("")
    parts.append("-- Procedure: AppView." + sp)
    parts.append(block("database/07_Create_AppViews.sql", sp))

with open(OUT, "w", encoding="utf-8") as f:
    f.write("\n".join(parts).rstrip() + "\n")
print("Da sinh:", os.path.relpath(OUT, ROOT).replace("\\", "/"))
print("So dong:", len("\n".join(parts).splitlines()))
