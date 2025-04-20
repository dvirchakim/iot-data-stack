# IoT Data Stack with ChirpStack Integration

This Docker stack provides a complete solution for collecting, processing, and visualizing IoT data from ChirpStack. It includes:

- **n8n**: Workflow automation platform for data processing
- **InfluxDB**: Time series database for storing sensor data
- **HTTP Broker (Nginx)**: Handles HTTP requests from ChirpStack
- **Home Assistant**: Dashboard and visualization platform

## Features

- **Complete IoT Pipeline**: From device data collection to visualization
- **Auto-Discovery System**: Automatically detects and registers new devices and sensors
- **Containerized Architecture**: Easy deployment and scaling
- **Pre-configured Integration**: Ready-to-use ChirpStack integration
- **Customizable Dashboards**: Visualize your IoT data with Home Assistant

## Quick Start

The easiest way to get started is to use one of our setup scripts:

### For Ubuntu 22.04 (Recommended)

```bash
# Clone the repository
git clone https://github.com/dvirchakim/iot-data-stack.git

# Navigate to the directory
cd iot-data-stack

# Make the script executable
chmod +x ubuntu-setup.sh

# Run the setup script (requires sudo)
sudo ./ubuntu-setup.sh
```

The script will:
1. Install Docker and Docker Compose if needed
2. Configure all services with your custom settings
3. Set up the data flow between ChirpStack, n8n, InfluxDB, and Home Assistant
4. Start the Docker stack
5. Provide you with access URLs and credentials

### For Other Linux Distributions

```bash
# Clone the repository
git clone https://github.com/dvirchakim/iot-data-stack.git

# Navigate to the directory
cd iot-data-stack

# Make the script executable
chmod +x deploy.sh

# Run the deployment script (requires sudo)
sudo ./deploy.sh
```

### For Windows (Testing Only)

```powershell
# Clone the repository
git clone https://github.com/dvirchakim/iot-data-stack.git

# Navigate to the directory
cd iot-data-stack

# Run the setup script as Administrator in PowerShell
.\setup-and-configure.ps1
```

## Prerequisites

Before setting up this stack, ensure you have:

1. Ubuntu 22.04 (or similar Linux distribution)
2. Docker and Docker Compose installed (installation instructions in the setup scripts)
3. A working ChirpStack server (configured at 192.168.0.244:8080)

## Installation Options

This project offers three ways to install and configure the IoT data stack:

1. **Recommended**: Use the Ubuntu setup script for a fully automated installation
2. **Alternative**: Use the deployment script for other Linux distributions
3. **Manual Installation**: For those who prefer to set up each component manually

For detailed manual installation instructions, see [MANUAL-INSTALLATION.md](MANUAL-INSTALLATION.md).

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

> **Note**: If you used one of the setup scripts, a detailed ChirpStack integration guide will be created in the project directory. This guide includes specific instructions for your environment.

### n8n Workflow Setup

1. Access n8n at `http://your-docker-host-ip:5678`
2. Log in with the credentials:
   - Username: admin (or your custom username if you used a setup script)
   - Password: strongpassword123 (or your custom password if you used a setup script)
3. Create a new workflow or import the provided template:
   - Go to "Workflows" > "Import from File"
   - Select the file `n8n-workflows/chirpstack-to-influxdb.json`
   - The workflow will be pre-configured with the correct settings
4. Activate the workflow by clicking the "Active" toggle in the top-right corner

> **Note**: The setup scripts automatically configure n8n with the correct settings for your environment.

### InfluxDB Setup

InfluxDB is automatically configured with the following settings:
- URL: `http://your-docker-host-ip:8086`
- Username: admin (or your custom username if you used a setup script)
- Password: strongpassword123 (or your custom password if you used a setup script)
- Organization: iot-org
- Bucket: iot-data
- Retention period: 5 years (1825 days)

> **Note**: If you used one of the setup scripts, InfluxDB will be pre-configured with your custom settings.

### Home Assistant Setup

1. Access Home Assistant at `http://your-docker-host-ip:8123`
2. Follow the initial setup wizard
3. Home Assistant is pre-configured to integrate with InfluxDB using the settings in `config/homeassistant/configuration.yaml`

