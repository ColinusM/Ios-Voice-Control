# Apple App Store Review Guidelines (2025)

**Source:** https://developer.apple.com/app-store/review/guidelines/  
**Last Updated:** May 2025  
**Status:** Living Document

## Overview

The App Store Review Guidelines provide guidance and examples across a range of development topics, including user interface design, functionality, content, and the use of specific technologies. These guidelines are intended to help you prepare your app for the App Review process and speed your app through review when you submit it.

**Key Principle:** When people install an app from the App Store, they want to feel confident that it's safe to do so—that the app doesn't contain upsetting or offensive content, won't damage their device, and isn't likely to cause physical harm from its use.

## Recent Updates (May 2025)

### United States Court Decision Compliance
The App Review Guidelines were updated on May 1, 2025, for compliance with a United States court decision regarding buttons, external links, and other calls to action in apps. These changes affect apps distributed on the United States storefront of the App Store.

**Key Changes:**
- Apps on the United States storefront are not prohibited from including buttons, external links, or other calls to action when allowing users to browse NFT collections owned by others
- No entitlement is required for NFT browsing functionality
- The prohibition on encouraging users to use a purchasing method other than in-app purchase does not apply on the United States storefront
- The External Link Account entitlement is not required for US storefront apps

## 1. Safety Guidelines

### 1.1 Objectionable Content
Apps must not include content that is:
- Offensive or discriminatory
- Defamatory, mean-spirited, or likely to place a targeted individual in harm's way
- Designed to upset or disgust users
- Excessively violent or graphic
- Promoting illegal activities

### 1.2 User-Generated Content
Apps with user-generated content must:
- Implement robust content moderation
- Provide clear reporting mechanisms
- Remove problematic content promptly
- Block abusive users
- Publish content guidelines for users

### 1.3 Kids Category
Apps targeting children must:
- Comply with applicable privacy laws
- Not include behavioral advertising
- Request parental permission for data collection
- Provide appropriate content filtering
- Use age-appropriate language and imagery

### 1.4 Physical Harm
Apps must not:
- Encourage dangerous or illegal activities
- Provide inaccurate device data that could be used to make health decisions
- Facilitate illegal drug use or excessive alcohol consumption
- Encourage reckless behavior

### 1.5 Developer Information
Developers must:
- Provide accurate contact information
- Update apps to fix bugs and improve user experience
- Respond to user feedback and support requests
- Maintain truthful app descriptions

## 2. Performance Guidelines

### 2.1 App Completeness
Apps must be:
- Complete and functional
- Ready for public use
- Free of placeholder content
- Fully tested and bug-free
- Include all necessary metadata

### 2.2 Beta Testing
- Use TestFlight for beta testing
- Don't distribute incomplete apps
- Ensure proper testing before submission
- Remove test content before release

### 2.3 Accurate Metadata
App metadata must:
- Accurately describe the app's functionality
- Include relevant keywords
- Provide clear, high-quality screenshots
- Use appropriate age ratings
- Include accurate app descriptions

### 2.4 Hardware Compatibility
Apps must:
- Run on the devices they claim to support
- Use device capabilities efficiently
- Provide graceful degradation on older devices
- Respect battery life and device performance

### 2.5 Software Requirements
Apps must:
- Use public APIs only
- Follow platform conventions
- Include proper error handling
- Provide offline functionality where appropriate

## 3. Business Guidelines

### 3.1 Payments
#### 3.1.1 In-App Purchase
Apps must use Apple's in-app purchase system for:
- Digital content and services
- App functionality
- Subscriptions
- Premium features

#### 3.1.2 Subscriptions
Subscription apps must:
- Provide clear value to users
- Offer transparent pricing
- Include family sharing where appropriate
- Provide easy cancellation

#### 3.1.3 External Payment Methods
- Generally prohibited except for specific exceptions
- Physical goods and services may use external payment
- Reader apps may link to external websites
- US storefront apps have relaxed restrictions (May 2025 update)

### 3.2 Other Business Model Issues
#### 3.2.1 Acceptable
- Freemium models with clear value
- Advertising (when appropriate)
- Physical goods and services
- Enterprise and education tools

#### 3.2.2 Unacceptable
- Charity fundraising without proper verification
- Loan and payday loan apps
- Gambling without licenses
- Contest and sweepstakes without legal compliance

## 4. Design Guidelines

### 4.1 Copycats
Apps must:
- Provide unique value and functionality
- Not copy other apps without adding value
- Create original content and design
- Avoid misleading similarities to other apps

### 4.2 Minimum Functionality
Apps must:
- Provide substantial utility
- Go beyond basic web browsing
- Include meaningful functionality
- Justify their existence on the platform

### 4.3 Spam
Apps must not:
- Flood the App Store with similar apps
- Use misleading titles or descriptions
- Manipulate rankings or reviews
- Submit multiple similar apps

