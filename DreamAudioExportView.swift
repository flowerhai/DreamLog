//
//  DreamAudioExportView.swift
//  DreamLog
//
//  梦境音频导出 - UI 界面
//  Phase 39: 梦境播客/音频导出功能
//

import SwiftUI
import SwiftData
import AVFoundation

// MARK: - 主界面

struct DreamAudioExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var configs: [AudioExportConfig] = []
    @State private var tasks: [AudioExportTask] = []
    @State private var stats: AudioExportStats = .empty
    @State private var showingConfigSheet = false
    @State private var showingExportSheet = false
    @State private var selectedConfig: AudioExportConfig?
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // 导出配置标签页
                configsTab
                    .tabItem {
                        Label("配置", systemImage: "slider.horizontal.3")
                    }
                    .tag(0)
                
                // 导出任务标签页
                tasksTab
                    .tabItem {
                        Label("任务", systemImage: "list.bullet.clipboard")
                    }
                    .tag(1)
                
                // 统计标签页
                statsTab
                    .tabItem {
                        Label("统计", systemImage: "chart.bar.fill")
                    }
                    .tag(2)
            }
            .navigationTitle("音频导出")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingConfigSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingConfigSheet) {
                AudioExportConfigSheet(config: selectedConfig) {
                    loadConfigs()
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let config = selectedConfig {
                    ExportProgressSheet(config: config)
                }
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    // MARK: - Configs Tab
    
    private var configsTab: some View {
        Group {
            if configs.isEmpty {
                emptyStateView
            } else {
                List {
                    // 预设配置
                    Section("预设配置") {
                        ForEach(PresetAudioExportConfig.presets) { preset in
                            PresetConfigRow(preset: preset) {
                                selectPreset(preset)
                            }
                        }
                    }
                    
                    // 自定义配置
                    Section("我的配置") {
                        ForEach(configs) { config in
                            ConfigRow(config: config) {
                                selectedConfig = config
                                showingConfigSheet = true
                            } onDelete: {
                                deleteConfig(config)
                            } onExport: {
                                selectedConfig = config
                                showingExportSheet = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tasks Tab
    
    private var tasksTab: some View {
        Group {
            if tasks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("暂无导出任务")
                        .font(.headline)
                    Text("创建导出配置后，开始你的第一个音频导出")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 100)
            } else {
                List {
                    ForEach(tasks) { task in
                        TaskRow(task: task) {
                            deleteTask(task)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Tab
    
    private var statsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 概览卡片
                OverviewStatsCard(stats: stats)
                
                // 格式分布
                if !stats.exportsByFormat.isEmpty {
                    DistributionCard(
                        title: "导出格式分布",
                        data: stats.exportsByFormat,
                        colorScheme: [.blue, .green, .orange]
                    )
                }
                
                // 质量分布
                if !stats.exportsByQuality.isEmpty {
                    DistributionCard(
                        title: "音质分布",
                        data: stats.exportsByQuality,
                        colorScheme: [.purple, .pink, .cyan]
                    )
                }
                
                // 最近导出
                if let lastDate = stats.lastExportDate {
                    LastExportCard(date: lastDate)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无导出配置")
                .font(.headline)
            Text("点击右上角 + 创建你的第一个音频导出配置")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingConfigSheet = true }) {
                Label("创建配置", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 100)
    }
    
    // MARK: - Actions
    
    private func loadData() async {
        let service = DreamAudioExportService(modelContext: modelContext)
        
        do {
            configs = try await service.getAllConfigs()
            tasks = try await service.getAllTasks()
            stats = try await service.getExportStats()
        } catch {
            print("加载数据失败：\(error)")
        }
    }
    
    private func loadConfigs() {
        Task {
            let service = DreamAudioExportService(modelContext: modelContext)
            configs = try await service.getAllConfigs()
        }
    }
    
    private func selectPreset(_ preset: PresetAudioExportConfig) {
        let config = AudioExportConfig(
            name: preset.name,
            format: preset.format,
            quality: preset.quality,
            exportRange: .last7Days,
            includeTags: preset.includeTags,
            includeEmotions: preset.includeEmotions,
            includeAIAnalysis: preset.includeAIAnalysis,
            includeIntro: preset.includeIntro,
            includeOutro: preset.includeOutro,
            addBackgroundMusic: preset.addBackgroundMusic
        )
        
        selectedConfig = config
        showingConfigSheet = true
    }
    
    private func deleteConfig(_ config: AudioExportConfig) {
        Task {
            let service = DreamAudioExportService(modelContext: modelContext)
            try await service.deleteConfig(config)
            await loadData()
        }
    }
    
    private func deleteTask(_ task: AudioExportTask) {
        Task {
            let service = DreamAudioExportService(modelContext: modelContext)
            try await service.deleteTask(task)
            await loadData()
        }
    }
}

// MARK: - Config Row

struct ConfigRow: View {
    let config: AudioExportConfig
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.headline)
                Text(formatConfigDescription(config))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onExport) {
                Image(systemName: "play.fill")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .swipeActions {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.accentColor)
        }
    }
    
    private func formatConfigDescription(_ config: AudioExportConfig) -> String {
        let format = AudioExportFormat(rawValue: config.format)?.displayName ?? config.format
        let quality = AudioQuality(rawValue: config.quality)?.displayName ?? config.quality
        return "\(format) · \(quality)"
    }
}

// MARK: - Preset Config Row

struct PresetConfigRow: View {
    let preset: PresetAudioExportConfig
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            Text(preset.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.headline)
                Text(preset.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: AudioExportTask
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                
                HStack {
                    statusBadge
                    Text("\(task.processedDreams)/\(task.totalDreams) 梦境")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if task.status == AudioExportStatus.completed.rawValue {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            } else if task.status == AudioExportStatus.processing.rawValue {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
    
    private var statusBadge: some View {
        let status = AudioExportStatus(rawValue: task.status) ?? .pending
        
        return Text(status.displayName)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(4)
    }
}

extension AudioExportStatus {
    var displayName: String {
        switch self {
        case .pending: return "等待中"
        case .processing: return "处理中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
}

// MARK: - Stats Cards

struct OverviewStatsCard: View {
    let stats: AudioExportStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("导出概览")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatItem(
                    icon: "music.note.list",
                    value: "\(stats.totalExports)",
                    label: "总导出"
                )
                
                StatItem(
                    icon: "clock",
                    value: formatDuration(stats.totalDuration),
                    label: "总时长"
                )
                
                StatItem(
                    icon: "externaldrive",
                    value: formatFileSize(stats.totalFileSize),
                    label: "总大小"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DistributionCard: View {
    let title: String
    let data: [String: Int]
    let colorScheme: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                HStack {
                    Circle()
                        .fill(colorScheme[index % colorScheme.count])
                        .frame(width: 12, height: 12)
                    
                    Text(formatKey(item.key))
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(item.value)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private func formatKey(_ key: String) -> String {
        if let format = AudioExportFormat(rawValue: key) {
            return format.displayName
        }
        if let quality = AudioQuality(rawValue: key) {
            return quality.displayName
        }
        return key
    }
}

struct LastExportCard: View {
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近导出")
                .font(.headline)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                
                Text(formatDate(date))
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Config Sheet

struct AudioExportConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String = ""
    @State private var format: AudioExportFormat = .m4a
    @State private var quality: AudioQuality = .high
    @State private var exportRange: AudioExportRange = .last7Days
    @State private var includeTags = true
    @State private var includeEmotions = true
    @State private var includeAIAnalysis = true
    @State private var includeIntro = true
    @State private var includeOutro = true
    @State private var voiceIdentifier = "com.apple.voice.compiled.zh-CN.Ting-Ting"
    @State private var speechRate: Float = 0.5
    @State private var addBackgroundMusic = false
    @State private var backgroundMusicVolume: Float = 0.3
    
    let config: AudioExportConfig?
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: $name)
                    
                    Picker("音频格式", selection: $format) {
                        ForEach(AudioExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    
                    Picker("音质", selection: $quality) {
                        ForEach(AudioQuality.allCases, id: \.self) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                    
                    Picker("导出范围", selection: $exportRange) {
                        ForEach(AudioExportRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
                
                Section("内容选项") {
                    Toggle("包含标签", isOn: $includeTags)
                    Toggle("包含情绪", isOn: $includeEmotions)
                    Toggle("包含 AI 解析", isOn: $includeAIAnalysis)
                }
                
                Section("语音设置") {
                    Toggle("包含片头", isOn: $includeIntro)
                    Toggle("包含片尾", isOn: $includeOutro)
                    
                    Picker("语音", selection: $voiceIdentifier) {
                        Text("Ting-Ting (女声)").tag("com.apple.voice.compiled.zh-CN.Ting-Ting")
                        Text("Mei-Jia (女声)").tag("com.apple.voice.compiled.zh-CN.Mei-Jia")
                        Text("Sin-Ji (男声)").tag("com.apple.voice.compiled.zh-CN.Sin-Ji")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("语速：\(speechRate, specifier: "%.1f")")
                            .font(.caption)
                        Slider(value: $speechRate, in: 0.3...1.0)
                    }
                }
                
                Section("背景音乐") {
                    Toggle("添加背景音乐", isOn: $addBackgroundMusic)
                    
                    if addBackgroundMusic {
                        VStack(alignment: .leading) {
                            Text("音乐音量：\(Int(backgroundMusicVolume * 100))%")
                                .font(.caption)
                            Slider(value: $backgroundMusicVolume, in: 0.1...0.5)
                        }
                    }
                }
            }
            .navigationTitle(config == nil ? "新建配置" : "编辑配置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveConfig()
                    }
                }
            }
            .onAppear {
                if let config = config {
                    name = config.name
                    format = AudioExportFormat(rawValue: config.format) ?? .m4a
                    quality = AudioQuality(rawValue: config.quality) ?? .high
                    exportRange = AudioExportRange(rawValue: config.exportRange) ?? .last7Days
                    includeTags = config.includeTags
                    includeEmotions = config.includeEmotions
                    includeAIAnalysis = config.includeAIAnalysis
                    includeIntro = config.includeIntro
                    includeOutro = config.includeOutro
                    voiceIdentifier = config.voiceIdentifier
                    speechRate = config.speechRate
                    addBackgroundMusic = config.addBackgroundMusic
                    backgroundMusicVolume = config.backgroundMusicVolume
                } else {
                    name = "我的导出配置"
                }
            }
        }
    }
    
    private func saveConfig() {
        let config = config ?? AudioExportConfig()
        config.name = name
        config.format = format.rawValue
        config.quality = quality.rawValue
        config.exportRange = exportRange.rawValue
        config.includeTags = includeTags
        config.includeEmotions = includeEmotions
        config.includeAIAnalysis = includeAIAnalysis
        config.includeIntro = includeIntro
        config.includeOutro = includeOutro
        config.voiceIdentifier = voiceIdentifier
        config.speechRate = speechRate
        config.addBackgroundMusic = addBackgroundMusic
        config.backgroundMusicVolume = backgroundMusicVolume
        
        modelContext.insert(config)
        
        try? modelContext.save()
        onSave()
        dismiss()
    }
}

// MARK: - Export Progress Sheet

struct ExportProgressSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let config: AudioExportConfig
    
    @State private var progress: Double = 0
    @State private var statusText = "准备中..."
    @State private var isExporting = false
    @State private var outputURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 进度指示器
                if isExporting {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .scaleEffect(y: 2)
                        .padding(.horizontal)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let url = outputURL {
                    // 完成状态
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("导出完成！")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Button(action: {
                        shareFile(url)
                    }) {
                        Label("分享音频", systemImage: "square.and.arrow.up")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("导出音频")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isExporting {
                        Button("取消") {
                            isExporting = false
                        }
                    } else {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                startExport()
            }
            .alert("导出失败", isPresented: $showError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startExport() {
        isExporting = true
        
        Task {
            let service = DreamAudioExportService(modelContext: modelContext)
            
            do {
                let dreams = try await service.getDreamsForExport(
                    range: AudioExportRange(rawValue: config.exportRange) ?? .last7Days
                )
                
                let task = try await service.createExportTask(config: config, dreams: dreams)
                
                let url = try await service.executeExport(
                    task: task,
                    config: config,
                    dreams: dreams
                ) { progress, text in
                    self.progress = progress
                    self.statusText = text
                }
                
                outputURL = url
                isExporting = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isExporting = false
            }
        }
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    DreamAudioExportView()
        .modelContainer(for: AudioExportConfig.self, inMemory: true)
}
