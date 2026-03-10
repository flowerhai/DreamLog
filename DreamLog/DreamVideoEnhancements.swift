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
