# ChirpStack Auto-Discovery Agent

This system automatically detects, classifies, and registers new devices and sensors from incoming ChirpStack HTTP requests without requiring manual configuration.

## Overview

The Auto-Discovery Agent performs the following functions:

1. **Automatic Device Detection**: Identifies new devices from ChirpStack HTTP requests
2. **Sensor Classification**: Analyzes payload data to determine sensor types (temperature, humidity, etc.)
3. **Dynamic Registration**: Automatically registers new devices and sensors in the system
4. **Dashboard Integration**: Creates and updates dashboard entries for discovered devices
5. **Debugging Support**: Provides detailed information for troubleshooting

## Components

The system consists of three main components:

1. **n8n Workflow**: Processes incoming data, detects sensors, and maintains device registry
2. **Home Assistant Configuration**: Handles auto-discovered devices and creates entities
3. **Dashboard Configuration**: Displays auto-discovered devices and sensors

## Setup Instructions

### 1. Import the n8n Workflow

1. Access n8n at `http://your-server-ip:5678`
2. Go to Workflows → Import From File
3. Select the file `n8n-workflows/auto-discovery-agent.json`
4. Configure the InfluxDB credentials:
   - URL: `http://influxdb:8086`
   - API Token: `my-super-secret-auth-token` (or your custom token)
   - Organization: `iot-org`
   - Bucket: `iot-data`
5. Save and activate the workflow

### 2. Update Home Assistant Configuration

Add the contents of `home-assistant-auto-discovery.yaml` to your Home Assistant configuration:

1. SSH into your server
2. Edit the Home Assistant configuration file:
   ```bash
   nano /opt/iot-data-stack/config/homeassistant/configuration.yaml
   ```
3. Add the contents of `home-assistant-auto-discovery.yaml` to the file
4. Create the dashboard directory if it doesn't exist:
   ```bash
   mkdir -p /opt/iot-data-stack/config/homeassistant/dashboards
   ```
5. Copy the dashboard file:
   ```bash
   cp dashboards/auto-discovered-devices.yaml /opt/iot-data-stack/config/homeassistant/dashboards/
   ```
6. Restart Home Assistant:
   ```bash
   docker-compose restart homeassistant
   ```

### 3. Configure ChirpStack

Configure your ChirpStack application to send data to the Auto-Discovery webhook:

1. Go to your ChirpStack application
2. Navigate to Integrations
3. Add or edit your HTTP integration
4. Set the URL to: `http://your-server-ip:8080/chirpstack-webhook`
5. Make sure the payload format is set to JSON
6. Save the integration

## How It Works

1. **Data Reception**: ChirpStack sends device data to the HTTP webhook
2. **Data Analysis**: The n8n workflow analyzes the payload to identify:
   - Device information (EUI, name, application)
   - Sensor types (temperature, humidity, etc.)
   - Value types and units
3. **Device Registry**: The system maintains a registry of all discovered devices and sensors
4. **InfluxDB Storage**: Sensor data is stored in InfluxDB for historical analysis
5. **Home Assistant Integration**: Home Assistant is notified about new devices and sensors
6. **Dashboard Updates**: The dashboard automatically updates to display new entities

## Sensor Type Detection

The system can automatically detect various sensor types based on payload field names and values:

- Temperature sensors
- Humidity sensors
- Pressure sensors
- Battery levels
- Light/illuminance sensors
- Motion/presence sensors
- Door/window sensors
- Gas/air quality sensors
- Dust/particulate matter sensors
- GPS/location sensors
- Accelerometers/gyroscopes
- Signal strength (RSSI)

If a sensor type cannot be determined, it will be classified as "unknown" but still registered and displayed.

## Troubleshooting

If devices are not appearing in the dashboard:

1. Check the n8n logs:
   ```bash
   docker-compose logs -f n8n
   ```

2. Verify ChirpStack is sending data to the correct webhook URL:
   ```bash
   docker-compose logs -f http-broker
   ```

3. Check Home Assistant logs:
   ```bash
   docker-compose logs -f homeassistant
   ```

4. Verify the device registry file exists:
   ```bash
   docker-compose exec n8n ls -la /tmp/device_registry.json
   ```

5. Check the raw device registry data:
   ```bash
   docker-compose exec n8n cat /tmp/device_registry.json
   ```

## Customization

You can customize the sensor detection logic by editing the n8n workflow:

1. Go to the "Analyze Incoming Data" node
2. Modify the `sensorPatterns` object to add or change sensor type detection patterns
3. Update the `determineUnit` function to add or change unit detection logic
4. Save the workflow

## License

This Auto-Discovery Agent is provided as part of the IoT Data Stack project.
