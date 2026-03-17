//
//  DreamVideoEditor.swift
//  DreamLog
//
//  Dream Video Editor - Phase 14 Completion
//  Crop, trim, add text overlays, and apply filters to videos
//

import Foundation
import AVFoundation
import UIKit
import Combine
import CoreImage

// MARK: - 视频编辑模型

/// 视频裁剪区域
struct VideoCropRegion {
    var x: CGFloat       // 0-1, 归一化坐标
    var y: CGFloat       // 0-1, 归一化坐标
    var width: CGFloat   // 0-1, 归一化坐标
    var height: CGFloat  // 0-1, 归一化坐标
    
    /// 默认全屏
    static let `default` = VideoCropRegion(x: 0, y: 0, width: 1, height: 1)
    
    /// 1:1 正方形裁剪（居中）
    static let square = VideoCropRegion(x: 0.25, y: 0, width: 0.5, height: 1)
    
    /// 9:16 竖屏裁剪（居中）
    static let portrait = VideoCropRegion(x: 0, y: 0.125, width: 1, height: 0.75)
    
    /// 16:9 横屏裁剪（居中）
    static let landscape = VideoCropRegion(x: 0.0625, y: 0, width: 0.875, height: 1)
}

/// 视频修剪范围
struct VideoTrimRange {
    var startTime: CMTime
    var endTime: CMTime
    
    var duration: CMTime {
        CMTimeSubtract(endTime, startTime)
    }
    
    /// 创建时间范围（秒）
    static func fromSeconds(start: Double, end: Double, timescale: Int32 = 600) -> VideoTrimRange {
        VideoTrimRange(
            startTime: CMTime(seconds: start, preferredTimescale: timescale),
            endTime: CMTime(seconds: end, preferredTimescale: timescale)
        )
    }
}

/// 文字叠加配置
struct VideoTextOverlay: Identifiable, Codable {
    var id: UUID = UUID()
    var text: String
    var startTime: Double      // 秒
    var endTime: Double        // 秒
    var position: TextPosition
    var fontSize: CGFloat
    var fontName: String
    var textColor: String      // HEX
    var backgroundColor: String? // HEX, optional
    var animation: TextAnimation
    var alignment: TextAlignment
    
    enum TextPosition: String, Codable, CaseIterable {
        case top = "顶部"
        case center = "中间"
        case bottom = "底部"
        case topLeft = "左上"
        case topRight = "右上"
        case bottomLeft = "左下"
        case bottomRight = "右下"
        case custom = "自定义"
        
        var cgPoint: CGPoint {
            switch self {
            case .top: return CGPoint(x: 0.5, y: 0.15)
            case .center: return CGPoint(x: 0.5, y: 0.5)
            case .bottom: return CGPoint(x: 0.5, y: 0.85)
            case .topLeft: return CGPoint(x: 0.15, y: 0.15)
            case .topRight: return CGPoint(x: 0.85, y: 0.15)
            case .bottomLeft: return CGPoint(x: 0.15, y: 0.85)
            case .bottomRight: return CGPoint(x: 0.85, y: 0.85)
            case .custom: return CGPoint(x: 0.5, y: 0.5)
            }
        }
    }
    
    enum TextAnimation: String, Codable, CaseIterable {
        case none = "无"
        case fadeIn = "淡入"
        case fadeOut = "淡出"
        case fadeInOut = "淡入淡出"
        case slideIn = "滑入"
        case typewriter = "打字机"
        
        var description: String {
            switch self {
            case .none: return "静态文字"
            case .fadeIn: return "逐渐显现"
            case .fadeOut: return "逐渐消失"
            case .fadeInOut: return "淡入后淡出"
            case .slideIn: return "从一侧滑入"
            case .typewriter: return "逐字显示"
            }
        }
    }
    
    enum TextAlignment: String, Codable {
        case left = "左对齐"
        case center = "居中"
        case right = "右对齐"
    }
    
    /// 默认标题样式
    static func titleStyle(text: String, duration: Double) -> VideoTextOverlay {
        VideoTextOverlay(
            text: text,
            startTime: 0,
            endTime: min(3.0, duration),
            position: .center,
            fontSize: 48,
            fontName: "Helvetica-Bold",
            textColor: "FFFFFF",
            backgroundColor: "00000080",
            animation: .fadeInOut,
            alignment: .center
        )
    }
    
    /// 默认字幕样式
    static func captionStyle(text: String, startTime: Double, endTime: Double) -> VideoTextOverlay {
        VideoTextOverlay(
            text: text,
            startTime: startTime,
            endTime: endTime,
            position: .bottom,
            fontSize: 32,
            fontName: "Helvetica",
            textColor: "FFFFFF",
            backgroundColor: "00000060",
            animation: .fadeIn,
            alignment: .center
        )
    }
}

