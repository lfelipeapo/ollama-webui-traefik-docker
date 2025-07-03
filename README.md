# Ollama & Open WebUi with Nginx

This repository provides a simple setup for running [Ollama](https://ollama.com/) and [Open WebUI](https://github.com/open-webui/open-webui) with Nginx as a reverse proxy using **Docker Compose**. This setup automatically downloads the required models, so everything is set up with a single command.

## 💡 Recommended Hosting
This example is meant to run on a small **VPS (Virtual Private Server)** showing that you can run lightweight models on dual core + 8GB RAM systems.

I highly recommend using **Hostinger**, which offers excellent and affordable plans. Check them out with this link: [Hostinger Plans](https://ewbr.cc/hostinger-ew-1001)

## ⭐ Support This Project
If you find this project useful, please consider giving it a **star** on GitHub! ⭐ Your support helps keep this project maintained and encourages further development.

## 🚀 Quick Start

### Prerequisites
Ensure you have the following installed:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Installation
1. Clone this repository:
   ```sh
   git clone https://github.com/erickwendel/ollama-webui-traefik-docker.git
   cd ollama-webui-traefik-docker
   ```

2. Copy `.env.example` to `.env` and adjust the values for your environment. The Nginx template will read these variables when the containers start:
   ```sh
   cp .env.example .env
   DOMAIN=srv665452.hstgr.cloud  # Change this to your actual domain
   WEBUI_ADMIN_EMAIL=admin@example.com
   WEBUI_ADMIN_PASSWORD=changeme
   WEBUI_SECRET_KEY=your-secret-key
   ```

3. Run the installation script (to install Docker if not already installed):
   ```sh
   ./init.sh
   ```

4. To stop services:
   ```sh
   ./down.sh
   ```

## 📜 Services Included

### 1. **Nginx**
- Routes traffic to **Ollama** and **Open WebUI**.
 - Configuration is generated from `nginx/templates/default.conf.template` using the `DOMAIN` value from the environment file.

### 2. **Ollama (LLM Inference Engine)**
- Hosts AI models.
- Auto-downloads predefined models (`gemma:2b`, `deepseek-r1:1.5b`, `qwen2.5-coder:1.5b`, `codegemma:2b`).
- Accessible via `https://your-domain/ollama`.

### 3. **Ollama Model Loader**
- A helper service that ensures models are downloaded inside the Ollama container before usage.

### 4. **Open WebUI (Frontend for Ollama)**
- Provides a web-based interface for interacting with AI models.
- Accessible via `https://your-domain/`.

### 5. **Watchtower (Automatic Updates)**
- Monitors the `open-webui` container and pulls new images when available.
- Keeps the WebUI updated without impacting the Ollama service.

## 🛠 Scripts

### `request-ollama.sh`
This Bash script allows users to get available model tags and send prompts to Ollama.
Usage:
```sh
./request-ollama.sh "Your prompt here"
```

### `upload.sh`
Uploads all files in the directory to the VPS via SCP

## ⚠️ **Production Warning**
This repository is intended for **example purposes only** and is not recommended for production use.
For production deployments, consider using **Kubernetes**, **Docker Swarm**, or other orchestration tools to ensure high availability and security.

## 📜 Configuration
Modify the `.env` file (copied from `.env.example`) to set your domain and WebUI credentials. These values will be injected into the Nginx configuration and Open WebUI at startup:
```sh
DOMAIN=ollama...
WEBUI_ADMIN_EMAIL=admin@example.com
WEBUI_ADMIN_PASSWORD=changeme
WEBUI_SECRET_KEY=your-secret-key
```

## 📎 Additional Notes
 - This setup automatically downloads AI models inside the Ollama container and stores them in `ollama-data` so they are reused between runs.
 - Open WebUI data is stored in `webui-data` to preserve chats and settings across updates.
- Make sure to configure your DNS settings to point your domain to your server's IP.
- A `.gitignore` file keeps data directories and log files out of version control.

## 📝 License
This project is licensed under the MIT License.

