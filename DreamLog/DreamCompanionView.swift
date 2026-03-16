//
//  DreamCompanionView.swift
//  DreamLog
//
//  Phase 56 - 梦境 AI 伙伴系统
//  UI 界面
//

import SwiftUI

// MARK: - Main View

struct DreamCompanionView: View {
    @StateObject private var companionService = DreamCompanionService()
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.modelContext) private var modelContext
    
    @State private var sessions: [CompanionSession] = []
    @State private var selectedSession: CompanionSession?
    @State private var showingNewSessionSheet = false
    @State private var selectedDream: Dream?
    @State private var showingDreamPicker = false
    @State private var showingStats = false
    @State private var showingShareSheet = false
    @State private var shareText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 会话列表
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("AI 伙伴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !sessions.isEmpty {
                        Button(action: { showingNewSessionSheet = true }) {
                            Label("新对话", systemImage: "plus")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    statsButton
                }
            }
            .task {
                await loadSessions()
            }
            .sheet(isPresented: $showingNewSessionSheet) {
                NewSessionView(companionService: companionService, dreamStore: dreamStore)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(item: $selectedDream) { dream in
                DreamDetailView(dream: dream)
                    .environmentObject(dreamStore)
            }
            .sheet(isPresented: $showingStats) {
                CompanionStatsView(companionService: companionService)
            }
            .sheet(isPresented: $showingShareSheet) {
                ActivityView(activityItems: [shareText])
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("开始你的第一次梦境对话")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("AI 伙伴会帮你解析梦境、探索潜意识、\n发现梦境中的智慧和启示")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "🔮", title: "梦境解析", desc: "深度解析梦境含义")
                FeatureRow(icon: "💭", title: "探索对话", desc: "探索梦境与现实的联系")
                FeatureRow(icon: "💡", title: "洞察发现", desc: "发现重复的梦境模式")
                FeatureRow(icon: "🎯", title: "成长指导", desc: "从梦境中获取生活启示")
            }
            .padding(.horizontal, 40)
            
            Button(action: { showingNewSessionSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("开始新对话")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .cornerRadius(30)
            }
            .padding(.top, 24)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Session List
    
    private var sessionListView: some View {
        List {
            // 快速开始
            Section {
                QuickStartCard(companionService: companionService)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            
            // 最近对话
            Section("最近对话") {
                ForEach(sessions.filter { !$0.isArchived }) { session in
                    SessionRow(session: session)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSession = session
                        }
                }
                .onDelete(perform: deleteSessions)
            }
            
            // 已归档
            if sessions.contains(where: { $0.isArchived }) {
                Section("已归档") {
                    ForEach(sessions.filter { $0.isArchived }) { session in
                        SessionRow(session: session)
                            .opacity(0.6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSession = session
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await loadSessions()
        }
    }
    
    // MARK: - Stats Button
    
    private var statsButton: some View {
        Button(action: {
            showingStats = true
        }) {
            Image(systemName: "chart.bar.fill")
        }
    }
    
    // MARK: - Actions
    
    private func loadSessions() async {
        sessions = await companionService.getAllSessions()
    }
    
    private func deleteSessions(at offsets: IndexSet) {
        let activeSessions = sessions.filter { !$0.isArchived }
        var sessionIdsToDelete: [UUID] = []
        
        for index in offsets {
            if index < activeSessions.count {
                sessionIdsToDelete.append(activeSessions[index].id)
            }
        }
        
        Task {
            await companionService.deleteSessions(sessionIds: sessionIdsToDelete)
            await loadSessions()
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: CompanionSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(session.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(session.topic)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Text("\(session.messageCount) 条消息")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !session.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(session.tags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Start Card

struct QuickStartCard: View {
    @ObservedObject var companionService: DreamCompanionService
    @EnvironmentObject var dreamStore: DreamStore
    @State private var showingDreamPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("快速开始")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickStartButton(
                    icon: "✨",
                    title: "解析梦境",
                    color: .purple
                ) {
                    showingDreamPicker = true
                }
                
                QuickStartButton(
                    icon: "💭",
                    title: "自由对话",
                    color: .blue
                ) {
                    Task {
                        _ = await companionService.createSession(topic: "自由对话")
                    }
                }
                
                QuickStartButton(
                    icon: "🔮",
                    title: "探索符号",
                    color: .orange
                ) {
                    Task {
                        _ = await companionService.createSession(topic: "符号探索")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingDreamPicker) {
            DreamPickerView(dreamStore: dreamStore) { dream in
                Task {
                    _ = await companionService.createSession(dreamId: dream.id, topic: "梦境解析")
                }
            }
            .environmentObject(dreamStore)
        }
    }
}

// MARK: - Quick Start Button

struct QuickStartButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.title)
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
}

// MARK: - New Session View

struct NewSessionView: View {
    @ObservedObject var companionService: DreamCompanionService
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTopic: String = "梦境解析"
    @State private var selectedDream: Dream?
    @State private var showingDreamPicker = false
    @State private var customTopic: String = ""
    
    let topics = ["梦境解析", "自由对话", "符号探索", "创意启发", "梦境反思", "其他"]
    
    var body: some View {
        NavigationView {
            Form {
                // 选择话题
                Section("对话话题") {
                    Picker("话题", selection: $selectedTopic) {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic).tag(topic)
                        }
                    }
                    
                    if selectedTopic == "其他" {
                        TextField("输入自定义话题", text: $customTopic)
                    }
                }
                
                // 关联梦境（可选）
                Section("关联梦境（可选）") {
                    if let dream = selectedDream {
                        Button(action: { showingDreamPicker = true }) {
                            HStack {
                                Text(dream.title)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    } else {
                        Button(action: { showingDreamPicker = true }) {
                            HStack {
                                Text("选择梦境")
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 模板选择
                Section("对话模板") {
                    ForEach(CompanionTemplate.defaultTemplates) { template in
                        TemplateRow(template: template) {
                            selectedTopic = template.name
                        }
                    }
                }
            }
            .navigationTitle("新对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始") {
                        startSession()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingDreamPicker) {
                DreamPickerView(dreamStore: dreamStore) { dream in
                    selectedDream = dream
                }
                .environmentObject(dreamStore)
            }
        }
    }
    
    private func startSession() {
        Task {
            let topic = selectedTopic == "其他" ? customTopic : selectedTopic
            let dreamId = selectedDream?.id
            _ = await companionService.createSession(dreamId: dreamId, topic: topic)
            dismiss()
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: CompanionTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(template.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Dream Picker View

struct DreamPickerView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    let onSelect: (Dream) -> Void
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreamStore.dreams.prefix(20).map { $0 }
        }
        return dreamStore.dreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }.prefix(20).map { $0 }
    }
    
    var body: some View {
        NavigationView {
            List(filteredDreams) { dream in
                Button(action: {
                    onSelect(dream)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dream.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(dream.content.prefix(100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack {
                            Text(dream.date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            ForEach(dream.emotions.prefix(3), id: \.self) { emotion in
                                Text(emotion)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索梦境")
            .navigationTitle("选择梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Chat View

struct CompanionChatView: View {
    @ObservedObject var session: CompanionSession
    @StateObject private var companionService = DreamCompanionService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText: String = ""
    @State private var isSending = false
    @State private var selectedQuickQuestion: QuickQuestion?
    
    var messages: [CompanionMessage] {
        session.messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            messageList
            
            Divider()
            
            // 快速问题
            quickQuestionsView
            
            Divider()
            
            // 输入区域
            inputArea
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                sessionOptionsButton
            }
        }
        .task {
            await companionService.loadSession(sessionId: session.id)
        }
    }
    
    // MARK: - Message List
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, newValue in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Questions
    
    private var quickQuestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickQuestion.defaultQuestions) { question in
                    Button(action: {
                        inputText = question.question
                    }) {
                        HStack(spacing: 4) {
                            Text(question.icon)
                            Text(question.question)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1))
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
            TextField("输入消息...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 40)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(inputText.isEmpty ? .secondary : .accentColor)
            }
            .disabled(inputText.isEmpty || isSending)
            .padding(.trailing, 8)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Session Options
    
    private var sessionOptionsButton: some View {
        Menu {
            Button(action: {
                Task {
                    shareText = await companionService.shareConversation(sessionId: session.id)
                    showingShareSheet = true
                }
            }) {
                Label("分享对话", systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
                Task {
                    let exportText = await companionService.exportConversation(sessionId: session.id)
                    await exportToFiles(exportText)
                }
            }) {
                Label("导出为文本", systemImage: "doc.text")
            }
            
            Divider()
            
            Button(role: .destructive) {
                Task {
                    await companionService.archiveSession(sessionId: session.id)
                    dismiss()
                }
            } label: {
                Label("结束对话", systemImage: "xmark.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    // MARK: - Export Helper
    
    private func exportToFiles(_ text: String) async {
        // 这里会调用 iOS 的文件导出功能
        // 简化处理：在实际应用中需要使用 UIDocumentInteractionController
        print("导出内容：\(text.prefix(200))...")
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !inputText.isEmpty && !isSending else { return }
        
        let message = inputText
        inputText = ""
        isSending = true
        
        Task {
            _ = await companionService.sendMessage(message, dreamId: session.dreamId)
            isSending = false
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: CompanionMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                userBubble
            } else {
                aiBubble
                Spacer()
            }
        }
    }
    
    private var userBubble: some View {
        Text(message.content)
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(16)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var aiBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(message.tone.icon)
                    .font(.caption)
                Text(message.messageType.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
            
            if let timestamp = formatTimestamp(message.timestamp) {
                Text(timestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatTimestamp(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Stats View

struct CompanionStatsView: View {
    @ObservedObject var companionService: DreamCompanionService
    @Environment(\.dismiss) private var dismiss
    
    @State private var stats: CompanionStats?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("加载统计...")
                } else if let stats = stats {
                    statsContent(stats)
                } else {
                    Text("无法加载统计")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("对话统计")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadStats()
            }
        }
    }
    
    private func statsContent(_ stats: CompanionStats) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 概览卡片
                overviewCards(stats)
                
                // 话题分布
                topicDistribution(stats)
                
                // 周趋势
                weeklyTrend(stats)
                
                // 洞察统计
                insightsStats(stats)
            }
            .padding()
        }
    }
    
    private func overviewCards(_ stats: CompanionStats) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "总会话", value: "\(stats.totalSessions)", icon: "message.fill", color: .blue)
                StatCard(title: "总消息", value: "\(stats.totalMessages)", icon: "text.bubble.fill", color: .green)
            }
            
            HStack(spacing: 12) {
                StatCard(title: "平均长度", value: String(format: "%.1f", stats.averageSessionLength), icon: "ruler", color: .orange)
                StatCard(title: "洞察生成", value: "\(stats.insightsGenerated)", icon: "lightbulb.fill", color: .yellow)
            }
        }
    }
    
    private func topicDistribution(_ stats: CompanionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门话题")
                .font(.headline)
            
            ForEach(stats.mostCommonTopics.prefix(5), id: \.self) { topic in
                HStack {
                    Text(topic)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.accentColor)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private func weeklyTrend(_ stats: CompanionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("周趋势")
                .font(.headline)
            
            ForEach(stats.weeklyTrend, id: \.weekStart) { week in
                HStack {
                    VStack(alignment: .leading) {
                        Text(formatWeekStart(week.weekStart))
                            .font(.subheadline)
                        Text("\(week.sessionsCount) 会话 · \(week.messagesCount) 消息")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.1f", week.averageDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private func insightsStats(_ stats: CompanionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("洞察分析")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("已生成洞察")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(stats.insightsGenerated)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()
                Image(systemName: "lightbulb.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            if let satisfaction = stats.userSatisfactionScore {
                HStack {
                    Text("满意度")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f/5.0", satisfaction))
                        .font(.headline)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private func formatWeekStart(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func loadStats() async {
        isLoading = true
        stats = await companionService.getStats()
        isLoading = false
    }
}

// MARK: - Stat Card

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
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Activity View

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    DreamCompanionView()
        .environmentObject(DreamStore())
}
