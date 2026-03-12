//
//  DreamMusicPlaylist.swift
//  DreamLog
//
//  Phase 26 - 梦境音乐播放列表管理
//  支持创建、管理、分享自定义音乐播放列表
//

import Foundation
import SwiftUI

// MARK: - 播放列表模型

/// 梦境音乐播放列表
struct DreamMusicPlaylist: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var musicIds: [UUID]  // 音乐 ID 列表
    var coverMood: DreamMusic.DreamMusicMood?  // 封面情绪
    var createdAt: Date
    var updatedAt: Date
    var isSmartPlaylist: Bool = false  // 是否为智能播放列表
    var smartCriteria: SmartPlaylistCriteria?  // 智能播放列表条件
    var playCount: Int = 0
    var isFavorite: Bool = false
    
    /// 智能播放列表条件
    struct SmartPlaylistCriteria: Codable {
        var mood: DreamMusic.DreamMusicMood?
        var tempo: DreamMusic.DreamMusicTempo?
        var instruments: [DreamMusic.DreamMusicInstrument]?
        var maxDuration: TimeInterval?
        var dateRange: DateInterval?
        var sortBy: SortOption = .createdAt
        
        enum SortOption: String, Codable {
            case createdAt = "createdAt"
            case duration = "duration"
            case mood = "mood"
            case tempo = "tempo"
        }
    }
    
    /// 计算属性：获取实际音乐列表
    func getMusic(from library: [DreamMusic]) -> [DreamMusic] {
        return library.filter { musicIds.contains($0.id) }
    }
}

// MARK: - 播放列表服务

@MainActor
class DreamMusicPlaylistService: ObservableObject {
    static let shared = DreamMusicPlaylistService()
    
    @Published var playlists: [DreamMusicPlaylist] = []
    @Published var currentPlaylist: DreamMusicPlaylist?
    @Published var isCreating = false
    @Published var errorMessage: String?
    
    private let saveKey = "DreamMusicPlaylists"
    
    private init() {
        loadPlaylists()
    }
    
    // MARK: - 数据持久化
    
