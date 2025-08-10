#!/bin/bash

# Kill any existing Python servers
echo "🧹 Cleaning up existing servers..."
pkill -f "start_server.py"
pkill -f "python3 -m http.server"

# Wait a moment for processes to stop
sleep 2

# Start the improved server
echo "🚀 Starting admin panel server..."
cd /home/cyberexpert/Dev/request-marketplace/admin-web-app

# Use our improved Python server
if python3 start_server.py &
then
    SERVER_PID=$!
    echo $SERVER_PID > .server_pid
    echo "✅ Admin panel server started with PID: $SERVER_PID"
    echo "📋 Server will automatically find an available port"
    echo "🌐 Browser should open automatically"
    echo "⚡ Server is running in background..."
    echo ""
    echo "📚 Available endpoints:"
    echo "   Login: /index.html"
    echo "   Admin: /simple-admin.html" 
    echo "   Debug: /debug.html"
    echo ""
    echo "To stop the server: kill $SERVER_PID"
else
    echo "❌ Failed to start server. Trying fallback method..."
    if python3 -m http.server 8081 &
    then
        SERVER_PID=$!
        echo $SERVER_PID > .server_pid
        echo "✅ Fallback server started on http://localhost:8081"
        echo "🌐 Open http://localhost:8081 in your browser"
    else
        echo "❌ All server start attempts failed!"
        exit 1
    fi
fi

echo ""
echo "🔥 To access Firebase console: https://console.firebase.google.com/project/request-marketplace"
echo "📊 Admin panel should be accessible shortly..."
elif python3 -m http.server 8081 2>/dev/null &
then
    SERVER_PID=$!
    echo "✅ Admin panel server started on http://localhost:8081"
    echo "📋 Process ID: $SERVER_PID"
    echo "🌐 Open http://localhost:8081 in your browser"
    echo "⚡ Server is running in background..."
else
    echo "❌ Failed to start server on both ports 8080 and 8081"
    exit 1
fi

# Store the PID for later use
echo $SERVER_PID > .server_pid

echo ""
echo "🛑 To stop the server later, run: kill $SERVER_PID"
echo "📊 To check server status: ps aux | grep 'python3 -m http.server'"
