//
//  DreamAudioExportTests.swift
//  DreamLogTests
//
//  梦境音频导出 - 单元测试
//  Phase 39: 梦境播客/音频导出功能
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamAudioExportTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamAudioExportService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存模型容器
        let schema = Schema([
            AudioExportConfig.self,
            AudioExportTask.self,
            Dream.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        service = DreamAudioExportService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Config Tests
    
    /// 测试创建导出配置
    func testCreateExportConfig() async throws {
        let config = AudioExportConfig(
            name: "测试配置",
            format: .m4a,
            quality: .high,
            exportRange: .last7Days
        )
        
        try await service.saveConfig(config)
        
        let configs = try await service.getAllConfigs()
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs[0].name, "测试配置")
        XCTAssertEqual(configs[0].format, "m4a")
        XCTAssertEqual(configs[0].quality, "high")
    }
    
    /// 测试配置默认值
    func testConfigDefaultValues() {
        let config = AudioExportConfig()
        
        XCTAssertEqual(config.name, "我的导出配置")
        XCTAssertEqual(config.format, "m4a")
        XCTAssertEqual(config.quality, "high")
        XCTAssertEqual(config.exportRange, "last7Days")
        XCTAssertTrue(config.includeTags)
        XCTAssertTrue(config.includeEmotions)
        XCTAssertTrue(config.includeAIAnalysis)
        XCTAssertTrue(config.includeIntro)
        XCTAssertTrue(config.includeOutro)
        XCTAssertFalse(config.addBackgroundMusic)
    }
    
    /// 测试更新配置
    func testUpdateConfig() async throws {
        let config = AudioExportConfig(name: "原始配置")
        try await service.saveConfig(config)
        
        config.name = "更新后的配置"
        config.format = AudioExportFormat.mp3.rawValue
        config.quality = AudioQuality.medium.rawValue
        
        try await service.saveConfig(config)
        
        let configs = try await service.getAllConfigs()
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs[0].name, "更新后的配置")
        XCTAssertEqual(configs[0].format, "mp3")
        XCTAssertEqual(configs[0].quality, "medium")
    }
    
    /// 测试删除配置
    func testDeleteConfig() async throws {
        let config = AudioExportConfig(name: "待删除配置")
        try await service.saveConfig(config)
        
        var configs = try await service.getAllConfigs()
        XCTAssertEqual(configs.count, 1)
        
        try await service.deleteConfig(config)
        
        configs = try await service.getAllConfigs()
        XCTAssertEqual(configs.count, 0)
    }
    
    // MARK: - Task Tests
    
    /// 测试创建导出任务
    func testCreateExportTask() async throws {
        let config = AudioExportConfig(name: "测试配置")
        try await service.saveConfig(config)
        
        let dreams = createSampleDreams(count: 3)
        dreams.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        let task = try await service.createExportTask(config: config, dreams: dreams)
        
        XCTAssertEqual(task.configId, config.id)
        XCTAssertEqual(task.status, "pending")
        XCTAssertEqual(task.totalDreams, 3)
        XCTAssertEqual(task.processedDreams, 0)
        XCTAssertEqual(task.progress, 0)
    }
    
    /// 测试获取所有任务
    func testGetAllTasks() async throws {
        let config = AudioExportConfig(name: "测试配置")
        try await service.saveConfig(config)
        
        for i in 0..<3 {
            let dreams = createSampleDreams(count: 2)
            dreams.forEach { modelContext.insert($0) }
            try modelContext.save()
            
            _ = try await service.createExportTask(config: config, dreams: dreams)
        }
        
        let tasks = try await service.getAllTasks()
        XCTAssertEqual(tasks.count, 3)
    }
    
    /// 测试删除任务
    func testDeleteTask() async throws {
        let config = AudioExportConfig(name: "测试配置")
        try await service.saveConfig(config)
        
        let dreams = createSampleDreams(count: 1)
        dreams.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        let task = try await service.createExportTask(config: config, dreams: dreams)
        
        var tasks = try await service.getAllTasks()
        XCTAssertEqual(tasks.count, 1)
        
        try await service.deleteTask(task)
        
        tasks = try await service.getAllTasks()
        XCTAssertEqual(tasks.count, 0)
    }
    
    // MARK: - Stats Tests
    
    /// 测试获取导出统计（空数据）
    func testGetExportStatsEmpty() async throws {
        let stats = try await service.getExportStats()
        
        XCTAssertEqual(stats.totalExports, 0)
        XCTAssertEqual(stats.totalDuration, 0)
        XCTAssertEqual(stats.totalFileSize, 0)
        XCTAssertEqual(stats.exportsByFormat.count, 0)
        XCTAssertEqual(stats.exportsByQuality.count, 0)
        XCTAssertNil(stats.lastExportDate)
    }
    
    /// 测试获取导出统计（有数据）
    func testGetExportStatsWithData() async throws {
        let config = AudioExportConfig(name: "测试配置")
        try await service.saveConfig(config)
        
        // 创建已完成的任务
        let task = AudioExportTask(
            configId: config.id,
            name: "测试任务",
            status: "completed",
            progress: 1.0,
            totalDreams: 5,
            processedDreams: 5,
            fileSize: 1024 * 1024 * 10, // 10MB
            duration: 300, // 5 分钟
            completedAt: Date()
        )
        modelContext.insert(task)
        try modelContext.save()
        
        let stats = try await service.getExportStats()
        
        XCTAssertEqual(stats.totalExports, 1)
        XCTAssertEqual(stats.totalDuration, 300)
        XCTAssertEqual(stats.totalFileSize, 1024 * 1024 * 10)
        XCTAssertEqual(stats.averageDuration, 300)
        XCTAssertEqual(stats.averageFileSize, 1024 * 1024 * 10)
    }
    
    // MARK: - Dreams Export Tests
    
    /// 测试获取全部梦境
    func testGetDreamsForExportAll() async throws {
        let dreams = createSampleDreams(count: 5)
        dreams.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        let exportedDreams = try await service.getDreamsForExport(range: .all)
        XCTAssertEqual(exportedDreams.count, 5)
    }
    
    /// 测试获取最近 7 天梦境
    func testGetDreamsForExportLast7Days() async throws {
        let calendar = Calendar.current
        
        // 创建 3 个最近 7 天的梦境
        for i in 0..<3 {
            let dream = Dream(
                title: "最近梦境 \(i)",
                content: "内容",
                date: calendar.date(byAdding: .day, value: -i, to: Date())!
            )
            modelContext.insert(dream)
        }
        
        // 创建 2 个 7 天前的梦境
        for i in 0..<2 {
            let dream = Dream(
                title: "旧梦境 \(i)",
                content: "内容",
                date: calendar.date(byAdding: .day, value: -(i + 8), to: Date())!
            )
            modelContext.insert(dream)
        }
        
        try modelContext.save()
        
        let exportedDreams = try await service.getDreamsForExport(range: .last7Days)
        XCTAssertEqual(exportedDreams.count, 3)
    }
    
    /// 测试获取最近 30 天梦境
    func testGetDreamsForExportLast30Days() async throws {
        let calendar = Calendar.current
        
        // 创建 5 个最近 30 天的梦境
        for i in 0..<5 {
            let dream = Dream(
                title: "最近梦境 \(i)",
                content: "内容",
                date: calendar.date(byAdding: .day, value: -i, to: Date())!
            )
            modelContext.insert(dream)
        }
        
        // 创建 3 个 30 天前的梦境
        for i in 0..<3 {
            let dream = Dream(
                title: "旧梦境 \(i)",
                content: "内容",
                date: calendar.date(byAdding: .day, value: -(i + 31), to: Date())!
            )
            modelContext.insert(dream)
        }
        
        try modelContext.save()
        
        let exportedDreams = try await service.getDreamsForExport(range: .last30Days)
        XCTAssertEqual(exportedDreams.count, 5)
    }
    
    /// 测试自定义日期范围导出
    func testGetDreamsForExportCustomRange() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate = calendar.date(byAdding: .day, value: -10, to: now)!
        let endDate = calendar.date(byAdding: .day, value: -5, to: now)!
        
        // 创建范围内的梦境
        for i in 0..<3 {
            let dream = Dream(
                title: "范围内梦境 \(i)",
                content: "内容",
                date: calendar.date(byAdding: .day, value: -(7 + i), to: now)!
            )
            modelContext.insert(dream)
        }
        
        // 创建范围外的梦境
        for i in 0..<2 {
            let dream = Dream(
                title: "范围外梦境 \(i)",
                content: "内容",
                date: calendar.date(byAdding: .day, value: -i, to: now)!
            )
            modelContext.insert(dream)
        }
        
        try modelContext.save()
        
        let exportedDreams = try await service.getDreamsForExport(
            range: .custom,
            customStartDate: startDate,
            customEndDate: endDate
        )
        XCTAssertEqual(exportedDreams.count, 3)
    }
    
    // MARK: - Format Tests
    
    /// 测试音频格式枚举
    func testAudioExportFormat() {
        XCTAssertEqual(AudioExportFormat.m4a.displayName, "M4A (推荐)")
        XCTAssertEqual(AudioExportFormat.mp3.displayName, "MP3")
        XCTAssertEqual(AudioExportFormat.wav.displayName, "WAV (无损)")
        
        XCTAssertEqual(AudioExportFormat.m4a.mimeType, "audio/mp4")
        XCTAssertEqual(AudioExportFormat.mp3.mimeType, "audio/mpeg")
        XCTAssertEqual(AudioExportFormat.wav.mimeType, "audio/wav")
    }
    
    /// 测试音频质量枚举
    func testAudioQuality() {
        XCTAssertEqual(AudioQuality.low.displayName, "标准 (64 kbps)")
        XCTAssertEqual(AudioQuality.medium.displayName, "高质量 (128 kbps)")
        XCTAssertEqual(AudioQuality.high.displayName, "最佳 (256 kbps)")
        XCTAssertEqual(AudioQuality.lossless.displayName, "无损 (WAV)")
        
        XCTAssertEqual(AudioQuality.low.bitRate, 64000)
        XCTAssertEqual(AudioQuality.medium.bitRate, 128000)
        XCTAssertEqual(AudioQuality.high.bitRate, 256000)
        XCTAssertEqual(AudioQuality.lossless.bitRate, 1411000)
    }
    
    /// 测试导出范围枚举
    func testAudioExportRange() {
        XCTAssertEqual(AudioExportRange.all.displayName, "全部梦境")
        XCTAssertEqual(AudioExportRange.last7Days.displayName, "最近 7 天")
        XCTAssertEqual(AudioExportRange.last30Days.displayName, "最近 30 天")
        XCTAssertEqual(AudioExportRange.custom.displayName, "自定义范围")
    }
    
    // MARK: - Preset Config Tests
    
    /// 测试预设配置数量
    func testPresetConfigsCount() {
        XCTAssertEqual(PresetAudioExportConfig.presets.count, 4)
    }
    
    /// 测试预设配置内容
    func testPresetConfigContent() {
        let quickShare = PresetAudioExportConfig.presets[0]
        XCTAssertEqual(quickShare.name, "快速分享")
        XCTAssertEqual(quickShare.format, .m4a)
        XCTAssertEqual(quickShare.quality, .low)
        XCTAssertFalse(quickShare.addBackgroundMusic)
        
        let podcast = PresetAudioExportConfig.presets[1]
        XCTAssertEqual(podcast.name, "高质量播客")
        XCTAssertEqual(podcast.format, .m4a)
        XCTAssertEqual(podcast.quality, .high)
        XCTAssertTrue(podcast.addBackgroundMusic)
        
        let lossless = PresetAudioExportConfig.presets[2]
        XCTAssertEqual(lossless.name, "无损存档")
        XCTAssertEqual(lossless.format, .wav)
        XCTAssertEqual(lossless.quality, .lossless)
        
        let sleep = PresetAudioExportConfig.presets[3]
        XCTAssertEqual(sleep.name, "睡眠回顾")
        XCTAssertTrue(sleep.addBackgroundMusic)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleDreams(count: Int) -> [Dream] {
        var dreams: [Dream] = []
        for i in 0..<count {
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "这是第 \(i) 个测试梦境的内容",
                date: Date()
            )
            dreams.append(dream)
        }
        return dreams
    }
}

// MARK: - Performance Tests

@available(iOS 17.0, *)
extension DreamAudioExportTests {
    
    /// 性能测试：创建大量配置
    func testPerformanceCreateConfigs() throws {
        self.measure {
            for i in 0..<100 {
                let config = AudioExportConfig(name: "配置 \(i)")
                modelContext.insert(config)
            }
            try? modelContext.save()
        }
    }
    
    /// 性能测试：查询大量任务
    func testPerformanceQueryTasks() async throws {
        // 创建测试数据
        let config = AudioExportConfig(name: "测试配置")
        modelContext.insert(config)
        try modelContext.save()
        
        for i in 0..<1000 {
            let task = AudioExportTask(
                configId: config.id,
                name: "任务 \(i)",
                status: "completed"
            )
            modelContext.insert(task)
        }
        try modelContext.save()
        
        // 性能测试
        self.measure {
            let expectation = self.expectation(description: "Query tasks")
            
            Task {
                _ = try? await service.getAllTasks()
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 10)
        }
    }
}
