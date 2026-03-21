//
//  DreamShareHubEnhancedService.swift
//  DreamLog
//
//  Phase 82 - 梦境分享中心增强
//  核心服务层
//

import Foundation
import SwiftData
import UIKit

// MARK: - 分享中心增强服务

@ModelActor
actor DreamShareHubEnhancedService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 分享链接管理
    
    /// 创建分享链接
    func createShareLink(dreamId: UUID, title: String, description: String? = nil, expiresAt: Date? = nil, password: String? = nil) async throws -> DreamShareLink {
        let link = DreamShareLink(
            dreamId: dreamId,
            title: title,
            description: description,
            expiresAt: expiresAt,
            password: password
        )
        
        modelContext.insert(link)
        try modelContext.save()
        
        return link
    }
    
    /// 获取分享链接
    func getShareLink(shortCode: String) async throws -> DreamShareLink? {
        let descriptor = FetchDescriptor<DreamShareLink>(
            predicate: #Predicate { $0.shortCode == shortCode }
        )
        
        let links = try modelContext.fetch(descriptor)
        return links.first
    }
    
    /// 获取梦境的所有分享链接
    func getShareLinks(for dreamId: UUID) async throws -> [DreamShareLink] {
        let descriptor = FetchDescriptor<DreamShareLink>(
            predicate: #Predicate { $0.dreamId == dreamId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取所有活跃分享链接
    func getAllActiveShareLinks() async throws -> [DreamShareLink] {
        let descriptor = FetchDescriptor<DreamShareLink>(
            predicate: #Predicate { $0.isActive && ($0.expiresAt == nil || $0.expiresAt! > Date()) },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 更新链接访问计数
    func incrementViewCount(for shortCode: String) async throws {
        guard let link = try getShareLink(shortCode: shortCode) else { return }
        
        link.viewCount += 1
        link.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 更新链接点击计数
    func incrementClickCount(for shortCode: String) async throws {
        guard let link = try getShareLink(shortCode: shortCode) else { return }
        
        link.clickCount += 1
        link.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 停用分享链接
    func deactivateShareLink(_ link: DreamShareLink) async throws {
        link.isActive = false
        link.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 删除分享链接
    func deleteShareLink(_ link: DreamShareLink) async throws {
        modelContext.delete(link)
        try modelContext.save()
    }
    
    /// 清理过期链接
    func cleanupExpiredLinks() async throws {
        let descriptor = FetchDescriptor<DreamShareLink>(
            predicate: #Predicate { $0.expiresAt != nil && $0.expiresAt! < Date() && $0.isActive }
        )
        
        let expiredLinks = try modelContext.fetch(descriptor)
        
        for link in expiredLinks {
            link.isActive = false
            link.updatedAt = Date()
        }
        
        try modelContext.save()
    }
    
    // MARK: - 分享统计
    
    /// 记录分享
    func recordShare(platform: SharePlatform, contentType: ShareContentType, dreamId: UUID) async throws {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 获取或创建今日统计
        let descriptor = FetchDescriptor<DreamShareStatistics>(
            predicate: #Predicate { $0.date == today }
        )
        
        var stats = try modelContext.fetch(descriptor).first
        
        if stats == nil {
            stats = DreamShareStatistics(date: today)
            modelContext.insert(stats!)
        }
        
        stats?.addShare(platform: platform)
        stats?.addShare(contentType: contentType.rawValue)
        
        try modelContext.save()
    }
    
    /// 获取分享统计
    func getShareStatistics(days: Int = 30) async throws -> ShareAnalytics {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<DreamShareStatistics>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date)]
        )
        
        let statsList = try modelContext.fetch(descriptor)
        
        var analytics = ShareAnalytics()
        
        for stats in statsList {
            analytics.totalShares += stats.totalShares
            analytics.totalViews += stats.totalViews
            analytics.totalClicks += stats.totalClicks
            
            // 合并平台数据
            for (platform, count) in stats.sharesByPlatform {
                analytics.sharesByPlatform[platform, default: 0] += count
            }
            
            // 合并内容类型数据
            for (type, count) in stats.sharesByContentType {
                analytics.sharesByContentType[type, default: 0] += count
            }
        }
        
        // 获取热门分享梦境
        analytics.topSharedDreams = try await getTopSharedDreams(limit: 10)
        
        return analytics
    }
    
    /// 获取热门分享梦境
    private func getTopSharedDreams(limit: Int) async throws -> [DreamShareStat] {
        // 简化实现：返回空数组
        // 实际实现需要关联 Dream 模型进行统计
        return []
    }
    
    /// 获取趋势数据
    func getShareTrend(days: Int = 30) async throws -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<DreamShareStatistics>(
            predicate: #Predicate { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date)]
        )
        
        let statsList = try modelContext.fetch(descriptor)
        
        return statsList.map { ($0.date, $0.totalShares) }
    }
    
    // MARK: - 模板管理
    
    /// 获取所有模板
    func getTemplates(category: TemplateCategory? = nil, platform: SharePlatform? = nil) async throws -> [DreamShareTemplate] {
        var predicate: Predicate<DreamShareTemplate>? = nil
        
        if let category = category, let platform = platform {
            predicate = #Predicate { $0.category.rawValue == category.rawValue && $0.platform?.rawValue == platform.rawValue }
        } else if let category = category {
            predicate = #Predicate { $0.category.rawValue == category.rawValue }
        } else if let platform = platform {
            predicate = #Predicate { $0.platform?.rawValue == platform.rawValue }
        }
        
        let descriptor = FetchDescriptor<DreamShareTemplate>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.isPreset, order: .reverse), SortDescriptor(\.usageCount, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取预设模板
    func getPresetTemplates() async throws -> [DreamShareTemplate] {
        let descriptor = FetchDescriptor<DreamShareTemplate>(
            predicate: #Predicate { $0.isPreset == true },
            sortBy: [SortDescriptor(\.category), SortDescriptor(\.name)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取收藏模板
    func getFavoriteTemplates() async throws -> [DreamShareTemplate] {
        let descriptor = FetchDescriptor<DreamShareTemplate>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 切换模板收藏状态
    func toggleFavorite(_ template: DreamShareTemplate) async throws {
        template.isFavorite.toggle()
        template.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 增加模板使用计数
    func incrementTemplateUsage(_ template: DreamShareTemplate) async throws {
        template.usageCount += 1
        template.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 保存自定义模板
    func saveCustomTemplate(_ template: DreamShareTemplate) async throws {
        template.isPreset = false
        template.updatedAt = Date()
        
        modelContext.insert(template)
        try modelContext.save()
    }
    
    /// 删除自定义模板
    func deleteCustomTemplate(_ template: DreamShareTemplate) async throws {
        guard !template.isPreset else {
            throw ShareError.cannotDeletePreset
        }
        
        modelContext.delete(template)
        try modelContext.save()
    }
    
    // MARK: - 成就系统
    
    /// 获取所有成就
    func getAchievements() async throws -> [DreamShareAchievement] {
        let descriptor = FetchDescriptor<DreamShareAchievement>(
            sortBy: [SortDescriptor(\.type)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取未解锁成就
    func getLockedAchievements() async throws -> [DreamShareAchievement] {
        let descriptor = FetchDescriptor<DreamShareAchievement>(
            predicate: #Predicate { $0.isUnlocked == false },
            sortBy: [SortDescriptor(\.requirement)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取已解锁成就
    func getUnlockedAchievements() async throws -> [DreamShareAchievement] {
        let descriptor = FetchDescriptor<DreamShareAchievement>(
            predicate: #Predicate { $0.isUnlocked == true },
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 更新成就进度
    func updateAchievementProgress(type: AchievementType, newValue: Int) async throws {
        let descriptor = FetchDescriptor<DreamShareAchievement>(
            predicate: #Predicate { $0.type.rawValue == type.rawValue }
        )
        
        var achievements = try modelContext.fetch(descriptor)
        
        if achievements.isEmpty {
            // 创建新成就
            let achievement = createAchievement(type: type)
            modelContext.insert(achievement)
            achievements = [achievement]
        }
        
        for achievement in achievements {
            achievement.updateProgress(to: newValue)
        }
        
        try modelContext.save()
    }
    
    /// 创建成就实例
    private func createAchievement(type: AchievementType) -> DreamShareAchievement {
        switch type {
        case .firstShare:
            return DreamShareAchievement(
                type: type,
                name: "首次分享",
                description: "完成第一次梦境分享",
                icon: "star.fill",
                requirement: 1
            )
        case .shareNovice:
            return DreamShareAchievement(
                type: type,
                name: "分享新手",
                description: "完成 10 次分享",
                icon: "star.circle.fill",
                requirement: 10
            )
        case .shareExpert:
            return DreamShareAchievement(
                type: type,
                name: "分享专家",
                description: "完成 50 次分享",
                icon: "star.square.fill",
                requirement: 50
            )
        case .shareMaster:
            return DreamShareAchievement(
                type: type,
                name: "分享大师",
                description: "完成 100 次分享",
                icon: "star.square.on.square.fill",
                requirement: 100
            )
        case .multiPlatform:
            return DreamShareAchievement(
                type: type,
                name: "多平台分享者",
                description: "在 5 个不同平台分享",
                icon: "globe",
                requirement: 5
            )
        case .popularCreator:
            return DreamShareAchievement(
                type: type,
                name: "热门创作者",
                description: "单次分享获得 100+ 浏览",
                icon: "flame.fill",
                requirement: 100
            )
        case .viralShare:
            return DreamShareAchievement(
                type: type,
                name: "病毒式分享",
                description: "单次分享获得 1000+ 浏览",
                icon: "sparkles",
                requirement: 1000
            )
        case .creativeSharer:
            return DreamShareAchievement(
                type: type,
                name: "创意分享家",
                description: "使用 10 种不同模板分享",
                icon: "paintpalette.fill",
                requirement: 10
            )
        }
    }
    
    // MARK: - 分享任务管理
    
    /// 创建分享任务
    func createShareTask(dreamId: UUID, platforms: [SharePlatform], contentType: ShareContentType, scheduledAt: Date? = nil) async throws -> DreamShareTask {
        let task = DreamShareTask(
            dreamId: dreamId,
            platforms: platforms,
            contentType: contentType,
            scheduledAt: scheduledAt
        )
        
        modelContext.insert(task)
        try modelContext.save()
        
        return task
    }
    
    /// 获取待处理任务
    func getPendingTasks() async throws -> [DreamShareTask] {
        let descriptor = FetchDescriptor<DreamShareTask>(
            predicate: #Predicate { $0.status == .pending },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取所有任务
    func getAllTasks(status: ShareTaskStatus? = nil) async throws -> [DreamShareTask] {
        var predicate: Predicate<DreamShareTask>? = nil
        
        if let status = status {
            predicate = #Predicate { $0.status == status }
        }
        
        let descriptor = FetchDescriptor<DreamShareTask>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 更新任务状态
    func updateTaskStatus(_ task: DreamShareTask, status: ShareTaskStatus, errorMessage: String? = nil) async throws {
        task.status = status
        if status == .completed || status == .failed || status == .cancelled {
            task.completedAt = Date()
        }
        task.errorMessage = errorMessage
        
        try modelContext.save()
    }
    
    /// 取消任务
    func cancelTask(_ task: DreamShareTask) async throws {
        try await updateTaskStatus(task, status: .cancelled)
    }
    
    /// 删除任务
    func deleteTask(_ task: DreamShareTask) async throws {
        modelContext.delete(task)
        try modelContext.save()
    }
    
    // MARK: - 平台检测
    
    /// 检测已安装的平台
    func getInstalledPlatforms() -> [SharePlatform] {
        SharePlatform.allCases.filter { $0.isInstalled }
    }
    
    /// 获取推荐分享平台
    func getRecommendedPlatforms(for contentType: ShareContentType) -> [SharePlatform] {
        switch contentType {
        case .image, .card:
            return [.wechatMoments, .xiaohongshu, .instagram, .weibo]
        case .video:
            return [.douyin, .tiktok, .bilibili]
        case .story:
            return [.wechat, .medium, .zhihu]
        case .link:
            return [.wechat, .telegram, .discord]
        case .text:
            return [.twitter, .weibo, .telegram]
        }
    }
}

// MARK: - 分享分析数据结构

struct ShareAnalytics {
    var totalShares: Int = 0
    var sharesByPlatform: [String: Int] = [:]
    var sharesByContentType: [String: Int] = [:]
    var totalViews: Int = 0
    var totalClicks: Int = 0
    var topSharedDreams: [DreamShareStat] = []
    var trendData: [(date: Date, count: Int)] = []
    
    /// 预估互动数 (浏览 * 0.1 + 点击 * 0.5)
    var estimatedEngagements: Int {
        Int(Double(totalViews) * 0.1) + Int(Double(totalClicks) * 0.5)
    }
}

struct DreamShareStat {
    var dreamId: UUID
    var title: String
    var shareCount: Int
    var viewCount: Int
    var clickCount: Int
}

// MARK: - 错误类型

enum ShareError: LocalizedError {
    case linkNotFound
    case linkExpired
    case invalidPassword
    case cannotDeletePreset
    case platformNotInstalled
    case shareFailed(String)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .linkNotFound:
            return "分享链接不存在"
        case .linkExpired:
            return "分享链接已过期"
        case .invalidPassword:
            return "密码错误"
        case .cannotDeletePreset:
            return "无法删除预设模板"
        case .platformNotInstalled:
            return "目标应用未安装"
        case .shareFailed(let message):
            return "分享失败：\(message)"
        case .invalidConfiguration:
            return "配置无效"
        }
    }
}

// MARK: - CGSize Extension

extension CGSize {
    init(width: Int, height: Int) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}
