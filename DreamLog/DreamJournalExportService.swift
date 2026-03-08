//
//  DreamJournalExportService.swift
//  DreamLog
//
//  梦境日记 PDF 导出服务
//  支持生成精美的 PDF 梦境日记/书籍
//

import Foundation
import UIKit
import PDFKit

/// PDF 导出风格
enum PDFExportStyle: String, CaseIterable, Identifiable {
    case minimal = "简约风格"
    case classic = "经典风格"
    case artistic = "艺术风格"
    case modern = "现代风格"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .minimal: return "干净简洁，专注内容"
        case .classic: return "传统书籍排版，优雅正式"
        case .artistic: return "创意布局，丰富装饰"
        case .modern: return "时尚设计，大胆用色"
        }
    }
    
    var iconName: String {
        switch self {
        case .minimal: return "doc.text"
        case .classic: return "book.fill"
        case .artistic: return "paintpalette.fill"
        case .modern: return "sparkles"
        }
    }
    
    var primaryColor: UIColor {
        switch self {
        case .minimal: return .black
        case .classic: return UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1)
        case .artistic: return UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1)
        case .modern: return UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1)
        }
    }
}

/// PDF 页面尺寸
enum PDFPageSize: String, CaseIterable, Identifiable {
    case a4 = "A4"
    case letter = "Letter"
    case square = "正方形"
    
    var id: String { rawValue }
    
    var size: CGSize {
        switch self {
        case .a4: return CGSize(width: 595, height: 842)
        case .letter: return CGSize(width: 612, height: 792)
        case .square: return CGSize(width: 600, height: 600)
        }
    }
    
    var description: String {
        switch self {
        case .a4: return "210 × 297 mm (国际标准)"
        case .letter: return "8.5 × 11 英寸 (美式标准)"
        case .square: return "600 × 600 pt (社交媒体)"
        }
    }
}

/// PDF 导出配置
struct PDFExportConfig: Codable {
    var style: PDFExportStyle
    var pageSize: PDFPageSize
    var includeCoverPage: Bool
    var includeTableOfContents: Bool
    var includeAIImages: Bool
    var includeStatistics: Bool
    var includeTags: Bool
    var includeEmotions: Bool
    var customTitle: String
    var customSubtitle: String
    var dateRange: DateRange
    var sortBy: SortOption
    
    enum SortOption: String, CaseIterable, Codable {
        case dateDesc = "日期 (最新优先)"
        case dateAsc = "日期 (最早优先)"
        case clarity = "清晰度"
        case intensity = "强度"
    }
    
    struct DateRange: Codable {
        var startDate: Date
        var endDate: Date
        
        static var all: DateRange {
            DateRange(startDate: Date.distantPast, endDate: Date())
        }
        
        static var thisWeek: DateRange {
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
            return DateRange(startDate: startOfWeek, endDate: Date())
        }
        
        static var thisMonth: DateRange {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
            return DateRange(startDate: startOfMonth, endDate: Date())
        }
        
        static var thisYear: DateRange {
            let calendar = Calendar.current
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date())) ?? Date()
            return DateRange(startDate: startOfYear, endDate: Date())
        }
    }
    
    static var `default`: PDFExportConfig {
        PDFExportConfig(
            style: .classic,
            pageSize: .a4,
            includeCoverPage: true,
            includeTableOfContents: true,
            includeAIImages: true,
            includeStatistics: true,
            includeTags: true,
            includeEmotions: true,
            customTitle: "我的梦境日记",
            customSubtitle: "DreamLog Journal",
            dateRange: .all,
            sortBy: .dateDesc
        )
    }
}

/// PDF 导出服务
class DreamJournalExportService {
    static let shared = DreamJournalExportService()
    
    private let renderer: UIGraphicsPDFRenderer
    private var config: PDFExportConfig
    
