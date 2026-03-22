//
//  SubscriptionModels.swift
//  DreamLog - 订阅系统数据模型
//
//  Phase 87 - App Store 发布与高级功能
//  Created: 2026-03-22
//

import Foundation
import SwiftData

// MARK: - 订阅层级

/// 订阅层级枚举
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"           // 基础版 (免费)
    case premium = "premium"     // 高级版 (订阅)
    case lifetime = "lifetime"   // 终身版 (买断)
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .free: return "基础版"
        case .premium: return "高级版"
        case .lifetime: return "终身版"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .free: return "🌱"
        case .premium: return "⭐"
        case .lifetime: return "👑"
        }
    }
    
    /// 描述
    var description: String {
        switch self {
        case .free: return "基础功能，完全免费"
        case .premium: return "解锁所有高级功能"
        case .lifetime: return "一次购买，终身享用"
        }
    }
    
    /// 价格 (人民币)
    var price: String? {
        switch self {
        case .free: return nil
        case .premium: return "¥39.99/月 或 ¥399.99/年"
        case .lifetime: return "¥999.99"
        }
    }
    
    /// 是否包含所有高级功能
    var hasAllFeatures: Bool {
        switch self {
        case .free: return false
        case .premium, .lifetime: return true
        }
    }
}

// MARK: - 订阅计划

/// 订阅计划模型
@Model
final class SubscriptionPlan {
    var id: String
    var tier: String  // SubscriptionTier.rawValue
    var productID: String
    var price: Double
    var currency: String
    var period: String  // "monthly", "yearly", "lifetime"
    var periodUnit: String  // "month", "year", "lifetime"
    var periodCount: Int
    var isTrialAvailable: Bool
    var trialDays: Int
    var isActive: Bool
    var sortOrder: Int
    
    init(
        id: String = UUID().uuidString,
        tier: String,
        productID: String,
        price: Double,
        currency: String = "CNY",
        period: String,
        periodUnit: String,
        periodCount: Int,
        isTrialAvailable: Bool = false,
        trialDays: Int = 0,
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.tier = tier
        self.productID = productID
        self.price = price
        self.currency = currency
        self.period = period
        self.periodUnit = periodUnit
        self.periodCount = periodCount
        self.isTrialAvailable = isTrialAvailable
        self.trialDays = trialDays
        self.isActive = isActive
        self.sortOrder = sortOrder
    }
}

// MARK: - 用户订阅状态

/// 用户订阅状态模型
@Model
final class UserSubscription {
    var id: String
    var tier: String  // SubscriptionTier.rawValue
    var productID: String?
    var purchaseDate: Date?
    var expirationDate: Date?
    var isTrialPeriod: Bool
    var isActive: Bool
    var autoRenewStatus: String  // "active", "cancelled", "expired"
    var lastVerifiedDate: Date
    var receiptData: Data?
    
    init(
        id: String = UUID().uuidString,
        tier: String = SubscriptionTier.free.rawValue,
        productID: String? = nil,
        purchaseDate: Date? = nil,
        expirationDate: Date? = nil,
        isTrialPeriod: Bool = false,
        isActive: Bool = false,
        autoRenewStatus: String = "inactive",
        lastVerifiedDate: Date = Date(),
        receiptData: Data? = nil
    ) {
        self.id = id
        self.tier = tier
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.isTrialPeriod = isTrialPeriod
        self.isActive = isActive
        self.autoRenewStatus = autoRenewStatus
        self.lastVerifiedDate = lastVerifiedDate
        self.receiptData = receiptData
    }
    
    /// 当前层级
    var currentTier: SubscriptionTier {
        SubscriptionTier(rawValue: tier) ?? .free
    }
    
    /// 是否已过期
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date() && !isActive
    }
    
    /// 剩余天数
    var remainingDays: Int? {
        guard let expirationDate = expirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
        return days
    }
}

// MARK: - 高级功能

/// 高级功能类型
enum PremiumFeature: String, CaseIterable {
    // AI 功能
    case unlimitedAIAnalysis = "unlimited_ai_analysis"
    case unlimitedAIArt = "unlimited_ai_art"
    case priorityAIProcessing = "priority_ai_processing"
    
    // 分析功能
    case advancedAnalytics = "advanced_analytics"
    case patternPrediction = "pattern_prediction"
    case dreamCorrelation = "dream_correlation"
    
    // 导出功能
    case advancedExport = "advanced_export"
    case pdfExport = "pdf_export"
    case epubExport = "epub_export"
    case audioExport = "audio_export"
    
    // 备份功能
    case cloudBackup = "cloud_backup"
    
    // 个性化
    case premiumThemes = "premium_themes"
    case customWidgets = "custom_widgets"
    
