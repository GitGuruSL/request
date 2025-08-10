#!/usr/bin/env python3
"""
Simple HTTP server for the admin panel
Run this to serve the admin panel locally
"""

import http.server
import socketserver
import os
import webbrowser
from pathlib import Path
import socket

PORT = 8080
DIRECTORY = Path(__file__).parent

def find_free_port(start_port=8080, max_attempts=50):
    """Find a free port starting from start_port"""
    for port in range(start_port, start_port + max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('', port))
                return port
        except OSError:
            continue
    raise RuntimeError(f"Could not find a free port after {max_attempts} attempts")

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Add headers to allow ES modules and CORS
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

def main():
    os.chdir(DIRECTORY)
    
    # Find an available port
    try:
        port = find_free_port(PORT)
    except RuntimeError as e:
        print(f"❌ Error: {e}")
        return
    
    # Save the process ID
    pid_file = DIRECTORY / '.server_pid'
    with open(pid_file, 'w') as f:
        f.write(str(os.getpid()))
    
    try:
        with socketserver.TCPServer(("", port), CustomHTTPRequestHandler) as httpd:
            print(f"🌐 Serving admin panel at http://localhost:{port}")
            print(f"📁 Directory: {DIRECTORY}")
            print(f"🔗 Login: http://localhost:{port}/index.html")
            print(f"🔗 Admin: http://localhost:{port}/simple-admin.html")
            print(f"🔧 Debug: http://localhost:{port}/debug.html")
            print("Press Ctrl+C to stop the server")
            
            try:
                # Open browser automatically
                webbrowser.open(f"http://localhost:{port}/index.html")
            except Exception as e:
                print(f"⚠️ Could not open browser automatically: {e}")
                
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print("\n🛑 Server stopped")
    finally:
        # Clean up PID file
        if pid_file.exists():
            pid_file.unlink()

if __name__ == "__main__":
    main()
