//
//  DreamWidgetTests.swift
//  DreamLogTests
//
//  iOS 小组件单元测试 - Phase 33
//

import XCTest
@testable import DreamLog

// MARK: - 小组件模型测试

final class DreamWidgetModelsTests: XCTestCase {
    
    // MARK: - DreamWidgetKind 测试
    
    func testWidgetKindAllCases() {
        // 验证所有小组件类型
        XCTAssertEqual(DreamWidgetKind.allCases.count, 7)
        
        let expectedKinds: [DreamWidgetKind] = [
            .quickRecord, .dailyStats, .dreamQuote,
            .moodTracker, .tagFilter, .recentDreams, .streakCounter
        ]
        
        for kind in expectedKinds {
            XCTAssertTrue(DreamWidgetKind.allCases.contains(kind))
        }
    }
    
    func testWidgetKindDisplayName() {
        XCTAssertEqual(DreamWidgetKind.quickRecord.displayName, "快速记录")
        XCTAssertEqual(DreamWidgetKind.dailyStats.displayName, "今日统计")
        XCTAssertEqual(DreamWidgetKind.dreamQuote.displayName, "梦境名言")
        XCTAssertEqual(DreamWidgetKind.moodTracker.displayName, "情绪追踪")
        XCTAssertEqual(DreamWidgetKind.tagFilter.displayName, "标签筛选")
        XCTAssertEqual(DreamWidgetKind.recentDreams.displayName, "最近梦境")
        XCTAssertEqual(DreamWidgetKind.streakCounter.displayName, "连续记录")
    }
    
    func testWidgetKindIcon() {
        XCTAssertEqual(DreamWidgetKind.quickRecord.icon, "🎤")
        XCTAssertEqual(DreamWidgetKind.dailyStats.icon, "📊")
        XCTAssertEqual(DreamWidgetKind.dreamQuote.icon, "💭")
        XCTAssertEqual(DreamWidgetKind.moodTracker.icon, "😊")
        XCTAssertEqual(DreamWidgetKind.tagFilter.icon, "🏷️")
        XCTAssertEqual(DreamWidgetKind.recentDreams.icon, "🌙")
        XCTAssertEqual(DreamWidgetKind.streakCounter.icon, "🔥")
    }
    
    func testWidgetKindSupportedFamilies() {
        // 快速记录支持小尺寸和锁屏
        XCTAssertTrue(DreamWidgetKind.quickRecord.supportedFamilies.contains(.systemSmall))
        XCTAssertTrue(DreamWidgetKind.quickRecord.supportedFamilies.contains(.accessoryCircular))
        
        // 标签筛选支持中大尺寸
        XCTAssertTrue(DreamWidgetKind.tagFilter.supportedFamilies.contains(.systemMedium))
        XCTAssertTrue(DreamWidgetKind.tagFilter.supportedFamilies.contains(.systemLarge))
    }
    
    // MARK: - WidgetTheme 测试
    
    func testWidgetThemeAllThemes() {
        // 验证 8 种主题
        XCTAssertEqual(WidgetTheme.allThemes.count, 8)
        
        let themeNames = WidgetTheme.allThemes.map { $0.name }
        let expectedNames = ["星空紫", "日落橙", "森林绿", "海洋蓝", "午夜黑", "玫瑰粉", "奢华金", "薰衣草"]
        
        for name in expectedNames {
            XCTAssertTrue(themeNames.contains(name))
        }
    }
    
    func testWidgetThemeDefault() {
        let defaultTheme = WidgetTheme.default
        XCTAssertEqual(defaultTheme.name, "星空紫")
        XCTAssertTrue(defaultTheme.isDark)
    }
    
    func testWidgetThemeProperties() {
        let theme = WidgetTheme.allThemes[0]
        
        XCTAssertNotNil(theme.id)
        XCTAssertFalse(theme.name.isEmpty)
        XCTAssertFalse(theme.nameKey.isEmpty)
        XCTAssertFalse(theme.backgroundColor.isEmpty)
        XCTAssertFalse(theme.textColor.isEmpty)
        XCTAssertFalse(theme.accentColor.isEmpty)
        XCTAssertFalse(theme.gradientStart.isEmpty)
        XCTAssertFalse(theme.gradientEnd.isEmpty)
    }
    
