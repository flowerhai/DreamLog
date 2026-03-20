//
//  HomeView.swift
//  DreamLog
//
//  首页 - 梦境列表和记录入口
//

import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var speechService: SpeechService
    @State private var showingRecordSheet = false
    @State private var searchText = ""
    @State private var showingAdvancedSearch = false
    @AppStorage("siriTipDismissed") private var siriTipDismissed = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 快速记录区域
                QuickRecordSection(showingRecordSheet: $showingRecordSheet)
                    .padding()
                
                // Siri 快捷指令提示
                if !siriTipDismissed {
                    SiriShortcutTipCard(onDismiss: {
                        siriTipDismissed = true
                    })
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // 梦境回顾卡片 ✨ NEW (Phase 6)
                OnThisDayCard()
                    .environmentObject(dreamStore)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // 梦境故事卡片 ✨ NEW (Phase 8)
                DreamStoriesCard()
                    .environmentObject(dreamStore)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // 语音日记卡片 ✨ NEW (Phase 51)
                VoiceJournalCard()
                    .environmentObject(dreamStore)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // 晨间反思卡片 ✨ NEW (Phase 79)
                if #available(iOS 17.0, *) {
                    MorningReflectionCard()
                        .environmentObject(dreamStore)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // 模式预测卡片 ✨ NEW (Phase 55)
                PatternPredictionCard()
                    .environmentObject(dreamStore)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // 搜索栏
                HStack {
                    SearchBar(text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            dreamStore.filterDreams(searchText: newValue)
                        }
                    
                    Button(action: { showingAdvancedSearch = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // 热门标签
                TagFilterSection(tags: dreamStore.tags) { tag in
                    dreamStore.filterByTag(tag)
                }
                .padding(.vertical, 8)
                
                // 梦境列表
                DreamListSection(dreams: dreamStore.filteredDreams)
            }
            .navigationTitle("DreamLog 🌙")
            .sheet(isPresented: $showingRecordSheet) {
                RecordView()
            }
            .sheet(isPresented: $showingAdvancedSearch) {
                AdvancedSearchView()
                    .environmentObject(dreamStore)
            }
        }
    }
}

// MARK: - 快速记录区域
struct QuickRecordSection: View {
    @Binding var showingRecordSheet: Bool
    @EnvironmentObject var speechService: SpeechService
    
