# Windows Setup Script for IoT Data Stack
# This script installs all necessary components for the IoT data stack on Windows
# Run this script in PowerShell with Administrator privileges

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator. Please restart PowerShell as Administrator and try again." -ForegroundColor Red
    exit
}

# Function to display colored messages
function Write-ColoredMessage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Function to check if a program is installed
function Test-ProgramInstalled {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ProgramName
    )
    
    $installed = $false
    
    # Check in Program Files
    if (Test-Path "${env:ProgramFiles}\$ProgramName" -ErrorAction SilentlyContinue) {
        $installed = $true
    }
    # Check in Program Files (x86)
    elseif (Test-Path "${env:ProgramFiles(x86)}\$ProgramName" -ErrorAction SilentlyContinue) {
        $installed = $true
    }
    # Check in the PATH
    elseif (Get-Command $ProgramName -ErrorAction SilentlyContinue) {
        $installed = $true
    }
    
    return $installed
}

# Display welcome message
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "      IoT Data Stack - Windows Setup Script         " -ForegroundColor Cyan
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "This script will install the following components:" -ForegroundColor Cyan
Write-ColoredMessage "  - Docker Desktop (requires Windows 10/11 Pro/Enterprise/Education)" -ForegroundColor Cyan
Write-ColoredMessage "  - Git for Windows" -ForegroundColor Cyan
Write-ColoredMessage "  - WSL 2 (Windows Subsystem for Linux)" -ForegroundColor Cyan
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "Press Enter to continue or Ctrl+C to cancel..." -ForegroundColor Yellow
$null = Read-Host

# Check Windows version
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$osVersion = [Version]$osInfo.Version
$osName = $osInfo.Caption

Write-ColoredMessage "Detected OS: $osName (Version $osVersion)" -ForegroundColor Green

if ($osVersion -lt [Version]"10.0.17763") {
    Write-ColoredMessage "Docker Desktop requires Windows 10 version 1809 (build 17763) or later." -ForegroundColor Red
    Write-ColoredMessage "Please update your Windows version and try again." -ForegroundColor Red
    exit
}

# Create a temporary directory for downloads
$tempDir = "$env:TEMP\iot-stack-setup"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Install Chocolatey if not already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-ColoredMessage "Installing Chocolatey package manager..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Add Chocolatey to the current session's PATH
    $env:Path = "$env:Path;$env:ALLUSERSPROFILE\chocolatey\bin"
    
    Write-ColoredMessage "Chocolatey installed successfully!" -ForegroundColor Green
} else {
    Write-ColoredMessage "Chocolatey is already installed." -ForegroundColor Green
}

# Install Git if not already installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ColoredMessage "Installing Git for Windows..." -ForegroundColor Yellow
    choco install git -y
    
    # Add Git to the current session's PATH
    $env:Path = "$env:Path;$env:ProgramFiles\Git\cmd"
    
    Write-ColoredMessage "Git installed successfully!" -ForegroundColor Green
} else {
    Write-ColoredMessage "Git is already installed." -ForegroundColor Green
}

# Enable WSL 2
Write-ColoredMessage "Enabling Windows Subsystem for Linux (WSL)..." -ForegroundColor Yellow
try {
    # Enable WSL feature
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    
    # Enable Virtual Machine Platform
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    Write-ColoredMessage "WSL features enabled. You may need to restart your computer." -ForegroundColor Green
    
    # Download and install WSL2 kernel update
    $wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $wslUpdateFile = "$tempDir\wsl_update_x64.msi"
    
    Write-ColoredMessage "Downloading WSL2 kernel update..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdateFile -UseBasicParsing
    
    Write-ColoredMessage "Installing WSL2 kernel update..." -ForegroundColor Yellow
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $wslUpdateFile, "/quiet", "/norestart" -Wait
    
    # Set WSL2 as default
    Write-ColoredMessage "Setting WSL2 as default..." -ForegroundColor Yellow
    wsl --set-default-version 2
    
    Write-ColoredMessage "WSL2 setup completed!" -ForegroundColor Green
} catch {
    Write-ColoredMessage "An error occurred while setting up WSL: $_" -ForegroundColor Red
    Write-ColoredMessage "You may need to enable virtualization in your BIOS settings." -ForegroundColor Yellow
}

# Install Docker Desktop if not already installed
if (-not (Test-ProgramInstalled "Docker Desktop")) {
    Write-ColoredMessage "Installing Docker Desktop..." -ForegroundColor Yellow
    
    $dockerUrl = "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = "$tempDir\DockerDesktopInstaller.exe"
    
    Write-ColoredMessage "Downloading Docker Desktop..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
    
    Write-ColoredMessage "Installing Docker Desktop (this may take a while)..." -ForegroundColor Yellow
    Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet" -Wait
    
    Write-ColoredMessage "Docker Desktop installed successfully!" -ForegroundColor Green
    Write-ColoredMessage "You may need to restart your computer to complete the Docker installation." -ForegroundColor Yellow
} else {
    Write-ColoredMessage "Docker Desktop is already installed." -ForegroundColor Green
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Final instructions
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "Installation completed!" -ForegroundColor Green
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "Next steps:" -ForegroundColor Yellow
Write-ColoredMessage "1. Restart your computer if prompted" -ForegroundColor Yellow
Write-ColoredMessage "2. Start Docker Desktop from the Start menu" -ForegroundColor Yellow
Write-ColoredMessage "3. Open a PowerShell window in the IoT data stack directory" -ForegroundColor Yellow
Write-ColoredMessage "4. Run the following command to start the stack:" -ForegroundColor Yellow
Write-ColoredMessage "   docker-compose up -d" -ForegroundColor Green
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "You can access your services at:" -ForegroundColor Yellow
Write-ColoredMessage "- InfluxDB: http://localhost:8086" -ForegroundColor Green
Write-ColoredMessage "- n8n: http://localhost:5678" -ForegroundColor Green
Write-ColoredMessage "- Home Assistant: http://localhost:8123" -ForegroundColor Green
Write-ColoredMessage "- HTTP Broker: http://localhost:8080" -ForegroundColor Green
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
