#!/data/data/com.termux/files/usr/bin/bash
# Launch All Planetary Agents

echo "🪐 Launching Planetary Agent System..."

# Check for Python
if ! command -v python3 &>/dev/null; then
    echo "Installing Python..."
    pkg install python -y
fi

# Check for Node.js  
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    pkg install nodejs -y
fi

# Launch agents (example - customize based on your actual agents)
AGENT_DIRS=(
    ~/earth-agent
    ~/mars-agent
    ~/jupiter-agent
    ~/saturn-agent
    ~/neptune-agent
)

for dir in "${AGENT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  🌍 Starting $(basename $dir)..."
        cd "$dir"
        
        # Start Python agents
        if [ -f "agent.py" ]; then
            nohup python3 agent.py > ~/logs/$(basename $dir).log 2>&1 &
        fi
        
        # Start Node agents
        if [ -f "index.js" ]; then
            nohup node index.js > ~/logs/$(basename $dir).log 2>&1 &
        fi
    fi
done

echo "✅ All agents launched. Check logs with: orchestrate logs"
