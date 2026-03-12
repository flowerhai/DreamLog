//
//  DreamARPhotoMode.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - AR Photo Mode Service

/// AR 照片模式服务 - 提供专业 AR 截图功能
@MainActor
class DreamARPhotoMode: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前选中的滤镜
    @Published var selectedFilter: ARPhotoFilter = .none
    
    /// 滤镜强度 (0-100)
    @Published var filterIntensity: Double = 100
    
    /// 是否启用景深效果
    @Published var isDepthEffectEnabled: Bool = false
    
    /// 景深模糊强度 (0-10)
    @Published var depthBlurIntensity: Double = 5.0
    
    /// 是否显示网格
    @Published var showGrid: Bool = false
    
    /// 定时器秒数
    @Published var timerSeconds: Int = 0
    
    /// 是否正在倒计时
    @Published var isCountdownActive: Bool = false
    
    /// 倒计时剩余时间
    @Published var countdownRemaining: Int = 0
    
    /// 连拍模式
    @Published var isBurstMode: Bool = false
    
    /// 连拍数量
    @Published var burstCount: Int = 3
    
    /// 当前照片库
    @Published var photos: [ARPhotoCapture] = []
    
    // MARK: - Filters
    
    /// 可用滤镜列表
    let availableFilters: [ARPhotoFilter] = [
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
        .starry
    ]
    
    // MARK: - Private Properties
    
    private let context = CIContext()
    private let photoService = DreamARPhotoService.shared
    private var countdownTimer: Timer?
    
    // MARK: - Singleton
    
    static let shared = DreamARPhotoMode()
    
    private init() {}
    
    // MARK: - Photo Capture
    
    /// 拍摄照片
    func capturePhoto(from arView: ARView, dream: Dream?) async -> ARPhotoCapture? {
        // 处理倒计时
        if timerSeconds > 0 {
            await startCountdown()
        }
        
        guard let snapshot = await arView.snapshot() else {
            return nil
        }
        
        // 应用滤镜
        let processedImage = await applyFilters(to: snapshot)
        
        // 创建照片对象
        let photo = ARPhotoCapture(
            id: UUID(),
            image: processedImage,
            originalImage: snapshot,
            filter: selectedFilter,
            filterIntensity: filterIntensity,
            depthEffectEnabled: isDepthEffectEnabled,
            depthBlurIntensity: depthBlurIntensity,
            dreamId: dream?.id,
            dreamTitle: dream?.title,
            captureDate: Date()
        )
        
        // 保存照片
        await photoService.savePhoto(photo)
        photos.insert(photo, at: 0)
        
        // 连拍模式
        if isBurstMode && burstCount > 1 {
            await captureBurst(from: arView, dream: dream, count: burstCount)
        }
        
        return photo
    }
    
    /// 连拍
    private func captureBurst(from arView: ARView, dream: Dream?, count: Int) async {
        var delay = 0.0
        let interval: Double = 0.3 // 每张间隔 300ms
        
        for i in 1..<count {
            delay = Double(i) * interval
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            
            guard let snapshot = await arView.snapshot() else { continue }
            let processedImage = await applyFilters(to: snapshot)
            
            let photo = ARPhotoCapture(
                id: UUID(),
                image: processedImage,
                originalImage: snapshot,
                filter: selectedFilter,
                filterIntensity: filterIntensity,
                depthEffectEnabled: isDepthEffectEnabled,
                depthBlurIntensity: depthBlurIntensity,
                dreamId: dream?.id,
                dreamTitle: dream?.title,
                captureDate: Date(),
                isBurstPhoto: true,
                burstSequenceId: photos.first?.id
            )
            
            await photoService.savePhoto(photo)
            photos.insert(photo, at: 0)
        }
    }
    
    // MARK: - Countdown
    
    /// 开始倒计时
    func startCountdown() async {
        guard timerSeconds > 0 else { return }
        
        isCountdownActive = true
        countdownRemaining = timerSeconds
        
        await withCheckedContinuation { continuation in
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    continuation.resume()
                    return
                }
                
                Task { @MainActor in
                    self.countdownRemaining -= 1
                    
                    if self.countdownRemaining <= 0 {
                        timer.invalidate()
                        self.isCountdownActive = false
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// 取消倒计时
    func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountdownActive = false
        countdownRemaining = 0
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
        
        // 应用景深效果
        var finalImage = UIImage(cgImage: cgImage)
        if isDepthEffectEnabled {
            finalImage = await applyDepthEffect(to: finalImage)
        }
        
        return finalImage
    }
    
    /// 创建 Core Image 滤镜
    private func createFilter(for photoFilter: ARPhotoFilter) -> CIFilter {
        switch photoFilter {
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
    }
    
    /// 应用景深效果
    func applyDepthEffect(to image: UIImage) async -> UIImage {
        // 简化实现：应用中心到边缘的渐变模糊
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = depthBlurIntensity
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Photo Management
    
    /// 删除照片
    func deletePhoto(_ photo: ARPhotoCapture) async {
        await photoService.deletePhoto(photo)
        photos.removeAll { $0.id == photo.id }
    }
    
    /// 导出照片
    func exportPhoto(_ photo: ARPhotoCapture, to url: URL) async -> Bool {
        return await photoService.exportPhoto(photo, to: url)
    }
    
    /// 分享照片
    func sharePhoto(_ photo: ARPhotoCapture) -> UIActivityViewController {
        return photoService.createShareViewController(for: photo)
    }
    
    /// 清除所有照片
    func clearAllPhotos() async {
        for photo in photos {
            await photoService.deletePhoto(photo)
        }
        photos.removeAll()
    }
}

// MARK: - AR Photo Filter

/// AR 照片滤镜
enum ARPhotoFilter: String, CaseIterable, Identifiable {
    case none = "原图"
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
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "photo"
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
        }
    }
}

// MARK: - AR Photo Capture

/// AR 照片捕获
struct ARPhotoCapture: Identifiable, Codable {
    let id: UUID
    let image: UIImage
    let originalImage: UIImage
    let filter: ARPhotoFilter
    let filterIntensity: Double
    let depthEffectEnabled: Bool
    let depthBlurIntensity: Double
    let dreamId: UUID?
    let dreamTitle: String?
    let captureDate: Date
    var isBurstPhoto: Bool = false
    var burstSequenceId: UUID?
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id, filter, filterIntensity, depthEffectEnabled, depthBlurIntensity
        case dreamId, dreamTitle, captureDate, isBurstPhoto, burstSequenceId
        // 图像数据单独处理
    }
    
    // MARK: - Computed Properties
    
    var fileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "DreamLog_\(formatter.string(from: captureDate)).jpg"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: captureDate)
    }
}

