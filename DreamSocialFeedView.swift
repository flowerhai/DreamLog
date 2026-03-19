//
//  DreamSocialFeedView.swift
//  DreamLog - Phase 70: 梦境社交分享增强
//
//  Created by DreamLog Team on 2026-03-19.
//  Phase 70: Social Feed - 梦境社交动态
//

import SwiftUI
import SwiftData

// MARK: - 社交动态主视图

/// 梦境社交动态 - 查看好友分享的梦境、点赞评论互动
struct DreamSocialFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var feedItems: [SocialFeedItem] = []
    @State private var isLoading = false
    @State private var selectedFilter: FeedFilter = .all
    @State private var showProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器
                filterBar
                
                Divider()
                
                // 动态列表
                if isLoading {
                    loadingView
                } else if feedItems.isEmpty {
                    emptyView
                } else {
                    feedList
                }
            }
            .navigationTitle("梦境动态")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                SocialProfileView()
            }
            .onAppear {
                loadFeed()
            }
            .refreshable {
                await refreshFeed()
            }
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FeedFilter.allCases) { filter in
                    FilterChip(
                        title: filter.displayName,
                        icon: filter.iconName,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        loadFeed()
                    }
                }
            }
            .padding()
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载中...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有动态")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("关注好友后，他们的梦境分享将显示在这里")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                // 查找好友
            } label: {
                Text("查找好友")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(feedItems) { item in
                    FeedItemCard(item: item)
                }
            }
            .padding()
        }
    }
    
    private func loadFeed() {
        isLoading = true
        
        // 模拟加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            feedItems = generateSampleFeedItems()
            isLoading = false
        }
    }
    
    private func refreshFeed() async {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        feedItems = generateSampleFeedItems()
        isLoading = false
    }
    
    private func generateSampleFeedItems() -> [SocialFeedItem] {
        [
            SocialFeedItem(
                id: UUID(),
                user: SocialUser(name: "小明", avatar: nil),
                dreamTitle: "飞翔在星空之中",
                dreamPreview: "我梦见自己在无边无际的星空中自由飞翔，周围是闪烁的星星和遥远的星系...",
                dreamImage: nil,
                template: "starry",
                likeCount: 24,
                commentCount: 5,
                shareCount: 3,
                timestamp: Date().addingTimeInterval(-3600),
                isLiked: false,
                isBookmarked: false
            ),
            SocialFeedItem(
                id: UUID(),
                user: SocialUser(name: "小红", avatar: nil),
                dreamTitle: "海底探险",
                dreamPreview: "梦境中我变成了潜水员，探索神秘的海底世界，看到了五彩斑斓的珊瑚和奇异的海洋生物...",
                dreamImage: nil,
                template: "ocean",
                likeCount: 18,
                commentCount: 8,
                shareCount: 2,
                timestamp: Date().addingTimeInterval(-7200),
                isLiked: true,
                isBookmarked: true
            ),
            SocialFeedItem(
                id: UUID(),
                user: SocialUser(name: "阿强", avatar: nil),
                dreamTitle: "回到童年",
                dreamPreview: "梦见回到了小时候的家，院子里的老槐树还在，奶奶在厨房里忙碌...",
                dreamImage: nil,
                template: "vintage",
                likeCount: 42,
                commentCount: 12,
                shareCount: 7,
                timestamp: Date().addingTimeInterval(-86400),
                isLiked: false,
                isBookmarked: false
            )
        ]
    }
}

// MARK: - 筛选器枚举

enum FeedFilter: String, Codable, CaseIterable, Identifiable {
    case all = "all"
    case following = "following"
    case popular = "popular"
    case recent = "recent"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .following: return "关注"
        case .popular: return "热门"
        case .recent: return "最新"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .following: return "person.2"
        case .popular: return "fire"
        case .recent: return "clock"
        }
    }
}

// MARK: - 社交动态项模型

struct SocialFeedItem: Identifiable {
    let id: UUID
    let user: SocialUser
    let dreamTitle: String
    let dreamPreview: String
    let dreamImage: Data?
    let template: String
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    let timestamp: Date
    var isLiked: Bool
    var isBookmarked: Bool
}

struct SocialUser: Identifiable {
    let id: UUID = UUID()
    let name: String
    let avatar: Data?
}

// MARK: - 动态卡片视图

