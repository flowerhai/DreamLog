//
//  DreamShareCircleService.swift
//  DreamLog
//
//  梦境分享圈服务
//  Phase 17: 梦境分享圈功能
//

import Foundation
import Combine
import CloudKit

@MainActor
class DreamShareCircleService: ObservableObject {
    static let shared = DreamShareCircleService()
    
    // MARK: - Published Properties
    
    @Published var circles: [ShareCircle] = []
    @Published var currentCircle: ShareCircle?
    @Published var sharedDreams: [SharedDream] = []
    @Published var invitations: [CircleInvitation] = []
    @Published var activities: [CircleActivity] = []
    @Published var isLoading: Bool = false
    @Published var error: ShareCircleError?
    
    // MARK: - Private Properties
    
    private let userDefaultsKey = "dreamShareCircles"
    private let cloudKitContainer = CKContainer(identifier: "iCloud.com.dreamlog.app")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadCircles()
        setupCloudKitSubscriptions()
    }
    
    // MARK: - 分享圈管理
    
    /// 创建分享圈
    func createCircle(name: String, type: ShareCircleType, description: String? = nil) async throws -> ShareCircle {
        isLoading = true
        defer { isLoading = false }
        
        let owner = CircleMember(
            userId: "current_user",
            userName: "我",
            role: .owner,
            joinedAt: Date()
        )
        
        var circle = ShareCircle(
            name: name,
            type: type,
            description: description,
            owner: owner,
            members: [owner],
            createdAt: Date()
        )
        
        // 生成邀请码
        circle.inviteCode = generateInviteCode()
        
        circles.append(circle)
        currentCircle = circle
        saveCircles()
        
        // 添加到 CloudKit
        try await saveCircleToCloudKit(circle)
        
        return circle
    }
    
    /// 加入分享圈
    func joinCircle(inviteCode: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // 查找匹配的邀请码
        guard let circle = circles.first(where: { $0.inviteCode == inviteCode }) else {
            throw ShareCircleError.invitationInvalid
        }
        
        // 检查是否已是成员
        let currentUserId = "current_user"
        if circle.members.contains(where: { $0.userId == currentUserId }) {
            throw ShareCircleError.alreadyMember
        }
        
        // 添加当前用户为成员
        let newMember = CircleMember(
            userId: currentUserId,
            userName: "我",
            role: .member,
            joinedAt: Date()
        )
        
        if var updatedCircle = circles.first(where: { $0.id == circle.id }) {
            updatedCircle.members.append(newMember)
            
            if let index = circles.firstIndex(where: { $0.id == circle.id }) {
                circles[index] = updatedCircle
            }
            
            currentCircle = updatedCircle
            saveCircles()
            try await saveCircleToCloudKit(updatedCircle)
        }
    }
    
    /// 离开分享圈
    func leaveCircle(circleId: String) async throws {
        guard let index = circles.firstIndex(where: { $0.id == circleId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        var circle = circles[index]
        circle.members.removeAll { $0.userId == "current_user" }
        
        if circle.members.isEmpty {
            // 如果没有成员了，删除分享圈
            circles.remove(at: index)
        } else {
            circles[index] = circle
        }
        
        if currentCircle?.id == circleId {
            currentCircle = circles.first
        }
        
        saveCircles()
        try await deleteCircleFromCloudKit(circleId)
    }
    
    /// 删除分享圈
    func deleteCircle(circleId: String) async throws {
        guard let circle = circles.first(where: { $0.id == circleId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        // 只有圈主可以删除
        guard circle.owner.userId == "current_user" else {
            throw ShareCircleError.insufficientPermissions
        }
        
        circles.removeAll { $0.id == circleId }
        
        if currentCircle?.id == circleId {
            currentCircle = circles.first
        }
        
        saveCircles()
        try await deleteCircleFromCloudKit(circleId)
    }
    
    /// 更新分享圈设置
    func updateCircleSettings(circleId: String, settings: CircleSettings) async throws {
        guard let index = circles.firstIndex(where: { $0.id == circleId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        circles[index].settings = settings
        saveCircles()
        try await saveCircleToCloudKit(circles[index])
    }
    
    /// 邀请成员
    func inviteMember(circleId: String, email: String, message: String? = nil) async throws -> CircleInvitation {
        guard let circle = circles.first(where: { $0.id == circleId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        // 检查权限
        guard let currentUser = circle.members.first(where: { $0.userId == "current_user" }),
              currentUser.role.permissions.canInvite else {
            throw ShareCircleError.insufficientPermissions
        }
        
        let invitation = CircleInvitation(
            circleId: circleId,
            circleName: circle.name,
            circleType: circle.type,
            inviter: currentUser,
            inviteeEmail: email,
            inviteCode: circle.inviteCode ?? generateInviteCode(),
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(7 * 24 * 3600), // 7 天有效期
            message: message
        )
        
        invitations.append(invitation)
        
        // 这里可以集成邮件发送功能
        // try await sendInvitationEmail(invitation)
        
        return invitation
    }
    
    /// 移除成员
    func removeMember(circleId: String, memberId: String) async throws {
        guard let index = circles.firstIndex(where: { $0.id == circleId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        var circle = circles[index]
        
        // 检查权限
        guard let currentUser = circle.members.first(where: { $0.userId == "current_user" }),
              currentUser.role.permissions.canRemoveMembers else {
            throw ShareCircleError.insufficientPermissions
        }
        
        // 不能移除圈主
        guard circle.owner.userId != memberId else {
            throw ShareCircleError.insufficientPermissions
        }
        
        circle.members.removeAll { $0.userId == memberId }
        circles[index] = circle
        saveCircles()
        try await saveCircleToCloudKit(circle)
    }
    
    // MARK: - 梦境分享
    
    /// 分享梦境到分享圈
    func shareDream(_ dream: Dream, to circleId: String) async throws -> SharedDream {
        guard let circle = circles.first(where: { $0.id == circleId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        guard let sharer = circle.members.first(where: { $0.userId == "current_user" }),
              sharer.role.permissions.canShareDreams else {
            throw ShareCircleError.insufficientPermissions
        }
        
        let sharedDream = SharedDream(
            dreamId: dream.id,
            circleId: circleId,
            sharedBy: sharer,
            sharedAt: Date(),
            title: dream.title,
            content: dream.content,
            emotions: dream.emotions,
            tags: dream.tags,
            dreamDate: dream.date,
            isLucid: dream.isLucid,
            clarity: dream.clarity,
            comments: [],
            reactions: []
        )
        
        sharedDreams.insert(sharedDream, at: 0)
        
        // 更新成员分享计数
        if let memberIndex = circle.members.firstIndex(where: { $0.userId == "current_user" }) {
            circle.members[memberIndex].sharedDreamCount += 1
            if let circleIndex = circles.firstIndex(where: { $0.id == circleId }) {
                circles[circleIndex] = circle
            }
            saveCircles()
        }
        
        return sharedDream
    }
    
    /// 取消分享梦境
    func unshareDream(_ sharedDreamId: String) async throws {
        guard let index = sharedDreams.firstIndex(where: { $0.id == sharedDreamId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        sharedDreams.remove(at: index)
    }
    
    // MARK: - 评论功能
    
    /// 添加评论
    func addComment(to sharedDreamId: String, content: String) async throws -> DreamComment {
        guard let sharedDreamIndex = sharedDreams.firstIndex(where: { $0.id == sharedDreamId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        guard let circle = circles.first(where: { $0.id == sharedDreams[sharedDreamIndex].circleId }),
              let commenter = circle.members.first(where: { $0.userId == "current_user" }),
              commenter.role.permissions.canComment else {
            throw ShareCircleError.insufficientPermissions
        }
        
        let comment = DreamComment(
            sharedDreamId: sharedDreamId,
            author: commenter,
            content: content,
            createdAt: Date(),
            reactions: []
        )
        
        sharedDreams[sharedDreamIndex].comments.append(comment)
        
        return comment
    }
    
    /// 删除评论
    func deleteComment(_ commentId: String, from sharedDreamId: String) async throws {
        guard let dreamIndex = sharedDreams.firstIndex(where: { $0.id == sharedDreamId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        sharedDreams[dreamIndex].comments.removeAll { $0.id == commentId }
    }
    
    // MARK: - 表情回应
    
    /// 添加表情回应
    func addReaction(_ type: DreamReaction.ReactionType, to sharedDreamId: String) async throws {
        guard let index = sharedDreams.firstIndex(where: { $0.id == sharedDreamId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        let reaction = DreamReaction(
            type: type,
            userId: "current_user",
            userName: "我",
            createdAt: Date()
        )
        
        // 检查是否已经回应过
        if !sharedDreams[index].reactions.contains(where: { $0.userId == "current_user" }) {
            sharedDreams[index].reactions.append(reaction)
        }
    }
    
    /// 移除表情回应
    func removeReaction(from sharedDreamId: String) async throws {
        guard let index = sharedDreams.firstIndex(where: { $0.id == sharedDreamId }) else {
            throw ShareCircleError.circleNotFound
        }
        
        sharedDreams[index].reactions.removeAll { $0.userId == "current_user" }
    }
    
    // MARK: - 数据持久化
    
    private func loadCircles() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ShareCircle].self, from: data) {
            circles = decoded
            currentCircle = circles.first
        } else {
            // 创建示例数据
            loadMockData()
        }
    }
    
    private func saveCircles() {
        if let encoded = try? JSONEncoder().encode(circles) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadMockData() {
        // 创建示例分享圈
        let closeFriends = ShareCircle.mock(name: "密友圈", type: .closeFriends, memberCount: 4)
        let dreamGroup = ShareCircle.mock(name: "梦境研究小组", type: .dreamGroup, memberCount: 6)
        
        circles = [closeFriends, dreamGroup]
        currentCircle = circles.first
        
        // 创建示例分享的梦境
        if let firstCircle = circles.first {
            let owner = firstCircle.owner
            for _ in 0..<3 {
                sharedDreams.append(SharedDream.mock(circleId: firstCircle.id, sharedBy: owner))
            }
        }
    }
    
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    // MARK: - CloudKit 集成
    
    private func setupCloudKitSubscriptions() {
        // 设置 CloudKit 订阅以接收实时更新
        let subscription = CKQuerySubscription(
            recordType: "ShareCircle",
            predicate: NSPredicate(value: true),
            subscriptionID: "ShareCircleUpdates",
            options: .firesOnRecordCreation
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        cloudKitContainer.publicCloudDatabase.save(subscription) { _, error in
            if let error = error {
                print("CloudKit subscription error: \(error)")
            }
        }
    }
    
    private func saveCircleToCloudKit(_ circle: ShareCircle) async throws {
        // CloudKit 保存逻辑
        // 这里简化处理，实际应用中需要完整的 CloudKit 集成
    }
    
    private func deleteCircleFromCloudKit(_ circleId: String) async throws {
        // CloudKit 删除逻辑
    }
    
    // MARK: - 统计信息
    
    /// 获取分享圈统计信息
    func getCircleStatistics(circleId: String) -> CircleStatistics {
        guard let circle = circles.first(where: { $0.id == circleId }) else {
            return CircleStatistics.empty
        }
        
        let circleDreams = sharedDreams.filter { $0.circleId == circleId }
        
        return CircleStatistics(
            totalMembers: circle.memberCount,
            totalDreams: circleDreams.count,
            totalComments: circleDreams.reduce(0) { $0 + $1.commentCount },
            totalReactions: circleDreams.reduce(0) { $0 + $1.reactionCount },
            mostActiveMember: circle.members.max(by: { $0.sharedDreamCount < $1.sharedDreamCount }),
            averageDreamsPerMember: circle.memberCount > 0 ? Double(circleDreams.count) / Double(circle.memberCount) : 0
        )
    }
}

// MARK: - 统计信息

struct CircleStatistics {
    var totalMembers: Int
    var totalDreams: Int
    var totalComments: Int
    var totalReactions: Int
    var mostActiveMember: CircleMember?
    var averageDreamsPerMember: Double
    
    static let empty = CircleStatistics(
        totalMembers: 0,
        totalDreams: 0,
        totalComments: 0,
        totalReactions: 0,
        mostActiveMember: nil,
        averageDreamsPerMember: 0
    )
}

// MARK: - Dream 扩展

extension Dream {
    /// 转换为分享的梦境
    func toSharedDream(circleId: String, sharedBy: CircleMember) -> SharedDream {
        SharedDream(
            dreamId: id,
            circleId: circleId,
            sharedBy: sharedBy,
            sharedAt: Date(),
            title: title,
            content: content,
            emotions: emotions,
            tags: tags,
            dreamDate: date,
            isLucid: isLucid,
            clarity: clarity,
            comments: [],
            reactions: []
        )
    }
}
