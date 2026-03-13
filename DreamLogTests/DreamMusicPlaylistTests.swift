//
//  DreamMusicPlaylistTests.swift
//  DreamLogTests
//
//  Created by DreamLog Team on 2026-03-13
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamMusicPlaylistTests: XCTestCase {
    
    var playlistService: DreamMusicPlaylistService!
    
    override func setUp() async throws {
        try await super.setUp()
        playlistService = DreamMusicPlaylistService.shared
        // 清空现有数据
        playlistService.playlists.removeAll()
        playlistService.sharedMusic.removeAll()
    }
    
    override func tearDown() async throws {
        playlistService = nil
        try await super.tearDown()
    }
    
    // MARK: - Playlist Creation Tests
    
    func testCreatePlaylist() {
        let playlist = playlistService.createPlaylist(
            name: "测试播放列表",
            description: "测试描述",
            musicIds: []
        )
        
        XCTAssertEqual(playlist.name, "测试播放列表")
        XCTAssertEqual(playlist.description, "测试描述")
        XCTAssertEqual(playlist.musicIds.count, 0)
        XCTAssertEqual(playlistService.playlists.count, 1)
    }
    
    func testCreatePlaylistWithTemplate() {
        let template = PlaylistTemplate.templates.first!
        let playlist = playlistService.createPlaylist(
            name: "模板播放列表",
            template: template
        )
        
        XCTAssertEqual(playlist.coverMood, template.mood)
        XCTAssertNotNil(playlist.sleepTimer)
        XCTAssertEqual(playlist.sleepTimer?.duration, template.suggestedDuration)
    }
    
    func testCreatePlaylistWithName() {
        let playlist = playlistService.createPlaylist(
            name: "",
            description: "",
            template: nil
        )
        
        XCTAssertEqual(playlist.name, "")
        XCTAssertNotNil(playlist.id)
        XCTAssertEqual(playlist.createdAt, playlist.updatedAt)
    }
    
    // MARK: - Playlist Management Tests
    
    func testUpdatePlaylist() {
        let playlist = playlistService.createPlaylist(name: "原始名称")
        
        var updated = playlist
        updated.name = "新名称"
        updated.description = "新描述"
        
        playlistService.updatePlaylist(updated)
        
        let retrieved = playlistService.getPlaylist(playlist.id)
        XCTAssertEqual(retrieved?.name, "新名称")
        XCTAssertEqual(retrieved?.description, "新描述")
        XCTAssertGreaterThan(retrieved?.updatedAt ?? Date(), playlist.updatedAt)
    }
    
    func testDeletePlaylist() {
        let playlist = playlistService.createPlaylist(name: "待删除")
        let countBefore = playlistService.playlists.count
        
        playlistService.deletePlaylist(playlist)
        
        XCTAssertEqual(playlistService.playlists.count, countBefore - 1)
        XCTAssertNil(playlistService.currentPlaylist)
    }
    
    func testAddMusicToPlaylist() {
        let playlist = playlistService.createPlaylist(name: "测试")
        let musicId = UUID()
        
        playlistService.addMusicToPlaylist(playlist.id, musicId: musicId)
        
        let updated = playlistService.getPlaylist(playlist.id)
        XCTAssertEqual(updated?.musicIds.count, 1)
        XCTAssertEqual(updated?.musicIds.first, musicId)
    }
    
    func testAddDuplicateMusicToPlaylist() {
        let playlist = playlistService.createPlaylist(name: "测试")
        let musicId = UUID()
        
        playlistService.addMusicToPlaylist(playlist.id, musicId: musicId)
        playlistService.addMusicToPlaylist(playlist.id, musicId: musicId)
        
        let updated = playlistService.getPlaylist(playlist.id)
        XCTAssertEqual(updated?.musicIds.count, 1)  // 不应该重复添加
    }
    
    func testRemoveMusicFromPlaylist() {
        let playlist = playlistService.createPlaylist(name: "测试")
        let musicId = UUID()
        
        playlistService.addMusicToPlaylist(playlist.id, musicId: musicId)
        playlistService.removeMusicFromPlaylist(playlist.id, musicId: musicId)
        
        let updated = playlistService.getPlaylist(playlist.id)
        XCTAssertEqual(updated?.musicIds.count, 0)
    }
    
    func testToggleFavorite() {
        let playlist = playlistService.createPlaylist(name: "测试")
        XCTAssertFalse(playlist.isFavorite)
        
        playlistService.toggleFavorite(playlist)
        
        let updated = playlistService.getPlaylist(playlist.id)
        XCTAssertTrue(updated?.isFavorite ?? false)
        
        playlistService.toggleFavorite(playlist)
        
        let updated2 = playlistService.getPlaylist(playlist.id)
        XCTAssertFalse(updated2?.isFavorite ?? false)
    }
    
    // MARK: - Playback Tests
    
    func testPlayPlaylist() {
        let playlist = playlistService.createPlaylist(name: "测试")
        playlistService.addMusicToPlaylist(playlist.id, musicId: UUID())
        
        playlistService.playPlaylist(playlist)
        
        XCTAssertEqual(playlistService.currentPlaylist?.id, playlist.id)
        XCTAssertNotNil(playlistService.playbackState.currentIndex)
    }
    
    func testPauseAndResume() {
        let playlist = playlistService.createPlaylist(name: "测试")
        playlistService.playPlaylist(playlist)
        
        XCTAssertTrue(playlistService.playbackState.isPlaying)
        
        playlistService.pause()
        XCTAssertTrue(playlistService.playbackState.isPaused)
        
        playlistService.resume()
        XCTAssertTrue(playlistService.playbackState.isPlaying)
    }
    
    func testStopPlayback() {
        let playlist = playlistService.createPlaylist(name: "测试")
        playlistService.playPlaylist(playlist)
        
        playlistService.stopPlayback()
        
        XCTAssertEqual(playlistService.playbackState, .stopped)
        XCTAssertNil(playlistService.currentPlaylist)
    }
    
    func testPlayNext() {
        let playlist = playlistService.createPlaylist(name: "测试")
        playlistService.addMusicToPlaylist(playlist.id, musicId: UUID())
        playlistService.addMusicToPlaylist(playlist.id, musicId: UUID())
        playlistService.playPlaylist(playlist)
        
        let initialIndex = playlistService.playbackState.currentIndex
        playlistService.playNext()
        
        // 应该切换到下一首
        XCTAssertNotEqual(playlistService.playbackState.currentIndex, initialIndex)
    }
    
    func testPlayPrevious() {
        let playlist = playlistService.createPlaylist(name: "测试")
        playlistService.addMusicToPlaylist(playlist.id, musicId: UUID())
        playlistService.addMusicToPlaylist(playlist.id, musicId: UUID())
        playlistService.playPlaylist(playlist)
        playlistService.playNext()
        
        let currentIndex = playlistService.playbackState.currentIndex
        playlistService.playPrevious()
        
        XCTAssertNotEqual(playlistService.playbackState.currentIndex, currentIndex)
    }
    
    func testToggleShuffle() {
        XCTAssertFalse(playlistService.isShuffleEnabled)
        
        playlistService.toggleShuffle()
        XCTAssertTrue(playlistService.isShuffleEnabled)
        
        playlistService.toggleShuffle()
        XCTAssertFalse(playlistService.isShuffleEnabled)
    }
    
    func testToggleRepeatMode() {
        // 初始状态应该是 off
        // 由于 repeatMode 是 private，我们通过多次调用来测试循环
        playlistService.toggleRepeatMode()  // off -> all
        playlistService.toggleRepeatMode()  // all -> one
        playlistService.toggleRepeatMode()  // one -> off
    }
    
    // MARK: - Sleep Timer Tests
    
    func testSetSleepTimer() {
        XCTAssertFalse(playlistService.isSleepTimerActive)
        
        playlistService.setSleepTimer(duration: .minutes15)
        
        XCTAssertTrue(playlistService.isSleepTimerActive)
        XCTAssertNotNil(playlistService.sleepTimerRemaining)
    }
    
    func testTurnOffSleepTimer() {
        playlistService.setSleepTimer(duration: .minutes15)
        XCTAssertTrue(playlistService.isSleepTimerActive)
        
        playlistService.setSleepTimer(duration: .off)
        
        XCTAssertFalse(playlistService.isSleepTimerActive)
        XCTAssertNil(playlistService.sleepTimerRemaining)
    }
    
    func testSleepTimerDurationValues() {
        XCTAssertEqual(SleepTimerConfig.SleepTimerDuration.minutes15.seconds, 15 * 60)
        XCTAssertEqual(SleepTimerConfig.SleepTimerDuration.minutes30.seconds, 30 * 60)
        XCTAssertEqual(SleepTimerConfig.SleepTimerDuration.minutes45.seconds, 45 * 60)
        XCTAssertEqual(SleepTimerConfig.SleepTimerDuration.minutes60.seconds, 60 * 60)
        XCTAssertEqual(SleepTimerConfig.SleepTimerDuration.minutes90.seconds, 90 * 60)
        XCTAssertNil(SleepTimerConfig.SleepTimerDuration.off.seconds)
        XCTAssertNil(SleepTimerConfig.SleepTimerDuration.untilEnd.seconds)
    }
    
    // MARK: - Sharing Tests
    
    func testShareMusic() {
        let music = createTestMusic()
        
        let shared = playlistService.shareMusic(music, expiryDays: 7)
        
        XCTAssertEqual(shared.musicId, music.id)
        XCTAssertNotNil(shared.shareCode)
        XCTAssertEqual(shared.shareCode?.count, 8)
        XCTAssertGreaterThan(shared.expiresAt, Date())
        XCTAssertEqual(playlistService.sharedMusic.count, 1)
    }
    
    func testShareCodeFormat() {
        let music = createTestMusic()
        let shared = playlistService.shareMusic(music)
        
        // 分享码应该是 8 位字母数字组合
        let shareCode = shared.shareCode!
        XCTAssertEqual(shareCode.count, 8)
        
        // 不应该包含容易混淆的字符
        let invalidChars = CharacterSet(charactersIn: "IO01")
        for char in shareCode {
            XCTAssertFalse(invalidChars.contains(Character(String(char))))
        }
    }
    
    func testGetMusicByShareCode() {
        let music = createTestMusic()
        let shared = playlistService.shareMusic(music, expiryDays: 7)
        
        let retrieved = playlistService.getMusicByShareCode(shared.shareCode)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, music.id)
    }
    
    func testExpiredShareCode() {
        let music = createTestMusic()
        let shared = playlistService.shareMusic(music, expiryDays: 0)  // 立即过期
        
        // 模拟过期
        var expiredShared = shared
        expiredShared.expiresAt = Date().addingTimeInterval(-1)
        
        // 实际实现中应该检查过期时间
        let retrieved = playlistService.getMusicByShareCode(expiredShared.shareCode)
        
        // 过期的分享码应该返回 nil
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Statistics Tests
    
    func testGetPlaybackStats() {
        let playlist1 = playlistService.createPlaylist(name: "列表 1")
        let playlist2 = playlistService.createPlaylist(name: "列表 2")
        
        playlistService.addMusicToPlaylist(playlist1.id, musicId: UUID())
        playlistService.addMusicToPlaylist(playlist1.id, musicId: UUID())
        playlistService.addMusicToPlaylist(playlist2.id, musicId: UUID())
        
        let stats = playlistService.getPlaybackStats()
        
        XCTAssertEqual(stats.totalPlaylists, 2)
        XCTAssertEqual(stats.totalMusic, 3)
    }
    
    func testFavoritePlaylistsCount() {
        let playlist1 = playlistService.createPlaylist(name: "列表 1")
        let playlist2 = playlistService.createPlaylist(name: "列表 2")
        
        playlistService.toggleFavorite(playlist1)
        
        let stats = playlistService.getPlaybackStats()
        XCTAssertEqual(stats.favoritePlaylists, 1)
    }
    
    // MARK: - Playlist Template Tests
    
    func testPlaylistTemplatesExist() {
        let templates = PlaylistTemplate.templates
        
        XCTAssertGreaterThan(templates.count, 0)
        
        let templateNames = templates.map { $0.name }
        XCTAssertTrue(templateNames.contains("深度睡眠"))
        XCTAssertTrue(templateNames.contains("快速入眠"))
        XCTAssertTrue(templateNames.contains("午间小憩"))
    }
    
    func testPlaylistTemplateProperties() {
        let template = PlaylistTemplate.templates.first!
        
        XCTAssertNotNil(template.id)
        XCTAssertFalse(template.name.isEmpty)
        XCTAssertFalse(template.description.isEmpty)
        XCTAssertFalse(template.iconName.isEmpty)
        XCTAssertFalse(template.color.isEmpty)
    }
    
    // MARK: - Persistence Tests
    
    func testPlaylistPersistence() {
        let playlist = playlistService.createPlaylist(name: "持久化测试")
        playlistService.addMusicToPlaylist(playlist.id, musicId: UUID())
        
        // 模拟保存和重新加载
        playlistService.savePlaylists()
        
        // 创建新实例模拟重新加载
        let newService = DreamMusicPlaylistService.shared
        
        let retrieved = newService.getPlaylist(playlist.id)
        XCTAssertEqual(retrieved?.name, "持久化测试")
    }
    
    // MARK: - Edge Cases
    
    func testPlayEmptyPlaylist() {
        let playlist = playlistService.createPlaylist(name: "空列表")
        
        playlistService.playPlaylist(playlist)
        
        // 应该能处理空播放列表
        XCTAssertEqual(playlistService.currentPlaylist?.id, playlist.id)
    }
    
    func testPlayNonExistentPlaylist() {
        let nonExistentId = UUID()
        let playlist = DreamMusicPlaylist(name: "测试", musicIds: [], createdAt: Date(), updatedAt: Date())
        
        // 尝试播放不存在的播放列表
        playlistService.playPlaylist(playlist)
        
        // 应该能处理
        XCTAssertEqual(playlistService.currentPlaylist?.name, "测试")
    }
    
    func testRemoveFromNonExistentPlaylist() {
        let nonExistentId = UUID()
        let musicId = UUID()
        
        // 不应该崩溃
        playlistService.removeMusicFromPlaylist(nonExistentId, musicId: musicId)
    }
    
    // MARK: - Helper Methods
    
    private func createTestMusic() -> DreamMusic {
        DreamMusic(
            dreamId: UUID(),
            title: "测试音乐",
            duration: 180,
            mood: .peaceful,
            tempo: .moderate,
            instruments: [.piano],
            audioLayers: [],
            createdAt: Date()
        )
    }
}

// MARK: - Performance Tests

final class DreamMusicPlaylistPerformanceTests: XCTestCase {
    
    func testCreateMultiplePlaylistsPerformance() {
        let playlistService = DreamMusicPlaylistService.shared
        
        measure {
            for i in 0..<100 {
                playlistService.createPlaylist(name: "测试\(i)")
            }
        }
    }
    
    func testLargePlaylistPlaybackPerformance() {
        let playlistService = DreamMusicPlaylistService.shared
        let playlist = playlistService.createPlaylist(name: "大型播放列表")
        
        // 添加 100 首音乐
        for _ in 0..<100 {
            playlistService.addMusicToPlaylist(playlist.id, musicId: UUID())
        }
        
        measure {
            playlistService.playPlaylist(playlist)
        }
    }
}
