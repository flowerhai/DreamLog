//
//  DreamReportExportService.swift
//  DreamLog
//
//  Phase 20: 梦境分析报告导出服务
//  生成可导出的 PDF 分析报告，包含统计、趋势、关联分析
//

import Foundation
import UIKit

/// 梦境报告导出服务
class DreamReportExportService {
    static let shared = DreamReportExportService()
    
    // MARK: - 数据结构
    
    struct ReportConfig {
        var includeStatistics: Bool = true
        var includeTrends: Bool = true
        var includeCorrelations: Bool = true
        var includePredictions: Bool = true
        var includeRawData: Bool = false
        var dateRange: DateInterval?
        var pageSize: PageSize = .a4
        
        enum PageSize {
            case a4
            case letter
            case custom(width: CGFloat, height: CGFloat)
            
            var size: CGSize {
                switch self {
                case .a4: return CGSize(width: 595, height: 842)
                case .letter: return CGSize(width: 612, height: 792)
                case .custom(let width, let height): return CGSize(width: width, height: height)
                }
            }
        }
    }
    
    // MARK: - 公开方法
    
    /// 生成 PDF 报告
    func generatePDFReport(
        dreams: [Dream],
        config: ReportConfig = ReportConfig(),
        correlationReport: DreamCorrelationService.DreamCorrelationReport?,
        trendReport: DreamTrendService.DreamTrendReport?
    ) -> Data? {
        let pageSize = config.pageSize.size
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        var pdfData = Data()
        
        // 计算总页数
        let totalPages = calculateTotalPages(config: config)
        
        // 创建 PDF
        var currentPage = 0
        
        for page in 0..<totalPages {
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: pageSize))
                
