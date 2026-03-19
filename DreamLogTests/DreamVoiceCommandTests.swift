//
//  DreamVoiceCommandTests.swift
//  DreamLogTests
//
//  Phase 71 - 语音命令系统单元测试
//  测试覆盖：命令识别/服务功能/视图模型
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamVoiceCommandTests: XCTestCase {
    
    // MARK: - 测试数据
    
    var voiceService: VoiceCommandService!
    var viewModel: DreamVoiceCommandViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        voiceService = VoiceCommandService.shared
        viewModel = DreamVoiceCommandViewModel(voiceService: voiceService)
    }
    
    override func tearDown() async throws {
        voiceService = nil
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - VoiceCommand 枚举测试
    
    func testVoiceCommandAllCases() {
        let allCases = VoiceCommand.allCases
        XCTAssertGreaterThan(allCases.count, 0, "应该有多个语音命令")
    }
    
    func testVoiceCommandKeywords() {
        for command in VoiceCommand.allCases {
            XCTAssertFalse(command.keywords.isEmpty, "\(command) 应该有关键词")
        }
    }
    
    func testVoiceCommandDescriptions() {
        for command in VoiceCommand.allCases {
            XCTAssertFalse(command.description.isEmpty, "\(command) 应该有描述")
        }
    }
    
    func testVoiceCommandIcons() {
        for command in VoiceCommand.allCases {
            XCTAssertFalse(command.icon.isEmpty, "\(command) 应该有图标")
        }
    }
    
    // MARK: - 命令识别测试
    
    func testRecordDreamCommandRecognition() {
        let keywords = ["记录梦境", "记梦", "写梦", "记录", "记一下"]
        
        for keyword in keywords {
            let command = identifyCommand(from: keyword)
            XCTAssertEqual(command, .recordDream, "应该识别\"\(keyword)\"为记录梦境命令")
        }
    }
    
    func testShowStatsCommandRecognition() {
        let keywords = ["查看统计", "统计数据", "我的统计", "数据分析"]
        
        for keyword in keywords {
            let command = identifyCommand(from: keyword)
            XCTAssertEqual(command, .showStats, "应该识别\"\(keyword)\"为查看统计命令")
        }
    }
    
    func testOpenGalleryCommandRecognition() {
        let keywords = ["画廊", "梦境画廊", "图片", "AI 绘画"]
        
        for keyword in keywords {
            let command = identifyCommand(from: keyword)
            XCTAssertEqual(command, .openGallery, "应该识别\"\(keyword)\"为打开画廊命令")
        }
    }
    
    func testHelpCommandRecognition() {
        let keywords = ["帮助", "怎么用", "如何使用"]
        
        for keyword in keywords {
            let command = identifyCommand(from: keyword)
            XCTAssertEqual(command, .help, "应该识别\"\(keyword)\"为帮助命令")
        }
    }
    
    // MARK: - VoiceCommandResult 测试
    
    func testVoiceCommandResultSuccess() {
        let result = VoiceCommandResult(
            command: .recordDream,
            confidence: 0.95,
            transcribedText: "记录梦境",
            timestamp: Date()
        )
        
        XCTAssertTrue(result.isSuccess, "高置信度的识别应该是成功的")
        XCTAssertFalse(result.displayText.isEmpty, "应该有显示文本")
    }
    
    func testVoiceCommandResultFailure() {
        let result = VoiceCommandResult(
            command: nil,
            confidence: 0.3,
            transcribedText: "未知命令",
            timestamp: Date()
        )
        
        XCTAssertFalse(result.isSuccess, "低置信度的识别应该是失败的")
    }
    
    // MARK: - VoiceCommandConfig 测试
    
    func testVoiceCommandConfigDefault() {
        let config = VoiceCommandConfig.default
        
        XCTAssertTrue(config.enabled, "默认应该启用")
        XCTAssertEqual(config.language, "zh-CN", "默认语言应该是中文")
        XCTAssertFalse(config.requiresConfirmation, "默认不需要确认")
        XCTAssertTrue(config.showVisualFeedback, "默认显示视觉反馈")
        XCTAssertTrue(config.hapticFeedback, "默认启用触觉反馈")
    }
    
    func testVoiceCommandConfigEncoding() throws {
        var config = VoiceCommandConfig.default
        config.enabled = false
        config.language = "en-US"
        config.requiresConfirmation = true
        
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(VoiceCommandConfig.self, from: data)
        
        XCTAssertEqual(config.enabled, decoded.enabled)
        XCTAssertEqual(config.language, decoded.language)
        XCTAssertEqual(config.requiresConfirmation, decoded.requiresConfirmation)
    }
    
    // MARK: - ViewModel 测试
    
    func testViewModelInitialization() {
        XCTAssertEqual(viewModel.currentView, .gallery, "默认视图应该是画廊")
        XCTAssertFalse(viewModel.isShowingFeedback, "默认不显示反馈")
        XCTAssertNil(viewModel.errorMessage, "默认没有错误")
    }
    
    func testViewModelNavigation() {
        viewModel.navigateTo(.insights)
        XCTAssertEqual(viewModel.currentView, .insights, "应该导航到洞察页面")
        
        viewModel.navigateTo(.settings)
        XCTAssertEqual(viewModel.currentView, .settings, "应该导航到设置页面")
    }
    
    func testViewModelFeedback() async {
        viewModel.showFeedback("测试反馈")
        
        XCTAssertTrue(viewModel.isShowingFeedback, "应该显示反馈")
        XCTAssertEqual(viewModel.feedbackMessage, "测试反馈", "反馈消息应该正确")
        
        // 等待自动隐藏
        try await Task.sleep(nanoseconds: 2_500_000_000)
        
        XCTAssertFalse(viewModel.isShowingFeedback, "反馈应该自动隐藏")
    }
    
    func testViewModelDreamSelection() {
        let dream = Dream(title: "测试梦境", content: "测试内容")
        
        viewModel.selectDream(dream)
        XCTAssertEqual(viewModel.selectedDream?.title, "测试梦境", "应该选中梦境")
        XCTAssertEqual(viewModel.currentView, .detail, "应该导航到详情页面")
        
        viewModel.clearSelection()
        XCTAssertNil(viewModel.selectedDream, "应该清除选择")
    }
    
    func testViewModelTodayDreams() async {
        // 设置测试数据
        viewModel.dreams = [
            Dream(title: "今天的梦", content: "今天做的梦", createdAt: Date()),
            Dream(title: "昨天的梦", content: "昨天做的梦", createdAt: Date().addingTimeInterval(-86400))
        ]
        
        viewModel.showTodayDreams()
        
        XCTAssertEqual(viewModel.dreams.count, 1, "应该只显示今天的梦境")
        XCTAssertEqual(viewModel.dreams.first?.title, "今天的梦", "应该是今天的梦境")
    }
    
    func testViewModelLockDreamWithoutSelection() {
        viewModel.lockCurrentDream()
        
        XCTAssertEqual(viewModel.feedbackMessage, "请先选择一个梦境", "应该提示选择梦境")
    }
    
    func testViewModelShareDreamWithoutSelection() {
        viewModel.shareCurrentDream()
        
        XCTAssertEqual(viewModel.feedbackMessage, "请先选择一个梦境", "应该提示选择梦境")
    }
    
    func testViewModelAnalyzeDreamWithoutSelection() {
        viewModel.analyzeCurrentDream()
        
        XCTAssertEqual(viewModel.feedbackMessage, "请先选择一个梦境", "应该提示选择梦境")
    }
    
    // MARK: - 边界情况测试
    
    func testEmptyKeywordRecognition() {
        let command = identifyCommand(from: "")
        XCTAssertNil(command, "空字符串不应该识别为任何命令")
    }
    
    func testRandomTextRecognition() {
        let command = identifyCommand(from: "随机文本 xyz 123")
        XCTAssertNil(command, "随机文本不应该识别为任何命令")
    }
    
    func testMixedLanguageRecognition() {
        let command = identifyCommand(from: "记录 record 梦境 dream")
        // 混合语言可能无法正确识别，这是预期行为
        XCTAssertNotNil(command) // 只要有匹配就应该识别
    }
    
    // MARK: - 性能测试
    
    func testCommandIdentificationPerformance() {
        let testTexts = [
            "记录梦境",
            "查看统计",
            "打开画廊",
            "帮助",
            "搜索梦境"
        ]
        
        measure {
            for text in testTexts {
                _ = identifyCommand(from: text)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func identifyCommand(from text: String) -> VoiceCommand? {
        let lowercasedText = text.lowercased()
        
        var bestMatch: VoiceCommand?
        var bestScore = 0.0
        
        for command in VoiceCommand.allCases {
            for keyword in command.keywords {
                if lowercasedText.contains(keyword.lowercased()) {
                    let score = Double(keyword.count) / Double(text.count)
                    if score > bestScore {
                        bestScore = score
                        bestMatch = command
                    }
                }
            }
        }
        
        return bestScore > 0.3 ? bestMatch : nil
    }
}

// MARK: - 测试数据扩展

extension DreamVoiceCommandTests {
    private func createTestDreams() -> [Dream] {
        return [
            Dream(title: "飞行梦", content: "我在天空中飞翔", tags: ["飞行", "自由"]),
            Dream(title: "追逐梦", content: "有人在追我", tags: ["追逐", "恐惧"]),
            Dream(title: "清醒梦", content: "我知道自己在做梦", tags: ["清醒梦"], isLucid: true)
        ]
    }
}
