//
//  DreamVideoTemplates.swift
//  DreamLog
//
//  Dream Video Template Market - Phase 14 Completion
//  Pre-designed video templates for quick video creation
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 视频模板模型

/// 视频模板类别
enum VideoTemplateCategory: String, CaseIterable, Identifiable {
    case featured = "精选"
    case cinematic = "电影感"
    case minimal = "简约"
    case artistic = "艺术"
    case social = "社交"
    case memory = "回忆"
    case seasonal = "季节"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .cinematic: return "film"
        case .minimal: return "square.dashed"
        case .artistic: return "paintbrush.fill"
        case .social: return "person.2.fill"
        case .memory: return "heart.fill"
        case .seasonal: return "leaf.fill"
        }
    }
    
    var description: String {
        switch self {
        case .featured: return "编辑精选模板"
        case .cinematic: return "电影级视觉效果"
        case .minimal: return "简洁干净设计"
        case .artistic: return "艺术创意风格"
        case .social: return "社交媒体优化"
        case .memory: return "温馨回忆风格"
        case .seasonal: return "应季主题模板"
        }
    }
}

/// 视频模板难度
enum VideoTemplateDifficulty: String, CaseIterable {
    case easy = "简单"
    case medium = "中等"
    case advanced = "高级"
    
    var icon: String {
        switch self {
        case .easy: return "hare.fill"
        case .medium: return "tortoise.fill"
        case .advanced: return "flame.fill"
        }
    }
}

/// 视频模板
struct VideoTemplate: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var category: VideoTemplateCategory
    var difficulty: VideoTemplateDifficulty
    var duration: Double          // 秒
    var aspectRatio: DreamVideoConfig.AspectRatio
    var thumbnailName: String     // 本地资源名或 URL
    var isPremium: Bool = false
    var isFavorite: Bool = false
    var downloadCount: Int = 0
    var rating: Double = 5.0      // 0-5
    var tags: [String]
    var createdAt: Date
    
    // 模板配置
    var transitionStyle: AdvancedTransition
    var filterConfig: VideoFilterConfig
    var textOverlays: [VideoTextOverlay]
    var musicTrack: BackgroundMusicTrack?
    var kenBurnsEffect: Bool
    
    /// 创建内置模板
    static func builtin(
        name: String,
        description: String,
        category: VideoTemplateCategory,
        duration: Double,
        aspectRatio: DreamVideoConfig.AspectRatio = .portrait,
        transition: AdvancedTransition = .fade(duration: 1.0),
        filter: VideoFilterConfig = VideoFilterConfig(filterType: .none, intensity: 1.0),
        textOverlays: [VideoTextOverlay] = [],
        music: BackgroundMusicTrack? = nil,
        kenBurns: Bool = false,
        tags: [String] = []
    ) -> VideoTemplate {
        VideoTemplate(
            name: name,
            description: description,
            category: category,
            difficulty: .easy,
            duration: duration,
            aspectRatio: aspectRatio,
            thumbnailName: "template_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            isPremium: false,
            isFavorite: false,
            downloadCount: 0,
            rating: 5.0,
            tags: tags,
            createdAt: Date(),
            transitionStyle: transition,
            filterConfig: filter,
            textOverlays: textOverlays,
            musicTrack: music,
            kenBurnsEffect: kenBurns
        )
    }
}

// MARK: - 预设模板库

extension VideoTemplate {
    /// 获取所有内置模板
    static var builtinTemplates: [VideoTemplate] {
        [
            // 电影感系列
            VideoTemplate.builtin(
                name: "电影开场",
                description: "经典电影开场效果，黑色背景渐入，配优雅字幕",
                category: .cinematic,
                duration: 30,
                aspectRatio: .landscape,
                transition: .fade(duration: 1.5),
                filter: VideoFilterConfig(filterType: .noir, intensity: 0.7),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "我的梦境", duration: 30)
                ],
                music: .cinematic,
                kenBurns: true,
                tags: ["电影", "开场", "经典", "黑白"]
            ),
            
