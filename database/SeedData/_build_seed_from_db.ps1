# =====================================================================
#  _build_seed_from_db.ps1
#  (1) Xuat 29 bang trong EV_Charging_System ra CSV chuan BULK INSERT
#      (ngay ISO, NULL = rong, UTF-8 KHONG BOM, bo cot computed).
#  (2) Sinh file ..\09_Seed_Demo_Data.sql phien ban nap tu CSV.
#  Chay lai khi du lieu nguon thay doi.
# =====================================================================
param([switch]$SqlOnly)   # -SqlOnly: chi sinh lai file 09, KHONG xuat lai CSV
$ErrorActionPreference = "Stop"
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture

$server   = "localhost\SQLEXPRESS"
$database = "EV_Charging_System"
$seedDir  = $PSScriptRoot                                  # ...\database\SeedData
$sqlOut   = Join-Path (Split-Path $seedDir -Parent) "09_Seed_Demo_Data.sql"
$inv      = [System.Globalization.CultureInfo]::InvariantCulture

# Thu tu nap theo phu thuoc khoa ngoai (cha truoc con)
$order = @(
    "Core.Region","Identity.Role","Identity.UserAccount","Infrastructure.ConnectorType",
    "Operations.PricingPolicy","Audit.AuditLog",
    "Core.Address","Infrastructure.ElectricitySupplier","Identity.UserRole",
    "Identity.AuthEvent","Identity.AuthToken",
    "Franchise.FranchisePartner","Franchise.FranchiseContract","Franchise.RevenueSharePolicy",
    "Infrastructure.ChargingStation","Franchise.FranchiseStation","Franchise.RevenueShareSettlement",
    "Infrastructure.ChargingPoint","Infrastructure.StationConnectorType","Operations.Vehicle",
    "Infrastructure.PointStatusHistory","Infrastructure.PointTelemetry",
    "Maintenance.ErrorLog","Maintenance.MaintenanceTicket",
    "Operations.Booking","Operations.ChargingSession","Operations.SessionEvent",
    "Payments.PaymentTransaction","Payments.Invoice"
)

$connStr = "Server=$server;Database=$database;Integrated Security=True;TrustServerCertificate=True"
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()

function Get-Columns($schema, $table) {
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = @"
SELECT c.name, t.name AS typ, c.max_length, c.precision, c.scale,
       c.is_identity, c.is_computed
FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(@o)
ORDER BY c.column_id
"@
    [void]$cmd.Parameters.AddWithValue("@o", "$schema.$table")
    $cols = @(); $r = $cmd.ExecuteReader()
    while ($r.Read()) {
        $cols += [pscustomobject]@{
            Name=$r["name"]; Type=$r["typ"]; MaxLen=[int]$r["max_length"]
            Prec=[int]$r["precision"]; Scale=[int]$r["scale"]
            IsIdentity=[bool]$r["is_identity"]; IsComputed=[bool]$r["is_computed"]
        }
    }
    $r.Close(); $cols
}

function Sql-Type($c) {
    switch ($c.Type) {
        {$_ -in 'nvarchar','nchar'}            { $l = if($c.MaxLen -eq -1){'max'}else{$c.MaxLen/2}; "$($c.Type)($l)" }
        {$_ -in 'varchar','char','varbinary','binary'} { $l = if($c.MaxLen -eq -1){'max'}else{$c.MaxLen}; "$($c.Type)($l)" }
        {$_ -in 'decimal','numeric'}           { "$($c.Type)($($c.Prec),$($c.Scale))" }
        {$_ -in 'datetime2','time','datetimeoffset'} { "$($c.Type)($($c.Scale))" }
        default { $c.Type }
    }
}

