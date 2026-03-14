//
//  DreamCommunityService.swift
//  DreamLog
//
//  Phase 42 - 梦境社区核心服务
//  匿名分享、浏览、点赞、评论、关注
//

import Foundation
import SwiftData
import Combine

// MARK: - 错误类型

enum DreamCommunityError: LocalizedError {
    case modelContainerNotInitialized
    case userNotFound
    case dreamNotFound
    case networkError
    case invalidOperation
    
    var errorDescription: String? {
        switch self {
        case .modelContainerNotInitialized:
            return "模型容器未初始化"
        case .userNotFound:
            return "用户不存在"
        case .dreamNotFound:
            return "梦境不存在"
        case .networkError:
            return "网络错误"
        case .invalidOperation:
            return "无效操作"
        }
    }
}

// MARK: - 社区服务

/// 梦境社区服务
@MainActor
class DreamCommunityService: ObservableObject {
    static let shared = DreamCommunityService()
    
    // MARK: - Published 状态
    
    @Published var currentUser: CommunityUser?
    @Published var sharedDreams: [SharedDream] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var stats: CommunityStats = CommunityStats()
    
    // MARK: - 配置
    
    private let anonymizationConfig: AnonymizationConfig = .default
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - SwiftData 容器
    
    @MainActor private static var _modelContainer: ModelContainer?
    @MainActor static var modelContainer: ModelContainer {
        get async {
            if _modelContainer == nil {
                do {
                    try await setupModelContainer()
                } catch {
                    fatalError("DreamCommunityService: SwiftData 容器初始化失败：\(error)")
                }
            }
            guard let container = _modelContainer else {
                fatalError("DreamCommunityService: 模型容器未初始化")
            }
            return container
        }
    }
    
    @MainActor private static func setupModelContainer() async throws {
        let schema = Schema([
            SharedDream.self,
            CommunityUser.self,
            CommunityComment.self,
            CommunityLike.self,
            CommunityFavorite.self,
            FollowRelationship.self,
            CommunityReport.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        _modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        print("🌐 DreamCommunityService: SwiftData 容器初始化完成")
    }
    
    private init() {
        Task {
            await Self.modelContainer
            await loadCurrentUser()
            await fetchSharedDreams(filter: .hot)
            await fetchStats()
        }
    }
    
    // MARK: - 用户管理
    
    /// 加载当前用户
    func loadCurrentUser() async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            // 尝试获取现有用户
            let descriptor = FetchDescriptor<CommunityUser>(
                predicate: #Predicate { $0.anonymousId == getCurrentAnonymousId() }
            )
            
            let users = try context.fetch(descriptor)
            
            if let existingUser = users.first {
                self.currentUser = existingUser
            } else {
                // 创建新用户
                let newUser = createNewUser()
                context.insert(newUser)
                try context.save()
                self.currentUser = newUser
            }
            
            print("✅ 当前用户加载完成：\(currentUser?.anonymousId ?? "unknown")")
        } catch {
            print("❌ 加载用户失败：\(error)")
            self.error = "加载用户失败：\(error.localizedDescription)"
        }
    }
    
    /// 创建新用户
    func createNewUser() -> CommunityUser {
        let anonymousId = generateAnonymousId()
        let avatarSeed = Int.random(in: 0..<1000)
        let avatarEmojis = ["🌙", "⭐", "🌟", "✨", "💫", "🌈", "🦋", "🌸", "🍀", "🔮"]
        let avatarEmoji = avatarEmojis[avatarSeed % avatarEmojis.count]
        
        return CommunityUser(
            anonymousId: anonymousId,
            avatarSeed: avatarSeed,
            avatarEmoji: avatarEmoji
        )
    }
    
    /// 获取当前用户匿名 ID
    private func getCurrentAnonymousId() -> String {
        // 使用设备标识符生成稳定的匿名 ID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        return "user_\(deviceId.prefix(12))"
    }
    
    // MARK: - 匿名化算法
    
    /// 匿名化梦境内容
    func anonymizeDream(_ dream: Dream) -> SharedDream {
        var content = dream.content
        
        // 1. 移除人名 (简单实现，实际应使用 NLP)
        if anonymizationConfig.removeNames {
            content = removeNames(from: content)
        }
        
        // 2. 模糊化地名
        if anonymizationConfig.removeLocations {
            content =模糊化 locations(in: content)
        }
        
        // 3. 移除具体日期
        if anonymizationConfig.removeDates {
            content = removeSpecificDates(from: content)
        }
        
        // 4. 移除具体数字
        if anonymizationConfig.removeSpecificNumbers {
            content = removeSpecificNumbers(from: content)
        }
        
        // 5. 泛化内容 (可选)
        if anonymizationConfig.generalizeContent {
            content = generalizeContent(content)
        }
        
        // 创建共享梦境
        return SharedDream(
            anonymousId: currentUser?.anonymousId ?? generateAnonymousId(),
            dreamId: dream.id,
            title: dream.title,
            content: content,
            emotions: dream.emotions.map { $0.rawValue },
            tags: dream.tags,
            dreamType: detectDreamType(from: dream),
            aiAnalysis: dream.aiAnalysis,
            moodScore: calculateMoodScore(from: dream.emotions),
            clarityScore: dream.clarityScore,
            isLucid: dream.isLucid,
            visibility: .public,
            allowComments: true,
            isAnonymous: true
        )
    }
    
