//
//  DreamReportGenerator.swift
//  DreamLog
//
//  Phase 74: 梦境数据分析增强 📊🔍
//  梦境报告生成引擎
//
//  Created: 2026-03-20
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData
import PDFKit

// MARK: - 报告生成器

/// 梦境报告生成器
public actor DreamReportGenerator {
    /// 共享实例
    public static let shared = DreamReportGenerator()
    
    /// 报告模板
    private let templates: [ReportType: ReportTemplate]
    
    private init() {
        self.templates = [
            .weekly: WeeklyReportTemplate(),
            .monthly: MonthlyReportTemplate(),
            .yearly: YearlyReportTemplate()
        ]
    }
    
    // MARK: - 公共方法
    
    /// 生成报告
    public func generateReport(
        type: ReportType,
        startDate: Date,
        endDate: Date,
        in context: ModelContext
    ) async throws -> DreamReport {
        guard let template = templates[type] else {
            throw ReportError.templateNotFound
        }
        
        // 获取时间段内的梦境
        let dreams = try fetchDreams(
            from: startDate,
            to: endDate,
            in: context
        )
        
        guard !dreams.isEmpty else {
            throw ReportError.noDreamsInPeriod
        }
        
        // 使用模板生成报告
        let report = try await template.generate(
            dreams: dreams,
            from: startDate,
            to: endDate
        )
        
        return report
    }
    
    /// 生成 PDF 报告
    public func generatePDF(
        from report: DreamReport,
        template: ReportTemplate? = nil
    ) async throws -> Data {
        let pdfTemplate = template ?? templates[report.type] ?? DefaultReportTemplate()
        
        // 生成 PDF 内容
        let pdfData = try await pdfTemplate.renderToPDF(report: report)
        
        return pdfData
    }
    
    /// 生成所有类型的报告
    public func generateAllReports(
        in context: ModelContext
    ) async throws -> [ReportType: DreamReport] {
        var reports: [ReportType: DreamReport] = [:]
        
        let now = Date()
        let calendar = Calendar.current
        
        // 周报
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
            do {
                let weeklyReport = try await generateReport(
                    type: .weekly,
                    startDate: weekAgo,
                    endDate: now,
                    in: context
                )
                reports[.weekly] = weeklyReport
            } catch {
                // 继续生成其他报告
            }
        }
        
        // 月报
        if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
            do {
                let monthlyReport = try await generateReport(
                    type: .monthly,
                    startDate: monthAgo,
                    endDate: now,
                    in: context
                )
                reports[.monthly] = monthlyReport
            } catch {
                // 继续生成其他报告
            }
        }
        
        // 年报
        if let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) {
            do {
                let yearlyReport = try await generateReport(
                    type: .yearly,
                    startDate: yearAgo,
                    endDate: now,
                    in: context
                )
                reports[.yearly] = yearlyReport
            } catch {
                // 继续生成其他报告
            }
        }
        
        return reports
    }
    
    // MARK: - 数据获取
    
    /// 获取时间段内的梦境
    private func fetchDreams(
        from startDate: Date,
        to endDate: Date,
        in context: ModelContext
    ) throws -> [DreamEntry] {
        let predicate = #Predicate<DreamEntry> { dream in
            dream.date >= startDate && dream.date <= endDate
        }
        
        let descriptor = FetchDescriptor<DreamEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )
        
        return try context.fetch(descriptor)
    }
}

// MARK: - 报告模板协议

public protocol ReportTemplate: AnyObject {
    var reportType: ReportType { get }
    var title: String { get }
    var description: String { get }
    
    func generate(
        dreams: [DreamEntry],
        from startDate: Date,
        to endDate: Date
    ) async throws -> DreamReport
    
    func renderToPDF(report: DreamReport) async throws -> Data
}

// MARK: - 周报模板

public class WeeklyReportTemplate: ReportTemplate {
    public let reportType = ReportType.weekly
    public let title = "梦境周报"
    public let description = "每周梦境总结与洞察"
    
