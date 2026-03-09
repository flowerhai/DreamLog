//
//  ImageCacheService.swift
//  DreamLog
//
//  图片缓存服务 - 优化图片加载性能 (LRU + 双层缓存)
//

import Foundation
import SwiftUI
import UIKit

// MARK: - 缓存配置

struct CacheConfig {
    var maxMemoryCount: Int
    var maxDiskSize: Int64
    var diskCleanupThreshold: Double // 触发清理的阈值 (0.0-1.0)
    
    static var `default`: CacheConfig {
        CacheConfig(
            maxMemoryCount: 100,
            maxDiskSize: 100 * 1024 * 1024, // 100MB
            diskCleanupThreshold: 0.8 // 80% 时触发清理
        )
    }
    
    static var aggressive: CacheConfig {
        CacheConfig(
            maxMemoryCount: 50,
            maxDiskSize: 50 * 1024 * 1024, // 50MB
            diskCleanupThreshold: 0.7
        )
    }
    
    static var relaxed: CacheConfig {
        CacheConfig(
            maxMemoryCount: 200,
            maxDiskSize: 200 * 1024 * 1024, // 200MB
            diskCleanupThreshold: 0.9
        )
    }
}

// MARK: - LRU 缓存节点

private class LRUNode {
    let urlString: String
    var timestamp: Date
    var prev: LRUNode?
    var next: LRUNode?
    
    init(urlString: String) {
        self.urlString = urlString
        self.timestamp = Date()
    }
}

// MARK: - 图片缓存服务

