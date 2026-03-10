//
//  DreamStoryView.swift
//  DreamLog
//
//  Dream Story Generation & Reading View - Phase 14
//  UI for creating and reading narrative stories from dreams
//

import SwiftUI

/// Dream Story View - Main container
struct DreamStoryView: View {
    @StateObject private var store = DreamStore.shared
    @State private var selectedDream: Dream?
    @State private var isGeneratingStory = false
    @State private var generatedStory: DreamStoryService.GeneratedStory?
    @State private var showGenrePicker = false
    @State private var selectedGenre: DreamStoryService.StoryGenre = .fantasy
    @State private var savedStories: [DreamStoryService.GeneratedStory] = []
    @State private var showStoryReader = false
    @State private var readingStory: DreamStoryService.GeneratedStory?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 0) {
                    // Header
                    storyHeader
                    
                    // Saved Stories List
                    if !savedStories.isEmpty {
                        savedStoriesSection
                    } else {
                        emptyStateView
                    }
                    
                    // Generate New Story Button
                    generateButton
                }
            }
            .navigationTitle("梦境故事")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshStories) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                loadSavedStories()
            }
            .sheet(isPresented: $showGenrePicker) {
                GenrePickerView(
                    selectedGenre: $selectedGenre,
                    onSelect: {
                        showGenrePicker = false
                        generateStory()
                    }
                )
            }
            .sheet(isPresented: $showStoryReader) {
                if let story = readingStory {
                    StoryReaderView(story: story, onDelete: deleteStory)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var storyHeader: some View {
        VStack(spacing: 16) {
            // Icon and title
            VStack(spacing: 8) {
                Text("📖")
                    .font(.system(size: 60))
                
                Text("梦境故事集")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("将你的梦境转化为精彩的故事")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            
            // Stats
            HStack(spacing: 30) {
                StatView(
                    value: "\(savedStories.count)",
                    label: "已创作故事",
                    icon: "📚"
                )
                
                StatView(
                    value: "\(DreamStoryService.StoryGenre.allCases.count)",
                    label: "故事风格",
                    icon: "🎭"
                )
            }
            .padding(.horizontal)
        }
        .background(Color.white.opacity(0.7))
        .cornerRadius(16)
        .padding()
    }
    
    // MARK: - Saved Stories Section
    
    private var savedStoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的故事集")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(savedStories, id: \.id) { story in
                        StoryCardView(story: story) {
                            readingStory = story
                            showStoryReader = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("还没有创作故事")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("选择一个梦境，开始你的故事创作之旅")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Generate Button
    
    private var generateButton: some View {
        Button(action: {
            showGenrePicker = true
        }) {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("创作新故事")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadSavedStories() {
        savedStories = DreamStoryService.shared.getAllStories()
    }
    
    private func refreshStories() {
        loadSavedStories()
    }
    
    private func generateStory() {
        isGeneratingStory = true
        
        // Get a random dream with sufficient content
        let dreams = store.dreams.filter { $0.content.count > 50 }
        
        guard let dream = dreams.randomElement() else {
            isGeneratingStory = false
            return
        }
        
        selectedDream = dream
        
        Task {
            do {
                let story = try await DreamStoryService.shared.generateStory(
                    from: dream,
                    genre: selectedGenre
                )
                
                DreamStoryService.shared.saveStory(story)
                generatedStory = story
                readingStory = story
                showStoryReader = true
                loadSavedStories()
            } catch {
                print("Story generation failed: \(error)")
            }
            
            isGeneratingStory = false
        }
    }
    
    private func deleteStory(id: UUID) {
        DreamStoryService.shared.deleteStory(id: id)
        loadSavedStories()
    }
}

// MARK: - Stat View

struct StatView: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
    }
}

// MARK: - Story Card View

struct StoryCardView: View {
    let story: DreamStoryService.GeneratedStory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(story.genre.icon)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(story.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(story.genre.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Info
                HStack(spacing: 16) {
                    Label("\(story.wordCount) 字", systemImage: "text.alignleft")
                    Label("\(story.readingTime) 分钟", systemImage: "clock")
                    
                    Spacer()
                    
                    Text(story.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Tags
                if !story.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(story.tags.prefix(5), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Genre Picker View

struct GenrePickerView: View {
    @Binding var selectedGenre: DreamStoryService.StoryGenre
    let onSelect: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("选择故事风格")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(DreamStoryService.StoryGenre.allCases) { genre in
                            GenreCard(
                                genre: genre,
                                isSelected: selectedGenre == genre
                            ) {
                                selectedGenre = genre
                                onSelect()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onSelect()
                    }
                }
            }
        }
    }
}

struct GenreCard: View {
    let genre: DreamStoryService.StoryGenre
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Text(genre.icon)
                    .font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(
                        isSelected ?
                        LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.1), .gray.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(12)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(genre.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(genre.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.2), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSelected ? Color.purple.opacity(0.1) : Color.clear)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Story Reader View

struct StoryReaderView: View {
    let story: DreamStoryService.GeneratedStory
    let onDelete: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false
    @State private var fontSize: CGFloat = 18
    @State private var isPlaying = false
    @ObservedObject private var speechService = SpeechSynthesisService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.05),
                        Color.blue.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Cover
                        storyCoverSection
                        
                        // Story content
                        storyContentSection
                        
                        // Actions
                        storyActionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("故事阅读")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Menu {
                            Button(action: { fontSize = max(14, fontSize - 2) }) {
                                Label("缩小字体", systemImage: "textformat.size.smaller")
                            }
                            
                            Button(action: { fontSize = min(28, fontSize + 2) }) {
                                Label("放大字体", systemImage: "textformat.size.larger")
                            }
                        } label: {
                            Image(systemName: "textformat.size")
                        }
                        
                        Button(action: { showShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Button(action: { showDeleteConfirm = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .confirmationDialog("删除故事", isPresented: $showDeleteConfirm) {
                Button("删除", role: .destructive) {
                    onDelete(story.id)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这个故事吗？此操作不可撤销。")
            }
            .onDisappear {
                // 视图消失时停止播放
                speechService.stop()
                isPlaying = false
            }
        }
    }
    
    // MARK: - Cover Section
    
    private var storyCoverSection: some View {
        VStack(spacing: 16) {
            // Genre icon
            Text(story.genre.icon)
                .font(.system(size: 80))
            
            // Title
            Text(story.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Metadata
            HStack(spacing: 20) {
                Label("\(story.wordCount) 字", systemImage: "text.alignleft")
                Label("\(story.readingTime) 分钟阅读", systemImage: "clock")
                Label(story.mood, systemImage: "heart")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(story.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .purple.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Content Section
    
    private var storyContentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(story.sections, id: \.order) { section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    Text(section.content)
                        .font(.custom("Georgia", size: fontSize))
                        .lineSpacing(6)
                        .foregroundColor(.primary)
                    
                    if section.order < story.sections.count {
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Actions Section
    
    private var storyActionsSection: some View {
        VStack(spacing: 12) {
            // Play button
            Button(action: togglePlayback) {
                HStack {
                    Image(systemName: playbackIcon)
                        .font(.title2)
                    Text(playbackButtonText)
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(speechService.isSpeaking && !speechService.isPaused && isPlaying == false)
            
            // Share button
            Button(action: { showShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享故事")
                        .font(.headline)
                }
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    
    private var playbackIcon: String {
        if speechService.isPaused {
            return "play.circle.fill"
        } else if speechService.isSpeaking && isPlaying {
            return "pause.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }
    
    private var playbackButtonText: String {
        if speechService.isPaused {
            return "继续朗读"
        } else if speechService.isSpeaking && isPlaying {
            return "暂停朗读"
        } else {
            return "朗读故事"
        }
    }
    
    // MARK: - Actions
    
    private func togglePlayback() {
        if speechService.isSpeaking {
            if speechService.isPaused {
                // 继续播放
                speechService.resume()
                isPlaying = true
            } else if isPlaying {
                // 暂停播放
                speechService.pause()
            } else {
                // 停止播放
                speechService.stop()
                isPlaying = false
            }
        } else {
            // 组合所有章节内容进行朗读
            let fullStoryText = story.sections
                .sorted { $0.order < $1.order }
                .map { "\($0.title)。\($0.content)" }
                .joined(separator: " ")
            
            speechService.speak(fullStoryText) { [weak self] in
                // 播放完成回调
                self?.isPlaying = false
            }
            isPlaying = true
        }
    }
}

// MARK: - Preview

struct DreamStoryView_Previews: PreviewProvider {
    static var previews: some View {
        DreamStoryView()
    }
}
