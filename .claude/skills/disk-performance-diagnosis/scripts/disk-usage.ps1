# Disk Usage Analysis Script (PowerShell)
# Analyzes disk space usage and identifies large files

param(
    [switch]$Remote,
    [string]$HostName,
    [string]$User,
    [string]$Password,
    [int]$Port = 22,
    [int]$Timeout = 30,
    [string]$TargetPath
)

if ($Remote) {
    if (-not $HostName -or -not $User) {
        Write-Error "Remote mode requires -HostName and -User parameters"
        exit 1
    }

    Write-Host "=== Remote Disk Usage Analysis: $HostName ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not $TargetPath) {
        $TargetPath = "/"
    }

    $remoteCommands = @"
echo '=== Disk Usage Analysis: $TargetPath ===' &&
echo '' &&
echo '1. Overall Usage:' &&
echo '----------------------------------------' &&
df -h $TargetPath &&
echo '' &&
echo '2. Top 20 Directories by Size:' &&
echo '----------------------------------------' &&
du -h $TargetPath/* 2>/dev/null | sort -hr | head -n 20 &&
echo '' &&
echo '3. Large Files (>100MB):' &&
echo '----------------------------------------' &&
find $TargetPath -type f -size +100M -exec du -h {} + 2>/dev/null | sort -hr | head -n 20 &&
echo '' &&
echo '4. Inode Usage:' &&
echo '----------------------------------------' &&
df -i $TargetPath &&
echo '' &&
echo '5. Recently Modified Files (last 7 days, >10MB):' &&
echo '----------------------------------------' &&
find $TargetPath -type f -mtime -7 -size +10M -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -n 10
"@

    Write-Host "Connecting to ${User}@${HostName}:${Port}..." -ForegroundColor Yellow
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$Timeout -p $Port "${User}@${HostName}" $remoteCommands

    Write-Host ""
    Write-Host "=== Disk Usage Analysis Complete ===" -ForegroundColor Green

} else {
    Write-Host "=== Local Disk Usage Analysis (Windows) ===" -ForegroundColor Cyan
    Write-Host ""

    if (-not $TargetPath) {
        Write-Host "Available Drives:"
        Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0} |
            Format-Table Name, @{Label="Used(GB)";Expression={[math]::Round($_.Used/1GB,2)}},
                         @{Label="Free(GB)";Expression={[math]::Round($_.Free/1GB,2)}},
                         Root -AutoSize

        $TargetPath = Read-Host "Enter drive or path to analyze (e.g., C:\, D:\)"
    }

    if (-not (Test-Path $TargetPath)) {
        Write-Error "Path does not exist: $TargetPath"
        exit 1
    }

    Write-Host "Analyzing path: $TargetPath" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "1. Overall Usage:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    $drive = Get-PSDrive -PSProvider FileSystem | Where-Object {$TargetPath -like "$($_.Root)*"}
    if ($drive) {
        [PSCustomObject]@{
            Drive = $drive.Name
            Root = $drive.Root
            "Used(GB)" = [math]::Round($drive.Used/1GB,2)
            "Free(GB)" = [math]::Round($drive.Free/1GB,2)
            "Total(GB)" = [math]::Round(($drive.Used + $drive.Free)/1GB,2)
            "Used%" = [math]::Round(($drive.Used/($drive.Used + $drive.Free))*100,1)
        } | Format-List
    }
    Write-Host ""

    Write-Host "2. Top 20 Directories by Size:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Write-Host "Scanning directories, please wait..." -ForegroundColor Gray

    Get-ChildItem -Path $TargetPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $size = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Path = $_.FullName
            "Size(GB)" = [math]::Round($size/1GB,2)
            "Size(MB)" = [math]::Round($size/1MB,2)
        }
    } | Sort-Object "Size(GB)" -Descending | Select-Object -First 20 | Format-Table -AutoSize
    Write-Host ""

    Write-Host "3. Large Files (>100MB):" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Write-Host "Searching for large files, please wait..." -ForegroundColor Gray

    Get-ChildItem -Path $TargetPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {$_.Length -gt 100MB} |
        Sort-Object Length -Descending |
        Select-Object -First 20 @{Label="Size(GB)";Expression={[math]::Round($_.Length/1GB,2)}},
                                @{Label="Size(MB)";Expression={[math]::Round($_.Length/1MB,2)}},
                                FullName,
                                LastWriteTime |
        Format-Table -AutoSize
    Write-Host ""

    Write-Host "4. File Type Statistics (Top 15):" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Write-Host "Analyzing file types, please wait..." -ForegroundColor Gray

    Get-ChildItem -Path $TargetPath -Recurse -File -ErrorAction SilentlyContinue |
        Group-Object Extension |
        Select-Object Name, Count, @{Label="TotalSize(GB)";Expression={
            [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum/1GB,2)
        }} |
        Sort-Object "TotalSize(GB)" -Descending |
        Select-Object -First 15 |
        Format-Table -AutoSize
    Write-Host ""

    Write-Host "=== Disk Usage Analysis Complete ===" -ForegroundColor Green
}