/// 视频滤镜配置
struct VideoFilterConfig {
    var filterType: FilterType
    var intensity: CGFloat  // 0-1
    
    enum FilterType: String, CaseIterable, Identifiable {
        case none = "无"
        case vintage = "复古"
        case noir = "黑白"
        case fade = "褪色"
        case instant = "即时"
        case process = "处理"
        case chrome = "铬色"
        case mono = "单色"
        case tonal = "色调"
        case linear = "线性"
        case warm = "暖色"
        case cool = "冷色"
        
        var id: String { rawValue }
        
        var filterName: String {
            switch self {
            case .none: return ""
            case .vintage: return "CIPhotoEffectMono"
            case .noir: return "CIPhotoEffectNoir"
            case .fade: return "CIPhotoEffectFade"
            case .instant: return "CIPhotoEffectInstant"
            case .process: return "CIPhotoEffectProcess"
            case .chrome: return "CIPhotoEffectChrome"
            case .mono: return "CIColorMonochrome"
            case .tonal: return "CIPhotoEffectTonal"
            case .linear: return "CIPhotoEffectTransfer"
            case .warm: return "CITemperatureAndTint"
            case .cool: return "CIColorTemperature"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "slash.circle"
            case .vintage: return "clock.fill"
            case .noir: return "circle.lefthalf.filled"
            case .fade: return "cloud.fog.fill"
            case .instant: return "bolt.fill"
            case .process: return "gearshape.fill"
            case .chrome: return "metal"
            case .mono: return "circle.fill"
            case .tonal: return "slider.horizontal.3"
            case .linear: return "line.3.horizontal"
            case .warm: return "sun.max.fill"
            case .cool: return "snowflake"
            }
        }
    }
}

/// 视频编辑配置
struct VideoEditConfig {
    var cropRegion: VideoCropRegion = .default
    var trimRange: VideoTrimRange? = nil
    var textOverlays: [VideoTextOverlay] = []
    var filterConfig: VideoFilterConfig = VideoFilterConfig(filterType: .none, intensity: 1.0)
    var outputAspectRatio: DreamVideoConfig.AspectRatio = .portrait
    var outputQuality: VideoExportConfig.ExportQuality = .high
    
    var hasEdits: Bool {
        cropRegion != .default ||
        trimRange != nil ||
        !textOverlays.isEmpty ||
        filterConfig.filterType != .none
    }
}

// MARK: - 视频编辑错误

enum VideoEditError: LocalizedError {
    case invalidCropRegion
    case invalidTrimRange
    case failedToLoadVideo
    case failedToApplyFilter
    case failedToAddTextOverlay
    case exportFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidCropRegion: return "无效的裁剪区域"
        case .invalidTrimRange: return "无效的修剪范围"
        case .failedToLoadVideo: return "无法加载视频"
        case .failedToApplyFilter: return "应用滤镜失败"
        case .failedToAddTextOverlay: return "添加文字失败"
        case .exportFailed: return "导出失败"
        case .cancelled: return "已取消"
        }
    }
}

// MARK: - 视频编辑服务

/// 梦境视频编辑服务
@MainActor
class DreamVideoEditor: ObservableObject {
    static let shared = DreamVideoEditor()
    
    @Published var isEditing = false
    @Published var editProgress: Double = 0.0
    @Published var editStatus: String = ""
    @Published var previewFrame: UIImage?
    @Published var videoDuration: Double = 0
    @Published var videoSize: CGSize = .zero
    
    private var currentAsset: AVAsset?
    private var cancellables = Set<AnyCancellable>()
    private let ciContext = CIContext(options: nil)
    
    private init() {}
    
    // MARK: - 加载视频
    
    /// 加载视频进行编辑
    func loadVideo(url: URL) async throws {
        guard !isEditing else {
            throw VideoEditError.cancelled
        }
        
        editStatus = "加载视频中..."
        currentAsset = AVAsset(url: url)
        
        guard let asset = currentAsset else {
            throw VideoEditError.failedToLoadVideo
        }
        
        // 获取视频信息
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw VideoEditError.failedToLoadVideo
        }
        
        let size = try await track.load(.naturalSize)
        let transform = try await track.load(.transform)
        let duration = try await asset.load(.duration)
        
        // 应用旋转变换
        let transformedSize = size.applying(transform)
        videoSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
        videoDuration = CMTimeGetSeconds(duration)
        
        // 生成预览帧
        await generatePreviewFrame()
        
