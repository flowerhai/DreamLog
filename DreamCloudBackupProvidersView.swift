//
//  DreamCloudBackupProvidersView.swift
//  DreamLog
//
//  Phase 62: Dream Cloud Backup Enhancement
//  UI for managing Google Drive, Dropbox, and OneDrive backups
//

import SwiftUI
import SwiftData

// MARK: - Main Cloud Backup View

struct DreamCloudBackupProvidersView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var accounts: [CloudBackupAccount] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingConnectSheet = false
    @State private var selectedProvider: CloudBackupProvider?
    
    var body: some View {
        NavigationView {
            List {
                // Connected Accounts Section
                Section {
                    if accounts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "cloud.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("暂无连接的云备份账户")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("连接 Google Drive、Dropbox 或 OneDrive 以启用云备份")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(accounts) { account in
                            AccountRow(account: account)
                                .onTapGesture {
                                    // Navigate to account details
                                }
                        }
                    }
                } header: {
                    Text("已连接的账户")
                }
                
                // Connect New Account Section
                Section {
                    ForEach(CloudBackupProvider.allCases) { provider in
                        if !isAccountConnected(provider: provider) {
                            ConnectProviderRow(provider: provider) {
                                selectedProvider = provider
                                showingConnectSheet = true
                            }
                        }
                    }
                } header: {
                    Text("连接新账户")
                }
                
                // Backup Settings Section
                Section {
                    NavigationLink(destination: CloudBackupSettingsView()) {
                        Label("备份设置", systemImage: "gearshape")
                    }
                } header: {
                    Text("设置")
                }
            }
            .navigationTitle("云备份")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshAccounts) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingConnectSheet) {
                if let provider = selectedProvider {
                    OAuthWebView(provider: provider) { account in
                        accounts.insert(account, at: 0)
                        showingConnectSheet = false
                    }
                }
            }
            .task {
                await loadAccounts()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAccounts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let service = DreamCloudBackupProvidersService(modelContext: modelContext)
            accounts = try await service.getConnectedAccounts()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func refreshAccounts() {
        Task {
            await loadAccounts()
        }
    }
    
    private func isAccountConnected(provider: CloudBackupProvider) -> Bool {
        accounts.contains { $0.provider == provider.rawValue && $0.isConnected }
    }
}

// MARK: - Account Row

struct AccountRow: View {
    let account: CloudBackupAccount
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Provider Icon
            ZStack {
                Circle()
                    .fill(Color(hex: account.providerEnum?.brandColor ?? "8E8E93"))
                    .frame(width: 44, height: 44)
                
                Image(systemName: account.providerEnum?.iconName ?? "cloud")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.providerEnum?.displayName ?? account.provider)
                        .font(.headline)
                    
                    if account.isConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                if let email = account.accountEmail {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Storage Usage
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(account.formattedStorageUsed) / \(account.formattedStorageQuota)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(storageColor)
                                .frame(width: geometry.size.width * min(account.storageUsagePercent / 100, 1), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                
                // Last Backup
                if let lastBackup = account.lastBackupAt {
                    Text("上次备份：\(lastBackup.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action Button
            Menu {
                Button(action: backupNow) {
                    Label("立即备份", systemImage: "arrow.up.circle")
                }
                
                Button(action: viewBackups) {
                    Label("查看备份", systemImage: "folder")
                }
                
                Divider()
                
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("断开连接", systemImage: "unlink")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .alert("断开连接", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("断开", role: .destructive) {
                disconnectAccount()
            }
        } message: {
            Text("断开后，您将无法访问此账户的备份。已有的备份文件将保留在云端。")
        }
    }
    
    private var storageColor: Color {
        let percent = account.storageUsagePercent
        if percent < 50 { return .green }
        if percent < 75 { return .orange }
        return .red
    }
    
    private func backupNow() {
        // Trigger immediate backup
    }
    
    private func viewBackups() {
        // Navigate to backup list
    }
    
    private func disconnectAccount() {
        Task {
            do {
                let service = DreamCloudBackupProvidersService(modelContext: modelContext)
                try await service.disconnectAccount(account)
                withAnimation {
                    account.isConnected = false
                }
            } catch {
                print("断开连接失败：\(error)")
            }
        }
    }
}

// MARK: - Connect Provider Row

struct ConnectProviderRow: View {
    let provider: CloudBackupProvider
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: provider.brandColor))
                    .frame(width: 44, height: 44)
                
                Image(systemName: provider.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                    .font(.headline)
                
                Text("获取 \(storageQuota(provider)) 免费存储空间")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
    
    private func storageQuota(_ provider: CloudBackupProvider) -> String {
        switch provider {
        case .googleDrive: return "15GB"
        case .dropbox: return "2GB"
        case .onedrive: return "5GB"
        }
    }
}

// MARK: - OAuth Web View

struct OAuthWebView: View {
    let provider: CloudBackupProvider
    let onComplete: (CloudBackupAccount) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("正在加载认证页面...")
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("认证失败")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .navigationTitle("连接 \(provider.displayName)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadOAuthPage()
            }
        }
    }
    
    private func loadOAuthPage() async {
        // In a real implementation, this would load a WKWebView with the OAuth URL
        // For now, we'll simulate the flow
        isLoading = false
    }
}

// MARK: - Cloud Backup Settings View

struct CloudBackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("cloudAutoBackupEnabled") private var autoBackupEnabled = false
    @AppStorage("cloudBackupFrequency") private var backupFrequency = "weekly"
    @AppStorage("cloudBackupTime") private var backupTime = Date()
    @AppStorage("cloudIncludeAudio") private var includeAudio = true
    @AppStorage("cloudIncludeImages") private var includeImages = true
    @AppStorage("cloudCompressBackup") private var compressBackup = true
    @AppStorage("cloudEncryptBackup") private var encryptBackup = true
    @AppStorage("cloudRetainCount") private var retainCount = 10
    
    var body: some View {
        Form {
            Section {
                Toggle("自动备份", isOn: $autoBackupEnabled)
                
                if autoBackupEnabled {
                    Picker("备份频率", selection: $backupFrequency) {
                        Text("每天").tag("daily")
                        Text("每周").tag("weekly")
                        Text("每月").tag("monthly")
                    }
                    
                    DatePicker("备份时间", selection: $backupTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("自动备份")
            }
            
            Section {
                Toggle("包含音频", isOn: $includeAudio)
                Toggle("包含图片", isOn: $includeImages)
                Toggle("压缩备份", isOn: $compressBackup)
                Toggle("加密备份", isOn: $encryptBackup)
            } header: {
                Text("备份选项")
            }
            
            Section {
                Stepper("保留备份数量：\(retainCount)", value: $retainCount, in: 1...50)
            } header: {
                Text("备份管理")
            } footer: {
                Text("超过数量的旧备份将自动删除")
            }
        }
        .navigationTitle("备份设置")
    }
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - Preview

#Preview {
    DreamCloudBackupProvidersView()
        .modelContainer(for: CloudBackupAccount.self, inMemory: true)
}
