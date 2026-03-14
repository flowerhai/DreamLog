//
//  DreamTimeCapsuleService.swift
//  DreamLog - Phase 27: 梦境时间胶囊
//
//  时间胶囊核心服务
//  管理时间胶囊的创建、解锁、通知等功能
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
class DreamTimeCapsuleService: ObservableObject {
    static let shared = DreamTimeCapsuleService()
    
    @Published var capsules: [DreamTimeCapsule] = []
    @Published var stats: TimeCapsuleStats = TimeCapsuleStats()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let modelContext: ModelContext
    private let notificationService: NotificationService
    
    init(modelContext: ModelContext? = nil, notificationService: NotificationService? = nil) {
        if let modelContext = modelContext {
            self.modelContext = modelContext
        } else if let app = DreamLogApp.shared {
            self.modelContext = ModelContext(app.modelContainer)
        } else {
            // Fallback: create an in-memory context for testing
            let schema = Schema([DreamTimeCapsule.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                self.modelContext = ModelContext(container)
            } catch {
                fatalError("Failed to create in-memory model container: \(error)")
            }
        }
        self.notificationService = notificationService ?? NotificationService.shared
        Task { await loadCapsules() }
    }
    
    // MARK: - 加载时间胶囊
    
    func loadCapsules() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<DreamTimeCapsule>(
                sortBy: [SortDescriptor(\.unlockDate, order: .forward)]
            )
            capsules = try modelContext.fetch(descriptor)
            
            // 检查并更新过期状态
            await checkExpiredCapsules()
            
            // 更新统计
            await updateStats()
            
            // 检查是否有可解锁的胶囊
            await checkReadyToUnlockCapsules()
            
            isLoading = false
        } catch {
            errorMessage = "加载时间胶囊失败：\(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - 创建时间胶囊
    
    func createCapsule(config: TimeCapsuleConfig) async throws -> DreamTimeCapsule {
        guard config.isValid else {
            throw TimeCapsuleError.invalidConfig
        }
        
        let capsule = DreamTimeCapsule(
            title: config.title,
            message: config.message,
            capsuleType: config.capsuleType,
            unlockDate: config.unlockDate,
            dreamIds: config.selectedDreamIds,
            notifyOnUnlock: config.notifyOnUnlock,
            shareWithFriendId: config.shareWithFriendId,
            shareMessage: config.shareMessage
        )
        
        capsule.tags = config.tags
        
        modelContext.insert(capsule)
        
        try modelContext.save()
        
        // 设置解锁提醒
        if config.notifyOnUnlock {
            await scheduleUnlockNotification(for: capsule)
        }
        
        // 刷新列表
        await loadCapsules()
        
        return capsule
    }
    
    // MARK: - 解锁时间胶囊
    
    func unlockCapsule(_ capsule: DreamTimeCapsule) async throws {
        guard capsule.isReadyToUnlock else {
            throw TimeCapsuleError.notReadyToUnlock
        }
        
        capsule.unlock()
        
        try modelContext.save()
        
        // 增加查看次数
        capsule.incrementViewCount()
        
        // 刷新列表
        await loadCapsules()
        
        // 发送解锁通知
        await sendUnlockNotification(for: capsule)
    }
    
    // MARK: - 删除时间胶囊
    
    func deleteCapsule(_ capsule: DreamTimeCapsule) async throws {
        modelContext.delete(capsule)
        try modelContext.save()
        
        // 取消相关通知
        await cancelNotifications(for: capsule)
        
        // 刷新列表
        await loadCapsules()
    }
    
    // MARK: - 收藏管理
    
    func toggleFavorite(_ capsule: DreamTimeCapsule) async throws {
        capsule.toggleFavorite()
        try modelContext.save()
        await loadCapsules()
    }
    
    // MARK: - 批量操作
    
    func createAutoYearlyReviewCapsules() async {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        
        // 为过去年份创建年度回顾胶囊（如果不存在）
        for year in (currentYear - 3)..<currentYear {
            guard let yearStartDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                  let yearEndDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
                continue
            }
            
            // 检查是否已存在该年份的胶囊
            let existing = capsules.first {
                $0.typedCapsuleType == .yearlyReview &&
                $0.title.contains("\(year)")
            }
            
            if existing == nil {
                // 获取该年份的梦境
                let dreamIds = await getDreamIdsForYear(year)
                
                if !dreamIds.isEmpty {
                    // 解锁日期设为次年 1 月 1 日
                    guard let unlockDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
                        continue
                    }
                    
                    do {
                        _ = try await createCapsule(config: TimeCapsuleConfig(
                            title: "\(year) 年度梦境回顾",
                            message: "这是你在 \(year) 年记录的所有梦境。回顾一下，看看你的潜意识在这一年里经历了什么...",
                            capsuleType: .yearlyReview,
                            selectedDreamIds: dreamIds,
                            unlockDate: unlockDate
                        ))
                    } catch {
                        print("创建年度回顾胶囊失败：\(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - 快捷胶囊创建
    
    func createQuickCapsule(
        dreamIds: [String],
        daysInFuture: Int = 7
    ) async throws -> DreamTimeCapsule {
        let config = TimeCapsuleConfig(
            title: "梦境时间胶囊",
            message: "未来的我，希望这些梦境能给你带来一些启示...",
            capsuleType: .futureSelf,
            selectedDreamIds: dreamIds,
            unlockDate: Calendar.current.date(byAdding: .day, value: daysInFuture, to: Date()) ?? Date()
        )
        
        return try await createCapsule(config: config)
    }
    
    func createMilestoneCapsule(
        title: String,
        message: String,
        dreamIds: [String],
        milestoneDate: Date
    ) async throws -> DreamTimeCapsule {
        let config = TimeCapsuleConfig(
            title: title,
            message: message,
            capsuleType: .milestone,
            selectedDreamIds: dreamIds,
            unlockDate: milestoneDate
        )
        
        return try await createCapsule(config: config)
    }
    
    // MARK: - 私有方法
    
    private func checkExpiredCapsules() async {
        for capsule in capsules {
            capsule.expire()
        }
        try? modelContext.save()
    }
    
    private func updateStats() async {
        let total = capsules.count
        let locked = capsules.filter { $0.typedStatus == .locked }.count
        let unlocked = capsules.filter { $0.typedStatus == .unlocked }.count
        let expired = capsules.filter { $0.typedStatus == .expired }.count
        let totalDreams = capsules.reduce(0) { $0 + $1.dreamCount }
        let favorites = capsules.filter { $0.isFavorite }.count
        
        // 计算下次解锁日期
        let lockedCapsules = capsules.filter { $0.isLocked }
        let nextUnlock = lockedCapsules.min(by: { $0.unlockDate < $1.unlockDate })?.unlockDate
        
        // 按类型统计
        var byType: [TimeCapsuleType: Int] = [:]
        for capsule in capsules {
            let type = capsule.typedCapsuleType
            byType[type, default: 0] += 1
        }
        
        // 可解锁数量
        let readyToUnlock = capsules.filter { $0.isReadyToUnlock }.count
        
        stats = TimeCapsuleStats(
            totalCapsules: total,
            lockedCapsules: locked,
            unlockedCapsules: unlocked,
            expiredCapsules: expired,
            totalDreams: totalDreams,
            favoriteCapsules: favorites,
            nextUnlockDate: nextUnlock,
            capsulesByType: byType,
            capsulesReadyToUnlock: readyToUnlock
        )
    }
    
    private func checkReadyToUnlockCapsules() async {
        let ready = capsules.filter { $0.isReadyToUnlock }
        
        for capsule in ready {
            if capsule.notifyOnUnlock && !capsule.notificationSent {
                await sendUnlockNotification(for: capsule)
                capsule.notificationSent = true
            }
        }
        
        try? modelContext.save()
    }
    
    private func scheduleUnlockNotification(for capsule: DreamTimeCapsule) async {
        let content = UNMutableNotificationContent()
        content.title = "🔓 时间胶囊已解锁"
        content.body = "\"\(capsule.title)\" 已准备好解锁，快来看看里面的梦境吧！"
        content.sound = .default
        content.categoryIdentifier = "dream_time_capsule"
        content.userInfo = ["capsuleId": capsule.id.uuidString]
        
        let triggerDate = capsule.unlockDate
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "capsule_unlock_\(capsule.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        await notificationService.scheduleNotification(request)
    }
    
    private func sendUnlockNotification(for capsule: DreamTimeCapsule) async {
        let content = UNMutableNotificationContent()
        content.title = "🎉 时间胶囊已解锁"
        content.body = "\"\(capsule.title)\" 已解锁！\(capsule.dreamCount) 个梦境等待你回顾。"
        content.sound = .default
        content.categoryIdentifier = "dream_time_capsule_unlock"
        content.userInfo = ["capsuleId": capsule.id.uuidString]
        
        let request = UNNotificationRequest(
            identifier: "capsule_unlocked_\(capsule.id.uuidString)",
            content: content,
            trigger: nil // 立即发送
        )
        
        await notificationService.scheduleNotification(request)
    }
    
    private func cancelNotifications(for capsule: DreamTimeCapsule) async {
        let ids = [
            "capsule_unlock_\(capsule.id.uuidString)",
            "capsule_unlocked_\(capsule.id.uuidString)"
        ]
        await notificationService.cancelNotifications(withIds: ids)
    }
    
    private func getDreamIdsForYear(_ year: Int) async -> [String] {
        // 这里需要从 DreamStore 获取指定年份的梦境 ID
        // 简化实现，实际应该查询数据库
        return []
    }
}

// MARK: - 错误类型

enum TimeCapsuleError: LocalizedError {
    case invalidConfig
    case notReadyToUnlock
    case notFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidConfig:
            return "配置无效，请检查必填项"
        case .notReadyToUnlock:
            return "时间胶囊还未到解锁时间"
        case .notFound:
            return "时间胶囊不存在"
        case .saveFailed:
            return "保存失败，请重试"
        }
    }
}

// MARK: - 通知类别

extension DreamTimeCapsuleService {
    static func registerNotificationCategories() {
        let unlockAction = UNNotificationAction(
            identifier: "UNLOCK_CAPSULE",
            title: "立即解锁",
            options: .foreground
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "稍后提醒",
            options: []
        )
        
        let capsuleCategory = UNNotificationCategory(
            identifier: "dream_time_capsule",
            actions: [unlockAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        let unlockCategory = UNNotificationCategory(
            identifier: "dream_time_capsule_unlock",
            actions: [unlockAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([capsuleCategory, unlockCategory])
    }
}
