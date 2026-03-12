//
//  DreamARModelsLibrary.swift
//  DreamLog
//
//  Phase 22 - 3D 模型库服务
//  创建时间：2026-03-12
//

import Foundation
import SwiftUI
import Combine

// MARK: - 模型库服务

@MainActor
class DreamARModelsLibrary: ObservableObject {
    static let shared = DreamARModelsLibrary()
    
    /// 所有可用模型
    @Published var availableModels: [DreamARElement3D] = []
    
    /// 已下载模型
    @Published var downloadedModels: [DreamARElement3D] = []
    
    /// 收藏的模型
    @Published var favoriteModels: [DreamARElement3D] = []
    
    /// 最近使用的模型
    @Published var recentModels: [DreamARElement3D] = []
    
    /// 当前筛选类别
    @Published var selectedCategory: ModelCategory?
    
    /// 搜索关键词
    @Published var searchQuery: String = ""
    
    /// 下载任务
    @Published var downloadTasks: [UUID: DownloadTask] = [:]
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 本地模型目录
    private let modelsDirectory: URL
    
    /// 缓存管理器
    private let cacheManager: ARModelCacheManager
    
    private init() {
        // 初始化本地目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.modelsDirectory = documentsPath.appendingPathComponent("ARModels", isDirectory: true)
        
        // 初始化缓存管理器
        self.cacheManager = ARModelCacheManager()
        
        // 创建目录
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        // 加载模型
        Task {
            await loadModels()
        }
    }
    
    // MARK: - 加载模型
    
    /// 加载所有模型
    func loadModels() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 加载预设模型
            let presetModels = await loadPresetModels()
            
            // 加载已下载的模型
            let downloadedModels = await loadDownloadedModels()
            