    public func generate(
        dreams: [DreamEntry],
        from startDate: Date,
        to endDate: Date
    ) async throws -> DreamReport {
        let calendar = Calendar.current
        
        // 基础统计
        let totalDreams = dreams.count
        let averageClarity = dreams.map { $0.clarity ?? 0.5 }.reduce(0, +) / Double(totalDreams)
        let lucidCount = dreams.filter { $0.isLucid }.count
        
        // 情绪分布
        let emotionCounts = Dictionary(grouping: dreams) { dream in
            dream.emotion?.displayName ?? "中性"
        }.mapValues { Double($0.count) / Double(totalDreams) }
        
        let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "中性"
        
        // 热门符号
        let allSymbols = dreams.flatMap { $0.symbols ?? [] }
        let topSymbols = Dictionary(grouping: allSymbols) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
        
        // 生成洞察
        let insights = try await generateInsights(dreams: dreams)
        
        // 生成可视化数据
        let visualizations = generateVisualizations(dreams: dreams)
        
        // 生成建议
        let recommendations = generateRecommendations(dreams: dreams)
        
        // 关键词
        let keywords = extractKeywords(dreams: dreams)
        
        // 亮点
        let highlight = generateHighlight(dreams: dreams)
        
        return DreamReport(
            id: UUID(),
            type: .weekly,
            title: "梦境周报 - \(formatDateRange(from: startDate, to: endDate))",
            periodStart: startDate,
            periodEnd: endDate,
            generatedAt: Date(),
            summary: .init(
                totalDreams: totalDreams,
                averageClarity: averageClarity,
                dominantEmotion: dominantEmotion,
                lucidDreamCount: lucidCount,
                keyWords: keywords,
                highlight: highlight
            ),
            statistics: .init(
                dreamsByDay: groupDreamsByDay(dreams: dreams, calendar: calendar),
                emotionDistribution: emotionCounts,
                topSymbols: topSymbols,
                averageLength: dreams.map { Double($0.content?.count ?? 0) }.reduce(0, +) / Double(totalDreams),
                sleepQualityCorrelation: calculateSleepQualityCorrelation(dreams: dreams)
            ),
            insights: insights,
            visualizations: visualizations,
            recommendations: recommendations
        )
    }
    
    public func renderToPDF(report: DreamReport) async throws -> Data {
        // PDF 渲染实现
        return Data()
    }
    
    // MARK: - 辅助方法
    
    private func generateInsights(dreams: [DreamEntry]) async throws -> [DreamReport.ReportInsight] {
        var insights: [DreamReport.ReportInsight] = []
        
        // 检查清醒梦趋势
        let lucidRatio = Double(dreams.filter { $0.isLucid }.count) / Double(dreams.count)
        if lucidRatio > 0.3 {
            insights.append(.init(
                id: UUID(),
                type: .achievement,
                title: "清醒梦大师",
                description: "本周 \(Int(lucidRatio * 100))% 的梦境是清醒梦，表现优异！",
                icon: "brain.head.profile",
                severity: .low
            ))
        }
        
        // 检查记录频率
        if dreams.count >= 7 {
            insights.append(.init(
                id: UUID(),
                type: .achievement,
                title: "持之以恒",
                description: "连续记录 7 天，继续保持！",
                icon: "calendar.badge.checkmark",
                severity: .low
            ))
        }
        
        // 检查情绪模式
        let emotionCounts = Dictionary(grouping: dreams) { $0.emotion?.rawValue ?? "neutral" }
        if let negativeEmotions = emotionCounts["anxious"]?.count ?? emotionCounts["fearful"]?.count,
           negativeEmotions > dreams.count / 2 {
            insights.append(.init(
                id: UUID(),
                type: .suggestion,
                title: "压力提醒",
                description: "本周焦虑/恐惧情绪较多，注意休息和放松",
                icon: "heart.fill",
                severity: .medium
            ))
        }
        
        return insights
    }
    