    // 其他
    case noAds = "no_ads"
    case prioritySupport = "priority_support"
    case earlyAccess = "early_access"
    case exclusiveBadges = "exclusive_badges"
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .unlimitedAIAnalysis: return "无限 AI 解析"
        case .unlimitedAIArt: return "无限 AI 绘画"
        case .priorityAIProcessing: return "优先 AI 处理"
        case .advancedAnalytics: return "高级数据分析"
        case .patternPrediction: return "梦境模式预测"
        case .dreamCorrelation: return "梦境关联分析"
        case .advancedExport: return "高级导出"
        case .pdfExport: return "PDF 导出"
        case .epubExport: return "EPUB 导出"
        case .audioExport: return "音频导出"
        case .cloudBackup: return "云备份"
        case .premiumThemes: return "高级主题"
        case .customWidgets: return "自定义小组件"
        case .noAds: return "无广告"
        case .prioritySupport: return "优先支持"
        case .earlyAccess: return "抢先体验"
        case .exclusiveBadges: return "专属徽章"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .unlimitedAIAnalysis: return "🧠"
        case .unlimitedAIArt: return "🎨"
        case .priorityAIProcessing: return "⚡"
        case .advancedAnalytics: return "📊"
        case .patternPrediction: return "🔮"
        case .dreamCorrelation: return "🔗"
        case .advancedExport: return "📤"
        case .pdfExport: return "📕"
        case .epubExport: return "📖"
        case .audioExport: return "🎙️"
        case .cloudBackup: return "☁️"
        case .premiumThemes: return "🎨"
        case .customWidgets: return "📱"
        case .noAds: return "✨"
        case .prioritySupport: return "💬"
        case .earlyAccess: return "🚀"
        case .exclusiveBadges: return "🏆"
        }
    }
    
    /// 描述
    var description: String {
        switch self {
        case .unlimitedAIAnalysis: return "无限制使用 AI 梦境解析"
        case .unlimitedAIArt: return "无限制生成 AI 梦境艺术"
        case .priorityAIProcessing: return "AI 请求优先处理"
        case .advancedAnalytics: return "深度数据分析和洞察"
        case .patternPrediction: return "预测未来梦境模式"
        case .dreamCorrelation: return "发现梦境之间的隐藏关联"
        case .advancedExport: return "多种格式导出选项"
        case .pdfExport: return "导出精美 PDF 日记"
        case .epubExport: return "导出 EPUB 电子书"
        case .audioExport: return "导出音频日记"
        case .cloudBackup: return "Google Drive/Dropbox/OneDrive 备份"
        case .premiumThemes: return "12 种独家精美主题"
        case .customWidgets: return "完全自定义小组件"
        case .noAds: return "无任何广告干扰"
        case .prioritySupport: return "优先客户支持"
        case .earlyAccess: return "抢先体验新功能"
        case .exclusiveBadges: return "终身用户专属徽章"
        }
    }
}

// MARK: - 功能访问权限

/// 功能访问权限配置
struct FeatureAccess {
    /// 每日 AI 解析次数限制 (免费版)
    static let freeDailyAIAnalysisLimit = 3
    
    /// 每月 AI 绘画次数限制 (免费版)
    static let freeMonthlyAIArtLimit = 10
    
    /// 检查功能是否可用
    static func canAccess(_ feature: PremiumFeature, tier: SubscriptionTier) -> Bool {
        switch feature {
        // 免费版有限的功能
        case .unlimitedAIAnalysis, .unlimitedAIArt:
            return tier != .free
        case .priorityAIProcessing:
            return tier != .free
            
        // 高级功能
        case .advancedAnalytics, .patternPrediction, .dreamCorrelation:
            return tier != .free
        case .advancedExport, .pdfExport, .epubExport, .audioExport:
            return tier != .free
        case .cloudBackup:
            return tier != .free
        case .premiumThemes, .customWidgets:
            return tier != .free
        case .noAds:
            return tier != .free
            
        // 终身版专属
        case .prioritySupport, .earlyAccess, .exclusiveBadges:
            return tier == .lifetime
        }
    }
    
    /// 获取剩余使用次数
    static func getRemainingUsage(for feature: PremiumFeature, tier: SubscriptionTier, currentUsage: Int) -> Int? {
        guard tier == .free else { return nil }  // 付费版本无限制
        
        switch feature {
        case .unlimitedAIAnalysis:
            return max(0, freeDailyAIAnalysisLimit - currentUsage)
        case .unlimitedAIArt:
            return max(0, freeMonthlyAIArtLimit - currentUsage)
        default:
            return FeatureAccess.canAccess(feature, tier: tier) ? nil : 0
        }
    }
}

// MARK: - 订阅配置

/// 订阅产品配置
struct SubscriptionProducts {
    /// 高级版 - 月度
    static let premiumMonthly = "com.dreamlog.premium.monthly"
    
    /// 高级版 - 年度
    static let premiumYearly = "com.dreamlog.premium.yearly"
    
    /// 终身版
    static let lifetime = "com.dreamlog.lifetime"
    
    /// 所有产品 ID
    static let allProductIDs: [String] = [
        premiumMonthly,
        premiumYearly,
        lifetime
    ]
}

// MARK: - 付费墙配置

/// 付费墙展示配置
struct PaywallConfig {
    /// 标题
    let title = "解锁 DreamLog 全部潜能"
    
    /// 副标题
    let subtitle = "升级至高级版，获得完整的梦境探索体验"
    
    /// 免费试用天数
    let freeTrialDays = 7
    
    /// 特色功能列表 (显示在付费墙上)
    let featuredFeatures: [PremiumFeature] = [
        .unlimitedAIAnalysis,
        .unlimitedAIArt,
        .advancedAnalytics,
        .patternPrediction,
        .cloudBackup,
        .premiumThemes
    ]
}
