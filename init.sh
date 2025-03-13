#!/bin/bash

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Sistema não suportado."
    exit 1
fi

# Verifica se o Docker está instalado e se o serviço está ativo
if command -v docker >/dev/null 2>&1; then
    if [[ "$OS" == "alpine" ]]; then
        # Para Alpine, usa OpenRC ao invés de systemctl
        if rc-service docker status >/dev/null 2>&1; then
            echo "✅ Docker já está instalado e o serviço está ativo."
        else
            echo "⚠️ Docker instalado, mas o serviço não está ativo. Tentando iniciar..."
            rc-service docker start
            if rc-service docker status >/dev/null 2>&1; then
                echo "✅ Docker iniciado com sucesso."
            else
                echo "❌ Falha ao iniciar o serviço do Docker. Verifique a instalação."
                exit 1
            fi
        fi
    else
        # Para Ubuntu/Debian usa systemctl
        if sudo systemctl is-active docker >/dev/null 2>&1; then
            echo "✅ Docker já está instalado e o serviço está ativo."
        else
            echo "⚠️ Docker instalado, mas o serviço não está ativo. Tentando iniciar..."
            sudo systemctl start docker
            if sudo systemctl is-active docker >/dev/null 2>&1; then
                echo "✅ Docker iniciado com sucesso."
            else
                echo "❌ Falha ao iniciar o serviço do Docker. Verifique a instalação."
                exit 1
            fi
        fi
    fi
else
    echo "🔧 Docker não encontrado. Instalando Docker e dependências..."
    bash install-docker.sh
fi

# Função para matar processos que estão usando determinada porta com lsof
kill_port_if_in_use() {
    local port=$1
    local pids

    if command -v lsof >/dev/null 2>&1; then
        pids=$(lsof -t -i :"$port" 2>/dev/null)
    else
        echo "⚠️ lsof não encontrado. Tentando usar netstat..."
        pids=$(netstat -tulnp 2>/dev/null | grep ":$port" | awk '{print $7}' | cut -d'/' -f1)
    fi

    if [[ -n "$pids" ]]; then
        echo "🔴 A porta $port está em uso pelos processos: $pids. Matando processos..."
        for pid in $pids; do
            kill -9 "$pid" && echo "✅ Processo $pid finalizado." || echo "⚠️ Falha ao finalizar o processo $pid."
        done
    else
        echo "✅ A porta $port está livre."
    fi
}

# Função para forçar a remoção de containers remanescentes do projeto docker-compose
force_remove_stuck_containers() {
    local containers
    containers=$(docker ps -aq --filter "label=com.docker.compose.project")
    if [[ -n "$containers" ]]; then
        echo "Forçando remoção dos containers remanescentes do projeto docker-compose..."
        for container in $containers; do
            echo "Verificando container $container..."
            pid=$(docker inspect --format '{{.State.Pid}}' "$container")
            if [[ -n "$pid" && "$pid" != "0" ]]; then
                echo "Matando processo do container $container (PID: $pid)..."
                kill -9 "$pid"
                sleep 1
            fi
            echo "Removendo container $container..."
            docker container rm -f "$container" && echo "✅ Container $container removido." || echo "⚠️ Falha ao remover container $container."
        done
    else
        echo "Nenhum container remanescente do docker-compose encontrado."
    fi
}

# Mata processos que estão usando as portas configuradas
ports=(80 81 443 444 8080 8181 11434 11435)
echo "Iniciando limpeza: matando processos que ocupam as portas..."
for port in "${ports[@]}"; do
    kill_port_if_in_use "$port"
done

# Força a remoção de containers remanescentes, se houver
force_remove_stuck_containers

# Inicia os containers via docker-compose
echo "🚀 Iniciando containers..."
docker-compose up -d
echo "✅ Containers iniciados."
