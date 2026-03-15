//
//  DreamExportTemplateModels.swift
//  DreamLog
//
//  Phase 53 - 导出模板编辑器
//  创建时间：2026-03-16
//

import Foundation
import SwiftData

// MARK: - 导出模板模型

/// 导出模板 - 允许用户自定义导出格式
@Model
final class DreamExportTemplate {
    var id: UUID
    var name: String
    var description: String
    var content: String
    var platform: ExportPlatform
    var format: ExportFormat
    var isPreset: Bool
    var isFavorite: Bool
    var category: TemplateCategory
    var variables: [String]
    var createdAt: Date
    var updatedAt: Date
    var usageCount: Int
    
    // 关系
    @Relationship(deleteRule: .nullify)
    var createdBy: UserAccount?
    
    init(
        name: String,
        description: String = "",
        content: String,
        platform: ExportPlatform = .markdown,
        format: ExportFormat = .markdown,
        isPreset: Bool = false,
        isFavorite: Bool = false,
        category: TemplateCategory = .general,
        variables: [String] = [],
        createdBy: UserAccount? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.content = content
        self.platform = platform
        self.format = format
        self.isPreset = isPreset
        self.isFavorite = isFavorite
        self.category = category
        self.variables = variables
        self.createdAt = Date()
        self.updatedAt = Date()
        self.usageCount = 0
        self.createdBy = createdBy
    }
}

// MARK: - 模板分类

/// 模板分类
enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case general = "general"
    case social = "social"
    case note = "note"
    case document = "document"
    case data = "data"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .general: return "通用模板"
        case .social: return "社交分享"
        case .note: return "笔记应用"
        case .document: return "文档导出"
        case .data: return "数据格式"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "📋"
        case .social: return "📱"
        case .note: return "📓"
        case .document: return "📄"
        case .data: return "📊"
        case .custom: return "⚙️"
        }
    }
}

// MARK: - 模板变量

/// 支持的导出模板变量
enum TemplateVariable: String, CaseIterable, Identifiable {
    case title = "title"
    case content = "content"
    case date = "date"
    case time = "time"
    case datetime = "datetime"
    case emotions = "emotions"
    case tags = "tags"
    case aiAnalysis = "aiAnalysis"
    case aiSummary = "aiSummary"
    case aiInterpretation = "aiInterpretation"
    case aiKeywords = "aiKeywords"
    case isLucid = "isLucid"
    case rating = "rating"
    case sleepQuality = "sleepQuality"
    case duration = "duration"
    case location = "location"
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .title: return "梦境标题"
        case .content: return "梦境内容"
        case .date: return "日期"
        case .time: return "时间"
        case .datetime: return "日期时间"
        case .emotions: return "情绪"
        case .tags: return "标签"
        case .aiAnalysis: return "AI 解析全文"
        case .aiSummary: return "AI 摘要"
        case .aiInterpretation: return "AI 解读"
        case .aiKeywords: return "AI 关键词"
        case .isLucid: return "清醒梦标记"
        case .rating: return "评分"
        case .sleepQuality: return "睡眠质量"
        case .duration: return "梦境时长"
        case .location: return "地点"
        }
    }
    
    var placeholder: String {
        switch self {
        case .title: return "{{title}}"
        case .content: return "{{content}}"
        case .date: return "{{date}}"
        case .time: return "{{time}}"
        case .datetime: return "{{datetime}}"
        case .emotions: return "{{emotions}}"
        case .tags: return "{{tags}}"
        case .aiAnalysis: return "{{aiAnalysis}}"
        case .aiSummary: return "{{aiSummary}}"
        case .aiInterpretation: return "{{aiInterpretation}}"
        case .aiKeywords: return "{{aiKeywords}}"
        case .isLucid: return "{{isLucid}}"
        case .rating: return "{{rating}}"
        case .sleepQuality: return "{{sleepQuality}}"
        case .duration: return "{{duration}}"
        case .location: return "{{location}}"
        }
    }
    
    var description: String {
        switch self {
        case .title: return "梦境的标题"
        case .content: return "梦境的详细内容"
        case .date: return "记录日期 (yyyy-MM-dd)"
        case .time: return "记录时间 (HH:mm)"
        case .datetime: return "完整日期时间"
        case .emotions: return "情绪列表，逗号分隔"
        case .tags: return "标签列表，带 # 号"
        case .aiAnalysis: return "完整的 AI 解析内容"
        case .aiSummary: return "AI 生成的摘要"
        case .aiInterpretation: return "AI 解读内容"
        case .aiKeywords: return "AI 提取的关键词"
        case .isLucid: return "清醒梦标记 (✅/❌)"
        case .rating: return "评分 (⭐️)"
        case .sleepQuality: return "睡眠质量评分"
        case .duration: return "梦境持续时长"
        case .location: return "做梦地点"
        }
    }
}

// MARK: - 预设模板

