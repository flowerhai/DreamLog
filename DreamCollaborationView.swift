//
//  DreamCollaborationView.swift
//  DreamLog - 梦境协作解读主界面
//
//  Phase 67: 梦境协作解读板
//  创建时间：2026-03-18
//

import SwiftUI
import SwiftData

struct DreamCollaborationView: View {
    @EnvironmentObject var collaborationService: DreamCollaborationService
    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false
    @State private var showingJoinSheet = false
    @State private var selectedSession: DreamCollaborationSession?
    @State private var searchText = ""
    @State private var selectedFilter: CollaborationFilterOptions = CollaborationFilterOptions()
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if collaborationService.isLoading {
                    loadingView
                } else if collaborationService.currentSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("协作解读")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilterSheet.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingJoinSheet.toggle() }) {
                            Image(systemName: "person.badge.plus")
                        }
                        
                        Button(action: { showingCreateSheet.toggle() }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSessionView()
            }
            .sheet(isPresented: $showingJoinSheet) {
                JoinSessionView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(filter: $selectedFilter)
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .onAppear {
                Task {
                    collaborationService.setModelContext(modelContext)
                    await collaborationService.loadSessions()
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载协作会话...")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("还没有协作会话")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("创建或加入协作会话，\n与朋友一起解读梦境")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                Button(action: { showingCreateSheet.toggle() }) {
                    Label("创建会话", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: { showingJoinSheet.toggle() }) {
                    Label("加入会话", systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(Color.clear)
                        .foregroundColor(.purple)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple, lineWidth: 2)
                        )
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Session List View
    
    private var sessionListView: some View {
        let filteredSessions = filterSessions()
        
        List(filteredSessions) { session in
            SessionRowView(session: session)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSession = session
                }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "搜索会话")
    }
    
    // MARK: - Filter Helper
    
    private func filterSessions() -> [DreamCollaborationSession] {
        var sessions = collaborationService.currentSessions
        
        // 搜索筛选
        if !searchText.isEmpty {
            sessions = sessions.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 状态筛选
        if let status = selectedFilter.status {
            sessions = sessions.filter { $0.status == status }
        }
        
        // 可见性筛选
        if let visibility = selectedFilter.visibility {
            sessions = sessions.filter { $0.visibility == visibility }
        }
        
        // 只显示已加入的
        if selectedFilter.showOnlyJoined {
            sessions = sessions.filter { session in
                session.participants.contains { $0.userId == "current_user" }
            }
        }
        
        // 排序
        switch selectedFilter.sortBy {
        case .recent:
            sessions.sort { $0.updatedAt > $1.updatedAt }
        case .popular:
            sessions.sort { $0.voteCount > $1.voteCount }
        case .interpretations:
            sessions.sort { $0.interpretationCount > $1.interpretationCount }
        case .participants:
            sessions.sort { $0.participantCount > $1.participantCount }
        }
        
        return sessions
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: DreamCollaborationSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack {
                Text(session.visibility.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(session.status.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 邀请码
                Text("码：\(session.inviteCode)")
                    .font(.caption)
                    .monospaced()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // 描述
            Text(session.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // 统计信息
            HStack(spacing: 16) {
                Label("\(session.participantCount)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(session.interpretationCount)", systemImage: "lightbulb")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(session.voteCount)", systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let expires = session.expiresAt {
                    Text("剩余 \(daysRemaining(until: expires)) 天")
                        .font(.caption)
                        .foregroundColor(expires < Date().addingTimeInterval(86400 * 2) ? .orange : .secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func daysRemaining(until date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
}

// MARK: - Create Session View

struct CreateSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var collaborationService: DreamCollaborationService
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var description = ""
    @State private var visibility: CollaborationVisibility = .friends
    @State private var maxParticipants = 10
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("会话标题", text: $title)
                    
                    TextField("会话描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("隐私设置")) {
                    Picker("可见性", selection: $visibility) {
                        ForEach(CollaborationVisibility.allCases, id: \.self) { vis in
                            Label("\(vis.icon) \(vis.rawValue)", systemImage: vis == .private ? "lock" : vis == .friends ? "person.2" : "globe")
                                .tag(vis)
                        }
                    }
                    
                    Stepper("最大参与者：\(maxParticipants)", value: $maxParticipants, in: 2...20)
                }
                
                Section(header: Text("说明")) {
                    Text("• 会话将在 7 天后自动过期")
                    Text("• 你可以随时结束或归档会话")
                    Text("• 参与者可以通过邀请码加入")
                }
            }
            .navigationTitle("创建协作会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { await createSession() }
                    }
                    .disabled(title.isEmpty || isCreating)
                }
            }
            .alert("创建失败", isPresented: $showError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createSession() async {
        isCreating = true
        defer { isCreating = false }
        
        do {
            // 这里需要一个 dreamId，实际使用中应该从梦境详情页面传入
            let dreamId = UUID()
            _ = try await collaborationService.createSession(
                dreamId: dreamId,
                title: title,
                description: description,
                visibility: visibility,
                maxParticipants: maxParticipants
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Join Session View

struct JoinSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var collaborationService: DreamCollaborationService
    
    @State private var inviteCode = ""
    @State private var isJoining = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("邀请码")) {
                    TextField("输入 6 位邀请码", text: $inviteCode)
                        .textCase(.uppercase)
                        .keyboardType(.alphabet)
                        .autocapitalization(.characters)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                }
                
                Section(header: Text("说明")) {
                    Text("• 向会话创建者索取邀请码")
                    Text("• 邀请码由 6 位字母和数字组成")
                    Text("• 会话过期或满员后无法加入")
                }
            }
            .navigationTitle("加入协作会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("加入") {
                        Task { await joinSession() }
                    }
                    .disabled(inviteCode.count != 6 || isJoining)
                }
            }
            .alert("加入失败", isPresented: $showError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func joinSession() async {
        isJoining = true
        defer { isJoining = false }
        
        // 这里需要实际的 sessionId，简化处理
        showError = true
        errorMessage = "请通过分享链接加入会话"
    }
}

// MARK: - Filter Sheet View

struct FilterSheetView: View {
    @Binding var filter: CollaborationFilterOptions
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("状态")) {
                    Picker("状态", selection: $filter.status) {
                        Text("全部").tag(nil as CollaborationSessionStatus?)
                        ForEach(CollaborationSessionStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status as CollaborationSessionStatus?)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("可见性")) {
                    Picker("可见性", selection: $filter.visibility) {
                        Text("全部").tag(nil as CollaborationVisibility?)
                        ForEach(CollaborationVisibility.allCases, id: \.self) { vis in
                            Text(vis.rawValue).tag(vis as CollaborationVisibility?)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("排序")) {
                    Picker("排序", selection: $filter.sortBy) {
                        ForEach(CollaborationFilterOptions.CollaborationSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                
                Section {
                    Toggle("只显示已加入", isOn: $filter.showOnlyJoined)
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var collaborationService: DreamCollaborationService
    @Environment(\.modelContext) private var modelContext
    
    let session: DreamCollaborationSession
    
    @State private var showingInterpretationSheet = false
    @State private var selectedInterpretation: DreamInterpretation?
    
    var body: some View {
        NavigationStack {
            List {
                // 会话信息
                Section(header: Text("会话信息")) {
                    Label(session.title, systemImage: session.visibility.icon)
                    Text(session.description)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("\(session.participantCount) 人", systemImage: "person.2")
                        Spacer()
                        Label("\(session.interpretationCount) 解读", systemImage: "lightbulb")
                        Spacer()
                        Label("\(session.voteCount) 投票", systemImage: "hand.thumbsup")
                    }
                    .font(.subheadline)
                }
                
                // 参与者
                Section(header: Text("参与者 (\(session.participantCount))")) {
                    ForEach(session.participants) { participant in
                        HStack {
                            Text(participant.role.icon)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(participant.username)
                                    .font(.headline)
                                Text(participant.role.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if participant.isOnline {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                
                // 解读列表
                Section(header: Text("解读 (\(session.interpretationCount))")) {
                    ForEach(session.interpretations.sorted { $0.createdAt > $1.createdAt }) { interpretation in
                        InterpretationRowView(interpretation: interpretation)
                            .onTapGesture {
                                selectedInterpretation = interpretation
                            }
                    }
                }
                
                // 操作
                Section {
                    if session.isValid {
                        Button(action: { showingInterpretationSheet.toggle() }) {
                            Label("添加解读", systemImage: "lightbulb.badge.plus")
                        }
                    }
                    
                    Button(role: .destructive) {
                        Task { try? await collaborationService.leaveSession(sessionId: session.id) }
                        dismiss()
                    } label: {
                        Label("离开会话", systemImage: "door.left.hand.open")
                    }
                }
            }
            .navigationTitle("协作详情")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingInterpretationSheet) {
                AddInterpretationView(session: session)
            }
            .sheet(item: $selectedInterpretation) { interpretation in
                InterpretationDetailView(interpretation: interpretation)
            }
        }
    }
}

// MARK: - Interpretation Row View

struct InterpretationRowView: View {
    let interpretation: DreamInterpretation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(interpretation.type.icon, systemImage: "")
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(interpretation.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(interpretation.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if interpretation.isAccepted {
                    Label("已采纳", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text(interpretation.content)
                .font(.subheadline)
                .lineLimit(3)
            
            HStack {
                Label("\(interpretation.voteCount)", systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !interpretation.comments.isEmpty {
                    Label("\(interpretation.comments.count)", systemImage: "bubble.left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Interpretation View

struct AddInterpretationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var collaborationService: DreamCollaborationService
    
    let session: DreamCollaborationSession
    
    @State private var content = ""
    @State private var type: InterpretationType = .symbolic
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("解读内容")) {
                    TextField("分享你的解读...", text: $content, axis: .vertical)
                        .lineLimit(5...15)
                }
                
                Section(header: Text("解读类型")) {
                    Picker("类型", selection: $type) {
                        ForEach(InterpretationType.allCases, id: \.self) { type in
                            Label("\(type.icon) \(type.rawValue)", systemImage: "")
                                .tag(type)
                        }
                    }
                }
            }
            .navigationTitle("添加解读")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        Task { await submitInterpretation() }
                    }
                    .disabled(content.isEmpty || isSubmitting)
                }
            }
        }
    }
    
    private func submitInterpretation() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            _ = try await collaborationService.addInterpretation(
                sessionId: session.id,
                dreamId: session.dreamId,
                content: content,
                type: type
            )
            dismiss()
        } catch {
            // 处理错误
        }
    }
}

// MARK: - Interpretation Detail View

struct InterpretationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var collaborationService: DreamCollaborationService
    
    let interpretation: DreamInterpretation
    
    @State private var commentText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 作者信息
                    HStack {
                        Text(interpretation.type.icon)
                            .font(.title)
                        
                        VStack(alignment: .leading) {
                            Text(interpretation.authorName)
                                .font(.headline)
                            Text(interpretation.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if interpretation.isAccepted {
                            Label("最佳解读", systemImage: "trophy.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Divider()
                    
                    // 解读内容
                    Text(interpretation.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    // 统计
                    HStack(spacing: 20) {
                        Label("\(interpretation.voteCount) 投票", systemImage: "hand.thumbsup")
                        Label("\(interpretation.comments.count) 评论", systemImage: "bubble.left")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // 评论列表
                    if !interpretation.comments.isEmpty {
                        Text("评论")
                            .font(.headline)
                        
                        ForEach(interpretation.comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.authorName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(comment.content)
                                    .font(.subheadline)
                            }
                            Divider()
                        }
                    }
                    
                    // 添加评论
                    HStack {
                        TextField("添加评论...", text: $commentText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("发送") {
                            Task { await addComment() }
                        }
                        .disabled(commentText.isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("解读详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { try? await collaborationService.voteInterpretation(interpretation) }
                    }) {
                        Image(systemName: "hand.thumbsup")
                    }
                }
            }
        }
    }
    
    private func addComment() async {
        // 实现评论添加
    }
}

// MARK: - Preview

#Preview {
    DreamCollaborationView()
        .environmentObject(DreamCollaborationService.shared)
}
