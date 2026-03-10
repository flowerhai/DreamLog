//
//  DreamVideoEnhancements.swift
//  DreamLog
//
//  Dream Video Advanced Features - Phase 14
//  Batch export, social sharing, playlists, and advanced effects
//

import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - 视频分享平台

/// 视频分享平台枚举
enum VideoSharePlatform: String, CaseIterable, Identifiable {
    case wechat = "微信"
    case wechatMoments = "朋友圈"
    case weibo = "微博"
    case qq = "QQ"
    case telegram = "Telegram"
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case copyLink = "复制链接"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .wechat, .wechatMoments: return "message.fill"
        case .weibo: return "square.and.pencil"
        case .qq: return "bubble.left.and.bubble.right"
        case .telegram: return "paperplane"
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .copyLink: return "link"
        }
    }
    
    var color: String {
        switch self {
        case .wechat, .wechatMoments: return "07C160"
        case .weibo: return "E6162D"
        case .qq: return "12B7F5"
        case .telegram: return "0088cc"
        case .instagram: return "E44056"
        case .tiktok: return "000000"
        case .copyLink: return "8E8E93"
        }
    }
}

// MARK: - 视频播放列表

/// 梦境视频播放列表
struct VideoPlaylist: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var videoIds: [UUID]
    var createdAt: Date
    var isFavorite: Bool = false
    var coverVideoId: UUID?
    
    var videoCount: Int { videoIds.count }
}

// MARK: - 视频导出配置

/// 视频导出配置
struct VideoExportConfig {
    var format: ExportFormat
    var quality: ExportQuality
    var includeMetadata: Bool
    var compressSize: Bool
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case mp4 = "MP4 (H.264)"
        case mov = "MOV (ProRes)"
        case gif = "GIF (动图)"
        
        var id: String { rawValue }
        
        var fileExtension: String {
            switch self {
            case .mp4: return "mp4"
            case .mov: return "mov"
            case .gif: return "gif"
            }
        }
    }
    
    enum ExportQuality: String, CaseIterable, Identifiable {
        case low = "低 (480p)"
        case medium = "中 (720p)"
        case high = "高 (1080p)"
        case original = "原始"
        
        var id: String { rawValue }
        
        var bitrate: Int {
            switch self {
            case .low: return 1_000_000
            case .medium: return 2_500_000
            case .high: return 5_000_000
            case .original: return 10_000_000
            }
        }
    }
}

// MARK: - 社交媒体导出预设

/// 社交媒体平台视频导出预设
struct SocialMediaPreset {
    let platform: VideoSharePlatform
    let name: String
    let aspectRatio: DreamVideoConfig.AspectRatio
    let maxDuration: Double  // 秒
    let resolution: CGSize
    let frameRate: Int
    let bitrate: Int
    let format: VideoExportConfig.ExportFormat
    let recommendations: [String]  // 最佳实践建议
    
