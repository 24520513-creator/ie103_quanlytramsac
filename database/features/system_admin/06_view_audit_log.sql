USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: xem audit log gan nhat.
- Co the sua TOP 50 neu muon xem nhieu/it hon.
- Tac dong du lieu: CHI DOC DU LIEU, khong them/sua/xoa.
*/

PRINT N'Xem audit log: quản trị viên kiểm tra lịch sử thay đổi dữ liệu và thao tác quan trọng.';

SELECT TOP 50 AuditID, SchemaName, TableName, RecordID, ActionType, OldValues, NewValues, ChangedBy, ChangedAt
FROM Audit.AuditLog
ORDER BY AuditID DESC;
GO



