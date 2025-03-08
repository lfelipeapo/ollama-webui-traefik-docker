#!/bin/bash

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
    # Obtém o PID do container (exemplo: open-webui)
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

# Derruba os containers via docker-compose
echo "Derrubando os containers via docker-compose..."
docker-compose down

# Aguarda um pouco para garantir que o docker-compose tenha derrubado os containers
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

echo "Limpeza completa! Containers e processos liberados!"
