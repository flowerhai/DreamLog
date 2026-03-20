//
//  DreamARSocialView.swift
//  DreamLog
//
//  Created for Phase 40 - AR 社交功能
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import ARKit

// MARK: - AR 社交主视图

/// AR 社交功能主界面
struct DreamARSocialView: View {
    @StateObject private var service: DreamARSocialService
    @State private var showingCreateSession = false
    @State private var showingJoinSession = false
    @State private var inviteCode = ""
    @State private var selectedTemplate: ARSceneTemplate = .starryNight
    
    init(modelContainer: ModelContainer, userID: UUID, displayName: String) {
        _service = StateObject(wrappedValue: DreamARSocialService(
            modelContainer: modelContainer,
            userID: userID,
            displayName: displayName
        ))
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch service.sessionState {
                case .disconnected, .error:
                    sessionListView
                case .connecting:
                    connectingView
                case .hosting, .joined:
                    arSocialSpaceView
                }
            }
            .navigationTitle("AR 社交空间")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if service.sessionState == .disconnected || service.sessionState == .error {
                        Menu {
                            Button(action: { showingCreateSession = true }) {
                                Label("创建会话", systemImage: "plus")
                            }
                            Button(action: { showingJoinSession = true }) {
                                Label("加入会话", systemImage: "arrow.down.right.and.arrow.up.left")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    } else {
                        Button(action: { Task { await service.leaveSession() } }) {
                            Label("离开", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateSession) {
                CreateSessionView(service: service, selectedTemplate: $selectedTemplate)
            }
            .sheet(isPresented: $showingJoinSession) {
                JoinSessionView(service: service, inviteCode: $inviteCode)
            }
        }
    }
    
    // MARK: - Session List View
    
    private var sessionListView: some View {
        List {
            Section(header: Text("可用会话")) {
                if service.availableSessions.isEmpty {
                    Text("暂无可用会话")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(service.availableSessions) { session in
                        SessionRow(session: session)
                            .onTapGesture {
                                Task {
                                    try? await service.joinSession(withCode: session.sessionCode)
                                }
                            }
                    }
                }
            }
            
            Section(header: Text("快速操作")) {
                Button(action: { showingCreateSession = true }) {
                    Label("创建新会话", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                
                Button(action: { showingJoinSession = true }) {
                    Label("输入邀请码", systemImage: "arrow.down.right.and.arrow.up.left")
                        .foregroundColor(.green)
                }
            }
        }
        .onAppear {
            Task {
                try? await service.fetchAvailableSessions()
            }
        }
        .refreshable {
            try? await service.fetchAvailableSessions()
        }
    }
    
    // MARK: - Connecting View
    
    private var connectingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在连接...")
                .font(.headline)
            
            Text("请稍候")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - AR Social Space View
    
    private var arSocialSpaceView: some View {
        ZStack {
            ARSocialSpaceView(service: service)
            
            VStack {
                // 顶部参与者列表
                ParticipantBar(participants: service.participants)
                
                Spacer()
                
                // 底部控制栏
                ControlBar(service: service)
            }
            .padding()
        }
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: ARSession
    
    var body: some View {
        HStack {
            Image(systemName: session.sceneTemplate.icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sceneTemplate.displayName)
                    .font(.headline)
                
                Text("\(session.participantCount)/\(session.maxParticipants) 人")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(session.sessionCode)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Session View

struct CreateSessionView: View {
    @ObservedObject var service: DreamARSocialService
    @Binding var selectedTemplate: ARSceneTemplate
    @Environment(\.dismiss) var dismiss
    @State private var maxParticipants = 8
    @State private var isPublic = false
    @State private var durationMinutes = 60
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("场景模板")) {
                    Picker("模板", selection: $selectedTemplate) {
                        ForEach(ARSceneTemplate.allCases) { template in
                            Label(template.displayName, systemImage: template.icon)
                                .tag(template)
                        }
                    }
                    
                    Text(selectedTemplate.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("设置")) {
                    Stepper("人数上限：\(maxParticipants)", value: $maxParticipants, in: 2...12)
                    
                    Toggle("公开会话", isOn: $isPublic)
                    
                    Stepper("时长：\(durationMinutes) 分钟", value: $durationMinutes, in: 15...180, step: 15)
                }
                
                Section(header: Text("预览")) {
                    TemplatePreview(template: selectedTemplate)
                }
            }
            .navigationTitle("创建会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task {
                            isCreating = true
                            try? await service.createSession(
                                sceneTemplate: selectedTemplate,
                                maxParticipants: maxParticipants,
                                isPublic: isPublic,
                                durationMinutes: durationMinutes
                            )
                            isCreating = false
                            dismiss()
                        }
                    }
                    .disabled(isCreating)
                }
            }
        }
    }
}

// MARK: - Join Session View

struct JoinSessionView: View {
    @ObservedObject var service: DreamARSocialService
    @Binding var inviteCode: String
    @Environment(\.dismiss) var dismiss
    @State private var isJoining = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("邀请码")) {
                    TextField("6 位邀请码", text: $inviteCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .autocapitalization(.characters)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                
                Section {
                    Text("向朋友索取 6 位邀请码，然后输入加入他们的 AR 梦境空间。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("加入会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("加入") {
                        Task {
                            isJoining = true
                            errorMessage = nil
                            
                            do {
                                try await service.joinSession(withCode: inviteCode)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            
                            isJoining = false
                        }
                    }
                    .disabled(inviteCode.count != 6 || isJoining)
                }
            }
        }
    }
}

// MARK: - Template Preview

struct TemplatePreview: View {
    let template: ARSceneTemplate
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: template.icon)
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            Text(template.displayName)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(template.backgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Participant Bar

struct ParticipantBar: View {
    let participants: [ARParticipant]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(participants) { participant in
                    ParticipantAvatar(participant: participant)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
    }
}

// MARK: - Participant Avatar

struct ParticipantAvatar: View {
    let participant: ARParticipant
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(participant.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: participant.isHost ? 3 : 2)
                )
                .overlay(
                    Image(systemName: participant.isHost ? "crown.fill" : "person.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            Text(participant.displayName)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 60)
    }
}

// MARK: - Control Bar

struct ControlBar: View {
    @ObservedObject var service: DreamARSocialService
    @State private var showingMessages = false
    @State private var showingElementPicker = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { showingMessages = true }) {
                Image(systemName: "message.fill")
                    .font(.title2)
            }
            
            Button(action: { showingElementPicker = true }) {
                Image(systemName: "plus.app.fill")
                    .font(.title2)
            }
            
            Spacer()
            
            Button(action: { Task { await service.sendReaction("✨", at: nil) } }) {
                Text("✨")
                    .font(.title2)
            }
            
            Button(action: { Task { await service.sendReaction("❤️", at: nil) } }) {
                Text("❤️")
                    .font(.title2)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
        .sheet(isPresented: $showingMessages) {
            MessagePanelView(service: service)
        }
        .sheet(isPresented: $showingElementPicker) {
            ElementPickerView(service: service)
        }
    }
}

// MARK: - Message Panel View

struct MessagePanelView: View {
    @ObservedObject var service: DreamARSocialService
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List(service.messages) { message in
                    MessageRow(message: message)
                }
                
                Divider()
                
                HStack {
                    TextField("输入消息...", text: $messageText)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("消息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func sendMessage() {
        Task {
            await service.sendMessage(messageType: .text, content: messageText)
            messageText = ""
        }
    }
}

// MARK: - Message Row

struct MessageRow: View {
    let message: ARMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(message.senderName.prefix(1)))
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .font(.body)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Element Picker View

struct ElementPickerView: View {
    @ObservedObject var service: DreamARSocialService
    @Environment(\.dismiss) var dismiss
    @State private var selectedElement: ARElementType?
    
    var availableElements: [ARElementType] {
        service.currentSession?.sceneTemplate.availableElements ?? []
    }
    
    var body: some View {
        NavigationView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                ForEach(availableElements) { element in
                    ElementButton(element: element) {
                        selectedElement = element
                        // 元素将在 AR 视图中通过手势放置
                        // 实际放置逻辑在 DreamARSocialView 中处理
                        print("🎨 选择元素：\(element.displayName)")
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationTitle("选择元素")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Element Button

struct ElementButton: View {
    let element: ARElementType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: element.icon)
                    .font(.title)
                
                Text(element.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 80)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - AR Social Space View (ARKit Integration)

struct ARSocialSpaceView: View {
    @ObservedObject var service: DreamARSocialService
    @State private var showConfiguration = false
    
    var body: some View {
        ZStack {
            // AR 视图（需要 ARKit 集成）
            ARViewContainer(service: service)
                .ignoresSafeArea()
            
            // 配置提示
            if showConfiguration {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture { showConfiguration = false }
                
                VStack(spacing: 20) {
                    Image(systemName: "scan.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("移动设备以扫描环境")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("找到平面后可以放置梦境元素")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            showConfiguration = true
        }
    }
}

// MARK: - AR View Container

struct ARSocialViewContainer: UIViewRepresentable {
    @ObservedObject var service: DreamARSocialService
    
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.scene = SCNScene()
        view.autoenablesDefaultLighting = true
        view.automaticallyUpdatesLighting = true
        
        // 配置 AR
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        view.session.run(configuration)
        
        return view
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // 更新 AR 内容
    }
}

// MARK: - Preview

#Preview {
    DreamARSocialView(
        modelContainer: {
            do {
                return try ModelContainer(for: ARSession.self, ARParticipant.self, ARElement.self, ARMessage.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            } catch {
                fatalError("Preview setup failed: \(error)")
            }
        }(),
        userID: UUID(),
        displayName: "Test User"
    )
}
