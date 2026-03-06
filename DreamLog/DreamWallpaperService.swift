//
//  DreamWallpaperService.swift
//  DreamLog
//
//  梦境壁纸生成服务 - 将梦境转换为精美的手机壁纸
//

import Foundation
import SwiftUI
import UIKit

// MARK: - 壁纸模型

/// 梦境壁纸
struct DreamWallpaper: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var dreamId: UUID
    var imageUrl: String
    var style: WallpaperStyle
    var size: WallpaperSize
    var createdAt: Date
    var isFavorite: Bool = false
    
    enum WallpaperStyle: String, Codable, CaseIterable {
        case minimalist = "简约"
        case artistic = "艺术"
        case gradient = "渐变"
        case nature = "自然"
        case abstract = "抽象"
        case cosmic = "宇宙"
        
        var description: String {
            switch self {
            case .minimalist: return "简洁干净的设计"
            case .artistic: return "艺术化的视觉效果"
            case .gradient: return "流畅的渐变色彩"
            case .nature: return "自然元素融合"
            case .abstract: return "抽象几何图案"
            case .cosmic: return "星空宇宙主题"
            }
        }
    }
    
    enum WallpaperSize: String, Codable, CaseIterable {
        case iphone15ProMax = "iPhone 15 Pro Max"
        case iphone15Pro = "iPhone 15 Pro"
        case iphone15 = "iPhone 15"
        case iphone14ProMax = "iPhone 14 Pro Max"
        case iphone14Pro = "iPhone 14 Pro"
        case iphone14 = "iPhone 14"
        case universal = "通用尺寸"
        
        var resolution: CGSize {
            switch self {
            case .iphone15ProMax: return CGSize(width: 1290, height: 2796)
            case .iphone15Pro: return CGSize(width: 1179, height: 2556)
            case .iphone15: return CGSize(width: 1170, height: 2532)
            case .iphone14ProMax: return CGSize(width: 1290, height: 2796)
            case .iphone14Pro: return CGSize(width: 1179, height: 2556)
            case .iphone14: return CGSize(width: 1170, height: 2532)
            case .universal: return CGSize(width: 1170, height: 2532)
            }
        }
        
        var aspectRatio: String {
            switch self {
            case .iphone15ProMax, .iphone14ProMax: return "19.5:9"
            case .iphone15Pro, .iphone15, .iphone14Pro, .iphone14: return "19.5:9"
            case .universal: return "19.5:9"
            }
        }
    }
}

// MARK: - 壁纸生成服务

@MainActor
class DreamWallpaperService: ObservableObject {
    static let shared = DreamWallpaperService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var currentWallpaper: DreamWallpaper?
    @Published var errorMessage: String?
    
    // 本地存储的壁纸
    @Published var wallpapers: [DreamWallpaper] = []
    
