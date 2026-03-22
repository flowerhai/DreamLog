//
//  DreamMusicPlaylistView.swift
//  DreamLog - Phase 9: AI Dream Music Enhancement
//
//  Created by DreamLog Team on 2026-03-13
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

/// 梦境音乐播放列表主界面
struct DreamMusicPlaylistView: View {
    @ObservedObject private var playlistService = DreamMusicPlaylistService.shared
    @State private var showingCreatePlaylist = false
    @State private var selectedPlaylist: DreamMusicPlaylist?
    @State private var showingSleepTimer = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前播放栏
                if playlistService.playbackState.isPlaying || playlistService.playbackState.isPaused {
                    CurrentPlaybackBar(
                        playlistService: playlistService,
                        onTap: {
                            if let playlist = playlistService.currentPlaylist {
                                selectedPlaylist = playlist
                            }
                        }
                    )
                }
                
                // 播放列表列表
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 统计卡片
                        PlaybackStatsCard(stats: playlistService.getPlaybackStats())
                        
                        // 预设模板
                        Text("快速创建")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PlaylistTemplate.templates) { template in
                                    PlaylistTemplateCard(
                                        template: template,
                                        onTap: {
                                            playlistService.createPlaylist(
                                                name: template.name,
                                                description: template.description,
                                                template: template
                                            )
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 我的播放列表
                        Text("我的播放列表")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        if playlistService.playlists.isEmpty {
                            EmptyPlaylistsView(onCreate: { showingCreatePlaylist = true })
                        } else {
                            ForEach(playlistService.playlists) { playlist in
                                PlaylistCard(
                                    playlist: playlist,
                                    onTap: {
                                        selectedPlaylist = playlist
                                    },
                                    onPlay: {
                                        playlistService.playPlaylist(playlist)
                                    },
                                    onFavorite: {
                                        playlistService.toggleFavorite(playlist)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("音乐播放列表")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePlaylist = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                CreatePlaylistView(playlistService: playlistService)
            }
            .sheet(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(
                    playlist: playlist,
                    playlistService: playlistService
                )
            }
        }
    }
}

// MARK: - Current Playback Bar

struct CurrentPlaybackBar: View {
    @ObservedObject var playlistService: DreamMusicPlaylistService
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // 专辑封面
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "8B5CF6"),
                                    Color(hex: "EC4899")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                // 音乐信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlistService.currentPlaylist?.name ?? "未知播放列表")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let index = playlistService.playbackState.currentIndex {
                        Text("第 \(index + 1) 首")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 进度条
                    if case .playing(_, let progress) = playlistService.playbackState {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.purple)
                                    .frame(width: geo.size.width * (progress / 180), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                
                Spacer()
                
                // 控制按钮
                HStack(spacing: 16) {
                    Button(action: { playlistService.playPrevious() }) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    
                    Button(action: {
                        if playlistService.playbackState.isPlaying {
                            playlistService.pause()
                        } else {
                            playlistService.resume()
                        }
                    }) {
                        Image(systemName: playlistService.playbackState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    
                    Button(action: { playlistService.playNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                }
                
                Button(action: { showingSleepTimer = true }) {
                    Image(systemName: playlistService.isSleepTimerActive ? "timer" : "timer")
                        .font(.title3)
                        .foregroundColor(playlistService.isSleepTimerActive ? .purple : .secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
    }
}

// MARK: - Playback Stats Card

struct PlaybackStatsCard: View {
    let stats: PlaybackStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("播放统计")
                        .font(.headline)
                    Text("总计 \(stats.formattedPlayTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    MusicPlaylistStatItem(icon: "list.bullet", value: "\(stats.totalPlaylists)", label: "播放列表")
                    MusicPlaylistStatItem(icon: "music.note", value: "\(stats.totalMusic)", label: "音乐")
                    MusicPlaylistStatItem(icon: "play.circle", value: "\(stats.totalPlays)", label: "播放")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "5B91F5").opacity(0.1),
                            Color(hex: "8B5CF6").opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal)
    }
}

struct MusicPlaylistStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Playlist Template Card

struct PlaylistTemplateCard: View {
    let template: PlaylistTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: template.color))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: template.iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(template.suggestedDuration.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Playlist Card

struct PlaylistCard: View {
    let playlist: DreamMusicPlaylist
    let onTap: () -> Void
    let onPlay: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // 封面
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "music.note.house")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(playlist.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if playlist.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    if !playlist.description.isEmpty {
                        Text(playlist.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(playlist.musicCount) 首", systemImage: "music.note")
                        Label(playlist.formattedTotalDuration, systemImage: "clock")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 8) {
                    Button(action: onFavorite) {
                        Image(systemName: playlist.isFavorite ? "star.fill" : "star")
                            .foregroundColor(playlist.isFavorite ? .yellow : .gray)
                    }
                    
                    Button(action: onPlay) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private var gradientColors: [Color] {
        if let mood = playlist.coverMood {
            switch mood {
            case .peaceful: return [Color(hex: "5B91F5"), Color(hex: "3B82F6")]
            case .mysterious: return [Color(hex: "8B5CF6"), Color(hex: "7C3AED")]
            case .dreamy: return [Color(hex: "EC4899"), Color(hex: "DB2777")]
            case .energetic: return [Color(hex: "F59E0B"), Color(hex: "D97706")]
            case .melancholic: return [Color(hex: "64748B"), Color(hex: "475569")]
            case .ethereal: return [Color(hex: "06B6D4"), Color(hex: "0891B2")]
            case .tense: return [Color(hex: "DC2626"), Color(hex: "B91C1C")]
            case .joyful: return [Color(hex: "10B981"), Color(hex: "059669")]
            }
        }
        return [Color(hex: "8B5CF6"), Color(hex: "EC4899")]
    }
}

// MARK: - Empty Playlists View

struct EmptyPlaylistsView: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("暂无播放列表")
                .font(.headline)
            
            Text("创建你的第一个梦境音乐播放列表")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: onCreate) {
                Label("创建播放列表", systemImage: "plus")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Create Playlist View

struct CreateMusicPlaylistView: View {
    @ObservedObject var playlistService: DreamMusicPlaylistService
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var selectedTemplate: PlaylistTemplate?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("播放列表名称", text: $name)
                    TextField("描述（可选）", text: $description)
                }
                
                Section(header: Text("选择模板")) {
                    ForEach(PlaylistTemplate.templates) { template in
                        Button(action: { selectedTemplate = template }) {
                            HStack {
                                Image(systemName: template.iconName)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedTemplate?.id == template.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("新建播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        playlistService.createPlaylist(
                            name: name.isEmpty ? "未命名播放列表" : name,
                            description: description,
                            template: selectedTemplate
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty && selectedTemplate == nil)
                }
            }
        }
    }
}

// MARK: - Playlist Detail View

struct MusicPlaylistDetailView: View {
    let playlist: DreamMusicPlaylist
    @ObservedObject var playlistService: DreamMusicPlaylistService
    @Environment(\.dismiss) var dismiss
    @State private var showingSleepTimer = false
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 播放列表信息
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 200)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "music.note.house")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                            
                            Text(playlist.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(playlist.musicCount) 首音乐 • \(playlist.formattedTotalDuration)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // 控制按钮
                    HStack(spacing: 24) {
                        Button(action: { playlistService.playPlaylist(playlist) }) {
                            VStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.purple)
                                Text("播放")
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: { showingSleepTimer = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "timer")
                                    .font(.system(size: 48))
                                    .foregroundColor(.purple)
                                Text("定时")
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: { playlistService.toggleFavorite(playlist) }) {
                            VStack(spacing: 8) {
                                Image(systemName: playlist.isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 48))
                                    .foregroundColor(playlist.isFavorite ? .yellow : .gray)
                                Text(playlist.isFavorite ? "已收藏" : "收藏")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
                
                // 音乐列表
                List {
                    Section(header: Text("音乐列表")) {
                        if playlist.musicIds.isEmpty {
                            Text("暂无音乐，先去生成一些梦境音乐吧")
                                .foregroundColor(.secondary)
                                .padding(.vertical)
                        } else {
                            ForEach(Array(playlist.musicIds.enumerated()), id: \.element) { index, musicId in
                                MusicListItem(
                                    index: index,
                                    musicId: musicId,
                                    playlistService: playlistService
                                )
                            }
                            .onMove { indices, newOffset in
                                // 实现拖拽排序
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $showingSleepTimer) {
                SleepTimerSelectionView(playlistService: playlistService)
            }
        }
    }
}

struct MusicListItem: View {
    let index: Int
    let musicId: UUID
    @ObservedObject var playlistService: DreamMusicPlaylistService
    
    var body: some View {
        HStack {
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Image(systemName: "music.note")
                .foregroundColor(.purple)
            
            VStack(alignment: .leading) {
                Text("梦境音乐 \(index + 1)")
                    .font(.subheadline)
                Text("3:00")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Sleep Timer Selection View

struct MusicSleepTimerSelectionView: View {
    @ObservedObject var playlistService: DreamMusicPlaylistService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("选择时长")) {
                    ForEach(SleepTimerConfig.SleepTimerDuration.allCases) { duration in
                        Button(action: {
                            playlistService.setSleepTimer(duration: duration)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: duration.icon)
                                    .foregroundColor(.purple)
                                Text(duration.rawValue)
                                Spacer()
                                if playlistService.isSleepTimerActive && 
                                   ((duration == .minutes15 && playlistService.sleepTimerRemaining == 15 * 60) ||
                                    (duration == .minutes30 && playlistService.sleepTimerRemaining == 30 * 60) ||
                                    (duration == .minutes45 && playlistService.sleepTimerRemaining == 45 * 60) ||
                                    (duration == .minutes60 && playlistService.sleepTimerRemaining == 60 * 60) ||
                                    (duration == .minutes90 && playlistService.sleepTimerRemaining == 90 * 60)) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
                
                if playlistService.isSleepTimerActive {
                    Section {
                        Button(action: {
                            playlistService.setSleepTimer(duration: .off)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                Text("关闭定时器")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("睡眠定时器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// Note: Color(hex:) is defined in Theme.swift to avoid duplicate declarations

#Preview {
    DreamMusicPlaylistView()
}
