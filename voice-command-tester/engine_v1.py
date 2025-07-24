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
        
        # Security hardening - input validation limits
        self.MAX_CHANNEL = 40
        self.MAX_MIX = 20
        self.MAX_SCENE = 100
        self.MAX_DCA = 8
        self.MIN_DB = -60
        self.MAX_DB = 10
        self.MAX_INPUT_LENGTH = 200
        
        # Common word variations for numbers (expanded professional usage)
        self.number_words = {
            'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
            'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
            'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
            'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
            'nineteen': 19, 'twenty': 20, 'twenty-one': 21, 'twenty-two': 22,
            'twenty-three': 23, 'twenty-four': 24, 'twenty-five': 25,
            'twenty-six': 26, 'twenty-seven': 27, 'twenty-eight': 28,
            'twenty-nine': 29, 'thirty': 30, 'thirty-one': 31, 'thirty-two': 32,
            'thirty-three': 33, 'thirty-four': 34, 'thirty-five': 35,
            'thirty-six': 36, 'thirty-seven': 37, 'thirty-eight': 38,
            'thirty-nine': 39, 'forty': 40
        }
        
        # Professional audio instrument/source terminology for contextual commands
        self.instrument_aliases = {
            'vocal': 'vocals', 'vox': 'vocals', 'lead vox': 'lead vocal', 'bg vox': 'background vocals',
            'kick': 'kick drum', 'bass drum': 'kick drum', 'bd': 'kick drum',
            'snare': 'snare drum', 'sd': 'snare drum',
            'hi-hat': 'hihat', 'hh': 'hihat', 'hat': 'hihat',
            'overhead': 'overheads', 'oh': 'overheads', 'cymbals': 'overheads',
            'tom': 'toms', 'floor tom': 'floor', 'rack tom': 'rack',
            'bass': 'bass guitar', 'di': 'bass guitar', 'kick': 'bass drum',
            'guitar': 'electric guitar', 'gtr': 'guitar', 'elec': 'electric guitar',
            'acoustic': 'acoustic guitar', 'ac': 'acoustic guitar',
            'keys': 'keyboard', 'kb': 'keyboard', 'piano': 'keyboard',
            'strings': 'strings', 'horns': 'brass', 'brass': 'horns',
            'sax': 'saxophone', 'trumpet': 'horn', 'trombone': 'horn'
        }
        
        # Pan position mapping
        self.pan_positions = {
            'hard left': -63, 'hard_left': -63, 'hardleft': -63,
            'left': -32, 'slightly left': -16, 'slight left': -16,
            'center': 0, 'centre': 0, 'middle': 0,
            'slightly right': 16, 'slight right': 16,
            'right': 32, 'hard right': 63, 'hard_right': 63, 'hardright': 63
        }
        
        # dB value mapping (expanded professional terminology)
        self.db_keywords = {
            'unity': 0, 'zero': 0, 'nominal': 0, 'line level': 0, 'u': 0,
            'minus infinity': -32768, 'negative infinity': -32768, 'inf': -32768,
            'off': -32768, 'down': -32768, 'kill': -32768, 'cut': -32768,
            'hot': 300, 'loud': 300, 'cooking': 300, 'pushing': 300,
            'quiet': -1000, 'low': -1000, 'soft': -1000, 'back': -600,
            'up': 300, 'boost': 600, 'bump': 300, 'push': 300,
            'pull': -300, 'bring down': -600, 'take down': -600,
            'park': -1000, 'set': 0, 'dial in': 0, 'trim': 0
        }
        
        # Professional fader action terminology
        self.fader_actions = {
            'bring up': 'increase', 'pull up': 'increase', 'push up': 'increase',
            'bring down': 'decrease', 'pull down': 'decrease', 'push down': 'decrease',
            'bump up': 'increase', 'bump down': 'decrease', 'nudge up': 'increase',
            'nudge down': 'decrease', 'ride': 'adjust', 'trim': 'adjust',
            'dial in': 'set', 'park': 'set', 'set': 'set', 'put': 'set'
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
        
    def validate_channel(self, num: int) -> bool:
        """Validate channel number is within acceptable range"""
        return 1 <= num <= self.MAX_CHANNEL
        
    def validate_mix(self, num: int) -> bool:
        """Validate mix number is within acceptable range"""
        return 1 <= num <= self.MAX_MIX
        
    def validate_scene(self, num: int) -> bool:
        """Validate scene number is within acceptable range"""
        return 1 <= num <= self.MAX_SCENE
        
    def validate_dca(self, num: int) -> bool:
        """Validate DCA number is within acceptable range"""
        return 1 <= num <= self.MAX_DCA
        
    def validate_db(self, db_value: int) -> int:
        """Clamp dB value to reasonable range"""
        return max(self.MIN_DB * 100, min(self.MAX_DB * 100, db_value))
    
    def get_channel_for_instrument(self, instrument: str) -> Optional[int]:
        """Look up channel number for instrument name from stored labels"""
        instrument_lower = instrument.lower()
        
        # Direct lookup in channel labels
        if instrument_lower in self.channel_labels:
            return self.channel_labels[instrument_lower]
            
        # Check aliases
        if instrument_lower in self.instrument_aliases:
            alias = self.instrument_aliases[instrument_lower]
            if alias.lower() in self.channel_labels:
                return self.channel_labels[alias.lower()]
                
        # Try partial matching for flexibility
        for label, channel in self.channel_labels.items():
            if instrument_lower in label or label in instrument_lower:
                return channel
                
        # For demo purposes, assign some default channels to common instruments
        # In real usage, these would be set via labeling commands
        default_assignments = {
            'vocals': 1, 'vox': 1, 'lead vocal': 1,
            'kick': 2, 'kick drum': 2, 'bass drum': 2, 'bd': 2,
            'snare': 3, 'snare drum': 3, 'sd': 3,
            'hihat': 4, 'hi-hat': 4, 'hh': 4, 'hat': 4,
            'bass': 5, 'bass guitar': 5, 'di': 5,
            'guitar': 6, 'electric guitar': 6, 'gtr': 6,
            'keys': 7, 'keyboard': 7, 'kb': 7, 'piano': 7,
            'acoustic': 8, 'acoustic guitar': 8, 'ac': 8
        }
        
        if instrument_lower in default_assignments:
            return default_assignments[instrument_lower]
            
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
                # Convert to RCP format (multiply by 100) and validate
                db_value = int(value * 100)
                return self.validate_db(db_value)
                
        return None
        
    def process_channel_fader(self, command: str) -> List[RCPCommand]:
        """Process channel fader level commands with comprehensive professional terminology"""
        results = []
        
        # Comprehensive patterns for professional channel fader commands
        patterns = [
            # Standard channel commands
            (r'(?:set\s+)?channel\s+(\d+)\s+(?:to|at|fader\s+to|volume\s+to|level\s+to)\s+(.+)', 'set'),
            (r'(?:put\s+)?channel\s+(\d+)\s+(?:at|to)\s+(.+)', 'set'),
            
            # Professional fader actions
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:channel\s+)?(\d+)(?:\s+to\s+(.+))?', 'bring_up'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:channel\s+)?(\d+)(?:\s+to\s+(.+))?', 'bring_down'),
            (r'(?:bump\s+up|nudge\s+up)\s+(?:channel\s+)?(\d+)(?:\s+(?:by\s+)?(.+))?', 'bump_up'),
            (r'(?:bump\s+down|nudge\s+down)\s+(?:channel\s+)?(\d+)(?:\s+(?:by\s+)?(.+))?', 'bump_down'),
            (r'(?:ride|trim)\s+(?:channel\s+)?(\d+)(?:\s+(?:at|to)\s+(.+))?', 'adjust'),
            (r'(?:dial\s+in|park)\s+(?:channel\s+)?(\d+)(?:\s+(?:at|to)\s+(.+))?', 'set'),
            
            # Instrument-based commands (expanded)
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:the\s+)?(vocals?|vox|lead\s+vox|bg\s+vox|background\s+vocals?)(?:\s+to\s+(.+))?', 'bring_up_instrument'),
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:the\s+)?(kick|bass\s+drum|bd|snare|snare\s+drum|sd)(?:\s+to\s+(.+))?', 'bring_up_instrument'),
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:the\s+)?(hi-hat|hihat|hh|hat|overhead|overheads|oh|cymbals)(?:\s+to\s+(.+))?', 'bring_up_instrument'),
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:the\s+)?(tom|toms|floor\s+tom|rack\s+tom|floor|rack)(?:\s+to\s+(.+))?', 'bring_up_instrument'),
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:the\s+)?(bass|bass\s+guitar|di|guitar|gtr|elec|electric\s+guitar)(?:\s+to\s+(.+))?', 'bring_up_instrument'),
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:the\s+)?(acoustic|acoustic\s+guitar|ac|keys|keyboard|kb|piano)(?:\s+to\s+(.+))?', 'bring_up_instrument'),
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:the\s+)?(strings|horns|brass|sax|saxophone|trumpet|horn|trombone)(?:\s+to\s+(.+))?', 'bring_up_instrument'),
            
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:the\s+)?(vocals?|vox|lead\s+vox|bg\s+vox|background\s+vocals?)(?:\s+to\s+(.+))?', 'bring_down_instrument'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:the\s+)?(kick|bass\s+drum|bd|snare|snare\s+drum|sd)(?:\s+to\s+(.+))?', 'bring_down_instrument'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:the\s+)?(hi-hat|hihat|hh|hat|overhead|overheads|oh|cymbals)(?:\s+to\s+(.+))?', 'bring_down_instrument'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:the\s+)?(tom|toms|floor\s+tom|rack\s+tom|floor|rack)(?:\s+to\s+(.+))?', 'bring_down_instrument'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:the\s+)?(bass|bass\s+guitar|di|guitar|gtr|elec|electric\s+guitar)(?:\s+to\s+(.+))?', 'bring_down_instrument'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:the\s+)?(acoustic|acoustic\s+guitar|ac|keys|keyboard|kb|piano)(?:\s+to\s+(.+))?', 'bring_down_instrument'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:the\s+)?(strings|horns|brass|sax|saxophone|trumpet|horn|trombone)(?:\s+to\s+(.+))?', 'bring_down_instrument'),
            
            # Set instrument levels
            (r'(?:set|put|dial\s+in|park)\s+(?:the\s+)?(vocals?|vox|lead\s+vox|bg\s+vox|background\s+vocals?)\s+(?:at|to)\s+(.+)', 'set_instrument'),
            (r'(?:set|put|dial\s+in|park)\s+(?:the\s+)?(kick|bass\s+drum|bd|snare|snare\s+drum|sd)\s+(?:at|to)\s+(.+)', 'set_instrument'),
            (r'(?:set|put|dial\s+in|park)\s+(?:the\s+)?(hi-hat|hihat|hh|hat|overhead|overheads|oh|cymbals)\s+(?:at|to)\s+(.+)', 'set_instrument'),
            (r'(?:set|put|dial\s+in|park)\s+(?:the\s+)?(tom|toms|floor\s+tom|rack\s+tom|floor|rack)\s+(?:at|to)\s+(.+)', 'set_instrument'),
            (r'(?:set|put|dial\s+in|park)\s+(?:the\s+)?(bass|bass\s+guitar|di|guitar|gtr|elec|electric\s+guitar)\s+(?:at|to)\s+(.+)', 'set_instrument'),
            (r'(?:set|put|dial\s+in|park)\s+(?:the\s+)?(acoustic|acoustic\s+guitar|ac|keys|keyboard|kb|piano)\s+(?:at|to)\s+(.+)', 'set_instrument'),
            (r'(?:set|put|dial\s+in|park)\s+(?:the\s+)?(strings|horns|brass|sax|saxophone|trumpet|horn|trombone)\s+(?:at|to)\s+(.+)', 'set_instrument'),
            
            # Alternative channel syntax
            (r'channel\s+(\d+)\s+(?:up|down)\s+(\d+)\s*(?:db)?', 'relative'),
            (r'channel\s+(\d+)\s+(?:fader|level|volume)\s+(.+)', 'set'),
            (r'(?:ch|ch\.)\s*(\d+)\s+(?:to|at)\s+(.+)', 'set'),  # Abbreviated channel
            
            # Gain/trim commands (separate from fader)
            (r'(?:trim|gain)\s+(?:channel\s+)?(\d+)(?:\s+(?:to|at)\s+(.+))?', 'gain'),
            (r'(?:set\s+)?(?:channel\s+)?(\d+)\s+(?:trim|gain)\s+(?:to\s+)?(.+)', 'gain'),
            
            # Professional slang variations
            (r'(?:crank|slam|smash)\s+(?:channel\s+)?(\d+)', 'hot'),  # Push loud
            (r'(?:bury|lose|ditch)\s+(?:channel\s+)?(\d+)', 'bury'),  # Pull way down
            (r'(?:cooking|hot|loud)\s+(?:channel\s+)?(\d+)', 'hot'),  # Running hot
            (r'(?:quiet|soft|back)\s+(?:channel\s+)?(\d+)', 'quiet'),  # Pull back
        ]
        
        for pattern, action in patterns:
            match = re.search(pattern, command.lower())
            if match:
                # Handle instrument-based commands
                if 'instrument' in action:
                    instrument = match.group(1)
                    # Look up channel number for this instrument from labels
                    channel_num = self.get_channel_for_instrument(instrument)
                    if not channel_num:
                        continue  # Unknown instrument, skip
                    level_text = match.group(2) if len(match.groups()) > 1 and match.group(2) else None
                else:
                    channel_num = self.parse_number(match.group(1))
                    level_text = match.group(2) if len(match.groups()) > 1 else None
                
                if channel_num is None or not self.validate_channel(channel_num):
                    continue
                    
                channel_idx = channel_num - 1  # Convert to 0-based index
                
                # Process different action types
                if action == 'set':
                    db_value = self.parse_db_value(level_text)
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Set channel {channel_num} fader to {db_value/100:.1f} dB"
                        ))
                        
                elif action in ['bring_up', 'bring_up_instrument']:
                    if level_text:
                        db_value = self.parse_db_value(level_text)
                    else:
                        db_value = 300  # Default +3dB boost
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Bring up channel {channel_num} to {db_value/100:.1f} dB"
                        ))
                        
                elif action in ['bring_down', 'bring_down_instrument']:
                    if level_text:
                        db_value = self.parse_db_value(level_text)
                    else:
                        db_value = -600  # Default -6dB reduction
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Bring down channel {channel_num} to {db_value/100:.1f} dB"
                        ))
                        
                elif action == 'bump_up':
                    if level_text:
                        db_change = self.parse_db_value(level_text)
                    else:
                        db_change = 300  # Default +3dB bump
                    results.append(RCPCommand(
                        f"# GET current level, then add {db_change/100:.1f} dB",
                        f"Bump up channel {channel_num} by {db_change/100:.1f} dB",
                        0.8
                    ))
                    
                elif action == 'bump_down':
                    if level_text:
                        db_change = self.parse_db_value(level_text)
                    else:
                        db_change = -300  # Default -3dB bump
                    results.append(RCPCommand(
                        f"# GET current level, then subtract {abs(db_change)/100:.1f} dB",
                        f"Bump down channel {channel_num} by {abs(db_change)/100:.1f} dB",
                        0.8
                    ))
                    
                elif action == 'adjust':
                    if level_text:
                        db_value = self.parse_db_value(level_text)
                        if db_value is not None:
                            results.append(RCPCommand(
                                f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                                f"Adjust channel {channel_num} to {db_value/100:.1f} dB"
                            ))
                    else:
                        results.append(RCPCommand(
                            f"# Manual adjustment mode for channel {channel_num}",
                            f"Ready to adjust channel {channel_num}",
                            0.9
                        ))
                        
                elif action == 'gain':
                    if level_text:
                        db_value = self.parse_db_value(level_text)
                        if db_value is not None:
                            # Note: This would be gain/trim, not fader level
                            results.append(RCPCommand(
                                f"# set MIXER:Current/InCh/Head/Gain {channel_idx} 0 {db_value}",
                                f"Set channel {channel_num} gain to {db_value/100:.1f} dB",
                                0.7  # Lower confidence - gain control not fully implemented
                            ))
                    else:
                        results.append(RCPCommand(
                            f"# Adjust gain/trim for channel {channel_num}",
                            f"Adjust gain on channel {channel_num}",
                            0.7
                        ))
                        
                elif action == 'hot':
                    # Push loud/hot
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 300",
                        f"Push channel {channel_num} hot (+3.0 dB)"
                    ))
                    
                elif action == 'bury':
                    # Pull way down
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 -1500",
                        f"Bury channel {channel_num} (-15.0 dB)"
                    ))
                    
                elif action == 'quiet':
                    # Pull back/quiet
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 -1000",
                        f"Pull channel {channel_num} back (-10.0 dB)"
                    ))
                    
                elif action == 'set_instrument':
                    db_value = self.parse_db_value(level_text)
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Set {match.group(1)} to {db_value/100:.1f} dB"
                        ))
                        
                elif action == 'relative':
                    # Handle relative changes
                    change = self.parse_number(level_text)
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
        """Process channel mute/unmute commands with professional terminology"""
        results = []
        
        # Comprehensive patterns for professional mute commands
        patterns = [
            # Standard mute commands with channel numbers
            (r'(?:mute|kill|cut|silence|turn\s+off|shut\s+off|disable)\s+channel\s+(\d+)', 0),
            (r'(?:unmute|restore|open|activate|turn\s+on|enable|bring\s+back)\s+channel\s+(\d+)', 1),
            (r'channel\s+(\d+)\s+(?:on|unmute|open|active)', 1),
            (r'channel\s+(\d+)\s+(?:off|mute|killed?|cut)', 0),
            (r'(?:ch|ch\.)\s*(\d+)\s+(?:mute|off)', 0),  # Abbreviated
            (r'(?:ch|ch\.)\s*(\d+)\s+(?:unmute|on)', 1),
            
            # Professional slang variations
            (r'(?:lose|ditch|bury|dump)\s+channel\s+(\d+)', 0),  # Mute slang
            (r'(?:solo\s+off|unsolo)\s+channel\s+(\d+)', 1),  # Unsolo = unmute in some contexts
            (r'(?:safe|protect)\s+channel\s+(\d+)', 0),  # Mute for protection
            
            # Instrument-based mute commands
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(vocals?|vox|lead\s+vox|bg\s+vox|background\s+vocals?)', 0, 'instrument'),
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(kick|bass\s+drum|bd|snare|snare\s+drum|sd)', 0, 'instrument'),
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(hi-hat|hihat|hh|hat|overhead|overheads|oh|cymbals)', 0, 'instrument'),
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(tom|toms|floor\s+tom|rack\s+tom|floor|rack)', 0, 'instrument'),
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(bass|bass\s+guitar|di|guitar|gtr|elec|electric\s+guitar)', 0, 'instrument'),
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(acoustic|acoustic\s+guitar|ac|keys|keyboard|kb|piano)', 0, 'instrument'),
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(strings|horns|brass|sax|saxophone|trumpet|horn|trombone)', 0, 'instrument'),
            
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(vocals?|vox|lead\s+vox|bg\s+vox|background\s+vocals?)', 1, 'instrument'),
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(kick|bass\s+drum|bd|snare|snare\s+drum|sd)', 1, 'instrument'),
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(hi-hat|hihat|hh|hat|overhead|overheads|oh|cymbals)', 1, 'instrument'),
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(tom|toms|floor\s+tom|rack\s+tom|floor|rack)', 1, 'instrument'),
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(bass|bass\s+guitar|di|guitar|gtr|elec|electric\s+guitar)', 1, 'instrument'),
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(acoustic|acoustic\s+guitar|ac|keys|keyboard|kb|piano)', 1, 'instrument'),
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(strings|horns|brass|sax|saxophone|trumpet|horn|trombone)', 1, 'instrument'),
            
            # Group mute commands
            (r'(?:mute|kill)\s+(?:all\s+)?(?:drums|percussion)', 0, 'group'),
            (r'(?:mute|kill)\s+(?:all\s+)?(?:vocals?|voices)', 0, 'group'),
            (r'(?:mute|kill)\s+(?:all\s+)?(?:guitars?|gtrs)', 0, 'group'),
            (r'(?:unmute|restore)\s+(?:all\s+)?(?:drums|percussion)', 1, 'group'),
            (r'(?:unmute|restore)\s+(?:all\s+)?(?:vocals?|voices)', 1, 'group'),
            (r'(?:unmute|restore)\s+(?:all\s+)?(?:guitars?|gtrs)', 1, 'group'),
            
            # Monitor-specific mute commands
            (r'(?:mute|kill)\s+(?:monitor|mon|wedge)\s+(\d+)', 0, 'monitor'),
            (r'(?:unmute|restore)\s+(?:monitor|mon|wedge)\s+(\d+)', 1, 'monitor'),
        ]
        
        for pattern in patterns:
            if len(pattern) == 3:
                pattern_text, state, command_type = pattern
            else:
                pattern_text, state = pattern
                command_type = 'channel'
                
            match = re.search(pattern_text, command.lower())
            if match:
                if command_type == 'instrument':
                    # Handle instrument-based mute commands
                    instrument = match.group(1)
                    channel_num = self.get_channel_for_instrument(instrument)
                    if not channel_num:
                        continue
                    channel_idx = channel_num - 1
                    state_text = "on" if state == 1 else "off"
                    action_text = "Unmute" if state == 1 else "Mute"
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/On {channel_idx} 0 {state}",
                        f"{action_text} {instrument} (channel {channel_num})"
                    ))
                    
                elif command_type == 'group':
                    # Handle group mute commands (would need group membership info)
                    group_name = 'drums' if 'drum' in command.lower() else 'vocals' if 'vocal' in command.lower() else 'guitars'
                    action_text = "Unmute" if state == 1 else "Mute"
                    results.append(RCPCommand(
                        f"# {action_text} all {group_name} channels (requires group implementation)",
                        f"{action_text} all {group_name}",
                        0.6  # Lower confidence - group operations not fully implemented
                    ))
                    
                elif command_type == 'monitor':
                    # Handle monitor mute commands
                    monitor_num = self.parse_number(match.group(1))
                    if monitor_num and self.validate_mix(monitor_num):
                        mix_idx = monitor_num - 1
                        state_text = "on" if state == 1 else "off"
                        action_text = "Unmute" if state == 1 else "Mute"
                        results.append(RCPCommand(
                            f"set MIXER:Current/Mix/Fader/On {mix_idx} 0 {state}",
                            f"{action_text} monitor {monitor_num}"
                        ))
                        
                else:  # Standard channel command
                    channel_num = self.parse_number(match.group(1))
                    if channel_num and self.validate_channel(channel_num):
                        channel_idx = channel_num - 1
                        state_text = "on" if state == 1 else "off"
                        action_text = "Unmute" if state == 1 else "Mute"
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/On {channel_idx} 0 {state}",
                            f"{action_text} channel {channel_num}"
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
                if channel_num and self.validate_channel(channel_num):
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
        """Process send to mix commands with comprehensive professional terminology"""
        results = []
        
        # Comprehensive patterns for professional routing/send commands
        patterns = [
            # Standard channel-to-mix routing
            (r'(?:send|route|add|patch|feed|mult)\s+channel\s+(\d+)\s+to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\d+)', 'on'),
            (r'(?:send|route|add|patch|feed)\s+(?:ch|ch\.)\s*(\d+)\s+to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\d+)', 'on'),
            
            # Professional routing terminology
            (r'(?:patch|route|assign)\s+channel\s+(\d+)\s+(?:into|to)\s+(?:aux|send|bus)\s+(\d+)', 'on'),
            (r'(?:tie|connect|link)\s+channel\s+(\d+)\s+(?:to|with)\s+(?:mix|aux|monitor)\s+(\d+)', 'on'),
            (r'(?:mult|split|feed)\s+channel\s+(\d+)\s+(?:to|into)\s+(?:mix|aux|monitor)\s+(\d+)', 'on'),
            
            # UK terminology (foldback = monitors)
            (r'(?:send|route|add)\s+channel\s+(\d+)\s+to\s+(?:foldback|fb)\s+(\d+)', 'on'),
            
            # Turn on/off routing
            (r'(?:turn\s+)?(?:on|enable|activate)\s+channel\s+(\d+)\s+(?:send\s+)?to\s+(?:mix|aux|monitor)\s+(\d+)', 'on'),
            (r'(?:turn\s+)?(?:off|disable|kill|remove)\s+channel\s+(\d+)\s+(?:send\s+)?(?:to|from)\s+(?:mix|aux|monitor)\s+(\d+)', 'off'),
            
            # Send with level (expanded)
            (r'(?:set\s+)?channel\s+(\d+)\s+(?:send\s+)?to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\d+)\s+(?:at|to|level)\s+(.+)', 'level'),
            (r'(?:send|route)\s+channel\s+(\d+)\s+to\s+(?:mix|aux|monitor)\s+(\d+)\s+at\s+(.+)', 'level'),
            (r'channel\s+(\d+)\s+to\s+(?:mix|aux|monitor)\s+(\d+)\s+at\s+(.+)', 'level'),
            (r'(?:patch|feed)\s+channel\s+(\d+)\s+(?:into|to)\s+(?:mix|aux)\s+(\d+)\s+at\s+(.+)', 'level'),
            
            # Instrument-based routing
            (r'(?:send|route|add|patch|feed)\s+(?:the\s+)?(vocals?|vox|lead\s+vox|bg\s+vox)\s+to\s+(?:mix|aux|monitor|mon|wedge)\s+(\d+)(?:\s+at\s+(.+))?', 'instrument'),
            (r'(?:send|route|add|patch|feed)\s+(?:the\s+)?(kick|bass\s+drum|bd|snare|snare\s+drum|sd)\s+to\s+(?:mix|aux|monitor|mon|wedge)\s+(\d+)(?:\s+at\s+(.+))?', 'instrument'),
            (r'(?:send|route|add|patch|feed)\s+(?:the\s+)?(hi-hat|hihat|hh|hat|overhead|overheads|oh)\s+to\s+(?:mix|aux|monitor|mon|wedge)\s+(\d+)(?:\s+at\s+(.+))?', 'instrument'),
            (r'(?:send|route|add|patch|feed)\s+(?:the\s+)?(tom|toms|floor\s+tom|rack\s+tom|floor|rack)\s+to\s+(?:mix|aux|monitor|mon|wedge)\s+(\d+)(?:\s+at\s+(.+))?', 'instrument'),
            (r'(?:send|route|add|patch|feed)\s+(?:the\s+)?(bass|bass\s+guitar|di|guitar|gtr|elec)\s+to\s+(?:mix|aux|monitor|mon|wedge)\s+(\d+)(?:\s+at\s+(.+))?', 'instrument'),
            (r'(?:send|route|add|patch|feed)\s+(?:the\s+)?(acoustic|ac|keys|keyboard|kb|piano)\s+to\s+(?:mix|aux|monitor|mon|wedge)\s+(\d+)(?:\s+at\s+(.+))?', 'instrument'),
            
            # Monitor-specific terminology
            (r'(?:add|send|give)\s+(?:the\s+)?(vocals?|vox|lead\s+vox)\s+to\s+(?:the\s+)?(?:singer|vocalist)(?:\'s)?\s+(?:mix|monitor|wedge|ears)', 'vocalist_monitor'),
            (r'(?:add|send|give)\s+(?:the\s+)?(kick|snare|drums)\s+to\s+(?:the\s+)?(?:drummer|drum)(?:\'s)?\s+(?:mix|monitor|wedge|ears)', 'drummer_monitor'),
            (r'(?:add|send|give)\s+(?:the\s+)?(guitar|bass)\s+to\s+(?:the\s+)?(?:guitarist|bassist)(?:\'s)?\s+(?:mix|monitor|wedge|ears)', 'musician_monitor'),
            
            # IEM-specific routing
            (r'(?:send|route|add)\s+(?:the\s+)?(vocals?|vox|instruments?)\s+to\s+(?:the\s+)?(?:IEM|IEMs|in-ears?|ears)\s+(?:mix\s+)?(\d+)', 'iem'),
            (r'(?:patch|feed)\s+(?:the\s+)?(vocals?|instruments?)\s+(?:into|to)\s+(?:IEM|in-ear)\s+(?:mix\s+)?(\d+)', 'iem'),
            
            # Pre/post fader routing (advanced)
            (r'(?:send|route)\s+channel\s+(\d+)\s+(?:pre|post)\s+(?:fader\s+)?to\s+(?:mix|aux)\s+(\d+)', 'pre_post'),
            (r'(?:pre|post)\s+(?:fader\s+)?(?:send|route)\s+channel\s+(\d+)\s+to\s+(?:mix|aux)\s+(\d+)', 'pre_post'),
            
            # Matrix routing (advanced mixing)
            (r'(?:send|route)\s+(?:mix|aux)\s+(\d+)\s+to\s+(?:matrix|mtx)\s+(\d+)', 'matrix'),
            (r'(?:patch|feed)\s+(?:mix|aux)\s+(\d+)\s+(?:into|to)\s+(?:matrix|mtx)\s+(\d+)', 'matrix'),
            
            # Group/bus routing
            (r'(?:send|route|assign)\s+channel\s+(\d+)\s+to\s+(?:group|subgroup|sub|bus)\s+(\d+)', 'group'),
            (r'(?:add|assign)\s+channel\s+(\d+)\s+(?:to|into)\s+(?:group|subgroup|sub)\s+(\d+)', 'group'),
            
            # Remove/disconnect routing
            (r'(?:remove|disconnect|unroute|kill)\s+channel\s+(\d+)\s+(?:from|to)\s+(?:mix|aux|monitor)\s+(\d+)', 'off'),
            (r'(?:unpatch|disconnect)\s+channel\s+(\d+)\s+(?:from|to)\s+(?:mix|aux)\s+(\d+)', 'off'),
            
            # Professional slang
            (r'(?:throw|blast|pump)\s+(?:the\s+)?(vocals?|kick|snare)\s+(?:to|into)\s+(?:mix|aux|monitor)\s+(\d+)', 'instrument_slang'),
            (r'(?:crank|slam)\s+(?:the\s+)?(vocals?|drums)\s+(?:in|into)\s+(?:the\s+)?(?:wedges?|monitors?)', 'monitor_slang'),
        ]
        
        for pattern, action in patterns:
            match = re.search(pattern, command.lower())
            if match:
                if action == 'instrument':
                    # Handle instrument-based routing
                    instrument = match.group(1)
                    channel_num = self.get_channel_for_instrument(instrument)
                    if not channel_num:
                        continue
                    mix_num = self.parse_number(match.group(2))
                    level_text = match.group(3) if len(match.groups()) > 2 and match.group(3) else None
                    
                    if mix_num and self.validate_mix(mix_num):
                        channel_idx = channel_num - 1
                        mix_idx = mix_num - 1
                        
                        # Turn on the send
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 1",
                            f"Send {instrument} to mix {mix_num}"
                        ))
                        
                        # Set level if specified
                        if level_text:
                            db_value = self.parse_db_value(level_text)
                            if db_value is not None:
                                results.append(RCPCommand(
                                    f"set MIXER:Current/InCh/ToMix/Level {channel_idx} {mix_idx} {db_value}",
                                    f"Set {instrument} send to mix {mix_num} at {db_value/100:.1f} dB"
                                ))
                                
                elif action in ['vocalist_monitor', 'drummer_monitor', 'musician_monitor']:
                    # Handle performer-specific monitor requests
                    instrument = match.group(1)
                    channel_num = self.get_channel_for_instrument(instrument)
                    if not channel_num:
                        continue
                    
                    # For demo, assume performer monitors are on mix 1-4
                    performer_type = action.split('_')[0]
                    default_mixes = {'vocalist': 1, 'drummer': 2, 'musician': 3}
                    mix_num = default_mixes.get(performer_type, 1)
                    
                    channel_idx = channel_num - 1
                    mix_idx = mix_num - 1
                    
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 1",
                        f"Add {instrument} to {performer_type}'s monitor (mix {mix_num})"
                    ))
                    
                elif action == 'iem':
                    # Handle IEM routing
                    instrument = match.group(1)
                    channel_num = self.get_channel_for_instrument(instrument)
                    if not channel_num:
                        continue
                    iem_num = self.parse_number(match.group(2))
                    
                    if iem_num and self.validate_mix(iem_num):
                        channel_idx = channel_num - 1
                        mix_idx = iem_num - 1
                        
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 1",
                            f"Route {instrument} to IEM mix {iem_num}"
                        ))
                        
                elif action == 'pre_post':
                    # Handle pre/post fader routing
                    channel_num = self.parse_number(match.group(1))
                    mix_num = self.parse_number(match.group(2))
                    
                    if channel_num and mix_num and self.validate_channel(channel_num) and self.validate_mix(mix_num):
                        channel_idx = channel_num - 1
                        mix_idx = mix_num - 1
                        pre_post = 'pre' if 'pre' in command.lower() else 'post'
                        
                        results.append(RCPCommand(
                            f"# set MIXER:Current/InCh/ToMix/PreOn {channel_idx} {mix_idx} {1 if pre_post == 'pre' else 0}",
                            f"Set channel {channel_num} to mix {mix_num} {pre_post}-fader",
                            0.8  # Lower confidence - advanced feature
                        ))
                        
                elif action == 'matrix':
                    # Handle matrix routing
                    source_mix = self.parse_number(match.group(1))
                    dest_matrix = self.parse_number(match.group(2))
                    
                    if source_mix and dest_matrix and self.validate_mix(source_mix):
                        source_idx = source_mix - 1
                        matrix_idx = dest_matrix - 1
                        
                        results.append(RCPCommand(
                            f"# set MIXER:Current/Mix/ToMatrix/On {source_idx} {matrix_idx} 1",
                            f"Route mix {source_mix} to matrix {dest_matrix}",
                            0.7  # Lower confidence - advanced feature
                        ))
                        
                elif action == 'group':
                    # Handle group/subgroup routing
                    channel_num = self.parse_number(match.group(1))
                    group_num = self.parse_number(match.group(2))
                    
                    if channel_num and group_num and self.validate_channel(channel_num):
                        channel_idx = channel_num - 1
                        group_idx = group_num - 1
                        
                        results.append(RCPCommand(
                            f"# set MIXER:Current/InCh/ToGroup/On {channel_idx} {group_idx} 1",
                            f"Assign channel {channel_num} to group {group_num}",
                            0.8  # Lower confidence - not fully implemented
                        ))
                        
                elif action in ['instrument_slang', 'monitor_slang']:
                    # Handle professional slang routing
                    instrument = match.group(1) if len(match.groups()) > 0 else 'input'
                    channel_num = self.get_channel_for_instrument(instrument)
                    
                    if channel_num:
                        channel_idx = channel_num - 1
                        # Assume slang means "send hot to main monitors"
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} 0 1",
                            f"Pump {instrument} into monitors (slang command)"
                        ))
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/Level {channel_idx} 0 300",
                            f"Set {instrument} monitor send hot (+3.0 dB)"
                        ))
                        
                else:
                    # Handle standard channel routing
                    channel_num = self.parse_number(match.group(1))
                    mix_num = self.parse_number(match.group(2))
                    
                    if channel_num and mix_num and self.validate_channel(channel_num) and self.validate_mix(mix_num):
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
                        elif action == 'level':
                            level_text = match.group(3) if len(match.groups()) > 2 else None
                            if level_text:
                                db_value = self.parse_db_value(level_text)
                                if db_value is not None:
                                    # Turn on send first
                                    results.append(RCPCommand(
                                        f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 1",
                                        f"Turn on channel {channel_num} send to mix {mix_num}"
                                    ))
                                    # Set level
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
                            
                if channel_num and pan_value is not None and self.validate_channel(channel_num):
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
                        
                if channel_num and mix_num and pan_value is not None and self.validate_channel(channel_num) and self.validate_mix(mix_num):
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
                if scene_num and self.validate_scene(scene_num):
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
                if dca_num and self.validate_dca(dca_num):
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
                if dca_num and self.validate_dca(dca_num):
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
                if dca_num and self.validate_dca(dca_num):
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
                # Replace label with channel number and process with specific processors
                modified_command = command.lower().replace(label, f"channel {channel_num}")
                # Only use non-context processors to avoid recursion
                for processor in [self.process_channel_fader, self.process_channel_mute, 
                                self.process_send_to_mix, self.process_pan_commands]:
                    try:
                        results.extend(processor(modified_command))
                    except Exception as e:
                        print(f"Error in {processor.__name__}: {e}")
                
        # Check for labeled DCAs
        for label, dca_num in self.dca_labels.items():
            if label in command.lower():
                # Replace label with DCA number and process with DCA processor
                modified_command = command.lower().replace(label, f"dca {dca_num}")
                try:
                    results.extend(self.process_dca_commands(modified_command))
                except Exception as e:
                    print(f"Error in process_dca_commands: {e}")
                
        return results
        
    def process_command(self, command: str) -> List[RCPCommand]:
        """Main entry point for processing voice commands"""
        results = []
        command = command.strip()
        
        # Security: Validate input length
        if len(command) > self.MAX_INPUT_LENGTH:
            return []  # Reject overly long inputs
        
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