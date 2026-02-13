# Disk Information Collection Script (PowerShell)
# Supports local Windows and remote Linux server diagnostics

param(
    [switch]$Remote,
    [string]$HostName,
    [string]$User,
    [string]$Password,
    [int]$Port = 22,
    [int]$Timeout = 30
)

if ($Remote) {
    if (-not $HostName -or -not $User) {
        Write-Error "Remote mode requires -HostName and -User parameters"
        exit 1
    }

    Write-Host "=== Remote Disk Information: $HostName ===" -ForegroundColor Cyan
    Write-Host ""

    $remoteCommands = @"
echo '=== 1. Disk Partition Information ===' &&
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL &&
echo '' &&
echo '=== 2. Filesystem Information ===' &&
df -hT &&
echo '' &&
echo '=== 3. Mount Points ===' &&
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS 2>/dev/null || mount &&
echo '' &&
echo '=== 4. Disk Usage by Percentage ===' &&
df -h | sort -k5 -h &&
echo '' &&
echo '=== 5. I/O Statistics ===' &&
if command -v iostat &> /dev/null; then iostat -dx 1 2; else echo 'iostat not installed'; fi &&
echo '' &&
echo '=== 6. Inode Usage ===' &&
df -i
"@

    Write-Host "Connecting to ${User}@${HostName}:${Port}..." -ForegroundColor Yellow
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$Timeout -p $Port "${User}@${HostName}" $remoteCommands

    Write-Host ""
    Write-Host "=== Disk Information Collection Complete ===" -ForegroundColor Green

} else {
    Write-Host "=== Local Disk Information (Windows) ===" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "1. Physical Disks:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Get-Disk | Format-Table Number, FriendlyName, @{Label="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, PartitionStyle, HealthStatus -AutoSize
    Write-Host ""

    Write-Host "2. Partitions:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Get-Partition | Format-Table DiskNumber, PartitionNumber, DriveLetter, @{Label="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, Type -AutoSize
    Write-Host ""

    Write-Host "3. Volumes:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Get-Volume | Format-Table DriveLetter, FileSystemLabel, FileSystem, DriveType, HealthStatus,
        @{Label="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}},
        @{Label="Free(GB)";Expression={[math]::Round($_.SizeRemaining/1GB,2)}},
        @{Label="Used%";Expression={[math]::Round((($_.Size-$_.SizeRemaining)/$_.Size)*100,1)}} -AutoSize
    Write-Host ""

    Write-Host "4. Logical Disks:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} |
        Select-Object DeviceID, VolumeName, FileSystem,
        @{Label="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}},
        @{Label="Free(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}},
        @{Label="Used(GB)";Expression={[math]::Round(($_.Size-$_.FreeSpace)/1GB,2)}},
        @{Label="Used%";Expression={[math]::Round((($_.Size-$_.FreeSpace)/$_.Size)*100,1)}} |
        Format-Table -AutoSize
    Write-Host ""

    Write-Host "=== Disk Information Collection Complete ===" -ForegroundColor Green
}
