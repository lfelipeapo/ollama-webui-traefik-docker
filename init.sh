#!/bin/bash

# 1) Verifica se o Docker está instalado; se não, instala.
if ! command -v docker &> /dev/null; then
    echo "🔧 Instalando Docker e dependências..."
    bash install-docker.sh
else
    echo "✅ Docker já está instalado."
fi

# 2) Função para matar processos que estejam ocupando determinada porta usando lsof
kill_port_if_in_use() {
    local port=$1
    # Captura todos os PIDs usando a porta com lsof
    local pids
    pids=$(lsof -t -i :"$port" 2>/dev/null)
    
    if [[ -n "$pids" ]]; then
        echo "🔴 A porta $port está em uso pelos processos: $pids. Matando processos..."
        for pid in $pids; do
            kill -9 "$pid" && echo "✅ Processo $pid finalizado." || echo "⚠️ Falha ao finalizar o processo $pid."
        done
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
