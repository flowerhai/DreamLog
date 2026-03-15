//
//  DreamExportTemplateService.swift
//  DreamLog
//
//  Phase 53 - 导出模板管理服务
//  创建时间：2026-03-16
//

import Foundation
import SwiftData

/// 导出模板服务
@ModelActor
actor DreamExportTemplateService {
    
    // MARK: - 单例
    
    static let shared = DreamExportTemplateService()
    
    // MARK: - 模板管理
    
    /// 创建模板
    func createTemplate(
        name: String,
        description: String = "",
        content: String,
        platform: ExportPlatform = .markdown,
        format: ExportFormat = .markdown,
        category: TemplateCategory = .general
    ) async throws -> DreamExportTemplate {
        // 验证名称
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TemplateError.emptyName
        }
        
        // 验证内容
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TemplateError.emptyContent
        }
        
        // 检查名称重复
        let existing = try findTemplate(byName: name)
        if existing != nil {
            throw TemplateError.duplicateName
        }
        
        // 提取变量
        let variables = TemplateVariableExtractor.extractVariables(from: content)
        
        let template = DreamExportTemplate(
            name: name,
            description: description,
            content: content,
            platform: platform,
            format: format,
            isPreset: false,
            category: category
        )
        template.variables = variables
        
        modelContext.insert(template)
        try modelContext.save()
        
        return template
    }
    
    /// 更新模板
    func updateTemplate(_ template: DreamExportTemplate) async throws {
        // 验证名称
        guard !template.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TemplateError.emptyName
        }
        
        // 验证内容
        guard !template.content.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TemplateError.emptyContent
        }
        
        // 更新变量
        template.variables = TemplateVariableExtractor.extractVariables(from: template.content)
        template.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 删除模板
    func deleteTemplate(_ template: DreamExportTemplate) async throws {
        guard !template.isPreset else {
            throw TemplateError.cannotDeletePreset
        }
        
        modelContext.delete(template)
        try modelContext.save()
    }
    
    /// 获取所有模板
    func getAllTemplates() async throws -> [DreamExportTemplate] {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            sortBy: [
                SortDescriptor(\.isFavorite, order: .reverse),
                SortDescriptor(\.updatedAt, order: .reverse)
            ]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取自定义模板
    func getCustomTemplates() async throws -> [DreamExportTemplate] {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            predicate: #Predicate<DreamExportTemplate> { $0.isPreset == false },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取预设模板
    func getPresetTemplates() async throws -> [DreamExportTemplate] {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            predicate: #Predicate<DreamExportTemplate> { $0.isPreset == true },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取收藏模板
    func getFavoriteTemplates() async throws -> [DreamExportTemplate] {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            predicate: #Predicate<DreamExportTemplate> { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按分类获取模板
    func getTemplates(by category: TemplateCategory) async throws -> [DreamExportTemplate] {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            predicate: #Predicate<DreamExportTemplate> { $0.category == category },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按平台获取模板
    func getTemplates(by platform: ExportPlatform) async throws -> [DreamExportTemplate] {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            predicate: #Predicate<DreamExportTemplate> { $0.platform == platform },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 根据名称查找模板
    func findTemplate(byName name: String) async throws -> DreamExportTemplate? {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            predicate: #Predicate<DreamExportTemplate> { $0.name == name }
        )
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    /// 根据 ID 查找模板
    func findTemplate(byId id: UUID) async throws -> DreamExportTemplate? {
        let descriptor = FetchDescriptor<DreamExportTemplate>(
            predicate: #Predicate<DreamExportTemplate> { $0.id == id }
        )
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ template: DreamExportTemplate) async throws {
        template.isFavorite.toggle()
        template.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 增加使用次数
    func incrementUsage(_ template: DreamExportTemplate) async throws {
        template.usageCount += 1
        template.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - 模板导入/导出
    
    /// 导出模板为 JSON
    func exportTemplate(_ template: DreamExportTemplate) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let exportData = TemplateExportData(
            name: template.name,
            description: template.description,
            content: template.content,
            platform: template.platform.rawValue,
            format: template.format.rawValue,
            category: template.category.rawValue,
            version: "1.0"
        )
        
        return try encoder.encode(exportData)
    }
    
    /// 从 JSON 导入模板
    func importTemplate(from data: Data) async throws -> DreamExportTemplate {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(TemplateExportData.self, from: data)
        
        // 验证平台
        guard let platform = ExportPlatform(rawValue: importData.platform) else {
            throw TemplateError.invalidPlatform
        }
        
        // 验证格式
        guard let format = ExportFormat(rawValue: importData.format) else {
            throw TemplateError.invalidFormat
        }
        
        // 验证分类
        guard let category = TemplateCategory(rawValue: importData.category) else {
            throw TemplateError.invalidCategory
        }
        
        return try await createTemplate(
            name: importData.name,
            description: importData.description,
            content: importData.content,
            platform: platform,
            format: format,
            category: category
        )
    }
    
    /// 批量导出模板
    func exportTemplates(_ templates: [DreamExportTemplate]) async throws -> Data {
        let exportData = try await templates.map { template in
            try await exportTemplate(template)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(exportData)
    }
    
    /// 批量导入模板
    func importTemplates(from data: Data) async throws -> [DreamExportTemplate] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importArray = try decoder.decode([Data].self, from: data)
        
        var templates: [DreamExportTemplate] = []
        for importData in importArray {
            do {
                let template = try await importTemplate(from: importData)
                templates.append(template)
            } catch {
                // 跳过失败的导入
                continue
            }
        }
        
        return templates
    }
    
    // MARK: - 模板渲染
    
    /// 渲染模板 - 将变量替换为实际内容
    func renderTemplate(_ template: DreamExportTemplate, dream: Dream) async -> String {
        var content = template.content
        
        // 替换简单变量
        content = content.replacingOccurrences(of: "{{title}}", with: dream.title)
        content = content.replacingOccurrences(of: "{{content}}", with: dream.content)
        
        // 日期时间
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        content = content.replacingOccurrences(of: "{{date}}", with: dateFormatter.string(from: dream.date))
        
        dateFormatter.dateFormat = "HH:mm"
        content = content.replacingOccurrences(of: "{{time}}", with: dateFormatter.string(from: dream.date))
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        content = content.replacingOccurrences(of: "{{datetime}}", with: dateFormatter.string(from: dream.date))
        
        // 情绪
        let emotions = dream.emotions.map { $0.displayName }.joined(separator: ", ")
        content = content.replacingOccurrences(of: "{{emotions}}", with: emotions)
        
        // 标签
        let tags = dream.tags.map { "#\($0.name)" }.joined(separator: " ")
        content = content.replacingOccurrences(of: "{{tags}}", with: tags)
        
        // AI 解析
        if let analysis = dream.aiAnalysis {
            content = content.replacingOccurrences(of: "{{aiAnalysis}}", with: "available")
            content = content.replacingOccurrences(of: "{{aiSummary}}", with: analysis.summary ?? "")
            content = content.replacingOccurrences(of: "{{aiInterpretation}}", with: analysis.interpretation ?? "")
            content = content.replacingOccurrences(of: "{{aiKeywords}}", with: analysis.keywords?.joined(separator: ", ") ?? "")
        } else {
            content = content.replacingOccurrences(of: "{{aiAnalysis}}", with: "")
            content = content.replacingOccurrences(of: "{{aiSummary}}", with: "")
            content = content.replacingOccurrences(of: "{{aiInterpretation}}", with: "")
            content = content.replacingOccurrences(of: "{{aiKeywords}}", with: "")
        }
        
        // 清醒梦
        content = content.replacingOccurrences(of: "{{isLucid}}", with: dream.isLucid ? "✅" : "❌")
        
        // 评分
        let rating = dream.rating > 0 ? String(repeating: "⭐️", count: Int(dream.rating)) : ""
        content = content.replacingOccurrences(of: "{{rating}}", with: rating)
        
        // 处理条件语句 {{#if variable}}...{{/if}}
        content = processConditionals(content, dream: dream)
        
        return content
    }
    
    /// 处理条件语句
    private func processConditionals(_ content: String, dream: Dream) -> String {
        var result = content
        
        // 处理 {{#if aiAnalysis}}...{{/if}}
        let aiAnalysisPattern = #"\{\{#if aiAnalysis\}\}(.*?)\{\{/if\}\}"#
        if let regex = try? NSRegularExpression(pattern: aiAnalysisPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range).reversed()
            
            for match in matches {
                if let range = Range(match.range, in: result) {
                    if dream.aiAnalysis != nil {
                        // 保留内容，移除标记
                        let innerContent = String(result[range])
                            .replacingOccurrences(of: "{{#if aiAnalysis}}", with: "")
                            .replacingOccurrences(of: "{{/if}}", with: "")
                        result.replaceSubrange(range, with: innerContent)
                    } else {
                        // 移除整个条件块
                        result.replaceSubrange(range, with: "")
                    }
                }
            }
        }
        
        // 处理 {{#if isLucid}}...{{/if}}
        let isLucidPattern = #"\{\{#if isLucid\}\}(.*?)\{\{/if\}\}"#
        if let regex = try? NSRegularExpression(pattern: isLucidPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range).reversed()
            
            for match in matches {
                if let range = Range(match.range, in: result) {
                    if dream.isLucid {
                        let innerContent = String(result[range])
                            .replacingOccurrences(of: "{{#if isLucid}}", with: "")
                            .replacingOccurrences(of: "{{/if}}", with: "")
                        result.replaceSubrange(range, with: innerContent)
                    } else {
                        result.replaceSubrange(range, with: "")
                    }
                }
            }
        }
        
        // 处理 {{#if rating}}...{{/if}}
        let ratingPattern = #"\{\{#if rating\}\}(.*?)\{\{/if\}\}"#
        if let regex = try? NSRegularExpression(pattern: ratingPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: range).reversed()
            
            for match in matches {
                if let range = Range(match.range, in: result) {
                    if dream.rating > 0 {
                        let innerContent = String(result[range])
                            .replacingOccurrences(of: "{{#if rating}}", with: "")
                            .replacingOccurrences(of: "{{/if}}", with: "")
                        result.replaceSubrange(range, with: innerContent)
                    } else {
                        result.replaceSubrange(range, with: "")
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - 统计
    
    /// 获取模板统计
    func getTemplateStats() async throws -> TemplateStats {
        let allTemplates = try await getAllTemplates()
        let customTemplates = try await getCustomTemplates()
        let favoriteTemplates = try await getFavoriteTemplates()
        
        var totalUsageCount = 0
        for template in allTemplates {
            totalUsageCount += template.usageCount
        }
        
        return TemplateStats(
            totalTemplates: allTemplates.count,
            customTemplates: customTemplates.count,
            presetTemplates: allTemplates.count - customTemplates.count,
            favoriteTemplates: favoriteTemplates.count,
            totalUsageCount: totalUsageCount
        )
    }
}

// MARK: - 模板错误

enum TemplateError: LocalizedError {
    case emptyName
    case emptyContent
    case duplicateName
    case cannotDeletePreset
    case invalidPlatform
    case invalidFormat
    case invalidCategory
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .emptyName: return "模板名称不能为空"
        case .emptyContent: return "模板内容不能为空"
        case .duplicateName: return "模板名称已存在"
        case .cannotDeletePreset: return "无法删除预设模板"
        case .invalidPlatform: return "无效的平台类型"
        case .invalidFormat: return "无效的格式类型"
        case .invalidCategory: return "无效的分类类型"
        case .notFound: return "模板不存在"
        }
    }
}

// MARK: - 模板导出数据结构

struct TemplateExportData: Codable {
    var name: String
    var description: String
    var content: String
    var platform: String
    var format: String
    var category: String
    var version: String
}

// MARK: - 模板统计

struct TemplateStats {
    var totalTemplates: Int
    var customTemplates: Int
    var presetTemplates: Int
    var favoriteTemplates: Int
    var totalUsageCount: Int
}
