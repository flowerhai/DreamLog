//
//  DreamExportGalleryTests.swift
//  DreamLog - 梦境导出画廊单元测试
//
//  Phase 75: 梦境导出画廊
//  统一管理所有导出内容 (PDF/音频/视频/分享卡片)
//

import Testing
import Foundation
import SwiftData

@Suite("梦境导出画廊测试")
struct DreamExportGalleryTests {
    
    // MARK: - 数据模型测试
    
    @Test("导出类型枚举测试")
    func testExportTypeCases() async throws {
        let allTypes = DreamExportType.allCases
        
        #expect(allTypes.count == 6)
        #expect(allTypes.contains(.pdf))
        #expect(allTypes.contains(.audio))
        #expect(allTypes.contains(.video))
        #expect(allTypes.contains(.shareCard))
        #expect(allTypes.contains(.arScene))
        #expect(allTypes.contains(.story))
    }
    
    @Test("导出类型显示名称测试")
    func testExportTypeDisplayNames() async throws {
        #expect(DreamExportType.pdf.displayName == "📕 PDF 日记")
        #expect(DreamExportType.audio.displayName == "🎙️ 音频播客")
        #expect(DreamExportType.video.displayName == "🎬 梦境视频")
        #expect(DreamExportType.shareCard.displayName == "🎴 分享卡片")
        #expect(DreamExportType.arScene.displayName == "🥽 AR 场景")
        #expect(DreamExportType.story.displayName == "📖 梦境 故事")
    }
    
    @Test("导出项模型初始化测试")
    func testExportItemInitialization() async throws {
        let item = DreamExportItem(
            type: .pdf,
            title: "测试导出",
            description: "测试描述",
            fileSize: 1024 * 1024, // 1MB
            dreamCount: 5
        )
        
        #expect(item.type == .pdf)
        #expect(item.title == "测试导出")
        #expect(item.description == "测试描述")
        #expect(item.fileSize == 1024 * 1024)
        #expect(item.dreamCount == 5)
        #expect(item.isFavorite == false)
        #expect(item.shareCount == 0)
        #expect(item.viewCount == 0)
    }
    
    @Test("导出项文件大小格式化测试")
    func testExportItemFileSizeFormatting() async throws {
        let item1 = DreamExportItem(type: .pdf, title: "小文件", fileSize: 1024) // 1KB
        let item2 = DreamExportItem(type: .pdf, title: "中文件", fileSize: 1024 * 1024) // 1MB
        let item3 = DreamExportItem(type: .pdf, title: "大文件", fileSize: 1024 * 1024 * 100) // 100MB
        
        #expect(item1.formattedFileSize.contains("KB"))
        #expect(item2.formattedFileSize.contains("MB"))
        #expect(item3.formattedFileSize.contains("MB"))
    }
    
    @Test("导出项时长格式化测试")
    func testExportItemDurationFormatting() async throws {
        let item1 = DreamExportItem(type: .audio, title: "短音频", duration: 30) // 30 秒
        let item2 = DreamExportItem(type: .audio, title: "长音频", duration: 150) // 2 分 30 秒
        
        #expect(item1.formattedDuration == "30 秒")
        #expect(item2.formattedDuration == "2 分 30 秒")
    }
    
    @Test("导出项日期格式化测试")
    func testExportItemDateFormatting() async throws {
        let item = DreamExportItem(type: .pdf, title: "测试", exportDate: Date())
        
        #expect(!item.formattedExportDate.isEmpty)
        #expect(item.formattedExportDate.contains("年") || item.formattedExportDate.contains("/"))
    }
    
    // MARK: - 统计模型测试
    
    @Test("导出统计初始化测试")
    func testExportStatsInitialization() async throws {
        let stats = DreamExportStats(
            totalExports: 10,
            totalFileSize: 1024 * 1024 * 50,
            totalShareCount: 25,
            totalViewCount: 100
        )
        
        #expect(stats.totalExports == 10)
        #expect(stats.totalShareCount == 25)
        #expect(stats.totalViewCount == 100)
        #expect(!stats.storageUsage.isEmpty)
    }
    
    @Test("字节格式化测试")
    func testByteFormatting() async throws {
        #expect(DreamExportStats.formatBytes(1024).contains("KB"))
        #expect(DreamExportStats.formatBytes(1024 * 1024).contains("MB"))
        #expect(DreamExportStats.formatBytes(1024 * 1024 * 1024).contains("GB"))
    }
    
    // MARK: - 筛选选项测试
    
