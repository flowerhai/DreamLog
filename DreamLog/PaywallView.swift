//
//  PaywallView.swift
//  DreamLog
//
//  Subscription Paywall UI
//  Phase 87: App Store Launch & Premium Features
//

import SwiftUI

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = SubscriptionManager.shared
    
    let sourceFeature: PremiumFeature?
    let config: PaywallConfig
    
    @State private var selectedPlan: SubscriptionPlan?
    @State private var isProcessing: Bool = false
    @State private var showRestoreAlert: Bool = false
    @State private var errorMessage: String?
    
    init(
        sourceFeature: PremiumFeature? = nil,
        config: PaywallConfig = .default
    ) {
        self.sourceFeature = sourceFeature
        self.config = config
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Stars background
                StarsBackground()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Features list
                    featuresSection
                    
                    // Plans
                    plansSection
                    
                    // Footer
                    footerSection
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("恢复购买", isPresented: $showRestoreAlert) {
                Button("取消", role: .cancel) {}
                Button("恢复") {
                    Task {
                        await restorePurchases()
                    }
                }
            } message: {
                Text("我们将检查您的购买历史记录并恢复任何可用的订阅。")
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "未知错误")
            }
        }
        .task {
            selectedPlan = manager.availablePlans.first { $0.period == config.defaultPlan }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Crown icon for premium
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 10)
            
            Text("解锁 DreamLog 高级版")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let feature = sourceFeature {
                Text("升级以使用 \(feature.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("解锁全部高级功能，获得更好的梦境体验")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Trial badge
            if config.showTrial {
                HStack {
                    Image(systemName: "gift.fill")
                    Text("免费试用 \(config.trialDays) 天")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow)
                .cornerRadius(20)
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级版包含:")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 8)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PremiumFeature.allCases.prefix(8), id: \.self) { feature in
                    FeatureRow(feature: feature)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Plans Section
    
    private var plansSection: some View {
        VStack(spacing: 12) {
            ForEach(manager.availablePlans, id: \.productId) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: selectedPlan?.productId == plan.productId,
                    onSelect: {
                        selectedPlan = plan
                    }
                )
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Subscribe button
            Button(action: subscribe) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(subscribeButtonText)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .disabled(selectedPlan == nil || isProcessing)
            .opacity(selectedPlan == nil || isProcessing ? 0.6 : 1.0)
            
            // Restore purchases
            Button(action: { showRestoreAlert = true }) {
                Text("恢复购买")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Terms
            HStack(spacing: 4) {
                Text("继续即表示您同意")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                Link("服务条款", destination: URL(string: "https://dreamlog.app/terms")!)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                Text("和")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                Link("隐私政策", destination: URL(string: "https://dreamlog.app/privacy")!)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Manage subscription (for existing subscribers)
            if manager.isPremium {
                Button(action: { manager.manageSubscription() }) {
                    Text("管理订阅")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.top)
    }
    
    // MARK: - Actions
    
    private var subscribeButtonText: String {
        guard let plan = selectedPlan else { return "选择订阅方案" }
        
        if config.showTrial && plan.period == .yearly && !manager.isPremium {
            return "免费试用 \(config.trialDays) 天"
        }
        
        switch plan.period {
        case .monthly: return "订阅每月 ¥39.99"
        case .yearly: return "订阅每年 ¥399.99"
        case .lifetime: return "购买终身版 ¥999.99"
        }
    }
    
    private func subscribe() {
        guard let plan = selectedPlan else { return }
        
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                try await manager.purchase(plan: plan)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await manager.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 8) {
            Text(feature.icon)
                .font(.title2)
            Text(feature.displayName)
                .font(.caption)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio button
                Circle()
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 10, height: 10)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.tier == "lifetime" ? "终身版" : "高级版")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if plan.isPopular {
                            Text("热门")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.period.displayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    if let savings = plan.period.savingsPercentage {
                        Text("节省 \(savings)%")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥\(String(format: "%.2f", plan.price))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(plan.period == .lifetime ? "" : "/\(plan.period == .monthly ? "月" : "年")")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stars Background

struct StarsBackground: View {
    @State private var stars: [Star] = (0..<50).map { _ in Star() }
    
    var body: some View {
        ZStack {
            ForEach(stars) { star in
                Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.size, height: star.size)
                    .position(x: star.x, y: star.y)
                    .animation(
                        Animation.easeInOut(duration: star.duration)
                            .repeatForever(autoreverses: true),
                        value: star.opacity
                    )
            }
        }
        .onAppear {
            withAnimation {
                stars = stars.map { star in
                    var newStar = star
                    newStar.opacity = Double.random(in: 0.3...1.0)
                    return newStar
                }
            }
        }
    }
}

struct Star: Identifiable {
    let id = UUID()
    var x: CGFloat = CGFloat.random(in: 0...1)
    var y: CGFloat = CGFloat.random(in: 0...1)
    var size: CGFloat = CGFloat.random(in: 1...3)
    var opacity: Double = 0.5
    var duration: Double = 2
}

// MARK: - Preview

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(sourceFeature: .unlimitedAIAnalysis)
    }
}
#endif
