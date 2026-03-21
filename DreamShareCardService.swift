//
//  DreamShareCardService.swift
//  DreamLog
//
//  Phase 54 - Dream Share Cards (梦境分享卡片)
//  核心服务 - 卡片生成、管理、分享
//

import Foundation
import SwiftUI
import UIKit

// MARK: - 分享卡片服务

@MainActor
final class DreamShareCardService {
    static let shared = DreamShareCardService()
    
    private let modelContext: ModelContext
    private var shareHistory: [ShareRecord] = []
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? (SharedModelContainer.shared.container.viewContext)
    }
    
    // MARK: - 卡片创建与管理
    
    /// 创建分享卡片
    func createShareCard(
        dreamId: UUID,
        template: ShareCardTemplate = .presets[0],
        customConfig: ShareCardConfig? = nil
    ) async throws -> DreamShareCard {
        let card = DreamShareCard(
            dreamId: dreamId,
            templateId: template.id,
            theme: template.theme,
            showTags: true,
            showEmotions: true,
            showDate: true,
            showWatermark: true
        )
        
        // 应用自定义配置
        if let config = customConfig {
            card.customTitle = config.title
            card.customContent = config.content
            card.showTags = config.showTags
            card.showEmotions = config.showEmotions
            card.showDate = config.showDate
            card.showWatermark = config.showWatermark
        }
        
        modelContext.insert(card)
        try modelContext.save()
        
        return card
    }
    
    /// 获取所有分享卡片
    func getAllShareCards() -> [DreamShareCard] {
        let descriptor = FetchDescriptor<DreamShareCard>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    /// 获取收藏的卡片
    func getFavoriteCards() -> [DreamShareCard] {
        getAllShareCards().filter { $0.isFavorite }
    }
    
    /// 获取指定梦境的卡片
    func getCardsForDream(dreamId: UUID) -> [DreamShareCard] {
        getAllShareCards().filter { $0.dreamId == dreamId }
    }
    
    /// 更新卡片
    func updateCard(_ card: DreamShareCard) throws {
        try modelContext.save()
    }
    
    /// 删除卡片
    func deleteCard(_ card: DreamShareCard) throws {
        modelContext.delete(card)
        try modelContext.save()
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ card: DreamShareCard) throws {
        card.isFavorite.toggle()
        try modelContext.save()
    }
    
    // MARK: - 卡片生成
    
    /// 生成分享卡片图片
    func generateCardImage(
        card: DreamShareCard,
        dream: Dream,
        size: CGSize = CGSize(width: 1080, height: 1350)
    ) async throws -> UIImage {
        // 使用 ViewImageRenderer 渲染卡片
        let renderer = ViewImageRenderer()
        
        // 创建卡片视图
        let cardView = ShareCardPreviewView(
            card: card,
            dream: dream,
            size: size
        )
        
        // 渲染为图片
        let image = try await renderer.render(view: cardView, size: size)
        
        // 保存生成的图片
        card.generatedImageData = image.jpegData(compressionQuality: 0.9)
        try modelContext.save()
        
        return image
    }
    
    /// 批量生成卡片
    func generateCards(
        dreams: [Dream],
        template: ShareCardTemplate
    ) async throws -> [DreamShareCard] {
        var cards: [DreamShareCard] = []
        
        for dream in dreams {
            let card = try await createShareCard(
                dreamId: dream.id,
                template: template
            )
            cards.append(card)
        }
        
        return cards
    }
    
    // MARK: - 分享功能
    
    /// 分享卡片到平台
    func shareCard(
        _ card: DreamShareCard,
        dream: Dream,
        to platform: SharePlatformConfig.ShareCardPlatform,
        completion: @escaping (Bool) -> Void
    ) async {
        do {
            // 生成卡片图片
            let image = try await generateCardImage(card: card, dream: dream)
            
            // 准备分享内容
            var shareText = dream.title
            if !dream.tags.isEmpty {
                shareText += "\n\n" + dream.tags.map { "#\($0)" }.joined(separator: " ")
            }
            
            // 创建分享项
            let items: [Any] = [image, shareText]
            
            // 使用系统分享
            DispatchQueue.main.async {
                let shareVC = UIActivityViewController(
                    activityItems: items,
                    applicationActivities: nil
                )
                
                // 获取当前窗口
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    completion(false)
                    return
                }
                
                // 呈现分享界面
                rootVC.present(shareVC, animated: true)
                
                // 设置完成回调
                shareVC.completionWithItemsHandler = { activity, completed, _, _ in
                    if completed {
                        // 更新分享计数
                        card.shareCount += 1
                        self.recordShare(card: card, platform: platform.rawValue)
                        try? self.modelContext.save()
                    }
                    completion(completed)
                }
            }
        } catch {
            print("分享卡片失败：\(error)")
            completion(false)
        }
    }
    
    /// 记录分享历史
    private func recordShare(card: DreamShareCard, platform: String) {
        let record = ShareRecord(
            cardId: card.id,
            platform: platform,
            timestamp: Date()
        )
        shareHistory.append(record)
        
        // 保留最近 100 条记录
        if shareHistory.count > 100 {
            shareHistory.removeFirst(shareHistory.count - 100)
        }
    }
    
    // MARK: - 统计数据
    
    /// 获取分享统计
    func getStats() -> ShareCardStats {
        let cards = getAllShareCards()
        
        // 按主题统计
        var cardsByTheme: [String: Int] = [:]
        for card in cards {
            let theme = card.theme.rawValue
            cardsByTheme[theme, default: 0] += 1
        }
        
        // 按平台统计
        var cardsByPlatform: [String: Int] = [:]
        for record in shareHistory {
            cardsByPlatform[record.platform, default: 0] += 1
        }
        
        // 找出最常用的主题
        let mostUsedTheme = cardsByTheme.max(by: { $0.value < $1.value })?.key.flatMap {
            ShareCardTheme(rawValue: $0)
        }
        
        // 最近的分享记录
        let recentShares = shareHistory.suffix(10).map { record in
            ShareCardStats.ShareRecord(
                cardId: record.cardId,
                platform: record.platform,
                timestamp: record.timestamp
            )
        }
        
        return ShareCardStats(
            totalCards: cards.count,
            totalShares: shareHistory.reduce(0) { $0 + 1 },
            favoriteCards: cards.filter { $0.isFavorite }.count,
            mostUsedTheme: mostUsedTheme,
            cardsByTheme: cardsByTheme,
            cardsByPlatform: cardsByPlatform,
            recentShares: Array(recentShares)
        )
    }
    
    // MARK: - 模板管理
    
    /// 获取所有模板
    func getAllTemplates() -> [ShareCardTemplate] {
        ShareCardTemplate.presets
    }
    
    /// 获取模板
    func getTemplate(id: String) -> ShareCardTemplate? {
        ShareCardTemplate.presets.first { $0.id == id }
    }
}

