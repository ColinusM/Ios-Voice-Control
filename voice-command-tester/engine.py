#!/usr/bin/env python3
"""
Voice Command Rule Engine v2.0 for Yamaha RCP Control
Modular, professional-grade voice command processing with comprehensive terminology support
"""

import re
from typing import Dict, List, Optional
from dataclasses import dataclass

# Import our modular processors
from terms import ProfessionalAudioTerms
from channels import ChannelProcessor, RCPCommand
from routing import RoutingProcessor
from effects import EffectsProcessor

class VoiceCommandEngine:
    """Main voice command engine coordinator"""
    
    def __init__(self):
        # Security hardening - input validation limits
        self.validation_limits = {
            'MAX_CHANNEL': 40,
            'MAX_MIX': 20,
            'MAX_SCENE': 100,
            'MAX_DCA': 8,
            'MIN_DB': -60,
            'MAX_DB': 10,
            'MAX_INPUT_LENGTH': 200
        }
        
        # Initialize professional audio terms database
        self.terms = ProfessionalAudioTerms()
        
        # Initialize specialized processors
        self.channel_processor = ChannelProcessor(self.terms, self.validation_limits)
        self.routing_processor = RoutingProcessor(self.terms, self.validation_limits, self.channel_processor)
        self.effects_processor = EffectsProcessor(self.terms, self.validation_limits, self.channel_processor)
        
        # DCA labels storage
        self.dca_labels = {}

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

    def validate_scene(self, num: int) -> bool:
        """Validate scene number is within acceptable range"""
        return 1 <= num <= self.validation_limits['MAX_SCENE']
        
    def validate_dca(self, num: int) -> bool:
        """Validate DCA number is within acceptable range"""
        return 1 <= num <= self.validation_limits['MAX_DCA']

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

    def process_scene_recall(self, command: str) -> List[RCPCommand]:
        """Process scene recall commands with professional terminology"""
        results = []
        
        patterns = [
            r'(?:recall|load|go\s+to|switch\s+to|call\s+up)\s+(?:scene|preset|snapshot|memory)\s+(\w+)',
            r'(?:scene|preset|snapshot|memory)\s+(\w+)',
            r'(?:bank|scene\s+bank)\s+(\w+)',  # Scene bank terminology
            r'(?:store|save)\s+(?:scene|preset)\s+(\w+)',  # Store scene
            r'(?:copy|duplicate)\s+(?:scene|preset)\s+(\w+)',  # Copy scene
            # Missing patterns from failing commands
            r'(?:go\s+to)\s+scene\s+(\w+)',
            r'(?:scene\s+change)\s+(\w+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, command.lower())
            if match:
                scene_num = self.parse_number(match.group(1))
                if scene_num and self.validate_scene(scene_num):
                    scene_str = f"{scene_num:02d}"
                    
                    if 'store' in command.lower() or 'save' in command.lower():
                        results.append(RCPCommand(
                            f"ssstore scene_{scene_str}",
                            f"Store current settings to scene {scene_num}",
                            0.9
                        ))
                    elif 'copy' in command.lower():
                        results.append(RCPCommand(
                            f"# Copy scene {scene_num} operations",
                            f"Copy scene {scene_num}",
                            0.8
                        ))
                    else:
                        results.append(RCPCommand(
                            f"ssrecall_ex scene_{scene_str}",
                            f"Recall scene {scene_num}"
                        ))
                    
        return results

    def process_dca_commands(self, command: str) -> List[RCPCommand]:
        """Process DCA/VCA group commands with professional terminology"""
        results = []
        
        # DCA fader patterns
        fader_patterns = [
            (r'(?:set\s+)?(?:dca|vca|group)\s+(\d+)\s+(?:to|at)\s+(.+)', 'level'),
            (r'(?:dca|vca|group)\s+(\d+)\s+(?:up|down)\s+(\d+)', 'relative'),
            (r'(?:bring\s+up|pull\s+up)\s+(?:dca|vca|group)\s+(\d+)', 'up'),
            (r'(?:bring\s+down|pull\s+down)\s+(?:dca|vca|group)\s+(\d+)', 'down'),
            (r'(?:dca|vca|group)\s+(\d+)\s+(?:hot|loud|cooking)', 'hot'),
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
                    elif action == 'up':
                        results.append(RCPCommand(
                            f"set MIXER:Current/DCA/Fader/Level {dca_idx} 0 300",
                            f"Bring up DCA {dca_num} (+3.0 dB)"
                        ))
                    elif action == 'down':
                        results.append(RCPCommand(
                            f"set MIXER:Current/DCA/Fader/Level {dca_idx} 0 -600",
                            f"Bring down DCA {dca_num} (-6.0 dB)"
                        ))
                    elif action == 'hot':
                        results.append(RCPCommand(
                            f"set MIXER:Current/DCA/Fader/Level {dca_idx} 0 500",
                            f"Push DCA {dca_num} hot (+5.0 dB)"
                        ))
                            
        # DCA mute patterns
        mute_patterns = [
            (r'(?:mute|kill|turn\s+off)\s+(?:dca|vca|group)\s+(\d+)', 0),
            (r'(?:unmute|restore|turn\s+on)\s+(?:dca|vca|group)\s+(\d+)', 1),
        ]
        
        for pattern, state in mute_patterns:
            match = re.search(pattern, command.lower())
            if match:
                dca_num = self.parse_number(match.group(1))
                if dca_num and self.validate_dca(dca_num):
                    dca_idx = dca_num - 1
                    action_text = "Unmute" if state == 1 else "Mute"
                    results.append(RCPCommand(
                        f"set MIXER:Current/DCA/Fader/On {dca_idx} 0 {state}",
                        f"{action_text} DCA {dca_num}"
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
        channel_labels = self.channel_processor.get_channel_labels()
        for label, channel_num in channel_labels.items():
            if label in command.lower():
                # Replace label with channel number and process with specific processors
                modified_command = command.lower().replace(label, f"channel {channel_num}")
                # Use processors to handle the modified command
                try:
                    results.extend(self.channel_processor.process_channel_fader(modified_command))
                    results.extend(self.channel_processor.process_channel_mute(modified_command))
                    results.extend(self.routing_processor.process_send_to_mix(modified_command))
                    results.extend(self.routing_processor.process_pan_commands(modified_command))
                except Exception as e:
                    print(f"Error in context-aware processing: {e}")
                
        # Check for labeled DCAs
        for label, dca_num in self.dca_labels.items():
            if label in command.lower():
                modified_command = command.lower().replace(label, f"dca {dca_num}")
                try:
                    results.extend(self.process_dca_commands(modified_command))
                except Exception as e:
                    print(f"Error in DCA context processing: {e}")
                
        return results

    def is_compound_command(self, command: str) -> bool:
        """Check if command contains multiple operations"""
        conjunctions = [
            r'\s+and\s+',
            r'\s+then\s+',
            r'\s+also\s+',
            r',\s*(?:and\s+)?(?:then\s+)?',
            r'\s+plus\s+',
            r'\s+as\s+well\s+as\s+',
        ]
        
        for conjunction in conjunctions:
            if re.search(conjunction, command.lower()):
                return True
        return False

    def process_compound_command(self, command: str) -> List[RCPCommand]:
        """Process compound commands with multiple operations"""
        results = []
        
        # Split command by conjunctions while preserving context
        command_parts = self.split_compound_command(command)
        
        # Extract primary context (channel/track number, instrument name)
        primary_context = self.extract_primary_context(command_parts[0])
        
        # Process each part, applying context inheritance
        for i, part in enumerate(command_parts):
            # Apply context to subsequent commands if they lack explicit targets
            if i > 0 and primary_context:
                part = self.apply_context_inheritance(part, primary_context)
                
            # Process the individual command
            part_results = self.process_single_command(part)
            results.extend(part_results)
            
        return results

    def split_compound_command(self, command: str) -> List[str]:
        """Split compound command into individual parts"""
        # Define splitting patterns in order of precedence
        split_patterns = [
            r'\s+and\s+(?:then\s+)?',  # "and then", "and"
            r'\s+then\s+',              # "then"
            r'\s+also\s+',              # "also"
            r',\s*(?:and\s+)?(?:then\s+)?',  # ", and then", ", then", ","
            r'\s+plus\s+',              # "plus"
            r'\s+as\s+well\s+as\s+',  # "as well as"
        ]
        
        # Find the first matching pattern and split on it
        for pattern in split_patterns:
            if re.search(pattern, command.lower()):
                parts = re.split(pattern, command.lower())
                return [part.strip() for part in parts if part.strip()]
                
        return [command]  # No split needed

    def extract_primary_context(self, first_command: str) -> dict:
        """Extract channel/track/instrument context from first command"""
        context = {}
        
        # Extract channel/track numbers
        channel_match = re.search(r'(?:channel|ch)\s+(\w+)', first_command.lower())
        if channel_match:
            context['channel'] = channel_match.group(1)
            context['target_type'] = 'channel'
            
        track_match = re.search(r'(?:track|trk)\s+(\w+)', first_command.lower())
        if track_match:
            context['track'] = track_match.group(1)
            context['target_type'] = 'track'
            
        # Extract instrument names from labeling commands
        label_match = re.search(r'(?:label|name|call)\s+(?:channel|track)\s+\w+\s+(?:as\s+)?([\w\s]+)', first_command.lower())
        if label_match:
            context['instrument'] = label_match.group(1).strip()
            
        return context

    def substitute_pronouns(self, command: str, context: dict) -> str:
        """Replace pronouns (it, that, this) with explicit channel/track references"""
        command_lower = command.lower()
        
        # Handle various pronoun patterns
        pronouns = ['it', 'that', 'this']
        
        for pronoun in pronouns:
            if pronoun in command_lower:
                pattern = r'\b' + pronoun + r'\b'
                if context.get('channel'):
                    replacement = 'channel ' + context['channel']
                    command = re.sub(pattern, replacement, command, flags=re.IGNORECASE)
                elif context.get('track'):
                    replacement = 'track ' + context['track']
                    command = re.sub(pattern, replacement, command, flags=re.IGNORECASE)
                elif context.get('instrument'):
                    replacement = 'the ' + context['instrument']
                    command = re.sub(pattern, replacement, command, flags=re.IGNORECASE)
                    
        return command

    def apply_context_inheritance(self, command: str, context: dict) -> str:
        """Apply inherited context to commands missing explicit targets"""
        # Handle pronoun references first
        command = self.substitute_pronouns(command, context)
        
        # If command already has explicit target after pronoun substitution, don't modify further
        if re.search(r'(?:channel|track|ch|trk)\s+\w+', command.lower()):
            return command
            
        # If command starts with action words, prepend context
        action_patterns = [
            r'^(?:send|route|add|patch|feed)',
            r'^(?:pan|center|centre)',
            r'^(?:set|bring|pull|push)',
            r'^(?:mute|unmute|solo)',
            r'^(?:compress|limit|gate)',
            r'^(?:add|send)\s+(?:reverb|delay)',
        ]
        
        for pattern in action_patterns:
            if re.search(pattern, command.lower()):
                if context.get('channel'):
                    return f"channel {context['channel']} {command}"
                elif context.get('track'):
                    return f"track {context['track']} {command}"
                elif context.get('instrument'):
                    return f"{context['instrument']} {command}"
                    
        return command

    def process_single_command(self, command: str) -> List[RCPCommand]:
        """Process a single command using existing processors"""
        results = []
        
        # Process through all specialized processors (same as main process_command)
        processors = [
            ('channel_fader', self.channel_processor.process_channel_fader),
            ('channel_mute', self.channel_processor.process_channel_mute),
            ('channel_label', self.channel_processor.process_channel_label),
            ('routing', self.routing_processor.process_send_to_mix),
            ('pan', self.routing_processor.process_pan_commands),
            ('scene', self.process_scene_recall),
            ('dca', self.process_dca_commands),
            ('effects', self.effects_processor.process_effects_commands),
            ('dynamics', self.effects_processor.process_dynamics_commands),
            ('context', self.process_context_aware),
        ]
        
        for processor_name, processor_func in processors:
            try:
                results.extend(processor_func(command))
            except Exception as e:
                print(f"Error in {processor_name}: {e}")
                
        return results

    def process_command(self, command: str) -> List[RCPCommand]:
        """Main entry point for processing voice commands"""
        results = []
        command = command.strip()
        
        # Security: Validate input length
        if len(command) > self.validation_limits['MAX_INPUT_LENGTH']:
            return []
            
        # Check for compound commands first
        if self.is_compound_command(command):
            return self.process_compound_command(command)
        
        # Process command through all specialized processors
        processors = [
            ('channel_fader', self.channel_processor.process_channel_fader),
            ('channel_mute', self.channel_processor.process_channel_mute),
            ('channel_label', self.channel_processor.process_channel_label),
            ('routing', self.routing_processor.process_send_to_mix),
            ('pan', self.routing_processor.process_pan_commands),
            ('scene', self.process_scene_recall),
            ('dca', self.process_dca_commands),
            ('effects', self.effects_processor.process_effects_commands),
            ('dynamics', self.effects_processor.process_dynamics_commands),
            ('context', self.process_context_aware),
        ]
        
        for processor_name, processor_func in processors:
            try:
                results.extend(processor_func(command))
            except Exception as e:
                print(f"Error in {processor_name}: {e}")
                
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
        return self.channel_processor.get_channel_labels()
        
    def get_dca_labels(self) -> Dict[str, int]:
        """Get current DCA labels"""
        return self.dca_labels.copy()

    def get_system_info(self) -> Dict:
        """Get system information and statistics"""
        return {
            'validation_limits': self.validation_limits,
            'channel_labels': len(self.get_channel_labels()),
            'dca_labels': len(self.get_dca_labels()),
            'processors': ['channel', 'routing', 'effects', 'scene', 'dca', 'context'],
            'version': '2.0 - Modular Professional'
        }


# Example usage and testing
if __name__ == "__main__":
    engine = VoiceCommandEngine()
    
    # Professional test commands
    test_commands = [
        "Bring up the vocals to unity",
        "Send the kick to mix 2 at minus 6 dB",
        "Pan the snare hard left", 
        "Add reverb to the vocals",
        "Compress the bass",
        "Recall scene 15",
        "Set DCA 1 to minus 3 dB",
        "Mute the guitar",
        "High pass the vocals",
        "Crank channel 5"
    ]
    
    print("Professional Voice Command Engine v2.0 Test")
    print("=" * 60)
    print(f"System Info: {engine.get_system_info()}")
    print("=" * 60)
    
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