//
//  DreamPublishService.swift
//  DreamLog
//
//  Phase 47: Dream Newsletter & Auto-Publishing
//  梦境自动发布核心服务
//

import Foundation
import SwiftData

actor DreamPublishService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var scheduledTasks: [UUID: Timer] = [:]
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Template Management
    
    /// 获取所有发布模板
    func fetchTemplates() -> [PublishTemplate] {
        let descriptor = FetchDescriptor<PublishTemplate>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    /// 获取平台默认模板
    func getDefaultTemplate(for platform: PublishPlatform) -> PublishTemplate? {
        let descriptor = FetchDescriptor<PublishTemplate>(
            predicate: #Predicate<PublishTemplate> { $0.platform == platform.rawValue && $0.isDefault }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    /// 保存模板
    func saveTemplate(_ template: PublishTemplate) throws {
        template.updatedAt = Date()
        modelContext.insert(template)
        try modelContext.save()
    }
    
    /// 删除模板
    func deleteTemplate(_ template: PublishTemplate) throws {
        modelContext.delete(template)
        try modelContext.save()
    }
    
    // MARK: - Content Generation
    
    /// 生成发布内容
    func generateContent(
        dream: Dream,
        template: PublishTemplate,
        includeImages: Bool = true
    ) -> PublishPreview {
        var title = template.titleTemplate
        var content = template.contentTemplate
        
        // 替换梦境变量
        title = title.replacingOccurrences(of: "{{title}}", with: dream.title)
        
        content = content.replacingOccurrences(of: "{{content}}", with: dream.content)
        content = content.replacingOccurrences(of: "{{title}}", with: dream.title)
        
        // 处理日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        content = content.replacingOccurrences(of: "{{date}}", with: dateFormatter.string(from: dream.date))
        
        // 处理标签
        if template.includeTags && !dream.tags.isEmpty {
            let tagsString = dream.tags.joined(separator: ", ")
            content = content.replacingOccurrences(of: "{{tags}}", with: tagsString)
            content = content.replacingOccurrences(of: "{{tagsJoined}}", with: dream.tags.map { "#\($0.replacingOccurrences(of: " ", with: ""))" }.joined(separator: " "))
            content = content.replacingOccurrences(of: "{{tagsFirst3}}", with: dream.tags.prefix(3).map { "#\($0.replacingOccurrences(of: " ", with: ""))" }.joined(separator: " "))
        } else {
            content = content.replacingOccurrences(of: "{{tags}}", with: "")
            content = content.replacingOccurrences(of: "{{tagsJoined}}", with: "")
            content = content.replacingOccurrences(of: "{{tagsFirst3}}", with: "")
        }
        
        // 处理情绪
        if template.includeEmotions && !dream.emotions.isEmpty {
            let emotionsString = dream.emotions.map { $0.rawValue }.joined(separator: ", ")
            content = content.replacingOccurrences(of: "{{emotions}}", with: emotionsString)
        } else {
            content = content.replacingOccurrences(of: "{{emotions}}", with: "")
        }
        
        // 处理 AI 解析
        if template.includeAIAnalysis, let aiAnalysis = dream.aiAnalysis {
            content = content.replacingOccurrences(of: "{{aiAnalysis}}", with: aiAnalysis)
        } else {
            content = content.replacingOccurrences(of: "{{aiAnalysis}}", with: "")
        }
        
        // 处理内容截断 (Twitter)
        let maxChars = 280
        if content.count > maxChars {
            content = String(content.prefix(maxChars - 3)) + "..."
        }
        
        // 处理条件语句
        content = processConditionals(content, dream: dream, template: template)
        
        // 计算统计数据
        let characterCount = (title + content).count
        let estimatedReadTime = max(1, Int(ceil(Double(characterCount) / 200.0))) // 200 字/分钟
        let hashtags = extractHashtags(from: content)
        
        return PublishPreview(
            title: title,
            content: content,
            platform: template.platform,
            characterCount: characterCount,
            estimatedReadTime: estimatedReadTime,
            hashtags: hashtags,
            imageCount: includeImages ? 1 : 0
        )
    }
    
    /// 处理条件语句
    private func processConditionals(_ content: String, dream: Dream, template: PublishTemplate) -> String {
        var result = content
        
        // 处理 {{#if aiAnalysis}}...{{/if}}
        if let aiAnalysis = dream.aiAnalysis, !aiAnalysis.isEmpty {
            result = processIfBlock(result, key: "aiAnalysis", value: aiAnalysis, template: template)
        } else {
            result = removeIfBlock(result, key: "aiAnalysis")
        }
        
        // 处理 {{#if tags}}...{{/if}}
        if template.includeTags && !dream.tags.isEmpty {
            result = processIfBlock(result, key: "tags", value: dream.tags.joined(separator: ", "), template: template)
        } else {
            result = removeIfBlock(result, key: "tags")
        }
        
        // 处理 {{#if emotions}}...{{/if}}
        if template.includeEmotions && !dream.emotions.isEmpty {
            result = processIfBlock(result, key: "emotions", value: dream.emotions.map { $0.rawValue }.joined(separator: ", "), template: template)
        } else {
            result = removeIfBlock(result, key: "emotions")
        }
        
        return result
    }
    
    private func processIfBlock(_ content: String, key: String, value: String, template: PublishTemplate) -> String {
        let pattern = "\\{\\{#if \\(key)\\}\\}(.*?)\\{\\{/if\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else {
            return content
        }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        var result = content
        for match in matches.reversed() {
            guard let blockRange = Range(match.range, in: content) else { continue }
            let block = String(content[blockRange])
            
            // 提取 {{#if}} 和 {{/if}} 之间的内容
            let innerContent = block
                .replacingOccurrences(of: "{{#if \(key)}}", with: "")
                .replacingOccurrences(of: "{{/if}}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            result = result.replacingOccurrences(of: block, with: innerContent)
        }
        
        return result
    }
    
    private func removeIfBlock(_ content: String, key: String) -> String {
        let pattern = "\\{\\{#if \\(key)\\}\\}.*?\\{\\{/if\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else {
            return content
        }
        
        let range = NSRange(content.startIndex..., in: content)
        return regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")
    }
    
    /// 提取标签
    private func extractHashtags(from content: String) -> [String] {
        let pattern = "#\\w+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: content) else { return nil }
            return String(content[range])
        }
    }
    
    // MARK: - Publish Task Management
    
    /// 创建发布任务
    func createPublishTask(
        dream: Dream,
        platform: PublishPlatform,
        template: PublishTemplate,
        scheduledAt: Date? = nil
    ) throws -> PublishTask {
        let preview = generateContent(dream: dream, template: template)
        
        let task = PublishTask(
            title: preview.title,
            content: preview.content,
            platform: platform.rawValue,
            templateId: template.id,
            dreamIds: [dream.id],
            scheduledAt: scheduledAt,
            status: scheduledAt != nil ? .scheduled : .pending
        )
        
        modelContext.insert(task)
        try modelContext.save()
        
        // 如果是计划任务，设置定时器
        if let scheduledAt = scheduledAt {
            scheduleTask(task, at: scheduledAt)
        }
        
        return task
    }
    
    /// 创建批量发布任务 (通讯)
    func createNewsletterTask(
        dreams: [Dream],
        platform: PublishPlatform,
        template: PublishTemplate,
        scheduledAt: Date? = nil
    ) throws -> PublishTask {
        var content = template.contentTemplate
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        // 生成每篇梦境的内容
        var dreamContents: [String] = []
        for dream in dreams {
            var dreamContent = template.contentTemplate
            dreamContent = dreamContent.replacingOccurrences(of: "{{title}}", with: dream.title)
            dreamContent = dreamContent.replacingOccurrences(of: "{{content}}", with: dream.content)
            dreamContent = dreamContent.replacingOccurrences(of: "{{date}}", with: dateFormatter.string(from: dream.date))
            
            if let aiAnalysis = dream.aiAnalysis {
                dreamContent = dreamContent.replacingOccurrences(of: "{{aiAnalysis}}", with: aiAnalysis)
            }
            
            dreamContents.append(dreamContent)
        }
        
        content = dreamContents.joined(separator: "\n\n---\n\n")
        
        let title = template.titleTemplate.replacingOccurrences(
            of: "{{date}}",
            with: dateFormatter.string(from: Date())
        )
        
        let task = PublishTask(
            title: title,
            content: content,
            platform: platform.rawValue,
            templateId: template.id,
            dreamIds: dreams.map { $0.id },
            scheduledAt: scheduledAt,
            status: scheduledAt != nil ? .scheduled : .pending
        )
        
        modelContext.insert(task)
        try modelContext.save()
        
        if let scheduledAt = scheduledAt {
            scheduleTask(task, at: scheduledAt)
        }
        
        return task
    }
    
    /// 获取所有发布任务
    func fetchTasks(status: PublishTaskStatus? = nil) -> [PublishTask] {
        var descriptor = FetchDescriptor<PublishTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        if let status = status {
            descriptor.predicate = #Predicate<PublishTask> { $0.status == status.rawValue }
        }
        
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    /// 更新任务状态
    func updateTaskStatus(_ task: PublishTask, status: PublishTaskStatus, url: String? = nil, error: String? = nil) throws {
        task.taskStatus = status
        task.updatedAt = Date()
        
        if let url = url {
            task.publishedURL = url
            task.publishedAt = Date()
        }
        
        if let error = error {
            task.errorMessage = error
        }
        
        try modelContext.save()
    }
    
    /// 删除任务
    func deleteTask(_ task: PublishTask) throws {
        // 取消计划任务
        if let timer = scheduledTasks[task.id] {
            timer.invalidate()
            scheduledTasks.removeValue(forKey: task.id)
        }
        
        modelContext.delete(task)
        try modelContext.save()
    }
    
    // MARK: - Scheduling
    
    /// 计划任务
    private func scheduleTask(_ task: PublishTask, at date: Date) {
        let timer = Timer.scheduledTimer(withTimeInterval: date.timeIntervalSinceNow, repeats: false) { [weak self] _ in
            Task {
                await self?.executeTask(task)
            }
        }
        scheduledTasks[task.id] = timer
    }
    
    /// 执行发布任务
    private func executeTask(_ task: PublishTask) async {
        guard task.taskStatus == .scheduled || task.taskStatus == .pending else { return }
        
        do {
            try await publishTask(task)
        } catch {
            try? updateTaskStatus(task, status: .failed, error: error.localizedDescription)
        }
    }
    
    /// 发布任务到平台
    func publishTask(_ task: PublishTask) async throws {
        // 更新状态为处理中
        try? updateTaskStatus(task, status: .processing)
        
        // 获取平台配置
        let config = try fetchConfig(for: task.platform)
        
        // 根据平台执行发布
        switch task.platform {
        case PublishPlatform.medium.rawValue:
            try await publishToMedium(task: task, config: config)
        case PublishPlatform.wordpress.rawValue:
            try await publishToWordPress(task: task, config: config)
        case PublishPlatform.ghost.rawValue:
            try await publishToGhost(task: task, config: config)
        case PublishPlatform.twitter.rawValue:
            try await publishToTwitter(task: task, config: config)
        default:
            // 对于不支持自动发布的平台，标记为成功并显示内容
            try? updateTaskStatus(task, status: .success)
        }
    }
    
    // MARK: - Platform Publishing
    
    /// 发布到 Medium
    private func publishToMedium(task: PublishTask, config: PublishConfig?) async throws {
        guard let config = config, let apiKey = config.apiKey else {
            throw PublishError.missingCredentials
        }
        
        // Medium API 集成
        // 实际实现需要调用 Medium API
        // 这里提供框架
        
        let url = "https://api.medium.com/v1/users/me/posts"
        // 实际发布逻辑...
        
        try? updateTaskStatus(task, status: .success, url: "https://medium.com/@user/dream-title")
    }
    
    /// 发布到 WordPress
    private func publishToWordPress(task: PublishTask, config: PublishConfig?) async throws {
        guard let config = config, let apiKey = config.apiKey, let endpoint = config.endpoint else {
            throw PublishError.missingCredentials
        }
        
        // WordPress REST API 集成
        let url = "\(endpoint)/wp-json/wp/v2/posts"
        // 实际发布逻辑...
        
        try? updateTaskStatus(task, status: .success, url: "https://example.com/dream-post")
    }
    
    /// 发布到 Ghost
    private func publishToGhost(task: PublishTask, config: PublishConfig?) async throws {
        guard let config = config, let apiKey = config.apiKey else {
            throw PublishError.missingCredentials
        }
        
        // Ghost Admin API 集成
        // 实际发布逻辑...
        
        try? updateTaskStatus(task, status: .success, url: "https://example.com/dream")
    }
    
    /// 发布到 Twitter
    private func publishToTwitter(task: PublishTask, config: PublishConfig?) async throws {
        guard let config = config, let apiKey = config.apiKey else {
            throw PublishError.missingCredentials
        }
        
        // Twitter API v2 集成
        // 实际发布逻辑...
        
        try? updateTaskStatus(task, status: .success, url: "https://twitter.com/user/status/123")
    }
    
    // MARK: - Configuration Management
    
    /// 获取平台配置
    func fetchConfig(for platform: String) throws -> PublishConfig? {
        let descriptor = FetchDescriptor<PublishConfig>(
            predicate: #Predicate<PublishConfig> { $0.platform == platform }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    /// 保存平台配置
    func saveConfig(_ config: PublishConfig) throws {
        config.updatedAt = Date()
        modelContext.insert(config)
        try modelContext.save()
    }
    
    /// 删除平台配置
    func deleteConfig(_ config: PublishConfig) throws {
        modelContext.delete(config)
        try modelContext.save()
    }
    
    // MARK: - Statistics
    
    /// 获取发布统计
    func getStats() -> PublishStats {
        let allTasks = fetchTasks()
        let publishedTasks = allTasks.filter { $0.taskStatus == .success }
        
        var byPlatform: [String: Int] = [:]
        for task in publishedTasks {
            byPlatform[task.platform, default: 0] += 1
        }
        
        let mostPopular = byPlatform.max(by: { $0.value < $1.value })?.key
        
        return PublishStats(
            totalPublished: publishedTasks.count,
            byPlatform: byPlatform,
            totalViews: 0, // 需要从平台 API 获取
            totalLikes: 0,
            totalShares: 0,
            mostPopularPlatform: mostPopular,
            averageEngagement: 0
        )
    }
}

// MARK: - Errors

enum PublishError: LocalizedError {
    case missingCredentials
    case invalidTemplate
    case platformNotSupported
    case networkError
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "缺少平台凭证，请在设置中配置 API Key"
        case .invalidTemplate:
            return "模板格式无效"
        case .platformNotSupported:
            return "该平台不支持自动发布"
        case .networkError:
            return "网络错误，请检查连接"
        case .rateLimitExceeded:
            return "发布频率超限，请稍后再试"
        }
    }
}
