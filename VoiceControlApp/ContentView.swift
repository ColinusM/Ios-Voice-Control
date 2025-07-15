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
    
    init() {}
    
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
            
            currentUser = User(
                id: authResult.user.uid,
                email: authResult.user.email ?? "",
                displayName: authResult.user.displayName
            )
            
            authState = .authenticated
            print("✅ Google Sign-In successful")
            
        } catch {
            print("❌ Google Sign-In failed: \(error)")
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            authState = .unauthenticated
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
    @StateObject private var authManager = AuthenticationManager()
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
    #if DEBUG
    @ObservedObject var iO = injectionObserver
    #endif
    
    var body: some View {
        AuthenticationView()
        #if DEBUG
        .enableInjection()
        #endif
    }
}

#Preview {
    ContentView()
}