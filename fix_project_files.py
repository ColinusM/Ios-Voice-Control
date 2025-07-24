#!/usr/bin/env python3

from pbxproj import XcodeProject
import os

def main():
    # Open the project
    print("Loading Xcode project...")
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
    
    print("Attempting to remove and re-add files...")
    
    # First, try to remove any existing references
    for file_path in voice_command_files:
        try:
            project.remove_file(file_path)
            print(f"  Removed {file_path}")
        except:
            print(f"  {file_path} was not in project (or couldn't be removed)")
    
    # Now add the files using a simpler approach
    for file_path in voice_command_files:
        # Check if file exists on disk
        if not os.path.exists(file_path):
            print(f"  ❌ File does not exist: {file_path}")
            continue
            
        try:
            # Use the low-level API to add files
            file_options = {}
            
            # Add the file
            file_ref = project.add_file(file_path, force=True)
            print(f"  ✅ Added {file_path}")
            
        except Exception as e:
            print(f"  ❌ Error adding {file_path}: {str(e)}")
            # Try alternative method
            try:
                # Alternative: Add file without specifying target
                project.add_file_if_doesnt_exist(file_path)
                print(f"  ✅ Added {file_path} (alternative method)")
            except Exception as e2:
                print(f"  ❌ Alternative method also failed: {str(e2)}")
    
    # Save the project
    print("\nSaving project...")
    try:
        project.save()
        print("✅ Project saved successfully!")
    except Exception as e:
        print(f"❌ Error saving project: {e}")
        return False
    
    print("\n🎉 Done! VoiceCommand files should now be properly added to the Xcode project.")
    return True

if __name__ == "__main__":
    main()