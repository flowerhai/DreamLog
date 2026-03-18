//
//  DreamVideoService.swift
//  DreamLog
//
//  Dream Video Generation Service - Phase 14
//  Combines AI images, music, and text to create shareable dream videos
//

import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - 梦境视频模型

/// 梦境视频配置
struct DreamVideoConfig {
    var dreamId: UUID
    var style: VideoStyle
    var duration: VideoDuration
    var includeMusic: Bool
    var includeTextOverlay: Bool
    var aspectRatio: AspectRatio
    var transitionStyle: TransitionStyle
    
    enum VideoStyle: String, CaseIterable, Identifiable {
        case cinematic = "电影感"
        case slideshow = "幻灯片"
        case kenBurns = "Ken Burns"
        case minimal = "极简风"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .cinematic: return "电影级转场效果，专业质感"
            case .slideshow: return "简洁的图片切换"
            case .kenBurns: return "缓慢缩放平移，纪录片风格"
            case .minimal: return "干净简约，突出内容"
            }
        }
        
        var icon: String {
            switch self {
            case .cinematic: return "film"
            case .slideshow: return "rectangle.on.rectangle"
            case .kenBurns: return "arrow.up.left.and.arrow.down.right"
            case .minimal: return "square.dashed"
            }
        }
    }
    
    enum VideoDuration: String, CaseIterable, Identifiable {
        case short = "15 秒"
        case medium = "30 秒"
        case long = "60 秒"
        
        var id: String { rawValue }
        
        var seconds: Double {
            switch self {
            case .short: return 15
            case .medium: return 30
            case .long: return 60
            }
        }
    }
    
    enum AspectRatio: String, CaseIterable, Identifiable {
        case square = "1:1 (正方形)"
        case portrait = "9:16 (竖屏)"
        case landscape = "16:9 (横屏)"
        case story = "4:5 (Instagram)"
        
        var id: String { rawValue }
        
        var size: CGSize {
            switch self {
            case .square: return CGSize(width: 1080, height: 1080)
            case .portrait: return CGSize(width: 1080, height: 1920)
            case .landscape: return CGSize(width: 1920, height: 1080)
            case .story: return CGSize(width: 1080, height: 1350)
            }
        }
    }
    
    enum TransitionStyle: String, CaseIterable, Identifiable {
        case fade = "淡入淡出"
        case dissolve = "溶解"
        case slide = "滑动"
        case zoom = "缩放"
        
        var id: String { rawValue }
    }
}

/// 梦境视频
struct DreamVideo: Identifiable, Codable {
    var id: UUID = UUID()
    var dreamId: UUID
    var title: String
    var filePath: String
    var thumbnailPath: String
    var duration: Double
    var style: String
    var aspectRatio: String
    var createdAt: Date
    var fileSize: Int64
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, dreamId, title, filePath, thumbnailPath, duration, style, aspectRatio, createdAt, fileSize, isFavorite
    }
}

// MARK: - 视频生成服务

/// 梦境视频生成服务
@MainActor
class DreamVideoService: ObservableObject {
    static let shared = DreamVideoService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var generationStatus: String = ""
    @Published var videos: [DreamVideo] = []
    @Published var lastError: String?
    
    private var renderers: [UUID: AVAssetWriter] = [:]
    
    private init() {
        loadVideos()
    }
    
    private func loadVideos() {
        videos = getAllVideos()
    }
    
    // MARK: - 视频生成
    
