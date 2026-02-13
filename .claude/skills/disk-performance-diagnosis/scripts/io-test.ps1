# I/O Performance Test Script (PowerShell)
# Tests disk read/write performance

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

    Write-Host "=== Remote I/O Performance Test: $HostName ===" -ForegroundColor Cyan
    Write-Host ""

    $remoteCommands = @"
echo '=== I/O Performance Test ===' &&
echo '' &&
echo 'Checking for fio tool...' &&
if ! command -v fio &> /dev/null; then
    echo 'ERROR: fio not installed'
    echo 'On Ubuntu/Debian: sudo apt-get install fio'
    echo 'On CentOS/RHEL: sudo yum install fio'
    exit 1
fi &&
echo 'fio found, starting tests...' &&
echo '' &&
echo '=== Sequential Read Test (1GB file) ===' &&
fio --name=seq-read --filename=/tmp/fio-test --size=1G --bs=1M --rw=read --iodepth=4 --numjobs=1 --direct=1 --runtime=30 --time_based --group_reporting &&
echo '' &&
echo '=== Sequential Write Test (1GB file) ===' &&
fio --name=seq-write --filename=/tmp/fio-test --size=1G --bs=1M --rw=write --iodepth=4 --numjobs=1 --direct=1 --runtime=30 --time_based --group_reporting &&
echo '' &&
echo '=== Random Read Test (4K blocks) ===' &&
fio --name=rand-read --filename=/tmp/fio-test --size=1G --bs=4k --rw=randread --iodepth=16 --numjobs=4 --direct=1 --runtime=30 --time_based --group_reporting &&
echo '' &&
echo '=== Random Write Test (4K blocks) ===' &&
fio --name=rand-write --filename=/tmp/fio-test --size=1G --bs=4k --rw=randwrite --iodepth=16 --numjobs=4 --direct=1 --runtime=30 --time_based --group_reporting &&
echo '' &&
echo 'Cleaning up test file...' &&
rm -f /tmp/fio-test &&
echo '=== I/O Performance Test Complete ==='
"@

    Write-Host "Connecting to ${User}@${HostName}:${Port}..." -ForegroundColor Yellow
    Write-Host "WARNING: Performance test may take several minutes" -ForegroundColor Yellow
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$Timeout -p $Port "${User}@${HostName}" $remoteCommands

    Write-Host ""
    Write-Host "=== I/O Performance Test Complete ===" -ForegroundColor Green

} else {
    Write-Host "=== Local I/O Performance Test (Windows) ===" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Available Drives:"
    Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0} |
        Format-Table Name, @{Label="Free(GB)";Expression={[math]::Round($_.Free/1GB,2)}}, Root -AutoSize

    $driveLetter = Read-Host "Enter drive letter to test (e.g., C, D)"
    $testPath = "${driveLetter}:\disk-io-test.tmp"

    if (-not (Test-Path "${driveLetter}:\")) {
        Write-Error "Drive does not exist: ${driveLetter}:\"
        exit 1
    }

    $drive = Get-PSDrive -Name $driveLetter
    if ($drive.Free -lt 2GB) {
        Write-Warning "WARNING: Less than 2GB free space, test may fail"
        $continue = Read-Host "Continue? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            exit 0
        }
    }

    Write-Host ""
    Write-Host "Test file: $testPath" -ForegroundColor Yellow
    Write-Host "Test size: 1GB"
    Write-Host "WARNING: Test will use disk I/O resources" -ForegroundColor Yellow
    Write-Host ""

    $testSize = 1GB
    $blockSize = 1MB
    $blocks = $testSize / $blockSize
    $buffer = New-Object byte[] $blockSize

    # Sequential Write Test
    Write-Host "=== 1. Sequential Write Test ===" -ForegroundColor Yellow
    Write-Host "Creating 1GB test file..." -ForegroundColor Gray

    $writeStart = Get-Date
    $stream = [System.IO.File]::Create($testPath)
    try {
        for ($i = 0; $i -lt $blocks; $i++) {
            $stream.Write($buffer, 0, $buffer.Length)
            if ($i % 100 -eq 0) {
                Write-Progress -Activity "Write Test" -Status "Progress: $i/$blocks" -PercentComplete (($i/$blocks)*100)
            }
        }
        $stream.Flush()
    } finally {
        $stream.Close()
    }
    $writeEnd = Get-Date
    $writeDuration = ($writeEnd - $writeStart).TotalSeconds
    $writeSpeed = [math]::Round($testSize / $writeDuration / 1MB, 2)

    Write-Host "Sequential Write Speed: $writeSpeed MB/s" -ForegroundColor Green
    Write-Host "Write Time: $([math]::Round($writeDuration, 2)) seconds"
    Write-Host ""

    # Sequential Read Test
    Write-Host "=== 2. Sequential Read Test ===" -ForegroundColor Yellow

    $readStart = Get-Date
    $stream = [System.IO.File]::OpenRead($testPath)
    try {
        $bytesRead = 0
        $buffer = New-Object byte[] $blockSize
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $bytesRead += $read
            if ($bytesRead % (100 * $blockSize) -eq 0) {
                Write-Progress -Activity "Read Test" -Status "Read: $([math]::Round($bytesRead/1MB, 0)) MB" -PercentComplete (($bytesRead/$testSize)*100)
            }
        }
    } finally {
        $stream.Close()
    }
    $readEnd = Get-Date
    $readDuration = ($readEnd - $readStart).TotalSeconds
    $readSpeed = [math]::Round($testSize / $readDuration / 1MB, 2)

    Write-Host "Sequential Read Speed: $readSpeed MB/s" -ForegroundColor Green
    Write-Host "Read Time: $([math]::Round($readDuration, 2)) seconds"
    Write-Host ""

    # Random Access Test
    Write-Host "=== 3. Random Access Test (4KB blocks) ===" -ForegroundColor Yellow

    $randomBlockSize = 4KB
    $randomOps = 1000
    $fileSize = (Get-Item $testPath).Length

    $stream = [System.IO.File]::Open($testPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
    $buffer = New-Object byte[] $randomBlockSize
    $random = New-Object System.Random

    $randomReadStart = Get-Date
    try {
        for ($i = 0; $i -lt $randomOps; $i++) {
            $position = $random.Next(0, [int]($fileSize - $randomBlockSize))
            $stream.Seek($position, [System.IO.SeekOrigin]::Begin) | Out-Null
            $stream.Read($buffer, 0, $randomBlockSize) | Out-Null

            if ($i % 100 -eq 0) {
                Write-Progress -Activity "Random Read Test" -Status "Operations: $i/$randomOps" -PercentComplete (($i/$randomOps)*100)
            }
        }
    } finally {
        $stream.Close()
    }
    $randomReadEnd = Get-Date
    $randomReadDuration = ($randomReadEnd - $randomReadStart).TotalSeconds
    $randomReadIOPS = [math]::Round($randomOps / $randomReadDuration, 0)

    Write-Host "Random Read IOPS: $randomReadIOPS ops/s" -ForegroundColor Green
    Write-Host "Average Latency: $([math]::Round(1000 / $randomReadIOPS, 2)) ms"
    Write-Host ""

    # Cleanup
    Write-Host "Cleaning up test file..." -ForegroundColor Gray
    Remove-Item $testPath -Force -ErrorAction SilentlyContinue

    # Performance Summary
    Write-Host ""
    Write-Host "=== Performance Summary ===" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    Write-Host "Sequential Write: $writeSpeed MB/s"
    Write-Host "Sequential Read: $readSpeed MB/s"
    Write-Host "Random Read IOPS: $randomReadIOPS ops/s"
    Write-Host ""

    # Performance Assessment
    Write-Host "=== Performance Assessment ===" -ForegroundColor Cyan
    Write-Host "----------------------------------------"

    if ($writeSpeed -gt 500) {
        Write-Host "[OK] Write Performance: Excellent (SSD level)" -ForegroundColor Green
    } elseif ($writeSpeed -gt 100) {
        Write-Host "[OK] Write Performance: Good" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Write Performance: Slow (HDD or high system load)" -ForegroundColor Yellow
    }

    if ($readSpeed -gt 500) {
        Write-Host "[OK] Read Performance: Excellent (SSD level)" -ForegroundColor Green
    } elseif ($readSpeed -gt 100) {
        Write-Host "[OK] Read Performance: Good" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Read Performance: Slow (HDD or high system load)" -ForegroundColor Yellow
    }

    if ($randomReadIOPS -gt 5000) {
        Write-Host "[OK] Random Read: Excellent (NVMe SSD level)" -ForegroundColor Green
    } elseif ($randomReadIOPS -gt 1000) {
        Write-Host "[OK] Random Read: Good (SATA SSD level)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Random Read: Slow (HDD or high system load)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "=== I/O Performance Test Complete ===" -ForegroundColor Green
}
