# Xuat toan bo 29 bang trong EV_Charging_System ra 29 file CSV (day du moi dong).
# CSV chuan: co header, encoding UTF-8, tu dong escape dau phay/xuong dong/dau nháy.
$ErrorActionPreference = "Stop"

$server   = "localhost\SQLEXPRESS"
$database = "EV_Charging_System"
$outDir   = Join-Path $PSScriptRoot "CSV_Export"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$connStr = "Server=$server;Database=$database;Integrated Security=True;TrustServerCertificate=True"
$conn = New-Object System.Data.SqlClient.SqlConnection $connStr
$conn.Open()

# Lay danh sach schema.table
$tblCmd = $conn.CreateCommand()
$tblCmd.CommandText = @"
SELECT s.name AS s, t.name AS t
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name
"@
$tables = @()
$r = $tblCmd.ExecuteReader()
while ($r.Read()) { $tables += [pscustomobject]@{ Schema = $r["s"]; Table = $r["t"] } }
$r.Close()

$total = 0
foreach ($tbl in $tables) {
    $full = "[$($tbl.Schema)].[$($tbl.Table)]"
    $file = Join-Path $outDir "$($tbl.Schema).$($tbl.Table).csv"

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT * FROM $full"
    $cmd.CommandTimeout = 600
    $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
    $dt = New-Object System.Data.DataTable
    [void]$da.Fill($dt)

    $dt | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    $count = $dt.Rows.Count
    $total += $count
    "{0,-45} {1,12:N0} dong" -f ($tbl.Schema + "." + $tbl.Table), $count
    $dt.Dispose()
}
$conn.Close()
""
"Hoan tat: $($tables.Count) file CSV, tong $('{0:N0}' -f $total) dong -> $outDir"
