# PostgreSQL Password Reset Script
# Run this as Administrator: Right-click PowerShell -> Run as Administrator

$ErrorActionPreference = "Stop"

Write-Host "PostgreSQL Password Reset Tool" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$pgVersion = "18"
$pgDataDir = "C:\Program Files\PostgreSQL\$pgVersion\data"
$pgHbaConf = "$pgDataDir\pg_hba.conf"
$pgHbaBackup = "$pgDataDir\pg_hba.conf.backup"
$newPassword = "postgres123"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "        Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Find PostgreSQL service
Write-Host "[1/7] Finding PostgreSQL service..." -ForegroundColor Yellow
$pgService = Get-Service | Where-Object { $_.Name -like "*postgresql*" } | Select-Object -First 1

if (-not $pgService) {
    Write-Host "[ERROR] PostgreSQL service not found!" -ForegroundColor Red
    Write-Host "        Make sure PostgreSQL is installed." -ForegroundColor Yellow
    exit 1
}

Write-Host "      Found service: $($pgService.Name)" -ForegroundColor Green
Write-Host ""

# Backup pg_hba.conf
Write-Host "[2/7] Backing up pg_hba.conf..." -ForegroundColor Yellow
if (Test-Path $pgHbaBackup) {
    Remove-Item $pgHbaBackup -Force
}
Copy-Item $pgHbaConf $pgHbaBackup
Write-Host "      Backup created: $pgHbaBackup" -ForegroundColor Green
Write-Host ""

# Modify pg_hba.conf to trust
Write-Host "[3/7] Modifying authentication to 'trust'..." -ForegroundColor Yellow
$content = Get-Content $pgHbaConf
$newContent = $content -replace 'scram-sha-256', 'trust' -replace 'md5', 'trust'
$newContent | Set-Content $pgHbaConf
Write-Host "      Authentication set to 'trust' (temporary)" -ForegroundColor Green
Write-Host ""

# Restart PostgreSQL
Write-Host "[4/7] Restarting PostgreSQL service..." -ForegroundColor Yellow
Restart-Service $pgService.Name -Force
Start-Sleep -Seconds 3
Write-Host "      Service restarted" -ForegroundColor Green
Write-Host ""

# Reset password
Write-Host "[5/7] Resetting postgres user password..." -ForegroundColor Yellow
try {
    $env:PGPASSWORD = ""
    $sqlCommand = "ALTER USER postgres WITH PASSWORD `'$newPassword`';"
    $output = psql -U postgres -c $sqlCommand 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Password reset to: $newPassword" -ForegroundColor Green
    } else {
        throw "psql command failed: $output"
    }
} catch {
    Write-Host "[ERROR] Failed to reset password!" -ForegroundColor Red
    Write-Host "        Error: $_" -ForegroundColor Red
    Write-Host "        Restoring backup..." -ForegroundColor Yellow
    Copy-Item $pgHbaBackup $pgHbaConf -Force
    Restart-Service $pgService.Name -Force
    exit 1
}
Write-Host ""

# Restore pg_hba.conf
Write-Host "[6/7] Restoring secure authentication..." -ForegroundColor Yellow
Copy-Item $pgHbaBackup $pgHbaConf -Force
Write-Host "      pg_hba.conf restored" -ForegroundColor Green
Write-Host ""

# Restart PostgreSQL again
Write-Host "[7/7] Restarting PostgreSQL with secure settings..." -ForegroundColor Yellow
Restart-Service $pgService.Name -Force
Start-Sleep -Seconds 3
Write-Host "      Service restarted" -ForegroundColor Green
Write-Host ""

# Test new password
Write-Host "Testing new password..." -ForegroundColor Yellow
$env:PGPASSWORD = $newPassword
try {
    $testOutput = psql -U postgres -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Password test passed!" -ForegroundColor Green
    } else {
        throw "Test failed: $testOutput"
    }
} catch {
    Write-Host "[WARNING] Password test failed, but password may have been set" -ForegroundColor Yellow
    Write-Host "          Error: $_" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "PASSWORD RESET COMPLETE!" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "New credentials:" -ForegroundColor White
Write-Host "  Username: postgres" -ForegroundColor Cyan
Write-Host "  Password: $newPassword" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Set password: `$env:PGPASSWORD = ""$newPassword""" -ForegroundColor Yellow
Write-Host "  2. Create database: psql -U postgres -f setup_database.sql" -ForegroundColor Yellow
Write-Host "  3. Run migrations: psql -U lbc_user -d lbc -f migrations\001_create_events_table.sql" -ForegroundColor Yellow
Write-Host "  4. Start gateway: cd services\ws-gateway; npm start" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
