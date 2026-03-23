//
//  SubscriptionTests.swift
//  DreamLog - 订阅系统单元测试
//
//  Phase 87 - App Store 发布与高级功能
//  Created: 2026-03-23
//

import XCTest
import Foundation
import SwiftUI
import SwiftData
@testable import DreamLog

// MARK: - SubscriptionTier 测试

final class SubscriptionTierTests: XCTestCase {
    
    // MARK: - 测试 CaseIterable
    
    func testAllCases() {
        let allTiers = SubscriptionTier.allCases
        XCTAssertEqual(allTiers.count, 3)
        XCTAssertEqual(allTiers, [.free, .premium, .lifetime])
    }
    
    // MARK: - 测试显示名称
    
    func testDisplayName() {
        XCTAssertEqual(SubscriptionTier.free.displayName, "基础版")
        XCTAssertEqual(SubscriptionTier.premium.displayName, "高级版")
        XCTAssertEqual(SubscriptionTier.lifetime.displayName, "终身版")
    }
    
    // MARK: - 测试图标
    
    func testIcon() {
        XCTAssertEqual(SubscriptionTier.free.icon, "🌱")
        XCTAssertEqual(SubscriptionTier.premium.icon, "⭐")
        XCTAssertEqual(SubscriptionTier.lifetime.icon, "👑")
    }
    
    // MARK: - 测试描述
    
    func testDescription() {
        XCTAssertEqual(SubscriptionTier.free.description, "基础功能，完全免费")
        XCTAssertEqual(SubscriptionTier.premium.description, "解锁所有高级功能")
        XCTAssertEqual(SubscriptionTier.lifetime.description, "一次购买，终身享用")
    }
    
    // MARK: - 测试价格
    
    func testPrice() {
        XCTAssertNil(SubscriptionTier.free.price)
        XCTAssertEqual(SubscriptionTier.premium.price, "¥39.99/月 或 ¥399.99/年")
        XCTAssertEqual(SubscriptionTier.lifetime.price, "¥999.99")
    }
    
    // MARK: - 测试功能访问
    
    func testHasAllFeatures() {
        XCTAssertFalse(SubscriptionTier.free.hasAllFeatures)
        XCTAssertTrue(SubscriptionTier.premium.hasAllFeatures)
        XCTAssertTrue(SubscriptionTier.lifetime.hasAllFeatures)
    }
    
    // MARK: - 测试 Codable
    
    func testCodable() throws {
        let tier = SubscriptionTier.premium
        let data = try JSONEncoder().encode(tier)
        let decoded = try JSONDecoder().decode(SubscriptionTier.self, from: data)
        XCTAssertEqual(tier, decoded)
    }
    
    // MARK: - 测试 RawRepresentable
    
    func testRawRepresentable() {
        XCTAssertEqual(SubscriptionTier.free.rawValue, "free")
        XCTAssertEqual(SubscriptionTier.premium.rawValue, "premium")
        XCTAssertEqual(SubscriptionTier.lifetime.rawValue, "lifetime")
        
        XCTAssertEqual(SubscriptionTier(rawValue: "free"), .free)
        XCTAssertEqual(SubscriptionTier(rawValue: "premium"), .premium)
        XCTAssertEqual(SubscriptionTier(rawValue: "lifetime"), .lifetime)
        XCTAssertNil(SubscriptionTier(rawValue: "invalid"))
    }
}

// MARK: - SubscriptionPlan 测试

final class SubscriptionPlanTests: XCTestCase {
    
