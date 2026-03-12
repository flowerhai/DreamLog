//
//  DreamARModelCache.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import RealityKit
import SwiftUI

// MARK: - AR Model Cache

/// AR 模型缓存管理器 - 高效管理 3D 模型加载和缓存
@MainActor
class DreamARModelCache: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 缓存中的模型数量
    @Published var cachedModelCount: Int = 0
    
    /// 缓存大小 (MB)
    @Published var cacheSizeMB: Double = 0.0
    
    /// 是否正在预加载
    @Published var isPreloading: Bool = false
    
    /// 预加载进度
    @Published var preloadProgress: Double = 0.0
    
    // MARK: - Cache Configuration
    
    /// 最大缓存大小 (MB)
    let maxCacheSizeMB: Double = 100.0
    
    /// 缓存保留时间 (秒)
    let cacheRetentionSeconds: TimeInterval = 300.0 // 5 分钟
    
    // MARK: - Private Properties
    
    private var modelCache: [String: CachedModel] = [:]
    private var modelLoadOrder: [String] = [] // LRU 顺序
    private var pendingLoads: [String: Task<Entity?, Never>] = [:]
    
    private let fileManager = FileManager.default
    private let cacheQueue = DispatchQueue(label: "com.dreamlog.modelcache", qos: .utility)
    
    // MARK: - Singleton
    
    static let shared = DreamARModelCache()
    
    private init() {
        setupCacheDirectory()
        updateCacheStats()
    }
    
    // MARK: - Setup
    
    private func setupCacheDirectory() {
        let cachePath = getCacheDirectory()
        try? fileManager.createDirectory(at: cachePath, withIntermediateDirectories: true)
    }
    
    private func getCacheDirectory() -> URL {
        let cachePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachePath.appendingPathComponent("ARModels", isDirectory: true)
    }
    
    // MARK: - Model Loading
    
    /// 加载模型（带缓存）
    func loadModel(for element: DreamARElement3D) async -> Entity? {
        let cacheKey = makeCacheKey(for: element)
        
        // 检查内存缓存
        if let cached = modelCache[cacheKey] {
            // 更新 LRU 顺序
            updateLRUOrder(cacheKey)
            
            cached.lastAccessTime = Date()
            return cached.entity
        }
        
        // 检查是否有正在进行的加载
        if let pendingTask = pendingLoads[cacheKey] {
            return await pendingTask.value
        }
        
        // 从磁盘加载或下载
        let task = Task<Entity?, Never> {
            return await loadModelFromDiskOrCreate(element: element, cacheKey: cacheKey)
        }
        
        pendingLoads[cacheKey] = task
        let result = await task.value
        pendingLoads.removeValue(forKey: cacheKey)
        
        return result
    }
    
    private func loadModelFromDiskOrCreate(element: DreamARElement3D, cacheKey: String) async -> Entity? {
        let cachePath = getCacheDirectory()
        let modelURL = cachePath.appendingPathComponent("\(cacheKey).usdz")
        
        // 检查磁盘缓存
        if fileManager.fileExists(atPath: modelURL.path) {
            do {
                let entity = try await Entity.load(contentsOf: modelURL)
                
                // 添加到内存缓存
                addToCache(cacheKey, entity: entity, element: element)
                
                return entity
            } catch {
                print("加载缓存模型失败：\(error)")
                // 删除损坏的缓存文件
                try? fileManager.removeItem(at: modelURL)
            }
        }
        
        // 从模型库加载
        return await loadFromModelLibrary(element: element, cacheKey: cacheKey, cacheURL: modelURL)
    }
    
    private func loadFromModelLibrary(element: DreamARElement3D, cacheKey: String, cacheURL: URL) async -> Entity? {
        // 从预设模型库获取模型 URL
        let library = DreamARModelsLibrary.shared
        let modelURL = library.getModelURL(for: element)
        
        guard let sourceURL = modelURL else {
            print("未找到模型：\(element.modelName)")
            return nil
        }
        
        do {
            // 加载模型
            let entity = try await Entity.load(contentsOf: sourceURL)
            
            // 保存到缓存
            try await saveToDiskCache(entity: entity, to: cacheURL)
            addToCache(cacheKey, entity: entity, element: element)
            
            return entity
        } catch {
            print("加载模型失败：\(error)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    private func addToCache(_ key: String, entity: Entity, element: DreamARElement3D) {
        let cached = CachedModel(
            entity: entity,
            element: element,
            loadTime: Date(),
            lastAccessTime: Date()
        )
        
        modelCache[key] = cached
        modelLoadOrder.append(key)
        
        updateCacheStats()
        enforceCacheLimit()
    }
    
    private func updateLRUOrder(_ key: String) {
        if let index = modelLoadOrder.firstIndex(of: key) {
            modelLoadOrder.remove(at: index)
        }
        modelLoadOrder.append(key)
    }
    
    private func enforceCacheLimit() {
        while cacheSizeMB > maxCacheSizeMB && !modelLoadOrder.isEmpty {
            let oldestKey = modelLoadOrder.removeFirst()
            removeFromCache(oldestKey)
        }
    }
    
    private func removeFromCache(_ key: String) {
        guard let cached = modelCache.removeValue(forKey: key) else { return }
        
        // 从磁盘删除
        let cachePath = getCacheDirectory()
        let modelURL = cachePath.appendingPathComponent("\(key).usdz")
        try? fileManager.removeItem(at: modelURL)
        
        updateCacheStats()
    }
    
    /// 清理未使用的缓存
    func clearUnusedModels() {
        let now = Date()
        var keysToRemove: [String] = []
        
        for (key, cached) in modelCache {
            if now.timeIntervalSince(cached.lastAccessTime) > cacheRetentionSeconds {
                keysToRemove.append(key)
            }
        }
        
        for key in keysToRemove {
            removeFromCache(key)
        }
        
        print("清理了 \(keysToRemove.count) 个未使用的缓存模型")
    }
    
    /// 清空所有缓存
    func clearAllCache() {
        modelCache.removeAll()
        modelLoadOrder.removeAll()
        pendingLoads.removeAll()
        
        let cachePath = getCacheDirectory()
        try? fileManager.removeItem(at: cachePath)
        setupCacheDirectory()
        
        updateCacheStats()
    }
    
    // MARK: - Preloading
    
    /// 预加载模型
    func preloadModel(for element: DreamARElement3D) async {
        let cacheKey = makeCacheKey(for: element)
        
        // 如果已缓存，跳过
        if modelCache[cacheKey] != nil {
            return
        }
        
        isPreloading = true
        
        // 后台加载
        await loadModel(for: element)
        
        isPreloading = false
    }
    
    /// 批量预加载
    func preloadModels(_ elements: [DreamARElement3D]) async {
        isPreloading = true
        
        let total = elements.count
        for (index, element) in elements.enumerated() {
            await preloadModel(for: element)
            preloadProgress = Double(index + 1) / Double(total)
        }
        
        isPreloading = false
        preloadProgress = 0
    }
    
    // MARK: - LOD Models
    
    /// 获取高精度模型
    func getHighDetailModel(for element: DreamARElement3D) -> URL? {
        // 高精度使用原始模型
        return DreamARModelsLibrary.shared.getModelURL(for: element)
    }
    
    /// 获取中等精度模型
    func getMediumDetailModel(for element: DreamARElement3D) -> URL? {
        // 中等精度可以使用简化版模型（如果有）
        // 目前返回原始模型，后续可以添加 LOD 模型生成
        return DreamARModelsLibrary.shared.getModelURL(for: element)
    }
    
    /// 获取低精度模型
    func getLowDetailModel(for element: DreamARElement3D) -> URL? {
        // 低精度使用简化版模型（如果有）
        // 目前返回原始模型，后续可以添加 LOD 模型生成
        return DreamARModelsLibrary.shared.getModelURL(for: element)
    }
    
    // MARK: - Stats
    
    private func updateCacheStats() {
        cachedModelCount = modelCache.count
        
        // 计算缓存大小
        let cachePath = getCacheDirectory()
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: cachePath, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        cacheSizeMB = Double(totalSize) / 1024.0 / 1024.0
    }
    
    // MARK: - Utilities
    
    private func makeCacheKey(for element: DreamARElement3D) -> String {
        return "\(element.modelName)_\(element.id.uuidString)"
    }
    
    private func saveToDiskCache(entity: Entity, to url: URL) async throws {
        // RealityKit 5 的 Entity 导出功能
        // 注意：这可能需要根据实际 RealityKit 版本调整
        try await entity.export(to: url)
    }
}

// MARK: - Cached Model

struct CachedModel {
    let entity: Entity
    let element: DreamARElement3D
    var loadTime: Date
    var lastAccessTime: Date
}

// MARK: - Cache Stats View

struct ModelCacheStatsView: View {
    @ObservedObject var cache = DreamARModelCache.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("模型缓存")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await cache.clearAllCache()
                    }
                }) {
                    Label("清空", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("缓存数量")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(cache.cachedModelCount)")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("缓存大小")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f MB", cache.cacheSizeMB))
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
            
            if cache.isPreloading {
                ProgressView(value: cache.preloadProgress)
                    .progressViewStyle(.linear)
                
                Text("预加载中...")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    ModelCacheStatsView()
}
