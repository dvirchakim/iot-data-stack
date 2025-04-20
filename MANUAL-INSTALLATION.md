# Manual Installation Guide

This guide provides detailed instructions for manually setting up the IoT Data Stack without using the automated scripts.

## Prerequisites

Before setting up this stack, ensure you have:

1. Ubuntu 22.04 (or similar Linux distribution)
2. Root or sudo access to the server
3. A working ChirpStack server (configured at 192.168.0.244:8080)

## Installation Steps

### 1. Install Docker and Docker Compose

```bash
# Update package index
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add your user to the docker group to run Docker without sudo
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

Note: After adding your user to the docker group, you may need to log out and back in for the changes to take effect.

### 2. Deploy the Stack

1. Clone this repository:
   ```bash
   git clone https://github.com/dvirchakim/iot-data-stack.git
   cd iot-data-stack
   ```

2. Create the configuration directories:
   ```bash
   mkdir -p config/homeassistant/dashboards
   ```

3. Copy the configuration files:
   ```bash
   cp homeassistant/configuration.yaml config/homeassistant/
   cp homeassistant/dashboards/iot-dashboard.yaml config/homeassistant/dashboards/
   ```

4. Start the stack:
   ```bash
   docker-compose up -d
   ```

## Configuration

### ChirpStack HTTP Integration

1. Log in to your ChirpStack server at 192.168.0.244:8080
2. Navigate to your application
3. Go to the "Integrations" tab
4. Click "Add HTTP integration"
5. Configure the integration as follows:
   - Payload encoding: JSON
   - Event endpoint URL(s): `http://your-docker-host-ip:8080/chirpstack-webhook`
   - Add any required headers if needed

### n8n Workflow Setup

1. Access n8n at `http://your-docker-host-ip:5678`
2. Log in with the credentials:
   - Username: admin
   - Password: strongpassword123
3. Create a new workflow or import the provided template:
   - Go to "Workflows" > "Import from File"
   - Select the file `n8n-workflows/chirpstack-to-influxdb.json`
   - The workflow will be pre-configured with the correct settings
4. Activate the workflow by clicking the "Active" toggle in the top-right corner

### InfluxDB Setup

InfluxDB is automatically configured with the following settings:
- URL: `http://your-docker-host-ip:8086`
- Username: admin
- Password: strongpassword123
- Organization: iot-org
- Bucket: iot-data
- Retention period: 5 years (1825 days)

### Home Assistant Setup

1. Access Home Assistant at `http://your-docker-host-ip:8123`
2. Follow the initial setup wizard
3. To integrate with InfluxDB manually:
   - Go to Configuration > Integrations
   - Add the InfluxDB integration
   - Configure with:
     - URL: http://influxdb:8086
     - API Token: my-super-secret-auth-token
     - Organization: iot-org
     - Bucket: iot-data

## Troubleshooting

If you encounter issues during the manual installation:

1. Check that Docker and Docker Compose are correctly installed
2. Verify that all required ports are open in your firewall
3. Check the logs of each service: `docker-compose logs -f [service_name]`
4. Ensure your user has the correct permissions to run Docker commands

For more detailed troubleshooting, refer to the main [README.md](README.md) file.
