//
//  DreamSocialPlatforms.swift
//  DreamLog - Phase 70: 梦境社交分享增强
//
//  Created by DreamLog Team on 2026-03-19.
//  Phase 70: Enhanced Social Sharing - 扩展社交平台支持
//

import Foundation
import SwiftUI
import UIKit
import LinkPresentation

// MARK: - 扩展分享平台枚举

/// 扩展的分享平台 (Phase 70 新增)
enum ExtendedSharePlatform: String, Codable, CaseIterable, Identifiable {
    // MARK: 原有平台
    case wechat = "wechat"                    // 微信好友
    case wechatMoments = "wechat_moments"     // 朋友圈
    case weibo = "weibo"                      // 微博
    case xiaohongshu = "xiaohongshu"          // 小红书
    case qq = "qq"                            // QQ
    case telegram = "telegram"                // Telegram
    case instagram = "instagram"              // Instagram
    case twitter = "twitter"                  // Twitter/X
    case facebook = "facebook"                // Facebook
    
    // MARK: Phase 70 新增平台
    case tiktok = "tiktok"                    // 抖音/TikTok
    case douyin = "douyin"                    // 抖音 (国内版)
    case youtubeShorts = "youtube_shorts"     // YouTube Shorts
    case snapchat = "snapchat"                // Snapchat
    case pinterest = "pinterest"              // Pinterest
    case threads = "threads"                  // Threads
    case mastodon = "mastodon"                // Mastodon
    case bluesky = "bluesky"                  // Bluesky
    case discord = "discord"                  // Discord
    case reddit = "reddit"                    // Reddit
    case linkedin = "linkedin"                // LinkedIn (职业分享)
    case whatsapp = "whatsapp"                // WhatsApp
    case line = "line"                        // LINE
    case kakao = "kakao"                      // KakaoTalk
    
    // MARK: 通用选项
    case copy = "copy"                        // 复制链接
    case image = "image"                      // 保存图片
    case video = "video"                      // 保存视频
    case airDrop = "airdrop"                  // AirDrop
    
    var id: String { rawValue }
    
    /// 平台显示名称
    var displayName: String {
        switch self {
        case .wechat: return "微信好友"
        case .wechatMoments: return "朋友圈"
        case .weibo: return "微博"
        case .xiaohongshu: return "小红书"
        case .qq: return "QQ"
        case .telegram: return "Telegram"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .facebook: return "Facebook"
        case .tiktok: return "TikTok"
        case .douyin: return "抖音"
        case .youtubeShorts: return "YouTube Shorts"
        case .snapchat: return "Snapchat"
        case .pinterest: return "Pinterest"
        case .threads: return "Threads"
        case .mastodon: return "Mastodon"
        case .bluesky: return "Bluesky"
        case .discord: return "Discord"
        case .reddit: return "Reddit"
        case .linkedin: return "LinkedIn"
        case .whatsapp: return "WhatsApp"
        case .line: return "LINE"
        case .kakao: return "KakaoTalk"
        case .copy: return "复制链接"
        case .image: return "保存图片"
        case .video: return "保存视频"
        case .airDrop: return "AirDrop"
        }
    }
    
    /// 平台图标 (SF Symbol)
    var iconName: String {
        switch self {
        case .wechat: return "message.fill"
        case .wechatMoments: return "bubble.left.and.bubble.right.fill"
        case .weibo: return "square.grid.2x2.fill"
        case .xiaohongshu: return "book.fill"
        case .qq: return "quote.bubble.fill"
        case .telegram: return "paperplane.fill"
        case .instagram: return "camera.fill"
        case .twitter: return "x.circle.fill"
        case .facebook: return "f.circle.fill"
        case .tiktok, .douyin: return "music.note.house.fill"
        case .youtubeShorts: return "play.rectangle.fill"
        case .snapchat: return "ghost.fill"
        case .pinterest: return "pin.fill"
        case .threads: return "thread.fill"
        case .mastodon: return "m.circle.fill"
        case .bluesky: return "cloud.fill"
        case .discord: return "gamecontroller.fill"
        case .reddit: return "alien.fill"
        case .linkedin: return "linkedin.fill"
        case .whatsapp: return "phone.badge.plus.fill"
        case .line: return "line.3.horizontal"
        case .kakao: return "k.circle.fill"
        case .copy: return "doc.on.doc.fill"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .airDrop: return "wifi"
        }
    }
    
