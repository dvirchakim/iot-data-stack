# IoT Data Stack - Complete Setup and Configuration Script
# This script installs all necessary components and configures the data flow between services
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
Write-ColoredMessage "  IoT Data Stack - Complete Setup & Configuration   " -ForegroundColor Cyan
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "This script will:" -ForegroundColor Cyan
Write-ColoredMessage "1. Install Docker Desktop and required dependencies" -ForegroundColor Cyan
Write-ColoredMessage "2. Configure the Docker stack components" -ForegroundColor Cyan
Write-ColoredMessage "3. Set up data flows between services" -ForegroundColor Cyan
Write-ColoredMessage "4. Configure ChirpStack integration" -ForegroundColor Cyan
Write-ColoredMessage "====================================================" -ForegroundColor Cyan

# Get ChirpStack server information
Write-ColoredMessage "Please enter your ChirpStack server information:" -ForegroundColor Yellow
$chirpstackHost = Read-Host "ChirpStack server IP address (default: 192.168.0.244)"
if ([string]::IsNullOrWhiteSpace($chirpstackHost)) {
    $chirpstackHost = "192.168.0.244"
}
$chirpstackPort = Read-Host "ChirpStack server port (default: 8080)"
if ([string]::IsNullOrWhiteSpace($chirpstackPort)) {
    $chirpstackPort = "8080"
}

# Get custom credentials if desired
Write-ColoredMessage "Would you like to use custom credentials for the services? (default: No)" -ForegroundColor Yellow
$useCustomCredentials = Read-Host "Enter 'Y' for Yes, any other key for No"
if ($useCustomCredentials -eq "Y" -or $useCustomCredentials -eq "y") {
    $influxdbUsername = Read-Host "InfluxDB username (default: admin)"
    if ([string]::IsNullOrWhiteSpace($influxdbUsername)) {
        $influxdbUsername = "admin"
    }
    $influxdbPassword = Read-Host "InfluxDB password" -AsSecureString
    $influxdbPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($influxdbPassword))
    if ([string]::IsNullOrWhiteSpace($influxdbPasswordText)) {
        $influxdbPasswordText = "strongpassword123"
    }
    
    $n8nUsername = Read-Host "n8n username (default: admin)"
    if ([string]::IsNullOrWhiteSpace($n8nUsername)) {
        $n8nUsername = "admin"
    }
    $n8nPassword = Read-Host "n8n password" -AsSecureString
    $n8nPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($n8nPassword))
    if ([string]::IsNullOrWhiteSpace($n8nPasswordText)) {
        $n8nPasswordText = "strongpassword123"
    }
    
    $influxdbToken = Read-Host "InfluxDB API token (leave empty to generate automatically)"
    if ([string]::IsNullOrWhiteSpace($influxdbToken)) {
        $influxdbToken = "my-super-secret-auth-token"
    }
} else {
    $influxdbUsername = "admin"
    $influxdbPasswordText = "strongpassword123"
    $n8nUsername = "admin"
    $n8nPasswordText = "strongpassword123"
    $influxdbToken = "my-super-secret-auth-token"
}

# Create a temporary directory for downloads
$tempDir = "$env:TEMP\iot-stack-setup"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# PART 1: INSTALL REQUIRED SOFTWARE
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "PART 1: Installing required software" -ForegroundColor Cyan
Write-ColoredMessage "====================================================" -ForegroundColor Cyan

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
    
    $restartNeeded = $true
} else {
    Write-ColoredMessage "Docker Desktop is already installed." -ForegroundColor Green
    $restartNeeded = $false
}

# PART 2: CONFIGURE DOCKER STACK
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "PART 2: Configuring Docker stack" -ForegroundColor Cyan
Write-ColoredMessage "====================================================" -ForegroundColor Cyan

# Get the current directory
$currentDir = Get-Location

# Update docker-compose.yml with custom credentials
Write-ColoredMessage "Updating docker-compose.yml with your settings..." -ForegroundColor Yellow

$dockerComposeFile = Join-Path $currentDir "docker-compose.yml"
$dockerComposeContent = Get-Content $dockerComposeFile -Raw

# Replace credentials in docker-compose.yml
$dockerComposeContent = $dockerComposeContent -replace "DOCKER_INFLUXDB_INIT_USERNAME=admin", "DOCKER_INFLUXDB_INIT_USERNAME=$influxdbUsername"
$dockerComposeContent = $dockerComposeContent -replace "DOCKER_INFLUXDB_INIT_PASSWORD=strongpassword123", "DOCKER_INFLUXDB_INIT_PASSWORD=$influxdbPasswordText"
$dockerComposeContent = $dockerComposeContent -replace "DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=my-super-secret-auth-token", "DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$influxdbToken"
$dockerComposeContent = $dockerComposeContent -replace "N8N_BASIC_AUTH_USER=admin", "N8N_BASIC_AUTH_USER=$n8nUsername"
$dockerComposeContent = $dockerComposeContent -replace "N8N_BASIC_AUTH_PASSWORD=strongpassword123", "N8N_BASIC_AUTH_PASSWORD=$n8nPasswordText"

