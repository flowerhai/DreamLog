//
//  DreamPublishModels.swift
//  DreamLog
//
//  Phase 47: Dream Newsletter & Auto-Publishing
//  梦境自动发布与通讯模型
//

import Foundation
import SwiftData

// MARK: - 发布平台枚举

/// 支持的发布平台
enum PublishPlatform: String, Codable, CaseIterable, Identifiable {
    case medium = "medium"
    case substack = "substack"
    case wordpress = "wordpress"
    case ghost = "ghost"
    case wechat = "wechat"
    case xiaohongshu = "xiaohongshu"
    case twitter = "twitter"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .medium: return "Medium"
        case .substack: return "Substack"
        case .wordpress: return "WordPress"
        case .ghost: return "Ghost"
        case .wechat: return "微信公众号"
        case .xiaohongshu: return "小红书"
        case .twitter: return "Twitter/X"
        case .custom: return "自定义平台"
        }
    }
    
    var icon: String {
        switch self {
        case .medium: return "m.circle"
        case .substack: return "text.alignleft"
        case .wordpress: return "w.circle"
        case .ghost: return "g.circle"
        case .wechat: return "message.fill"
        case .xiaohongshu: return "book.fill"
        case .twitter: return "x.circle"
        case .custom: return "globe"
        }
    }
    
    /// 是否需要 API Key
    var requiresAPIKey: Bool {
        switch self {
        case .medium, .wordpress, .ghost, .twitter: return true
        case .substack, .wechat, .xiaohongshu: return false // 这些通常需要手动发布
        case .custom: return false
        }
    }
    
    /// 是否支持自动发布
    var supportsAutoPublish: Bool {
        switch self {
        case .medium, .wordpress, .ghost, .twitter: return true
        case .substack, .wechat, .xiaohongshu: return false // 需要手动复制粘贴
        case .custom: return false
        }
    }
}

// MARK: - 发布模板

/// 发布模板数据模型
@Model
final class PublishTemplate {
    var id: UUID
    var name: String
    var platform: String
    var titleTemplate: String
    var contentTemplate: String
    var includeTags: Bool
    var includeEmotions: Bool
    var includeAIAnalysis: Bool
    var includeImages: Bool
    var hashtagStyle: String // "prefix", "suffix", "inline"
    var customFooter: String?
    var createdAt: Date
    var updatedAt: Date
    var isDefault: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        platform: String,
        titleTemplate: String,
        contentTemplate: String,
        includeTags: Bool = true,
        includeEmotions: Bool = true,
        includeAIAnalysis: Bool = false,
        includeImages: Bool = true,
        hashtagStyle: String = "suffix",
        customFooter: String? = nil,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.platform = platform
        self.titleTemplate = titleTemplate
        self.contentTemplate = contentTemplate
        self.includeTags = includeTags
        self.includeEmotions = includeEmotions
        self.includeAIAnalysis = includeAIAnalysis
        self.includeImages = includeImages
        self.hashtagStyle = hashtagStyle
        self.customFooter = customFooter
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDefault = isDefault
    }
    
    /// 预设模板
    static func presets() -> [PublishTemplate] {
        [
            // Medium 风格
            PublishTemplate(
                name: "Medium 风格",
                platform: PublishPlatform.medium.rawValue,
                titleTemplate: "{{title}}",
                contentTemplate: """
                {{content}}
                
                {{#if aiAnalysis}}
                ## AI 梦境解析
                
                {{aiAnalysis}}
                {{/if}}
                
                {{#if tags}}
                _Tags: {{tags}}_
                {{/if}}
                
                ---
                *Published from DreamLog*
                """,
                includeTags: true,
                includeEmotions: false,
                includeAIAnalysis: true,
                includeImages: true,
                hashtagStyle: "inline",
                isDefault: true
            ),
            
            // 微信公众号风格
            PublishTemplate(
                name: "微信公众号",
                platform: PublishPlatform.wechat.rawValue,
                titleTemplate: "【梦境记录】{{title}}",
                contentTemplate: """
                🌙 {{content}}
                
                {{#if emotions}}
                💭 情绪：{{emotions}}
                {{/if}}
                
                {{#if tags}}
                🏷️ 标签：{{tags}}
                {{/if}}
                
                {{#if aiAnalysis}}
                🧠 AI 解析：
                {{aiAnalysis}}
                {{/if}}
                
                ---
                来自 DreamLog 梦境日记
                """,
                includeTags: true,
                includeEmotions: true,
                includeAIAnalysis: true,
                includeImages: true,
                hashtagStyle: "suffix"
            ),
            
            // 小红书风格
            PublishTemplate(
                name: "小红书",
                platform: PublishPlatform.xiaohongshu.rawValue,
                titleTemplate: "{{title}} | 梦境记录🌙",
                contentTemplate: """
                {{content}}
                
                {{#if emotions}}
                情绪：{{emotions}}
                {{/if}}
                
                {{#if tags}}
                #{{tagsJoined}}
                {{/if}}
                
                #梦境 #DreamLog #潜意识 #梦境解析
                """,
                includeTags: true,
                includeEmotions: true,
                includeAIAnalysis: false,
                includeImages: true,
                hashtagStyle: "suffix"
            ),
            
            // Twitter/X 风格
            PublishTemplate(
                name: "Twitter/X",
                platform: PublishPlatform.twitter.rawValue,
                titleTemplate: "",
                contentTemplate: """
                {{contentTruncated}}
                
                {{#if tags}}
                #{{tagsFirst3}}
                {{/if}}
                
                via @DreamLog
                """,
                includeTags: true,
                includeEmotions: false,
                includeAIAnalysis: false,
                includeImages: true,
                hashtagStyle: "suffix"
            ),
            
            // 邮件通讯风格
            PublishTemplate(
                name: "邮件通讯",
                platform: "email",
                titleTemplate: "DreamLog Weekly - {{date}}",
                contentTemplate: """
                <html>
                <body>
                <h1>🌙 DreamLog Weekly</h1>
                <p>{{dateRange}}</p>
                
                {{#each dreams}}
                <article>
                <h2>{{title}}</h2>
                <p><em>{{date}}</em></p>
                <p>{{content}}</p>
                {{#if aiAnalysis}}
                <blockquote>{{aiAnalysis}}</blockquote>
                {{/if}}
                </article>
                <hr>
                {{/each}}
                
                <footer>
                <p>Generated by DreamLog</p>
                </footer>
                </body>
                </html>
                """,
                includeTags: false,
                includeEmotions: false,
                includeAIAnalysis: true,
                includeImages: true,
                hashtagStyle: "none"
            )
        ]
    }
}

