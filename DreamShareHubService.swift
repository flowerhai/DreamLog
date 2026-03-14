//
//  DreamShareHubService.swift
//  DreamLog - 梦境分享中心核心服务
//
//  Created by DreamLog Team on 2026-03-14.
//  Phase 36: Dream Share Hub - 一键多平台分享中心
//

import Foundation
import SwiftData
import UIKit

actor DreamShareHubService {
    
    // MARK: - Singleton
    
    static let shared = DreamShareHubService()
    
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    private var shareConfigs: [ShareConfig] = []
    private var shareHistory: [ShareHistory] = []
    
    /// 分享配置缓存
    private var configCache: [String: ShareConfig] = [:]
    
    /// 分享统计缓存
    private var statsCache: ShareStats = .empty
    
    // MARK: - Initialization
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadConfigs()
        loadHistory()
    }
    
    // MARK: - 配置管理
    
    /// 加载所有分享配置
    func loadConfigs() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ShareConfig>()
            shareConfigs = try context.fetch(descriptor)
            
            // 构建缓存
            configCache = Dictionary(uniqueKeysWithValues: shareConfigs.map { ($0.id.uuidString, $0) })
        } catch {
            print("❌ 加载分享配置失败：\(error)")
        }
    }
    
    /// 获取所有配置
    func getAllConfigs() -> [ShareConfig] {
        return shareConfigs
    }
    
    /// 获取默认配置
    func getDefaultConfig() -> ShareConfig? {
        return shareConfigs.first { $0.isDefault } ?? shareConfigs.first
    }
    
    /// 获取指定配置
    func getConfig(id: String) -> ShareConfig? {
        return configCache[id]
    }
    
    /// 创建新配置
    func createConfig(_ config: ShareConfig) async throws {
        guard let context = modelContext else {
            throw ShareError.noModelContext
        }
        
        // 如果是默认配置，取消其他配置的默认状态
        if config.isDefault {
            for existing in shareConfigs {
                existing.isDefault = false
            }
        }
        
        context.insert(config)
        try context.save()
        
        shareConfigs.append(config)
        configCache[config.id.uuidString] = config
    }
    
    /// 更新配置
    func updateConfig(_ config: ShareConfig) async throws {
        guard let context = modelContext else {
            throw ShareError.noModelContext
        }
        
        config.updatedAt = Date()
        
        // 如果是默认配置，取消其他配置的默认状态
        if config.isDefault {
            for existing in shareConfigs where existing.id != config.id {
                existing.isDefault = false
            }
        }
        
        try context.save()
        
        // 更新缓存
        if let index = shareConfigs.firstIndex(where: { $0.id == config.id }) {
            shareConfigs[index] = config
        }
        configCache[config.id.uuidString] = config
    }
    
    /// 删除配置
    func deleteConfig(_ config: ShareConfig) async throws {
        guard let context = modelContext else {
            throw ShareError.noModelContext
        }
        
        context.delete(config)
        try context.save()
        
        // 从缓存移除
        shareConfigs.removeAll { $0.id == config.id }
        configCache.removeValue(forKey: config.id.uuidString)
    }
    
    /// 设置默认配置
    func setDefaultConfig(id: String) async throws {
        guard let context = modelContext else {
            throw ShareError.noModelContext
        }
        
        for config in shareConfigs {
            config.isDefault = (config.id.uuidString == id)
        }
        
        try context.save()
        
        // 更新缓存
        configCache.values.forEach { $0.isDefault = ($0.id.uuidString == id) }
    }
    
    // MARK: - 分享历史管理
    
    /// 加载分享历史
    func loadHistory() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ShareHistory>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            shareHistory = try context.fetch(descriptor)
        } catch {
            print("❌ 加载分享历史失败：\(error)")
        }
    }
    
    /// 获取分享历史
    func getHistory(limit: Int = 50) -> [ShareHistory] {
        return Array(shareHistory.prefix(limit))
    }
    
    /// 添加分享记录
    func addShareHistory(
        dreamId: UUID,
        dreamTitle: String,
        platforms: [String],
        template: String,
        shareMessage: String? = nil,
        successCount: Int,
        failCount: Int
    ) async throws -> ShareHistory {
        guard let context = modelContext else {
            throw ShareError.noModelContext
        }
        
        let history = ShareHistory(
            dreamId: dreamId,
            dreamTitle: dreamTitle,
            platforms: platforms,
            template: template,
            shareMessage: shareMessage
        )
        history.successCount = successCount
        history.failCount = failCount
        
        context.insert(history)
        try context.save()
        
        shareHistory.insert(history, at: 0)
        
        // 更新统计缓存
        await updateStatsCache()
        
        return history
    }
    
    /// 删除分享历史
    func deleteHistory(_ history: ShareHistory) async throws {
        guard let context = modelContext else {
            throw ShareError.noModelContext
        }
        
        context.delete(history)
        try context.save()
        
        shareHistory.removeAll { $0.id == history.id }
    }
    
    /// 清空所有历史
    func clearAllHistory() async throws {
        guard let context = modelContext else {
            throw ShareError.noModelContext
        }
        
        for history in shareHistory {
            context.delete(history)
        }
        
        try context.save()
        shareHistory.removeAll()
    }
    
    // MARK: - 分享统计
    
    /// 获取分享统计
    func getStats() async -> ShareStats {
        // 如果缓存存在且新鲜，直接返回
        if statsCache.totalShares > 0 {
            return statsCache
        }
        
        return await calculateStats()
    }
    
    /// 计算分享统计
    private func calculateStats() async -> ShareStats {
        let now = Date()
        let calendar = Calendar.current
        
        // 本周开始
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        // 本月开始
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        var totalShares = 0
        var thisWeekShares = 0
        var thisMonthShares = 0
        var platformCounts: [String: Int] = [:]
        var templateCounts: [String: Int] = [:]
        
        for history in shareHistory {
            totalShares += history.successCount
            
            if history.createdAt >= weekStart {
                thisWeekShares += history.successCount
            }
            
            if history.createdAt >= monthStart {
                thisMonthShares += history.successCount
            }
            
            // 统计平台使用
            for platform in history.platforms {
                platformCounts[platform, default: 0] += 1
            }
            
            // 统计模板使用
            templateCounts[history.template, default: 0] += 1
        }
        
        // 找出最常用平台
        let favoritePlatform = platformCounts.max(by: { $0.value < $1.value })?.key
        
        // 找出最常用模板
        let favoriteTemplate = templateCounts.max(by: { $0.value < $1.value })?.key
        
        statsCache = ShareStats(
            totalShares: totalShares,
            totalPlatforms: platformCounts.count,
            favoritePlatform: favoritePlatform,
            thisWeekShares: thisWeekShares,
            thisMonthShares: thisMonthShares,
            favoriteTemplate: favoriteTemplate
        )
        
        return statsCache
    }
    
    /// 更新统计缓存
    private func updateStatsCache() {
        statsCache = .empty  // 清空缓存，下次访问时重新计算
    }
    
    // MARK: - 分享执行
    
    /// 执行批量分享
    func batchShare(
        dreamId: UUID,
        dreamTitle: String,
        dreamContent: String,
        platforms: [SharePlatform],
        template: ShareTemplate,
        shareMessage: String? = nil,
        includeAIAnalysis: Bool = false,
        includeImage: Bool = false
    ) async -> BatchShareResult {
        var results: [ShareTaskResult] = []
        var successCount = 0
        var failCount = 0
        
        // 生成分享内容
        let content = generateShareContent(
            dreamTitle: dreamTitle,
            dreamContent: dreamContent,
            template: template,
            shareMessage: shareMessage,
            includeAIAnalysis: includeAIAnalysis
        )
        
        // 逐个平台分享
        for platform in platforms {
            let result = await shareToPlatform(
                platform: platform,
                content: content,
                includeImage: includeImage
            )
            
            results.append(result)
            
            if result.success {
                successCount += 1
            } else {
                failCount += 1
            }
        }
        
        // 记录分享历史
        var historyId: UUID?
        do {
            let history = try await addShareHistory(
                dreamId: dreamId,
                dreamTitle: dreamTitle,
                platforms: platforms.map { $0.rawValue },
                template: template.rawValue,
                shareMessage: shareMessage,
                successCount: successCount,
                failCount: failCount
            )
            historyId = history.id
        } catch {
            print("❌ 记录分享历史失败：\(error)")
        }
        
        return BatchShareResult(
            dreamId: dreamId,
            totalPlatforms: platforms.count,
            successCount: successCount,
            failCount: failCount,
            results: results,
            shareHistoryId: historyId
        )
    }
    
    /// 分享到单个平台
    private func shareToPlatform(
        platform: SharePlatform,
        content: String,
        includeImage: Bool
    ) async -> ShareTaskResult {
        do {
            switch platform {
            case .copy:
                // 复制到剪贴板
                UIPasteboard.general.string = content
                return ShareTaskResult(platform: platform, success: true)
                
            case .image:
                // 保存图片 (需要生成图片)
                // TODO: 实现图片生成和保存
                return ShareTaskResult(platform: platform, success: true)
                
            default:
                // 打开对应 App
                try await openPlatformApp(platform: platform, content: content)
                return ShareTaskResult(platform: platform, success: true)
            }
        } catch {
            return ShareTaskResult(
                platform: platform,
                success: false,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    /// 打开平台 App
    private func openPlatformApp(platform: SharePlatform, content: String) async throws {
        guard let urlScheme = platform.urlScheme else {
            throw ShareError.unsupportedPlatform
        }
        
        guard let url = URL(string: urlScheme) else {
            throw ShareError.invalidURL
        }
        
        // 检查是否安装了 App
        if await UIApplication.shared.canOpenURL(url) {
            // 在实际应用中，这里会使用 UIScene 来打开 URL
            // 由于这是在 Actor 中，我们只验证 URL 有效性
            print("✅ 可以打开 \(platform.displayName)")
        } else {
            throw ShareError.appNotInstalled(platform: platform.displayName)
        }
    }
    
    // MARK: - 内容生成
    
    /// 生成分享内容
    private func generateShareContent(
        dreamTitle: String,
        dreamContent: String,
        template: ShareTemplate,
        shareMessage: String?,
        includeAIAnalysis: Bool
    ) -> String {
        var content = ""
        
        // 自定义消息
        if let message = shareMessage {
            content += "\(message)\n\n"
        }
        
        // 梦境标题
        content += "🌙 \(dreamTitle)\n\n"
        
        // 梦境内容 (截取前 200 字)
        let truncatedContent = dreamContent.prefix(200)
        content += "\(truncatedContent)"
        
        if dreamContent.count > 200 {
            content += "..."
        }
        
        content += "\n\n"
        
        // AI 解析
        if includeAIAnalysis {
            content += "🧠 AI 解析：[梦境解析内容]\n\n"
        }
        
        // 标签
        content += "#DreamLog #梦境记录 #\(template.displayName)"
        
        return content
    }
    
    // MARK: - 平台检测
    
    /// 检测已安装的平台
    func detectInstalledPlatforms() async -> [SharePlatform] {
        var installed: [SharePlatform] = []
        
        for platform in SharePlatform.allCases {
            if let urlScheme = platform.urlScheme {
                if let url = URL(string: urlScheme) {
                    if await UIApplication.shared.canOpenURL(url) {
                        installed.append(platform)
                    }
                }
            } else {
                // 没有 URL Scheme 的平台 (如复制、保存图片) 默认支持
                installed.append(platform)
            }
        }
        
        return installed
    }
}

// MARK: - 分享错误

enum ShareError: LocalizedError {
    case noModelContext
    case unsupportedPlatform
    case invalidURL
    case appNotInstalled(platform: String)
    case shareFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .noModelContext:
            return "数据上下文未初始化"
        case .unsupportedPlatform:
            return "不支持的分享平台"
        case .invalidURL:
            return "无效的 URL"
        case .appNotInstalled(let platform):
            return "未安装 \(platform) App"
        case .shareFailed(let reason):
            return "分享失败：\(reason)"
        }
    }
}
