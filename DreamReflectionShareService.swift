//
//  DreamReflectionShareService.swift
//  DreamLog
//
//  Phase 50: 反思分享服务
//  支持匿名分享到社区
//

import Foundation
import SwiftData

// MARK: - 分享模型

/// 分享的反思
@Model
final class SharedReflection {
    var id: UUID
    var reflectionId: UUID
    var anonymousId: String
    var type: String
    var content: String
    var tags: [String]
    var rating: Int
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    var isApproved: Bool
    var status: ShareStatus
    var createdAt: Date
    var updatedAt: Date
    var submittedAt: Date?
    var approvedAt: Date?
    
    @Relationship var originalReflection: DreamReflection?
    
    enum ShareStatus: String, CaseIterable, Codable {
        case pending = "待审核"
        case approved = "已通过"
        case rejected = "已拒绝"
        case deleted = "已删除"
        
        var displayName: String { rawValue }
    }
    
    init(
        id: UUID = UUID(),
        reflectionId: UUID,
        anonymousId: String,
        type: String,
        content: String,
        tags: [String] = [],
        rating: Int = 3,
        likeCount: Int = 0,
        commentCount: Int = 0,
        shareCount: Int = 0,
        isApproved: Bool = false,
        status: ShareStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        submittedAt: Date? = nil,
        approvedAt: Date? = nil,
        originalReflection: DreamReflection? = nil
    ) {
        self.id = id
        self.reflectionId = reflectionId
        self.anonymousId = anonymousId
        self.type = type
        self.content = content
        self.tags = tags
        self.rating = rating
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.isApproved = isApproved
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.submittedAt = submittedAt
        self.approvedAt = approvedAt
        self.originalReflection = originalReflection
    }
    
    var reflectionType: ReflectionType {
        ReflectionType(rawValue: type) ?? .insight
    }
    
    var displayDate: String {
        createdAt.formatted(.dateTime.year().month().day())
    }
}

// MARK: - 分享服务

/// 反思分享服务
@MainActor
class DreamReflectionShareService {
    
    static let shared = DreamReflectionShareService()
    
    private let modelContext: ModelContext
    private let userDefaults: UserDefaults
    
    private let anonymousIdKey = "reflection_anonymous_id"
    
