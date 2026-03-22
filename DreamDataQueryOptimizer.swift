//
//  DreamDataQueryOptimizer.swift
//  DreamLog
//
//  Phase 89 Session 2: Core Data 查询优化
//  创建时间：2026-03-22
//

import Foundation
import SwiftData

// MARK: - 查询优化器

/// Core Data 查询优化器 - 提供优化的查询配置和缓存
actor DreamDataQueryOptimizer {
    
    // MARK: - 单例
    
    static let shared = DreamDataQueryOptimizer()
    
    // MARK: - 查询缓存
    
    private var queryCache: [String: CachedQueryResult] = [:]
    private let cacheQueue = DispatchQueue(label: "com.dreamlog.query.cache", attributes: .concurrent)
    
    // 缓存配置
    private let maxCacheSize = 100
    private let defaultCacheTimeout: TimeInterval = 300 // 5 分钟
    
    // MARK: - 优化的 FetchDescriptor 工厂方法
    
    /// 创建优化的梦境查询描述符
    /// - Parameters:
    ///   - predicate: 过滤条件
    ///   - sortBy: 排序键路径
    ///   - order: 排序顺序
    ///   - fetchLimit: 获取限制
    ///   - fetchBatchSize: 批量获取大小
    /// - Returns: 优化的 FetchDescriptor
    func createOptimizedDescriptor<D: PersistentModel>(
        predicate: Predicate<D>? = nil,
        sortBy: [SortDescriptor<D>],
        order: SortOrder = .forward,
        fetchLimit: Int = 0,
        fetchBatchSize: Int = 20
    ) -> FetchDescriptor<D> {
        var descriptor = FetchDescriptor<D>(
            predicate: predicate,
            sortBy: sortBy
        )
        
        // 设置批量获取大小 - 减少内存峰值
        descriptor.fetchBatchSize = fetchBatchSize
        
        // 设置获取限制
        if fetchLimit > 0 {
            descriptor.fetchLimit = fetchLimit
        }
        
        return descriptor
    }
    
    /// 创建带关系预加载的查询描述符
    /// - Parameters:
    ///   - predicate: 过滤条件
    ///   - sortBy: 排序
    ///   - relationships: 需要预加载的关系
    /// - Returns: 优化的 FetchDescriptor
    func createDescriptorWithPrefetch<D: PersistentModel>(
        predicate: Predicate<D>? = nil,
        sortBy: [SortDescriptor<D>],
        relationships: [KeyPath<D, any PersistentModel>?]
    ) -> FetchDescriptor<D> {
        var descriptor = createOptimizedDescriptor(
            predicate: predicate,
            sortBy: sortBy
        )
        
        // 预加载关系 - 减少 N+1 查询问题
        descriptor.relationshipsToPrefetch = relationships
        
        return descriptor
    }
    
    // MARK: - 查询缓存方法
    
    /// 从缓存获取查询结果，如果不存在则执行查询
    /// - Parameters:
    ///   - cacheKey: 缓存键
    ///   - modelContext: 模型上下文
    ///   - descriptor: 查询描述符
    ///   - timeout: 缓存超时时间
    /// - Returns: 查询结果
    func fetchWithCache<D: PersistentModel>(
        cacheKey: String,
        modelContext: ModelContext,
        descriptor: FetchDescriptor<D>,
        timeout: TimeInterval? = nil
    ) throws -> [D] {
        // 检查缓存
        if let cached = getCachedResult(forKey: cacheKey) {
            return cached.results as? [D] ?? []
        }
        
        // 执行查询
        let results = try modelContext.fetch(descriptor)
        
        // 缓存结果
        cacheResult(
            forKey: cacheKey,
            results: results,
            timeout: timeout ?? defaultCacheTimeout
        )
        
        return results
    }
    
    /// 清除查询缓存
    func clearCache() {
        queryCache.removeAll()
    }
    
    /// 清除过期缓存
    func clearExpiredCache() {
        let now = Date()
        queryCache = queryCache.filter { _, cached in
            cached.expiresAt > now
        }
    }
    
    // MARK: - 私有缓存方法
    
    private func getCachedResult(forKey key: String) -> CachedQueryResult? {
        cacheQueue.sync {
            return queryCache[key]
        }
    }
    
    private func cacheResult<D>(
        forKey key: String,
        results: [D],
        timeout: TimeInterval
    ) {
        cacheQueue.async(flags: .barrier) {
            // LRU 淘汰策略
            if self.queryCache.count >= self.maxCacheSize {
                if let oldestKey = self.queryCache
                    .min(by: { $0.value.expiresAt < $1.value.expiresAt })?
                    .key {
                    self.queryCache.removeValue(forKey: oldestKey)
                }
            }
            
            self.queryCache[key] = CachedQueryResult(
                results: results,
                expiresAt: Date().addingTimeInterval(timeout)
            )
        }
    }
    
    // MARK: - 查询性能分析
    
    /// 查询性能统计
    struct QueryPerformanceStats {
        let queryKey: String
        let executionTime: TimeInterval
        let resultCount: Int
        let timestamp: Date
    }
    
    private var performanceStats: [QueryPerformanceStats] = []
    private let maxStatsCount = 100
    
    /// 记录查询性能
    func recordQueryPerformance(
        key: String,
        executionTime: TimeInterval,
        resultCount: Int
    ) {
        let stat = QueryPerformanceStats(
            queryKey: key,
            executionTime: executionTime,
            resultCount: resultCount,
            timestamp: Date()
        )
        
        performanceStats.append(stat)
        
        // 限制统计数量
        if performanceStats.count > maxStatsCount {
            performanceStats.removeFirst(performanceStats.count - maxStatsCount)
        }
    }
    
    /// 获取慢查询列表
    func getSlowQueries(threshold: TimeInterval = 0.1) -> [QueryPerformanceStats] {
        return performanceStats.filter { $0.executionTime > threshold }
    }
    
    /// 获取查询性能报告
    func getPerformanceReport() -> String {
        let slowQueries = getSlowQueries()
        let avgTime = performanceStats.isEmpty ? 0 :
            performanceStats.map { $0.executionTime }.reduce(0, +) / Double(performanceStats.count)
        
        var report = "=== 查询性能报告 ===\n"
        report += "总查询数：\(performanceStats.count)\n"
        report += "平均执行时间：\(String(format: "%.3f", avgTime))s\n"
        report += "慢查询数：\(slowQueries.count)\n"
        
        if !slowQueries.isEmpty {
            report += "\n慢查询详情:\n"
            for stat in slowQueries.prefix(10) {
                report += "- \(stat.queryKey): \(String(format: "%.3f", stat.executionTime))s (\(stat.resultCount) 条结果)\n"
            }
        }
        
        return report
    }
}