    /// 平台品牌色 (十六进制)
    var brandColor: String {
        switch self {
        case .wechat, .wechatMoments: return "07C160"
        case .weibo: return "E6162D"
        case .xiaohongshu: return "FF2442"
        case .qq: return "12B7F5"
        case .telegram: return "0088CC"
        case .instagram: return "E4405F"
        case .twitter: return "000000"
        case .facebook: return "1877F2"
        case .tiktok: return "000000"
        case .douyin: return "FE2C55"
        case .youtubeShorts: return "FF0000"
        case .snapchat: return "FFFC00"
        case .pinterest: return "E60023"
        case .threads: return "000000"
        case .mastodon: return "6364FF"
        case .bluesky: return "0085FF"
        case .discord: return "5865F2"
        case .reddit: return "FF4500"
        case .linkedin: return "0A66C2"
        case .whatsapp: return "25D366"
        case .line: return "06C755"
        case .kakao: return "FEE500"
        case .copy: return "8E8E93"
        case .image: return "007AFF"
        case .video: return "FF2D55"
        case .airDrop: return "007AFF"
        }
    }
    
    /// URL Scheme (用于直接跳转)
    var urlScheme: String? {
        switch self {
        case .wechat, .wechatMoments: return "weixin://"
        case .weibo: return "sinaweibo://"
        case .xiaohongshu: return "xhsdiscover://"
        case .qq: return "mqq://"
        case .telegram: return "tg://"
        case .instagram: return "instagram://"
        case .twitter: return "twitter://"
        case .facebook: return "facebook://"
        case .tiktok: return "tiktok://"
        case .douyin: return "snssdk1128://"
        case .youtubeShorts: return "youtube://"
        case .snapchat: return "snapchat://"
        case .pinterest: return "pinterest://"
        case .threads: return "threads://"
        case .discord: return "discord://"
        case .reddit: return "reddit://"
        case .linkedin: return "linkedin://"
        case .whatsapp: return "whatsapp://"
        case .line: return "line://"
        case .kakao: return "kakaotalk://"
        case .mastodon, .bluesky, .copy, .image, .video, .airDrop: return nil
        }
    }
    
    /// 是否支持视频分享
    var supportsVideo: Bool {
        switch self {
        case .tiktok, .douyin, .youtubeShorts, .instagram, .snapchat, .facebook, .twitter:
            return true
        default:
            return false
        }
    }
    
    /// 是否支持图片分享
    var supportsImage: Bool {
        switch self {
        case .image, .video: return true
        default: return true  // 大多数平台都支持图片
        }
    }
    
    /// 是否支持文本分享
    var supportsText: Bool {
        switch self {
        case .image, .video, .airDrop: return false
        default: return true
        }
    }
    
    /// 是否支持链接分享
    var supportsLink: Bool {
        switch self {
        case .image, .video: return false
        default: return true
        }
    }
    
    /// 推荐的内容类型
    var recommendedContentType: ShareContentType {
        switch self {
        case .tiktok, .douyin, .youtubeShorts, .snapchat:
            return .video
        case .instagram, .pinterest:
            return .image
        case .twitter, .threads, .mastodon, .bluesky:
            return .text
        case .linkedin:
            return .article
        case .discord, .reddit:
            return .mixed
        default:
            return .mixed
        }
    }
    
    /// 平台分组
    var platformGroup: PlatformGroup {
        switch self {
        case .wechat, .wechatMoments, .qq, .line, .kakao, .whatsapp:
            return .messaging
        case .weibo, .twitter, .threads, .mastodon, .bluesky:
            return .microblog
        case .instagram, .tiktok, .douyin, .youtubeShorts, .snapchat, .pinterest:
            return .visual
        case .facebook, .reddit, .discord:
            return .community
        case .linkedin:
            return .professional
        case .telegram:
            return .messaging
        case .xiaohongshu:
            return .visual
        case .copy, .image, .video, .airDrop:
            return .utility
        }
    }
}

// MARK: - 内容类型枚举

