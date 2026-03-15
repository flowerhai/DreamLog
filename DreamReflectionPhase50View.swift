//
//  DreamReflectionPhase50View.swift
//  DreamLog
//
//  Phase 50: 反思功能增强 UI
//  导出/提醒/分享/冥想集成
//

import SwiftUI
import SwiftData

// MARK: - 主界面

/// Phase 50 反思增强主界面
struct DreamReflectionPhase50View: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var exportService: ReflectionExportService
    @StateObject private var reminderService: ReflectionReminderService
    @StateObject private var shareService: DreamReflectionShareService
    @StateObject private var meditationIntegration: ReflectionMeditationIntegration
    
    @Query(sort: \DreamReflection.createdAt, order: .reverse)
    private var reflections: [DreamReflection]
    
    @State private var selectedTab = 0
    @State private var showExportConfig = false
    @State private var showReminderSettings = false
    
    init() {
        _exportService = StateObject(wrappedValue: ReflectionExportService())
        _reminderService = StateObject(wrappedValue: ReflectionReminderService())
        _shareService = StateObject(wrappedValue: DreamReflectionShareService())
        _meditationIntegration = StateObject(wrappedValue: ReflectionMeditationIntegration())
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // 导出标签页
                ExportTabView(exportService: exportService, reflections: reflections)
                    .tabItem {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }
                    .tag(0)
                
                // 提醒标签页
                ReminderTabView(reminderService: reminderService)
                    .tabItem {
                        Label("提醒", systemImage: "bell")
                    }
                    .tag(1)
                
                // 分享标签页
                ShareTabView(shareService: shareService)
                    .tabItem {
                        Label("分享", systemImage: "person.2")
                    }
                    .tag(2)
                
                // 冥想标签页
                MeditationTabView(meditationIntegration: meditationIntegration, reflections: reflections)
                    .tabItem {
                        Label("冥想", systemImage: "figure.mind.and.body")
                    }
                    .tag(3)
            }
            .navigationTitle("反思增强")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showExportConfig = true }) {
                            Label("导出配置", systemImage: "gearshape")
                        }
                        Button(action: { showReminderSettings = true }) {
                            Label("提醒设置", systemImage: "bell.badge")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showExportConfig) {
                ExportConfigSheet(exportService: exportService)
            }
            .sheet(isPresented: $showReminderSettings) {
                ReminderSettingsSheet(reminderService: reminderService)
            }
        }
    }
}

// MARK: - 导出标签页

struct ExportTabView: View {
    @ObservedObject var exportService: ReflectionExportService
    var reflections: [DreamReflection]
    
