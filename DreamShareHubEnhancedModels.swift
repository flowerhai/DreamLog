//
//  DreamShareHubEnhancedModels.swift
//  DreamLog
//
//  Phase 82 - 梦境分享中心增强
//  数据模型层
//

import Foundation
import SwiftData

// MARK: - 分享平台枚举

/// 支持的分享平台
enum SharePlatform: String, CaseIterable, Codable, Identifiable {
    // 国内平台
    case wechat = "wechat"              // 微信
    case wechatMoments = "wechat_moments" // 微信朋友圈
    case weibo = "weibo"                // 微博
    case xiaohongshu = "xiaohongshu"    // 小红书
    case qq = "qq"                      // QQ
    case qzone = "qzone"                // QQ 空间
    case douban = "douban"              // 豆瓣
    case bilibili = "bilibili"          // B 站 (新增)
    case douyin = "douyin"              // 抖音 (新增)
    case zhihu = "zhihu"                // 知乎 (新增)
    
    // 国际平台
    case instagram = "instagram"
    case twitter = "twitter"
    case facebook = "facebook"
    case telegram = "telegram"          // (新增)
    case discord = "discord"            // (新增)
    case tiktok = "tiktok"              // TikTok (新增)
    case pinterest = "pinterest"
    case snapchat = "snapchat"
    case whatsapp = "whatsapp"
    case line = "line"
    case medium = "medium"
    case reddit = "reddit"
    
    var id: String { rawValue }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .wechat: return "微信"
        case .wechatMoments: return "朋友圈"
        case .weibo: return "微博"
        case .xiaohongshu: return "小红书"
        case .qq: return "QQ"
        case .qzone: return "QQ 空间"
        case .douban: return "豆瓣"
        case .bilibili: return "B 站"
        case .douyin: return "抖音"
        case .zhihu: return "知乎"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .facebook: return "Facebook"
        case .telegram: return "Telegram"
        case .discord: return "Discord"
        case .tiktok: return "TikTok"
        case .pinterest: return "Pinterest"
        case .snapchat: return "Snapchat"
        case .whatsapp: return "WhatsApp"
        case .line: return "LINE"
        case .medium: return "Medium"
        case .reddit: return "Reddit"
        }
    }
    
    /// 平台图标 (SF Symbol)
    var icon: String {
        switch self {
        case .wechat, .wechatMoments: return "message.fill"
        case .weibo: return "waveform"
        case .xiaohongshu: return "book.fill"
        case .qq, .qzone: return "bubble.left.fill"
        case .douban: return "film.fill"
        case .bilibili: return "tv.fill"
        case .douyin, .tiktok: return "music.note"
        case .zhihu: return "text.book.closed"
        case .instagram: return "camera.fill"
        case .twitter: return "message.badge.fill"
        case .facebook: return "person.2.fill"
        case .telegram: return "paperplane.fill"
        case .discord: return "gamecontroller.fill"
        case .pinterest: return "pin.fill"
        case .snapchat: return "ghost.fill"
        case .whatsapp: return "phone.fill"
        case .line: return "bubble.left.and.bubble.right.fill"
        case .medium: return "medium"
        case .reddit: return "bubble.left.fill"
        }
    }
    
    /// 平台主题色
    var accentColor: String {
        switch self {
        case .wechat, .wechatMoments: return "#07C160"
        case .weibo: return "#E6162D"
        case .xiaohongshu: return "#FF2442"
        case .qq, .qzone: return "#12B7F5"
        case .douban: return "#00B51D"
        case .bilibili: return "#00A1D6"
        case .douyin, .tiktok: return "#000000"
        case .zhihu: return "#0084FF"
        case .instagram: return "#C13584"
        case .twitter: return "#1DA1F2"
        case .facebook: return "#1877F2"
        case .telegram: return "#0088CC"
        case .discord: return "#5865F2"
        case .pinterest: return "#E60023"
        case .snapchat: return "#FFFC00"
        case .whatsapp: return "#25D366"
        case .line: return "#06C755"
        case .medium: return "#000000"
        case .reddit: return "#FF4500"
        }
    }
    
    /// 是否已安装 (通过 URL Scheme 检测)
    var isInstalled: Bool {
        let scheme: String? = {
            switch self {
            case .wechat: return "weixin://"
            case .wechatMoments: return "weixin://"
            case .weibo: return "sinaweibo://"
            case .xiaohongshu: return "xiaohongshu://"
            case .qq, .qzone: return "mqq://"
            case .douban: return "douban://"
            case .bilibili: return "bilibili://"
            case .douyin: return "snssdk1128://"
            case .zhihu: return "zhihu://"
            case .instagram: return "instagram://"
            case .twitter: return "twitter://"
            case .facebook: return "facebook://"
            case .telegram: return "telegram://"
            case .discord: return "discord://"
            case .tiktok: return "tiktok://"
            case .pinterest: return "pinterest://"
            case .snapchat: return "snapchat://"
            case .whatsapp: return "whatsapp://"
            case .line: return "line://"
            case .medium: return "medium://"
            case .reddit: return "reddit://"
            }
        }()
        
        guard let scheme = scheme, let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    /// 分享 URL 格式
    func shareURL(content: String, title: String, image: Data?) -> URL? {
        // 基础 URL 编码
        let encodedText = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        switch self {
        case .wechat, .wechatMoments:
            // 微信需要通过 SDK 分享，这里返回通用文本分享
            return URL(string: "weixin://")
        case .weibo:
            return URL(string: "sinaweibo://compose?text=\(encodedText)")
        case .twitter:
            return URL(string: "twitter://compose?message=\(encodedText)")
        case .telegram:
            return URL(string: "telegram://msg?text=\(encodedText)")
        case .whatsapp:
            return URL(string: "whatsapp://send?text=\(encodedText)")
        case .line:
            return URL(string: "line://msg?text=\(encodedText)")
        default:
            // 其他平台使用系统分享
            return nil
        }
    }
}

