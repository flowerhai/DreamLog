//
//  PaywallView.swift
//  DreamLog - 付费墙 UI 界面
//
//  Phase 87 - App Store 发布与高级功能
//  Created: 2026-03-22
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedPlan: Product?
    @State private var isPurchasing = false
    @State private var showRestoreConfirmation = false
    @State private var purchaseError: String?
    @State private var showSuccessAnimation = false
    
    private let config = PaywallConfig()
    
    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient
            
            // 动画星星
            animatedStars
            
            VStack(spacing: 0) {
                // 关闭按钮
                closeButton
                
                Spacer()
                
                // 主内容
                mainContent
                
                Spacer()
                
                // 订阅计划选择
                planSelection
                
                // 购买按钮
                purchaseButton
                
                // 恢复购买
                restoreButton
                
                // 底部条款
                footerTerms
            }
            .padding()
        }
        .task {
            await subscriptionManager.fetchAvailableProducts()
            if let plan = subscriptionManager.recommendedPlan {
                selectedPlan = plan
            }
        }
        .alert("错误", isPresented: .constant(purchaseError != nil)) {
            Button("确定", role: .cancel) {
                purchaseError = nil
            }
        } message: {
            Text(purchaseError ?? "")
        }
        .confirmationDialog("恢复购买", isPresented: $showRestoreConfirmation) {
            Button("恢复购买") {
                Task {
                    await restorePurchases()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将检查您之前的购买记录并恢复订阅")
        }
        .overlay {
            if showSuccessAnimation {
                successAnimationOverlay
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "1a1a3e"),  // 深蓝紫
                Color(hex: "2d1b4e"),  // 紫色
                Color(hex: "1a1a3e")   // 深蓝紫
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var animatedStars: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { index in
                StarView(
                    size: CGFloat.random(in: 2...5),
                    x: CGFloat.random(in: 0...geometry.size.width),
                    y: CGFloat.random(in: 0...geometry.size.height),
                    duration: CGFloat.random(in: 2...4)
                )
            }
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            // 皇冠图标
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 10)
            
            // 标题
            Text(config.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // 副标题
            Text(config.subtitle)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // 免费试用标签
            if subscriptionManager.subscriptionStatus == .notSubscribed {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("新用户享 \(config.freeTrialDays) 天免费试用")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.yellow)
                )
            }
            
            // 功能列表
            featureList
        }
    }
    
    private var featureList: some View {
        VStack(spacing: 12) {
            ForEach(config.featuredFeatures, id: \.self) { feature in
                FeatureRow(feature: feature)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Plan Selection
    
    private var planSelection: some View {
        VStack(spacing: 12) {
            // 月度计划
            if let monthlyPlan = subscriptionManager.availableProducts.first(where: { $0.productID == SubscriptionProducts.premiumMonthly }) {
                PlanCard(
                    product: monthlyPlan,
                    isSelected: selectedPlan?.productID == monthlyPlan.productID,
                    tier: .premium
                ) {
                    selectedPlan = monthlyPlan
                }
            }
            
            // 年度计划 (推荐)
            if let yearlyPlan = subscriptionManager.availableProducts.first(where: { $0.productID == SubscriptionProducts.premiumYearly }) {
                PlanCard(
                    product: yearlyPlan,
                    isSelected: selectedPlan?.productID == yearlyPlan.productID,
                    tier: .premium,
                    isRecommended: true
                ) {
                    selectedPlan = yearlyPlan
                }
            }
            
            // 终身计划
            if let lifetimePlan = subscriptionManager.availableProducts.first(where: { $0.productID == SubscriptionProducts.lifetime }) {
                PlanCard(
                    product: lifetimePlan,
                    isSelected: selectedPlan?.productID == lifetimePlan.productID,
                    tier: .lifetime
                ) {
                    selectedPlan = lifetimePlan
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        Button(action: {
            Task {
                await purchase()
            }
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("处理中...")
                } else {
                    if let plan = selectedPlan {
                        if plan.productID == SubscriptionProducts.lifetime {
                            Text("立即购买 • \(formatPrice(plan.price))")
                        } else {
                            Text("免费试用 \(config.freeTrialDays) 天 • 之后 \(formatPrice(plan.price))")
                        }
                    } else {
                        Text("选择订阅计划")
                    }
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(isPurchasing || selectedPlan == nil)
        .padding(.bottom, 12)
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
        Button(action: {
            showRestoreConfirmation = true
        }) {
            Text("恢复购买")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Footer Terms
    
    private var footerTerms: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Button("服务条款") {
                    openURL("https://dreamlog.app/terms")
                }
                
                Text("•")
                    .foregroundColor(.white.opacity(0.5))
                
                Button("隐私政策") {
                    openURL("https://dreamlog.app/privacy")
                }
            }
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.7))
            
            Text("订阅将通过 iTunes 账户确认购买。订阅将自动续期，除非在当前期间结束前至少 24 小时关闭自动续期。")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Success Animation Overlay
    
    private var successAnimationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("订阅成功！")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("感谢升级至高级版")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Actions
    
    private func purchase() async {
        guard let plan = selectedPlan else { return }
        
        isPurchasing = true
        purchaseError = nil
        
        do {
            let success = try await subscriptionManager.purchase(plan)
            
            if success {
                withAnimation {
                    showSuccessAnimation = true
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                await MainActor.run {
                    dismiss()
                }
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        
        isPurchasing = false
    }
    
    private func restorePurchases() async {
        isPurchasing = true
        
        do {
            try await subscriptionManager.restorePurchases()
        } catch {
            purchaseError = error.localizedDescription
        }
        
        isPurchasing = false
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: price)) ?? "¥\(Int(price))"
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 12) {
            Text(feature.icon)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let tier: SubscriptionTier
    var isRecommended: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 选择指示器
                Circle()
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.3), lineWidth: 3)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 14, height: 14)
                        }
                    }
                
                // 计划信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(tier.displayName)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if isRecommended {
                            Text("推荐")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(formatPrice(product.price))")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // 层级图标
                Text(tier.icon)
                    .font(.system(size: 24))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: price)) ?? "¥\(Int(price))"
    }
}

// MARK: - Star View

struct StarView: View {
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let duration: CGFloat
    
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = Double.random(in: 0.3...1.0)
                }
            }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
