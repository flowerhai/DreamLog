//
//  SubscriptionModels.swift
//  DreamLog
//
//  Subscription and Premium Features Data Models
//  Phase 87: App Store Launch & Premium Features
//

import Foundation
import SwiftData

// MARK: - Subscription Tier

/// Defines the subscription tier levels
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    case lifetime = "lifetime"
    
    /// Display name for the tier
    var displayName: String {
        switch self {
        case .free: return "基础版"
        case .premium: return "高级版"
        case .lifetime: return "终身版"
        }
    }
    
    /// Description of the tier
    var description: String {
        switch self {
        case .free: return "基础功能，永久免费"
        case .premium: return "解锁全部高级功能"
        case .lifetime: return "一次购买，终身使用"
        }
    }
    
    /// Icon for the tier
    var icon: String {
        switch self {
        case .free: return "🌙"
        case .premium: return "⭐"
        case .lifetime: return "👑"
        }
    }
    
    /// Color for the tier
    var color: String {
        switch self {
        case .free: return "gray"
        case .premium: return "blue"
        case .lifetime: return "gold"
        }
    }
}

// MARK: - Subscription Plan

/// Defines a subscription plan with pricing
@Model
final class SubscriptionPlan {
    var id: UUID
    var tier: String // SubscriptionTier raw value
    var productId: String
    var price: Double
    var currency: String
    var period: SubscriptionPeriod
    var isPopular: Bool
    var features: [String]
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        tier: SubscriptionTier,
        productId: String,
        price: Double,
        currency: String = "CNY",
        period: SubscriptionPeriod,
        isPopular: Bool = false,
        features: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tier = tier.rawValue
        self.productId = productId
        self.price = price
        self.currency = currency
        self.period = period
        self.isPopular = isPopular
        self.features = features
        self.createdAt = createdAt
    }
}

// MARK: - Subscription Period

enum SubscriptionPeriod: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"
    
    var displayName: String {
        switch self {
        case .monthly: return "每月"
        case .yearly: return "每年"
        case .lifetime: return "终身"
        }
    }
    
    var displayPrice: String {
        // This would be dynamically fetched from StoreKit
        switch self {
        case .monthly: return "¥39.99/月"
        case .yearly: return "¥399.99/年"
        case .lifetime: return "¥999.99"
        }
    }
    
    var savingsPercentage: Int? {
        switch self {
        case .monthly: return nil
        case .yearly: return 17 // Save 17% vs monthly
        case .lifetime: return nil
        }
    }
}

// MARK: - User Subscription

/// Tracks the user's current subscription status
@Model
final class UserSubscription {
    var id: UUID
    var tier: String // SubscriptionTier raw value
    var productId: String?
    var expiresDate: Date?
    var isTrial: Bool
    var purchasedDate: Date?
    var lastVerified: Date
    var receiptData: Data?
    
    init(
        id: UUID = UUID(),
        tier: SubscriptionTier = .free,
        productId: String? = nil,
        expiresDate: Date? = nil,
        isTrial: Bool = false,
        purchasedDate: Date? = nil,
        lastVerified: Date = Date(),
        receiptData: Data? = nil
    ) {
        self.id = id
        self.tier = tier.rawValue
        self.productId = productId
        self.expiresDate = expiresDate
        self.isTrial = isTrial
        self.purchasedDate = purchasedDate
        self.lastVerified = lastVerified
        self.receiptData = receiptData
    }
    
    var currentTier: SubscriptionTier {
        SubscriptionTier(rawValue: tier) ?? .free
    }
    
    var isActive: Bool {
        guard let expires = expiresDate else {
            return currentTier == .lifetime
        }
        return expires > Date() || currentTier == .lifetime
    }
    
    var daysRemaining: Int? {
        guard let expires = expiresDate else {
            return nil
        }
        return Calendar.current.dateComponents([.day], from: Date(), to: expires).day
    }
}

// MARK: - Premium Feature

/// Defines premium features and their access levels
enum PremiumFeature: String, CaseIterable {
    // AI Features
    case unlimitedAIAnalysis = "unlimited_ai_analysis"
    case unlimitedAIArt = "unlimited_ai_art"
    case priorityAIProcessing = "priority_ai_processing"
    
    // Analytics
    case advancedAnalytics = "advanced_analytics"
    case patternPrediction = "pattern_prediction"
    case dreamInsights = "dream_insights"
    
    // Export
    case advancedExport = "advanced_export"
    case pdfExport = "pdf_export"
    case epubExport = "epub_export"
    
    // Backup
    case cloudBackup = "cloud_backup"
    
    // Customization
    case premiumThemes = "premium_themes"
    case customIcons = "custom_icons"
    
    // Support
    case prioritySupport = "priority_support"
    case earlyAccess = "early_access"
    case exclusiveBadges = "exclusive_badges"
    
    /// Display name
    var displayName: String {
        switch self {
        case .unlimitedAIAnalysis: return "无限 AI 解析"
        case .unlimitedAIArt: return "无限 AI 绘画"
        case .priorityAIProcessing: return "优先 AI 处理"
        case .advancedAnalytics: return "高级数据分析"
        case .patternPrediction: return "梦境模式预测"
        case .dreamInsights: return "智能梦境洞察"
        case .advancedExport: return "高级导出"
        case .pdfExport: return "PDF 导出"
        case .epubExport: return "EPUB 导出"
        case .cloudBackup: return "云备份"
        case .premiumThemes: return "高级主题"
        case .customIcons: return "自定义图标"
        case .prioritySupport: return "优先支持"
        case .earlyAccess: return "抢先体验"
        case .exclusiveBadges: return "专属徽章"
        }
    }
    