// MARK: - 分享链接模型

/// 可分享的梦境链接
@Model
final class DreamShareLink {
    var id: UUID
    var dreamId: UUID
    var shortCode: String
    var title: String
    var description: String?
    var expiresAt: Date?
    var password: String?
    var isPasswordProtected: Bool
    var viewCount: Int
    var clickCount: Int
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(dreamId: UUID, title: String, description: String? = nil, expiresAt: Date? = nil, password: String? = nil) {
        self.id = UUID()
        self.dreamId = dreamId
        self.shortCode = DreamShareLink.generateShortCode()
        self.title = title
        self.description = description
        self.expiresAt = expiresAt
        self.password = password
        self.isPasswordProtected = password != nil
        self.viewCount = 0
        self.clickCount = 0
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 生成 8 位短码
    private static func generateShortCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
    
    /// Universal Link URL
    var universalLink: URL? {
        URL(string: "https://dreamlog.app/d/\(shortCode)")
    }
    
    /// 备用下载链接
    var fallbackLink: URL? {
        URL(string: "https://apps.apple.com/app/dreamlog")
    }
    
    /// 是否已过期
    var isExpired: Bool {
        if let expiresAt = expiresAt {
            return Date() > expiresAt
        }
        return false
    }
    
    /// 剩余有效期 (天)
    var daysRemaining: Int? {
        guard let expiresAt = expiresAt else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day
        return max(0, days ?? 0)
    }
}

// MARK: - 分享统计模型

/// 分享统计数据
@Model
final class DreamShareStatistics {
    var id: UUID
    var date: Date
    var totalShares: Int
    var sharesByPlatform: [String: Int]  // platform rawValue: count
    var sharesByContentType: [String: Int]  // type: count
    var totalViews: Int
    var totalClicks: Int
    var topSharedDreamIds: [String]  // dream UUID strings
    
