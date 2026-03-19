//
//  DreamVoiceCommandView.swift
//  DreamLog
//
//  Phase 71 - 语音命令 UI 界面
//  提供语音交互界面和命令历史查看
//

import SwiftUI

// MARK: - 主视图

struct DreamVoiceCommandView: View {
    @StateObject private var service = VoiceCommandService.shared
    @State private var showingHelp = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 语音状态卡片
                VoiceStatusCard(service: service)
                    .padding()
                
                // 命令历史
                if !service.results.isEmpty {
                    Text("历史记录")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    List(filteredResults) { result in
                        VoiceCommandRow(result: result)
                    }
                    .listStyle(.inset)
                } else {
                    VoiceEmptyState()
                }
            }
            .navigationTitle("语音命令")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !service.results.isEmpty {
                        Button(action: { service.clearHistory() }) {
                            Image(systemName: "trash")
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    VoiceControlBar(service: service)
                }
            }
            .searchable(text: $searchText, prompt: "搜索命令历史")
            .sheet(isPresented: $showingHelp) {
                VoiceCommandHelpView()
            }
            .onAppear {
                service.checkAuthorization()
            }
        }
    }
    
    private var filteredResults: [VoiceCommandResult] {
        if searchText.isEmpty {
            return service.results
        }
        return service.results.filter {
            $0.transcribedText.localizedCaseInsensitiveContains(searchText) ||
            ($0.command?.description.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

// MARK: - 语音状态卡片

struct VoiceStatusCard: View {
    @ObservedObject var service: VoiceCommandService
    
    var body: some View {
        VStack(spacing: 16) {
            // 状态指示器
            HStack {
                Spacer()
                
                ZStack {
                    // 外圈脉冲动画
                    if service.isListening {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 4)
                            .frame(width: 80, height: 80)
                            .scaleEffect(service.isProcessing ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: service.isProcessing)
                    }
                    
                    // 内圈
                    Circle()
                        .fill(statusColor)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: statusIcon)
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        )
                }
                
                Spacer()
            }
            
            // 状态文本
            Text(statusText)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(statusDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 授权状态
            if service.authorizationStatus != .authorized {
                Button(action: { service.requestAuthorization() }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("需要语音识别权限")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var statusColor: Color {
        if service.authorizationStatus != .authorized {
            return .orange
        } else if service.isListening {
            return .red
        } else {
            return .green
        }
    }
    
    private var statusIcon: String {
        if service.authorizationStatus != .authorized {
            return "exclamationmark.triangle"
        } else if service.isListening {
            return service.isProcessing ? "waveform" : "mic.fill"
        } else {
            return "mic.slash.fill"
        }
    }
    
    private var statusText: String {
        if service.authorizationStatus != .authorized {
            return "需要授权"
        } else if service.isListening {
            return service.isProcessing ? "正在聆听..." : "聆听中"
        } else {
            return "点击开始"
        }
    }
    
    private var statusDescription: String {
        if service.authorizationStatus != .authorized {
            return "请点击授权以使用语音命令"
        } else if service.isListening {
            return "说出你的命令，例如\"记录梦境\""
        } else {
            return "点击下方按钮开始语音控制"
        }
    }
}

// MARK: - 命令历史行

struct VoiceCommandRow: View {
    let result: VoiceCommandResult
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: result.command?.icon ?? "questionmark.circle")
                .font(.title2)
                .foregroundColor(result.isSuccess ? .green : .orange)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                // 识别文本
                Text(result.transcribedText)
                    .font(.body)
                    .fontWeight(.medium)
                
                // 命令描述
                if let command = result.command {
                    Text(command.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 置信度和时间
                HStack {
                    Text(String(format: "%.0f%%", result.confidence * 100))
                        .font(.caption2)
                        .foregroundColor(confidenceColor)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(result.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 成功标记
            if result.isSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var confidenceColor: Color {
        if result.confidence > 0.8 {
            return .green
        } else if result.confidence > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - 空状态

struct VoiceEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无语音命令历史")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击下方按钮开始使用语音控制")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - 控制栏

struct VoiceControlBar: View {
    @ObservedObject var service: VoiceCommandService
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            
            Button(action: toggleListening) {
                Image(systemName: service.isListening ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(service.isListening ? Color.red : Color.green)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(service.authorizationStatus != .authorized)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func toggleListening() {
        Task {
            if service.isListening {
                service.stopListening()
            } else {
                do {
                    try await service.startListening()
                } catch {
                    print("启动语音识别失败：\(error)")
                }
            }
        }
    }
}

// MARK: - 帮助视图

struct VoiceCommandHelpView: View {
    @Environment(\.dismiss) var dismiss
    let service = VoiceCommandService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("记录相关")) {
                    ForEach(commandsWithKeywords(["记录梦境", "快速记录", "开始录音", "停止录音"]), id: \.command) { item in
                        CommandHelpRow(command: item.command, keywords: item.keywords)
                    }
                }
                
                Section(header: Text("查询相关")) {
                    ForEach(commandsWithKeywords(["查看统计", "今天有什么梦", "最近的梦境", "搜索梦境"]), id: \.command) { item in
                        CommandHelpRow(command: item.command, keywords: item.keywords)
                    }
                }
                
                Section(header: Text("导航相关")) {
                    ForEach(commandsWithKeywords(["打开画廊", "打开洞察", "打开日历", "打开设置"]), id: \.command) { item in
                        CommandHelpRow(command: item.command, keywords: item.keywords)
                    }
                }
                
                Section(header: Text("功能相关")) {
                    ForEach(commandsWithKeywords(["分享梦境", "锁定梦境", "分析梦境", "设置提醒"]), id: \.command) { item in
                        CommandHelpRow(command: item.command, keywords: item.keywords)
                    }
                }
                
                Section(header: Text("提示")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("说话清晰，语速适中")
                        }
                        
                        HStack {
                            Image(systemName: "volume.fill")
                                .foregroundColor(.blue)
                            Text("确保环境安静，减少背景噪音")
                        }
                        
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(.green)
                            Text("部分功能需要网络连接")
                        }
                    }
                    .font(.subheadline)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("语音命令帮助")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func commandsWithKeywords(_ keywords: [String]) -> [(command: VoiceCommand, keywords: [String])] {
        VoiceCommand.allCases.compactMap { command in
            if keywords.contains(where: { command.keywords.contains($0) }) {
                return (command, command.keywords)
            }
            return nil
        }
    }
}

struct CommandHelpRow: View {
    let command: VoiceCommand
    let keywords: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: command.icon)
                    .foregroundColor(.green)
                    .frame(width: 30)
                
                Text(command.description)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            LazyVFlow(alignment: .leading, spacing: 4) {
                ForEach(keywords.prefix(4), id: \.self) { keyword in
                    Text(keyword)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct DreamVoiceCommandView_Previews: PreviewProvider {
    static var previews: some View {
        DreamVoiceCommandView()
    }
}
