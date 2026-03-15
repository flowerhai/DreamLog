//
//  DreamVoiceJournalView.swift
//  DreamLog
//
//  Phase 51: 梦境语音日记与 AI 摘要 - UI 界面
//

import SwiftUI
import AVFoundation

// MARK: - 主界面

struct DreamVoiceJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: VoiceJournalViewModel
    @State private var isRecording = false
    @State private var showingSettings = false
    @State private var selectedEntry: VoiceJournalEntry?
    @State private var searchText = ""
    
    init(modelContext: ModelContext? = nil) {
        _viewModel = StateObject(wrappedValue: VoiceJournalViewModel(modelContext: modelContext ?? ModelContext()))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 统计卡片
                statsCard
                
                // 搜索栏
                searchBar
                
                // 列表
                entryList
                
                // 录音按钮
                recordButton
            }
            .navigationTitle("🎙️ 语音日记")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                VoiceJournalSettingsView()
            }
            .sheet(item: $selectedEntry) { entry in
                VoiceJournalDetailView(entry: entry)
            }
        }
        .task {
            await viewModel.loadEntries()
            await viewModel.loadStats()
        }
    }
    
    // MARK: - 统计卡片
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📊 统计概览")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatBox(
                    value: "\(viewModel.stats.totalEntries)",
                    label: "总条目",
                    icon: "📝"
                )
                
                StatBox(
                    value: formatDuration(viewModel.stats.totalDuration),
                    label: "总时长",
                    icon: "⏱️"
                )
                
                StatBox(
                    value: "\(viewModel.stats.favoriteCount)",
                    label: "收藏",
                    icon: "⭐"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - 搜索栏
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索语音日记...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onChange(of: searchText) { _, newValue in
            Task {
                await viewModel.search(query: newValue)
            }
        }
    }
    
    // MARK: - 列表
    
    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredEntries) { entry in
                    VoiceJournalCard(entry: entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }
                
                if viewModel.filteredEntries.isEmpty {
                    emptyState
                }
            }
            .padding()
        }
    }
    
    // MARK: - 空状态
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("还没有语音日记")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("点击下方按钮开始录音")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - 录音按钮
    
    private var recordButton: some View {
        VStack(spacing: 12) {
            if isRecording {
                Text("正在录音...")
                    .foregroundColor(.red)
                    .font(.caption)
                
                HStack(spacing: 30) {
                    // 取消按钮
                    Button(action: {
                        Task {
                            await viewModel.cancelRecording()
                            isRecording = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                    
                    // 停止按钮
                    Button(action: {
                        Task {
                            try? await viewModel.stopRecording()
                            isRecording = false
                            await viewModel.loadEntries()
                        }
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
            } else {
                Button(action: {
                    Task {
                        try? await viewModel.startRecording()
                        isRecording = true
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.title)
                        Text("按住说话")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .purple.opacity(0.3), radius: 10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - 统计卡片组件

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 日记卡片

struct VoiceJournalCard: View {
    let entry: VoiceJournalEntry
    @State private var isPlaying = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(formatDate(entry.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 情绪图标
                if let mood = entry.mood {
                    Text(mood.icon)
                        .font(.title2)
                }
                
                // 收藏图标
                Image(systemName: entry.isFavorite ? "star.fill" : "star")
                    .foregroundColor(entry.isFavorite ? .yellow : .gray)
            }
            
            // 摘要
            if let summary = entry.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 播放控制
            HStack {
                Button(action: {
                    // 播放/暂停
                    withAnimation {
                        isPlaying.toggle()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                
                // 进度条
                Slider(value: .constant(0), in: 0...1)
                    .disabled(true)
                
                Text(formatDuration(entry.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            // 标签
            if !entry.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.keywords.prefix(5), id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - 详情界面

struct VoiceJournalDetailView: View {
    let entry: VoiceJournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var playbackSpeed: Float = 1.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 播放器
                    playerCard
                    
                    // 转写文本
                    if let transcript = entry.transcript {
                        transcriptCard(transcript: transcript)
                    }
                    
                    // AI 摘要
                    if let summary = entry.summary {
                        summaryCard(summary: summary)
                    }
                    
                    // 元数据
                    metadataCard
                }
                .padding()
            }
            .navigationTitle("语音日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // 标记收藏
                    }) {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                    }
                }
            }
        }
    }
    
    // MARK: - 播放器卡片
    
    private var playerCard: some View {
        VStack(spacing: 16) {
            // 播放控制
            HStack(spacing: 30) {
                Button(action: {
                    // 快退 10 秒
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                }
                
                Button(action: {
                    withAnimation {
                        isPlaying.toggle()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    // 快进 10 秒
                }) {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                }
            }
            
            // 进度条
            Slider(value: $currentTime, in: 0...entry.duration)
            
            // 时间显示
            HStack {
                Text(formatTime(currentTime))
                Spacer()
                Text(formatTime(entry.duration))
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .monospacedDigit()
            
            // 速度控制
            HStack {
                Text("速度:")
                    .font(.caption)
                
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                    Button(action: {
                        playbackSpeed = speed
                    }) {
                        Text("\(speed)x")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(playbackSpeed == speed ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(playbackSpeed == speed ? .white : .primary)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 转写卡片
    
    private func transcriptCard(transcript: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundColor(.blue)
                Text("转写文本")
                    .font(.headline)
            }
            
            Text(transcript)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 摘要卡片
    
    private func summaryCard(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI 摘要")
                    .font(.headline)
            }
            
            Text(summary)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 元数据卡片
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                Text("详细信息")
                    .font(.headline)
            }
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("创建时间")
                        .foregroundColor(.secondary)
                    Text(formatDate(entry.createdAt))
                }
                
                GridRow {
                    Text("时长")
                        .foregroundColor(.secondary)
                    Text(formatDuration(entry.duration))
                }
                
                if let mood = entry.mood {
                    GridRow {
                        Text("情绪")
                            .foregroundColor(.secondary)
                        Text("\(mood.icon) \(mood.displayName)")
                    }
                }
                
                GridRow {
                    Text("播放次数")
                        .foregroundColor(.secondary)
                    Text("\(entry.playCount) 次")
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - 设置界面

struct VoiceJournalSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("voiceQuality") private var quality = "high"
    @AppStorage("autoTranscribe") private var autoTranscribe = true
    @AppStorage("autoSummarize") private var autoSummarize = true
    @AppStorage("maxDuration") private var maxDuration = 300
    
    var body: some View {
        NavigationStack {
            Form {
                Section("录音质量") {
                    Picker("音质", selection: $quality) {
                        Text("低 (64kbps)").tag("low")
                        Text("中 (128kbps)").tag("medium")
                        Text("高 (256kbps)").tag("high")
                        Text("无损 (FLAC)").tag("lossless")
                    }
                }
                
                Section("自动处理") {
                    Toggle("自动转写", isOn: $autoTranscribe)
                    Toggle("自动生成摘要", isOn: $autoSummarize)
                }
                
                Section("录音限制") {
                    Stepper("最长录音时长：\(maxDuration / 60) 分钟", value: $maxDuration, in: 60...600, step: 60)
                }
            }
            .navigationTitle("语音日记设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class VoiceJournalViewModel: ObservableObject {
    @Published var entries: [VoiceJournalEntry] = []
    @Published var filteredEntries: [VoiceJournalEntry] = []
    @Published var stats: VoiceJournalStats = .empty
    @Published var isLoading = false
    
    private let service: DreamVoiceJournalService
    
    init(modelContext: ModelContext) {
        // 初始化服务
        service = DreamVoiceJournalService(modelContext: modelContext)
    }
    
    func loadEntries() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            entries = try await service.getAllEntries()
            filteredEntries = entries
        } catch {
            print("加载失败：\(error)")
        }
    }
    
    func loadStats() async {
        do {
            stats = try await service.getStats()
        } catch {
            print("加载统计失败：\(error)")
        }
    }
    
    func search(query: String) async {
        if query.isEmpty {
            filteredEntries = entries
        } else {
            do {
                filteredEntries = try await service.search(query: query)
            } catch {
                print("搜索失败：\(error)")
            }
        }
    }
    
    func startRecording() async throws {
        _ = try await service.startRecording()
    }
    
    func stopRecording() async throws {
        _ = try await service.stopRecording()
    }
    
    func cancelRecording() async {
        try? await service.cancelRecording()
    }
}

#Preview {
    DreamVoiceJournalView()
}