    init(date: Date = Date(), totalShares: Int = 0) {
        self.id = UUID()
        self.date = date
        self.totalShares = totalShares
        self.sharesByPlatform = [:]
        self.sharesByContentType = [:]
        self.totalViews = 0
        self.totalClicks = 0
        self.topSharedDreamIds = []
    }
    
    /// 添加平台分享计数
    func addShare(platform: SharePlatform) {
        sharesByPlatform[platform.rawValue, default: 0] += 1
        totalShares += 1
    }
    
    /// 添加内容类型分享计数
    func addShare(contentType: String) {
        sharesByContentType[contentType, default: 0] += 1
    }
}

// MARK: - 分享模板模型

/// 分享模板
@Model
final class DreamShareTemplate {
    var id: UUID
    var name: String
    var description: String?
    var category: TemplateCategory
    var platform: SharePlatform?
    var layout: TemplateLayout
    var backgroundColor: String
    var textColor: String
    var fontName: String
    var fontSize: Double
    var showLogo: Bool
    var showDate: Bool
    var showTags: Bool
    var showEmotions: Bool
    var customElements: [CustomTemplateElement]
    var isPreset: Bool
    var isFavorite: Bool
    var usageCount: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, description: String? = nil, category: TemplateCategory, platform: SharePlatform? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.platform = platform
        self.layout = .standard
        self.backgroundColor = "#FFFFFF"
        self.textColor = "#000000"
        self.fontName = "SF Pro Text"
        self.fontSize = 16.0
        self.showLogo = true
        self.showDate = true
        self.showTags = true
        self.showEmotions = true
        self.customElements = []
        self.isPreset = true
        self.isFavorite = false
        self.usageCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 模板分类
enum TemplateCategory: String, Codable, CaseIterable {
    case social = "social"              // 社交媒体
    case festival = "festival"          // 节日主题
    case emotion = "emotion"            // 情绪主题
    case art = "art"                    // 艺术风格
    case minimal = "minimal"            // 极简风格
    case creative = "creative"          // 创意风格
    
    var displayName: String {
        switch self {
        case .social: return "社交媒体"
        case .festival: return "节日主题"
        case .emotion: return "情绪主题"
        case .art: return "艺术风格"
        case .minimal: return "极简风格"
        case .creative: return "创意风格"
        }
    }
}

/// 模板布局
enum TemplateLayout: String, Codable, CaseIterable {
    case standard = "standard"          // 标准
    case square = "square"              // 正方形
    case portrait = "portrait"          // 竖版
    case landscape = "landscape"        // 横版
    case story = "story"                // 故事
    
    var displayName: String {
        switch self {
        case .standard: return "标准"
        case .square: return "正方形"
        case .portrait: return "竖版"
        case .landscape: return "横版"
        case .story: return "故事"
        }
    }
    
    /// 推荐尺寸 (像素)
    var recommendedSize: CGSize {
        switch self {
        case .standard: return CGSize(width: 1080, height: 1080)
        case .square: return CGSize(width: 1080, height: 1080)
        case .portrait: return CGSize(width: 1080, height: 1350)
        case .landscape: return CGSize(width: 1200, height: 630)
        case .story: return CGSize(width: 1080, height: 1920)
        }
    }
}

/// 自定义模板元素
struct CustomTemplateElement: Codable {
    var type: ElementType
    var content: String
    var position: CGPoint
    var fontSize: Double
    var color: String
    var rotation: Double
    
    enum ElementType: String, Codable {
        case text = "text"
        case image = "image"
        case shape = "shape"
        case sticker = "sticker"
    }
}

// MARK: - 分享成就模型

/// 分享成就
@Model
final class DreamShareAchievement {
    var id: UUID
    var type: AchievementType
    var name: String
    var description: String
    var icon: String
    var requirement: Int
    var currentProgress: Int
    var isUnlocked: Bool
    var unlockedAt: Date?
    var reward: AchievementReward?
    
    init(type: AchievementType, name: String, description: String, icon: String, requirement: Int) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.currentProgress = 0
        self.isUnlocked = false
        self.unlockedAt = nil
        self.reward = nil
    }
    
