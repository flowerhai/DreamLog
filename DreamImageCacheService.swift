//
//  DreamImageCacheService.swift
//  DreamLog
//
//  Phase 89: 性能优化
//  图片缓存服务 - 三级缓存架构 (内存/磁盘/网络)
//

import Foundation
import UIKit
import os

/// 图片缓存配置
struct ImageCacheConfig {
    var memoryCacheLimit: Int = 50 * 1024 * 1024  // 50MB
    var diskCacheLimit: Int = 500 * 1024 * 1024   // 500MB
    var imageCacheDirectory: String = "DreamLog/ImageCache"
    var cacheExpirationDays: Int = 30
}

/// 图片缓存统计
struct ImageCacheStats {
    var memoryCacheCount: Int = 0
    var memoryCacheSize: Int = 0
    var diskCacheCount: Int = 0
    var diskCacheSize: Int = 0
    var hitCount: Int = 0
    var missCount: Int = 0
    
    var hitRate: Double {
        let total = hitCount + missCount
        return total > 0 ? Double(hitCount) / Double(total) * 100 : 0
    }
}

/// 图片缓存服务
@MainActor
final class DreamImageCacheService {
    
    static let shared = DreamImageCacheService()
    
    private let logger = Logger(subsystem: "com.dreamlog.app", category: "ImageCache")
    private let config: ImageCacheConfig
    
    // 内存缓存 (LRU)
    private let memoryCache: NSCache<NSString, UIImage>
    private var memoryCacheKeys: Set<String> = []
    private var currentMemorySize: Int = 0
    
    // 磁盘缓存
    private let diskCachePath: URL
    private let cacheQueue = DispatchQueue(label: "com.dreamlog.imagecache.disk", qos: .utility)
    
    // 统计
    private var stats = ImageCacheStats()
    
    // 正在下载的任务
    private var downloadTasks: [String: Task<UIImage?, Never>] = [:]
    
    private init(config: ImageCacheConfig = ImageCacheConfig()) {
        self.config = config
        
        // 初始化内存缓存
        memoryCache = NSCache()
        memoryCache.name = "DreamLog.ImageCache"
        memoryCache.countLimit = 100  // 最多 100 张图片
        memoryCache.totalCostLimit = config.memoryCacheLimit
        
        // 初始化磁盘缓存路径
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        diskCachePath = paths[0].appendingPathComponent(config.imageCacheDirectory)
        
        setupCacheDirectory()
        setupMemoryWarningHandling()
        loadDiskCacheStats()
        
        logger.info("💾 图片缓存服务已初始化")
        logger.info("   内存限制：\(config.memoryCacheLimit / 1024 / 1024)MB")
        logger.info("   磁盘限制：\(config.diskCacheLimit / 1024 / 1024)MB")
    }
    
    // MARK: - 缓存目录设置
    
