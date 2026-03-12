//
//  DreamARVideoMode.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - AR Video Mode Service

/// AR 视频模式服务 - 提供专业 AR 视频录制功能
@MainActor
class DreamARVideoMode: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前选中的视频滤镜
    @Published var selectedFilter: ARVideoFilter = .none
    
    /// 滤镜强度 (0-100)
    @Published var filterIntensity: Double = 100
    
    /// 录制质量
    @Published var recordingQuality: VideoQuality = .high
    
    /// 录制时长 (秒)
    @Published var recordingDuration: Int = 30
    
    /// 是否正在录制
    @Published var isRecording: Bool = false
    
    /// 录制剩余时间
    @Published var recordingTimeRemaining: Int = 0
    
    /// 慢动作模式
    @Published var isSlowMotionMode: Bool = false
    
    /// 慢动作倍率
    @Published var slowMotionRate: SlowMotionRate = .x2
    
    /// 延时摄影模式
    @Published var isTimeLapseMode: Bool = false
    
    /// 延时摄影间隔 (秒)
    @Published var timeLapseInterval: TimeInterval = 1.0
    
    /// 是否启用空间音频
    @Published var isSpatialAudioEnabled: Bool = true
    
    /// 当前视频库
    @Published var videos: [ARVideoCapture] = []
    
    /// 录制进度 (0-1)
    @Published var recordingProgress: Double = 0
    
    // MARK: - Filters
    
    /// 可用视频滤镜列表
    let availableFilters: [ARVideoFilter] = [
        .none,
        .vintage,
        .blackWhite,
        .sepia,
        .dramatic,
        .fade,
        .instant,
        .chrome,
        .mono,
        .tonal,
        .linear,
        .warmth,
        .cool,
        .dreamy,
        .starry,
        .neon,
        .cyberpunk
    ]
    
    // MARK: - Private Properties
    
    private let context = CIContext()
    private let videoService = DreamARVideoService.shared
    private var recordingTimer: Timer?
    private var timeLapseTimer: Timer?
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var isPaused: Bool = false
    private var capturedFrames: [UIImage] = []
    
    // MARK: - Singleton
    
    static let shared = DreamARVideoMode()
    
    private init() {}
    
    // MARK: - Video Recording
    
    /// 开始录制视频
    func startRecording(from arView: ARView, dream: Dream?) async {
        guard !isRecording else { return }
        
        isRecording = true
        recordingTimeRemaining = recordingDuration
        recordingProgress = 0
        capturedFrames.removeAll()
        
        // 根据模式计算实际帧率
        let targetFrameRate = calculateTargetFrameRate()
        
        // 配置 ARView 进行录制
        await setupARViewForRecording(arView, frameRate: targetFrameRate)
        
        // 开始录制计时
        startRecordingTimer()
        
        // 延时摄影模式特殊处理
        if isTimeLapseMode {
            startTimeLapseRecording(from: arView, dream: dream)
        }
    }
    
    /// 停止录制视频
    func stopRecording(from arView: ARView, dream: Dream?) async -> ARVideoCapture? {
        guard isRecording else { return nil }
        
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        timeLapseTimer?.invalidate()
        timeLapseTimer = nil
        
        // 生成视频
        let video = await createVideo(from: arView, dream: dream)
        
        if let video = video {
            videos.insert(video, at: 0)
        }
        
        return video
    }
    
    /// 暂停/继续录制
    func togglePause() {
        isPaused.toggle()
    }
    
    /// 取消录制
    func cancelRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        timeLapseTimer?.invalidate()
        timeLapseTimer = nil
        capturedFrames.removeAll()
        recordingProgress = 0
    }
    
    // MARK: - Private Recording Methods
    
    /// 计算目标帧率
    private func calculateTargetFrameRate() -> Int {
        if isSlowMotionMode {
            switch slowMotionRate {
            case .x2: return 120
            case .x4: return 240
            case .x8: return 240
            }
        } else if isTimeLapseMode {
            return 30 // 输出帧率
        } else {
            return 60 // 正常录制
        }
    }
    
    /// 配置 ARView 进行录制
    private func setupARViewForRecording(_ arView: ARView, frameRate: Int) async {
        // 配置 AR 会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameRate = CAPFrameRate(rawValue: frameRate) ?? .fps60
        
        // 启用空间音频
        if isSpatialAudioEnabled {
            configuration.audioRenderingMode = .spatial
        }
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    /// 开始录制计时器
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                if !self.isPaused {
                    self.recordingTimeRemaining -= 1
                    self.recordingProgress = 1.0 - (Double(self.recordingTimeRemaining) / Double(self.recordingDuration))
                    
                    if self.recordingTimeRemaining <= 0 {
                        timer.invalidate()
                        // 自动停止录制
                    }
                }
            }
        }
    }
    
    /// 开始延时摄影录制
    private func startTimeLapseRecording(from arView: ARView, dream: Dream?) {
        timeLapseTimer = Timer.scheduledTimer(withTimeInterval: timeLapseInterval, repeats: true) { [weak self] timer in
            guard let self = self, !self.isPaused else { return }
            
            Task { @MainActor in
                if let snapshot = await arView.snapshot() {
                    self.capturedFrames.append(snapshot)
                }
                
                self.recordingTimeRemaining -= Int(self.timeLapseInterval)
                self.recordingProgress = 1.0 - (Double(self.recordingTimeRemaining) / Double(self.recordingDuration))
                
                if self.recordingTimeRemaining <= 0 {
                    timer.invalidate()
                    Task {
                        _ = await self.stopRecording(from: arView, dream: dream)
                    }
                }
            }
        }
    }
    
    /// 创建视频
    private func createVideo(from arView: ARView, dream: Dream?) async -> ARVideoCapture? {
        guard !capturedFrames.isEmpty else {
            // 非延时摄影模式，使用普通录制
            return await createNormalVideo(from: arView, dream: dream)
        }
        
        // 延时摄影模式：将捕获的帧合成视频
        return await createTimeLapseVideo(dream: dream)
    }
    
    /// 创建普通视频
    private func createNormalVideo(from arView: ARView, dream: Dream?) async -> ARVideoCapture? {
        // 简化实现：实际项目中需要使用 AVAssetWriter
        guard let snapshot = await arView.snapshot() else { return nil }
        
        let processedImage = await applyFilters(to: snapshot)
        
        let video = ARVideoCapture(
            id: UUID(),
            thumbnail: processedImage,
            filter: selectedFilter,
            filterIntensity: filterIntensity,
            duration: Double(recordingDuration - recordingTimeRemaining),
            frameRate: calculateTargetFrameRate(),
            isSlowMotion: isSlowMotionMode,
            slowMotionRate: isSlowMotionMode ? slowMotionRate : nil,
            isTimeLapse: isTimeLapseMode,
            timeLapseInterval: isTimeLapseMode ? timeLapseInterval : nil,
            spatialAudioEnabled: isSpatialAudioEnabled,
            dreamId: dream?.id,
            dreamTitle: dream?.title,
            captureDate: Date(),
            quality: recordingQuality
        )
        
        await videoService.saveVideo(video)
        return video
    }
    
    /// 创建延时摄影视频
    private func createTimeLapseVideo(dream: Dream?) async -> ARVideoCapture? {
        guard !capturedFrames.isEmpty else { return nil }
        
        // 应用滤镜到所有帧
        var processedFrames: [UIImage] = []
        for frame in capturedFrames {
            let processed = await applyFilters(to: frame)
            processedFrames.append(processed)
        }
        
        let video = ARVideoCapture(
            id: UUID(),
            thumbnail: processedFrames.first,
            filter: selectedFilter,
            filterIntensity: filterIntensity,
            duration: Double(capturedFrames.count) * timeLapseInterval,
            frameRate: 30,
            isSlowMotion: false,
            slowMotionRate: nil,
            isTimeLapse: true,
            timeLapseInterval: timeLapseInterval,
            spatialAudioEnabled: false,
            dreamId: dream?.id,
            dreamTitle: dream?.title,
            captureDate: Date(),
            quality: recordingQuality
        )
        
        await videoService.saveVideo(video)
        return video
    }
    
    // MARK: - Filter Application
    
    /// 应用滤镜到图像
    func applyFilters(to image: UIImage) async -> UIImage {
        guard selectedFilter != .none,
              let ciImage = CIImage(image: image) else {
            return image
        }
        
        let filter = createFilter(for: selectedFilter)
        filter.inputImage = ciImage
        
        // 设置滤镜参数
        configureFilter(filter, intensity: filterIntensity)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 创建 Core Image 滤镜
    private func createFilter(for videoFilter: ARVideoFilter) -> CIFilter {
        switch videoFilter {
        case .none:
            return CIFilter()
        case .vintage:
            let filter = CIFilter.sepiaTone()
            filter.intensity = 0.5
            return filter
        case .blackWhite:
            return CIFilter.photoEffectMono()
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.intensity = 0.8
            return filter
        case .dramatic:
            return CIFilter.photoEffectDramatic()
        case .fade:
            return CIFilter.photoEffectFade()
        case .instant:
            return CIFilter.photoEffectInstant()
        case .chrome:
            return CIFilter.photoEffectChrome()
        case .mono:
            return CIFilter.photoEffectMono()
        case .tonal:
            return CIFilter.photoEffectTonal()
        case .linear:
            return CIFilter.photoEffectProcess()
        case .warmth:
            return CIFilter.photoEffectTransfer()
        case .cool:
            let filter = CIFilter.colorTemperature()
            filter.temperature = 0.5
            return filter
        case .dreamy:
            let filter = CIFilter.gaussianBlur()
            filter.radius = 2.0
            return filter
        case .starry:
            let filter = CIFilter.gaussianBlur()
            filter.radius = 1.5
            return filter
        case .neon:
            let filter = CIFilter.posterize()
            filter.levels = 4
            return filter
        case .cyberpunk:
            let filter = CIFilter.colorControls()
            filter.saturation = 1.5
            filter.contrast = 1.3
            return filter
        }
    }
    
    /// 配置滤镜参数
    private func configureFilter(_ filter: CIFilter, intensity: Double) {
        let intensityValue = Float(intensity / 100.0)
        
        if filter.responds(to: #selector(setter: CIFilter.intensity)) {
            filter.setValue(intensityValue, forKey: "intensity")
        }
        
        if filter.responds(to: #selector(setter: CIFilter.amount)) {
            filter.setValue(intensityValue, forKey: "amount")
        }
        
        if filter.responds(to: #selector(setter: CIFilter.radius)) {
            filter.setValue(intensityValue * 5.0, forKey: "radius")
        }
        
        if filter.responds(to: #selector(setter: CIFilter.levels)) {
            filter.setValue(Int(3 + intensityValue * 5), forKey: "levels")
        }
        
        if filter.responds(to: #selector(setter: CIFilter.saturation)) {
            filter.setValue(1.0 + intensityValue * 0.5, forKey: "saturation")
        }
        
        if filter.responds(to: #selector(setter: CIFilter.contrast)) {
            filter.setValue(1.0 + intensityValue * 0.3, forKey: "contrast")
        }
    }
    
    // MARK: - Video Management
    
    /// 删除视频
    func deleteVideo(_ video: ARVideoCapture) async {
        await videoService.deleteVideo(video)
        videos.removeAll { $0.id == video.id }
    }
    
    /// 导出视频
    func exportVideo(_ video: ARVideoCapture, to url: URL) async -> Bool {
        return await videoService.exportVideo(video, to: url)
    }
    
    /// 分享视频
    func shareVideo(_ video: ARVideoCapture) -> UIActivityViewController {
        return videoService.createShareViewController(for: video)
    }
    
    /// 清除所有视频
    func clearAllVideos() async {
        for video in videos {
            await videoService.deleteVideo(video)
        }
        videos.removeAll()
    }
}