/// 分享内容类型
enum ShareContentType: String, Codable, CaseIterable {
    case text = "text"              // 纯文本
    case image = "image"            // 图片
    case video = "video"            // 视频
    case link = "link"              // 链接
    case article = "article"        // 文章
    case mixed = "mixed"            // 混合内容
    
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .image: return "图片"
        case .video: return "视频"
        case .link: return "链接"
        case .article: return "文章"
        case .mixed: return "混合"
        }
    }
    
    var iconName: String {
        switch self {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .video: return "video"
        case .link: return "link"
        case .article: return "doc.text"
        case .mixed: return "square.grid.2x2"
        }
    }
}

// MARK: - 平台分组枚举

/// 平台分组
enum PlatformGroup: String, Codable, CaseIterable, Identifiable {
    case messaging = "messaging"        // 即时通讯
    case microblog = "microblog"        // 微博客
    case visual = "visual"              // 视觉分享
    case community = "community"        // 社区论坛
    case professional = "professional"  // 职业社交
    case utility = "utility"            // 工具类
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .messaging: return "即时通讯"
        case .microblog: return "微博客"
        case .visual: return "视觉分享"
        case .community: return "社区论坛"
        case .professional: return "职业社交"
        case .utility: return "工具类"
        }
    }
    
    var iconName: String {
        switch self {
        case .messaging: return "message.fill"
        case .microblog: return "text.bubble.fill"
        case .visual: return "camera.fill"
        case .community: return "person.3.fill"
        case .professional: return "briefcase.fill"
        case .utility: return "wrench.and.screwdriver.fill"
        }
    }
    
    var groupColor: String {
        switch self {
        case .messaging: return "34C759"
        case .microblog: return "007AFF"
        case .visual: return "FF2D55"
        case .community: return "5856D6"
        case .professional: return "007AFF"
        case .utility: return "8E8E93"
        }
    }
}

// MARK: - 平台分享能力

/// 平台分享能力配置
struct PlatformCapabilities {
    let platform: ExtendedSharePlatform
    let maxTextLength: Int?               // 最大文本长度 (nil 表示无限制)
    let maxImageCount: Int                // 最大图片数量
    let maxVideoDuration: TimeInterval?   // 最大视频时长
    let supportsHashtags: Bool            // 支持话题标签
    let supportsMentions: Bool            // 支持提及用户
    let supportsLocation: Bool            // 支持位置
    let supportsScheduling: Bool          // 支持定时发布
    let supportsAnalytics: Bool           // 支持数据分析
    let requiresAccount: Bool             // 需要登录账号
    
    /// 获取平台的默认能力配置
    static func capabilities(for platform: ExtendedSharePlatform) -> PlatformCapabilities {
        switch platform {
        case .twitter:
            return PlatformCapabilities(
                platform: platform,
                maxTextLength: 280,
                maxImageCount: 4,
                maxVideoDuration: 140,
                supportsHashtags: true,
                supportsMentions: true,
                supportsLocation: true,
                supportsScheduling: true,
                supportsAnalytics: true,
                requiresAccount: true
            )
        case .instagram:
            return PlatformCapabilities(
                platform: platform,
                maxTextLength: 2200,
                maxImageCount: 10,
                maxVideoDuration: 900,
                supportsHashtags: true,
                supportsMentions: true,
                supportsLocation: true,
                supportsScheduling: true,
                supportsAnalytics: true,
                requiresAccount: true
            )
        case .tiktok, .douyin:
            return PlatformCapabilities(
                platform: platform,
                maxTextLength: 150,
                maxImageCount: 0,
                maxVideoDuration: 180,
                supportsHashtags: true,
                supportsMentions: true,
                supportsLocation: true,
                supportsScheduling: false,
                supportsAnalytics: true,
                requiresAccount: true
            )
        case .youtubeShorts:
            return PlatformCapabilities(
                platform: platform,
                maxTextLength: 100,
                maxImageCount: 0,
                maxVideoDuration: 60,
                supportsHashtags: true,
                supportsMentions: false,
                supportsLocation: false,
                supportsScheduling: true,
                supportsAnalytics: true,
                requiresAccount: true
            )
        case .linkedin:
            return PlatformCapabilities(
                platform: platform,
                maxTextLength: 3000,
                maxImageCount: 9,
                maxVideoDuration: 600,
                supportsHashtags: true,
                supportsMentions: true,
                supportsLocation: true,
                supportsScheduling: true,
                supportsAnalytics: true,
                requiresAccount: true
            )
        default:
            return PlatformCapabilities(
                platform: platform,
                maxTextLength: nil,
                maxImageCount: 10,
                maxVideoDuration: nil,
                supportsHashtags: true,
                supportsMentions: true,
                supportsLocation: true,
                supportsScheduling: false,
                supportsAnalytics: false,
                requiresAccount: false
            )
        }
    }
}

