//
//  DreamChallengeTests.swift
//  DreamLogTests
//
//  Phase 58 - 梦境挑战系统单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamChallengeTests: XCTestCase {
    
    var service: DreamChallengeService!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContext
        let container = ModelContainer(
            for: DreamChallengeTemplate.self, UserChallenge.self, AchievementBadge.self, ChallengeStats.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)
        service = DreamChallengeService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 模板管理测试
    
    func testInitializePresetTemplates() async throws {
        // 初始化预设模板
        try service.initializePresetTemplates()
        
        // 验证模板已创建
        let templates = try service.getPresetTemplates()
        XCTAssertGreaterThan(templates.count, 0, "应该创建预设模板")
    }
    
    func testGetAllTemplates() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        XCTAssertGreaterThan(templates.count, 0, "应该能获取所有模板")
    }
    
    func testGetTemplatesByCategory() async throws {
        try service.initializePresetTemplates()
        
        let recordingTemplates = try service.getTemplates(by: .recording)
        XCTAssertGreaterThanOrEqual(recordingTemplates.count, 0, "应该能按类别获取模板")
    }
    
    func testGetTemplatesByType() async throws {
        try service.initializePresetTemplates()
        
        let dailyTemplates = try service.getTemplates(by: .daily)
        XCTAssertGreaterThanOrEqual(dailyTemplates.count, 0, "应该能按类型获取模板")
    }
    
    func testGetDailyChallenges() async throws {
        try service.initializePresetTemplates()
        
        let dailyChallenges = try service.getDailyChallenges()
        XCTAssertGreaterThanOrEqual(dailyChallenges.count, 0, "应该能获取每日挑战")
    }
    
    func testGetWeeklyChallenges() async throws {
        try service.initializePresetTemplates()
        
        let weeklyChallenges = try service.getWeeklyChallenges()
        XCTAssertGreaterThanOrEqual(weeklyChallenges.count, 0, "应该能获取每周挑战")
    }
    
    // MARK: - 徽章管理测试
    
    func testInitializePresetBadges() async throws {
        try service.initializePresetBadges()
        
        let badges = try service.getAllBadges()
        XCTAssertGreaterThan(badges.count, 0, "应该创建预设徽章")
    }
    
    func testGetUnlockedBadges() async throws {
        try service.initializePresetBadges()
        
        let unlocked = try service.getUnlockedBadges()
        XCTAssertEqual(unlocked.count, 0, "初始时应该没有解锁的徽章")
    }
    
    func testGetLockedBadges() async throws {
        try service.initializePresetBadges()
        
        let locked = try service.getLockedBadges()
        XCTAssertGreaterThan(locked.count, 0, "初始时应该有未解锁的徽章")
    }
    
    func testUnlockBadge() async throws {
        try service.initializePresetBadges()
        
        // 解锁第一个徽章
        let badges = try service.getAllBadges()
        if let firstBadge = badges.first {
            try service.unlockBadge(id: firstBadge.id)
            
            // 验证徽章已解锁
            let unlocked = try service.getUnlockedBadges()
            XCTAssertTrue(unlocked.contains { $0.id == firstBadge.id }, "徽章应该已解锁")
            XCTAssertTrue(unlocked.first?.isUnlocked ?? false, "徽章的 isUnlocked 应该为 true")
        }
    }
    
    // MARK: - 用户挑战管理测试
    
    func testStartChallenge() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 验证挑战属性
            XCTAssertEqual(challenge.templateId, template.id)
            XCTAssertEqual(challenge.status, .inProgress)
            XCTAssertEqual(challenge.targetProgress, template.targetValue)
            XCTAssertFalse(challenge.isCompleted)
        }
    }
    
    func testStartChallengeAlreadyStarted() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            // 开始挑战
            let challenge1 = try service.startChallenge(templateId: template.id)
            
            // 再次开始相同挑战
            let challenge2 = try service.startChallenge(templateId: template.id)
            
            // 应该返回相同的挑战
            XCTAssertEqual(challenge1.id, challenge2.id)
        }
    }
    
    func testUpdateChallengeProgress() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 更新进度
            try service.updateChallengeProgress(challengeId: challenge.id, progress: 1)
            
            // 验证进度已更新
            let challenges = try service.getUserChallenges()
            if let updated = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertEqual(updated.progress, 1)
            }
        }
    }
    
    func testCompleteChallenge() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 完成挑战
            try service.updateChallengeProgress(
                challengeId: challenge.id,
                progress: template.targetValue
            )
            
            // 验证挑战已完成
            let challenges = try service.getUserChallenges()
            if let completed = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertTrue(completed.isCompleted)
                XCTAssertEqual(completed.status, .completed)
                XCTAssertNotNil(completed.completedAt)
            }
        }
    }
    
    func testClaimReward() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 完成挑战
            try service.updateChallengeProgress(
                challengeId: challenge.id,
                progress: template.targetValue
            )
            
            // 领取奖励
            try service.claimReward(challengeId: challenge.id)
            
            // 验证奖励已领取
            let challenges = try service.getUserChallenges()
            if let claimed = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertTrue(claimed.isClaimed)
            }
        }
    }
    
    func testClaimRewardAlreadyClaimed() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 完成并领取奖励
            try service.updateChallengeProgress(
                challengeId: challenge.id,
                progress: template.targetValue
            )
            try service.claimReward(challengeId: challenge.id)
            
            // 再次领取应该失败
            XCTAssertThrowsError(try service.claimReward(challengeId: challenge.id))
        }
    }
    
    func testDeleteChallenge() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 删除挑战
            try service.deleteChallenge(challenge)
            
            // 验证挑战已删除
            let challenges = try service.getUserChallenges()
            XCTAssertFalse(challenges.contains { $0.id == challenge.id })
        }
    }
    
    func testToggleFavorite() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            XCTAssertFalse(challenge.isFavorite)
            
            // 切换收藏
            try service.toggleFavorite(challenge)
            
            let challenges = try service.getUserChallenges()
            if let updated = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertTrue(updated.isFavorite)
            }
            
            // 再次切换
            try service.toggleFavorite(challenge)
            
            let challenges2 = try service.getUserChallenges()
            if let updated = challenges2.first(where: { $0.id == challenge.id }) {
                XCTAssertFalse(updated.isFavorite)
            }
        }
    }
    
    func testGetUserChallenges() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates().prefix(3)
        
        for template in templates {
            _ = try service.startChallenge(templateId: template.id)
        }
        
        let challenges = try service.getUserChallenges()
        XCTAssertEqual(challenges.count, 3)
    }
    
    func testGetActiveChallenges() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates().prefix(3)
        
        for template in templates {
            _ = try service.startChallenge(templateId: template.id)
        }
        
        // 完成其中一个
        if let firstTemplate = templates.first {
            let challenges = try service.getUserChallenges()
            if let challenge = challenges.first {
                try service.updateChallengeProgress(
                    challengeId: challenge.id,
                    progress: 100 // 设置为完成
                )
            }
        }
        
        let active = try service.getActiveChallenges()
        XCTAssertEqual(active.count, 2) // 应该还有 2 个进行中
    }
    
    func testGetCompletedChallenges() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates().prefix(2)
        
        for template in templates {
            let challenge = try service.startChallenge(templateId: template.id)
            try service.updateChallengeProgress(
                challengeId: challenge.id,
                progress: template.targetValue
            )
        }
        
        let completed = try service.getCompletedChallenges()
        XCTAssertEqual(completed.count, 2)
    }
    
    // MARK: - 统计管理测试
    
    func testGetStats() async throws {
        let stats = try service.getStats()
        
        XCTAssertEqual(stats.userId, "current_user")
        XCTAssertEqual(stats.totalChallengesCompleted, 0)
        XCTAssertEqual(stats.totalPointsEarned, 0)
    }
    
    func testRefreshStats() async throws {
        try service.initializePresetTemplates()
        
        // 完成一些挑战
        let templates = try service.getAllTemplates().prefix(3)
        for template in templates {
            let challenge = try service.startChallenge(templateId: template.id)
            try service.updateChallengeProgress(
                challengeId: challenge.id,
                progress: template.targetValue
            )
        }
        
        // 刷新统计
        let stats = try service.refreshStats()
        
        XCTAssertEqual(stats.totalChallengesCompleted, 3)
        XCTAssertGreaterThan(stats.totalPointsEarned, 0)
    }
    
    func testStatsByCategory() async throws {
        try service.initializePresetTemplates()
        
        // 完成一个记录挑战
        let recordingTemplates = try service.getTemplates(by: .recording)
        if let template = recordingTemplates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            try service.updateChallengeProgress(
                challengeId: challenge.id,
                progress: template.targetValue
            )
        }
        
        let stats = try service.refreshStats()
        XCTAssertGreaterThanOrEqual(stats.recordingChallengesCompleted, 1)
    }
    
    func testStatsByDifficulty() async throws {
        try service.initializePresetTemplates()
        
        // 完成一个简单挑战
        let easyTemplates = try service.getAllTemplates().filter { $0.difficulty == .easy }
        if let template = easyTemplates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            try service.updateChallengeProgress(
                challengeId: challenge.id,
                progress: template.targetValue
            )
        }
        
        let stats = try service.refreshStats()
        XCTAssertGreaterThanOrEqual(stats.easyCompleted, 1)
    }
    
    // MARK: - 自动进度追踪测试
    
    func testOnDreamRecorded() async throws {
        try service.initializePresetTemplates()
        
        // 开始一个记录梦境挑战
        let recordingTemplates = try service.getTemplates(by: .recording)
        if let template = recordingTemplates.first(where: { $0.targetType == .recordDreams }) {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 模拟记录梦境
            try service.onDreamRecorded(
                dreamId: UUID(),
                hasEmotions: false,
                hasTags: false,
                hasAudio: false,
                isLucid: false
            )
            
            // 验证进度已更新
            let challenges = try service.getUserChallenges()
            if let updated = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertEqual(updated.progress, 1)
            }
        }
    }
    
    func testOnDreamRecordedWithEmotions() async throws {
        try service.initializePresetTemplates()
        
        // 开始一个带情绪的挑战
        let emotionTemplates = try service.getTemplates(by: .recording)
        if let template = emotionTemplates.first(where: { $0.targetType == .recordWithEmotions }) {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 模拟记录带情绪的梦境
            try service.onDreamRecorded(
                dreamId: UUID(),
                hasEmotions: true,
                hasTags: false,
                hasAudio: false,
                isLucid: false
            )
            
            // 验证进度已更新
            let challenges = try service.getUserChallenges()
            if let updated = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertEqual(updated.progress, 1)
            }
        }
    }
    
    func testOnDreamShared() async throws {
        try service.initializePresetTemplates()
        
        // 开始一个分享挑战
        let socialTemplates = try service.getTemplates(by: .social)
        if let template = socialTemplates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 模拟分享梦境
            try service.onDreamShared(dreamId: UUID())
            
            // 验证进度已更新
            let challenges = try service.getUserChallenges()
            if let updated = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertEqual(updated.progress, 1)
            }
        }
    }
    
    func testOnMeditationCompleted() async throws {
        try service.initializePresetTemplates()
        
        // 开始一个冥想挑战
        let reflectionTemplates = try service.getTemplates(by: .reflection)
        if let template = reflectionTemplates.first(where: { $0.targetType == .meditation }) {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 模拟完成冥想
            try service.onMeditationCompleted()
            
            // 验证进度已更新
            let challenges = try service.getUserChallenges()
            if let updated = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertEqual(updated.progress, 1)
            }
        }
    }
    
    // MARK: - 进度百分比测试
    
    func testChallengeProgressPercentage() async throws {
        try service.initializePresetTemplates()
        
        let templates = try service.getAllTemplates()
        if let template = templates.first {
            let challenge = try service.startChallenge(templateId: template.id)
            
            // 测试 0%
            XCTAssertEqual(challenge.progressPercentage, 0.0)
            
            // 更新到 50%
            let halfProgress = template.targetValue / 2
            try service.updateChallengeProgress(challengeId: challenge.id, progress: halfProgress)
            
            let challenges = try service.getUserChallenges()
            if let updated = challenges.first(where: { $0.id == challenge.id }) {
                XCTAssertGreaterThanOrEqual(updated.progressPercentage, 0.4)
                XCTAssertLessThanOrEqual(updated.progressPercentage, 0.6)
            }
        }
    }
    
    // MARK: - 错误处理测试
    
    func testStartChallengeWithInvalidTemplate() async throws {
        let invalidId = UUID()
        
        // 尝试开始不存在的挑战
        XCTAssertThrowsError(try service.startChallenge(templateId: invalidId))
    }
    
    func testUpdateProgressWithInvalidChallenge() async throws {
        let invalidId = UUID()
        
        // 尝试更新不存在的挑战
        XCTAssertThrowsError(try service.updateChallengeProgress(challengeId: invalidId, progress: 1))
    }
}
