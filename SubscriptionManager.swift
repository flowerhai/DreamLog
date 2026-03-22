//
//  SubscriptionManager.swift
//  DreamLog - 订阅管理服务
//
//  Phase 87 - App Store 发布与高级功能
//  Created: 2026-03-22
//

import Foundation
import StoreKit
import SwiftData

@MainActor
final class SubscriptionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前订阅层级
    @Published private(set) var currentTier: SubscriptionTier = .free
    
    /// 订阅是否活跃
    @Published private(set) var isPremium: Bool = false
    
    /// 订阅是否终身
    @Published private(set) var isLifetime: Bool = false
    
    /// 可用订阅产品
    @Published private(set) var availableProducts: [Product] = []
    
    /// 当前订阅状态
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    
    /// 试用剩余天数
    @Published private(set) var trialRemainingDays: Int?
    
    /// 订阅过期日期
    @Published private(set) var expirationDate: Date?
    
    /// 加载状态
    @Published private(set) var isLoading = false
    
    /// 错误信息
    @Published private(set) var errorMessage: String?
    
    /// AI 解析今日使用次数
    @Published var todayAIAnalysisCount: Int = 0
    
    /// AI 绘画本月使用次数
    @Published var thisMonthAIArtCount: Int = 0
    
    // MARK: - 单例
    
    static let shared = SubscriptionManager()
    
    // MARK: - 初始化
    
    private init() {
        loadSubscriptionState()
        resetUsageCountersIfNeeded()
    }
    
    // MARK: - 订阅状态枚举
    
    enum SubscriptionStatus {
        case notSubscribed
        case onTrial
        case subscribed
        case expired
        case lifetime
    }
    
    // MARK: - 公共方法
    
    /// 加载订阅状态
    func loadSubscriptionState() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    /// 检查订阅状态
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 检查 StoreKit 订阅
            for await result in Transaction.updates {
                await handleTransactionUpdate(result)
            }
            
            // 检查当前 entitlements
            let entitlements = await Transaction.currentEntitlements
            await updateSubscriptionState(from: entitlements)
            
        } catch {
            errorMessage = "检查订阅失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 获取可用产品
    func fetchAvailableProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: SubscriptionProducts.allProductIDs)
            await MainActor.run {
                self.availableProducts = storeProducts.sorted { $0.price < $1.price }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "获取产品失败：\(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    /// 购买订阅
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                await transaction.finish()
                await checkSubscriptionStatus()
                await MainActor.run {
                    self.errorMessage = nil
                }
                return true
                
            case .userCancelled:
                await MainActor.run {
                    self.errorMessage = "购买已取消"
                }
                return false
                
            case .pending:
                await MainActor.run {
                    self.errorMessage = "购买待处理"
                }
                return false
                
            @unknown default:
                await MainActor.run {
                    self.errorMessage = "未知购买状态"
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "购买失败：\(error.localizedDescription)"
            }
            throw error
        }
        
        isLoading = false
    }
    
    /// 恢复购买
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "恢复购买失败：\(error.localizedDescription)"
            }
            throw error
        }
        
        isLoading = false
    }
    
    /// 管理订阅 (打开 App Store 订阅管理页面)
    func manageSubscription() async {
        guard let windowScene = await getWindowScene() else { return }
        
        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            // 如果失败，尝试打开订阅管理 URL
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    // MARK: - 功能访问检查
    
    /// 检查功能是否可用
    func canAccess(_ feature: PremiumFeature) -> Bool {
        FeatureAccess.canAccess(feature, tier: currentTier)
    }
    
    /// 检查 AI 解析是否可用
    func canUseAIAnalysis() -> (allowed: Bool, remaining: Int?) {
        if currentTier != .free {
            return (true, nil)  // 付费版本无限制
        }
        
        let remaining = max(0, FeatureAccess.freeDailyAIAnalysisLimit - todayAIAnalysisCount)
        return (remaining > 0, remaining)
    }
    
    /// 检查 AI 绘画是否可用
    func canUseAIArt() -> (allowed: Bool, remaining: Int?) {
        if currentTier != .free {
            return (true, nil)  // 付费版本无限制
        }
        
        let remaining = max(0, FeatureAccess.freeMonthlyAIArtLimit - thisMonthAIArtCount)
        return (remaining > 0, remaining)
    }
    
    /// 增加 AI 解析使用次数
    func incrementAIAnalysisUsage() {
        todayAIAnalysisCount += 1
        saveUsageCounters()
    }
    
    /// 增加 AI 绘画使用次数
    func incrementAIArtUsage() {
        thisMonthAIArtCount += 1
        saveUsageCounters()
    }
    
    // MARK: - 私有方法
    
    /// 处理交易更新
    private func handleTransactionUpdate(_ result: Result<Transaction, Error>) async {
        switch result {
        case .success(let transaction):
            await updateSubscriptionState(from: [transaction])
            await transaction.finish()
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = "交易更新失败：\(error.localizedDescription)"
            }
        }
    }
    
    /// 更新订阅状态
    private func updateSubscriptionState(from entitlements: [Product.ID: Transaction]) async {
        var newTier: SubscriptionTier = .free
        var newStatus: SubscriptionStatus = .notSubscribed
        var newExpirationDate: Date?
        var newTrialDays: Int?
        
        for (_, transaction) in entitlements {
            let productID = transaction.productID
            
            if productID == SubscriptionProducts.lifetime {
                newTier = .lifetime
                newStatus = .lifetime
                break
            } else if productID == SubscriptionProducts.premiumYearly ||
                      productID == SubscriptionProducts.premiumMonthly {
                newTier = .premium
                
                if transaction.originalPurchaseDate == transaction.purchaseDate {
                    newStatus = .onTrial
                    // 计算试用剩余天数
                    if let expiration = transaction.expirationDate {
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
                        newTrialDays = max(0, days)
                    }
                } else {
                    newStatus = .subscribed
                }
                
                newExpirationDate = transaction.expirationDate
            }
        }
        
        await MainActor.run {
            self.currentTier = newTier
            self.isPremium = newTier != .free
            self.isLifetime = newTier == .lifetime
            self.subscriptionStatus = newStatus
            self.trialRemainingDays = newTrialDays
            self.expirationDate = newExpirationDate
        }
        
        // 持久化到 SwiftData
        await saveSubscriptionToSwiftData()
    }
    
    /// 保存订阅状态到 SwiftData
    private func saveSubscriptionToSwiftData() async {
        // 这里应该通过依赖注入获取 modelContext
        // 简化实现，实际使用时需要从 App 注入
        print("Saving subscription state: \(currentTier.rawValue)")
    }
    
    /// 从 SwiftData 加载订阅状态
    private func loadSubscriptionState() {
        // 从 UserDefaults 加载使用计数器
        let defaults = UserDefaults.standard
        
        // 检查是否需要重置计数器
        let lastResetDate = defaults.object(forKey: "usageCounterLastResetDate") as? Date ?? Date.distantPast
        let now = Date()
        
        // AI 解析计数器 - 每日重置
        let aiAnalysisDateKey = "aiAnalysisCounterDate"
        let lastAIAnalysisDate = defaults.object(forKey: aiAnalysisDateKey) as? Date ?? Date.distantPast
        if !Calendar.current.isDate(lastAIAnalysisDate, inSameDayAs: now) {
            todayAIAnalysisCount = 0
            defaults.set(now, forKey: aiAnalysisDateKey)
        } else {
            todayAIAnalysisCount = defaults.integer(forKey: "todayAIAnalysisCount")
        }
        
        // AI 绘画计数器 - 每月重置
        let aiArtMonthKey = "aiArtCounterMonth"
        let lastAIArtMonth = defaults.object(forKey: aiArtMonthKey) as? String ?? ""
        let currentMonth = "\(Calendar.current.component(.year, from: now))-\(Calendar.current.component(.month, from: now))"
        if lastAIArtMonth != currentMonth {
            thisMonthAIArtCount = 0
            defaults.set(currentMonth, forKey: aiArtMonthKey)
        } else {
            thisMonthAIArtCount = defaults.integer(forKey: "thisMonthAIArtCount")
        }
        
        defaults.set(now, forKey: "usageCounterLastResetDate")
    }
    
    /// 保存使用计数器
    private func saveUsageCounters() {
        let defaults = UserDefaults.standard
        defaults.set(todayAIAnalysisCount, forKey: "todayAIAnalysisCount")
        defaults.set(thisMonthAIArtCount, forKey: "thisMonthAIArtCount")
    }
    
    /// 重置使用计数器 (如果需要)
    private func resetUsageCountersIfNeeded() {
        // 已在 loadSubscriptionState 中处理
    }
    
    /// 获取窗口场景 (用于订阅管理)
    private func getWindowScene() async -> UIWindowScene? {
        await MainActor.run {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
        }
    }
}

