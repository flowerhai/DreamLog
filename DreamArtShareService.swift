//
//  DreamArtShareService.swift
//  DreamLog
//
//  Phase 54 - AI 梦境艺术分享卡片服务
//  创建时间：2026-03-16
//

import Foundation
import SwiftData
import UIKit
import CoreGraphics

actor DreamArtShareService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let fileManager: FileManager
    private let exportsDirectory: URL
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.fileManager = FileManager.default
        self.exportsDirectory = {
            let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let exportsDir = docsDir.appendingPathComponent("ArtShares", isDirectory: true)
            try? fileManager.createDirectory(at: exportsDir, withIntermediateDirectories: true)
            return exportsDir
        }()
    }
    
    // MARK: - Template Management
    
    /// 获取所有模板
    func getAllTemplates() throws -> [ArtShareTemplate] {
        let descriptor = FetchDescriptor<ArtShareTemplate>()
        return try modelContext.fetch(descriptor).sorted { $0.name < $1.name }
    }
    
    /// 获取预设模板
    func getPresetTemplates() throws -> [ArtShareTemplate] {
        let descriptor = FetchDescriptor<ArtShareTemplate>(
            predicate: #Predicate<ArtShareTemplate> { $0.isPreset == true }
        )
        return try modelContext.fetch(descriptor).sorted { $0.name < $1.name }
    }
    
    /// 获取自定义模板
    func getCustomTemplates() throws -> [ArtShareTemplate] {
        let descriptor = FetchDescriptor<ArtShareTemplate>(
            predicate: #Predicate<ArtShareTemplate> { $0.isPreset == false }
        )
        return try modelContext.fetch(descriptor).sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// 获取收藏模板
    func getFavoriteTemplates() throws -> [ArtShareTemplate] {
        let descriptor = FetchDescriptor<ArtShareTemplate>(
            predicate: #Predicate<ArtShareTemplate> { $0.isFavorite == true }
        )
        return try modelContext.fetch(descriptor).sorted { $0.name < $1.name }
    }
    
    /// 按分类获取模板
    func getTemplates(by category: TemplateCategory) throws -> [ArtShareTemplate] {
        let descriptor = FetchDescriptor<ArtShareTemplate>(
            predicate: #Predicate<ArtShareTemplate> { $0.category == category }
        )
        return try modelContext.fetch(descriptor).sorted { $0.name < $1.name }
    }
    
    /// 创建模板
    func createTemplate(_ template: ArtShareTemplate) throws {
        modelContext.insert(template)
        try modelContext.save()
    }
    
    /// 更新模板
    func updateTemplate(_ template: ArtShareTemplate) throws {
        template.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 删除模板
    func deleteTemplate(_ template: ArtShareTemplate) throws {
        modelContext.delete(template)
        try modelContext.save()
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ template: ArtShareTemplate) throws {
        template.isFavorite.toggle()
        template.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 初始化预设模板
    func initializePresetTemplates() throws {
        let existing = try getPresetTemplates()
        guard existing.isEmpty else { return }
        
        for preset in ArtShareTemplate.presetTemplates {
            modelContext.insert(preset)
        }
        try modelContext.save()
    }
    
    // MARK: - Card Generation
    
    /// 生成分享卡片
    func generateCard(
        dreamId: UUID,
        dreamTitle: String,
        dreamContent: String,
        dreamDate: Date,
        tags: [String],
        emotions: [String],
        aiAnalysis: String?,
        aiImageUrl: String?,
        template: ArtShareTemplate
    ) async throws -> URL {
        
        let cardData = ArtShareCardData(
            dreamId: dreamId,
            dreamTitle: dreamTitle,
            dreamContent: dreamContent,
            dreamDate: dreamDate,
            tags: tags,
            emotions: emotions,
            aiAnalysis: aiAnalysis,
            aiImageUrl: aiImageUrl,
            template: template
        )
        
        // 创建卡片图片
        let image = try await renderCard(cardData: cardData)
        
        // 保存图片
        let filename = "DreamShare_\(UUID().uuidString.prefix(8)).png"
        let fileURL = exportsDirectory.appendingPathComponent(filename)
        
        guard let pngData = image.pngData() else {
            throw ArtShareError.imageGenerationFailed
        }
        
        try pngData.write(to: fileURL)
        
        // 记录分享历史
        let history = ArtShareHistory(
            dreamId: dreamId,
            dreamTitle: dreamTitle,
            templateId: template.id,
            templateName: template.name,
            cardType: template.type,
            platform: .save,
            imageUrl: fileURL.absoluteString,
            fileSize: Int64(pngData.count)
        )
        modelContext.insert(history)
        try modelContext.save()
        
        return fileURL
    }
    
    /// 批量生成卡片
    func generateCards(
        dreams: [(dreamId: UUID, title: String, content: String, date: Date, tags: [String], emotions: [String], aiAnalysis: String?, aiImageUrl: String?)],
        template: ArtShareTemplate
    ) async throws -> [URL] {
        
        var urls: [URL] = []
        
        for dream in dreams {
            let url = try await generateCard(
                dreamId: dream.dreamId,
                dreamTitle: dream.title,
                dreamContent: dream.content,
                dreamDate: dream.date,
                tags: dream.tags,
                emotions: dream.emotions,
                aiAnalysis: dream.aiAnalysis,
                aiImageUrl: dream.aiImageUrl,
                template: template
            )
            urls.append(url)
        }
        
        return urls
    }
    
    // MARK: - Rendering
    
    /// 渲染卡片图片
    private func renderCard(cardData: ArtShareCardData) async throws -> UIImage {
        let size = cardData.template.type.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 绘制背景
            drawBackground(context: ctx, template: cardData.template, size: size)
            
            // 绘制覆盖图案
            drawOverlayPattern(context: ctx, template: cardData.template, size: size)
            
            // 绘制 AI 图片
            if let aiImageUrl = cardData.aiImageUrl {
                drawAIImage(context: ctx, cardData: cardData, size: size, imageUrl: aiImageUrl)
            }
            
            // 绘制文字内容
            drawTextContent(context: ctx, cardData: cardData, size: size)
            
            // 绘制 Logo
            if cardData.template.showLogo {
                drawLogo(context: ctx, template: cardData.template, size: size)
            }
        }
    }
    
    /// 绘制背景
    private func drawBackground(context: CGContext, template: ArtShareTemplate, size: CGSize) {
        // 检查是否有渐变
        if let startHex = template.gradientStart, let endHex = template.gradientEnd {
            guard let startColor = hexToColor(startHex),
                  let endColor = hexToColor(endHex) else {
                //  fallback to solid color
                if let bgColor = hexToColor(template.backgroundColor) {
                    context.setFillColor(bgColor)
                    context.fill(CGRect(origin: .zero, size: size))
                }
                return
            }
            
            // 创建渐变
            let colors = [startColor.cgColor, endColor.cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
                let startPoint = CGPoint(x: size.width / 2, y: 0)
                let endPoint = CGPoint(x: size.width / 2, y: size.height)
                context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
            }
        } else if let bgColor = hexToColor(template.backgroundColor) {
            context.setFillColor(bgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    /// 绘制覆盖图案
    private func drawOverlayPattern(context: CGContext, template: ArtShareTemplate, size: CGSize) {
        switch template.overlayPattern {
        case .stars:
            drawStarsPattern(context: context, size: size)
        case .dots:
            drawDotsPattern(context: context, size: size)
        case .lines:
            drawLinesPattern(context: context, size: size)
        case .gradient:
            drawGradientOverlay(context: context, template: template, size: size)
        case .noise:
            drawNoisePattern(context: context, size: size)
        case .none:
            break
        }
    }
    
    /// 绘制星星图案
    private func drawStarsPattern(context: CGContext, size: CGSize) {
        for _ in 0..<50 {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let radius = CGFloat.random(in: 1..<3)
            
            context.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.addEllipse(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
            context.fillPath()
        }
    }
    
    /// 绘制圆点图案
    private func drawDotsPattern(context: CGContext, size: CGSize) {
        let spacing: CGFloat = 30
        for x in stride(from: 0, to: size.width, by: spacing) {
            for y in stride(from: 0, to: size.height, by: spacing) {
                context.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
                context.addEllipse(in: CGRect(x: x, y: y, width: 4, height: 4))
                context.fillPath()
            }
        }
    }
    
    /// 绘制线条图案
    private func drawLinesPattern(context: CGContext, size: CGSize) {
        let spacing: CGFloat = 50
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(1)
        
        for x in stride(from: 0, to: size.width, by: spacing) {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.strokePath()
    }
    
    /// 绘制渐变覆盖
    private func drawGradientOverlay(context: CGContext, template: ArtShareTemplate, size: CGSize) {
        guard let accentColor = hexToColor(template.accentColor) else { return }
        
        let colors = [
            accentColor.withAlphaComponent(0.0).cgColor,
            accentColor.withAlphaComponent(0.3).cgColor
        ] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) else { return }
        
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: size.width, y: size.height)
        
        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    }
    
    /// 绘制噪点图案
    private func drawNoisePattern(context: CGContext, size: CGSize) {
        for _ in 0..<1000 {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let alpha = CGFloat.random(in: 0.02..<0.1)
            
            context.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
            context.fill(CGRect(x: x, y: y, width: 2, height: 2))
        }
    }
    
    /// 绘制 AI 图片
    private func drawAIImage(context: CGContext, cardData: ArtShareCardData, size: CGSize, imageUrl: String) {
        // 这里应该从 URL 加载图片
        // 由于是异步操作，在实际实现中需要预先加载
        // 这里做简化处理
    }
    
    /// 绘制文字内容
    private func drawTextContent(context: CGContext, cardData: ArtShareCardData, size: CGSize) {
        let template = cardData.template
        
        guard let textColor = hexToColor(template.textColor) else { return }
        guard let accentColor = hexToColor(template.accentColor) else { return }
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: template.titleFont, size: template.titleSize) ?? .systemFont(ofSize: template.titleSize),
            .foregroundColor: textColor
        ]
        
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: template.contentFont, size: template.contentSize) ?? .systemFont(ofSize: template.contentSize),
            .foregroundColor: textColor.withAlphaComponent(0.8)
        ]
        
        let padding: CGFloat = 40
        var yOffset: CGFloat = padding
        
        // 根据图片位置调整文字起始位置
        switch template.imagePosition {
        case .top:
            yOffset = size.height * 0.55
        case .bottom:
            yOffset = padding
        case .background, .center:
            // 添加半透明背景以增强可读性
            let textBgRect = CGRect(x: padding, y: size.height - 250, width: size.width - padding * 2, height: 200)
            context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            context.fill(textBgRect)
            yOffset = size.height - 230
        default:
            yOffset = padding
        }
        
        // 绘制标题
        let titleRect = CGRect(x: padding, y: yOffset, width: size.width - padding * 2, height: 60)
        cardData.dreamTitle.draw(in: titleRect, withAttributes: textAttributes)
        
        yOffset += 70
        
        // 绘制日期
        if template.showDate {
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: textColor.withAlphaComponent(0.6)
            ]
            let dateRect = CGRect(x: padding, y: yOffset, width: size.width - padding * 2, height: 20)
            cardData.formattedDate.draw(in: dateRect, withAttributes: dateAttributes)
            yOffset += 30
        }
        
        // 绘制情绪
        if template.showEmotions && !cardData.emotions.isEmpty {
            let emotionRect = CGRect(x: padding, y: yOffset, width: size.width - padding * 2, height: 25)
            let emotionString = cardData.emotionIcons + " " + cardData.emotions.joined(separator: " ")
            emotionString.draw(in: emotionRect, withAttributes: contentAttributes)
            yOffset += 35
        }
        
        // 绘制标签
        if template.showTags && !cardData.tags.isEmpty {
            let maxTags = min(cardData.tags.count, 5)
            let tags = cardData.tags.prefix(maxTags).joined(separator: "  ")
            let tagAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: accentColor
            ]
            let tagRect = CGRect(x: padding, y: yOffset, width: size.width - padding * 2, height: 20)
            "#\(tags)".draw(in: tagRect, withAttributes: tagAttributes)
        }
    }
    
    /// 绘制 Logo
    private func drawLogo(context: CGContext, template: ArtShareTemplate, size: CGSize) {
        let logoText = "DreamLog 🌙"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5)
        ]
        
        let textRect = CGRect(x: size.width - 120, y: size.height - 30, width: 100, height: 20)
        logoText.draw(in: textRect, withAttributes: attributes)
    }
    
    // MARK: - Share History
    
    /// 获取分享历史
    func getShareHistory(limit: Int = 50) throws -> [ArtShareHistory] {
        let descriptor = FetchDescriptor<ArtShareHistory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).prefix(limit).map { $0 }
    }
    
    /// 删除分享历史
    func deleteShareHistory(_ history: ArtShareHistory) throws {
        // 删除图片文件
        let url = URL(fileURLWithPath: history.imageUrl)
        try? fileManager.removeItem(at: url)
        
        modelContext.delete(history)
        try modelContext.save()
    }
    
    /// 清除所有分享历史
    func clearAllShareHistory() throws {
        let all = try getShareHistory(limit: 1000)
        for item in all {
            deleteShareHistory(item)
        }
    }
    
    /// 获取分享统计
    func getShareStatistics() throws -> ShareStatistics {
        let all = try getShareHistory(limit: 1000)
        
        let totalShares = all.count
        let totalSize = all.reduce(0) { $0 + $1.fileSize }
        
        var platformCounts: [SharePlatform: Int] = [:]
        for item in all {
            platformCounts[item.platform, default: 0] += 1
        }
        
        return ShareStatistics(
            totalShares: totalShares,
            totalSizeBytes: totalSize,
            platformCounts: platformCounts,
            lastShareDate: all.first?.createdAt
        )
    }
    
    // MARK: - Utilities
    
    /// Hex 颜色转 UIColor
    private func hexToColor(_ hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Errors

enum ArtShareError: LocalizedError {
    case imageGenerationFailed
    case imageLoadFailed
    case fileSaveFailed
    case templateNotFound
    
    var errorDescription: String? {
        switch self {
        case .imageGenerationFailed: return "卡片图片生成失败"
        case .imageLoadFailed: return "图片加载失败"
        case .fileSaveFailed: return "文件保存失败"
        case .templateNotFound: return "模板未找到"
        }
    }
}

// MARK: - Statistics

struct ShareStatistics {
    let totalShares: Int
    let totalSizeBytes: Int64
    let platformCounts: [SharePlatform: Int]
    let lastShareDate: Date?
    
    var totalSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSizeBytes)
    }
}
