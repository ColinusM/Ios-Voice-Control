#!/usr/bin/env python3
"""
Simple GUI Receiver for iOS Voice Control App
Perfect for iPhone hotspot testing with visual feedback
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import socket
import json
import threading
from datetime import datetime
import queue

class VoiceControlGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("🎙️ iOS Voice Control Receiver")
        self.root.geometry("800x600")
        
        # Server state
        self.server_socket = None
        self.is_running = False
        self.clients = []
        self.message_queue = queue.Queue()
        
        # Setup GUI
        self.setup_gui()
        
        # Start message processor
        self.process_messages()
    
    def setup_gui(self):
        """Create the GUI interface"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Connection settings
        settings_frame = ttk.LabelFrame(main_frame, text="Connection Settings", padding="10")
        settings_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(0, 10))
        
        ttk.Label(settings_frame, text="Port:").grid(row=0, column=0, sticky=tk.W)
        self.port_var = tk.StringVar(value="8080")
        port_entry = ttk.Entry(settings_frame, textvariable=self.port_var, width=10)
        port_entry.grid(row=0, column=1, padx=(5, 20))
        
        ttk.Label(settings_frame, text="Mode:").grid(row=0, column=2, sticky=tk.W)
        self.mode_var = tk.StringVar(value="Development (UDP 8080)")
        mode_combo = ttk.Combobox(settings_frame, textvariable=self.mode_var, 
                                 values=["Development (UDP 8080)", "Yamaha RCP (TCP 49280)"], 
                                 state="readonly", width=20)
        mode_combo.grid(row=0, column=3, padx=(5, 0))
        mode_combo.bind('<<ComboboxSelected>>', self.on_mode_change)
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=1, column=0, columnspan=2, pady=(0, 10))
        
        self.start_button = ttk.Button(button_frame, text="🚀 Start Server", command=self.start_server)
        self.start_button.pack(side=tk.LEFT, padx=(0, 5))
        
        self.stop_button = ttk.Button(button_frame, text="⏹️ Stop Server", command=self.stop_server, state=tk.DISABLED)
        self.stop_button.pack(side=tk.LEFT, padx=(0, 5))
        
        self.clear_button = ttk.Button(button_frame, text="🗑️ Clear Log", command=self.clear_log)
        self.clear_button.pack(side=tk.LEFT, padx=(0, 5))
        
        # Status
        self.status_var = tk.StringVar(value="📱 Ready to connect - Start server first")
        status_label = ttk.Label(main_frame, textvariable=self.status_var, font=("Arial", 10, "bold"))
        status_label.grid(row=2, column=0, columnspan=2, pady=(0, 10))
        
        # Messages log
        log_frame = ttk.LabelFrame(main_frame, text="Messages & RCP Commands", padding="10")
        log_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=20, state=tk.DISABLED, 
                                                font=("Monaco", 11))
        self.log_text.pack(fill=tk.BOTH, expand=True)
        
        # Connection info
        info_frame = ttk.LabelFrame(main_frame, text="iPhone Hotspot Setup", padding="10")
        info_frame.grid(row=4, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(10, 0))
        
        info_text = """📱 iPhone Hotspot Instructions:
1. iPhone: Settings → Personal Hotspot → Turn On
2. Mac: Connect to iPhone's hotspot WiFi
3. iPhone IP usually: 172.20.10.1 (your iOS app sends to Mac)
4. Click 'Start Server' above, then test with iOS app"""
        
        info_label = ttk.Label(info_frame, text=info_text, justify=tk.LEFT, font=("Arial", 9))
        info_label.pack()
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(3, weight=1)
    
    def on_mode_change(self, event=None):
        """Handle mode selection change"""
        mode = self.mode_var.get()
        if "Development" in mode:
            self.port_var.set("8080")
        elif "Yamaha" in mode:
            self.port_var.set("49280")
    
    def log_message(self, message, level="INFO"):
        """Add message to log with timestamp"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        
        # Color coding
        if level == "VOICE":
            prefix = "🗣️"
        elif level == "RCP":
            prefix = "🎛️"
        elif level == "CONNECT":
            prefix = "📱"
        elif level == "ERROR":
            prefix = "❌"
        else:
            prefix = "ℹ️"
        
        log_entry = f"[{timestamp}] {prefix} {message}\n"
        
        # Queue the message for thread-safe GUI update
        self.message_queue.put(log_entry)
    
    def process_messages(self):
        """Process queued messages in main thread"""
        try:
            while True:
                message = self.message_queue.get_nowait()
                self.log_text.config(state=tk.NORMAL)
                self.log_text.insert(tk.END, message)
                self.log_text.see(tk.END)
                self.log_text.config(state=tk.DISABLED)
        except queue.Empty:
            pass
        
        # Schedule next check
        self.root.after(100, self.process_messages)
    
    def start_server(self):
        """Start the server in a separate thread"""
        try:
            port = int(self.port_var.get())
            mode = self.mode_var.get()
            
            if "TCP" in mode or "Yamaha" in mode:
                self.start_tcp_server(port)
            else:
                # Default to UDP for Development mode
                self.start_udp_server(port)
            
            self.start_button.config(state=tk.DISABLED)
            self.stop_button.config(state=tk.NORMAL)
            
            self.status_var.set(f"✅ Server running on port {port} - Ready for iOS connections!")
            self.log_message(f"Server started on port {port} ({mode})", "INFO")
            
        except ValueError:
            messagebox.showerror("Error", "Invalid port number")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to start server: {e}")
    
    def start_udp_server(self, port):
        """Start UDP server for development"""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.server_socket.bind(('0.0.0.0', port))
        self.is_running = True
        
        def udp_handler():
            while self.is_running:
                try:
                    data, addr = self.server_socket.recvfrom(4096)
                    self.handle_udp_message(data, addr)
                except Exception as e:
                    if self.is_running:
                        self.log_message(f"UDP Error: {e}", "ERROR")
        
        threading.Thread(target=udp_handler, daemon=True).start()
    
    def start_tcp_server(self, port):
        """Start TCP server for Yamaha RCP"""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind(('0.0.0.0', port))
        self.server_socket.listen(5)
        self.is_running = True
        
        def tcp_handler():
            while self.is_running:
                try:
                    client_socket, addr = self.server_socket.accept()
                    self.log_message(f"Connected: {addr[0]}:{addr[1]}", "CONNECT")
                    threading.Thread(target=self.handle_tcp_client, 
                                   args=(client_socket, addr), daemon=True).start()
                except Exception as e:
                    if self.is_running:
                        self.log_message(f"TCP Error: {e}", "ERROR")
        
        threading.Thread(target=tcp_handler, daemon=True).start()
    
    def handle_udp_message(self, data, addr):
        """Handle UDP message"""
        try:
            message_str = data.decode('utf-8').strip()
            
            try:
                message = json.loads(message_str)
                content = message.get('content', 'N/A')
                self.log_message(f"Voice from {addr[0]}: \"{content}\"", "VOICE")
                
                # Check if RCP commands were already generated and sent
                rcp_commands = message.get('rcpCommands', [])
                if rcp_commands:
                    self.log_message(f"Received {len(rcp_commands)} RCP commands:", "RCP")
                    for i, cmd in enumerate(rcp_commands, 1):
                        command = cmd.get('command', 'N/A')
                        description = cmd.get('description', 'N/A')
                        self.log_message(f"  {i}. {description}", "RCP")
                        self.log_message(f"     {command}", "RCP")
                else:
                    # Fallback to simple voice-to-RCP conversion
                    rcp = self.voice_to_rcp(content)
                    if rcp:
                        self.log_message(f"RCP Command: {rcp}", "RCP")
                
            except json.JSONDecodeError:
                self.log_message(f"Text from {addr[0]}: {message_str}", "INFO")
                
        except Exception as e:
            self.log_message(f"Message handling error: {e}", "ERROR")
    
    def handle_tcp_client(self, client_socket, addr):
        """Handle TCP client connection"""
        buffer = ""
        try:
            while self.is_running:
                data = client_socket.recv(1024)
                if not data:
                    break
                
                buffer += data.decode('utf-8')
                while '\n' in buffer:
                    message, buffer = buffer.split('\n', 1)
                    if message.strip():
                        self.process_tcp_message(message.strip(), addr)
        except Exception as e:
            self.log_message(f"Client error {addr[0]}: {e}", "ERROR")
        finally:
            client_socket.close()
            self.log_message(f"Disconnected: {addr[0]}", "CONNECT")
    
    def process_tcp_message(self, message, addr):
        """Process TCP message"""
        try:
            data = json.loads(message)
            content = data.get('content', '')
            self.log_message(f"Voice from {addr[0]}: \"{content}\"", "VOICE")
            
            rcp = self.voice_to_rcp(content)
            if rcp:
                self.log_message(f"RCP Command: {rcp}", "RCP")
        except json.JSONDecodeError:
            self.log_message(f"RCP from {addr[0]}: {message}", "RCP")
    
    def voice_to_rcp(self, voice_text):
        """Convert voice to RCP command"""
        voice_lower = voice_text.lower()
        
        # Basic voice to RCP conversion
        if 'channel' in voice_lower and 'unity' in voice_lower:
            for word in voice_text.split():
                if word.isdigit():
                    ch = int(word)
                    return f"set MIXER:Current/InCh/Fader/Level {ch-1} 0 0"
        
        elif 'mute' in voice_lower and 'channel' in voice_lower:
            for word in voice_text.split():
                if word.isdigit():
                    ch = int(word)
                    return f"set MIXER:Current/InCh/Fader/On {ch-1} 0 0"
        
        return None
    
    def stop_server(self):
        """Stop the server"""
        self.is_running = False
        if self.server_socket:
            self.server_socket.close()
        
        self.start_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)
        self.status_var.set("📱 Server stopped - Click Start to begin again")
        self.log_message("Server stopped", "INFO")
    
    def clear_log(self):
        """Clear the message log"""
        self.log_text.config(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.config(state=tk.DISABLED)

def main():
    root = tk.Tk()
    app = VoiceControlGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()