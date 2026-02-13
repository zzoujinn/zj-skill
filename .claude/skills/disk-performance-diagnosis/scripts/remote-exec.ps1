# Remote Execution Core Script (PowerShell)
# Handles remote SSH connections and command execution

param(
    [string]$HostName,
    [string]$User,
    [string]$Password,
    [int]$Port = 22,
    [int]$Timeout = 30,
    [string]$Command
)

# Validate required parameters
if (-not $HostName -or -not $User) {
    Write-Error "ERROR: Must provide hostname and username"
    exit 1
}

# Check if password is provided
if ($Password) {
    # Use plink (PuTTY) for password authentication
    $plinkPath = Get-Command plink -ErrorAction SilentlyContinue

    if ($plinkPath) {
        Write-Host "Using plink to connect to ${User}@${HostName}:${Port}..."
        $env:PLINK_PROTOCOL = "ssh"
        echo y | plink -ssh -P $Port -pw $Password -batch $User@$HostName $Command
    } else {
        Write-Host "plink not found, trying SSH..."
        Write-Warning "WARNING: Windows SSH does not support command-line password"
        Write-Host "Attempting connection (you may need to enter password manually)..."
        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$Timeout -p $Port $User@$HostName $Command
    }
} else {
    # Use SSH key authentication
    Write-Host "Connecting to ${User}@${HostName}:${Port}..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$Timeout -p $Port $User@$HostName $Command
}