# Add N8N_SECURE_COOKIE=false if it doesn't exist
if (-not ($dockerComposeContent -match "N8N_SECURE_COOKIE=false")) {
    Write-ColoredMessage "Adding N8N_SECURE_COOKIE=false to fix secure cookie issue..." -ForegroundColor Yellow
    $dockerComposeContent = $dockerComposeContent -replace "- GENERIC_TIMEZONE=UTC", "- GENERIC_TIMEZONE=UTC`n      - N8N_SECURE_COOKIE=false"
}

# Write updated docker-compose.yml
Set-Content -Path $dockerComposeFile -Value $dockerComposeContent

# Update Home Assistant configuration
Write-ColoredMessage "Updating Home Assistant configuration..." -ForegroundColor Yellow

$haConfigFile = Join-Path $currentDir "config\homeassistant\configuration.yaml"
$haConfigContent = Get-Content $haConfigFile -Raw

# Replace token in Home Assistant configuration
$haConfigContent = $haConfigContent -replace "token: my-super-secret-auth-token", "token: $influxdbToken"

# Write updated Home Assistant configuration
Set-Content -Path $haConfigFile -Value $haConfigContent

# Update n8n workflow
Write-ColoredMessage "Updating n8n workflow configuration..." -ForegroundColor Yellow

$n8nWorkflowFile = Join-Path $currentDir "n8n-workflows\chirpstack-to-influxdb.json"
$n8nWorkflowContent = Get-Content $n8nWorkflowFile -Raw

# Replace token in n8n workflow
$n8nWorkflowContent = $n8nWorkflowContent -replace "my-super-secret-auth-token", "$influxdbToken"

# Write updated n8n workflow
Set-Content -Path $n8nWorkflowFile -Value $n8nWorkflowContent

# Update Nginx configuration for ChirpStack
Write-ColoredMessage "Updating Nginx configuration for ChirpStack integration..." -ForegroundColor Yellow

$nginxConfigFile = Join-Path $currentDir "nginx\conf.d\default.conf"
$nginxConfigContent = Get-Content $nginxConfigFile -Raw

