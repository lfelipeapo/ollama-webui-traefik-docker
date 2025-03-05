#!/bin/bash

# 🚀 Verifica se o script de instalação já foi executado
if ! command -v docker &> /dev/null; then
    echo "🔧 Instalando Docker e dependências..."
    bash install-docker.sh
else
    echo "✅ Docker já está instalado."
fi

# 📌 Criar diretórios necessários para LetsEncrypt e Certbot
setup_directories() {
    echo "📂 Criando diretórios essenciais..."
    mkdir -p ./letsencrypt ./certbot-data ./nginx
    chmod -R 755 ./letsencrypt ./certbot-data
    echo "✅ Diretórios configurados."
}

# 📌 Criar arquivos de configuração do Nginx se não existirem
setup_nginx_config() {
    echo "🔧 Verificando arquivos de configuração do Nginx..."

    if [ ! -f "./nginx/nginx-http.conf" ]; then
        cat <<EOL > ./nginx/nginx-http.conf
server {
    listen 81;
    server_name \${DOMAIN};
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { return 200 "Servidor em configuração inicial"; }
}
EOL
        echo "✅ nginx-http.conf criado."
    fi

    if [ ! -f "./nginx/nginx.conf" ]; then
        cat <<EOL > ./nginx/nginx.conf
server {
    listen 81;
    server_name \${DOMAIN};
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { return 301 https://\$host\$request_uri; }
}
server {
    listen 444 ssl;
    server_name \${DOMAIN};
    ssl_certificate /etc/letsencrypt/live/\${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/\${DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    location /ollama/ { proxy_pass http://ollama:11435/; }
    location / { proxy_pass http://open-webui:8181/; }
}
EOL
        echo "✅ nginx.conf criado."
    fi
}

# 📌 Parar e remover processos `docker-proxy` remanescentes
cleanup_docker_proxy() {
    echo "🛑 Removendo processos antigos do docker-proxy..."
    pids=$(pgrep -f docker-proxy)
    if [ -n "$pids" ]; then
        kill -9 $pids
        echo "✅ Processos docker-proxy finalizados."
    else
        echo "✅ Nenhum processo docker-proxy encontrado."
    fi
}

# 📌 Iniciar Docker Compose
start_docker_compose() {
    echo "🚀 Iniciando containers..."
    docker-compose up -d
    echo "✅ Docker Compose iniciado."
}

# 🚀 Executando os passos
setup_directories
setup_nginx_config
cleanup_docker_proxy
start_docker_compose
