//
//  DreamExportHubView.swift
//  DreamLog
//
//  Phase 52 - 梦境导出中心
//  创建时间：2026-03-16
//

import SwiftUI
import SwiftData

// MARK: - 主视图

/// 梦境导出中心主视图
struct DreamExportHubView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportTasks: [ExportTask] = []
    @State private var exportStats: ExportStats?
    @State private var showingNewTaskSheet = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationTitle("导出中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewTaskSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingNewTaskSheet) {
                NewExportTaskView {
                    Task {
                        await loadExportTasks()
                    }
                }
            }
            .task {
                await loadExportTasks()
            }
            .refreshable {
                await loadExportTasks()
            }
        }
    }
    
    // MARK: - 子视图
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载导出任务...")
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("加载失败")
                .font(.headline)
            Text(error)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("重试", action: refresh)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var contentView: some View {
        List {
            // 统计卡片
            if let stats = exportStats {
                statsSection(stats)
            }
            
            // 快速导出
            quickExportSection
            
            // 导出任务列表
            if !exportTasks.isEmpty {
                exportTasksSection
            }
            
            // 空状态
            if exportTasks.isEmpty {
                emptyStateView
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 统计部分
    
    private func statsSection(_ stats: ExportStats) -> some View {
        Section {
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    StatItemView(
                        icon: "square.and.arrow.up",
                        value: "\(stats.totalExports)",
                        label: "总导出"
                    )
                    
                    StatItemView(
                        icon: "doc.text",
                        value: "\(stats.totalDreamsExported)",
                        label: "导出梦境"
                    )
                    
                    StatItemView(
                        icon: "disk",
                        value: formatFileSize(stats.totalDataSize),
                        label: "总大小"
                    )
                }
                
                if let lastDate = stats.lastExportDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("上次导出：\(formatRelativeDate(lastDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("导出统计")
        }
    }
    
    // MARK: - 快速导出部分
    
    private var quickExportSection: some View {
        Section {
            QuickExportButton(
                icon: "doc.text",
                title: "导出为 Markdown",
                subtitle: "适合 Obsidian/Logseq"
            ) {
                Task {
                    await quickExport(platform: .markdown, format: .markdown)
                }
            }
            
            QuickExportButton(
                icon: "doc.richtext",
                title: "导出为 PDF",
                subtitle: "精美格式，适合分享"
            ) {
                Task {
                    await quickExport(platform: .pdf, format: .pdf)
                }
            }
            
            QuickExportButton(
                icon: "data",
                title: "导出为 JSON",
                subtitle: "原始数据格式"
            ) {
                Task {
                    await quickExport(platform: .json, format: .json)
                }
            }
            
            QuickExportButton(
                icon: "envelope",
                title: "通过邮件发送",
                subtitle: "分享给朋友"
            ) {
                Task {
                    await quickExport(platform: .email, format: .plainText)
                }
            }
        } header: {
            Text("快速导出")
        }
    }
    
    // MARK: - 导出任务列表
    
    private var exportTasksSection: some View {
        Section {
            ForEach(exportTasks) { task in
                ExportTaskRow(task: task)
                    .contextMenu {
                        Button(action: {
                            Task {
                                await executeTask(task)
                            }
                        }) {
                            Label("立即执行", systemImage: "play.fill")
                        }
                        
                        Button(action: {
                            Task {
                                try? await DreamExportHubService.shared.toggleExportTask(task, enabled: !task.isEnabled)
                                await loadExportTasks()
                            }
                        }) {
                            Label(task.isEnabled ? "禁用" : "启用", systemImage: task.isEnabled ? "pause.fill" : "play.fill")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            Task {
                                try? await DreamExportHubService.shared.deleteExportTask(task)
                                await loadExportTasks()
                            }
                        }) {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        } header: {
            Text("导出任务")
        }
    }
    
    // MARK: - 空状态
    
    private var emptyStateView: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up.trianglebadge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("暂无导出任务")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("点击右上角 + 创建新的导出任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    // MARK: - 操作
    
    private func loadExportTasks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let tasks = DreamExportHubService.shared.getAllExportTasks()
            async let stats = DreamExportHubService.shared.getExportStats()
            
            exportTasks = try await tasks
            exportStats = try await stats
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func refresh() {
        Task {
            await loadExportTasks()
        }
    }
    
    private func quickExport(platform: ExportPlatform, format: ExportFormat) async {
        do {
            let task = try await DreamExportHubService.shared.createExportTask(
                name: "快速导出 - \(platform.displayName)",
                platform: platform,
                format: format,
                exportAll: true,
                options: .default
            )
            
            _ = try await DreamExportHubService.shared.executeExportTask(task)
            
            await loadExportTasks()
        } catch {
            errorMessage = "导出失败：\(error.localizedDescription)"
        }
    }
    
    private func executeTask(_ task: ExportTask) async {
        do {
            _ = try await DreamExportHubService.shared.executeExportTask(task)
            await loadExportTasks()
        } catch {
            errorMessage = "执行失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 辅助方法
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 统计项视图

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 快速导出按钮

struct QuickExportButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 导出任务行

struct ExportTaskRow: View {
    let task: ExportTask
    
    var body: some View {
        HStack(spacing: 12) {
            // 平台图标
            VStack {
                Text(task.platformEnum.icon)
                    .font(.title2)
                Text(task.formatEnum.fileExtension.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            // 任务信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if !task.isEnabled {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    Label(task.platformEnum.displayName, systemImage: "square.grid.2x2")
                    
                    if let nextTime = task.nextExportTime {
                        Label(formatNextExport(nextTime), systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // 状态指示器
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(task.statusEnum.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if task.exportCount > 0 {
                        Text("• 已导出 \(task.exportCount) 次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 执行按钮
            if task.statusEnum == .pending || task.statusEnum == .scheduled {
                Button(action: {}) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch task.statusEnum {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .scheduled: return .purple
        }
    }
    
    private func formatNextExport(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "下次：\(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - 新建导出任务视图

struct NewExportTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onTaskCreated: () -> Void
    
    @State private var name = ""
    @State private var selectedPlatform: ExportPlatform = .markdown
    @State private var selectedFormat: ExportFormat = .markdown
    @State private var exportAll = true
    @State private var includeEmotions = true
    @State private var includeTags = true
    @State private var includeAIAnalysis = true
    @State private var includeImages = false
    @State private var isScheduled = false
    @State private var scheduledDate = Date()
    @State private var repeatInterval: String? = nil
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("任务名称", text: $name)
                        .textContentType(.name)
                } header: {
                    Text("基本信息")
                }
                
                Section {
                    Picker("导出平台", selection: $selectedPlatform) {
                        ForEach(ExportPlatform.allCases) { platform in
                            Label("\(platform.icon) \(platform.displayName)", systemImage: platform.icon)
                                .tag(platform)
                        }
                    }
                    
                    Picker("文件格式", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                } header: {
                    Text("导出设置")
                }
                
                Section {
                    Toggle("导出所有梦境", isOn: $exportAll)
                    
                    if !exportAll {
                        Text("选择梦境功能暂未实现")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section {
                    Toggle("包含情绪", isOn: $includeEmotions)
                    Toggle("包含标签", isOn: $includeTags)
                    Toggle("包含 AI 解析", isOn: $includeAIAnalysis)
                    Toggle("包含图片", isOn: $includeImages)
                } header: {
                    Text("内容选项")
                }
                
                Section {
                    Toggle("定时导出", isOn: $isScheduled)
                    
                    if isScheduled {
                        DatePicker("导出时间", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        
                        Picker("重复频率", selection: $repeatInterval) {
                            Text("不重复").tag(nil as String?)
                            Text("每天").tag("daily" as String?)
                            Text("每周").tag("weekly" as String?)
                            Text("每月").tag("monthly" as String?)
                        }
                    }
                } header: {
                    Text("定时设置")
                }
            }
            .navigationTitle("新建导出任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task {
                            await createTask()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createTask() async {
        let options = ExportOptions(
            includeEmotions: includeEmotions,
            includeTags: includeTags,
            includeAIAnalysis: includeAIAnalysis,
            includeImages: includeImages
        )
        
        do {
            _ = try await DreamExportHubService.shared.createExportTask(
                name: name,
                platform: selectedPlatform,
                format: selectedFormat,
                exportAll: exportAll,
                options: options,
                scheduledTime: isScheduled ? scheduledDate : nil,
                repeatInterval: repeatInterval
            )
            
            onTaskCreated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - 预览

#Preview {
    DreamExportHubView()
        .modelContainer(for: Dream.self, inMemory: true)
}
