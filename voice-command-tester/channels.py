#!/usr/bin/env python3
"""
Channel Processing Module for Voice Command Engine
Handles all channel-related voice commands (faders, muting, labeling)
"""

import re
from typing import List, Optional
from dataclasses import dataclass
from terms import ProfessionalAudioTerms

@dataclass
class RCPCommand:
    """Represents a Yamaha RCP command"""
    command: str
    description: str
    confidence: float = 1.0

class ChannelProcessor:
    """Processes channel-related voice commands"""
    
    def __init__(self, terms: ProfessionalAudioTerms, validation_limits: dict):
        self.terms = terms
        self.validation_limits = validation_limits
        self.channel_labels = {}  # Store channel labels for context-aware commands
        
    def validate_channel(self, num: int) -> bool:
        """Validate channel number is within acceptable range"""
        return 1 <= num <= self.validation_limits['MAX_CHANNEL']
        
    def validate_db(self, db_value: int) -> int:
        """Clamp dB value to reasonable range"""
        return max(self.validation_limits['MIN_DB'] * 100, 
                  min(self.validation_limits['MAX_DB'] * 100, db_value))
    
    def get_channel_for_instrument(self, instrument: str) -> Optional[int]:
        """Look up channel number for instrument name from stored labels"""
        instrument_lower = instrument.lower()
        
        # Direct lookup in channel labels
        if instrument_lower in self.channel_labels:
            return self.channel_labels[instrument_lower]
            
        # Check aliases
        if instrument_lower in self.terms.instrument_aliases:
            alias = self.terms.instrument_aliases[instrument_lower]
            if alias.lower() in self.channel_labels:
                return self.channel_labels[alias.lower()]
                
        # Try partial matching for flexibility
        for label, channel in self.channel_labels.items():
            if instrument_lower in label or label in instrument_lower:
                return channel
                
        # Use default assignments for demo
        default_assignments = self.terms.get_default_instrument_channels()
        if instrument_lower in default_assignments:
            return default_assignments[instrument_lower]
            
        return None

    def parse_number(self, text: str) -> Optional[int]:
        """Parse a number from text, handling both digits and words"""
        # Try direct integer conversion
        try:
            return int(text)
        except ValueError:
            pass
            
        # Try word to number conversion
        text_lower = text.lower()
        if text_lower in self.terms.number_words:
            return self.terms.number_words[text_lower]
            
        return None
        
    def parse_db_value(self, text: str) -> Optional[int]:
        """Parse a dB value from text"""
        if not text:
            return None
            
        # Check for special keywords first
        text_lower = text.lower()
        for keyword, value in self.terms.db_keywords.items():
            if keyword in text_lower:
                return value
                
        # Parse numeric dB values
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
            # Professional slang variations (MUST be first - most specific)
            (r'(?:crank|slam|smash)\s+(?:channel|ch|track|trk)\s+(\d+)(?:\s+(?:to|at)\s+(.+))?', 'crank'),  # Aggressive level setting
            (r'(?:bury|lose|ditch)\s+(?:channel\s+)?(\d+)', 'bury'),  # Pull way down
            (r'(?:cooking|hot|loud)\s+(?:channel\s+)?(\d+)', 'hot'),  # Running hot
            (r'(?:quiet|soft|back)\s+(?:channel\s+)?(\d+)', 'quiet'),  # Pull back
            
            # Standard channel commands (support words and digits)
            (r'(?:set\s+)?channel\s+(\w+)\s+(?:to|at|fader\s+to|volume\s+to|level\s+to)\s+(.+)', 'set'),
            (r'(?:put\s+)?channel\s+(\w+)\s+(?:at|to)\s+(.+)', 'set'),
            (r'(?:set\s+)?(?:track|trk)\s+(\w+)\s+(?:to|at|level\s+to)\s+(.+)', 'set'),
            
            # Professional fader actions (channel and track)
            (r'(?:bring\s+up|pull\s+up|push\s+up)\s+(?:channel|ch|track|trk)\s+(\w+)(?:\s+to\s+(.+))?', 'bring_up'),
            (r'(?:bring\s+down|pull\s+down|push\s+down)\s+(?:channel|ch|track|trk)\s+(\w+)(?:\s+to\s+(.+))?', 'bring_down'),
            
            # Track-specific commands (missing patterns)
            (r'(?:track|trk)\s+(\w+)\s+up\s+(\w+)\s*(?:db|decibels?)?', 'relative_up'),
            (r'(?:track|trk)\s+(\w+)\s+down\s+(?:by\s+)?(\w+)\s*(?:db|decibels?)?', 'relative_down'),
            (r'(?:boost|bump)\s+(?:channel|track)\s+(\w+)\s+(?:by\s+)?(\w+)\s*(?:db)?', 'boost'),
            (r'(?:pull|bring)\s+(?:the\s+)?(\w+)\s+down\s+(\w+)\s*(?:db)?', 'pull_down_instrument'),
            (r'(?:vocal|vocals)\s+track\s+up\s+(\w+)\s*(?:decibels?|db)?', 'vocal_up'),
            (r'(?:bass|kick|snare|guitar|piano)\s+channel\s+to\s+(.+)', 'instrument_to_level'),
            
            # Fader and input terminology
            (r'(?:fader|input)\s+(\w+)\s+(?:to|at)\s+(.+)', 'fader_set'),
            (r'(?:input)\s+(\w+)\s+(?:down\s+to|up\s+to)\s+(.+)', 'input_adjust'),
            (r'(?:push|ride|slam)\s+(?:the\s+)?(\w+)', 'push_action'),
            (r'(?:push|ride)\s+(?:track|channel)\s+(\w+)\s+(?:a\s+bit|slightly)', 'push_slight'),
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
            
        ]
        
        for pattern, action in patterns:
            match = re.search(pattern, command.lower())
            if match:
                # Handle instrument-based commands
                if 'instrument' in action:
                    instrument = match.group(1)
                    channel_num = self.get_channel_for_instrument(instrument)
                    if not channel_num:
                        continue
                    level_text = match.group(2) if len(match.groups()) > 1 and match.group(2) else None
                else:
                    channel_num = self.parse_number(match.group(1))
                    level_text = match.group(2) if len(match.groups()) > 1 else None
                
                if channel_num is None or not self.validate_channel(channel_num):
                    continue
                    
                channel_idx = channel_num - 1
                
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
                            results.append(RCPCommand(
                                f"# set MIXER:Current/InCh/Head/Gain {channel_idx} 0 {db_value}",
                                f"Set channel {channel_num} gain to {db_value/100:.1f} dB",
                                0.7
                            ))
                    else:
                        results.append(RCPCommand(
                            f"# Adjust gain/trim for channel {channel_num}",
                            f"Adjust gain on channel {channel_num}",
                            0.7
                        ))
                        
                elif action == 'hot':
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 300",
                        f"Push channel {channel_num} hot (+3.0 dB)"
                    ))
                    
                elif action == 'bury':
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 -1500",
                        f"Bury channel {channel_num} (-15.0 dB)"
                    ))
                    
                elif action == 'quiet':
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 -1000",
                        f"Pull channel {channel_num} back (-10.0 dB)"
                    ))
                    
                elif action == 'crank':
                    # Handle "crank" with optional level specification
                    if len(match.groups()) > 1 and match.group(2):
                        level_text = match.group(2)
                        db_value = self.parse_db_value(level_text)
                        if db_value is not None:
                            results.append(RCPCommand(
                                f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                                f"Crank channel {channel_num} to {db_value/100:.1f} dB"
                            ))
                        else:
                            # Default crank behavior (hot)
                            results.append(RCPCommand(
                                f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 300",
                                f"Crank channel {channel_num} hot (+3.0 dB)"
                            ))
                    else:
                        # Default crank behavior (hot)
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 300",
                            f"Crank channel {channel_num} hot (+3.0 dB)"
                        ))
                    
                elif action == 'set_instrument':
                    db_value = self.parse_db_value(level_text)
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Set {match.group(1)} to {db_value/100:.1f} dB"
                        ))
                        
                elif action == 'relative':
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
                            
                elif action == 'relative_up':
                    db_change = self.parse_number(level_text)
                    if db_change:
                        db_value = db_change * 100  # Convert to RCP format
                        results.append(RCPCommand(
                            f"# GET current level first, then add {db_change} dB",
                            f"Track {channel_num} up {db_change} dB",
                            0.9
                        ))
                        
                elif action == 'relative_down':
                    db_change = self.parse_number(level_text)
                    if db_change:
                        db_value = -db_change * 100  # Convert to RCP format (negative)
                        results.append(RCPCommand(
                            f"# GET current level first, then subtract {db_change} dB",
                            f"Track {channel_num} down {db_change} dB",
                            0.9
                        ))
                        
                elif action == 'boost':
                    db_change = self.parse_number(level_text) if level_text else 6  # Default 6dB boost
                    if db_change:
                        db_value = db_change * 100
                        results.append(RCPCommand(
                            f"# GET current level first, then add {db_change} dB",
                            f"Boost channel {channel_num} by {db_change} dB",
                            0.9
                        ))
                        
                elif action == 'pull_down_instrument':
                    instrument = match.group(1)
                    db_change = self.parse_number(match.group(2)) if len(match.groups()) > 1 else 3
                    channel_num = self.get_channel_for_instrument(instrument)
                    if channel_num:
                        channel_idx = channel_num - 1
                        db_value = -db_change * 100  # Negative for pulling down
                        results.append(RCPCommand(
                            f"# GET current level first, then subtract {db_change} dB",
                            f"Pull {instrument} down {db_change} dB",
                            0.9
                        ))
                        
                elif action == 'vocal_up':
                    db_change = self.parse_number(match.group(1)) if match.group(1) else 4
                    vocal_channel = self.get_channel_for_instrument('vocals')
                    if vocal_channel:
                        channel_idx = vocal_channel - 1
                        db_value = db_change * 100
                        results.append(RCPCommand(
                            f"# GET current level first, then add {db_change} dB",
                            f"Vocal track up {db_change} dB",
                            0.9
                        ))
                        
                elif action == 'instrument_to_level':
                    instrument = None
                    # Extract instrument from pattern match
                    if 'bass' in command.lower():
                        instrument = 'bass'
                    elif 'kick' in command.lower():
                        instrument = 'kick'
                    elif 'snare' in command.lower():
                        instrument = 'snare'
                    elif 'guitar' in command.lower():
                        instrument = 'guitar'
                    elif 'piano' in command.lower():
                        instrument = 'piano'
                    
                    if instrument:
                        db_value = self.parse_db_value(level_text)
                        if db_value is not None:
                            inst_channel = self.get_channel_for_instrument(instrument)
                            if inst_channel:
                                channel_idx = inst_channel - 1
                                results.append(RCPCommand(
                                    f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                                    f"Set {instrument} to {db_value/100:.1f} dB"
                                ))
                                
                elif action == 'fader_set':
                    db_value = self.parse_db_value(level_text)
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Set fader {channel_num} to {db_value/100:.1f} dB"
                        ))
                        
                elif action == 'input_adjust':
                    db_value = self.parse_db_value(level_text)
                    if db_value is not None:
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/Level {channel_idx} 0 {db_value}",
                            f"Set input {channel_num} to {db_value/100:.1f} dB"
                        ))
                        
                elif action == 'push_action':
                    instrument = match.group(1)
                    if instrument in ['vocal', 'vocals', 'guitar', 'lead', 'bass', 'kick', 'snare']:
                        inst_channel = self.get_channel_for_instrument(instrument)
                        if inst_channel:
                            channel_idx = inst_channel - 1
                            results.append(RCPCommand(
                                f"# Manual adjustment mode for {instrument}",
                                f"Ready to push {instrument} fader",
                                0.8
                            ))
                            
                elif action == 'push_slight':
                    db_value = 200  # +2dB slight push
                    results.append(RCPCommand(
                        f"# GET current level first, then add 2 dB",
                        f"Push track {channel_num} slightly (+2 dB)",
                        0.8
                    ))
                            
        return results

    def process_channel_mute(self, command: str) -> List[RCPCommand]:
        """Process channel mute/unmute commands with professional terminology"""
        results = []
        
        # Comprehensive patterns for professional mute commands
        patterns = [
            # Standard mute commands with channel numbers (digits and words)
            (r'(?:mute|kill|cut|silence|turn\s+off|shut\s+off|disable)\s+channel\s+(\w+)', 0),
            (r'(?:unmute|restore|open|activate|turn\s+on|enable|bring\s+back)\s+channel\s+(\w+)', 1),
            (r'channel\s+(\w+)\s+(?:on|unmute|open|active)', 1),
            (r'channel\s+(\w+)\s+(?:off|mute|killed?|cut)', 0),
            (r'(?:ch|ch\.)\s*(\w+)\s+(?:mute|off)', 0),
            (r'(?:ch|ch\.)\s*(\w+)\s+(?:unmute|on)', 1),
            
            # Professional slang variations
            (r'(?:lose|ditch|bury|dump)\s+channel\s+(\d+)', 0),
            (r'(?:solo\s+off|unsolo)\s+channel\s+(\d+)', 1),
            (r'(?:safe|protect)\s+channel\s+(\d+)', 0),
            
            # Track mute commands (missing patterns)
            (r'(?:cut|kill|mute)\s+track\s+(\w+)', 0),
            (r'(?:kill)\s+track\s+(\w+)', 0),
            (r'track\s+(\w+)\s+(?:cut|kill|mute)', 0),
            
            # Solo commands (new) - support words and digits
            (r'(?:solo)\s+channel\s+(\w+)', 'solo'),
            (r'(?:solo)\s+(?:track|trk)\s+(\w+)', 'solo'),
            (r'channel\s+(\w+)\s+solo', 'solo'),
            (r'(?:track|trk)\s+(\w+)\s+solo', 'solo'),
            
            # Instrument-based mute commands (expanded for failing instruments)
            (r'(?:mute|kill|cut|silence|turn\s+off)\s+(?:the\s+)?(vocals?|vox|kick|snare|bass|guitar|keys)', 0, 'instrument'),
            (r'(?:unmute|restore|open|activate|turn\s+on)\s+(?:the\s+)?(vocals?|vox|kick|snare|bass|guitar|keys)', 1, 'instrument'),
            (r'(?:mute|kill|cut)\s+(?:the\s+)?(drums|overhead|overheads|piano|strings|saxophone|sax)', 0, 'instrument'),
            (r'(?:mute|kill|cut)\s+(?:the\s+)?(lead\s+vocal|background\s+vocals|bg\s+vox)', 0, 'instrument'),
            
            # Instrument-based solo commands (expanded)
            (r'(?:solo)\s+(?:the\s+)?(vocals?|vox|kick|snare|bass|guitar|keys)', 'solo', 'instrument'),
            (r'(?:the\s+)?(vocals?|vox|kick|snare|bass|guitar|keys)\s+solo', 'solo', 'instrument'),
            (r'(?:solo)\s+(?:the\s+)?(lead\s+vocal|saxophone|sax|piano|strings)', 'solo', 'instrument'),
        ]
        
        for pattern in patterns:
            if len(pattern) == 3:
                pattern_text, state, command_type = pattern
            else:
                pattern_text, state = pattern
                command_type = 'channel'
                
            match = re.search(pattern_text, command.lower())
            if match:
                if state == 'solo':
                    # Handle solo commands
                    if command_type == 'instrument':
                        instrument = match.group(1)
                        channel_num = self.get_channel_for_instrument(instrument)
                        if not channel_num:
                            continue
                        channel_idx = channel_num - 1
                        results.append(RCPCommand(
                            f"# set MIXER:Current/InCh/Solo {channel_idx} 0 1",
                            f"Solo {instrument} (channel {channel_num})",
                            0.9
                        ))
                    else:
                        channel_num = self.parse_number(match.group(1))
                        if channel_num and self.validate_channel(channel_num):
                            channel_idx = channel_num - 1
                            results.append(RCPCommand(
                                f"# set MIXER:Current/InCh/Solo {channel_idx} 0 1",
                                f"Solo channel {channel_num}",
                                0.9
                            ))
                elif command_type == 'instrument':
                    instrument = match.group(1)
                    channel_num = self.get_channel_for_instrument(instrument)
                    if not channel_num:
                        continue
                    channel_idx = channel_num - 1
                    action_text = "Unmute" if state == 1 else "Mute"
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/Fader/On {channel_idx} 0 {state}",
                        f"{action_text} {instrument} (channel {channel_num})"
                    ))
                else:
                    channel_num = self.parse_number(match.group(1))
                    if channel_num and self.validate_channel(channel_num):
                        channel_idx = channel_num - 1
                        action_text = "Unmute" if state == 1 else "Mute"
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/Fader/On {channel_idx} 0 {state}",
                            f"{action_text} channel {channel_num}"
                        ))
                    
        return results

    def process_channel_label(self, command: str) -> List[RCPCommand]:
        """Process channel labeling commands"""
        results = []
        
        patterns = [
            r'(?:name|label|call|tag|mark)\s+(?:channel|track)\s+(\w+)\s+(?:as\s+)?(.+)',
            r'(?:set\s+)?(?:channel|track)\s+(\w+)\s+(?:name|label)\s+(?:to\s+)?(.+)',
            r'(?:channel|track)\s+(\w+)\s+(?:is|called)\s+(.+)',
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

    def get_channel_labels(self) -> dict:
        """Get current channel labels"""
        return self.channel_labels.copy()