extension DreamExportTemplate {
    /// 预设模板 - Notion 优化
    static var notionTemplate: DreamExportTemplate {
        let content = """
        # {{title}}
        
        📅 **日期**: {{datetime}}
        
        {{content}}
        
        ---
        
        ## 🏷️ 标签
        {{tags}}
        
        ## 😊 情绪
        {{emotions}}
        
        {{#if aiAnalysis}}
        ## 🧠 AI 解析
        
        ### 摘要
        {{aiSummary}}
        
        ### 解读
        {{aiInterpretation}}
        
        ### 关键词
        {{aiKeywords}}
        {{/if}}
        
        {{#if isLucid}}
        ## 👁️ 清醒梦
        这是一个清醒梦 ✅
        {{/if}}
        
        {{#if rating}}
        ## ⭐️ 评分
        {{rating}}
        {{/if}}
        
        ---
        *由 DreamLog 导出*
        """
        
        return DreamExportTemplate(
            name: "Notion 数据库模板",
            description: "优化用于 Notion 数据库的梦境导出格式",
            content: content,
            platform: .notion,
            format: .markdown,
            isPreset: true,
            category: .note
        )
    }
    
    /// 预设模板 - Obsidian 优化
    static var obsidianTemplate: DreamExportTemplate {
        let content = """
        ---
        title: {{title}}
        date: {{date}}
        time: {{time}}
        tags: {{tags}}
        emotions: {{emotions}}
        {{#if isLucid}}lucid: true{{/if}}
        {{#if rating}}rating: {{rating}}{{/if}}
        ---
        
        # {{title}}
        
        {{content}}
        
        ## 标签
        {{tags}}
        
        ## 情绪
        {{emotions}}
        
        {{#if aiAnalysis}}
        ## AI 解析
        
        > [!SUMMARY] 摘要
        > {{aiSummary}}
        
        > [!INTERPRETATION] 解读
        > {{aiInterpretation}}
        
        > [!KEYWORDS] 关键词
        > {{aiKeywords}}
        {{/if}}
        
        {{#if isLucid}}
        > [!LUCID] 清醒梦
        > 这是一个清醒梦
        {{/if}}
        
        ---
        来源:: [[DreamLog]]
        导出时间:: {{datetime}}
        """
        
        return DreamExportTemplate(
            name: "Obsidian 双向链接模板",
            description: "支持 Obsidian 双向链接和 Callout 语法",
            content: content,
            platform: .obsidian,
            format: .markdown,
            isPreset: true,
            category: .note
        )
    }
    
    /// 预设模板 - PDF 精美文档
    static var pdfTemplate: DreamExportTemplate {
        let content = """
        {{title}}
        
        {{date}} {{time}}
        
        {{content}}
        
        情绪：{{emotions}}
        标签：{{tags}}
        
        {{#if aiAnalysis}}
        AI 解析
        摘要：{{aiSummary}}
        解读：{{aiInterpretation}}
        关键词：{{aiKeywords}}
        {{/if}}
        """
        
        return DreamExportTemplate(
            name: "PDF 精美文档模板",
            description: "适合打印和分享的精美 PDF 格式",
            content: content,
            platform: .pdf,
            format: .pdf,
            isPreset: true,
            category: .document
        )
    }
    
    /// 预设模板 - 社交媒体分享
    static var socialShareTemplate: DreamExportTemplate {
        let content = """
        🌙 我的梦境记录
        
        {{title}}
        
        {{content}}
        
        {{#if emotions}}
        情绪：{{emotions}}
        {{/if}}
        
        {{#if tags}}
        {{tags}}
        {{/if}}
        
        ---
        来自 #DreamLog
        """
        
        return DreamExportTemplate(
            name: "社交媒体分享模板",
            description: "简洁格式，适合微信/微博分享",
            content: content,
            platform: .wechat,
            format: .plainText,
            isPreset: true,
            category: .social
        )
    }
    
    /// 预设模板 - JSON 数据导出
    static var jsonTemplate: DreamExportTemplate {
        let content = """
        {
          "title": "{{title}}",
          "date": "{{date}}",
          "time": "{{time}}",
          "content": "{{content}}",
          "emotions": [{{emotions}}],
          "tags": [{{tags}}],
          "isLucid": {{isLucid}},
          "rating": {{rating}}
        }
        """
        
        return DreamExportTemplate(
            name: "JSON 数据模板",
            description: "标准 JSON 格式，用于数据分析",
            content: content,
            platform: .json,
            format: .json,
            isPreset: true,
            category: .data
        )
    }
    
    /// 预设模板列表
    static var presets: [DreamExportTemplate] {
        [notionTemplate, obsidianTemplate, pdfTemplate, socialShareTemplate, jsonTemplate]
    }
}

// MARK: - 模板变量提取器

struct TemplateVariableExtractor {
    /// 从模板内容中提取使用的变量
    static func extractVariables(from content: String) -> [String] {
        let pattern = #"\{\{(\w+)\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let range = NSRange(content.startIndex..., in: content)
        var variables: Set<String> = []
        
        regex.enumerateMatches(in: content, options: [], range: range) { match, _, _ in
            if let match = match, match.numberOfRanges > 1 {
                let variableRange = Range(match.range(at: 1), in: content)
                if let variable = variableRange.map({ String(content[$0]) }) {
                    variables.insert(variable)
                }
            }
        }
        
        return Array(variables)
    }
    
    /// 验证模板变量是否有效
    static func validateVariables(_ variables: [String]) -> [String] {
        let validVariables = TemplateVariable.allCases.map { $0.rawValue }
        return variables.filter { !validVariables.contains($0) }
    }
}

// MARK: - 用户账户（简化版）

@Model
final class UserAccount {
    var id: UUID
    var name: String
    var email: String?
    var createdAt: Date
    
    init(name: String, email: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.createdAt = Date()
    }
}
