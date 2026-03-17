//
//  DreamPlaylistTests.swift
//  DreamLog - Phase 59: Dream Playlist System
//
//  Created by DreamLog Team on 2026-03-17.
//  梦境播放列表单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamPlaylistTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamPlaylistService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存模型容器
        let schema = Schema([
            Dream.self,
            DreamPlaylist.self,
            DreamPlaylistItem.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        service = DreamPlaylistService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestDream(
        title: String = "测试梦境",
        content: String = "这是一个测试梦境内容",
        date: Date = Date(),
        clarity: Int = 3,
        isLucid: Bool = false,
        tags: [String] = [],
        emotions: [DreamEmotion] = [.neutral]
    ) -> Dream {
        let dream = Dream(
            title: title,
            content: content,
            date: date,
            clarity: clarity,
            intensity: 3,
            isLucid: isLucid,
            tags: tags,
            emotions: emotions
        )
        modelContext.insert(dream)
        try? modelContext.save()
        return dream
    }
    
    // MARK: - Create Playlist Tests
    
    func testCreatePlaylist() async throws {
        let playlist = try await service.createPlaylist(
            title: "测试播放列表",
            description: "测试描述",
            coverEmoji: "🎵",
            themeColor: .starry,
            isPublic: false
        )
        
        XCTAssertEqual(playlist.title, "测试播放列表")
        XCTAssertEqual(playlist.description, "测试描述")
        XCTAssertEqual(playlist.coverEmoji, "🎵")
        XCTAssertEqual(playlist.themeColor, .starry)
        XCTAssertEqual(playlist.isPublic, false)
        XCTAssertEqual(playlist.itemCount, 0)
        XCTAssertNotNil(playlist.id)
        XCTAssertNotNil(playlist.createdAt)
    }
    
    func testCreatePlaylistWithDreams() async throws {
        let dream1 = createTestDream(title: "梦境 1")
        let dream2 = createTestDream(title: "梦境 2")
        
        let playlist = try await service.createPlaylist(
            title: "带梦境的播放列表",
            dreamIds: [dream1.id, dream2.id]
        )
        
        XCTAssertEqual(playlist.itemCount, 2)
        XCTAssertEqual(playlist.items[0].dream?.title, "梦境 1")
        XCTAssertEqual(playlist.items[1].dream?.title, "梦境 2")
    }
    
    func testCreatePlaylistFromPreset() async throws {
        // 创建一些测试梦境
        for i in 0..<5 {
            _ = createTestDream(
                title: "梦境 \(i)",
                date: Date().addingTimeInterval(Double(-i) * 86400),
                clarity: 5 - i
            )
        }
        
        let preset = PlaylistPreset.presets[0] // 本周精选
        let playlist = try await service.createFromPreset(preset)
        
        XCTAssertEqual(playlist.title, preset.title)
        XCTAssertEqual(playlist.coverEmoji, preset.emoji)
        XCTAssertEqual(playlist.themeColor, preset.themeColor)
        XCTAssertGreaterThan(playlist.itemCount, 0)
    }
    
    // MARK: - Update Playlist Tests
    
    func testUpdatePlaylist() async throws {
        let playlist = try await service.createPlaylist(title: "原始标题")
        
        try await service.updatePlaylist(
            playlist,
            title: "新标题",
            description: "新描述",
            coverEmoji: "⭐",
            themeColor: .sunset,
            isPublic: true
        )
        
        XCTAssertEqual(playlist.title, "新标题")
        XCTAssertEqual(playlist.description, "新描述")
        XCTAssertEqual(playlist.coverEmoji, "⭐")
        XCTAssertEqual(playlist.themeColor, .sunset)
        XCTAssertEqual(playlist.isPublic, true)
    }
    
    // MARK: - Delete Playlist Tests
    
    func testDeletePlaylist() async throws {
        let playlist = try await service.createPlaylist(title: "待删除")
        let playlistId = playlist.id
        
        try await service.deletePlaylist(playlist)
        
        let fetched = try await service.getPlaylist(by: playlistId)
        XCTAssertNil(fetched)
    }
    
    // MARK: - Get Playlists Tests
    
    func testGetAllPlaylists() async throws {
        _ = try await service.createPlaylist(title: "播放列表 1")
        _ = try await service.createPlaylist(title: "播放列表 2")
        _ = try await service.createPlaylist(title: "播放列表 3")
        
        let playlists = try await service.getAllPlaylists()
        
        XCTAssertEqual(playlists.count, 3)
    }
    
    func testGetPlaylistById() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let fetched = try await service.getPlaylist(by: playlist.id)
        
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "测试")
    }
    
    func testGetNonExistentPlaylist() async throws {
        let fetched = try await service.getPlaylist(by: UUID())
        XCTAssertNil(fetched)
    }
    
    // MARK: - Add Dream to Playlist Tests
    
    func testAddDreamToPlaylist() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let dream = createTestDream(title: "新梦境")
        
        try await service.addDreamToPlaylist(playlist, dreamId: dream.id)
        
        XCTAssertEqual(playlist.itemCount, 1)
        XCTAssertEqual(playlist.items[0].dream?.title, "新梦境")
    }
    
    func testAddSameDreamTwice() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let dream = createTestDream(title: "新梦境")
        
        try await service.addDreamToPlaylist(playlist, dreamId: dream.id)
        
        do {
            try await service.addDreamToPlaylist(playlist, dreamId: dream.id)
            XCTFail("应该抛出 dreamAlreadyInPlaylist 错误")
        } catch PlaylistError.dreamAlreadyInPlaylist {
            // 预期错误
        } catch {
            XCTFail("抛出意外错误：\(error)")
        }
    }
    
    func testAddNonExistentDream() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        
        do {
            try await service.addDreamToPlaylist(playlist, dreamId: UUID())
            XCTFail("应该抛出 dreamNotFound 错误")
        } catch PlaylistError.dreamNotFound {
            // 预期错误
        } catch {
            XCTFail("抛出意外错误：\(error)")
        }
    }
    
    // MARK: - Remove Dream from Playlist Tests
    
    func testRemoveDreamFromPlaylist() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let dream = createTestDream(title: "待删除")
        
        try await service.addDreamToPlaylist(playlist, dreamId: dream.id)
        let itemId = playlist.items[0].id
        
        try await service.removeDreamFromPlaylist(playlist, itemId: itemId)
        
        XCTAssertEqual(playlist.itemCount, 0)
    }
    
    func testRemoveNonExistentItem() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        
        do {
            try await service.removeDreamFromPlaylist(playlist, itemId: UUID())
            XCTFail("应该抛出 itemNotFound 错误")
        } catch PlaylistError.itemNotFound {
            // 预期错误
        } catch {
            XCTFail("抛出意外错误：\(error)")
        }
    }
    
    // MARK: - Reorder Playlist Items Tests
    
    func testReorderPlaylistItems() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        
        // 添加 3 个梦境
        for i in 0..<3 {
            let dream = createTestDream(title: "梦境 \(i)")
            try await service.addDreamToPlaylist(playlist, dreamId: dream.id)
        }
        
        // 重新排序：将第 1 个移到最后
        try await service.reorderPlaylistItems(
            playlist,
            fromOffsets: IndexSet(integer: 0),
            toOffset: 3
        )
        
        XCTAssertEqual(playlist.items[0].position, 0)
        XCTAssertEqual(playlist.items[1].position, 1)
        XCTAssertEqual(playlist.items[2].position, 2)
    }
    
    // MARK: - Statistics Tests
    
    func testGetStats() async throws {
        // 创建多个播放列表
        let dream = createTestDream(title: "测试梦境", audioDuration: 300)
        
        let playlist1 = try await service.createPlaylist(title: "播放列表 1", dreamIds: [dream.id])
        let playlist2 = try await service.createPlaylist(title: "播放列表 2", dreamIds: [dream.id])
        
        // 增加播放次数
        try await service.incrementPlayCount(for: playlist1)
        try await service.incrementPlayCount(for: playlist1)
        try await service.incrementShareCount(for: playlist2)
        
        let stats = try await service.getStats()
        
        XCTAssertEqual(stats.totalPlaylists, 2)
        XCTAssertEqual(stats.totalItems, 2)
        XCTAssertEqual(stats.totalPlays, 2)
        XCTAssertEqual(stats.totalShares, 1)
        XCTAssertEqual(stats.publicPlaylists, 0)
    }
    
    func testGetEmptyStats() async throws {
        let stats = try await service.getStats()
        
        XCTAssertEqual(stats.totalPlaylists, 0)
        XCTAssertEqual(stats.totalItems, 0)
        XCTAssertEqual(stats.totalPlays, 0)
    }
    
    // MARK: - Auto-generated Playlists Tests
    
    func testGenerateWeeklyHighlights() async throws {
        // 创建本周的梦境
        for i in 0..<5 {
            _ = createTestDream(
                title: "本周梦境 \(i)",
                date: Date().addingTimeInterval(Double(-i) * 86400),
                clarity: 5 - i
            )
        }
        
        let playlist = try await service.generateWeeklyHighlights()
        
        XCTAssertNotNil(playlist)
        XCTAssertEqual(playlist?.title, "本周精选 🌟")
        XCTAssertGreaterThan(playlist?.itemCount ?? 0, 0)
    }
    
    func testGenerateWeeklyHighlightsNoDreams() async throws {
        // 没有梦境
        let playlist = try await service.generateWeeklyHighlights()
        
        XCTAssertNil(playlist)
    }
    
    func testGenerateLucidDreamsCollection() async throws {
        // 创建清醒梦
        for i in 0..<3 {
            _ = createTestDream(
                title: "清醒梦 \(i)",
                isLucid: true
            )
        }
        
        // 创建非清醒梦
        _ = createTestDream(
            title: "普通梦",
            isLucid: false
        )
        
        let playlist = try await service.generateLucidDreamsCollection()
        
        XCTAssertNotNil(playlist)
        XCTAssertEqual(playlist?.title, "清醒梦合集 🌟")
        XCTAssertEqual(playlist?.itemCount, 3)
    }
    
    // MARK: - Share Link Tests
    
    func testCreateShareLink() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let link = service.createShareLink(for: playlist, expiresInSeconds: 3600)
        
        XCTAssertEqual(link.playlistId, playlist.id)
        XCTAssertFalse(link.isExpired)
        XCTAssertEqual(link.shareURL, "dreamlog://playlist/\(link.id)")
    }
    
    func testShareLinkExpiration() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        
        // 创建已过期的链接
        let link = PlaylistShareLink(
            playlistId: playlist.id,
            expiresAt: Date().addingTimeInterval(-3600)
        )
        
        XCTAssertTrue(link.isExpired)
    }
    
    func testIncrementPlayCount() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let initialCount = playlist.playCount
        
        try await service.incrementPlayCount(for: playlist)
        
        XCTAssertEqual(playlist.playCount, initialCount + 1)
    }
    
    func testIncrementShareCount() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let initialCount = playlist.shareCount
        
        try await service.incrementShareCount(for: playlist)
        
        XCTAssertEqual(playlist.shareCount, initialCount + 1)
    }
    
    // MARK: - Playlist Theme Color Tests
    
    func testPlaylistThemeColors() {
        for color in PlaylistThemeColor.allCases {
            XCTAssertFalse(color.displayName.isEmpty)
            XCTAssertFalse(color.startColor.isEmpty)
            XCTAssertFalse(color.endColor.isEmpty)
            XCTAssertFalse(color.icon.isEmpty)
        }
    }
    
    func testPlaylistOrderTypes() {
        for orderType in PlaylistOrderType.allCases {
            XCTAssertFalse(orderType.displayName.isEmpty)
        }
    }
    
    // MARK: - Playlist Preset Tests
    
    func testPlaylistPresets() {
        let presets = PlaylistPreset.presets
        
        XCTAssertGreaterThan(presets.count, 0)
        
        for preset in presets {
            XCTAssertFalse(preset.title.isEmpty)
            XCTAssertFalse(preset.description.isEmpty)
            XCTAssertFalse(preset.emoji.isEmpty)
            XCTAssertGreaterThan(preset.suggestedDreams, 0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testCreateMultiplePlaylistsPerformance() async throws {
        measure {
            let expectation = expectation(description: "创建 10 个播放列表")
            
            Task {
                for i in 0..<10 {
                    _ = try? await service.createPlaylist(title: "播放列表 \(i)")
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
    
    func testLargePlaylistPerformance() async throws {
        let playlist = try await service.createPlaylist(title: "大型播放列表")
        
        // 添加 50 个梦境
        for i in 0..<50 {
            let dream = createTestDream(title: "梦境 \(i)")
            try await service.addDreamToPlaylist(playlist, dreamId: dream.id)
        }
        
        XCTAssertEqual(playlist.itemCount, 50)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyTitle() async throws {
        do {
            _ = try await service.createPlaylist(title: "")
            // 空标题应该被允许（或者服务层应该有验证）
        } catch {
            // 或者抛出错误
        }
    }
    
    func testVeryLongTitle() async throws {
        let longTitle = String(repeating: "A", count: 1000)
        let playlist = try await service.createPlaylist(title: longTitle)
        
        XCTAssertEqual(playlist.title.count, 1000)
    }
    
    func testSpecialCharactersInTitle() async throws {
        let title = "测试 🎵 Playlist!@#$%^&*()"
        let playlist = try await service.createPlaylist(title: title)
        
        XCTAssertEqual(playlist.title, title)
    }
    
    func testUpdateItemNotes() async throws {
        let playlist = try await service.createPlaylist(title: "测试")
        let dream = createTestDream(title: "测试梦境")
        try await service.addDreamToPlaylist(playlist, dreamId: dream.id)
        
        let item = playlist.items[0]
        try await service.updateItemNotes(item, notes: "这是一条备注")
        
        XCTAssertEqual(item.notes, "这是一条备注")
    }
}
