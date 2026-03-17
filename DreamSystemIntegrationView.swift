//
//  DreamSystemIntegrationView.swift
//  DreamLog - Phase 59: iOS System Integration Enhancement
//
//  Created by DreamLog Team on 2026-03-17.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import SwiftData

struct DreamSystemIntegrationView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service: DreamSystemIntegrationService
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                QuickActionsTabView(service: service)
                    .tabItem {
                        Label("快捷操作", systemImage: "bolt.fill")
                    }
                    .tag(0)
                
                FocusModeTabView(service: service)
                    .tabItem {
                        Label("专注模式", systemImage: "moon.fill")
                    }
                    .tag(1)
                
                SiriSuggestionsTabView(service: service)
                    .tabItem {
                        Label("Siri 建议", systemImage: "mic.fill")
                    }
                    .tag(2)
                
                LockScreenTabView(service: service)
                    .tabItem {
                        Label("锁屏", systemImage: "lock.shield.fill")
                    }
                    .tag(3)
                
                StatsTabView(service: service)
                    .tabItem {
                        Label("统计", systemImage: "chart.bar.fill")
                    }
                    .tag(4)
            }
            .navigationTitle("系统集成")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("重置") {
                        service.resetStats()
                    }
                }
            }
        }
        .onAppear {
            service.initializeDefaultConfigs()
        }
    }
    
    init(modelContext: ModelContext) {
        _service = StateObject(wrappedValue: DreamSystemIntegrationService(modelContext: modelContext))
    }
}

// MARK: - Quick Actions Tab

struct QuickActionsTabView: View {
    @ObservedObject var service: DreamSystemIntegrationService
    @State private var enabledActions: Set<String> = []
    
    var body: some View {
        List {
            Section(header: Text("主屏幕快捷操作")) {
                Text("长按 App 图标可快速访问常用功能")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(QuickActionType.allCases) { action in
                    QuickActionRow(
                        action: action,
                        isEnabled: enabledActions.contains(action.rawValue)
                    ) { isEnabled in
                        if isEnabled {
                            enabledActions.insert(action.rawValue)
                        } else {
                            enabledActions.remove(action.rawValue)
                        }
                        try? service.updateQuickAction(action, isEnabled: isEnabled)
                    }
                }
            }
            
            Section(header: Text("使用说明")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.blue)
                        Text("长按 DreamLog 图标")
                    }
                    
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.blue)
                        Text("选择快捷操作")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("快速进入功能")
                    }
                }
                .font(.caption)
            }
        }
        .onAppear {
            enabledActions = Set(service.getEnabledQuickActions().map { $0.rawValue })
        }
    }
}

