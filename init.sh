#!/bin/bash

# 1) Verifica se o Docker está instalado; se não, instala.
if ! command -v docker &> /dev/null; then
    echo "🔧 Instalando Docker e dependências..."
    bash install-docker.sh
else
    echo "✅ Docker já está instalado."
fi

# 2) Função para matar processos que estejam ocupando determinada porta
kill_port_if_in_use() {
    local port=$1
    if lsof -i :$port -sTCP:LISTEN >/dev/null 2>&1; then
        echo "🔴 A porta $port está em uso. Matando processo..."
        fuser -k "$port/tcp" || echo "Não foi possível matar automaticamente."
    else
        echo "✅ A porta $port está livre."
    fi
}

# 3) Ajuste aqui para as portas que você usa no docker-compose
kill_port_if_in_use 81
kill_port_if_in_use 444
kill_port_if_in_use 8181
kill_port_if_in_use 11435

# 4) Inicia o Docker Compose
echo "🚀 Iniciando containers..."
docker-compose up -d
echo "✅ Containers iniciados."