            await MainActor.run {
                self.availableModels = presetModels
                self.downloadedModels = downloadedModels
                self.updateFavoriteModels()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载模型失败：\(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// 加载预设模型
    private func loadPresetModels() async -> [DreamARElement3D] {
        // 预设模型列表
        var models: [DreamARElement3D] = []
        
        // 自然类
        models.append(contentsOf: createNatureModels())
        
        // 动物类
        models.append(contentsOf: createAnimalModels())
        
        // 人物类
        models.append(contentsOf: createPersonModels())
        
        // 建筑类
        models.append(contentsOf: createBuildingModels())
        
        // 抽象类
        models.append(contentsOf: createAbstractModels())
        
        // 梦境符号类
        models.append(contentsOf: createDreamSymbolModels())
        
        return models
    }
    
    // MARK: - 创建预设模型
    
    private func createNatureModels() -> [DreamARElement3D] {
        [
            DreamARElement3D(
                name: "tree_oak",
                elementType: .nature,
                category: .nature,
                scale: 1.5
            ),
            DreamARElement3D(
                name: "tree_cherry",
                elementType: .nature,
                category: .nature,
                scale: 1.2
            ),
            DreamARElement3D(
                name: "flower_rose",
                elementType: .nature,
                category: .nature,
                scale: 0.3
            ),
            DreamARElement3D(
                name: "flower_sunflower",
                elementType: .nature,
                category: .nature,
                scale: 0.5
            ),
            DreamARElement3D(
                name: "rock_large",
                elementType: .earth,
                category: .nature,
                scale: 1.0
            ),
            DreamARElement3D(
                name: "rock_small",
                elementType: .earth,
                category: .nature,
                scale: 0.5
            ),
            DreamARElement3D(
                name: "cloud_fluffy",
                elementType: .wind,
                category: .nature,
                scale: 2.0
            ),
            DreamARElement3D(
                name: "mushroom",
                elementType: .nature,
                category: .nature,
                scale: 0.4
            ),
            DreamARElement3D(
                name: "grass_patch",
                elementType: .nature,
                category: .nature,
                scale: 0.8
            ),
            DreamARElement3D(
                name: "water_lily",
                elementType: .water,
                category: .nature,
                scale: 0.3
            )
        ]
    }
    
    private func createAnimalModels() -> [DreamARElement3D] {
        [
            DreamARElement3D(
                name: "butterfly_blue",
                elementType: .animal,
                category: .animal,
                scale: 0.2,
                animation: .float
            ),
            DreamARElement3D(
                name: "butterfly_monarch",
                elementType: .animal,
                category: .animal,
                scale: 0.25,
                animation: .float
            ),
            DreamARElement3D(
                name: "bird_sparrow",
                elementType: .animal,
                category: .animal,
                scale: 0.3,
                animation: .float
            ),
            DreamARElement3D(
                name: "bird_dove",
                elementType: .animal,
                category: .animal,
                scale: 0.35,
                animation: .float
            ),
            DreamARElement3D(
                name: "fish_koi",
                elementType: .animal,
                category: .animal,
                scale: 0.4,
                animation: .wave
            ),
            DreamARElement3D(
                name: "fish_goldfish",
                elementType: .animal,
                category: .animal,
                scale: 0.3,
                animation: .wave
            ),
            DreamARElement3D(
                name: "cat_sleeping",
                elementType: .animal,
                category: .animal,
                scale: 0.5
            ),
            DreamARElement3D(
                name: "rabbit",
                elementType: .animal,
                category: .animal,
                scale: 0.4
            ),
            DreamARElement3D(
                name: "owl",
                elementType: .animal,
                category: .animal,
                scale: 0.4,
                animation: .float
            ),
            DreamARElement3D(
                name: "dragonfly",
                elementType: .animal,
                category: .animal,
                scale: 0.15,
                animation: .float
            )
        ]
    }
    
    private func createPersonModels() -> [DreamARElement3D] {
        [
            DreamARElement3D(
                name: "person_standing",
                elementType: .person,
                category: .person,
                scale: 1.0
            ),
            DreamARElement3D(
                name: "person_sitting",
                elementType: .person,
                category: .person,
                scale: 0.8
            ),
            DreamARElement3D(
                name: "hand_open",
                elementType: .person,
                category: .person,
                scale: 0.5
            ),
            DreamARElement3D(
                name: "hand_pointing",
                elementType: .person,
                category: .person,
                scale: 0.5
            ),
            DreamARElement3D(
                name: "face_smile",
                elementType: .person,
                category: .person,
                scale: 0.6
            ),
            DreamARElement3D(
                name: "silhouette",
                elementType: .person,
                category: .person,
                scale: 1.0
            )
        ]
    }
    
    private func createBuildingModels() -> [DreamARElement3D] {
        [
            DreamARElement3D(
                name: "house_cottage",
                elementType: .building,
                category: .building,
                scale: 2.0
            ),
            DreamARElement3D(
                name: "house_modern",
                elementType: .building,
                category: .building,
                scale: 2.5
            ),
            DreamARElement3D(
                name: "door_wooden",
                elementType: .door,
                category: .building,
                scale: 1.0
            ),
            DreamARElement3D(
                name: "door_magical",
                elementType: .door,
                category: .building,
                scale: 1.0,
                material: MaterialConfig.emissive
            ),
            DreamARElement3D(
                name: "window_arch",
                elementType: .building,
                category: .building,
                scale: 0.8
            ),
            DreamARElement3D(
                name: "stairs_spiral",
                elementType: .building,
                category: .building,
                scale: 1.5
            ),
            DreamARElement3D(
                name: "bridge_stone",
                elementType: .building,
                category: .building,
                scale: 3.0
            ),
            DreamARElement3D(
                name: "lantern",
                elementType: .building,
                category: .building,
                scale: 0.4,
                material: MaterialConfig.emissive
            )
        ]
    }
    
    private func createAbstractModels() -> [DreamARElement3D] {
        [
            DreamARElement3D(
                name: "cube_crystal",
                elementType: .abstract,
                category: .abstract,
                scale: 0.5,
                material: MaterialConfig.glass
            ),
            DreamARElement3D(
                name: "sphere_glowing",
                elementType: .light,
                category: .abstract,
                scale: 0.4,
                material: MaterialConfig.emissive,
                animation: .pulse
            ),
            DreamARElement3D(
                name: "torus_gold",
                elementType: .abstract,
                category: .abstract,
                scale: 0.6,
                material: MaterialConfig.metal
            ),
            DreamARElement3D(
                name: "pyramid",
                elementType: .abstract,
                category: .abstract,
                scale: 0.7
            ),
            DreamARElement3D(
                name: "particles_sparkle",
                elementType: .light,
                category: .abstract,
                scale: 0.3,
                animation: .sparkle
            ),
            DreamARElement3D(
                name: "light_beam",
                elementType: .light,
                category: .abstract,
                scale: 1.0,
                animation: .pulse
            ),
            DreamARElement3D(
                name: "geometric_pattern",
                elementType: .abstract,
                category: .abstract,
                scale: 1.5
            ),
            DreamARElement3D(
                name: "energy_orb",
                elementType: .abstract,
                category: .abstract,
                scale: 0.5,
                material: MaterialConfig.emissive,
                animation: .rotate
            )
        ]
    }
    
    private func createDreamSymbolModels() -> [DreamARElement3D] {
        [
            DreamARElement3D(
                name: "moon_crescent",
                elementType: .light,
                category: .dreamSymbol,
                scale: 0.8,
                material: MaterialConfig.emissive,
                animation: .pulse
            ),
            DreamARElement3D(
                name: "moon_full",
                elementType: .light,
                category: .dreamSymbol,
                scale: 1.0,
                material: MaterialConfig.emissive
            ),
            DreamARElement3D(
                name: "star_small",
                elementType: .light,
                category: .dreamSymbol,
                scale: 0.2,
                material: MaterialConfig.emissive,
                animation: .sparkle
            ),
            DreamARElement3D(
                name: "star_large",
                elementType: .light,
                category: .dreamSymbol,
                scale: 0.4,
                material: MaterialConfig.emissive,
                animation: .sparkle
            ),
            DreamARElement3D(
                name: "key_ancient",
                elementType: .abstract,
                category: .dreamSymbol,
                scale: 0.4,
                material: MaterialConfig.metal
            ),
            DreamARElement3D(
                name: "key_golden",
                elementType: .abstract,
                category: .dreamSymbol,
                scale: 0.4,
                material: MaterialConfig.metal
            ),
            DreamARElement3D(
                name: "lock_vintage",
                elementType: .abstract,
                category: .dreamSymbol,
                scale: 0.3,
                material: MaterialConfig.metal
            ),
            DreamARElement3D(
                name: "clock_pocket",
                elementType: .abstract,
                category: .dreamSymbol,
                scale: 0.4,
                material: MaterialConfig.metal
            ),
            DreamARElement3D(
                name: "mirror_antique",
                elementType: .abstract,
                category: .dreamSymbol,
                scale: 0.6,
                material: MaterialConfig.glass
            ),
            DreamARElement3D(
                name: "feather",
                elementType: .wind,
                category: .dreamSymbol,
                scale: 0.3,
                animation: .float
            ),
            DreamARElement3D(
                name: "flame",
                elementType: .fire,
                category: .dreamSymbol,
                scale: 0.4,
                material: MaterialConfig.emissive,
                animation: .pulse
            ),
            DreamARElement3D(
                name: "water_drop",
                elementType: .water,
                category: .dreamSymbol,
                scale: 0.2,
                material: MaterialConfig.glass,
                animation: .float
            )
        ]
    }
    
    /// 加载已下载的模型
    private func loadDownloadedModels() async -> [DreamARElement3D] {
        var models: [DreamARElement3D] = []
        
        let enumerator = FileManager.default.enumerator(at: modelsDirectory, includingPropertiesForKeys: [.isRegularFileKey])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "usdz" || fileURL.pathExtension == "glb" {
                let modelName = fileURL.deletingPathExtension().lastPathComponent
                if let model = availableModels.first(where: { $0.name == modelName }) {
                    var downloadedModel = model
                    downloadedModel.downloadStatus = .downloaded
                    downloadedModel.modelURL = fileURL
                    models.append(downloadedModel)
                }
            }
        }
        
        return models
    }
    
    /// 更新收藏模型列表
    private func updateFavoriteModels() {
        favoriteModels = availableModels.filter { $0.isFavorite }
    }
    
    // MARK: - 模型筛选
    
    /// 获取筛选后的模型列表
    var filteredModels: [DreamARElement3D] {
        var models = availableModels
        
        // 按类别筛选
        if let category = selectedCategory {
            models = models.filter { $0.category == category }
        }
        
        // 按搜索关键词筛选
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            models = models.filter {
                $0.name.lowercased().contains(query) ||
                $0.nameLocalizable.lowercased().contains(query)
            }
        }
        
        return models
    }
    
