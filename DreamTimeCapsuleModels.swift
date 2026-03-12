//
//  DreamTimeCapsuleModels.swift
//  DreamLog - Phase 27: 梦境时间胶囊
//
//  时间胶囊数据模型
//  允许用户锁定梦境并在未来特定日期解锁
//

import Foundation
import SwiftData

// MARK: - 时间胶囊状态

enum TimeCapsuleStatus: String, Codable, CaseIterable {
    case locked       // 已锁定
    case unlocked     // 已解锁
    case expired      // 已过期 (超过解锁日期未解锁)
    
    var displayName: String {
        switch self {
        case .locked: return "🔒 已锁定"
        case .unlocked: return "🔓 已解锁"
        case .expired: return "⏰ 已过期"
        }
    }
    
    var color: String {
        switch self {
        case .locked: return "orange"
        case .unlocked: return "green"
        case .expired: return "red"
        }
    }
}

// MARK: - 时间胶囊类型

enum TimeCapsuleType: String, Codable, CaseIterable {
    case personal     // 个人回忆
    case futureSelf   // 给未来的自己
    case shareWithFriend // 分享给朋友
    case yearlyReview // 年度回顾
    case milestone    // 里程碑纪念
    
    var displayName: String {
        switch self {
        case .personal: return "💭 个人回忆"
        case .futureSelf: return "📮 给未来的自己"
        case .shareWithFriend: return "👥 分享给朋友"
        case .yearlyReview: return "📅 年度回顾"
        case .milestone: return "🏆 里程碑纪念"
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "💭"
        case .futureSelf: return "📮"
        case .shareWithFriend: return "👥"
        case .yearlyReview: return "📅"
        case .milestone: return "🏆"
        }
    }
}

// MARK: - 时间胶囊数据模型

@Model
final class DreamTimeCapsule {
    @Attribute(.unique) var id: UUID
    var title: String
    var message: String // 用户写给未来自己的消息
    var capsuleType: String // TimeCapsuleType .rawValue
    var status: String // TimeCapsuleStatus .rawValue
    
    // 时间设置
    var createdAt: Date
    var unlockDate: Date
    var unlockedAt: Date?
    
    // 关联的梦境
    @Relationship var dreamIds: [String] // 存储 Dream.id
    var dreamCount: Int
    
    // 通知设置
    var notifyOnUnlock: Bool
    var notificationSent: Bool
    
    // 分享设置 (用于 shareWithFriend 类型)
    var shareWithFriendId: String?
    var shareMessage: String?
    
    // 元数据
    var tags: [String]
    var isFavorite: Bool
    var viewCount: Int
    
    init(
        title: String,
        message: String,
        capsuleType: TimeCapsuleType,
        unlockDate: Date,
        dreamIds: [String],
        notifyOnUnlock: Bool = true,
        shareWithFriendId: String? = nil,
        shareMessage: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.capsuleType = capsuleType.rawValue
        self.status = TimeCapsuleStatus.locked.rawValue
        self.createdAt = Date()
        self.unlockDate = unlockDate
        self.dreamIds = dreamIds
        self.dreamCount = dreamIds.count
        self.notifyOnUnlock = notifyOnUnlock
        self.notificationSent = false
        self.shareWithFriendId = shareWithFriendId
        self.shareMessage = shareMessage
        self.tags = []
        self.isFavorite = false
        self.viewCount = 0
    }
    
    // MARK: - 计算属性
    
    var typedCapsuleType: TimeCapsuleType {
        TimeCapsuleType(rawValue: capsuleType) ?? .personal
    }
    
    var typedStatus: TimeCapsuleStatus {
        TimeCapsuleStatus(rawValue: status) ?? .locked
    }
    
    var isLocked: Bool {
        typedStatus == .locked && Date() < unlockDate
    }
    
    var isReadyToUnlock: Bool {
        typedStatus == .locked && Date() >= unlockDate
    }
    
