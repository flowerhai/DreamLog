//
//  DreamPlaylistService.swift
//  DreamLog - Phase 59: Dream Playlist System
//
//  Created by DreamLog Team on 2026-03-17.
//  梦境播放列表核心服务
//

import Foundation
import SwiftData

actor DreamPlaylistService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var cachedPlaylists: [DreamPlaylist] = []
    private var lastFetchTime: Date?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// 创建播放列表
    func createPlaylist(
        title: String,
        description: String = "",
        coverEmoji: String = "🎵",
        themeColor: PlaylistThemeColor = .starry,
        isPublic: Bool = false,
        orderType: PlaylistOrderType = .manual,
        dreamIds: [UUID] = []
    ) async throws -> DreamPlaylist {
        let playlist = DreamPlaylist(
            title: title,
            description: description,
            coverEmoji: coverEmoji,
            themeColor: themeColor,
            isPublic: isPublic,
            orderType: orderType
        )
        
        // 添加梦境到播放列表
        for dreamId in dreamIds {
            if let dream = try getDream(by: dreamId) {
                let item = DreamPlaylistItem(dream: dream, position: playlist.items.count)
                playlist.items.append(item)
            }
        }
        
        modelContext.insert(playlist)
        try modelContext.save()
        
        await refreshCache()
        return playlist
    }
    
    /// 从预设创建播放列表
    func createFromPreset(_ preset: PlaylistPreset) async throws -> DreamPlaylist {
        let dreams = try await fetchDreams(for: preset.filterType, limit: preset.suggestedDreams)
        
        return try await createPlaylist(
            title: preset.title,
            description: preset.description,
            coverEmoji: preset.emoji,
            themeColor: preset.themeColor,
            dreamIds: dreams.map { $0.id }
        )
    }
    
    /// 更新播放列表
    func updatePlaylist(
        _ playlist: DreamPlaylist,
        title: String? = nil,
        description: String? = nil,
        coverEmoji: String? = nil,
        themeColor: PlaylistThemeColor? = nil,
        isPublic: Bool? = nil,
        orderType: PlaylistOrderType? = nil
    ) async throws {
        if let title = title { playlist.title = title }
        if let description = description { playlist.description = description }
        if let coverEmoji = coverEmoji { playlist.coverEmoji = coverEmoji }
        if let themeColor = themeColor { playlist.themeColor = themeColor }
        if let isPublic = isPublic { playlist.isPublic = isPublic }
        if let orderType = orderType { playlist.orderType = orderType }
        
        playlist.updatedAt = Date()
        try modelContext.save()
        
        await refreshCache()
    }
    
    /// 删除播放列表
    func deletePlaylist(_ playlist: DreamPlaylist) async throws {
        modelContext.delete(playlist)
        try modelContext.save()
        
        await refreshCache()
    }
    
    /// 获取所有播放列表
    func getAllPlaylists(includePublic: Bool = true) async throws -> [DreamPlaylist] {
        if let cached = cachedPlaylists,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < 60 {
            return cached
        }
        
        var descriptor = FetchDescriptor<DreamPlaylist>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        if !includePublic {
            descriptor.predicate = #Predicate { $0.isPublic == false }
        }
        
        let playlists = try modelContext.fetch(descriptor)
        cachedPlaylists = playlists
        lastFetchTime = Date()
        
        return playlists
    }
    
    /// 获取单个播放列表
    func getPlaylist(by id: UUID) async throws -> DreamPlaylist? {
        let descriptor = FetchDescriptor<DreamPlaylist>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - Playlist Items Management
    
    /// 添加梦境到播放列表
    func addDreamToPlaylist(_ playlist: DreamPlaylist, dreamId: UUID, notes: String? = nil) async throws {
        guard let dream = try getDream(by: dreamId) else {
            throw PlaylistError.dreamNotFound
        }
        
        // 检查是否已存在
        let exists = playlist.items.contains { $0.dream?.id == dreamId }
        if exists {
            throw PlaylistError.dreamAlreadyInPlaylist
        }
        
        let item = DreamPlaylistItem(
            dream: dream,
            position: playlist.items.count,
            notes: notes
        )
        playlist.items.append(item)
        playlist.updatedAt = Date()
        
        try modelContext.save()
        await refreshCache()
    }
    
    /// 从播放列表移除梦境
    func removeDreamFromPlaylist(_ playlist: DreamPlaylist, itemId: UUID) async throws {
        guard let index = playlist.items.firstIndex(where: { $0.id == itemId }) else {
            throw PlaylistError.itemNotFound
        }
        
        playlist.items.remove(at: index)
        playlist.updatedAt = Date()
        
        // 重新排序
        for (index, item) in playlist.items.enumerated() {
            item.position = index
        }
        
        try modelContext.save()
        await refreshCache()
    }
    
    /// 重新排序播放列表项
    func reorderPlaylistItems(_ playlist: DreamPlaylist, fromOffsets: IndexSet, toOffset: Int) async throws {
        var items = playlist.items
        items.move(fromOffsets: fromOffsets, toOffset: toOffset)
        
        // 更新位置
        for (index, item) in items.enumerated() {
            item.position = index
        }
        
        playlist.items = items
        playlist.updatedAt = Date()
        
        try modelContext.save()
        await refreshCache()
    }
    
    /// 更新播放列表项备注
    func updateItemNotes(_ item: DreamPlaylistItem, notes: String?) async throws {
        item.notes = notes
        try modelContext.save()
    }
    
    // MARK: - Auto-generated Playlists
    
    /// 自动生成"本周精选"播放列表
    func generateWeeklyHighlights() async throws -> DreamPlaylist? {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.date >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.clarity, order: .reverse)]
        )
        
        let dreams = try modelContext.fetch(descriptor).prefix(10).map { $0 }
        
        if dreams.isEmpty {
            return nil
        }
        
        return try await createPlaylist(
            title: "本周精选 🌟",
            description: "本周最清晰、最有趣的梦境合集",
            coverEmoji: "⭐",
            themeColor: .starry,
            dreamIds: dreams.map { $0.id }
        )
    }
    
    /// 自动生成"清醒梦合集"
    func generateLucidDreamsCollection() async throws -> DreamPlaylist? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.isLucid == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let dreams = try modelContext.fetch(descriptor).prefix(20).map { $0 }
        
        if dreams.isEmpty {
            return nil
        }
        
        return try await createPlaylist(
            title: "清醒梦合集 🌟",
            description: "所有清醒梦体验",
            coverEmoji: "✨",
            themeColor: .crystal,
            dreamIds: dreams.map { $0.id }
        )
    }
    
    // MARK: - Statistics
    
    /// 获取播放列表统计
    func getStats() async throws -> PlaylistStats {
        let playlists = try await getAllPlaylists()
        
        guard !playlists.isEmpty else {
            return .empty
        }
        
        let totalItems = playlists.reduce(0) { $0 + $1.itemCount }
        let totalDuration = playlists.reduce(0) { $0 + $1.totalDuration }
        let totalPlays = playlists.reduce(0) { $0 + $1.playCount }
        let totalShares = playlists.reduce(0) { $0 + $1.shareCount }
        let publicCount = playlists.filter { $0.isPublic }.count
        
        // 计算最常用的主题色
        let themeCounts = Dictionary(grouping: playlists, by: { $0.themeColor })
        let mostUsedTheme = themeCounts.max(by: { $0.value.count < $1.value.count })?.key
        
        return PlaylistStats(
            totalPlaylists: playlists.count,
            totalItems: totalItems,
            totalDuration: totalDuration,
            mostUsedTheme: mostUsedTheme,
            averageItemsPerPlaylist: Double(totalItems) / Double(playlists.count),
            publicPlaylists: publicCount,
            totalPlays: totalPlays,
            totalShares: totalShares
        )
    }
    
    // MARK: - Share Link Management
    
    /// 创建分享链接
    func createShareLink(for playlist: DreamPlaylist, expiresInSeconds: TimeInterval = 7 * 24 * 3600) -> PlaylistShareLink {
        let expiresAt = Date().addingTimeInterval(expiresInSeconds)
        return PlaylistShareLink(playlistId: playlist.id, expiresAt: expiresAt)
    }
    
    /// 增加播放次数
    func incrementPlayCount(for playlist: DreamPlaylist) async throws {
        playlist.playCount += 1
        try modelContext.save()
    }
    
    /// 增加分享次数
    func incrementShareCount(for playlist: DreamPlaylist) async throws {
        playlist.shareCount += 1
        try modelContext.save()
    }
    
    // MARK: - Private Helpers
    
    private func getDream(by id: UUID) throws -> Dream? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    private func fetchDreams(for filterType: PlaylistFilterType, limit: Int) async throws -> [Dream] {
        var descriptor = FetchDescriptor<Dream>()
        descriptor.fetchLimit = limit
        
        switch filterType {
        case .all:
            break
            
        case .recentDays(let days):
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            descriptor.predicate = #Predicate { $0.date >= startDate }
            
        case .lucidOnly:
            descriptor.predicate = #Predicate { $0.isLucid == true }
            
        case .emotion(let emotion):
            descriptor.predicate = #Predicate { $0.emotions.contains(emotion) }
            
        case .tag(let tagName):
            descriptor.predicate = #Predicate { $0.tags.contains(tagName) }
            
        case .keyword(let keyword):
            // 简单关键词搜索
            descriptor.predicate = #Predicate { $0.content.contains(keyword) || $0.title.contains(keyword) }
            
        case .recurring:
            // 查找重复出现的标签组合
            // 这里简化处理，查找有"重复"标签的梦境
            descriptor.predicate = #Predicate { $0.tags.contains("重复") }
            
        case .custom(let dreamIds):
            descriptor.predicate = #Predicate { dreamIds.contains($0.id) }
        }
        
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    private func refreshCache() async {
        cachedPlaylists.removeAll()
        lastFetchTime = nil
    }
}

// MARK: - Playlist Errors

enum PlaylistError: LocalizedError {
    case dreamNotFound
    case dreamAlreadyInPlaylist
    case itemNotFound
    case playlistNotFound
    case invalidOrder
    
    var errorDescription: String? {
        switch self {
        case .dreamNotFound:
            return "梦境不存在"
        case .dreamAlreadyInPlaylist:
            return "梦境已在播放列表中"
        case .itemNotFound:
            return "播放列表项不存在"
        case .playlistNotFound:
            return "播放列表不存在"
        case .invalidOrder:
            return "无效的排序"
        }
    }
}