    init(modelContext: ModelContext? = nil,
         userDefaults: UserDefaults = .standard) {
        if let context = modelContext {
            self.modelContext = context
        } else if let container = SharedModelContainer.main,
                  let context = try? ModelContext(container) {
            self.modelContext = context
        } else {
            // Fallback to in-memory context for previews/tests
            let container = try? ModelContainer(for: SharedReflection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            self.modelContext = ModelContext(container ?? try! ModelContainer(for: SharedReflection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        }
        self.userDefaults = userDefaults
    }
    
    // MARK: - 匿名 ID 管理
    
    /// 获取或创建匿名 ID
    var anonymousId: String {
        if let existing = userDefaults.string(forKey: anonymousIdKey) {
            return existing
        }
        
        let newId = "Dreamer_\(String(UUID().uuidString.prefix(8)))"
        userDefaults.set(newId, forKey: anonymousIdKey)
        return newId
    }
    
    // MARK: - 分享反思
    
    /// 分享反思到社区
    func shareReflection(_ reflection: DreamReflection) async throws -> SharedReflection {
        // 1. 内容审核
        try await validateContent(reflection.content)
        
        // 2. 匿名化处理
        let anonymizedContent = anonymizeContent(reflection.content)
        
        // 3. 创建分享记录
        let sharedReflection = SharedReflection(
            reflectionId: reflection.id,
            anonymousId: anonymousId,
            type: reflection.type.rawValue,
            content: anonymizedContent,
            tags: reflection.tags,
            rating: reflection.rating,
            status: .pending
        )
        
        modelContext.insert(sharedReflection)
        try modelContext.save()
        
        // 4. 提交审核
        try await submitForReview(sharedReflection)
        
        return sharedReflection
    }
    
    /// 内容验证
    private func validateContent(_ content: String) async throws {
        // 检查敏感词 (基础词库，实际应从服务器获取或使用更智能的 NLP 检测)
        let sensitiveWords = [
            // 政治敏感
            "敏感政治词汇",
            // 暴力内容
            "暴力", "杀戮", "血腥",
            // 色情内容
            "色情", "淫秽",
            // 广告 spam
            "加微信", "QQ 群", "点击链接", "http://", "https://"
        ]
        
        for word in sensitiveWords {
            if content.lowercased().contains(word.lowercased()) {
                throw ShareError.containsSensitiveContent
            }
        }
        
        // 检查 URL (防止外部链接)
        let urlPattern = #"https?://[^\s]+"#
        if content.range(of: urlPattern, options: .regularExpression) != nil {
            throw ShareError.containsSensitiveContent
        }
        
        // 检查最小长度
        if content.count < 10 {
            throw ShareError.contentTooShort
        }
        
        // 检查最大长度
        if content.count > 2000 {
            throw ShareError.contentTooLong
        }
    }
    
    /// 匿名化处理
    private func anonymizeContent(_ content: String) -> String {
        var anonymized = content
        
        // 移除人名 (简单实现，实际应使用 NLP)
        let namePatterns = ["[张三李四王五赵六]", "[小明小红]"]
        for pattern in namePatterns {
            anonymized = anonymized.replacingOccurrences(of: pattern, with: "某人")
        }
        
        // 移除具体地址
        let addressPatterns = ["[路街巷号]", "[省市县]"]
        for pattern in addressPatterns {
            anonymized = anonymized.replacingOccurrences(of: pattern, with: "某地")
        }
        
        // 移除联系方式
        let phonePattern = #"1[3-9]\d{9}"#
        anonymized = anonymized.replacingOccurrences(of: phonePattern, with: "电话号码", options: .regularExpression)
        
        return anonymized
    }
    
    /// 提交审核
    private func submitForReview(_ sharedReflection: SharedReflection) async throws {
        // 设置待审核状态
        sharedReflection.isApproved = false
        sharedReflection.status = .pending
        sharedReflection.submittedAt = Date()
        
        // 在真实场景中，这里会：
        // 1. 将分享提交到服务器审核队列
        // 2. 触发自动内容审核 (AI + 规则)
        // 3. 必要时转人工审核
        // 4. 审核结果通过推送通知返回
        
        // 模拟自动审核流程 (实际应调用服务器 API)
        let autoApproved = await autoModerationCheck(sharedReflection)
        
        if autoApproved {
            sharedReflection.isApproved = true
            sharedReflection.status = .approved
            sharedReflection.approvedAt = Date()
        }
        
        try modelContext.save()
        
        // 如果审核通过，触发通知
        if sharedReflection.isApproved {
            await notifyShareApproved(sharedReflection)
        }
    }
    
    /// 自动内容审核
    private func autoModerationCheck(_ sharedReflection: SharedReflection) async -> Bool {
        // 基础审核规则：
        // 1. 内容已通过敏感词检查 (在 validateContent 中完成)
        // 2. 匿名化处理已完成
        // 3. 长度符合要求
        // 实际应集成第三方内容审核 API (如阿里云内容安全、腾讯云内容安全)
        
        // 模拟审核延迟
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        
        // 默认通过 (因为已经过 validateContent 检查)
        return true
    }
    
    /// 通知分享已审核通过
    private func notifyShareApproved(_ sharedReflection: SharedReflection) async {
        // 在真实场景中，这里会发送本地通知或推送
        // 使用 UserNotifications 框架
        print("📢 分享已审核通过：\(sharedReflection.id)")
    }
    
    // MARK: - 获取分享的反思
    
    /// 获取已分享的反思列表
    func getSharedReflections(limit: Int = 20,
                              offset: Int = 0,
                              type: ReflectionType? = nil,
                              sortBy: SortBy = .latest) async throws -> [SharedReflection] {
        var descriptor = FetchDescriptor<SharedReflection>(
            predicate: #Predicate<SharedReflection> { $0.isApproved && $0.status == .approved },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        
        let results = try modelContext.fetch(descriptor)
        return results
    }
    
    /// 获取用户自己的分享
    func getMySharedReflections() async throws -> [SharedReflection] {
        let descriptor = FetchDescriptor<SharedReflection>(
            predicate: #Predicate<SharedReflection> { $0.anonymousId == anonymousId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 互动功能
    
    /// 点赞
    func likeReflection(_ sharedReflection: SharedReflection) async throws {
        sharedReflection.likeCount += 1
        try modelContext.save()
    }
    
    /// 取消点赞
    func unlikeReflection(_ sharedReflection: SharedReflection) async throws {
        sharedReflection.likeCount = max(0, sharedReflection.likeCount - 1)
        try modelContext.save()
    }
    
    /// 增加分享次数
    func incrementShareCount(_ sharedReflection: SharedReflection) async throws {
        sharedReflection.shareCount += 1
        try modelContext.save()
    }
    
    // MARK: - 删除分享
    
    /// 删除分享
    func deleteShare(_ sharedReflection: SharedReflection) async throws {
        sharedReflection.status = .deleted
        try modelContext.save()
    }
    
    // MARK: - 统计
    
    /// 获取分享统计
    func getShareStats() async throws -> ReflectionShareStats {
        let descriptor = FetchDescriptor<SharedReflection>(
            predicate: #Predicate<SharedReflection> { $0.anonymousId == anonymousId }
        )
        
        let myShares = try modelContext.fetch(descriptor)
        
        return ReflectionShareStats(
            totalShares: myShares.count,
            totalLikes: myShares.reduce(0) { $0 + $1.likeCount },
            totalComments: myShares.reduce(0) { $0 + $1.commentCount },
            approvedCount: myShares.filter { $0.status == .approved }.count
        )
    }
}

// MARK: - 统计模型

/// 分享统计
struct ReflectionShareStats {
    var totalShares: Int
    var totalLikes: Int
    var totalComments: Int
    var approvedCount: Int
}

// MARK: - 错误类型

enum ShareError: LocalizedError {
    case containsSensitiveContent
    case contentTooShort
    case contentTooLong
    case shareFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .containsSensitiveContent:
            return "内容包含敏感信息，请修改后重试"
        case .contentTooShort:
            return "内容太短，请至少输入 10 个字"
        case .contentTooLong:
            return "内容太长，请控制在 2000 字以内"
        case .shareFailed:
            return "分享失败，请重试"
        case .networkError:
            return "网络错误，请检查网络连接"
        }
    }
}

// MARK: - 排序方式

enum SortBy {
    case latest
    case popular
    case mostLiked
    
    var sortDescriptor: SortDescriptor<SharedReflection> {
        switch self {
        case .latest:
            return SortDescriptor(\.createdAt, order: .reverse)
        case .popular:
            return SortDescriptor(\.likeCount, order: .reverse)
        case .mostLiked:
            return SortDescriptor(\.likeCount, order: .reverse)
        }
    }
}
