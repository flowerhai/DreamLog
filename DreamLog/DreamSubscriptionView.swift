//
//  DreamSubscriptionView.swift
//  DreamLog
//
//  Phase 25 - App Store 发布准备
//  订阅与付费墙界面
//

import SwiftUI

// MARK: - 订阅主视图

struct DreamSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: SubscriptionTier = .premium
    @State private var isProcessing = false
    @State private var showSuccess = false
    
    let isPaywall: Bool
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 头部
                if !isPaywall {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                                .symbolEffect(.twinkle)
                            
                            Text(isPaywall ? "解锁 DreamLog 高级功能" : "升级高级版")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(isPaywall ? "立即解锁所有功能，开启完整梦境探索之旅" : "享受无限制的 AI 解析和高级功能")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, isPaywall ? 40 : 20)
                        
                        // 订阅层级选择
                        subscriptionTiersSection
                        
                        // 功能对比
                        featureComparisonSection
                        
                        // 用户评价
                        testimonialsSection
                        
                        // 保证说明
                        guaranteeSection
                    }
                    .padding(.horizontal, 20)
                }
                
                // 底部购买按钮
                purchaseButtonSection
            }
        }
        .alert("订阅成功", isPresented: $showSuccess) {
            Button("开始使用", action: {
                dismiss()
            })
        } message: {
            Text("感谢订阅！你现在可以解锁所有高级功能。")
        }
    }
    
    // MARK: - 订阅层级选择
    
    private var subscriptionTiersSection: some View {
        VStack(spacing: 12) {
            Text("选择适合你的方案")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 12) {
                // 免费版
                SubscriptionTierCard(
                    tier: .free,
                    isSelected: selectedTier == .free,
                    action: { selectedTier = .free }
                )
                
                // 高级版
                SubscriptionTierCard(
                    tier: .premium,
                    isSelected: selectedTier == .premium,
                    isPopular: true,
                    action: { selectedTier = .premium }
                )
                
                // 终身版
                SubscriptionTierCard(
                    tier: .lifetime,
                    isSelected: selectedTier == .lifetime,
                    action: { selectedTier = .lifetime }
                )
            }
        }
    }
    
    // MARK: - 功能对比
    
    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("功能对比")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // 表头
                HStack(spacing: 12) {
                    Text("功能")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: 120, alignment: .leading)
                    Spacer()
                    Text("免费")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray.opacity(0.8))
                        .frame(width: 50)
                    Text("高级")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.purple)
                        .frame(width: 50)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.1))
                
                // 功能列表
                ForEach(FeatureComparison.comparisons) { comparison in
                    HStack(spacing: 12) {
                        Text(comparison.feature)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: 120, alignment: .leading)
                        Spacer()
                        featureCheck(isAvailable: comparison.free)
                        featureCheck(isAvailable: comparison.premium)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.05))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    private func featureCheck(isAvailable: Bool) -> some View {
        Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 20))
            .foregroundColor(isAvailable ? .green : .gray)
            .frame(width: 50)
    }
    
    // MARK: - 用户评价
    
    private var testimonialsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("用户评价")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    TestimonialCard(
                        name: "小李",
                        avatar: "person.crop.circle.fill",
                        rating: 5,
                        content: "DreamLog 帮我发现了很多潜意识的模式，AI 解析很准确！"
                    )
                    
                    TestimonialCard(
                        name: "Sarah",
                        avatar: "person.crop.circle.fill",
                        rating: 5,
                        content: "AR 功能太酷了！能看到自己的梦境在现实中呈现，太神奇了。"
                    )
                    
                    TestimonialCard(
                        name: "张先生",
                        avatar: "person.crop.circle.fill",
                        rating: 5,
                        content: "冥想音效帮我改善了睡眠质量，强烈推荐给失眠的朋友。"
                    )
                }
            }
        }
    }
    
    // MARK: - 保证说明
    
    private var guaranteeSection: some View {
        HStack(spacing: 20) {
            GuaranteeItem(
                icon: "lock.shield.fill",
                title: "安全支付",
                description: "Apple 官方支付"
            )
            
            GuaranteeItem(
                icon: "arrow.triangle.2.circlepath",
                title: "随时取消",
                description: "无隐藏费用"
            )
            
            GuaranteeItem(
                icon: "star.fill",
                title: "7 天试用",
                description: "不满意退款"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
        )
    }
    
    // MARK: - 购买按钮
    
    private var purchaseButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                processPurchase()
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(selectedTier == .free ? "继续使用免费版" : "立即订阅")
                        .font(.system(size: 18, weight: .semibold))
                    
                    if !isProcessing && selectedTier != .free {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedTier == .free
                    ? LinearGradient(
                        gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                      )
                    : LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                      )
                )
                .cornerRadius(12)
            }
            .disabled(isProcessing && selectedTier != .free)
            
            if selectedTier != .free {
                Text(selectedTier.price)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // 恢复购买
            if selectedTier != .free {
                Button("恢复购买") {
                    restorePurchases()
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom: 40)
    }
    
    // MARK: - Actions
    
    private func processPurchase() {
        if selectedTier == .free {
            dismiss()
            return
        }
        
        isProcessing = true
        
        // 模拟购买流程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            showSuccess = true
            
            // 保存订阅状态
            UserDefaults.standard.set(true, forKey: "isPremiumSubscriber")
            UserDefaults.standard.set(selectedTier.rawValue, forKey: "subscriptionTier")
        }
    }
    
    private func restorePurchases() {
        // 恢复购买逻辑
        let alert = UIAlertController(
            title: "恢复购买",
            message: "正在检查您的购买记录...",
            preferredStyle: .alert
        )
        // 实际实现需要 StoreKit
    }
}

// MARK: - 订阅层级卡片

struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    var isPopular: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isPopular {
                    Text("最受欢迎")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                }
                
                Image(systemName: tier.icon)
                    .font(.system(size: 24))
                    .foregroundColor(tier.color)
                
                Text(tier.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(tier == .free ? "免费" : tier.price)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical: 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tier.color.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? tier.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - 用户评价卡片

struct TestimonialCard: View {
    let name: String
    let avatar: String
    let rating: Int
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: avatar)
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            Text(content)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .frame(width: 200)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - 保证项目

struct GuaranteeItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.purple)
            
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            
            Text(description)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 预览

#Preview("Subscription") {
    DreamSubscriptionView(isPaywall: true)
}

#Preview("Paywall") {
    DreamSubscriptionView(isPaywall: false)
}
