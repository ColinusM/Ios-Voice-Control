#!/usr/bin/env python3
"""
Test script to verify the WiFi receiver is working
Sends test messages to the receiver
"""

import socket
import json
import time
from datetime import datetime
import uuid

def send_test_message(host='localhost', port=8080):
    """Send a test message to the receiver"""
    try:
        # Create test message in iOS app format
        test_message = {
            "id": str(uuid.uuid4()),
            "content": "Set channel 1 to unity gain",
            "timestamp": datetime.now().isoformat(),
            "messageType": "plainText",
            "metadata": {"source": "test_script"}
        }
        
        # Create UDP socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(5.0)
        
        # Send message
        message_data = json.dumps(test_message).encode('utf-8')
        sock.sendto(message_data, (host, port))
        print(f"✅ Sent test message to {host}:{port}")
        print(f"   Content: {test_message['content']}")
        
        # Wait for acknowledgment
        try:
            response, addr = sock.recvfrom(1024)
            response_data = json.loads(response.decode('utf-8'))
            print(f"✅ Received acknowledgment: {response_data['status']}")
        except socket.timeout:
            print("⚠️  No acknowledgment received (timeout)")
        except Exception as e:
            print(f"⚠️  Error receiving acknowledgment: {e}")
            
        sock.close()
        
    except Exception as e:
        print(f"❌ Failed to send test message: {e}")

def main():
    print("🧪 Testing WiFi Text Receiver")
    print("Make sure the receiver is running with: python3 udp_receiver.py")
    print()
    
    # Send a few test messages
    send_test_message()
    time.sleep(1)
    
    # Send plain text message
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.sendto(b"Plain text test message", ('localhost', 8080))
        print("✅ Sent plain text message")
        sock.close()
    except Exception as e:
        print(f"❌ Failed to send plain text: {e}")

if __name__ == "__main__":
    main()