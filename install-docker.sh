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

    # Verificar se estamos executando como root
    if [ "$(id -u)" -ne 0 ]; then
        echo "Este script deve ser executado como root no Alpine Linux."
        echo "Por favor, execute com: su -c './install-docker.sh'"
        exit 1
    fi

    # Habilitar o repositório community onde o Docker está localizado
    echo "Habilitando repositório community..."
    sed -i 's/#.*community/&/' /etc/apk/repositories
    sed -i 's/#http\(.*\)community/http\1community/' /etc/apk/repositories

    # Atualiza os repositórios
    echo "Atualizando repositórios..."
    apk update

    # Instala Docker e Docker Compose
    echo "Instalando Docker e Docker Compose..."
    apk add docker docker-compose openrc

    # Habilita e inicia o serviço do Docker
    echo "Configurando Docker para iniciar automaticamente..."
    rc-update add docker default
    
    echo "Iniciando serviço Docker..."
    /etc/init.d/docker start

    # Adiciona o usuário ao grupo docker (se não for root)
    if [ "$SUDO_USER" ]; then
        echo "Adicionando usuário $SUDO_USER ao grupo docker..."
        addgroup $SUDO_USER docker
    elif [ "$USER" != "root" ]; then
        echo "Adicionando usuário $USER ao grupo docker..."
        addgroup $USER docker
    else
        echo "Você está executando como root. Se desejar usar Docker sem root, adicione seu usuário ao grupo docker com:"
        echo "addgroup SEUNOME docker"
    fi

    echo "Docker e Docker Compose instalados com sucesso no Alpine Linux."

else
    echo "Sistema operacional não suportado para instalação automática."
    exit 1
fi

# Exibir versões
echo "Verificando versões instaladas:"
docker --version || echo "Docker não está disponível no PATH atual"
docker-compose --version || echo "Docker Compose não está disponível no PATH atual"

echo "Nota: Pode ser necessário reiniciar sua sessão para usar o Docker sem root."
