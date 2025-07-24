#!/usr/bin/env python3
"""
Routing Processing Module for Voice Command Engine
Handles all routing-related voice commands (sends, pan, matrix routing)
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

class RoutingProcessor:
    """Processes routing-related voice commands"""
    
    def __init__(self, terms: ProfessionalAudioTerms, validation_limits: dict, channel_processor):
        self.terms = terms
        self.validation_limits = validation_limits
        self.channel_processor = channel_processor  # Access to channel labeling
        
    def validate_channel(self, num: int) -> bool:
        """Validate channel number is within acceptable range"""
        return 1 <= num <= self.validation_limits['MAX_CHANNEL']
        
    def validate_mix(self, num: int) -> bool:
        """Validate mix number is within acceptable range"""
        return 1 <= num <= self.validation_limits['MAX_MIX']

    def parse_number(self, text: str) -> Optional[int]:
        """Parse a number from text, handling both digits and words"""
        try:
            return int(text)
        except ValueError:
            pass
            
        text_lower = text.lower()
        if text_lower in self.terms.number_words:
            return self.terms.number_words[text_lower]
            
        return None

    def parse_db_value(self, text: str) -> Optional[int]:
        """Parse a dB value from text"""
        if not text:
            return None
            
        text_lower = text.lower()
        for keyword, value in self.terms.db_keywords.items():
            if keyword in text_lower:
                return value
                
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
                db_value = int(value * 100)
                return max(self.validation_limits['MIN_DB'] * 100, 
                          min(self.validation_limits['MAX_DB'] * 100, db_value))
                
        return None

    def get_channel_for_instrument(self, instrument: str) -> Optional[int]:
        """Get channel number for instrument via channel processor"""
        return self.channel_processor.get_channel_for_instrument(instrument)

    def process_send_to_mix(self, command: str) -> List[RCPCommand]:
        """Process send to mix commands with comprehensive professional terminology"""
        results = []
        
        patterns = [
            # Standard channel-to-mix routing
            (r'(?:send|route|add|patch|feed|mult)\s+channel\s+(\d+)\s+to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\d+)', 'on'),
            (r'(?:send|route|add|patch|feed)\s+(?:ch|ch\.)\s*(\d+)\s+to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\d+)', 'on'),
            
            # Track-based routing (professional terminology)
            (r'(?:send|route|add|patch|feed|mult)\s+track\s+(\d+)\s+to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\d+)', 'on'),
            (r'(?:send|route|add|patch|feed)\s+(?:trk|tr)\s*(\d+)\s+to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\d+)', 'on'),
            
            # Channel/Track with word numbers  
            (r'(?:send|route|add|patch|feed|mult)\s+(?:channel|ch|track|trk)\s+(\w+)\s+to\s+(?:mix|aux|monitor|mon|wedge|bus)\s+(\w+)', 'word_numbers'),
            
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
            
            # Missing routing patterns for failing commands
            (r'(?:patch)\s+(?:channel|track)\s+(\w+)\s+(?:into|to)\s+(?:wedge)\s+(\w+)', 'patch_into'),
            (r'(?:route)\s+(?:vocals?|vox)\s+to\s+(?:singer\'s\s+)?(?:wedge|monitor)', 'singer_wedge'), 
            (r'(?:send)\s+(?:track|channel)\s+(\w+)\s+to\s+(?:in-ears|in\s+ears|iems?)', 'in_ears'),
            (r'(?:patch)\s+track\s+(\w+)\s+into\s+mix\s+(\w+)', 'patch_track'),
            (r'(?:send)\s+(?:the\s+)?(snare|overhead|overheads)\s+to\s+(?:wedges|monitors)', 'to_wedges'),
            (r'(?:route)\s+(?:overhead|overheads)\s+to\s+(?:monitors)', 'overheads_monitors'),
            (r'(?:feed)\s+(?:vocals?|vox)\s+to\s+(?:the\s+)?(?:ears|in-ears)', 'vocal_ears'),
            (r'(?:send)\s+(?:aux|mix)\s+(\w+)\s+to\s+matrix\s+(?:out)', 'aux_matrix'),
            (r'(?:feed)\s+track\s+(\w+)\s+to\s+(?:the\s+)?(?:wedge)', 'track_wedge'),
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
                            0.8
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
                            0.7
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
                            0.8
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
                        
                elif action == 'word_numbers':
                    # Handle track/channel with word numbers (e.g., "track 1 to bus seven")
                    channel_text = match.group(1)
                    mix_text = match.group(2)
                    
                    channel_num = self.parse_number(channel_text)
                    mix_num = self.parse_number(mix_text)
                    
                    if channel_num and mix_num and self.validate_channel(channel_num) and self.validate_mix(mix_num):
                        channel_idx = channel_num - 1
                        mix_idx = mix_num - 1
                        
                        # Determine if it was track or channel terminology
                        input_type = 'track' if 'track' in command.lower() or 'trk' in command.lower() else 'channel'
                        output_type = 'bus' if 'bus' in command.lower() else 'mix'
                        
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 1",
                            f"Send {input_type} {channel_num} to {output_type} {mix_num}"
                        ))
                        
                elif action == 'patch_into':
                    # Handle "patch channel X into wedge Y"
                    channel_text = match.group(1)
                    mix_text = match.group(2)
                    channel_num = self.parse_number(channel_text)
                    mix_num = self.parse_number(mix_text)
                    
                    if channel_num and mix_num and self.validate_channel(channel_num) and self.validate_mix(mix_num):
                        channel_idx = channel_num - 1
                        mix_idx = mix_num - 1
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} {mix_idx} 1",
                            f"Patch channel {channel_num} into wedge {mix_num}"
                        ))
                        
                elif action == 'singer_wedge':
                    # Handle "route vocals to singer's wedge"
                    vocal_channel = self.get_channel_for_instrument('vocals')
                    if vocal_channel:
                        channel_idx = vocal_channel - 1
                        # Default to mix 1 for singer's wedge
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} 0 1",
                            f"Route vocals to singer's wedge (mix 1)"
                        ))
                        
                elif action == 'in_ears':
                    # Handle "send track X to in-ears"
                    channel_text = match.group(1)
                    channel_num = self.parse_number(channel_text)
                    if channel_num and self.validate_channel(channel_num):
                        channel_idx = channel_num - 1
                        # Default to mix 3 for IEMs
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} 2 1",
                            f"Send track {channel_num} to IEM mix 3"
                        ))
                        
                elif action == 'patch_track':
                    # Handle "patch track X into mix Y"
                    track_text = match.group(1)
                    mix_text = match.group(2)
                    track_num = self.parse_number(track_text)
                    mix_num = self.parse_number(mix_text)
                    
                    if track_num and mix_num and self.validate_channel(track_num) and self.validate_mix(mix_num):
                        track_idx = track_num - 1
                        mix_idx = mix_num - 1
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {track_idx} {mix_idx} 1",
                            f"Patch track {track_num} into mix {mix_num}"
                        ))
                        
                elif action == 'to_wedges':
                    # Handle "send snare/overhead to wedges"
                    instrument = match.group(1)
                    channel_num = self.get_channel_for_instrument(instrument)
                    if channel_num:
                        channel_idx = channel_num - 1
                        # Send to multiple wedges (mix 1 and 2)
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} 0 1",
                            f"Send {instrument} to wedge 1"
                        ))
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} 1 1",
                            f"Send {instrument} to wedge 2"
                        ))
                        
                elif action == 'overheads_monitors':
                    # Handle "route overhead to monitors"
                    overhead_channel = self.get_channel_for_instrument('overhead')
                    if overhead_channel:
                        channel_idx = overhead_channel - 1
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} 0 1",
                            f"Route overheads to monitors (mix 1)"
                        ))
                        
                elif action == 'vocal_ears':
                    # Handle "feed vocals to the ears"
                    vocal_channel = self.get_channel_for_instrument('vocals')
                    if vocal_channel:
                        channel_idx = vocal_channel - 1
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {channel_idx} 2 1",
                            f"Feed vocals to IEMs (mix 3)"
                        ))
                        
                elif action == 'aux_matrix':
                    # Handle "send aux X to matrix out"
                    aux_text = match.group(1)
                    aux_num = self.parse_number(aux_text)
                    if aux_num and self.validate_mix(aux_num):
                        aux_idx = aux_num - 1
                        results.append(RCPCommand(
                            f"# set MIXER:Current/Mix/ToMatrix/On {aux_idx} 0 1",
                            f"Send aux {aux_num} to matrix output",
                            0.7
                        ))
                        
                elif action == 'track_wedge':
                    # Handle "feed track X to the wedge"
                    track_text = match.group(1)
                    track_num = self.parse_number(track_text)
                    if track_num and self.validate_channel(track_num):
                        track_idx = track_num - 1
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToMix/On {track_idx} 0 1",
                            f"Feed track {track_num} to wedge (mix 1)"
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
        """Process pan commands with professional terminology"""
        results = []
        
        # Main stereo pan patterns
        stereo_patterns = [
            r'(?:pan|hard)\s+(?:left|right)\s+channel\s+(\d+)',
            r'(?:pan\s+)?channel\s+(\d+)\s+(?:to\s+)?(.+)',
            r'(?:center|centre)\s+channel\s+(\d+)',
            
            # Track-based panning (missing patterns)
            r'(?:pan)\s+track\s+(\w+)\s+(?:hard\s+)?(?:left|right)',
            r'(?:pan)\s+track\s+(\w+)\s+(?:to\s+)?(.+)',
            r'(?:center|centre)\s+track\s+(\w+)',
            r'(?:hard\s+)?(left|right)\s+on\s+(?:the\s+)?(snare|guitar|piano|kick|bass)',
            
            # Instrument-based panning (expanded)
            r'(?:pan|center|centre)\s+(?:the\s+)?(vocals?|vox|kick|snare|bass|guitar|keys)\s+(?:to\s+)?(.+)',
            r'(?:hard\s+)?(?:left|right|center|centre)\s+(?:the\s+)?(vocals?|vox|kick|snare|bass|guitar|keys)',
            r'(?:pan)\s+(?:the\s+)?(piano|strings|horns)\s+(?:to\s+)?(.+)',
            r'(?:spread)\s+(?:the\s+)?(overheads|overhead)',
            r'(?:hard\s+)?(left|right)\s+on\s+(guitar|piano)',
        ]
        
        for pattern in stereo_patterns:
            match = re.search(pattern, command.lower())
            if match:
                channel_num = None
                pan_value = None
                
                # Handle different pattern types
                if 'track' in pattern:
                    # Track-based commands: "pan track X", "center track Y"
                    track_text = match.group(1)
                    channel_num = self.parse_number(track_text)
                    
                    if 'center' in pattern or 'centre' in pattern:
                        pan_value = 0
                    elif len(match.groups()) > 1 and match.group(2):
                        pan_text = match.group(2).lower()
                        for position, value in self.terms.pan_positions.items():
                            if position in pan_text:
                                pan_value = value
                                break
                    else:
                        # Extract from command
                        if 'hard right' in command.lower():
                            pan_value = 63
                        elif 'right' in command.lower():
                            pan_value = 32
                        elif 'hard left' in command.lower():
                            pan_value = -63
                        elif 'left' in command.lower():
                            pan_value = -32
                            
                elif 'spread' in pattern:
                    # Handle "spread the overheads"
                    instrument = match.group(1) if match.groups() else 'overheads'
                    channel_num = self.get_channel_for_instrument(instrument)
                    if channel_num:
                        # Create two commands for stereo spread
                        channel_idx = channel_num - 1
                        results.append(RCPCommand(
                            f"set MIXER:Current/InCh/ToSt/Pan {channel_idx} 0 -32",
                            f"Pan {instrument} left (stereo spread)"
                        ))
                        # Assume channel+1 for right side
                        if channel_num < 40:
                            results.append(RCPCommand(
                                f"set MIXER:Current/InCh/ToSt/Pan {channel_idx + 1} 0 32",
                                f"Pan {instrument} right (stereo spread)"
                            ))
                        continue
                        
                elif any(inst in pattern for inst in ['vocals', 'vox', 'kick', 'snare', 'bass', 'guitar', 'keys', 'piano']):
                    # Instrument-based commands
                    instrument = match.group(1) if match.groups() else None
                    if not instrument:
                        # Extract from pattern match in command
                        for inst in ['vocals', 'vox', 'kick', 'snare', 'bass', 'guitar', 'keys', 'piano']:
                            if inst in command.lower():
                                instrument = inst
                                break
                                
                    if instrument:
                        channel_num = self.get_channel_for_instrument(instrument)
                        
                        # Determine pan position
                        if 'center' in pattern or 'centre' in pattern:
                            pan_value = 0
                        elif 'hard left' in command.lower() or 'hard left on' in command.lower():
                            pan_value = -63
                        elif 'hard right' in command.lower() or 'hard right on' in command.lower():
                            pan_value = 63
                        elif 'left' in command.lower():
                            pan_value = -32
                        elif 'right' in command.lower():
                            pan_value = 32
                        elif len(match.groups()) > 1 and match.group(2):
                            pan_text = match.group(2).lower()
                            for position, value in self.terms.pan_positions.items():
                                if position in pan_text:
                                    pan_value = value
                                    break
                else:
                    # Standard channel commands
                    if 'center' in pattern or 'centre' in pattern:
                        channel_num = self.parse_number(match.group(1))
                        pan_value = 0
                    else:
                        channel_num = self.parse_number(match.group(1))
                        # Determine pan position
                        if len(match.groups()) > 1:
                            pan_text = match.group(2).lower() if match.group(2) else command.lower()
                        else:
                            pan_text = command.lower()
                            
                        for position, value in self.terms.pan_positions.items():
                            if position in pan_text:
                                pan_value = value
                                break
                            
                if channel_num and pan_value is not None and self.validate_channel(channel_num):
                    channel_idx = channel_num - 1
                    results.append(RCPCommand(
                        f"set MIXER:Current/InCh/ToSt/Pan {channel_idx} 0 {pan_value}",
                        f"Pan channel {channel_num} to {pan_value}"
                    ))
                    
        return results