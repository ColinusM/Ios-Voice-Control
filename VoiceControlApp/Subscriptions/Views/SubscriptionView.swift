import SwiftUI
import StoreKit

// MARK: - Subscription Purchase View

struct SubscriptionView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: SubscriptionPlan?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Voice Control Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Unlimited voice commands with advanced mixing console control")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Current Usage (for guest users)
                    if authManager.authState == .guest, let guestUser = authManager.guestUser {
                        VStack(spacing: 12) {
                            Text("Current Usage")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Free Time Used:")
                                    Spacer()
                                    Text(guestUser.usedTimeText)
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Remaining:")
                                    Spacer()
                                    Text(guestUser.remainingUsageText)
                                        .fontWeight(.medium)
                                        .foregroundColor(guestUser.usageWarningLevel == .critical ? .red : .primary)
                                }
                                
                                ProgressView(value: guestUser.usagePercentage)
                                    .progressViewStyle(LinearProgressViewStyle(tint: guestUser.usageWarningLevel == .critical ? .red : .blue))
                                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Subscription Plans
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(subscriptionManager.availablePlans, id: \.id) { plan in
                            PlanCardView(
                                plan: plan,
                                isSelected: selectedPlan?.id == plan.id,
                                onSelect: {
                                    selectedPlan = plan
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // Purchase Button
                    if let selectedPlan = selectedPlan {
                        Button(action: {
                            purchaseSubscription(selectedPlan)
                        }) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "crown.fill")
                                        .font(.title3)
                                }
                                
                                Text(isPurchasing ? "Processing..." : selectedPlan.actionButtonText)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPurchasing ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isPurchasing)
                        .padding(.horizontal)
                    }
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's Included")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                            ForEach(proFeatures, id: \.self) { feature in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                    
                                    Text(feature)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            Button("Terms of Service") {
                                // Open terms URL
                            }
                            .font(.caption)
                            
                            Button("Privacy Policy") {
                                // Open privacy URL
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Load available plans
            Task {
                await subscriptionManager.loadAvailableProducts()
            }
            
            // Pre-select the monthly plan if available
            if selectedPlan == nil {
                selectedPlan = subscriptionManager.availablePlans.first
            }
        }
    }
    
    private var proFeatures: [String] {
        [
            "Unlimited voice recognition time",
            "Advanced mixing console control",
            "Cloud sync across devices",
            "Priority customer support",
            "Premium voice processing features",
            "No usage limits or restrictions",
            "Ad-free experience"
        ]
    }
    
    private func purchaseSubscription(_ plan: SubscriptionPlan) {
        guard !isPurchasing else { return }
        
        isPurchasing = true
        
        Task {
            await subscriptionManager.purchase(plan)
            
            await MainActor.run {
                isPurchasing = false
                
                // Check subscription state to determine success
                if subscriptionManager.subscriptionState.canAccessAPI {
                    // Purchase successful - dismiss view
                    dismiss()
                } else {
                    // Show generic error
                    errorMessage = "Purchase failed. Please try again."
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionManager())
        .environmentObject(AuthenticationManager())
}