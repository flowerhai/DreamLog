//
//  DreamVoiceCommandView.swift
//  DreamLog - 梦境语音命令 UI 界面
//  Phase 84: 梦境语音命令系统
//
//  Created by DreamLog Team on 2026/3/21.
//

import SwiftUI
import SwiftData

// MARK: - 主界面

struct DreamVoiceCommandView: View {
    @StateObject private var service: DreamVoiceCommandService
    @Environment(\.modelContext) private var modelContext
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    init(modelContext: ModelContext? = nil) {
        _service = StateObject(wrappedValue: DreamVoiceCommandService(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 头部统计
                statsHeader
                
                // 主按钮区域
                mainButtonSection
                
                // 最近命令
                recentCommandsSection
                
                // 快速命令列表
                quickCommandsList
            }
            .padding()
            .navigationTitle("语音命令")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                VoiceCommandSettingsView(service: service)
            }
            .sheet(isPresented: $showingHelp) {
                VoiceCommandHelpView()
            }
            .onAppear {
                service.loadHistory()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var statsHeader: some View {
        let stats = service.getStats()
        
        return VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatCard(
                    title: "总命令",
                    value: "\(stats.totalCommands)",
                    icon: "🎤",
                    color: .blue
                )
                
                StatCard(
                    title: "成功率",
                    value: String(format: "%.0f%%", stats.successRate * 100),
                    icon: "✅",
                    color: .green
                )
                
                StatCard(
                    title: "今日",
                    value: "\(stats.todayCommands)",
                    icon: "📅",
                    color: .orange
                )
            }
            
            if let mostUsed = stats.mostUsedCommand {
                Text("最常用：\(mostUsed.icon) \(mostUsed.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var mainButtonSection: some View {
        VStack(spacing: 16) {
            // 语音按钮
            Button(action: {
                Task {
                    if service.isListening {
                        service.stopListening()
                    } else {
                        try? await service.startListening()
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: service.isListening ? [.red, .orange] : [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: service.isListening ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 8) {
                        Image(systemName: service.isListening ? "waveform.circle.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text(service.isListening ? "正在听..." : "按住说话")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 状态指示
            if service.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("处理中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 识别文本
            if !service.recognizedText.isEmpty {
                Text("\"\(service.recognizedText)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            // 结果消息
            if let result = service.lastResult {
                ResultCard(result: result)
            }
        }
    }
    
    private var recentCommandsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近命令")
                .font(.headline)
            
            if service.commandHistory.isEmpty {
                Text("暂无历史记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(service.commandHistory.prefix(5)) { history in
                    HistoryRow(history: history)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var quickCommandsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速命令")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(VoiceCommandType.allCases, id: \.self) { command in
                    QuickCommandButton(
                        command: command,
                        action: {
                            service.executeCommand(command, recognizedText: command.displayName)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 子组件

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title2)
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

struct ResultCard: View {
    let result: VoiceCommandResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.commandType.displayName)
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "%.0f%%", result.confidence * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(result.recognizedText)
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

struct HistoryRow: View {
    let history: VoiceCommandHistory
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: history.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(history.success ? .green : .red)
                        .font(.caption)
                    
                    Text(history.commandType)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(history.recognizedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(history.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.2fs", history.responseTime))
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuickCommandButton: View {
    let command: VoiceCommandType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(command.icon)
                    .font(.title2)
                Text(command.displayName)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 设置界面

struct VoiceCommandSettingsView: View {
    @ObservedObject var service: DreamVoiceCommandService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本设置") {
                    Toggle("启用语音命令", isOn: $service.config.isEnabled)
                    
                    TextField("唤醒词", text: $service.config.wakeWord)
                    
                    Picker("语言", selection: $service.config.language) {
                        Text("简体中文").tag("zh-CN")
                        Text("English").tag("en-US")
                    }
                }
                
                Section("反馈设置") {
                    Toggle("触觉反馈", isOn: $service.config.hapticFeedback)
                    Toggle("语音反馈", isOn: $service.config.voiceFeedback)
                    Toggle("显示确认", isOn: $service.config.showConfirmation)
                    Toggle("自动执行", isOn: $service.config.autoExecute)
                }
                
                Section("历史记录") {
                    Stepper("保留天数：\(service.config.maxHistoryDays) 天", value: $service.config.maxHistoryDays, in: 7...90)
                    
                    Stepper("最低置信度：\(Int(service.config.minConfidence * 100))%",
                           value: Binding(
                                get: { Int(service.config.minConfidence * 100) },
                                set: { service.config.minConfidence = Double($0) / 100.0 }
                            ),
                            in: 50...95)
                }
                
                Section("统计数据") {
                    let stats = service.getStats()
                    
                    HStack {
                        Text("总命令数")
                        Spacer()
                        Text("\(stats.totalCommands)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("成功率")
                        Spacer()
                        Text(String(format: "%.1f%%", stats.successRate * 100))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("平均响应时间")
                        Spacer()
                        Text(String(format: "%.2f 秒", stats.averageResponseTime))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("清除历史记录", role: .destructive) {
                        clearHistory()
                    }
                }
            }
            .navigationTitle("语音命令设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        service.saveConfig()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func clearHistory() {
        guard let modelContext = service.modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<VoiceCommandHistory>()
            let records = try modelContext.fetch(descriptor)
            for record in records {
                modelContext.delete(record)
            }
            service.commandHistory.removeAll()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
}

// MARK: - 帮助界面

struct VoiceCommandHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    let commandGroups: [(category: String, commands: [VoiceCommandType])] = [
        ("记录类", [.recordDream, .quickNote]),
        ("查询类", [.searchDream, .showStats, .showRecent, .showCalendar]),
        ("分析类", [.showInsights, .showTrends, .showPatterns]),
        ("功能类", [.startMeditation, .playMusic, .showGallery, .exportData]),
        ("设置类", [.openSettings, .setReminder]),
        ("帮助类", [.help, .whatCanIDo])
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(commandGroups, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.commands, id: \.self) { command in
                            HStack {
                                Text(command.icon)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(command.displayName)
                                        .font(.headline)
                                    
                                    Text("示例：\(examplePhrase(for: command))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section("使用提示") {
                    Text("• 点击麦克风按钮开始说话")
                    Text("• 清晰地说出命令短语")
                    Text("• 可以在设置中自定义唤醒词")
                    Text("• 支持中文和英文识别")
                }
            }
            .navigationTitle("语音命令帮助")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func examplePhrase(for command: VoiceCommandType) -> String {
        switch command {
        case .recordDream: return "记录梦境"
        case .quickNote: return "快速备注"
        case .searchDream: return "搜索飞行梦"
        case .showStats: return "查看统计"
        case .showRecent: return "最近的梦"
        case .showCalendar: return "梦境日历"
        case .showInsights: return "智能洞察"
        case .showTrends: return "梦境趋势"
        case .showPatterns: return "梦境模式"
        case .startMeditation: return "开始冥想"
        case .playMusic: return "播放音乐"
        case .showGallery: return "梦境画廊"
        case .exportData: return "导出数据"
        case .openSettings: return "打开设置"
        case .setReminder: return "设置提醒"
        case .help: return "帮助"
        case .whatCanIDo: return "我能做什么"
        }
    }
}

// MARK: - Preview

#Preview {
    DreamVoiceCommandView()
        .modelContainer(for: VoiceCommandHistory.self, inMemory: true)
}
