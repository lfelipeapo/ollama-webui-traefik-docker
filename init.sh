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
    local pid

    # Tenta encontrar o processo usando netstat ou ss
    if command -v netstat &> /dev/null; then
        pid=$(netstat -tulnp 2>/dev/null | grep ":$port" | awk '{print $7}' | cut -d'/' -f1)
    elif command -v ss &> /dev/null; then
        pid=$(ss -tulnp 2>/dev/null | grep ":$port" | awk '{print $7}' | cut -d',' -f2 | cut -d'=' -f2)
    fi

    if [[ -n "$pid" ]]; then
        echo "🔴 A porta $port está em uso pelo processo PID $pid. Matando processo..."
        kill -9 "$pid" && echo "✅ Processo $pid finalizado." || echo "⚠️ Falha ao finalizar o processo $pid."
    else
        echo "✅ A porta $port está livre."
    fi
}

# 3) Ajuste aqui para as portas que você usa no docker-compose
kill_port_if_in_use 80
kill_port_if_in_use 81
kill_port_if_in_use 443
kill_port_if_in_use 444
kill_port_if_in_use 8080
kill_port_if_in_use 8181
kill_port_if_in_use 11434
kill_port_if_in_use 11435

# 4) Inicia o Docker Compose
echo "🚀 Iniciando containers..."
docker-compose up -d
echo "✅ Containers iniciados."
