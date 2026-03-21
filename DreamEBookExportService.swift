//
//  DreamEBookExportService.swift
//  DreamLog
//
//  Phase 83: 梦境电子书导出功能
//  核心服务：处理电子书生成、章节组织、PDF/EPUB 渲染
//

import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - 电子书导出服务

/// 梦境电子书导出服务
@MainActor
class DreamEBookExportService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var exportStatus: EBookExportStatus = .idle
    @Published var currentProgress: Int = 0
    @Published var totalProgress: Int = 0
    @Published var errorMessage: String?
    @Published var generatedFileURL: URL?
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Public Methods
    
    /// 生成电子书
    func generateEBook(config: EBookExportConfig) async {
        exportStatus = .preparing
        errorMessage = nil
        
        do {
            // 1. 获取梦境数据
            let dreams = try await fetchDreams(for: config.dateRange, includeIds: config.includeDreams)
            
            if dreams.isEmpty {
                throw EBookExportError.noDreamsFound
            }
            
            // 2. 组织章节
            let chapters = try organizeChapters(from: dreams, config: config)
            
            // 3. 生成 PDF 内容
            exportStatus = .generating(0, chapters.count)
            let pdfData = try await generatePDF(chapters: chapters, config: config)
            
            // 4. 保存文件
            exportStatus = .completing
            let fileURL = try saveEBook(data: pdfData, config: config)
            
            exportStatus = .success(fileURL)
            generatedFileURL = fileURL
            
        } catch {
            exportStatus = .failure(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    /// 获取梦境数据
    func fetchDreams(for dateRange: EBookDateRange, includeIds: [UUID]) async throws -> [Dream] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Dream>()
        
        var allDreams: [Dream] = []
        do {
            allDreams = try context.fetch(descriptor)
        } catch {
            throw EBookExportError.fetchFailed(error.localizedDescription)
        }
        
        // 按 ID 筛选
        if !includeIds.isEmpty {
            return allDreams.filter { includeIds.contains($0.id) }
        }
        
        // 按日期范围筛选
        let now = Date()
        let calendar = Calendar.current
        
        switch dateRange {
        case .all:
            return allDreams.sorted { $0.date > $1.date }
            
        case .last7Days:
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else {
                return allDreams.sorted { $0.date > $1.date }
            }
            return allDreams.filter { $0.date >= startDate }.sorted { $0.date > $1.date }
            
        case .last30Days:
            guard let startDate = calendar.date(byAdding: .day, value: -30, to: now) else {
                return allDreams.sorted { $0.date > $1.date }
            }
            return allDreams.filter { $0.date >= startDate }.sorted { $0.date > $1.date }
            
        case .last90Days:
            guard let startDate = calendar.date(byAdding: .day, value: -90, to: now) else {
                return allDreams.sorted { $0.date > $1.date }
            }
            return allDreams.filter { $0.date >= startDate }.sorted { $0.date > $1.date }
            
        case .thisYear:
            let year = calendar.component(.year, from: now)
            guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
                return allDreams.sorted { $0.date > $1.date }
            }
            return allDreams.filter { $0.date >= startDate }.sorted { $0.date > $1.date }
            
        case .lastYear:
            let year = calendar.component(.year, from: now) - 1
            guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                  let endDate = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else {
                return allDreams.sorted { $0.date > $1.date }
            }
            return allDreams.filter { $0.date >= startDate && $0.date <= endDate }.sorted { $0.date > $1.date }
            
        case .custom:
            return allDreams.sorted { $0.date > $1.date }
        }
    }
    
    /// 组织章节
    func organizeChapters(from dreams: [Dream], config: EBookExportConfig) throws -> [EBookChapter] {
        if !config.chapters.isEmpty {
            return config.chapters
        }
        
        // 根据日期范围自动分章
        let calendar = Calendar.current
        
        switch config.dateRange {
        case .all, .thisYear, .lastYear, .custom:
            // 按月份分章
            return organizeByMonth(dreams: dreams, calendar: calendar)
            
        case .last90Days:
            // 按周分章
            return organizeByWeek(dreams: dreams, calendar: calendar)
            
        case .last30Days:
            // 按周分章
            return organizeByWeek(dreams: dreams, calendar: calendar)
            
        case .last7Days:
            // 单章
            return [EBookChapter(title: "最近 7 天", type: .manual, dreamIds: dreams.map { $0.id })]
        }
    }
    
    /// 按月份组织章节
    private func organizeByMonth(dreams: [Dream], calendar: Calendar) -> [EBookChapter] {
        var chaptersByMonth: [String: [Dream]] = [:]
        
        for dream in dreams {
            let monthKey = calendar.string(from: DateComponents(year: calendar.component(.year, from: dream.date),
                                                                 month: calendar.component(.month, from: dream.date))) ?? "Unknown"
            if chaptersByMonth[monthKey] == nil {
                chaptersByMonth[monthKey] = []
            }
            chaptersByMonth[monthKey]?.append(dream)
        }
        
        return chaptersByMonth.sorted { $0.key < $1.key }.enumerated().map { (index, element) in
            EBookChapter(
                title: element.key,
                type: .byMonth,
                dreamIds: element.value.map { $0.id },
                sortOrder: index
            )
        }
    }
    
    /// 按周组织章节
    private func organizeByWeek(dreams: [Dream], calendar: Calendar) -> [EBookChapter] {
        var chaptersByWeek: [String: [Dream]] = [:]
        
        for dream in dreams {
            let weekOfYear = calendar.component(.weekOfYear, from: dream.date)
            let year = calendar.component(.year, from: dream.date)
            let weekKey = "第\(weekOfYear)周"
            
            if chaptersByWeek[weekKey] == nil {
                chaptersByWeek[weekKey] = []
            }
            chaptersByWeek[weekKey]?.append(dream)
        }
        
        return chaptersByWeek.sorted { $0.key < $1.key }.enumerated().map { (index, element) in
            EBookChapter(
                title: element.key,
                type: .byMonth, // 复用 byMonth 类型
                dreamIds: element.value.map { $0.id },
                sortOrder: index
            )
        }
    }
    
    /// 生成 PDF
    func generatePDF(chapters: [EBookChapter], config: EBookExportConfig) async throws -> Data {
        // 简化版 PDF 生成 - 实际项目中应使用更完整的 PDF 渲染
        let pdfRenderer = DreamPDFExportRenderer()
        
        var allDreams: [Dream] = []
        for chapter in chapters.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            for dreamId in chapter.dreamIds {
                if let dream = try? await fetchDream(by: dreamId) {
                    allDreams.append(dream)
                }
            }
        }
        
        // 使用现有的 PDF 渲染器
        let pdfData = try pdfRenderer.renderDreamsToPDF(
            dreams: allDreams,
            title: config.title,
            subtitle: config.subtitle,
            includeDate: config.dreamDetails.includeDate,
            includeEmotion: config.dreamDetails.includeEmotion,
            includeTags: config.dreamDetails.includeTags,
            includeAIAnalysis: config.dreamDetails.includeAIAnalysis
        )
        
        return pdfData
    }
    
    /// 获取单个梦境
    func fetchDream(by id: UUID) async throws -> Dream? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { $0.id == id }
        )
        
        do {
            let dreams = try context.fetch(descriptor)
            return dreams.first
        } catch {
            throw EBookExportError.fetchFailed(error.localizedDescription)
        }
    }
    
    /// 保存电子书文件
    func saveEBook(data: Data, config: EBookExportConfig) throws -> URL {
        let fileManager = FileManager.default
        
        // 获取文档目录
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw EBookExportError.saveFailed("无法访问文档目录")
        }
        
        // 生成文件名
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "T", with: "_")
        let fileName = "\(config.title)_\(timestamp).\(config.exportFormat.fileExtension)"
        let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "-")
        
        let fileURL = documentsDirectory.appendingPathComponent(sanitizedFileName)
        
        // 如果文件已存在，删除旧文件
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        
        // 保存文件
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    /// 获取导出统计信息
    func getExportStats(config: EBookExportConfig, dreams: [Dream]) -> EBookExportStats {
        let totalWords = dreams.reduce(0) { $0 + ($1.content.count / 4) } // 估算中文字数
        let totalPages = max(1, totalWords / 300) // 估算页数
        
        return EBookExportStats(
            totalDreams: dreams.count,
            totalWords: totalWords,
            totalPages: totalPages,
            chapterCount: config.chapters.isEmpty ? 1 : config.chapters.count,
            dateRangeStart: dreams.min(by: { $0.date < $1.date })?.date ?? Date(),
            dateRangeEnd: dreams.max(by: { $0.date < $1.date })?.date ?? Date(),
            generatedAt: Date(),
            fileSize: 0 // 将在生成后更新
        )
    }
    
    /// 取消导出
    func cancelExport() {
        exportStatus = .idle
        currentProgress = 0
        totalProgress = 0
        errorMessage = nil
    }
    
    /// 重置状态
    func reset() {
        exportStatus = .idle
        currentProgress = 0
        totalProgress = 0
        errorMessage = nil
        generatedFileURL = nil
    }
}