    func testSubscriptionPlanInitialization() {
        let plan = SubscriptionPlan(
            tier: "premium",
            productID: "com.dreamlog.premium.monthly",
            price: 39.99,
            currency: "CNY",
            period: "monthly",
            periodUnit: "month",
            periodCount: 1,
            isTrialAvailable: true,
            trialDays: 7,
            isActive: true,
            sortOrder: 1
        )
        
        XCTAssertNotNil(plan.id)
        XCTAssertEqual(plan.tier, "premium")
        XCTAssertEqual(plan.productID, "com.dreamlog.premium.monthly")
        XCTAssertEqual(plan.price, 39.99)
        XCTAssertEqual(plan.currency, "CNY")
        XCTAssertEqual(plan.period, "monthly")
        XCTAssertEqual(plan.periodUnit, "month")
        XCTAssertEqual(plan.periodCount, 1)
        XCTAssertTrue(plan.isTrialAvailable)
        XCTAssertEqual(plan.trialDays, 7)
        XCTAssertTrue(plan.isActive)
        XCTAssertEqual(plan.sortOrder, 1)
    }
    
    func testDefaultValues() {
        let plan = SubscriptionPlan(
            tier: "free",
            productID: "com.dreamlog.free",
            price: 0,
            period: "lifetime",
            periodUnit: "lifetime",
            periodCount: 0
        )
        
        XCTAssertEqual(plan.currency, "CNY")
        XCTAssertFalse(plan.isTrialAvailable)
        XCTAssertEqual(plan.trialDays, 0)
        XCTAssertTrue(plan.isActive)
        XCTAssertEqual(plan.sortOrder, 0)
    }
}

// MARK: - UserSubscription 测试

final class UserSubscriptionTests: XCTestCase {
    
    func testUserSubscriptionInitialization() {
        let subscription = UserSubscription(
            tier: "premium",
            productID: "com.dreamlog.premium.yearly",
            purchaseDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .year, to: Date()),
            isTrialPeriod: false,
            isActive: true,
            autoRenewStatus: "active"
        )
        
        XCTAssertNotNil(subscription.id)
        XCTAssertEqual(subscription.tier, "premium")
        XCTAssertEqual(subscription.productID, "com.dreamlog.premium.yearly")
        XCTAssertNotNil(subscription.purchaseDate)
        XCTAssertNotNil(subscription.expirationDate)
        XCTAssertFalse(subscription.isTrialPeriod)
        XCTAssertTrue(subscription.isActive)
        XCTAssertEqual(subscription.autoRenewStatus, "active")
        XCTAssertNotNil(subscription.lastVerifiedDate)
    }
    
    func testDefaultUserSubscription() {
        let subscription = UserSubscription()
        
        XCTAssertEqual(subscription.tier, SubscriptionTier.free.rawValue)
        XCTAssertNil(subscription.productID)
        XCTAssertNil(subscription.purchaseDate)
        XCTAssertNil(subscription.expirationDate)
        XCTAssertFalse(subscription.isTrialPeriod)
        XCTAssertFalse(subscription.isActive)
        XCTAssertEqual(subscription.autoRenewStatus, "inactive")
    }
    
    func testSubscriptionTierAccessor() {
        let premiumSubscription = UserSubscription(tier: "premium")
        XCTAssertEqual(premiumSubscription.subscriptionTier, .premium)
        
        let lifetimeSubscription = UserSubscription(tier: "lifetime")
        XCTAssertEqual(lifetimeSubscription.subscriptionTier, .lifetime)
        
        let freeSubscription = UserSubscription()
        XCTAssertEqual(freeSubscription.subscriptionTier, .free)
    }
}

// MARK: - SubscriptionProducts 测试

final class SubscriptionProductsTests: XCTestCase {
    
    func testProductIDs() {
        let productIDs = SubscriptionProducts.allProductIDs
        XCTAssertEqual(productIDs.count, 3)
        
        XCTAssertTrue(productIDs.contains(SubscriptionProducts.premiumMonthly))
        XCTAssertTrue(productIDs.contains(SubscriptionProducts.premiumYearly))
        XCTAssertTrue(productIDs.contains(SubscriptionProducts.lifetime))
    }
    
