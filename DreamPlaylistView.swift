//
//  DreamPlaylistView.swift
//  DreamLog - Phase 59: Dream Playlist System
//
//  Created by DreamLog Team on 2026-03-17.
//  梦境播放列表 UI 界面
//

import SwiftUI
import SwiftData

// MARK: - Main Playlist View

struct DreamPlaylistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamPlaylistService?
    
    @Query(sort: \DreamPlaylist.updatedAt, order: .reverse)
    private var playlists: [DreamPlaylist]
    
    @State private var showingCreateSheet = false
    @State private var showingPresetSheet = false
    @State private var selectedPlaylist: DreamPlaylist?
    @State private var showingStats = false
    @State private var stats: PlaylistStats?
    
    var body: some View {
        NavigationStack {
            Group {
                if playlists.isEmpty {
                    EmptyStateView()
                } else {
                    PlaylistListView
                }
            }
            .navigationTitle("梦境播放列表")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingStats = true }) {
                        Label("统计", systemImage: "chart.bar")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingPresetSheet = true }) {
                            Label("从预设创建", systemImage: "star")
                        }
                        Button(action: { showingCreateSheet = true }) {
                            Label("新建播放列表", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreatePlaylistView(service: service)
            }
            .sheet(isPresented: $showingPresetSheet) {
                PresetPlaylistView(service: service)
            }
            .sheet(isPresented: $showingStats) {
                if let stats = stats {
                    PlaylistStatsView(stats: stats)
                } else {
                    ProgressView()
                }
            }
            .navigationDestination(for: DreamPlaylist.self) { playlist in
                PlaylistDetailView(playlist: playlist, service: service)
            }
            .task {
                service = DreamPlaylistService(modelContext: modelContext)
                await loadStats()
            }
        }
    }
    
    private var PlaylistListView: some View {
        List(playlists) { playlist in
            NavigationLink(destination: PlaylistDetailView(playlist: playlist, service: service)) {
                PlaylistRowView(playlist: playlist)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    if let service = service {
                        Task {
                            try? await service.deletePlaylist(playlist)
                        }
                    }
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func loadStats() async {
        if let service = service {
            stats = try? await service.getStats()
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text("还没有播放列表")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("创建播放列表来整理你的梦境\n或从预设模板快速开始")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Playlist Row View

struct PlaylistRowView: View {
    let playlist: DreamPlaylist
    
    var body: some View {
        HStack(spacing: 15) {
            // Cover
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: playlist.themeColor.startColor) ?? .purple,
                                Color(hex: playlist.themeColor.endColor) ?? .indigo
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Text(playlist.coverEmoji)
                    .font(.system(size: 28))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(playlist.itemCount)", systemImage: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(playlist.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if playlist.isPublic {
                    Label("公开", systemImage: "globe")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Playlist View

struct CreatePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var coverEmoji = "🎵"
    @State private var themeColor = PlaylistThemeColor.starry
    @State private var isPublic = false
    @State private var orderType = PlaylistOrderType.manual
    
    let service: DreamPlaylistService?
    
    private let emojis = ["🎵", "🌙", "⭐", "✨", "🌟", "💫", "🌈", "🦋", "🌸", "🎨", "📖", "💭"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("播放列表标题", text: $title)
                    
                    TextField("描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("外观") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button(action: { coverEmoji = emoji }) {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(emoji == coverEmoji ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(emoji == coverEmoji ? Color.purple : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Picker("主题色", selection: $themeColor) {
                        ForEach(PlaylistThemeColor.allCases, id: \.self) { color in
                            Label(color.displayName, systemImage: color.icon)
                                .tag(color)
                        }
                    }
                }
                
                Section("设置") {
                    Toggle("公开播放列表", isOn: $isPublic)
                    
                    Picker("排序方式", selection: $orderType) {
                        ForEach(PlaylistOrderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
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
                        createPlaylist()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func createPlaylist() {
        if let service = service {
            Task {
                do {
                    try await service.createPlaylist(
                        title: title.trimmingCharacters(in: .whitespaces),
                        description: description.trimmingCharacters(in: .whitespaces),
                        coverEmoji: coverEmoji,
                        themeColor: themeColor,
                        isPublic: isPublic,
                        orderType: orderType
                    )
                    dismiss()
                } catch {
                    print("创建播放列表失败：\(error)")
                }
            }
        }
    }
}

// MARK: - Preset Playlist View

struct PresetPlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    
    let service: DreamPlaylistService?
    
    var body: some View {
        NavigationStack {
            List(PlaylistPreset.presets) { preset in
                Button(action: {
                    createFromPreset(preset)
                }) {
                    HStack(spacing: 15) {
                        Text(preset.emoji)
                            .font(.system(size: 32))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.title)
                                .font(.headline)
                            
                            Text(preset.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            Label("约 \(preset.suggestedDreams) 个梦境", systemImage: "music.note")
                                .font(.caption2)
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("从预设创建")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    private func createFromPreset(_ preset: PlaylistPreset) {
        if let service = service {
            Task {
                do {
                    try await service.createFromPreset(preset)
                    dismiss()
                } catch {
                    print("创建预设播放列表失败：\(error)")
                }
            }
        }
    }
}

// MARK: - Playlist Detail View

struct PlaylistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let playlist: DreamPlaylist
    let service: DreamPlaylistService?
    
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingAddDreamSheet = false
    
    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: 12) {
                    Text(playlist.coverEmoji)
                        .font(.system(size: 60))
                    
                    Text(playlist.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !playlist.description.isEmpty {
                        Text(playlist.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 20) {
                        StatItem(icon: "music.note", value: "\(playlist.itemCount)", label: "梦境")
                        StatItem(icon: "clock", value: playlist.formattedDuration, label: "时长")
                        StatItem(icon: "play.circle", value: "\(playlist.playCount)", label: "播放")
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            // Dreams
            Section("梦境列表") {
                ForEach(playlist.items.sorted(by: { $0.position < $1.position }), id: \.id) { item in
                    if let dream = item.dream {
                        DreamPlaylistItemRow(item: item, dream: dream)
                    }
                }
                .onMove { fromOffsets, toOffset in
                    if let service = service {
                        Task {
                            try? await service.reorderPlaylistItems(playlist, fromOffsets: fromOffsets, toOffset: toOffset)
                        }
                    }
                }
            }
            
            // Actions
            Section {
                Button(action: { showingAddDreamSheet = true }) {
                    Label("添加梦境", systemImage: "plus")
                }
                
                Button(action: { showingEditSheet = true }) {
                    Label("编辑播放列表", systemImage: "pencil")
                }
                
                Button(action: { showingShareSheet = true }) {
                    Label("分享播放列表", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle(playlist.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: {
                        if let service = service {
                            Task {
                                try? await service.deletePlaylist(playlist)
                                dismiss()
                            }
                        }
                    }) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPlaylistView(playlist: playlist, service: service)
        }
        .sheet(isPresented: $showingAddDreamSheet) {
            AddDreamToPlaylistView(playlist: playlist, service: service)
        }
        .sheet(isPresented: $showingShareSheet) {
            SharePlaylistView(playlist: playlist, service: service)
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.purple)
            Text(value)
                .fontWeight(.bold)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

struct DreamPlaylistItemRow: View {
    let item: DreamPlaylistItem
    let dream: Dream
    
    @State private var showingNotes = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dream.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(dream.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if dream.isLucid {
                        Label("清醒", systemImage: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.purple)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: { showingNotes = true }) {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .alert("备注", isPresented: $showingNotes) {
            TextField("添加备注", text: .constant(item.notes ?? ""))
            Button("保存", action: {})
            Button("取消", role: .cancel) {}
        } message: {
            Text("为这个梦境添加备注")
        }
    }
}

// MARK: - Edit Playlist View

struct EditPlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    
    let playlist: DreamPlaylist
    let service: DreamPlaylistService?
    
    @State private var title: String
    @State private var description: String
    @State private var coverEmoji: String
    @State private var themeColor: PlaylistThemeColor
    @State private var isPublic: Bool
    @State private var orderType: PlaylistOrderType
    
    init(playlist: DreamPlaylist, service: DreamPlaylistService?) {
        self.playlist = playlist
        self.service = service
        _title = State(initialValue: playlist.title)
        _description = State(initialValue: playlist.description)
        _coverEmoji = State(initialValue: playlist.coverEmoji)
        _themeColor = State(initialValue: playlist.themeColor)
        _isPublic = State(initialValue: playlist.isPublic)
        _orderType = State(initialValue: playlist.orderType)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("描述", text: $description, axis: .vertical)
                }
                
                Section("外观") {
                    Picker("主题色", selection: $themeColor) {
                        ForEach(PlaylistThemeColor.allCases, id: \.self) { color in
                            Label(color.displayName, systemImage: color.icon).tag(color)
                        }
                    }
                    
                    TextField("封面 Emoji", text: $coverEmoji)
                        .keyboardType(.asciiCapable)
                }
                
                Section("设置") {
                    Toggle("公开播放列表", isOn: $isPublic)
                    
                    Picker("排序方式", selection: $orderType) {
                        ForEach(PlaylistOrderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("编辑播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        if let service = service {
            Task {
                try? await service.updatePlaylist(
                    playlist,
                    title: title,
                    description: description,
                    coverEmoji: coverEmoji,
                    themeColor: themeColor,
                    isPublic: isPublic,
                    orderType: orderType
                )
                dismiss()
            }
        }
    }
}

// MARK: - Add Dream to Playlist View

struct AddDreamToPlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let playlist: DreamPlaylist
    let service: DreamPlaylistService?
    
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var searchText = ""
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreams
        }
        return dreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredDreams) { dream in
                Button(action: {
                    addDream(dream)
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dream.title)
                                .font(.headline)
                            Text(dream.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if playlist.items.contains(where: { $0.dream?.id == dream.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索梦境")
            .navigationTitle("添加梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func addDream(_ dream: Dream) {
        if let service = service {
            Task {
                try? await service.addDreamToPlaylist(playlist, dreamId: dream.id)
            }
        }
    }
}

// MARK: - Share Playlist View

struct SharePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    
    let playlist: DreamPlaylist
    let service: DreamPlaylistService?
    
    @State private var shareLink: PlaylistShareLink?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("分享选项") {
                    Button(action: {
                        createShareLink()
                    }) {
                        Label("创建分享链接", systemImage: "link")
                    }
                    
                    Button(action: {
                        // System share
                    }) {
                        Label("分享到...", systemImage: "square.and.arrow.up")
                    }
                }
                
                if let link = shareLink {
                    Section("分享链接") {
                        Text(link.shareURL)
                            .font(.system(.body, design: .monospaced))
                        
                        Text("有效期至：\(link.expiresAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("统计") {
                    HStack {
                        Text("播放次数")
                        Spacer()
                        Text("\(playlist.playCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("分享次数")
                        Spacer()
                        Text("\(playlist.shareCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("分享播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func createShareLink() {
        if let service = service {
            shareLink = service.createShareLink(for: playlist)
        }
    }
}

// MARK: - Playlist Stats View

struct PlaylistStatsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let stats: PlaylistStats
    
    var body: some View {
        NavigationStack {
            List {
                Section("概览") {
                    StatRow(label: "播放列表总数", value: "\(stats.totalPlaylists)")
                    StatRow(label: "梦境总数", value: "\(stats.totalItems)")
                    StatRow(label: "总时长", value: formatDuration(stats.totalDuration))
                    StatRow(label: "平均每列表", value: String(format: "%.1f", stats.averageItemsPerPlaylist))
                }
                
                Section("互动") {
                    StatRow(label: "总播放次数", value: "\(stats.totalPlays)")
                    StatRow(label: "总分享次数", value: "\(stats.totalShares)")
                    StatRow(label: "公开播放列表", value: "\(stats.publicPlaylists)")
                }
                
                if let theme = stats.mostUsedTheme {
                    Section("偏好") {
                        HStack {
                            Text("最常用主题")
                            Spacer()
                            Label(theme.displayName, systemImage: theme.icon)
                        }
                    }
                }
            }
            .navigationTitle("播放列表统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    DreamPlaylistView()
        .modelContainer(for: [DreamPlaylist.self, DreamPlaylistItem.self, Dream.self], inMemory: true)
}
