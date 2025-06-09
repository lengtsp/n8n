#!/bin/bash

# Configuration
MAX_IDLE_TIME=${MAX_IDLE_TIME:-3600}  # Default 1 hour in seconds
OLLAMA_PID=$(pgrep ollama)
MAX_CONCURRENT=${MAX_CONCURRENT_REQUESTS:-10}

# Check if Ollama process exists
if [ -z "$OLLAMA_PID" ]; then
    echo "Ollama process not found"
    exit 1
fi

# Get last activity time
LAST_ACTIVITY=$(ps -p $OLLAMA_PID -o etimes=)

# Check concurrent requests
CURRENT_CONNECTIONS=$(netstat -an | grep :11434 | grep ESTABLISHED | wc -l)

# If too many concurrent connections, exit with error
if [ $CURRENT_CONNECTIONS -gt $MAX_CONCURRENT ]; then
    echo "Too many concurrent connections: $CURRENT_CONNECTIONS"
    exit 1
fi

# If process has been idle for too long, kill it
if [ $LAST_ACTIVITY -gt $MAX_IDLE_TIME ]; then
    echo "Process idle for too long, killing PID: $OLLAMA_PID"
    kill $OLLAMA_PID
    exit 1
fi

# Basic health check using curl
curl -f http://localhost:11434/api/health >/dev/null 2>&1
CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Health check failed"
    exit 1
fi

echo "Health check passed"
exit 0