    func testProductConstants() {
        XCTAssertEqual(SubscriptionProducts.premiumMonthly, "com.dreamlog.premium.monthly")
        XCTAssertEqual(SubscriptionProducts.premiumYearly, "com.dreamlog.premium.yearly")
        XCTAssertEqual(SubscriptionProducts.lifetime, "com.dreamlog.lifetime")
    }
}

// MARK: - PremiumFeature 测试

final class PremiumFeatureTests: XCTestCase {
    
    func testAllCases() {
        let allFeatures = PremiumFeature.allCases
        XCTAssertGreaterThan(allFeatures.count, 0)
    }
    
    func testFeatureProperties() {
        // 测试至少一个功能的属性
        let feature = PremiumFeature.unlimitedAIAnalysis
        XCTAssertFalse(feature.displayName.isEmpty)
        XCTAssertFalse(feature.description.isEmpty)
        XCTAssertFalse(feature.icon.isEmpty)
    }
    
    func testFeatureDisplayNames() {
        XCTAssertEqual(PremiumFeature.unlimitedAIAnalysis.displayName, "无限 AI 解析")
        XCTAssertEqual(PremiumFeature.unlimitedAIArt.displayName, "无限 AI 绘画")
        XCTAssertEqual(PremiumFeature.advancedAnalytics.displayName, "高级数据分析")
        XCTAssertEqual(PremiumFeature.cloudBackup.displayName, "云备份")
    }
    
    func testFeatureIcons() {
        XCTAssertEqual(PremiumFeature.unlimitedAIAnalysis.icon, "🧠")
        XCTAssertEqual(PremiumFeature.unlimitedAIArt.icon, "🎨")
        XCTAssertEqual(PremiumFeature.advancedAnalytics.icon, "📊")
        XCTAssertEqual(PremiumFeature.cloudBackup.icon, "☁️")
    }
}

// MARK: - SubscriptionManager 测试

final class SubscriptionManagerTests: XCTestCase {
    