    var daysUntilUnlock: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: unlockDate).day ?? 0
        return max(0, days)
    }
    
    var daysSinceUnlock: Int {
        guard let unlockedAt = unlockedAt else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: unlockedAt, to: Date()).day ?? 0
        return days
    }
    
    var unlockProgress: Double {
        let total = unlockDate.timeIntervalSince(createdAt)
        let elapsed = Date().timeIntervalSince(createdAt)
        guard total > 0 else { return 1.0 }
        return min(1.0, max(0.0, elapsed / total))
    }
    
    // MARK: - 状态管理
    
    func unlock() {
        status = TimeCapsuleStatus.unlocked.rawValue
        unlockedAt = Date()
    }
    
    func expire() {
        if typedStatus == .locked && Date() > unlockDate.addingTimeInterval(7 * 24 * 60 * 60) {
            status = TimeCapsuleStatus.expired.rawValue
        }
    }
    
    func incrementViewCount() {
        viewCount += 1
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    // MARK: - 快捷初始化
    
    static func createYearlyReviewCapsule(
        year: Int,
        dreamIds: [String],
        unlockDate: Date
    ) -> DreamTimeCapsule {
        DreamTimeCapsule(
            title: "\(year) 年度梦境回顾",
            message: "这是你在 \(year) 年记录的所有梦境。回顾一下，看看你的潜意识在这一年里经历了什么...",
            capsuleType: .yearlyReview,
            unlockDate: unlockDate,
            dreamIds: dreamIds
        )
    }
    
    static func createFutureSelfCapsule(
        title: String,
        message: String,
        dreamIds: [String],
        daysInFuture: Int
    ) -> DreamTimeCapsule {
        let unlockDate = Calendar.current.date(byAdding: .day, value: daysInFuture, to: Date()) ?? Date()
        return DreamTimeCapsule(
            title: title,
            message: message,
            capsuleType: .futureSelf,
            unlockDate: unlockDate,
            dreamIds: dreamIds
        )
    }
    
    static func createMilestoneCapsule(
        title: String,
        message: String,
        dreamIds: [String],
        milestoneDate: Date
    ) -> DreamTimeCapsule {
        DreamTimeCapsule(
            title: title,
            message: message,
            capsuleType: .milestone,
            unlockDate: milestoneDate,
            dreamIds: dreamIds
        )
    }
}

// MARK: - 时间胶囊统计

struct TimeCapsuleStats {
    var totalCapsules: Int
    var lockedCapsules: Int
    var unlockedCapsules: Int
    var expiredCapsules: Int
    var totalDreams: Int
    var favoriteCapsules: Int
    var nextUnlockDate: Date?
    var capsulesByType: [TimeCapsuleType: Int]
    var capsulesReadyToUnlock: Int
    
    init(
        totalCapsules: Int = 0,
        lockedCapsules: Int = 0,
        unlockedCapsules: Int = 0,
        expiredCapsules: Int = 0,
        totalDreams: Int = 0,
        favoriteCapsules: Int = 0,
        nextUnlockDate: Date? = nil,
        capsulesByType: [TimeCapsuleType: Int] = [:],
        capsulesReadyToUnlock: Int = 0
    ) {
        self.totalCapsules = totalCapsules
        self.lockedCapsules = lockedCapsules
        self.unlockedCapsules = unlockedCapsules
        self.expiredCapsules = expiredCapsules
        self.totalDreams = totalDreams
        self.favoriteCapsules = favoriteCapsules
        self.nextUnlockDate = nextUnlockDate
        self.capsulesByType = capsulesByType
        self.capsulesReadyToUnlock = capsulesReadyToUnlock
    }
    
    var unlockRate: Double {
        guard totalCapsules > 0 else { return 0 }
        return Double(unlockedCapsules) / Double(totalCapsules)
    }
}

// MARK: - 时间胶囊创建配置

struct TimeCapsuleConfig {
    var title: String
    var message: String
    var capsuleType: TimeCapsuleType
    var selectedDreamIds: [String]
    var unlockDate: Date
    var notifyOnUnlock: Bool
    var shareWithFriendId: String?
    var shareMessage: String?
    var tags: [String]
    
    init(
        title: String = "",
        message: String = "",
        capsuleType: TimeCapsuleType = .personal,
        selectedDreamIds: [String] = [],
        unlockDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60), // 默认 7 天后
        notifyOnUnlock: Bool = true,
        shareWithFriendId: String? = nil,
        shareMessage: String? = nil,
        tags: [String] = []
    ) {
        self.title = title
        self.message = message
        self.capsuleType = capsuleType
        self.selectedDreamIds = selectedDreamIds
        self.unlockDate = unlockDate
        self.notifyOnUnlock = notifyOnUnlock
        self.shareWithFriendId = shareWithFriendId
        self.shareMessage = shareMessage
        self.tags = tags
    }
    
    var isValid: Bool {
        !title.isEmpty && !selectedDreamIds.isEmpty && unlockDate > Date()
    }
    
    var minimumUnlockDate: Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }
}

// MARK: - 时间胶囊预览数据

struct TimeCapsulePreview {
    var id: UUID
    var title: String
    var capsuleType: TimeCapsuleType
    var status: TimeCapsuleStatus
    var unlockDate: Date
    var dreamCount: Int
    var isFavorite: Bool
    var daysUntilUnlock: Int
    
    init(from capsule: DreamTimeCapsule) {
        self.id = capsule.id
        self.title = capsule.title
        self.capsuleType = capsule.typedCapsuleType
        self.status = capsule.typedStatus
        self.unlockDate = capsule.unlockDate
        self.dreamCount = capsule.dreamCount
        self.isFavorite = capsule.isFavorite
        self.daysUntilUnlock = capsule.daysUntilUnlock
    }
}
