import SwiftUI

// MARK: - Subscription Plan Card Component

struct PlanCardView: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isYearlyPlan: Bool {
        plan.billingPeriod == .yearly
    }
    
    private var badgeText: String? {
        if isYearlyPlan {
            return "BEST VALUE"
        }
        return nil
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                // Badge for yearly plan
                HStack {
                    if let badgeText = badgeText {
                        Text(badgeText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .gray.opacity(0.5))
                }
                
                // Plan Info
                VStack(spacing: 12) {
                    // Plan name
                    Text(plan.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Description
                    Text(plan.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Pricing
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(plan.formattedPrice)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("/ \(plan.billingPeriod.shortDisplayText)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Trial information
                        if let trialText = plan.trialText {
                            Text(trialText)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        
                        // Savings for yearly plan
                        if isYearlyPlan {
                            Text("Save 17% compared to monthly")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Key Features (limit to top 3)
                if !plan.features.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(plan.features.prefix(3).enumerated()), id: \.offset) { _, feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text(feature)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                        
                        // Show more features indicator
                        if plan.features.count > 3 {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("\(plan.features.count - 3) more features")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading State Card

struct PlanCardLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
            
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 24)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 32)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 16)
                    
                    Spacer()
                }
            }
            
            Divider()
            
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 12, height: 12)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// MARK: - Shimmer Effect Extension

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview("Plan Card") {
    VStack(spacing: 16) {
        PlanCardView(
            plan: SubscriptionPlan.monthlyPro,
            isSelected: false,
            onSelect: {}
        )
        
        PlanCardView(
            plan: SubscriptionPlan.yearlyPro,
            isSelected: true,
            onSelect: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Loading Card") {
    PlanCardLoadingView()
        .padding()
        .background(Color.gray.opacity(0.1))
}