    /// Icon for the feature
    var icon: String {
        switch self {
        case .unlimitedAIAnalysis: return "🧠"
        case .unlimitedAIArt: return "🎨"
        case .priorityAIProcessing: return "⚡"
        case .advancedAnalytics: return "📊"
        case .patternPrediction: return "🔮"
        case .dreamInsights: return "💡"
        case .advancedExport: return "📤"
        case .pdfExport: return "📕"
        case .epubExport: return "📖"
        case .cloudBackup: return "☁️"
        case .premiumThemes: return "🌈"
        case .customIcons: return "🎭"
        case .prioritySupport: return "💬"
        case .earlyAccess: return "🚀"
        case .exclusiveBadges: return "🏆"
        }
    }
    
    /// Description
    var description: String {
        switch self {
        case .unlimitedAIAnalysis: return "每天无限次 AI 梦境解析"
        case .unlimitedAIArt: return "无限生成梦境 AI 艺术图"
        case .priorityAIProcessing: return "AI 请求优先处理，更快返回结果"
        case .advancedAnalytics: return "深度数据分析和可视化图表"
        case .patternPrediction: return "预测未来梦境模式和趋势"
        case .dreamInsights: return "个性化梦境洞察和建议"
        case .advancedExport: return "导出为 PDF/EPUB 等格式"
        case .pdfExport: return "导出精美的 PDF 梦境日记"
        case .epubExport: return "导出为电子书格式"
        case .cloudBackup: return "备份到 Google Drive/Dropbox/OneDrive"
        case .premiumThemes: return "12 种独家精美主题"
        case .customIcons: return "自定义应用图标"
        case .prioritySupport: return "优先客户支持服务"
        case .earlyAccess: return "抢先体验新功能"
        case .exclusiveBadges: return "终身用户专属徽章"
        }
    }
}

// MARK: - Feature Access Level

/// Defines which tiers have access to which features
extension PremiumFeature {
    var requiredTier: SubscriptionTier {
        switch self {
        case .unlimitedAIAnalysis,
             .unlimitedAIArt,
             .priorityAIProcessing,
             .advancedAnalytics,
             .patternPrediction,
             .dreamInsights,
             .advancedExport,
             .pdfExport,
             .epubExport,
             .cloudBackup,
             .premiumThemes,
             .customIcons,
             .prioritySupport:
            return .premium
            
        case .earlyAccess,
             .exclusiveBadges:
            return .lifetime
        }
    }
    
    /// Check if a tier has access to this feature
    func isAccessible(by tier: SubscriptionTier) -> Bool {
        switch tier {
        case .free:
            return false
        case .premium:
            return requiredTier == .premium || requiredTier == .free
        case .lifetime:
            return true
        }
    }
}

// MARK: - Subscription Usage Tracking

/// Tracks usage of limited features for free tier
@Model
final class SubscriptionUsage {
    var id: UUID
    var date: Date
    var aiAnalysisCount: Int
    var aiArtCount: Int
    var lastResetDate: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        aiAnalysisCount: Int = 0,
        aiArtCount: Int = 0,
        lastResetDate: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.aiAnalysisCount = aiAnalysisCount
        self.aiArtCount = aiArtCount
        self.lastResetDate = lastResetDate
    }
    
    /// Free tier limits
    static let freeAIAnalysisLimit = 3
    static let freeAIArtLimit = 10
    
    /// Check if user can use AI analysis
    var canUseAIAnalysis: Bool {
        aiAnalysisCount < Self.freeAIAnalysisLimit
    }
    
    /// Check if user can generate AI art
    var canUseAIArt: Bool {
        aiArtCount < Self.freeAIArtLimit
    }
    
    /// Remaining AI analysis uses
    var remainingAIAnalysis: Int {
        max(0, Self.freeAIAnalysisLimit - aiAnalysisCount)
    }
    
    /// Remaining AI art uses
    var remainingAIArt: Int {
        max(0, Self.freeAIArtLimit - aiArtCount)
    }
    
    /// Reset daily counters
    func resetIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            aiAnalysisCount = 0
            aiArtCount = 0
            lastResetDate = Date()
        }
    }
}

// MARK: - Paywall Configuration

/// Configuration for paywall display
struct PaywallConfig {
    var showTrial: Bool = true
    var trialDays: Int = 7
    var defaultPlan: SubscriptionPeriod = .yearly
    var showLifetime: Bool = true
    var features: [PremiumFeature] = PremiumFeature.allCases
    
    static let `default` = PaywallConfig()
}

// MARK: - Subscription State

/// Current state of the subscription system
enum SubscriptionState {
    case loading
    case loaded(UserSubscription)
    case error(String)
    
    var tier: SubscriptionTier {
        switch self {
        case .loading: return .free
        case .loaded(let subscription): return subscription.currentTier
        case .error: return .free
        }
    }
    
    var isActive: Bool {
        switch self {
        case .loading: return false
        case .loaded(let subscription): return subscription.isActive
        case .error: return false
        }
    }
}
