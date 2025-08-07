#!/usr/bin/env python3

"""
🎯 Android Mobile MCP Testing Framework
Intelligent testing loop for Voice Control App with automated validation
"""

import subprocess
import time
import json
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import sys

class AndroidTester:
    def __init__(self):
        self.app_package = "com.voicecontrol.app"
        self.app_activity = "com.voicecontrol.app.MainActivity"
        self.results_dir = Path(f"test_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
        self.results_dir.mkdir(exist_ok=True)
        
        # Load configuration
        self.config = self.load_config()
        
        # Test patterns for different components (updated for structured logging)
        self.patterns = {
            'network': r"NetworkSettings|Navigation|nav_network|CoreBackPreview|NetworkSettingsViewModel",
            'voice_recording': r"VoiceRecordingViewModel|SpeechRecognitionService|AudioManager|🎙️|🚀|Recording|startRecording",
            'assembly_ai': r"AssemblyAI|WebSocket|🔗|Connected|Streaming|transcription",
            'structured_logging': r"VLogger|VoiceControlLogger|sessionId|metadata|JSON",
            'retry_logic': r"retry|RetryOperation|exponential backoff|startRecordingWithRetry|🔄",
            'back': r"onBackPressed|WindowDispatcher|CoreBackPreview|sendCancelIfRunning",
            'launch': r"MainActivity|onCreate|VoiceControlApp|🚀.*MainActivity",
            'error': r"ERROR|FATAL|Exception|ANR|crash|❌",
            'touch': r"TouchEvent|MotionEvent|onClick|InputDispatcher",
            'lifecycle': r"Activity|Fragment|onResume|onPause|onCreate|onDestroy",
            'permission': r"RECORD_AUDIO|permission|🔐|granted|Audio permission",
            'command_processing': r"VoiceCommandProcessor|processTranscription|🎯|Command|✅.*Parsed"
        }
        
        # UI element coordinates (updated for new RecordButton)
        self.ui_elements = {
            'network_button': (257, 1990),
            'record_button': (512, 1800),  # Updated for RecordButton FAB
            'upgrade_button': (771, 1990),
            'menu_button': (975, 195),
            'retry_button': (512, 1400),
            'cancel_retry_button': (512, 1500)
        }
        
    def load_config(self) -> Dict:
        """Load test configuration from file"""
        config_file = Path(__file__).parent / "test_config.json"
        if config_file.exists():
            try:
                with open(config_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                print(f"⚠️  Error loading config: {e}")
        return {}
        
    def run_adb(self, command: str) -> str:
        """Execute ADB command and return output"""
        try:
            result = subprocess.run(
                f"adb {command}",
                shell=True,
                capture_output=True,
                text=True,
                timeout=5
            )
            return result.stdout
        except subprocess.TimeoutExpired:
            return "Command timed out"
        except Exception as e:
            return f"Error: {str(e)}"
    
    def clear_logs(self):
        """Clear logcat buffer"""
        self.run_adb("logcat -c")
        print("✅ Logs cleared")
    
    def inject_marker(self, test_name: str) -> str:
        """Inject a marker into logs for tracking"""
        marker = f"TEST_{test_name}_{int(time.time())}"
        self.run_adb(f'shell log -t TestMarker -p i "{marker}"')
        return marker
    
    def capture_logs(self, marker: str, duration: int = 2) -> Dict[str, List[str]]:
        """Capture logs with multiple filters"""
        print(f"📝 Capturing logs for {duration} seconds...")
        
        # Start capture
        time.sleep(duration)
        
        # Get logs with different filters
        logs = {
            'full': self.run_adb("logcat -d -t 500").splitlines(),
            'app': self.run_adb(f"logcat -d -t 500 | grep {self.app_package}").splitlines(),
            'errors': self.run_adb('logcat -d -t 500 | grep -E "ERROR|FATAL"').splitlines(),
            'touch': self.run_adb('logcat -d -t 500 | grep -E "TouchEvent|onClick"').splitlines(),
            'lifecycle': self.run_adb('logcat -d -t 500 | grep -E "Activity|Fragment"').splitlines()
        }
        
        # Save to files
        for log_type, log_lines in logs.items():
            log_file = self.results_dir / f"{marker}_{log_type}.log"
            log_file.write_text('\n'.join(log_lines))
        
        return logs
    
    def analyze_logs(self, logs: Dict[str, List[str]], expected_pattern: str) -> Tuple[bool, List[str]]:
        """Analyze logs for expected patterns"""
        found_lines = []
        pattern = re.compile(expected_pattern, re.IGNORECASE)
        
        for log_type, log_lines in logs.items():
            for line in log_lines:
                if pattern.search(line):
                    found_lines.append(f"[{log_type}] {line}")
        
        return len(found_lines) > 0, found_lines
    
    def tap_screen(self, x: int, y: int, description: str = ""):
        """Tap screen at coordinates"""
        print(f"👆 Tapping {description} at ({x}, {y})")
        self.run_adb(f"shell input tap {x} {y}")
    
    def press_button(self, button: str):
        """Press hardware button"""
        button_map = {
            'BACK': 'KEYCODE_BACK',
            'HOME': 'KEYCODE_HOME',
            'MENU': 'KEYCODE_MENU',
            'ENTER': 'KEYCODE_ENTER'
        }
        keycode = button_map.get(button, button)
        print(f"🔘 Pressing {button} button")
        self.run_adb(f"shell input keyevent {keycode}")
    
    def launch_app(self):
        """Launch the Voice Control app"""
        print("🚀 Launching Voice Control app")
        self.run_adb(f"shell am start -n {self.app_package}/{self.app_activity}")
    
    def take_screenshot(self, name: str):
        """Take screenshot and save locally"""
        screenshot_path = self.results_dir / f"{name}.png"
        self.run_adb(f"exec-out screencap -p > {screenshot_path}")
        print(f"📸 Screenshot saved: {screenshot_path}")
        return screenshot_path
    
    def run_test(self, test_name: str, action_func, expected_pattern: str) -> bool:
        """Run a single test with validation"""
        print(f"\n{'='*50}")
        print(f"🧪 Running test: {test_name}")
        print(f"{'='*50}")
        
        # Prepare
        self.clear_logs()
        marker = self.inject_marker(test_name)
        
        # Take before screenshot
        self.take_screenshot(f"{marker}_before")
        
        # Execute action
        action_func()
        
        # Capture logs
        logs = self.capture_logs(marker, duration=3)
        
        # Take after screenshot
        self.take_screenshot(f"{marker}_after")
        
        # Analyze
        passed, found_lines = self.analyze_logs(logs, expected_pattern)
        
        if passed:
            print(f"✅ Test PASSED: {test_name}")
            if found_lines:
                print(f"📋 Found {len(found_lines)} matching lines:")
                for line in found_lines[:3]:  # Show first 3 matches
                    print(f"   {line[:100]}...")
        else:
            print(f"❌ Test FAILED: {test_name}")
            print(f"   Expected pattern: {expected_pattern}")
            
            # Check for errors
            error_lines = [l for l in logs.get('errors', []) if l]
            if error_lines:
                print(f"⚠️  Errors detected:")
                for error in error_lines[:3]:
                    print(f"   {error[:100]}...")
        
        # Save test result
        result = {
            'test_name': test_name,
            'passed': passed,
            'timestamp': datetime.now().isoformat(),
            'expected_pattern': expected_pattern,
            'found_lines': found_lines[:10] if found_lines else [],
            'errors': error_lines[:10] if 'error_lines' in locals() else []
        }
        
        result_file = self.results_dir / f"{marker}_result.json"
        result_file.write_text(json.dumps(result, indent=2))
        
        return passed
    
    def test_network_button(self) -> bool:
        """Test Network button functionality"""
        return self.run_test(
            "Network Button",
            lambda: self.tap_screen(257, 1990, "Network button"),
            self.patterns['network']
        )
    
    def test_record_button(self) -> bool:
        """Test Record button functionality with structured logging"""
        return self.run_test(
            "Record Button",
            lambda: self.tap_screen(512, 1800, "Record button"),
            self.patterns['voice_recording']
        )
    
    def test_back_navigation(self) -> bool:
        """Test back navigation"""
        return self.run_test(
            "Back Navigation",
            lambda: self.press_button('BACK'),
            self.patterns['back']
        )
    
    def test_app_launch(self) -> bool:
        """Test app launch"""
        return self.run_test(
            "App Launch",
            self.launch_app,
            self.patterns['launch']
        )
    
    def test_structured_logging(self) -> bool:
        """Test VLogger structured logging integration"""
        return self.run_test(
            "Structured Logging",
            lambda: self.tap_screen(512, 1800, "Record button for logging test"),
            self.patterns['structured_logging']
        )
    
    def test_assembly_ai_integration(self) -> bool:
        """Test AssemblyAI WebSocket integration"""
        return self.run_test(
            "AssemblyAI Integration",
            lambda: [
                self.tap_screen(512, 1800, "Start recording"),
                time.sleep(3),
                self.tap_screen(512, 1800, "Stop recording")
            ][-1],  # Return last operation
            self.patterns['assembly_ai']
        )
    
    def test_retry_logic(self) -> bool:
        """Test retry logic and error recovery"""
        def trigger_retry_scenario():
            # First, put app in airplane mode to trigger connection failure
            self.run_adb("shell settings put global airplane_mode_on 1")
            self.run_adb("shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true")
            time.sleep(2)
            
            # Try to start recording (should trigger retry)
            self.tap_screen(512, 1800, "Record button for retry test")
            time.sleep(5)
            
            # Restore connection
            self.run_adb("shell settings put global airplane_mode_on 0")
            self.run_adb("shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false")
            
        return self.run_test(
            "Retry Logic",
            trigger_retry_scenario,
            self.patterns['retry_logic']
        )
    
    def test_permission_handling(self) -> bool:
        """Test microphone permission handling"""
        def test_permission():
            # Grant permission explicitly
            self.run_adb(f"shell pm grant {self.app_package} android.permission.RECORD_AUDIO")
            time.sleep(1)
            # Try recording
            self.tap_screen(512, 1800, "Record button with permission")
            
        return self.run_test(
            "Permission Handling",
            test_permission,
            self.patterns['permission']
        )
    
    def test_command_processing(self) -> bool:
        """Test voice command processing pipeline"""
        def test_voice_processing():
            # Start recording
            self.tap_screen(512, 1800, "Start voice recording")
            time.sleep(3)
            # Simulate some activity (in real scenario, user would speak)
            time.sleep(2)
            # Stop recording
            self.tap_screen(512, 1800, "Stop voice recording")
            
        return self.run_test(
            "Command Processing",
            test_voice_processing,
            self.patterns['command_processing']
        )
    
    def run_test_suite(self):
        """Run complete test suite"""
        print("\n" + "="*60)
        print("🎯 VOICE CONTROL APP TEST SUITE")
        print("="*60)
        
        tests = [
            self.test_app_launch,
            self.test_structured_logging,
            self.test_network_button,
            self.test_record_button,
            self.test_permission_handling,
            self.test_assembly_ai_integration,
            self.test_command_processing,
            self.test_back_navigation,
            self.test_retry_logic  # Keep retry logic last as it toggles airplane mode
        ]
        
        results = {'passed': 0, 'failed': 0}
        
        for test_func in tests:
            if test_func():
                results['passed'] += 1
            else:
                results['failed'] += 1
            time.sleep(2)  # Pause between tests
        
        # Print summary
        print("\n" + "="*60)
        print("📊 TEST SUITE SUMMARY")
        print("="*60)
        print(f"✅ Passed: {results['passed']}")
        print(f"❌ Failed: {results['failed']}")
        print(f"📁 Results saved to: {self.results_dir}")
        
        # Save summary
        summary_file = self.results_dir / "test_summary.json"
        summary_file.write_text(json.dumps({
            'timestamp': datetime.now().isoformat(),
            'passed': results['passed'],
            'failed': results['failed'],
            'total': results['passed'] + results['failed']
        }, indent=2))
        
        return results['failed'] == 0
    
    def live_monitor(self):
        """Live monitoring mode with colored output"""
        print("🔴 Live Monitoring Mode (Ctrl+C to stop)")
        print("="*60)
        
        self.clear_logs()
        
        try:
            process = subprocess.Popen(
                ['adb', 'logcat'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            for line in process.stdout:
                # Color code based on content (updated for structured logging)
                if re.search(r'ERROR|FATAL|Exception|❌', line):
                    print(f"🔴 {line.strip()}")
                elif re.search(r'VLogger|VoiceControlLogger|🎙️|🚀|✅', line):
                    print(f"🟣 {line.strip()}")  # Purple for VLogger
                elif self.app_package in line:
                    print(f"🟢 {line.strip()}")
                elif re.search(r'AssemblyAI|🔗|WebSocket', line):
                    print(f"🟠 {line.strip()}")  # Orange for AssemblyAI
                elif re.search(r'TouchEvent|onClick', line):
                    print(f"🟡 {line.strip()}")
                elif re.search(r'Activity|Fragment', line):
                    print(f"🔵 {line.strip()}")
                elif re.search(r'🔄|retry|RetryOperation', line):
                    print(f"🔄 {line.strip()}")  # Retry indicator
                    
        except KeyboardInterrupt:
            print("\n✋ Monitoring stopped")
            process.terminate()
    
    def interactive_mode(self):
        """Interactive testing mode"""
        while True:
            print("\n" + "="*60)
            print("🎯 ANDROID VOICE CONTROL TESTER")
            print("="*60)
            print("1. Run Full Test Suite")
            print("2. Test App Launch")
            print("3. Test Record Button (Voice)")
            print("4. Test Network Button")
            print("5. Test Back Navigation")
            print("6. Test Structured Logging")
            print("7. Test AssemblyAI Integration")
            print("8. Test Permission Handling")
            print("9. Test Command Processing")
            print("10. Test Retry Logic")
            print("11. Custom Tap Test")
            print("12. Live Monitor Mode")
            print("13. Take Screenshot")
            print("14. Clear Logs")
            print("0. Exit")
            print("="*60)
            
            choice = input("Select option: ")
            
            if choice == '1':
                self.run_test_suite()
            elif choice == '2':
                self.test_app_launch()
            elif choice == '3':
                self.test_record_button()
            elif choice == '4':
                self.test_network_button()
            elif choice == '5':
                self.test_back_navigation()
            elif choice == '6':
                self.test_structured_logging()
            elif choice == '7':
                self.test_assembly_ai_integration()
            elif choice == '8':
                self.test_permission_handling()
            elif choice == '9':
                self.test_command_processing()
            elif choice == '10':
                self.test_retry_logic()
            elif choice == '11':
                x = int(input("Enter X coordinate: "))
                y = int(input("Enter Y coordinate: "))
                pattern = input("Enter expected pattern: ")
                self.run_test(
                    f"Custom Tap ({x},{y})",
                    lambda: self.tap_screen(x, y, "custom location"),
                    pattern
                )
            elif choice == '12':
                self.live_monitor()
            elif choice == '13':
                name = input("Screenshot name: ")
                self.take_screenshot(name)
            elif choice == '14':
                self.clear_logs()
            elif choice == '0':
                print("👋 Goodbye!")
                break
            else:
                print("❌ Invalid option")
            
            if choice != '12':  # Don't pause after live monitor
                input("\nPress Enter to continue...")

def main():
    """Main entry point"""
    tester = AndroidTester()
    
    # Check ADB connection
    devices = tester.run_adb("devices")
    if "device" not in devices:
        print("❌ No Android device connected!")
        print("Connect a device or start an emulator.")
        sys.exit(1)
    
    print("✅ Device connected")
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        if sys.argv[1] == '--suite':
            success = tester.run_test_suite()
            sys.exit(0 if success else 1)
        elif sys.argv[1] == '--live':
            tester.live_monitor()
        elif sys.argv[1] == '--help':
            print("Usage:")
            print("  python android_mcp_tester.py          # Interactive mode")
            print("  python android_mcp_tester.py --suite  # Run test suite")
            print("  python android_mcp_tester.py --live   # Live monitor")
            sys.exit(0)
    else:
        tester.interactive_mode()

if __name__ == "__main__":
    main()