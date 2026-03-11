//
//  DreamWeeklyReportTests.swift
//  DreamLogTests
//
//  梦境周报功能单元测试
//  Phase 18 - 梦境周报功能
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamWeeklyReportTests: XCTestCase {
    
    var service: DreamWeeklyReportService!
    var dreamStore: DreamStore!
    
    override func setUp() async throws {
        try await super.setUp()
        dreamStore = DreamStore.shared
        service = DreamWeeklyReportService(dreamStore: dreamStore)
    }
    
    override func tearDown() async throws {
        service = nil
        dreamStore = nil
        try await super.tearDown()
    }
    
    // MARK: - 模型测试
    
    func testWeeklyReportModelCreation() {
        let report = DreamWeeklyReport(
            weekStartDate: Date(),
            weekEndDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            generatedAt: Date(),
            totalDreams: 10,
            lucidDreams: 3,
            averageClarity: 4.2,
            averageIntensity: 3.5,
            recordingStreak: 7,
            emotionDistribution: ["快乐": 5, "平静": 3, "焦虑": 2],
            dominantEmotion: "快乐",
            moodTrend: .improving,
            topTags: [TagFrequency(tag: "飞行", count: 5, change: 2)],
            emergingThemes: ["冒险"],
            fadingThemes: ["工作"],
            dreamsByTimeOfDay: ["清晨 (5-8 点)": 3, "上午 (8-12 点)": 4],
            dreamsByWeekday: [1: 2, 2: 3],
            mostActiveDay: 2,
            bestRecallHour: 7,
            highlightDreams: [],
            insights: [],
            suggestions: ["继续保持良好的记录习惯"],
            lastWeekComparison: nil
        )
        
        XCTAssertEqual(report.totalDreams, 10)
        XCTAssertEqual(report.lucidDreams, 3)
        XCTAssertEqual(report.averageClarity, 4.2)
        XCTAssertEqual(report.recordingStreak, 7)
        XCTAssertEqual(report.dominantEmotion, "快乐")
        XCTAssertEqual(report.moodTrend, .improving)
    }
    
    func testMoodTrendDisplayValues() {
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.improving.displayName, "情绪改善")
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.stable.displayName, "情绪稳定")
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.declining.displayName, "情绪下降")
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.fluctuating.displayName, "情绪波动")
    }
    
    func testMoodTrendIcons() {
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.improving.icon, "arrow.up.right.circle.fill")
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.stable.icon, "minus.circle.fill")
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.declining.icon, "arrow.down.right.circle.fill")
        XCTAssertEqual(DreamWeeklyReport.MoodTrend.fluctuating.icon, "arrow.left.and.right.circle.fill")
    }
    
    func testHighlightTypeDisplayValues() {
        XCTAssertEqual(DreamHighlight.HighlightType.mostLucid.displayName, "👁️ 最佳清醒梦")
        XCTAssertEqual(DreamHighlight.HighlightType.highestClarity.displayName, "⭐ 最清晰的梦")
        XCTAssertEqual(DreamHighlight.HighlightType.mostEmotional.displayName, "💖 情绪最强烈")
        XCTAssertEqual(DreamHighlight.HighlightType.longest.displayName, "📝 最详细的梦")
    }
    
    func testInsightTypeDisplayValues() {
        XCTAssertEqual(ReportInsight.InsightType.pattern.displayName, "🔍 模式发现")
        XCTAssertEqual(ReportInsight.InsightType.trend.displayName, "📈 趋势分析")
        XCTAssertEqual(ReportInsight.InsightType.achievement.displayName, "🏆 成就认可")
        XCTAssertEqual(ReportInsight.InsightType.suggestion.displayName, "💡 改进建议")
    }
    
    // MARK: - 配置测试
    
    func testDefaultConfig() {
        let config = WeeklyReportConfig.default
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertTrue(config.autoGenerate)
        XCTAssertEqual(config.generateDay, 0)
        XCTAssertEqual(config.generateHour, 20)
        XCTAssertTrue(config.includeSuggestions)
        XCTAssertTrue(config.includeHighlights)
        XCTAssertFalse(config.shareAutomatically)
    }
    
    func testConfigPersistence() {
        var config = WeeklyReportConfig.default
        config.isEnabled = false
        config.generateHour = 18
        config.shareAutomatically = true
        
        service.config = config
        
        let loadedConfig = service.config
        XCTAssertFalse(loadedConfig.isEnabled)
        XCTAssertEqual(loadedConfig.generateHour, 18)
        XCTAssertTrue(loadedConfig.shareAutomatically)
    }
    
    // MARK: - 周对比测试
    
    func testWeekComparisonCalculation() {
        let comparison = WeekComparison(
            dreamsChange: 3,
            dreamsChangePercent: 30.0,
            clarityChange: 0.5,
            lucidChange: 1,
            streakChange: 2
        )
        
        XCTAssertTrue(comparison.isBetter)
        XCTAssertEqual(comparison.dreamsChangePercent, 30.0)
    }
    
    func testWeekComparisonWorse() {
        let comparison = WeekComparison(
            dreamsChange: -2,
            dreamsChangePercent: -20.0,
            clarityChange: -0.3,
            lucidChange: 0,
            streakChange: 0
        )
        
        XCTAssertFalse(comparison.isBetter)
    }
    
    // MARK: - 服务测试
    
    func testServiceInitialization() {
        let service = DreamWeeklyReportService()
        XCTAssertNotNil(service)
        XCTAssertNil(service.currentReport)
        XCTAssertFalse(service.isGenerating)
    }
    
    func testEmptyReportGeneration() async {
        // 清空梦境数据
        let emptyDreams: [Dream] = []
        
        let report = await service.generateReport(startDate: Date(), endDate: Date().addingTimeInterval(7 * 24 * 60 * 60))
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report?.totalDreams, 0)
        XCTAssertEqual(report?.suggestions.first, "开始记录你的第一个梦境吧！")
    }
    
    func testReportGenerationWithDreams() async throws {
        // 创建测试梦境
        let testDream = Dream(
            title: "测试梦境",
            content: "这是一个测试梦境内容",
            tags: ["测试", "飞行"],
            emotions: [.happy, .calm],
            clarity: 4,
            intensity: 3,
            isLucid: true
        )
        
        // 注意：实际测试需要 mock DreamStore
        // 这里只是验证服务可以初始化
        let service = DreamWeeklyReportService()
        XCTAssertNotNil(service)
    }
    
    // MARK: - 标签频率测试
    
    func testTagFrequencyCreation() {
        let tagFreq = TagFrequency(tag: "飞行", count: 5, change: 2)
        
        XCTAssertEqual(tagFreq.tag, "飞行")
        XCTAssertEqual(tagFreq.count, 5)
        XCTAssertEqual(tagFreq.change, 2)
        XCTAssertEqual(tagFreq.id, "飞行")
    }
    
    func testTagFrequencyWithoutChange() {
        let tagFreq = TagFrequency(tag: "水", count: 3, change: nil)
        
        XCTAssertEqual(tagFreq.tag, "水")
        XCTAssertEqual(tagFreq.count, 3)
        XCTAssertNil(tagFreq.change)
    }
    
    // MARK: - 报告卡片测试
    
    func testReportCardThemeDisplayValues() {
        XCTAssertEqual(WeeklyReportCard.ReportCardTheme.starry.displayName, "星空")
        XCTAssertEqual(WeeklyReportCard.ReportCardTheme.sunset.displayName, "日落")
        XCTAssertEqual(WeeklyReportCard.ReportCardTheme.ocean.displayName, "海洋")
        XCTAssertEqual(WeeklyReportCard.ReportCardTheme.forest.displayName, "森林")
        XCTAssertEqual(WeeklyReportCard.ReportCardTheme.minimal.displayName, "简约")
        XCTAssertEqual(WeeklyReportCard.ReportCardTheme.gradient.displayName, "渐变")
    }
    
    func testReportCardCreation() {
        let report = DreamWeeklyReport(
            weekStartDate: Date(),
            weekEndDate: Date(),
            generatedAt: Date(),
            totalDreams: 5,
            lucidDreams: 1,
            averageClarity: 3.5,
            averageIntensity: 3.0,
            recordingStreak: 3,
            emotionDistribution: [:],
            dominantEmotion: "平静",
            moodTrend: .stable,
            topTags: [],
            emergingThemes: [],
            fadingThemes: [],
            dreamsByTimeOfDay: [:],
            dreamsByWeekday: [:],
            mostActiveDay: 1,
            bestRecallHour: 8,
            highlightDreams: [],
            insights: [],
            suggestions: [],
            lastWeekComparison: nil
        )
        
        let card = WeeklyReportCard(report: report, theme: .starry, backgroundImage: nil)
        
        XCTAssertEqual(card.report.totalDreams, 5)
        XCTAssertEqual(card.theme, .starry)
        XCTAssertNil(card.backgroundImage)
    }
    
    // MARK: - 洞察生成测试
    
    func testInsightCreation() {
        let insight = ReportInsight(
            type: .achievement,
            title: "记录达人",
            description: "本周记录了 10 个梦境",
            icon: "trophy.fill",
            confidence: 1.0
        )
        
        XCTAssertEqual(insight.type, .achievement)
        XCTAssertEqual(insight.title, "记录达人")
        XCTAssertEqual(insight.confidence, 1.0)
        XCTAssertNotNil(insight.id)
    }
    
    func testInsightWithLowConfidence() {
        let insight = ReportInsight(
            type: .pattern,
            title: "模式发现",
            description: "发现重复主题",
            icon: "magnifyingglass",
            confidence: 0.6
        )
        
        XCTAssertEqual(insight.confidence, 0.6)
        XCTAssertEqual(insight.type, .pattern)
    }
}