// MARK: - 导出错误

enum EBookExportError: LocalizedError {
    case noDreamsFound
    case fetchFailed(String)
    case generateFailed(String)
    case saveFailed(String)
    case invalidConfig(String)
    
    var errorDescription: String? {
        switch self {
        case .noDreamsFound:
            return "在选定的日期范围内没有找到梦境记录"
        case .fetchFailed(let message):
            return "获取梦境数据失败：\(message)"
        case .generateFailed(let message):
            return "生成电子书失败：\(message)"
        case .saveFailed(let message):
            return "保存文件失败：\(message)"
        case .invalidConfig(let message):
            return "配置无效：\(message)"
        }
    }
}

// MARK: - PDF 渲染器扩展

extension DreamPDFExportRenderer {
    /// 渲染梦境到 PDF (简化版本)
    func renderDreamsToPDF(
        dreams: [Dream],
        title: String,
        subtitle: String,
        includeDate: Bool,
        includeEmotion: Bool,
        includeTags: Bool,
        includeAIAnalysis: Bool
    ) throws -> Data {
        // 使用现有的 PDF 导出功能
        // 这里简化处理，实际应调用完整的 PDF 渲染逻辑
        let htmlContent = generateHTMLContent(
            dreams: dreams,
            title: title,
            subtitle: subtitle,
            includeDate: includeDate,
            includeEmotion: includeEmotion,
            includeTags: includeTags,
            includeAIAnalysis: includeAIAnalysis
        )
        
        // 简化：返回占位数据
        // 实际项目中应使用 PDFKit 或类似库生成真正的 PDF
        return Data(htmlContent.utf8)
    }
    
