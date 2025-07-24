#!/usr/bin/env python3
"""
Simple Flask server for Voice Command GUI
Serves the HTML interface and processes voice commands via the rule engine
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import sys
import socket
import json
from engine import VoiceCommandEngine

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize the voice command engine
engine = VoiceCommandEngine()

@app.route('/')
def index():
    """Serve the main GUI HTML file"""
    return send_file('gui.html')

@app.route('/process', methods=['POST'])
def process_command():
    """Process a voice command and return RCP commands"""
    try:
        data = request.get_json()
        
        if not data or 'command' not in data:
            return jsonify({'error': 'No command provided'}), 400
            
        command = data['command'].strip()
        
        if not command:
            return jsonify({'error': 'Empty command'}), 400
            
        # Process the command
        results = engine.process_command(command)
        
        # Convert results to JSON-serializable format
        json_results = []
        for result in results:
            json_results.append({
                'command': result.command,
                'description': result.description,
                'confidence': result.confidence
            })
            
        return jsonify({
            'success': True,
            'results': json_results,
            'command': command
        })
        
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

@app.route('/labels', methods=['GET'])
def get_labels():
    """Get current channel and DCA labels"""
    try:
        return jsonify({
            'channel_labels': engine.get_channel_labels(),
            'dca_labels': engine.get_dca_labels()
        })
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

@app.route('/test', methods=['GET'])
def test_endpoint():
    """Test endpoint to verify server is running"""
    return jsonify({
        'status': 'ok',
        'message': 'Voice Command Server is running',
        'engine_ready': True
    })

@app.route('/send_to_receiver', methods=['POST'])
def send_to_receiver():
    """Send RCP commands to ComputerReceiver"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Default receiver settings
        receiver_host = '127.0.0.1'
        receiver_port = 8080
        
        # Create UDP socket to send to receiver
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(5.0)  # 5 second timeout
        
        try:
            # Send the message as JSON
            message_json = json.dumps(data)
            sock.sendto(message_json.encode('utf-8'), (receiver_host, receiver_port))
            
            return jsonify({
                'success': True,
                'message': f'Sent to receiver at {receiver_host}:{receiver_port}',
                'commands_sent': len(data.get('rcpCommands', []))
            })
            
        except socket.timeout:
            return jsonify({'error': 'Timeout connecting to receiver - make sure it\'s running on port 8080'}), 408
        except ConnectionRefusedError:
            return jsonify({'error': 'Connection refused - make sure ComputerReceiver is running on port 8080'}), 503
        except Exception as e:
            return jsonify({'error': f'Network error: {str(e)}'}), 500
        finally:
            sock.close()
            
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

if __name__ == '__main__':
    print("=" * 60)
    print("🎙️  Voice Command Tester Server")
    print("=" * 60)
    print()
    print("Starting server...")
    print("📍 GUI will be available at: http://localhost:5001")
    print("🔧 API endpoint: http://localhost:5001/process")
    print()
    print("Press Ctrl+C to stop the server")
    print()
    
    # Run the Flask development server
    try:
        app.run(
            host='127.0.0.1',
            port=5001,  # Changed from 5000 to avoid Apple AirTunes conflict
            debug=True,
            use_reloader=False  # Disable reloader to prevent double startup
        )
    except KeyboardInterrupt:
        print("\n👋 Server stopped")
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        sys.exit(1)