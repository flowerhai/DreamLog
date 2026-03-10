//
//  DreamShareCircleView.swift
//  DreamLog
//
//  梦境分享圈界面
//  Phase 17: 梦境分享圈功能
//

import SwiftUI

struct DreamShareCircleView: View {
    @StateObject private var service = DreamShareCircleService.shared
    @State private var showingCreateSheet = false
    @State private var showingInviteSheet = false
    @State private var showingSettingsSheet = false
    @State private var selectedCircleId: String?
    @State private var newCommentText: String = ""
    @State private var showingReactionPicker = false
    @State private var selectedDreamId: String?
    
    var body: some View {
        NavigationView {
            Group {
                if service.circles.isEmpty {
                    EmptyStateView()
                } else {
                    CircleListView
                }
            }
            .navigationTitle("分享圈")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateCircleSheet()
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteMemberSheet(circleId: selectedCircleId)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                CircleSettingsSheet(circleId: selectedCircleId)
            }
        }
    }
    
    // MARK: - 空状态视图
    
    @ViewBuilder
    private var EmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("创建你的第一个分享圈")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("与信任的朋友和家人分享你的梦境")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateSheet = true }) {
                Label("创建分享圈", systemImage: "plus")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding(40)
    }
    
    // MARK: - 分享圈列表
    
    @ViewBuilder
    private var CircleListView: some View {
        List {
            // 我的分享圈
            Section("我的分享圈") {
                ForEach(service.circles) { circle in
                    CircleRowView(circle: circle)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCircleId = circle.id
                            service.currentCircle = circle
                        }
                }
            }
            
            // 待处理邀请
            if !service.invitations.isEmpty {
                Section("待处理邀请") {
                    ForEach(service.invitations.filter { $0.status == .pending }) { invitation in
                        InvitationRowView(invitation: invitation)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - 分享圈行视图

struct CircleRowView: View {
    let circle: ShareCircle
    
    var body: some View {
        HStack(spacing: 12) {
            // 头像
            ZStack {
                Circle()
                    .fill(circle.type.color.gradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: circle.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(circle.name)
                        .font(.headline)
                    
                    if circle.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("\(circle.memberCount) 名成员 · \(circle.totalSharedDreams) 个梦境")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 邀请行视图

struct InvitationRowView: View {
    let invitation: CircleInvitation
    @StateObject private var service = DreamShareCircleService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(invitation.circleName)
                    .font(.headline)
                
                Spacer()
                
                Text("剩余 \(daysRemaining) 天")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Text("由 \(invitation.inviter.userName) 邀请")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let message = invitation.message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                Button("接受") {
                    Task {
                        try? await service.joinCircle(inviteCode: invitation.inviteCode)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("拒绝") {
                    // 处理拒绝逻辑
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var daysRemaining: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: invitation.expiresAt)
        return components.day ?? 0
    }
}

// MARK: - 创建分享圈表单

struct CreateCircleSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DreamShareCircleService.shared
    
    @State private var name: String = ""
    @State private var selectedType: ShareCircleType = .closeFriends
    @State private var description: String = ""
    @State private var isPrivate: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("分享圈名称", text: $name)
                    
                    Picker("类型", selection: $selectedType) {
                        ForEach(ShareCircleType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    TextField("描述（可选）", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("隐私设置") {
                    Toggle("私密分享圈", isOn: $isPrivate)
                    
                    if isPrivate {
                        Text("只有被邀请的成员才能加入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("任何人都可以搜索并申请加入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("创建分享圈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task {
                            try? await service.createCircle(
                                name: name,
                                type: selectedType,
                                description: description.isEmpty ? nil : description
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - 邀请成员表单

struct InviteMemberSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DreamShareCircleService.shared
    
    let circleId: String?
    @State private var email: String = ""
    @State private var message: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("邀请信息") {
                    TextField("邮箱地址", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("邀请留言（可选）", text: $message, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                if let circleId = circleId,
                   let circle = service.circles.first(where: { $0.id == circleId }) {
                    Section("分享圈信息") {
                        Label(circle.name, systemImage: circle.type.icon)
                        
                        Text("邀请码：`\(circle.inviteCode ?? "N/A")`")
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .navigationTitle("邀请成员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("发送邀请") {
                        Task {
                            try? await service.inviteMember(
                                circleId: circleId ?? "",
                                email: email,
                                message: message.isEmpty ? nil : message
                            )
                            dismiss()
                        }
                    }
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - 分享圈设置表单

struct CircleSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DreamShareCircleService.shared
    
    let circleId: String?
    @State private var settings: CircleSettings = .init()
    
    var body: some View {
        NavigationView {
            Form {
                Section("成员管理") {
                    Toggle("允许成员邀请", isOn: $settings.allowMemberInvites)
                    Toggle("需要审核新成员", isOn: $settings.requireApproval)
                }
                
                Section("互动设置") {
                    Toggle("允许评论", isOn: $settings.allowComments)
                    Toggle("允许表情回应", isOn: $settings.allowReactions)
                    Toggle("显示成员列表", isOn: $settings.showMemberList)
                }
                
                Section("梦境可见性") {
                    Picker("可见范围", selection: $settings.dreamVisibility) {
                        ForEach(CircleSettings.DreamVisibility.allCases, id: \.self) { visibility in
                            Text(visibility.displayName).tag(visibility)
                        }
                    }
                }
                
                Section("通知设置") {
                    Toggle("新梦境分享", isOn: $settings.notificationPreferences.newDreamShared)
                    Toggle("新评论", isOn: $settings.notificationPreferences.newComment)
                    Toggle("新成员加入", isOn: $settings.notificationPreferences.memberJoined)
                }
            }
            .navigationTitle("分享圈设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            try? await service.updateCircleSettings(
                                circleId: circleId ?? "",
                                settings: settings
                            )
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            if let circleId = circleId,
               let circle = service.circles.first(where: { $0.id == circleId }) {
                settings = circle.settings
            }
        }
    }
}

// MARK: - 梦境详情视图

struct SharedDreamDetailView: View {
    let sharedDream: SharedDream
    @StateObject private var service = DreamShareCircleService.shared
    @State private var newCommentText: String = ""
    @State private var showingReactionPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 梦境内容
                DreamContentCard(dream: sharedDream)
                
                // 表情回应
                ReactionBar(dream: sharedDream)
                
                // 评论区
                CommentSection(dream: sharedDream)
            }
            .padding()
        }
        .navigationTitle("梦境详情")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("选择表情", isPresented: $showingReactionPicker) {
            ForEach(DreamReaction.ReactionType.allCases, id: \.self) { type in
                Button("\(type.emoji) \(type.rawValue)") {
                    Task {
                        try? await service.addReaction(type, to: sharedDream.id)
                    }
                }
            }
        }
    }
}

// MARK: - 梦境内容卡片

struct DreamContentCard: View {
    let dream: SharedDream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text(dream.title)
                .font(.title2)
                .fontWeight(.bold)
            
            // 元信息
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text(dream.sharedBy.userName)
                        .font(.caption)
                }
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Text(dream.sharedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 梦境内容
            Text(dream.content)
                .font(.body)
                .lineSpacing(4)
            
            // 标签
            if !dream.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(dream.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                    }
                }
            }
            
            // 情绪和清醒梦标识
            HStack(spacing: 12) {
                if dream.isLucid {
                    Label("清醒梦", systemImage: "brain.head.profile")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
                
                Label("清晰度：\(dream.clarity)/5", systemImage: "star.fill")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 表情回应栏

struct ReactionBar: View {
    let dream: SharedDream
    @StateObject private var service = DreamShareCircleService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showingReactionPicker = true }) {
                Image(systemName: "face.smiling")
                    .font(.title3)
            }
            
            // 显示已有回应
            ForEach(uniqueReactions) { reaction in
                Text(reaction.emoji)
                    .font(.title3)
            }
            
            Spacer()
            
            Text("\(dream.reactionCount) 个回应")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var uniqueReactions: [DreamReaction.ReactionType] {
        Array(Set(dream.reactions.map { $0.type }))
    }
}

// MARK: - 评论区

struct CommentSection: View {
    let dream: SharedDream
    @StateObject private var service = DreamShareCircleService.shared
    @State private var newCommentText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("评论")
                .font(.headline)
            
            // 评论列表
            ForEach(dream.comments) { comment in
                CommentRow(comment: comment)
            }
            
            // 添加评论
            HStack {
                TextField("写下你的评论...", text: $newCommentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
                
                Button(action: addComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.purple)
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func addComment() {
        Task {
            try? await service.addComment(to: dream.id, content: newCommentText)
            newCommentText = ""
        }
    }
}

// MARK: - 评论行

struct CommentRow: View {
    let comment: DreamComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.author.userName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.content)
                .font(.body)
            
            if comment.reactions.count > 0 {
                HStack {
                    ForEach(Array(Set(comment.reactions.map { $0.type })), id: \.self) { type in
                        Text(type.emoji)
                            .font(.caption)
                    }
                    
                    Text("\(comment.reactions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 辅助扩展

extension ShareCircleType {
    var color: Color {
        switch self {
        case .closeFriends: return .pink
        case .family: return .orange
        case .dreamGroup: return .purple
        case .therapy: return .green
        case .custom: return .blue
        }
    }
}

extension CircleSettings.DreamVisibility {
    var displayName: String {
        switch self {
        case .all: return "全部梦境"
        case .recent7Days: return "最近 7 天"
        case .recent30Days: return "最近 30 天"
        case .none: return "不可见"
        }
    }
}

#Preview {
    DreamShareCircleView()
}
