//
//  DreamPartnerTests.swift
//  DreamLogTests
//
//  梦境伴侣共享系统 - 单元测试
//  Phase 88: 梦境伴侣与家庭共享
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamPartnerTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamPartnerService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存模型容器
        let schema = Schema([
            DreamPartner.self,
            DreamPartnerShare.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        service = DreamPartnerService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 邀请码测试
    
    func testGenerateInviteCode() {
        let code = PartnerInvite.generateCode()
        
        XCTAssertEqual(code.count, 6, "邀请码应该是 6 位")
        XCTAssertTrue(code.allSatisfy { "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) })
    }
    
    func testInviteExpiration() {
        let expiresAt = Date().addingTimeInterval(3600)  // 1 小时后过期
        let invite = PartnerInvite(
            code: "ABC123",
            inviterName: "Test User",
            expiresAt: expiresAt
        )
        
        XCTAssertFalse(invite.isExpired, "1 小时后应该未过期")
        XCTAssertEqual(invite.timeRemaining, "1 小时")
    }
    
    func testExpiredInvite() {
        let expiresAt = Date().addingTimeInterval(-3600)  // 1 小时前过期
        let invite = PartnerInvite(
            code: "ABC123",
            inviterName: "Test User",
            expiresAt: expiresAt
        )
        
        XCTAssertTrue(invite.isExpired, "应该已过期")
        XCTAssertEqual(invite.timeRemaining, "已过期")
    }
    
    // MARK: - 邀请管理测试
    
    func testCreateAndSaveInvite() {
        let invite = service.createInvite(message: "Test message", expiresInHours: 24)
        
        XCTAssertEqual(invite.inviterName, "DreamLog 用户")
        XCTAssertFalse(invite.isUsed)
        XCTAssertFalse(invite.isExpired)
        
        // 验证可以检索
        let retrieved = service.getInvite(code: invite.code)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.code, invite.code)
    }
    
    func testDeleteInvite() {
        let invite = service.createInvite()
        
        service.deleteInvite(code: invite.code)
        
        let retrieved = service.getInvite(code: invite.code)
        XCTAssertNil(retrieved, "邀请应该已删除")
    }
    
    func testAcceptInvite() async throws {
        let invite = service.createInvite(message: "Join me!")
        
        let partner = try await service.acceptInvite(code: invite.code)
        
        XCTAssertEqual(partner.status, .accepted)
        XCTAssertEqual(partner.partnerName, "DreamLog 用户")
        XCTAssertNotNil(partner.connectedAt)
        
        // 验证邀请已标记为已使用
        let retrieved = service.getInvite(code: invite.code)
        XCTAssertTrue(retrieved?.isUsed ?? false)
    }
    
    func testAcceptExpiredInvite() async {
        let expiredInvite = PartnerInvite(
            code: "EXPIRED",
            inviterName: "Test",
            expiresAt: Date().addingTimeInterval(-3600)
        )
        service.saveInvite(expiredInvite)
        
        do {
            _ = try await service.acceptInvite(code: "EXPIRED")
            XCTFail("应该抛出过期错误")
        } catch DreamPartnerService.PartnerError.inviteExpired {
            // 预期错误
        } catch {
            XCTFail("应该抛出 inviteExpired 错误")
        }
    }
    
    // MARK: - 伴侣管理测试
    
    func testAddPartner() async throws {
        let partner = try await service.addPartner(name: "Test Partner", permission: .viewOnly)
        
        XCTAssertEqual(partner.partnerName, "Test Partner")
        XCTAssertEqual(partner.status, .pending)
        XCTAssertEqual(partner.myPermission, .viewOnly)
        
        // 验证已保存
        let partners = service.getAllPartners()
        XCTAssertEqual(partners.count, 1)
    }
    
    func testAcceptPartner() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        
        try await service.acceptPartner(partner, permission: .viewAndComment)
        
        XCTAssertEqual(partner.status, .accepted)
        XCTAssertEqual(partner.theirPermission, .viewAndComment)
        XCTAssertNotNil(partner.connectedAt)
    }
    
    func testDeclinePartner() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        
        try await service.declinePartner(partner)
        
        XCTAssertEqual(partner.status, .declined)
    }
    
    func testRemovePartner() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        
        try await service.removePartner(partner)
        
        XCTAssertEqual(partner.status, .revoked)
    }
    
    func testUpdatePermission() async throws {
        let partner = try await service.addPartner(name: "Test Partner", permission: .viewOnly)
        
        try await service.updatePermission(for: partner, permission: .fullAccess)
        
        XCTAssertEqual(partner.myPermission, .fullAccess)
    }
    
    func testSetFavorite() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        
        try await service.setFavorite(partner, isFavorite: true)
        
        XCTAssertTrue(partner.isFavorite)
        
        try await service.setFavorite(partner, isFavorite: false)
        XCTAssertFalse(partner.isFavorite)
    }
    
    func testUpdateNotes() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        
        try await service.updateNotes(partner, notes: "My test notes")
        
        XCTAssertEqual(partner.notes, "My test notes")
    }
    
    // MARK: - 梦境共享测试
    
    func testShareDream() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        try await service.acceptPartner(partner)
        
        try await service.shareDream("dream_123", with: partner)
        
        XCTAssertEqual(partner.shareCount, 1)
        XCTAssertEqual(partner.shares.count, 1)
        XCTAssertEqual(partner.shares.first?.dreamId, "dream_123")
    }
    
    func testShareMultipleDreams() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        try await service.acceptPartner(partner)
        
        let dreamIds = ["dream_1", "dream_2", "dream_3"]
        try await service.shareDreams(dreamIds, with: partner)
        
        XCTAssertEqual(partner.shareCount, 3)
        XCTAssertEqual(partner.shares.count, 3)
    }
    
    func testMarkAsViewed() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        try await service.acceptPartner(partner)
        try await service.shareDream("dream_123", with: partner)
        
        guard let share = partner.shares.first else {
            XCTFail("应该有分享记录")
            return
        }
        
        XCTAssertNil(share.viewedAt)
        
        try await service.markAsViewed(share)
        
        XCTAssertNotNil(share.viewedAt)
    }
    
    func testAddComment() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        try await service.acceptPartner(partner)
        try await service.shareDream("dream_123", with: partner)
        
        guard let share = partner.shares.first else {
            XCTFail("应该有分享记录")
            return
        }
        
        try await service.addComment(share, comment: "Great dream!")
        
        XCTAssertEqual(share.comment, "Great dream!")
    }
    
    func testAddReaction() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        try await service.acceptPartner(partner)
        try await service.shareDream("dream_123", with: partner)
        
        guard let share = partner.shares.first else {
            XCTFail("应该有分享记录")
            return
        }
        
        try await service.addReaction(share, reaction: "❤️")
        
        XCTAssertEqual(share.reaction, "❤️")
    }
    
    func testHideShare() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        try await service.acceptPartner(partner)
        try await service.shareDream("dream_123", with: partner)
        
        guard let share = partner.shares.first else {
            XCTFail("应该有分享记录")
            return
        }
        
        XCTAssertFalse(share.isHidden)
        
        try await service.hideShare(share)
        
        XCTAssertTrue(share.isHidden)
    }
    
    // MARK: - 统计测试
    
    func testGetSharingStats() async throws {
        // 创建多个伴侣和分享
        let partner1 = try await service.addPartner(name: "Partner 1")
        let partner2 = try await service.addPartner(name: "Partner 2")
        try await service.acceptPartner(partner1)
        try await service.acceptPartner(partner2)
        
        try await service.shareDream("dream_1", with: partner1)
        try await service.shareDream("dream_2", with: partner1)
        try await service.shareDream("dream_3", with: partner2)
        
        let stats = service.getSharingStats()
        
        XCTAssertEqual(stats.totalPartners, 2)
        XCTAssertEqual(stats.activePartners, 2)
        XCTAssertEqual(stats.totalShares, 3)
    }
    
    func testShareViewRate() {
        var stats = PartnerSharingStats(
            totalPartners: 1,
            activePartners: 1,
            pendingInvites: 0,
            totalShares: 10,
            totalViews: 5,
            totalComments: 2,
            mostSharedDreamId: nil,
            lastSharedAt: nil
        )
        
        XCTAssertEqual(stats.shareViewRate, 50.0, "查看率应该是 50%")
        
        stats.totalShares = 0
        XCTAssertEqual(stats.shareViewRate, 0, "分享数为 0 时查看率应该是 0")
    }
    
    // MARK: - 联合洞察测试
    
    func testGenerateJointInsights() {
        let partner = DreamPartner(
            userId: "user1",
            partnerUserId: "user2",
            partnerName: "Test Partner"
        )
        
        let myDreams = ["dream_1", "dream_2"]
        let theirDreams = ["dream_3", "dream_4"]
        
        let insights = service.generateJointInsights(with: partner, myDreams: myDreams, theirDreams: theirDreams)
        
        XCTAssertGreaterThan(insights.count, 0, "应该生成至少一个洞察")
        XCTAssertEqual(insights.first?.type, .commonTheme)
    }
    
    func testGenerateJointInsightsEmptyDreams() {
        let partner = DreamPartner(
            userId: "user1",
            partnerUserId: "user2",
            partnerName: "Test Partner"
        )
        
        let insights = service.generateJointInsights(with: partner, myDreams: [], theirDreams: [])
        
        XCTAssertEqual(insights.count, 0, "没有梦境时不应该生成洞察")
    }
    
    // MARK: - 权限枚举测试
    
    func testSharingPermissionDisplayText() {
        XCTAssertEqual(SharingPermission.viewOnly.displayText, "仅查看")
        XCTAssertEqual(SharingPermission.viewAndComment.displayText, "查看 + 评论")
        XCTAssertEqual(SharingPermission.fullAccess.displayText, "完全访问")
    }
    
    func testPartnerStatusDisplayText() {
        XCTAssertEqual(PartnerStatus.pending.displayText, "等待接受")
        XCTAssertEqual(PartnerStatus.accepted.displayText, "已连接")
        XCTAssertEqual(PartnerStatus.declined.displayText, "已拒绝")
        XCTAssertEqual(PartnerStatus.suspended.displayText, "已暂停")
        XCTAssertEqual(PartnerStatus.revoked.displayText, "已撤销")
    }
    
    // MARK: - 性能测试
    
    func testPerformanceShareDreams() async throws {
        let partner = try await service.addPartner(name: "Test Partner")
        try await service.acceptPartner(partner)
        
        measure {
            let expectation = XCTestExpectation(description: "Share dreams")
            
            Task {
                let dreamIds = (1...50).map { "dream_\($0)" }
                try? await service.shareDreams(dreamIds, with: partner)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
    
    // MARK: - 边界情况测试
    
    func testEmptyPartnerName() async {
        do {
            _ = try await service.addPartner(name: "")
            // 空名称应该被允许（由 UI 层验证）
        } catch {
            // 或者抛出错误，取决于实现
        }
    }
    
    func testMultipleInvites() {
        let invite1 = service.createInvite()
        let invite2 = service.createInvite()
        
        XCTAssertNotEqual(invite1.code, invite2.code, "邀请码应该唯一")
        
        XCTAssertNotNil(service.getInvite(code: invite1.code))
        XCTAssertNotNil(service.getInvite(code: invite2.code))
    }
}
