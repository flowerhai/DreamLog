//
//  DreamExportService.swift
//  DreamLog
//
//  梦境导出服务 - 支持 PDF、JSON、文本格式
//  Phase 6 - 个性化体验
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

class DreamExportService {
    static let shared = DreamExportService()
    
    private init() {}
    
    // MARK: - 导出格式枚举
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case json = "JSON"
        case text = "文本"
        case markdown = "Markdown"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .json: return "doc.badge.gearshape"
            case .text: return "doc.text"
            case .markdown: return "doc.richtext"
            }
        }
        
        var description: String {
            switch self {
            case .pdf: return "精美的 PDF 文档，适合打印和分享"
            case .json: return "结构化数据，适合备份和迁移"
            case .text: return "纯文本格式，通用兼容"
            case .markdown: return "Markdown 格式，支持富文本编辑"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .json: return "json"
            case .text: return "txt"
            case .markdown: return "md"
            }
        }
    }
    
    // MARK: - PDF 导出
    
    /// 导出梦境为 PDF
    /// - Parameters:
    ///   - dreams: 要导出的梦境列表
    ///   - includeAnalysis: 是否包含 AI 解析
    ///   - includeStats: 是否包含统计信息
    ///   - theme: PDF 主题风格
    /// - Returns: PDF 数据
    func exportToPDF(
        dreams: [Dream],
        includeAnalysis: Bool = true,
        includeStats: Bool = true,
        theme: PDFTheme = .starry
    ) -> Data? {
        #if canImport(UIKit)
        let renderer = DreamPDFRenderer(theme: theme)
        return renderer.renderPDF(
            dreams: dreams,
            includeAnalysis: includeAnalysis,
            includeStats: includeStats
        )
        #else
        return nil
        #endif
    }
    
    // MARK: - JSON 导出
    
    /// 导出梦境为 JSON
    func exportToJSON(dreams: [Dream]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(dreams)
        } catch {
            print("❌ JSON 导出失败：\(error)")
            return nil
        }
    }
    
    // MARK: - 文本导出
    
    /// 导出梦境为纯文本
    func exportToText(dreams: [Dream], includeAnalysis: Bool = true) -> String {
        var output = ""
        output += "═══════════════════════════════════════\n"
        output += "         DreamLog 梦境日记\n"
        output += "═══════════════════════════════════════\n\n"
        output += "导出时间：\(Date().formatted(.dateTime.year().month().day().hour().minute()))\n"
        output += "梦境数量：\(dreams.count)\n\n"
        
        for (index, dream) in dreams.enumerated() {
            output += "───────────────────────────────────────\n"
            output += "【梦境 \(index + 1)】\n\n"
            output += "📅 日期：\(dream.date.formatted(.dateTime.year().month().day().hour().minute()))\n"
            output += "🏷️ 标题：\(dream.title)\n"
            
            if !dream.tags.isEmpty {
                output += "🏷️ 标签：\(dream.tags.joined(separator: ", "))\n"
            }
            
            if !dream.emotions.isEmpty {
                let emotionNames = dream.emotions.map { $0.rawValue }.joined(separator: ", ")
                output += "😊 情绪：\(emotionNames)\n"
            }
            
            output += "⭐ 清晰度：\(dream.clarity)/5\n"
            output += "💪 强度：\(dream.intensity)/5\n"
            
            if dream.isLucid {
                output += "🌟 清醒梦：是\n"
            }
            
            output += "\n📝 内容：\n\(dream.content)\n"
            
            if includeAnalysis, let analysis = dream.aiAnalysis {
                output += "\n🧠 AI 解析：\n\(analysis)\n"
            }
            
            output += "\n"
        }
        
        output += "═══════════════════════════════════════\n"
        output += "          感谢使用 DreamLog 🌙\n"
        output += "═══════════════════════════════════════\n"
        
        return output
    }
    
    // MARK: - Markdown 导出
    
    /// 导出梦境为 Markdown
    func exportToMarkdown(dreams: [Dream], includeAnalysis: Bool = true) -> String {
        var output = ""
        output += "# DreamLog 梦境日记 🌙\n\n"
        output += "**导出时间**: \(Date().formatted(.dateTime.year().month().day().hour().minute()))\n"
        output += "**梦境数量**: \(dreams.count)\n\n"
        output += "---\n\n"
        
        for (index, dream) in dreams.enumerated() {
            output += "## 梦境 \(index + 1): \(dream.title)\n\n"
            output += "### 📋 基本信息\n\n"
            output += "- **日期**: \(dream.date.formatted(.dateTime.year().month().day().hour().minute()))\n"
            
            if !dream.tags.isEmpty {
                output += "- **标签**: \(dream.tags.map { "#\($0)" }.joined(separator: " "))\n"
            }
            
            if !dream.emotions.isEmpty {
                let emotionNames = dream.emotions.map { $0.rawValue }.joined(separator: ", ")
                output += "- **情绪**: \(emotionNames)\n"
            }
            
            output += "- **清晰度**: \(String(repeating: "⭐", count: dream.clarity))\n"
            output += "- **强度**: \(String(repeating: "💪", count: dream.intensity))\n"
            
            if dream.isLucid {
                output += "- **清醒梦**: 🌟 是\n"
            }
            
            output += "\n### 📝 梦境内容\n\n"
            output += "\(dream.content)\n\n"
            
            if includeAnalysis, let analysis = dream.aiAnalysis {
                output += "### 🧠 AI 解析\n\n"
                output += "\(analysis)\n\n"
            }
            
            output += "---\n\n"
        }
        
        output += "\n*感谢使用 DreamLog*\n"
        
        return output
    }
    
    // MARK: - 批量导出
    
    /// 批量导出梦境
    func exportDreams(
        dreams: [Dream],
        format: ExportFormat,
        includeAnalysis: Bool = true,
        includeStats: Bool = true,
        theme: PDFTheme = .starry
    ) -> ExportResult {
        switch format {
        case .pdf:
            guard let data = exportToPDF(
                dreams: dreams,
                includeAnalysis: includeAnalysis,
                includeStats: includeStats,
                theme: theme
            ) else {
                return .failure("PDF 生成失败")
            }
            return .success(data: data, extension: format.fileExtension)
            
        case .json:
            guard let data = exportToJSON(dreams: dreams) else {
                return .failure("JSON 导出失败")
            }
            return .success(data: data, extension: format.fileExtension)
            
        case .text:
            let text = exportToText(dreams: dreams, includeAnalysis: includeAnalysis)
            guard let data = text.data(using: .utf8) else {
                return .failure("文本编码失败")
            }
            return .success(data: data, extension: format.fileExtension)
            
        case .markdown:
            let text = exportToMarkdown(dreams: dreams, includeAnalysis: includeAnalysis)
            guard let data = text.data(using: .utf8) else {
                return .failure("Markdown 编码失败")
            }
            return .success(data: data, extension: format.fileExtension)
        }
    }
}