// MARK: - 订阅管理器扩展：订阅产品配置

extension SubscriptionManager {
    /// 获取推荐的订阅计划
    var recommendedPlan: Product? {
        // 优先推荐年付计划 (性价比最高)
        availableProducts.first { $0.productID == SubscriptionProducts.premiumYearly }
        ?? availableProducts.first { $0.productID == SubscriptionProducts.premiumMonthly }
    }
    
    /// 获取最便宜的订阅计划
    var cheapestPlan: Product? {
        availableProducts.min { $0.price < $1.price }
    }
    
    /// 获取终身计划
    var lifetimePlan: Product? {
        availableProducts.first { $0.productID == SubscriptionProducts.lifetime }
    }
}

// MARK: - 订阅管理器扩展：统计信息

extension SubscriptionManager {
    /// 获取 AI 解析剩余次数
    var remainingAIAnalysis: Int {
        max(0, FeatureAccess.freeDailyAIAnalysisLimit - todayAIAnalysisCount)
    }
    
    /// 获取 AI 绘画剩余次数
    var remainingAIArt: Int {
        max(0, FeatureAccess.freeMonthlyAIArtLimit - thisMonthAIArtCount)
    }
    
    /// AI 解析是否已用完
    var isAIAnalysisLimitReached: Bool {
        todayAIAnalysisCount >= FeatureAccess.freeDailyAIAnalysisLimit
    }
    
    /// AI 绘画是否已用完
    var isAIArtLimitReached: Bool {
        thisMonthAIArtCount >= FeatureAccess.freeMonthlyAIArtLimit
    }
}