struct QuickActionRow: View {
    let action: QuickActionType
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: action.iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(action.displayName)
                    .font(.body)
                Text(action.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Focus Mode Tab

struct FocusModeTabView: View {
    @ObservedObject var service: DreamSystemIntegrationService
    @State private var config: DreamFocusModeConfig?
    
    var body: some View {
        List {
            Section(header: Text("睡眠专注模式")) {
                Toggle("自动启用录音准备", isOn: $config?.autoRecordInSleepFocus ?? false)
                    .onChange(of: config?.autoRecordInSleepFocus) { _, newValue in
                        config?.autoRecordInSleepFocus = newValue
                        saveConfig()
                    }
                
                Toggle("显示睡眠小组件", isOn: $config?.showWidgetInSleepFocus ?? false)
                    .onChange(of: config?.showWidgetInSleepFocus) { _, newValue in
                        config?.showWidgetInSleepFocus = newValue
                        saveConfig()
                    }
            }
            
            Section(header: Text("工作专注模式")) {
                Toggle("禁用梦境通知", isOn: $config?.disableNotificationsInWorkFocus ?? false)
                    .onChange(of: config?.disableNotificationsInWorkFocus) { _, newValue in
                        config?.disableNotificationsInWorkFocus = newValue
                        saveConfig()
                    }
            }
            
            Section(header: Text("个人专注模式")) {
                Toggle("显示每日灵感", isOn: $config?.showInspirationInPersonalFocus ?? false)
                    .onChange(of: config?.showInspirationInPersonalFocus) { _, newValue in
                        config?.showInspirationInPersonalFocus = newValue
                        saveConfig()
                    }
            }
            
            Section(header: Text("使用说明")) {
                Text("专注模式开启时，DreamLog 会自动调整行为以配合你的状态")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if config == nil {
                config = service.getFocusModeConfig() ?? service.createDefaultFocusModeConfig()
            }
        }
    }
    
    private func saveConfig() {
        guard let config = config else { return }
        try? service.saveFocusModeConfig(config)
    }
}

// MARK: - Siri Suggestions Tab

struct SiriSuggestionsTabView: View {
    @ObservedObject var service: DreamSystemIntegrationService
    @State private var config: DreamSiriSuggestionsConfig?
    
    var body: some View {
        List {
            Section(header: Text("Siri 建议设置")) {
                Toggle("启用 Siri 建议", isOn: $config?.isEnabled ?? false)
                    .onChange(of: config?.isEnabled) { _, newValue in
                        config?.isEnabled = newValue
                        saveConfig()
                        Task {
                            await service.updateSiriSuggestions()
                        }
                    }
            }
            
            if config?.isEnabled ?? false {
                Section(header: Text("显示位置")) {
                    Toggle("锁屏", isOn: $config?.showOnLockScreen ?? false)
                        .onChange(of: config?.showOnLockScreen) { _, newValue in
                            config?.showOnLockScreen = newValue
                            saveConfig()
                        }
                    
                    Toggle("Spotlight 搜索", isOn: $config?.showInSpotlight ?? false)
                        .onChange(of: config?.showInSpotlight) { _, newValue in
                            config?.showInSpotlight = newValue
                            saveConfig()
                        }
                    
                    Toggle("App 库", isOn: $config?.showInAppLibrary ?? false)
                        .onChange(of: config?.showInAppLibrary) { _, newValue in
                            config?.showInAppLibrary = newValue
                            saveConfig()
                        }
                }
                
                Section(header: Text("建议类型")) {
                    ForEach(SiriSuggestionType.allCases) { type in
                        SuggestionTypeRow(type: type)
                    }
                }
                
                Section(header: Text("智能建议")) {
                    Toggle("基于时间建议", isOn: $config?.timeBasedSuggestions ?? false)
                        .onChange(of: config?.timeBasedSuggestions) { _, newValue in
                            config?.timeBasedSuggestions = newValue
                            saveConfig()
                            Task {
                                await service.updateSiriSuggestions()
                            }
                        }
                    
                    Toggle("基于习惯建议", isOn: $config?.habitBasedSuggestions ?? false)
                        .onChange(of: config?.habitBasedSuggestions) { _, newValue in
                            config?.habitBasedSuggestions = newValue
                            saveConfig()
                            Task {
                                await service.updateSiriSuggestions()
                            }
                        }
                }
            }
            
            Section(header: Text("使用说明")) {
                Text("Siri 会根据你的使用习惯和时间，在合适的时候提醒你记录梦境或查看灵感")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if config == nil {
                config = service.getSiriSuggestionsConfig() ?? service.createDefaultSiriSuggestionsConfig()
            }
        }
    }
    
    private func saveConfig() {
        guard let config = config else { return }
        try? service.saveSiriSuggestionsConfig(config)
    }
}

struct SuggestionTypeRow: View {
    let type: SiriSuggestionType
    
    var body: some View {
        HStack {
            Image(systemName: type.iconName)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(type.displayName)
        }
    }
}

// MARK: - Lock Screen Tab

struct LockScreenTabView: View {
    @ObservedObject var service: DreamSystemIntegrationService
    @State private var config: DreamLockScreenConfig?
    
    var body: some View {
        List {
            Section(header: Text("锁屏快捷操作")) {
                Toggle("启用锁屏快捷操作", isOn: $config?.isEnabled ?? false)
                    .onChange(of: config?.isEnabled) { _, newValue in
                        config?.isEnabled = newValue
                        saveConfig()
                    }
                
                if config?.isEnabled ?? false {
                    NavigationLink("配置快捷操作") {
                        LockScreenActionConfigView(config: $config)
                    }
                }
            }
            
            Section(header: Text("高级选项")) {
                Toggle("始终显示屏幕", isOn: $config?.showOnAlwaysOnDisplay ?? false)
                    .onChange(of: config?.showOnAlwaysOnDisplay) { _, newValue in
                        config?.showOnAlwaysOnDisplay = newValue
                        saveConfig()
                    }
                
                Toggle("需要 Face ID", isOn: $config?.requireFaceID ?? false)
                    .onChange(of: config?.requireFaceID) { _, newValue in
                        config?.requireFaceID = newValue
                        saveConfig()
                    }
            }
            
            Section(header: Text("使用说明")) {
                Text("在锁屏界面快速访问 DreamLog 功能，无需解锁手机")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if config == nil {
                config = service.getLockScreenConfig() ?? service.createDefaultLockScreenConfig()
            }
        }
    }
    
    private func saveConfig() {
        guard let config = config else { return }
        try? service.saveLockScreenConfig(config)
    }
}

struct LockScreenActionConfigView: View {
    @Binding var config: DreamLockScreenConfig?
    @State private var selectedActions: [LockScreenQuickAction] = []
    
    var body: some View {
        List {
            Section(header: Text("已选操作")) {
                ForEach(selectedActions) { action in
                    HStack {
                        Image(systemName: action.type.iconName)
                            .foregroundColor(.blue)
                        Text(action.type.displayName)
                        Spacer()
                        Text(action.position.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onMove { indices, newOffset in
                    selectedActions.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            
            Section(header: Text("添加操作")) {
                ForEach(LockScreenActionType.allCases) { type in
                    if !selectedActions.contains(where: { $0.type == type }) {
                        Button(action: {
                            addAction(type)
                        }) {
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(.green)
                                Text("添加 \(type.displayName)")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("锁屏操作")
        .onAppear {
            selectedActions = config?.quickActions ?? []
        }
        .onDisappear {
            config?.quickActions = selectedActions
        }
    }
    
    private func addAction(_ type: LockScreenActionType) {
        let position = getNextAvailablePosition()
        let action = LockScreenQuickAction(type: type, position: position)
        selectedActions.append(action)
    }
    
    private func getNextAvailablePosition() -> LockScreenPosition {
        let usedPositions = Set(selectedActions.map { $0.position })
        for position in LockScreenPosition.allCases {
            if !usedPositions.contains(position) {
                return position
            }
        }
        return .topLeft
    }
}

extension LockScreenPosition {
    var displayName: String {
        switch self {
        case .topLeft: return "左上"
        case .topRight: return "右上"
        case .bottomLeft: return "左下"
        case .bottomRight: return "右下"
        }
    }
}

// MARK: - Stats Tab

struct StatsTabView: View {
    @ObservedObject var service: DreamSystemIntegrationService
    @State private var stats: SystemIntegrationStats = SystemIntegrationStats()
    
    var body: some View {
        List {
            Section(header: Text("使用统计")) {
                StatRow(title: "快捷操作使用", value: "\(stats.quickActionUses) 次")
                StatRow(title: "专注模式触发", value: "\(stats.focusModeTriggers) 次")
                StatRow(title: "控制中心使用", value: "\(stats.controlCenterUses) 次")
                StatRow(title: "锁屏操作使用", value: "\(stats.lockScreenActionUses) 次")
            }
            
            Section(header: Text("Siri 建议")) {
                StatRow(title: "展示次数", value: "\(stats.siriSuggestionsShown) 次")
                StatRow(title: "点击次数", value: "\(stats.siriSuggestionsTapped) 次")
                StatRow(title: "点击率", value: String(format: "%.1f%%", stats.siriSuggestionTapRate))
            }
            
            Section(header: Text("最后使用")) {
                if let lastUsed = stats.lastUsedDate {
                    Text(lastUsed.formatted())
                } else {
                    Text("暂无记录")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("重置统计", role: .destructive) {
                    service.resetStats()
                    stats = service.getStats()
                }
            }
        }
        .onAppear {
            stats = service.getStats()
        }
    }
}

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

// MARK: - Preview

#Preview {
    DreamSystemIntegrationView(modelContext: ModelContext(for: DreamLogApp.self))
}
