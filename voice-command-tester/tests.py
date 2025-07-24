#!/usr/bin/env python3
"""
Test script for the Voice Command Engine
Validates the rule engine against the known working commands
"""

from voice_command_engine import VoiceCommandEngine
import json

def test_engine():
    """Test the voice command engine with various commands"""
    engine = VoiceCommandEngine()
    
    # Test commands from the 100-percent-sure-voice-commands.md file
    test_cases = [
        # Channel Fader Control
        {
            'input': 'Set channel 1 to unity',
            'expected_contains': 'MIXER:Current/InCh/Fader/Level 0 0 0'
        },
        {
            'input': 'Channel 12 to minus 10 dB',
            'expected_contains': 'MIXER:Current/InCh/Fader/Level 11 0 -1000'
        },
        {
            'input': 'Set channel 24 volume to minus 20',
            'expected_contains': 'MIXER:Current/InCh/Fader/Level 23 0 -2000'
        },
        
        # Channel Muting
        {
            'input': 'Mute channel 3',
            'expected_contains': 'MIXER:Current/InCh/Fader/On 2 0 0'
        },
        {
            'input': 'Unmute channel 7',
            'expected_contains': 'MIXER:Current/InCh/Fader/On 6 0 1'
        },
        {
            'input': 'Turn off channel 15',
            'expected_contains': 'MIXER:Current/InCh/Fader/On 14 0 0'
        },
        
        # Channel Labeling
        {
            'input': 'Name channel 1 vocals',
            'expected_contains': 'MIXER:Current/InCh/Label/Name 0 0 "vocals"'
        },
        {
            'input': 'Label channel 5 kick drum',
            'expected_contains': 'MIXER:Current/InCh/Label/Name 4 0 "kick drum"'
        },
        
        # Send to Mix
        {
            'input': 'Send channel 1 to mix 3',
            'expected_contains': 'MIXER:Current/InCh/ToMix/On 0 2 1'
        },
        {
            'input': 'Set channel 2 send to mix 1 at minus 6 dB',
            'expected_contains': 'MIXER:Current/InCh/ToMix/Level 1 0 -600'
        },
        
        # Pan Controls
        {
            'input': 'Pan channel 1 hard left',
            'expected_contains': 'MIXER:Current/InCh/ToSt/Pan 0 0 -63'
        },
        {
            'input': 'Center channel 5',
            'expected_contains': 'MIXER:Current/InCh/ToSt/Pan 4 0 0'
        },
        
        # Scene Management
        {
            'input': 'Recall scene 1',
            'expected_contains': 'ssrecall_ex scene_01'
        },
        {
            'input': 'Load scene 15',
            'expected_contains': 'ssrecall_ex scene_15'
        },
        
        # DCA Controls
        {
            'input': 'Set DCA 1 to unity',
            'expected_contains': 'MIXER:Current/DCA/Fader/Level 0 0 0'
        },
        {
            'input': 'Mute DCA 3',
            'expected_contains': 'MIXER:Current/DCA/Fader/On 2 0 0'
        },
    ]
    
    print("🧪 Voice Command Engine Test Results")
    print("=" * 60)
    
    passed = 0
    failed = 0
    
    for i, test_case in enumerate(test_cases, 1):
        input_cmd = test_case['input']
        expected = test_case['expected_contains']
        
        print(f"\n{i:2d}. Testing: '{input_cmd}'")
        
        results = engine.process_command(input_cmd)
        
        if not results:
            print(f"    ❌ FAIL: No results generated")
            failed += 1
            continue
            
        # Check if any result contains the expected command
        found = False
        for result in results:
            if expected in result.command:
                print(f"    ✅ PASS: Generated '{result.command}'")
                print(f"              {result.description}")
                found = True
                break
                
        if not found:
            print(f"    ❌ FAIL: Expected '{expected}' not found in results:")
            for result in results:
                print(f"              Generated: '{result.command}'")
            failed += 1
        else:
            passed += 1
    
    print("\n" + "=" * 60)
    print(f"📊 Test Summary: {passed} passed, {failed} failed")
    print(f"   Success rate: {passed/(passed+failed)*100:.1f}%")
    
    if failed == 0:
        print("🎉 All tests passed!")
    else:
        print("⚠️  Some tests failed - engine needs improvement")
    
    return passed, failed

def test_edge_cases():
    """Test edge cases and error handling"""
    engine = VoiceCommandEngine()
    
    print("\n🔍 Testing Edge Cases")
    print("-" * 40)
    
    edge_cases = [
        "",  # Empty command
        "This is not a valid command",  # Unrecognized command
        "Set channel 99 to unity",  # Out of range channel
        "Mute channel zero",  # Invalid channel number
        "Recall scene 101",  # Out of range scene
    ]
    
    for case in edge_cases:
        print(f"Testing: '{case}'")
        results = engine.process_command(case)
        print(f"  Results: {len(results)} commands generated")
        if results:
            for result in results:
                print(f"    - {result.description}")
        print()

def demo_context_aware():
    """Demonstrate context-aware functionality"""
    engine = VoiceCommandEngine()
    
    print("\n🎯 Context-Aware Demo")
    print("-" * 40)
    
    # First, label some channels
    print("1. Setting up labels...")
    engine.process_command("Name channel 1 vocals")
    engine.process_command("Name channel 5 kick drum")
    engine.process_command("Label DCA 1 drums")
    
    print("   Channel labels:", engine.get_channel_labels())
    print("   DCA labels:", engine.get_dca_labels())
    
    # Now try context-aware commands
    print("\n2. Testing context-aware commands...")
    context_commands = [
        "Turn up the vocals",
        "Add some reverb to kick drum",
        "Mute the drums",
    ]
    
    for cmd in context_commands:
        print(f"\nCommand: '{cmd}'")
        results = engine.process_command(cmd)
        for result in results:
            print(f"  -> {result.description}")
            print(f"     {result.command}")

if __name__ == "__main__":
    # Run all tests
    passed, failed = test_engine()
    test_edge_cases()
    demo_context_aware()
    
    print("\n" + "=" * 60)
    print("🚀 Ready to test with the GUI!")
    print("   Run: python voice_command_server.py")
    print("   Then open: http://localhost:5000")
    print("=" * 60)