    /// 生成梦境视频
    func generateVideo(for dream: Dream, config: DreamVideoConfig) async throws -> DreamVideo {
        guard !isGenerating else {
            throw VideoError.alreadyGenerating
        }
        
        isGenerating = true
        generationProgress = 0.0
        generationStatus = "准备生成视频..."
        
        defer {
            isGenerating = false
            generationProgress = 0.0
        }
        
        do {
            // 1. 获取梦境的 AI 图片
            generationStatus = "加载梦境图片..."
            generationProgress = 0.1
            let images = try await loadDreamImages(for: dream)
            
            guard !images.isEmpty else {
                throw VideoError.noImages
            }
            
            // 2. 准备音频 (如果启用)
            var audioURL: URL? = nil
            if config.includeMusic {
                generationStatus = "准备背景音乐..."
                generationProgress = 0.2
                audioURL = try await prepareBackgroundMusic(for: dream, duration: config.duration.seconds)
            }
            
            // 3. 创建视频合成器
            generationStatus = "创建视频合成器..."
            generationProgress = 0.3
            let outputURL = getOutputURL(for: dream)
            let thumbnailURL = getThumbnailURL(for: dream)
            
            // 4. 渲染视频
            generationStatus = "渲染视频中... (0%)"
            generationProgress = 0.4
            
            try await renderVideo(
                images: images,
                audioURL: audioURL,
                outputURL: outputURL,
                thumbnailURL: thumbnailURL,
                config: config,
                dream: dream
            )
            
            // 5. 保存视频记录
            generationStatus = "保存视频..."
            generationProgress = 0.95
            
            let video = DreamVideo(
                dreamId: dream.id,
                title: dream.title,
                filePath: outputURL.path,
                thumbnailPath: thumbnailURL.path,
                duration: config.duration.seconds,
                style: config.style.rawValue,
                aspectRatio: config.aspectRatio.rawValue,
                createdAt: Date(),
                fileSize: try getFileSize(at: outputURL)
            )
            
            saveVideo(video)
            
            generationStatus = "视频生成完成！✨"
            generationProgress = 1.0
            
            return video
            
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - 图片加载
    
    private func loadDreamImages(for dream: Dream) async throws -> [UIImage] {
        var images: [UIImage] = []
        
        // 从 DreamArtGallery 加载 AI 生成的图片
        if let artService = try? await AIArtService.shared.getArtwork(for: dream.id) {
            if let imageData = artService.imageData,
               let image = UIImage(data: imageData) {
                images.append(image)
            }
        }
        
        // 如果没有 AI 图片，创建文本图片
        if images.isEmpty {
            let textImage = createTextImage(from: dream)
            images.append(textImage)
        }
        
        // 至少需要一张图片
        if images.isEmpty {
            let placeholder = createPlaceholderImage(for: dream)
            images.append(placeholder)
        }
        
        return images
    }
    
    // MARK: - 音频准备
    
    private func prepareBackgroundMusic(for dream: Dream, duration: Double) async throws -> URL? {
        // 尝试获取已有的梦境音乐
        let musicService = DreamMusicService.shared
        if let music = musicService.getMusic(for: dream.id) {
            if let filePath = music.filePath,
               FileManager.default.fileExists(atPath: filePath) {
                return URL(fileURLWithPath: filePath)
            }
        }
        
        // 如果没有，尝试生成新的音乐
        // 这里简化处理，返回 nil 表示无音乐
        return nil
    }
    
    // MARK: - 视频渲染
    
    private func renderVideo(
        images: [UIImage],
        audioURL: URL?,
        outputURL: URL,
        thumbnailURL: URL,
        config: DreamVideoConfig,
        dream: Dream
    ) async throws {
        let outputSize = config.aspectRatio.size
        let fps: Double = 30
        let duration = config.duration.seconds
        let totalFrames = Int(duration * fps)
        
        // 创建视频写入器
        guard let videoWriter = AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            throw VideoError.writerCreationFailed
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: outputSize.width,
            AVVideoHeightKey: outputSize.height
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: outputSize.width,
                kCVPixelBufferHeightKey as String: outputSize.height
            ]
        )
        
        videoWriter.add(videoWriterInput)
        
        // 添加音频轨道 (如果有)
        var audioWriterInput: AVAssetWriterInput?
        if let audioURL = audioURL {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000
            ]
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            input.expectsMediaDataInRealTime = false
            audioWriterInput = input
            videoWriter.add(input)
        }
        
        // 开始写入
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        // 渲染每一帧
        let imageDuration = duration / Double(images.count)
        var currentFrame = 0
        
        for (imageIndex, image) in images.enumerated() {
            let imageStartFrame = Int(Double(imageIndex) * imageDuration * fps)
            let imageEndFrame = Int(Double(imageIndex + 1) * imageDuration * fps)
            
            for frameNum in imageStartFrame..<min(imageEndFrame, totalFrames) {
                guard videoWriterInput.isReadyForMoreMediaData else { continue }
                
                let progress = Double(frameNum) / Double(totalFrames)
                await MainActor.run {
                    self.generationProgress = 0.4 + (progress * 0.5)
                    self.generationStatus = "渲染视频中... (\(Int(progress * 100))%)"
                }
                
                let frameTime = CMTimeMake(value: Int64(frameNum), timescale: Int32(fps))
                
                // 根据风格处理图片
                let processedImage = processImage(
                    image,
                    for: config.style,
                    at: config.aspectRatio.size,
                    progress: Double(frameNum - imageStartFrame) / Double(max(1, imageEndFrame - imageStartFrame)),
                    dream: dream
                )
                
                if let pixelBuffer = createPixelBuffer(from: processedImage, size: outputSize) {
                    pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
                }
                
                currentFrame += 1
            }
        }
        
