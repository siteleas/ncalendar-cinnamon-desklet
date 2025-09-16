#!/usr/bin/env python3
"""
NextCloud Authentication Helper
Provides authentication flow similar to NextCloud Talk Desktop
"""

import sys
import webbrowser
import urllib.parse
import http.server
import socketserver
import threading
import time
from urllib.parse import urlparse, parse_qs

class AuthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/auth/callback'):
            # Parse the callback URL for credentials
            parsed_url = urlparse(self.path)
            query_params = parse_qs(parsed_url.query)
            
            if 'server' in query_params and 'user' in query_params and 'password' in query_params:
                self.server.auth_result = {
                    'server': query_params['server'][0],
                    'user': query_params['user'][0], 
                    'password': query_params['password'][0]
                }
                
                # Send success response
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(b"""
                <html>
                <head><title>Authentication Success</title></head>
                <body>
                    <h1>Authentication Successful!</h1>
                    <p>You can now close this window and return to the desklet configuration.</p>
                    <script>setTimeout(() => window.close(), 3000);</script>
                </body>
                </html>
                """)
            else:
                # Send error response
                self.send_response(400)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(b"""
                <html>
                <head><title>Authentication Error</title></head>
                <body>
                    <h1>Authentication Failed</h1>
                    <p>Missing required parameters. Please try again.</p>
                </body>
                </html>
                """)
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress default logging
        return

def authenticate_with_nextcloud(server_url):
    """
    Start NextCloud authentication flow
    """
    print(f"Starting authentication flow for {server_url}")
    
    # Start local HTTP server for callback
    port = 8080
    server = socketserver.TCPServer(("", port), AuthHandler)
    server.auth_result = None
    
    # Start server in background thread
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    
    # Create callback URL
    callback_url = f"http://localhost:{port}/auth/callback"
    
    # Build NextCloud login flow URL
    login_url = f"{server_url}/index.php/login/flow"
    
    print(f"Opening browser to: {login_url}")
    print(f"Callback URL: {callback_url}")
    print("Please complete the authentication in your browser...")
    print("Note: This is a simplified flow. For full NextCloud Talk Desktop-style authentication,")
    print("you would need to register a custom URL scheme (nc://) with the system.")
    
    # Open browser
    webbrowser.open(login_url)
    
    # Wait for authentication result
    timeout = 300  # 5 minutes
    start_time = time.time()
    
    while server.auth_result is None and (time.time() - start_time) < timeout:
        time.sleep(1)
    
    server.shutdown()
    
    if server.auth_result:
        print("Authentication successful!")
        return server.auth_result
    else:
        print("Authentication timed out or failed.")
        return None

def main():
    if len(sys.argv) != 2:
        print("Usage: auth_helper.py <nextcloud_server_url>")
        sys.exit(1)
    
    server_url = sys.argv[1]
    if not server_url.startswith(('http://', 'https://')):
        server_url = 'https://' + server_url
    
    result = authenticate_with_nextcloud(server_url)
    
    if result:
        print(f"Server: {result['server']}")
        print(f"User: {result['user']}")
        print(f"Password: {result['password']}")
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
