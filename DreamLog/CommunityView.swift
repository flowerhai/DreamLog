//
//  CommunityView.swift
//  DreamLog
//
//  梦境社区：浏览、点赞、分享
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var communityService = CommunityService()
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedFilter: CommunityFilter = .hot
    @State private var searchText: String = ""
    @State private var showingPostSheet = false
    @State private var selectedPost: CommunityPost?
    @State private var showingShareSheet = false
    @State private var dreamToShare: Dream?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器
                filterBar
                
                // 帖子列表
                if communityService.isLoading {
                    loadingView
                } else if communityService.posts.isEmpty {
                    emptyView
                } else {
                    postList
                }
            }
            .navigationTitle("梦境社区")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPostSheet = true }) {
                        Label("发布", systemImage: "plus.circle.fill")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索梦境")
            .onChange(of: searchText) { _, newValue in
                Task {
                    await communityService.searchPosts(query: newValue)
                }
            }
            .task {
                await communityService.fetchPosts(filter: selectedFilter)
            }
            .sheet(isPresented: $showingPostSheet) {
                CommunityPostView(dreamStore: dreamStore, communityService: communityService)
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post, communityService: communityService)
            }
        }
    }
    
    // MARK: - 筛选栏
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CommunityFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.icon + " " + filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        Task {
                            await communityService.fetchPosts(filter: filter)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("正在加载梦境...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 空视图
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.moon")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            Text("还没有梦境分享")
                .font(.headline)
            Text("成为第一个分享梦境的人吧！")
                .foregroundColor(.secondary)
            Button(action: { showingPostSheet = true }) {
                Text("分享我的梦境")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 帖子列表
    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(communityService.posts) { post in
                    CommunityPostCard(
                        post: post,
                        onLike: {
                            Task {
                                await communityService.toggleLike(post: post)
                            }
                        },
                        onTap: {
                            selectedPost = post
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 筛选芯片
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - 社区帖子卡片
struct CommunityPostCard: View {
    @ObservedObject var post: CommunityPost
    let onLike: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                // 用户头像
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Text(String(post.authorName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(post.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 清醒梦标记
                if post.isLucid {
                    Label("清醒梦", systemImage: "sparkles")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.2))
                        )
                        .foregroundColor(.purple)
                }
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(post.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // 标签
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(post.tags.prefix(5), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                )
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            
            // AI 图片预览
            if let imageUrl = post.aiImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 150)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            Divider()
            
            // 互动栏
            HStack(spacing: 20) {
                // 点赞
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .secondary)
                        Text("\(post.likeCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 评论
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .foregroundColor(.secondary)
                    Text("\(post.commentCount)")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 分享
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 帖子详情视图
struct PostDetailView: View {
    @ObservedObject var post: CommunityPost
    @ObservedObject var communityService: CommunityService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 作者信息
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Text(String(post.authorName.prefix(1)))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.authorName)
                                .font(.headline)
                            
                            Text(post.createdAt.formatted(.dateTime.year().month().day().hour().minute()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if post.isLucid {
                            Label("清醒梦", systemImage: "sparkles")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.2))
                                )
                                .foregroundColor(.purple)
                        }
                    }
                    
                    // 内容
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(post.content)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    
                    // 情绪
                    if !post.emotions.isEmpty {
                        HStack {
                            Text("情绪：")
                                .foregroundColor(.secondary)
                            ForEach(post.emotions, id: \.self) { emotion in
                                Text(emotion.icon + emotion.rawValue)
                            }
                        }
                    }
                    
                    // 标签
                    if !post.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(post.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentColor.opacity(0.1))
                                    )
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    // AI 图片
                    if let imageUrl = post.aiImageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(16)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 300)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    
                    Divider()
                    
                    // 互动统计
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(post.likeCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("点赞")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(post.commentCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("评论")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(post.shareCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("分享")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("梦境详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await communityService.toggleLike(post: post)
                        }
                    }) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .primary)
                    }
                }
            }
        }
    }
}

#Preview {
    CommunityView(dreamStore: DreamStore())
}
