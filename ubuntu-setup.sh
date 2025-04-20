#!/bin/bash
# IoT Data Stack - Ubuntu 22.04 Setup and Configuration Script
# This script installs Docker and configures the IoT data stack on Ubuntu 22.04
# Run with: sudo bash ubuntu-setup.sh

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root or with sudo${NC}"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    echo -e "${YELLOW}Warning: This script is designed for Ubuntu 22.04. You are running:${NC}"
    cat /etc/os-release | grep "PRETTY_NAME"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Welcome message
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}  IoT Data Stack - Ubuntu 22.04 Setup & Configuration${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}This script will:${NC}"
echo -e "${CYAN}1. Install Docker and Docker Compose${NC}"
echo -e "${CYAN}2. Configure the Docker stack components${NC}"
echo -e "${CYAN}3. Set up data flows between services${NC}"
echo -e "${CYAN}4. Configure ChirpStack integration${NC}"
echo -e "${CYAN}====================================================${NC}"
echo

# Get ChirpStack server information
echo -e "${YELLOW}Please enter your ChirpStack server information:${NC}"
read -p "ChirpStack server IP address (default: 192.168.0.244): " chirpstack_host
chirpstack_host=${chirpstack_host:-192.168.0.244}

read -p "ChirpStack server port (default: 8080): " chirpstack_port
chirpstack_port=${chirpstack_port:-8080}

# Get custom credentials if desired
echo -e "${YELLOW}Would you like to use custom credentials for the services? (default: No)${NC}"
read -p "Enter 'y' for Yes, any other key for No: " use_custom_credentials

if [[ $use_custom_credentials =~ ^[Yy]$ ]]; then
    read -p "InfluxDB username (default: admin): " influxdb_username
    influxdb_username=${influxdb_username:-admin}
    
    read -p "InfluxDB password (default: strongpassword123): " influxdb_password
    influxdb_password=${influxdb_password:-strongpassword123}
    
    read -p "n8n username (default: admin): " n8n_username
    n8n_username=${n8n_username:-admin}
    
    read -p "n8n password (default: strongpassword123): " n8n_password
    n8n_password=${n8n_password:-strongpassword123}
    
    read -p "InfluxDB API token (leave empty to generate automatically): " influxdb_token
    influxdb_token=${influxdb_token:-my-super-secret-auth-token}
else
    influxdb_username="admin"
    influxdb_password="strongpassword123"
    n8n_username="admin"
    n8n_password="strongpassword123"
    influxdb_token="my-super-secret-auth-token"
fi

# PART 1: INSTALL REQUIRED SOFTWARE
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}PART 1: Installing required software${NC}"
echo -e "${CYAN}====================================================${NC}"

# Update package index
echo -e "${YELLOW}Updating package index...${NC}"
apt update

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index again
    apt update
    
    # Install Docker
    apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add the current user to the docker group
    if [ "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
        echo -e "${GREEN}Added user $SUDO_USER to the docker group${NC}"
        echo -e "${YELLOW}You may need to log out and back in for this to take effect${NC}"
    fi
    
    echo -e "${GREEN}Docker installed successfully!${NC}"
else
    echo -e "${GREEN}Docker is already installed.${NC}"
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose not found. Installing Docker Compose...${NC}"
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    echo -e "${GREEN}Docker Compose installed successfully!${NC}"
else
    echo -e "${GREEN}Docker Compose is already installed.${NC}"
fi

# PART 2: CONFIGURE DOCKER STACK
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}PART 2: Configuring Docker stack${NC}"
echo -e "${CYAN}====================================================${NC}"

# Create project directory
PROJECT_DIR="/opt/iot-data-stack"
echo -e "${YELLOW}Creating project directory at $PROJECT_DIR...${NC}"
mkdir -p $PROJECT_DIR

# Copy all files to the project directory
echo -e "${YELLOW}Copying project files...${NC}"
cp -r * $PROJECT_DIR/

# Create required directories
mkdir -p $PROJECT_DIR/config/homeassistant/dashboards

# Update docker-compose.yml with custom credentials
echo -e "${YELLOW}Updating docker-compose.yml with your settings...${NC}"

# Replace credentials in docker-compose.yml
sed -i "s/DOCKER_INFLUXDB_INIT_USERNAME=admin/DOCKER_INFLUXDB_INIT_USERNAME=$influxdb_username/" $PROJECT_DIR/docker-compose.yml
sed -i "s/DOCKER_INFLUXDB_INIT_PASSWORD=strongpassword123/DOCKER_INFLUXDB_INIT_PASSWORD=$influxdb_password/" $PROJECT_DIR/docker-compose.yml
sed -i "s/DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=my-super-secret-auth-token/DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$influxdb_token/" $PROJECT_DIR/docker-compose.yml
sed -i "s/N8N_BASIC_AUTH_USER=admin/N8N_BASIC_AUTH_USER=$n8n_username/" $PROJECT_DIR/docker-compose.yml
sed -i "s/N8N_BASIC_AUTH_PASSWORD=strongpassword123/N8N_BASIC_AUTH_PASSWORD=$n8n_password/" $PROJECT_DIR/docker-compose.yml

# Add N8N_SECURE_COOKIE=false if it doesn't exist
if ! grep -q "N8N_SECURE_COOKIE=false" $PROJECT_DIR/docker-compose.yml; then
    echo -e "${YELLOW}Adding N8N_SECURE_COOKIE=false to fix secure cookie issue...${NC}"
    sed -i "/GENERIC_TIMEZONE=UTC/a \ \ \ \ \ \ - N8N_SECURE_COOKIE=false" $PROJECT_DIR/docker-compose.yml
fi