    // MARK: - 模型下载
    
    /// 下载模型
    func downloadModel(_ model: DreamARElement3D) async throws {
        guard model.modelURL == nil else { return } // 已下载
        
        let taskID = model.id
        let downloadTask = DownloadTask(
            modelID: model.id,
            modelName: model.name,
            status: .downloading(0.0),
            startTime: Date()
        )
        
        await MainActor.run {
            self.downloadTasks[taskID] = downloadTask
        }
        
        // 模拟下载过程（实际实现需要从服务器下载）
        try await simulateDownload(taskID: taskID, modelName: model.name)
        
        // 更新模型状态
        await MainActor.run {
            if let index = self.availableModels.firstIndex(where: { $0.id == model.id }) {
                self.availableModels[index].downloadStatus = .downloaded
                self.downloadedModels.append(self.availableModels[index])
                self.addToRecent(model: self.availableModels[index])
            }
            self.downloadTasks.removeValue(forKey: taskID)
        }
    }
    
    /// 模拟下载过程
    private func simulateDownload(taskID: UUID, modelName: String) async throws {
        // 模拟下载进度
        for progress in stride(from: 0.0, to: 1.0, by: 0.1) {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
            
            await MainActor.run {
                if var task = self.downloadTasks[taskID] {
                    task.status = .downloading(progress)
                    self.downloadTasks[taskID] = task
                }
            }
        }
        
        // 创建空文件（模拟下载完成）
        let fileURL = modelsDirectory.appendingPathComponent("\(modelName).usdz")
        try Data().write(to: fileURL)
    }
    
