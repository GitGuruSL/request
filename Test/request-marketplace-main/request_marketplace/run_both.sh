#!/bin/bash

# Script to run Flutter on both Android and Web simultaneously

echo "🚀 Starting Request Marketplace on Multiple Platforms..."

# Export Chrome executable for web
export CHROME_EXECUTABLE=/usr/bin/chromium

# Start Android emulator version
echo "📱 Starting Android version..."
flutter run -d emulator-5554 &
ANDROID_PID=$!

# Wait a moment for Android to start
sleep 5

# Start web version
echo "🌐 Starting Web version..."
flutter run -d chrome --web-port 8080 &
WEB_PID=$!

echo "✅ Both platforms started!"
echo "📱 Android PID: $ANDROID_PID"
echo "🌐 Web PID: $WEB_PID"
echo ""
echo "🔗 Access points:"
echo "📱 Android: Running on emulator"
echo "🌐 Web: http://localhost:8080"
echo "🏠 Landing Page: http://localhost:8080/pages/index.html"
echo "⚙️ Admin Dashboard: http://localhost:8080/admin/dashboard.html"
echo ""
echo "Press Ctrl+C to stop both instances"

# Wait for both processes
wait $ANDROID_PID $WEB_PID