// MARK: - 分享平台管理器

@MainActor
final class SocialPlatformManager {
    static let shared = SocialPlatformManager()
    
    private var installedApps: Set<ExtendedSharePlatform> = []
    
    private init() {
        detectInstalledApps()
    }
    
    /// 检测已安装的应用
    private func detectInstalledApps() {
        var detected: Set<ExtendedSharePlatform> = []
        
        for platform in ExtendedSharePlatform.allCases {
            if let scheme = platform.urlScheme,
               let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                detected.insert(platform)
            }
        }
        
        self.installedApps = detected
    }
    
    /// 检查平台是否可用
    func isPlatformAvailable(_ platform: ExtendedSharePlatform) -> Bool {
        // 工具类平台总是可用
        if platform.platformGroup == .utility {
            return true
        }
        
        // 检查是否安装了应用
        return installedApps.contains(platform)
    }
    
    /// 获取所有可用平台
    func getAvailablePlatforms() -> [ExtendedSharePlatform] {
        ExtendedSharePlatform.allCases.filter { isPlatformAvailable($0) }
    }
    
    /// 获取指定分组的可用平台
    func getPlatforms(in group: PlatformGroup) -> [ExtendedSharePlatform] {
        getAvailablePlatforms().filter { $0.platformGroup == group }
    }
    
    /// 获取推荐的平台列表 (按使用频率排序)
    func getRecommendedPlatforms(for contentType: ShareContentType) -> [ExtendedSharePlatform] {
        getAvailablePlatforms()
            .filter { $0.recommendedContentType == contentType || $0.recommendedContentType == .mixed }
            .sorted { platform1, platform2 in
                // 按用户偏好排序 (可以扩展为基于使用历史)
                platform1.displayName < platform2.displayName
            }
    }
    
    /// 刷新已安装应用检测
    func refreshInstalledApps() {
        detectInstalledApps()
    }
}

// MARK: - 分享链接生成器

/// 分享链接生成器 - 为不同平台生成优化的分享链接
struct ShareLinkGenerator {
    
    /// 生成平台特定的分享 URL
    static func generateShareURL(
        for platform: ExtendedSharePlatform,
        text: String?,
        image: Data?,
        videoURL: URL?,
        linkURL: URL?
    ) -> URL? {
        guard let scheme = platform.urlScheme else {
            return nil
        }
        
        switch platform {
        case .twitter:
            return generateTwitterURL(text: text, linkURL: linkURL)
        case .facebook:
            return generateFacebookURL(text: text, linkURL: linkURL)
        case .whatsapp:
            return generateWhatsAppURL(text: text, linkURL: linkURL)
        case .telegram:
            return generateTelegramURL(text: text, linkURL: linkURL)
        case .linkedin:
            return generateLinkedInURL(text: text, linkURL: linkURL)
        default:
            // 对于没有特定 URL 格式的平台，返回通用 scheme
            return URL(string: scheme)
        }
    }
    
    private static func generateTwitterURL(text: String?, linkURL: URL?) -> URL? {
        var components = URLComponents(string: "twitter://post")
        var params: [String: String] = [:]
        
        if let text = text {
            params["message"] = text
        }
        if let linkURL = linkURL {
            params["url"] = linkURL.absoluteString
        }
        
        if !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        return components?.url
    }
    
    private static func generateFacebookURL(text: String?, linkURL: URL?) -> URL? {
        // Facebook 主要通过 share dialog
        guard let linkURL = linkURL else {
            return URL(string: "facebook://")
        }
        
        return URL(string: "fb://share/?href=\(linkURL.absoluteString)")
    }
    