    /// 获取所有预设
    static var allPresets: [SocialMediaPreset] {
        [
            // 抖音/TikTok
            SocialMediaPreset(
                platform: .tiktok,
                name: "抖音/TikTok",
                aspectRatio: .portrait,  // 9:16
                maxDuration: 60,
                resolution: CGSize(width: 1080, height: 1920),
                frameRate: 30,
                bitrate: 5_000_000,
                format: .mp4,
                recommendations: [
                    "使用竖屏 9:16 比例",
                    "前 3 秒吸引注意力",
                    "添加热门音乐",
                    "使用快节奏转场",
                    "添加文字说明"
                ]
            ),
            
            // Instagram Reels
            SocialMediaPreset(
                platform: .instagram,
                name: "Instagram Reels",
                aspectRatio: .portrait,  // 9:16
                maxDuration: 90,
                resolution: CGSize(width: 1080, height: 1920),
                frameRate: 30,
                bitrate: 5_000_000,
                format: .mp4,
                recommendations: [
                    "竖屏 9:16 最佳",
                    "使用流行音乐",
                    "添加相关标签",
                    "保持内容有趣",
                    "使用滤镜增强效果"
                ]
            ),
            
            // Instagram Stories
            SocialMediaPreset(
                platform: .instagram,
                name: "Instagram Stories",
                aspectRatio: .portrait,  // 9:16
                maxDuration: 15,
                resolution: CGSize(width: 1080, height: 1920),
                frameRate: 30,
                bitrate: 4_000_000,
                format: .mp4,
                recommendations: [
                    "每条最多 15 秒",
                    "竖屏拍摄",
                    "添加互动贴纸",
                    "使用标签和位置",
                    "保持真实自然"
                ]
            ),
            
            // 微信朋友圈
            SocialMediaPreset(
                platform: .wechatMoments,
                name: "微信朋友圈",
                aspectRatio: .portrait,  // 9:16 或 1:1
                maxDuration: 30,
                resolution: CGSize(width: 1080, height: 1920),
                frameRate: 30,
                bitrate: 4_000_000,
                format: .mp4,
                recommendations: [
                    "支持竖屏和正方形",
                    "时长不超过 30 秒",
                    "添加有趣文案",
                    "选择合适可见范围",
                    "避免过度编辑"
                ]
            ),
            
            // 微博
            SocialMediaPreset(
                platform: .weibo,
                name: "微博",
                aspectRatio: .landscape,  // 16:9
                maxDuration: 120,
                resolution: CGSize(width: 1920, height: 1080),
                frameRate: 30,
                bitrate: 5_000_000,
                format: .mp4,
                recommendations: [
                    "横屏 16:9 最佳",
                    "可上传长视频",
                    "添加话题标签",
                    "配合文字说明",
                    "@相关账号增加曝光"
                ]
            ),
            
            // YouTube Shorts
            SocialMediaPreset(
                platform: .tiktok,  // 复用图标
                name: "YouTube Shorts",
                aspectRatio: .portrait,  // 9:16
                maxDuration: 60,
                resolution: CGSize(width: 1080, height: 1920),
                frameRate: 30,
                bitrate: 5_000_000,
                format: .mp4,
                recommendations: [
                    "竖屏 9:16",
                    "时长 60 秒内",
                    "添加#Shorts 标签",
                    "使用热门音乐",
                    "前 5 秒抓住观众"
                ]
            ),
            
            // Telegram
            SocialMediaPreset(
                platform: .telegram,
                name: "Telegram",
                aspectRatio: .landscape,  // 16:9
                maxDuration: 60,  // 免压缩限制
                resolution: CGSize(width: 1920, height: 1080),
                frameRate: 30,
                bitrate: 5_000_000,
                format: .mp4,
                recommendations: [
                    "支持多种格式",
                    "文件<50MB 免压缩",
                    "可发送原画质量",
                    "支持 GIF 动图",
                    "可添加到收藏夹"
                ]
            ),
            
            // QQ
            SocialMediaPreset(
                platform: .qq,
                name: "QQ",
                aspectRatio: .portrait,
                maxDuration: 30,
                resolution: CGSize(width: 1080, height: 1920),
                frameRate: 30,
                bitrate: 4_000_000,
                format: .mp4,
                recommendations: [
                    "支持竖屏视频",
                    "时长适中",
                    "添加趣味表情",
                    "分享给好友或群",
                    "可设置为动态"
                ]
            )
        ]
    }
    
    /// 根据平台获取预设
    static func preset(for platform: VideoSharePlatform) -> SocialMediaPreset? {
        allPresets.first { $0.platform == platform }
    }
    
    /// 获取推荐配置
    func recommendedConfig() -> DreamVideoConfig {
        DreamVideoConfig(
            style: .cinematic,
            duration: min(maxDuration, 30),  // 默认 30 秒或平台最大值
            aspectRatio: aspectRatio
        )
    }
}

// MARK: - 视频增强服务