### 4.4 Extensions
App extensions must:
- Provide functionality related to the main app
- Not include advertising
- Respect user privacy
- Follow extension-specific guidelines

### 4.5 Apple Sites and Services
When using Apple services:
- Follow Apple's branding guidelines
- Use services appropriately
- Respect rate limits and terms of service
- Provide accurate implementation

## 5. Legal Guidelines

### 5.1 Privacy
Apps must:
- Implement comprehensive privacy protection
- Request permission for data access
- Provide clear privacy policies
- Respect user consent
- Minimize data collection
- Secure user data appropriately

#### 5.1.1 Data Collection and Storage
- Only collect necessary data
- Provide clear explanations for data use
- Implement proper security measures
- Allow users to delete their data
- Comply with regional privacy laws

#### 5.1.2 Data Use and Sharing
- Don't sell user data to third parties
- Obtain consent for data sharing
- Provide transparency about data practices
- Allow users to control their data

### 5.2 Intellectual Property
Apps must:
- Respect copyrights and trademarks
- Only use content you own or have permission to use
- Properly attribute third-party content
- Avoid trademark confusion
- Respect patent rights

### 5.3 Gaming, Gambling, and Lotteries
Gaming apps must:
- Comply with local gambling laws
- Provide appropriate age ratings
- Include responsible gaming features
- Obtain necessary licenses
- Avoid misleading users about odds

### 5.4 VPN Apps
VPN apps must:
- Use only public APIs
- Provide clear privacy policies
- Explain their functionality clearly
- Comply with local laws
- Avoid logging user activity

### 5.5 Developer Code of Conduct
Developers must:
- Follow the Developer Program License Agreement
- Respect user privacy and security
- Provide accurate information
- Respond to Apple's requests
- Maintain professional conduct

## Specific Considerations for Voice Control Apps

### Audio and Privacy
For voice control apps like this iOS Voice Control app:
- **Microphone Permission**: Clearly explain why microphone access is needed
- **Data Processing**: Be transparent about how audio is processed
- **Storage**: Explain if/how audio data is stored
- **Third-Party Services**: Disclose use of external speech recognition services (like AssemblyAI)

### Authentication and User Data
- **OAuth Implementation**: Ensure proper implementation of Google Sign-In
- **User Consent**: Clearly explain data collection and usage
- **Data Retention**: Implement appropriate data retention policies
- **Security**: Use proper encryption and security measures

### Accessibility
- **Voice Commands**: Provide alternative input methods
- **Visual Feedback**: Ensure proper visual indicators for voice state
- **Hearing Impairment**: Consider users with hearing difficulties

## Compliance Checklist for Voice Control App

### Pre-Submission Checklist
- [ ] App is complete and fully functional
- [ ] All features work as described
- [ ] Microphone permission properly requested and explained
- [ ] Google Sign-In implemented correctly
- [ ] Privacy policy includes audio processing disclosure
- [ ] App metadata accurately describes functionality
- [ ] Screenshots show actual app functionality
- [ ] No placeholder content or test data
- [ ] Error handling implemented for all network requests
- [ ] Offline functionality or proper error messages
- [ ] Appropriate age rating selected
- [ ] App follows iOS design guidelines
- [ ] Third-party SDKs properly integrated
- [ ] App doesn't crash or freeze
- [ ] Performance optimized for target devices

### Privacy and Security
- [ ] Data collection minimized to necessary functions
- [ ] Clear privacy policy provided
- [ ] User consent obtained for data processing
- [ ] Secure data transmission implemented
- [ ] Authentication properly implemented
- [ ] No sensitive data logged or exposed
- [ ] Biometric authentication properly protected

### Business Model
- [ ] In-app purchase implementation (if applicable)
- [ ] Subscription terms clearly explained (if applicable)
- [ ] No prohibited monetization methods
- [ ] Clear value proposition for users

## Additional Resources

### Apple Developer Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Common App Rejections](https://developer.apple.com/app-store/review/rejections/)

### Best Practices
- Test thoroughly on multiple devices
- Follow Apple's design principles
- Provide excellent user experience
- Maintain app quality over time
- Respond promptly to user feedback
- Stay updated with guideline changes

### Support and Appeals
- Use App Store Connect for submissions
- Respond to reviewer feedback promptly
- Use the Resolution Center for appeals
- Provide detailed explanations for complex functionality
- Include demo accounts or instructions for testing

---

**Note:** These guidelines are subject to change. Always refer to the official Apple Developer documentation for the most current version. The guidelines are a living document, and new apps presenting new questions may result in new rules at any time.

**For Voice Control App Developers:** Pay special attention to privacy guidelines, audio processing disclosure, and user consent requirements. Ensure your app provides clear value beyond basic functionality and follows all authentication and security best practices.