    @State private var isExporting = false
    @State private var exportMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        List {
            Section("快速导出") {
                Button(action: exportQuick) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("PDF 日记")
                                .font(.headline)
                            Text("导出所有反思为精美 PDF")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
                
                Button(action: exportMarkdown) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Markdown")
                                .font(.headline)
                            Text("导出为 Markdown 格式")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .disabled(isExporting)
            }
            
            Section("统计") {
                HStack {
                    Text("总反思数")
                    Spacer()
                    Text("\(reflections.count)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("可导出")
                    Spacer()
                    Text("\(reflections.filter { !$0.isPrivate }.count)")
                        .fontWeight(.semibold)
                }
            }
            
            if !exportMessage.isEmpty {
                Section("状态") {
                    Text(exportMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("导出成功", isPresented: $showSuccess) {
            Button("在文件中查看", action: openInFiles)
            Button("完成", role: .cancel) {}
        } message: {
            Text("反思日记已导出到文件 App")
        }
    }
    
    private func exportQuick() {
        isExporting = true
        exportMessage = "正在生成 PDF..."
        
        Task {
            do {
                let config = ReflectionExportConfig.default
                config.format = .pdf
                let url = try await exportService.exportReflections(config: config)
                
                await MainActor.run {
                    isExporting = false
                    exportMessage = "导出完成：\(url.lastPathComponent)"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportMessage = "导出失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    private func exportMarkdown() {
        isExporting = true
        exportMessage = "正在生成 Markdown..."
        
        Task {
            do {
                let config = ReflectionExportConfig.default
                config.format = .markdown
                let url = try await exportService.exportReflections(config: config)
                
                await MainActor.run {
                    isExporting = false
                    exportMessage = "导出完成：\(url.lastPathComponent)"
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportMessage = "导出失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    private func openInFiles() {
        // TODO: 打开文件 App
    }
}

// MARK: - 提醒标签页

struct ReminderTabView: View {
    @ObservedObject var reminderService: ReflectionReminderService
    
    var body: some View {
        List {
            Section("状态") {
                HStack {
                    Image(systemName: reminderService.config.isEnabled ? "bell.fill" : "bell.slash.fill")
                        .foregroundColor(reminderService.config.isEnabled ? .green : .gray)
                    Text(reminderService.config.isEnabled ? "提醒已启用" : "提醒已禁用")
                }
            }
            
            Section("下次提醒") {
                Text("今天 21:00")
                    .font(.headline)
                Text("每天")
                    .foregroundColor(.secondary)
            }
            
            Section("提醒类型") {
                Toggle("每日提醒", isOn: .constant(true))
                Toggle("记录后提醒", isOn: .constant(reminderService.config.remindAfterDreamRecord))
                Toggle("睡前提醒", isOn: .constant(reminderService.config.remindBeforeSleep))
            }
        }
        .navigationTitle("反思提醒")
    }
}

// MARK: - 分享标签页

struct ShareTabView: View {
    @ObservedObject var shareService: DreamReflectionShareService
    
    @State private var myShares: [SharedReflection] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载中...")
            } else if myShares.isEmpty {
                ContentUnavailableView(
                    "暂无分享",
                    systemImage: "person.crop.circle.dashed",
                    description: Text("分享的反思会显示在这里")
                )
            } else {
                List(myShares) { share in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(share.reflectionType.icon)
                            Text(share.reflectionType.displayName)
                                .font(.headline)
                            Spacer()
                            Text(share.displayDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(share.content)
                            .lineLimit(3)
                            .font(.subheadline)
                        
                        HStack {
                            Label("\(share.likeCount)", systemImage: "heart")
                            Spacer()
                            Label("\(share.commentCount)", systemImage: "message")
                            Spacer()
                            Label("\(share.shareCount)", systemImage: "arrowshape.turn.up.right")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task {
            await loadMyShares()
        }
        .navigationTitle("我的分享")
    }
    
    private func loadMyShares() async {
        do {
            myShares = try await shareService.getMySharedReflections()
        } catch {
            print("加载分享失败：\(error)")
        }
        isLoading = false
    }
}

// MARK: - 冥想标签页

struct MeditationTabView: View {
    @ObservedObject var meditationIntegration: ReflectionMeditationIntegration
    var reflections: [DreamReflection]
    
    @State private var recommendations: [ReflectionMeditationRecommendation] = []
    
    var body: some View {
        List {
            Section("推荐冥想") {
                ForEach(recommendations.prefix(5), id: \.reflection.id) { recommendation in
                    NavigationLink {
                        MeditationDetailPage(recommendation: recommendation)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(recommendation.meditationType.icon)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text(recommendation.meditationType.rawValue)
                                        .font(.headline)
                                    Text("\(recommendation.duration) 分钟")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "play.circle")
                                    .foregroundColor(.blue)
                            }
                            
                            Text(recommendation.reason)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            
            if recommendations.isEmpty {
                Section {
                    Text("记录反思后，这里会显示个性化冥想推荐")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .task {
            generateRecommendations()
        }
        .navigationTitle("冥想推荐")
    }
    
    private func generateRecommendations() {
        recommendations = reflections.prefix(10).map { reflection in
            meditationIntegration.recommendMeditation(for: reflection)
        }
    }
}

struct MeditationDetailPage: View {
    let recommendation: ReflectionMeditationRecommendation
    
    @State private var isPlaying = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 冥想类型
                HStack {
                    Text(recommendation.meditationType.icon)
                        .font(.system(size: 50))
                    VStack(alignment: .leading) {
                        Text(recommendation.meditationType.rawValue)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(recommendation.meditationType.description)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 时长
                HStack {
                    Image(systemName: "clock")
                    Text("\(recommendation.duration) 分钟")
                }
                .font(.headline)
                
                // 推荐理由
                VStack(alignment: .leading, spacing: 8) {
                    Text("推荐理由")
                        .font(.headline)
                    Text(recommendation.reason)
                        .foregroundColor(.secondary)
                }
                
                // 开始按钮
                Button(action: { isPlaying = true }) {
                    HStack {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        Text(isPlaying ? "冥想中..." : "开始冥想")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // 反思内容预览
                VStack(alignment: .leading, spacing: 8) {
                    Text("相关反思")
                        .font(.headline)
                    Text(recommendation.reflection.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                }
            }
            .padding()
        }
        .navigationTitle("冥想详情")
    }
}

// MARK: - 配置表单

struct ExportConfigSheet: View {
    @ObservedObject var exportService: ReflectionExportService
    @Environment(\.dismiss) private var dismiss
    
    @State private var config = ReflectionExportConfig.default
    
    var body: some View {
        NavigationStack {
            Form {
                Section("导出格式") {
                    Picker("格式", selection: $config.format) {
                        ForEach(ReflectionExportConfig.ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }
                
                Section("日期范围") {
                    Picker("范围", selection: $config.dateRange) {
                        ForEach(ReflectionExportConfig.DateRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
                
                Section("内容选项") {
                    Toggle("包含私密反思", isOn: $config.includePrivate)
                    Toggle("包含行动项", isOn: $config.includeActionItems)
                    Toggle("包含标签", isOn: $config.includeTags)
                }
                
                Section("排序") {
                    Picker("排序方式", selection: $config.sortBy) {
                        ForEach(ReflectionExportConfig.SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    
                    Picker("顺序", selection: $config.sortOrder) {
                        ForEach(ReflectionExportConfig.SortOrder.allCases, id: \.self) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                }
            }
            .navigationTitle("导出配置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导出") {
                        // TODO: 执行导出
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReminderSettingsSheet: View {
    @ObservedObject var reminderService: ReflectionReminderService
    @Environment(\.dismiss) private var dismiss
    
    @State private var config: ReflectionReminderConfig
    
    init(reminderService: ReflectionReminderService) {
        _reminderService = ObservedObject(wrappedValue: reminderService)
        _config = State(initialValue: reminderService.config)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("启用提醒") {
                    Toggle("启用反思提醒", isOn: $config.isEnabled)
                }
                
                Section("提醒时间") {
                    DatePicker("提醒时间", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                }
                
                Section("提醒频率") {
                    Picker("频率", selection: $config.reminderFrequency) {
                        ForEach(ReflectionReminderConfig.ReminderFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                }
                
                Section("额外提醒") {
                    Toggle("记录梦境后提醒", isOn: $config.remindAfterDreamRecord)
                    Toggle("睡前提醒", isOn: $config.remindBeforeSleep)
                }
                
                Section("自定义消息") {
                    TextEditor(text: $config.customMessage)
                        .frame(height: 80)
                    Text("留空使用默认消息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("提醒设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        reminderService.config = config
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    DreamReflectionPhase50View()
        .modelContainer(for: DreamReflection.self, inMemory: true)
}
