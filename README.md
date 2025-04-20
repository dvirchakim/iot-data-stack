# IoT Data Stack with ChirpStack Integration

This Docker stack provides a complete solution for collecting, processing, and visualizing IoT data from ChirpStack. It includes:

- **n8n**: Workflow automation platform for data processing
- **InfluxDB**: Time series database for storing sensor data
- **HTTP Broker (Nginx)**: Handles HTTP requests from ChirpStack
- **Home Assistant**: Dashboard and visualization platform

## Prerequisites

Before setting up this stack, ensure you have:

1. Ubuntu 22.04 (or similar Linux distribution)
2. Docker and Docker Compose installed (installation instructions below)
3. A working ChirpStack server (configured at localhost:8080)

## Installation

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

1. Copy this entire directory to your Ubuntu server
2. Navigate to the directory:
   ```bash
   cd /path/to/iot-data-stack
   ```
3. Start the stack:
   ```bash
   docker-compose up -d
   ```

## Configuration

### ChirpStack HTTP Integration

1. Log in to your ChirpStack server at chirpstack-server-ip:8080
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
3. Create a new workflow:
   - Add a "Webhook" node as a trigger (use the path `/webhook/chirpstack`)
   - Add an "InfluxDB" node to store the data
   - Configure the InfluxDB connection:
     - Host: influxdb
     - Port: 8086
     - Organization: iot-org
     - Bucket: iot-data
     - API Token: my-super-secret-auth-token

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
3. To integrate with InfluxDB:
   - Go to Configuration > Integrations
   - Add the InfluxDB integration
   - Configure with:
     - URL: http://influxdb:8086
     - API Token: my-super-secret-auth-token
     - Organization: iot-org
     - Bucket: iot-data

## Security Considerations

For a production environment, consider:
1. Changing all default passwords in the docker-compose.yml file
2. Setting up HTTPS with proper certificates
3. Implementing network segmentation and firewall rules
4. Using Docker secrets for sensitive information

## Maintenance

- To update the stack: `docker-compose pull && docker-compose up -d`
- To view logs: `docker-compose logs -f [service_name]`
- To restart a service: `docker-compose restart [service_name]`
- To stop the stack: `docker-compose down`
- To stop and remove volumes: `docker-compose down -v` (caution: this will delete all data)

## Troubleshooting

- Check service status: `docker-compose ps`
- View service logs: `docker-compose logs -f [service_name]`
- Restart a specific service: `docker-compose restart [service_name]`
- Verify network connectivity between services: `docker network inspect iot-data-stack_iot-network`
