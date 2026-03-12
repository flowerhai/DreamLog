//
//  DreamARTemplateService.swift
//  DreamLog
//
//  Phase 22 - AR 场景模板服务
//  创建时间：2026-03-12
//

import Foundation
import SwiftUI
import Combine

// MARK: - AR 模板服务

@MainActor
class DreamARTemplateService: ObservableObject {
    static let shared = DreamARTemplateService()
    
    /// 所有可用模板
    @Published var availableTemplates: [DreamARTemplate] = []
    
    /// 收藏的模板
    @Published var favoriteTemplates: [DreamARTemplate] = []
    
    /// 最近使用的模板
    @Published var recentTemplates: [DreamARTemplate] = []
    
    /// 当前筛选类别
    @Published var selectedCategory: TemplateCategory?
    
    /// 搜索关键词
    @Published var searchQuery: String = ""
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    private init() {
        Task {
            await loadTemplates()
        }
    }
    
    // MARK: - 加载模板
    
    /// 加载所有模板
    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 加载预设模板
            let presetTemplates = createPresetTemplates()
            
            await MainActor.run {
                self.availableTemplates = presetTemplates
                self.updateFavoriteTemplates()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载模板失败：\(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - 创建预设模板
    
    private func createPresetTemplates() -> [DreamARTemplate] {
        var templates: [DreamARTemplate] = []
        
        // 星空梦境
        templates.append(DreamARTemplate(
            name: "starry_night",
            description: "在璀璨星空下漫步，星星闪烁，月亮高悬",
            category: .starrySky,
            elements: createStarrySkyElements(),
            environment: .sky,
            lighting: .dramatic,
            difficulty: .easy,
            estimatedTime: 30,
            downloadCount: 1250,
            rating: 4.8
        ))
        
        // 海洋世界
        templates.append(DreamARTemplate(
            name: "ocean_depths",
            description: "探索神秘的海底世界，水母游弋，鱼群穿梭",
            category: .oceanWorld,
            elements: createOceanWorldElements(),
            environment: .ocean,
            lighting: .natural,
            difficulty: .medium,
            estimatedTime: 45,
            downloadCount: 980,
            rating: 4.7
        ))
        
        // 森林秘境
        templates.append(DreamARTemplate(
            name: "enchanted_forest",
            description: "进入魔法森林，古树参天，小动物嬉戏",
            category: .forestSecret,
            elements: createForestElements(),
            environment: .forest,
            lighting: .soft,
            difficulty: .medium,
            estimatedTime: 50,
            downloadCount: 1100,
            rating: 4.9
        ))
        
        // 魔法空间
        templates.append(DreamARTemplate(
            name: "magic_realm",
            description: "神秘的魔法空间，水晶球发光，魔法阵旋转",
            category: .magicSpace,
            elements: createMagicElements(),
            environment: .abstract,
            lighting: .colorful,
            difficulty: .hard,
            estimatedTime: 60,
            downloadCount: 750,
            rating: 4.6
        ))
        
        // 童话城堡
        templates.append(DreamARTemplate(
            name: "fairytale_castle",
            description: "梦幻的童话城堡，彩虹横跨，云朵飘浮",
            category: .fairytaleCastle,
            elements: createCastleElements(),
            environment: .sky,
            lighting: .dreamy,
            difficulty: .hard,
            estimatedTime: 90,
            downloadCount: 1500,
            rating: 4.9
        ))
        
        // 抽象艺术
        templates.append(DreamARTemplate(
            name: "abstract_dream",
            description: "抽象的梦境空间，几何体漂浮，色彩斑斓",
            category: .abstractArt,
            elements: createAbstractElements(),
            environment: .abstract,
            lighting: .colorful,
            difficulty: .easy,
            estimatedTime: 25,
            downloadCount: 680,
            rating: 4.5
        ))
        
        // 月下花园
        templates.append(DreamARTemplate(
            name: "moonlight_garden",
            description: "月光下的静谧花园，花朵绽放，萤火虫飞舞",
            category: .forestSecret,
            elements: createGardenElements(),
            environment: .forest,
            lighting: .dim,
            difficulty: .medium,
            estimatedTime: 40,
            downloadCount: 920,
            rating: 4.8
        ))
        
        // 天空之城
        templates.append(DreamARTemplate(
            name: "sky_castle",
            description: "漂浮在云端的城堡，神秘而壮观",
            category: .fairytaleCastle,
            elements: createSkyCastleElements(),
            environment: .sky,
            lighting: .natural,
            difficulty: .hard,
            estimatedTime: 80,
            downloadCount: 1350,
            rating: 4.9
        ))
        
        return templates
    }
    
    // MARK: - 创建模板元素
    
    private func createStarrySkyElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "moon_full", elementType: .light, category: .dreamSymbol, scale: 1.5, material: MaterialConfig.emissive),
            DreamARElement3D(name: "star_large", elementType: .light, category: .dreamSymbol, scale: 0.5, material: MaterialConfig.emissive, animation: .twinkle),
            DreamARElement3D(name: "star_large", elementType: .light, category: .dreamSymbol, scale: 0.5, material: MaterialConfig.emissive, animation: .twinkle),
            DreamARElement3D(name: "star_small", elementType: .light, category: .dreamSymbol, scale: 0.3, material: MaterialConfig.emissive, animation: .twinkle),
            DreamARElement3D(name: "star_small", elementType: .light, category: .dreamSymbol, scale: 0.3, material: MaterialConfig.emissive, animation: .twinkle),
            DreamARElement3D(name: "star_small", elementType: .light, category: .dreamSymbol, scale: 0.3, material: MaterialConfig.emissive, animation: .twinkle),
            DreamARElement3D(name: "cloud_fluffy", elementType: .wind, category: .nature, scale: 2.0),
            DreamARElement3D(name: "particles_sparkle", elementType: .light, category: .abstract, scale: 0.5, animation: .sparkle)
        ]
    }
    
    private func createOceanWorldElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "fish_koi", elementType: .animal, category: .animal, scale: 0.5, animation: .wave),
            DreamARElement3D(name: "fish_goldfish", elementType: .animal, category: .animal, scale: 0.4, animation: .wave),
            DreamARElement3D(name: "fish_goldfish", elementType: .animal, category: .animal, scale: 0.4, animation: .wave),
            DreamARElement3D(name: "water_lily", elementType: .water, category: .nature, scale: 0.4),
            DreamARElement3D(name: "water_drop", elementType: .water, category: .dreamSymbol, scale: 0.3, animation: .float),
            DreamARElement3D(name: "sphere_glowing", elementType: .light, category: .abstract, scale: 0.2, animation: .float)
        ]
    }
    
    private func createForestElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "tree_oak", elementType: .nature, category: .nature, scale: 2.0),
            DreamARElement3D(name: "tree_cherry", elementType: .nature, category: .nature, scale: 1.8),
            DreamARElement3D(name: "mushroom", elementType: .nature, category: .nature, scale: 0.5),
            DreamARElement3D(name: "mushroom", elementType: .nature, category: .nature, scale: 0.4),
            DreamARElement3D(name: "grass_patch", elementType: .nature, category: .nature, scale: 1.0),
            DreamARElement3D(name: "rabbit", elementType: .animal, category: .animal, scale: 0.5),
            DreamARElement3D(name: "butterfly_blue", elementType: .animal, category: .animal, scale: 0.3, animation: .flutter),
            DreamARElement3D(name: "owl", elementType: .animal, category: .animal, scale: 0.5, animation: .hover)
        ]
    }
    
    private func createMagicElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "sphere_glowing", elementType: .light, category: .abstract, scale: 0.6, material: MaterialConfig.emissive, animation: .pulse),
            DreamARElement3D(name: "energy_orb", elementType: .abstract, category: .abstract, scale: 0.5, material: MaterialConfig.emissive, animation: .rotate),
            DreamARElement3D(name: "cube_crystal", elementType: .abstract, category: .abstract, scale: 0.4, material: MaterialConfig.glass),
            DreamARElement3D(name: "torus_gold", elementType: .abstract, category: .abstract, scale: 1.5, material: MaterialConfig.emissive, animation: .rotate),
            DreamARElement3D(name: "particles_sparkle", elementType: .light, category: .abstract, scale: 0.4, animation: .sparkle),
            DreamARElement3D(name: "light_beam", elementType: .light, category: .abstract, scale: 1.0, animation: .pulse)
        ]
    }
    
    private func createCastleElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "house_cottage", elementType: .building, category: .building, scale: 3.0),
            DreamARElement3D(name: "door_magical", elementType: .light, category: .building, scale: 1.2, material: MaterialConfig.emissive),
            DreamARElement3D(name: "window_arch", elementType: .building, category: .building, scale: 1.0),
            DreamARElement3D(name: "cloud_fluffy", elementType: .wind, category: .nature, scale: 3.0),
            DreamARElement3D(name: "torus_gold", elementType: .abstract, category: .abstract, scale: 4.0, material: MaterialConfig.glass),
            DreamARElement3D(name: "star_large", elementType: .light, category: .dreamSymbol, scale: 0.6, material: MaterialConfig.emissive)
        ]
    }
    
    private func createAbstractElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "cube_crystal", elementType: .abstract, category: .abstract, scale: 0.7, material: MaterialConfig.glass),
            DreamARElement3D(name: "torus_gold", elementType: .abstract, category: .abstract, scale: 0.8, material: MaterialConfig.metal),
            DreamARElement3D(name: "pyramid", elementType: .abstract, category: .abstract, scale: 0.9),
            DreamARElement3D(name: "sphere_glowing", elementType: .light, category: .abstract, scale: 0.5, material: MaterialConfig.emissive, animation: .pulse),
            DreamARElement3D(name: "geometric_pattern", elementType: .abstract, category: .abstract, scale: 2.0),
            DreamARElement3D(name: "particles_sparkle", elementType: .light, category: .abstract, scale: 0.3, animation: .sparkle)
        ]
    }
    
    private func createGardenElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "flower_rose", elementType: .nature, category: .nature, scale: 0.4),
            DreamARElement3D(name: "flower_sunflower", elementType: .nature, category: .nature, scale: 0.6),
            DreamARElement3D(name: "moon_crescent", elementType: .light, category: .dreamSymbol, scale: 1.0, material: MaterialConfig.emissive),
            DreamARElement3D(name: "star_small", elementType: .light, category: .abstract, scale: 0.1, material: MaterialConfig.emissive, animation: .sparkle),
            DreamARElement3D(name: "grass_patch", elementType: .nature, category: .nature, scale: 1.2),
            DreamARElement3D(name: "butterfly_monarch", elementType: .animal, category: .animal, scale: 0.3, animation: .float)
        ]
    }
    
    private func createSkyCastleElements() -> [DreamARElement3D] {
        [
            DreamARElement3D(name: "house_modern", elementType: .building, category: .building, scale: 4.0),
            DreamARElement3D(name: "bridge_stone", elementType: .building, category: .building, scale: 5.0),
            DreamARElement3D(name: "cloud_fluffy", elementType: .wind, category: .nature, scale: 4.0),
            DreamARElement3D(name: "cloud_fluffy", elementType: .wind, category: .nature, scale: 3.5),
            DreamARElement3D(name: "stairs_spiral", elementType: .building, category: .building, scale: 2.0),
            DreamARElement3D(name: "star_large", elementType: .light, category: .dreamSymbol, scale: 0.7, material: MaterialConfig.emissive),
            DreamARElement3D(name: "bird_dove", elementType: .animal, category: .animal, scale: 0.5, animation: .hover)
        ]
    }
    
    // MARK: - 模板筛选
    
    /// 获取筛选后的模板列表
    var filteredTemplates: [DreamARTemplate] {
        var templates = availableTemplates
        
        // 按类别筛选
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        // 按搜索关键词筛选
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            templates = templates.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                $0.nameLocalizable.lowercased().contains(query)
            }
        }
        
        return templates
    }
    
    // MARK: - 收藏管理
    
    /// 切换模板收藏状态
    func toggleFavorite(_ template: DreamARTemplate) {
        if let index = availableTemplates.firstIndex(where: { $0.id == template.id }) {
            availableTemplates[index].isFavorite.toggle()
            updateFavoriteTemplates()
        }
    }
    
    /// 更新收藏模板列表
    private func updateFavoriteTemplates() {
        favoriteTemplates = availableTemplates.filter { $0.isFavorite }
    }
    
    // MARK: - 最近使用
    
    /// 添加到最近使用
    func addToRecent(_ template: DreamARTemplate) {
        // 移除已存在的
        recentTemplates.removeAll { $0.id == template.id }
        
        // 添加到开头
        recentTemplates.insert(template, at: 0)
        
        // 限制数量
        if recentTemplates.count > 10 {
            recentTemplates.removeLast()
        }
    }
    
    // MARK: - 模板应用
    
    /// 应用模板到场景
    func applyTemplate(_ template: DreamARTemplate, to sceneService: DreamARService) async throws {
        // 清空当前场景
        await sceneService.clearScene()
        
        // 添加模板元素
        for element in template.elements {
            try await sceneService.addElement(element.toARElement())
        }
        
        // 设置环境
        await sceneService.setEnvironment(template.environment)
        
        // 设置灯光
        await sceneService.setLighting(template.lighting)
        
        // 添加到最近使用
        addToRecent(template)
    }
    
    // MARK: - 模板搜索
    
    /// 搜索模板
    func searchTemplates(query: String, category: TemplateCategory? = nil) -> [DreamARTemplate] {
        var results = availableTemplates
        
        if !query.isEmpty {
            let lowercasedQuery = query.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(lowercasedQuery) ||
                $0.description.lowercased().contains(lowercasedQuery)
            }
        }
        
        if let category = category {
            results = results.filter { $0.category == category }
        }
        
        return results
    }
    
    // MARK: - 模板预览
    
    /// 生成模板预览图片
    func generatePreview(for template: DreamARTemplate) async -> UIImage? {
        // 实际实现中会渲染模板的缩略图
        // 这里返回 nil，由 UI 显示占位图
        return nil
    }
}
