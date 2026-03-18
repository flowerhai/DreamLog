//
//  DreamCollaborationService.swift
//  DreamLog - 梦境协作解读核心服务
//
//  Phase 67: 梦境协作解读板
//  创建时间：2026-03-18
//

import Foundation
import SwiftData
import Combine

// MARK: - 协作服务主类

@MainActor
class DreamCollaborationService: ObservableObject {
    
    // MARK: - 单例
    
    static let shared = DreamCollaborationService()
    
    // MARK: - Published Properties
    
    @Published var currentSessions: [DreamCollaborationSession] = []
    @Published var activeSession: DreamCollaborationSession?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var notifications: [CollaborationNotification] = []
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private let userId: String = "current_user" // 从用户服务获取（当前为占位实现）
    
    /// 获取当前用户 ID（可注入真实用户服务）
    func getCurrentUserId() -> String {
        // TODO: 集成真实用户服务
        return userId
    }
    
    // MARK: - Initialization
    
    init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSessions()
    }
    
    // MARK: - Session Management
    
    /// 创建新的协作会话
    func createSession(
        dreamId: UUID,
        title: String,
        description: String,
        visibility: CollaborationVisibility = .friends,
        maxParticipants: Int = 10
    ) async throws -> DreamCollaborationSession {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        let currentUserId = getCurrentUserId()
        let session = DreamCollaborationSession(
            dreamId: dreamId,
            title: title,
            description: description,
            createdBy: currentUserId,
            visibility: visibility,
            maxParticipants: maxParticipants
        )
        
        // 添加创建者为参与者
        let owner = CollaborationParticipant(
            sessionId: session.id,
            userId: currentUserId,
            username: "我",
            role: .owner
        )
        session.participants.append(owner)
        session.participantCount = 1
        
        context.insert(session)
        context.insert(owner)
        
        try context.save()
        
        // 刷新列表
        await loadSessions()
        
        return session
    }
    
    /// 加载协作会话列表
    func loadSessions() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<DreamCollaborationSession>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            currentSessions = try context.fetch(descriptor)
        } catch {
            self.error = "加载会话失败：\(error.localizedDescription)"
        }
    }
    
    /// 获取单个会话详情
    func getSession(id: UUID) async -> DreamCollaborationSession? {
        guard let context = modelContext else { return nil }
        
        do {
            let descriptor = FetchDescriptor<DreamCollaborationSession>(
                predicate: #Predicate { $0.id == id }
            )
            return try context.fetch(descriptor).first
        } catch {
            return nil
        }
    }
    
    /// 更新会话
    func updateSession(_ session: DreamCollaborationSession) async throws {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        session.updatedAt = Date()
        try context.save()
        
        await loadSessions()
    }
    
    /// 删除会话
    func deleteSession(_ session: DreamCollaborationSession) async throws {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        context.delete(session)
        try context.save()
        
        await loadSessions()
    }
    
    /// 加入协作会话
    func joinSession(sessionId: UUID, inviteCode: String) async throws -> DreamCollaborationSession {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        guard let session = await getSession(id: sessionId) else {
            throw CollaborationError.sessionNotFound
        }
        
        // 验证邀请码
        guard session.inviteCode == inviteCode else {
            throw CollaborationError.invalidInviteCode
        }
        
        // 检查会话是否有效
        guard session.isValid else {
            throw CollaborationError.sessionInvalid
        }
        
        let currentUserId = getCurrentUserId()
        
        // 检查是否已加入
        let alreadyJoined = session.participants.contains { $0.userId == currentUserId }
        guard !alreadyJoined else {
            throw CollaborationError.alreadyJoined
        }
        
        // 添加参与者
        let participant = CollaborationParticipant(
            sessionId: sessionId,
            userId: currentUserId,
            username: "我"
        )
        session.participants.append(participant)
        session.participantCount += 1
        session.updatedAt = Date()
        
        context.insert(participant)
        try context.save()
        
        // 通知创建者
        await createNotification(
            userId: session.createdBy,
            sessionId: sessionId,
            type: .newParticipant,
            title: "新参与者加入",
            message: "\"我\" 加入了你的协作会话"
        )
        
        await loadSessions()
        
        return session
    }
    
    /// 离开协作会话
    func leaveSession(sessionId: UUID) async throws {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        guard let session = await getSession(id: sessionId) else {
            throw CollaborationError.sessionNotFound
        }
        
        let currentUserId = getCurrentUserId()
        
        // 移除参与者
        if let index = session.participants.firstIndex(where: { $0.userId == currentUserId }) {
            let participant = session.participants[index]
            context.delete(participant)
            session.participants.remove(at: index)
            session.participantCount -= 1
            session.updatedAt = Date()
            
            try context.save()
            await loadSessions()
        }
    }
    
    // MARK: - Interpretation Management
    
    /// 添加解读
    func addInterpretation(
        sessionId: UUID,
        dreamId: UUID,
        content: String,
        type: InterpretationType = .symbolic
    ) async throws -> DreamInterpretation {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        let currentUserId = getCurrentUserId()
        let interpretation = DreamInterpretation(
            sessionId: sessionId,
            dreamId: dreamId,
            authorId: currentUserId,
            authorName: "我",
            content: content,
            type: type
        )
        
        context.insert(interpretation)
        
        // 更新会话统计
        if let session = await getSession(id: sessionId) {
            session.interpretations.append(interpretation)
            session.interpretationCount += 1
            session.updatedAt = Date()
            
            // 通知其他参与者
            for participant in session.participants where participant.userId != currentUserId {
                await createNotification(
                    userId: participant.userId,
                    sessionId: sessionId,
                    type: .newInterpretation,
                    title: "新解读发布",
                    message: "\"我\" 发布了一个新的解读"
                )
            }
        }
        
        try context.save()
        
        return interpretation
    }
    
    /// 投票支持解读
    func voteInterpretation(_ interpretation: DreamInterpretation) async throws {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        let currentUserId = getCurrentUserId()
        
        // 检查是否已投票
        let alreadyVoted = interpretation.votes.contains { $0.voterId == currentUserId }
        guard !alreadyVoted else { return }
        
        let vote = InterpretationVote(
            interpretationId: interpretation.id,
            voterId: currentUserId
        )
        
        interpretation.votes.append(vote)
        interpretation.voteCount += 1
        interpretation.updatedAt = Date()
        
        context.insert(vote)
        try context.save()
        
        // 通知作者
        if interpretation.authorId != currentUserId {
            await createNotification(
                userId: interpretation.authorId,
                sessionId: interpretation.sessionId,
                type: .voteReceived,
                title: "收到投票",
                message: "你的解读获得了新的投票"
            )
        }
    }
    
    /// 采纳最佳解读
    func acceptInterpretation(_ interpretation: DreamInterpretation) async throws {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        let currentUserId = getCurrentUserId()
        
        // 取消之前的采纳
        if let session = await getSession(id: interpretation.sessionId) {
            for existing in session.interpretations {
                existing.isAccepted = false
            }
        }
        
        interpretation.isAccepted = true
        interpretation.updatedAt = Date()
        
        try context.save()
        
        // 通知作者
        if interpretation.authorId != currentUserId {
            await createNotification(
                userId: interpretation.authorId,
                sessionId: interpretation.sessionId,
                type: .interpretationAccepted,
                title: "解读被采纳",
                message: "你的解读被采纳为最佳解读！🏆"
            )
        }
    }
    
    // MARK: - Comment Management
    
    /// 添加评论
    func addComment(
        sessionId: UUID,
        content: String,
        parentId: UUID? = nil
    ) async throws -> CollaborationComment {
        guard let context = modelContext else {
            throw CollaborationError.noModelContext
        }
        
        let currentUserId = getCurrentUserId()
        let comment = CollaborationComment(
            sessionId: sessionId,
            authorId: currentUserId,
            authorName: "我",
            content: content,
            parentId: parentId
        )
        
        context.insert(comment)
        
        if let session = await getSession(id: sessionId) {
            session.comments.append(comment)
            session.updatedAt = Date()
        }
        
        try context.save()
        
        return comment
    }
    
    // MARK: - Notification Management
    
    /// 创建通知
    func createNotification(
        userId: String,
        sessionId: UUID,
        type: CollaborationNotificationType,
        title: String,
        message: String
    ) async {
        guard let context = modelContext else { return }
        
        let notification = CollaborationNotification(
            userId: userId,
            sessionId: sessionId,
            type: type,
            title: title,
            message: message
        )
        
        context.insert(notification)
        try? context.save()
    }
    
    /// 获取未读通知数量
    func getUnreadNotificationCount() async -> Int {
        guard let context = modelContext else { return 0 }
        
        do {
            let descriptor = FetchDescriptor<CollaborationNotification>(
                predicate: #Predicate { $0.userId == userId && !$0.isRead }
            )
            let notifications = try context.fetch(descriptor)
            return notifications.count
        } catch {
            return 0
        }
    }
    
    /// 标记通知为已读
    func markNotificationAsRead(_ notification: CollaborationNotification) async throws {
        guard let context = modelContext else { return }
        
        notification.isRead = true
        try context.save()
    }
    
    /// 标记所有通知为已读
    func markAllNotificationsAsRead() async throws {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<CollaborationNotification>(
                predicate: #Predicate { $0.userId == userId && !$0.isRead }
            )
            let notifications = try context.fetch(descriptor)
            for notification in notifications {
                notification.isRead = true
            }
            try context.save()
        } catch {
            // 忽略错误
        }
    }
    
    // MARK: - Statistics
    
    /// 获取协作统计
    func getStatistics() async -> CollaborationStats {
        guard let context = modelContext else { return CollaborationStats() }
        
        var stats = CollaborationStats()
        
        do {
            // 总会话数
            let sessionDescriptor = FetchDescriptor<DreamCollaborationSession>()
            let sessions = try context.fetch(sessionDescriptor)
            stats.totalSessions = sessions.count
            stats.activeSessions = sessions.filter { $0.status == .active }.count
            
            // 总解读数
            let interpretationDescriptor = FetchDescriptor<DreamInterpretation>()
            let interpretations = try context.fetch(interpretationDescriptor)
            stats.totalInterpretations = interpretations.count
            stats.acceptedInterpretations = interpretations.filter { $0.isAccepted }.count
            
            // 总评论数
            let commentDescriptor = FetchDescriptor<CollaborationComment>()
            let comments = try context.fetch(commentDescriptor)
            stats.totalComments = comments.count
            
            // 总投票数
            let voteDescriptor = FetchDescriptor<InterpretationVote>()
            let votes = try context.fetch(voteDescriptor)
            stats.totalVotes = votes.count
            
            // 平均每会话参与者
            if stats.totalSessions > 0 {
                let totalParticipants = sessions.reduce(0) { $0 + $1.participantCount }
                stats.averageParticipantsPerSession = Double(totalParticipants) / Double(stats.totalSessions)
            }
            
            // 最活跃的解读类型
            let typeCounts = Dictionary(grouping: interpretations, by: { $0.type })
                .mapValues { $0.count }
            stats.mostActiveType = typeCounts.max(by: { $0.value < $1.value })?.key
            
        } catch {
            // 忽略错误
        }
        
        return stats
    }
    
    // MARK: - Search & Filter
    
    /// 搜索协作会话
    func searchSessions(query: String, filter: CollaborationFilterOptions) async -> [DreamCollaborationSession] {
        guard let context = modelContext else { return [] }
        
        do {
            var descriptor = FetchDescriptor<DreamCollaborationSession>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            // 应用筛选
            var predicates: [Predicate<DreamCollaborationSession>] = []
            
            if let status = filter.status {
                predicates.append(#Predicate { $0.status == status })
            }
            
            if let visibility = filter.visibility {
                predicates.append(#Predicate { $0.visibility == visibility })
            }
            
            if filter.showOnlyJoined {
                predicates.append(#Predicate { $0.participants.contains { $0.userId == userId } })
            }
            
            if !query.isEmpty {
                predicates.append(#Predicate { $0.title.contains(query) || $0.description.contains(query) })
            }
            
            if !predicates.isEmpty {
                descriptor.predicate = predicates.reduce(#Predicate { true }) { $0 && $1 }
            }
            
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    /// 根据梦境 ID 获取协作会话
    func getSessionsByDreamId(_ dreamId: UUID) async -> [DreamCollaborationSession] {
        guard let context = modelContext else { return [] }
        
        do {
            let descriptor = FetchDescriptor<DreamCollaborationSession>(
                predicate: #Predicate { $0.dreamId == dreamId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    /// 导出会话数据（用于分享或备份）
    func exportSession(_ session: DreamCollaborationSession) async -> [String: Any]? {
        return [
            "id": session.id.uuidString,
            "dreamId": session.dreamId.uuidString,
            "title": session.title,
            "description": session.description,
            "createdAt": session.createdAt.ISO8601Format(),
            "status": session.status.rawValue,
            "visibility": session.visibility.rawValue,
            "participantCount": session.participantCount,
            "interpretationCount": session.interpretationCount,
            "participants": session.participants.map { [
                "username": $0.username,
                "role": $0.role.rawValue,
                "joinedAt": $0.joinedAt.ISO8601Format()
            ]},
            "interpretations": session.interpretations.map { [
                "id": $0.id.uuidString,
                "authorName": $0.authorName,
                "content": $0.content,
                "type": $0.type.rawValue,
                "voteCount": $0.voteCount,
                "isAccepted": $0.isAccepted,
                "createdAt": $0.createdAt.ISO8601Format()
            ]}
        ]
    }
}

// MARK: - Errors

enum CollaborationError: LocalizedError {
    case noModelContext
    case sessionNotFound
    case invalidInviteCode
    case sessionInvalid
    case alreadyJoined
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noModelContext: return "数据库上下文未初始化"
        case .sessionNotFound: return "会话不存在"
        case .invalidInviteCode: return "邀请码错误"
        case .sessionInvalid: return "会话已过期或已满"
        case .alreadyJoined: return "你已加入该会话"
        case .permissionDenied: return "没有权限执行此操作"
        }
    }
}
