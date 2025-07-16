#!/usr/bin/env python3
"""
TCP Receiver for Yamaha RCP Protocol
Compatible with Yamaha TF, CL, QL, Rivage, DM3 series mixing consoles
"""

import socket
import json
import threading
from datetime import datetime
import argparse
import sys

class YamahaTCPReceiver:
    def __init__(self, host='0.0.0.0', port=49280):
        self.host = host
        self.port = port
        self.server_socket = None
        self.is_running = False
        self.clients = []
        
    def start_server(self):
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(5)
            self.is_running = True
            
            print(f"🎛️  Yamaha RCP TCP Receiver listening on {self.host}:{self.port}")
            print("📱 Ready for iOS Voice Control app connections")
            print("🎵 Compatible with Yamaha TF, CL, QL, Rivage, DM3 series")
            print("🔄 Waiting for connections...\n")
            
            while self.is_running:
                try:
                    client_socket, addr = self.server_socket.accept()
                    print(f"📱 New connection from {addr[0]}:{addr[1]}")
                    
                    # Handle client in separate thread
                    client_thread = threading.Thread(
                        target=self.handle_client, 
                        args=(client_socket, addr)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except Exception as e:
                    if self.is_running:
                        print(f"❌ Error accepting connection: {e}")
                        
        except OSError as e:
            if e.errno == 48:  # Address already in use
                print(f"❌ Port {self.port} is already in use.")
                print(f"💡 Try: sudo lsof -i :{self.port} to find what's using it")
                sys.exit(1)
            else:
                print(f"❌ Failed to start server: {e}")
                sys.exit(1)
    
    def handle_client(self, client_socket, addr):
        """Handle individual client connection"""
        self.clients.append(client_socket)
        buffer = ""
        
        try:
            while self.is_running:
                data = client_socket.recv(1024)
                if not data:
                    break
                    
                # Decode and add to buffer
                buffer += data.decode('utf-8')
                
                # Process complete messages (newline-delimited for RCP)
                while '\n' in buffer:
                    message, buffer = buffer.split('\n', 1)
                    if message.strip():
                        self.process_message(message.strip(), addr, client_socket)
                        
        except Exception as e:
            print(f"❌ Error handling client {addr[0]}: {e}")
        finally:
            if client_socket in self.clients:
                self.clients.remove(client_socket)
            client_socket.close()
            print(f"🔌 Disconnected: {addr[0]}:{addr[1]}")
    
    def process_message(self, message, addr, client_socket):
        """Process incoming message and convert to RCP if needed"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        
        try:
            # Try to parse as JSON first (from iOS app)
            data = json.loads(message)
            self.handle_ios_message(data, addr, client_socket)
        except json.JSONDecodeError:
            # Handle as plain RCP command
            self.handle_rcp_command(message, addr, client_socket)
    
    def handle_ios_message(self, data, addr, client_socket):
        """Handle structured message from iOS Voice Control app"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        content = data.get('content', '')
        
        print(f"📱 [{timestamp}] iOS Voice Message from {addr[0]}")
        print(f"   🗣️  Speech: \"{content}\"")
        
        # Convert voice command to RCP
        rcp_command = self.voice_to_rcp(content)
        if rcp_command:
            print(f"   🎛️  RCP Command: {rcp_command}")
            
            # Send RCP command to any connected Yamaha consoles
            self.forward_to_yamaha(rcp_command)
            
            # Send acknowledgment back to iOS
            response = json.dumps({
                "status": "converted_to_rcp",
                "rcp_command": rcp_command,
                "timestamp": datetime.now().isoformat()
            })
            client_socket.send((response + '\n').encode('utf-8'))
        else:
            print(f"   ❓ Could not convert to RCP command")
        
        print("")
    
    def handle_rcp_command(self, command, addr, client_socket):
        """Handle direct RCP command"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        print(f"🎛️  [{timestamp}] Direct RCP from {addr[0]}: {command}")
        
        # Forward to any connected Yamaha consoles
        self.forward_to_yamaha(command)
        print("")
    
    def voice_to_rcp(self, voice_text):
        """Convert natural language to Yamaha RCP commands"""
        voice_lower = voice_text.lower()
        
        # Channel fader controls
        if 'channel' in voice_lower and any(level in voice_lower for level in ['unity', 'zero', '0']):
            # Extract channel number
            for word in voice_text.split():
                if word.isdigit():
                    ch = int(word)
                    if 1 <= ch <= 32:  # Typical channel range
                        return f"set MIXER:Current/InCh/Fader/Level {ch-1} 0 0"
        
        elif 'mute' in voice_lower and 'channel' in voice_lower:
            for word in voice_text.split():
                if word.isdigit():
                    ch = int(word)
                    if 1 <= ch <= 32:
                        return f"set MIXER:Current/InCh/Fader/On {ch-1} 0 0"
        
        elif 'unmute' in voice_lower and 'channel' in voice_lower:
            for word in voice_text.split():
                if word.isdigit():
                    ch = int(word)
                    if 1 <= ch <= 32:
                        return f"set MIXER:Current/InCh/Fader/On {ch-1} 0 1"
        
        elif 'gain' in voice_lower and 'channel' in voice_lower:
            # Basic gain control - would need more sophisticated parsing
            for word in voice_text.split():
                if word.isdigit():
                    ch = int(word)
                    if 1 <= ch <= 32:
                        return f"set MIXER:Current/InCh/Gain {ch-1} 0 0"
        
        return None
    
    def forward_to_yamaha(self, rcp_command):
        """Forward RCP command to actual Yamaha console (future implementation)"""
        # Future: Connect to actual Yamaha console on port 49280
        # For now, just log what would be sent
        print(f"   📤 Would send to Yamaha: {rcp_command}")
    
    def stop_server(self):
        """Gracefully stop the server"""
        self.is_running = False
        for client in self.clients:
            client.close()
        if self.server_socket:
            self.server_socket.close()

def main():
    parser = argparse.ArgumentParser(description='Yamaha RCP TCP Receiver for iOS Voice Control')
    parser.add_argument('--port', type=int, default=49280, help='Port to listen on (default: 49280 - Yamaha RCP)')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--dev-port', type=int, default=8080, help='Development port for iOS testing (default: 8080)')
    args = parser.parse_args()
    
    if args.port == 49280:
        print("🎛️  Starting in YAMAHA RCP MODE (port 49280)")
    else:
        print(f"🔧 Starting in DEVELOPMENT MODE (port {args.port})")
    
    receiver = YamahaTCPReceiver(args.host, args.port)
    
    try:
        receiver.start_server()
    except KeyboardInterrupt:
        print("\n🛑 Shutting down receiver...")
        receiver.stop_server()
        print("✅ Receiver stopped.")

if __name__ == "__main__":
    main()