    var sut: SubscriptionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = SubscriptionManager.shared
    }
    
    override func tearDown() async throws {
        // 重置状态
        await MainActor.run {
            // 不清除单例，只验证状态
        }
        try await super.tearDown()
    }
    
    // MARK: - 测试初始状态
    
    @MainActor
    func testInitialState() {
        // 初始应该是免费版
        XCTAssertEqual(sut.currentTier, .free)
        XCTAssertFalse(sut.isPremium)
        XCTAssertFalse(sut.isLifetime)
        XCTAssertEqual(sut.subscriptionStatus, .notSubscribed)
    }
    
    // MARK: - 测试用量计数器
    
    @MainActor
    func testUsageCounters() {
        // 验证计数器初始值
        XCTAssertGreaterThanOrEqual(sut.todayAIAnalysisCount, 0)
        XCTAssertGreaterThanOrEqual(sut.thisMonthAIArtCount, 0)
    }
    
    // MARK: - 测试 AI 解析使用检查 (免费版)
    
    @MainActor
    func testCanUseAIAnalysis_FreeTier() {
        // 免费版且有剩余次数
        sut.todayAIAnalysisCount = 0
        let result1 = sut.canUseAIAnalysis()
        XCTAssertTrue(result1.allowed)
        XCTAssertEqual(result1.remaining, 3)
        
        // 使用了 2 次
        sut.todayAIAnalysisCount = 2
        let result2 = sut.canUseAIAnalysis()
        XCTAssertTrue(result2.allowed)
        XCTAssertEqual(result2.remaining, 1)
        
        // 使用了 3 次 (达到限制)
        sut.todayAIAnalysisCount = 3
        let result3 = sut.canUseAIAnalysis()
        XCTAssertFalse(result3.allowed)
        XCTAssertEqual(result3.remaining, 0)
        
        // 超过限制
        sut.todayAIAnalysisCount = 5
        let result4 = sut.canUseAIAnalysis()
        XCTAssertFalse(result4.allowed)
        XCTAssertEqual(result4.remaining, 0)
    }
    
    // MARK: - 测试 AI 绘画使用检查 (免费版)
    
    @MainActor
    func testCanUseAIArt_FreeTier() {
        // 免费版且有剩余次数
        sut.thisMonthAIArtCount = 0
        let result1 = sut.canUseAIArt()
        XCTAssertTrue(result1.allowed)
        XCTAssertEqual(result1.remaining, 10)
        
        // 使用了 5 次
        sut.thisMonthAIArtCount = 5
        let result2 = sut.canUseAIArt()
        XCTAssertTrue(result2.allowed)
        XCTAssertEqual(result2.remaining, 5)
        
        // 使用了 10 次 (达到限制)
        sut.thisMonthAIArtCount = 10
        let result3 = sut.canUseAIArt()
        XCTAssertFalse(result3.allowed)
        XCTAssertEqual(result3.remaining, 0)
    }
    
    // MARK: - 测试用量增加
    
    @MainActor
    func testIncrementUsage() {
        let initialAIAnalysis = sut.todayAIAnalysisCount
        let initialAIArt = sut.thisMonthAIArtCount
        
        sut.incrementAIAnalysisUsage()
        XCTAssertEqual(sut.todayAIAnalysisCount, initialAIAnalysis + 1)
        
        sut.incrementAIArtUsage()
        XCTAssertEqual(sut.thisMonthAIArtCount, initialAIArt + 1)
    }
    
    // MARK: - 测试功能访问检查
    
    @MainActor
    func testCanAccessFeature() {
        // 免费版测试
        sut.currentTier = .free
        
        // 免费版不能访问无限 AI 分析
        XCTAssertFalse(sut.canAccess(.unlimitedAIAnalysis))
        XCTAssertFalse(sut.canAccess(.unlimitedAIArt))
        XCTAssertFalse(sut.canAccess(.advancedAnalytics))
        XCTAssertFalse(sut.canAccess(.cloudBackup))
        
        // 高级版测试
        sut.currentTier = .premium
        
        XCTAssertTrue(sut.canAccess(.unlimitedAIAnalysis))
        XCTAssertTrue(sut.canAccess(.unlimitedAIArt))
        XCTAssertTrue(sut.canAccess(.advancedAnalytics))
        XCTAssertTrue(sut.canAccess(.cloudBackup))
        
        // 终身版专属功能
        XCTAssertFalse(sut.canAccess(.prioritySupport))
        XCTAssertFalse(sut.canAccess(.earlyAccess))
        XCTAssertFalse(sut.canAccess(.exclusiveBadges))
        
        // 终身版测试
        sut.currentTier = .lifetime
        
        XCTAssertTrue(sut.canAccess(.prioritySupport))
        XCTAssertTrue(sut.canAccess(.earlyAccess))
        XCTAssertTrue(sut.canAccess(.exclusiveBadges))
    }
}

// MARK: - Subscription 扩展测试

final class SubscriptionExtensionTests: XCTestCase {
    
    func testUserSubscriptionSubscriptionTier() {
        let freeSub = UserSubscription(tier: "free")
        XCTAssertEqual(freeSub.subscriptionTier, .free)
        
        let premiumSub = UserSubscription(tier: "premium")
        XCTAssertEqual(premiumSub.subscriptionTier, .premium)
        
        let lifetimeSub = UserSubscription(tier: "lifetime")
        XCTAssertEqual(lifetimeSub.subscriptionTier, .lifetime)
        
        // 测试无效层级回退到免费
        let invalidSub = UserSubscription(tier: "invalid")
        XCTAssertEqual(invalidSub.subscriptionTier, .free)
    }
}

// MARK: - 订阅状态逻辑测试

final class SubscriptionLogicTests: XCTestCase {
    
