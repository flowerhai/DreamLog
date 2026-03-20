//
//  DreamCommunityView.swift
//  DreamLog
//
//  Phase 42 - 梦境社区界面
//  匿名分享、浏览、点赞、评论、关注
//

import SwiftUI
import SwiftData

// MARK: - 社区主界面

struct DreamCommunityView: View {
    @ObservedObject private var service = DreamCommunityService.shared
    @State private var selectedFilter: CommunityFilter = .hot
    @State private var showingShareSheet = false
    @State private var selectedDream: SharedDream?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选栏
                filterBar
                
                // 梦境列表
                communityFeed
                
                // 悬浮分享按钮
                floatingShareButton
            }
            .navigationTitle("🌐 梦境社区")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索梦境...")
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareDreamView()
        }
        .sheet(item: $selectedDream) { dream in
            SharedDreamDetailView(dream: dream)
        }
    }
    
    // MARK: - 筛选栏
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CommunityFilter.allCases, id: \.self) { filter in
                    DreamCommunityFilterChip(
                        title: filter.displayName,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 社区动态
    
    private var communityFeed: some View {
        Group {
            if service.isLoading {
                loadingView
            } else if service.sharedDreams.isEmpty {
                emptyStateView
            } else {
                dreamList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载梦境...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
                .opacity(0.5)
            
            Text("还没有人分享梦境")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("成为第一个分享梦境的人吧！")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingShareSheet = true }) {
                Label("分享梦境", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var dreamList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredDreams, id: \.id) { dream in
                    SharedDreamCard(dream: dream) {
                        selectedDream = dream
                    }
                }
            }
            .padding()
        }
    }
    
    private var filteredDreams: [SharedDream] {
        var dreams = service.sharedDreams
        
        // 搜索过滤
        if !searchText.isEmpty {
            dreams = dreams.filter { dream in
                dream.title.localizedCaseInsensitiveContains(searchText) ||
                dream.content.localizedCaseInsensitiveContains(searchText) ||
                dream.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return dreams
    }
    
    // MARK: - 悬浮按钮
    
    private var floatingShareButton: some View {
        ZStack {
            VStack { Spacer() }
            HStack {
                Spacer()
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - 筛选芯片

struct DreamCommunityFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.purple : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 梦境卡片

struct SharedDreamCard: View {
    let dream: SharedDream
    let onTap: () -> Void
    
    @State private var isLiked = false
    @State private var likeCount: Int
    
    init(dream: SharedDream, onTap: @escaping () -> Void) {
        self.dream = dream
        self.onTap = onTap
        _isLiked = State(initialValue: dream.isLikedByCurrentUser)
        _likeCount = State(initialValue: dream.likeCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部：作者信息
            authorHeader
            
            Divider()
            
            // 梦境内容
            dreamContent
            
            // 标签
            if !dream.tags.isEmpty {
                tagsRow
            }
            
            Divider()
            
            // 互动栏
            interactionBar
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onTapGesture(perform: onTap)
    }
    
    private var authorHeader: some View {
        HStack {
            // 匿名头像
            Text(dream.author?.avatarEmoji ?? "🌙")
                .font(.title2)
                .padding(8)
                .background(Color(.systemGray5))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("梦友 \(dream.anonymousId.prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text(formatDate(dream.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if dream.isLucid {
                        Label("清醒梦", systemImage: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            Spacer()
            
            // 可见性图标
            Image(systemName: dream.visibility.icon)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var dreamContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dream.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(dream.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(4)
        }
    }
    
    private var tagsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(dream.tags.prefix(5), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var interactionBar: some View {
        HStack(spacing: 20) {
            // 点赞
            Button(action: toggleLike) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                    Text("\(likeCount)")
                        .font(.caption)
                }
            }
            
            // 评论
            HStack(spacing: 4) {
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
                Text("\(dream.commentCount)")
                    .font(.caption)
            }
            
            // 收藏
            Button(action: toggleFavorite) {
                HStack(spacing: 4) {
                    Image(systemName: dream.isFavoritedByCurrentUser ? "star.fill" : "star")
                        .foregroundColor(dream.isFavoritedByCurrentUser ? .yellow : .gray)
                }
            }
            
            Spacer()
            
            // 分享
            Button(action: shareDream) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.green)
            }
        }
        .font(.subheadline)
    }
    
    // MARK: - Actions
    
    private func toggleLike() {
        withAnimation(.spring(response: 0.3)) {
            isLiked.toggle()
            likeCount += isLiked ? 1 : -1
        }
        Task {
            await service.toggleLike(dream: dream)
        }
    }
    
    private func toggleFavorite() {
        Task {
            await service.toggleFavorite(dream: dream)
        }
    }
    
    private func shareDream() {
        showingShareSheet = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 分享梦境界面

struct ShareDreamView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var service = DreamCommunityService.shared
    @ObservedObject private var dreamStore = DreamStore.shared
    @State private var selectedDream: Dream?
    @State private var title = ""
    @State private var allowAIAnalysis = true
    @State private var visibility: Visibility = .public
    @State private var allowComments = true
    @State private var isAnonymous = true
    @State private var isSharing = false
    @State private var showingDreamPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                // 选择梦境
                Section(header: Text("选择梦境")) {
                    if let dream = selectedDream {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(dream.title)
                                .font(.headline)
                            Text(dream.content.prefix(100))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    NavigationLink(destination: DreamCommunityPickerView(selectedDream: $selectedDream)) {
                        HStack {
                            Image(systemName: selectedDream != nil ? "checkmark.circle.fill" : "plus.circle")
                                .foregroundColor(selectedDream != nil ? .green : .purple)
                            Text(selectedDream != nil ? "已选择梦境" : "选择要分享的梦境")
                                .foregroundColor(selectedDream != nil ? .green : .purple)
                        }
                    }
                }
                
                // 隐私设置
                Section(header: Text("隐私设置")) {
                    Picker("可见性", selection: $visibility) {
                        ForEach(Visibility.allCases, id: \.self) { vis in
                            Text(vis.displayName).tag(vis)
                        }
                    }
                    
                    Picker("匿名设置", selection: $isAnonymous) {
                        Text("完全匿名").tag(true)
                        Text("显示昵称").tag(false)
                    }
                    
                    Toggle("允许评论", isOn: $allowComments)
                }
                
                // 内容选项
                Section(header: Text("内容选项")) {
                    Toggle("包含 AI 解析", isOn: $allowAIAnalysis)
                }
                
                // 分享按钮
                Section {
                    Button(action: shareToCommunity) {
                        HStack {
                            Spacer()
                            if isSharing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text("分享到社区")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                    }
                    .disabled(selectedDream == nil || isSharing)
                }
            }
            .navigationTitle("分享梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    // selectDream 不再需要，已改用 NavigationLink
    
    private func shareToCommunity() {
        guard let dream = selectedDream else { return }
        
        isSharing = true
        
        Task {
            do {
                try await service.shareDream(
                    dream: dream,
                    title: title,
                    visibility: visibility,
                    allowComments: allowComments,
                    isAnonymous: isAnonymous,
                    includeAIAnalysis: allowAIAnalysis
                )
                dismiss()
            } catch {
                print("分享失败：\(error)")
            }
            isSharing = false
        }
    }
}

// MARK: - 梦境详情界面

struct SharedDreamDetailView: View {
    let dream: SharedDream
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var comments: [CommunityComment] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 作者信息
                    authorSection
                    
                    // 梦境内容
                    contentSection
                    
                    // 标签
                    if !dream.tags.isEmpty {
                        tagsSection
                    }
                    
                    // AI 解析
                    if let aiAnalysis = dream.aiAnalysis {
                        aiAnalysisSection(aiAnalysis)
                    }
                    
                    // 评论区
                    commentsSection
                }
                .padding()
            }
            .navigationTitle("梦境详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private var authorSection: some View {
        HStack {
            Text(dream.author?.avatarEmoji ?? "🌙")
                .font(.title)
                .padding(8)
                .background(Color(.systemGray5))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("梦友 \(dream.anonymousId.prefix(10))")
                    .font(.headline)
                Text(formatDate(dream.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dream.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(dream.content)
                .font(.body)
                .lineSpacing(4)
        }
    }
    
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dream.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func aiAnalysisSection(_ analysis: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI 解析")
                    .font(.headline)
            }
            
            Text(analysis)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("评论")
                    .font(.headline)
                Spacer()
                Text("\(dream.commentCount) 条评论")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 评论输入框
            HStack {
                TextField("写下你的评论...", text: $commentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: postComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.purple)
                }
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            // 评论列表
            ForEach(comments, id: \.id) { comment in
                CommentRow(comment: comment)
            }
        }
    }
    
    private func postComment() {
        guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        Task {
            do {
                if let comment = await service.addComment(to: dream, content: commentText) {
                    comments.append(comment)
                    commentText = ""
                }
            } catch {
                print("发布评论失败：\(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 评论行

struct CommentRow: View {
    let comment: CommunityComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.author?.avatarEmoji ?? "🌙")
                    .font(.caption)
                Text("梦友 \(comment.author?.anonymousId.prefix(8) ?? "unknown")")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text(formatDate(comment.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.content)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 梦境选择器

struct DreamCommunityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    @Binding var selectedDream: Dream?
    @State private var searchText = ""
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreamStore.filteredDreams
        }
        return dreamStore.filteredDreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredDreams, id: \.id) { dream in
                Button(action: {
                    selectedDream = dream
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(dream.title)
                                .font(.headline)
                            Spacer()
                            if selectedDream?.id == dream.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text(dream.content.prefix(80))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack {
                            Label(dream.date, systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if dream.isLucid {
                                Label("清醒梦", systemImage: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("选择梦境")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "搜索梦境...")
    }
}

// MARK: - 预览

#Preview {
    DreamCommunityView()
}
