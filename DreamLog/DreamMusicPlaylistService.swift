//
//  DreamMusicPlaylistService.swift
//  DreamLog - Phase 9: AI Dream Music Enhancement
//
//  Created by DreamLog Team on 2026-03-13
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import AVFoundation
import Combine
import UserNotifications

/// 梦境音乐播放列表服务
@MainActor
class DreamMusicPlaylistService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DreamMusicPlaylistService()
    
    // MARK: - Published Properties
    
    @Published var playlists: [DreamMusicPlaylist] = []
    @Published var currentPlaylist: DreamMusicPlaylist?
    @Published var playbackState: PlaybackState = .stopped
    @Published var currentVolume: Float = 1.0
    @Published var isShuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var sleepTimerRemaining: TimeInterval?
    @Published var isSleepTimerActive: Bool = false
    @Published var sharedMusic: [SharedDreamMusic] = []
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var sleepTimer: Timer?
    private var progressTimer: Timer?
    
    private let playlistsKey = "dreamlog_music_playlists"
    private let sharedMusicKey = "dreamlog_shared_music"
    private let historyKey = "dreamlog_playback_history"
    
    private var musicLibrary: [UUID: DreamMusic] = [:]
    private var playbackHistory: [PlaybackHistory] = []
    
    private var shuffleOrder: [Int] = []
    private var currentShuffleIndex: Int = 0
    
    enum RepeatMode {
        case off
        case all
        case one
    }
    
    // MARK: - Init
    
    private init() {
        loadPlaylists()
        loadSharedMusic()
        loadPlaybackHistory()
        setupAudioSession()
    }
    
    // MARK: - Audio Session
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ 设置音频会话失败：\(error)")
        }
    }
    
    // MARK: - Playlist Management
    
    /// 创建播放列表
    func createPlaylist(name: String, description: String = "", musicIds: [UUID] = [], template: PlaylistTemplate? = nil) -> DreamMusicPlaylist {
        var playlist = DreamMusicPlaylist(
            name: name,
            description: description,
            musicIds: musicIds,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        if let template = template {
            playlist.coverMood = template.mood
            playlist.sleepTimer = SleepTimerConfig(
                duration: template.suggestedDuration,
                fadeOut: true,
                fadeOutDuration: 30,
                action: .pause
            )
        }
        
        playlists.append(playlist)
        savePlaylists()
        
        print("✅ 创建播放列表：\(name)")
        return playlist
    }
    
    /// 更新播放列表
    func updatePlaylist(_ playlist: DreamMusicPlaylist) {
        var updated = playlist
        updated.updatedAt = Date()
        
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = updated
            savePlaylists()
        }
    }
    
    /// 删除播放列表
    func deletePlaylist(_ playlist: DreamMusicPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
        
        if currentPlaylist?.id == playlist.id {
            stopPlayback()
        }
        
        print("🗑️ 删除播放列表：\(playlist.name)")
    }
    
    /// 添加音乐到播放列表
    func addMusicToPlaylist(_ playlistId: UUID, musicId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            if !playlists[index].musicIds.contains(musicId) {
                playlists[index].musicIds.append(musicId)
                playlists[index].updatedAt = Date()
                savePlaylists()
                print("✅ 添加音乐到播放列表")
            }
        }
    }
    
    /// 从播放列表移除音乐
    func removeMusicFromPlaylist(_ playlistId: UUID, musicId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].musicIds.removeAll { $0 == musicId }
            playlists[index].updatedAt = Date()
            savePlaylists()
        }
    }
    
    /// 获取播放列表
    func getPlaylist(_ id: UUID) -> DreamMusicPlaylist? {
        playlists.first { $0.id == id }
    }
    
    /// 收藏/取消收藏播放列表
    func toggleFavorite(_ playlist: DreamMusicPlaylist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].isFavorite.toggle()
            playlists[index].updatedAt = Date()
            savePlaylists()
        }
    }
    
    // MARK: - Playback Control
    
    /// 播放播放列表
    func playPlaylist(_ playlist: DreamMusicPlaylist, startIndex: Int = 0) {
        currentPlaylist = playlist
        playbackState = .loading(index: startIndex)
        
        // 生成随机播放顺序
        if isShuffleEnabled {
            shuffleOrder = Array(0..<playlist.musicIds.count).shuffled()
            currentShuffleIndex = shuffleOrder.firstIndex(of: startIndex) ?? 0
        }
        
        // 加载并播放第一首音乐
        playMusicAtIndex(startIndex)
        
        print("▶️ 开始播放播放列表：\(playlist.name)")
    }
    
    private func playMusicAtIndex(_ index: Int) {
        guard let playlist = currentPlaylist, index < playlist.musicIds.count else {
            playbackState = .error("音乐索引超出范围")
            return
        }
        
        let musicId = playlist.musicIds[index]
        playbackState = .loading(index: index)
        
        // 模拟加载音乐（实际实现中从文件加载）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.playbackState = .playing(index: index, progress: 0)
            self?.startProgressTimer()
            self?.recordPlaybackStart(playlistId: playlist.id, musicId: musicId)
        }
    }
    
    /// 暂停播放
    func pause() {
        if case .playing(let index, let progress) = playbackState {
            playbackState = .paused(index: index, progress: progress)
            stopProgressTimer()
            print("⏸️ 暂停播放")
        }
    }
    
    /// 继续播放
    func resume() {
        if case .paused(let index, _) = playbackState {
            playbackState = .playing(index: index, progress: 0)
            startProgressTimer()
            print("▶️ 继续播放")
        }
    }
    
    /// 停止播放
    func stopPlayback() {
        stopProgressTimer()
        stopSleepTimer()
        audioPlayer?.stop()
        playbackState = .stopped
        currentPlaylist = nil
        print("⏹️ 停止播放")
    }
    
    /// 播放下一首
    func playNext() {
        guard let playlist = currentPlaylist else { return }
        
        guard case .playing(let currentIndex, _) = playbackState else { return }
        
        var nextIndex: Int
        if isShuffleEnabled {
            currentShuffleIndex += 1
            if currentShuffleIndex >= shuffleOrder.count {
                if repeatMode == .all {
                    currentShuffleIndex = 0
                } else {
                    stopPlayback()
                    return
                }
            }
            nextIndex = shuffleOrder[currentShuffleIndex]
        } else {
            nextIndex = currentIndex + 1
            if nextIndex >= playlist.musicIds.count {
                if repeatMode == .all {
                    nextIndex = 0
                } else {
                    stopPlayback()
                    return
                }
            }
        }
        
        playMusicAtIndex(nextIndex)
    }
    
    /// 播放上一首
    func playPrevious() {
        guard let playlist = currentPlaylist else { return }
        
        guard case .playing(let currentIndex, _) = playbackState else { return }
        
        var previousIndex: Int
        if isShuffleEnabled {
            currentShuffleIndex -= 1
            if currentShuffleIndex < 0 {
                currentShuffleIndex = shuffleOrder.count - 1
            }
            previousIndex = shuffleOrder[currentShuffleIndex]
        } else {
            previousIndex = currentIndex - 1
            if previousIndex < 0 {
                previousIndex = playlist.musicIds.count - 1
            }
        }
        
        playMusicAtIndex(previousIndex)
    }
    
    /// 切换随机播放
    func toggleShuffle() {
        isShuffleEnabled.toggle()
        if isShuffleEnabled && let playlist = currentPlaylist {
            shuffleOrder = Array(0..<playlist.musicIds.count).shuffled()
        }
        print("🔀 随机播放：\(isShuffleEnabled ? "开启" : "关闭")")
    }
    
    /// 切换循环模式
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
            print("🔁 列表循环")
        case .all:
            repeatMode = .one
            print("🔂 单曲循环")
        case .one:
            repeatMode = .off
            print("🔁 循环关闭")
        }
    }
    
    // MARK: - Progress Tracking
    
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard case .playing(let index, var progress) = playbackState else { return }
        
        progress += 1
        
        // 模拟音乐时长 3 分钟
        let musicDuration: TimeInterval = 180
        
        if progress >= musicDuration {
            // 音乐播放完毕
            if repeatMode == .one {
                playbackState = .playing(index: index, progress: 0)
                recordPlaybackComplete(musicId: currentPlaylist?.musicIds[index])
            } else {
                recordPlaybackComplete(musicId: currentPlaylist?.musicIds[index])
                playNext()
            }
        } else {
            playbackState = .playing(index: index, progress: progress)
        }
    }
    
    // MARK: - Sleep Timer
    
    /// 设置睡眠定时器
    func setSleepTimer(duration: SleepTimerConfig.SleepTimerDuration) {
        stopSleepTimer()
        
        guard let seconds = duration.seconds else {
            isSleepTimerActive = false
            sleepTimerRemaining = nil
            print("⏰ 睡眠定时器关闭")
            return
        }
        
        isSleepTimerActive = true
        sleepTimerRemaining = seconds
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSleepTimer()
            }
        }
        
        print("⏰ 睡眠定时器设置：\(duration.rawValue)")
    }
    
    private func updateSleepTimer() {
        guard var remaining = sleepTimerRemaining, remaining > 0 else {
            stopSleepTimer()
            return
        }
        
        remaining -= 1
        sleepTimerRemaining = remaining
        
        if remaining <= 30 && remaining > 0 {
            // 最后 30 秒开始淡出
            fadeOutVolume()
        }
        
        if remaining <= 0 {
            // 定时器结束，暂停播放
            pause()
            isSleepTimerActive = false
            sendSleepTimerNotification()
            print("⏰ 睡眠定时器结束")
        }
    }
    
    private func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        isSleepTimerActive = false
        sleepTimerRemaining = nil
        currentVolume = 1.0
        fadeTimer?.invalidate()
    }
    
    private func fadeOutVolume() {
        fadeTimer?.invalidate()
        var fadeSteps: Float = 30
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            fadeSteps -= 1
            self.currentVolume = fadeSteps / 30.0
            if fadeSteps <= 0 {
                self.fadeTimer?.invalidate()
            }
        }
    }
    
    private func sendSleepTimerNotification() {
        let content = UNMutableNotificationContent()
        content.title = "睡眠定时器结束"
        content.body = "DreamLog 已暂停播放，祝您晚安 🌙"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Sharing
    
    /// 分享音乐
    func shareMusic(_ music: DreamMusic, expiryDays: Int = 7) -> SharedDreamMusic {
        let shareCode = generateShareCode()
        let expiresAt = Calendar.current.date(byAdding: .day, value: expiryDays, to: Date()) ?? Date()
        
        let shared = SharedDreamMusic(
            id: UUID(),
            musicId: music.id,
            shareCode: shareCode,
            expiresAt: expiresAt,
            viewCount: 0,
            downloadCount: 0,
            createdAt: Date()
        )
        
        sharedMusic.append(shared)
        saveSharedMusic()
        
        print("🔗 分享音乐：\(music.title), 分享码：\(shareCode)")
        return shared
    }
    
    private func generateShareCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in chars.randomElement() ?? "A" })
    }
    
    /// 通过分享码获取音乐
    func getMusicByShareCode(_ code: String) -> DreamMusic? {
        guard let shared = sharedMusic.first(where: { $0.shareCode == code && !$0.isExpired }) else {
            return nil
        }
        
        shared.viewCount += 1
        saveSharedMusic()
        
        // 实际实现中从服务器获取音乐
        return musicLibrary[shared.musicId]
    }
    
    // MARK: - History
    
    private func recordPlaybackStart(playlistId: UUID, musicId: UUID) {
        let history = PlaybackHistory(playlistId: playlistId, musicId: musicId)
        playbackHistory.append(history)
        savePlaybackHistory()
    }
    
    private func recordPlaybackComplete(musicId: UUID?) {
        if let index = playbackHistory.lastIndex(where: { $0.musicId == musicId && !$0.completed }) {
            playbackHistory[index].completed = true
            savePlaybackHistory()
        }
    }
    
    /// 获取播放历史
    func getPlaybackHistory(limit: Int = 50) -> [PlaybackHistory] {
        Array(playbackHistory.suffix(limit)).reversed()
    }
    
    // MARK: - Persistence
    
    private func savePlaylists() {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: playlistsKey)
        }
    }
    
    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let loaded = try? JSONDecoder().decode([DreamMusicPlaylist].self, from: data) {
            playlists = loaded
        } else {
            // 创建默认播放列表
            createDefaultPlaylists()
        }
    }
    
    private func createDefaultPlaylists() {
        for template in PlaylistTemplate.templates {
            createPlaylist(
                name: template.name,
                description: template.description,
                template: template
            )
        }
    }
    
    private func saveSharedMusic() {
        if let data = try? JSONEncoder().encode(sharedMusic) {
            UserDefaults.standard.set(data, forKey: sharedMusicKey)
        }
    }
    
    private func loadSharedMusic() {
        if let data = UserDefaults.standard.data(forKey: sharedMusicKey),
           let loaded = try? JSONDecoder().decode([SharedDreamMusic].self, from: data) {
            sharedMusic = loaded.filter { !$0.isExpired }
        }
    }
    
    private func savePlaybackHistory() {
        // 只保留最近 100 条记录
        let recent = Array(playbackHistory.suffix(100))
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    private func loadPlaybackHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let loaded = try? JSONDecoder().decode([PlaybackHistory].self, from: data) {
            playbackHistory = loaded
        }
    }
    
    // MARK: - Statistics
    
    /// 获取播放统计
    func getPlaybackStats() -> PlaybackStats {
        let totalPlaylists = playlists.count
        let totalMusic = playlists.reduce(0) { $0 + $1.musicIds.count }
        let favoritePlaylists = playlists.filter { $0.isFavorite }.count
        let totalPlayTime = playbackHistory.reduce(0) { $0 + $1.playDuration }
        
        return PlaybackStats(
            totalPlaylists: totalPlaylists,
            totalMusic: totalMusic,
            favoritePlaylists: favoritePlaylists,
            totalPlayTime: totalPlayTime,
            totalPlays: playbackHistory.count
        )
    }
}

/// 播放统计
struct PlaybackStats {
    let totalPlaylists: Int
    let totalMusic: Int
    let favoritePlaylists: Int
    let totalPlayTime: TimeInterval
    let totalPlays: Int
    
    var formattedPlayTime: String {
        let hours = Int(totalPlayTime / 3600)
        let minutes = Int((totalPlayTime.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
}