    /// 更新进度
    func updateProgress(to newValue: Int) {
        currentProgress = min(newValue, requirement)
        if currentProgress >= requirement && !isUnlocked {
            isUnlocked = true
            unlockedAt = Date()
        }
    }
}

/// 成就类型
enum AchievementType: String, Codable, CaseIterable {
    case firstShare = "first_share"              // 首次分享
    case shareNovice = "share_novice"            // 分享新手 (10 次)
    case shareExpert = "share_expert"            // 分享专家 (50 次)
    case shareMaster = "share_master"            // 分享大师 (100 次)
    case multiPlatform = "multi_platform"        // 多平台分享者
    case popularCreator = "popular_creator"      // 热门创作者
    case viralShare = "viral_share"              // 病毒式分享
    case creativeSharer = "creative_sharer"      // 创意分享家
    
    var displayName: String {
        switch self {
        case .firstShare: return "首次分享"
        case .shareNovice: return "分享新手"
        case .shareExpert: return "分享专家"
        case .shareMaster: return "分享大师"
        case .multiPlatform: return "多平台分享者"
        case .popularCreator: return "热门创作者"
        case .viralShare: return "病毒式分享"
        case .creativeSharer: return "创意分享家"
        }
    }
}

/// 成就奖励
struct AchievementReward: Codable {
    var type: RewardType
    var value: String
    var description: String
    
    enum RewardType: String, Codable {
        case template = "template"      // 解锁模板
        case badge = "badge"            // 专属徽章
        case quota = "quota"            // 提升配额
        case feature = "feature"        // 解锁功能
    }
}

// MARK: - 分享任务模型

/// 分享任务 (用于队列管理)
@Model
final class DreamShareTask {
    var id: UUID
    var dreamId: UUID
    var platforms: [String]  // platform rawValues
    var contentType: ShareContentType
    var scheduledAt: Date?
    var status: ShareTaskStatus
    var createdAt: Date
    var completedAt: Date?
    var errorMessage: String?
    
    init(dreamId: UUID, platforms: [SharePlatform], contentType: ShareContentType, scheduledAt: Date? = nil) {
        self.id = UUID()
        self.dreamId = dreamId
        self.platforms = platforms.map { $0.rawValue }
        self.contentType = contentType
        self.scheduledAt = scheduledAt
        self.status = .pending
        self.createdAt = Date()
        self.completedAt = nil
        self.errorMessage = nil
    }
}

/// 分享任务状态
enum ShareTaskStatus: String, Codable {
    case pending = "pending"            // 等待中
    case processing = "processing"      // 处理中
    case completed = "completed"        // 已完成
    case failed = "failed"              // 失败
    case cancelled = "cancelled"        // 已取消
}

/// 分享内容类型
enum ShareContentType: String, Codable, CaseIterable {
    case image = "image"                // 图片
    case card = "card"                  // 分享卡片
    case video = "video"                // 视频
    case story = "story"                // 梦境故事
    case link = "link"                  // 分享链接
    case text = "text"                  // 纯文本
    
    var displayName: String {
        switch self {
        case .image: return "图片"
        case .card: return "卡片"
        case .video: return "视频"
        case .story: return "故事"
        case .link: return "链接"
        case .text: return "文本"
        }
    }
}

// MARK: - 分享配置

/// 分享配置
struct ShareConfiguration: Codable {
    var defaultPlatforms: [SharePlatform]
    var autoGenerateLink: Bool
    var trackAnalytics: Bool
    var showAchievementNotifications: Bool
    var maxDailyShares: Int
    var enableScheduledSharing: Bool
    
    static var `default`: ShareConfiguration {
        ShareConfiguration(
            defaultPlatforms: [.wechat, .wechatMoments, .weibo],
            autoGenerateLink: true,
            trackAnalytics: true,
            showAchievementNotifications: true,
            maxDailyShares: 50,
            enableScheduledSharing: true
        )
    }
}
