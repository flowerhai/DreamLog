//
//  DreamIncubationService.swift
//  DreamLog
//
//  梦境孵育核心服务
//  管理孵育会话的创建、跟踪和统计
//

import Foundation
import SwiftData
import UserNotifications
import ActivityKit

/// 梦境孵育服务
@MainActor
class DreamIncubationService: ObservableObject {
    static let shared = DreamIncubationService()
    
    // MARK: - Published Properties
    
    @Published var sessions: [DreamIncubationSession] = []
    @Published var isCreatingSession: Bool = false
    @Published var activeSession: DreamIncubationSession?
    @Published var reminderConfig: IncubationReminder = IncubationReminder()
    @Published var stats: IncubationStats = IncubationStats()
    
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    private let userDefaults = UserDefaults.standard
    private let statsKey = "dreamIncubationStats"
    private let reminderKey = "dreamIncubationReminder"
    private let liveActivityService = DreamLiveActivityService.shared
    
    // MARK: - Initialization
    
    init() {
        loadReminderConfig()
        setupNotifications()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSessions()
    }
    
    // MARK: - Session Management
    
    /// 创建新的孵育会话
    func createSession(
        type: IncubationType,
        title: String,
        description: String = "",
        intention: String,
        affirmations: [String] = [],
        intensity: IncubationIntensity = .moderate,
        scheduledDate: Date = Date()
    ) async throws -> DreamIncubationSession {
        guard let context = modelContext else {
            throw IncubationError.noModelContext
        }
        
        let session = DreamIncubationSession(
            type: type,
            title: title,
            description: description,
            intention: intention,
            affirmations: affirmations,
            intensity: intensity,
            duration: intensity.recommendedDuration,
            scheduledDate: scheduledDate,
            status: "pending"
        )
        
        context.insert(session)
        try context.save()
        
        await loadSessions()
        
        // 如果是立即开始的会话，激活它
        if scheduledDate <= Date() {
            await activateSession(session.id)
        }
        
        // 发送通知
        await scheduleSessionReminder(session: session)
        
        return session
    }
    
    /// 加载所有孵育会话
    func loadSessions() async {
        guard let context = modelContext else {
            sessions = []
            return
        }
        
        do {
            let descriptor = FetchDescriptor<DreamIncubationSession>(
                sortBy: [SortDescriptor(\.scheduledDate, order: .reverse)]
            )
            sessions = try context.fetch(descriptor)
            calculateStats()
        } catch {
            print("Failed to load incubation sessions: \(error)")
            sessions = []
        }
    }
    
    /// 激活孵育会话
    func activateSession(_ sessionId: UUID) async {
        guard let session = sessions.first(where: { $0.id == sessionId }) else { return }
        
        session.status = "active"
        session.scheduledDate = Date()
        activeSession = session
        
        do {
            try modelContext?.save()
            
            // 启动实时活动
            try? await liveActivityService.startIncubationActivity(incubation: session)
        } catch {
            print("Failed to activate session: \(error)")
        }
    }
    
    /// 完成孵育会话
    func completeSession(_ sessionId: UUID, successRating: Int, notes: String = "", relatedDreamIds: [UUID] = []) async {
        guard let session = sessions.first(where: { $0.id == sessionId }) else { return }
        
        session.status = "completed"
        session.completedDate = Date()
        session.successRating = successRating
        session.notes = notes
        session.relatedDreamIds = relatedDreamIds
        session.updatedAt = Date()
        
        activeSession = nil
        
        do {
            try modelContext?.save()
            await loadSessions()
            
            // 结束实时活动
            await liveActivityService.endIncubationActivity(incubationId: sessionId.uuidString, reason: .completed)
        } catch {
            print("Failed to complete session: \(error)")
        }
    }
    
    /// 取消孵育会话
    func cancelSession(_ sessionId: UUID) async {
        guard let session = sessions.first(where: { $0.id == sessionId }) else { return }
        
        session.status = "cancelled"
        session.updatedAt = Date()
        
        if activeSession?.id == sessionId {
            activeSession = nil
        }
        
        do {
            try modelContext?.save()
        } catch {
            print("Failed to cancel session: \(error)")
        }
    }
    
