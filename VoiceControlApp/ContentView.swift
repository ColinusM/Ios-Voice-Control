import SwiftUI
import Foundation
#if DEBUG
import HotSwiftUI
#endif

struct ContentView: View {
    #if DEBUG
    @ObservedObject var iO = injectionObserver
    #endif
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("🎯 LOG CAPTURE TEST 🎯")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("iOS  App")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    Button(action: {
                        NSLog("🔵 Sign In button tapped - User wants to authenticate")
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                            Text("Sign In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        NSLog("🟢 Voice Control button tapped - User wants to start voice control")
                    }) {
                        HStack {
                            Image(systemName: "mic")
                            Text("Start Voice Control")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Voice Control")
        }
        #if DEBUG
        .enableInjection()
        #endif
    }
}

#Preview {
    ContentView()
}