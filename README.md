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
3. A working ChirpStack server (configured at 192.168.0.244:8080)

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

# Hi there, I'm Dvir Chakim! 👋

## 🧠 Embedded Innovator | 🎛️ AI at the Edge | 🇮🇱 Based in Israel

Welcome to my GitHub! I'm an electrical engineering student and tech enthusiast passionate about pushing intelligence to the edge — literally. Here, you'll find my projects and experiments in embedded systems and AI.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/dvir-chakim/) [![GitHub followers](https://img.shields.io/github/followers/dvirchakim?style=flat&logo=github)](https://github.com/dvirchakim?tab=followers)

---

## 🛠️ What I Do

- ⚙️ **Embedded Systems**: Crafting solutions with Raspberry Pi, Jetson Nano, Orange Pi, Portenta X8, Nicla Voice, and more.
- 🤖 **AI/ML at the Edge**: Implementing local models for speech recognition, image classification, wake-word detection, and real-time decision-making.
- 📦 **Dockerized Pipelines**: Streamlining deployments with containerized STT, TTS, and LLM models on low-power boards.
- 🌐 **Self-Hosted IoT Networks**: Building robust systems with ChirpStack, MQTT, Node-RED, InfluxDB, Grafana, and custom dashboards.
- 🎤 **Voice Assistants**: Designing offline AI assistants that listen, think, and respond — completely cloud-free.

---

## ⚡ Tech Stack

- **Languages**: Python, C/C++, Bash  
- **Platforms**: Arduino, STM32, Edge Impulse, Ubuntu, Proxmox, Yocto  
- **Tools**: Docker, Git, VSCode, Klipper, Mainsail  
- **AI Accelerators**: DeepX M1, Hailo8, Axelera Metis, NVIDIA Jetson, Alif Ensemble

---

## 🔬 Current Projects

- 🤖 **Humanoid Robot**: Developing a local voice interface and environmental awareness for intuitive interaction.
- 🖨️ **AI-Powered 3D Printer Monitor**: Real-time failure detection to save time and materials.
- 📡 **RF Signal Classification**: Using SDR and neural networks for advanced signal analysis.
- 🌡️ **Environmental Sensor Suite**: Dust, gas, and motion detection with LoRa and Bluetooth sleep/wake logic.
- 📹 **Smart Camera Server**: Frigate-based surveillance system running on Jetson Nano.
- 🗣️ **Self-Hosted Voice Assistant**: Fully offline solution with Portenta X8, leveraging Dockerized STT → LLM → TTS pipeline.

---

## 📈 Data-Driven Innovation

I believe in rigorous testing and optimization. My approach includes:

- Precision, Recall, and F1-score evaluations for model performance.
- Advanced filter comparisons (Chebyshev, Butterworth, Wavelets, etc.).
- Real-time PSD & topograph visualizations for EEG data analysis.

---

## ❤️ Fun Facts

- 🌊 I live near the sea, so humidity is always a factor in my hardware designs.
- 💾 I built a custom NAS with Radxa SATA HATs, SSDs, and HDDs for ultimate data control.
- 🧠 I can break down neural networks using flip-flops and logic gates.
- 🖼️ My enclosures are SCAD-modeled and STL-ready, often with sleek sliding lids.
- 🛠️ I slice PETG at 24 mm³/s and treat TPU drying like a science experiment.

---

## 💬 Let's Connect!

I'm always open to collaboration, feedback, and tech discussions. I communicate in Hebrew, English, and a touch of French (with an accent for flair). Catch me optimizing inference speeds, debugging logs, or designing 3D parts on a Sunday night.

- 📧 Drop me a message or open an issue on any repo.
- 🤝 Let's build something amazing together!

---

### Thanks for visiting!  
**Explore my repositories, star anything that inspires you, and reach out if you'd like to collaborate.**  

> "If it runs offline, in real-time, and fits on a board — I'm all in."  