    @Test("筛选选项初始化测试")
    func testFilterInitialization() async throws {
        let filter = ExportGalleryFilter()
        
        #expect(filter.type == nil)
        #expect(filter.searchText.isEmpty)
        #expect(filter.sortBy == .dateDesc)
    }
    
    @Test("排序选项枚举测试")
    func testSortOptionCases() async throws {
        let allOptions = ExportGalleryFilter.ExportSortOption.allCases
        
        #expect(allOptions.count == 6)
        #expect(allOptions.contains(.dateDesc))
        #expect(allOptions.contains(.sharesDesc))
    }
    
    @Test("排序选项显示名称测试")
    func testSortOptionDisplayNames() async throws {
        #expect(ExportGalleryFilter.ExportSortOption.dateDesc.displayName == "最新导出")
        #expect(ExportGalleryFilter.ExportSortOption.sharesDesc.displayName == "分享次数")
        #expect(ExportGalleryFilter.ExportSortOption.viewsDesc.displayName == "浏览次数")
    }
    
    // MARK: - 导出建议测试
    
    @Test("导出建议模型测试")
    func testExportSuggestion() async throws {
        let suggestion = ExportSuggestion(
            type: .firstExport,
            title: "创建第一个导出",
            description: "尝试导出你的梦境",
            icon: "doc.badge.plus"
        )
        
        #expect(suggestion.title == "创建第一个导出")
        #expect(suggestion.icon == "doc.badge.plus")
    }
    
    @Test("建议类型枚举测试")
    func testSuggestionTypeCases() async throws {
        let types: [ExportSuggestion.SuggestionType] = [
            .firstExport,
            .moreExports,
            .cleanup,
            .reviewFavorites,
            .shareMore,
            .tryNewFormat
        ]
        
        #expect(types.count == 6)
    }
    
    // MARK: - 错误类型测试
    
    @Test("导出错误描述测试")
    func testExportErrorDescriptions() async throws {
        #expect(ExportGalleryError.fileNotFound.errorDescription == "文件未找到")
        #expect(ExportGalleryError.invalidFormat.errorDescription == "文件格式无效")
        #expect(ExportGalleryError.storageFull.errorDescription == "存储空间不足")
        
        let customError = ExportGalleryError.exportFailed("测试原因")
        #expect(customError.errorDescription?.contains("测试原因") == true)
    }
    
    // MARK: - 服务层测试 (需要 ModelContext)
    
    @Test("服务初始化测试")
    func testServiceInitialization() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        
        let service = DreamExportGalleryService(modelContext: context)
        
