//
//  DreamStoryView.swift
//  DreamLog
//
//  梦境故事模式 UI 界面
//  Phase 70: Dream Story Mode - 将相关梦境串联成视觉故事
//

import SwiftUI
import SwiftData

// MARK: - 梦境故事主界面

struct DreamStoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stories: [DreamStory] = []
    @State private var stats: DreamStoryStats?
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingCreateSheet = false
    @State private var selectedStory: DreamStory?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if stories.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("梦境故事")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreateSheet = true }) {
                        Label("新建故事", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateStoryView()
            }
            .refreshable {
                await loadStories()
            }
        }
        .task {
            await loadStories()
        }
    }
    
    // MARK: - 子视图
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载故事中...")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "film")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("还没有梦境故事")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("将相关的梦境串联成美丽的视觉故事")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateSheet = true }) {
                Label("创建第一个故事", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 统计卡片
                if let stats = stats {
                    statsOverview(stats: stats)
                }
                
                // 故事列表
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 16
                ) {
                    ForEach(stories, id: \.id) { story in
                        StoryCardView(story: story)
                            .onTapGesture {
                                selectedStory = story
                            }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
        }
    }
    
    // MARK: - 统计概览
    
    private func statsOverview(stats: DreamStoryStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("故事概览")
                .font(.headline)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatCardView(
                    title: "总故事数",
                    value: "\(stats.totalStories)",
                    icon: "film",
                    color: .purple
                )
                
                StatCardView(
                    title: "总帧数",
                    value: "\(stats.totalFrames)",
                    icon: "square.grid.2x2",
                    color: .blue
                )
                
                StatCardView(
                    title: "总浏览",
                    value: "\(stats.totalViews)",
                    icon: "eye",
                    color: .green
                )
                
                StatCardView(
                    title: "总点赞",
                    value: "\(stats.totalLikes)",
                    icon: "heart",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 故事卡片

struct StoryCardView: View {
    let story: DreamStory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 封面
            ZStack {
                // 渐变背景
                LinearGradient(
                    colors: story.theme.colors.map { Color(hex: $0) ?? .purple },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                
                // Emoji 封面
                Text(story.coverEmoji)
                    .font(.system(size: 60))
                
                // 时长标签
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(formatDuration(story.duration))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    .padding(8)
                }
            }
            .cornerRadius(12)
            
            // 标题和信息
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(story.frames.count)", systemImage: "film")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(story.viewCount)", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(story.likeCount)", systemImage: "heart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - 统计卡片

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - 创建故事界面

struct CreateStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var config = DreamStoryConfig(
        title: "",
        description: "",
        selectedDreams: [],
        theme: .starry,
        storyType: .chronological,
        autoGenerateArt: true,
        autoGenerateNarration: true,
        frameDuration: 5.0,
        transition: .fade,
        coverEmoji: "🌙",
        tags: [],
        isPublic: false
    )
    @State private var showingDreamPicker = false
    @State private var isCreating = false
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("故事标题", text: $config.title)
                    TextField("故事描述", text: $config.description, axis: .vertical)
                }
                
                // 选择梦境
                Section("选择梦境") {
                    Button(action: { showingDreamPicker = true }) {
                        HStack {
                            Text("已选择 \(config.selectedDreams.count) 个梦境")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !config.selectedDreams.isEmpty {
                        ForEach(config.selectedDreams, id: \.self) { dreamId in
                            DreamPreviewRow(dreamId: dreamId)
                        }
                    }
                }
                
                // 故事设置
                Section("故事设置") {
                    Picker("主题", selection: $config.theme) {
                        ForEach(DreamStoryTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    
                    Picker("故事类型", selection: $config.storyType) {
                        ForEach(DreamStoryType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("封面 Emoji", selection: $config.coverEmoji) {
                        ForEach(["🌙", "✨", "💫", "🌟", "⭐", "🌠", "🎬", "📖"], id: \.self) { emoji in
                            Text(emoji).tag(emoji)
                        }
                    }
                }
                
                // 高级选项
                Section("高级选项") {
                    Toggle("自动生成 AI 艺术", isOn: $config.autoGenerateArt)
                    Toggle("自动生成旁白", isOn: $config.autoGenerateNarration)
                    
                    Stepper("每帧时长：\(Int(config.frameDuration))秒", value: $config.frameDuration, in: 3...15, step: 1)
                    
                    Picker("转场效果", selection: $config.transition) {
                        ForEach(DreamStoryTransition.allCases, id: \.self) { transition in
                            Text(transition.displayName).tag(transition)
                        }
                    }
                    
                    Toggle("公开故事", isOn: $config.isPublic)
                }
            }
            .navigationTitle("创建故事")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task {
                            await createStory()
                        }
                    }
                    .disabled(config.title.isEmpty || config.selectedDreams.isEmpty)
                    .disabled(isCreating)
                }
            }
            .sheet(isPresented: $showingDreamPicker) {
                DreamStoryPickerView(selectedDreamIds: $config.selectedDreams)
            }
        }
    }
    
    private func createStory() async {
        isCreating = true
        
        do {
            let service = DreamStoryService(modelContext: modelContext)
            _ = try await service.createStory(config: config)
            dismiss()
        } catch {
            showError = true
        }
        
        isCreating = false
    }
}

// MARK: - 梦境选择器

struct DreamStoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDreamIds: [UUID]
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var searchText = ""
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreams
        }
        return dreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredDreams) { dream in
                    Button(action: {
                        toggleDreamSelection(dream.id)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(dream.title)
                                    .font(.headline)
                                Text(dream.content.prefix(80))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if selectedDreamIds.contains(dream.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "搜索梦境")
            .navigationTitle("选择梦境")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成 (\(selectedDreamIds.count))") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleDreamSelection(_ id: UUID) {
        if let index = selectedDreamIds.firstIndex(of: id) {
            selectedDreamIds.remove(at: index)
        } else {
            selectedDreamIds.append(id)
        }
    }
}

// MARK: - 梦境预览行

struct DreamPreviewRow: View {
    let dreamId: UUID
    @Query(filter: #Predicate<Dream> { $0.id == UUID() }) var dream: Dream?
    
    init(dreamId: UUID) {
        self.dreamId = dreamId
        _dream = Query(
            filter: #Predicate<Dream> { $0.id == dreamId },
            sort: \Dream.date
        ).first()
    }
    
    var body: some View {
        if let dream = dream {
            HStack {
                Text(dream.title)
                    .font(.subheadline)
                Spacer()
                Text(dream.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 故事详情界面

struct StoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let story: DreamStory
    @State private var currentIndex = 0
    @State private var isPlaying = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 故事内容
                if !story.frames.isEmpty {
                    FrameView(frame: story.frames[currentIndex])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 控制栏
                controlBar
            }
            .navigationTitle(story.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private var controlBar: some View {
        VStack(spacing: 12) {
            // 进度指示器
            HStack(spacing: 4) {
                ForEach(0..<story.frames.count, id: \.self) { index in
                    Rectangle()
                        .frame(height: 3)
                        .foregroundColor(index == currentIndex ? .purple : .gray.opacity(0.3))
                        .animation(.easeInOut, value: currentIndex)
                }
            }
            .padding(.horizontal)
            
            // 播放控制
            HStack(spacing: 30) {
                Button(action: previousFrame) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .disabled(currentIndex == 0)
                
                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                
                Button(action: nextFrame) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .disabled(currentIndex == story.frames.count - 1)
            }
            .padding()
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
    }
    
    private func togglePlay() {
        isPlaying.toggle()
        // 实际实现中需要添加自动播放逻辑
    }
    
    private func nextFrame() {
        guard currentIndex < story.frames.count - 1 else { return }
        currentIndex += 1
    }
    
    private func previousFrame() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
}

// MARK: - 帧视图

struct FrameView: View {
    let frame: DreamStoryFrame
    @State private var showFullContent = false
    
    var body: some View {
        ZStack {
            // 背景
            if let imageData = frame.aiArtImage, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            
            // 内容
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text(frame.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    
                    Text(frame.content)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(showFullContent ? nil : 4)
                        .shadow(color: .black.opacity(0.5), radius: 1)
                    
                    if frame.content.count > 100 {
                        Button(action: { showFullContent.toggle() }) {
                            Text(showFullContent ? "收起" : "展开")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(15)
                        }
                    }
                    
                    if let narration = frame.narration {
                        Text(narration)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - 辅助扩展

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

// MARK: - 预览

#Preview {
    DreamStoryView()
        .modelContainer(for: Dream.self, inMemory: true)
}
