import SwiftUI
import Foundation
import GoogleSignIn
import FirebaseAuth
#if DEBUG
import HotSwiftUI
#endif

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        print("🔍 AuthenticationManager initialized")
        setupAuthStateListener()
        
        // Check if there's already a user signed in
        if let currentFirebaseUser = Auth.auth().currentUser {
            print("🔍 Found existing Firebase user: \(currentFirebaseUser.email ?? "Unknown")")
        } else {
            print("🔍 No existing Firebase user found")
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.handleAuthStateChange(user: user)
            }
        }
    }
    
    @MainActor
    private func handleAuthStateChange(user: FirebaseAuth.User?) {
        print("🔍 Auth state changed - User: \(user?.email ?? "none")")
        
        if let user = user {
            // Add 0.5 second delay to see authentication flow
            print("⏱️ Delaying auto-restore by 0.5 seconds...")
            Task {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    // User is signed in
                    self.currentUser = User(
                        id: user.uid,
                        email: user.email ?? "",
                        displayName: user.displayName ?? user.email ?? "Unknown User"
                    )
                    self.authState = .authenticated
                    print("✅ Auto-restored user session: \(user.email ?? "Unknown")")
                    self.isLoading = false
                }
            }
        } else {
            // User is signed out
            self.currentUser = nil
            self.authState = .unauthenticated
            print("🔓 User session ended")
            self.isLoading = false
        }
    }
    
    @MainActor
    func signInWithGoogle() async {
        authState = .authenticating
        isLoading = true
        errorMessage = nil
        
        print("🔵 Google Sign-In initiated")
        
        guard let presentingViewController = await UIApplication.shared.firstKeyWindow?.rootViewController else {
            errorMessage = "No presenting view controller available"
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                errorMessage = "Failed to extract authentication token"
                isLoading = false
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Force immediate auth state update
            DispatchQueue.main.async {
                self.handleAuthStateChange(user: authResult.user)
            }
            
            print("✅ Google Sign-In successful - User: \(authResult.user.email ?? "Unknown")")
            
        } catch {
            print("❌ Google Sign-In failed: \(error)")
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            authState = .unauthenticated
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            print("🔓 User signed out successfully")
            
        } catch {
            print("❌ Sign out failed: \(error)")
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func clearError() {
        errorMessage = nil
        if case .error = authState {
            authState = .unauthenticated
        }
    }
}

// MARK: - Models
enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated
    case error(String)
}

struct User {
    let id: String
    let email: String
    let displayName: String?
}

// MARK: - Google Sign-In Service
class GoogleSignInService {
    static func configure() {
        // Try Firebase configuration first
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            
            // Method 1: Try to use a web client ID if available
            if let webClientId = plist["CLIENT_ID"] as? String {
                print("🔵 GoogleSignInService: Using web CLIENT_ID: \(webClientId)")
                let config = GIDConfiguration(clientID: webClientId)
                GIDSignIn.sharedInstance.configuration = config
                print("✅ GoogleSignInService: Configuration completed with web client ID")
                return
            }
            
            // Method 2: Derive client ID from reversed client ID
            if let reversedClientId = plist["REVERSED_CLIENT_ID"] as? String {
                let clientId = reversedClientId.replacingOccurrences(of: "com.googleusercontent.apps.", with: "") + ".apps.googleusercontent.com"
                print("🔵 GoogleSignInService: Using derived clientID: \(clientId)")
                print("🔵 GoogleSignInService: From reversedClientID: \(reversedClientId)")
                
                let config = GIDConfiguration(clientID: clientId)
                GIDSignIn.sharedInstance.configuration = config
                print("✅ GoogleSignInService: Configuration completed with derived client ID")
                return
            }
        }
        
        print("❌ GoogleSignInService: GoogleService-Info.plist not found or missing client ID")
    }
    
    static func handleURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - UIApplication Extension
extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.windows
            .first { $0.isKeyWindow }
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab: AuthTab = .signIn
    
    enum AuthTab: CaseIterable {
        case signIn
        case signUp
        
        var title: String {
            switch self {
            case .signIn: return "Sign In"
            case .signUp: return "Sign Up"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                authHeaderView
                
                // Tab Selection
                authTabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    SignInView()
                        .tag(AuthTab.signIn)
                        .environmentObject(authManager)
                    
                    SignUpView()
                        .tag(AuthTab.signUp)
                        .environmentObject(authManager)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
    
    private var authHeaderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            VStack(spacing: 8) {
                Text("Voice Control")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Enterprise-grade authentication with Google Sign-In")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 32)
    }
    
    private var authTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AuthTab.allCases, id: \.self) { tab in
                Button(action: {
                    print("🔵 Tab button tapped: \(tab.title)")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.title)
                            .font(.headline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}

struct SignInView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Sign In Button
                Button(action: {
                    print("🔵 Email/Password button tapped")
                    Task { await signIn() }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(authManager.isLoading)
                .allowsHitTesting(!authManager.isLoading)
                
                // Google Sign-In Section
                VStack(spacing: 16) {
                    Text("Or continue with")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        print("🔵 Google Sign-In button tapped")
                        Task { await authManager.signInWithGoogle() }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(authManager.isLoading)
                    .allowsHitTesting(!authManager.isLoading)
                }
                
                // Error Display
                if let errorMessage = authManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Success Display
                if authManager.authState == .authenticated {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("✅ Authentication Successful!")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            Spacer()
                        }
                        
                        if let user = authManager.currentUser {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome, \(user.displayName ?? "User")!")
                                    .font(.headline)
                                Text("Email: \(user.email)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }
    
    private func signIn() async {
        authManager.clearError()
        print("🔵 Email/Password Sign-In: \(email)")
    }
}

struct SignUpView: View {
    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.title)
            Text("Create your account here")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}


// MARK: - ContentView (Entry Point)
struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    #if DEBUG
    @ObservedObject var iO = injectionObserver
    #endif
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .authenticated:
                VoiceControlMainView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("🎯 SHOWING VoiceControlMainView - Auth state: .authenticated")
                    }
            case .unauthenticated:
                AuthenticationView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("🔓 SHOWING AuthenticationView - Auth state: .unauthenticated")
                    }
            case .authenticating:
                AuthenticationView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("⏳ SHOWING AuthenticationView - Auth state: .authenticating")
                    }
            case .error(let message):
                AuthenticationView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("❌ SHOWING AuthenticationView - Auth state: .error(\(message))")
                    }
            }
        }
        #if DEBUG
        .enableInjection()
        #endif
    }
}

// MARK: - Voice Control Main App
struct VoiceControlMainView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var speechText: String = ""
    @State private var isRecording: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with user info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Voice Control")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let user = authManager.currentUser {
                            Text("Welcome, \(user.displayName?.split(separator: " ").first.map(String.init) ?? "User")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Sign Out Button (more prominent)
                    Button(action: {
                        print("🔴 Sign Out button tapped")
                        Task { await authManager.signOut() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Main Speech Text Box
                VStack(spacing: 16) {
                    Text("Speech Recognition")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(speechText.isEmpty ? "Tap the microphone to start speaking..." : speechText)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(speechText.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRecording ? Color.red : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Microphone Button
                Button(action: {
                    toggleRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                            .shadow(radius: isRecording ? 8 : 4)
                        
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                Spacer()
                
                // Status Text
                Text(isRecording ? "🎤 Listening..." : "Tap microphone to speak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            print("✅ VoiceControlMainView appeared - User: \(authManager.currentUser?.email ?? "Unknown")")
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            // Start speech recognition
            speechText = "Recording started... (Speech recognition will be implemented next)"
            print("🎤 Started recording")
        } else {
            // Stop speech recognition
            speechText += "\n\nRecording stopped."
            print("🛑 Stopped recording")
        }
    }
}

#Preview {
    ContentView()
}