    private func generateHTMLContent(
        dreams: [Dream],
        title: String,
        subtitle: String,
        includeDate: Bool,
        includeEmotion: Bool,
        includeTags: Bool,
        includeAIAnalysis: Bool
    ) -> String {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>\(title)</title>
            <style>
                body { font-family: Georgia, serif; padding: 40px; }
                h1 { text-align: center; color: #333; }
                h2 { color: #666; border-bottom: 1px solid #ddd; padding-bottom: 10px; }
                .dream { margin: 30px 0; padding: 20px; background: #f9f9f9; border-radius: 8px; }
                .dream-date { color: #999; font-size: 12px; }
                .dream-content { margin: 15px 0; line-height: 1.6; }
                .dream-tags { color: #666; font-size: 12px; }
            </style>
        </head>
        <body>
            <h1>\(title)</h1>
            <p style="text-align: center; color: #666;">\(subtitle)</p>
            <hr>
        """
        
        for dream in dreams {
            html += """
            <div class="dream">
                <h2>梦境记录</h2>
            """
            
            if includeDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                html += "<p class=\"dream-date\">\(dateFormatter.string(from: dream.date))</p>"
            }
            
            html += "<div class=\"dream-content\">\(dream.content)</div>"
            
            if includeEmotion && !dream.emotion.isEmpty {
                html += "<p><strong>情绪:</strong> \(dream.emotion)</p>"
            }
            
            if includeTags && !dream.tags.isEmpty {
                let tags = dream.tags.map { $0.name }.joined(separator: ", ")
                html += "<p class=\"dream-tags\"><strong>标签:</strong> \(tags)</p>"
            }
            
            if includeAIAnalysis && !dream.aiAnalysisSummary.isEmpty {
                html += "<p><strong>AI 分析:</strong> \(dream.aiAnalysisSummary)</p>"
            }
            
            html += "</div>"
        }
        
        html += """
        </body>
        </html>
        """
        
        return html
    }
}
