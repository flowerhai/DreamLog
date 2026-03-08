//
//  DreamMusicView.swift
//  DreamLog
//
//  梦境音乐生成与播放界面
//  Phase 9 - AI 音乐增强功能
//

import SwiftUI

// MARK: - 梦境音乐主视图

struct DreamMusicView: View {
    @StateObject private var musicService = DreamMusicService.shared
    @State private var selectedDream: Dream?
    @State private var showingGenerator = false
    @State private var generatedMusic: DreamMusic?
    @State private var showingPlayer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                DreamBackgroundView()
                
                VStack(spacing: 0) {
                    // 头部
                    headerSection
                    
                    // 内容
                    ScrollView {
                        VStack(spacing: 20) {
                            // 快速生成卡片
                            quickGenerateCard
                            
                            // 我的音乐库
                            musicLibrarySection
                            
                            // 收藏
                            favoritesSection
                            
                            // 音乐情绪浏览
                            moodBrowseSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("梦境音乐")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingGenerator) {
                DreamMusicGeneratorView(dream: selectedDream)
            }
            .sheet(isPresented: $showingPlayer) {
                if let music = generatedMusic {
                    DreamMusicPlayerView(music: music)
                }
            }
        }
    }
    
    // MARK: - 头部
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("为梦境配乐")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("AI 根据你的梦境生成专属 ambient 音乐")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingGenerator = true }) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .padding(12)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
        }
    }
    
    // MARK: - 快速生成卡片
    
    private var quickGenerateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("快速生成")
                    .font(.headline)
                Spacer()
            }
            
            Text("选择最近的梦境，立即生成专属音乐")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 最近梦境选择器
            RecentDreamsPicker(selectedDream: $selectedDream)
            
            Button(action: {
                if selectedDream != nil {
                    showingGenerator = true
                }
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("生成梦境音乐")
                    Spacer()
                }
                .padding()
                .background(selectedDream == nil ? Color.gray.opacity(0.3) : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedDream == nil)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 音乐库部分
    
    private var musicLibrarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note.house")
                    .font(.title3)
                    .foregroundColor(.blue)
                Text("我的音乐库")
                    .font(.headline)
                Spacer()
                Text("\(musicService.musicLibrary.count) 首")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if musicService.musicLibrary.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("暂无音乐")
                        .foregroundColor(.secondary)
                    Text("为梦境生成音乐后会显示在这里")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 8) {
                    ForEach(musicService.musicLibrary.reversed()) { music in
                        MusicListItemView(music: music) {
                            generatedMusic = music
                            showingPlayer = true
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 收藏部分
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.pink)
                Text("收藏")
                    .font(.headline)
                Spacer()
            }
            
            let favorites = musicService.musicLibrary.filter { $0.isFavorite }
            
            if favorites.isEmpty {
                HStack {
                    Image(systemName: "heart")
                        .foregroundColor(.gray.opacity(0.5))
                    Text("收藏的音乐会显示在这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(favorites) { music in
                            MusicCardView(music: music, compact: true) {
                                generatedMusic = music
                                showingPlayer = true
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 情绪浏览部分
    
    private var moodBrowseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.purple)
                Text("按情绪浏览")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(DreamMusic.DreamMusicMood.allCases) { mood in
                    MoodCardView(mood: mood) {
                        // 筛选该情绪的音乐
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 最近梦境选择器

struct RecentDreamsPicker: View {
    @Binding var selectedDream: Dream?
    @StateObject private var dreamStore = DreamStore.shared
    
    var recentDreams: [Dream] {
        Array(dreamStore.dreams.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择梦境")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recentDreams) { dream in
                        Button(action: {
                            selectedDream = dream
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dream.title ?? "无题梦境")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text(dream.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .frame(width: 100, alignment: .leading)
                            .background(selectedDream?.id == dream.id ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
                            .foregroundColor(selectedDream?.id == dream.id ? .purple : .primary)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 音乐列表项

struct MusicListItemView: View {
    let music: DreamMusic
    let onTap: () -> Void
    @StateObject private var musicService = DreamMusicService.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 情绪图标
                ZStack {
                    Circle()
                        .fill(Color(hex: music.mood.color).opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: music.mood.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: music.mood.color))
                }
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(music.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label(music.mood.rawValue, systemImage: music.mood.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Label(formatDuration(music.duration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 播放按钮
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
            }
            .padding(8)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .contextMenu {
            // 播放
            Button(action: onTap) {
                Label("播放", systemImage: "play.fill")
            }
            
            // 导出
            Button(action: {
                Task {
                    await musicService.exportMusic(music)
                }
            }) {
                Label("导出音频", systemImage: "square.and.arrow.down")
            }
            
            // 分享
            Button(action: {
                Task {
                    await musicService.shareMusic(music)
                }
            }) {
                Label("分享", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            // 收藏
            Button(action: {
                musicService.toggleFavorite(music)
            }) {
                Label(music.isFavorite ? "取消收藏" : "收藏", 
                      systemImage: music.isFavorite ? "heart.slash.fill" : "heart.fill")
            }
            
            Divider()
            
            // 删除
            Button(role: .destructive, action: {
                musicService.deleteMusic(music)
            }) {
                Label("删除", systemImage: "trash")
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(secs, specifier: "%02d")"
    }
}

// MARK: - 音乐卡片

struct MusicCardView: View {
    let music: DreamMusic
    let compact: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 封面
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: music.mood.color).opacity(0.2))
                        .frame(width: compact ? 80 : 120, height: compact ? 80 : 120)
                    
                    Image(systemName: music.mood.icon)
                        .font(.system(size: compact ? 32 : 40))
                        .foregroundColor(Color(hex: music.mood.color))
                    
                    // 播放按钮
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.purple)
                        )
                }
                
                // 标题
                Text(music.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            .frame(width: compact ? 80 : 120, alignment: .leading)
        }
    }
}

// MARK: - 情绪卡片

struct MoodCardView: View {
    let mood: DreamMusic.DreamMusicMood
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: mood.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: mood.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: mood.color))
                }
                
                Text(mood.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - 梦境音乐生成器视图

struct DreamMusicGeneratorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var musicService = DreamMusicService.shared
    let dream: Dream?
    
    var body: some View {
        NavigationView {
            ZStack {
                DreamBackgroundView()
                
                VStack(spacing: 30) {
                    if musicService.isGenerating {
                        // 生成中
                        generatingView
                    } else if let music = musicService.currentMusic {
                        // 生成完成
                        completedView(music: music)
                    } else {
                        // 初始状态
                        initialView
                    }
                }
                .padding()
            }
            .navigationTitle("生成梦境音乐")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let dream = dream {
                    Task {
                        await musicService.generateMusic(for: dream)
                    }
                }
            }
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("准备生成梦境音乐")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("AI 将分析你的梦境内容，生成匹配的 ambient 音乐")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let dream = dream {
                VStack(alignment: .leading, spacing: 8) {
                    Text("梦境预览")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(dream.title ?? "无题")
                        .font(.headline)
                    
                    Text(dream.content.prefix(100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                if let dream = dream {
                    Task {
                        await musicService.generateMusic(for: dream)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("开始生成")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var generatingView: some View {
        VStack(spacing: 20) {
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: musicService.generationProgress)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: musicService.generationProgress)
                
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 8) {
                Text("正在生成梦境音乐...")
                    .font(.headline)
                
                Text("\(Int(musicService.generationProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text(generatingStepText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var generatingStepText: String {
        let progress = musicService.generationProgress
        if progress < 0.25 { return "分析梦境情绪..." }
        if progress < 0.5 { return "选择乐器和节奏..." }
        if progress < 0.75 { return "生成音频层..." }
        if progress < 1.0 { return "创建音乐..." }
        return "完成！"
    }
    
    private func completedView(music: DreamMusic) -> some View {
        VStack(spacing: 20) {
            // 成功图标
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("音乐生成成功！")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(music.title)
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            
            // 音乐信息卡片
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("情绪")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: music.mood.icon)
                            Text(music.mood.rawValue)
                        }
                        .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("时长")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(music.duration))
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("节奏")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: music.tempo.icon)
                            Text(music.tempo.rawValue.components(separatedBy: " ").first ?? "")
                        }
                        .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 乐器
                VStack(alignment: .leading, spacing: 8) {
                    Text("使用乐器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(music.instruments, id: \.rawValue) { instrument in
                            HStack(spacing: 4) {
                                Image(systemName: instrument.icon)
                                Text(instrument.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            
            // 操作按钮
            VStack(spacing: 12) {
                HStack(spacing: 15) {
                    Button(action: {
                        musicService.saveMusic(music)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("保存")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        musicService.play(music)
                        musicService.saveMusic(music)
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("播放")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                // 导出和分享按钮
                HStack(spacing: 15) {
                    Button(action: {
                        Task {
                            await musicService.exportMusic(music)
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square")
                            Text("导出")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        Task {
                            await musicService.shareMusic(music)
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("分享")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(secs, specifier: "%02d")"
    }
}

// MARK: - 梦境音乐播放器视图

struct DreamMusicPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var musicService = DreamMusicService.shared
    let music: DreamMusic
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: music.mood.color).opacity(0.3),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // 专辑封面
                    ZStack {
                        Circle()
                            .fill(Color(hex: music.mood.color).opacity(0.2))
                            .frame(width: 250, height: 250)
                        
                        Image(systemName: music.mood.icon)
                            .font(.system(size: 100))
                            .foregroundColor(Color(hex: music.mood.color))
                        
                        // 旋转动画
                        if isPlaying {
                            Circle()
                                .stroke(Color(hex: music.mood.color).opacity(0.3), lineWidth: 2)
                                .frame(width: 270, height: 270)
                                .rotationEffect(.degrees(Double(currentTime) * 10))
                        }
                    }
                    
                    // 音乐信息
                    VStack(spacing: 8) {
                        Text(music.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 15) {
                            Label(music.mood.rawValue, systemImage: music.mood.icon)
                                .font(.subheadline)
                            
                            Text("•")
                            
                            Label(formatDuration(music.duration), systemImage: "clock")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // 进度条
                    VStack(spacing: 8) {
                        Slider(
                            value: $currentTime,
                            in: 0...music.duration,
                            onEditingChanged: { _ in
                                musicService.seek(to: currentTime)
                            }
                        )
                        .tint(Color(hex: music.mood.color))
                        
                        HStack {
                            Text(formatDuration(currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatDuration(music.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 播放控制
                    HStack(spacing: 40) {
                        Button(action: {
                            currentTime = max(0, currentTime - 10)
                            musicService.seek(to: currentTime)
                        }) {
                            Image(systemName: "gobackward.10")
                                .font(.system(size: 30))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            if isPlaying {
                                musicService.pause()
                                isPlaying = false
                            } else {
                                musicService.play(music)
                                isPlaying = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: music.mood.color))
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Button(action: {
                            currentTime = min(music.duration, currentTime + 10)
                            musicService.seek(to: currentTime)
                        }) {
                            Image(systemName: "goforward.10")
                                .font(.system(size: 30))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // 乐器列表
                    VStack(alignment: .leading, spacing: 8) {
                        Text("乐器")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        FlowLayout(spacing: 6) {
                            ForEach(music.instruments, id: \.rawValue) { instrument in
                                HStack(spacing: 4) {
                                    Image(systemName: instrument.icon)
                                    Text(instrument.rawValue)
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.5))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("播放器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // 睡眠定时器按钮
                    Menu {
                        Button(action: { musicService.setSleepTimer(duration: 0) }) {
                            Label("关闭", systemImage: "timer")
                        }
                        Button(action: { musicService.setSleepTimer(duration: 15 * 60) }) {
                            Label("15 分钟", systemImage: "timer")
                        }
                        Button(action: { musicService.setSleepTimer(duration: 30 * 60) }) {
                            Label("30 分钟", systemImage: "timer")
                        }
                        Button(action: { musicService.setSleepTimer(duration: 45 * 60) }) {
                            Label("45 分钟", systemImage: "timer")
                        }
                        Button(action: { musicService.setSleepTimer(duration: 60 * 60) }) {
                            Label("1 小时", systemImage: "timer")
                        }
                        Button(action: { musicService.setSleepTimer(duration: 90 * 60) }) {
                            Label("90 分钟", systemImage: "timer")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: musicService.isSleepTimerActive ? "timer.fill" : "timer")
                                .foregroundColor(musicService.isSleepTimerActive ? .orange : .primary)
                            if musicService.isSleepTimerActive {
                                Text(musicService.formatSleepTimerRemaining())
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // 导出选项
                        Button(action: {
                            Task {
                                await musicService.exportMusic(music)
                            }
                        }) {
                            Label("导出音频", systemImage: "square.and.arrow.down")
                        }
                        
                        // 分享选项
                        Menu("分享到") {
                            Button(action: {
                                Task {
                                    await musicService.shareMusicToSocial(music, platform: .wechat)
                                }
                            }) {
                                Label("微信", systemImage: "message.fill")
                            }
                            Button(action: {
                                Task {
                                    await musicService.shareMusicToSocial(music, platform: .weibo)
                                }
                            }) {
                                Label("微博", systemImage: "weibo")
                            }
                            Button(action: {
                                Task {
                                    await musicService.shareMusicToSocial(music, platform: .qq)
                                }
                            }) {
                                Label("QQ", systemImage: "message.circle.fill")
                            }
                            Button(action: {
                                UIPasteboard.general.string = music.title
                            }) {
                                Label("复制链接", systemImage: "link")
                            }
                        }
                        
                        Divider()
                        
                        Button("完成") {
                            musicService.stop()
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(secs, specifier: "%02d")"
    }
}

// MARK: - 流动布局

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            var positions: [CGPoint] = []
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
            self.positions = positions
        }
    }
}

#Preview {
    DreamMusicView()
}
