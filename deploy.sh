#!/bin/bash
# IoT Data Stack Deployment Script
# This script will set up Docker and deploy the IoT data stack

# Exit on error
set -e

# Print colored messages
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

print_red() {
    echo -e "\e[31m$1\e[0m"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_red "This script must be run as root or with sudo"
    exit 1
fi

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    print_yellow "Docker not found. Installing Docker..."
    
    # Update package index
    apt update
    
    # Install required packages
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    apt update
    
    # Install Docker
    apt install -y docker-ce docker-ce-cli containerd.io
    
    print_green "Docker installed successfully!"
else
    print_green "Docker is already installed."
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    print_yellow "Docker Compose not found. Installing Docker Compose..."
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    print_green "Docker Compose installed successfully!"
else
    print_green "Docker Compose is already installed."
fi

# Create a directory for the project
PROJECT_DIR="/opt/iot-data-stack"
print_yellow "Creating project directory at $PROJECT_DIR..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Copy all files from the current directory to the project directory
print_yellow "Copying project files..."
cp -r * $PROJECT_DIR/

# Make sure the configuration directories exist
mkdir -p $PROJECT_DIR/config/homeassistant/dashboards

# Set proper permissions
print_yellow "Setting permissions..."
chown -R 1000:1000 $PROJECT_DIR/config

# Start the Docker stack
print_yellow "Starting the IoT data stack..."
cd $PROJECT_DIR
docker-compose up -d

# Check if all services are running
print_yellow "Checking service status..."
sleep 10
docker-compose ps

# Print access information
print_green "============================================="
print_green "IoT Data Stack deployed successfully!"
print_green "============================================="
print_green "Access your services at:"
print_green "- InfluxDB: http://$(hostname -I | awk '{print $1}'):8086"
print_green "- n8n: http://$(hostname -I | awk '{print $1}'):5678"
print_green "- Home Assistant: http://$(hostname -I | awk '{print $1}'):8123"
print_green "- HTTP Broker: http://$(hostname -I | awk '{print $1}'):8080"
print_green "============================================="
print_green "ChirpStack HTTP Integration URL:"
print_green "http://$(hostname -I | awk '{print $1}'):8080/chirpstack-webhook"
print_green "============================================="
print_green "Default credentials:"
print_green "- InfluxDB: admin / strongpassword123"
print_green "- n8n: admin / strongpassword123"
print_green "- Home Assistant: Set during first login"
print_green "============================================="
print_yellow "IMPORTANT: For production use, change the default passwords in docker-compose.yml"
print_green "============================================="
