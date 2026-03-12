//
//  DreamBackupView.swift
//  DreamLog
//
//  Phase 29 - Dream Backup & Restore System
//  User interface for backup and restore operations
//

import SwiftUI
import SwiftData

struct DreamBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backupService = BackupServiceViewModel()
    
    @Query(sort: \BackupHistory.backupDate, order: .reverse)
    private var backupHistory: [BackupHistory]
    
    @State private var selectedTab = 0
    @State private var showingPasswordSheet = false
    @State private var backupPassword = ""
    @State private var restoreFileURL: URL?
    @State private var showingRestoreConfirmation = false
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Backup Tab
                BackupTabView(
                    backupService: backupService,
                    showingPasswordSheet: $showingPasswordSheet,
                    backupPassword: $backupPassword
                )
                .tabItem {
                    Label("创建备份", systemImage: "square.and.arrow.up")
                }
                .tag(0)
                
                // Restore Tab
                RestoreTabView(
                    backupService: backupService,
                    restoreFileURL: $restoreFileURL,
                    showingPasswordSheet: $showingPasswordSheet,
                    backupPassword: $backupPassword,
                    showingRestoreConfirmation: $showingRestoreConfirmation
                )
                .tabItem {
                    Label("恢复备份", systemImage: "square.and.arrow.down")
                }
                .tag(1)
                
                // History Tab
                HistoryTabView(
                    backupHistory: backupHistory,
                    backupService: backupService
                )
                .tabItem {
                    Label("备份历史", systemImage: "clock")
                }
                .tag(2)
                
                // Settings Tab
                SettingsTabView(
                    backupService: backupService,
                    modelContext: modelContext
                )
                .tabItem {
                    Label("自动备份", systemImage: "gear")
                }
                .tag(3)
            }
            .navigationTitle("备份与恢复")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPasswordSheet) {
                PasswordSheet(
                    password: $backupPassword,
                    showingPasswordSheet: $showingPasswordSheet,
                    action: .backup
                )
            }
            .confirmationDialog("确认恢复", isPresented: $showingRestoreConfirmation) {
                Button("恢复", role: .destructive) {
                    if let url = restoreFileURL {
                        Task {
                            await backupService.restoreBackup(from: url, password: backupPassword.isEmpty ? nil : backupPassword)
                        }
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("恢复操作将导入备份中的梦境数据。是否继续？")
            }
            .onChange(of: backupService.restoreTrigger) { oldValue, newValue in
                if newValue > oldValue {
                    showingRestoreConfirmation = true
                }
            }
        }
    }
}

// MARK: - Backup Tab

struct BackupTabView: View {
    @ObservedObject var backupService: BackupServiceViewModel
    @Binding var showingPasswordSheet: Bool
    @Binding var backupPassword: String
    
    @State private var includeAllDreams = true
    @State private var includeAudio = true
    @State private var includeImages = true
    @State private var encryptBackup = false
    @State private var dateRangeStart = Date().addingTimeInterval(-7 * 24 * 3600)
    @State private var dateRangeEnd = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Backup Options Section
                BackupOptionsSection(
                    includeAllDreams: $includeAllDreams,
                    dateRangeStart: $dateRangeStart,
                    dateRangeEnd: $dateRangeEnd,
                    includeAudio: $includeAudio,
                    includeImages: $includeImages,
                    encryptBackup: $encryptBackup
                )
                
                // Progress Section
                if backupService.isBackingUp {
                    BackupProgressSection(progress: backupService.progress)
                }
                
                // Result Section
                if let result = backupService.lastBackupResult {
                    BackupResultSection(result: result)
                }
                
                // Create Backup Button
                Button(action: createBackup) {
                    HStack {
                        Image(systemName: backupService.isBackingUp ? "hourglass" : "square.and.arrow.up")
                            .font(.title2)
                        Text(backupService.isBackingUp ? "备份中..." : "创建备份")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(backupService.isBackingUp)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("创建备份")
    }
    
    private func createBackup() {
        let options = BackupOptions(
            includeAllDreams: includeAllDreams,
            dateRange: includeAllDreams ? nil : (start: dateRangeStart, end: dateRangeEnd),
            includeAudio: includeAudio,
            includeImages: includeImages,
            includeMetadata: true,
            encryptBackup: encryptBackup,
            backupPassword: encryptBackup ? backupPassword : nil
        )
        
        if encryptBackup && backupPassword.isEmpty {
            showingPasswordSheet = true
            return
        }
        
        Task {
            await backupService.createBackup(options: options)
        }
    }
}

struct BackupOptionsSection: View {
    @Binding var includeAllDreams: Bool
    @Binding var dateRangeStart: Date
    @Binding var dateRangeEnd: Date
    @Binding var includeAudio: Bool
    @Binding var includeImages: Bool
    @Binding var encryptBackup: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("备份选项")
                .font(.headline)
            
