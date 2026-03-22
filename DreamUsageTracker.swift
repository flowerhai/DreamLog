//
//  DreamUsageTracker.swift
//  DreamLog - 使用量追踪服务
//
//  Phase 87 - App Store 发布与高级功能
//  追踪免费版用户的使用量限制 (AI 解析/AI 绘画)
//  Created: 2026-03-23
//

import Foundation
import SwiftData

// MARK: - 使用量追踪服务

@MainActor
final class DreamUsageTracker: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 今日 AI 解析次数
    @Published private(set) var todayAIAnalysisCount: Int = 0
    
    /// 本月 AI 绘画次数
    @Published private(set) var thisMonthAIArtCount: Int = 0
    
    /// 剩余 AI 解析次数
    var remainingAIAnalysisToday: Int {
        let limit = FeatureAccess.freeDailyAIAnalysisLimit
        return max(0, limit - todayAIAnalysisCount)
    }
    
    /// 剩余 AI 绘画次数
    var remainingAIArtThisMonth: Int {
        let limit = FeatureAccess.freeMonthlyAIArtLimit
        return max(0, limit - thisMonthAIArtCount)
    }
    
    /// 是否达到 AI 解析限制
    var hasReachedAIAnalysisLimit: Bool {
        remainingAIAnalysisToday <= 0
    }
    
    /// 是否达到 AI 绘画限制
    var hasReachedAIArtLimit: Bool {
        remainingAIArtThisMonth <= 0
    }
    
    // MARK: - 单例
    
    static let shared = DreamUsageTracker()
    
    // MARK: - 存储键
    
    private let aiAnalysisCountKey = "dream_usage_ai_analysis_count"
    private let aiAnalysisDateKey = "dream_usage_ai_analysis_date"
    private let aiArtCountKey = "dream_usage_ai_art_count"
    private let aiArtMonthKey = "dream_usage_ai_art_month"
    
    // MARK: - 初始化
    
    private init() {
        resetCountersIfNeeded()
        loadCounts()
        
        // 监听订阅状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionChange),
            name: NSNotification.Name("SubscriptionStatusChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 公共方法
    
    /// 重置计数器（如果需要）
    func resetCountersIfNeeded() {
        resetAIAnalysisCounterIfNeeded()
        resetAIArtCounterIfNeeded()
    }
    
    /// 记录 AI 解析使用
    func recordAIAnalysisUsage() {
        guard !SubscriptionManager.shared.isPremium else { return }
        
        todayAIAnalysisCount += 1
        saveAIAnalysisCount()
        
        objectWillChange.send()
    }
    
    /// 记录 AI 绘画使用
    func recordAIArtUsage() {
        guard !SubscriptionManager.shared.isPremium else { return }
        
        thisMonthAIArtCount += 1
        saveAIArtCount()
        
        objectWillChange.send()
    }
    
    /// 检查是否可以使用 AI 解析
    func canUseAIAnalysis() -> Bool {
        if SubscriptionManager.shared.isPremium {
            return true
        }
        return !hasReachedAIAnalysisLimit
    }
    
    /// 检查是否可以使用 AI 绘画
    func canUseAIArt() -> Bool {
        if SubscriptionManager.shared.isPremium {
            return true
        }
        return !hasReachedAIArtLimit
    }
    
    /// 获取 AI 解析限制信息
    func getAIAnalysisLimitInfo() -> UsageLimitInfo {
        let limit = FeatureAccess.freeDailyAIAnalysisLimit
        return UsageLimitInfo(
            used: todayAIAnalysisCount,
            limit: limit,
            remaining: remainingAIAnalysisToday,
            resetDate: nextResetDate(for: .daily),
            period: .daily
        )
    }
    
    /// 获取 AI 绘画限制信息
    func getAIArtLimitInfo() -> UsageLimitInfo {
        let limit = FeatureAccess.freeMonthlyAIArtLimit
        return UsageLimitInfo(
            used: thisMonthAIArtCount,
            limit: limit,
            remaining: remainingAIArtThisMonth,
            resetDate: nextResetDate(for: .monthly),
            period: .monthly
        )
    }
    
    /// 手动重置计数器（用于测试或订阅状态变化）
    func resetAllCounters() {
        todayAIAnalysisCount = 0
        thisMonthAIArtCount = 0
        saveAIAnalysisCount()
        saveAIArtCount()
        objectWillChange.send()
    }
    
    // MARK: - 私有方法
    
    private func loadCounts() {
        let defaults = UserDefaults.standard
        
        // 加载 AI 解析计数
        if let storedDate = defaults.string(forKey: aiAnalysisDateKey),
           storedDate == currentDateKey(for: .daily) {
            todayAIAnalysisCount = defaults.integer(forKey: aiAnalysisCountKey)
        } else {
            todayAIAnalysisCount = 0
        }
        
        // 加载 AI 绘画计数
        if let storedMonth = defaults.string(forKey: aiArtMonthKey),
           storedMonth == currentDateKey(for: .monthly) {
            thisMonthAIArtCount = defaults.integer(forKey: aiArtCountKey)
        } else {
            thisMonthAIArtCount = 0
        }
    }
    
    private func saveAIAnalysisCount() {
        let defaults = UserDefaults.standard
        defaults.set(todayAIAnalysisCount, forKey: aiAnalysisCountKey)
        defaults.set(currentDateKey(for: .daily), forKey: aiAnalysisDateKey)
    }
    
    private func saveAIArtCount() {
        let defaults = UserDefaults.standard
        defaults.set(thisMonthAIArtCount, forKey: aiArtCountKey)
        defaults.set(currentDateKey(for: .monthly), forKey: aiArtMonthKey)
    }
    
    private func resetAIAnalysisCounterIfNeeded() {
        let defaults = UserDefaults.standard
        let storedDate = defaults.string(forKey: aiAnalysisDateKey)
        let today = currentDateKey(for: .daily)
        
        if storedDate != today {
            todayAIAnalysisCount = 0
            saveAIAnalysisCount()
        }
    }
    
    private func resetAIArtCounterIfNeeded() {
        let defaults = UserDefaults.standard
        let storedMonth = defaults.string(forKey: aiArtMonthKey)
        let currentMonth = currentDateKey(for: .monthly)
        
        if storedMonth != currentMonth {
            thisMonthAIArtCount = 0
            saveAIArtCount()
        }
    }
    
    private func currentDateKey(for period: ResetPeriod) -> String {
        let formatter = DateFormatter()
        switch period {
        case .daily:
            formatter.dateFormat = "yyyy-MM-dd"
        case .monthly:
            formatter.dateFormat = "yyyy-MM"
        }
        return formatter.string(from: Date())
    }
    
    private func nextResetDate(for period: ResetPeriod) -> Date {
        let calendar = Calendar.current
        switch period {
        case .daily:
            // 明天零点
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
                return Date()
            }
            return calendar.startOfDay(for: tomorrow)
        case .monthly:
            // 下月 1 号
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) else {
                return Date()
            }
            return calendar.date(from: DateComponents(year: nextMonth.year, month: nextMonth.month, day: 1)) ?? Date()
        }
    }
    
    @objc private func handleSubscriptionChange() {
        // 订阅状态变化时，如果是 premium 用户，重置计数器显示
        if SubscriptionManager.shared.isPremium {
            resetAllCounters()
        } else {
            loadCounts()
        }
    }
}

// MARK: - 使用量限制信息

struct UsageLimitInfo {
    let used: Int
    let limit: Int
    let remaining: Int
    let resetDate: Date
    let period: ResetPeriod
    
    /// 格式化剩余次数
    var remainingText: String {
        if remaining == Int.max {
            return "无限"
        }
        return "\(remaining) 次"
    }
    
    /// 格式化重置时间
    var resetDateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: resetDate, relativeTo: Date())
    }
    
    /// 使用进度
    var progress: Double {
        guard limit > 0 && limit != Int.max else { return 0 }
        return Double(used) / Double(limit)
    }
}

// MARK: - 重置周期

enum ResetPeriod {
    case daily
    case monthly
    
    var displayName: String {
        switch self {
        case .daily: return "每日"
        case .monthly: return "每月"
        }
    }
}

// MARK: - 通知名称

extension Notification.Name {
    static let SubscriptionStatusChanged = Notification.Name("SubscriptionStatusChanged")
}