/// 梦境视频增强服务
class DreamVideoEnhancementService: ObservableObject {
    static let shared = DreamVideoEnhancementService()
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var exportStatus: String = ""
    @Published var playlists: [VideoPlaylist] = []
    @Published var lastExportURL: URL?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadPlaylists()
    }
    
    private func loadPlaylists() {
        // 从文件系统加载播放列表
        playlists = getAllPlaylists()
    }
    
    // MARK: - 批量导出
    
    /// 批量导出视频
    func batchExportVideos(videos: [DreamVideo], config: VideoExportConfig) async throws -> [URL] {
        guard !isExporting else {
            throw VideoEnhancementError.alreadyExporting
        }
        
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        var exportedURLs: [URL] = []
        let total = videos.count
        
        for (index, video) in videos.enumerated() {
            exportStatus = "正在导出 \(index + 1)/\(total): \(video.title)"
            exportProgress = Double(index) / Double(total)
            
            do {
                let url = try await exportVideo(video, config: config)
                exportedURLs.append(url)
            } catch {
                print("导出失败 \(video.title): \(error)")
            }
        }
        
        exportStatus = "批量导出完成！共 \(exportedURLs.count)/\(total) 个视频"
        exportProgress = 1.0
        
        return exportedURLs
    }
    
    /// 导出单个视频
    func exportVideo(_ video: DreamVideo, config: VideoExportConfig) async throws -> URL {
        let sourceURL = URL(fileURLWithPath: video.filePath)
        
        guard FileManager.default.fileExists(atPath: video.filePath) else {
            throw VideoEnhancementError.fileNotFound
        }
        
        let outputURL = getExportOutputURL(for: video, config: config)
        
        if config.format == .gif {
            // 转换为 GIF
            try await convertToGIF(sourceURL: sourceURL, outputURL: outputURL)
        } else if config.compressSize || config.quality != .original {
            // 重新编码
            try await reencodeVideo(sourceURL: sourceURL, outputURL: outputURL, config: config)
        } else {
            // 直接复制
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
        }
        
        if config.includeMetadata {
            try await writeMetadata(to: outputURL, video: video)
        }
        
        return outputURL
    }
    
    // MARK: - GIF 转换
    
    private func convertToGIF(sourceURL: URL, outputURL: URL) async throws {
        // 简化实现：实际需要使用 GIF 编码库
        // 这里使用占位实现
        exportStatus = "转换为 GIF 格式..."
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟 1 秒处理时间
    }
    
    // MARK: - 视频重新编码
    
    private func reencodeVideo(sourceURL: URL, outputURL: URL, config: VideoExportConfig) async throws {
        exportStatus = "重新编码视频中..."
        
        // 使用 AVAssetExportSession 进行重新编码
        let asset = AVAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: getExportPreset(for: config.quality)) else {
            throw VideoEnhancementError.exportFailed("无法创建导出会话")
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // 监控进度
        exportSession.progress.publisher()
            .sink { [weak self] progress in
                self?.exportProgress = progress
            }
            .store(in: &cancellables)
        
        await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                continuation.resume()
            }
        }
        
        guard exportSession.status == .completed else {
            throw VideoEnhancementError.exportFailed(exportSession.error?.localizedDescription ?? "导出失败")
        }
    }
    
    private func getExportPreset(for quality: VideoExportConfig.ExportQuality) -> String {
        switch quality {
        case .low: return AVAssetExportPreset640x480
        case .medium: return AVAssetExportPreset1280x720
        case .high: return AVAssetExportPreset1920x1080
        case .original: return AVAssetExportPresetPassthrough
        }
    }
    
    // MARK: - 元数据写入
    
    private func writeMetadata(to url: URL, video: DreamVideo) async throws {
        // 使用 AVAssetWriter 写入元数据
        // 简化实现
    }
    
    // MARK: - 分享功能
    
    /// 生成分享项目
    func generateShareItem(for video: DreamVideo, platform: VideoSharePlatform) -> ShareItem {
        let title = "🌙 我刚刚用 DreamLog 记录了梦境「\(video.title)」"
        let message = "这个梦太有意思了！快来看看我的梦境视频 \(video.style) 风格，时长 \(Int(video.duration)) 秒"
        
        return ShareItem(
            title: title,
            message: message,
            url: URL(fileURLWithPath: video.filePath),
            platform: platform
        )
    }
    
    /// 分享到社交平台
    func shareToPlatform(_ platform: VideoSharePlatform, video: DreamVideo) {
        let shareItem = generateShareItem(for: video, platform: platform)
        
        switch platform {
        case .copyLink:
            // 复制链接到剪贴板
            UIPasteboard.general.url = shareItem.url
            exportStatus = "链接已复制到剪贴板"
        default:
            // 其他平台使用系统分享
            exportStatus = "准备分享到 \(platform.rawValue)..."
        }
    }
    
    // MARK: - 播放列表管理
    
    /// 创建播放列表
    func createPlaylist(title: String, description: String = "", videos: [DreamVideo]) -> VideoPlaylist {
        let playlist = VideoPlaylist(
            title: title,
            description: description,
            videoIds: videos.map { $0.id },
            createdAt: Date(),
            coverVideoId: videos.first?.id
        )
        
        playlists.append(playlist)
        savePlaylists()
        
        return playlist
    }
    
    /// 添加到播放列表
    func addToPlaylist(_ playlist: inout VideoPlaylist, video: DreamVideo) {
        if !playlist.videoIds.contains(video.id) {
            playlist.videoIds.append(video.id)
            savePlaylists()
        }
    }
    
    /// 从播放列表移除
    func removeFromPlaylist(_ playlist: inout VideoPlaylist, videoId: UUID) {
        playlist.videoIds.removeAll { $0 == videoId }
        savePlaylists()
    }
    
    /// 删除播放列表
    func deletePlaylist(_ playlist: VideoPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
        savePlaylists()
    }
    
    // MARK: - 数据持久化
    
    private func getAllPlaylists() -> [VideoPlaylist] {
        // 从文件系统加载播放列表
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let playlistsPath = documentsPath.appendingPathComponent("DreamVideoPlaylists", isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: playlistsPath.path) else {
            return []
        }
        
        // 简化实现：返回空数组
        return []
    }
    
    private func savePlaylists() {
        // 保存播放列表到文件系统
        // 简化实现
    }
    
    private func getExportOutputURL(for video: DreamVideo, config: VideoExportConfig) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportsPath = documentsPath.appendingPathComponent("DreamVideoExports", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: exportsPath, withIntermediateDirectories: true)
        
        let filename = "DreamLog_\(video.title.prefix(20).replacingOccurrences(of: "/", with: "_")).\(config.format.fileExtension)"
        return exportsPath.appendingPathComponent(filename)
    }
}

