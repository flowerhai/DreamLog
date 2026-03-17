//
//  CommunityService.swift
//  DreamLog
//
//  梦境社区服务：匿名分享、浏览、点赞
//

import Foundation
import Combine

/// 梦境社区帖子
class CommunityPost: Identifiable, ObservableObject {
    @Published var id: UUID
    @Published var dreamId: UUID
    @Published var title: String
    @Published var content: String
    @Published var tags: [String]
    @Published var emotions: [Emotion]
    @Published var isLucid: Bool
    @Published var authorName: String  // 匿名用户名
    @Published var likeCount: Int
    @Published var commentCount: Int
    @Published var shareCount: Int
    @Published var createdAt: Date
    @Published var isLiked: Bool  // 当前用户是否点赞
    @Published var aiImageUrl: String?
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        title: String,
        content: String,
        tags: [String],
        emotions: [Emotion],
        isLucid: Bool,
        authorName: String = "匿名用户",
        likeCount: Int = 0,
        commentCount: Int = 0,
        shareCount: Int = 0,
        createdAt: Date = Date(),
        isLiked: Bool = false,
        aiImageUrl: String? = nil
    ) {
        self.id = id
        self.dreamId = dreamId
        self.title = title
        self.content = content
        self.tags = tags
        self.emotions = emotions
        self.isLucid = isLucid
        self.authorName = authorName
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.aiImageUrl = aiImageUrl
    }
}

/// 社区服务类
@MainActor
class CommunityService: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var currentUser: String = ""
    
    private let apiKey: String = "demo_key"  // 实际使用时替换为真实 API
    private let baseURL: String = "https://api.dreamlog.community"  // 示例地址
    
    // 本地存储的帖子（演示用）
    private var localPosts: [CommunityPost] = []
    
    init() {
        generateDemoPosts()
    }
    
    // MARK: - 生成演示数据
    private func generateDemoPosts() {
        let demoPosts = [
            CommunityPost(
                dreamId: UUID(),
                title: "在云端飞翔",
                content: "我梦见自己突然飞了起来，穿过云层，阳光洒在身上，感觉无比自由。下方是连绵的山脉和蜿蜒的河流，整个世界都在我脚下。",
                tags: ["飞行", "自由", "云端"],
                emotions: [.excited, .happy],
                isLucid: true,
                authorName: "追梦人",
                likeCount: 128,
                commentCount: 23,
                createdAt: Date().addingTimeInterval(-3600 * 2),
                isLiked: false
            ),
            CommunityPost(
                dreamId: UUID(),
                title: "深海探险",
                content: "潜入深海，周围是发光的海洋生物。一条巨大的鲸鱼游过我身边，它的眼睛里有星辰大海。那一刻我感受到了生命的浩瀚。",
                tags: ["海洋", "鲸鱼", "星空"],
                emotions: [.calm, .surprised],
                isLucid: false,
                authorName: "深海鱼",
                likeCount: 256,
                commentCount: 45,
                createdAt: Date().addingTimeInterval(-3600 * 5),
                isLiked: true
            ),
            CommunityPost(
                dreamId: UUID(),
                title: "回到童年老屋",
                content: "梦见回到了小时候住过的老房子，院子里的桂花树还在开花。奶奶在厨房做饭，香味飘满整个院子。醒来后很怀念那段时光。",
                tags: ["童年", "家人", "怀念"],
                emotions: [.sad, .calm],
                isLucid: false,
                authorName: "时光旅人",
                likeCount: 342,
                commentCount: 67,
                createdAt: Date().addingTimeInterval(-3600 * 24),
                isLiked: false
            ),
            CommunityPost(
                dreamId: UUID(),
                title: "被追逐的噩梦",
                content: "有个黑影一直在追我，我拼命跑却跑不动。后来意识到这是梦，停下来面对它，黑影就消失了。原来恐惧来自内心。",
                tags: ["追逐", "恐惧", "清醒梦"],
                emotions: [.fearful, .anxious],
                isLucid: true,
                authorName: "勇者",
                likeCount: 189,
                commentCount: 34,
                createdAt: Date().addingTimeInterval(-3600 * 48),
                isLiked: false
            ),
            CommunityPost(
                dreamId: UUID(),
                title: "会说话的猫咪",
                content: "家里的猫咪突然开口说话，跟我讨论哲学问题。它说：'人类总是追逐意义，但存在本身就是意义。'醒来后思考了很久。",
                tags: ["动物", "哲学", "奇幻"],
                emotions: [.surprised, .confused],
                isLucid: false,
                authorName: "猫奴",
                likeCount: 421,
                commentCount: 89,
                createdAt: Date().addingTimeInterval(-3600 * 72),
                isLiked: true
            )
        ]
        
        self.localPosts = demoPosts
        self.posts = demoPosts
    }
    
    // MARK: - 获取社区帖子
    func fetchPosts(filter: CommunityFilter = .hot) async {
        isLoading = true
        error = nil
        
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        switch filter {
        case .hot:
            posts = localPosts.sorted { $0.likeCount > $1.likeCount }
        case .new:
            posts = localPosts.sorted { $0.createdAt > $1.createdAt }
        case .lucid:
            posts = localPosts.filter { $0.isLucid }.sorted { $0.likeCount > $1.likeCount }
        }
        
        isLoading = false
    }
    
    // MARK: - 发布梦境到社区
    func shareToCommunity(dream: Dream, anonymous: Bool) async -> Bool {
        isLoading = true
        
        // 模拟发布延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let newPost = CommunityPost(
            dreamId: dream.id,
            title: dream.title,
            content: dream.content,
            tags: dream.tags,
            emotions: dream.emotions,
            isLucid: dream.isLucid,
            authorName: anonymous ? "匿名用户" : currentUser.isEmpty ? "梦友" : currentUser,
            createdAt: Date(),
            aiImageUrl: dream.aiImageUrl
        )
        
        localPosts.insert(newPost, at: 0)
        posts.insert(newPost, at: 0)
        
        isLoading = false
        return true
    }
    
    // MARK: - 点赞/取消点赞
    func toggleLike(post: CommunityPost) async {
        post.isLiked.toggle()
        post.likeCount += post.isLiked ? 1 : -1
        
        // 模拟 API 调用
        try? await Task.sleep(nanoseconds: 200_000_000)
    }
    
    // MARK: - 搜索帖子
    func searchPosts(query: String) async {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        if query.isEmpty {
            posts = localPosts
        } else {
            posts = localPosts.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.content.localizedCaseInsensitiveContains(query) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        isLoading = false
    }
    
    // MARK: - 获取用户匿名名称
    func generateAnonymousName() -> String {
        let adjectives = ["神秘", "快乐", "勇敢", "安静", "自由", "梦幻", "奇妙", "温暖"]
        let nouns = ["追梦人", "旅人", "探索者", "观察者", "思想家", "艺术家", "守护者", "行者"]
        
        let adj = adjectives.randomElement() ?? "神秘"
        let noun = nouns.randomElement() ?? "旅人"
        
        return adj + noun
    }
}

// MARK: - 社区筛选
enum CommunityFilter: String, CaseIterable {
    case hot = "热门"
    case new = "最新"
    case lucid = "清醒梦"
    
    var icon: String {
        switch self {
        case .hot: return "🔥"
        case .new: return "✨"
        case .lucid: return "🌙"
        }
    }
}

// MARK: - 社区统计
struct CommunityStats {
    let totalPosts: Int
    let totalLikes: Int
    let yourPosts: Int
    let yourLikes: Int
}
