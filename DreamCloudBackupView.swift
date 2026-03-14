//
//  DreamCloudBackupView.swift
//  DreamLog - Phase 37: Cloud Backup Integration
//
//  Created by DreamLog Team on 2026-03-14.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import SwiftData

// MARK: - Main Cloud Backup View

struct DreamCloudBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configs: [CloudBackupConfig]
    @State private var selectedProvider: CloudProvider?
    @State private var showingAddConfig = false
    @State private var showingBackupOptions = false
    @State private var selectedConfig: CloudBackupConfig?
    @State private var isBackingUp = false
    @State private var backupProgress: Double = 0
    @State private var backupMessage = ""
    @State private var showingRestoreSheet = false
    @State private var selectedRestoreRecord: CloudBackupRecord?
    
    var statistics: CloudBackupStatistics {
        // 简化实现，实际应从服务获取
        let connectedCount = configs.filter { $0.isConnected }.count
        let totalBackups = configs.reduce(0) { $0 + $1.totalBackups }
        let totalSize = configs.reduce(0) { $0 + $1.storageUsed }
        
        return CloudBackupStatistics(
            totalConfigs: configs.count,
            connectedConfigs: connectedCount,
            totalBackups: totalBackups,
            totalSizeBytes: totalSize,
            successfulBackups: totalBackups,
            failedBackups: 0,
            lastBackupDate: configs.compactMap { $0.lastBackupDate }.max(),
            nextScheduledBackup: configs.compact { $0.nextBackupDate }.min(),
            providers: configs.compactMap { CloudProvider(rawValue: $0.provider) }
        )
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 统计卡片
                statisticsSection
                
                // 已连接的云服务
                if !configs.isEmpty {
                    connectedServicesSection
                }
                
                // 添加新服务
                addServiceSection
                
                // 备份历史
                if !configs.isEmpty {
                    backupHistorySection
                }
            }
            .navigationTitle("云备份")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingBackupOptions = true }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(configs.filter { $0.isConnected }.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddConfig) {
                AddCloudConfigView(selectedProvider: $selectedProvider)
            }
            .sheet(isPresented: $showingBackupOptions) {
                BackupOptionsView(config: selectedConfig ?? configs.first(where: { $0.isConnected })!)
            }
            .sheet(isPresented: $showingRestoreSheet) {
                RestoreBackupView(record: selectedRestoreRecord!)
            }
            .overlay {
                if isBackingUp {
                    backupProgressOverlay
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var statisticsSection: some View {
        Section {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    StatCard(
                        title: "已连接",
                        value: "\(statistics.connectedConfigs)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "总备份",
                        value: "\(statistics.totalBackups)",
                        icon: "arrow.up.circle.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "存储使用",
                        value: statistics.totalSizeFormatted,
                        icon: "externaldrive.fill",
                        color: .purple
                    )
                }
                
                if let lastBackup = statistics.lastBackupDate {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.secondary)
                        Text("上次备份：\(lastBackup.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let nextBackup = statistics.nextScheduledBackup {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.secondary)
                        Text("下次备份：\(nextBackup.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("概览")
        }
    }
    
    private var connectedServicesSection: some View {
        Section("已连接的云服务") {
            ForEach(configs) { config in
                CloudServiceRow(
                    config: config,
                    onBackup: {
                        selectedConfig = config
                        showingBackupOptions = true
                    },
                    onRestore: {
                        selectedConfig = config
                        showingRestoreSheet = true
                    }
                )
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    modelContext.delete(configs[index])
                }
            }
        }
    }
    
    private var addServiceSection: some View {
        Section("添加云服务") {
            ForEach(CloudProvider.allCases.filter { provider in
                !configs.contains { $0.provider == provider.rawValue }
            }) { provider in
                Button(action: {
                    selectedProvider = provider
                    showingAddConfig = true
                }) {
                    HStack {
                        Image(systemName: provider.iconName)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: provider.color))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        VStack(alignment: .leading) {
                            Text(provider.displayName)
                                .font(.body)
                            Text("点击连接")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var backupHistorySection: some View {
        Section("最近备份") {
            let allRecords = configs.flatMap { config -> [CloudBackupRecord] in
                // 简化实现
                return []
            }
            .sorted { $0.uploadDate > $1.uploadDate }
            .prefix(5)
            
            if allRecords.isEmpty {
                Text("暂无备份记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(allRecords) { record in
                    BackupRecordRow(record: record)
                }
            }
        }
    }
    
    // MARK: - Overlays
    
    private var backupProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: backupProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 250)
                
                Text(backupMessage)
                    .foregroundColor(.white)
                    .font(.body)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding()
        }
    }
}

// MARK: - Subviews

struct StatCard: View {
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
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CloudServiceRow: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var config: CloudBackupConfig
    let onBackup: () -> Void
    let onRestore: () -> Void
    @State private var showingDisconnectAlert = false
    
    var provider: CloudProvider? {
        CloudProvider(rawValue: config.provider)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: provider?.iconName ?? "cloud")
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: provider?.color ?? "6B7280"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(provider?.displayName ?? "云服务")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if config.isConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                if !config.accountName.isEmpty {
                    Text(config.accountName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if config.autoBackupEnabled {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                        Text("自动备份：\(config.autoBackupFrequency.displayName)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if config.isConnected {
                VStack(spacing: 8) {
                    Button(action: onBackup) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onRestore) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if config.isConnected {
                Button(action: { showingDisconnectAlert = true }) {
                    Label("断开连接", systemImage: "slash.circle")
                }
            }
        }
        .alert("断开连接", isPresented: $showingDisconnectAlert) {
            Button("取消", role: .cancel) {}
            Button("断开", role: .destructive) {
                config.isConnected = false
                config.accessToken = nil
                config.refreshToken = nil
                try? modelContext.save()
            }
        } message: {
            Text("确定要断开与 \(provider?.displayName ?? "云服务") 的连接吗？")
        }
    }
}

struct BackupRecordRow: View {
    @ObservedObject var record: CloudBackupRecord
    
    var provider: CloudProvider? {
        CloudProvider(rawValue: record.provider)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.status.icon)
                .foregroundColor(record.status == .completed ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.fileName)
                    .font(.body)
                
                HStack(spacing: 8) {
                    Text(record.backupType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(record.dreamCount) 个梦境")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(ByteCountFormatter.string(fromByteCount: record.fileSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(record.uploadDate.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if record.isEncrypted {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Cloud Config View

struct AddCloudConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedProvider: CloudProvider?
    @State private var webdavConfig = WebDAVConfig(serverUrl: "", username: "", password: "")
    @State private var isConnecting = false
    @State private var errorMessage: String?
    
    var provider: CloudProvider? {
        selectedProvider
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if provider == .webdav {
                    Section("WebDAV 配置") {
                        TextField("服务器地址", text: $webdavConfig.serverUrl)
                            .autocapitalization(.none)
                        TextField("用户名", text: $webdavConfig.username)
                            .autocapitalization(.none)
                        SecureField("密码", text: $webdavConfig.password)
                        TextField("路径", text: $webdavConfig.path)
                            .autocapitalization(.none)
                        Toggle("使用 SSL", isOn: $webdavConfig.useSSL)
                        TextField("端口", value: $webdavConfig.port, format: .number)
                            .keyboardType(.numberPad)
                    }
                } else {
                    Section("OAuth 授权") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("点击下面的按钮连接到 \(provider?.displayName ?? "云服务")")
                                .font(.body)
                            
                            Text("这将打开浏览器进行授权，授权完成后会自动返回应用")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: startOAuth) {
                                HStack {
                                    Spacer()
                                    Text("连接到 \(provider?.displayName ?? "云服务")")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isConnecting)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("说明") {
                        Text("• 您的数据将加密存储在您的云账户中")
                        Text("• DreamLog 只能访问应用创建的文件夹")
                        Text("• 您可以随时断开连接或删除备份")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加 \(provider?.displayName ?? "云服务")")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .overlay {
                if isConnecting {
                    ProgressView("连接中...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private func startOAuth() {
        isConnecting = true
        errorMessage = nil
        
        // 实际实现中，这里应该打开 Safari 进行 OAuth 授权
        // 简化实现：直接创建配置
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let provider = provider {
                let config = CloudBackupConfig(provider: provider)
                config.isConnected = true
                config.accountName = "user@example.com"
                modelContext.insert(config)
                try? modelContext.save()
            }
            isConnecting = false
            dismiss()
        }
    }
}

// MARK: - Backup Options View

struct BackupOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var config: CloudBackupConfig
    @State private var options = CloudBackupOptions()
    @State private var isPerformingBackup = false
    @State private var backupProgress: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("备份类型") {
                    Picker("类型", selection: $options.backupType) {
                        ForEach(BackupType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section("日期范围") {
                    Picker("范围", selection: $options.dateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
                
                Section("包含内容") {
                    Toggle("音频文件", isOn: $options.includeAudio)
                    Toggle("图片", isOn: $options.includeImages)
                    Toggle("AI 解析", isOn: $options.includeAIAnalysis)
                    Toggle("位置信息", isOn: $options.includeLocations)
                }
                
                Section("安全选项") {
                    Toggle("压缩数据", isOn: $options.compressData)
                    Toggle("加密备份", isOn: $options.encryptData)
                    
                    if options.encryptData {
                        SecureField("加密密码", text: $options.encryptionPassword)
                        Text("请妥善保管密码，丢失后无法恢复数据")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section("自动备份") {
                    Toggle("启用自动备份", isOn: $config.autoBackupEnabled)
                    
                    if config.autoBackupEnabled {
                        Picker("频率", selection: $config.autoBackupFrequency) {
                            ForEach(BackupFrequency.allCases, id: \.self) { freq in
                                Text(freq.displayName).tag(freq)
                            }
                        }
                    }
                }
            }
            .navigationTitle("备份选项")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: performBackup) {
                        Text("开始备份")
                            .fontWeight(.semibold)
                    }
                    .disabled(isPerformingBackup)
                }
            }
            .overlay {
                if isPerformingBackup {
                    ProgressView(value: backupProgress)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private func performBackup() {
        isPerformingBackup = true
        
        // 模拟备份进度
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { backupProgress = 0.2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { backupProgress = 0.4 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { backupProgress = 0.6 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { backupProgress = 0.8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            backupProgress = 1.0
            config.lastBackupDate = Date()
            config.totalBackups += 1
            dismiss()
        }
    }
}

// MARK: - Restore Backup View

struct RestoreBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var record: CloudBackupRecord
    @State private var password = ""
    @State private var isRestoring = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("备份信息") {
                    HStack {
                        Text("文件名")
                        Spacer()
                        Text(record.fileName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("备份类型")
                        Spacer()
                        Text(record.backupType.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("梦境数量")
                        Spacer()
                        Text("\(record.dreamCount) 个")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("文件大小")
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: record.fileSize, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("备份时间")
                        Spacer()
                        Text(record.uploadDate.formatted())
                            .foregroundColor(.secondary)
                    }
                    
                    if record.isEncrypted {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text("已加密")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if record.isEncrypted {
                    Section("解密密码") {
                        SecureField("输入加密密码", text: $password)
                        Text("请输入创建备份时设置的密码")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("⚠️ 恢复操作将把备份中的梦境合并到当前数据库中")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .navigationTitle("恢复备份")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: startRestore) {
                        Text("恢复")
                            .fontWeight(.semibold)
                    }
                    .disabled(isRestoring || (record.isEncrypted && password.isEmpty))
                }
            }
        }
    }
    
    private func startRestore() {
        isRestoring = true
        // 实际实现中调用服务的恢复方法
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    DreamCloudBackupView()
        .modelContainer(for: CloudBackupConfig.self, inMemory: true)
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