    /// 取消下载
    func cancelDownload(modelID: UUID) {
        downloadTasks.removeValue(forKey: modelID)
    }
    
    /// 删除已下载的模型
    func deleteModel(_ model: DreamARElement3D) throws {
        guard let modelURL = model.modelURL else { return }
        
        try FileManager.default.removeItem(at: modelURL)
        
        if let index = downloadedModels.firstIndex(where: { $0.id == model.id }) {
            downloadedModels.remove(at: index)
        }
        
        if let index = availableModels.firstIndex(where: { $0.id == model.id }) {
            availableModels[index].downloadStatus = .notDownloaded
            availableModels[index].modelURL = nil
        }
    }
    
    // MARK: - 收藏管理
    
    /// 切换收藏状态
    func toggleFavorite(_ model: DreamARElement3D) {
        if let index = availableModels.firstIndex(where: { $0.id == model.id }) {
            availableModels[index].isFavorite.toggle()
            updateFavoriteModels()
        }
    }
    
    // MARK: - 最近使用
    
    /// 添加到最近使用
    private func addToRecent(model: DreamARElement3D) {
        // 移除已存在的
        recentModels.removeAll { $0.id == model.id }
        
        // 添加到开头
        recentModels.insert(model, at: 0)
        
        // 限制数量
        if recentModels.count > 20 {
            recentModels.removeLast()
        }
    }
    
    // MARK: - 模型搜索
    
    /// 搜索模型
    func searchModels(query: String, category: ModelCategory? = nil) -> [DreamARElement3D] {
        var results = availableModels
        
        if !query.isEmpty {
            let lowercasedQuery = query.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(lowercasedQuery) ||
                $0.nameLocalizable.lowercased().contains(lowercasedQuery)
            }
        }
        
        if let category = category {
            results = results.filter { $0.category == category }
        }
        
        return results
    }
}

// MARK: - 下载任务

struct DownloadTask: Identifiable {
    let id: UUID
    let modelID: UUID
    let modelName: String
    var status: DownloadStatus
    let startTime: Date
    
    init(
        id: UUID = UUID(),
        modelID: UUID,
        modelName: String,
        status: DownloadStatus,
        startTime: Date = Date()
    ) {
        self.id = id
        self.modelID = modelID
        self.modelName = modelName
        self.status = status
        self.startTime = startTime
    }
}

// MARK: - 模型缓存管理器

class ARModelCacheManager {
    static let shared = ARModelCacheManager()
    
    private let cache = NSCache<NSString, NSData>()
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    
    private init() {
        cache.totalCostLimit = maxCacheSize
    }
    
    func cache(model data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }
    
    func getCachedModel(forKey key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
