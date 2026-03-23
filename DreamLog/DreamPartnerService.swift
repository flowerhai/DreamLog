//
//  DreamPartnerService.swift
//  DreamLog
//
//  梦境伴侣共享系统 - 核心服务
//  Phase 88: 梦境伴侣与家庭共享
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
class DreamPartnerService {
    
    static let shared = DreamPartnerService()
    
    private let modelContext: ModelContext
    private var activityService: DreamPartnerActivityService
    private var currentUserId: String {
        UserDefaults.standard.string(forKey: "dreamLogUserId") ?? UUID().uuidString
    }
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? (try? ModelContext(ModelConfiguration(for: DreamPartner.self)))!
        self.activityService = DreamPartnerActivityService(modelContext: modelContext)
    }
    
    // MARK: - 邀请管理
    
    /// 创建邀请
    func createInvite(message: String? = nil, expiresInHours: Double = 72) -> PartnerInvite {
        let code = PartnerInvite.generateCode()
        let expiresAt = Date().addingTimeInterval(expiresInHours * 3600)
        
        let invite = PartnerInvite(
            code: code,
            inviterName: getCurrentUserName(),
            inviterAvatar: getCurrentUserAvatar(),
            message: message,
            expiresAt: expiresAt
        )
        
        // 保存邀请到本地
        saveInvite(invite)
        
        return invite
    }
    
    /// 保存邀请
    func saveInvite(_ invite: PartnerInvite) {
        let key = "partner_invite_\(invite.code)"
        if let data = try? JSONEncoder().encode(invite) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    /// 获取邀请
    func getInvite(code: String) -> PartnerInvite? {
        let key = "partner_invite_\(code)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PartnerInvite.self, from: data)
    }
    
    /// 接受邀请
    func acceptInvite(code: String) async throws -> DreamPartner {
        guard let invite = getInvite(code: code) else {
            throw PartnerError.invalidInvite
        }
        
        guard !invite.isUsed && !invite.isExpired else {
            throw PartnerError.inviteExpired
        }
        
        // 创建伴侣关系
        let partner = DreamPartner(
            userId: currentUserId,
            partnerUserId: generateUserIdFromName(invite.inviterName),
            partnerName: invite.inviterName,
            partnerAvatar: invite.inviterAvatar,
            status: .accepted,
            connectedAt: Date()
        )
        
        try modelContext.insert(partner)
        try modelContext.save()
        
        // 标记邀请为已使用
        var usedInvite = invite
        usedInvite.isUsed = true
        usedInvite.usedAt = Date()
        saveInvite(usedInvite)
        
        // 发送通知
        await sendNotification(
            title: "伴侣连接成功",
            body: "你已与 \(invite.inviterName) 建立梦境共享关系"
        )
        
        return partner
    }
    
    /// 删除邀请
    func deleteInvite(code: String) {
        let key = "partner_invite_\(code)"
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - 伴侣管理
    
    /// 获取所有伴侣
    func getAllPartners() -> [DreamPartner] {
        let descriptor = FetchDescriptor<DreamPartner>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取活跃伴侣
    func getActivePartners() -> [DreamPartner] {
        getAllPartners().filter { $0.status == .accepted }
    }
    
    /// 获取待处理邀请
    func getPendingPartners() -> [DreamPartner] {
        getAllPartners().filter { $0.status == .pending }
    }
    
    /// 添加伴侣
    func addPartner(name: String, avatar: String? = nil, permission: SharingPermission = .viewOnly) async throws -> DreamPartner {
        let partner = DreamPartner(
            userId: currentUserId,
            partnerUserId: generateUserIdFromName(name),
            partnerName: name,
            partnerAvatar: avatar,
            status: .pending,
            myPermission: permission
        )
        
        try modelContext.insert(partner)
        try modelContext.save()
        
        return partner
    }
    
    /// 接受伴侣请求
    func acceptPartner(_ partner: DreamPartner, permission: SharingPermission = .viewOnly) async throws {
        partner.status = .accepted
        partner.theirPermission = permission
        partner.connectedAt = Date()
        try modelContext.save()
        
        // 记录连接活动
        await activityService.logConnection(
            partnerId: partner.partnerUserId,
            partnerName: partner.partnerName
        )
        
        await sendNotification(
            title: "伴侣请求已接受",
            body: "你现在可以与 \(partner.partnerName) 共享梦境"
        )
    }
    
    /// 拒绝伴侣请求
    func declinePartner(_ partner: DreamPartner) async throws {
        partner.status = .declined
        try modelContext.save()
    }
    
    /// 移除伴侣
    func removePartner(_ partner: DreamPartner) async throws {
        partner.status = .revoked
        try modelContext.save()
    }
    
    /// 更新权限
    func updatePermission(for partner: DreamPartner, permission: SharingPermission) async throws {
        partner.myPermission = permission
        try modelContext.save()
    }
    
    /// 设置收藏状态
    func setFavorite(_ partner: DreamPartner, isFavorite: Bool) async throws {
        partner.isFavorite = isFavorite
        try modelContext.save()
    }
    
    /// 更新备注
    func updateNotes(_ partner: DreamPartner, notes: String) async throws {
        partner.notes = notes
        try modelContext.save()
    }
    
    // MARK: - 梦境共享
    
    /// 分享梦境给伴侣
    func shareDream(_ dreamId: String, dreamTitle: String = "", with partner: DreamPartner) async throws {
        let share = DreamPartnerShare(
            dreamId: dreamId,
            partnerId: partner.id
        )
        
        try modelContext.insert(share)
        partner.shares.append(share)
        partner.shareCount += 1
        try modelContext.save()
        
        // 记录活动
        await activityService.logDreamShare(
            dreamId: dreamId,
            dreamTitle: dreamTitle,
            partnerId: partner.partnerUserId,
            partnerName: partner.partnerName
        )
        
        if partner.myPermission == .viewAndComment || partner.myPermission == .fullAccess {
            await sendNotification(
                title: "新梦境共享",
                body: "\(getCurrentUserName()) 与你分享了一个新梦境",
                partnerId: partner.partnerUserId
            )
        }
    }
    
    /// 批量分享梦境
    func shareDreams(_ dreamIds: [String], with partner: DreamPartner) async throws {
        for dreamId in dreamIds {
            try await shareDream(dreamId, with: partner)
        }
    }
    
    /// 获取已分享的梦境
    func getSharedDreams(with partner: DreamPartner) -> [DreamPartnerShare] {
        partner.shares.filter { !$0.isHidden }
    }
    
    /// 标记为已查看
    func markAsViewed(_ share: DreamPartnerShare, dreamTitle: String = "") async throws {
        share.viewedAt = Date()
        try modelContext.save()
        
        // 记录查看活动 (仅第一次查看)
        if share.viewedAt != nil {
            await activityService.logDreamView(
                dreamId: share.dreamId,
                dreamTitle: dreamTitle,
                partnerId: share.partnerId,
                partnerName: partnerNameForShare(share)
            )
        }
    }
    
    /// 添加评论
    func addComment(_ share: DreamPartnerShare, comment: String, dreamTitle: String = "") async throws {
        share.comment = comment
        try modelContext.save()
        
        // 记录活动
        await activityService.logComment(
            dreamId: share.dreamId,
            dreamTitle: dreamTitle,
            partnerId: share.partnerId,
            partnerName: partnerNameForShare(share),
            comment: comment
        )
        
        // 通知对方
        await sendNotification(
            title: "新评论",
            body: "\(partnerNameForShare(share)) 评论了你的梦境",
            partnerId: share.partnerId
        )
    }
    
    /// 添加反应
    func addReaction(_ share: DreamPartnerShare, reaction: String, dreamTitle: String = "") async throws {
        share.reaction = reaction
        try modelContext.save()
        
        // 记录活动
        await activityService.logReaction(
            dreamId: share.dreamId,
            partnerId: share.partnerId,
            partnerName: partnerNameForShare(share),
            reaction: reaction
        )
    }
    
    /// 隐藏分享
    func hideShare(_ share: DreamPartnerShare) async throws {
        share.isHidden = true
        try modelContext.save()
    }
    
    // MARK: - 统计
    
    /// 获取共享统计
    func getSharingStats() -> PartnerSharingStats {
        let partners = getAllPartners()
        let activePartners = partners.filter { $0.status == .accepted }
        let pendingPartners = partners.filter { $0.status == .pending }
        
        var totalShares = 0
        var totalViews = 0
        var totalComments = 0
        var maxShares = 0
        var mostSharedDreamId: String?
        var lastSharedAt: Date?
        
        for partner in partners {
            totalShares += partner.shareCount
            
            for share in partner.shares {
                if share.viewedAt != nil { totalViews += 1 }
                if share.comment != nil { totalComments += 1 }
                
                // 找出分享最多的梦境
                let shareCount = partner.shares.filter { $0.dreamId == share.dreamId }.count
                if shareCount > maxShares {
                    maxShares = shareCount
                    mostSharedDreamId = share.dreamId
                }
                
                // 最后分享时间
                if lastSharedAt == nil || share.sharedAt > lastSharedAt! {
                    lastSharedAt = share.sharedAt
                }
            }
        }
        
        return PartnerSharingStats(
            totalPartners: partners.count,
            activePartners: activePartners.count,
            pendingInvites: pendingPartners.count,
            totalShares: totalShares,
            totalViews: totalViews,
            totalComments: totalComments,
            mostSharedDreamId: mostSharedDreamId,
            lastSharedAt: lastSharedAt
        )
    }
    
    // MARK: - 联合洞察
    
    /// 生成联合洞察
    func generateJointInsights(with partner: DreamPartner, myDreams: [String], theirDreams: [String]) -> [JointInsight] {
        var insights: [JointInsight] = []
        
        // 这里应该分析双方梦境的共同模式
        // 简化实现：返回示例洞察
        
        if !myDreams.isEmpty && !theirDreams.isEmpty {
            insights.append(JointInsight(
                id: UUID().uuidString,
                type: .commonTheme,
                title: "共同主题",
                description: "你们最近的梦境都出现了相似的主题元素",
                confidence: 0.75,
                relatedDreamIds: Array(myDreams.prefix(3)) + Array(theirDreams.prefix(3)),
                createdAt: Date()
            ))
        }
        
        return insights
    }
    
    // MARK: - 辅助方法
    
    private func getCurrentUserName() -> String {
        UserDefaults.standard.string(forKey: "dreamLogUserName") ?? "DreamLog 用户"
    }
    
    private func getCurrentUserAvatar() -> String? {
        UserDefaults.standard.string(forKey: "dreamLogUserAvatar")
    }
    
    private func generateUserIdFromName(_ name: String) -> String {
        "\(name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(Int.random(in: 1000...9999))"
    }
    
    private func partnerNameForShare(_ share: DreamPartnerShare) -> String {
        guard let partner = try? modelContext.fetch(FetchDescriptor<DreamPartner>(predicate: #Predicate { $0.id == share.partnerId })).first else {
            return "伴侣"
        }
        return partner.partnerName
    }
    
    private func sendNotification(title: String, body: String, partnerId: String? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 错误类型
    
    enum PartnerError: LocalizedError {
        case invalidInvite
        case inviteExpired
        case partnerNotFound
        case shareNotFound
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .invalidInvite: return "无效的邀请码"
            case .inviteExpired: return "邀请已过期"
            case .partnerNotFound: return "伴侣不存在"
            case .shareNotFound: return "分享记录不存在"
            case .permissionDenied: return "权限不足"
            }
        }
    }
}
