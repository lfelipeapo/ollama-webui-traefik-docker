#!/bin/bash

# Derruba os containers
docker-compose down

# Aguarda um pequeno tempo para garantir que os processos terminem
sleep 2

# Mata todos os processos docker-proxy em execução
pids=$(pgrep -f docker-proxy)
if [ -n "$pids" ]; then
  echo "Finalizando docker-proxy..."
  kill -9 $pids
fi

echo "Docker e processos de proxy finalizados!"
