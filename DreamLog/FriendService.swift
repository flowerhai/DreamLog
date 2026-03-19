//
//  FriendService.swift
//  DreamLog
//
//  好友服务：添加好友、管理好友列表、私密分享
//

import Foundation
import Combine

/// 好友模型
@MainActor
class Friend: Identifiable, ObservableObject {
    @Published var id: UUID
    @Published var userId: String
    @Published var username: String
    @Published var avatar: String?
    @Published var bio: String
    @Published var dreamCount: Int
    @Published var lucidDreamCount: Int
    @Published var streakDays: Int
    @Published var isFavorite: Bool
    @Published var addedAt: Date
    @Published var lastActiveAt: Date?
    
    init(
        id: UUID = UUID(),
        userId: String,
        username: String,
        avatar: String? = nil,
        bio: String = "",
        dreamCount: Int = 0,
        lucidDreamCount: Int = 0,
        streakDays: Int = 0,
        isFavorite: Bool = false,
        addedAt: Date = Date(),
        lastActiveAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.username = username
        self.avatar = avatar
        self.bio = bio
        self.dreamCount = dreamCount
        self.lucidDreamCount = lucidDreamCount
        self.streakDays = streakDays
        self.isFavorite = isFavorite
        self.addedAt = addedAt
        self.lastActiveAt = lastActiveAt
    }
}

/// 好友请求模型
@MainActor
class FriendRequest: Identifiable, ObservableObject {
    @Published var id: UUID
    @Published var fromUserId: String
    @Published var fromUsername: String
    @Published var fromAvatar: String?
    @Published var message: String
    @Published var createdAt: Date
    @Published var status: FriendRequestStatus
    
    init(
        id: UUID = UUID(),
        fromUserId: String,
        fromUsername: String,
        fromAvatar: String? = nil,
        message: String = "",
        createdAt: Date = Date(),
        status: FriendRequestStatus = .pending
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.fromAvatar = fromAvatar
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
}

/// 好友请求状态
enum FriendRequestStatus: String {
    case pending = "待处理"
    case accepted = "已接受"
    case declined = "已拒绝"
    case blocked = "已拉黑"
}

/// 梦境圈模型
class DreamCircle: Identifiable, ObservableObject {
    @Published var id: UUID
    @Published var name: String
    @Published var description: String
    @Published var members: [Friend]
    @Published var sharedDreams: [Dream]
    @Published var isPrivate: Bool
    @Published var createdAt: Date
    @Published var createdBy: String
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        members: [Friend] = [],
        sharedDreams: [Dream] = [],
        isPrivate: Bool = true,
        createdAt: Date = Date(),
        createdBy: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.members = members
        self.sharedDreams = sharedDreams
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
}

/// 好友评论模型
class FriendComment: Identifiable, ObservableObject {
    @Published var id: UUID
    @Published var dreamId: UUID
    @Published var userId: String
    @Published var username: String
    @Published var avatar: String?
    @Published var content: String
    @Published var reactions: [String: Int]  // emoji -> count
    @Published var createdAt: Date
    @Published var isEdited: Bool
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        userId: String,
        username: String,
        avatar: String? = nil,
        content: String,
        reactions: [String: Int] = [:],
        createdAt: Date = Date(),
        isEdited: Bool = false
    ) {
        self.id = id
        self.dreamId = dreamId
        self.userId = userId
        self.username = username
        self.avatar = avatar
        self.content = content
        self.reactions = reactions
        self.createdAt = createdAt
        self.isEdited = isEdited
    }
}

