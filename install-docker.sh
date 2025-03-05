#!/bin/bash

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Sistema não suportado."
    exit 1
fi

# Instalação no Ubuntu/Debian
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    echo "Detectado: Ubuntu/Debian"

    # Atualiza a lista de pacotes
    sudo apt update

    # Instala pacotes necessários
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Adiciona a chave GPG oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Adiciona o repositório oficial do Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualiza os pacotes e instala o Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    # Habilita e inicia o serviço do Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    # Adiciona o usuário ao grupo docker
    sudo usermod -aG docker $USER

    # Instala Docker Compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    # Dá permissão de execução ao Docker Compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo "Docker e Docker Compose instalados com sucesso no Ubuntu/Debian."

# Instalação no Alpine Linux
elif [[ "$OS" == "alpine" ]]; then
    echo "Detectado: Alpine Linux"

    # Atualiza os repositórios
    sudo apk update

    # Instala pacotes necessários
    sudo apk add docker docker-cli docker-compose openrc

    # Habilita e inicia o serviço do Docker
    sudo rc-update add docker boot
    sudo service docker start

    # Adiciona o usuário ao grupo docker (para evitar uso de sudo)
    addgroup $USER docker

    echo "Docker e Docker Compose instalados com sucesso no Alpine Linux."

else
    echo "Sistema operacional não suportado para instalação automática."
    exit 1
fi

# Exibir versões
docker --version
docker-compose --version
