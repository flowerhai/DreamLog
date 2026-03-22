//
//  SubscriptionManager.swift
//  DreamLog
//
//  Subscription Management Service
//  Phase 87: App Store Launch & Premium Features
//

import Foundation
import SwiftData

// MARK: - Subscription Manager

/// Manages subscription state and premium feature access
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var state: SubscriptionState = .loading
    @Published private(set) var usage: SubscriptionUsage?
    @Published private(set) var availablePlans: [SubscriptionPlan] = []
    @Published var showPaywall: Bool = false
    
    // MARK: - Computed Properties
    
    var currentTier: SubscriptionTier {
        state.tier
    }
    
    var isPremium: Bool {
        currentTier != .free
    }
    
    var isLifetime: Bool {
        currentTier == .lifetime
    }
    
    var isActive: Bool {
        state.isActive
    }
    
    // MARK: - Free Tier Limits
    
    let freeAIAnalysisLimit = 3
    let freeAIArtLimit = 10
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultPlans()
        Task {
            await loadSubscription()
        }
    }
    
    // MARK: - Setup
    
    private func setupDefaultPlans() {
        availablePlans = [
            SubscriptionPlan(
                tier: .premium,
                productId: "com.dreamlog.premium.monthly",
                price: 39.99,
                currency: "CNY",
                period: .monthly,
                isPopular: false,
                features: [
                    "无限 AI 解析",
                    "无限 AI 绘画",
                    "高级数据分析",
                    "梦境模式预测",
                    "PDF/EPUB 导出",
                    "云备份",
                    "12 种高级主题"
                ]
            ),
            SubscriptionPlan(
                tier: .premium,
                productId: "com.dreamlog.premium.yearly",
                price: 399.99,
                currency: "CNY",
                period: .yearly,
                isPopular: true,
                features: [
                    "包含所有月度功能",
                    "节省 17%",
                    "优先支持",
                    "抢先体验新功能"
                ]
            ),
            SubscriptionPlan(
                tier: .lifetime,
                productId: "com.dreamlog.lifetime",
                price: 999.99,
                currency: "CNY",
                period: .lifetime,
                isPopular: false,
                features: [
                    "所有高级功能",
                    "终身使用",
                    "专属徽章",
                    "优先支持",
                    "抢先体验所有新功能"
                ]
            )
        ]
    }
    
    // MARK: - Loading
    
    func loadSubscription() async {
        state = .loading
        
        do {
            // Try to load from model context
            let subscription = try await fetchUserSubscription()
            usage = try await fetchUsage()
            
            // Reset usage if needed
            usage?.resetIfNeeded()
            
            state = .loaded(subscription)
        } catch {
            // Create default free subscription
            let freeSubscription = UserSubscription(tier: .free)
            try? await saveSubscription(freeSubscription)
            state = .loaded(freeSubscription)
        }
    }
    
    // MARK: - Feature Access
    
    func canAccess(_ feature: PremiumFeature) -> Bool {
        switch state {
        case .loading:
            return false
        case .loaded(let subscription):
            return feature.isAccessible(by: subscription.currentTier)
        case .error:
            return false
        }
    }
    
    func canUseAIAnalysis() -> Bool {
        if isPremium { return true }
        return usage?.canUseAIAnalysis ?? false
    }
    
    func canUseAIArt() -> Bool {
        if isPremium { return true }
        return usage?.canUseAIArt ?? false
    }
    
    // MARK: - Usage Tracking
    
    func trackAIAnalysis() async {
        guard !isPremium, let usage = usage else { return }
        usage.aiAnalysisCount += 1
        try? await saveUsage(usage)
    }
    
    func trackAIArt() async {
        guard !isPremium, let usage = usage else { return }
        usage.aiArtCount += 1
        try? await saveUsage(usage)
    }
    
    func getRemainingAIAnalysis() -> Int {
        if isPremium { return Int.max }
        return usage?.remainingAIAnalysis ?? 0
    }
    
    func getRemainingAIArt() -> Int {
        if isPremium { return Int.max }
        return usage?.remainingAIArt ?? 0
    }
    
    // MARK: - Purchase Flow
    
    func purchase(plan: SubscriptionPlan) async throws {
        // In production, this would integrate with StoreKit 2 or RevenueCat
        // For now, simulate the purchase flow
        
        print("Initiating purchase for plan: \(plan.productId)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Create subscription
        let subscription = UserSubscription(
            tier: plan.tier == "lifetime" ? .lifetime : .premium,
            productId: plan.productId,
            expiresDate: plan.period == .lifetime ? nil : Date().addingTimeInterval(30 * 24 * 60 * 60),
            isTrial: plan.period == .yearly, // Yearly gets trial
            purchasedDate: Date()
        )
        
        try await saveSubscription(subscription)
        state = .loaded(subscription)
        
        // Reset usage for new premium user
        if let usage = usage {
            usage.aiAnalysisCount = 0
            usage.aiArtCount = 0
            try await saveUsage(usage)
        }
    }
    
    func restorePurchases() async throws {
        // In production, this would call StoreKit's restorePurchases
        print("Restoring purchases...")
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // For demo, just reload
        await loadSubscription()
    }
    
    // MARK: - Subscription Management
    
    func manageSubscription() {
        // Open App Store subscription management
        print("Opening subscription management...")
        // In production: open App Store subscription page
    }
    
    // MARK: - Data Persistence
    
    private func fetchUserSubscription() async throws -> UserSubscription {
        // In production, use SwiftData model context
        // For now, return a default subscription
        return UserSubscription(tier: .free)
    }
    
    private func saveSubscription(_ subscription: UserSubscription) async throws {
        // In production, save to SwiftData
        print("Saving subscription: \(subscription.currentTier)")
    }
    
    private func fetchUsage() async throws -> SubscriptionUsage {
        // In production, use SwiftData model context
        return SubscriptionUsage()
    }
    
    private func saveUsage(_ usage: SubscriptionUsage) async throws {
        // In production, save to SwiftData
        print("Saving usage: AI Analysis=\(usage.aiAnalysisCount), AI Art=\(usage.aiArtCount)")
    }
    
    // MARK: - Paywall
    
    func showPaywallIfNeeded(for feature: PremiumFeature? = nil) {
        if canAccess(feature ?? .unlimitedAIAnalysis) {
            return
        }
        showPaywall = true
    }
    
    func dismissPaywall() {
        showPaywall = false
    }
}

