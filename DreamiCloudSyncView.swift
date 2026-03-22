//
//  DreamiCloudSyncView.swift
//  DreamLog - Phase 88: iCloud CloudKit Sync
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import CloudKit

// MARK: - iCloud Sync Settings View

struct DreamiCloudSyncView: View {
    @StateObject private var syncService = DreamiCloudSyncService.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showingAuthAlert = false
    @State private var authErrorMessage = ""
    
    var body: some View {
        Form {
            // MARK: - Status Section
            Section {
                VStack(spacing: 12) {
                    // Status indicator
                    HStack {
                        Image(systemName: syncService.syncStatus.iconName)
                            .font(.title2)
                            .foregroundColor(syncService.syncStatus.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(syncService.syncStatus.displayName)
                                .font(.headline)
                            Text(syncService.syncMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if syncService.syncStatus == .syncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // Progress bar
                    if syncService.syncStatus == .syncing {
                        ProgressView(value: syncService.syncProgress)
                            .progressViewStyle(.linear)
                    }
                    
                    // Last sync date
                    if let lastSync = syncService.lastSyncDate {
                        Text("上次同步：\(lastSync.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("同步状态")
            }
            
            // MARK: - Enable Sync Section
            Section {
                Toggle("启用 iCloud 同步", isOn: $syncService.isAvailable)
                    .onChange(of: syncService.isAvailable) { oldValue, newValue in
                        if newValue {
                            checkAndRequestAuthentication()
                        }
                    }
                
                if syncService.isAvailable && !syncService.isAuthenticated {
                    Button("登录 iCloud") {
                        checkAndRequestAuthentication()
                    }
                    .foregroundColor(.blue)
                }
            } header: {
                Text("基本设置")
            } footer: {
                if !syncService.isAvailable {
                    Text("iCloud 同步需要登录 Apple ID 并在设置中启用 iCloud Drive")
                        .font(.caption)
                }
            }
            
            // MARK: - Sync Content Section
            if syncService.isAuthenticated {
                Section("同步内容") {
                    Toggle("梦境记录", isOn: .constant(true))
                    Toggle("收藏集", isOn: .constant(true))
                    Toggle("设置与偏好", isOn: .constant(true))
                }
                
                // MARK: - Sync Frequency Section
                Section("同步频率") {
                    Picker("频率", selection: .constant(SyncFrequency.automatic)) {
                        ForEach(SyncFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    
                    Toggle("使用蜂窝数据同步", isOn: .constant(false))
                }
                
                // MARK: - Conflict Resolution Section
                Section("冲突解决") {
                    Picker("策略", selection: .constant(ConflictResolutionPolicy.latestWins)) {
                        ForEach(ConflictResolutionPolicy.allCases, id: \.self) { policy in
                            VStack(alignment: .leading) {
                                Text(policy.displayName)
                                Text(policy.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(policy)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // MARK: - Manual Sync Section
                Section {
                    Button(action: {
                        Task {
                            await syncService.startSync()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("立即同步")
                            Spacer()
                            if syncService.syncStatus == .syncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(syncService.syncStatus == .syncing)
                    
                    if syncService.syncStatus == .syncing {
                        Button("取消同步") {
                            syncService.pauseSync()
                        }
                        .foregroundColor(.red)
                    }
                } header: {
                    Text("手动操作")
                }
                
                // MARK: - Statistics Section
                Section("同步统计") {
                    StatRow(title: "总上传", value: "\(syncService.statistics.totalUploads)")
                    StatRow(title: "总下载", value: "\(syncService.statistics.totalDownloads)")
                    StatRow(title: "冲突解决", value: "\(syncService.statistics.totalConflicts)")
                    StatRow(title: "错误次数", value: "\(syncService.statistics.totalErrors)")
                    
                    if let lastSync = syncService.statistics.lastSyncDate {
                        StatRow(title: "上次同步", value: lastSync.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    StatRow(title: "数据大小", value: syncService.statistics.formattedDataSize)
                    StatRow(title: "同步时长", value: syncService.statistics.formattedDuration)
                }
                
                // MARK: - Advanced Section
                Section("高级选项") {
                    NavigationLink("查看冲突记录") {
                        ConflictListView(conflicts: syncService.conflicts)
                    }
                    
                    NavigationLink("同步日志") {
                        SyncLogView()
                    }
                    
                    Button("重置同步状态", role: .destructive) {
                        resetSync()
                    }
                }
            }
            
            // MARK: - Help Section
            Section {
                Link("iCloud 同步帮助", destination: URL(string: "https://support.apple.com/zh-cn/HT204260")!)
                Link("隐私政策", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
            } header: {
                Text("帮助与支持")
            }
        }
        .navigationTitle("iCloud 同步")
        .navigationBarTitleDisplayMode(.inline)
        .alert("iCloud 认证", isPresented: $showingAuthAlert) {
            Button("确定", role: .cancel) { }
            Button("打开设置") {
                openSettings()
            }
        } message: {
            Text(authErrorMessage)
        }
        .onAppear {
            syncService.checkAuthentication()
        }
    }
    
    // MARK: - Methods
    
    private func checkAndRequestAuthentication() {
        syncService.checkAuthentication()
        
        if !syncService.isAuthenticated {
            authErrorMessage = "请在 iPhone 设置中登录 iCloud 并启用 iCloud Drive"
            showingAuthAlert = true
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetSync() {
        // TODO: 实现重置逻辑
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Conflict List View

struct ConflictListView: View {
    let conflicts: [SyncConflict]
    
    var body: some View {
        List {
            if conflicts.isEmpty {
                ContentUnavailableView(
                    "暂无冲突",
                    systemImage: "checkmark.circle",
                    description: Text("所有数据都已同步完成")
                )
            } else {
                ForEach(conflicts) { conflict in
                    ConflictRow(conflict: conflict)
                }
            }
        }
        .navigationTitle("冲突记录")
    }
}

struct ConflictRow: View {
    let conflict: SyncConflict
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(conflict.recordType)
                .font(.headline)
            
            HStack {
                Text("本地：\(conflict.localModifiedDate.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                Spacer()
                Text("云端：\(conflict.cloudModifiedDate.formatted(.relative(presentation: .named)))")
                    .font(.caption)
            }
            
            HStack {
                Button("使用本地") {
                    // TODO: 解决冲突
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("使用云端") {
                    // TODO: 解决冲突
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sync Log View

struct SyncLogView: View {
    var body: some View {
        List {
            Text("同步日志功能开发中...")
        }
        .navigationTitle("同步日志")
    }
}

// MARK: - Sync Status Color Extension

extension SyncStatus {
    var color: Color {
        switch self {
        case .idle: return .gray
        case .syncing: return .blue
        case .paused: return .orange
        case .error: return .red
        case .completed: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DreamiCloudSyncView()
    }
}
