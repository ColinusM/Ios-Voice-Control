# InjectionIII Setup Guide - Based on Official GitHub Documentation

## Critical Setup Requirements (from original docs)

### 1. Xcode Project Requirements
- Create actual Xcode project (not just Swift Package)
- Bundle ID: `com.voicecontrol.app` (exact match to Firebase)
- Deployment Target: iOS 16.0+

### 2. Debug Configuration Linker Flags
Add to "Other Linker Flags" in Debug configuration ONLY:
```
-Xlinker
-interposable
```

### 3. Xcode 16.3+ Specific Requirement
Add user-defined build setting in Debug configuration:
```
EMIT_FRONTEND_COMMAND_LINES = YES
```

### 4. App Initialization Code
Add to App or AppDelegate:
```swift
#if DEBUG
Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
#endif
```

### 5. SwiftUI View Integration
For each SwiftUI view:
```swift
import Inject

struct ContentView: View {
    @ObserveInjection var inject
    
    var body: some View {
        VStack {
            // Your UI code
        }
        .enableInjection()
    }
}
```

### 6. Device Injection (iPhone X)
For real device hot reloading:
```bash
defaults write com.johnholdsworth.InjectionIII deviceUnlock any
```

## Current Status
- ✅ InjectionIII app installed and running
- ✅ Swift Package dependencies configured
- ❌ Need actual Xcode project with proper build settings
- ❌ Need linker flags and bundle loading
- ✅ Scripts placed in project root

## Next Steps
1. Create proper Xcode project structure
2. Configure build settings per official docs
3. Add initialization code
4. Test hot reload functionality