@MainActor
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    // 内存缓存
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // LRU 追踪 (用于优化内存缓存)
    private var lruHead: LRUNode?
    private var lruTail: LRUNode?
    private var lruMap: [String: LRUNode] = [:]
    
    // 磁盘缓存目录
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("DreamLogImages", isDirectory: true)
    }
    
    // 缓存配置
    var config: CacheConfig = .default
    
    @Published var memoryCacheCount: Int = 0
    @Published var diskCacheSizeFormatted: String = "0 B"
    
    private init() {
        memoryCache.countLimit = config.maxMemoryCount
        memoryCache.totalCostLimit = config.maxMemoryCount * 1024 * 1024 // ~1MB per image estimate
        setupCacheDirectory()
        setupObservers()
        Task {
            await cleanDiskCacheIfNeeded()
            await updateCacheStats()
        }
    }
    
    // MARK: - 观察者设置
    
    private func setupObservers() {
        // 监听内存警告
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearMemoryCache()
        }
        
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.cleanDiskCacheIfNeeded()
            }
        }
    }
    
    // MARK: - 缓存目录设置
    
    private func setupCacheDirectory() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func cleanDiskCacheIfNeeded() async {
        let totalSize = await getDiskCacheSize()
        let threshold = Int64(Double(config.maxDiskSize) * config.diskCleanupThreshold)
        
        if totalSize > threshold {
            await cleanDiskCache()
        }
    }
    
    private func getDiskCacheSize() async -> Int64 {
        guard let resources = try? fileManager.attributesOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) else {
            return 0
        }
        return resources[.totalFileAllocatedSizeKey] as? Int64 ?? 0
    }
    
    private func updateCacheStats() async {
        memoryCacheCount = memoryCache.count
        let size = await getDiskCacheSize()
        
        if size < 1024 {
            diskCacheSizeFormatted = "\(size) B"
        } else if size < 1024 * 1024 {
            diskCacheSizeFormatted = String(format: "%.1f KB", Double(size) / 1024)
        } else {
            diskCacheSizeFormatted = String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
    }
    
    private func cleanDiskCache() async {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey, .totalFileAllocatedSizeKey]) else {
            return
        }
        
        // 按创建时间排序，删除最旧的文件直到低于阈值
        var sorted = contents.compactMap { url -> (URL, Date, Int64)? in
            guard let date = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate,
                  let size = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize as? Int64 else {
                return nil
            }
            return (url, date, size)
        }.sorted { $0.1 > $1.1 } // 最新的在前
        
        var currentSize = sorted.reduce(0) { $0 + $1.2 }
        let targetSize = Int64(Double(config.maxDiskSize) * 0.5) // 清理到 50%
        
        while currentSize > targetSize, let (url, _, size) = sorted.popLast() {
            try? fileManager.removeItem(at: url)
            currentSize -= size
        }
        
        await updateCacheStats()
    }
    
    // MARK: - LRU 追踪
    
    private func updateLRU(_ urlString: String) {
        // 如果已存在，移动到头部
        if let node = lruMap[urlString] {
            node.timestamp = Date()
            moveToHead(node)
        } else {
            // 添加新节点
            let node = LRUNode(urlString: urlString)
            lruMap[urlString] = node
            addToHead(node)
            
            // 如果超出限制，移除尾部
            while lruMap.count > config.maxMemoryCount {
                if let tail = lruTail {
                    removeNode(tail)
                    lruMap.removeValue(forKey: tail.urlString)
                }
            }
        }
    }
    
    private func addToHead(_ node: LRUNode) {
        node.next = lruHead
        node.prev = nil
        
        if let head = lruHead {
            head.prev = node
        }
        
        lruHead = node
        
        if lruTail == nil {
            lruTail = node
        }
    }
    
    private func removeNode(_ node: LRUNode) {
        if let prev = node.prev {
            prev.next = node.next
        } else {
            lruHead = node.next
        }
        
        if let next = node.next {
            next.prev = node.prev
        } else {
            lruTail = node.prev
        }
    }
    
    private func moveToHead(_ node: LRUNode) {
        removeNode(node)
        addToHead(node)
    }
    
    // MARK: - 获取图片
    
    /// 从缓存或网络加载图片
    func loadImage(from urlString: String) async -> UIImage? {
        // 1. 检查内存缓存
        if let cached = memoryCache.object(forKey: urlString as NSString) {
            updateLRU(urlString)
            return cached
        }
        
        // 2. 检查磁盘缓存
        if let diskCached = loadFromDisk(urlString: urlString) {
            memoryCache.setObject(diskCached, forKey: urlString as NSString)
            updateLRU(urlString)
            await updateCacheStats()
            return diskCached
        }
        
        // 3. 从网络加载
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                return nil
            }
            
            // 缓存到内存和磁盘
            cacheImage(image, urlString: urlString)
            await updateCacheStats()
            
            return image
        } catch {
            print("❌ 加载图片失败：\(urlString) - \(error)")
            return nil
        }
    }
    
    /// 批量预加载图片 (缓存预热)
    func preloadImages(urlStrings: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for urlString in urlStrings {
                group.addTask { [weak self] in
                    _ = await self?.loadImage(from: urlString)
                }
            }
        }
    }
    
    /// 从梦境列表预加载相关图片
    func preloadDreamsImages(dreams: [Dream]) async {
        let imageUrls = dreams.compactMap { dream -> String? in
            dream.aiArtImageURL ?? dream.shareImageURL
        }
        
        if !imageUrls.isEmpty {
            await preloadImages(urlStrings: Array(imageUrls.prefix(20))) // 限制预加载数量
        }
    }
    
    // MARK: - 缓存图片
    
    /// 缓存图片到内存和磁盘
    func cacheImage(_ image: UIImage, urlString: String) {
        // 内存缓存
        memoryCache.setObject(image, forKey: urlString as NSString)
        updateLRU(urlString)
        
        // 磁盘缓存
        saveToDisk(image: image, urlString: urlString)
    }
    
    private func saveToDisk(image: UIImage, urlString: String) {
        let fileName = urlString.md5()
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        try? imageData.write(to: fileURL)
    }
    
    private func loadFromDisk(urlString: String) -> UIImage? {
        let fileName = urlString.md5()
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    // MARK: - 清除缓存
    
    /// 清除所有缓存
    func clearCache() async {
        memoryCache.removeAllObjects()
        lruMap.removeAll()
        lruHead = nil
        lruTail = nil
        
        try? fileManager.removeItem(at: cacheDirectory)
        setupCacheDirectory()
        
        await updateCacheStats()
    }
    
    /// 清除内存缓存
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        lruMap.removeAll()
        lruHead = nil
        lruTail = nil
        memoryCacheCount = 0
    }
    
    /// 清除磁盘缓存
    func clearDiskCache() async {
        try? fileManager.removeItem(at: cacheDirectory)
        setupCacheDirectory()
        await updateCacheStats()
    }
    
    // MARK: - 缓存管理
    
    /// 获取缓存统计信息
    func getCacheStats() async -> (memoryCount: Int, diskSize: Int64, diskSizeFormatted: String) {
        let memoryCount = memoryCache.count
        let diskSize = await getDiskCacheSize()
        
        let diskSizeFormatted: String
        if diskSize < 1024 {
            diskSizeFormatted = "\(diskSize) B"
        } else if diskSize < 1024 * 1024 {
            diskSizeFormatted = String(format: "%.1f KB", Double(diskSize) / 1024)
        } else {
            diskSizeFormatted = String(format: "%.1f MB", Double(diskSize) / (1024 * 1024))
        }
        
        return (memoryCount, diskSize, diskSizeFormatted)
    }
    
    /// 移除特定图片的缓存
    func removeCache(for urlString: String) async {
        memoryCache.removeObject(forKey: urlString as NSString)
        lruMap.removeValue(forKey: urlString)
        
        let fileName = urlString.md5()
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
        
        await updateCacheStats()
    }
    
    /// 设置缓存配置
    func setConfig(_ newConfig: CacheConfig) async {
        config = newConfig
        memoryCache.countLimit = newConfig.maxMemoryCount
        memoryCache.totalCostLimit = newConfig.maxMemoryCount * 1024 * 1024
        
        // 如果 LRU 超出新限制，清理
        while lruMap.count > newConfig.maxMemoryCount {
            if let tail = lruTail {
                removeNode(tail)
                lruMap.removeValue(forKey: tail.urlString)
                memoryCache.removeObject(forKey: tail.urlString as NSString)
            }
        }
        
        await cleanDiskCacheIfNeeded()
        await updateCacheStats()
    }
}

// MARK: - String 扩展 (MD5)

extension String {
    func md5() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var digest = [UInt8](repeating: 0, count: 16)
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
            return digest
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - 需要导入 CommonCrypto
// 在 DreamLog-Bridging-Header.h 中添加:
// #import <CommonCrypto/CommonCrypto.h>
