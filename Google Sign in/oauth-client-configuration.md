# Google OAuth Client Configuration

## Configuration Details from Google Cloud Console

### OAuth Client Created
**Status**: ✅ Client OAuth créé (OAuth Client Created)

### Client Information
- **Project**: ios-voice-control
- **Application Type**: iOS
- **Application Name**: IosVoiceControl
- **Bundle ID**: com.voicecontrol.app

### OAuth Client ID
```
1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv.apps.googleusercontent.com
```

### Additional Information from Screenshot
- **French Interface Text**: "Un ID client sert à identifier une application unique auprès des serveurs OAuth de Google. Si votre application s'exécute sur plusieurs plates-formes, chacune d'elle devra posséder son propre ID client."
- **Translation**: "A client ID is used to identify a unique application with Google's OAuth servers. If your application runs on multiple platforms, each of them will need to have its own client ID."

### Configuration Notes
- OAuth is limited to 100 connections in sensitive scopes until the OAuth consent screen is validated
- This may require validation that can take several days
- The client can be accessed from the "Clients" tab in Google Auth Platform

### Files to Update
1. **GoogleService-Info.plist** - Update with new OAuth client information
2. **Info.plist** - Update URL schemes with correct reversed client ID
3. **ContentView.swift** - Update GoogleSignInService configuration

### Next Steps
1. Download the updated .plist file from Google Cloud Console
2. Replace the existing GoogleService-Info.plist in the iOS project
3. Update URL schemes in Info.plist to match the new client ID
4. Test the Google Sign-In flow with the new configuration

### URL Scheme Format
Based on the client ID, the URL scheme should be:
```
com.googleusercontent.apps.1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv
```

### Comparison with Current Configuration
- **Current Client ID**: 1020288809254-0f690b195cca167b47a9e7.apps.googleusercontent.com
- **New Client ID**: 1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv.apps.googleusercontent.com
- **Key Change**: The suffix changed from `0f690b195cca167b47a9e7` to `gs8jhl1ak8oi5rasarpc1i5cq28sokjv`