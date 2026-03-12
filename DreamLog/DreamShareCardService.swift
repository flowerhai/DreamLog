//
//  DreamShareCardService.swift
//  DreamLog
//
//  Phase 25 - Dream Sharing Cards & Social Templates
//  梦境分享卡片核心服务
//

import Foundation
import SwiftUI
import UIKit
import CoreGraphics

actor DreamShareCardService {
    
    // MARK: - 单例
    
    static let shared = DreamShareCardService()
    
    // MARK: - 属性
    
    private let fileManager = FileManager.default
    private var generatedCards: [GeneratedShareCard] = []
    private var shareHistory: [ShareHistoryEntry] = []
    
    private var cardsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cardsDir = documents.appendingPathComponent("ShareCards", isDirectory: true)
        try? fileManager.createDirectory(at: cardsDir, withIntermediateDirectories: true)
        return cardsDir
    }
    
    private var historyFile: URL {
        cardsDirectory.appendingPathComponent("share_history.json")
    }
    
    // MARK: - 初始化
    
    init() {
        loadShareHistory()
    }
    
    // MARK: - 生成卡片
    
    /// 生成分享卡片
    func generateCard(
        for dream: Dream,
        config: ShareCardConfig,
        template: CardTemplate? = nil
    ) async throws -> GeneratedShareCard {
        
        let selectedTemplate = template ?? CardTemplate.template(id: "\(config.cardType.rawValue)_\(config.platform.rawValue)") 
            ?? CardTemplate.templates.first { $0.type == config.cardType }
            ?? CardTemplate.templates[0]
        
        // 创建卡片视图
        let cardView = ShareCardView(
            dream: dream,
            config: config,
            template: selectedTemplate
        )
        
        // 渲染为图片
        let imageSize = config.platform.recommendedSize
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        let image = renderer.image { context in
            let hostingController = UIHostingController(rootView: cardView)
            hostingController.view.frame = CGRect(origin: .zero, size: imageSize)
            hostingController.view.render(in: context.cgContext)
        }
        
        // 保存图片
        let fileName = "dream_\(dream.id.uuidString)_\(Date().timeIntervalSince1970).png"
        let imageUrl = cardsDirectory.appendingPathComponent(fileName)
        
        guard let pngData = image.pngData() else {
            throw ShareCardError.imageRenderingFailed
        }
        
        try pngData.write(to: imageUrl)
        
        // 创建卡片记录
        let card = GeneratedShareCard(
            dreamId: dream.id,
            config: config,
            imageUrl: imageUrl,
            shareCount: 0,
            platform: config.platform
        )
        
        generatedCards.append(card)
        
        // 记录分享历史
        let historyEntry = ShareHistoryEntry(
            cardId: card.id,
            dreamId: dream.id,
            platform: config.platform,
            cardType: config.cardType,
            createdAt: Date()
        )
        shareHistory.append(historyEntry)
        saveShareHistory()
        
        return card
    }
    
    // MARK: - 批量生成
    
    /// 批量生成多个平台的卡片
    func generateCardsForMultiplePlatforms(
        for dream: Dream,
        platforms: [SocialPlatform],
        cardType: ShareCardType = .dreamy
    ) async throws -> [SocialPlatform: GeneratedShareCard] {
        
        var cards: [SocialPlatform: GeneratedShareCard] = [:]
        
        for platform in platforms {
            let config = ShareCardConfig(
                cardType: cardType,
                platform: platform
            )
            
            do {
                let card = try await generateCard(for: dream, config: config)
                cards[platform] = card
            } catch {
                print("Failed to generate card for \(platform): \(error)")
            }
        }
        
        return cards
    }
    
    // MARK: - 分享卡片
    
    /// 分享卡片到平台
    func shareCard(_ card: GeneratedShareCard, with text: String? = nil) async throws {
        // 更新分享计数
        if let index = generatedCards.firstIndex(where: { $0.id == card.id }) {
            generatedCards[index].shareCount += 1
        }
        
        // 记录分享
        let shareEntry = ShareHistoryEntry(
            cardId: card.id,
            dreamId: card.dreamId,
            platform: card.platform ?? .wechat,
            cardType: card.config.cardType,
            createdAt: Date(),
            shareText: text
        )
        shareHistory.append(shareEntry)
        saveShareHistory()
    }
    
    // MARK: - 获取卡片
    
    /// 获取所有生成的卡片
    func getAllCards() -> [GeneratedShareCard] {
        return generatedCards.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 获取指定梦境的卡片
    func getCards(for dreamId: UUID) -> [GeneratedShareCard] {
        return generatedCards.filter { $0.dreamId == dreamId }
    }
    
    /// 获取最近的卡片
    func getRecentCards(limit: Int = 20) -> [GeneratedShareCard] {
        return Array(getAllCards().prefix(limit))
    }
    
    // MARK: - 删除卡片
    
    /// 删除卡片
    func deleteCard(_ card: GeneratedShareCard) throws {
        // 删除文件
        try? fileManager.removeItem(at: card.imageUrl)
        
        // 从数组中移除
        generatedCards.removeAll { $0.id == card.id }
    }
    
    /// 清理所有卡片
    func clearAllCards() throws {
        try? fileManager.removeItem(at: cardsDirectory)
        try? fileManager.createDirectory(at: cardsDirectory, withIntermediateDirectories: true)
        generatedCards.removeAll()
        shareHistory.removeAll()
        saveShareHistory()
    }
    
    // MARK: - 统计
    
    /// 获取分享统计
    func getStatistics() -> ShareStatistics {
        let totalShares = shareHistory.count
        
        // 按平台统计
        var byPlatform: [SocialPlatform: Int] = [:]
        for entry in shareHistory {
            byPlatform[entry.platform, default: 0] += 1
        }
        
        // 按卡片类型统计
        var byCardType: [ShareCardType: Int] = [:]
        for entry in shareHistory {
            byCardType[entry.cardType, default: 0] += 1
        }
        
        // 计算平均每周分享
        let daysSinceFirstShare = shareHistory.min(by: { $0.createdAt < $1.createdAt })
            .map { Date().days(since: $0.createdAt) } ?? 1
        let weeks = max(Double(daysSinceFirstShare) / 7.0, 1)
        let avgPerWeek = Double(totalShares) / weeks
        
        // 最常使用的模板
        let templateCounts = shareHistory.reduce(into: [String: Int]()) {
            $0[$1.cardType.rawValue, default: 0] += 1
        }
        let favoriteTemplate = templateCounts.max(by: { $0.value < $1.value })?.key
        
        return ShareStatistics(
            totalShares: totalShares,
            sharesByPlatform: byPlatform,
            sharesByCardType: byCardType,
            averageSharesPerWeek: avgPerWeek,
            favoriteTemplate: favoriteTemplate
        )
    }
    
    // MARK: - 导出功能
    
    /// 导出卡片到相册
    func exportCardToPhotoLibrary(_ card: GeneratedShareCard) async throws {
        guard let image = UIImage(contentsOfFile: card.imageUrl.path) else {
            throw ShareCardError.imageLoadingFailed
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    /// 导出卡片为文件
    func exportCardToFile(_ card: GeneratedShareCard) -> URL? {
        let exportDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ExportedCards")
        try? fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        let exportUrl = exportDir.appendingPathComponent("dream_share_\(card.id.uuidString).png")
        
        do {
            try fileManager.copyItem(at: card.imageUrl, to: exportUrl)
            return exportUrl
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
    
    // MARK: - 私有方法
    
    private func loadShareHistory() {
        guard fileManager.fileExists(atPath: historyFile.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: historyFile)
            shareHistory = try JSONDecoder().decode([ShareHistoryEntry].self, from: data)
        } catch {
            print("Failed to load share history: \(error)")
        }
    }
    
    private func saveShareHistory() {
        do {
            let data = try JSONEncoder().encode(shareHistory)
            try data.write(to: historyFile)
        } catch {
            print("Failed to save share history: \(error)")
        }
    }
}

// MARK: - 分享历史记录

struct ShareHistoryEntry: Codable, Identifiable {
    let id: UUID
    let cardId: UUID
    let dreamId: UUID
    let platform: SocialPlatform
    let cardType: ShareCardType
    let createdAt: Date
    var shareText: String?
    
    init(
        id: UUID = UUID(),
        cardId: UUID,
        dreamId: UUID,
        platform: SocialPlatform,
        cardType: ShareCardType,
        createdAt: Date = Date(),
        shareText: String? = nil
    ) {
        self.id = id
        self.cardId = cardId
        self.dreamId = dreamId
        self.platform = platform
        self.cardType = cardType
        self.createdAt = createdAt
        self.shareText = shareText
    }
}

// MARK: - 错误类型

enum ShareCardError: LocalizedError {
    case imageRenderingFailed
    case imageLoadingFailed
    case fileSaveFailed
    case invalidConfig
    case platformNotSupported
    
    var errorDescription: String? {
        switch self {
        case .imageRenderingFailed: return "图片渲染失败"
        case .imageLoadingFailed: return "图片加载失败"
        case .fileSaveFailed: return "文件保存失败"
        case .invalidConfig: return "配置无效"
        case .platformNotSupported: return "平台不支持"
        }
    }
}

// MARK: - Date 扩展

extension Date {
    func days(since earlierDate: Date) -> Int {
        Calendar.current.dateComponents([.day], from: earlierDate, to: self).day ?? 0
    }
}