# Update Home Assistant configuration
echo -e "${YELLOW}Updating Home Assistant configuration...${NC}"

# Replace token in Home Assistant configuration
sed -i "s/token: my-super-secret-auth-token/token: $influxdb_token/" $PROJECT_DIR/config/homeassistant/configuration.yaml

# Update n8n workflow
echo -e "${YELLOW}Updating n8n workflow configuration...${NC}"

# Replace token in n8n workflow
sed -i "s/my-super-secret-auth-token/$influxdb_token/" $PROJECT_DIR/n8n-workflows/chirpstack-to-influxdb.json

# PART 3: PREPARE CHIRPSTACK INTEGRATION
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}PART 3: Preparing ChirpStack integration${NC}"
echo -e "${CYAN}====================================================${NC}"

# Create a ChirpStack integration guide
cat > $PROJECT_DIR/chirpstack-integration-guide.md << EOL
# ChirpStack HTTP Integration Guide

This guide will help you set up the HTTP integration between your ChirpStack server and the IoT data stack.

## Prerequisites

- ChirpStack server running at $chirpstack_host:$chirpstack_port
- IoT data stack running on your Ubuntu server

## Steps to Configure ChirpStack HTTP Integration

1. Log in to your ChirpStack server at http://$chirpstack_host:$chirpstack_port
2. Navigate to your application
3. Go to the "Integrations" tab
4. Click "Add HTTP integration"
5. Configure the integration as follows:
   - Payload encoding: JSON
   - Event endpoint URL(s): \`http://YOUR_SERVER_IP:8080/chirpstack-webhook\`
     (Replace YOUR_SERVER_IP with your Ubuntu server's IP address)
   - Add any required headers if needed
6. Click "Submit" to save the integration

## Testing the Integration

1. Make sure your IoT data stack is running (\`docker-compose up -d\`)
2. Send a test message from one of your devices
3. Check the logs in n8n to verify that the message was received:
   \`\`\`
   docker-compose logs -f n8n
   \`\`\`
4. Check InfluxDB to verify that the data was stored:
   - Access InfluxDB at http://YOUR_SERVER_IP:8086
   - Log in with username: $influxdb_username, password: $influxdb_password
   - Go to "Data Explorer" and select the "iot-data" bucket
   - You should see your device data

## Troubleshooting

If you're not seeing data flow through the system:

1. Check that your ChirpStack server can reach your Ubuntu server's IP address
2. Verify that port 8080 is open in your firewall:
   \`\`\`
   sudo ufw status
   \`\`\`
   If the firewall is enabled, allow the necessary ports:
   \`\`\`
   sudo ufw allow 8080/tcp
   sudo ufw allow 8086/tcp
   sudo ufw allow 5678/tcp
   sudo ufw allow 8123/tcp
   \`\`\`
3. Check the logs of each service:
   \`\`\`
   docker-compose logs -f http-broker
   docker-compose logs -f n8n
   docker-compose logs -f influxdb
   docker-compose logs -f homeassistant
   \`\`\`
4. Verify that the webhook URL is correctly configured in ChirpStack
EOL

# Set proper permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chown -R 1000:1000 $PROJECT_DIR/config

# PART 4: START THE STACK
echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}PART 4: Starting the IoT data stack${NC}"
echo -e "${CYAN}====================================================${NC}"

# Start the Docker stack
echo -e "${YELLOW}Starting the IoT data stack with docker-compose...${NC}"
cd $PROJECT_DIR
docker-compose up -d

# Check if all services are running
echo -e "${YELLOW}Checking service status...${NC}"
sleep 10
docker-compose ps

# Get the server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Configure firewall if it's active
if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
    echo -e "${YELLOW}Configuring firewall to allow necessary ports...${NC}"
    ufw allow 8080/tcp
    ufw allow 8086/tcp
    ufw allow 5678/tcp
    ufw allow 8123/tcp
    echo -e "${GREEN}Firewall configured.${NC}"
fi

# Final instructions
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}Setup and configuration completed!${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}Your IoT data stack is now running. You can access the services at:${NC}"
echo -e "${GREEN}- InfluxDB: http://$SERVER_IP:8086${NC}"
echo -e "${GREEN}  Username: $influxdb_username${NC}"
echo -e "${GREEN}  Password: $influxdb_password${NC}"
echo -e "${GREEN}- n8n: http://$SERVER_IP:5678${NC}"
echo -e "${GREEN}  Username: $n8n_username${NC}"
echo -e "${GREEN}  Password: $n8n_password${NC}"
echo -e "${GREEN}- Home Assistant: http://$SERVER_IP:8123${NC}"
echo -e "${GREEN}- HTTP Broker: http://$SERVER_IP:8080${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}ChirpStack HTTP Integration URL:${NC}"
echo -e "${GREEN}http://$SERVER_IP:8080/chirpstack-webhook${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}A detailed ChirpStack integration guide has been created:${NC}"
echo -e "${GREEN}$PROJECT_DIR/chirpstack-integration-guide.md${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}To manage the stack, use these commands:${NC}"
echo -e "${GREEN}- Stop the stack: docker-compose down${NC}"
echo -e "${GREEN}- View logs: docker-compose logs -f${NC}"
echo -e "${GREEN}- Restart a service: docker-compose restart [service_name]${NC}"
echo -e "${CYAN}====================================================${NC}"

# Reminder about user permissions
if [ "$SUDO_USER" ]; then
    echo -e "${YELLOW}IMPORTANT: If you want to run docker commands without sudo, log out and log back in${NC}"
    echo -e "${YELLOW}or run this command: newgrp docker${NC}"
fi

echo -e "${GREEN}Installation complete! Your IoT data stack is ready to use.${NC}"