struct FeedItemCard: View {
    let item: SocialFeedItem
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    
    init(item: SocialFeedItem) {
        self.item = item
        _isLiked = State(initialValue: item.isLiked)
        _isBookmarked = State(initialValue: item.isBookmarked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 用户信息
            userHeader
            
            // 梦境内容
            dreamContent
            
            // 互动按钮
            interactionBar
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var userHeader: some View {
        HStack {
            // 头像
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.user.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(formatTimestamp(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 更多选项
            Button {
                // 显示更多选项
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var dreamContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            Text(item.dreamTitle)
                .font(.headline)
                .fontWeight(.bold)
            
            // 预览
            Text(item.dreamPreview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // 模板标签
            HStack {
                Image(systemName: "paintpalette")
                    .font(.caption)
                Text(templateName(for: item.template))
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var interactionBar: some View {
        HStack(spacing: 20) {
            // 点赞
            Button {
                isLiked.toggle()
                if isLiked {
                    item.likeCount += 1
                } else {
                    item.likeCount -= 1
                }
            } label: {
                HStack {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .primary)
                    Text("\(item.likeCount)")
                        .foregroundColor(.secondary)
                }
            }
            
            // 评论
            Button {
                // 打开评论
            } label: {
                HStack {
                    Image(systemName: "message")
                    Text("\(item.commentCount)")
                        .foregroundColor(.secondary)
                }
            }
            
            // 分享
            Button {
                // 分享
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("\(item.shareCount)")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 收藏
            Button {
                isBookmarked.toggle()
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundColor(isBookmarked ? .blue : .secondary)
            }
        }
        .font(.subheadline)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) 分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) 小时前"
        } else {
            let days = Int(interval / 86400)
            return "\(days) 天前"
        }
    }
    
    private func templateName(for templateId: String) -> String {
        ShareCardTemplateLibrary.template(id: templateId)?.name ?? templateId
    }
}

// MARK: - 个人主页视图

struct SocialProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 个人信息
                    profileHeader
                    
                    // 统计
                    statsSection
                    
                    // 我的分享
                    mySharesSection
                }
                .padding()
            }
            .navigationTitle("我的主页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // 头像
            Circle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                )
            
            // 用户名
            Text("我的 DreamLog")
                .font(.title)
                .fontWeight(.bold)
            
            // 简介
            Text("记录每一个奇妙的梦境")
                .foregroundColor(.secondary)
            
            // 编辑资料按钮
            Button {
                // 编辑资料
            } label: {
                Text("编辑资料")
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 40) {
            StatItem(value: "128", label: "分享")
            StatItem(value: "256", label: "点赞")
            StatItem(value: "42", label: "关注")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var mySharesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的分享")
                .font(.headline)
            
            ForEach(0..<5) { _ in
                MiniShareCard()
            }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MiniShareCard: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray4))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("梦境标题")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("2 小时前")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 评论视图

struct DreamCommentsView: View {
    @Environment(\.dismiss) private var dismiss
    let dreamId: UUID
    
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 评论列表
                commentList
                
                Divider()
                
                // 输入框
                commentInput
            }
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var commentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            }
            .padding()
        }
    }
    
    private var commentInput: some View {
        HStack(spacing: 12) {
            TextField("写下你的评论...", text: $newComment)
                .textFieldStyle(.roundedBorder)
            
            Button {
                postComment()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
            }
            .disabled(newComment.isEmpty)
        }
        .padding()
    }
    
    private func postComment() {
        // 发表评论
        newComment = ""
    }
}

struct Comment: Identifiable {
    let id: UUID
    let user: SocialUser
    let content: String
    let timestamp: Date
    let likeCount: Int
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(formatTimestamp(comment.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.subheadline)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "heart")
                    .font(.caption)
                Text("\(comment.likeCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) 分"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) 时"
        } else {
            let days = Int(interval / 86400)
            return "\(days) 天"
        }
    }
}

// MARK: - 关注列表视图

struct FollowingListView: View {
    @State private var following: [SocialUser] = []
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // 搜索框
                searchField
                
                // 关注列表
                followingList
            }
            .navigationTitle("关注")
        }
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索用户", text: $searchText)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    private var followingList: some View {
        List {
            ForEach(following) { user in
                UserRow(user: user)
            }
        }
    }
}

struct UserRow: View {
    let user: SocialUser
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("32 个分享")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                // 取消关注
            } label: {
                Text("已关注")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 发现页面视图

struct DiscoverView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 热门话题
                    hotTopicsSection
                    
                    // 推荐用户
                    recommendedUsersSection
                    
                    // 精选梦境
                    featuredDreamsSection
                }
                .padding()
            }
            .navigationTitle("发现")
        }
    }
    
    private var hotTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门话题")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["#清醒梦", "#飞行梦", "#童年回忆", "#未来预言", "#奇幻冒险"], id: \.self) { topic in
                        TopicChip(topic: topic)
                    }
                }
            }
        }
    }
    
    private var recommendedUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推荐用户")
                .font(.headline)
            
            ForEach(0..<3) { _ in
                SuggestedUserRow()
            }
        }
    }
    
    private var featuredDreamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("精选梦境")
                .font(.headline)
            
            ForEach(0..<5) { _ in
                FeaturedDreamCard()
            }
        }
    }
}

struct TopicChip: View {
    let topic: String
    
    var body: some View {
        Text(topic)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(20)
    }
}

struct SuggestedUserRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("梦境达人")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("分享了 128 个梦境")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                // 关注
            } label: {
                Text("关注")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct FeaturedDreamCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray4))
                .aspectRatio(16/9, contentMode: .fill)
            
            Text("精彩的梦境标题")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Label("256", systemImage: "heart")
                Label("42", systemImage: "message")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}
