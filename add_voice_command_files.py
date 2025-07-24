#!/usr/bin/env python3

from pbxproj import XcodeProject

# Open the project
project = XcodeProject.load('VoiceControlApp.xcodeproj/project.pbxproj')

# List of VoiceCommand files to add
voice_command_files = [
    'VoiceControlApp/VoiceCommand/Models/RCPCommand.swift',
    'VoiceControlApp/VoiceCommand/Models/ProcessedVoiceCommand.swift',
    'VoiceControlApp/VoiceCommand/Services/VoiceCommandProcessor.swift',
    'VoiceControlApp/VoiceCommand/Services/ProfessionalAudioTerms.swift',
    'VoiceControlApp/VoiceCommand/Components/VoiceCommandBubble.swift',
    'VoiceControlApp/VoiceCommand/Components/VoiceCommandBubblesView.swift'
]

# Add each file to the project and target
for file_path in voice_command_files:
    print(f"Adding {file_path} to project...")
    try:
        # Add file to project with force=False to avoid duplicates
        result = project.add_file(file_path, force=False)
        if result:
            print(f"  ✅ Successfully added {file_path}")
        else:
            print(f"  ⚠️  File {file_path} already exists in project")
    except Exception as e:
        print(f"  ❌ Error adding {file_path}: {e}")

# Save the project
try:
    project.save()
    print("\n🎉 Project saved successfully!")
except Exception as e:
    print(f"\n❌ Error saving project: {e}")

print("\nDone! All VoiceCommand files have been added to the Xcode project.")