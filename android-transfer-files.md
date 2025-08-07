# Files to Copy to Android Repository

After cloning your new Android repository, copy these essential files:

## 1. Main PRP Documentation
```bash
cp /Users/colinmignot/Claude\ Code/AndroidVoiceApp/Ios-Voice-Control/PRPs/ios-to-android-conversion-parallel.md ./PRPs/
```

## 2. Development Agent Configuration
```bash
mkdir -p claude_md_files
cp /Users/colinmignot/Claude\ Code/AndroidVoiceApp/Ios-Voice-Control/claude_md_files/CLAUDE-JAVA-GRADLE.md ./claude_md_files/
```

## 3. Firebase Configuration (if needed)
```bash
mkdir -p Firebase
cp -r /Users/colinmignot/Claude\ Code/AndroidVoiceApp/Ios-Voice-Control/Firebase/* ./Firebase/
```

## 4. Professional Audio Documentation
```bash
mkdir -p docs
cp -r /Users/colinmignot/Claude\ Code/AndroidVoiceApp/Ios-Voice-Control/docs/yamaha-rcp ./docs/
```

## 5. Create Android-Specific CLAUDE.md
```bash
# This will be created with Android-specific instructions
```

## Commands to Run After Setup:
```bash
# Add all files
git add .

# Commit initial setup
git commit -m "feat: initial Android Voice Control app setup

- Add comprehensive iOS to Android conversion PRP
- Include Android development configuration
- Set up Firebase integration documentation
- Add Yamaha RCP mixer control documentation

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to new repository
git push origin main
```