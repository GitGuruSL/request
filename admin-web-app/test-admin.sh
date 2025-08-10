#!/bin/bash

echo "🧪 Testing Admin Panel Components..."
echo "======================================="

# Test 1: Check if all required files exist
echo "📂 Checking required files..."
required_files=(
    "index.html"
    "simple-admin.html" 
    "debug.html"
    "start_server.py"
    "start-admin.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""

# Test 2: Check Firebase configuration
echo "🔥 Checking Firebase configuration..."
if grep -q "355474518888" index.html; then
    echo "✅ Firebase config updated in index.html"
else
    echo "❌ Firebase config needs update in index.html"
fi

if grep -q "355474518888" simple-admin.html; then
    echo "✅ Firebase config updated in simple-admin.html"
else
    echo "❌ Firebase config needs update in simple-admin.html"
fi

echo ""

# Test 3: Check if port is available
echo "🌐 Checking port availability..."
if ! lsof -i :8081 >/dev/null 2>&1; then
    echo "✅ Port 8081 is available"
else
    echo "⚠️ Port 8081 is in use"
    echo "   Current usage:"
    lsof -i :8081
fi

echo ""

# Test 4: Test server startup
echo "🚀 Testing server startup..."
if python3 -c "import socket; s=socket.socket(); s.bind(('',8081)); s.close()" 2>/dev/null; then
    echo "✅ Server can bind to port 8081"
else
    echo "❌ Cannot bind to port 8081"
fi

echo ""

# Test 5: Check Python modules
echo "🐍 Checking Python requirements..."
python3 -c "import http.server, socketserver, webbrowser, pathlib" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ All required Python modules available"
else
    echo "❌ Missing Python modules"
fi

echo ""

# Test 6: HTML validation check
echo "📄 Basic HTML validation..."
if grep -q "<!DOCTYPE html>" index.html && grep -q "</html>" index.html; then
    echo "✅ index.html structure looks good"
else
    echo "❌ index.html structure issues"
fi

if grep -q "<!DOCTYPE html>" simple-admin.html && grep -q "</html>" simple-admin.html; then
    echo "✅ simple-admin.html structure looks good"
else
    echo "❌ simple-admin.html structure issues"
fi

echo ""
echo "🏁 Test completed!"
echo ""
echo "📋 To start the admin panel:"
echo "   ./start-admin.sh"
echo ""
echo "🌐 Or manually:"
echo "   python3 start_server.py"
echo ""
echo "🔗 Access URLs (once server is running):"
echo "   Login: http://localhost:8081/index.html"
echo "   Admin: http://localhost:8081/simple-admin.html"
echo "   Debug: http://localhost:8081/debug.html"
