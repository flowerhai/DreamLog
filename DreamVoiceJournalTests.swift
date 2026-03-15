//
//  DreamVoiceJournalTests.swift
//  DreamLogTests
//
//  Phase 51: 梦境语音日记与 AI 摘要 - 单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamVoiceJournalTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamVoiceJournalService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            VoiceJournalEntry.self,
            Dream.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // 创建服务实例
        service = DreamVoiceJournalService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 录音测试
    
    /// 测试开始录音
    func testStartRecording() async throws {
        let entry = try await service.startRecording(title: "测试录音")
        
        XCTAssertEqual(entry.title, "测试录音")
        XCTAssertFalse(entry.isProcessed)
        XCTAssertEqual(entry.playCount, 0)
        XCTAssertEqual(entry.playbackSpeed, 1.0)
        
        // 清理
        try await service.cancelRecording()
    }
    
    /// 测试停止录音
    func testStopRecording() async throws {
        let entry = try await service.startRecording(title: "测试录音")
        let stoppedEntry = try await service.stopRecording()
        
        XCTAssertNotNil(stoppedEntry)
        XCTAssertEqual(stoppedEntry?.title, "测试录音")
        XCTAssertGreaterThanOrEqual(stoppedEntry?.duration ?? 0, 0)
    }
    
    /// 测试取消录音
    func testCancelRecording() async throws {
        let entry = try await service.startRecording(title: "测试录音")
        try await service.cancelRecording()
        
        let entries = try await service.getAllEntries()
        XCTAssertTrue(entries.isEmpty)
    }
    
    /// 测试重复开始录音
    func testAlreadyRecording() async throws {
        _ = try await service.startRecording(title: "测试 1")
        
        do {
            _ = try await service.startRecording(title: "测试 2")
            XCTFail("应该抛出 alreadyRecording 错误")
        } catch VoiceJournalError.alreadyRecording {
            // 预期错误
        } catch {
            XCTFail("抛出错误类型错误：\(error)")
        }
        
        // 清理
        try await service.cancelRecording()
    }
    
    // MARK: - 处理测试
    
    /// 测试语音转写
    func testTranscribeAudio() async throws {
        let entry = try await service.startRecording(title: "转写测试")
        try await service.stopRecording()
        
        let transcript = try await service.transcribeAudio(at: entry.audioURL)
        
        XCTAssertFalse(transcript.text.isEmpty)
        XCTAssertGreaterThanOrEqual(transcript.confidence, 0)
        XCTAssertLessThanOrEqual(transcript.confidence, 1)
        XCTAssertEqual(transcript.language, "zh-CN")
    }
    
    /// 测试摘要生成
    func testGenerateSummary() async throws {
        let testText = "昨晚我做了一个很奇怪的梦，梦见自己在天空中飞行，感觉很自由很兴奋"
        
        let summary = try await service.generateSummary(from: testText)
        
        XCTAssertFalse(summary.title.isEmpty)
        XCTAssertFalse(summary.summary.isEmpty)
        XCTAssertFalse(summary.keywords.isEmpty)
        XCTAssertEqual(summary.mood, .excited)
    }
    
    /// 测试情绪分析
    func testMoodAnalysis() async throws {
        let testCases: [(String, VoiceMood)] = [
            ("我很害怕，很恐惧", .fearful),
            ("我很开心，很快乐", .happy),
            ("我很悲伤，很难过", .sad),
            ("我很兴奋，很激动", .excited),
            ("我很焦虑，很紧张", .anxious),
            ("我很平静，很放松", .calm),
            ("我很困惑，很迷茫", .confused),
            ("今天天气不错", .neutral)
        ]
        
        for (text, expectedMood) in testCases {
            let summary = try await service.generateSummary(from: text)
            XCTAssertEqual(summary.mood, expectedMood, "文本：\(text)")
        }
    }
    
    // MARK: - 查询测试
    
    /// 测试获取所有条目
    func testGetAllEntries() async throws {
        // 创建测试数据
        let entry1 = VoiceJournalEntry(title: "测试 1", audioURL: URL(fileURLWithPath: "/test1.m4a"))
        let entry2 = VoiceJournalEntry(title: "测试 2", audioURL: URL(fileURLWithPath: "/test2.m4a"))
        modelContext.insert(entry1)
        modelContext.insert(entry2)
        try modelContext.save()
        
        let entries = try await service.getAllEntries()
        
        XCTAssertEqual(entries.count, 2)
    }
    
    /// 测试搜索功能
    func testSearch() async throws {
        // 创建测试数据
        let entry1 = VoiceJournalEntry(
            title: "飞行梦",
            audioURL: URL(fileURLWithPath: "/test1.m4a"),
            transcript: "我梦见自己在天空中飞行",
            keywords: ["飞行", "天空", "梦"]
        )
        let entry2 = VoiceJournalEntry(
            title: "水之梦",
            audioURL: URL(fileURLWithPath: "/test2.m4a"),
            transcript: "我梦见大海和波浪",
            keywords: ["水", "海", "梦"]
        )
        modelContext.insert(entry1)
        modelContext.insert(entry2)
        try modelContext.save()
        
        // 搜索"飞行"
        let results1 = try await service.search(query: "飞行")
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results1.first?.title, "飞行梦")
        
        // 搜索"梦"
        let results2 = try await service.search(query: "梦")
        XCTAssertEqual(results2.count, 2)
        
        // 搜索不存在的词
        let results3 = try await service.search(query: "不存在")
        XCTAssertEqual(results3.count, 0)
    }
    
    /// 测试统计数据
    func testGetStats() async throws {
        // 创建测试数据
        let entry1 = VoiceJournalEntry(
            title: "测试 1",
            audioURL: URL(fileURLWithPath: "/test1.m4a"),
            duration: 60,
            mood: .happy,
            isFavorite: true
        )
        let entry2 = VoiceJournalEntry(
            title: "测试 2",
            audioURL: URL(fileURLWithPath: "/test2.m4a"),
            duration: 120,
            mood: .calm,
            isFavorite: false
        )
        modelContext.insert(entry1)
        modelContext.insert(entry2)
        try modelContext.save()
        
        let stats = try await service.getStats()
        
        XCTAssertEqual(stats.totalEntries, 2)
        XCTAssertEqual(stats.totalDuration, 180)
        XCTAssertEqual(stats.favoriteCount, 1)
        XCTAssertEqual(stats.moodDistribution["happy"], 1)
        XCTAssertEqual(stats.moodDistribution["calm"], 1)
    }
    
    // MARK: - 管理测试
    
    /// 测试删除条目
    func testDeleteEntry() async throws {
        let entry = VoiceJournalEntry(
            title: "测试",
            audioURL: URL(fileURLWithPath: "/test.m4a")
        )
        modelContext.insert(entry)
        try modelContext.save()
        
        try await service.delete(entry: entry)
        
        let entries = try await service.getAllEntries()
        XCTAssertTrue(entries.isEmpty)
    }
    
    /// 测试切换收藏状态
    func testToggleFavorite() async throws {
        let entry = VoiceJournalEntry(
            title: "测试",
            audioURL: URL(fileURLWithPath: "/test.m4a"),
            isFavorite: false
        )
        modelContext.insert(entry)
        try modelContext.save()
        
        try await service.toggleFavorite(entry: entry)
        XCTAssertTrue(entry.isFavorite)
        
        try await service.toggleFavorite(entry: entry)
        XCTAssertFalse(entry.isFavorite)
    }
    
    /// 测试更新播放速度
    func testUpdatePlaybackSpeed() async throws {
        let entry = VoiceJournalEntry(
            title: "测试",
            audioURL: URL(fileURLWithPath: "/test.m4a"),
            playbackSpeed: 1.0
        )
        modelContext.insert(entry)
        try modelContext.save()
        
        try await service.updatePlaybackSpeed(entry: entry, speed: 1.5)
        XCTAssertEqual(entry.playbackSpeed, 1.5)
    }
    
    // MARK: - 配置测试
    
    /// 测试默认配置
    func testDefaultConfig() {
        let config = VoiceJournalConfig.default
        
        XCTAssertEqual(config.audioQuality, .high)
        XCTAssertTrue(config.autoTranscribe)
        XCTAssertTrue(config.autoSummarize)
        XCTAssertTrue(config.autoMoodAnalysis)
        XCTAssertEqual(config.defaultPlaybackSpeed, 1.0)
        XCTAssertEqual(config.maxRecordingDuration, 300)
        XCTAssertTrue(config.saveToCloud)
    }
    
    /// 测试音质配置
    func testAudioQuality() {
        XCTAssertEqual(VoiceJournalConfig.AudioQuality.low.bitRate, 64)
        XCTAssertEqual(VoiceJournalConfig.AudioQuality.medium.bitRate, 128)
        XCTAssertEqual(VoiceJournalConfig.AudioQuality.high.bitRate, 256)
        XCTAssertEqual(VoiceJournalConfig.AudioQuality.lossless.bitRate, 1411)
    }
    
    // MARK: - 模型测试
    
    /// 测试 VoiceJournalEntry 初始化
    func testVoiceJournalEntryInit() {
        let audioURL = URL(fileURLWithPath: "/test.m4a")
        let entry = VoiceJournalEntry(
            title: "测试标题",
            audioURL: audioURL,
            duration: 120,
            isFavorite: true,
            playbackSpeed: 1.5
        )
        
        XCTAssertEqual(entry.title, "测试标题")
        XCTAssertEqual(entry.audioURL, audioURL)
        XCTAssertEqual(entry.duration, 120)
        XCTAssertTrue(entry.isFavorite)
        XCTAssertEqual(entry.playbackSpeed, 1.5)
        XCTAssertEqual(entry.playCount, 0)
        XCTAssertFalse(entry.isProcessed)
    }
    
    /// 测试 VoiceMood 枚举
    func testVoiceMoodEnum() {
        let moods: [VoiceMood] = [.calm, .excited, .anxious, .sad, .confused, .happy, .fearful, .neutral]
        
        for mood in moods {
            XCTAssertFalse(mood.displayName.isEmpty)
            XCTAssertFalse(mood.icon.isEmpty)
            XCTAssertFalse(mood.color.isEmpty)
        }
    }
    
    /// 测试 VoiceSummary 初始化
    func testVoiceSummaryInit() {
        let summary = VoiceSummary(
            title: "测试标题",
            summary: "测试摘要",
            keyPoints: ["要点 1", "要点 2"],
            mood: .happy,
            keywords: ["关键词 1", "关键词 2"],
            emotionScores: ["happy": 0.8, "sad": 0.2]
        )
        
        XCTAssertEqual(summary.title, "测试标题")
        XCTAssertEqual(summary.summary, "测试摘要")
        XCTAssertEqual(summary.keyPoints.count, 2)
        XCTAssertEqual(summary.mood, .happy)
        XCTAssertEqual(summary.keywords.count, 2)
        XCTAssertEqual(summary.emotionScores["happy"], 0.8)
    }
    
    /// 测试 VoiceJournalStats 空值
    func testVoiceJournalStatsEmpty() {
        let stats = VoiceJournalStats.empty
        
        XCTAssertEqual(stats.totalEntries, 0)
        XCTAssertEqual(stats.totalDuration, 0)
        XCTAssertEqual(stats.totalTranscripts, 0)
        XCTAssertEqual(stats.averageDuration, 0)
        XCTAssertTrue(stats.moodDistribution.isEmpty)
        XCTAssertTrue(stats.entriesByDate.isEmpty)
        XCTAssertTrue(stats.mostUsedKeywords.isEmpty)
        XCTAssertEqual(stats.favoriteCount, 0)
    }
    
    // MARK: - 性能测试
    
    /// 测试大量数据查询性能
    func testPerformanceWithManyEntries() async throws {
        // 创建 100 个测试条目
        for i in 0..<100 {
            let entry = VoiceJournalEntry(
                title: "测试 \(i)",
                audioURL: URL(fileURLWithPath: "/test\(i).m4a"),
                duration: Double(i * 10),
                isFavorite: i % 10 == 0
            )
            modelContext.insert(entry)
        }
        try modelContext.save()
        
        // 测量查询性能
        measure {
            let expectation = XCTestExpectation(description: "Load entries")
            
            Task {
                let entries = try? await service.getAllEntries()
                XCTAssertEqual(entries?.count, 100)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
    
    /// 测试搜索性能
    func testSearchPerformance() async throws {
        // 创建 50 个测试条目
        for i in 0..<50 {
            let entry = VoiceJournalEntry(
                title: "测试 \(i)",
                audioURL: URL(fileURLWithPath: "/test\(i).m4a"),
                transcript: "这是第 \(i) 个测试条目的转写文本",
                keywords: ["测试", "条目", "\(i)"]
            )
            modelContext.insert(entry)
        }
        try modelContext.save()
        
        // 测量搜索性能
        measure {
            let expectation = XCTestExpectation(description: "Search entries")
            
            Task {
                let results = try? await service.search(query: "测试")
                XCTAssertGreaterThan(results?.count ?? 0, 0)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
}

// MARK: - 测试覆盖率说明

/*
 测试覆盖范围:
 
 1. 录音功能 (4 个测试)
    - ✅ 开始录音
    - ✅ 停止录音
    - ✅ 取消录音
    - ✅ 重复录音错误处理
 
 2. 处理功能 (3 个测试)
    - ✅ 语音转写
    - ✅ 摘要生成
    - ✅ 情绪分析
 
 3. 查询功能 (3 个测试)
    - ✅ 获取所有条目
    - ✅ 搜索功能
    - ✅ 统计数据
 
 4. 管理功能 (3 个测试)
    - ✅ 删除条目
    - ✅ 切换收藏
    - ✅ 更新播放速度
 
 5. 配置测试 (2 个测试)
    - ✅ 默认配置
    - ✅ 音质配置
 
 6. 模型测试 (4 个测试)
    - ✅ VoiceJournalEntry 初始化
    - ✅ VoiceMood 枚举
    - ✅ VoiceSummary 初始化
    - ✅ VoiceJournalStats 空值
 
 7. 性能测试 (2 个测试)
    - ✅ 大量数据查询性能
    - ✅ 搜索性能
 
 总测试用例：23 个
 测试覆盖率目标：95%+
 */