    /// 移除人名
    private func removeNames(from text: String) -> String {
        // 简单实现：移除常见称呼
        var result = text
        let patterns = [
            #"我的\b\w+"#,
            #"\b[A-Z][a-z]+\b"#,  // 简单英文人名匹配
            #"朋友 | 同事 | 家人 | 老师 | 同学"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: range,
                    withTemplate: "某人"
                )
            }
        }
        
        return result
    }
    
    /// 模糊化地名
    private func模糊化 locations(in text: String) -> String {
        var result = text
        
        // 替换具体地名为泛化描述
        let locationPatterns = [
            ("北京", "某个城市"),
            ("上海", "某个城市"),
            ("纽约", "某个城市"),
            ("家", "一个地方"),
            ("学校", "某个场所"),
            ("公司", "某个场所"),
            ("公园", "户外场所"),
            ("海边", "水边"),
            ("山上", "高处")
        ]
        
        for (specific, general) in locationPatterns {
            result = result.replacingOccurrences(of: specific, with: general)
        }
        
        return result
    }
    
    /// 移除具体日期
    private func removeSpecificDates(from text: String) -> String {
        var result = text
        
        // 移除日期模式
        let datePatterns = [
            #"\d{4}年\d{1,2}月\d{1,2}日"#,
            #"\d{4}-\d{2}-\d{2}"#,
            #"\d{2}/\d{2}/\d{4}"#,
            #"昨天 | 今天 | 明天 | 前天 | 后天"#,
            #"上周 | 本周 | 下周 | 上个月 | 这个月 | 下个月"#
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: range,
                    withTemplate: "某天"
                )
            }
        }
        
        return result
    }
    
    /// 移除具体数字
    private func removeSpecificNumbers(from text: String) -> String {
        var result = text
        
        // 替换具体数字为模糊描述
        if let regex = try? NSRegularExpression(pattern: #"\d+"#) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                range: range,
                withTemplate: "一些"
            )
        }
        
        return result
    }
    
    /// 泛化内容
    private func generalizeContent(_ text: String) -> String {
        // 简单实现：移除过于具体的细节
        var result = text
        
        // 移除过长的描述
        let sentences = result.components(separatedBy: ".")
        if sentences.count > 10 {
            result = sentences.prefix(10).joined(separator: ".") + "..."
        }
        
        return result
    }
    
    /// 检测梦境类型
    private func detectDreamType(from dream: Dream) -> String? {
        let content = (dream.title + " " + dream.content).lowercased()
        
        if content.contains("飞") || content.contains("飞翔") { return "冒险" }
        if content.contains("魔法") || content.contains("神奇") { return "奇幻" }
        if content.contains("害怕") || content.contains("恐怖") { return "恐怖" }
        if content.contains("爱") || content.contains("喜欢") { return "浪漫" }
        if content.contains("考试") || content.contains("工作") { return "日常" }
        if content.contains("动物") || content.contains("自然") { return "自然" }
        
        return nil
    }
    
    /// 计算情绪评分
    private func calculateMoodScore(from emotions: [Emotion]) -> Double {
        guard !emotions.isEmpty else { return 0.0 }
        
        let positiveEmotions: Set<Emotion> = [.happy, .excited, .calm, .surprised]
        let negativeEmotions: Set<Emotion> = [.sad, .angry, .fearful, .disgusted, .anxious]
        
        var score: Double = 0.0
        
        for emotion in emotions {
            if positiveEmotions.contains(emotion) {
                score += 1.0
            } else if negativeEmotions.contains(emotion) {
                score -= 1.0
            }
        }
        
        return score / Double(emotions.count)
    }
    
    // MARK: - 分享梦境
    
    /// 分享梦境到社区
    func shareDream(_ dream: Dream, config: ShareConfig = .default) async -> SharedDream? {
        isLoading = true
        error = nil
        
        do {
            // 1. 匿名化处理
            let sharedDream = anonymizeDream(dream)
            
            // 2. 应用分享配置
            if !config.includeAIAnalysis {
                sharedDream.aiAnalysis = nil
            }
            
            sharedDream.visibility = config.visibility
            sharedDream.allowComments = config.allowComments
            
            // 3. 保存到 SwiftData
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            if let user = currentUser {
                sharedDream.author = user
                user.sharedDreams.append(sharedDream)
                user.incrementSharedCount()
            }
            
            context.insert(sharedDream)
            try context.save()
            
            // 4. 更新本地列表
            await fetchSharedDreams(filter: .new)
            
            isLoading = false
            print("✅ 梦境分享成功：\(sharedDream.id)")
            return sharedDream
            
        } catch {
            isLoading = false
            self.error = "分享失败：\(error.localizedDescription)"
            print("❌ 分享梦境失败：\(error)")
            return nil
        }
    }
    
    /// 删除分享的梦境
    func deleteSharedDream(_ sharedDream: SharedDream) async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            sharedDream.softDelete()
            try context.save()
            
            // 从本地列表移除
            sharedDreams.removeAll { $0.id == sharedDream.id }
            
            print("✅ 梦境删除成功：\(sharedDream.id)")
        } catch {
            self.error = "删除失败：\(error.localizedDescription)"
            print("❌ 删除梦境失败：\(error)")
        }
    }
    
    // MARK: - 浏览梦境
    
    /// 获取共享梦境列表
    func fetchSharedDreams(filter: CommunityFilter, limit: Int = 50) async {
        isLoading = true
        error = nil
        
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            var descriptor = FetchDescriptor<SharedDream>(
                predicate: #Predicate { $0.isDeleted == false && $0.visibility == .public },
                sortBy: []
            )
            
            // 根据筛选器排序
            switch filter {
            case .hot:
                descriptor.sortBy = [SortDescriptor(\.likeCount, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
            case .new:
                descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
            case .lucid:
                descriptor.predicate = #Predicate { $0.isDeleted == false && $0.visibility == .public && $0.isLucid == true }
                descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
            default:
                descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
            }
            
            descriptor.fetchLimit = limit
            
            let dreams = try context.fetch(descriptor)
            
            await MainActor.run {
                self.sharedDreams = dreams
                self.isLoading = false
            }
            
            print("✅ 获取梦境列表成功：\(dreams.count) 个")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.error = "加载失败：\(error.localizedDescription)"
            }
            print("❌ 获取梦境列表失败：\(error)")
        }
    }
    
    /// 搜索梦境
    func searchDreams(query: String) async -> [SharedDream] {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            let descriptor = FetchDescriptor<SharedDream>(
                predicate: #Predicate {
                    $0.isDeleted == false &&
                    $0.visibility == .public &&
                    ($0.title.contains(query) || $0.content.contains(query) || $0.tags.contains(query))
                },
                sortBy: [SortDescriptor(\.likeCount, order: .reverse)]
            )
            
            let results = try context.fetch(descriptor)
            return results
            
        } catch {
            print("❌ 搜索失败：\(error)")
            return []
        }
    }
    
    // MARK: - 互动功能
    
    /// 点赞梦境
    func likeDream(_ sharedDream: SharedDream) async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            if sharedDream.isLikedByCurrentUser {
                // 取消点赞
                sharedDream.decrementLikeCount()
                sharedDream.isLikedByCurrentUser = false
            } else {
                // 添加点赞
                sharedDream.incrementLikeCount()
                sharedDream.isLikedByCurrentUser = true
                
                // 创建点赞记录
                if let userId = currentUser?.id.uuidString {
                    let like = CommunityLike(
                        userId: userId,
                        targetType: .dream,
                        targetId: sharedDream.id
                    )
                    context.insert(like)
                }
                
                // 更新作者获赞数
                if let author = sharedDream.author {
                    author.incrementTotalLikes()
                }
            }
            
            try context.save()
            print("✅ 点赞操作成功")
            
        } catch {
            self.error = "操作失败：\(error.localizedDescription)"
            print("❌ 点赞失败：\(error)")
        }
    }
    
    /// 收藏梦境
    func favoriteDream(_ sharedDream: SharedDream) async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            if sharedDream.isFavoritedByCurrentUser {
                // 取消收藏
                sharedDream.isFavoritedByCurrentUser = false
                sharedDream.favoriteCount = max(0, sharedDream.favoriteCount - 1)
            } else {
                // 添加收藏
                sharedDream.isFavoritedByCurrentUser = true
                sharedDream.favoriteCount += 1
                
                // 创建收藏记录
                if let userId = currentUser?.id.uuidString {
                    let favorite = CommunityFavorite(
                        userId: userId,
                        sharedDreamId: sharedDream.id
                    )
                    context.insert(favorite)
                }
            }
            
            try context.save()
            print("✅ 收藏操作成功")
            
        } catch {
            self.error = "操作失败：\(error.localizedDescription)"
            print("❌ 收藏失败：\(error)")
        }
    }
    
    /// 关注用户
    func followUser(_ user: CommunityUser) async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            if user.isFollowedByCurrentUser {
                // 取消关注
                user.isFollowedByCurrentUser = false
                user.followerCount = max(0, user.followerCount - 1)
            } else {
                // 添加关注
                user.isFollowedByCurrentUser = true
                user.followerCount += 1
                
                // 创建关注关系
                if let followerId = currentUser?.id.uuidString {
                    let relationship = FollowRelationship(
                        followerId: followerId,
                        followingId: user.id.uuidString
                    )
                    context.insert(relationship)
                }
            }
            
            try context.save()
            print("✅ 关注操作成功")
            
        } catch {
            self.error = "操作失败：\(error.localizedDescription)"
            print("❌ 关注失败：\(error)")
        }
    }
    
    // MARK: - 评论功能
    
    /// 添加评论
    func addComment(to sharedDream: SharedDream, content: String, parentComment: CommunityComment? = nil) async -> CommunityComment? {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            let comment = CommunityComment(
                sharedDreamId: sharedDream.id,
                anonymousId: currentUser?.anonymousId ?? generateAnonymousId(),
                content: content,
                parentCommentId: parentComment?.id
            )
            
            if let user = currentUser {
                comment.author = user
            }
            
            sharedDream.comments.append(comment)
            sharedDream.commentCount += 1
            
            if let parent = parentComment {
                parent.replies.append(comment)
                parent.replyCount += 1
            }
            
            context.insert(comment)
            try context.save()
            
            print("✅ 评论添加成功")
            return comment
            
        } catch {
            self.error = "评论失败：\(error.localizedDescription)"
            print("❌ 评论失败：\(error)")
            return nil
        }
    }
    
    /// 删除评论
    func deleteComment(_ comment: CommunityComment) async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            comment.softDelete()
            try context.save()
            
            print("✅ 评论删除成功")
        } catch {
            self.error = "删除失败：\(error.localizedDescription)"
            print("❌ 删除评论失败：\(error)")
        }
    }
    
    /// 举报评论
    func reportComment(_ comment: CommunityComment, reason: ReportReason, description: String? = nil) async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            comment.report()
            
            // 创建举报记录
            if let reporterId = currentUser?.id.uuidString {
                let report = CommunityReport(
                    reporterId: reporterId,
                    targetType: .comment,
                    targetId: comment.id,
                    reason: reason,
                    description: description
                )
                context.insert(report)
            }
            
            try context.save()
            print("✅ 举报提交成功")
            
        } catch {
            self.error = "举报失败：\(error.localizedDescription)"
            print("❌ 举报失败：\(error)")
        }
    }
    
    // MARK: - 统计功能
    
    /// 获取社区统计
    func fetchStats() async {
        do {
            let container = await Self.modelContainer
            let context = ModelContext(container)
            
            // 获取总数
            let totalDreams = try context.fetch(FetchDescriptor<SharedDream>(
                predicate: #Predicate { $0.isDeleted == false && $0.visibility == .public }
            )).count
            
            let totalUsers = try context.fetch(FetchDescriptor<CommunityUser>()).count
            
            var stats = CommunityStats()
            stats.totalSharedDreams = totalDreams
            stats.totalUsers = totalUsers
            
            await MainActor.run {
                self.stats = stats
            }
            
            print("✅ 统计获取成功")
            
        } catch {
            print("❌ 获取统计失败：\(error)")
        }
    }
    
    // MARK: - 工具方法
    
    /// 生成匿名 ID
    private func generateAnonymousId() -> String {
        let adjectives = ["快乐", "安静", "神秘", "勇敢", "温柔", "自由", "梦幻", "奇妙"]
        let nouns = ["旅人", "探索者", "观察者", "追梦人", "夜行者", "星辰", "月光", "云朵"]
        
        let adjective = adjectives.randomElement() ?? "神秘"
        let noun = nouns.randomElement() ?? "旅人"
        let number = Int.random(in: 1000..<9999)
        
        return "\(adjective)\(noun)\(number)"
    }
}

// MARK: - Dream 扩展

extension Dream {
    var aiAnalysis: String? {
        // 如果 Dream 模型没有这个字段，可以返回 nil 或从其他字段生成
        return nil
    }
    
    var clarityScore: Double? {
        // 如果 Dream 模型没有这个字段，可以返回 nil 或从其他字段计算
        return nil
    }
}
