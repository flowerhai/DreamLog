//
//  DreamArtStyleTransferService.swift
//  DreamLog
//
//  Phase 81: 梦境 AI 绘画增强 - 艺术风格迁移与滤镜系统
//  Created: 2026-03-21
//

import Foundation
import SwiftData
import CoreImage
import CoreImage.CIFilterBuiltins

@ModelActor
actor DreamArtStyleTransferService {
    
    // MARK: - Properties
    
    private let context: CIContext
    private let cacheDirectory: URL
    private var styleTransferCache: [String: Data] = [:]
    
    // MARK: - Initialization
    
    init() {
        self.context = CIContext(options: [.useSoftwareRenderer: false])
        
        // 设置缓存目录
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = caches.appendingPathComponent("StyleTransfer", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Core Style Transfer
    
    /// 应用艺术风格到图像
    func applyStyleTransfer(
        to imageData: Data,
        config: StyleTransferConfig
    ) async throws -> Data {
        guard let ciImage = CIImage(data: imageData) else {
            throw StyleTransferError.invalidImage
        }
        
        let startTime = Date()
        
        // 根据风格类型应用不同的滤镜组合
        let styledImage = try await processStyle(ciImage, config: config)
        
        // 转换为 PNG
        guard let cgImage = context.createCGImage(styledImage, from: styledImage.extent) else {
            throw StyleTransferError.processingFailed
        }
        
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw StyleTransferError.processingFailed
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw StyleTransferError.processingFailed
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        print("风格迁移完成，耗时：\(String(format: "%.2f", processingTime))秒")
        
        return outputData as Data
    }
    
    /// 混合两种艺术风格
    func mixStyles(
        imageData: Data,
        config: StyleMixConfig
    ) async throws -> Data {
        guard let ciImage = CIImage(data: imageData) else {
            throw StyleTransferError.invalidImage
        }
        
        // 分别应用两种风格
        let config1 = StyleTransferConfig(
            styleType: config.style1,
            intensity: config.mixRatio < 0.5 ? 0.7 : 0.3,
            preserveContent: 0.5
        )
        let config2 = StyleTransferConfig(
            styleType: config.style2,
            intensity: config.mixRatio > 0.5 ? 0.7 : 0.3,
            preserveContent: 0.5
        )
        
        let image1 = try await processStyle(ciImage, config: config1)
        let image2 = try await processStyle(ciImage, config: config2)
        
        // 混合两种风格
        let blendedImage = blendImages(image1, image2, ratio: config.mixRatio, mode: config.blendMode)
        
        // 转换为输出
        guard let cgImage = context.createCGImage(blendedImage, from: blendedImage.extent) else {
            throw StyleTransferError.processingFailed
        }
        
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw StyleTransferError.processingFailed
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw StyleTransferError.processingFailed
        }
        
        return outputData as Data
    }
    
    // MARK: - Style Processing
    
    private func processStyle(_ ciImage: CIImage, config: StyleTransferConfig) async throws -> CIImage {
        var result = ciImage
        
        // 根据风格应用不同的 Core Image 滤镜
        switch config.styleType {
        case .impressionist:
            result = applyImpressionistFilter(to: result, intensity: config.intensity)
        case .postImpressionist:
            result = applyPostImpressionistFilter(to: result, intensity: config.intensity)
        case .cubist:
            result = applyCubistFilter(to: result, intensity: config.intensity)
        case .surrealist:
            result = applySurrealistFilter(to: result, intensity: config.intensity)
        case .abstractExpressionist:
            result = applyAbstractFilter(to: result, intensity: config.intensity)
        case .popArt:
            result = applyPopArtFilter(to: result, intensity: config.intensity)
        case .ukiyoe:
            result = applyUkiyoeFilter(to: result, intensity: config.intensity)
        case .inkWash:
            result = applyInkWashFilter(to: result, intensity: config.intensity)
        case .oilPainting:
            result = applyOilPaintingFilter(to: result, intensity: config.intensity)
        case .watercolor:
            result = applyWatercolorFilter(to: result, intensity: config.intensity)
        case .sketch:
            result = applySketchFilter(to: result, intensity: config.intensity)
        case .comic:
            result = applyComicFilter(to: result, intensity: config.intensity)
        case .pixelArt:
            result = applyPixelArtFilter(to: result, intensity: config.intensity)
        case .cyberpunk:
            result = applyCyberpunkFilter(to: result, intensity: config.intensity)
        case .dreamy:
            result = applyDreamyFilter(to: result, intensity: config.intensity)
        case .custom:
            if let customData = config.styleType == .custom ? nil : nil {
                // 自定义风格处理
                result = applyCustomFilter(to: result, configData: customData)
            }
        }
        
        // 色彩调整
        if config.colorTransfer {
            result = adjustColorTransfer(to: result, intensity: config.intensity)
        }
        
        return result
    }
    
    // MARK: - Filter Implementations
    
    private func applyImpressionistFilter(to image: CIImage, intensity: Double) -> CIImage {
        let filter = CIFilter.pointillize()
        filter.inputImage = image
        filter.radius = 10 * intensity
        return filter.outputImage ?? image
    }
    
    private func applyPostImpressionistFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 梵高风格：增强色彩饱和度 + 笔触效果
        var result = image
        
        // 色彩增强
        let saturationFilter = CIFilter.colorControls()
        saturationFilter.inputImage = result
        saturationFilter.saturation = 1.5 * intensity
        if let output = saturationFilter.outputImage {
            result = output
        }
        
        // 边缘增强
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = result
        edgeFilter.intensity = 5 * intensity
        if let edges = edgeFilter.outputImage {
            let blendFilter = CIFilter.sourceOverCompositing()
            blendFilter.backgroundImage = result
            blendFilter.inputImage = edges
            if let blended = blendFilter.outputImage {
                result = blended
            }
        }
        
        return result
    }
    
    private func applyCubistFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 立体主义：几何分割
        let filter = CIFilter.crystallize()
        filter.inputImage = image
        filter.radius = 20 * (1 - intensity) + 5
        return filter.outputImage ?? image
    }
    
    private func applySurrealistFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 超现实主义：扭曲效果
        var result = image
        
        let twistFilter = CIFilter.twirlDistortion()
        twistFilter.inputImage = result
        twistFilter.radius = 200 * intensity
        twistFilter.angle = 3.14 * intensity
        if let output = twistFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applyAbstractFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 抽象表现主义：强烈色彩对比
        var result = image
        
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = result
        contrastFilter.contrast = 1.5 * intensity
        if let output = contrastFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applyPopArtFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 波普艺术：高饱和度 + 色彩分离
        var result = image
        
        let saturationFilter = CIFilter.colorControls()
        saturationFilter.inputImage = result
        saturationFilter.saturation = 2.0 * intensity
        if let output = saturationFilter.outputImage {
            result = output
        }
        
        // 色彩量化效果
        let posterizeFilter = CIFilter.colorPosterize()
        posterizeFilter.inputImage = result
        posterizeFilter.levels = 4
        if let output = posterizeFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applyUkiyoeFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 浮世绘：线条强化 + 特定色彩调
        var result = image
        
        // 边缘检测
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = result
        edgeFilter.intensity = 3
        if let edges = edgeFilter.outputImage {
            let blendFilter = CIFilter.sourceOverCompositing()
            blendFilter.backgroundImage = result
            blendFilter.inputImage = edges
            if let blended = blendFilter.outputImage {
                result = blended
            }
        }
        
        // 色彩调整（偏青绿色调）
        let colorFilter = CIFilter.colorControls()
        colorFilter.inputImage = result
        colorFilter.saturation = 0.8
        if let output = colorFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applyInkWashFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 水墨画：去色 + 边缘强化
        var result = image
        
        // 转为黑白
        let monoFilter = CIFilter.photoEffectMono()
        monoFilter.inputImage = result
        if let output = monoFilter.outputImage {
            result = output
        }
        
        // 边缘强化
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = result
        edgeFilter.intensity = 2
        if let edges = edgeFilter.outputImage {
            let blendFilter = CIFilter.sourceOverCompositing()
            blendFilter.backgroundImage = result
            blendFilter.inputImage = edges
            if let blended = blendFilter.outputImage {
                result = blended
            }
        }
        
        return result
    }
    
    private func applyOilPaintingFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 油画：纹理 + 色彩丰富
        let filter = CIFilter.oilPainting()
        filter.inputImage = image
        filter.level = 5
        filter.noiseLevel = 0.5 * intensity
        return filter.outputImage ?? image
    }
    
    private func applyWatercolorFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 水彩：柔和边缘 + 色彩渗透
        var result = image
        
        // 高斯模糊
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = result
        blurFilter.radius = 2 * intensity
        if let output = blurFilter.outputImage {
            result = output
        }
        
        // 色彩增强
        let saturationFilter = CIFilter.colorControls()
        saturationFilter.inputImage = result
        saturationFilter.saturation = 1.3
        if let output = saturationFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applySketchFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 素描：边缘检测 + 去色
        var result = image
        
        // 边缘检测
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = result
        edgeFilter.intensity = 5 * intensity
        if let edges = edgeFilter.outputImage {
            result = edges
        }
        
        // 去色
        let monoFilter = CIFilter.photoEffectMono()
        monoFilter.inputImage = result
        if let output = monoFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applyComicFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 漫画风格：边缘强化 + 色彩简化
        var result = image
        
        // 边缘强化
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = result
        edgeFilter.intensity = 8 * intensity
        if let edges = edgeFilter.outputImage {
            let blendFilter = CIFilter.sourceOverCompositing()
            blendFilter.backgroundImage = result
            blendFilter.inputImage = edges
            if let blended = blendFilter.outputImage {
                result = blended
            }
        }
        
        // 色彩简化
        let posterizeFilter = CIFilter.colorPosterize()
        posterizeFilter.inputImage = result
        posterizeFilter.levels = 6
        if let output = posterizeFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applyPixelArtFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 像素艺术：降低分辨率 + 最近邻插值
        let filter = CIFilter.pixellate()
        filter.inputImage = image
        filter.scale = 10 * (1 - intensity) + 2
        return filter.outputImage ?? image
    }
    
    private func applyCyberpunkFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 赛博朋克：霓虹色彩 + 高对比
        var result = image
        
        // 色彩调整（偏蓝紫）
        let colorFilter = CIFilter.colorControls()
        colorFilter.inputImage = result
        colorFilter.saturation = 1.5
        colorFilter.contrast = 1.3
        if let output = colorFilter.outputImage {
            result = output
        }
        
        // 添加色调
        let toneFilter = CIFilter.colorMonochrome()
        toneFilter.inputImage = result
        toneFilter.color = CIColor(red: 0.2, green: 0.1, blue: 0.5, alpha: 1.0)
        toneFilter.intensity = 0.3 * intensity
        if let output = toneFilter.outputImage {
            let blendFilter = CIFilter.sourceOverCompositing()
            blendFilter.backgroundImage = result
            blendFilter.inputImage = output
            if let blended = blendFilter.outputImage {
                result = blended
            }
        }
        
        return result
    }
    
    private func applyDreamyFilter(to image: CIImage, intensity: Double) -> CIImage {
        // 梦幻风格：柔焦 + 光晕
        var result = image
        
        // 高斯模糊
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = result
        blurFilter.radius = 5 * intensity
        if let blurred = blurFilter.outputImage {
            // 与原图混合
            let blendFilter = CIFilter.sourceOverCompositing()
            blendFilter.backgroundImage = result
            blendFilter.inputImage = blurred
            if let blended = blendFilter.outputImage {
                result = blended
            }
        }
        
        // 色彩增强
        let saturationFilter = CIFilter.colorControls()
        saturationFilter.inputImage = result
        saturationFilter.saturation = 1.2
        if let output = saturationFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func applyCustomFilter(to image: CIImage, configData: Data?) -> CIImage {
        // 自定义风格处理
        return image
    }
    
    private func adjustColorTransfer(to image: CIImage, intensity: Double) -> CIImage {
        var result = image
        
        let saturationFilter = CIFilter.colorControls()
        saturationFilter.inputImage = result
        saturationFilter.saturation = 1.0 + (0.5 * intensity)
        if let output = saturationFilter.outputImage {
            result = output
        }
        
        return result
    }
    
    private func blendImages(_ image1: CIImage, _ image2: CIImage, ratio: Double, mode: StyleMixConfig.BlendMode) -> CIImage {
        let filter: CIFilter
        
        switch mode {
        case .linear:
            filter = CIFilter.sourceOverCompositing()
            filter.inputImage = image1
            filter.backgroundImage = image2
        case .overlay:
            filter = CIFilter.overlayBlendMode()
            filter.inputImage = image1
            filter.backgroundImage = image2
        case .multiply:
            filter = CIFilter.multiplyBlendMode()
            filter.inputImage = image1
            filter.backgroundImage = image2
        case .screen:
            filter = CIFilter.screenBlendMode()
            filter.inputImage = image1
            filter.backgroundImage = image2
        case .softLight:
            filter = CIFilter.softLightBlendMode()
            filter.inputImage = image1
            filter.backgroundImage = image2
        }
        
        return filter.outputImage ?? image1
    }
    
    // MARK: - CRUD Operations
    
    /// 保存风格迁移记录
    func saveStyleTransfer(
        dreamId: UUID,
        originalImageId: String,
        styleType: String,
        styleIntensity: Double,
        resultImageId: String,
        processingTime: TimeInterval
    ) async throws -> DreamArtStyleTransfer {
        let transfer = DreamArtStyleTransfer(
            dreamId: dreamId,
            originalImageId: originalImageId,
            styleType: styleType,
            styleIntensity: styleIntensity,
            resultImageId: resultImageId,
            processingTime: processingTime
        )
        
        modelContext.insert(transfer)
        try modelContext.save()
        
        return transfer
    }
    
    /// 获取风格迁移历史
    func getStyleTransfers(
        dreamId: UUID? = nil,
        limit: Int = 50,
        sortBy: SortOption = .createdAt
    ) async throws -> [DreamArtStyleTransfer] {
        var descriptor = FetchDescriptor<DreamArtStyleTransfer>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        if let dreamId = dreamId {
            descriptor.predicate = #Predicate<DreamArtStyleTransfer> { $0.dreamId == dreamId }
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 切换收藏状态
    func toggleFavorite(id: UUID) async throws {
        guard let transfer = try modelContext.fetch(
            FetchDescriptor<DreamArtStyleTransfer>(
                predicate: #Predicate<DreamArtStyleTransfer> { $0.id == id }
            )
        ).first else {
            throw StyleTransferError.notFound
        }
        
        transfer.isFavorite.toggle()
        try modelContext.save()
    }
    
    /// 删除风格迁移记录
    func deleteStyleTransfer(id: UUID) async throws {
        guard let transfer = try modelContext.fetch(
            FetchDescriptor<DreamArtStyleTransfer>(
                predicate: #Predicate<DreamArtStyleTransfer> { $0.id == id }
            )
        ).first else {
            throw StyleTransferError.notFound
        }
        
        modelContext.delete(transfer)
        try modelContext.save()
    }
    
    // MARK: - Statistics
    
    /// 获取统计信息
    func getStatistics() async throws -> StyleTransferStats {
        let allTransfers = try modelContext.fetch(FetchDescriptor<DreamArtStyleTransfer>())
        
        let totalCount = allTransfers.count
        let favoriteCount = allTransfers.filter { $0.isFavorite }.count
        
        // 按风格类型分组
        var byStyleType: [String: Int] = [:]
        for transfer in allTransfers {
            byStyleType[transfer.styleType, default: 0] += 1
        }
        
        // 平均处理时间
        let averageProcessingTime = totalCount > 0
            ? allTransfers.map { $0.processingTime }.reduce(0, +) / Double(totalCount)
            : 0
        
        // 最常用风格
        let mostUsedStyle = byStyleType.max(by: { $0.value < $1.value })
            .flatMap { ArtStyleType(rawValue: $0.key) }
        
        // 最近迁移
        let recentTransfers = allTransfers
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
            .map { $0 }
        
        return StyleTransferStats(
            totalCount: totalCount,
            favoriteCount: favoriteCount,
            byStyleType: byStyleType,
            averageProcessingTime: averageProcessingTime,
            mostUsedStyle: mostUsedStyle,
            recentTransfers: recentTransfers
        )
    }
    
    // MARK: - Cache Management
    
    /// 清理缓存
    func clearCache() async {
        styleTransferCache.removeAll()
        
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// MARK: - Errors

enum StyleTransferError: LocalizedError {
    case invalidImage
    case processingFailed
    case notFound
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "无效的图像数据"
        case .processingFailed: return "风格迁移处理失败"
        case .notFound: return "未找到风格迁移记录"
        case .cacheError: return "缓存操作失败"
        }
    }
}

// MARK: - Sort Options

extension DreamArtStyleTransferService {
    enum SortOption {
        case createdAt
        case processingTime
        case styleType
    }
}