    var body: some View {
        VStack(spacing: 16) {
            Text("昨晚你梦见了什么？")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .accessibilityHidden(true)
            
            // 语音按钮
            Button(action: {
                showingRecordSheet = true
            }) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6B4E9A"), Color(hex: "9B7EBD")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        if speechService.isRecording {
                            // 录音中动画
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    .frame(width: 80 + CGFloat(index) * 20, height: 80 + CGFloat(index) * 20)
                                    .scaleEffect(1 + Double(index) * 0.2)
                                    .animation(
                                        Animation.easeOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.3)
                                    )
                            }
                        }
                        
                        Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Text(speechService.isRecording ? "松开结束" : "按住说话")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .longPressButtonAction(
                onPress: {
                    speechService.startRecording()
                },
                onRelease: {
                    speechService.stopRecording()
                }
            )
            .accessibilityLabel(speechService.isRecording ? "录音中，松开结束" : "语音记录梦境，按住说话")
            .accessibilityHint("长按按钮开始语音记录梦境")
            
            // 文字输入
            Button(action: { showingRecordSheet = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("文字输入")
                }
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }
            .accessibilityLabel("文字记录梦境")
            .accessibilityHint("双击打开文字输入界面记录梦境")
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("快速记录区域")
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索梦境、标签...", text: $text)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 标签过滤
struct TagFilterSection: View {
    let tags: [String]
    let onTagSelected: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(tags.prefix(10)), id: \.self) { tag in
                    Button(action: { onTagSelected(tag) }) {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white.opacity(0.9))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 梦境列表
struct DreamListSection: View {
    let dreams: [Dream]
    @EnvironmentObject var hapticService: DreamHapticFeedback
    
    var body: some View {
        ScrollView {
            if dreams.isEmpty {
                // 空状态 - 使用 DreamEmptyStates
                DreamListEmptyView(
                    hasSearched: false,
                    onRecordDream: {
                        hapticService.trigger(.success)
                    }
                )
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(dreams, id: \.id) { dream in
                        NavigationLink(destination: DreamDetailView(dream: dream)) {
                            DreamCard(dream: dream)
                                .onTapGesture {
                                    hapticService.trigger(.selection)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - 梦境卡片
struct DreamCard: View {
    let dream: Dream
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和操作
            HStack {
                Text(dream.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if dream.isLucid {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .accessibilityLabel("清醒梦")
                    }
                    
                    // 分享按钮
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel("分享梦境")
                }
            }
            
            Text(dream.date.formatted(.dateTime.month().day().hour().minute()))
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("记录时间：\(dream.date.formatted(.dateTime.month().day().hour().minute()))")
            
            // 内容预览
            Text(String(dream.content.prefix(100)))
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            // 标签
            HStack(spacing: 8) {
                ForEach(Array(dream.tags.prefix(3)), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            
            // 情绪和指标
            HStack {
                HStack(spacing: 4) {
                    ForEach(Array(dream.emotions.prefix(2)), id: \.self) { emotion in
                        Text(emotion.icon)
                            .accessibilityLabel(emotion.name)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(String(repeating: "⭐", count: dream.clarity))
                        .font(.caption2)
                        .accessibilityLabel("清晰度：\(dream.clarity)星")
                    Text(String(repeating: "🔥", count: dream.intensity))
                        .font(.caption2)
                        .accessibilityLabel("强度：\(dream.intensity)星")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("梦境：\(dream.title)")
        .accessibilityHint("双击查看详情")
        .sheet(isPresented: $showingShareSheet) {
            DreamShareSheet(dream: dream)
        }
    }
}

// MARK: - 分享弹窗
struct DreamShareSheet: View {
    let dream: Dream
    @Environment(\.dismiss) var dismiss
    @StateObject private var shareService = ShareService()
    @State private var selectedStyle: ShareCardStyle = .dreamy
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 样式选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择卡片样式")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ShareCardStyle.allCases, id: \.self) { style in
                                    StyleButton(
                                        style: style,
                                        isSelected: selectedStyle == style
                                    ) {
                                        selectedStyle = style
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 卡片预览
                    if isGenerating {
                        ProgressView("生成分享图片...")
                            .progressViewStyle(.circular)
                            .tint(.accentColor)
                            .frame(height: 300)
                    } else if let image = generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 375)
                            .cornerRadius(12)
                            .shadow(radius: 20)
                    } else {
                        DreamShareCard(dream: dream, style: selectedStyle)
                            .shadow(radius: 20)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 16) {
                        Button(action: saveToPhotos) {
                            Label("保存到相册", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isGenerating || generatedImage == nil)
                        
                        Button(action: shareImage) {
                            Label("分享", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isGenerating || generatedImage == nil)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("分享梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                generatePreview()
            }
            .onChange(of: selectedStyle) { _, _ in
                generatePreview()
            }
        }
    }
    
    private func generatePreview() {
        isGenerating = true
        Task {
            generatedImage = await shareService.generateShareImage(dream: dream, style: selectedStyle)
            isGenerating = false
        }
    }
    
    private func saveToPhotos() {
        guard let image = generatedImage else { return }
        Task {
            await shareService.saveToPhotos(image: image)
        }
    }
    
    private func shareImage() {
        guard let image = generatedImage else { return }
        let shareText = shareService.getShareText(dream: dream)
        let activityVC = UIActivityViewController(
            activityItems: [image, shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - 样式按钮
struct StyleButton: View {
    let style: ShareCardStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: style.backgroundColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .shadow(radius: isSelected ? 8 : 4)
                
                Text(style.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 梦境故事卡片

struct DreamStoriesCard: View {
    @EnvironmentObject var dreamStore: DreamStore
    @ObservedObject private var storyService = DreamStoryService.shared
    @State private var showingStories = false
    
    var storiesCount: Int {
        storyService.stories.count
    }
    
    var recentDreamsCount: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        return dreamStore.dreams.filter { $0.date >= thirtyDaysAgo }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        Text("梦境故事")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(storiesCount > 0 
                         ? "已创建 \(storiesCount) 个故事"
                         : "将梦境变成精彩故事")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingStories = true }) {
                    HStack(spacing: 4) {
                        Text(storiesCount > 0 ? "查看全部" : "开始创作")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // 快速操作
            if recentDreamsCount > 0 && storiesCount == 0 {
                HStack(spacing: 12) {
                    Button(action: { showingStories = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("生成故事")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6B4E9A").opacity(0.3), Color(hex: "9B7EBD").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "6B4E9A").opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingStories) {
            DreamStoryView()
        }
    }
}

// MARK: - 🎙️ 语音日记卡片 (Phase 51)

struct VoiceJournalCard: View {
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.modelContext) private var modelContext
    @State private var showingVoiceJournal = false
    @State private var entryCount: Int = 0
    @State private var totalDuration: TimeInterval = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        
                        Text("语音日记")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(entryCount > 0
                         ? "已录制 \(entryCount) 条语音日记 (\(formatDuration(totalDuration)))"
                         : "用语音快速记录梦境")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                
                Button(action: { showingVoiceJournal = true }) {
                    HStack(spacing: 4) {
                        Text(entryCount > 0 ? "查看日记" : "开始录制")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .accessibilityHidden(true)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                }
                .accessibilityLabel(entryCount > 0 ? "查看语音日记" : "开始录制语音日记")
            }
            
            // 快速操作提示
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                        .accessibilityHidden(true)
                    Text("AI 转写")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("AI 语音转写功能")
                
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                        .accessibilityHidden(true)
                    Text("智能摘要")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("AI 智能摘要功能")
                
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                        .accessibilityHidden(true)
                    Text("情绪分析")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("情绪分析功能")
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "E67E22").opacity(0.3), Color(hex: "F39C12").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "E67E22").opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("语音日记卡片")
        .accessibilityHint(entryCount > 0 ? "双击查看 \(entryCount) 条语音日记" : "双击开始录制语音日记")
        .task {
            await loadStats()
        }
        .sheet(isPresented: $showingVoiceJournal) {
            DreamVoiceJournalView(modelContext: modelContext)
        }
    }
    
    @MainActor
    private func loadStats() async {
        do {
            let service = DreamVoiceJournalService(modelContext: modelContext)
            let stats = try await service.getStats()
            entryCount = stats.totalEntries
            totalDuration = stats.totalDuration
        } catch {
            print("加载语音日记统计失败：\(error)")
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return "\(Int(seconds))秒"
        }
    }
}

// MARK: - 🌅 晨间反思卡片 (Phase 79)

@available(iOS 17.0, *)
struct MorningReflectionCard: View {
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.modelContext) private var modelContext
    @State private var showingReflection = false
    @State private var todayCount: Int = 0
    @State private var streakDays: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sunrise.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                            .accessibilityHidden(true)
                        
                        Text("晨间反思")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(streakDays > 0
                         ? "已连续反思 \(streakDays) 天，今天已完成 \(todayCount) 次"
                         : "每天花几分钟，从梦境中获得洞察")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                
                Button(action: { showingReflection = true }) {
                    HStack(spacing: 4) {
                        Text(todayCount > 0 ? "查看反思" : "开始反思")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .accessibilityHidden(true)
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                }
                .accessibilityLabel(todayCount > 0 ? "查看晨间反思" : "开始晨间反思")
            }
            
            // 快速操作提示
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                        .accessibilityHidden(true)
                    Text("洞察")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("获得梦境洞察")
                
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                        .accessibilityHidden(true)
                    Text("追踪")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("追踪反思进度")
                
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundColor(.yellow.opacity(0.8))
                        .accessibilityHidden(true)
                    Text("提醒")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("晨间提醒功能")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "F1C40F").opacity(0.3), Color(hex: "F39C12").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "F1C40F").opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("晨间反思卡片")
        .accessibilityHint(streakDays > 0 ? "双击查看今日反思" : "双击开始晨间反思")
        .task {
            await loadStats()
        }
        .sheet(isPresented: $showingReflection) {
            DreamMorningReflectionView()
        }
    }
    
    @MainActor
    private func loadStats() async {
        do {
            let service = DreamMorningReflectionService(modelContext: modelContext)
            let stats = try service.getStatistics()
            todayCount = stats.completedToday
            streakDays = stats.streakDays
        } catch {
            print("加载晨间反思统计失败：\(error)")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(DreamStore())
        .environmentObject(SpeechService())
}
