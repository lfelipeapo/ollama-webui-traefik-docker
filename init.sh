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