    func testWidgetThemeCodable() throws {
        let theme = WidgetTheme.allThemes[0]
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(theme)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedTheme = try decoder.decode(WidgetTheme.self, from: data)
        
        XCTAssertEqual(theme.id, decodedTheme.id)
        XCTAssertEqual(theme.name, decodedTheme.name)
        XCTAssertEqual(theme.backgroundColor, decodedTheme.backgroundColor)
        XCTAssertEqual(theme.isDark, decodedTheme.isDark)
    }
    
    // MARK: - WidgetLayout 测试
    
    func testWidgetLayoutDefault() {
        let defaultLayout = WidgetLayout.default
        
        XCTAssertTrue(defaultLayout.showTitle)
        XCTAssertTrue(defaultLayout.showIcon)
        XCTAssertTrue(defaultLayout.showDate)
        XCTAssertTrue(defaultLayout.showStats)
        XCTAssertEqual(defaultLayout.fontSize, .medium)
        XCTAssertEqual(defaultLayout.cornerRadius, 16)
        XCTAssertEqual(defaultLayout.padding, 12)
    }
    
    func testWidgetLayoutCodable() throws {
        let layout = WidgetLayout(
            showTitle: false,
            showIcon: true,
            showDate: false,
            showStats: true,
            fontSize: .large,
            cornerRadius: 20,
            padding: 16
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(layout)
        
        let decoder = JSONDecoder()
        let decodedLayout = try decoder.decode(WidgetLayout.self, from: data)
        
        XCTAssertEqual(layout.showTitle, decodedLayout.showTitle)
        XCTAssertEqual(layout.showIcon, decodedLayout.showIcon)
        XCTAssertEqual(layout.fontSize, decodedLayout.fontSize)
        XCTAssertEqual(layout.cornerRadius, decodedLayout.cornerRadius)
    }
    
    // MARK: - DreamStats 测试
    
    func testDreamStatsEmpty() {
        let empty = DreamStats.empty
        
        XCTAssertEqual(empty.todayCount, 0)
        XCTAssertEqual(empty.weekCount, 0)
        XCTAssertEqual(empty.monthCount, 0)
        XCTAssertEqual(empty.totalCount, 0)
        XCTAssertEqual(empty.streakDays, 0)
        XCTAssertEqual(empty.longestStreak, 0)
        XCTAssertEqual(empty.averageClarity, 0)
        XCTAssertTrue(empty.commonEmotions.isEmpty)
        XCTAssertTrue(empty.commonTags.isEmpty)
    }
    
    // MARK: - StreakData 测试
    
    func testStreakDataEmpty() {
        let empty = StreakData.empty
        
        XCTAssertEqual(empty.currentStreak, 0)
        XCTAssertEqual(empty.longestStreak, 0)
        XCTAssertNil(empty.lastRecordDate)
        XCTAssertEqual(empty.nextMilestone, 7)
        XCTAssertEqual(empty.weeklyGoal, 7)
        XCTAssertEqual(empty.weeklyProgress, 0)
    }
    
    // MARK: - QuickRecordEntry 测试
    
    func testQuickRecordEntryEmpty() {
        let empty = QuickRecordEntry.empty
        
        XCTAssertFalse(empty.isRecording)
        XCTAssertNil(empty.lastRecordDate)
        XCTAssertEqual(empty.todayCount, 0)
        XCTAssertEqual(empty.weeklyGoal, 7)
        XCTAssertEqual(empty.progress, 0)
    }
}

// MARK: - 小组件服务测试

final class DreamWidgetServiceTests: XCTestCase {
    
    var service: DreamWidgetService!
    var mockUserDefaults: MockUserDefaults!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        service = DreamWidgetService(userDefaults: mockUserDefaults)
    }
    
