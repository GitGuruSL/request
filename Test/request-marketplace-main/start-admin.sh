#!/bin/bash

# Request Marketplace - Admin Panel Server
echo "🚀 Starting Admin Panel Server..."
echo "📍 URL: http://localhost:8080"
echo "📝 Make sure to add 'localhost:8080' to Firebase authorized domains"
echo "🔗 Firebase Console: https://console.firebase.google.com/"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=================================="

cd admin-web-app
python3 -m http.server 8080