/// 好友服务类
@MainActor
class FriendService: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var dreamCircles: [DreamCircle] = []
    @Published var friendDreams: [SharedDream] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var currentUserId: String = ""
    @Published var currentUsername: String = ""
    
    private let apiKey: String = "demo_key"
    private let baseURL: String = "https://api.dreamlog.community"
    
    // 本地存储
    private var localFriends: [Friend] = []
    private var localRequests: [FriendRequest] = []
    private var localCircles: [DreamCircle] = []
    private var localFriendDreams: [SharedDream] = []
    
    init() {
        generateDemoData()
    }
    
    // MARK: - 生成演示数据
    private func generateDemoData() {
        // 演示好友
        let demoFriends = [
            Friend(
                userId: "user_001",
                username: "梦境探索者",
                bio: "热爱记录每一个奇妙的梦",
                dreamCount: 128,
                lucidDreamCount: 23,
                streakDays: 45,
                isFavorite: true,
                lastActiveAt: Date().addingTimeInterval(-3600)
            ),
            Friend(
                userId: "user_002",
                username: "清醒梦大师",
                bio: "正在练习清醒梦技巧",
                dreamCount: 256,
                lucidDreamCount: 89,
                streakDays: 120,
                isFavorite: true,
                lastActiveAt: Date().addingTimeInterval(-7200)
            ),
            Friend(
                userId: "user_003",
                username: "星空旅人",
                bio: "梦见星辰大海",
                dreamCount: 67,
                lucidDreamCount: 12,
                streakDays: 30,
                isFavorite: false,
                lastActiveAt: Date().addingTimeInterval(-86400)
            ),
            Friend(
                userId: "user_004",
                username: "潜意识侦探",
                bio: "分析梦境背后的秘密",
                dreamCount: 189,
                lucidDreamCount: 45,
                streakDays: 60,
                isFavorite: false,
                lastActiveAt: Date().addingTimeInterval(-1800)
            ),
            Friend(
                userId: "user_005",
                username: "月光诗人",
                bio: "把梦写成诗",
                dreamCount: 93,
                lucidDreamCount: 31,
                streakDays: 21,
                isFavorite: true,
                lastActiveAt: Date().addingTimeInterval(-43200)
            )
        ]
        
        self.localFriends = demoFriends
        self.friends = demoFriends
        
        // 演示好友请求
        let demoRequests = [
            FriendRequest(
                fromUserId: "user_006",
                fromUsername: "梦境新人",
                message: "你好！看到你的梦境分享很有趣，想和你交流",
                createdAt: Date().addingTimeInterval(-3600 * 2),
                status: .pending
            ),
            FriendRequest(
                fromUserId: "user_007",
                fromUsername: "解梦爱好者",
                message: "一起探讨梦境的奥秘吧",
                createdAt: Date().addingTimeInterval(-3600 * 5),
                status: .pending
            )
        ]
        
        self.localRequests = demoRequests
        self.pendingRequests = demoRequests
        
        // 演示梦境圈
        let demoCircles = [
            DreamCircle(
                name: "清醒梦修行群",
                description: "一起练习清醒梦技巧，分享成功经验",
                members: Array(demoFriends.prefix(3)),
                isPrivate: true,
                createdBy: currentUserId
            ),
            DreamCircle(
                name: "创意梦境分享",
                description: "分享最奇幻、最有创意的梦境",
                members: Array(demoFriends.dropFirst(2)),
                isPrivate: true,
                createdBy: currentUserId
            )
        ]
        
        self.localCircles = demoCircles
        self.dreamCircles = demoCircles
        
        // 演示好友梦境
        generateDemoFriendDreams()
    }
    
    private func generateDemoFriendDreams() {
        let demoSharedDreams = [
            SharedDream(
                dreamId: UUID(),
                friendId: "user_001",
                friendName: "梦境探索者",
                title: "在彩虹上行走",
                content: "梦见脚下的云变成了彩虹，我小心翼翼地走在上面，每一种颜色都有不同的触感。红色温暖，蓝色清凉，绿色柔软...",
                tags: ["彩虹", "奇幻", "色彩"],
                emotions: [.happy, .excited],
                isLucid: true,
                sharedAt: Date().addingTimeInterval(-3600 * 3),
                visibility: .friends,
                commentCount: 5,
                reactionCount: 12,
                userReaction: nil
            ),
            SharedDream(
                dreamId: UUID(),
                friendId: "user_002",
                friendName: "清醒梦大师",
                title: "控制梦境天气",
                content: "意识到自己在做梦后，我尝试控制天气。先是晴天，然后下雨，最后下雪。最神奇的是能感受到每种天气的温度和湿度。",
                tags: ["清醒梦", "控制", "天气"],
                emotions: [.excited, .surprised],
                isLucid: true,
                sharedAt: Date().addingTimeInterval(-3600 * 6),
                visibility: .circle,
                circleId: localCircles[0].id,
                commentCount: 8,
                reactionCount: 23,
                userReaction: "🔥"
            ),
            SharedDream(
                dreamId: UUID(),
                friendId: "user_003",
                friendName: "星空旅人",
                title: "与外星人对话",
                content: "梦见被邀请到外星飞船，他们用心灵感应和我交流。他们问人类为什么害怕未知，我说因为我们不了解。他们说：'了解从好奇开始，不是从恐惧。'",
                tags: ["外星", "哲学", "对话"],
                emotions: [.calm, .surprised],
                isLucid: false,
                sharedAt: Date().addingTimeInterval(-3600 * 24),
                visibility: .friends,
                commentCount: 15,
                reactionCount: 45,
                userReaction: "⭐"
            )
        ]
        
        self.localFriendDreams = demoSharedDreams
        self.friendDreams = demoSharedDreams
    }
    
    // MARK: - 搜索好友
    func searchFriends(query: String) async -> [Friend] {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // 模拟搜索结果
        let allUsers = [
            Friend(userId: "user_101", username: "梦境记录者", dreamCount: 45),
            Friend(userId: "user_102", username: "梦境艺术家", dreamCount: 78),
            Friend(userId: "user_103", username: "梦境分析师", dreamCount: 156),
            Friend(userId: "user_104", username: "梦境收藏家", dreamCount: 234)
        ]
        
        isLoading = false
        
        if query.isEmpty {
            return allUsers
        }
        
        return allUsers.filter {
            $0.username.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - 发送好友请求
    func sendFriendRequest(to userId: String, message: String = "") async -> Bool {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // 模拟发送请求
        let request = FriendRequest(
            fromUserId: currentUserId,
            fromUsername: currentUsername,
            message: message,
            status: .pending
        )
        
        isLoading = false
        return true
    }
    
    // MARK: - 处理好友请求
    func handleFriendRequest(_ request: FriendRequest, accept: Bool) async {
        request.status = accept ? .accepted : .declined
        
        if accept {
            let newFriend = Friend(
                userId: request.fromUserId,
                username: request.fromUsername,
                avatar: request.fromAvatar,
                addedAt: Date()
            )
            localFriends.append(newFriend)
            friends = localFriends
        }
        
        localRequests.removeAll { $0.id == request.id }
        pendingRequests = localRequests
    }
    
    // MARK: - 删除好友
    func removeFriend(_ friend: Friend) async {
        localFriends.removeAll { $0.id == friend.id }
        friends = localFriends
    }
    
    // MARK: - 设置特别关心
    func toggleFavorite(_ friend: Friend) async {
        friend.isFavorite.toggle()
        
        if let index = localFriends.firstIndex(where: { $0.id == friend.id }) {
            localFriends[index].isFavorite = friend.isFavorite
        }
    }
    
    // MARK: - 创建梦境圈
    func createCircle(name: String, description: String, members: [Friend]) async -> DreamCircle? {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let circle = DreamCircle(
            name: name,
            description: description,
            members: members,
            isPrivate: true,
            createdBy: currentUserId
        )
        
        localCircles.append(circle)
        dreamCircles = localCircles
        
        isLoading = false
        return circle
    }
    
    // MARK: - 分享到梦境圈
    func shareToCircle(_ dream: Dream, circle: DreamCircle) async -> Bool {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // 模拟分享
        if let index = localCircles.firstIndex(where: { $0.id == circle.id }) {
            localCircles[index].sharedDreams.append(dream)
        }
        
        isLoading = false
        return true
    }
    
    // MARK: - 获取好友梦境
    func fetchFriendDreams(filter: FriendDreamFilter = .all) async {
        isLoading = true
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        switch filter {
        case .all:
            friendDreams = localFriendDreams.sorted { $0.sharedAt > $1.sharedAt }
        case .favorite:
            friendDreams = localFriendDreams
                .filter { localFriends.first(where: { $0.userId == $0.friendId })?.isFavorite == true }
                .sorted { $0.sharedAt > $1.sharedAt }
        case .lucid:
            friendDreams = localFriendDreams
                .filter { $0.isLucid }
                .sorted { $0.sharedAt > $1.sharedAt }
        }
        
        isLoading = false
    }
    
    // MARK: - 发送评论
    func addComment(to dreamId: UUID, content: String) async -> FriendComment? {
        let comment = FriendComment(
            dreamId: dreamId,
            userId: currentUserId,
            username: currentUsername,
            content: content
        )
        
        // 更新评论数
        if let index = localFriendDreams.firstIndex(where: { $0.dreamId == dreamId }) {
            localFriendDreams[index].commentCount += 1
        }
        
        return comment
    }
    
    // MARK: - 发送表情回应
    func addReaction(to dreamId: UUID, emoji: String) async {
        if let index = localFriendDreams.firstIndex(where: { $0.dreamId == dreamId }) {
            localFriendDreams[index].userReaction = emoji
            localFriendDreams[index].reactionCount += 1
        }
    }
}

// MARK: - 共享梦境模型
class SharedDream: Identifiable, ObservableObject {
    @Published var dreamId: UUID
    @Published var friendId: String
    @Published var friendName: String
    @Published var friendAvatar: String?
    @Published var title: String
    @Published var content: String
    @Published var tags: [String]
    @Published var emotions: [Emotion]
    @Published var isLucid: Bool
    @Published var aiImageUrl: String?
    @Published var sharedAt: Date
    @Published var visibility: ShareVisibility
    @Published var circleId: UUID?
    @Published var circleName: String?
    @Published var commentCount: Int
    @Published var reactionCount: Int
    @Published var userReaction: String?
    
    init(
        dreamId: UUID,
        friendId: String,
        friendName: String,
        friendAvatar: String? = nil,
        title: String,
        content: String,
        tags: [String],
        emotions: [Emotion],
        isLucid: Bool,
        aiImageUrl: String? = nil,
        sharedAt: Date = Date(),
        visibility: ShareVisibility = .friends,
        circleId: UUID? = nil,
        circleName: String? = nil,
        commentCount: Int = 0,
        reactionCount: Int = 0,
        userReaction: String? = nil
    ) {
        self.dreamId = dreamId
        self.friendId = friendId
        self.friendName = friendName
        self.friendAvatar = friendAvatar
        self.title = title
        self.content = content
        self.tags = tags
        self.emotions = emotions
        self.isLucid = isLucid
        self.aiImageUrl = aiImageUrl
        self.sharedAt = sharedAt
        self.visibility = visibility
        self.circleId = circleId
        self.circleName = circleName
        self.commentCount = commentCount
        self.reactionCount = reactionCount
        self.userReaction = userReaction
    }
}

// MARK: - 分享可见性
enum ShareVisibility: String {
    case friends = "好友可见"
    case circle = "圈子可见"
    case publicShare = "公开分享"
}

// MARK: - 好友梦境筛选
enum FriendDreamFilter: String, CaseIterable {
    case all = "全部"
    case favorite = "特别关心"
    case lucid = "清醒梦"
    
    var icon: String {
        switch self {
        case .all: return "📋"
        case .favorite: return "⭐"
        case .lucid: return "🌙"
        }
    }
}