// MARK: - 导出结果

enum ExportResult {
    case success(data: Data, extension: String)
    case failure(String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}

// MARK: - PDF 主题

enum PDFTheme: String, CaseIterable {
    case starry = "星空紫"
    case sunset = "日落橙"
    case forest = "森林绿"
    case ocean = "海洋蓝"
    case minimal = "简约黑"
    
    var primaryColor: String {
        switch self {
        case .starry: return "9B7EBD"
        case .sunset: return "FF6B35"
        case .forest: return "2D6A4F"
        case .ocean: return "0077B6"
        case .minimal: return "1A1A1A"
        }
    }
    
    var gradientColors: [String] {
        switch self {
        case .starry: return ["1A1A2E", "16213E", "0F3460"]
        case .sunset: return ["FF6B35", "F7C548", "F15BB5"]
        case .forest: return ["1B4332", "2D6A4F", "40916C"]
        case .ocean: return ["03045E", "0077B6", "90E0EF"]
        case .minimal: return ["1A1A1A", "2D2D2D", "404040"]
        }
    }
}

// MARK: - PDF 渲染器

#if canImport(UIKit)
class DreamPDFRenderer {
    private let theme: PDFTheme
    
    init(theme: PDFTheme) {
        self.theme = theme
    }
    
    func renderPDF(
        dreams: [Dream],
        includeAnalysis: Bool,
        includeStats: Bool
    ) -> Data? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842),
                                              format: UIGraphicsPDFRendererFormat())
        
        let data = renderer.pdfData { context in
            // 封面页
            renderCoverPage(context: context, dreamCount: dreams.count)
            
            // 统计页 (可选)
            if includeStats && !dreams.isEmpty {
                context.beginPage()
                renderStatsPage(context: context, dreams: dreams)
            }
            
            // 梦境内容页
            for (index, dream) in dreams.enumerated() {
                if index > 0 || includeStats {
                    context.beginPage()
                }
                renderDreamPage(context: context, dream: dream, index: index, includeAnalysis: includeAnalysis)
            }
            
            // 封底页
            context.beginPage()
            renderBackPage(context: context)
        }
        
        return data
    }
    
    private func renderCoverPage(context: UIGraphicsPDFRendererContext, dreamCount: Int) {
        context.beginPage()
        let bounds = context.format.bounds
        
        // 背景渐变
        let colors = theme.gradientColors.map { UIColor(hex: $0) }
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: colors.map { $0.cgColor } as CFArray,
                                   locations: [0, 0.5, 1])!
        
        context.cgContext.drawLinearGradient(gradient,
                                              start: CGPoint(x: 0, y: 0),
                                              end: CGPoint(x: 0, y: bounds.height),
                                              options: [])
        
        // 标题
        let title = "DreamLog"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let titleSize = title.size(withAttributes: titleAttributes)
        title.draw(at: CGPoint(x: (bounds.width - titleSize.width) / 2, y: bounds.height / 2 - 40),
                   withAttributes: titleAttributes)
        
        // 副标题
        let subtitle = "梦境日记"
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        subtitle.draw(at: CGPoint(x: (bounds.width - subtitleSize.width) / 2, y: bounds.height / 2 + 10),
                      withAttributes: subtitleAttributes)
        
        // 梦境数量
        let countText = "共 \(dreamCount) 个梦境"
        let countAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        let countSize = countText.size(withAttributes: countAttributes)
        countText.draw(at: CGPoint(x: (bounds.width - countSize.width) / 2, y: bounds.height / 2 + 60),
                       withAttributes: countAttributes)
        
        // 日期
        let dateText = Date().formatted(.dateTime.year().month().day())
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ]
        let dateSize = dateText.size(withAttributes: dateAttributes)
        dateText.draw(at: CGPoint(x: (bounds.width - dateSize.width) / 2, y: bounds.height - 80),
                      withAttributes: dateAttributes)
    }
    
    private func renderStatsPage(context: UIGraphicsPDFRendererContext, dreams: [Dream]) {
        let bounds = context.format.bounds
        var yOffset: CGFloat = 80
        
        // 页面标题
        let title = "📊 梦境统计"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor(hex: theme.primaryColor)
        ]
        title.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: titleAttributes)
        yOffset += 60
        
        // 统计信息
        let stats = calculateStats(dreams: dreams)
        
        let statItems: [(String, String)] = [
            ("总梦境数", "\(stats.totalCount)"),
            ("清醒梦", "\(stats.lucidCount)"),
            ("平均清晰度", "\(String(format: "%.1f", stats.avgClarity))/5"),
            ("平均强度", "\(String(format: "%.1f", stats.avgIntensity))/5"),
            ("记录天数", "\(stats.recordingDays)"),
            ("标签数量", "\(stats.totalTags)"),
        ]
        
        for (label, value) in statItems {
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor(hex: theme.primaryColor)
            ]
            
            let labelSize = label.size(withAttributes: labelAttributes)
            let valueSize = value.size(withAttributes: valueAttributes)
            
            label.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: labelAttributes)
            value.draw(at: CGPoint(x: bounds.width - 60 - valueSize.width, y: yOffset),
                       withAttributes: valueAttributes)
            
            yOffset += 35
        }
        
        // 情绪分布
        yOffset += 20
        let emotionTitle = "😊 情绪分布"
        let emotionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        emotionTitle.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: emotionAttributes)
        yOffset += 40
        
        for (emotion, count) in stats.emotionDistribution.prefix(5) {
            let emotionText = "\(emotion): \(count) 次"
            let emotionAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            emotionText.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: emotionAttr)
            yOffset += 25
        }
    }
    
    private func renderDreamPage(
        context: UIGraphicsPDFRendererContext,
        dream: Dream,
        index: Int,
        includeAnalysis: Bool
    ) {
        let bounds = context.format.bounds
        var yOffset: CGFloat = 60
        
        // 梦境标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor(hex: theme.primaryColor)
        ]
        let title = "🌙 \(dream.title)"
        title.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: titleAttributes)
        yOffset += 40
        
        // 日期
        let dateText = dream.date.formatted(.dateTime.year().month().day().hour().minute())
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .light),
            .foregroundColor: UIColor.gray
        ]
        dateText.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: dateAttributes)
        yOffset += 30
        
        // 标签和情绪
        if !dream.tags.isEmpty || !dream.emotions.isEmpty {
            let metaText = [
                dream.tags.isEmpty ? nil : "🏷️ " + dream.tags.joined(separator: " "),
                dream.emotions.isEmpty ? nil : "😊 " + dream.emotions.map { $0.rawValue }.joined(separator: ", ")
            ].compactMap { $0 }.joined(separator: "  |  ")
            
            let metaAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            metaText.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: metaAttributes)
            yOffset += 25
        }
        
        // 清晰度和强度
        let ratingText = "⭐ 清晰度：\(String(repeating: "★", count: dream.clarity) + String(repeating: "☆", count: 5 - dream.clarity))  " +
                        "💪 强度：\(String(repeating: "★", count: dream.intensity) + String(repeating: "☆", count: 5 - dream.intensity))"
        let ratingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        ratingText.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: ratingAttributes)
        yOffset += 30
        
        // 梦境内容
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.black
        ]
        
        let contentParagraphStyle = NSMutableParagraphStyle()
        contentParagraphStyle.lineSpacing = 6
        
        let contentAttributesWithParagraph: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.black,
            .paragraphStyle: contentParagraphStyle
        ]
        
        dream.content.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: contentAttributesWithParagraph)
        
        // 计算内容高度并更新 yOffset
        let contentSize = dream.content.boundingRect(
            with: CGSize(width: bounds.width - 120, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: contentAttributesWithParagraph,
            context: nil
        )
        yOffset += contentSize.height + 20
        
        // AI 解析 (可选)
        if includeAnalysis, let analysis = dream.aiAnalysis {
            // 分隔线
            let lineRect = CGRect(x: 60, y: yOffset, width: bounds.width - 120, height: 1)
            context.cgContext.setFillColor(UIColor.lightGray.cgColor)
            context.cgContext.fill(lineRect)
            yOffset += 30
            
            let aiTitle = "🧠 AI 解析"
            let aiTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor(hex: theme.primaryColor)
            ]
            aiTitle.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: aiTitleAttributes)
            yOffset += 25
            
            let analysisAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: contentParagraphStyle
            ]
            analysis.draw(at: CGPoint(x: 60, y: yOffset), withAttributes: analysisAttributes)
        }
        
        // 页码
        let pageNum = "\(index + 1)"
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .light),
            .foregroundColor: UIColor.lightGray
        ]
        let pageSize = pageNum.size(withAttributes: pageAttributes)
        pageNum.draw(at: CGPoint(x: bounds.width - 60 - pageSize.width, y: bounds.height - 40),
                     withAttributes: pageAttributes)
    }
    
    private func renderBackPage(context: UIGraphicsPDFRendererContext) {
        let bounds = context.format.bounds
        
        // 背景
        let colors = theme.gradientColors.map { UIColor(hex: $0) }
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: colors.map { $0.cgColor } as CFArray,
                                   locations: [0, 0.5, 1])!
        
        context.cgContext.drawLinearGradient(gradient,
                                              start: CGPoint(x: 0, y: 0),
                                              end: CGPoint(x: 0, y: bounds.height),
                                              options: [])
        
        // 感谢语
        let thanksText = "感谢使用 DreamLog"
        let thanksAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .light),
            .foregroundColor: UIColor.white
        ]
        let thanksSize = thanksText.size(withAttributes: thanksAttributes)
        thanksText.draw(at: CGPoint(x: (bounds.width - thanksSize.width) / 2, y: bounds.height / 2 - 20),
                        withAttributes: thanksAttributes)
        
        // 标语
        let slogan = "记录你的梦，发现潜意识的秘密"
        let sloganAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        let sloganSize = slogan.size(withAttributes: sloganAttributes)
        slogan.draw(at: CGPoint(x: (bounds.width - sloganSize.width) / 2, y: bounds.height / 2 + 20),
                    withAttributes: sloganAttributes)
        
        // 日期
        let dateText = Date().formatted(.dateTime.year().month().day())
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ]
        let dateSize = dateText.size(withAttributes: dateAttributes)
        dateText.draw(at: CGPoint(x: (bounds.width - dateSize.width) / 2, y: bounds.height - 80),
                      withAttributes: dateAttributes)
    }
    
    private func calculateStats(dreams: [Dream]) -> DreamStats {
        let totalCount = dreams.count
        let lucidCount = dreams.filter { $0.isLucid }.count
        let avgClarity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.clarity }) / Double(totalCount)
        let avgIntensity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.intensity }) / Double(totalCount)
        
        let dates = Set(dreams.map { Calendar.current.startOfDay(for: $0.date) })
        let recordingDays = dates.count
        
        let allTags = dreams.flatMap { $0.tags }
        let totalTags = allTags.count
        
        var emotionCount: [String: Int] = [:]
        dreams.forEach { dream in
            dream.emotions.forEach { emotion in
                emotionCount[emotion.rawValue, default: 0] += 1
            }
        }
        
        return DreamStats(
            totalCount: totalCount,
            lucidCount: lucidCount,
            avgClarity: avgClarity,
            avgIntensity: avgIntensity,
            recordingDays: recordingDays,
            totalTags: totalTags,
            emotionDistribution: emotionCount.sorted { $0.value > $1.value }
        )
    }
}

struct DreamStats {
    let totalCount: Int
    let lucidCount: Int
    let avgClarity: Double
    let avgIntensity: Double
    let recordingDays: Int
    let totalTags: Int
    let emotionDistribution: [(String, Int)]
}
#endif

// MARK: - UIColor 扩展
// Note: UIColor(hex:) is defined in Theme.swift to avoid redeclaration