    override func tearDown() {
        service = nil
        mockUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - 主题管理测试
    
    func testGetCurrentThemeDefault() {
        let theme = service.getCurrentTheme()
        XCTAssertEqual(theme.name, "星空紫")
    }
    
    func testSetTheme() {
        let newTheme = WidgetTheme.allThemes[1] // 日落橙
        service.setTheme(newTheme)
        
        let savedIndex = mockUserDefaults.integer(forKey: "widget_theme_index")
        XCTAssertEqual(savedIndex, 1)
    }
    
    func testGetCurrentLayoutDefault() {
        let layout = service.getCurrentLayout()
        XCTAssertEqual(layout.fontSize, .medium)
        XCTAssertEqual(layout.cornerRadius, 16)
    }
    
    func testSetLayout() {
        let newLayout = WidgetLayout(
            showTitle: false,
            showIcon: true,
            showDate: false,
            showStats: true,
            fontSize: .large,
            cornerRadius: 20,
            padding: 16
        )
        
        service.setLayout(newLayout)
        
        let savedData = mockUserDefaults.data(forKey: "widget_layout")
        XCTAssertNotNil(savedData)
    }
    
    // MARK: - 统计数据测试
    
    func testGetDreamStatsEmpty() async {
        let stats = await service.getDreamStats()
        
        XCTAssertEqual(stats.todayCount, 0)
        XCTAssertEqual(stats.weekCount, 0)
        XCTAssertEqual(stats.streakDays, 0)
    }
    
    // MARK: - 连续记录计算测试
    
    func testCalculateStreakEmpty() async {
        let streakData = await service.getStreakData()
        XCTAssertEqual(streakData.currentStreak, 0)
        XCTAssertEqual(streakData.longestStreak, 0)
    }
    
    // MARK: - 梦境名言测试
    
    func testGetDreamQuoteEmpty() async {
        let quote = await service.getDreamQuote()
        XCTAssertEqual(quote.content, "记录你的第一个梦境...")
    }
    
    // MARK: - 情绪追踪测试
    
    func testGetMoodTrackingEmpty() async {
        let mood = await service.getMoodTracking()
        XCTAssertNil(mood.currentMood)
        XCTAssertTrue(mood.moodHistory.isEmpty)
        XCTAssertTrue(mood.commonMoods.isEmpty)
    }
    
    // MARK: - 标签筛选测试
    
    func testGetTagFilterDataEmpty() async {
        let tagData = await service.getTagFilterData()
        XCTAssertTrue(tagData.frequentTags.isEmpty)
        XCTAssertTrue(tagData.recentTags.isEmpty)
        XCTAssertEqual(tagData.totalCount, 0)
    }
    
    // MARK: - 最近梦境测试
    
    func testGetRecentDreamsEmpty() async {
        let dreams = await service.getRecentDreams(limit: 5)
        XCTAssertTrue(dreams.dreams.isEmpty)
        XCTAssertFalse(dreams.hasMore)
    }
}

// MARK: - 实时活动属性测试

final class DreamLiveActivitiesTests: XCTestCase {
    
    // MARK: - DreamRecordAttributes 测试
    
    func testDreamRecordAttributesCreation() {
        let attributes = DreamRecordAttributes(
            dreamId: "test-123",
            userName: "Test User"
        )
        
        XCTAssertEqual(attributes.dreamId, "test-123")
        XCTAssertEqual(attributes.userName, "Test User")
    }
    
    func testDreamRecordContentState() {
        let state = DreamRecordAttributes.ContentState(
            reminderType: .bedtime,
            message: "睡前记录时间到！",
            timeRemaining: 1800
        )
        
        XCTAssertEqual(state.reminderType, .bedtime)
        XCTAssertEqual(state.message, "睡前记录时间到！")
        XCTAssertEqual(state.timeRemaining, 1800)
    }
    
    func testReminderTypeRawValues() {
        XCTAssertEqual(DreamRecordAttributes.ContentState.ReminderType.bedtime.rawValue, "bedtime")
        XCTAssertEqual(DreamRecordAttributes.ContentState.ReminderType.morning.rawValue, "morning")
        XCTAssertEqual(DreamRecordAttributes.ContentState.ReminderType.weekly.rawValue, "weekly")
    }
    
