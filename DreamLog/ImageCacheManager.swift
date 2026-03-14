//
//  ImageCacheManager.swift
//  DreamLog
//
//  Phase 45 - 图片缓存管理器，优化内存使用
//  LRU 缓存策略，支持内存 + 磁盘双层缓存
//

import UIKit
import Foundation

/// 图片缓存管理器
class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    // MARK: - 缓存配置
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCachePath: String
    private let fileManager = FileManager.default
    private let cacheQueue = DispatchQueue(label: "com.dreamlog.imagecache", attributes: .concurrent)
    
    // 缓存限制
    private let maxMemoryCount = 100
    private let maxMemorySize = 100 * 1024 * 1024 // 100MB
    private let maxDiskSize = 500 * 1024 * 1024 // 500MB
    
    // 统计信息
    private var cacheHits = 0
    private var cacheMisses = 0
    
    init() {
        // 配置内存缓存
        memoryCache.countLimit = maxMemoryCount
        memoryCache.totalCostLimit = maxMemorySize
        
        // 获取磁盘缓存路径
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        diskCachePath = paths[0].appendingPathComponent("ImageCache").path
        
        // 创建缓存目录
        try? fileManager.createDirectory(atPath: diskCachePath, withIntermediateDirectories: true)
        
        // 启动时清理过期缓存
        cleanupDiskCache()
    }
    
    // MARK: - 缓存操作
    
    /// 获取图片
    func image(forKey key: String) -> UIImage? {
        // 先检查内存缓存
        if let cached = memoryCache.object(forKey: key as NSString) {
            cacheHits += 1
            return cached
        }
        
        // 从磁盘加载
        if let diskImage = loadFromDisk(forKey: key) {
            cacheHits += 1
            // 重新加入内存缓存
            memoryCache.setObject(diskImage, forKey: key as NSString, cost: imageSize(diskImage))
            return diskImage
        }
        
        cacheMisses += 1
        return nil
    }
    
    /// 保存图片
    func saveImage(_ image: UIImage, forKey key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 保存到内存缓存
            let cost = self.imageSize(image)
            self.memoryCache.setObject(image, forKey: key as NSString, cost: cost)
            
            // 保存到磁盘缓存
            self.saveToDisk(image, forKey: key)
        }
    }
    
    /// 移除图片
    func removeImage(forKey key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.memoryCache.removeObject(forKey: key as NSString)
            self.removeFromDisk(forKey: key)
        }
    }
    
    /// 清除所有缓存
    func clearAll() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.memoryCache.removeAllObjects()
            self.clearDiskCache()
        }
    }
    
    /// 获取缓存统计
    func getCacheStats() -> (memoryCount: Int, memorySize: Int, diskSize: Int, hitRate: Double) {
        let total = cacheHits + cacheMisses
        let hitRate = total > 0 ? Double(cacheHits) / Double(total) : 0
        return (
            memoryCount: memoryCache.count,
            memorySize: memoryCache.totalCost,
            diskSize: calculateDiskCacheSize(),
            hitRate: hitRate
        )
    }
    
    // MARK: - 磁盘缓存
    
    private func loadFromDisk(forKey key: String) -> UIImage? {
        let filePath = cachePath(forKey: key)
        guard fileManager.fileExists(atPath: filePath) else { return nil }
        return UIImage(contentsOfFile: filePath)
    }
    
    private func saveToDisk(_ image: UIImage, forKey key: String) {
        let filePath = cachePath(forKey: key)
        
        // 压缩图片 (JPEG 80% 质量)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        try? data.write(to: URL(fileURLWithPath: filePath))
    }
    
    private func removeFromDisk(forKey key: String) {
        let filePath = cachePath(forKey: key)
        try? fileManager.removeItem(atPath: filePath)
    }
    
    private func cachePath(forKey key: String) -> String {
        return diskCachePath + "/" + key.md5()
    }
    
    private func calculateDiskCacheSize() -> Int {
        guard let enumerator = fileManager.enumerator(atPath: diskCachePath) else { return 0 }
        
        var totalSize = 0
        for file in enumerator {
            guard let fileName = file as? String else { continue }
            let filePath = diskCachePath + "/" + fileName
            guard let attributes = try? fileManager.attributesOfItem(atPath: filePath) else { continue }
            totalSize += attributes[.size] as? Int ?? 0
        }
        return totalSize
    }
    
    private func cleanupDiskCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let currentSize = self.calculateDiskCacheSize()
            guard currentSize > self.maxDiskSize else { return }
            
            // 删除最旧的文件直到小于限制
            guard let files = try? self.fileManager.contentsOfDirectory(atPath: self.diskCachePath) else { return }
            
            let fileDates = files.compactMap { file -> (name: String, date: Date)? in
                let filePath = self.diskCachePath + "/" + file
                guard let attributes = try? self.fileManager.attributesOfItem(atPath: filePath) else { return nil }
                return (name: file, date: attributes[.modificationDate] as? Date ?? Date.distantPast)
            }
            
            let sortedFiles = fileDates.sorted { $0.date < $1.date }
            var size = currentSize
            
            for file in sortedFiles {
                guard size > self.maxDiskSize * 0.8 else { break } // 清理到 80%
                let filePath = self.diskCachePath + "/" + file.name
                if let fileSize = try? self.fileManager.attributesOfItem(atPath: filePath)[.size] as? Int {
                    size -= fileSize
                }
                try? self.fileManager.removeItem(atPath: filePath)
            }
        }
    }
    
    private func clearDiskCache() {
        try? fileManager.removeItem(atPath: diskCachePath)
        try? fileManager.createDirectory(atPath: diskCachePath, withIntermediateDirectories: true)
    }
    
    private func imageSize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

// MARK: - String Extension for MD5

extension String {
    func md5() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: 16)
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// 需要导入 CommonCrypto
// 在 Bridging-Header.h 中添加：#import <CommonCrypto/CommonCrypto.h>
