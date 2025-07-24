#!/usr/bin/env python3
"""
Professional Audio Engineering Terminology Database
Contains comprehensive terminology dictionaries for commercial-grade voice control
"""

from typing import Dict

class ProfessionalAudioTerms:
    """Database of professional audio engineering terminology"""
    
    def __init__(self):
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
            'sax': 'saxophone', 'trumpet': 'horn', 'trombone': 'horn',
            # Additional missing instruments
            'drums': 'drums', 'lead vocal': 'vocals', 'lead guitar': 'guitar',
            'background vocals': 'vocals', 'bg vocals': 'vocals'
        }
        
        # Pan position mapping (professional terminology)
        self.pan_positions = {
            'hard left': -63, 'hard_left': -63, 'hardleft': -63, 'full left': -63,
            'left': -32, 'slightly left': -16, 'slight left': -16, 'little left': -16,
            'center': 0, 'centre': 0, 'middle': 0, 'dead center': 0, 'centered': 0,
            'slightly right': 16, 'slight right': 16, 'little right': 16,
            'right': 32, 'hard right': 63, 'hard_right': 63, 'hardright': 63, 'full right': 63
        }
        
        # dB value mapping (expanded professional terminology)
        self.db_keywords = {
            'unity': 0, 'zero': 0, 'nominal': 0, 'line level': 0,
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
        
        # Effects terminology
        self.effects_types = {
            'reverb': ['reverb', 'verb', 'rev', 'hall', 'plate', 'room', 'chamber'],
            'delay': ['delay', 'echo', 'slap', 'slapback', 'tape delay', 'ping pong'],
            'chorus': ['chorus', 'doubling', 'thickening'],
            'flanger': ['flanger', 'flanging', 'jet'],
            'phaser': ['phaser', 'phasing', 'swoosh'],
            'distortion': ['distortion', 'overdrive', 'fuzz', 'drive', 'crunch'],
            'compressor': ['compressor', 'comp', 'compression', 'limiting', 'limiter']
        }
        
        # EQ terminology
        self.eq_terms = {
            'frequencies': {
                'sub': '20-60', 'bass': '60-250', 'low': '60-250',
                'low mid': '250-500', 'low mids': '250-500', 'mud': '250-500',
                'mid': '500-2k', 'mids': '500-2k', 'midrange': '500-2k',
                'high mid': '2k-4k', 'high mids': '2k-4k', 'presence': '4k-6k',
                'treble': '6k-20k', 'high': '6k-20k', 'air': '10k-20k', 'brilliance': '6k-20k'
            },
            'actions': {
                'boost': 'increase', 'cut': 'decrease', 'notch': 'narrow_cut',
                'sweep': 'adjust', 'roll off': 'filter', 'high pass': 'hpf', 'low pass': 'lpf'
            }
        }
        
        # Dynamics terminology
        self.dynamics_terms = {
            'compressor': {
                'threshold': 'level where compression starts',
                'ratio': 'amount of compression (2:1, 4:1, 8:1)',
                'attack': 'how fast compression engages',
                'release': 'how fast compression disengages',
                'knee': 'hard or soft compression curve',
                'makeup': 'gain compensation after compression'
            },
            'gate': {
                'threshold': 'level where gate opens',
                'range': 'maximum attenuation amount',
                'hold': 'minimum gate open time',
                'attack': 'how fast gate opens',
                'release': 'how fast gate closes'
            }
        }
        
        # Monitor mixing terminology
        self.monitor_terms = {
            'types': ['wedge', 'sidefill', 'drum fill', 'front fill', 'iem', 'in-ear', 'cans'],
            'requests': ['more me', 'less me', 'turn me up', 'turn me down', 'can I get more'],
            'problems': ['feedback', 'ringing', 'too loud', 'too quiet', 'muddy', 'harsh']
        }
        
        # Scene/snapshot terminology
        self.scene_terms = {
            'actions': ['recall', 'load', 'store', 'save', 'copy', 'paste', 'clear'],
            'types': ['scene', 'snapshot', 'preset', 'memory', 'bank'],
            'modifiers': ['safe', 'global', 'partial', 'full']
        }
        
        # Professional slang and regional variations
        self.slang_terms = {
            'mute': ['kill', 'cut', 'lose', 'ditch', 'bury', 'dump'],
            'unmute': ['restore', 'bring back', 'open', 'activate'],
            'loud': ['hot', 'cooking', 'pushing', 'cranked', 'slammed'],
            'quiet': ['back', 'down', 'soft', 'pulled'],
            'console': ['desk', 'board', 'mixer'],
            'channels': ['strips', 'inputs'],
            'monitors': ['wedges', 'foldback'],  # UK term
            'cable': ['lead', 'multicore', 'snake']
        }
        
        # Equipment nicknames and abbreviations
        self.equipment_terms = {
            'A1': 'lead audio engineer',
            'A2': 'assistant audio engineer',
            'FOH': 'front of house',
            'MON': 'monitor engineer',
            'RF': 'radio frequency/wireless',
            'IEM': 'in-ear monitor',
            'DI': 'direct input',
            'HPF': 'high-pass filter',
            'LPF': 'low-pass filter',
            'GEQ': 'graphic equalizer',
            'PEQ': 'parametric equalizer'
        }

    def get_default_instrument_channels(self) -> Dict[str, int]:
        """Default channel assignments for common instruments (demo purposes)"""
        return {
            'vocals': 1, 'vox': 1, 'lead vocal': 1,
            'kick': 2, 'kick drum': 2, 'bass drum': 2, 'bd': 2,
            'snare': 3, 'snare drum': 3, 'sd': 3,
            'hihat': 4, 'hi-hat': 4, 'hh': 4, 'hat': 4,
            'bass': 5, 'bass guitar': 5, 'di': 5,
            'guitar': 6, 'electric guitar': 6, 'gtr': 6, 'lead guitar': 6,
            'keys': 7, 'keyboard': 7, 'kb': 7, 'piano': 7,
            'acoustic': 8, 'acoustic guitar': 8, 'ac': 8,
            # Additional instruments for failing commands
            'drums': 9, 'overhead': 10, 'overheads': 10, 'strings': 11,
            'saxophone': 12, 'sax': 12, 'background vocals': 13, 'bg vocals': 13
        }