> **Note**: If you're using a non-English interface (like Hebrew), you may need to manually configure some settings. The setup scripts create a pre-configured Home Assistant instance that should work without additional configuration.

## Auto-Discovery System

This stack includes a powerful auto-discovery system that automatically detects, classifies, and registers new devices and sensors from ChirpStack without requiring manual configuration.

### How It Works

1. **Automatic Detection**: When a new device sends data through ChirpStack, the system automatically detects it
2. **Sensor Classification**: The system analyzes the payload to identify sensor types (temperature, humidity, etc.)
3. **Dynamic Registration**: New devices and sensors are automatically registered in the system
4. **Dashboard Integration**: The dashboard is automatically updated with new devices and sensors

### Setting Up Auto-Discovery

1. **Import the n8n Workflow**:
   - Access n8n at `http://your-server-ip:5678`
   - Go to Workflows → Import From File
   - Select the file `n8n-workflows/auto-discovery-agent.json`
   - Save and activate the workflow

2. **Enable in Home Assistant**:
   - Add the contents of `home-assistant-auto-discovery.yaml` to your Home Assistant configuration
   - Copy the dashboard file to your dashboards directory:
     ```bash
     cp dashboards/auto-discovered-devices.yaml /opt/iot-data-stack/config/homeassistant/dashboards/
     ```
   - Restart Home Assistant: `docker-compose restart homeassistant`

3. **Configure ChirpStack**:
   - Set the HTTP integration URL to: `http://your-server-ip:8080/chirpstack-webhook`

For detailed instructions, see [README-auto-discovery.md](README-auto-discovery.md).

## Maintenance

- To update the stack: `docker-compose pull && docker-compose up -d`
- To view logs: `docker-compose logs -f [service_name]`
- To restart a service: `docker-compose restart [service_name]`
- To stop the stack: `docker-compose down`
- To stop and remove volumes: `docker-compose down -v` (caution: this will delete all data)

## Security Considerations

For a production environment, consider:
1. Changing all default passwords in the docker-compose.yml file
2. Setting up HTTPS with proper certificates
3. Implementing network segmentation and firewall rules
4. Using Docker secrets for sensitive information

## Troubleshooting

### Common Issues

1. **ChirpStack data not appearing in InfluxDB**
   - Check that your ChirpStack server can reach your Docker host
   - Verify the webhook URL is correct in ChirpStack
   - Check the logs of the HTTP broker: `docker-compose logs -f http-broker`
   - Check the logs of n8n: `docker-compose logs -f n8n`

2. **Home Assistant not showing sensor data**
   - Verify that data is being stored in InfluxDB
   - Check the Home Assistant configuration in `config/homeassistant/configuration.yaml`
   - Restart Home Assistant: `docker-compose restart homeassistant`

3. **Docker permission issues**
   - If you get "permission denied" errors, make sure your user is in the docker group:
     ```bash
     sudo usermod -aG docker $USER
     newgrp docker  # Apply group changes without logging out
     ```

4. **Network connectivity issues**
   - Ensure that all required ports are open in your firewall:
     ```bash
     sudo ufw allow 8080/tcp  # HTTP Broker
     sudo ufw allow 8086/tcp  # InfluxDB
     sudo ufw allow 5678/tcp  # n8n
     sudo ufw allow 8123/tcp  # Home Assistant
     ```

5. **n8n secure cookie issue**
   - If you see a warning about secure cookies in n8n, restart the stack:
     ```bash
     docker-compose down
     docker-compose up -d
     ```
   - The stack is pre-configured to fix this issue with `N8N_SECURE_COOKIE=false`

### Getting Help

If you encounter issues not covered in this troubleshooting section:
1. Check the logs of all services: `docker-compose logs`
2. See the [fix-webhook.md](fix-webhook.md) guide for webhook-specific issues
3. Refer to the [README-auto-discovery.md](README-auto-discovery.md) for auto-discovery issues
4. Open an issue on GitHub with detailed information about your problem
5. Include relevant logs and your environment details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