// MARK: - 分享项目

/// 分享项目结构
struct ShareItem {
    var title: String
    var message: String
    var url: URL
    var platform: VideoSharePlatform
}

// MARK: - 错误类型

enum VideoEnhancementError: LocalizedError {
    case alreadyExporting
    case fileNotFound
    case exportFailed(String)
    case playlistNotFound
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .alreadyExporting:
            return "正在导出另一个视频，请稍候"
        case .fileNotFound:
            return "视频文件不存在"
        case .exportFailed(let reason):
            return "导出失败：\(reason)"
        case .playlistNotFound:
            return "播放列表不存在"
        case .invalidFormat:
            return "不支持的视频格式"
        }
    }
}

// MARK: - 预览数据

#if DEBUG
extension VideoPlaylist {
    static var preview: VideoPlaylist {
        VideoPlaylist(
            title: "最美梦境",
            description: "收集的最美的梦境视频",
            videoIds: [UUID(), UUID(), UUID()],
            createdAt: Date(),
            isFavorite: true
        )
    }
}
#endif

// MARK: - 视频缩略图生成器 (Video Thumbnail Generator)

/// 视频缩略图生成服务
struct VideoThumbnailGenerator {
    
    /// 从视频生成缩略图
    /// - Parameters:
    ///   - videoURL: 视频文件 URL
    ///   - time: 时间点 (默认取视频中间帧)
    ///   - size: 缩略图尺寸
    /// - Returns: UIImage 缩略图
    static func generateThumbnail(from videoURL: URL, at time: CMTime? = nil, size: CGSize = CGSize(width: 320, height: 320)) async -> UIImage? {
        let asset = AVAsset(url: videoURL)
        
        do {
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = size
            
            let thumbnailTime = time ?? CMTime(seconds: Double(asset.duration.seconds) / 2.0, preferredTimescale: 600)
            
            let cgImage = try await imageGenerator.image(at: thumbnailTime).image
            return UIImage(cgImage: cgImage)
        } catch {
            print("Thumbnail generation failed: \(error)")
            return nil
        }
    }
    
    /// 批量生成视频缩略图
    static func generateThumbnails(for videos: [DreamVideo], from directory: URL) async -> [UUID: UIImage] {
        var thumbnails: [UUID: UIImage] = [:]
        
        await withTaskGroup(of: (UUID, UIImage?).self) { group in
            for video in videos {
                group.addTask {
                    let videoURL = directory.appendingPathComponent("\(video.id.uuidString).mp4")
                    let thumbnail = await generateThumbnail(from: videoURL)
                    return (video.id, thumbnail)
                }
            }
            
            for await (id, thumbnail) in group {
                if let thumbnail = thumbnail {
                    thumbnails[id] = thumbnail
                }
            }
        }
        
        return thumbnails
    }
}

// MARK: - 视频转场效果库 (Video Transition Effects Library)

/// 高级转场效果
enum AdvancedTransition {
    
    /// 淡入淡出
    case fade(duration: Double)
    
    /// 溶解
    case dissolve(duration: Double)
    
    /// 滑动 (方向)
    case slide(direction: SlideDirection, duration: Double)
    
    /// 缩放
    case zoom(scale: CGFloat, duration: Double)
    