// MARK: - 缓存结果结构

/// 缓存的查询结果
private struct CachedQueryResult {
    let results: Any
    let expiresAt: Date
}

// MARK: - 常用查询优化器扩展

extension DreamDataQueryOptimizer {
    
    // MARK: - 梦境查询优化
    
    /// 创建按日期范围查询的描述符
    func createDreamsByDateRangeDescriptor(
        startDate: Date,
        endDate: Date,
        sortBy: SortDescriptor<Dream> = SortDescriptor(\Dream.date, order: .reverse)
    ) -> FetchDescriptor<Dream> {
        return createOptimizedDescriptor(
            predicate: #Predicate<Dream> { dream in
                dream.date >= startDate && dream.date <= endDate
            },
            sortBy: [sortBy],
            fetchBatchSize: 50
        )
    }
    
    /// 创建按标签查询的描述符
    func createDreamsByTagDescriptor(
        tag: String,
        sortBy: SortDescriptor<Dream> = SortDescriptor(\Dream.date, order: .reverse)
    ) -> FetchDescriptor<Dream> {
        return createOptimizedDescriptor(
            predicate: #Predicate<Dream> { dream in
                dream.tags.contains(tag)
            },
            sortBy: [sortBy],
            fetchBatchSize: 50
        )
    }
    
    /// 创建按情绪查询的描述符
    func createDreamsByEmotionDescriptor(
        emotion: String,
        sortBy: SortDescriptor<Dream> = SortDescriptor(\Dream.date, order: .reverse)
    ) -> FetchDescriptor<Dream> {
        return createOptimizedDescriptor(
            predicate: #Predicate<Dream> { dream in
                dream.emotions.contains(emotion)
            },
            sortBy: [sortBy],
            fetchBatchSize: 50
        )
    }
    
    /// 创建清醒梦查询描述符
    func createLucidDreamsDescriptor(
        sortBy: SortDescriptor<Dream> = SortDescriptor(\Dream.date, order: .reverse)
    ) -> FetchDescriptor<Dream> {
        return createOptimizedDescriptor(
            predicate: #Predicate<Dream> { dream in
                dream.isLucid == true
            },
            sortBy: [sortBy],
            fetchBatchSize: 50
        )
    }
    
    /// 创建最近梦境查询描述符
    func createRecentDreamsDescriptor(
        days: Int = 7,
        sortBy: SortDescriptor<Dream> = SortDescriptor(\Dream.date, order: .reverse)
    ) -> FetchDescriptor<Dream> {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        
        return createOptimizedDescriptor(
            predicate: #Predicate<Dream> { dream in
                dream.date >= startDate
            },
            sortBy: [sortBy],
            fetchLimit: 100,
            fetchBatchSize: 20
        )
    }
}

// MARK: - SwiftData 索引建议

/// SwiftData 索引配置建议
/// 
/// 在 Model 定义中添加索引：
/// 
/// @Attribute(.indexed) var date: Date
/// @Attribute(.indexed) var isLucid: Bool
/// @Attribute(.indexed) var clarity: Int
/// 
/// 复合索引（通过查询优化）：
/// - date + isLucid
/// - date + tags
/// - emotions + date

// MARK: - 查询性能最佳实践

/*
 
 ## 查询性能最佳实践
 
 ### 1. 使用批量获取
 ```swift
 descriptor.fetchBatchSize = 20  // 每次获取 20 条
 ```
 
 ### 2. 设置获取限制
 ```swift
 descriptor.fetchLimit = 100  // 最多获取 100 条
 ```
 
 ### 3. 预加载关系
 ```swift
 descriptor.relationshipsToPrefetch = [\Dream.tags]
 ```
 
 ### 4. 使用精确的谓词
 ```swift
 // 好的谓词 - 可以使用索引
 #Predicate<Dream> { $0.date >= startDate }
 
 // 避免的谓词 - 无法使用索引
 #Predicate<Dream> { $0.content.contains("keyword") }
 ```
 
 ### 5. 后台上下文查询
 ```swift
 Task.detached {
     let context = ModelContext(modelContainer)
     let results = try context.fetch(descriptor)
     await MainActor.run {
         // 更新 UI
     }
 }
 ```
 
 ### 6. 查询结果缓存
 - 对频繁执行的查询使用缓存
 - 设置合理的缓存超时时间
 - 数据变更时清除相关缓存
 
 */

// MARK: - 预览

#Preview {
    VStack {
        Text("查询优化器 - 无 UI 组件")
            .font(.title)
    }
}
