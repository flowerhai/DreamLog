//
//  DreamBackupView.swift
//  DreamLog
//
//  梦境备份与恢复界面 - Phase 16
//

import SwiftUI

// MARK: - 备份主视图

struct DreamBackupView: View {
    @ObservedObject private var backupService = DreamBackupService.shared
    @ObservedObject private var dreamStore = DreamStore.shared
    
    @State private var showingBackupConfig = false
    @State private var showingRestorePicker = false
    @State private var selectedBackup: BackupMetadata?
    @State private var showingDeleteConfirm = false
    @State private var backupResult: BackupResult?
    @State private var restoreResult: RestoreResult?
    @State private var showingResultSheet = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // 备份状态概览
                backupStatusSection
                
                // 备份操作
                backupActionsSection
                
                // 备份历史
                backupHistorySection
                
                // 设置
                settingsSection
            }
            .navigationTitle("备份与恢复")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") {
                        showingBackupConfig = true
                    }
                    .sheet(isPresented: $showingBackupConfig) {
                        BackupConfigSheet(config: backupService.getConfig()) { config in
                            backupService.saveConfig(config)
                        }
                    }
                }
            }
            .overlay {
                if backupService.isBackingUp || backupService.isRestoring {
                    progressOverlay
                }
            }
        }
    }
    
    // MARK: - 备份状态概览
    
    private var backupStatusSection: some View {
        Section("备份状态") {
            HStack {
                Image(systemName: lastBackupIcon)
                    .foregroundColor(lastBackupColor)
                
                VStack(alignment: .leading) {
                    Text("上次备份")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastBackupText)
                        .font(.body)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("备份数量")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(backupService.backupHistory.backups.count) 个")
                        .font(.body)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "cylinder.split.1x2.fill")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("总大小")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(backupService.backupHistory.formattedTotalSize)
                        .font(.body)
                }
                
                Spacer()
            }
        }
    }
    
    private var lastBackupIcon: String {
        if backupService.lastBackupDate == nil {
            return "exclamationmark.triangle.fill"
        }
        return "checkmark.circle.fill"
    }
    
    private var lastBackupColor: Color {
        if backupService.lastBackupDate == nil {
            return .orange
        }
        return .green
    }
    
    private var lastBackupText: String {
        guard let date = backupService.lastBackupDate else {
            return "尚未备份"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - 备份操作
    
    private var backupActionsSection: some View {
        Section("操作") {
            Button(action: performBackup) {
                HStack {
                    Image(systemName: "arrow.up.doc.fill")
                        .foregroundColor(.green)
                    Text("立即备份")
                    Spacer()
                    if backupService.isBackingUp {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(backupService.isBackingUp || backupService.isRestoring)
            
            Button(action: { showingRestorePicker = true }) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.blue)
                    Text("恢复备份")
                    Spacer()
                }
            }
            .disabled(backupService.isBackingUp || backupService.isRestoring)
            .fileImporter(
                isPresented: $showingRestorePicker,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            await performRestore(from: url)
                        }
                    }
                case .failure(let error):
                    print("文件选择失败：\(error)")
                }
            }
        }
    }
    
    // MARK: - 备份历史
    
    private var backupHistorySection: some View {
        Section("备份历史") {
            if backupService.backupHistory.backups.isEmpty {
                Text("暂无备份记录")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.vertical, 8)
            } else {
                ForEach(backupService.backupHistory.backups, id: \.id) { backup in
                    BackupHistoryRow(
                        metadata: backup,
                        isValid: backupService.verifyBackup(backup),
                        onDelete: {
                            selectedBackup = backup
                            showingDeleteConfirm = true
                        },
                        onRestore: {
                            Task {
                                await restoreFromMetadata(backup)
                            }
                        }
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let backup = backupService.backupHistory.backups[index]
                        try? backupService.deleteBackup(backup)
                    }
                }
            }
        }
    }
    
    // MARK: - 设置
    
    private var settingsSection: some View {
        Section("设置") {
            NavigationLink {
                BackupConfigSheet(config: backupService.getConfig()) { config in
                    backupService.saveConfig(config)
                }
            } label: {
                Label("备份配置", systemImage: "gearshape")
            }
            
            Toggle("自动备份", isOn: .init(
                get: { backupService.getConfig().autoBackup },
                set: { enabled in
                    var config = backupService.getConfig()
                    config.autoBackup = enabled
                    backupService.saveConfig(config)
                }
            ))
        }
    }
    
    // MARK: - 进度覆盖层
    
    private var progressOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView(value: progressValue)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                
                Text(progressText)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
    
    private var progressValue: Double {
        if backupService.isBackingUp, let progress = backupService.backupProgress {
            return progress.progress
        }
        if backupService.isRestoring, let progress = backupService.restoreProgress {
            return progress.progress
        }
        return 0
    }
    
    private var progressText: String {
        if backupService.isBackingUp, let progress = backupService.backupProgress {
            return "\(progress.currentStep) (\(progress.currentStepIndex)/\(progress.totalSteps))"
        }
        if backupService.isRestoring, let progress = backupService.restoreProgress {
            return "\(progress.currentStep) (\(progress.currentStepIndex)/\(progress.totalSteps))"
        }
        return ""
    }
    
    // MARK: - Actions
    
    private func performBackup() {
        Task {
            let config = backupService.getConfig()
            let result = await backupService.createBackup(config: config)
            backupResult = result
            showingResultSheet = true
        }
    }
    
    private func performRestore(from url: URL) async {
        let config = RestoreConfig(
            conflictResolution: .keepNewer,
            restoreDreams: true,
            restoreTags: true,
            restoreSettings: false,
            restoreStatistics: false,
            dryRun: false
        )
        
        let result = await backupService.restoreBackup(from: url, config: config)
        restoreResult = result
        showingResultSheet = true
    }
    
    private func restoreFromMetadata(_ metadata: BackupMetadata) async {
        let fileURL = URL(fileURLWithPath: "/path/to/backup/\(metadata.id).dreambackup")
        await performRestore(from: fileURL)
    }
}