    /// 删除孵育会话
    func deleteSession(_ sessionId: UUID) async {
        guard let context = modelContext,
              let session = sessions.first(where: { $0.id == sessionId }) else { return }
        
        context.delete(session)
        
        if activeSession?.id == sessionId {
            activeSession = nil
        }
        
        do {
            try context.save()
            await loadSessions()
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
    
    /// 更新孵育会话
    func updateSession(_ session: DreamIncubationSession) async {
        session.updatedAt = Date()
        
        do {
            try modelContext?.save()
        } catch {
            print("Failed to update session: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    /// 计算统计数据
    func calculateStats() {
        let completed = sessions.filter { $0.status == "completed" }
        let pending = sessions.filter { $0.status == "pending" || $0.status == "active" }
        
        let ratedSessions = completed.filter { $0.successRating != nil }
        let avgRating = ratedSessions.isEmpty ? 0 :
            Double(ratedSessions.reduce(0) { $0 + ($1.successRating ?? 0) }) / Double(ratedSessions.count)
        
        let successfulSessions = completed.filter { ($1.successRating ?? 0) >= 4 }
        let successRate = completed.isEmpty ? 0 : Double(successfulSessions.count) / Double(completed.count)
        
        var byType: [String: Int] = [:]
        for session in sessions {
            byType[session.type, default: 0] += 1
        }
        
        let streak = calculateStreakDays()
        
        stats = IncubationStats(
            totalSessions: sessions.count,
            completedSessions: completed.count,
            pendingSessions: pending.count,
            averageSuccessRating: avgRating,
            sessionsByType: byType,
            successRate: successRate,
            streakDays: streak
        )
        
        saveStats()
    }
    
    /// 计算连续孵育天数
    private func calculateStreakDays() -> Int {
        let completed = sessions.filter { $0.status == "completed" }
            .compactMap { $0.completedDate }
            .sorted(by: >)
        
        guard let mostRecent = completed.first else { return 0 }
        
        var streak = 1
        var currentDate = Calendar.current.startOfDay(for: mostRecent)
        
        for date in completed.dropFirst() {
            let previousDate = Calendar.current.startOfDay(for: date)
            let daysDiff = Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if daysDiff == 1 {
                streak += 1
                currentDate = previousDate
            } else if daysDiff > 1 {
                break
            }
        }
        
        return streak
    }
    
    /// 保存统计数据
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            userDefaults.set(encoded, forKey: statsKey)
        }
    }
    
    /// 加载统计数据
    private func loadStats() {
        if let data = userDefaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(IncubationStats.self, from: data) {
            stats = decoded
        }
    }
    
    // MARK: - Templates
    
    /// 获取所有模板
    func getTemplates() -> [IncubationTemplate] {
        IncubationTemplate.templates
    }
    
    /// 根据类型获取模板
    func getTemplate(for type: IncubationType) -> IncubationTemplate? {
        IncubationTemplate.templates.first { $0.type == type }
    }
    
    // MARK: - Notifications
    
    /// 设置通知
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    /// 安排会话提醒
    private func scheduleSessionReminder(session: DreamIncubationSession) async {
        let content = UNMutableNotificationContent()
        content.title = "🌙 梦境孵育提醒"
        content.body = "「\(session.title)」- 记得在睡前专注你的意图"
        content.sound = .default
        content.categoryIdentifier = "dreamIncubation"
        
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -30, to: session.scheduledDate) ?? Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "incubation_\(session.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    /// 加载提醒配置
    private func loadReminderConfig() {
        if let data = userDefaults.data(forKey: reminderKey),
           let decoded = try? JSONDecoder().decode(IncubationReminder.self, from: data) {
            reminderConfig = decoded
        }
    }
    
    /// 保存提醒配置
    func saveReminderConfig() {
        if let encoded = try? JSONEncoder().encode(reminderConfig) {
            userDefaults.set(encoded, forKey: reminderKey)
        }
    }
    
    // MARK: - Insights
    
    /// 获取孵育建议
    func getInsights() -> [String] {
        var insights: [String] = []
        
        if stats.streakDays >= 7 {
            insights.append("🔥 你已经连续孵育 \(stats.streakDays) 天，继续保持！")
        }
        
        if stats.successRate >= 0.7 {
            insights.append("✨ 你的孵育成功率很高，说明意图设定很有效！")
        } else if stats.completedSessions > 5 && stats.successRate < 0.5 {
            insights.append("💡 尝试调整孵育强度或睡前仪式，可能会提高成功率")
        }
        
        if let topType = stats.sessionsByType.max(by: { $0.value < $1.value })?.key {
            insights.append("📊 你最常孵育的主题是「\(topType)」")
        }
        
        if stats.pendingSessions > 3 {
            insights.append("⏰ 你有 \(stats.pendingSessions) 个待完成的孵育，记得完成它们")
        }
        
        return insights.isEmpty ? ["开始你的第一次梦境孵育吧！"] : insights
    }
    
    /// 获取推荐模板
    func getRecommendedTemplate() -> IncubationTemplate? {
        // 根据用户历史推荐
        if stats.sessionsByType.isEmpty {
            return IncubationTemplate.templates.first { $0.type == .creative }
        }
        
        // 推荐用户较少尝试的类型
        let leastUsedType = IncubationType.allCases
            .min(by: { (stats.sessionsByType[$0.rawValue] ?? 0) < (stats.sessionsByType[$1.rawValue] ?? 0) })
        
        if let type = leastUsedType {
            return getTemplate(for: type)
        }
        
        return IncubationTemplate.templates.first
    }
}

// MARK: - Errors

enum IncubationError: LocalizedError {
    case noModelContext
    case sessionNotFound
    case invalidSessionStatus
    
    var errorDescription: String? {
        switch self {
        case .noModelContext: return "数据上下文未初始化"
        case .sessionNotFound: return "孵育会话不存在"
        case .invalidSessionStatus: return "无效的会话状态"
        }
    }
}

// MARK: - Notifications Extension

extension UNNotificationCategory {
    static let dreamIncubation = UNNotificationCategory(
        identifier: "dreamIncubation",
        actions: [],
        intentIdentifiers: [],
        options: []
    )
}
