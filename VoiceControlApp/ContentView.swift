import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Voice Control")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("iOS Voice Control App")
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
    }
}

#Preview {
    ContentView()
}