            // Date Range
            VStack(alignment: .leading, spacing: 8) {
                Toggle("备份所有梦境", isOn: $includeAllDreams)
                
                if !includeAllDreams {
                    VStack(spacing: 12) {
                        DatePicker("开始日期", selection: $dateRangeStart, displayedComponents: .date)
                        DatePicker("结束日期", selection: $dateRangeEnd, displayedComponents: .date)
                    }
                    .padding(.leading)
                }
            }
            
            Divider()
            
            // Content Options
            Toggle("包含音频录音", isOn: $includeAudio)
            Toggle("包含梦境图片", isOn: $includeImages)
            
            Divider()
            
            // Security
            VStack(alignment: .leading, spacing: 8) {
                Toggle("加密备份文件", isOn: $encryptBackup)
                
                if encryptBackup {
                    Text("🔒 备份将使用 AES-256 加密保护")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BackupProgressSection: View {
    let progress: BackupProgress
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(progress.message)
                    .font(.subheadline)
                Spacer()
                Text("\(progress.currentDreamIndex)/\(progress.totalDreamCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(progress.currentDreamIndex), total: Double(progress.totalDreamCount))
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BackupResultSection: View {
    let result: BackupResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.success ? "备份成功！" : "备份失败")
                    .font(.headline)
                
                Spacer()
            }
            
            if result.success {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("梦境数量：")
                            .foregroundColor(.secondary)
                        Text("\(result.dreamCount)")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("文件大小：")
                            .foregroundColor(.secondary)
                        Text(result.backupSize)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("备份时间：")
                            .foregroundColor(.secondary)
                        Text(result.completedAt, style: .date)
                            .fontWeight(.medium)
                    }
                }
                .font(.subheadline)
            } else if let error = result.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Restore Tab

struct RestoreTabView: View {
    @ObservedObject var backupService: BackupServiceViewModel
    @Binding var restoreFileURL: URL?
    @Binding var showingPasswordSheet: Bool
    @Binding var backupPassword: String
    @Binding var showingRestoreConfirmation: Bool
    
    @State private var showingFilePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("如何恢复备份")
                        .font(.headline)
                    
                    Text("1. 选择之前创建的 .dreamlog 备份文件")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("2. 如果备份已加密，输入密码")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("3. 确认后开始恢复")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Selected File
                if let url = restoreFileURL {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已选文件")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.purple)
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button("清除") {
                                restoreFileURL = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Progress
                if backupService.isRestoring {
                    BackupProgressSection(progress: backupService.progress)
                }
                
                // Result
                if let result = backupService.lastRestoreResult {
                    RestoreResultSection(result: result)
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "folder")
                                .font(.title2)
                            Text("选择备份文件")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    if restoreFileURL != nil {
                        Button(action: {
                            backupService.triggerRestore()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                    .font(.title2)
                                Text("开始恢复")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("恢复备份")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    restoreFileURL = url
                    // Start accessing security-scoped resource
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                }
            case .failure(let error):
                print("File selection failed: \(error)")
            }
        }
    }
}

struct RestoreResultSection: View {
    let result: RestoreResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.success ? "恢复成功！" : "恢复失败")
                    .font(.headline)
                
                Spacer()
            }
            
            if result.success {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("恢复梦境：")
                            .foregroundColor(.secondary)
                        Text("\(result.dreamsRestored)")
                            .fontWeight(.medium)
                    }
                    
                    if result.skippedDuplicates > 0 {
                        HStack {
                            Text("跳过重复：")
                                .foregroundColor(.secondary)
                            Text("\(result.skippedDuplicates)")
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Text("恢复时间：")
                            .foregroundColor(.secondary)
                        Text(result.completedAt, style: .date)
                            .fontWeight(.medium)
                    }
                }
                .font(.subheadline)
            } else if let error = result.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - History Tab

struct HistoryTabView: View {
    let backupHistory: [BackupHistory]
    @ObservedObject var backupService: BackupServiceViewModel
    
    @State private var showingDeleteConfirmation = false
    @State private var backupToDelete: BackupHistory?
    
