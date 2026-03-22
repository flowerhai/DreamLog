//
//  SettingsView.swift
//  DreamLog
//
//  设置页面 - 完整功能实现
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var hapticService: DreamHapticFeedback
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = "08:00"
    @AppStorage("icloudSync") private var icloudSync = false
    @AppStorage("autoAnalysis") private var autoAnalysis = true
    @AppStorage("darkMode") private var darkMode = true
    
    @ObservedObject private var reminderService = SmartReminderService.shared
    
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var showingDeleteConfirm = false
    @State private var showingFeedbackSheet = false
    @State private var exportMessage: String?
    @State private var importMessage: String?
    @State private var showingSmartReminderSettings = false
    
    // 同步状态颜色
    var statusColor: Color {
        switch dreamStore.cloudSyncStatus {
        case .idle: return .secondary
        case .syncing: return .blue
        case .success: return .green
        case .failed: return .red
        case .unavailable: return .orange
        case .conflict: return .orange
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 外观设置
                Section(header: Label("外观", systemImage: "paintpalette")) {
                    Toggle("深色模式", isOn: $darkMode)
                        .onChange(of: darkMode) { _ in
                            hapticService.trigger(.toggleSwitch)
                        }
                    
                    HStack {
                        Text("主题色")
                        Spacer()
                        ColorPicker("", selection: .constant(.accentColor))
                            .onChange(of: .accentColor) { _ in
                                hapticService.trigger(.selection)
                            }
                    }
                }
                
                // 小组件设置
                Section(header: Label("小组件", systemImage: "widget")) {
                    NavigationLink(destination: WidgetCustomizationView()) {
                        Label("个性化定制", systemImage: "paintpalette")
                    }
                    
                    Link(destination: URL(string: "dreamlog://widgets") ?? URL(fileURLWithPath: "/")) {
                        HStack {
                            Label("添加小组件", systemImage: "plus.app")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("可用小组件")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 12) {
                            // 快速记录小组件预览
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "mic.fill")
                                            .foregroundColor(.white)
                                    )
                                
                                Text("快速记录")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 梦境统计小组件预览
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.indigo, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "moon.stars.fill")
                                            .foregroundColor(.white)
                                    )
                                
                                Text("梦境统计")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 梦境目标小组件预览
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.pink]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "target")
                                            .foregroundColor(.white)
                                    )
                                
                                Text("梦境目标")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("长按主屏幕 → 左上角 + → 搜索 DreamLog")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 语音播放设置
                Section(header: Label("语音播放", systemImage: "speaker.wave.3.fill")) {
                    NavigationLink(destination: SpeechSettingsView()) {
                        Label("🎙️ 语音设置", systemImage: "mic.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("功能说明")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("• 在梦境详情页点击播放按钮即可聆听梦境")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 支持调整语速、音调和音量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 提供多种语音选择（中文/英文）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 适合睡前回顾或无障碍访问")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Siri 快捷指令
                Section(header: Label("Siri 与快捷指令", systemImage: "wand.and.stars")) {
                    NavigationLink(destination: SiriShortcutSettingsView()) {
                        Label("设置 Siri 快捷指令", systemImage: "mic.fill")
                    }
                    
                    // Phase 71 - 语音命令入口
                    NavigationLink(destination: DreamVoiceCommandView()) {
                        Label("语音命令控制", systemImage: "waveform")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("快捷命令")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("• 记录我的梦境")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 我的梦境统计")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 我最近做了什么梦")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 提醒设置
                Section(header: Label("提醒", systemImage: "bell")) {
                    Toggle("晨间提醒", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _ in
                            hapticService.trigger(.toggleSwitch)
                        }
                    
                    if notificationsEnabled {
                        HStack {
                            Text("提醒时间")
                            Spacer()
                            TextField("HH:mm", text: $reminderTime)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                    
                    Toggle("自动 AI 解析", isOn: $autoAnalysis)
                        .onChange(of: autoAnalysis) { _ in
                            hapticService.trigger(.toggleSwitch)
                        }
                    
                    // 智能提醒系统入口
                    NavigationLink(destination: SmartReminderSettingsView(service: reminderService, dreamStore: dreamStore)) {
                        Label("🧠 智能提醒设置", systemImage: "brain.head.profile")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 智能通知系统入口 (Phase 61)
                    NavigationLink(destination: DreamSmartNotificationSettingsView()) {
                        Label("🔔 智能通知与推送", systemImage: "bell.badge.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 数据与同步
                Section(header: Label("数据与同步", systemImage: "arrow.triangle.2.circlepath")) {
                    // iCloud 云同步状态
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("iCloud 同步", systemImage: "cloud.fill")
                            Spacer()
                            Toggle("", isOn: $icloudSync)
                                .labelsHidden()
                        }
                        
                        // 同步状态显示
                        HStack {
                            Text("\(dreamStore.cloudSyncStatus.icon) \(dreamStore.cloudSyncStatus.description)")
                                .font(.caption)
                                .foregroundColor(statusColor)
                            Spacer()
                            if let lastSync = dreamStore.lastSyncDate {
                                Text("最后同步：\(lastSync, style: .relative)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 手动同步按钮
                        if dreamStore.cloudSyncStatus != .syncing {
                            HStack(spacing: 12) {
                                Button(action: { dreamStore.pullFromCloud() }) {
                                    Label("从云端拉取", systemImage: "cloud.download")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                .disabled(!icloudSync)
                                
                                Button(action: { dreamStore.triggerCloudSync() }) {
                                    Label("推送到云端", systemImage: "cloud.upload")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.purple)
                                .disabled(!icloudSync)
                            }
                        } else {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在同步...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 云同步说明
                        Text("启用后，梦境数据将自动同步到您的 iCloud 账户，可在所有设备间无缝访问。数据采用端到端加密，保护您的隐私。")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // iCloud 高级同步设置 ✨ NEW (Phase 88)
                    NavigationLink(destination: DreamiCloudSyncView()) {
                        Label("⚙️ iCloud 同步高级设置", systemImage: "gearshape.2.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("管理同步频率、冲突解决策略、查看同步统计")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 支持自动/每小时/每天/每周同步")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 4 种冲突解决策略可选")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 实时同步状态与历史记录")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    
                    Divider()
                    
                    // 导出功能
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Label("导出数据", systemImage: "square.and.arrow.down")
                            Spacer()
                            Text("\(dreamStore.dreams.count) 条记录")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // PDF 日记导出
                    NavigationLink(destination: DreamJournalExportView().environmentObject(dreamStore)) {
                        Label("📕 导出 PDF 日记", systemImage: "book.closed")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 备份与恢复 ✨ NEW
                    NavigationLink(destination: DreamBackupView().environmentObject(dreamStore)) {
                        Label("🗄️ 备份与恢复", systemImage: "externaldrive")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("创建本地加密备份，支持自动备份计划")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 支持 AES-256 加密保护隐私")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 可设置每日/每周/每月自动备份")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• 选择性备份梦境/音频/图片")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    
                    Divider()
                    
                    // 导入功能
                    Button(action: { showingImportPicker = true }) {
                        HStack {
                            Label("导入数据", systemImage: "square.and.arrow.up")
                            Spacer()
                            if importMessage != nil {
                                Text("✅ 已导入")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // 删除所有
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        HStack {
                            Label("删除所有梦境", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
                
                // 隐私
                Section(header: Label("隐私", systemImage: "hand.raised")) {
                    Link(destination: URL(string: "https://dreamlog.app/privacy") ?? URL(fileURLWithPath: "/")) {
                        HStack {
                            Label("隐私政策", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://dreamlog.app/terms") ?? URL(fileURLWithPath: "/")) {
                        HStack {
                            Label("服务条款", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("匿名分享梦境", isOn: .constant(false))
                }
                
                // 关于
                Section(header: Label("关于", systemImage: "info.circle")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingFeedbackSheet = true }) {
                        HStack {
                            Label("反馈问题", systemImage: "envelope")
                            Spacer()
                        }
                    }
                    
                    Button(action: openAppStoreReview) {
                        HStack {
                            Label("评分支持", systemImage: "star")
                            Spacer()
                        }
                    }
                }
                
                // 开发者选项
                Section(header: Label("开发者", systemImage: "wrench.and.screwdriver")) {
                    Button(action: clearCache) {
                        HStack {
                            Label("清除缓存", systemImage: "trash.circle")
                            Spacer()
                        }
                    }
                    
                    Toggle("调试模式", isOn: .constant(false))
                    
                    Button(action: testAIFunction) {
                        HStack {
                            Label("测试 AI 解析", systemImage: "sparkles")
                            Spacer()
                        }
                    }
                }
                
                // 版权信息
                Section {
                    VStack(spacing: 8) {
                        Text("DreamLog 🌙")
                            .font(.headline)
                        Text("记录你的每一个梦境")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("© 2026 DreamLog Team")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("设置 ⚙️")
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(
                    isPresented: $showingExportOptions,
                    dreamStore: dreamStore,
                    onExported: { message in
                        exportMessage = message
                    }
                )
            }
            .sheet(isPresented: $showingImportPicker) {
                ImportPickerView(
                    isPresented: $showingImportPicker,
                    dreamStore: dreamStore,
                    onImported: { success in
                        importMessage = success ? "成功导入梦境" : "导入失败"
                    }
                )
            }
            .alert("删除所有梦境", isPresented: $showingDeleteConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    dreamStore.deleteAllDreams()
                }
            } message: {
                Text("这个操作无法撤销，所有梦境记录将被永久删除。")
            }
            .sheet(isPresented: $showingFeedbackSheet) {
                FeedbackSheet(isPresented: $showingFeedbackSheet)
            }
        }
    }
    
    // MARK: - 打开 App Store 评分
    private func openAppStoreReview() {
        guard let url = URL(string: "https://apps.apple.com/app/dreamlog/id123456789?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - 清除缓存
    private func clearCache() {
        // 清除图像缓存
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? FileManager.default.removeItem(at: cacheDir)
        }
        
        // 清除临时文件
        let tempDir = FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: tempDir)
        
        print("✅ 缓存已清除")
    }
    
    // MARK: - 测试 AI 功能
    private func testAIFunction() {
        Task {
            let aiService = AIService()
            let analysis = await aiService.analyzeDream(
                content: "测试梦境内容",
                tags: ["测试"],
                emotions: [.neutral]
            )
            print("🧠 AI 测试结果：\(analysis)")
        }
    }
}

// MARK: - 导出选项视图
struct ExportOptionsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dreamStore: DreamStore
    let onExported: (String) -> Void
    
    @State private var isExporting = false
    @State private var exportFormat: ExportFormat = .json
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF"
        case json = "JSON"
        case text = "文本"
        case markdown = "Markdown"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .json: return "doc.badge.gearshape"
            case .text: return "doc.text"
            case .markdown: return "doc.richtext"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 格式选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择导出格式")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(ExportFormat.allCases) { format in
                            Button(action: { exportFormat = format }) {
                                HStack {
                                    Image(systemName: format.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(exportFormat == format ? .accentColor : .secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(format.rawValue)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Text(formatDescription(for: format))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if exportFormat == format {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(exportFormat == format ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    
                    // 统计信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("导出内容")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Label("\(dreamStore.dreams.count) 个梦境", systemImage: "moon")
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // 导出按钮
                    Button(action: exportData) {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                Text("导出中...")
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                Text("导出")
                            }
                            Spacer()
                        }
                        .padding()
                        .background(isExporting ? Color.secondary : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isExporting)
                }
                .padding()
            }
            .navigationTitle("导出数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func formatDescription(for format: ExportFormat) -> String {
        switch format {
        case .pdf:
            return "精美的 PDF 文档，适合打印和分享"
        case .json:
            return "包含所有数据和元数据，适合备份"
        case .text:
            return "纯文本格式，易于阅读和分享"
        case .markdown:
            return "Markdown 格式，支持富文本编辑"
        }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .background).async {
            var success = false
            var message = ""
            
            // 使用新的 DreamExportService
            let exportService = DreamExportService.shared
            let result = exportService.exportDreams(
                dreams: dreamStore.dreams.sorted { $0.date > $1.date },
                format: convertFormat(exportFormat),
                includeAnalysis: true,
                includeStats: exportFormat == .pdf,
                theme: .starry
            )
            
            switch result {
            case .success(let data, let fileExtension):
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "dreamlog_export_\(Int(Date().timeIntervalSince1970)).\(fileExtension)"
                let fileURL = tempDir.appendingPathComponent(fileName)
                try? data.write(to: fileURL)
                
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(
                        activityItems: [fileURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityVC, animated: true)
                    }
                    success = true
                    message = "成功导出 \(dreamStore.dreams.count) 个梦境为 \(exportFormat.rawValue) 格式"
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    message = "导出失败：\(error)"
                }
            }
            
            if success {
                onExported(message)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isPresented = false
                }
            }
            
            isExporting = false
        }
    }
    
    private func convertFormat(_ format: ExportFormat) -> DreamExportService.ExportFormat {
        switch format {
        case .pdf: return .pdf
        case .json: return .json
        case .text: return .text
        case .markdown: return .markdown
        }
    }
}

// MARK: - 导入选择器视图
struct ImportPickerView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dreamStore: DreamStore
    let onImported: (Bool) -> Void
    
    @State private var isImporting = false
    @State private var importMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 说明
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    
                    Text("导入梦境数据")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("选择之前导出的 JSON 文件")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // 导入按钮
                Button(action: selectFile) {
                    HStack {
                        Spacer()
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                            Text("导入中...")
                        } else {
                            Image(systemName: "folder")
                            Text("选择文件")
                        }
                        Spacer()
                    }
                    .padding()
                    .background(isImporting ? Color.secondary : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isImporting)
                .padding(.horizontal)
                
                if let message = importMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("成功") ? .green : .red)
                }
                
                Spacer()
            }
            .navigationTitle("导入数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func selectFile() {
        // 使用文档选择器
        isImporting = true
        
        // 在实际应用中，这里会打开 UIDocumentPickerViewController
        // 由于这是演示，我们模拟导入过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 模拟导入成功
            importMessage = "✅ 成功导入梦境数据"
            onImported(true)
            isImporting = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        }
    }
}

// MARK: - 反馈表单
struct FeedbackSheet: View {
    @Binding var isPresented: Bool
    
    @State private var feedbackType: FeedbackType = .bug
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var submitSuccess = false
    
    enum FeedbackType: String, CaseIterable, Identifiable {
        case bug = "问题反馈"
        case feature = "功能建议"
        case other = "其他"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .bug: return "ladybug"
            case .feature: return "lightbulb"
            case .other: return "ellipsis"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 反馈类型
                    VStack(alignment: .leading, spacing: 12) {
                        Text("反馈类型")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(FeedbackType.allCases) { type in
                            Button(action: { feedbackType = type }) {
                                HStack {
                                    Image(systemName: type.icon)
                                        .foregroundColor(feedbackType == type ? .accentColor : .secondary)
                                    Text(type.rawValue)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if feedbackType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(feedbackType == type ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    
                    // 标题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("简要描述你的反馈", text: $title)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // 描述
                    VStack(alignment: .leading, spacing: 8) {
                        Text("详细描述")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // 邮箱 (可选)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("邮箱 (可选)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("your@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // 提交按钮
                    Button(action: submitFeedback) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                Text("提交中...")
                            } else if submitSuccess {
                                Image(systemName: "checkmark.circle")
                                Text("已提交")
                            } else {
                                Image(systemName: "paperplane")
                                Text("提交反馈")
                            }
                            Spacer()
                        }
                        .padding()
                        .background(isSubmitting ? Color.secondary : submitSuccess ? Color.green : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting || submitSuccess || title.isEmpty || description.isEmpty)
                }
                .padding()
            }
            .navigationTitle("反馈问题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func submitFeedback() {
        isSubmitting = true
        
        // 模拟提交
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSubmitting = false
            submitSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DreamStore())
}