    private func generateVisualizations(dreams: [DreamEntry]) -> [DreamReport.ReportVisualization] {
        var visualizations: [DreamReport.ReportVisualization] = []
        
        // 每日梦境数
        let dreamsByDay = Dictionary(grouping: dreams) { dream in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: dream.date)
        }.mapValues { $0.count }
        
        visualizations.append(.init(
            id: UUID(),
            type: .barChart,
            title: "每日梦境数",
            data: ["values": .dictionary(Dictionary(uniqueKeysWithValues: dreamsByDay.map { ($0.key, .int($0.value)) }))]
        ))
        
        // 情绪分布
        let emotionDist = Dictionary(grouping: dreams) { $0.emotion?.displayName ?? "中性" }
            .mapValues { Double($0.count) }
        
        visualizations.append(.init(
            id: UUID(),
            type: .pieChart,
            title: "情绪分布",
            data: ["values": .dictionary(Dictionary(uniqueKeysWithValues: emotionDist.map { ($0.key, .double($0.value)) }))]
        ))
        
        return visualizations
    }
    
    private func generateRecommendations(dreams: [DreamEntry]) -> [String] {
        var recommendations: [String] = []
        
        // 基于清晰度
        let avgClarity = dreams.map { $0.clarity ?? 0.5 }.reduce(0, +) / Double(dreams.count)
        if avgClarity < 0.4 {
            recommendations.append("尝试在醒来后立即记录梦境，可以提高清晰度")
        }
        
        // 基于记录频率
        if dreams.count < 3 {
            recommendations.append("尝试每天记录，即使是片段也能帮助发现模式")
        }
        
        // 基于清醒梦
        let lucidRatio = Double(dreams.filter { $0.isLucid }.count) / Double(dreams.count)
        if lucidRatio < 0.1 {
            recommendations.append("尝试清醒梦技巧：现实检查、MILD 或 WBTB")
        }
        
        return recommendations
    }
    
    private func extractKeywords(dreams: [DreamEntry]) -> [String] {
        let allSymbols = dreams.flatMap { $0.symbols ?? [] }
        let symbolCounts = Dictionary(grouping: allSymbols) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return symbolCounts.prefix(5).map { $0.key }
    }
    
    private func generateHighlight(dreams: [DreamEntry]) -> String {
        guard let mostLucid = dreams.filter({ $0.isLucid }).max(by: { $0.clarity ?? 0 < $1.clarity ?? 0 }) else {
            return "本周记录了许多有趣的梦境"
        }
        
        return "最精彩的清醒梦：\(mostLucid.title ?? "无题")"
    }
    
    private func groupDreamsByDay(dreams: [DreamEntry], calendar: Calendar) -> [String: Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        return Dictionary(grouping: dreams) { dream in
            formatter.string(from: dream.date)
        }.mapValues { $0.count }
    }
    
    private func calculateSleepQualityCorrelation(dreams: [DreamEntry]) -> Double? {
        guard dreams.count > 2 else { return nil }
        
        let sleepQualities = dreams.map { $0.sleepQuality ?? 0.5 }
        let clarities = dreams.map { $0.clarity ?? 0.5 }
        
        // 简化计算相关系数
        let meanSleep = sleepQualities.reduce(0, +) / Double(sleepQualities.count)
        let meanClarity = clarities.reduce(0, +) / Double(clarities.count)
        
        var numerator = 0.0
        var denomSleep = 0.0
        var denomClarity = 0.0
        
        for i in 0..<dreams.count {
            let sleepDiff = sleepQualities[i] - meanSleep
            let clarityDiff = clarities[i] - meanClarity
            numerator += sleepDiff * clarityDiff
            denomSleep += sleepDiff * sleepDiff
            denomClarity += clarityDiff * clarityDiff
        }
        
        let denominator = sqrt(denomSleep * denomClarity)
        guard denominator > 0 else { return nil }
        
        return numerator / denominator
    }
    
    private func formatDateRange(from startDate: Date, to endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - 月报模板

public class MonthlyReportTemplate: ReportTemplate {
    public let reportType = ReportType.monthly
    public let title = "梦境月报"
    public let description = "月度梦境趋势与深度分析"
    
    public func generate(
        dreams: [DreamEntry],
        from startDate: Date,
        to endDate: Date
    ) async throws -> DreamReport {
        // 类似周报，但包含更多趋势分析
        let weeklyTemplate = WeeklyReportTemplate()
        var report = try await weeklyTemplate.generate(dreams: dreams, from: startDate, to: endDate)
        
        report.type = .monthly
        report.title = "梦境月报 - \(formatMonth(date: endDate))"
        
        // 添加月度特有洞察
        let monthlyInsights = try await generateMonthlyInsights(dreams: dreams)
        report.insights.append(contentsOf: monthlyInsights)
        
        return report
    }
    
    public func renderToPDF(report: DreamReport) async throws -> Data {
        return Data()
    }
    
    private func generateMonthlyInsights(dreams: [DreamEntry]) async throws -> [DreamReport.ReportInsight] {
        var insights: [DreamReport.ReportInsight] = []
        
        // 月度里程碑
        if dreams.count >= 30 {
            insights.append(.init(
                id: UUID(),
                type: .achievement,
                title: "月度记录者",
                description: "本月记录了 \(dreams.count) 个梦境，创下单月新高！",
                icon: "trophy.fill",
                severity: .low
            ))
        }
        
        return insights
    }
    
    private func formatMonth(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月"
        return formatter.string(from: date)
    }
}

// MARK: - 年报模板

public class YearlyReportTemplate: ReportTemplate {
    public let reportType = ReportType.yearly
    public let title = "梦境年报"
    public let description = "年度梦境回顾与成长轨迹"
    
    public func generate(
        dreams: [DreamEntry],
        from startDate: Date,
        to endDate: Date
    ) async throws -> DreamReport {
        let weeklyTemplate = WeeklyReportTemplate()
        var report = try await weeklyTemplate.generate(dreams: dreams, from: startDate, to: endDate)
        
        report.type = .yearly
        report.title = "梦境年报 - \(formatYear(date: endDate))"
        
        // 添加年度特有洞察
        let yearlyInsights = try await generateYearlyInsights(dreams: dreams)
        report.insights.append(contentsOf: yearlyInsights)
        
        return report
    }
    
    public func renderToPDF(report: DreamReport) async throws -> Data {
        return Data()
    }
    
    private func generateYearlyInsights(dreams: [DreamEntry]) async throws -> [DreamReport.ReportInsight] {
        var insights: [DreamReport.ReportInsight] = []
        
        // 年度总计
        insights.append(.init(
            id: UUID(),
            type: .achievement,
            title: "年度旅程",
            description: "这一年记录了 \(dreams.count) 个梦境，是一段精彩的内心旅程",
            icon: "star.fill",
            severity: .low
        ))
        
        return insights
    }
    
    private func formatYear(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - 默认模板

public class DefaultReportTemplate: ReportTemplate {
    public let reportType = ReportType.custom
    public let title = "自定义报告"
    public let description = "自定义时间段报告"
    
    public func generate(
        dreams: [DreamEntry],
        from startDate: Date,
        to endDate: Date
    ) async throws -> DreamReport {
        let weeklyTemplate = WeeklyReportTemplate()
        return try await weeklyTemplate.generate(dreams: dreams, from: startDate, to: endDate)
    }
    
    public func renderToPDF(report: DreamReport) async throws -> Data {
        return Data()
    }
}

// MARK: - 报告错误

public enum ReportError: LocalizedError {
    case templateNotFound
    case noDreamsInPeriod
    case pdfGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "未找到报告模板"
        case .noDreamsInPeriod:
            return "该时间段内没有梦境记录"
        case .pdfGenerationFailed:
            return "PDF 生成失败"
        }
    }
}
