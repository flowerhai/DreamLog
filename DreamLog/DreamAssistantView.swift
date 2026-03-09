//
//  DreamAssistantView.swift
//  DreamLog
//
//  梦境 AI 助手聊天界面
//  Phase 13 - AI 助手
//

import SwiftUI

struct DreamAssistantView: View {
    @StateObject private var assistant = DreamAssistantService.shared
    @State private var inputText = ""
    @State private var showingRecordView = false
    @State private var showingStats = false
    @State private var showingGallery = false
    @State private var showingSearch = false
    @State private var showingLucidTraining = false
    @State private var showingMeditation = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 聊天消息列表
                messageList
                
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
            .padding(.trailing, 4)
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
