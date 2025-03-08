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

# Lista de portas a serem liberadas
ports=(80 81 443 444 8080 8181 11434 11435)

echo "Iniciando limpeza: matando processos que ocupam as portas..."
for port in "${ports[@]}"; do
    kill_port_if_in_use "$port"
done

# Mata processos docker-proxy, se existirem
echo "Finalizando processos docker-proxy..."
pids=$(pgrep -f docker-proxy)
if [[ -n "$pids" ]]; then
    echo "Processos docker-proxy encontrados: $pids. Matando..."
    kill -9 $pids && echo "✅ Processos docker-proxy finalizados." || echo "⚠️ Falha ao finalizar docker-proxy."
else
    echo "Nenhum processo docker-proxy encontrado."
fi

# Agora, derruba os containers
echo "Derrubando os containers via docker-compose..."
docker-compose down

echo "Limpeza completa! Containers e processos liberados!"