// MARK: - 备份历史行

struct BackupHistoryRow: View {
    let metadata: BackupMetadata
    let isValid: Bool
    let onDelete: () -> Void
    let onRestore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isValid ? "doc.fill.badge.checkmark" : "doc.fill.badge.exclamationmark")
                    .foregroundColor(isValid ? .green : .orange)
                
                VStack(alignment: .leading) {
                    Text(metadata.backupType.rawValue)
                        .font(.headline)
                    Text(metadata.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(metadata.formattedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = metadata.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Button(action: onRestore) {
                    Label("恢复", systemImage: "arrow.down.doc")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 备份配置 Sheet

struct BackupConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var config: BackupConfig
    let onSave: (BackupConfig) -> Void
    
    init(config: BackupConfig, onSave: @escaping (BackupConfig) -> Void) {
        _config = State(initialValue: config)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("备份类型") {
                    Picker("类型", selection: $config.backupType) {
                        ForEach(BackupType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(config.backupType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("加密") {
                    Picker("加密方式", selection: $config.encryption) {
                        ForEach(BackupEncryption.allCases) { encryption in
                            HStack {
                                Image(systemName: encryption.icon)
                                Text(encryption.rawValue)
                            }
                            .tag(encryption)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(config.encryption.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("包含内容") {
                    Toggle("包含设置", isOn: $config.includeSettings)
                    Toggle("包含统计", isOn: $config.includeStatistics)
                    Toggle("包含 AI 历史", isOn: $config.includeAIHistory)
                    Toggle("压缩数据", isOn: $config.compressData)
                }
                
                Section("自动备份") {
                    Toggle("启用自动备份", isOn: $config.autoBackup)
                    
                    if config.autoBackup {
                        Picker("频率", selection: $config.autoBackupInterval) {
                            ForEach(BackupConfig.AutoBackupInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                Section("预估大小") {
                    Text(config.estimatedSize)
                        .font(.headline)
                }
            }
            .navigationTitle("备份配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(config)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    DreamBackupView()
}