    /// 旋转
    case rotate(angle: CGFloat, duration: Double)
    
    /// 立方体旋转
    case cubeRotate(direction: SlideDirection, duration: Double)
    
    /// 页面翻转
    case pageCurl(direction: SlideDirection, duration: Double)
    
    /// 百叶窗
    case blinds(count: Int, duration: Double)
    
    /// 棋盘格
    case checkerboard(rows: Int, columns: Int, duration: Double)
    
    /// 随机
    case random
    
    enum SlideDirection {
        case left
        case right
        case up
        case down
    }
    
    /// 获取转场名称
    var name: String {
        switch self {
        case .fade: return "淡入淡出"
        case .dissolve: return "溶解"
        case .slide: return "滑动"
        case .zoom: return "缩放"
        case .rotate: return "旋转"
        case .cubeRotate: return "立方体"
        case .pageCurl: return "翻页"
        case .blinds: return "百叶窗"
        case .checkerboard: return "棋盘格"
        case .random: return "随机"
        }
    }
    
    /// 获取转场图标
    var icon: String {
        switch self {
        case .fade: return "circle.lefthalf.filled"
        case .dissolve: return "circle.dashed"
        case .slide: return "arrow.left.and.right"
        case .zoom: return "arrow.up.left.and.arrow.down.right"
        case .rotate: return "arrow.clockwise"
        case .cubeRotate: return "cube"
        case .pageCurl: return "doc.badge.plus"
        case .blinds: return "square.split.3x3"
        case .checkerboard: return "square.split.2x2"
        case .random: return "dice"
        }
    }
    
    /// 随机选择一个转场
    static func randomTransition() -> AdvancedTransition {
        let transitions: [AdvancedTransition] = [
            .fade(duration: 0.5),
            .dissolve(duration: 0.5),
            .slide(direction: .left, duration: 0.5),
            .zoom(scale: 1.2, duration: 0.5),
            .rotate(angle: .pi / 4, duration: 0.5)
        ]
        return transitions.randomElement() ?? .fade(duration: 0.5)
    }
}

// MARK: - 视频滤镜效果 (Video Filter Effects)

/// 视频滤镜
enum VideoFilter: String, CaseIterable, Identifiable {
    case none = "无"
    case vintage = "复古"
    case noir = "黑白电影"
    case fade = "褪色"
    case instant = "即时"
    case process = "冲印"
    case transfer = "转印"
    case chrome = "铬色"
    case mono = "单色"
    case tonal = "色调"
    case linear = "线性"
    
    var id: String { rawValue }
    
    /// 获取滤镜的 Core Image 名称
    var filterName: String? {
        switch self {
        case .none: return nil
        case .vintage: return "CIVintageCamera"
        case .noir: return "CIPhotoEffectNoir"
        case .fade: return "CIPhotoEffectFade"
        case .instant: return "CIPhotoEffectInstant"
        case .process: return "CIPhotoEffectProcess"
        case .transfer: return "CIPhotoEffectTransfer"
        case .chrome: return "CIPhotoEffectChrome"
        case .mono: return "CIPhotoEffectMono"
        case .tonal: return "CIPhotoEffectTonal"
        case .linear: return "CIPhotoEffectLinear"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "circle"
        case .vintage: return "film"
        case .noir: return "circle.lefthalf.filled"
        case .fade: return "sun.min"
        case .instant: return "bolt"
        case .process: return "gearshape"
        case .transfer: return "arrow.triangle.2.circlepath"
        case .chrome: return "circle.fill"
        case .mono: return "circle.grid.2x2"
        case .tonal: return "slider.horizontal.3"
        case .linear: return "line.3.horizontal"
        }
    }
}

// MARK: - 视频文字模板 (Video Text Templates)

/// 文字叠加模板
enum TextOverlayTemplate: String, CaseIterable, Identifiable {
    case none = "无"
    case title = "标题"
    case quote = "引用"
    case caption = "说明"
    case watermark = "水印"
    case date = "日期"
    case dream = "梦境"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .none: return "不添加文字"
        case .title: return "显示梦境标题"
        case .quote: return "显示梦境摘要"
        case .caption: return "显示时间和标签"
        case .watermark: return "添加 DreamLog 水印"
        case .date: return "显示记录日期"
        case .dream: return "显示梦境关键词"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "textformat"
        case .title: return "textformat.size"
        case .quote: return "text.quote"
        case .caption: return "text.alignleft"
        case .watermark: return "star.fill"
        case .date: return "calendar"
        case .dream: return "brain.head.profile"
        }
    }
}

