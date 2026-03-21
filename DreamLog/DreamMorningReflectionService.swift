//
//  DreamMorningReflectionService.swift
//  DreamLog
//
//  Phase 79: Morning Reflection Guide - 晨间反思引导
//  晨间反思核心服务
//

import Foundation
import SwiftData
import UserNotifications

@available(iOS 17.0, *)
@ModelActor
public actor DreamMorningReflectionService {
    
    // MARK: - Properties
    
    public let modelContext: ModelContext
    private let notificationCenter: UNUserNotificationCenter
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.notificationCenter = UNUserNotificationCenter.current()
    }
    
    // MARK: - 反思管理
    
    /// 创建晨间反思
    public func createReflection(
        dreamId: UUID? = nil,
        type: MorningReflectionType,
        content: String,
        mood: String? = nil,
        tags: [String] = []
    ) throws -> DreamMorningReflection {
        let reflection = DreamMorningReflection(
            dreamId: dreamId,
            type: type,
            content: content,
            mood: mood,
            tags: tags
        )
        
        modelContext.insert(reflection)
        try modelContext.save()
        
        return reflection
    }
    
    /// 更新反思
    public func updateReflection(
        id: UUID,
        content: String? = nil,
        mood: String? = nil,
        tags: [String]? = nil,
        isCompleted: Bool? = nil
    ) throws {
        let fetchDescriptor = FetchDescriptor<DreamMorningReflection>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let reflection = try modelContext.fetch(fetchDescriptor).first else {
            throw MorningReflectionError.notFound
        }
        
        if let content = content {
            reflection.content = content
        }
        if let mood = mood {
            reflection.mood = mood
        }
        if let tags = tags {
            reflection.tags = tags
        }
        if let isCompleted = isCompleted {
            reflection.isCompleted = isCompleted
        }
        
        reflection.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 删除反思
    public func deleteReflection(id: UUID) throws {
        let fetchDescriptor = FetchDescriptor<DreamMorningReflection>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let reflection = try modelContext.fetch(fetchDescriptor).first else {
            throw MorningReflectionError.notFound
        }
        
        modelContext.delete(reflection)
        try modelContext.save()
    }
    
    /// 获取今日反思
    public func getTodayReflections() throws -> [DreamMorningReflection] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let fetchDescriptor = FetchDescriptor<DreamMorningReflection>(
            predicate: #Predicate { $0.date >= startOfDay },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// 获取所有反思
    public func getAllReflections(limit: Int = 100) throws -> [DreamMorningReflection] {
        let fetchDescriptor = FetchDescriptor<DreamMorningReflection>(
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: limit
        )
        
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// 获取指定梦境的反思
    public func getReflectionsForDream(dreamId: UUID) throws -> [DreamMorningReflection] {
        let fetchDescriptor = FetchDescriptor<DreamMorningReflection>(
            predicate: #Predicate { $0.dreamId == dreamId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return try modelContext.fetch(fetchDescriptor)
    }
    
    // MARK: - 统计
    
    /// 获取反思统计
    public func getStatistics() throws -> MorningReflectionStats {
        let allReflections = try getAllReflections(limit: 1000)
        let todayReflections = try getTodayReflections()
        
        // 按类型统计
        var reflectionsByType: [MorningReflectionType: Int] = [:]
        for type in MorningReflectionType.allCases {
            reflectionsByType[type] = allReflections.filter { $0.type == type }.count
        }
        
        // 计算连续天数
        let streakDays = calculateStreakDays(reflections: allReflections)
        
        // 计算最常见标签
        let tagFrequency = Dictionary(grouping: allReflections.flatMap { $0.tags }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        return MorningReflectionStats(
            totalReflections: allReflections.count,
            completedToday: todayReflections.filter { $0.isCompleted }.count,
            streakDays: streakDays,
            reflectionsByType: reflectionsByType,
            mostCommonTags: tagFrequency
        )
    }
    
    /// 计算连续反思天数
    private func calculateStreakDays(reflections: [DreamMorningReflection]) -> Int {
        guard !reflections.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 按日期分组
        let dates = Set(reflections.map { calendar.startOfDay(for: $0.date) })
        
        var streak = 0
        var currentDate = today
        
        while dates.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    // MARK: - 通知
    
    /// 请求通知权限
    public func requestNotificationAuthorization() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()
        
        if settings.authorizationStatus == .authorized {
            return true
        }
        
        return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    /// 调度晨间反思提醒
    public func scheduleMorningReminder(time: String = "07:00") async throws {
        guard try await requestNotificationAuthorization() else {
            throw MorningReflectionError.notificationNotAuthorized
        }
        
        // 取消现有提醒
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: ["morning-reflection"])
        
        // 创建新提醒
        let content = UNMutableNotificationContent()
        content.title = "🌅 晨间反思时间"
        content.body = "花几分钟回顾你的梦境，发现潜意识的智慧"
        content.sound = .default
        content.categoryIdentifier = "morning-reflection"
        
        // 解析时间
        let components = time.split(separator: ":").map { Int($0) ?? 0 }
        guard components.count == 2 else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "morning-reflection",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    /// 取消晨间提醒
    public func cancelMorningReminder() async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: ["morning-reflection"])
    }
    
    // MARK: - 配置管理
    
    private let configKey = "MorningReflectionConfig"
    
    /// 保存配置
    public func saveConfig(_ config: MorningReflectionConfig) throws {
        let data = try JSONEncoder().encode(config)
        UserDefaults.standard.set(data, forKey: configKey)
    }
    
    /// 加载配置
    public func loadConfig() -> MorningReflectionConfig {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let config = try? JSONDecoder().decode(MorningReflectionConfig.self, from: data) else {
            return .default
        }
        return config
    }
    
    /// 标记反思为完成
    public func markReflectionCompleted(id: UUID) throws {
        try updateReflection(id: id, isCompleted: true)
    }
    
    // MARK: - 导出
    
    /// 导出反思为 Markdown
    public func exportReflectionsToMarkdown(reflections: [DreamMorningReflection]) -> String {
        var markdown = "# 晨间反思记录\n\n"
        markdown += "生成时间：\(Date().formatted())\n\n"
        markdown += "---\n\n"
        
        for reflection in reflections {
            markdown += "## \(reflection.type.icon) \(reflection.type.title)\n\n"
            markdown += "**日期**: \(reflection.date.formatted())\n\n"
            if let mood = reflection.mood {
                markdown += "**情绪**: \(mood)\n\n"
            }
            markdown += "**内容**:\n\n\(reflection.content)\n\n"
            
            if !reflection.tags.isEmpty {
                markdown += "**标签**: \(reflection.tags.joined(separator: ", "))\n\n"
            }
            
            markdown += "---\n\n"
        }
        
        return markdown
    }
}

// MARK: - 错误类型

public enum MorningReflectionError: LocalizedError {
    case notFound
    case notificationNotAuthorized
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .notFound: return "反思记录不存在"
        case .notificationNotAuthorized: return "未授权通知权限"
        case .invalidData: return "数据格式无效"
        }
    }
}

// MARK: - 通知类别注册

@available(iOS 17.0, *)
extension DreamMorningReflectionService {
    /// 注册通知类别
    public func registerNotificationCategories() {
        let reflectAction = UNNotificationAction(
            identifier: "REFLECT_ACTION",
            title: "开始反思",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "稍后提醒",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "morning-reflection",
            actions: [reflectAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
    }
}