    private let fileManager = FileManager.default
    private var wallpapersDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("DreamWallpapers", isDirectory: true)
    }
    
    private init() {
        loadWallpapers()
    }
    
    // MARK: - 生成壁纸
    
    /// 从梦境生成壁纸
    func generateWallpaper(from dream: Dream, style: DreamWallpaper.WallpaperStyle, size: DreamWallpaper.WallpaperSize) async {
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        do {
            // 步骤 1: 准备画布 (10%)
            try await simulateProgress(target: 0.1)
            let canvasSize = size.resolution
            
            // 步骤 2: 生成背景 (30%)
            try await simulateProgress(target: 0.3)
            let backgroundColor = generateBackgroundColor(for: dream, style: style)
            
            // 步骤 3: 添加梦境元素 (60%)
            try await simulateProgress(target: 0.6)
            let elements = extractWallpaperElements(from: dream)
            
            // 步骤 4: 应用风格化效果 (80%)
            try await simulateProgress(target: 0.8)
            
            // 步骤 5: 渲染最终图像 (90%)
            try await simulateProgress(target: 0.9)
            
            // 步骤 6: 保存壁纸 (100%)
            try await simulateProgress(target: 1.0)
            
            // 创建壁纸对象 (模拟 - 实际应该生成真实图像)
            let wallpaper = DreamWallpaper(
                dreamId: dream.id,
                imageUrl: "wallpaper_\(dream.id.uuidString).png",
                style: style,
                size: size,
                createdAt: Date()
            )
            
            currentWallpaper = wallpaper
            wallpapers.insert(wallpaper, at: 0)
            saveWallpapers()
            
        } catch {
            errorMessage = "生成壁纸失败：\(error.localizedDescription)"
        }
    }
    
    /// 生成背景颜色
    private func generateBackgroundColor(for dream: Dream, style: DreamWallpaper.WallpaperStyle) -> UIColor {
        switch style {
        case .minimalist:
            return UIColor.systemBackground
        case .artistic:
            return dream.primaryEmotion?.uiColor ?? UIColor.purple
        case .gradient:
            return UIColor.systemBackground
        case .nature:
            return UIColor.systemGreen
        case .abstract:
            return dream.primaryEmotion?.uiColor ?? UIColor.blue
        case .cosmic:
            return UIColor.black
        }
    }
    
    /// 从梦境提取壁纸元素
    private func extractWallpaperElements(from dream: Dream) -> [String] {
        var elements: [String] = []
        
        // 提取关键词
        let keywords = dream.tags.prefix(3).map { $0 }
        elements.append(contentsOf: keywords)
        
        // 提取情绪相关的元素
        for emotion in dream.emotions {
            switch emotion {
            case .calm: elements.append("平静的波浪")
            case .happy: elements.append("温暖的阳光")
            case .anxious: elements.append("流动的线条")
            case .fearful: elements.append("深邃的阴影")
            case .confused: elements.append("朦胧的雾气")
            case .excited: elements.append("跳跃的光点")
            case .sad: elements.append("柔和的蓝色")
            case .angry: elements.append("热烈的红色")
            case .surprised: elements.append("闪烁的星星")
            case .neutral: elements.append("平衡的几何")
            @unknown default: break
            }
        }
        
        return Array(Set(elements)) // 去重
    }
    
    // MARK: - 文件操作
    
    /// 保存壁纸到本地
    func saveWallpaperToPhotos(_ wallpaper: DreamWallpaper) async throws {
        // 实际实现需要：
        // 1. 从 imageUrl 加载图像
        // 2. 使用 PHPhotoLibrary 保存到相册
        // 3. 请求用户授权
        
        print("📸 保存壁纸到相册：\(wallpaper.id)")
        try await Task.sleep(nanoseconds: 500_000_000) // 模拟
    }
    
    /// 分享壁纸
    func shareWallpaper(_ wallpaper: DreamWallpaper) -> UIActivityViewController? {
        // 实际实现需要加载图像并创建分享控制器
        print("📤 分享壁纸：\(wallpaper.id)")
        return nil
    }
    
    // MARK: - 数据持久化
    
    private func loadWallpapers() {
        guard let data = UserDefaults.standard.data(forKey: "dreamWallpapers") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            wallpapers = try decoder.decode([DreamWallpaper].self, from: data)
        } catch {
            print("❌ 加载壁纸失败：\(error)")
        }
    }
    
    private func saveWallpapers() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(wallpapers)
            UserDefaults.standard.set(data, forKey: "dreamWallpapers")
        } catch {
            print("❌ 保存壁纸失败：\(error)")
        }
    }
    
    /// 删除壁纸
    func deleteWallpaper(_ wallpaper: DreamWallpaper) {
        wallpapers.removeAll { $0.id == wallpaper.id }
        saveWallpapers()
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ wallpaper: DreamWallpaper) {
        if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
            wallpapers[index].isFavorite.toggle()
            saveWallpapers()
        }
    }
    
    // MARK: - 工具方法
    
    private func simulateProgress(target: Double) async throws {
        while generationProgress < target {
            generationProgress += 0.05
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        generationProgress = target
    }
}

// MARK: - 扩展

extension Dream {
    var primaryEmotion: Emotion? {
        emotions.first
    }
}