// MARK: - AR Video Filter

/// AR 视频滤镜
enum ARVideoFilter: String, CaseIterable, Identifiable {
    case none = "原片"
    case vintage = "复古"
    case blackWhite = "黑白"
    case sepia = "棕褐色"
    case dramatic = "戏剧"
    case fade = "褪色"
    case instant = "即时"
    case chrome = "铬色"
    case mono = "单色"
    case tonal = "色调"
    case linear = "线性"
    case warmth = "暖色"
    case cool = "冷色"
    case dreamy = "梦幻"
    case starry = "星空"
    case neon = "霓虹"
    case cyberpunk = "赛博朋克"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "video"
        case .vintage: return "film"
        case .blackWhite: return "circle.lefthalf.filled"
        case .sepia: return "scope"
        case .dramatic: return "theatermasks"
        case .fade: return "cloud.fog"
        case .instant: return "camera.fill"
        case .chrome: return "metal"
        case .mono: return "circle.grid.cross"
        case .tonal: return "paintpalette"
        case .linear: return "ruler"
        case .warmth: return "sun.max"
        case .cool: return "snowflake"
        case .dreamy: return "sparkles"
        case .starry: return "star.fill"
        case .neon: return "light.beacon.min"
        case .cyberpunk: return "cpu"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .vintage: return .orange
        case .blackWhite: return .black
        case .sepia: return .brown
        case .dramatic: return .red
        case .fade: return .pink
        case .instant: return .yellow
        case .chrome: return .cyan
        case .mono: return .purple
        case .tonal: return .indigo
        case .linear: return .blue
        case .warmth: return .orange
        case .cool: return .blue
        case .dreamy: return .pink
        case .starry: return .purple
        case .neon: return .green
        case .cyberpunk: return .pink
        }
    }
}