    var body: some View {
        Group {
            if backupHistory.isEmpty {
                ContentUnavailableView(
                    "暂无备份历史",
                    systemImage: "clock",
                    description: Text("创建的备份将显示在这里")
                )
            } else {
                List {
                    ForEach(backupHistory, id: \.id) { history in
                        BackupHistoryRow(history: history)
                            .swipeActions(edge: .trailing) {
                                Button("删除", role: .destructive) {
                                    backupToDelete = history
                                    showingDeleteConfirmation = true
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("备份历史")
        .confirmationDialog("删除备份", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                if let history = backupToDelete, let url = URL(string: history.filePath) {
                    try? backupService.deleteBackup(at: url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这个备份文件吗？此操作不可撤销。")
        }
    }
}

struct BackupHistoryRow: View {
    let history: BackupHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: history.isEncrypted ? "lock.fill" : "doc.fill")
                    .foregroundColor(history.isEncrypted ? .orange : .purple)
                
                Text(history.backupDate, style: .date)
                    .font(.headline)
                
                Spacer()
                
                BadgeView(text: history.backupType.rawValue)
            }
            
            HStack {
                Text("\(history.dreamCount) 条梦境")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(ByteCountFormatter.string(fromByteCount: history.fileSize, countStyle: .file))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let notes = history.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BadgeView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var backupService: BackupServiceViewModel
    let modelContext: ModelContext
    
    @Query private var backupSchedules: [BackupSchedule]
    
    @State private var isEnabled = false
    @State private var frequency: BackupSchedule.BackupFrequency = .weekly
    @State private var backupTime = Date()
    @State private var keepLastNBackups = 5
    
    var body: some View {
        Form {
            Section("自动备份设置") {
                Toggle("启用自动备份", isOn: $isEnabled)
                
                if isEnabled {
                    Picker("备份频率", selection: $frequency) {
                        ForEach(BackupSchedule.BackupFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    
                    DatePicker("备份时间", selection: $backupTime, displayedComponents: .hourAndMinute)
                    
                    Stepper("保留最近 \(keepLastNBackups) 个备份", value: $keepLastNBackups, in: 1...20)
                }
            }
            
            Section("备份位置") {
                HStack {
                    Text("备份目录")
                    Spacer()
                    Text("Documents/DreamLogBackups")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Section("备份提示") {
                Text("• 自动备份会在指定时间自动创建")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• 建议启用加密保护隐私")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• 定期将备份文件导出到安全位置")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("保存设置") {
                    saveSettings()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("自动备份")
    }
    
    private func saveSettings() {
        // Update or create backup schedule
        if let schedule = backupSchedules.first {
            schedule.isEnabled = isEnabled
            schedule.frequency = frequency
            schedule.time = backupTime
            schedule.keepLastNBackups = keepLastNBackups
        } else {
            let schedule = BackupSchedule(
                isEnabled: isEnabled,
                frequency: frequency,
                time: backupTime,
                keepLastNBackups: keepLastNBackups
            )
            modelContext.insert(schedule)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Password Sheet

struct PasswordSheet: View {
    @Binding var password: String
    @Binding var showingPasswordSheet: Bool
    let action: PasswordAction
    
    enum PasswordAction {
        case backup
        case restore
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("设置备份密码") {
                    SecureField("密码", text: $password)
                    
                    Text("密码将用于加密备份文件。请妥善保管，丢失后无法恢复。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("备份密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingPasswordSheet = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showingPasswordSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class BackupServiceViewModel: ObservableObject {
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var progress = BackupProgress(
        currentStep: 0,
        totalSteps: 0,
        currentDreamIndex: 0,
        totalDreamCount: 0,
        status: .preparing,
        message: ""
    )
    @Published var lastBackupResult: BackupResult?
    @Published var lastRestoreResult: RestoreResult?
    @Published var restoreTrigger = 0
    
    private let backupService: DreamBackupService
    
    init() {
        self.backupService = DreamBackupService.shared
        self.backupService.onProgressUpdate = { [weak self] progress in
            DispatchQueue.main.async {
                self?.progress = progress
            }
        }
    }
    
    func createBackup(options: BackupOptions) async {
        isBackingUp = true
        lastBackupResult = nil
        
        let result = await backupService.createBackup(options: options)
        
        lastBackupResult = result
        isBackingUp = false
    }
    
    func restoreBackup(from url: URL, password: String?) async {
        isRestoring = true
        lastRestoreResult = nil
        
        let result = await backupService.restoreBackup(from: url, password: password)
        
        lastRestoreResult = result
        isRestoring = false
    }
    
    func triggerRestore() {
        restoreTrigger += 1
    }
    
    func deleteBackup(at url: URL) throws {
        try backupService.deleteBackup(at: url)
    }
}

#Preview {
    DreamBackupView()
        .modelContainer(for: [Dream.self, BackupHistory.self, BackupSchedule.self])
}
