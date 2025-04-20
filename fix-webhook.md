# Fix ChirpStack Webhook Integration

Follow these steps to fix the webhook integration between ChirpStack and n8n:

## 1. Create a New n8n Webhook

1. Access n8n at `http://your-server-ip:5678`
2. Log in with your credentials (admin/strongpassword123 by default)
3. Create a new workflow:
   - Click "Workflows" in the left sidebar
   - Click "Create new workflow"
   - Name it "ChirpStack Integration"

4. Add a Webhook node:
   - Click the "+" button to add a node
   - Search for "webhook" and select it
   - Configure the webhook:
     - Authentication: None
     - HTTP Method: POST
     - Path: `/chirpstack` (without the leading slash)
     - Response Mode: Last Node
     - Response Code: 200
     - Response Data: `success`

5. Add a Function node to process the data:
   - Click the "+" button to add a node after the webhook
   - Search for "function" and select it
   - Use this code:

```javascript
// Log the incoming data for debugging
console.log('Received webhook data:', $input.item.json);

// Return the data for further processing
return $input.item;
```

6. Add an InfluxDB node:
   - Click the "+" button to add a node after the function
   - Search for "influxdb" and select it
   - Configure the connection:
     - Operation: Write Points
     - URL: `http://influxdb:8086`
     - API Token: `my-super-secret-auth-token` (or your custom token)
     - Organization: `iot-org`
     - Bucket: `iot-data`
   - Configure the data:
     - Measurement: `sensor_data`
     - Tags: Add device_id, device_name, etc. based on your data structure
     - Fields: Add your sensor values (temperature, humidity, etc.)

7. Save and activate the workflow:
   - Click "Save" in the top-right corner
   - Toggle the "Active" switch to activate the workflow

## 2. Update the Nginx Configuration

The Nginx configuration needs to be updated to match the new webhook path. SSH into your server and run:

```bash
# Edit the Nginx configuration
nano /opt/iot-data-stack/nginx/conf.d/default.conf
```

Update the location block to:

```nginx
location /chirpstack-webhook {
    proxy_pass http://n8n:5678/webhook/chirpstack;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Save the file and restart Nginx:

```bash
docker-compose restart http-broker
```

## 3. Update ChirpStack Configuration

1. Go to your ChirpStack application
2. Navigate to Integrations
3. Edit your HTTP integration
4. Make sure the URL is exactly: `http://your-server-ip:8080/chirpstack-webhook`
5. Save the integration

## 4. Fix Home Assistant Template Errors

The Home Assistant errors occur because it's looking for data from a webhook entity that doesn't exist yet. Let's create a simpler configuration:

```bash
# Edit the Home Assistant configuration
nano /opt/iot-data-stack/config/homeassistant/configuration.yaml
```

Replace the template sensor section with:

```yaml
# Sensor templates for ChirpStack data - simplified version
template:
  - sensor:
      - name: "LoRa Temperature"
        unique_id: lora_temperature
        state: "{{ states('sensor.temperature') | float(0) }}"
        unit_of_measurement: "°C"
        device_class: temperature
        state_class: measurement
        
      - name: "LoRa Humidity"
        unique_id: lora_humidity
        state: "{{ states('sensor.humidity') | float(0) }}"
        unit_of_measurement: "%"
        device_class: humidity
        state_class: measurement
        
      - name: "LoRa Battery Level"
        unique_id: lora_battery
        state: "{{ states('sensor.battery_level') | float(0) }}"
        unit_of_measurement: "%"
        device_class: battery
        state_class: measurement
```

Save the file and restart Home Assistant:

```bash
docker-compose restart homeassistant
```

## 5. Find the ChirpStack Integration Guide

The integration guide was created in the current directory, not in `/opt`. You can find it with:

```bash
find ~/iot-data-stack -name "chirpstack-integration-guide.md"
```

Or you can view it directly:

```bash
cat ~/iot-data-stack/iot-data-stack/chirpstack-integration-guide.md
```