    func testSubscriptionStatusMapping() {
        // 测试不同订阅状态对应的层级
        let freeSub = UserSubscription(tier: "free", isActive: false)
        XCTAssertEqual(freeSub.subscriptionTier, .free)
        
        let activePremium = UserSubscription(tier: "premium", isActive: true, autoRenewStatus: "active")
        XCTAssertEqual(activePremium.subscriptionTier, .premium)
        XCTAssertTrue(activePremium.isActive)
        
        let expiredPremium = UserSubscription(tier: "premium", isActive: false, autoRenewStatus: "expired")
        XCTAssertEqual(expiredPremium.subscriptionTier, .premium)
        XCTAssertFalse(expiredPremium.isActive)
        
        let lifetime = UserSubscription(tier: "lifetime", isActive: true)
        XCTAssertEqual(lifetime.subscriptionTier, .lifetime)
        XCTAssertTrue(lifetime.isActive)
    }
    
    func testAutoRenewStatusValues() {
        let active = UserSubscription(autoRenewStatus: "active")
        XCTAssertEqual(active.autoRenewStatus, "active")
        
        let cancelled = UserSubscription(autoRenewStatus: "cancelled")
        XCTAssertEqual(cancelled.autoRenewStatus, "cancelled")
        
        let expired = UserSubscription(autoRenewStatus: "expired")
        XCTAssertEqual(expired.autoRenewStatus, "expired")
    }
}

// MARK: - FeatureAccess 测试

final class FeatureAccessTests: XCTestCase {
    
    func testFreeDailyAIAnalysisLimit() {
        XCTAssertEqual(FeatureAccess.freeDailyAIAnalysisLimit, 3)
    }
    
    func testFreeMonthlyAIArtLimit() {
        XCTAssertEqual(FeatureAccess.freeMonthlyAIArtLimit, 10)
    }
    
    func testCanAccess_FreeTier() {
        // 免费版不能访问高级功能
        XCTAssertFalse(FeatureAccess.canAccess(.unlimitedAIAnalysis, tier: .free))
        XCTAssertFalse(FeatureAccess.canAccess(.unlimitedAIArt, tier: .free))
        XCTAssertFalse(FeatureAccess.canAccess(.advancedAnalytics, tier: .free))
        XCTAssertFalse(FeatureAccess.canAccess(.cloudBackup, tier: .free))
        XCTAssertFalse(FeatureAccess.canAccess(.premiumThemes, tier: .free))
    }
    
    func testCanAccess_PremiumTier() {
        // 高级版可以访问所有高级功能
        XCTAssertTrue(FeatureAccess.canAccess(.unlimitedAIAnalysis, tier: .premium))
        XCTAssertTrue(FeatureAccess.canAccess(.unlimitedAIArt, tier: .premium))
        XCTAssertTrue(FeatureAccess.canAccess(.advancedAnalytics, tier: .premium))
        XCTAssertTrue(FeatureAccess.canAccess(.cloudBackup, tier: .premium))
        XCTAssertTrue(FeatureAccess.canAccess(.premiumThemes, tier: .premium))
        
        // 但无法访问终身版专属功能
        XCTAssertFalse(FeatureAccess.canAccess(.prioritySupport, tier: .premium))
        XCTAssertFalse(FeatureAccess.canAccess(.earlyAccess, tier: .premium))
        XCTAssertFalse(FeatureAccess.canAccess(.exclusiveBadges, tier: .premium))
    }
    
    func testCanAccess_LifetimeTier() {
        // 终身版可以访问所有功能
        XCTAssertTrue(FeatureAccess.canAccess(.unlimitedAIAnalysis, tier: .lifetime))
        XCTAssertTrue(FeatureAccess.canAccess(.prioritySupport, tier: .lifetime))
        XCTAssertTrue(FeatureAccess.canAccess(.earlyAccess, tier: .lifetime))
        XCTAssertTrue(FeatureAccess.canAccess(.exclusiveBadges, tier: .lifetime))
    }
    
