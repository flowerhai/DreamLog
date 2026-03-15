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
        originalReflection: DreamReflection? = nil
    ) {
        self.id = id
        self.reflectionId = reflectionId
        self.anonymousId = anonymousId
        self.type = type.rawValue
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
        self.modelContext = modelContext ?? (try? AppController.shared?.modelContext) ?? AppController.createPreviewContext()
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
            type: reflection.type,
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
        // 检查敏感词
        let sensitiveWords = ["敏感词 1", "敏感词 2"]  // TODO: 实现敏感词库
        for word in sensitiveWords {
            if content.contains(word) {
                throw ShareError.containsSensitiveContent
            }
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
        // TODO: 实现审核提交流程
        // 这里模拟审核通过
        sharedReflection.isApproved = true
        sharedReflection.status = .approved
        try modelContext.save()
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
