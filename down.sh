#!/bin/bash

# Detecta a distribuição para instalar dependências se necessário
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Sistema não suportado."
    exit 1
fi

# Verifica se está rodando no Alpine Linux e instala dependências
if [[ "$OS" == "alpine" ]]; then
    echo "🔍 Detected Alpine Linux. Checking for required packages..."

    # Instala pacotes necessários
    apk add --no-cache lsof procps
fi

# Função para matar processos que estão usando uma determinada porta com lsof
kill_port_if_in_use() {
    local port=$1
    local pids
    pids=$(lsof -t -i :"$port" 2>/dev/null)
    if [[ -n "$pids" ]]; then
        echo "🔴 A porta $port está em uso pelos processos: $pids. Matando..."
        for pid in $pids; do
            kill -9 "$pid" && echo "✅ Processo $pid finalizado." || echo "⚠️ Falha ao matar o processo $pid."
        done
    else
        echo "✅ A porta $port está livre."
    fi
}

# Função para matar um container pegando seu PID com docker inspect
kill_container_by_pid() {
    local container=$1
    local pid
    pid=$(sudo docker inspect --format '{{.State.Pid}}' "$container")
    if [[ -n "$pid" && "$pid" != "0" ]]; then
        echo "Matando container '$container' (PID: $pid)..."
        kill -9 "$pid" && echo "✅ Processo do container '$container' (PID: $pid) finalizado." || echo "⚠️ Falha ao matar o processo do container '$container'."
    else
        echo "Nenhum PID válido encontrado para o container '$container'."
    fi
}

# Lista de portas a serem liberadas
ports=(80 81 443 444 8080 8181 11434 11435)

echo "Iniciando limpeza: matando processos que ocupam as portas..."
for port in "${ports[@]}"; do
    kill_port_if_in_use "$port"
done

# Finaliza processos docker-proxy (caso existam)
echo "Finalizando processos docker-proxy..."
pids=$(pgrep -f docker-proxy)
if [[ -n "$pids" ]]; then
    echo "Processos docker-proxy encontrados: $pids. Matando..."
    kill -9 $pids && echo "✅ Processos docker-proxy finalizados." || echo "⚠️ Falha ao finalizar docker-proxy."
else
    echo "Nenhum processo docker-proxy encontrado."
fi

# Derruba os containers via docker-compose (ou docker compose, dependendo da versão)
echo "Derrubando os containers via docker-compose..."
if command -v docker-compose &> /dev/null; then
    docker-compose down
else
    docker compose down
fi

# Aguarda um pouco para garantir que os containers tenham sido parados
sleep 2

# Lista os containers do projeto (baseado no label do docker-compose)
remaining_containers=$(docker ps -aq --filter "label=com.docker.compose.project")
if [[ -n "$remaining_containers" ]]; then
    echo "Forçando remoção dos containers remanescentes do projeto docker-compose..."
    for container in $remaining_containers; do
        echo "Verificando container '$container'..."
        kill_container_by_pid "$container"
        sleep 1
        echo "Removendo container '$container'..."
        docker container rm -f "$container" && echo "✅ Container '$container' removido." || echo "⚠️ Falha ao remover container '$container'."
    done
else
    echo "Nenhum container remanescente do docker-compose encontrado."
fi

echo "🚀 Limpeza completa! Containers e processos liberados!"