                currentPage = page + 1
                drawPage(
                    in: context,
                    dreams: dreams,
                    config: config,
                    correlationReport: correlationReport,
                    trendReport: trendReport,
                    pageNumber: currentPage,
                    totalPages: totalPages
                )
            }
            
            // 将图片转换为 PDF
            if let pdfRepresentation = image.jpegData(compressionQuality: 0.9) {
                if page == 0 {
                    pdfData.append(pdfRepresentation)
                }
            }
        }
        
        return pdfData.isEmpty ? nil : pdfData
    }
    
    /// 保存报告到文件
    func saveReportToFile(
        dreams: [Dream],
        config: ReportConfig = ReportConfig(),
        correlationReport: DreamCorrelationService.DreamCorrelationReport?,
        trendReport: DreamTrendService.DreamTrendReport?,
        filename: String? = nil
    ) -> URL? {
        guard let pdfData = generatePDFReport(
            dreams: dreams,
            config: config,
            correlationReport: correlationReport,
            trendReport: trendReport
        ) else {
            return nil
        }
        
        let fileName = filename ?? generateFilename()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("保存报告失败：\(error)")
            return nil
        }
    }
    
    /// 分享报告
    func shareReport(
        dreams: [Dream],
        config: ReportConfig = ReportConfig(),
        correlationReport: DreamCorrelationService.DreamCorrelationReport?,
        trendReport: DreamTrendService.DreamTrendReport?,
        from viewController: UIViewController
    ) {
        guard let pdfData = generatePDFReport(
            dreams: dreams,
            config: config,
            correlationReport: correlationReport,
            trendReport: trendReport
        ) else {
            return
        }
        
        let fileName = generateFilename()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            viewController.present(activityVC, animated: true)
        } catch {
            print("分享报告失败：\(error)")
        }
    }
    
    // MARK: - 私有方法
    
    private func calculateTotalPages(config: ReportConfig) -> Int {
        var pages = 1 // 封面页
        
        if config.includeStatistics {
            pages += 1 // 统计页
        }
        
        if config.includeTrends {
            pages += 1 // 趋势页
        }
        
        if config.includeCorrelations {
            pages += 1 // 关联分析页
        }
        
        if config.includePredictions {
            pages += 1 // 预测页
        }
        
        if config.includeRawData {
            pages += 1 // 原始数据页
        }
        
        return pages
    }
    
    private func drawPage(
        in context: UIGraphicsImageRendererContext,
        dreams: [Dream],
        config: ReportConfig,
        correlationReport: DreamCorrelationService.DreamCorrelationReport?,
        trendReport: DreamTrendService.DreamTrendReport?,
        pageNumber: Int,
        totalPages: Int
    ) {
        let pageSize = config.pageSize.size
        let ctx = context.cgContext
        
        // 页面边距
        let margin: CGFloat = 40
        let contentWidth = pageSize.width - margin * 2
        
        // 计算页码对应的内容
        var currentY: CGFloat = margin
        var pageIndex = 1
        
        // 封面页
        if pageNumber == 1 {
            drawCoverPage(in: ctx, dreams: dreams, rect: CGRect(x: margin, y: margin, width: contentWidth, height: pageSize.height - margin * 2))
            return
        }
        
        // 统计页
        if config.includeStatistics && pageNumber == pageIndex + 1 {
            pageIndex += 1
            drawStatisticsPage(in: ctx, dreams: dreams, rect: CGRect(x: margin, y: margin, width: contentWidth, height: pageSize.height - margin * 2))
            drawPageNumber(in: ctx, pageNumber: pageNumber, totalPages: totalPages, rect: CGRect(x: margin, y: pageSize.height - 30, width: contentWidth, height: 20))
            return
        }
        
        // 趋势页
        if config.includeTrends && pageNumber == pageIndex + 1 {
            pageIndex += 1
            drawTrendsPage(in: ctx, trendReport: trendReport, rect: CGRect(x: margin, y: margin, width: contentWidth, height: pageSize.height - margin * 2))
            drawPageNumber(in: ctx, pageNumber: pageNumber, totalPages: totalPages, rect: CGRect(x: margin, y: pageSize.height - 30, width: contentWidth, height: 20))
            return
        }
        
        // 关联分析页
        if config.includeCorrelations && pageNumber == pageIndex + 1 {
            pageIndex += 1
            drawCorrelationsPage(in: ctx, correlationReport: correlationReport, rect: CGRect(x: margin, y: margin, width: contentWidth, height: pageSize.height - margin * 2))
            drawPageNumber(in: ctx, pageNumber: pageNumber, totalPages: totalPages, rect: CGRect(x: margin, y: pageSize.height - 30, width: contentWidth, height: 20))
            return
        }
        
        // 预测页
        if config.includePredictions && pageNumber == pageIndex + 1 {
            pageIndex += 1
            drawPredictionsPage(in: ctx, trendReport: trendReport, rect: CGRect(x: margin, y: margin, width: contentWidth, height: pageSize.height - margin * 2))
            drawPageNumber(in: ctx, pageNumber: pageNumber, totalPages: totalPages, rect: CGRect(x: margin, y: pageSize.height - 30, width: contentWidth, height: 20))
            return
        }
        
        // 原始数据页
        if config.includeRawData && pageNumber == pageIndex + 1 {
            pageIndex += 1
            drawRawDataPage(in: ctx, dreams: dreams, rect: CGRect(x: margin, y: margin, width: contentWidth, height: pageSize.height - margin * 2))
            drawPageNumber(in: ctx, pageNumber: pageNumber, totalPages: totalPages, rect: CGRect(x: margin, y: pageSize.height - 30, width: contentWidth, height: 20))
            return
        }
    }
    
    // MARK: - 页面绘制
    
    private func drawCoverPage(in ctx: CGContext, dreams: [Dream], rect: CGRect) {
        let title = "梦境分析报告"
        let subtitle = "DreamLog Analytics Report"
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        let totalDreams = dreams.count
        
        // 标题
        let titleFont = UIFont.boldSystemFont(ofSize: 36)
        let titleRect = CGRect(x: rect.origin.x, y: rect.origin.y + 100, width: rect.width, height: 50)
        drawText(title, in: titleRect, font: titleFont, color: .black, alignment: .center)
        
        // 副标题
        let subtitleFont = UIFont.systemFont(ofSize: 18)
        let subtitleRect = CGRect(x: rect.origin.x, y: titleRect.maxY + 10, width: rect.width, height: 30)
        drawText(subtitle, in: subtitleRect, font: subtitleFont, color: .gray, alignment: .center)
        
        // 日期
        let dateFont = UIFont.systemFont(ofSize: 14)
        let dateRect = CGRect(x: rect.origin.x, y: subtitleRect.maxY + 40, width: rect.width, height: 20)
        drawText("生成日期：\(date)", in: dateRect, font: dateFont, color: .gray, alignment: .center)
        
        // 统计摘要
        let statsFont = UIFont.systemFont(ofSize: 16)
        let statsY = rect.midY - 50
        
        let statsText = "共分析 \(totalDreams) 个梦境"
        let statsRect = CGRect(x: rect.origin.x, y: statsY, width: rect.width, height: 30)
        drawText(statsText, in: statsRect, font: statsFont, color: .black, alignment: .center)
        
        // 装饰线
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineWidth(2)
        ctx.stroke(CGRect(x: rect.origin.x + 50, y: statsRect.maxY + 30, width: rect.width - 100, height: 1))
    }
    
    private func drawStatisticsPage(in ctx: CGContext, dreams: [Dream], rect: CGRect) {
        var currentY = rect.origin.y
        
        // 页面标题
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleRect = CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 40)
        drawText("统计概览", in: titleRect, font: titleFont, color: .black, alignment: .left)
        currentY += 50
        
        // 基础统计
        let totalDreams = dreams.count
        let lucidDreams = dreams.filter { $0.isLucid }.count
        let recurringDreams = dreams.filter { $0.isRecurring }.count
        let avgClarity = dreams.map { Double($0.clarity) }.reduce(0, +) / Double(max(dreams.count, 1))
        
        let statsFont = UIFont.systemFont(ofSize: 14)
        let lineHeight: CGFloat = 25
        
        drawText("• 总梦境数：\(totalDreams)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight
        
        drawText("• 清醒梦：\(lucidDreams) (\(String(format: "%.1f", Double(lucidDreams) / Double(max(totalDreams, 1)) * 100))%)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight
        
        drawText("• 重复梦境：\(recurringDreams)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight
        
        drawText("• 平均清晰度：\(String(format: "%.2f", avgClarity)) / 5.0", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight * 2
        
        // 情绪分布
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        drawText("情绪分布", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: sectionTitleFont, color: .black)
        currentY += 35
        
        var emotionCounts: [String: Int] = [:]
        for dream in dreams {
            if let emotion = dream.emotion {
                emotionCounts[emotion.rawValue, default: 0] += 1
            }
        }
        
        let sortedEmotions = emotionCounts.sorted { $0.value > $1.value }
        for (emotion, count) in sortedEmotions.prefix(5) {
            let percentage = Double(count) / Double(totalDreams) * 100
            drawText("  \(emotion): \(count) (\(String(format: "%.1f", percentage))%)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
            currentY += lineHeight
        }
    }
    
    private func drawTrendsPage(in ctx: CGContext, trendReport: DreamTrendService.DreamTrendReport?, rect: CGRect) {
        var currentY = rect.origin.y
        
        // 页面标题
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleRect = CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 40)
        drawText("趋势分析", in: titleRect, font: titleFont, color: .black, alignment: .left)
        currentY += 50
        
        guard let report = trendReport else {
            drawText("暂无趋势数据", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: UIFont.systemFont(ofSize: 14), color: .gray)
            return
        }
        
        let statsFont = UIFont.systemFont(ofSize: 14)
        let lineHeight: CGFloat = 25
        
        // 情绪趋势
        drawText("情绪稳定性：\(String(format: "%.0f", report.emotionStability * 100))%", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight
        
        // 清晰度趋势
        drawText("清晰度趋势：\(report.clarityTrend.rawValue)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight
        
        // 清醒梦趋势
        drawText("清醒梦频率：\(String(format: "%.1f", report.lucidDreamFrequency))%", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight * 2
        
        // 预测
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        drawText("AI 预测", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: sectionTitleFont, color: .black)
        currentY += 35
        
        for prediction in report.predictions.prefix(5) {
            drawText("• \(prediction.description)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
            currentY += lineHeight
        }
    }
    
    private func drawCorrelationsPage(in ctx: CGContext, correlationReport: DreamCorrelationService.DreamCorrelationReport?, rect: CGRect) {
        var currentY = rect.origin.y
        
        // 页面标题
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleRect = CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 40)
        drawText("关联分析", in: titleRect, font: titleFont, color: .black, alignment: .left)
        currentY += 50
        
        guard let report = correlationReport else {
            drawText("暂无关联分析数据", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: UIFont.systemFont(ofSize: 14), color: .gray)
            return
        }
        
        let statsFont = UIFont.systemFont(ofSize: 14)
        let lineHeight: CGFloat = 25
        
        // 分析概览
        drawText("分析梦境数：\(report.totalDreamsAnalyzed)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight
        
        drawText("分析周期：\(DateFormatter.localizedString(from: report.analysisPeriod.start, dateStyle: .medium, timeStyle: .none)) - \(DateFormatter.localizedString(from: report.analysisPeriod.end, dateStyle: .medium, timeStyle: .none))", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
        currentY += lineHeight * 2
        
        // 强关联发现
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        drawText("强关联发现", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: sectionTitleFont, color: .black)
        currentY += 35
        
        for corr in report.strongCorrelations.prefix(5) {
            drawText("• \(corr.factorA) ↔ \(corr.factorB): \(corr.insight)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
            currentY += lineHeight
        }
        
        currentY += lineHeight
        
        // 洞察
        drawText("AI 洞察", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: sectionTitleFont, color: .black)
        currentY += 35
        
        for insight in report.insights.prefix(3) {
            drawText("• \(insight.description)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
            currentY += lineHeight
        }
    }
    
    private func drawPredictionsPage(in ctx: CGContext, trendReport: DreamTrendService.DreamTrendReport?, rect: CGRect) {
        var currentY = rect.origin.y
        
        // 页面标题
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleRect = CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 40)
        drawText("预测与建议", in: titleRect, font: titleFont, color: .black, alignment: .left)
        currentY += 50
        
        guard let report = trendReport else {
            drawText("暂无预测数据", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: UIFont.systemFont(ofSize: 14), color: .gray)
            return
        }
        
        let statsFont = UIFont.systemFont(ofSize: 14)
        let lineHeight: CGFloat = 25
        
        // 预测
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 18)
        drawText("AI 预测", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: sectionTitleFont, color: .black)
        currentY += 35
        
        for prediction in report.predictions {
            drawText("• [\(prediction.type.rawValue)] \(prediction.description)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
            currentY += lineHeight
        }
        
        currentY += lineHeight * 2
        
        // 建议
        drawText("个性化建议", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 30), font: sectionTitleFont, color: .black)
        currentY += 35
        
        for (index, recommendation) in report.recommendations.enumerated() {
            drawText("\(index + 1). \(recommendation)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .black)
            currentY += lineHeight
        }
    }
    
    private func drawRawDataPage(in ctx: CGContext, dreams: [Dream], rect: CGRect) {
        var currentY = rect.origin.y
        
        // 页面标题
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleRect = CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: 40)
        drawText("原始数据", in: titleRect, font: titleFont, color: .black, alignment: .left)
        currentY += 50
        
        let statsFont = UIFont.systemFont(ofSize: 10)
        let lineHeight: CGFloat = 20
        
        for dream in dreams.prefix(20) {
            let dateStr = DateFormatter.localizedString(from: dream.date, dateStyle: .short, timeStyle: .none)
            let title = dream.title.isEmpty ? "无标题" : dream.title
            let content = dream.content.prefix(100).replacingOccurrences(of: "\n", with: " ")
            
            drawText("\(dateStr) - \(title)", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: UIFont.boldSystemFont(ofSize: 10), color: .black)
            currentY += lineHeight
            
            drawText("  \(content)...", in: CGRect(x: rect.origin.x + 10, y: currentY, width: rect.width - 10, height: lineHeight), font: statsFont, color: .gray)
            currentY += lineHeight * 1.5
        }
        
        if dreams.count > 20 {
            drawText("... 还有 \(dreams.count - 20) 条梦境未在报告中显示", in: CGRect(x: rect.origin.x, y: currentY, width: rect.width, height: lineHeight), font: statsFont, color: .gray)
        }
    }
    
    private func drawPageNumber(in ctx: CGContext, pageNumber: Int, totalPages: Int, rect: CGRect) {
        let font = UIFont.systemFont(ofSize: 10)
        let text = "第 \(pageNumber) 页 / 共 \(totalPages) 页"
        drawText(text, in: rect, font: font, color: .gray, alignment: .center)
    }
    
    // MARK: - 辅助方法
    
    private func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        text.draw(in: rect, withAttributes: attributes)
    }
    
    private func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return "DreamLog_Report_\(dateFormatter.string(from: Date())).pdf"
    }
}
