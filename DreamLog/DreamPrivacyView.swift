//
//  DreamPrivacyView.swift
//  DreamLog - Privacy Settings UI
//
//  Phase 70: Dream Privacy Mode with Biometric Lock
//  Created: 2026-03-19
//

import SwiftUI
import SwiftData

// MARK: - Privacy Settings View

struct DreamPrivacyView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DreamPrivacyViewModel
    @State private var showingLockConfig = false
    @State private var showingKeywordEditor = false
    @State private var authResult: AuthResult?
    
    init() {
        _viewModel = StateObject(wrappedValue: DreamPrivacyViewModel())
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - 隐私模式开关
                Section {
                    Toggle("启用隐私模式", isOn: $viewModel.isEnabled)
                        .onChange(of: viewModel.isEnabled) { newValue in
                            Task {
                                try? await viewModel.updateSettings(isEnabled: newValue)
                            }
                        }
                    
                    if viewModel.isEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("隐私模式可保护您的敏感梦境，需要生物识别或密码才能查看。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("隐私模式")
                }
                
                // MARK: - 锁定类型
                if viewModel.isEnabled {
                    Section {
                        Button {
                            showingLockConfig = true
                        } label: {
                            HStack {
                                Image(systemName: viewModel.biometricType == "faceID" ? "faceid" : "touchid")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text("默认锁定类型")
                                    Text(viewModel.settings.defaultLockType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("安全设置")
                    } footer: {
                        Text("选择保护梦境的方式")
                    }
                    
                    // MARK: - 生物识别状态
                    Section {
                        HStack {
                            Image(systemName: viewModel.biometricType == "faceID" ? "faceid" : "touchid")
                                .foregroundStyle(viewModel.isBiometricAvailable ? .green : .red)
                            VStack(alignment: .leading) {
                                Text("生物识别")
                                Text(viewModel.biometricType == "faceID" ? "Face ID" : viewModel.biometricType == "touchID" ? "Touch ID" : "不可用")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if viewModel.isBiometricAvailable {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    // MARK: - 应用锁定
                    Section {
                        Toggle("启动时需要认证", isOn: $viewModel.requireAuthOnAppLaunch)
                            .onChange(of: viewModel.requireAuthOnAppLaunch) { newValue in
                                Task {
                                    try? await viewModel.updateSettings(requireAuthOnAppLaunch: newValue)
                                }
                            }
                        
                        if viewModel.requireAuthOnAppLaunch {
                            HStack {
                                Text("后台返回后锁定")
                                Spacer()
                                Menu {
                                    ForEach([60, 300, 900, 1800, 3600], id: \.self) { seconds in
                                        Button(formatTime(seconds)) {
                                            Task {
                                                try? await viewModel.updateSettings(requireAuthAfterSeconds: Double(seconds))
                                            }
                                        }
                                    }
                                } label: {
                                    Text(formatTime(viewModel.settings.requireAuthAfterSeconds))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("应用锁定")
                    }
                    
                    // MARK: - 自动锁定
                    Section {
                        Toggle("自动锁定", isOn: $viewModel.autoLockEnabled)
                            .onChange(of: viewModel.autoLockEnabled) { newValue in
                                Task {
                                    try? await viewModel.updateSettings(autoLockEnabled: newValue)
                                }
                            }
                        
                        if viewModel.autoLockEnabled {
                            Button {
                                showingKeywordEditor = true
                            } label: {
                                HStack {
                                    Image(systemName: "text.badge.checkmark")
                                    VStack(alignment: .leading) {
                                        Text("自动锁定关键词")
                                        Text("\(viewModel.settings.autoLockKeywords.count) 个关键词")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("自动锁定")
                    } footer: {
                        if viewModel.autoLockEnabled {
                            Text("包含这些关键词的梦境将自动锁定")
                        }
                    }
                    
                    // MARK: - 隐藏选项
                    Section {
                        Toggle("在小组件中隐藏", isOn: $viewModel.hideLockedFromWidgets)
                            .onChange(of: viewModel.hideLockedFromWidgets) { newValue in
                                Task {
                                    try? await viewModel.updateSettings(hideLockedFromWidgets: newValue)
                                }
                            }
                        
                        Toggle("在通知中隐藏", isOn: $viewModel.hideLockedFromNotifications)
                            .onChange(of: viewModel.hideLockedFromNotifications) { newValue in
                                Task {
                                    try? await viewModel.updateSettings(hideLockedFromNotifications: newValue)
                                }
                            }
                        
                        Toggle("在统计中隐藏", isOn: $viewModel.hideLockedFromStats)
                            .onChange(of: viewModel.hideLockedFromStats) { newValue in
                                Task {
                                    try? await viewModel.updateSettings(hideLockedFromStats: newValue)
                                }
                            }
                    } header: {
                        Text("隐藏选项")
                    }
                    
                    // MARK: - 统计信息
                    Section {
                        if let stats = viewModel.stats {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("已锁定梦境")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(stats.totalLockedDreams)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("本周新增")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("+\(stats.lockedThisWeek)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if let mostLockedTag = stats.mostLockedTag {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundStyle(.blue)
                                    Text("最多锁定的标签")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(mostLockedTag)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    } header: {
                        Text("统计")
                    }
                    
                    // MARK: - 测试认证
                    Section {
                        Button {
                            Task {
                                authResult = await viewModel.testBiometricAuth()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lock.shield")
                                Text("测试生物识别")
                            }
                        }
                    } header: {
                        Text("测试")
                    }
                }
            }
            .navigationTitle("隐私设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingLockConfig) {
                LockTypeConfigView(settings: viewModel.settings) { newType in
                    Task {
                        try? await viewModel.updateSettings(defaultLockType: newType)
                    }
                }
            }
            .sheet(isPresented: $showingKeywordEditor) {
                AutoLockKeywordEditor(keywords: $viewModel.settings.autoLockKeywords)
            }
            .alert("认证结果", isPresented: .constant(authResult != nil)) {
                Button("确定") {
                    authResult = nil
                }
            } message: {
                if let result = authResult {
                    switch result {
                    case .success:
                        Text("认证成功！")
                    case .failure(let reason):
                        Text("认证失败：\(reason)")
                    case .userFallback:
                        Text("用户选择使用密码")
                    case .userCancel:
                        Text("用户取消认证")
                    case .systemError:
                        Text("系统错误")
                    }
                }
            }
            .task {
                await viewModel.loadSettings()
                await viewModel.loadStats()
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        switch seconds {
        case 60:
            return "1 分钟"
        case 300:
            return "5 分钟"
        case 900:
            return "15 分钟"
        case 1800:
            return "30 分钟"
        case 3600:
            return "1 小时"
        default:
            return "\(Int(seconds))秒"
        }
    }
}

// MARK: - Lock Type Configuration View

struct LockTypeConfigView: View {
    let settings: DreamPrivacySettings
    let onSelect: (DreamLockType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(DreamLockType.allCases, id: \.rawValue) { type in
                    Button {
                        onSelect(type)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                    .font(.body)
                                Text(typeDescription(for: type))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.defaultLockType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择锁定类型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func typeDescription(for type: DreamLockType) -> String {
        switch type {
        case .none:
            return "不使用锁定"
        case .biometric:
            return "使用 Face ID 或 Touch ID"
        case .passcode:
            return "使用设备密码"
        case .hidden:
            return "完全隐藏，不显示在列表中"
        }
    }
}

// MARK: - Auto Lock Keyword Editor

struct AutoLockKeywordEditor: View {
    @Binding var keywords: [String]
    @State private var newKeyword = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        TextField("添加关键词", text: $newKeyword)
                        Button {
                            if !newKeyword.isEmpty && !keywords.contains(newKeyword) {
                                keywords.append(newKeyword)
                                newKeyword = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(newKeyword.isEmpty)
                    }
                } header: {
                    Text("添加自动锁定关键词")
                } footer: {
                    Text("梦境内容或标题包含这些关键词时将自动锁定")
                }
                
                if !keywords.isEmpty {
                    Section {
                        ForEach(keywords, id: \.self) { keyword in
                            HStack {
                                Text(keyword)
                                Spacer()
                                Button {
                                    keywords.removeAll { $0 == keyword }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            keywords.remove(atOffsets: indexSet)
                        }
                    } header: {
                        Text("已添加 \(keywords.count) 个关键词")
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("示例关键词：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("隐私、敏感、秘密、私人、工作、医疗...")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .navigationTitle("自动锁定关键词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Stats View

struct PrivacyStatsView: View {
    let stats: DreamPrivacyStats
    
    var body: some View {
        VStack(spacing: 16) {
            // 总锁定数
            StatCard(
                title: "已锁定梦境",
                value: "\(stats.totalLockedDreams)",
                icon: "lock.fill",
                color: .blue
            )
            
            HStack(spacing: 16) {
                // 本周锁定
                StatCard(
                    title: "本周",
                    value: "+\(stats.lockedThisWeek)",
                    icon: "calendar",
                    color: .green
                )
                
                // 本月锁定
                StatCard(
                    title: "本月",
                    value: "+\(stats.lockedThisMonth)",
                    icon: "calendar.badge.clock",
                    color: .orange
                )
            }
            
            // 按类型分布
            if !stats.lockedByType.isEmpty {
                Section {
                    ForEach(Array(stats.lockedByType.keys), id: \.rawValue) { type in
                        if let count = stats.lockedByType[type] {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(.blue)
                                Text(type.displayName)
                                Spacer()
                                Text("\(count)")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                } header: {
                    Text("按锁定类型")
                }
            }
        }
        .padding()
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    DreamPrivacyView()
}