    // MARK: - StreakAttributes 测试
    
    func testStreakAttributesCreation() {
        let attributes = StreakAttributes(userId: "user-456")
        XCTAssertEqual(attributes.userId, "user-456")
    }
    
    func testStreakContentState() {
        let state = StreakAttributes.ContentState(
            currentStreak: 7,
            longestStreak: 21,
            weeklyProgress: 5,
            weeklyGoal: 7,
            nextMilestone: 14,
            encouragement: "🔥 连续 7 天！加油！"
        )
        
        XCTAssertEqual(state.currentStreak, 7)
        XCTAssertEqual(state.longestStreak, 21)
        XCTAssertEqual(state.weeklyProgress, 5)
        XCTAssertEqual(state.weeklyGoal, 7)
        XCTAssertEqual(state.nextMilestone, 14)
    }
    
    // MARK: - DreamChallengeAttributes 测试
    
    func testDreamChallengeAttributesCreation() {
        let attributes = DreamChallengeAttributes(challengeId: "challenge-789")
        XCTAssertEqual(attributes.challengeId, "challenge-789")
    }
    
    func testChallengeContentState() {
        let state = DreamChallengeAttributes.ContentState(
            challengeName: "每周记录挑战",
            challengeDescription: "一周内记录 7 个梦境",
            currentProgress: 3,
            targetProgress: 7,
            timeRemaining: 86400,
            reward: "专属徽章",
            isCompleted: false
        )
        
        XCTAssertEqual(state.challengeName, "每周记录挑战")
        XCTAssertEqual(state.currentProgress, 3)
        XCTAssertEqual(state.targetProgress, 7)
        XCTAssertFalse(state.isCompleted)
    }
}

// MARK: - 小组件意图测试

final class WidgetIntentTests: XCTestCase {
    
    func testWidgetIntentAllCases() {
        XCTAssertEqual(WidgetIntent.allCases.count, 8)
        
        let expectedIntents: [WidgetIntent] = [
            .startRecording, .stopRecording, .likeDream,
            .favoriteDream, .filterByTag, .setMood,
            .viewStats, .openApp
        ]
        
        for intent in expectedIntents {
            XCTAssertTrue(WidgetIntent.allCases.contains(intent))
        }
    }
    
    func testWidgetIntentDisplayNames() {
        XCTAssertEqual(WidgetIntent.startRecording.displayName, "开始记录")
        XCTAssertEqual(WidgetIntent.stopRecording.displayName, "停止记录")
        XCTAssertEqual(WidgetIntent.likeDream.displayName, "点赞")
        XCTAssertEqual(WidgetIntent.favoriteDream.displayName, "收藏")
        XCTAssertEqual(WidgetIntent.filterByTag.displayName, "筛选标签")
        XCTAssertEqual(WidgetIntent.setMood.displayName, "设置情绪")
        XCTAssertEqual(WidgetIntent.viewStats.displayName, "查看统计")
        XCTAssertEqual(WidgetIntent.openApp.displayName, "打开应用")
    }
}

// MARK: - Mock UserDefaults

class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]
    
    override func integer(forKey key: String) -> Int {
        return storage[key] as? Int ?? 0
    }
    
    override func set(_ value: Int, forKey key: String) {
        storage[key] = value
    }
    
    override func data(forKey key: String) -> Data? {
        return storage[key] as? Data
    }
    
    override func set(_ value: Data?, forKey key: String) {
        storage[key] = value
    }
    
    override func bool(forKey key: String) -> Bool {
        return storage[key] as? Bool ?? false
    }
    
    override func set(_ value: Bool, forKey key: String) {
        storage[key] = value
    }
    
    override func string(forKey key: String) -> String? {
        return storage[key] as? String
    }
    
    override func set(_ value: String?, forKey key: String) {
        storage[key] = value
    }
    
    override func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