            VideoTemplate.builtin(
                name: "好莱坞预告",
                description: "震撼的好莱坞预告片风格，快速切换配紧张音乐",
                category: .cinematic,
                duration: 30,
                aspectRatio: .landscape,
                transition: .dissolve(duration: 0.5),
                filter: VideoFilterConfig(filterType: .process, intensity: 0.8),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "即将呈现", duration: 30)
                ],
                music: .cinematic,
                kenBurns: false,
                tags: ["预告", "震撼", "快速", "紧张"]
            ),
            
            // 简约系列
            VideoTemplate.builtin(
                name: "极简白色",
                description: "纯白背景，简洁转场，突出内容本身",
                category: .minimal,
                duration: 15,
                aspectRatio: .square,
                transition: .fade(duration: 0.8),
                filter: VideoFilterConfig(filterType: .none, intensity: 1.0),
                textOverlays: [],
                music: .ambient,
                kenBurns: false,
                tags: ["极简", "白色", "干净", "简约"]
            ),
            
            VideoTemplate.builtin(
                name: "柔和渐变",
                description: "温暖渐变背景，柔和过渡效果",
                category: .minimal,
                duration: 20,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.2),
                filter: VideoFilterConfig(filterType: .fade, intensity: 0.5),
                textOverlays: [
                    VideoTextOverlay.captionStyle(text: "梦境记录", startTime: 0, endTime: 20)
                ],
                music: .piano,
                kenBurns: true,
                tags: ["渐变", "柔和", "温暖", "治愈"]
            ),
            
            // 艺术系列
            VideoTemplate.builtin(
                name: "复古胶片",
                description: "老电影胶片质感，怀旧复古风格",
                category: .artistic,
                duration: 30,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.0),
                filter: VideoFilterConfig(filterType: .vintage, intensity: 0.9),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "昨日之梦", duration: 30)
                ],
                music: .lofi,
                kenBurns: true,
                tags: ["复古", "胶片", "怀旧", "老电影"]
            ),
            
            VideoTemplate.builtin(
                name: "梦幻色彩",
                description: "多彩渐变，梦幻般的视觉效果",
                category: .artistic,
                duration: 25,
                aspectRatio: .portrait,
                transition: .zoom(scale: 1.1, duration: 1.5),
                filter: VideoFilterConfig(filterType: .tonal, intensity: 0.6),
                textOverlays: [],
                music: .electronic,
                kenBurns: true,
                tags: ["梦幻", "多彩", "渐变", "艺术"]
            ),
            
            VideoTemplate.builtin(
                name: "水墨丹青",
                description: "中国风水墨效果，诗意盎然",
                category: .artistic,
                duration: 30,
                aspectRatio: .portrait,
                transition: .fade(duration: 2.0),
                filter: VideoFilterConfig(filterType: .mono, intensity: 0.8),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "梦境如画", duration: 30)
                ],
                music: .ambient,
                kenBurns: false,
                tags: ["水墨", "中国风", "诗意", "艺术"]
            ),
            
            // 社交系列
            VideoTemplate.builtin(
                name: "Instagram 故事",
                description: "完美适配 Instagram Story 尺寸，竖屏全屏",
                category: .social,
                duration: 15,
                aspectRatio: .portrait,
                transition: .slide(direction: .left, duration: 0.8),
                filter: VideoFilterConfig(filterType: .instant, intensity: 0.7),
                textOverlays: [
                    VideoTextOverlay.captionStyle(text: "#梦境记录", startTime: 0, endTime: 15)
                ],
                music: .lofi,
                kenBurns: false,
                tags: ["Instagram", "故事", "竖屏", "社交"]
            ),
            
            VideoTemplate.builtin(
                name: "抖音风格",
                description: "抖音热门视频风格，动感十足",
                category: .social,
                duration: 15,
                aspectRatio: .portrait,
                transition: .zoom(scale: 1.2, duration: 0.5),
                filter: VideoFilterConfig(filterType: .chrome, intensity: 0.8),
                textOverlays: [],
                music: .electronic,
                kenBurns: false,
                tags: ["抖音", "TikTok", "动感", "热门"]
            ),
            
            VideoTemplate.builtin(
                name: "朋友圈分享",
                description: "微信朋友圈优化，正方形构图",
                category: .social,
                duration: 20,
                aspectRatio: .square,
                transition: .fade(duration: 1.0),
                filter: VideoFilterConfig(filterType: .none, intensity: 1.0),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "分享我的梦", duration: 20)
                ],
                music: .piano,
                kenBurns: true,
                tags: ["微信", "朋友圈", "分享", "正方"]
            ),
            
            // 回忆系列
            VideoTemplate.builtin(
                name: "温馨回忆",
                description: "温暖色调，慢速转场，适合珍贵回忆",
                category: .memory,
                duration: 30,
                aspectRatio: .landscape,
                transition: .fade(duration: 2.0),
                filter: VideoFilterConfig(filterType: .warm, intensity: 0.6),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "珍贵回忆", duration: 30)
                ],
                music: .piano,
                kenBurns: true,
                tags: ["温馨", "回忆", "温暖", "珍贵"]
            ),
            
            VideoTemplate.builtin(
                name: "时光倒流",
                description: "倒放效果，仿佛时光倒流",
                category: .memory,
                duration: 25,
                aspectRatio: .portrait,
                transition: .dissolve(duration: 1.0),
                filter: VideoFilterConfig(filterType: .fade, intensity: 0.7),
                textOverlays: [],
                music: .ambient,
                kenBurns: false,
                tags: ["时光", "倒流", "回忆", "特效"]
            ),
            
            // 季节系列
            VideoTemplate.builtin(
                name: "春日暖阳",
                description: "明亮温暖，充满春天气息",
                category: .seasonal,
                duration: 20,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.2),
                filter: VideoFilterConfig(filterType: .warm, intensity: 0.5),
                textOverlays: [
                    VideoTextOverlay.captionStyle(text: "春日梦境", startTime: 0, endTime: 20)
                ],
                music: .nature,
                kenBurns: true,
                tags: ["春天", "温暖", "明亮", "季节"]
            ),
            
            VideoTemplate.builtin(
                name: "夏日清凉",
                description: "清爽蓝色调，夏日海滩风情",
                category: .seasonal,
                duration: 20,
                aspectRatio: .landscape,
                transition: .slide(direction: .right, duration: 1.0),
                filter: VideoFilterConfig(filterType: .cool, intensity: 0.6),
                textOverlays: [],
                music: .nature,
                kenBurns: false,
                tags: ["夏天", "清凉", "蓝色", "海滩"]
            ),
            
            VideoTemplate.builtin(
                name: "秋日私语",
                description: "金黄暖色调，秋日浪漫氛围",
                category: .seasonal,
                duration: 25,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.5),
                filter: VideoFilterConfig(filterType: .vintage, intensity: 0.6),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "秋梦", duration: 25)
                ],
                music: .piano,
                kenBurns: true,
                tags: ["秋天", "金黄", "浪漫", "落叶"]
            ),
            
            VideoTemplate.builtin(
                name: "冬日雪景",
                description: "冷色调，纯净雪白，冬日静谧",
                category: .seasonal,
                duration: 25,
                aspectRatio: .landscape,
                transition: .fade(duration: 2.0),
                filter: VideoFilterConfig(filterType: .cool, intensity: 0.8),
                textOverlays: [],
                music: .ambient,
                kenBurns: true,
                tags: ["冬天", "雪景", "纯净", "静谧"]
            ),
            
            // 高级模板
            VideoTemplate.builtin(
                name: "多重曝光",
                description: "艺术感多重曝光效果，高级视觉体验",
                category: .artistic,
                difficulty: .advanced,
                duration: 30,
                aspectRatio: .portrait,
                transition: .dissolve(duration: 1.5),
                filter: VideoFilterConfig(filterType: .tonal, intensity: 0.7),
                textOverlays: [],
                music: .electronic,
                kenBurns: true,
                tags: ["多重曝光", "艺术", "高级", "特效"]
            ),
            
            VideoTemplate.builtin(
                name: "时空穿梭",
                description: "炫酷转场效果，仿佛穿越时空",
                category: .cinematic,
                difficulty: .advanced,
                duration: 30,
                aspectRatio: .landscape,
                transition: .cubeRotate(direction: .left, duration: 1.0),
                filter: VideoFilterConfig(filterType: .process, intensity: 0.9),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "梦境穿梭", duration: 30)
                ],
                music: .cinematic,
                kenBurns: false,
                tags: ["时空", "穿梭", "炫酷", "特效"]
            ),
            
            // 社交媒体系列 - 抖音/TikTok
            VideoTemplate.builtin(
                name: "抖音热门",
                description: "竖屏快节奏，适合抖音/ TikTok 分享",
                category: .social,
                duration: 15,
                aspectRatio: .portrait,
                transition: .slide(direction: .left, duration: 0.4),
                filter: VideoFilterConfig(filterType: .instant, intensity: 0.7),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "#梦境记录", duration: 15)
                ],
                music: .lofi,
                kenBurns: false,
                tags: ["抖音", "TikTok", "竖屏", "快节奏", "社交"]
            ),
            
            VideoTemplate.builtin(
                name: "小红书风格",
                description: "清新治愈，小红书爆款风格",
                category: .social,
                duration: 20,
                aspectRatio: .portrait,
                transition: .fade(duration: 0.8),
                filter: VideoFilterConfig(filterType: .fade, intensity: 0.6),
                textOverlays: [
                    VideoTextOverlay.captionStyle(text: "昨晚的梦✨", startTime: 0, endTime: 20)
                ],
                music: .piano,
                kenBurns: true,
                tags: ["小红书", "清新", "治愈", "社交"]
            ),
            
            VideoTemplate.builtin(
                name: "Instagram 故事",
                description: "16:9 横屏，适合 IG 故事分享",
                category: .social,
                duration: 15,
                aspectRatio: .landscape,
                transition: .dissolve(duration: 0.6),
                filter: VideoFilterConfig(filterType: .process, intensity: 0.5),
                textOverlays: [],
                music: .ambient,
                kenBurns: true,
                tags: ["Instagram", "故事", "横屏", "社交"]
            ),
            
            // 回忆系列 - 新增
            VideoTemplate.builtin(
                name: "时光倒流",
                description: "倒放效果，仿佛时间倒流",
                category: .memory,
                duration: 25,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.0),
                filter: VideoFilterConfig(filterType: .vintage, intensity: 0.8),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "回忆", duration: 25)
                ],
                music: .piano,
                kenBurns: false,
                tags: ["回忆", "倒放", "怀旧", "时光"]
            ),
            
            VideoTemplate.builtin(
                name: "珍贵瞬间",
                description: "温馨回忆风格，记录美好梦境",
                category: .memory,
                duration: 30,
                aspectRatio: .square,
                transition: .fade(duration: 1.5),
                filter: VideoFilterConfig(filterType: .warm, intensity: 0.7),
                textOverlays: [
                    VideoTextOverlay.captionStyle(text: "珍贵的梦", startTime: 0, endTime: 30)
                ],
                music: .strings,
                kenBurns: true,
                tags: ["珍贵", "温馨", "回忆", "美好"]
            ),
            
            // 节日特别系列
            VideoTemplate.builtin(
                name: "新年梦境",
                description: "喜庆红色主题，新年特别版",
                category: .seasonal,
                duration: 20,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.0),
                filter: VideoFilterConfig(filterType: .warm, intensity: 0.9),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "新年好梦", duration: 20)
                ],
                music: .cinematic,
                kenBurns: true,
                tags: ["新年", "节日", "喜庆", "红色"]
            ),
            
            VideoTemplate.builtin(
                name: "情人节梦境",
                description: "浪漫粉色主题，情人节特别版",
                category: .seasonal,
                duration: 20,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.2),
                filter: VideoFilterConfig(filterType: .warm, intensity: 0.6),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "爱的梦境💕", duration: 20)
                ],
                music: .piano,
                kenBurns: true,
                tags: ["情人节", "浪漫", "粉色", "爱情"]
            ),
            
            // 艺术实验系列
            VideoTemplate.builtin(
                name: "抽象艺术",
                description: "抽象视觉效果，艺术实验风格",
                category: .artistic,
                difficulty: .advanced,
                duration: 30,
                aspectRatio: .square,
                transition: .checkerboard(rows: 4, columns: 4, duration: 1.0),
                filter: VideoFilterConfig(filterType: .tonal, intensity: 0.9),
                textOverlays: [],
                music: .electronic,
                kenBurns: false,
                tags: ["抽象", "艺术", "实验", "视觉"]
            ),
            
            VideoTemplate.builtin(
                name: "赛博朋克",
                description: "霓虹色彩，未来科技感",
                category: .artistic,
                difficulty: .advanced,
                duration: 25,
                aspectRatio: .landscape,
                transition: .slide(direction: .right, duration: 0.5),
                filter: VideoFilterConfig(filterType: .cool, intensity: 0.9),
                textOverlays: [
                    VideoTextOverlay.titleStyle(text: "赛博梦境", duration: 25)
                ],
                music: .electronic,
                kenBurns: false,
                tags: ["赛博朋克", "霓虹", "未来", "科技"]
            ),
            
            // 冥想放松系列
            VideoTemplate.builtin(
                name: "深度放松",
                description: "舒缓节奏，帮助放松入眠",
                category: .minimal,
                duration: 60,
                aspectRatio: .landscape,
                transition: .fade(duration: 3.0),
                filter: VideoFilterConfig(filterType: .fade, intensity: 0.4),
                textOverlays: [],
                music: .ambient,
                kenBurns: true,
                tags: ["放松", "冥想", "助眠", "舒缓"]
            ),
            
            VideoTemplate.builtin(
                name: "清晨唤醒",
                description: "清新明亮，晨间唤醒能量",
                category: .minimal,
                duration: 30,
                aspectRatio: .portrait,
                transition: .fade(duration: 1.5),
                filter: VideoFilterConfig(filterType: .warm, intensity: 0.6),
                textOverlays: [
                    VideoTextOverlay.captionStyle(text: "早安☀️", startTime: 0, endTime: 30)
                ],
                music: .piano,
                kenBurns: true,
                tags: ["清晨", "唤醒", "能量", "阳光"]
            )
        ]
    }
    
    /// 按类别筛选模板
    static func templates(in category: VideoTemplateCategory) -> [VideoTemplate] {
        builtinTemplates.filter { $0.category == category }
    }
    
    /// 搜索模板
    static func searchTemplates(query: String) -> [VideoTemplate] {
        let lowercaseQuery = query.lowercased()
        return builtinTemplates.filter { template in
            template.name.lowercased().contains(lowercaseQuery) ||
            template.description.lowercased().contains(lowercaseQuery) ||
            template.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
}

// MARK: - 模板市场服务

/// 梦境视频模板市场服务
@MainActor
class DreamVideoTemplateMarket: ObservableObject {
    static let shared = DreamVideoTemplateMarket()
    
    @Published var templates: [VideoTemplate] = []
    @Published var downloadedTemplates: [UUID] = []
    @Published var favoriteTemplates: [UUID] = []
    @Published var selectedCategory: VideoTemplateCategory = .featured
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    
    private let userDefaultsKey = "DreamLog_VideoTemplates"
    private let favoritesKey = "DreamLog_VideoTemplateFavorites"
    
    private init() {
        loadTemplates()
        loadUserPreferences()
    }
    
    // MARK: - 加载模板
    
    private func loadTemplates() {
        templates = VideoTemplate.builtinTemplates
        // 可以扩展为从网络下载更多模板
    }
    
    private func loadUserPreferences() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let downloaded = try? JSONDecoder().decode([UUID].self, from: data) {
            downloadedTemplates = downloaded
        }
        
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let favorites = try? JSONDecoder().decode([UUID].self, from: data) {
            favoriteTemplates = favorites
        }
    }
    
    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(downloadedTemplates) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        
        if let data = try? JSONEncoder().encode(favoriteTemplates) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
    
    // MARK: - 模板操作
    
    /// 下载模板
    func downloadTemplate(_ template: VideoTemplate) async throws {
        guard !downloadedTemplates.contains(template.id) else {
            return // 已下载
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // 模拟下载延迟
        try await Task.sleep(nanoseconds: 500_000_000)
        
        downloadedTemplates.append(template.id)
        saveUserPreferences()
    }
    
    /// 收藏模板
    func toggleFavorite(_ template: VideoTemplate) {
        if let index = favoriteTemplates.firstIndex(of: template.id) {
            favoriteTemplates.remove(at: index)
        } else {
            favoriteTemplates.append(template.id)
        }
        saveUserPreferences()
    }
    
    /// 检查模板是否已下载
    func isDownloaded(_ templateId: UUID) -> Bool {
        downloadedTemplates.contains(templateId)
    }
    
    /// 检查模板是否已收藏
    func isFavorite(_ templateId: UUID) -> Bool {
        favoriteTemplates.contains(templateId)
    }
    
    // MARK: - 筛选和搜索
    
    /// 获取筛选后的模板列表
    var filteredTemplates: [VideoTemplate] {
        var result = templates
        
        // 按类别筛选
        if selectedCategory != .featured {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 搜索
        if !searchQuery.isEmpty {
            result = VideoTemplate.searchTemplates(query: searchQuery)
        }
        
        return result
    }
    
    /// 获取收藏的模板
    var favoriteTemplateList: [VideoTemplate] {
        templates.filter { favoriteTemplates.contains($0.id) }
    }
    
    /// 获取已下载的模板
    var downloadedTemplateList: [VideoTemplate] {
        templates.filter { downloadedTemplates.contains($0.id) }
    }
    
    // MARK: - 应用模板
    
    /// 从模板创建编辑配置
    func createEditConfig(from template: VideoTemplate, for dream: Dream) -> VideoEditConfig {
        var config = VideoEditConfig()
        
        // 应用滤镜
        config.filterConfig = template.filterConfig
        
        // 应用文字叠加（替换标题为梦境标题）
        config.textOverlays = template.textOverlays.map { overlay in
            var modified = overlay
            if overlay.text == "我的梦境" || overlay.text == "梦境记录" {
                modified.text = dream.title.prefix(20) + (dream.title.count > 20 ? "..." : "")
            }
            return modified
        }
        
        return config
    }
}

// MARK: - 模板预览视图数据

/// 模板预览数据
struct TemplatePreviewData {
    var template: VideoTemplate
    var previewImages: [String]  // 预览图资源名
    var sampleVideoURL: String?  // 示例视频 URL
    
    static var samplePreviews: [TemplatePreviewData] {
        VideoTemplate.builtinTemplates.map { template in
            TemplatePreviewData(
                template: template,
                previewImages: ["preview_1", "preview_2", "preview_3"],
                sampleVideoURL: nil
            )
        }
    }
}
