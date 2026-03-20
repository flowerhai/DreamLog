//
//  DreamVideoView.swift
//  DreamLog
//
//  Dream Video Generation UI - Phase 14
//  User interface for creating and sharing dream videos
//

import SwiftUI
import AVKit
import Photos

// MARK: - 梦境视频主界面

struct DreamVideoView: View {
    @ObservedObject private var videoService = DreamVideoService.shared
    @EnvironmentObject var dreamStore: DreamStore
    @ObservedObject private var templateMarket = DreamVideoTemplateMarket.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDream: Dream?
    @State private var showingConfigSheet = false
    @State private var showingVideoPlayer = false
    @State private var currentVideo: DreamVideo?
    @State private var videoConfig: DreamVideoConfig?
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var selectedTab = 0
    @State private var showingEditor = false
    @State private var showingTemplates = false
    @State private var videoToEdit: DreamVideo?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分段控制器
                Picker("标签", selection: $selectedTab) {
                    Text("我的视频").tag(0)
                    Text("模板市场").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    // 我的视频
                    Group {
                        if videoService.videos.isEmpty {
                            emptyStateView
                        } else {
                            videoGridView
                        }
                    }
                } else {
                    // 模板市场
                    TemplateMarketView()
                }
            }
            .navigationTitle("梦境视频")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 0 {
                        Button(action: { showingConfigSheet = true }) {
                            Label("新建", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingConfigSheet) {
                VideoConfigSheet(
                    dreamStore: dreamStore,
                    selectedDream: $selectedDream,
                    config: $videoConfig,
                    onStartGeneration: {
                        showingConfigSheet = false
                        startVideoGeneration()
                    }
                )
            }
            .sheet(isPresented: $showingVideoPlayer) {
                if let video = currentVideo {
                    VideoPlayerView(video: video, onShare: {
                        shareURL = URL(fileURLWithPath: video.filePath)
                        showingShareSheet = true
                    })
                }
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(activityItems: [url])
            }
            .onChange(of: videoService.isGenerating) { oldValue, newValue in
                if !newValue && videoService.generationProgress == 1.0 {
                    // 生成完成
                    currentVideo = videoService.videos.first
                    showingVideoPlayer = true
                }
            }
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "film")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            VStack(spacing: 12) {
                Text("还没有梦境视频")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("将你的梦境转化为精美的视频\n与朋友分享那些奇妙的夜晚")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingConfigSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("创建第一个视频")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 视频网格视图
    
    private var videoGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                ForEach(videoService.videos) { video in
                    VideoThumbnailCard(
                        video: video,
                        onTap: {
                            currentVideo = video
                            showingVideoPlayer = true
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - 视频生成
    
    private func startVideoGeneration() {
        guard let dream = selectedDream,
              let config = videoConfig else { return }
        
        Task {
            do {
                try await videoService.generateVideo(for: dream, config: config)
            } catch {
                print("视频生成失败：\(error)")
            }
        }
    }
}

// MARK: - 视频缩略图卡片

struct VideoThumbnailCard: View {
    let video: DreamVideo
    let onTap: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 缩略图
                ZStack(alignment: .bottomTrailing) {
                    if let image = loadImage(from: video.thumbnailPath) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    
                    // 播放按钮
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                        )
                        .padding(8)
                    
                    // 时长标签
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(formatDuration(video.duration))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(8)
                }
                .cornerRadius(12)
                
                // 视频信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Text(video.style)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(video.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: { showingDeleteAlert = true }) {
                Label("删除", systemImage: "trash")
            }
        }
        .alert("删除视频", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                DreamVideoService.shared.deleteVideo(video)
            }
        } message: {
            Text("确定要删除这个梦境视频吗？此操作不可撤销。")
        }
    }
    
    private func loadImage(from path: String) -> UIImage? {
        guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - 视频配置表单

struct VideoConfigSheet: View {
    @ObservedObject var dreamStore: DreamStore
    @Binding var selectedDream: Dream?
    @Binding var config: DreamVideoConfig?
    let onStartGeneration: () -> Void
    
    @State private var selectedStyle: DreamVideoConfig.VideoStyle = .cinematic
    @State private var selectedDuration: DreamVideoConfig.VideoDuration = .medium
    @State private var selectedAspectRatio: DreamVideoConfig.AspectRatio = .portrait
    @State private var selectedTransition: DreamVideoConfig.TransitionStyle = .fade
    @State private var includeMusic = true
    @State private var includeTextOverlay = true
    @State private var searchText = ""
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreamStore.dreams
        }
        return dreamStore.dreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 选择梦境
                Section {
                    TextField("搜索梦境...", text: $searchText)
                        .disableAutocorrection(true)
                    
                    if filteredDreams.isEmpty {
                        Text("没有找到匹配的梦境")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(filteredDreams) { dream in
                            Button(action: { selectedDream = dream }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dream.title)
                                            .font(.subheadline.bold())
                                        Text(formatDate(dream.createdAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedDream?.id == dream.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("选择梦境")
                }
                
                // 视频风格
                Section {
                    Picker("视频风格", selection: $selectedStyle) {
                        ForEach(DreamVideoConfig.VideoStyle.allCases) { style in
                            HStack {
                                Text(style.icon)
                                Text(style.rawValue)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(selectedStyle.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 视频时长
                Section {
                    Picker("视频时长", selection: $selectedDuration) {
                        ForEach(DreamVideoConfig.VideoDuration.allCases) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // 画面比例
                Section {
                    Picker("画面比例", selection: $selectedAspectRatio) {
                        ForEach(DreamVideoConfig.AspectRatio.allCases) { ratio in
                            Text(ratio.rawValue).tag(ratio)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 转场效果
                Section {
                    Picker("转场效果", selection: $selectedTransition) {
                        ForEach(DreamVideoConfig.TransitionStyle.allCases) { transition in
                            Text(transition.rawValue).tag(transition)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // 高级选项
                Section {
                    Toggle("包含背景音乐", isOn: $includeMusic)
                    Toggle("显示文字叠加", isOn: $includeTextOverlay)
                }
                
                // 预览信息
                if let dream = selectedDream {
                    Section {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading) {
                                Text(dream.title)
                                    .font(.subheadline.bold())
                                Text("\(dream.content.prefix(50))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    } header: {
                        Text("已选梦境")
                    }
                }
            }
            .navigationTitle("创建梦境视频")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("生成") {
                        guard let dream = selectedDream else { return }
                        
                        config = DreamVideoConfig(
                            dreamId: dream.id,
                            style: selectedStyle,
                            duration: selectedDuration,
                            includeMusic: includeMusic,
                            includeTextOverlay: includeTextOverlay,
                            aspectRatio: selectedAspectRatio,
                            transitionStyle: selectedTransition
                        )
                        
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onStartGeneration()
                    }
                    .fontWeight(.bold)
                    .disabled(selectedDream == nil)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - 视频播放器视图

struct VideoPlayerView: View {
    let video: DreamVideo
    let onShare: () -> Void
    
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(video.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                let url = URL(fileURLWithPath: video.filePath)
                player = AVPlayer(url: url)
            }
        }
    }
}

// MARK: - 模板市场视图

struct TemplateMarketView: View {
    @ObservedObject private var templateMarket = DreamVideoTemplateMarket.shared
    @ObservedObject private var videoService = DreamVideoService.shared
    @ObservedObject private var dreamStore = DreamStore.shared
    
    @State private var selectedTemplate: VideoTemplate?
    @State private var showingTemplateDetail = false
    @State private var showingConfigSheet = false
    @State private var selectedDream: Dream?
    
    var body: some View {
        Group {
            if templateMarket.isLoading {
                ProgressView("加载模板中...")
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 分类选择
                        categorySelector
                        
                        // 搜索框
                        searchField
                        
                        // 模板网格
                        templateGrid
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingTemplateDetail) {
            if let template = selectedTemplate {
                TemplateDetailView(
                    template: template,
                    isDownloaded: templateMarket.isDownloaded(template.id),
                    isFavorite: templateMarket.isFavorite(template.id),
                    onDownload: {
                        Task {
                            try? await templateMarket.downloadTemplate(template)
                        }
                    },
                    onToggleFavorite: {
                        templateMarket.toggleFavorite(template)
                    },
                    onUseTemplate: {
                        selectedTemplate = template
                        showingTemplateDetail = false
                        showingConfigSheet = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingConfigSheet) {
            VideoConfigSheet(
                dreamStore: dreamStore,
                selectedDream: $selectedDream,
                config: $videoConfig,
                onStartGeneration: {
                    showingConfigSheet = false
                    // 应用模板配置
                    startVideoGenerationWithTemplate()
                }
            )
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VideoTemplateCategory.allCases) { category in
                    Button(action: {
                        withAnimation {
                            templateMarket.selectedCategory = category
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.title2)
                            Text(category.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(templateMarket.selectedCategory == category ? Color.purple : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(templateMarket.selectedCategory == category ? .white : .primary)
                    }
                }
            }
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索模板...", text: $templateMarket.searchQuery)
                .textFieldStyle(.plain)
            
            if !templateMarket.searchQuery.isEmpty {
                Button(action: {
                    templateMarket.searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var templateGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(templateMarket.filteredTemplates) { template in
                TemplateCard(
                    template: template,
                    isDownloaded: templateMarket.isDownloaded(template.id),
                    isFavorite: templateMarket.isFavorite(template.id),
                    onTap: {
                        selectedTemplate = template
                        showingTemplateDetail = true
                    },
                    onToggleFavorite: {
                        templateMarket.toggleFavorite(template)
                    }
                )
            }
        }
    }
    
    private func startVideoGenerationWithTemplate() {
        // 使用模板配置生成视频
        Task {
            if let dream = selectedDream, let config = videoConfig {
                try? await videoService.generateVideo(for: dream, config: config)
            }
        }
    }
}

// MARK: - 模板卡片

struct TemplateCard: View {
    let template: VideoTemplate
    let isDownloaded: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 缩略图
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradientForCategory(template.category))
                    .aspectRatio(0.75, contentMode: .fit)
                    .overlay(
                        Image(systemName: template.isPremium ? "star.fill" : "film")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                    )
                
                // 收藏按钮
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                
                // 已下载标记
                if isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                        .offset(x: -50, y: 0)
                }
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(template.duration, specifier: "%.0f")s", systemImage: "clock")
                    Spacer()
                    Image(systemName: template.difficulty.icon)
                        .font(.caption)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private func gradientForCategory(_ category: VideoTemplateCategory) -> LinearGradient {
        switch category {
        case .featured:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .cinematic:
            return LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
        case .minimal:
            return LinearGradient(colors: [.white, .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        case .artistic:
            return LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .social:
            return LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        case .memory:
            return LinearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom)
        case .seasonal:
            return LinearGradient(colors: [.green, .yellow], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - 模板详情视图

struct TemplateDetailView: View {
    let template: VideoTemplate
    let isDownloaded: Bool
    let isFavorite: Bool
    let onDownload: () -> Void
    let onToggleFavorite: () -> Void
    let onUseTemplate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 预览图
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradientForCategory(template.category))
                        .aspectRatio(0.75, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: template.isPremium ? "star.fill" : "film")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(template.name)
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                            }
                        )
                        .padding()
                    
                    // 信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text(template.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // 标签
                        FlowLayout {
                            ForEach(template.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.purple.opacity(0.2)))
                                    .foregroundColor(.purple)
                            }
                        }
                        
                        Divider()
                        
                        // 详情
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                            GridRow {
                                Label("时长", systemImage: "clock")
                                Text("\(template.duration, specifier: "%.0f") 秒")
                            }
                            GridRow {
                                Label("比例", systemImage: "aspectratio")
                                Text(template.aspectRatio.rawValue)
                            }
                            GridRow {
                                Label("难度", systemImage: template.difficulty.icon)
                                Text(template.difficulty.rawValue)
                            }
                            GridRow {
                                Label("转场", systemImage: "arrow.triangle.2.circlepath")
                                Text(template.transitionStyle.name)
                            }
                            if let music = template.musicTrack {
                                GridRow {
                                    Label("音乐", systemImage: "music.note")
                                    Text(music.rawValue)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal)
                    
                    // 按钮
                    HStack(spacing: 16) {
                        Button(action: onToggleFavorite) {
                            Label(
                                isFavorite ? "已收藏" : "收藏",
                                systemImage: isFavorite ? "heart.fill" : "heart"
                            )
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if isDownloaded {
                            Button(action: onUseTemplate) {
                                Label("使用模板", systemImage: "wand.and.stars")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: onDownload) {
                                Label("下载", systemImage: "arrow.down.circle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("模板详情")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func gradientForCategory(_ category: VideoTemplateCategory) -> LinearGradient {
        switch category {
        case .featured: return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .cinematic: return LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
        case .minimal: return LinearGradient(colors: [.white, .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        case .artistic: return LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .social: return LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
        case .memory: return LinearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom)
        case .seasonal: return LinearGradient(colors: [.green, .yellow], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - 预览

#Preview {
    DreamVideoView()
}
