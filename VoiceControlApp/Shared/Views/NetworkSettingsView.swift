import SwiftUI

// MARK: - Network Settings View

/// Settings view for configuring RCP command network targets
struct NetworkSettingsView: View {
    
    // MARK: - Properties
    
    @StateObject private var networkSettings = NetworkSettings.shared
    @StateObject private var networkClient = RCPNetworkClient.shared
    
    @State private var isTestingConnection = false
    @State private var testResult: String?
    @State private var showingResetAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Target Selection Section
                targetSelectionSection
                
                // Console Configuration Section
                if networkSettings.shouldSendToConsole {
                    consoleConfigurationSection
                }
                
                // Testing Configuration Section
                if networkSettings.shouldSendToGUI {
                    testingConfigurationSection
                }
                
                // Connection Status Section
                connectionStatusSection
                
                // Advanced Settings Section
                advancedSettingsSection
                
                // Actions Section
                actionsSection
            }
            .navigationTitle("🌐 Network Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        networkSettings.saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                networkSettings.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all network settings to factory defaults. This action cannot be undone.")
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var targetSelectionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Target")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ForEach(NetworkTargetType.allCases, id: \.self) { targetType in
                    targetOptionView(targetType)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("🎯 Command Destination")
        } footer: {
            Text(networkSettings.targetType.description)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func targetOptionView(_ targetType: NetworkTargetType) -> some View {
        HStack {
            Button(action: {
                networkSettings.targetType = targetType
            }) {
                HStack {
                    Image(systemName: networkSettings.targetType == targetType ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(networkSettings.targetType == targetType ? .blue : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(targetType.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(targetType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var consoleConfigurationSection: some View {
        Section {
            // Console IP Address
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Console IP Address")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    TextField("192.168.1.100", text: $networkSettings.consoleIP)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .padding(.vertical, 4)
            
            // Console Port
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Console Port")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    TextField("49280", value: $networkSettings.consolePort, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            .padding(.vertical, 4)
            
            // Test Console Connection
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test Console Connection")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Button(action: testConsoleConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.circle.fill")
                            }
                            
                            Text("Test Connection")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isTestingConnection ? Color.gray : Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(isTestingConnection)
                }
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("🎛️ Yamaha Console Configuration")
        } footer: {
            Text("Standard Yamaha RCP port is 49280. Ensure console is on same network.")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var testingConfigurationSection: some View {
        Section {
            // Testing IP Address
            HStack {
                Image(systemName: "desktopcomputer")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mac GUI IP Address")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    TextField("192.168.1.50", text: $networkSettings.testingIP)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .padding(.vertical, 4)
            
            // Testing Port
            HStack {
                Image(systemName: "network.badge.shield.half.filled")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("GUI Port")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    TextField("8080", value: $networkSettings.testingPort, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            .padding(.vertical, 4)
            
            // Test GUI Connection
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test GUI Connection")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Button(action: testGUIConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.circle.fill")
                            }
                            
                            Text("Test Connection")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isTestingConnection ? Color.gray : Color.orange)
                        .cornerRadius(8)
                    }
                    .disabled(isTestingConnection)
                }
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("🖥️ Mac GUI Testing Configuration")
        } footer: {
            Text("For development testing. Run gui_receiver.py on your Mac first.")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var connectionStatusSection: some View {
        Section {
            HStack {
                connectionStatusIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection Status")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(networkSettings.connectionStatus.displayText)
                        .font(.caption)
                        .foregroundColor(connectionStatusColor)
                }
                
                Spacer()
                
                // Network availability indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(networkClient.isNetworkAvailable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(networkClient.isNetworkAvailable ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // Last connection time
            if let lastConnection = networkSettings.lastConnectionTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last Successful Connection")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: lastConnection, relativeTo: Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            // Test result display
            if let testResult = testResult {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Test Result")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(testResult)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
        } header: {
            Text("📊 Connection Status")
        }
    }
    
    @ViewBuilder
    private var advancedSettingsSection: some View {
        Section {
            // Timeout Setting
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connection Timeout")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(value: $networkSettings.timeoutSeconds, in: 1...30, step: 1)
                        
                        Text("\(Int(networkSettings.timeoutSeconds))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Logging Toggle
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Network Logging")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Toggle("", isOn: $networkSettings.enableLogging)
                        .labelsHidden()
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("⚙️ Advanced Settings")
        } footer: {
            Text("Network logging helps with troubleshooting connection issues.")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var actionsSection: some View {
        Section {
            // Reset to Defaults
            Button(action: {
                showingResetAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.red)
                    
                    Text("Reset to Defaults")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            
        } header: {
            Text("🔄 Actions")
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusIcon: some View {
        let (iconName, color) = {
            switch networkSettings.connectionStatus {
            case .disconnected:
                return ("wifi.slash", Color.gray)
            case .connecting:
                return ("wifi.exclamationmark", Color.orange)
            case .connected:
                return ("wifi", Color.green)
            case .error:
                return ("wifi.exclamationmark", Color.red)
            }
        }()
        
        return Image(systemName: iconName)
            .foregroundColor(color)
            .frame(width: 24)
    }
    
    private var connectionStatusColor: Color {
        switch networkSettings.connectionStatus {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .error:
            return .red
        }
    }
    
    // MARK: - Actions
    
    private func testConsoleConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            let result = await networkClient.testConnection(
                ip: networkSettings.consoleIP,
                port: networkSettings.consolePort
            )
            
            await MainActor.run {
                isTestingConnection = false
                
                switch result {
                case .success(let message):
                    testResult = "✅ Console: \(message)"
                case .failure(let error):
                    testResult = "❌ Console: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func testGUIConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            let result = await networkClient.testConnection(
                ip: networkSettings.testingIP,
                port: networkSettings.testingPort
            )
            
            await MainActor.run {
                isTestingConnection = false
                
                switch result {
                case .success(let message):
                    testResult = "✅ GUI: \(message)"
                case .failure(let error):
                    testResult = "❌ GUI: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NetworkSettingsView()
}