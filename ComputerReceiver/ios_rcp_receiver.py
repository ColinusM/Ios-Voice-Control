#!/usr/bin/env python3
"""
iOS RCP Receiver - Flask HTTP Server
Receives RCP commands from iOS Voice Control App via HTTP POST
Matches the RCPCommandPayload structure from iOS client
"""

from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import json
import logging
from datetime import datetime
import sys
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('ios_rcp_receiver.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Store received commands for display
received_commands = []
MAX_COMMANDS = 100  # Keep last 100 commands

# HTML template for web GUI
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>🎙️ iOS RCP Command Receiver</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: #f5f5f7; 
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 12px; 
            padding: 30px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #1d1d1f; 
            text-align: center; 
            margin-bottom: 30px; 
            font-size: 2.2em;
        }
        .status { 
            background: #e8f5e8; 
            padding: 15px; 
            border: 1px solid #d1e7dd; 
            border-radius: 8px; 
            margin-bottom: 25px; 
            text-align: center;
            font-weight: 500;
        }
        .command { 
            background: #f8f9fa; 
            border: 1px solid #dee2e6; 
            border-radius: 8px; 
            padding: 20px; 
            margin-bottom: 15px; 
            transition: transform 0.2s ease;
        }
        .command:hover { 
            transform: translateY(-2px); 
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .command-header { 
            display: flex; 
            justify-content: space-between; 
            align-items: center; 
            margin-bottom: 12px; 
        }
        .timestamp { 
            color: #6c757d; 
            font-size: 0.9em; 
            font-family: 'Monaco', 'Menlo', monospace;
        }
        .device-info { 
            color: #495057; 
            font-size: 0.85em; 
            background: #e9ecef; 
            padding: 4px 8px; 
            border-radius: 4px;
        }
        .voice-text { 
            font-size: 1.1em; 
            font-weight: 500; 
            color: #495057; 
            margin-bottom: 10px;
            padding: 10px;
            background: #fff3cd;
            border-radius: 6px;
            border-left: 4px solid #ffc107;
        }
        .rcp-command { 
            font-family: 'Monaco', 'Menlo', monospace; 
            background: #f8f9fa; 
            padding: 12px; 
            border-radius: 6px; 
            border-left: 4px solid #0d6efd;
            margin-bottom: 8px;
            font-size: 0.95em;
        }
        .description { 
            color: #6c757d; 
            font-style: italic; 
            margin-bottom: 8px;
        }
        .confidence { 
            display: inline-block; 
            padding: 4px 8px; 
            border-radius: 20px; 
            font-size: 0.8em; 
            font-weight: 500;
        }
        .confidence.high { background: #d1e7dd; color: #0a3622; }
        .confidence.medium { background: #fff3cd; color: #664d03; }
        .confidence.low { background: #f8d7da; color: #58151c; }
        .no-commands { 
            text-align: center; 
            color: #6c757d; 
            padding: 40px; 
            font-style: italic;
        }
        .controls {
            text-align: center;
            margin-bottom: 25px;
        }
        .btn {
            background: #0d6efd;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.95em;
            margin: 0 5px;
        }
        .btn:hover {
            background: #0b5ed7;
        }
        .btn.danger {
            background: #dc3545;
        }
        .btn.danger:hover {
            background: #bb2d3b;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎙️ iOS RCP Command Receiver</h1>
        
        <div class="status">
            ✅ Server Running - Ready to receive commands from iOS Voice Control App
        </div>
        
        <div class="controls">
            <button class="btn" onclick="refreshPage()">🔄 Refresh</button>
            <button class="btn danger" onclick="clearCommands()">🗑️ Clear All</button>
        </div>
        
        <div id="commands">
            {% if commands %}
                {% for command in commands %}
                <div class="command">
                    <div class="command-header">
                        <span class="timestamp">{{ command.timestamp }}</span>
                        <span class="device-info">{{ command.device_id }}</span>
                    </div>
                    
                    <div class="voice-text">
                        🗣️ "{{ command.original_text }}"
                    </div>
                    
                    <div class="description">
                        {{ command.description }}
                    </div>
                    
                    <div class="rcp-command">
                        🎛️ {{ command.command }}
                    </div>
                    
                    <div>
                        <span class="confidence {{ 'high' if command.confidence >= 0.8 else 'medium' if command.confidence >= 0.5 else 'low' }}">
                            Confidence: {{ "%.1f%%"|format(command.confidence * 100) }}
                        </span>
                    </div>
                </div>
                {% endfor %}
            {% else %}
                <div class="no-commands">
                    📱 No commands received yet.<br>
                    Send a command from your iOS Voice Control App to see it here!
                </div>
            {% endif %}
        </div>
    </div>
    
    <script>
        function refreshPage() {
            location.reload();
        }
        
        function clearCommands() {
            if (confirm('Clear all received commands?')) {
                fetch('/clear', { method: 'POST' })
                    .then(() => location.reload());
            }
        }
        
        // Auto-refresh every 5 seconds
        setInterval(() => {
            location.reload();
        }, 5000);
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    """Serve the web GUI showing received commands"""
    return render_template_string(HTML_TEMPLATE, commands=list(reversed(received_commands[-20:])))

@app.route('/rcp', methods=['POST'])
def receive_rcp_command():
    """
    Receive RCP command from iOS app
    Expected JSON payload format from RCPCommandPayload:
    {
        "command": "set MIXER:Current/InCh/Fader/Level 0 0 0",
        "description": "Set channel 1 to unity gain", 
        "confidence": 0.95,
        "originalText": "channel one unity",
        "timestamp": "2024-01-15T10:30:45Z",
        "deviceId": "Colin's iPhone",
        "commandType": "voice_command"
    }
    """
    try:
        # Get JSON payload
        if not request.is_json:
            return jsonify({'error': 'Content-Type must be application/json'}), 400
            
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        # Validate required fields
        required_fields = ['command', 'description', 'confidence', 'originalText', 'timestamp', 'deviceId']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Create command record
        command_record = {
            'command': data['command'],
            'description': data['description'],
            'confidence': float(data['confidence']),
            'original_text': data['originalText'],
            'timestamp': data['timestamp'],
            'device_id': data['deviceId'],
            'command_type': data.get('commandType', 'unknown'),
            'received_at': datetime.now().isoformat(),
            'client_ip': request.remote_addr
        }
        
        # Add to received commands list
        received_commands.append(command_record)
        
        # Keep only last MAX_COMMANDS
        if len(received_commands) > MAX_COMMANDS:
            received_commands.pop(0)
        
        # Log the received command
        logger.info(f"📱 Received from {command_record['device_id']} ({command_record['client_ip']})")
        logger.info(f"🗣️  Voice: \"{command_record['original_text']}\"")
        logger.info(f"🎛️  RCP: {command_record['command']}")
        logger.info(f"📊 Confidence: {command_record['confidence']:.1%}")
        logger.info(f"📝 Description: {command_record['description']}")
        
        # Success response
        response_data = {
            'success': True,
            'message': 'RCP command received successfully',
            'command_id': len(received_commands),
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"✅ Response sent: {response_data['message']}")
        return jsonify(response_data), 200
        
    except ValueError as e:
        error_msg = f"Invalid data format: {str(e)}"
        logger.error(f"❌ {error_msg}")
        return jsonify({'error': error_msg}), 400
        
    except Exception as e:
        error_msg = f"Server error: {str(e)}"
        logger.error(f"❌ {error_msg}")
        return jsonify({'error': error_msg}), 500

@app.route('/clear', methods=['POST'])
def clear_commands():
    """Clear all received commands"""
    global received_commands
    received_commands.clear()
    logger.info("🗑️ All commands cleared")
    return jsonify({'success': True, 'message': 'Commands cleared'})

@app.route('/status', methods=['GET'])
def status():
    """Get server status and statistics"""
    return jsonify({
        'status': 'running',
        'message': 'iOS RCP Receiver is operational',
        'commands_received': len(received_commands),
        'last_command_time': received_commands[-1]['received_at'] if received_commands else None,
        'server_start_time': datetime.now().isoformat()
    })

@app.route('/api/commands', methods=['GET'])
def get_commands_api():
    """Get all received commands as JSON API"""
    return jsonify({
        'commands': received_commands,
        'total': len(received_commands)
    })

def main():
    """Main entry point"""
    print("=" * 60)
    print("🎙️  iOS RCP Command Receiver")
    print("=" * 60)
    print()
    print("📡 Starting HTTP server for iOS Voice Control App...")
    print()
    print("🌐 Web GUI: http://localhost:8080")
    print("📍 RCP Endpoint: http://localhost:8080/rcp")
    print("📊 Status API: http://localhost:8080/status")  
    print()
    print("📱 Configure your iOS app to send commands to:")
    print("   • IP: Your Mac's IP address")
    print("   • Port: 8080")
    print("   • Target: Mac GUI (Testing)")
    print()
    print("Press Ctrl+C to stop the server")
    print()
    
    try:
        # Run Flask server
        app.run(
            host='0.0.0.0',  # Accept connections from any IP
            port=8080,
            debug=False,
            threaded=True
        )
    except KeyboardInterrupt:
        print("\n👋 Server stopped gracefully")
    except Exception as e:
        print(f"❌ Server error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()