        // 完成视频写入
        videoWriterInput.markAsFinished()
        audioWriterInput?.markAsFinished()
        
        await withCheckedContinuation { continuation in
            videoWriter.finishWriting {
                continuation.resume()
            }
        }
        
        guard videoWriter.status == .completed else {
            throw VideoError.renderingFailed(videoWriter.error?.localizedDescription ?? "未知错误")
        }
        
        // 生成缩略图
        if let firstImage = images.first {
            saveThumbnail(firstImage, to: thumbnailURL)
        }
    }
    
    // MARK: - 图片处理
    
    private func processImage(
        _ image: UIImage,
        for style: DreamVideoConfig.VideoStyle,
        at size: CGSize,
        progress: Double,
        dream: Dream
    ) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return image
        }
        
        // 背景色
        UIColor.black.setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        // 根据风格绘制图片
        var drawRect = CGRect(origin: .zero, size: size)
        
        switch style {
        case .kenBurns:
            // Ken Burns 效果：缓慢缩放
            let scale: CGFloat = 1.0 + (progress * 0.2)
            let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
            let offsetX = (scaledSize.width - size.width) * progress * 0.5
            let offsetY = (scaledSize.height - size.height) * progress * 0.5
            drawRect = CGRect(
                x: -offsetX,
                y: -offsetY,
                width: scaledSize.width,
                height: scaledSize.height
            )
            
        case .cinematic, .slideshow, .minimal:
            // 保持宽高比填充
            let imageRatio = image.size.width / image.size.height
            let rectRatio = size.width / size.height
            
            if imageRatio > rectRatio {
                let newHeight = size.width / imageRatio
                let offsetY = (size.height - newHeight) / 2
                drawRect = CGRect(x: 0, y: offsetY, width: size.width, height: newHeight)
            } else {
                let newWidth = size.height * imageRatio
                let offsetX = (size.width - newWidth) / 2
                drawRect = CGRect(x: offsetX, y: 0, width: newWidth, height: size.height)
            }
        }
        
        // 绘制图片
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: drawRect)
        }
        
        // 添加文字叠加层
        if progress < 0.3 {
            // 标题显示在前 30% 时间
            let title = dream.title
            let titleFont = UIFont.boldSystemFont(ofSize: 32)
            let titleRect = CGRect(x: 20, y: size.height - 100, width: size.width - 40, height: 80)
            
            let titleParagraphStyle = NSMutableParagraphStyle()
            titleParagraphStyle.alignment = .left
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white,
                .paragraphStyle: titleParagraphStyle,
                .shadow: NSShadow.shadowWith(color: UIColor.black.withAlphaComponent(0.8), offset: CGSize(width: 2, height: 2), blurRadius: 4)
            ]
            
            title.draw(in: titleRect, withAttributes: titleAttributes)
        }
        
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image
        }
        
        return resultImage
    }
    
    private func createPixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    
    // MARK: - 辅助方法
    
    private func createTextImage(from dream: Dream) -> UIImage {
        let size = CGSize(width: 1080, height: 1920)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 渐变背景
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        let colors = [
            UIColor.systemIndigo.withAlphaComponent(0.9).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.9).cgColor,
            UIColor.systemPink.withAlphaComponent(0.9).cgColor
        ]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.5, 1]) else {
            return UIImage()
        }
        
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
        
        // 绘制标题
        let title = dream.title
        let titleFont = UIFont.boldSystemFont(ofSize: 48)
        let titleRect = CGRect(x: 40, y: 200, width: size.width - 80, height: 200)
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: titleParagraphStyle,
            .shadow: NSShadow.shadowWith(color: UIColor.black.withAlphaComponent(0.5), offset: CGSize(width: 2, height: 2), blurRadius: 4)
        ]
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // 绘制日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy 年 MM 月 dd 日"
        let dateString = dateFormatter.string(from: dream.createdAt)
        
        let dateFont = UIFont.systemFont(ofSize: 24)
        let dateRect = CGRect(x: 40, y: 420, width: size.width - 80, height: 60)
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8),
            .paragraphStyle: titleParagraphStyle
        ]
        
        dateString.draw(in: dateRect, withAttributes: dateAttributes)
        
        // 绘制梦境内容摘要
        let content = dream.content.prefix(200) + (dream.content.count > 200 ? "..." : "")
        let contentFont = UIFont.systemFont(ofSize: 28)
        let contentRect = CGRect(x: 40, y: 520, width: size.width - 80, height: 400)
        
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.9),
            .paragraphStyle: titleParagraphStyle,
            .shadow: NSShadow.shadowWith(color: UIColor.black.withAlphaComponent(0.3), offset: CGSize(width: 1, height: 1), blurRadius: 2)
        ]
        
        content.draw(in: contentRect, withAttributes: contentAttributes)
        
        // DreamLog 标识
        let logoFont = UIFont.boldSystemFont(ofSize: 20)
        let logoRect = CGRect(x: 40, y: size.height - 100, width: size.width - 80, height: 40)
        
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: logoFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        
        "🌙 DreamLog".draw(in: logoRect, withAttributes: logoAttributes)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return UIImage()
        }
        
        return image
    }
    
    private func createPlaceholderImage(for dream: Dream) -> UIImage {
        return createTextImage(from: dream)
    }
    
    private func saveThumbnail(_ image: UIImage, to url: URL) {
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: url)
        }
    }
    
    private func getOutputURL(for dream: Dream) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosPath = documentsPath.appendingPathComponent("DreamVideos", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: videosPath, withIntermediateDirectories: true)
        
        let filename = "DreamLog_\(dream.title.prefix(20).replacingOccurrences(of: "/", with: "_"))_\(Date().timeIntervalSince1970).mp4"
        return videosPath.appendingPathComponent(filename)
    }
    
    private func getThumbnailURL(for dream: Dream) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnailsPath = documentsPath.appendingPathComponent("DreamVideoThumbnails", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: thumbnailsPath, withIntermediateDirectories: true)
        
        let filename = "Thumb_\(dream.title.prefix(20).replacingOccurrences(of: "/", with: "_"))_\(Date().timeIntervalSince1970).jpg"
        return thumbnailsPath.appendingPathComponent(filename)
    }
    
    private func getFileSize(at url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
    
    // MARK: - 数据持久化
    
    private func getAllVideos() -> [DreamVideo] {
        // 从文件系统扫描视频
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosPath = documentsPath.appendingPathComponent("DreamVideos", isDirectory: true)
        
        guard let enumerator = FileManager.default.enumerator(at: videosPath, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]) else {
            return []
        }
        
        var videos: [DreamVideo] = []
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "mp4" {
                let attributes = try? fileURL.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                let video = DreamVideo(
                    dreamId: UUID(),
                    title: fileURL.deletingPathExtension().lastPathComponent,
                    filePath: fileURL.path,
                    thumbnailPath: "",
                    duration: 30,
                    style: "未知",
                    aspectRatio: "未知",
                    createdAt: attributes?.creationDate ?? Date(),
                    fileSize: attributes?.fileSize as? Int64 ?? 0
                )
                videos.append(video)
            }
        }
        
        return videos.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func saveVideo(_ video: DreamVideo) {
        videos.insert(video, at: 0)
    }
    
    func deleteVideo(_ video: DreamVideo) {
        try? FileManager.default.removeItem(atPath: video.filePath)
        try? FileManager.default.removeItem(atPath: video.thumbnailPath)
        videos.removeAll { $0.id == video.id }
    }
    
    func getVideo(by id: UUID) -> DreamVideo? {
        videos.first { $0.id == id }
    }
}

// MARK: - 错误类型

enum VideoError: LocalizedError {
    case alreadyGenerating
    case noImages
    case writerCreationFailed
    case renderingFailed(String)
    case audioLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .alreadyGenerating:
            return "正在生成另一个视频，请稍候"
        case .noImages:
            return "没有找到梦境图片，请先生成 AI 绘画"
        case .writerCreationFailed:
            return "无法创建视频写入器"
        case .renderingFailed(let reason):
            return "视频渲染失败：\(reason)"
        case .audioLoadFailed:
            return "无法加载背景音乐"
        }
    }
}

// MARK: - NSShadow 扩展

extension NSShadow {
    static func shadowWith(color: UIColor, offset: CGSize, blurRadius: CGFloat) -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = color
        shadow.shadowOffset = offset
        shadow.shadowBlurRadius = blurRadius
        return shadow
    }
}