// MARK: - 视频背景音乐库 (Video Background Music Library)

/// 视频背景音乐选项
enum BackgroundMusicTrack: String, CaseIterable, Identifiable {
    case ambient = "环境氛围"
    case piano = "钢琴曲"
    case strings = "弦乐"
    case electronic = "电子"
    case nature = "自然声音"
    case meditation = "冥想"
    case cinematic = "电影配乐"
    case lofi = "Lo-Fi"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .ambient: return "空灵的环境音效"
        case .piano: return "柔和的钢琴旋律"
        case .strings: return "温暖的弦乐合奏"
        case .electronic: return "现代电子节拍"
        case .nature: return "自然白噪音"
        case .meditation: return "冥想引导音乐"
        case .cinematic: return "史诗电影配乐"
        case .lofi: return "放松的 Lo-Fi 节拍"
        }
    }
    
    var icon: String {
        switch self {
        case .ambient: return "waveform"
        case .piano: return "music.note"
        case .strings: return "guitars.fill"
        case .electronic: return "waveform.path.ecg"
        case .nature: return "leaf.fill"
        case .meditation: return "figure.mind.and.body"
        case .cinematic: return "film"
        case .lofi: return "headphones"
        }
    }
}

// MARK: - 视频质量指标 (Video Quality Metrics)

/// 视频质量评估
struct VideoQualityMetrics {
    var resolution: String
    var frameRate: Double
    var bitrate: Int
    var codec: String
    var duration: Double
    var fileSize: Int64
    
    /// 质量评分 (0-100)
    var qualityScore: Int {
        var score = 0
        
        // 分辨率评分 (最高 30 分)
        if resolution.contains("1080") { score += 30 }
        else if resolution.contains("720") { score += 20 }
        else { score += 10 }
        
        // 帧率评分 (最高 20 分)
        if frameRate >= 60 { score += 20 }
        else if frameRate >= 30 { score += 15 }
        else { score += 10 }
        
        // 比特率评分 (最高 30 分)
        if bitrate >= 10_000_000 { score += 30 }
        else if bitrate >= 5_000_000 { score += 20 }
        else { score += 10 }
        
        // 编码评分 (最高 20 分)
        if codec.contains("H.265") || codec.contains("HEVC") { score += 20 }
        else if codec.contains("H.264") { score += 15 }
        else { score += 10 }
        
        return min(score, 100)
    }
    
    /// 质量等级
    var qualityLevel: String {
        let score = qualityScore
        if score >= 90 { return "优秀" }
        else if score >= 75 { return "良好" }
        else if score >= 60 { return "中等" }
        else { return "一般" }
    }
    
    /// 格式化文件大小
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - 视频分析服务 (Video Analytics Service)

/// 视频观看分析
class VideoAnalyticsService: ObservableObject {
    @Published var totalViews: Int = 0
    @Published var totalShares: Int = 0
    @Published var averageWatchTime: Double = 0
    @Published var completionRate: Double = 0
    
    private let userDefaultsKey = "VideoAnalytics"
    
    init() {
        loadAnalytics()
    }
    
    /// 记录观看
    func recordView(for videoId: UUID, watchTime: Double, duration: Double) {
        totalViews += 1
        averageWatchTime = (averageWatchTime * Double(totalViews - 1) + watchTime) / Double(totalViews)
        completionRate = (completionRate * Double(totalViews - 1) + (watchTime / duration)) / Double(totalViews)
        saveAnalytics()
    }
    
    /// 记录分享
    func recordShare(for videoId: UUID) {
        totalShares += 1
        saveAnalytics()
    }
    
    private func loadAnalytics() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let analytics = try? JSONDecoder().decode([String: AnyCodable].self, from: data) else { return }
        
        totalViews = analytics["totalViews"]?.value as? Int ?? 0
        totalShares = analytics["totalShares"]?.value as? Int ?? 0
        averageWatchTime = analytics["averageWatchTime"]?.value as? Double ?? 0
        completionRate = analytics["completionRate"]?.value as? Double ?? 0
    }
    
    private func saveAnalytics() {
        let analytics: [String: Any] = [
            "totalViews": totalViews,
            "totalShares": totalShares,
            "averageWatchTime": averageWatchTime,
            "completionRate": completionRate
        ]
        
        if let data = try? JSONEncoder().encode(AnyCodable(analytics)) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}

// Codable 辅助类型
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unknown type"))
        }
    }
}
