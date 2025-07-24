#!/usr/bin/env python3
"""
Automated Test Runner for 100 Professional Audio Engineer Voice Commands
Tests all commands from audio_engineer_test_commands.md
"""

import re
from engine import VoiceCommandEngine

def extract_commands_from_md():
    """Extract numbered commands from the markdown file"""
    commands = []
    
    with open('audio_engineer_test_commands.md', 'r') as f:
        content = f.read()
    
    # Find numbered commands (1-100)
    pattern = r'^\d+\.\s+"([^"]+)"'
    matches = re.findall(pattern, content, re.MULTILINE)
    
    return matches

def test_all_commands():
    """Test all 100 commands and generate report"""
    print("🎙️  PROFESSIONAL AUDIO ENGINEER VOICE COMMAND TEST SUITE")
    print("=" * 80)
    print()
    
    engine = VoiceCommandEngine()
    commands = extract_commands_from_md()
    
    results = {
        'working': [],      # Commands that generate RCP
        'failed': [],       # Commands that generate no RCP
        'multiple': [],     # Commands that generate multiple RCP
        'total_tested': 0
    }
    
    print(f"📋 Testing {len(commands)} professional audio commands...")
    print()
    
    for i, command in enumerate(commands, 1):
        results['total_tested'] += 1
        
        try:
            rcp_commands = engine.process_command(command)
            num_commands = len(rcp_commands)
            
            if num_commands == 0:
                results['failed'].append((i, command))
                status = "❌ FAIL"
                detail = "No RCP generated"
            elif num_commands == 1:
                results['working'].append((i, command, rcp_commands[0]))
                status = "✅ PASS"
                detail = f"1 RCP: {rcp_commands[0].description}"
            else:
                results['multiple'].append((i, command, rcp_commands))
                status = "⚠️  MULTI"
                detail = f"{num_commands} RCP commands"
            
            print(f"{i:3d}. {status} \"{command}\"")
            print(f"     {detail}")
            
            # Show RCP commands for working ones
            if num_commands > 0:
                for j, rcp in enumerate(rcp_commands):
                    confidence = f"({rcp.confidence*100:.0f}%)"
                    print(f"     └─ {rcp.command} {confidence}")
            
            print()
            
        except Exception as e:
            results['failed'].append((i, command))
            print(f"{i:3d}. ❌ ERROR \"{command}\"")
            print(f"     Exception: {e}")
            print()
    
    # Generate summary report
    print("\n" + "=" * 80)
    print("📊 FINAL RESULTS SUMMARY")
    print("=" * 80)
    
    total = results['total_tested']
    working = len(results['working'])
    failed = len(results['failed'])
    multiple = len(results['multiple'])
    
    success_rate = (working + multiple) / total * 100
    
    print(f"📈 Overall Success Rate: {success_rate:.1f}% ({working + multiple}/{total})")
    print(f"✅ Single RCP Generated: {working} commands")
    print(f"⚠️  Multiple RCP Generated: {multiple} commands")  
    print(f"❌ Failed (No RCP): {failed} commands")
    print()
    
    # Category breakdown
    print("📋 CATEGORY BREAKDOWN:")
    categories = [
        ("Channel Control & Faders", 1, 25),
        ("Muting & Solo", 26, 45),
        ("Routing & Sends", 46, 70),
        ("Panning & Positioning", 71, 85),
        ("Effects & Processing", 86, 95),
        ("Scene & System Commands", 96, 100)
    ]
    
    for category, start, end in categories:
        cat_working = len([x for x in results['working'] if start <= x[0] <= end])
        cat_multiple = len([x for x in results['multiple'] if start <= x[0] <= end])
        cat_failed = len([x for x in results['failed'] if start <= x[0] <= end])
        cat_total = end - start + 1
        cat_success = (cat_working + cat_multiple) / cat_total * 100
        
        print(f"  {category}: {cat_success:.1f}% ({cat_working + cat_multiple}/{cat_total})")
        print(f"    ✅ {cat_working} ⚠️  {cat_multiple} ❌ {cat_failed}")
    
    # Failed commands detail
    if results['failed']:
        print(f"\n❌ FAILED COMMANDS ({len(results['failed'])}):")
        for num, command in results['failed']:
            print(f"  {num:3d}. \"{command}\"")
    
    # Professional terminology analysis
    print(f"\n🎯 PROFESSIONAL TERMINOLOGY ANALYSIS:")
    
    # Track vs Channel usage
    track_commands = [cmd for _, cmd, _ in results['working'] if 'track' in cmd.lower()]
    channel_commands = [cmd for _, cmd, _ in results['working'] if 'channel' in cmd.lower()]
    print(f"  Track terminology: {len(track_commands)} working")
    print(f"  Channel terminology: {len(channel_commands)} working")
    
    # Professional slang
    slang_terms = ['crank', 'bury', 'kill', 'slam', 'ride', 'trim']
    slang_working = 0
    for _, cmd, _ in results['working']:
        if any(term in cmd.lower() for term in slang_terms):
            slang_working += 1
    print(f"  Professional slang: {slang_working} working")
    
    # Word numbers
    word_numbers = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 
                   'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 
                   'eighteen', 'nineteen', 'twenty']
    word_num_working = 0
    for _, cmd, _ in results['working']:
        if any(num in cmd.lower() for num in word_numbers):
            word_num_working += 1
    print(f"  Word numbers: {word_num_working} working")
    
    print(f"\n🚀 Testing complete! Check results above for detailed analysis.")
    
    return results

if __name__ == "__main__":
    test_all_commands()