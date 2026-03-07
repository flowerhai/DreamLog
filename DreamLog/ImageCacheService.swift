//
//  ImageCacheService.swift
//  DreamLog
//
//  图片缓存服务 - 优化图片加载性能
//

import Foundation
import SwiftUI
import UIKit

// MARK: - 图片缓存服务

@MainActor
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    // 内存缓存
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // 磁盘缓存目录
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("DreamLogImages", isDirectory: true)
    }
    
    // 缓存限制
    private let maxMemoryCount = 100
    private let maxDiskSize: Int64 = 100 * 1024 * 1024 // 100MB
    
    private init() {
        memoryCache.countLimit = maxMemoryCount
        setupCacheDirectory()
        cleanDiskCacheIfNeeded()
    }
    
    // MARK: - 缓存目录设置
    
    private func setupCacheDirectory() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    private func cleanDiskCacheIfNeeded() {
        guard let resources = try? fileManager.attributesOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) else {
            return
        }
        
        let totalSize = resources[.totalFileAllocatedSizeKey] as? Int64 ?? 0
        
        if totalSize > maxDiskSize {
            Task.detached {
                await self.cleanDiskCache()
            }
        }
    }
    
    private func cleanDiskCache() async {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        // 按创建时间排序，删除最旧的文件
        let sorted = contents.compactMap { url -> (URL, Date)? in
            guard let date = try? url.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                return nil
            }
            return (url, date)
        }.sorted { $0.1 > $1.1 }
        
        // 删除 50% 的旧文件
        let toDelete = sorted.prefix(sorted.count / 2)
        for (url, _) in toDelete {
            try? fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - 获取图片
    
    /// 从缓存或网络加载图片
    func loadImage(from urlString: String) async -> UIImage? {
        // 1. 检查内存缓存
        if let cached = memoryCache.object(forKey: urlString as NSString) {
            return cached
        }
        
        // 2. 检查磁盘缓存
        if let diskCached = loadFromDisk(urlString: urlString) {
            memoryCache.setObject(diskCached, forKey: urlString as NSString)
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
            
            return image
        } catch {
            print("❌ 加载图片失败：\(error)")
            return nil
        }
    }
    
    // MARK: - 缓存图片
    
    /// 缓存图片到内存和磁盘
    func cacheImage(_ image: UIImage, urlString: String) {
        // 内存缓存
        memoryCache.setObject(image, forKey: urlString as NSString)
        
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
    func clearCache() {
        memoryCache.removeAllObjects()
        
        try? fileManager.removeItem(at: cacheDirectory)
        setupCacheDirectory()
    }
    
    /// 清除内存缓存
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    /// 清除磁盘缓存
    func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        setupCacheDirectory()
    }
    
    // MARK: - 缓存统计
    
    var memoryCacheCount: Int {
        memoryCache.count
    }
    
    var diskCacheSize: Int64 {
        guard let resources = try? fileManager.attributesOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.totalFileAllocatedSizeKey]) else {
            return 0
        }
        return resources[.totalFileAllocatedSizeKey] as? Int64 ?? 0
    }
    
    var diskCacheSizeFormatted: String {
        let size = diskCacheSize
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
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
