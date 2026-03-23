//
//  DreamPartnerActivityService.swift
//  DreamLog
//
//  梦境伴侣活动动态 - 核心服务
//  Phase 88 Enhancement: 活动动态与通知增强
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
class DreamPartnerActivityService {
    
    static let shared = DreamPartnerActivityService()
    
    private let modelContext: ModelContext
    private var currentUserId: String {
        UserDefaults.standard.string(forKey: "dreamLogUserId") ?? UUID().uuidString
    }
    
    private var notificationSettings: PartnerNotificationSettings {
        get {
            guard let data = UserDefaults.standard.data(forKey: "partnerNotificationSettings"),
                  let settings = try? JSONDecoder().decode(PartnerNotificationSettings.self, from: data) else {
                return PartnerNotificationSettings()
            }
            return settings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "partnerNotificationSettings")
            }
        }
    }
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? (try? ModelContext(ModelConfiguration(for: PartnerActivity.self)))!
    }
    
    // MARK: - 活动记录
    
    /// 记录活动
    func logActivity(type: PartnerActivityType,
                     actorId: String,
                     actorName: String,
                     actorAvatar: String? = nil,
                     targetId: String? = nil,
                     targetTitle: String? = nil,
                     content: String? = nil,
                     metadata: [String: String]? = nil) async {
        let activity = PartnerActivity(
            type: type,
            actorId: actorId,
            actorName: actorName,
            actorAvatar: actorAvatar,
            targetId: targetId,
            targetTitle: targetTitle,
            content: content,
            metadata: metadata
        )
        
        try? modelContext.insert(activity)
        try? modelContext.save()
        
        // 发送通知
        await sendNotification(for: activity)
    }
    
    /// 记录梦境分享
    func logDreamShare(dreamId: String, dreamTitle: String, partnerId: String, partnerName: String) async {
        await logActivity(
            type: .dreamShared,
            actorId: partnerId,
            actorName: partnerName,
            targetId: dreamId,
            targetTitle: dreamTitle
        )
    }
    
    /// 记录梦境查看
    func logDreamView(dreamId: String, dreamTitle: String, partnerId: String, partnerName: String) async {
        await logActivity(
            type: .dreamViewed,
            actorId: partnerId,
            actorName: partnerName,
            targetId: dreamId,
            targetTitle: dreamTitle
        )
    }
    
    /// 记录评论
    func logComment(dreamId: String, dreamTitle: String, partnerId: String, partnerName: String, comment: String) async {
        await logActivity(
            type: .commentAdded,
            actorId: partnerId,
            actorName: partnerName,
            targetId: dreamId,
            targetTitle: dreamTitle,
            content: comment
        )
    }
    
    /// 记录反应
    func logReaction(dreamId: String, partnerId: String, partnerName: String, reaction: String) async {
        await logActivity(
            type: .reactionAdded,
            actorId: partnerId,
            actorName: partnerName,
            targetId: dreamId,
            content: reaction
        )
    }
    
    /// 记录连接建立
    func logConnection(partnerId: String, partnerName: String) async {
        await logActivity(
            type: .partnerConnected,
            actorId: partnerId,
            actorName: partnerName
        )
    }
    
    // MARK: - 查询活动
    
    /// 获取所有活动
    func getAllActivities(limit: Int = 100) -> [PartnerActivity] {
        let descriptor = FetchDescriptor<PartnerActivity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取未读活动
    func getUnreadActivities() -> [PartnerActivity] {
        getAllActivities().filter { !$0.isRead }
    }
    
    /// 获取特定类型的活动
    func getActivities(type: PartnerActivityType, limit: Int = 50) -> [PartnerActivity] {
        let descriptor = FetchDescriptor<PartnerActivity>(
            predicate: #Predicate { $0.type == type },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取特定目标的活动
    func getActivities(targetId: String, limit: Int = 50) -> [PartnerActivity] {
        let descriptor = FetchDescriptor<PartnerActivity>(
            predicate: #Predicate { $0.targetId == targetId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取统计信息
    func getStats() -> PartnerActivityStats {
        var stats = PartnerActivityStats()
        let activities = getAllActivities(limit: 100)
        stats.calculate(from: activities)
        return stats
    }
    
    // MARK: - 标记已读
    
    /// 标记活动为已读
    func markAsRead(_ activity: PartnerActivity) {
        activity.isRead = true
        try? modelContext.save()
    }
    
    /// 标记所有活动为已读
    func markAllAsRead() {
        let activities = getAllActivities()
        for activity in activities {
            activity.isRead = true
        }
        try? modelContext.save()
    }
    
    /// 标记特定类型为已读
    func markTypeAsRead(_ type: PartnerActivityType) {
        let activities = getActivities(type: type)
        for activity in activities {
            activity.isRead = true
        }
        try? modelContext.save()
    }
    
    // MARK: - 删除活动
    
    /// 删除活动
    func deleteActivity(_ activity: PartnerActivity) {
        modelContext.delete(activity)
        try? modelContext.save()
    }
    
    /// 删除所有活动
    func deleteAllActivities() {
        let activities = getAllActivities()
        for activity in activities {
            modelContext.delete(activity)
        }
        try? modelContext.save()
    }
    
    /// 清理旧活动 (保留最近 30 天)
    func cleanupOldActivities(keepDays: Int = 30) {
        let cutoffDate = Date().addingTimeInterval(-Double(keepDays * 86400))
        let activities = getAllActivities(limit: 1000)
        
        for activity in activities where activity.createdAt < cutoffDate {
            modelContext.delete(activity)
        }
        try? modelContext.save()
    }
    
    // MARK: - 通知设置
    
    /// 获取通知设置
    func getNotificationSettings() -> PartnerNotificationSettings {
        return notificationSettings
    }
    
    /// 更新通知设置
    func updateNotificationSettings(_ settings: PartnerNotificationSettings) {
        notificationSettings = settings
    }
    
    /// 设置特定类型的通知开关
    func setNotificationEnabled(_ enabled: Bool, for type: PartnerActivityType) {
        var settings = notificationSettings
        switch type {
        case .dreamShared: settings.enableDreamShared = enabled
        case .dreamViewed: settings.enableDreamViewed = enabled
        case .commentAdded: settings.enableCommentAdded = enabled
        case .reactionAdded: settings.enableReactionAdded = enabled
        case .partnerConnected: settings.enablePartnerConnected = enabled
        case .inviteAccepted: settings.enableInviteAccepted = enabled
        default: break
        }
        notificationSettings = settings
    }
    
    // MARK: - 通知发送
    
    /// 发送通知
    private func sendNotification(for activity: PartnerActivity) async {
        guard notificationSettings.shouldNotify(for: activity.type) else {
            return
        }
        
        let title: String
        let body: String
        
        switch activity.type {
        case .dreamShared:
            title = "🌙 新梦境分享"
            body = "\(activity.actorName) 与你分享了梦境\"\(activity.targetTitle ?? "")\""
        case .dreamViewed:
            title = "👁️ 梦境被查看"
            body = "\(activity.actorName) 查看了你的梦境"
        case .commentAdded:
            title = "💬 新评论"
            body = "\(activity.actorName): \(activity.content ?? "")"
        case .reactionAdded:
            title = "❤️ 新反应"
            body = "\(activity.actorName) 对你的梦境表达了\(activity.content ?? "喜欢")"
        case .partnerConnected:
            title = "🤝 新伴侣连接"
            body = "你与 \(activity.actorName) 建立了梦境共享关系"
        case .inviteAccepted:
            title = "✅ 邀请已接受"
            body = "\(activity.actorName) 接受了你的邀请"
        default:
            return
        }
        
        await sendNotification(title: title, body: body, activityId: activity.id)
    }
    
    /// 发送系统通知
    private func sendNotification(title: String, body: String, activityId: String? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "DREAM_PARTNER"
        
        if let activityId = activityId {
            content.userInfo = ["activityId": activityId]
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 请求通知权限
    
    /// 请求通知权限
    func requestNotificationAuthorization() async -> Bool {
        do {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            
            if granted {
                await registerNotificationCategories()
            }
            
            return granted
        } catch {
            print("请求通知权限失败：\(error)")
            return false
        }
    }
    
    /// 注册通知类别
    private func registerNotificationCategories() async {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "查看",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "稍后",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "DREAM_PARTNER",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
