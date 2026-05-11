# Run this script to fix PowerShell console encoding for UTF-8
# This prevents Vietnamese text corruption in terminal output

# Fix console output encoding to UTF-8
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()

# Fix PowerShell pipeline output encoding to UTF-8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

Write-Host "PowerShell encoding set to UTF-8"
Write-Host ""
Write-Host "Test: Nguyễn Huệ - Hệ Thống - Trạm Sạc Phú Yên - Điện Năng - Quản Lý"
Write-Host ""
Write-Host "To make this permanent, add the above to your PowerShell profile:"
Write-Host "  notepad `$PROFILE"
