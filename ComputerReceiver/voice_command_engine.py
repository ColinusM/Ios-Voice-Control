#!/usr/bin/env python3
"""
Voice Command Rule Engine for Yamaha RCP Control
Converts natural language voice commands to Yamaha RCP protocol commands
"""

import re
from typing import Dict, List, Tuple, Optional, Union
from dataclasses import dataclass
import json


@dataclass
class RCPCommand:
    """Represents a Yamaha RCP command"""
    command: str
    description: str
    confidence: float = 1.0


class VoiceCommandEngine:
    """Rule-based engine for converting voice commands to RCP commands"""
    
    def __init__(self):
        self.channel_labels = {}  # Store channel labels for context-aware commands
        self.dca_labels = {}  # Store DCA labels
        
        # Common word variations for numbers
        self.number_words = {
            'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
            'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
            'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
            'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
            'nineteen': 19, 'twenty': 20
        }
        
        # Pan position mapping
        self.pan_positions = {
            'hard left': -63, 'hard_left': -63, 'hardleft': -63,
            'left': -32, 'slightly left': -16, 'slight left': -16,
            'center': 0, 'centre': 0, 'middle': 0,
            'slightly right': 16, 'slight right': 16,
            'right': 32, 'hard right': 63, 'hard_right': 63, 'hardright': 63
        }
        
        # dB value mapping
        self.db_keywords = {
            'unity': 0, 'zero': 0, 'nominal': 0,
            'minus infinity': -32768, 'negative infinity': -32768, 'inf': -32768,
            'off': -32768, 'down': -32768
        }
        
    def parse_number(self, text: str) -> Optional[int]:
        """Parse a number from text, handling both digits and words"""
        # Try direct integer conversion
        try:
            return int(text)
        except ValueError:
            pass
            
        # Try word to number conversion
        text_lower = text.lower()
        if text_lower in self.number_words:
            return self.number_words[text_lower]
            
        return None
        
    def parse_db_value(self, text: str) -> Optional[int]:
        """Parse a dB value from text"""
        # Check for special keywords first
        text_lower = text.lower()
        for keyword, value in self.db_keywords.items():
            if keyword in text_lower:
                return value
                
        # Parse numeric dB values
        # Match patterns like: "-6", "minus 6", "+3", "plus 3", "-10 dB", etc.
        patterns = [
            r'(?:minus|negative|-)\s*(\d+(?:\.\d+)?)\s*(?:db)?',
            r'(?:plus|positive|\+)?\s*(\d+(?:\.\d+)?)\s*(?:db)?'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text_lower)
            if match:
                value = float(match.group(1))
                if 'minus' in text_lower or 'negative' in text_lower or '-' in match.group(0):
                    value = -value
                # Convert to RCP format (multiply by 100)
                return int(value * 100)
                
        return None
        
    def process_channel_fader(self, command: str) -> List[RCPCommand]:
        """Process channel fader level commands"""
        results = []
        
        # Patterns for channel fader commands
        patterns = [
            # Basic patterns
            (r'(?:set\s+)?channel\s+(\d+)\s+(?:to|at|fader\s+to|volume\s+to)\s+(.+)', 'set'),
            (r'channel\s+(\d+)\s+(?:up|down)\s+(\d+)\s*(?:db)?', 'relative'),
            (r'(?:bring|pull|push)\s+channel\s+(\d+)\s+(?:to|down\s+to|up\s+to)\s+(.+)', 'set'),
            (r'(?:turn\s+)?(?:up|down)\s+channel\s+(\d+)\s+to\s+(.+)', 'set'),
            (r'channel\s+(\d+)\s+(?:level|fader)\s+(.+)', 'set'),
        ]
        
        for pattern, action in patterns:
            match = re.search(pattern, command.lower())
            if match:
                channel_num = self.parse_number(match.group(1))
                if channel_num is None:
                    continue
                    
                channel_idx = channel_num - 1  # Convert to 0-based index
                
                if action == 'set':
                    db_value = self.parse_db_value(match.group(2))
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Set channel {channel_num} fader to {db_value/100:.1f} dB"
                        ))
                elif action == 'relative':
                    # Handle relative changes (not in original spec but useful)
                    change = self.parse_number(match.group(2))
                    if change:
                        if 'up' in command.lower():
                            results.append(RCPCommand(
                                f"# GET current level first, then add {change} dB",
                                f"Increase channel {channel_num} by {change} dB",
                                0.8
                            ))
                        else:
                            results.append(RCPCommand(
                                f"# GET current level first, then subtract {change} dB",
                                f"Decrease channel {channel_num} by {change} dB",
                                0.8
                            ))
                            
        return results
        
    def process_channel_mute(self, command: str) -> List[RCPCommand]:
        """Process channel mute/unmute commands"""
        results = []
        
        # Patterns for mute commands
        patterns = [
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+channel\s+(\d+)', 0),  # Mute
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+channel\s+(\d+)', 1),  # Unmute
            (r'channel\s+(\d+)\s+(?:on|unmute)', 1),  # Unmute
            (r'channel\s+(\d+)\s+(?:off|mute)', 0),  # Mute
        ]
        
        for pattern, state in patterns:
            match = re.search(pattern, command.lower())
            if match:
                channel_num = self.parse_number(match.group(1))
                if channel_num:
                    channel_idx = channel_num - 1
                    state_text = "on" if state == 1 else "off"
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/On {channel_idx} 0 {state}",
                        f"Turn {state_text} channel {channel_num}"
                    ))
                    
        return results
        
    def process_channel_label(self, command: str) -> List[RCPCommand]:
        """Process channel labeling commands"""
        results = []
        
        # Patterns for label commands
        patterns = [
            r'(?:name|label|call|tag|mark)\s+channel\s+(\d+)\s+(?:as\s+)?(.+)',
            r'(?:set\s+)?channel\s+(\d+)\s+(?:name|label)\s+(?:to\s+)?(.+)',
            r'channel\s+(\d+)\s+(?:is|called)\s+(.+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, command.lower())
            if match:
                channel_num = self.parse_number(match.group(1))
                if channel_num:
                    channel_idx = channel_num - 1
                    label = match.group(2).strip().strip('"\'')
                    
                    # Store label for context-aware commands
                    self.channel_labels[label.lower()] = channel_num
                    
                    results.append(RCPCommand(
                        f'set MIXER:Current/InCh/Label/Name {channel_idx} 0 "{label}"',
                        f"Set channel {channel_num} label to '{label}'"
                    ))
                    
        return results
        
    def process_send_to_mix(self, command: str) -> List[RCPCommand]:
        """Process send to mix commands"""
        results = []
        
        # Patterns for send commands
        patterns = [
            # Basic send on/off
            (r'(?:send|route|add)\s+channel\s+(\d+)\s+to\s+(?:mix|aux|monitor)\s+(\d+)', 'on', None),
            (r'(?:turn\s+)?(?:on|off)\s+channel\s+(\d+)\s+(?:send\s+)?to\s+(?:mix|aux|monitor)\s+(\d+)', 'toggle', None),
            (r'(?:remove|turn\s+off)\s+channel\s+(\d+)\s+(?:from|send\s+to)\s+(?:mix|aux|monitor)\s+(\d+)', 'off', None),
            
            # Send with level
            (r'(?:set\s+)?channel\s+(\d+)\s+(?:send\s+)?to\s+(?:mix|aux|monitor)\s+(\d+)\s+(?:at|to)\s+(.+)', 'level', None),
            (r'channel\s+(\d+)\s+to\s+(?:mix|aux|monitor)\s+(\d+)\s+at\s+(.+)', 'level', None),
        ]
        
        for pattern, action, _ in patterns:
            match = re.search(pattern, command.lower())
            if match:
                channel_num = self.parse_number(match.group(1))
                mix_num = self.parse_number(match.group(2))
                
                if channel_num and mix_num:
                    channel_idx = channel_num - 1
                    mix_idx = mix_num - 1
                    
                    if action == 'on':
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 1",
                            f"Turn on channel {channel_num} send to mix {mix_num}"
                        ))
                    elif action == 'off':
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 0",
                            f"Turn off channel {channel_num} send to mix {mix_num}"
                        ))
                    elif action == 'toggle':
                        state = 1 if 'on' in command.lower() else 0
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} {state}",
                            f"Turn {'on' if state else 'off'} channel {channel_num} send to mix {mix_num}"
                        ))
                    elif action == 'level' and len(match.groups()) > 2:
                        db_value = self.parse_db_value(match.group(3))
                        if db_value is not None:
                            results.append(RCPCommand(
                                f"set MIXER:Current/InCh/ToMix/Level {channel_idx} {mix_idx} {db_value}",
                                f"Set channel {channel_num} send to mix {mix_num} at {db_value/100:.1f} dB"
                            ))
                            
        return results
        
    def process_pan_commands(self, command: str) -> List[RCPCommand]:
        """Process pan commands"""
        results = []
        
        # Main stereo pan patterns
        stereo_patterns = [
            r'(?:pan|hard)\s+(?:left|right)\s+channel\s+(\d+)',
            r'(?:pan\s+)?channel\s+(\d+)\s+(?:to\s+)?(.+)',
            r'(?:center|centre)\s+channel\s+(\d+)',
        ]
        
        for pattern in stereo_patterns:
            match = re.search(pattern, command.lower())
            if match:
                if 'center' in pattern or 'centre' in pattern:
                    channel_num = self.parse_number(match.group(1))
                    pan_value = 0
                else:
                    channel_num = self.parse_number(match.group(1))
                    # Determine pan position
                    if len(match.groups()) > 1:
                        pan_text = match.group(2).lower()
                    else:
                        pan_text = command.lower()
                        
                    pan_value = None
                    for position, value in self.pan_positions.items():
                        if position in pan_text:
                            pan_value = value
                            break
                            
                if channel_num and pan_value is not None:
                    channel_idx = channel_num - 1
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/ToSt/Pan {channel_idx} 0 {pan_value}",
                        f"Pan channel {channel_num} to {pan_value}"
                    ))
                    
        # Send pan patterns
        send_pan_patterns = [
            r'pan\s+channel\s+(\d+)\s+(?:send\s+)?to\s+(?:mix|aux|monitor)\s+(\d+)\s+(.+)',
            r'(?:hard\s+)?(?:left|right|center|centre)\s+channel\s+(\d+)\s+(?:send\s+)?to\s+(?:mix|aux)\s+(\d+)',
        ]
        
        for pattern in send_pan_patterns:
            match = re.search(pattern, command.lower())
            if match:
                channel_num = self.parse_number(match.group(1))
                mix_num = self.parse_number(match.group(2))
                
                if len(match.groups()) > 2:
                    pan_text = match.group(3).lower()
                else:
                    pan_text = command.lower()
                    
                pan_value = None
                for position, value in self.pan_positions.items():
                    if position in pan_text:
                        pan_value = value
                        break
                        
                if channel_num and mix_num and pan_value is not None:
                    channel_idx = channel_num - 1
                    mix_idx = mix_num - 1
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/ToMix/Pan {channel_idx} {mix_idx} {pan_value}",
                        f"Pan channel {channel_num} send to mix {mix_num} to {pan_value}"
                    ))
                    
        return results
        
    def process_scene_recall(self, command: str) -> List[RCPCommand]:
        """Process scene recall commands"""
        results = []
        
        patterns = [
            r'(?:recall|load|go\s+to|switch\s+to)\s+(?:scene|preset|snapshot)\s+(\d+)',
            r'scene\s+(\d+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, command.lower())
            if match:
                scene_num = self.parse_number(match.group(1))
                if scene_num and 1 <= scene_num <= 100:
                    scene_str = f"{scene_num:02d}"  # Format as 2-digit string
                    results.append(RCPCommand(
                        f"ssrecall_ex scene_{scene_str}",
                        f"Recall scene {scene_num}"
                    ))
                    
        return results
        
    def process_dca_commands(self, command: str) -> List[RCPCommand]:
        """Process DCA/VCA group commands"""
        results = []
        
        # DCA fader patterns
        fader_patterns = [
            (r'(?:set\s+)?(?:dca|vca|group)\s+(\d+)\s+(?:to|at)\s+(.+)', 'level'),
            (r'(?:dca|vca|group)\s+(\d+)\s+(?:up|down)\s+(\d+)', 'relative'),
        ]
        
        for pattern, action in fader_patterns:
            match = re.search(pattern, command.lower())
            if match:
                dca_num = self.parse_number(match.group(1))
                if dca_num and 1 <= dca_num <= 8:
                    dca_idx = dca_num - 1
                    
                    if action == 'level':
                        db_value = self.parse_db_value(match.group(2))
                        if db_value is not None:
                            results.append(RCPCommand(
                                f"set MIXER:Current/DCA/Fader/Level {dca_idx} 0 {db_value}",
                                f"Set DCA {dca_num} to {db_value/100:.1f} dB"
                            ))
                            
        # DCA mute patterns
        mute_patterns = [
            (r'(?:mute|turn\s+off)\s+(?:dca|vca|group)\s+(\d+)', 0),
            (r'(?:unmute|turn\s+on)\s+(?:dca|vca|group)\s+(\d+)', 1),
        ]
        
        for pattern, state in mute_patterns:
            match = re.search(pattern, command.lower())
            if match:
                dca_num = self.parse_number(match.group(1))
                if dca_num and 1 <= dca_num <= 8:
                    dca_idx = dca_num - 1
                    results.append(RCPCommand(
                        f"set MIXER:Current/DCA/Fader/On {dca_idx} 0 {state}",
                        f"{'Unmute' if state else 'Mute'} DCA {dca_num}"
                    ))
                    
        # DCA label patterns
        label_patterns = [
            r'(?:name|label)\s+(?:dca|vca|group)\s+(\d+)\s+(.+)',
        ]
        
        for pattern in label_patterns:
            match = re.search(pattern, command.lower())
            if match:
                dca_num = self.parse_number(match.group(1))
                if dca_num and 1 <= dca_num <= 8:
                    dca_idx = dca_num - 1
                    label = match.group(2).strip().strip('"\'')
                    self.dca_labels[label.lower()] = dca_num
                    results.append(RCPCommand(
                        f'set MIXER:Current/DCA/Label/Name {dca_idx} 0 "{label}"',
                        f"Set DCA {dca_num} label to '{label}'"
                    ))
                    
        return results
        
    def process_context_aware(self, command: str) -> List[RCPCommand]:
        """Process context-aware commands using stored labels"""
        results = []
        
        # Check for labeled channels
        for label, channel_num in self.channel_labels.items():
            if label in command.lower():
                # Replace label with channel number and reprocess
                modified_command = command.lower().replace(label, f"channel {channel_num}")
                results.extend(self.process_command(modified_command))
                
        # Check for labeled DCAs
        for label, dca_num in self.dca_labels.items():
            if label in command.lower():
                # Replace label with DCA number and reprocess
                modified_command = command.lower().replace(label, f"dca {dca_num}")
                results.extend(self.process_command(modified_command))
                
        return results
        
    def process_command(self, command: str) -> List[RCPCommand]:
        """Main entry point for processing voice commands"""
        results = []
        command = command.strip()
        
        # Try each processor
        processors = [
            self.process_channel_fader,
            self.process_channel_mute,
            self.process_channel_label,
            self.process_send_to_mix,
            self.process_pan_commands,
            self.process_scene_recall,
            self.process_dca_commands,
            self.process_context_aware,
        ]
        
        for processor in processors:
            try:
                results.extend(processor(command))
            except Exception as e:
                print(f"Error in {processor.__name__}: {e}")
                
        # Remove duplicate commands
        seen = set()
        unique_results = []
        for result in results:
            if result.command not in seen:
                seen.add(result.command)
                unique_results.append(result)
                
        return unique_results
        
    def get_channel_labels(self) -> Dict[str, int]:
        """Get current channel labels"""
        return self.channel_labels.copy()
        
    def get_dca_labels(self) -> Dict[str, int]:
        """Get current DCA labels"""
        return self.dca_labels.copy()


# Example usage and testing
if __name__ == "__main__":
    engine = VoiceCommandEngine()
    
    # Test commands
    test_commands = [
        "Set channel 1 to unity",
        "Mute channel 3",
        "Name channel 5 kick drum",
        "Send channel 1 to mix 3",
        "Pan channel 8 hard left",
        "Recall scene 15",
        "Set DCA 1 to minus 6 dB",
        "Channel 12 to minus 10 dB",
        "Turn off channel 15",
        "Set channel 2 send to mix 1 at minus 6 dB",
    ]
    
    print("Voice Command Engine Test")
    print("=" * 50)
    
    for cmd in test_commands:
        print(f"\nCommand: '{cmd}'")
        results = engine.process_command(cmd)
        if results:
            for result in results:
                print(f"  RCP: {result.command}")
                print(f"  Description: {result.description}")
                print(f"  Confidence: {result.confidence}")
        else:
            print("  No results found")