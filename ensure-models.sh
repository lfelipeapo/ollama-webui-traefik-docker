#!/bin/sh

set -e

# List of models to ensure are downloaded
MODELS="gemma3:4b llava:13b llama2-uncensored:7b llama3.2-vision:11b llava-llama3:8b codellama:13b starcoder2:15b starcoder2:15b-instruct deepseek-coder-v2:16b-lite-instruct-q5_K_S deepseek-r1:14b codegemma:7b phi4-mini phi4 qwen2.5:14b qwen2.5-coder:14b"

# Wait until Ollama is ready
echo "⏳ Aguardando o Ollama iniciar..."
until docker exec ollama ollama list >/dev/null 2>&1; do
    sleep 2
done

for MODEL in $MODELS; do
    if docker exec ollama ollama list | grep -q "^$MODEL"; then
        echo "✅ Modelo $MODEL já existe, pulando download."
    else
        echo "📥 Baixando modelo $MODEL..."
        docker exec ollama ollama pull "$MODEL"
    fi
done

echo "✅ Verificação de modelos concluída."