# Add ChirpStack proxy configuration if needed
if (-not ($nginxConfigContent -match "location /chirpstack-webhook")) {
    $nginxConfigContent = $nginxConfigContent -replace "location /health {", @"
    # ChirpStack HTTP integration endpoint
    location /chirpstack-webhook {
        proxy_pass http://n8n:5678/webhook/chirpstack;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
"@
}

# Write updated Nginx configuration
Set-Content -Path $nginxConfigFile -Value $nginxConfigContent

# PART 3: PREPARE CHIRPSTACK INTEGRATION
Write-ColoredMessage "====================================================" -ForegroundColor Cyan
Write-ColoredMessage "PART 3: Preparing ChirpStack integration" -ForegroundColor Cyan
Write-ColoredMessage "====================================================" -ForegroundColor Cyan

# Create a ChirpStack integration guide
$chirpstackGuideFile = Join-Path $currentDir "chirpstack-integration-guide.md"
$chirpstackGuideContent = @"
# ChirpStack HTTP Integration Guide

This guide will help you set up the HTTP integration between your ChirpStack server and the IoT data stack.

## Prerequisites

- ChirpStack server running at $chirpstackHost:$chirpstackPort
- IoT data stack running on your machine

## Steps to Configure ChirpStack HTTP Integration

1. Log in to your ChirpStack server at http://$chirpstackHost:$chirpstackPort
2. Navigate to your application
3. Go to the "Integrations" tab
4. Click "Add HTTP integration"
5. Configure the integration as follows:
   - Payload encoding: JSON
   - Event endpoint URL(s): `http://YOUR_MACHINE_IP:8080/chirpstack-webhook`
     (Replace YOUR_MACHINE_IP with your computer's IP address)
   - Add any required headers if needed
6. Click "Submit" to save the integration

## Testing the Integration

1. Make sure your IoT data stack is running (`docker-compose up -d`)
2. Send a test message from one of your devices
3. Check the logs in n8n to verify that the message was received:
   ```
   docker-compose logs -f n8n
   ```
4. Check InfluxDB to verify that the data was stored:
   - Access InfluxDB at http://localhost:8086
   - Log in with username: $influxdbUsername, password: $influxdbPasswordText
   - Go to "Data Explorer" and select the "iot-data" bucket
   - You should see your device data

## Troubleshooting

If you're not seeing data flow through the system:

1. Check that your ChirpStack server can reach your computer's IP address
2. Verify that port 8080 is open in your firewall
3. Check the logs of each service:
   ```
   docker-compose logs -f http-broker
   docker-compose logs -f n8n
   docker-compose logs -f influxdb
   docker-compose logs -f homeassistant
   ```
4. Verify that the webhook URL is correctly configured in ChirpStack
"@

# Write ChirpStack integration guide
Set-Content -Path $chirpstackGuideFile -Value $chirpstackGuideContent

# Clean up
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Check if restart is needed
if ($restartNeeded) {
    Write-ColoredMessage "====================================================" -ForegroundColor Yellow
    Write-ColoredMessage "A system restart is required to complete the installation." -ForegroundColor Yellow
    Write-ColoredMessage "Please restart your computer before continuing." -ForegroundColor Yellow
    Write-ColoredMessage "====================================================" -ForegroundColor Yellow
    
    $restartNow = Read-Host "Would you like to restart now? (Y/N)"
    if ($restartNow -eq "Y" -or $restartNow -eq "y") {
        Restart-Computer -Force
    }
} else {
    # Start Docker services
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
    Write-ColoredMessage "PART 4: Starting the IoT data stack" -ForegroundColor Cyan
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
    
    # Check if Docker Desktop is running
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-ColoredMessage "Starting Docker Desktop..." -ForegroundColor Yellow
        Start-Process "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        
        # Wait for Docker to start
        Write-ColoredMessage "Waiting for Docker to start (this may take a minute)..." -ForegroundColor Yellow
        $dockerRunning = $false
        $attempts = 0
        $maxAttempts = 30
        
        while (-not $dockerRunning -and $attempts -lt $maxAttempts) {
            try {
                $null = docker info
                $dockerRunning = $true
            } catch {
                Start-Sleep -Seconds 2
                $attempts++
            }
        }
        
        if ($dockerRunning) {
            Write-ColoredMessage "Docker is now running!" -ForegroundColor Green
        } else {
            Write-ColoredMessage "Docker did not start within the expected time. Please start Docker Desktop manually." -ForegroundColor Red
            exit
        }
    } else {
        Write-ColoredMessage "Docker Desktop is already running." -ForegroundColor Green
    }
    
    # Start the Docker stack
    Write-ColoredMessage "Starting the IoT data stack with docker-compose..." -ForegroundColor Yellow
    try {
        Set-Location $currentDir
        docker-compose up -d
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredMessage "IoT data stack started successfully!" -ForegroundColor Green
        } else {
            Write-ColoredMessage "Failed to start the IoT data stack. Please check the error message above." -ForegroundColor Red
            exit
        }
    } catch {
        Write-ColoredMessage "An error occurred while starting the Docker stack: $_" -ForegroundColor Red
        exit
    }
    
    # Get the local IP address
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*" | Where-Object { $_.IPAddress -notlike "169.254.*" }).IPAddress
    if (-not $localIP) {
        $localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" | Where-Object { $_.IPAddress -notlike "169.254.*" }).IPAddress
    }
    if (-not $localIP) {
        $localIP = "YOUR_MACHINE_IP"
    }
    
    # Final instructions
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
    Write-ColoredMessage "Setup and configuration completed!" -ForegroundColor Green
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
    Write-ColoredMessage "Your IoT data stack is now running. You can access the services at:" -ForegroundColor Yellow
    Write-ColoredMessage "- InfluxDB: http://localhost:8086" -ForegroundColor Green
    Write-ColoredMessage "  Username: $influxdbUsername" -ForegroundColor Green
    Write-ColoredMessage "  Password: $influxdbPasswordText" -ForegroundColor Green
    Write-ColoredMessage "- n8n: http://localhost:5678" -ForegroundColor Green
    Write-ColoredMessage "  Username: $n8nUsername" -ForegroundColor Green
    Write-ColoredMessage "  Password: $n8nPasswordText" -ForegroundColor Green
    Write-ColoredMessage "- Home Assistant: http://localhost:8123" -ForegroundColor Green
    Write-ColoredMessage "- HTTP Broker: http://localhost:8080" -ForegroundColor Green
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
    Write-ColoredMessage "ChirpStack HTTP Integration URL:" -ForegroundColor Yellow
    Write-ColoredMessage "http://$localIP:8080/chirpstack-webhook" -ForegroundColor Green
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
    Write-ColoredMessage "A detailed ChirpStack integration guide has been created:" -ForegroundColor Yellow
    Write-ColoredMessage "$chirpstackGuideFile" -ForegroundColor Green
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
    Write-ColoredMessage "To stop the stack, run: docker-compose down" -ForegroundColor Yellow
    Write-ColoredMessage "To view logs, run: docker-compose logs -f" -ForegroundColor Yellow
    Write-ColoredMessage "====================================================" -ForegroundColor Cyan
}