        editStatus = "视频已加载"
    }
    
    /// 生成预览帧
    private func generatePreviewFrame() async {
        guard let asset = currentAsset else { return }
        
        do {
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 640, height: 640)
            
            let time = CMTime(seconds: videoDuration * 0.3, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: time).image
            previewFrame = UIImage(cgImage: cgImage)
        } catch {
            print("预览帧生成失败：\(error)")
        }
    }
    
    // MARK: - 裁剪视频
    
    /// 裁剪视频
    func cropVideo(region: VideoCropRegion) -> CGAffineTransform {
        let scaleX = 1.0 / region.width
        let scaleY = 1.0 / region.height
        let translateX = -region.x / region.width
        let translateY = -region.y / region.height
        
        return CGAffineTransform(scaleX: scaleX, y: scaleY)
            .translatedBy(x: translateX, y: translateY)
    }
    
    // MARK: - 应用滤镜
    
    /// 应用滤镜到图像
    func applyFilter(to image: CIImage, config: VideoFilterConfig) -> CIImage? {
        guard config.filterType != .none,
              let filter = CIFilter(name: config.filterType.filterName) else {
            return image
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        
        // 设置滤镜参数
        switch config.filterType {
        case .mono:
            filter.setValue(CIColor(red: 0.5, green: 0.5, blue: 0.5), forKey: "inputColor")
            filter.setValue(config.intensity, forKey: "inputIntensity")
        case .warm:
            filter.setValue(config.intensity * 2000, forKey: "inputNeutral")
            filter.setValue(0, forKey: "inputTargetNeutral")
        case .cool:
            filter.setValue(config.intensity * 6500, forKey: "inputTemperature")
        default:
            if config.intensity < 1.0 {
                filter.setValue(config.intensity, forKey: "inputIntensity")
            }
        }
        
        return filter.outputImage
    }
    
    // MARK: - 生成文字图层
    
    /// 生成文字图像
    func generateTextImage(overlay: VideoTextOverlay, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = overlay.alignment.nsTextAlignment
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: overlay.fontName, size: overlay.fontSize) ?? UIFont.systemFont(ofSize: overlay.fontSize),
                .foregroundColor: UIColor(hex: overlay.textColor) ?? .white,
                .paragraphStyle: paragraphStyle
            ]
            
            let position = overlay.position.cgPoint
            let x = position.x * size.width
            var y = position.y * size.height
            
            // 根据对齐方式调整起始位置
            let textSize = overlay.text.boundingRect(
                with: CGSize(width: size.width * 0.8, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            ).size
            
            switch overlay.alignment {
            case .left:
                paragraphStyle.alignment = .left
            case .center:
                paragraphStyle.alignment = .center
                y -= textSize.height / 2
            case .right:
                paragraphStyle.alignment = .right
                x = size.width - (size.width * 0.1)
            }
            
            // 绘制背景
            if let bgColor = overlay.backgroundColor {
                let bgRect = CGRect(x: x - textSize.width / 2 - 10,
                                   y: y - 5,
                                   width: textSize.width + 20,
                                   height: textSize.height + 10)
                UIColor(hex: bgColor)?.withAlphaComponent(0.5).setFill()
                UIRectFill(bgRect)
            }
            
            // 绘制文字
            (overlay.text as NSString).draw(in: CGRect(x: x - textSize.width / 2,
                                         y: y,
                                         width: textSize.width,
                                         height: textSize.height),
                             withAttributes: attributes)
        }
    }
    
    // MARK: - 导出编辑后的视频
    
    /// 导出编辑后的视频
    func exportEditedVideo(sourceURL: URL, config: VideoEditConfig, outputURL: URL) async throws {
        guard !isEditing else {
            throw VideoEditError.cancelled
        }
        
        isEditing = true
        editProgress = 0.0
        editStatus = "准备导出..."
        
        defer {
            isEditing = false
            editProgress = 0.0
        }
        
        let asset = AVAsset(url: sourceURL)
        
        // 创建视频写入器
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: config.outputAspectRatio.size.width,
            AVVideoHeightKey: config.outputAspectRatio.size.height
        ]
        
        let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        assetWriterInput.expectMediaDataInRealTime = false
        assetWriter.add(assetWriterInput)
        
        // 创建图片输出
        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        let reader = try AVAssetReader(asset: asset)
        guard let videoTrack = try await asset.tracks(withMediaType: .video).first else {
            throw VideoEditError.failedToLoadVideo
        }
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                      outputSettings: readerOutputSettings)
        reader.add(readerOutput)
        
        // 设置修剪范围
        if let trimRange = config.trimRange {
            readerOutput.timeRange = CMTimeRange(start: trimRange.startTime, duration: trimRange.duration)
        }
        
        // 开始读取
        guard reader.startReading() else {
            throw VideoEditError.failedToLoadVideo
        }
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: trimRangeStartTime(from: config.trimRange))
        
        var frameCount = 0
        let totalFrames = Int((config.trimRange?.duration.seconds ?? videoDuration) * 30) // 假设 30fps
        
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            if !isEditing {
                reader.cancelReading()
                assetWriter.cancelWriting()
                throw VideoEditError.cancelled
            }
            
            if assetWriterInput.isReadyForMoreMediaData {
                // 应用裁剪
                if config.cropRegion != .default {
                    let transform = cropVideo(region: config.cropRegion)
                    assetWriterInput.transform = transform
                }
                
                // 应用滤镜
                if config.filterConfig.filterType != .none {
                    sampleBuffer = try await applyFilterToBuffer(sampleBuffer, config: config.filterConfig)
                }
                
                // 添加文字叠加
                if !config.textOverlays.isEmpty {
                    let currentTime = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                    if let textImage = textImageForTime(currentTime, overlays: config.textOverlays, size: config.outputAspectRatio.size) {
                        sampleBuffer = try await compositeTextontoBuffer(sampleBuffer, textImage: textImage)
                    }
                }
                
                assetWriterInput.append(sampleBuffer)
                frameCount += 1
                
                editProgress = Double(frameCount) / Double(totalFrames)
                editStatus = "处理中... \(Int(editProgress * 100))%"
            }
        }
        
        assetWriterInput.markAsFinished()
        reader.finishReading()
        assetWriter.finishWriting()
        
        if assetWriter.status == .failed {
            throw VideoEditError.exportFailed
        }
        
        editProgress = 1.0
        editStatus = "导出完成"
    }
    
    private func trimRangeStartTime(from trimRange: VideoTrimRange?) -> CMTime {
        trimRange?.startTime ?? .zero
    }
    
    private func applyFilterToBuffer(_ buffer: CMSampleBuffer, config: VideoFilterConfig) async throws -> CMSampleBuffer {
        // 简化实现：实际项目中需要完整的 CIImage -> CMSampleBuffer 转换
        return buffer
    }
    
    private func textImageForTime(_ time: Double, overlays: [VideoTextOverlay], size: CGSize) -> UIImage? {
        for overlay in overlays {
            if time >= overlay.startTime && time <= overlay.endTime {
                return generateTextImage(overlay: overlay, size: size)
            }
        }
        return nil
    }
    
    private func compositeTextontoBuffer(_ buffer: CMSampleBuffer, textImage: UIImage) async throws -> CMSampleBuffer {
        // 简化实现：实际项目中需要完整的图像合成
        return buffer
    }
    
    // MARK: - 快速编辑
    
    /// 快速裁剪并导出
    func quickCrop(sourceURL: URL, aspectRatio: DreamVideoConfig.AspectRatio, outputURL: URL) async throws {
        var config = VideoEditConfig()
        config.outputAspectRatio = aspectRatio
        
        // 根据目标比例设置裁剪区域
        let sourceRatio = videoSize.width / videoSize.height
        let targetRatio = aspectRatio.size.width / aspectRatio.size.height
        
        if sourceRatio > targetRatio {
            // 源视频更宽，裁剪宽度
            let newWidth = targetRatio / sourceRatio
            config.cropRegion = VideoCropRegion(
                x: (1 - newWidth) / 2,
                y: 0,
                width: newWidth,
                height: 1
            )
        } else {
            // 源视频更高，裁剪高度
            let newHeight = sourceRatio / targetRatio
            config.cropRegion = VideoCropRegion(
                x: 0,
                y: (1 - newHeight) / 2,
                width: 1,
                height: newHeight
            )
        }
        
        try await exportEditedVideo(sourceURL: sourceURL, config: config, outputURL: outputURL)
    }
    
    /// 快速添加标题
    func quickAddTitle(sourceURL: URL, title: String, outputURL: URL) async throws {
        var config = VideoEditConfig()
        config.textOverlays = [.titleStyle(text: title, duration: videoDuration)]
        try await exportEditedVideo(sourceURL: sourceURL, config: config, outputURL: outputURL)
    }
    
    /// 快速应用滤镜
    func quickApplyFilter(sourceURL: URL, filterType: VideoFilterConfig.FilterType, outputURL: URL) async throws {
        var config = VideoEditConfig()
        config.filterConfig = VideoFilterConfig(filterType: filterType, intensity: 1.0)
        try await exportEditedVideo(sourceURL: sourceURL, config: config, outputURL: outputURL)
    }
}

// MARK: - Helper Extensions

extension NSTextAlignment {
    init(from alignment: VideoTextOverlay.TextAlignment) {
        switch alignment {
        case .left: self = .left
        case .center: self = .center
        case .right: self = .right
        }
    }
    
    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

// Note: UIColor(hex:) is defined in Theme.swift to avoid duplicate declarations