// MARK: - Video Quality

/// 视频质量
enum VideoQuality: String, CaseIterable, Identifiable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case ultra = "超高"
    
    var id: String { rawValue }
    
    var resolution: String {
        switch self {
        case .low: return "720p"
        case .medium: return "1080p"
        case .high: return "1080p"
        case .ultra: return "4K"
        }
    }
    
    var frameRate: Int {
        switch self {
        case .low: return 30
        case .medium: return 30
        case .high: return 60
        case .ultra: return 60
        }
    }
    
    var bitrate: Int {
        switch self {
        case .low: return 5_000_000
        case .medium: return 10_000_000
        case .high: return 20_000_000
        case .ultra: return 50_000_000
        }
    }
}

// MARK: - Slow Motion Rate

/// 慢动作倍率
enum SlowMotionRate: String, CaseIterable, Identifiable {
    case x2 = "2x"
    case x4 = "4x"
    case x8 = "8x"
    
    var id: String { rawValue }
    
    var captureFrameRate: Int {
        switch self {
        case .x2: return 120
        case .x4: return 240
        case .x8: return 240
        }
    }
    
    var playbackFrameRate: Int {
        return 30 // 标准播放帧率
    }
}

// MARK: - AR Video Capture

/// AR 视频捕获
struct ARVideoCapture: Identifiable, Codable {
    let id: UUID
    let thumbnail: UIImage?
    let filter: ARVideoFilter
    let filterIntensity: Double
    let duration: TimeInterval
    let frameRate: Int
    let isSlowMotion: Bool
    let slowMotionRate: SlowMotionRate?
    let isTimeLapse: Bool
    let timeLapseInterval: TimeInterval?
    let spatialAudioEnabled: Bool
    let dreamId: UUID?
    let dreamTitle: String?
    let captureDate: Date
    let quality: VideoQuality
    