    func loadPlaylists() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([DreamMusicPlaylist].self, from: data) else {
            playlists = []
            return
        }
        playlists = decoded
        print("🎵 加载了 \(playlists.count) 个播放列表")
    }
    
    func savePlaylists() {
        guard let encoded = try? JSONEncoder().encode(playlists) else {
            print("❌ 播放列表编码失败")
            return
        }
        UserDefaults.standard.set(encoded, forKey: saveKey)
        print("🎵 保存了 \(playlists.count) 个播放列表")
    }
    
    // MARK: - 播放列表管理
    
    /// 创建播放列表
    func createPlaylist(title: String, description: String? = nil, musicIds: [UUID] = []) -> DreamMusicPlaylist {
        let playlist = DreamMusicPlaylist(
            title: title,
            description: description,
            musicIds: musicIds,
            createdAt: Date(),
            updatedAt: Date()
        )
        playlists.append(playlist)
        savePlaylists()
        return playlist
    }
    
    /// 创建智能播放列表
    func createSmartPlaylist(title: String, criteria: DreamMusicPlaylist.SmartPlaylistCriteria) -> DreamMusicPlaylist {
        let playlist = DreamMusicPlaylist(
            title: title,
            musicIds: [],
            createdAt: Date(),
            updatedAt: Date(),
            isSmartPlaylist: true,
            smartCriteria: criteria
        )
        playlists.append(playlist)
        savePlaylists()
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
    }
    
    /// 添加音乐到播放列表
    func addMusicToPlaylist(_ playlistId: UUID, musicId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            if !playlists[index].musicIds.contains(musicId) {
                playlists[index].musicIds.append(musicId)
                playlists[index].updatedAt = Date()
                savePlaylists()
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
    
    /// 刷新智能播放列表
    func refreshSmartPlaylist(_ playlist: DreamMusicPlaylist, musicLibrary: [DreamMusic]) -> [DreamMusic] {
        guard let criteria = playlist.smartCriteria else {
            return []
        }
        
        var filtered = musicLibrary
        
        // 按情绪筛选
        if let mood = criteria.mood {
            filtered = filtered.filter { $0.mood == mood }
        }
        
        // 按节奏筛选
        if let tempo = criteria.tempo {
            filtered = filtered.filter { $0.tempo == tempo }
        }
        
        // 按乐器筛选
        if let instruments = criteria.instruments, !instruments.isEmpty {
            filtered = filtered.filter { music in
                music.instruments.contains { instruments.contains($0) }
            }
        }
        
        // 按时长筛选
        if let maxDuration = criteria.maxDuration {
            filtered = filtered.filter { $0.duration <= maxDuration }
        }
        
        // 按日期范围筛选
        if let dateRange = criteria.dateRange {
            filtered = filtered.filter { dateRange.contains($0.createdAt) }
        }
        
        // 排序
        switch criteria.sortBy {
        case .createdAt:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .duration:
            filtered.sort { $0.duration > $1.duration }
        case .mood:
            filtered.sort { $0.mood.rawValue < $1.mood.rawValue }
        case .tempo:
            filtered.sort { $0.tempo.rawValue < $1.tempo.rawValue }
        }
        
        return filtered
    }
    
    // MARK: - 预设播放列表模板
    
    /// 创建预设播放列表
    func createPresetPlaylists() {
        // 晨间唤醒
        _ = createSmartPlaylist(
            title: "☀️ 晨间唤醒",
            criteria: DreamMusicPlaylist.SmartPlaylistCriteria(
                mood: .joyful,
                tempo: .moderateFast,
                sortBy: .tempo
            )
        )
        
        // 深度冥想
        _ = createSmartPlaylist(
            title: "🧘 深度冥想",
            criteria: DreamMusicPlaylist.SmartPlaylistCriteria(
                mood: .peaceful,
                tempo: .verySlow,
                maxDuration: 300  // 5 分钟
            )
        )
        
        // 助眠音乐
        _ = createSmartPlaylist(
            title: "😴 助眠音乐",
            criteria: DreamMusicPlaylist.SmartPlaylistCriteria(
                mood: .peaceful,
                tempo: .verySlow,
                instruments: [.oceanWaves, .rainSounds, .ambientPad]
            )
        )
        
        // 专注工作
        _ = createSmartPlaylist(
            title: "🎯 专注工作",
            criteria: DreamMusicPlaylist.SmartPlaylistCriteria(
                mood: .ethereal,
                tempo: .moderate,
                instruments: [.piano, .ambientPad]
            )
        )
        
        // 创意灵感
        _ = createSmartPlaylist(
            title: "💡 创意灵感",
            criteria: DreamMusicPlaylist.SmartPlaylistCriteria(
                mood: .dreamy,
                tempo: .slow,
                instruments: [.harp, .flute, .windChimes]
            )
        )
        
        savePlaylists()
        print("🎵 创建了 5 个预设播放列表")
    }
    
    // MARK: - 播放列表分享
    
    /// 生成播放列表分享数据
    func generateShareData(for playlist: DreamMusicPlaylist, musicLibrary: [DreamMusic]) -> [String: Any] {
        let music = playlist.getMusic(from: musicLibrary)
        
        return [
            "playlistTitle": playlist.title,
            "playlistDescription": playlist.description ?? "",
            "musicCount": music.count,
            "totalDuration": music.reduce(0) { $0 + $1.duration },
            "moods": Set(music.map { $0.mood.rawValue }).joined(separator: ", "),
            "createdAt": playlist.createdAt.ISO8601Format(),
            "tracks": music.map { track in
                [
                    "title": track.title,
                    "duration": track.duration,
                    "mood": track.mood.rawValue,
                    "instruments": track.instruments.map { $0.rawValue }
                ]
            }
        ]
    }
}

// MARK: - 播放列表视图

struct DreamMusicPlaylistView: View {
    @ObservedObject private var playlistService = DreamMusicPlaylistService.shared
    @ObservedObject private var musicService = DreamMusicService.shared
    @State private var showingCreateSheet = false
    @State private var selectedPlaylist: DreamMusicPlaylist?
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                DreamBackgroundView()
                
                VStack(spacing: 0) {
                    // 头部
                    headerSection
                    
                    // 内容
                    ScrollView {
                        VStack(spacing: 16) {
                            // 预设播放列表
                            presetPlaylistsSection
                            
                            // 我的播放列表
                            myPlaylistsSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("播放列表")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateSheet) {
                CreatePlaylistView()
            }
            .sheet(item: $selectedPlaylist) { playlist in
                EditPlaylistView(playlist: playlist)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的播放列表")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("创建和管理你的梦境音乐合集")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingCreateSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
        }
    }
    
    private var presetPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                Text("预设播放列表")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(playlistService.playlists.filter { $0.isSmartPlaylist }, id: \.id) { playlist in
                    PlaylistCard(playlist: playlist, musicLibrary: musicService.musicLibrary)
                        .onTapGesture {
                            selectedPlaylist = playlist
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
    }
    
    private var myPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note.list")
                    .font(.title3)
                    .foregroundColor(.blue)
                Text("我的播放列表")
                    .font(.headline)
                Spacer()
                Text("\(playlistService.playlists.filter { !$0.isSmartPlaylist }.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if playlistService.playlists.filter({ !$0.isSmartPlaylist }).isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("还没有播放列表")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("点击右上角 + 创建你的第一个播放列表")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(playlistService.playlists.filter { !$0.isSmartPlaylist }, id: \.id) { playlist in
                    PlaylistCard(playlist: playlist, musicLibrary: musicService.musicLibrary)
                        .onTapGesture {
                            selectedPlaylist = playlist
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
    }
}

// MARK: - 播放列表卡片

struct PlaylistCard: View {
    let playlist: DreamMusicPlaylist
    let musicLibrary: [DreamMusic]
    
    private var musicCount: Int {
        if playlist.isSmartPlaylist {
            return playlistService.refreshSmartPlaylist(playlist, musicLibrary: musicLibrary).count
        } else {
            return playlist.musicIds.count
        }
    }
    
    private var playlistService = DreamMusicPlaylistService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradient)
                    .frame(height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text("\(musicCount) 首")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if playlist.isSmartPlaylist {
                        Image(systemName: "wand.and.stars")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var gradient: LinearGradient {
        if let mood = playlist.coverMood {
            return LinearGradient(
                colors: moodColors[mood] ?? [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var icon: String {
        if playlist.isSmartPlaylist {
            return "wand.and.stars"
        }
        return "music.note.house"
    }
    
    private var moodColors: [DreamMusic.DreamMusicMood: [Color]] {
        [
            .peaceful: [Color.blue, Color.purple],
            .mysterious: [Color.purple, Color.indigo],
            .dreamy: [Color.pink, Color.purple],
            .energetic: [Color.orange, Color.yellow],
            .melancholic: [Color.gray, Color.blue],
            .ethereal: [Color.cyan, Color.blue],
            .tense: [Color.red, Color.orange],
            .joyful: [Color.yellow, Color.orange]
        ]
    }
}

// MARK: - 创建播放列表视图

struct CreatePlaylistView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var playlistService = DreamMusicPlaylistService.shared
    @ObservedObject private var musicService = DreamMusicService.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedMusicIds: Set<UUID> = []
    @State private var isSmartPlaylist = false
    @State private var selectedMood: DreamMusic.DreamMusicMood?
    @State private var selectedTempo: DreamMusic.DreamMusicTempo?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("播放列表名称", text: $title)
                    TextField("描述（可选）", text: $description)
                }
                
                Section(header: Text("播放列表类型")) {
                    Toggle("智能播放列表", isOn: $isSmartPlaylist)
                    
                    if isSmartPlaylist {
                        Picker("情绪", selection: $selectedMood) {
                            Text("不限").tag(nil as DreamMusic.DreamMusicMood?)
                            ForEach(DreamMusic.DreamMusicMood.allCases, id: \.self) { mood in
                                Text(mood.rawValue).tag(mood as DreamMusic.DreamMusicMood?)
                            }
                        }
                        
                        Picker("节奏", selection: $selectedTempo) {
                            Text("不限").tag(nil as DreamMusic.DreamMusicTempo?)
                            ForEach(DreamMusic.DreamMusicTempo.allCases, id: \.self) { tempo in
                                Text(tempo.rawValue).tag(tempo as DreamMusic.DreamMusicTempo?)
                            }
                        }
                    }
                }
                
                if !isSmartPlaylist {
                    Section(header: Text("选择音乐")) {
                        ForEach(musicService.musicLibrary, id: \.id) { music in
                            HStack {
                                Image(systemName: music.mood.icon)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text(music.title)
                                        .font(.headline)
                                    Text("\(Int(music.duration / 60)):\(Int(music.duration.truncatingRemainder(dividingBy: 60)):02)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedMusicIds.contains(music.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedMusicIds.contains(music.id) ? .purple : .gray)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedMusicIds.contains(music.id) {
                                    selectedMusicIds.remove(music.id)
                                } else {
                                    selectedMusicIds.insert(music.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("新建播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createPlaylist()
                        dismiss()
                    }
                    .disabled(title.isEmpty || (!isSmartPlaylist && selectedMusicIds.isEmpty))
                }
            }
        }
    }
    
    private func createPlaylist() {
        if isSmartPlaylist {
            let criteria = DreamMusicPlaylist.SmartPlaylistCriteria(
                mood: selectedMood,
                tempo: selectedTempo
            )
            _ = playlistService.createSmartPlaylist(title: title, criteria: criteria)
        } else {
            _ = playlistService.createPlaylist(
                title: title,
                description: description.isEmpty ? nil : description,
                musicIds: Array(selectedMusicIds)
            )
        }
    }
}

// MARK: - 编辑播放列表视图

struct EditPlaylistView: View {
    @Environment(\.dismiss) var dismiss
    let playlist: DreamMusicPlaylist
    @ObservedObject private var playlistService = DreamMusicPlaylistService.shared
    @ObservedObject private var musicService = DreamMusicService.shared
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var isPlaying = false
    
    private var musicList: [DreamMusic] {
        if playlist.isSmartPlaylist {
            return playlistService.refreshSmartPlaylist(playlist, musicLibrary: musicService.musicLibrary)
        } else {
            return playlist.getMusic(from: musicService.musicLibrary)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 头部信息
                headerSection
                
                // 音乐列表
                musicListSection
            }
            .navigationTitle(playlist.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("分享播放列表", isPresented: $showingShareSheet) {
                Button("微信") {
                    // 分享到微信
                }
                Button("微博") {
                    // 分享到微博
                }
                Button("复制链接") {
                    // 复制链接
                }
            }
            .alert("删除播放列表", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    playlistService.deletePlaylist(playlist)
                    dismiss()
                }
            } message: {
                Text("确定要删除播放列表\"\(playlist.title)\"吗？此操作不可恢复。")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 封面
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 150)
                
                VStack(spacing: 8) {
                    Image(systemName: playlist.isSmartPlaylist ? "wand.and.stars" : "music.note.house")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text(playlist.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("\(musicList.count) 首音乐")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            
            // 操作按钮
            HStack(spacing: 20) {
                Button(action: { isPlaying.toggle() }) {
                    VStack {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                        Text(isPlaying ? "暂停" : "播放全部")
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                }
                
                Button(action: { showingShareSheet = true }) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                        Text("分享")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.title)
                        Text("删除")
                            .font(.caption)
                    }
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    private var musicListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(musicList, id: \.id) { music in
                    HStack {
                        Image(systemName: music.mood.icon)
                            .foregroundColor(.purple)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            Text(music.title)
                                .font(.headline)
                            Text(music.mood.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(music.duration / 60)):\(Int(music.duration.truncatingRemainder(dividingBy: 60)):02)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            playlistService.removeMusicFromPlaylist(playlist.id, musicId: music.id)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground).opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(.vertical)
        }
    }
}
