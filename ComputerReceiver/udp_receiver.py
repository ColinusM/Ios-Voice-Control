#!/usr/bin/env python3
"""
WiFi Text Receiver for iOS Voice Control App
Receives text transmissions over UDP and displays them
"""

import socket
import json
import threading
from datetime import datetime
import argparse
import sys

class WiFiTextReceiver:
    def __init__(self, host='0.0.0.0', port=8080):
        self.host = host
        self.port = port
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.is_running = False
        
    def start_server(self):
        try:
            self.socket.bind((self.host, self.port))
            self.is_running = True
            print(f"🎙️  WiFi Text Receiver listening on {self.host}:{self.port}")
            print("📱 Ready to receive messages from iOS Voice Control app")
            print("🔄 Waiting for connections...\n")
            
            while self.is_running:
                try:
                    data, addr = self.socket.recvfrom(4096)
                    self.handle_message(data, addr)
                except Exception as e:
                    if self.is_running:
                        print(f"❌ Error receiving message: {e}")
                        
        except OSError as e:
            if e.errno == 48:  # Address already in use
                print(f"❌ Port {self.port} is already in use. Try a different port with --port")
                sys.exit(1)
            else:
                print(f"❌ Failed to start server: {e}")
                sys.exit(1)
                
    def handle_message(self, data, addr):
        try:
            # Parse JSON message from iOS
            message_str = data.decode('utf-8').strip()
            
            # Handle both JSON and plain text messages
            try:
                message = json.loads(message_str)
                self.handle_json_message(message, addr)
            except json.JSONDecodeError:
                self.handle_plain_message(message_str, addr)
                
        except Exception as e:
            print(f"❌ Error handling message: {e}")
    
    def handle_json_message(self, message, addr):
        """Handle structured JSON message from iOS app"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        content = message.get('content', 'N/A')
        msg_type = message.get('messageType', 'unknown')
        
        print(f"📨 [{timestamp}] Message from {addr[0]}")
        print(f"   Content: {content}")
        print(f"   Type: {msg_type}")
        print(f"   ID: {message.get('id', 'N/A')}")
        
        # Check if this might be an RCP command
        if self.is_potential_rcp_command(content):
            print(f"   🎵 Potential RCP command detected!")
            rcp_command = self.convert_to_rcp(content)
            if rcp_command:
                print(f"   RCP: {rcp_command}")
        
        print("")  # Empty line for readability
        
        # Send acknowledgment back to iOS
        self.send_acknowledgment(message, addr)
    
    def handle_plain_message(self, message_str, addr):
        """Handle plain text message"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        print(f"📝 [{timestamp}] Plain text from {addr[0]}: {message_str}")
        print("")
    
    def send_acknowledgment(self, original_message, addr):
        """Send acknowledgment back to iOS app"""
        try:
            response = json.dumps({
                "status": "received",
                "timestamp": datetime.now().isoformat(),
                "messageId": original_message.get('id'),
                "receiver": "computer"
            })
            self.socket.sendto(response.encode('utf-8'), addr)
        except Exception as e:
            print(f"⚠️  Failed to send acknowledgment: {e}")
    
    def is_potential_rcp_command(self, content):
        """Detect if message content might be a mixing console command"""
        rcp_keywords = [
            'channel', 'fader', 'level', 'mute', 'unmute', 'gain', 
            'mix', 'send', 'pan', 'dca', 'scene', 'recall', 'unity'
        ]
        content_lower = content.lower()
        return any(keyword in content_lower for keyword in rcp_keywords)
    
    def convert_to_rcp(self, content):
        """Basic conversion of natural language to RCP commands"""
        # Future: Implement natural language to RCP command conversion
        # For now, return a placeholder that shows potential
        content_lower = content.lower()
        
        if 'channel' in content_lower and 'unity' in content_lower:
            return "set MIXER:Current/InCh/Fader/Level [CH] 0 0"
        elif 'mute' in content_lower and 'channel' in content_lower:
            return "set MIXER:Current/InCh/Fader/On [CH] 0 0"
        else:
            return f"# Future RCP: {content}"
    
    def stop_server(self):
        """Gracefully stop the server"""
        self.is_running = False
        self.socket.close()

def main():
    parser = argparse.ArgumentParser(description='WiFi Text Receiver for iOS Voice Control')
    parser.add_argument('--port', type=int, default=8080, help='Port to listen on (default: 8080)')
    parser.add_argument('--host', default='0.0.0.0', help='Host to bind to (default: 0.0.0.0)')
    args = parser.parse_args()
    
    receiver = WiFiTextReceiver(args.host, args.port)
    
    try:
        receiver.start_server()
    except KeyboardInterrupt:
        print("\n🛑 Shutting down receiver...")
        receiver.stop_server()
        print("✅ Receiver stopped.")

if __name__ == "__main__":
    main()