    // MARK: - Computed Properties
    
    var fileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "DreamLog_Video_\(formatter.string(from: captureDate)).mp4"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: captureDate)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var modeDescription: String {
        if isSlowMotion, let rate = slowMotionRate {
            return "慢动作 \(rate.rawValue)"
        } else if isTimeLapse {
            return "延时摄影"
        } else {
            return "普通视频"
        }
    }
}

// MARK: - AR Video Service

/// AR 视频存储服务
@MainActor
class DreamARVideoService {
    
    static let shared = DreamARVideoService()
    
    private let fileManager = FileManager.default
    private let videosDirectory: URL
    
    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        videosDirectory = documentsPath.appendingPathComponent("ARVideos", isDirectory: true)
        try? fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
    }
    
    /// 保存视频
    func saveVideo(_ video: ARVideoCapture) async {
        // 保存缩略图
        if let thumbnail = video.thumbnail,
           let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
            let thumbnailURL = videosDirectory.appendingPathComponent(video.fileName.replacingOccurrences(of: ".mp4", with: "_thumb.jpg"))
            try? jpegData.write(to: thumbnailURL)
        }
        
        // 视频文件元数据保存
        let metadataURL = videosDirectory.appendingPathComponent(video.fileName.replacingOccurrences(of: ".mp4", with: ".json"))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(video) {
            try? data.write(to: metadataURL)
        }
    }
    
    /// 删除视频
    func deleteVideo(_ video: ARVideoCapture) async {
        let videoURL = videosDirectory.appendingPathComponent(video.fileName)
        let thumbnailURL = videosDirectory.appendingPathComponent(video.fileName.replacingOccurrences(of: ".mp4", with: "_thumb.jpg"))
        let metadataURL = videosDirectory.appendingPathComponent(video.fileName.replacingOccurrences(of: ".mp4", with: ".json"))
        
        try? fileManager.removeItem(at: videoURL)
        try? fileManager.removeItem(at: thumbnailURL)
        try? fileManager.removeItem(at: metadataURL)
    }
    
    /// 导出视频
    func exportVideo(_ video: ARVideoCapture, to url: URL) async -> Bool {
        // 简化实现
        return true
    }
    
    /// 创建分享视图控制器
    func createShareViewController(for video: ARVideoCapture) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [video.fileName], // 实际应该是视频数据
            applicationActivities: nil
        )
        return activityVC
    }
    
    /// 获取所有视频
    func getAllVideos() async -> [ARVideoCapture] {
        // 从文件系统加载视频元数据
        return []
    }
}
