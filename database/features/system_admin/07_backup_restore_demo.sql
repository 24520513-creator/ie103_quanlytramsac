USE EV_Charging_System;
GO


/*
HUONG DAN SU DUNG
- Muc dich: hien thi cau lenh mau backup/restore.
- Can sua duong dan file .bak theo may truoc khi chay backup/restore that.
- Tac dong du lieu: file nay CHI HIEN THI LENH MAU, khong backup/restore that.
*/

PRINT N'Chuẩn bị backup và restore: quản trị viên xem câu lệnh mẫu để sao lưu và phục hồi database.';
PRINT N'Chuẩn bị backup và restore: quản trị viên xem câu lệnh mẫu để sao lưu và phục hồi database.';

SELECT
    DB_NAME() AS DatabaseName,
    N'BACKUP DATABASE EV_Charging_System TO DISK = N''C:\Temp\EV_Charging_System.bak'' WITH INIT, COMPRESSION, STATS = 5;' AS BackupCommand,
    N'RESTORE DATABASE EV_Charging_System_RestoreDemo FROM DISK = N''C:\Temp\EV_Charging_System.bak'' WITH MOVE ... , RECOVERY, STATS = 5;' AS RestoreCommand;
GO