// MARK: - AR Photo Service

/// AR 照片存储服务
@MainActor
class DreamARPhotoService {
    
    static let shared = DreamARPhotoService()
    
    private let fileManager = FileManager.default
    private let photosDirectory: URL
    
    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        photosDirectory = documentsPath.appendingPathComponent("ARPhotos", isDirectory: true)
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }
    
    /// 保存照片
    func savePhoto(_ photo: ARPhotoCapture) async {
        let fileURL = photosDirectory.appendingPathComponent(photo.fileName)
        
        if let jpegData = photo.image.jpegData(compressionQuality: 0.9) {
            try? jpegData.write(to: fileURL)
        }
    }
    
    /// 删除照片
    func deletePhoto(_ photo: ARPhotoCapture) async {
        let fileURL = photosDirectory.appendingPathComponent(photo.fileName)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// 导出照片
    func exportPhoto(_ photo: ARPhotoCapture, to url: URL) async -> Bool {
        guard let jpegData = photo.image.jpegData(compressionQuality: 1.0) else {
            return false
        }
        
        do {
            try jpegData.write(to: url)
            return true
        } catch {
            return false
        }
    }
    
    /// 创建分享视图控制器
    func createShareViewController(for photo: ARPhotoCapture) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [photo.image],
            applicationActivities: nil
        )
        return activityVC
    }
    
    /// 获取所有照片
    func getAllPhotos() async -> [ARPhotoCapture] {
        // 从文件系统加载照片元数据
        // 简化实现：返回空数组
        return []
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// 从 ARView 捕获快照
    static func from(arView: ARView) async -> UIImage? {
        await arView.snapshot()
    }
}