function Csv-Field($v) {
    if ($v -is [System.DBNull]) { return "" }                       # NULL -> rong
    if ($v -is [bool])          { if($v){return "1"}else{return "0"} }
    if ($v -is [datetime])      { return '"' + $v.ToString("yyyy-MM-ddTHH:mm:ss.fffffff",$inv) + '"' }
    if ($v -is [System.DateTimeOffset]) { return '"' + $v.ToString("yyyy-MM-ddTHH:mm:ss.fffffffzzz",$inv) + '"' }
    if ($v -is [timespan])      { return '"' + $v.ToString("c",$inv) + '"' }
    if ($v -is [byte[]])        { return "0x" + (($v | ForEach-Object { $_.ToString("x2") }) -join "") }
    if ($v -is [int] -or $v -is [long] -or $v -is [int16] -or $v -is [byte] -or `
        $v -is [decimal] -or $v -is [double] -or $v -is [System.Single]) {
        return ([System.IFormattable]$v).ToString($null,$inv)
    }
    return '"' + ($v.ToString() -replace '"','""') + '"'             # chuoi: boc nháy, escape "
}

$bulkOpts = "FORMAT=''CSV'',FIRSTROW=2,FIELDQUOTE=''`"'',FIELDTERMINATOR='','',ROWTERMINATOR=''0x0d0a'',CODEPAGE=''65001'',KEEPNULLS,TABLOCK"

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("USE EV_Charging_System;")
[void]$sb.AppendLine("GO")
[void]$sb.AppendLine(@"
/* =====================================================================
   09_Seed_Demo_Data.sql  -- PHIEN BAN NAP TU CSV (BULK INSERT)
   ---------------------------------------------------------------------
   - Thay cho ban sinh du lieu bang code (nhe, nhanh, khong gay crash).
   - Nguon du lieu: thu muc database\SeedData\*.csv (29 bang).
   - Chay SAU 00 -> 08 (DB moi, dang trong), TRUOC 10 -> 13.
   - Yeu cau: SQL Server 2016+ (ho tro FORMAT='CSV', CODEPAGE='65001').
   - File CSV doc theo ngu canh Windows cua nguoi dang dang nhap (local).
     Neu loi 'Cannot bulk load / Access denied': cap quyen Read thu muc
     SeedData cho tai khoan dich vu SQL Server, hoac doi @DataDir sang
     thu muc ma SQL Server doc duoc.
   ===================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- >>> SUA DUONG DAN NAY CHO DUNG MAY CUA BAN <<<
DECLARE @DataDir NVARCHAR(4000) = N'__DATADIR__';
DECLARE @sql NVARCHAR(MAX);

IF EXISTS (SELECT 1 FROM Operations.ChargingSession)
    THROW 60000, N'Cac bang da co du lieu. Hay chay tren DB moi (sau khi chay 00 -> 08).', 1;
"@)

$total = 0
foreach ($ft in $order) {
    $schema,$table = $ft.Split(".")
    $cols = Get-Columns $schema $table
    $insertable = @($cols | Where-Object { -not $_.IsComputed })
    $hasComputed = @($cols | Where-Object { $_.IsComputed }).Count -gt 0
    $colNames = ($insertable | ForEach-Object { $_.Name }) -join ","
    $file = Join-Path $seedDir "$ft.csv"

    # ---- Xuat CSV ----
    if (-not $SqlOnly) {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT $colNames FROM [$schema].[$table]"
        $cmd.CommandTimeout = 600
        $rd = $cmd.ExecuteReader()
        $sw = New-Object System.IO.StreamWriter($file, $false, (New-Object System.Text.UTF8Encoding($false)))
        $sw.NewLine = "`r`n"
        $sw.WriteLine($colNames)
        $n = 0
        while ($rd.Read()) {
            $vals = New-Object string[] $rd.FieldCount
            for ($i=0; $i -lt $rd.FieldCount; $i++) { $vals[$i] = Csv-Field $rd.GetValue($i) }
            $sw.WriteLine([string]::Join(",", $vals))
            $n++
        }
        $sw.Close(); $rd.Close()
        $total += $n
        "{0,-42} {1,10:N0} dong -> {2}.csv" -f $ft, $n, $ft
    }

    # ---- Sinh SQL nap ----
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("PRINT N'Nap $ft ...';")
    if (-not $hasComputed) {
        $opt = if ($insertable | Where-Object { $_.IsIdentity }) { "$bulkOpts,KEEPIDENTITY" } else { $bulkOpts }
        [void]$sb.AppendLine("SET @sql = N'BULK INSERT [$schema].[$table] FROM ''' + @DataDir + N'\$ft.csv'' WITH ($opt);';")
        [void]$sb.AppendLine("EXEC sp_executesql @sql;")
    } else {
        # Bang co cot computed: nap vao bang tam roi INSERT...SELECT
        $tmp = "#stg_" + ($table)
        $ddl = ($insertable | ForEach-Object { "[$($_.Name)] $(Sql-Type $_)" }) -join ", "
        [void]$sb.AppendLine("CREATE TABLE $tmp ($ddl);")
        [void]$sb.AppendLine("SET @sql = N'BULK INSERT $tmp FROM ''' + @DataDir + N'\$ft.csv'' WITH ($bulkOpts);';")
        [void]$sb.AppendLine("EXEC sp_executesql @sql;")
        $hasId = @($insertable | Where-Object { $_.IsIdentity }).Count -gt 0
        if ($hasId) { [void]$sb.AppendLine("SET IDENTITY_INSERT [$schema].[$table] ON;") }
        $colList = ($insertable | ForEach-Object { "[$($_.Name)]" }) -join ","
        [void]$sb.AppendLine("INSERT INTO [$schema].[$table] ($colList) SELECT $colList FROM $tmp;")
        if ($hasId) { [void]$sb.AppendLine("SET IDENTITY_INSERT [$schema].[$table] OFF;") }
        [void]$sb.AppendLine("DROP TABLE $tmp;")
    }
}

# ---- Reseed identity ----
[void]$sb.AppendLine("")
[void]$sb.AppendLine("-- Dat lai bo dem IDENTITY ve gia tri lon nhat hien co")
foreach ($ft in $order) {
    $schema,$table = $ft.Split(".")
    $cols = Get-Columns $schema $table
    if ($cols | Where-Object { $_.IsIdentity }) {
        [void]$sb.AppendLine("IF EXISTS (SELECT 1 FROM [$schema].[$table]) DBCC CHECKIDENT (N'[$schema].[$table]', RESEED);")
    }
}

# ---- Re-trust FK (tuy chon) ----
[void]$sb.AppendLine(@"

-- (Tuy chon) Xac thuc lai khoa ngoai de giu trang thai 'trusted'.
-- Co the bo comment neu may yeu va khong can.
DECLARE @recheck NVARCHAR(MAX) = N'';
SELECT @recheck += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + N'.'
                + QUOTENAME(OBJECT_NAME(parent_object_id)) + N' WITH CHECK CHECK CONSTRAINT ALL;' + CHAR(10)
FROM sys.foreign_keys;
EXEC sp_executesql @recheck;

PRINT N'>>> Seed tu CSV hoan tat.';
"@)

$conn.Close()

$text = $sb.ToString().Replace("__DATADIR__", $seedDir)
[System.IO.File]::WriteAllText($sqlOut, $text, (New-Object System.Text.UTF8Encoding($false)))

""
"Da xuat $($order.Count) file CSV ($('{0:N0}' -f $total) dong) -> $seedDir"
"Da sinh file SQL -> $sqlOut"
