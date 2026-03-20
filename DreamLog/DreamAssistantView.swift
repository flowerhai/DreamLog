//
//  DreamAssistantView.swift
//  DreamLog
//
//  梦境 AI 助手聊天界面
//  Phase 13 - AI 助手
//

import SwiftUI

struct DreamAssistantView: View {
    @ObservedObject private var assistant = DreamAssistantService.shared
    @State private var inputText = ""
    @State private var showingRecordView = false
    @State private var showingStats = false
    @State private var showingGallery = false
    @State private var showingSearch = false
    @State private var showingLucidTraining = false
    @State private var showingMeditation = false
    @State private var showingPredictions = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 预测洞察 (如果可用)
                if !assistant.predictionInsights.isEmpty {
                    predictionInsightsView
                }
                
                // 聊天消息列表
                messageList
                
                // 语音状态指示器
                if assistant.isListening || assistant.isSpeaking {
                    voiceStatusIndicator
                }
                
                Divider()
                
                // 建议芯片
                suggestionChips
                
                Divider()
                
                // 输入区域
                inputArea
            }
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // 语音模式切换
                    Button(action: {
                        withAnimation {
                            assistant.enableVoiceMode(!assistant.voiceModeEnabled)
                        }
                    }) {
                        Image(systemName: assistant.voiceModeEnabled ? "waveform" : "waveform.slash")
                            .foregroundColor(assistant.voiceModeEnabled ? .green : .secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 预测洞察按钮
                    Button(action: {
                        assistant.generatePredictionInsights()
                        showingPredictions = true
                    }) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        assistant.clearHistory()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .background(
                colorScheme == .dark ?
                Color.black.ignoresSafeArea() :
                Color(.systemGroupedBackground).ignoresSafeArea()
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingRecordView) {
            RecordView()
        }
        .sheet(isPresented: $showingStats) {
            InsightsView()
        }
        .sheet(isPresented: $showingGallery) {
            GalleryView()
        }
        .sheet(isPresented: $showingSearch) {
            DreamSearchView()
        }
        .sheet(isPresented: $showingLucidTraining) {
            LucidDreamTrainingView()
        }
        .sheet(isPresented: $showingMeditation) {
            MeditationView()
        }
        .sheet(isPresented: $showingPredictions) {
            PredictionInsightsSheet()
        }
    }
    
    // MARK: - Prediction Insights View
    
    private var predictionInsightsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(assistant.predictionInsights.indices, id: \.self) { index in
                    let insight = assistant.predictionInsights[index]
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: insight.icon)
                                .font(.caption)
                                .foregroundColor(.white)
                            Text(insight.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Text(insight.content)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                        
                        HStack {
                            Spacer()
                            Text(String(format: "%.0f%% 置信度", insight.confidence * 100))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(12)
                    .frame(width: 160)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .onTapGesture {
                        // 点击显示详细分析
                        showingPredictions = true
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(colorScheme == .dark ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
    }
    
    // MARK: - Voice Status Indicator
    
    private var voiceStatusIndicator: some View {
        HStack {
            if assistant.isListening {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.red)
                    Text("正在聆听...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
                .transition(.scale.combined(with: .opacity))
            }
            
            if assistant.isSpeaking {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.accentColor)
                    Text("正在播放...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(16)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Message List
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(assistant.messages) { message in
                        messageBubble(for: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: assistant.messages.count) { _ in
                if let lastMessage = assistant.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Bubble
    
    private func messageBubble(for message: ChatMessage) -> some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                // 消息内容
                messageContent(message)
                
                // 时间戳
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                message.sender == .user ?
                Color.accentColor.opacity(0.9) :
                (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.15))
            )
            .foregroundColor(message.sender == .user ? .white : .primary)
            .cornerRadius(16)
            .cornerRadius(message.sender == .user ? 16 : 16, corners: message.sender == .user ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
            
            if message.sender == .assistant {
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func messageContent(_ message: ChatMessage) -> some View {
        switch message.type {
        case .text:
            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
            
        case .suggestion:
            Text(message.content)
                .font(.body)
            
        case .dreamCard:
            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .font(.body)
                
                if let dreamIds = message.relatedDreams {
                    Text("点击查看 \(dreamIds.count) 个梦境")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
        case .insight:
            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
            }
            
        case .quickAction:
            Text(message.content)
                .font(.body)
        }
    }
    
    // MARK: - Suggestion Chips
    
    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(assistant.suggestions) { suggestion in
                    Button(action: {
                        Task {
                            await assistant.handleSuggestion(suggestion)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: suggestion.icon)
                                .font(.caption)
                            Text(suggestion.title)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            colorScheme == .dark ?
                            Color.gray.opacity(0.2) :
                            Color.gray.opacity(0.15)
                        )
                        .foregroundColor(.accentColor)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            // 快速操作按钮
            quickActionButton
            
            // 文本输入框
            TextField("询问关于梦境的问题...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await assistant.sendMessage(inputText)
                        inputText = ""
                    }
                }
            
            // 语音输入按钮
            Button(action: {
                if assistant.isListening {
                    assistant.stopListening()
                } else {
                    assistant.startListening()
                    // 实际 STT 由 UI 层处理，这里只是触发状态
                }
            }) {
                Image(systemName: assistant.isListening ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 18))
                    .foregroundColor(assistant.isListening ? .red : .accentColor)
            }
            .padding(.trailing, 4)
            
            // 发送按钮
            Button(action: {
                Task {
                    await assistant.sendMessage(inputText)
                    inputText = ""
                }
            }) {
                Image(systemName: assistant.state == .thinking ? "hourglass" : "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(inputText.isEmpty || assistant.state == .thinking ? .gray : .accentColor)
            }
            .disabled(inputText.isEmpty || assistant.state == .thinking)
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private var quickActionButton: some View {
        Menu {
            Button(action: { showingRecordView = true }) {
                Label("记录梦境", systemImage: "mic.fill")
            }
            Button(action: { showingStats = true }) {
                Label("查看统计", systemImage: "chart.bar")
            }
            Button(action: { showingGallery = true }) {
                Label("梦境画廊", systemImage: "photo.on.rectangle")
            }
            Button(action: { showingSearch = true }) {
                Label("搜索梦境", systemImage: "magnifyingglass")
            }
            Divider()
            Button(action: { showingLucidTraining = true }) {
                Label("清醒梦训练", systemImage: "brain.head.profile")
            }
            Button(action: { showingMeditation = true }) {
                Label("冥想", systemImage: "figure.mind.and.body")
            }
        } label: {
            Image(systemName: "plus.app")
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
        }
    }
}

// MARK: - Prediction Insights Sheet

struct PredictionInsightsSheet: View {
    @ObservedObject private var assistant = DreamAssistantService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if assistant.predictionInsights.isEmpty {
                        // 生成预测
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                            
                            Text("生成梦境预测")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("基于你的梦境记录，AI 将分析趋势并提供个性化洞察。")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                assistant.generatePredictionInsights()
                            }) {
                                Text("生成预测")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 60)
                    } else {
                        // 显示预测结果
                        ForEach(assistant.predictionInsights.indices, id: \.self) { index in
                            let insight = assistant.predictionInsights[index]
                            PredictionCard(insight: insight)
                        }
                        
                        // 深度分析报告
                        DeepAnalysisCard()
                    }
                }
                .padding()
            }
            .navigationTitle("梦境预测")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PredictionCard: View {
    let insight: DreamPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.purple)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(String(format: "置信度：%.0f%%", insight.confidence * 100))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text(insight.content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

struct DeepAnalysisCard: View {
    @ObservedObject private var assistant = DreamAssistantService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .cornerRadius(8)
                
                Text("深度分析报告")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            let report = assistant.performDeepAnalysis()
            
            VStack(spacing: 10) {
                AnalysisRow(title: "总梦境数", value: "\(report.totalDreams) 个", icon: "moon.fill")
                AnalysisRow(title: "平均清晰度", value: "\(report.avgClarity)/5", icon: "eye.fill")
                AnalysisRow(title: "平均强度", value: "\(report.avgIntensity)/5", icon: "flame.fill")
                AnalysisRow(title: "清醒梦比例", value: String(format: "%.1f%%", report.lucidRatio * 100), icon: "sparkles")
                AnalysisRow(title: "记录频率", value: report.dreamFrequency, icon: "calendar")
                AnalysisRow(title: "连续记录", value: "\(report.streakDays) 天", icon: "flame")
                AnalysisRow(title: "最佳时间", value: report.bestRecordingTime, icon: "clock.fill")
            }
            
            if !report.topTags.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text("热门主题")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                FlowLayout(spacing: 8) {
                    ForEach(report.topTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
            
            if !report.topEmotions.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text("主要情绪")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                FlowLayout(spacing: 8) {
                    ForEach(report.topEmotions, id: \.self) { emotion in
                        Text(emotion)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.white.opacity(0.8))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    DreamAssistantView()
}