// MARK: - Subscription Service (Non-Actor)

/// Non-actor version for background tasks
final class SubscriptionService {
    static let shared = SubscriptionService()
    
    private init() {}
    
    func checkSubscriptionStatus() async -> SubscriptionTier {
        await SubscriptionManager.shared.currentTier
    }
    
    func verifySubscription() async throws -> Bool {
        await SubscriptionManager.shared.isActive
    }
}

// MARK: - Premium Feature Helper

extension PremiumFeature {
    /// Get all features available for a tier
    static func features(for tier: SubscriptionTier) -> [PremiumFeature] {
        allCases.filter { $0.isAccessible(by: tier) }
    }
    
    /// Get locked features for a tier (to show as upsell)
    static func lockedFeatures(for tier: SubscriptionTier) -> [PremiumFeature] {
        allCases.filter { !$0.isAccessible(by: tier) }
    }
}

// MARK: - Preview Data

#if DEBUG
extension SubscriptionPlan {
    static let previewMonthly = SubscriptionPlan(
        tier: .premium,
        productId: "com.dreamlog.premium.monthly",
        price: 39.99,
        currency: "CNY",
        period: .monthly,
        isPopular: false,
        features: ["无限 AI 解析", "无限 AI 绘画", "高级数据分析"]
    )
    
    static let previewYearly = SubscriptionPlan(
        tier: .premium,
        productId: "com.dreamlog.premium.yearly",
        price: 399.99,
        currency: "CNY",
        period: .yearly,
        isPopular: true,
        features: ["包含所有月度功能", "节省 17%", "优先支持"]
    )
    
    static let previewLifetime = SubscriptionPlan(
        tier: .lifetime,
        productId: "com.dreamlog.lifetime",
        price: 999.99,
        currency: "CNY",
        period: .lifetime,
        isPopular: false,
        features: ["所有高级功能", "终身使用", "专属徽章"]
    )
}
#endif
