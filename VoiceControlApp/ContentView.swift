import SwiftUI
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
                
                Text("✅ DEVICE  SUCCESS! ✅")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("iOS  App")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    Button(action: {
                        // Authentication action
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
                        // Voice control action
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