    private static func generateWhatsAppURL(text: String?, linkURL: URL?) -> URL? {
        var message = text ?? ""
        if let linkURL = linkURL {
            message += "\n\(linkURL.absoluteString)"
        }
        
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "whatsapp://send?text=\(encoded)")
    }
    
    private static func generateTelegramURL(text: String?, linkURL: URL?) -> URL? {
        var message = text ?? ""
        if let linkURL = linkURL {
            message += "\n\(linkURL.absoluteString)"
        }
        
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "tg://msg?text=\(encoded)")
    }
    
    private static func generateLinkedInURL(text: String?, linkURL: URL?) -> URL? {
        guard let linkURL = linkURL else {
            return URL(string: "linkedin://")
        }
        
        var components = URLComponents(string: "linkedin://share")
        components?.queryItems = [
            URLQueryItem(name: "url", value: linkURL.absoluteString),
            URLQueryItem(name: "title", value: text ?? "")
        ]
        
        return components?.url
    }
}

// MARK: - 视频分享助手

/// 视频分享助手 - 处理视频导出和分享
@MainActor
final class VideoShareAssistant {
    static let shared = VideoShareAssistant()
    
    private init() {}
    
    /// 检查视频时长是否符合平台要求
    func validateVideoDuration(
        _ duration: TimeInterval,
        for platform: ExtendedSharePlatform
    ) -> (isValid: Bool, message: String?) {
        let capabilities = PlatformCapabilities.capabilities(for: platform)
        
        guard let maxDuration = capabilities.maxVideoDuration else {
            return (true, nil)
        }
        
        if duration <= maxDuration {
            return (true, nil)
        } else {
            let maxSeconds = Int(maxDuration)
            let minutes = maxSeconds / 60
            let seconds = maxSeconds % 60
            return (false, "视频时长不能超过 \(minutes)分\(seconds)秒")
        }
    }
    
    /// 获取平台推荐的视频规格
    func getRecommendedVideoSpecs(for platform: ExtendedSharePlatform) -> VideoSpecifications {
        switch platform {
        case .tiktok, .douyin:
            return VideoSpecifications(
                aspectRatio: "9:16",
                resolution: "1080x1920",
                frameRate: 30,
                format: "mp4",
                maxFileSize: 287_636_980  // 287.6 MB
            )
        case .youtubeShorts:
            return VideoSpecifications(
                aspectRatio: "9:16",
                resolution: "1080x1920",
                frameRate: 60,
                format: "mp4",
                maxFileSize: 256_000_000  // 256 MB
            )
        case .instagram:
            return VideoSpecifications(
                aspectRatio: "9:16",
                resolution: "1080x1920",
                frameRate: 30,
                format: "mp4",
                maxFileSize: 102_400_000  // 100 MB
            )
        case .snapchat:
            return VideoSpecifications(
                aspectRatio: "9:16",
                resolution: "1080x1920",
                frameRate: 30,
                format: "mp4",
                maxFileSize: 32_000_000  // 32 MB
            )
        default:
            return VideoSpecifications(
                aspectRatio: "16:9",
                resolution: "1920x1080",
                frameRate: 30,
                format: "mp4",
                maxFileSize: 102_400_000
            )
        }
    }
}

/// 视频规格
struct VideoSpecifications {
    let aspectRatio: String       // 宽高比
    let resolution: String        // 分辨率
    let frameRate: Int            // 帧率
    let format: String            // 格式
    let maxFileSize: Int          // 最大文件大小 (字节)
}

// MARK: - 分享预览提供者

/// 分享预览提供者 - 使用 Link Presentation 框架
@available(iOS 13.0, *)
final class SharePreviewProvider: NSObject, LPLinkMetadataProvider {
    static let shared = SharePreviewProvider()
    
    func metadata(for url: URL, completion: @escaping (LPLinkMetadata?, Error?) -> Void) {
        let metadata = LPLinkMetadata()
        metadata.title = "DreamLog - 记录你的梦境"
        metadata.description = "探索梦境的奥秘，发现潜意识的智慧"
        metadata.iconProvider = NSItemProvider(object: UIImage(systemName: "moon.stars.fill") ?? UIImage())
        metadata.imageProvider = NSItemProvider(object: UIImage())
        completion(metadata, nil)
    }
}