// MARK: - 发布任务

/// 发布任务状态
enum PublishTaskStatus: String, Codable {
    case pending = "pending"       // 等待发布
    case processing = "processing" // 发布中
    case success = "success"       // 发布成功
    case failed = "failed"         // 发布失败
    case scheduled = "scheduled"   // 已计划
    case cancelled = "cancelled"   // 已取消
}

/// 发布任务数据模型
@Model
final class PublishTask {
    var id: UUID
    var title: String
    var content: String
    var platform: String
    var templateId: UUID?
    var dreamIds: [UUID]
    var scheduledAt: Date?
    var publishedAt: Date?
    var publishedURL: String?
    var status: String
    var errorMessage: String?
    var metadata: [String: String]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        platform: String,
        templateId: UUID? = nil,
        dreamIds: [UUID] = [],
        scheduledAt: Date? = nil,
        publishedURL: String? = nil,
        status: PublishTaskStatus = .pending,
        errorMessage: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.platform = platform
        self.templateId = templateId
        self.dreamIds = dreamIds
        self.scheduledAt = scheduledAt
        self.publishedAt = publishedURL != nil ? Date() : nil
        self.publishedURL = publishedURL
        self.status = status.rawValue
        self.errorMessage = errorMessage
        self.metadata = metadata
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var taskStatus: PublishTaskStatus {
        get { PublishTaskStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
}

// MARK: - 发布配置

/// 发布配置数据模型
@Model
final class PublishConfig {
    var id: UUID
    var platform: String
    var apiKey: String?
    var apiSecret: String?
    var endpoint: String?
    var blogId: String?
    var defaultTemplateId: UUID?
    var autoPublish: Bool
    var defaultHashtags: [String]
    var includeWatermark: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        platform: String,
        apiKey: String? = nil,
        apiSecret: String? = nil,
        endpoint: String? = nil,
        blogId: String? = nil,
        defaultTemplateId: UUID? = nil,
        autoPublish: Bool = false,
        defaultHashtags: [String] = [],
        includeWatermark: Bool = true
    ) {
        self.id = id
        self.platform = platform
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.endpoint = endpoint
        self.blogId = blogId
        self.defaultTemplateId = defaultTemplateId
        self.autoPublish = autoPublish
        self.defaultHashtags = defaultHashtags
        self.includeWatermark = includeWatermark
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 发布统计

/// 发布统计数据
struct PublishStats {
    var totalPublished: Int
    var byPlatform: [String: Int]
    var totalViews: Int
    var totalLikes: Int
    var totalShares: Int
    var mostPopularPlatform: String?
    var averageEngagement: Double
    
    static var empty: PublishStats {
        PublishStats(
            totalPublished: 0,
            byPlatform: [:],
            totalViews: 0,
            totalLikes: 0,
            totalShares: 0,
            mostPopularPlatform: nil,
            averageEngagement: 0
        )
    }
}

// MARK: - 发布预览

/// 发布预览数据
struct PublishPreview {
    var title: String
    var content: String
    var platform: String
    var characterCount: Int
    var estimatedReadTime: Int // 分钟
    var hashtags: [String]
    var imageCount: Int
    
    var formattedReadTime: String {
        if estimatedReadTime < 1 {
            return "< 1 min"
        } else {
            return "\(estimatedReadTime) min"
        }
    }
}