// MARK: - 分享卡片配置

struct ShareCardConfig: Codable {
    var title: String?
    var content: String?
    var showTags: Bool
    var showEmotions: Bool
    var showDate: Bool
    var showWatermark: Bool
    var customFont: String?
    var customColors: [String]?
    
    init(
        title: String? = nil,
        content: String? = nil,
        showTags: Bool = true,
        showEmotions: Bool = true,
        showDate: Bool = true,
        showWatermark: Bool = true,
        customFont: String? = nil,
        customColors: [String]? = nil
    ) {
        self.title = title
        self.content = content
        self.showTags = showTags
        self.showEmotions = showEmotions
        self.showDate = showDate
        self.showWatermark = showWatermark
        self.customFont = customFont
        self.customColors = customColors
    }
}

// MARK: - 分享记录

struct ShareRecord: Codable {
    var cardId: UUID
    var platform: String
    var timestamp: Date
}

// MARK: - 卡片预览视图

struct ShareCardPreviewView: View {
    let card: DreamShareCard
    let dream: Dream
    let size: CGSize
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: card.theme.gradientColors.map { Color(hex: $0.description) }),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 内容
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                Text(dream.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(card.theme.textColor)
                    .multilineTextAlignment(.leading)
                
                // 内容
                Text(dream.content.prefix(300))
                    .font(.system(size: 18))
                    .foregroundColor(card.theme.textColor.opacity(0.9))
                    .lineLimit(6)
                
                Spacer()
                
                // 标签和情绪
                if card.showTags || card.showEmotions {
                    HStack(spacing: 12) {
                        if card.showTags && !dream.tags.isEmpty {
                            LabelStackView(tags: Array(dream.tags.prefix(3)))
                        }
                        if card.showEmotions && !dream.emotions.isEmpty {
                            EmotionBadgeView(emotions: Array(dream.emotions.prefix(2)))
                        }
                    }
                }
                
                // 日期和水印
                if card.showDate || card.showWatermark {
                    HStack {
                        if card.showDate {
                            Text(dream.date.formatted(date: .long, time: .omitted))
                                .font(.caption)
                                .foregroundColor(card.theme.textColor.opacity(0.7))
                        }
                        Spacer()
                        if card.showWatermark {
                            Text("DreamLog 🌙")
                                .font(.caption)
                                .foregroundColor(card.theme.textColor.opacity(0.7))
                        }
                    }
                }
            }
            .padding(30)
            
            // 装饰元素
            DecorationsView(theme: card.theme)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

// MARK: - 辅助视图

struct LabelStackView: View {
    let tags: [String]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(16)
            }
        }
    }
}

struct EmotionBadgeView: View {
    let emotions: [Emotion]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(emotions, id: \.self) { emotion in
                Text(emotion.icon)
                    .font(.title2)
            }
        }
    }
}

struct DecorationsView: View {
    let theme: ShareCardTheme
    
    var body: some View {
        Group {
            ForEach(0..<5, id: \.self) { index in
                Text(theme.decorations.randomElement() ?? "✨")
                    .font(.system(size: CGFloat.random(in: 20...40)))
                    .opacity(Double.random(in: 0.1...0.3))
                    .position(
                        x: CGFloat.random(in: 50...1000),
                        y: CGFloat.random(in: 50...1300)
                    )
            }
        }
    }
}