        #expect(service.exportDirectory.contains("Exports"))
        #expect(service.thumbnailDirectory.contains("Thumbnails"))
    }
    
    @Test("创建导出项测试")
    func testCreateExportItem() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        let item = DreamExportItem(
            type: .pdf,
            title: "测试导出",
            description: "测试描述"
        )
        
        try await service.createExport(item)
        
        let exports = await service.getAllExports()
        #expect(exports.count == 1)
        #expect(exports.first?.title == "测试导出")
    }
    
    @Test("获取所有导出测试")
    func testGetAllExports() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        // 创建多个导出项
        for i in 1...5 {
            let item = DreamExportItem(
                type: i % 2 == 0 ? .pdf : .audio,
                title: "导出 \(i)",
                fileSize: Int64(i * 1024)
            )
            try await service.createExport(item)
        }
        
        let exports = await service.getAllExports()
        #expect(exports.count == 5)
    }
    
    @Test("按类型筛选导出测试")
    func testFilterExportsByType() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        // 创建不同类型导出
        let pdfItem = DreamExportItem(type: .pdf, title: "PDF 导出")
        let audioItem = DreamExportItem(type: .audio, title: "音频导出")
        
        try await service.createExport(pdfItem)
        try await service.createExport(audioItem)
        
        // 按 PDF 筛选
        var filter = ExportGalleryFilter()
        filter.type = .pdf
        let pdfExports = await service.getAllExports(filter: filter)
        #expect(pdfExports.count == 1)
        #expect(pdfExports.first?.type == .pdf)
        
        // 按音频筛选
        filter.type = .audio
        let audioExports = await service.getAllExports(filter: filter)
        #expect(audioExports.count == 1)
        #expect(audioExports.first?.type == .audio)
    }
    
    @Test("收藏切换测试")
    func testToggleFavorite() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        let item = DreamExportItem(type: .pdf, title: "测试")
        try await service.createExport(item)
        
        // 初始不是收藏
        #expect(item.isFavorite == false)
        
        // 切换收藏
        try await service.toggleFavorite(item)
        #expect(item.isFavorite == true)
        
        // 再次切换
        try await service.toggleFavorite(item)
        #expect(item.isFavorite == false)
    }
    
    @Test("分享计数增加测试")
    func testIncrementShareCount() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        let item = DreamExportItem(type: .pdf, title: "测试", shareCount: 0)
        try await service.createExport(item)
        
        try await service.incrementShareCount(item)
        #expect(item.shareCount == 1)
        #expect(item.lastSharedDate != nil)
        
        try await service.incrementShareCount(item)
        #expect(item.shareCount == 2)
    }
    
    @Test("浏览计数增加测试")
    func testIncrementViewCount() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        let item = DreamExportItem(type: .pdf, title: "测试", viewCount: 0)
        try await service.createExport(item)
        
        try await service.incrementViewCount(item)
        #expect(item.viewCount == 1)
    }
    
    @Test("获取统计测试")
    func testGetExportStats() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        // 初始统计
        var stats = await service.getExportStats()
        #expect(stats.totalExports == 0)
        
        // 添加导出
        for i in 1...3 {
            let item = DreamExportItem(
                type: .pdf,
                title: "导出 \(i)",
                fileSize: 1024 * 100,
                shareCount: i,
                viewCount: i * 10
            )
            try await service.createExport(item)
        }
        
        stats = await service.getExportStats()
        #expect(stats.totalExports == 3)
        #expect(stats.totalShareCount == 6) // 1+2+3
        #expect(stats.totalViewCount == 60) // 10+20+30
    }
    
    @Test("删除导出项测试")
    func testDeleteExportItem() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        let item = DreamExportItem(type: .pdf, title: "测试删除")
        try await service.createExport(item)
        
        var exports = await service.getAllExports()
        #expect(exports.count == 1)
        
        try await service.deleteExport(item)
        
        exports = await service.getAllExports()
        #expect(exports.count == 0)
    }
    
    @Test("搜索导出测试")
    func testSearchExports() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        // 创建带不同标题的导出
        let item1 = DreamExportItem(type: .pdf, title: "梦境日记", tags: ["梦", "日记"])
        let item2 = DreamExportItem(type: .audio, title: "冥想音频", tags: ["冥想", "放松"])
        let item3 = DreamExportItem(type: .video, title: "梦境视频", tags: ["梦", "视频"])
        
        try await service.createExport(item1)
        try await service.createExport(item2)
        try await service.createExport(item3)
        
        // 搜索"梦"
        var filter = ExportGalleryFilter()
        filter.searchText = "梦"
        var results = await service.getAllExports(filter: filter)
        #expect(results.count == 2) // 梦境日记 + 梦境视频
        
        // 搜索"冥想"
        filter.searchText = "冥想"
        results = await service.getAllExports(filter: filter)
        #expect(results.count == 1)
        #expect(results.first?.title == "冥想音频")
    }
    
    @Test("排序导出测试")
    func testSortExports() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        // 创建不同大小的导出
        let item1 = DreamExportItem(type: .pdf, title: "小文件", fileSize: 1024)
        let item2 = DreamExportItem(type: .pdf, title: "中文件", fileSize: 1024 * 10)
        let item3 = DreamExportItem(type: .pdf, title: "大文件", fileSize: 1024 * 100)
        
        try await service.createExport(item1)
        try await service.createExport(item2)
        try await service.createExport(item3)
        
        // 按大小降序
        var filter = ExportGalleryFilter()
        filter.sortBy = .sizeDesc
        var results = await service.getAllExports(filter: filter)
        #expect(results[0].title == "大文件")
        #expect(results[2].title == "小文件")
        
        // 按标题升序
        filter.sortBy = .titleAsc
        results = await service.getAllExports(filter: filter)
        #expect(results[0].title == "中文件") // 中 < 大 < 小 (中文拼音)
    }
}

// MARK: - 性能测试

@Suite("导出画廊性能测试")
struct DreamExportGalleryPerformanceTests {
    
    @Test("大量导出项加载性能")
    func testLargeExportLoadPerformance() async throws {
        let container = try ModelContainer(for: DreamExportItem.self, inMemory: true)
        let context = ModelContext(container)
        let service = DreamExportGalleryService(modelContext: context)
        
        // 创建 100 个导出项
        for i in 1...100 {
            let item = DreamExportItem(
                type: DreamExportType.allCases[i % 6],
                title: "导出 \(i)",
                fileSize: Int64(i * 1024),
                dreamCount: i % 10
            )
            try await service.createExport(item)
        }
        
        let startTime = Date()
        let exports = await service.getAllExports()
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(exports.count == 100)
        #expect(duration < 1.0) // 应在 1 秒内完成
    }
}
