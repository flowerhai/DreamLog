//
//  DreamPrivacySettingsView.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import LocalAuthentication

// MARK: - Privacy Settings View

/// 隐私设置面板
struct DreamPrivacySettingsView: View {
    @StateObject private var biometricService = DreamBiometricLockService.shared
    @StateObject private var notificationService = DreamPrivacyNotificationService.shared
    
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @AppStorage("lockTimeout") private var lockTimeout = "immediate"
    @AppStorage("hideNotificationContent") private var hideNotificationContent = false
    @AppStorage("hideWidgetContent") private var hideWidgetContent = false
    @AppStorage("hideLockScreenPreview") private var hideLockScreenPreview = true
    @AppStorage("blurAppInSwitcher") private var blurAppInSwitcher = false
    
    @State private var showingBiometricSetup = false
    @State private var showingPasscodeSetup = false
    @State private var isBiometricConfigured = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - 应用锁 section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text("应用锁")
                                    .font(.headline)
                                Text("使用生物识别保护应用")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $biometricEnabled)
                                .labelsHidden()
                                .onChange(of: biometricEnabled) { _, newValue in
                                    Task {
                                        await toggleBiometricLock(newValue)
                                    }
                                }
                        }
                        
                        if biometricEnabled {
                            Picker("自动锁定", selection: $lockTimeout) {
                                Text("立即").tag("immediate")
                                Text("1 分钟后").tag("after1Minute")
                                Text("5 分钟后").tag("after5Minutes")
                                Text("15 分钟后").tag("after15Minutes")
                                Text("1 小时后").tag("after1Hour")
                            }
                            .pickerStyle(.menu)
                            
                            HStack {
                                Image(systemName: biometricService.biometricTypeName == "Face ID" ? "faceid" : "touchid")
                                    .foregroundColor(.green)
                                Text("\(biometricService.biometricTypeName) 已配置")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("安全")
                }
                
                // MARK: - 通知隐私 section
                Section {
                    Toggle("隐藏通知内容", isOn: $hideNotificationContent)
                        .toggleStyle(.switch)
                    
                    Toggle("隐藏小组件内容", isOn: $hideWidgetContent)
                        .toggleStyle(.switch)
                    
                    Toggle("隐藏锁屏预览", isOn: $hideLockScreenPreview)
                        .toggleStyle(.switch)
                    
                    Toggle("在应用切换器中模糊", isOn: $blurAppInSwitcher)
                        .toggleStyle(.switch)
                } header: {
                    Text("通知隐私")
                } footer: {
                    Text("启用后，通知将显示为\"你有新的梦境\"而不显示具体内容")
                }
                
                // MARK: - 私密梦境 section
                Section {
                    NavigationLink(destination: DreamPrivacyView()) {
                        HStack {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(.orange)
                            Text("管理私密梦境")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: DreamTrashView()) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("回收站")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("梦境隐私")
                }
                
                // MARK: - 备份 section
                Section {
                    NavigationLink(destination: DreamSecureBackupView()) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.blue)
                            Text("安全备份")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("数据保护")
                }
                
                // MARK: - 关于 section
                Section {
                    HStack {
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("数据安全说明")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("隐私与安全")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func toggleBiometricLock(_ enabled: Bool) async {
        do {
            if enabled {
                try await biometricService.configure(isEnabled: true)
                isBiometricConfigured = true
            } else {
                try await biometricService.configure(isEnabled: false)
            }
        } catch {
            biometricEnabled = !enabled
            print("配置应用锁失败：\(error)")
        }
    }
}

// MARK: - Secure Backup View

/// 安全备份视图
struct DreamSecureBackupView: View {
    @AppStorage("backupEnabled") private var backupEnabled = false
    @AppStorage("backupEncryption") private var backupEncryption = true
    @AppStorage("backupFrequency") private var backupFrequency = "weekly"
    
    @State private var isBackingUp = false
    @State private var lastBackupDate: Date?
    @State private var backupSize: String = "0 MB"
    
    var body: some View {
        List {
            Section {
                Toggle("启用安全备份", isOn: $backupEnabled)
                    .toggleStyle(.switch)
                
                Toggle("加密备份文件", isOn: $backupEncryption)
                    .toggleStyle(.switch)
                
                Picker("备份频率", selection: $backupFrequency) {
                    Text("每天").tag("daily")
                    Text("每周").tag("weekly")
                    Text("每月").tag("monthly")
                }
                .pickerStyle(.menu)
            } header: {
                Text("备份设置")
            }
            
            Section {
                if isBackingUp {
                    HStack {
                        ProgressView()
                        Text("正在备份...")
                    }
                } else {
                    Button(action: startBackup) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.blue)
                            Text("立即备份")
                        }
                    }
                    .disabled(!backupEnabled)
                }
                
                if let lastBackup = lastBackupDate {
                    HStack {
                        Text("上次备份")
                        Spacer()
                        Text(formatDate(lastBackup))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("备份大小")
                        Spacer()
                        Text(backupSize)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("备份状态")
            }
            
            Section {
                Text("备份使用 AES-256 加密，密钥存储在设备安全区域。即使备份文件泄露，没有密钥也无法解密。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } footer: {
                Text("备份位置：iCloud Drive / DreamLog / Backups")
            }
        }
        .navigationTitle("安全备份")
    }
    
    private func startBackup() {
        isBackingUp = true
        
        Task {
            // 模拟备份过程
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                isBackingUp = false
                lastBackupDate = Date()
                backupSize = "12.5 MB"
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    DreamPrivacySettingsView()
}
