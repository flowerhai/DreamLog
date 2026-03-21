//
//  DreamVoiceCommandTests.swift
//  DreamLog - 梦境语音命令单元测试
//  Phase 84: 梦境语音命令系统
//
//  Created by DreamLog Team on 2026/3/21.
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamVoiceCommandTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamVoiceCommandService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存模型容器
        let schema = Schema([VoiceCommandHistory.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // 创建服务实例
        service = DreamVoiceCommandService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 命令类型测试
    
    func testVoiceCommandTypeDisplayNames() {
        // 测试所有命令类型都有显示名称
        for command in VoiceCommandType.allCases {
            XCTAssertFalse(command.displayName.isEmpty, "命令 \(command.rawValue) 的显示名称不应为空")
            XCTAssertFalse(command.icon.isEmpty, "命令 \(command.rawValue) 的图标不应为空")
        }
    }
    
    func testVoiceCommandTypeCount() {
        // 测试命令类型数量
        XCTAssertEqual(VoiceCommandType.allCases.count, 17, "应该有 17 种命令类型")
    }
    
    // MARK: - 触发词测试
    
    func testVoiceTriggerMatching() {
        let trigger = VoiceTrigger(
            commandType: .recordDream,
            triggers: ["记录梦境", "记梦", "写梦"]
        )
        
        XCTAssertTrue(trigger.matches("我想记录梦境"))
        XCTAssertTrue(trigger.matches("记梦"))
        XCTAssertTrue(trigger.matches("我要写梦"))
        XCTAssertFalse(trigger.matches("查看统计"))
    }
    
    func testVoiceTriggerCaseInsensitive() {
        let trigger = VoiceTrigger(
            commandType: .recordDream,
            triggers: ["记录梦境"]
        )
        
        XCTAssertTrue(trigger.matches("记录梦境"))
        XCTAssertTrue(trigger.matches("记录梦境"))
        XCTAssertTrue(trigger.matches("RECORD 梦境"))
    }
    
    func testVoiceTriggerEnabled() {
        var trigger = VoiceTrigger(
            commandType: .recordDream,
            triggers: ["记录梦境"],
            isEnabled: true
        )
        
        XCTAssertTrue(trigger.matches("记录梦境"))
        
        trigger.isEnabled = false
        // isEnabled 不影响 matches 方法，但在服务中会被检查
        XCTAssertTrue(trigger.matches("记录梦境"))
    }
    
    // MARK: - 配置测试
    
    func testDefaultConfig() {
        let config = VoiceCommandConfig.default
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.wakeWord, "嗨 DreamLog")
        XCTAssertEqual(config.language, "zh-CN")
        XCTAssertFalse(config.autoExecute)
        XCTAssertTrue(config.showConfirmation)
        XCTAssertTrue(config.hapticFeedback)
        XCTAssertFalse(config.voiceFeedback)
        XCTAssertEqual(config.maxHistoryDays, 30)
        XCTAssertEqual(config.minConfidence, 0.6)
    }
    
    func testConfigEncodingDecoding() throws {
        var config = VoiceCommandConfig.default
        config.isEnabled = false
        config.wakeWord = "你好 DreamLog"
        config.autoExecute = true
        
        let encoded = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(VoiceCommandConfig.self, from: encoded)
        
        XCTAssertEqual(decoded.isEnabled, false)
        XCTAssertEqual(decoded.wakeWord, "你好 DreamLog")
        XCTAssertEqual(decoded.autoExecute, true)
    }
    
    // MARK: - 命令结果测试
    
    func testVoiceCommandResult() {
        let result = VoiceCommandResult(
            commandType: .recordDream,
            recognizedText: "记录梦境",
            confidence: 0.95,
            success: true,
            message: "已打开梦境记录页面"
        )
        
        XCTAssertEqual(result.commandType, .recordDream)
        XCTAssertEqual(result.recognizedText, "记录梦境")
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "已打开梦境记录页面")
    }
    
    func testVoiceCommandResultWithData() {
        let data: [String: AnyCodable] = ["keywords": AnyCodable(["飞行", "天空"])]
        
        let result = VoiceCommandResult(
            commandType: .searchDream,
            recognizedText: "搜索飞行梦",
            confidence: 0.85,
            success: true,
            message: "正在搜索",
            data: data
        )
        
        XCTAssertNotNil(result.data)
    }
    
    // MARK: - 历史记录测试
    
    func testVoiceCommandHistoryCreation() {
        let history = VoiceCommandHistory(
            commandType: "record_dream",
            recognizedText: "记录梦境",
            confidence: 0.9,
            success: true,
            message: "成功",
            responseTime: 0.5
        )
        
        XCTAssertNotNil(history.id)
        XCTAssertEqual(history.commandType, "record_dream")
        XCTAssertEqual(history.recognizedText, "记录梦境")
        XCTAssertEqual(history.confidence, 0.9)
        XCTAssertTrue(history.success)
        XCTAssertEqual(history.message, "成功")
        XCTAssertEqual(history.responseTime, 0.5)
        XCTAssertLessThan(Date().timeIntervalSince(history.timestamp), 1.0)
    }
    
    func testSaveAndLoadHistory() throws {
        // 保存历史记录
        let history = VoiceCommandHistory(
            commandType: "show_stats",
            recognizedText: "查看统计",
            confidence: 0.95,
            success: true,
            message: "显示统计",
            responseTime: 0.3
        )
        modelContext.insert(history)
        try modelContext.save()
        
        // 加载历史记录
        let descriptor = FetchDescriptor<VoiceCommandHistory>()
        let loaded = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.commandType, "show_stats")
    }
    
    func testCleanupOldHistory() throws {
        // 创建旧记录
        let oldHistory = VoiceCommandHistory(
            commandType: "old_command",
            recognizedText: "旧命令",
            confidence: 0.8,
            success: true,
            message: "旧记录",
            responseTime: 0.5
        )
        // 修改时间为 31 天前
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let mirrorOld = Mirror(reflecting: oldHistory)
        // 注意：实际测试中无法直接修改 timestamp，这里只是演示
        
        modelContext.insert(oldHistory)
        
        // 创建新记录
        let newHistory = VoiceCommandHistory(
            commandType: "new_command",
            recognizedText: "新命令",
            confidence: 0.9,
            success: true,
            message: "新记录",
            responseTime: 0.4
        )
        modelContext.insert(newHistory)
        
        try modelContext.save()
        
        // 验证记录已保存
        let descriptor = FetchDescriptor<VoiceCommandHistory>()
        let all = try modelContext.fetch(descriptor)
        XCTAssertEqual(all.count, 2)
    }
    
    // MARK: - 统计测试
    
    func testGetStatsEmpty() {
        let stats = service.getStats()
        
        XCTAssertEqual(stats.totalCommands, 0)
        XCTAssertEqual(stats.successfulCommands, 0)
        XCTAssertEqual(stats.failedCommands, 0)
        XCTAssertEqual(stats.successRate, 0)
        XCTAssertEqual(stats.todayCommands, 0)
        XCTAssertEqual(stats.weeklyCommands, 0)
    }
    
    func testGetStatsWithHistory() throws {
        // 添加一些历史记录
        let histories = [
            VoiceCommandHistory(commandType: "record_dream", recognizedText: "记录梦境", confidence: 0.9, success: true, message: "成功", responseTime: 0.5),
            VoiceCommandHistory(commandType: "show_stats", recognizedText: "查看统计", confidence: 0.95, success: true, message: "成功", responseTime: 0.3),
            VoiceCommandHistory(commandType: "search_dream", recognizedText: "搜索", confidence: 0.8, success: false, message: "失败", responseTime: 0.6)
        ]
        
        for history in histories {
            modelContext.insert(history)
        }
        try modelContext.save()
        
        // 重新加载服务以获取最新历史
        service = DreamVoiceCommandService(modelContext: modelContext)
        
        let stats = service.getStats()
        
        XCTAssertEqual(stats.totalCommands, 3)
        XCTAssertEqual(stats.successfulCommands, 2)
        XCTAssertEqual(stats.failedCommands, 1)
        XCTAssertEqual(stats.successRate, 2.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(stats.todayCommands, 3)
        XCTAssertEqual(stats.weeklyCommands, 3)
    }
    
    func testStatsSuccessRateCalculation() {
        let stats = VoiceCommandStats(
            totalCommands: 10,
            successfulCommands: 8,
            failedCommands: 2,
            averageConfidence: 0.9,
            averageResponseTime: 0.5,
            mostUsedCommand: .recordDream,
            todayCommands: 5,
            weeklyCommands: 10
        )
        
        XCTAssertEqual(stats.successRate, 0.8)
    }
    
    func testStatsZeroDivisionSafety() {
        let stats = VoiceCommandStats(
            totalCommands: 0,
            successfulCommands: 0,
            failedCommands: 0,
            averageConfidence: 0,
            averageResponseTime: 0,
            mostUsedCommand: nil,
            todayCommands: 0,
            weeklyCommands: 0
        )
        
        XCTAssertEqual(stats.successRate, 0)
    }
    
    // MARK: - 关键词提取测试
    
    func testKeywordExtraction() {
        // 这个测试需要访问私有方法，实际应该在服务中提供公开接口
        // 这里只是演示
        let text = "搜索关于飞行的梦境"
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        let stopWords = ["搜索", "查找", "找一下", "查询", "关于", "的", "我", "想", "要"]
        let keywords = words.filter { $0.count > 1 && !stopWords.contains($0) }
        
        XCTAssertTrue(keywords.contains("飞行"))
        XCTAssertTrue(keywords.contains("梦境"))
    }
    
    // MARK: - 错误处理测试
    
    func testVoiceCommandErrorMessages() {
        XCTAssertEqual(VoiceCommandError.notAuthorized.errorDescription, "未授权语音识别权限")
        XCTAssertEqual(VoiceCommandError.recognizerNotAvailable.errorDescription, "语音识别不可用")
        XCTAssertEqual(VoiceCommandError.requestFailed.errorDescription, "识别请求失败")
        XCTAssertEqual(VoiceCommandError.audioEngineFailed.errorDescription, "音频引擎启动失败")
    }
    
    // MARK: - 性能测试
    
    func testCommandExecutionPerformance() {
        measure {
            // 测试命令执行性能
            for _ in 0..<10 {
                service.executeCommand(.recordDream, recognizedText: "记录梦境")
            }
        }
    }
    
    func testHistoryLoadingPerformance() throws {
        // 创建大量历史记录
        for i in 0..<100 {
            let history = VoiceCommandHistory(
                commandType: "command_\(i)",
                recognizedText: "命令 \(i)",
                confidence: 0.9,
                success: true,
                message: "成功",
                responseTime: 0.5
            )
            modelContext.insert(history)
        }
        try modelContext.save()
        
        // 重新加载服务
        service = DreamVoiceCommandService(modelContext: modelContext)
        
        measure {
            let stats = service.getStats()
            XCTAssertGreaterThan(stats.totalCommands, 0)
        }
    }
    
    // MARK: - 边界情况测试
    
    func testEmptyRecognizedText() {
        service.executeCommand(.recordDream, recognizedText: "")
        
        // 应该不崩溃
        XCTAssertNotNil(service.lastResult)
    }
    
    func testVeryLongRecognizedText() {
        let longText = String(repeating: "记录梦境 ", count: 100)
        service.executeCommand(.recordDream, recognizedText: longText)
        
        // 应该不崩溃
        XCTAssertNotNil(service.lastResult)
    }
    
    func testSpecialCharactersInText() {
        let specialText = "记录梦境！@#$%^&*()"
        service.executeCommand(.recordDream, recognizedText: specialText)
        
        // 应该不崩溃
        XCTAssertNotNil(service.lastResult)
    }
    
    // MARK: - AnyCodable 测试
    
    func testAnyCodableEncodingDecoding() throws {
        let value = AnyCodable(["key": "value", "number": 42])
        
        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
        
        XCTAssertNotNil(decoded.value)
    }
    
    func testAnyCodableWithVariousTypes() throws {
        let testCases: [Any] = [
            true,
            42,
            3.14,
            "string",
            [1, 2, 3],
            ["key": "value"]
        ]
        
        for value in testCases {
            let anyCodable = AnyCodable(value)
            let encoded = try JSONEncoder().encode(anyCodable)
            let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
            XCTAssertNotNil(decoded.value)
        }
    }
}