    private init() {
        self.config = .default
        self.renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: config.pageSize.size))
    }
    
    /// 更新配置
    func updateConfig(_ newConfig: PDFExportConfig) {
        self.config = newConfig
    }
    
    /// 生成 PDF 数据
    func generatePDF(dreams: [Dream]) async throws -> Data {
        // 过滤和排序梦境
        let filteredDreams = filterDreams(dreams)
        let sortedDreams = sortDreams(filteredDreams)
        
        guard !sortedDreams.isEmpty else {
            throw PDFExportError.noDreamsInRange
        }
        
        var pdfData = Data()
        
        try await Task {
            pdfData = renderer.pdfData { context in
                // 封面页
                if config.includeCoverPage {
                    drawCoverPage(context: context, dreamCount: sortedDreams.count)
                }
                
                // 目录页
                if config.includeTableOfContents {
                    drawTableOfContents(context: context, dreams: sortedDreams)
                }
                
                // 统计页
                if config.includeStatistics {
                    drawStatisticsPage(context: context, dreams: sortedDreams)
                }
                
                // 梦境内容页
                for (index, dream) in sortedDreams.enumerated() {
                    drawDreamPage(context: context, dream: dream, pageNumber: index + 1)
                }
                
                // 封底页
                drawBackCover(context: context)
            }
        }.value
        
        return pdfData
    }
    
    // MARK: - 过滤和排序
    
    private func filterDreams(_ dreams: [Dream]) -> [Dream] {
        dreams.filter { dream in
            dream.date >= config.dateRange.startDate && 
            dream.date <= config.dateRange.endDate
        }
    }
    
    private func sortDreams(_ dreams: [Dream]) -> [Dream] {
        switch config.sortBy {
        case .dateDesc:
            return dreams.sorted { $0.date > $1.date }
        case .dateAsc:
            return dreams.sorted { $0.date < $1.date }
        case .clarity:
            return dreams.sorted { $0.clarity > $1.clarity }
        case .intensity:
            return dreams.sorted { $0.intensity > $1.intensity }
        }
    }
    
    // MARK: - 绘图方法
    
    private func drawCoverPage(context: UIGraphicsPDFRendererContext, dreamCount: Int) {
        context.beginPage()
        
        let bounds = context.format.bounds
        let style = config.style
        
        // 背景渐变
        let gradientColors = [
            style.primaryColor.cgColor,
            style.primaryColor.withAlphaComponent(0.3).cgColor
        ]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: [0, 1])!
        context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: bounds.height), options: [])
        
        // 装饰元素
        drawDecorativeElements(context: context, bounds: bounds, style: style)
        
        // 标题
        let titleRect = CGRect(x: bounds.midX - 200, y: bounds.midY - 150, width: 400, height: 100)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        config.customTitle.draw(in: titleRect, withAttributes: titleAttributes)
        
        // 副标题
        let subtitleRect = CGRect(x: bounds.midX - 150, y: bounds.midY - 60, width: 300, height: 50)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        config.customSubtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        
        // 统计信息
        let statsRect = CGRect(x: bounds.midX - 100, y: bounds.midY + 50, width: 200, height: 80)
        let statsText = "\(dreamCount) 个梦境\n\(formattedDateRange())"
        let statsAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        statsText.draw(in: statsRect, withAttributes: statsAttributes)
        
        // 底部标识
        let footerRect = CGRect(x: bounds.midX - 80, y: bounds.height - 80, width: 160, height: 30)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        "Generated by DreamLog 🌙".draw(in: footerRect, withAttributes: footerAttributes)
    }
    
    private func drawTableOfContents(context: UIGraphicsPDFRendererContext, dreams: [Dream]) {
        context.beginPage()
        
        let bounds = context.format.bounds
        let margins = UIEdgeInsets(top: 80, left: 60, bottom: 60, right: 60)
        
        // 标题
        let titleRect = CGRect(x: margins.left, y: margins.top, width: bounds.width - margins.left - margins.right, height: 60)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: config.style.primaryColor
        ]
        "目录".draw(in: titleRect, withAttributes: titleAttributes)
        
        // 分隔线
        let lineRect = CGRect(x: margins.left, y: margins.top + 65, width: bounds.width - margins.left - margins.right, height: 2)
        config.style.primaryColor.setFill()
        lineRect.fill()
        
        // 梦境列表
        var yPosition: CGFloat = margins.top + 100
        let lineHeight: CGFloat = 40
        
        for (index, dream) in dreams.prefix(15).enumerated() {
            if yPosition + lineHeight > bounds.height - margins.bottom {
                break // 避免超出页面
            }
            
            let entryRect = CGRect(x: margins.left, y: yPosition, width: bounds.width - margins.left - margins.right, height: lineHeight)
            
            let entryText = "\(index + 1). \(dream.title.isEmpty ? "无题梦境" : dream.title) — \(formatDate(dream.date))"
            let entryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            entryText.draw(in: entryRect, withAttributes: entryAttributes)
            
            yPosition += lineHeight
        }
        
        if dreams.count > 15 {
            let moreRect = CGRect(x: margins.left, y: yPosition + 20, width: bounds.width - margins.left - margins.right, height: 30)
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .light),
                .foregroundColor: UIColor.gray
            ]
            "… 以及另外 \(dreams.count - 15) 个梦境".draw(in: moreRect, withAttributes: moreAttributes)
        }
    }
    
    private func drawStatisticsPage(context: UIGraphicsPDFRendererContext, dreams: [Dream]) {
        context.beginPage()
        
        let bounds = context.format.bounds
        let margins = UIEdgeInsets(top: 80, left: 60, bottom: 60, right: 60)
        
        // 标题
        let titleRect = CGRect(x: margins.left, y: margins.top, width: bounds.width - margins.left - margins.right, height: 60)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: config.style.primaryColor
        ]
        "梦境统计".draw(in: titleRect, withAttributes: titleAttributes)
        
        // 统计卡片
        let stats = calculateStatistics(dreams)
        let cardWidth: CGFloat = (bounds.width - margins.left - margins.right - 20) / 2
        let cardHeight: CGFloat = 120
        
        // 第一行
        drawStatCard(context: context, title: "总梦境数", value: "\(stats.totalCount)", icon: "moon.fill", 
                     frame: CGRect(x: margins.left, y: margins.top + 100, width: cardWidth, height: cardHeight))
        drawStatCard(context: context, title: "清醒梦", value: "\(stats.lucidCount)", icon: "eye.fill",
                     frame: CGRect(x: margins.left + cardWidth + 20, y: margins.top + 100, width: cardWidth, height: cardHeight))
        
        // 第二行
        drawStatCard(context: context, title: "平均清晰度", value: String(format: "%.1f", stats.avgClarity), icon: "star.fill",
                     frame: CGRect(x: margins.left, y: margins.top + 240, width: cardWidth, height: cardHeight))
        drawStatCard(context: context, title: "平均强度", value: String(format: "%.1f", stats.avgIntensity), icon: "bolt.fill",
                     frame: CGRect(x: margins.left + cardWidth + 20, y: margins.top + 240, width: cardWidth, height: cardHeight))
        
        // 情绪分布
        let emotionY: CGFloat = margins.top + 380
        let emotionTitleRect = CGRect(x: margins.left, y: emotionY, width: 200, height: 30)
        let emotionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        "情绪分布".draw(in: emotionTitleRect, withAttributes: emotionTitleAttributes)
        
        // 简单的情绪条形图
        var emotionYPos = emotionY + 40
        let sortedEmotions = stats.emotionDistribution.sorted { $0.value > $1.value }.prefix(5)
        for (emotion, count) in sortedEmotions {
            let barWidth = (CGFloat(count) / CGFloat(stats.totalCount)) * (bounds.width - margins.left - margins.right)
            let barRect = CGRect(x: margins.left, y: emotionYPos, width: max(barWidth, 30), height: 20)
            
            let emotionColor = getEmotionColor(emotion)
            emotionColor.setFill()
            barRect.fill()
            
            let labelRect = CGRect(x: margins.left + barWidth + 40, y: emotionYPos - 2, width: 150, height: 24)
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            "\(emotion): \(count)".draw(in: labelRect, withAttributes: labelAttributes)
            
            emotionYPos += 30
        }
    }
    
    private func drawDreamPage(context: UIGraphicsPDFRendererContext, dream: Dream, pageNumber: Int) {
        context.beginPage()
        
        let bounds = context.format.bounds
        let margins = UIEdgeInsets(top: 80, left: 60, bottom: 60, right: 60)
        
        // 页眉
        let headerRect = CGRect(x: margins.left, y: margins.top - 20, width: bounds.width - margins.left - margins.right, height: 40)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .light),
            .foregroundColor: UIColor.gray
        ]
        "第 \(pageNumber) 页 • \(formatDate(dream.date))".draw(in: headerRect, withAttributes: headerAttributes)
        
        // 梦境标题
        let titleRect = CGRect(x: margins.left, y: margins.top + 20, width: bounds.width - margins.left - margins.right, height: 50)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: config.style.primaryColor
        ]
        (dream.title.isEmpty ? "无题梦境" : dream.title).draw(in: titleRect, withAttributes: titleAttributes)
        
        // 元信息 (标签和情绪)
        var metaY = margins.top + 80
        if config.includeTags && !dream.tags.isEmpty {
            let tagsText = "🏷️ " + dream.tags.prefix(5).joined(separator: " · ")
            let tagsRect = CGRect(x: margins.left, y: metaY, width: bounds.width - margins.left - margins.right, height: 25)
            let tagsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            tagsText.draw(in: tagsRect, withAttributes: tagsAttributes)
            metaY += 25
        }
        
        if config.includeEmotions && !dream.emotions.isEmpty {
            let emotionsText = "😊 " + dream.emotions.map { $0.rawValue }.prefix(3).joined(separator: " · ")
            let emotionsRect = CGRect(x: margins.left, y: metaY, width: bounds.width - margins.left - margins.right, height: 25)
            let emotionsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            emotionsText.draw(in: emotionsRect, withAttributes: emotionsAttributes)
            metaY += 25
        }
        
        // 清晰度/强度指示器
        let indicatorsRect = CGRect(x: margins.left, y: metaY, width: bounds.width - margins.left - margins.right, height: 25)
        let indicatorsText = "⭐ 清晰度：\(String(repeating: "★", count: dream.clarity) + String(repeating: "☆", count: 5 - dream.clarity))  |  🔥 强度：\(dream.intensity)/5"
        let indicatorsAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        indicatorsText.draw(in: indicatorsRect, withAttributes: indicatorsAttributes)
        
        // 梦境内容
        let contentY = metaY + 40
        let contentRect = CGRect(x: margins.left, y: contentY, width: bounds.width - margins.left - margins.right, height: bounds.height - contentY - margins.bottom - 100)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.black,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 6
                return style
            }()
        ]
        dream.content.draw(in: contentRect, withAttributes: contentAttributes)
        
        // AI 分析
        if let aiAnalysis = dream.aiAnalysis, !aiAnalysis.isEmpty {
            let aiY = bounds.height - margins.bottom - 90
            let aiRect = CGRect(x: margins.left, y: aiY, width: bounds.width - margins.left - margins.right, height: 80)
            
            // AI 分析背景
            let aiBackgroundRect = aiRect.insetBy(dx: -10, dy: -10)
            let aiBackgroundPath = UIBezierPath(roundedRect: aiBackgroundRect, cornerRadius: 10)
            config.style.primaryColor.withAlphaComponent(0.1).setFill()
            aiBackgroundPath.fill()
            
            let aiTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: config.style.primaryColor
            ]
            "🧠 AI 解析".draw(in: CGRect(x: margins.left + 10, y: aiY, width: 100, height: 20), withAttributes: aiTitleAttributes)
            
            let aiContentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 4
                    return style
                }()
            ]
            aiAnalysis.draw(in: CGRect(x: margins.left + 10, y: aiY + 25, width: bounds.width - margins.left - margins.right - 20, height: 50), withAttributes: aiContentAttributes)
        }
        
        // 页脚
        let footerRect = CGRect(x: bounds.midX - 50, y: bounds.height - 30, width: 100, height: 20)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .light),
            .foregroundColor: UIColor.lightGray
        ]
        "DreamLog 🌙".draw(in: footerRect, withAttributes: footerAttributes)
    }
    
    private func drawBackCover(context: UIGraphicsPDFRendererContext) {
        context.beginPage()
        
        let bounds = context.format.bounds
        let style = config.style
        
        // 背景
        style.primaryColor.withAlphaComponent(0.1).setFill()
        bounds.fill()
        
        // 中心标识
        let logoRect = CGRect(x: bounds.midX - 100, y: bounds.midY - 50, width: 200, height: 100)
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: style.primaryColor
        ]
        "DreamLog 🌙".draw(in: logoRect, withAttributes: logoAttributes)
        
        // 标语
        let sloganRect = CGRect(x: bounds.midX - 150, y: bounds.midY + 60, width: 300, height: 40)
        let sloganAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .light),
            .foregroundColor: style.primaryColor.withAlphaComponent(0.7)
        ]
        "记录你的梦，发现潜意识的秘密".draw(in: sloganRect, withAttributes: sloganAttributes)
        
        // 生成日期
        let dateRect = CGRect(x: bounds.midX - 100, y: bounds.height - 100, width: 200, height: 30)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: style.primaryColor.withAlphaComponent(0.5)
        ]
        "生成于 \(formatDate(Date()))".draw(in: dateRect, withAttributes: dateAttributes)
    }
    
    // MARK: - 辅助方法
    
    private func drawDecorativeElements(context: UIGraphicsPDFRendererContext, bounds: CGRect, style: PDFExportStyle) {
        // 简单的装饰性星星
        let starCount = 20
        for _ in 0..<starCount {
            let x = CGFloat.random(in: 0..<bounds.width)
            let y = CGFloat.random(in: 0..<bounds.height)
            let size = CGFloat.random(in: 2..<8)
            
            let starPath = UIBezierPath()
            for i in 0..<5 {
                let angle = CGFloat(i) * 2 * .pi / 5 - .pi / 2
                let outerX = x + size * cos(angle)
                let outerY = y + size * sin(angle)
                
                let innerAngle = angle + .pi / 5
                let innerSize = size * 0.4
                let innerX = x + innerSize * cos(innerAngle)
                let innerY = y + innerSize * sin(innerAngle)
                
                if i == 0 {
                    starPath.move(to: CGPoint(x: outerX, y: outerY))
                } else {
                    starPath.addLine(to: CGPoint(x: outerX, y: outerY))
                }
                starPath.addLine(to: CGPoint(x: innerX, y: innerY))
            }
            starPath.close()
            
            UIColor.white.withAlphaComponent(CGFloat.random(in: 0.3..<0.8)).setFill()
            starPath.fill()
        }
    }
    
    private func drawStatCard(context: UIGraphicsPDFRendererContext, title: String, value: String, icon: String, frame: CGRect) {
        let cardPath = UIBezierPath(roundedRect: frame, cornerRadius: 12)
        config.style.primaryColor.withAlphaComponent(0.1).setFill()
        cardPath.fill()
        
        let titleRect = CGRect(x: frame.origin.x + 15, y: frame.origin.y + 15, width: frame.width - 30, height: 25)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        let valueRect = CGRect(x: frame.origin.x + 15, y: frame.origin.y + 45, width: frame.width - 30, height: 40)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold),
            .foregroundColor: config.style.primaryColor
        ]
        value.draw(in: valueRect, withAttributes: valueAttributes)
    }
    
    private func calculateStatistics(_ dreams: [Dream]) -> DreamStatistics {
        let totalCount = dreams.count
        let lucidCount = dreams.filter { $0.isLucid }.count
        let avgClarity = dreams.isEmpty ? 0 : dreams.reduce(0) { $0 + $1.clarity } / Double(count)
        let avgIntensity = dreams.isEmpty ? 0 : dreams.reduce(0) { $0 + $1.intensity } / Double(count)
        
        var emotionDistribution: [String: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                emotionDistribution[emotion.rawValue, default: 0] += 1
            }
        }
        
        return DreamStatistics(
            totalCount: totalCount,
            lucidCount: lucidCount,
            avgClarity: avgClarity,
            avgIntensity: avgIntensity,
            emotionDistribution: emotionDistribution
        )
    }
    
    private struct DreamStatistics {
        let totalCount: Int
        let lucidCount: Int
        let avgClarity: Double
        let avgIntensity: Double
        let emotionDistribution: [String: Int]
    }
    
    private func getEmotionColor(_ emotion: String) -> UIColor {
        switch emotion {
        case "快乐": return UIColor.systemYellow
        case "焦虑": return UIColor.systemOrange
        case "恐惧": return UIColor.systemRed
        case "平静": return UIColor.systemBlue
        case "悲伤": return UIColor.systemPurple
        case "兴奋": return UIColor.systemPink
        default: return UIColor.systemGray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formattedDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return "\(formatter.string(from: config.dateRange.startDate)) - \(formatter.string(from: config.dateRange.endDate))"
    }
}

// MARK: - 错误类型

enum PDFExportError: LocalizedError {
    case noDreamsInRange
    case generationFailed
    case fileSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .noDreamsInRange: return "所选日期范围内没有梦境记录"
        case .generationFailed: return "PDF 生成失败，请重试"
        case .fileSaveFailed: return "文件保存失败"
        }
    }
}