    func testGetRemainingUsage_FreeTier() {
        // AI 解析剩余次数
        let remaining1 = FeatureAccess.getRemainingUsage(for: .unlimitedAIAnalysis, tier: .free, currentUsage: 0)
        XCTAssertEqual(remaining1, 3)
        
        let remaining2 = FeatureAccess.getRemainingUsage(for: .unlimitedAIAnalysis, tier: .free, currentUsage: 2)
        XCTAssertEqual(remaining2, 1)
        
        let remaining3 = FeatureAccess.getRemainingUsage(for: .unlimitedAIAnalysis, tier: .free, currentUsage: 3)
        XCTAssertEqual(remaining3, 0)
        
        // AI 绘画剩余次数
        let remaining4 = FeatureAccess.getRemainingUsage(for: .unlimitedAIArt, tier: .free, currentUsage: 5)
        XCTAssertEqual(remaining4, 5)
        
        // 付费版本返回 nil (无限制)
        let remaining5 = FeatureAccess.getRemainingUsage(for: .unlimitedAIAnalysis, tier: .premium, currentUsage: 100)
        XCTAssertNil(remaining5)
    }
}

// MARK: - PaywallConfig 测试

final class PaywallConfigTests: XCTestCase {
    
    func testPaywallConfigProperties() {
        let config = PaywallConfig()
        
        XCTAssertFalse(config.title.isEmpty)
        XCTAssertFalse(config.subtitle.isEmpty)
        XCTAssertGreaterThan(config.freeTrialDays, 0)
        XCTAssertGreaterThan(config.featuredFeatures.count, 0)
    }
    
    func testPaywallTitle() {
        let config = PaywallConfig()
        XCTAssertEqual(config.title, "解锁 DreamLog 全部潜能")
    }
    
    func testPaywallSubtitle() {
        let config = PaywallConfig()
        XCTAssertEqual(config.subtitle, "升级至高级版，获得完整的梦境探索体验")
    }
    
    func testPaywallTrialDays() {
        let config = PaywallConfig()
        XCTAssertEqual(config.freeTrialDays, 7)
    }
    
    func testPaywallFeaturedFeatures() {
        let config = PaywallConfig()
        
        XCTAssertTrue(config.featuredFeatures.contains(.unlimitedAIAnalysis))
        XCTAssertTrue(config.featuredFeatures.contains(.unlimitedAIArt))
        XCTAssertTrue(config.featuredFeatures.contains(.advancedAnalytics))
        XCTAssertTrue(config.featuredFeatures.contains(.cloudBackup))
    }
}

// MARK: - 价格计算测试

final class SubscriptionPricingTests: XCTestCase {
    
    func testPriceComparison() {
        let monthlyPrice = 39.99
        let yearlyPrice = 399.99
        let lifetimePrice = 999.99
        
        // 年度订阅比月度贵
        XCTAssertGreaterThan(yearlyPrice, monthlyPrice)
        
        // 终身订阅最贵
        XCTAssertGreaterThan(lifetimePrice, yearlyPrice)
        XCTAssertGreaterThan(lifetimePrice, monthlyPrice)
        
        // 计算年度订阅相当于多少个月
        let monthlyEquivalent = yearlyPrice / monthlyPrice
        XCTAssertEqual(monthlyEquivalent, 10.0, accuracy: 0.01) // 年度相当于 10 个月，省 2 个月
    }
    
    func testSavingsCalculation() {
        let monthlyPrice = 39.99
        let yearlyPrice = 399.99
        
        // 年度订阅相比 12 个月度订阅的节省
        let twelveMonthsCost = monthlyPrice * 12
        let savings = twelveMonthsCost - yearlyPrice
        let savingsPercentage = (savings / twelveMonthsCost) * 100
        
        XCTAssertGreaterThan(savings, 0)
        XCTAssertEqual(savingsPercentage, 16.67, accuracy: 0.1) // 节省约 16.7%
    }
}