    private func setupCacheDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: diskCachePath,
                withIntermediateDirectories: true,
                attributes: nil
            )
            logger.debug("📁 缓存目录已创建：\(diskCachePath.path)")
        } catch {
            logger.error("❌ 创建缓存目录失败：\(error.localizedDescription)")
        }
    }
    
    private func setupMemoryWarningHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        logger.warning("⚠️ 收到内存警告，清理内存缓存...")
        memoryCache.removeAllObjects()
        memoryCacheKeys.removeAll()
        currentMemorySize = 0
        updateMemoryStats()
    }
    
    // MARK: - 图片获取
    
    /// 获取图片（自动从三级缓存查找）
    func image(for dreamId: String, size: CGSize? = nil) async -> UIImage? {
        let cacheKey = makeCacheKey(dreamId: dreamId, size: size)
        
        // 1. 检查内存缓存
        if let cachedImage = getFromMemoryCache(key: cacheKey) {
            stats.hitCount += 1
            logger.debug("✅ 内存缓存命中：\(cacheKey)")
            return cachedImage
        }
        
        // 2. 检查磁盘缓存
        if let diskImage = await getFromDiskCache(key: cacheKey) {
            stats.hitCount += 1
            // 添加到内存缓存
            addToMemoryCache(image: diskImage, key: cacheKey)
            logger.debug("✅ 磁盘缓存命中：\(cacheKey)")
            return diskImage
        }
        
        // 3. 从网络加载
        stats.missCount += 1
        logger.debug("🌐 缓存未命中，从网络加载：\(cacheKey)")
        return await loadImageFromNetwork(dreamId: dreamId, cacheKey: cacheKey)
    }
    
    /// 从内存缓存获取
    private func getFromMemoryCache(key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }
    
    /// 从磁盘缓存获取
    private func getFromDiskCache(key: String) async -> UIImage? {
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let fileURL = self.diskCachePath.appendingPathComponent(key)
                
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let data = try Data(contentsOf: fileURL)
                    
                    // 检查是否过期
                    if self.isCacheExpired(fileURL: fileURL) {
                        try? FileManager.default.removeItem(at: fileURL)
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    if let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    self.logger.error("❌ 读取磁盘缓存失败：\(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// 从网络加载图片
    private func loadImageFromNetwork(dreamId: String, cacheKey: String) async -> UIImage? {
        // 检查是否已有下载任务
        if let existingTask = downloadTasks[cacheKey] {
            logger.debug("⏳ 等待现有下载任务：\(cacheKey)")
            return await existingTask.value
        }
        
        // 创建新的下载任务
        let task = Task<UIImage?, Never> {
            defer {
                downloadTasks.removeValue(forKey: cacheKey)
            }
            
            // 这里应该调用实际的图片下载服务
            // 示例实现：
            guard let url = URL(string: "https://dreamlog.app/images/\(dreamId).jpg") else {
                return nil
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let image = UIImage(data: data) else {
                    return nil
                }
                
                // 保存到缓存
                await self.saveToCache(image: image, key: cacheKey)
                
                return image
            } catch {
                self.logger.error("❌ 下载图片失败：\(error.localizedDescription)")
                return nil
            }
        }
        
        downloadTasks[cacheKey] = task
        return await task.value
    }
    
    // MARK: - 缓存保存
    
    /// 保存图片到缓存
    func saveToCache(image: UIImage, key: String) async {
        // 保存到内存缓存
        addToMemoryCache(image: image, key: key)
        
        // 保存到磁盘缓存
        await saveToDiskCache(image: image, key: key)
    }
    
    /// 添加到内存缓存
    private func addToMemoryCache(image: UIImage, key: String) {
        // 估算图片大小
        let imageSize = estimateImageSize(image)
        
        memoryCache.setObject(image, forKey: key as NSString, cost: imageSize)
        memoryCacheKeys.insert(key)
        currentMemorySize += imageSize
        
        updateMemoryStats()
        logger.debug("💾 已添加到内存缓存：\(key) (\(imageSize / 1024)KB)")
    }
    
    /// 保存到磁盘缓存
    private func saveToDiskCache(image: UIImage, key: String) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let fileURL = self.diskCachePath.appendingPathComponent(key)
                
                // 压缩图片
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    continuation.resume()
                    return
                }
                
                do {
                    try data.write(to: fileURL, options: .atomic)
                    
                    // 设置过期时间
                    let attributes: [FileAttributeKey: Any] = [
                        .modificationDate: Date()
                    ]
                    try FileManager.default.setAttributes(attributes, ofItemAtPath: fileURL.path)
                    
                    self.logger.debug("💾 已保存到磁盘缓存：\(key) (\(data.count / 1024)KB)")
                } catch {
                    self.logger.error("❌ 保存到磁盘缓存失败：\(error.localizedDescription)")
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - 缓存清理
    
    /// 清除所有缓存
    func clearAllCaches() async {
        logger.info("🧹 清除所有缓存...")
        
        // 清除内存缓存
        memoryCache.removeAllObjects()
        memoryCacheKeys.removeAll()
        currentMemorySize = 0
        
        // 清除磁盘缓存
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                do {
                    try FileManager.default.removeItem(at: self.diskCachePath)
                    try FileManager.default.createDirectory(
                        at: self.diskCachePath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    self.logger.info("✅ 磁盘缓存已清除")
                } catch {
                    self.logger.error("❌ 清除磁盘缓存失败：\(error.localizedDescription)")
                }
                
                continuation.resume()
            }
        }
        
        updateMemoryStats()
    }
    
    /// 清除过期缓存
    func clearExpiredCaches() async {
        logger.info("🧹 清理过期缓存...")
        
        await withCheckedContinuation { continuation in
            cacheQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                var removedCount = 0
                var removedSize: Int64 = 0
                
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: self.diskCachePath,
                        includingPropertiesForKeys: [.contentSizeKey, .modificationDateKey],
                        options: []
                    )
                    
                    for file in files {
                        if self.isCacheExpired(fileURL: file) {
                            let size = try file.resourceValues(forKeys: [.contentSizeKey]).contentSize ?? 0
                            removedSize += Int64(size)
                            try FileManager.default.removeItem(at: file)
                            removedCount += 1
                        }
                    }
                    
                    self.logger.info("✅ 清理完成：移除 \(removedCount) 个文件，释放 \(removedSize / 1024)KB")
                } catch {
                    self.logger.error("❌ 清理过期缓存失败：\(error.localizedDescription)")
                }
                
                continuation.resume()
            }
        }
    }
    
    /// 检查缓存是否过期
    private func isCacheExpired(fileURL: URL) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let modDate = attributes[.modificationDate] as? Date else {
            return true
        }
        
        let expirationDate = Date().addingTimeInterval(-Double(config.cacheExpirationDays) * 24 * 60 * 60)
        return modDate < expirationDate
    }
    
    // MARK: - 工具方法
    
    /// 生成缓存键
    private func makeCacheKey(dreamId: String, size: CGSize?) -> String {
        if let size = size {
            return "\(dreamId)_\(Int(size.width))x\(Int(size.height))"
        }
        return dreamId
    }
    
    /// 估算图片大小
    private func estimateImageSize(_ image: UIImage) -> Int {
        // 估算：宽 * 高 * 4 (RGBA)
        return Int(image.size.width * image.size.height * 4)
    }
    
    /// 更新内存统计
    private func updateMemoryStats() {
        stats.memoryCacheCount = memoryCacheKeys.count
        stats.memoryCacheSize = currentMemorySize
    }
    
    /// 加载磁盘缓存统计
    private func loadDiskCacheStats() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(
                    at: self.diskCachePath,
                    includingPropertiesForKeys: [.contentSizeKey],
                    options: []
                )
                
                self.stats.diskCacheCount = files.count
                self.stats.diskCacheSize = files.reduce(0) { total, file in
                    let size = try? file.resourceValues(forKeys: [.contentSizeKey]).contentSize
                    return total + (size ?? 0)
                }
            } catch {
                self.logger.error("❌ 加载磁盘缓存统计失败：\(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 统计信息
    
    /// 获取缓存统计
    func getStats() -> ImageCacheStats {
        return stats
    }
    
    /// 打印统计信息
    func printStats() {
        logger.info("📊 图片缓存统计:")
        logger.info("   内存缓存：\(stats.memoryCacheCount) 张图片，\(stats.memoryCacheSize / 1024)KB")
        logger.info("   磁盘缓存：\(stats.diskCacheCount) 张图片，\(stats.diskCacheSize / 1024)KB")
        logger.info("   命中率：\(String(format: "%.1f", stats.hitRate))%")
        logger.info("   命中：\(stats.hitCount) | 未命中：\(stats.missCount)")
    }
}

// MARK: - 图片加载扩展

extension DreamImageCacheService {
    
    /// 预加载多张图片
    func preloadImages(dreamIds: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for dreamId in dreamIds {
                group.addTask { [weak self] in
                    _ = await self?.image(for: dreamId)
                }
            }
        }
        logger.debug("✅ 预加载完成：\(dreamIds.count) 张图片")
    }
    
    /// 获取缩略图
    func thumbnail(for dreamId: String, size: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        return await image(for: dreamId, size: size)
    }
}
