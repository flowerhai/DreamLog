//
//  DreamQRShareService.swift
//  DreamLog
//
//  Dream QR Code Sharing & Web Preview Core Service
//  Phase 88: Enhanced Social Sharing
//

import Foundation
import SwiftData
import CoreImage
import CoreImage.CIFilterBuiltins

@ModelActor
actor DreamQRShareService {
    private let context: ModelContext
    private let fileManager: FileManager
    private let qrDirectory: URL
    
    init(modelContainer: ModelContainer) throws {
        self.context = ModelContext(modelContainer)
        self.fileManager = FileManager.default
        
        // Create QR codes directory
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw QRError.documentsDirectoryNotFound
        }
        self.qrDirectory = documentsPath.appendingPathComponent("QRShares", isDirectory: true)
        
        try? fileManager.createDirectory(at: qrDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - QR Share Management
    
    /// 创建新的 QR 分享
    func createQRShare(
        for dreamId: UUID,
        theme: QRShareTheme = .starry,
        includeAIAnalysis: Bool = true,
        includeTags: Bool = true,
        includeEmotions: Bool = true,
        customMessage: String? = nil,
        expirationDays: Int = 7
    ) async throws -> DreamQRShare {
        // Generate unique 8-character share code
        let shareCode = generateShareCode()
        
        // Create web preview URL
        let webPreviewURL = "https://dreamlog.app/preview/\(shareCode)"
        
        let share = DreamQRShare(
            dreamId: dreamId,
            shareCode: shareCode,
            webPreviewURL: webPreviewURL,
            theme: theme,
            includeAIAnalysis: includeAIAnalysis,
            includeTags: includeTags,
            includeEmotions: includeEmotions,
            customMessage: customMessage,
            expirationDays: expirationDays
        )
        
        context.insert(share)
        try context.save()
        
        // Generate QR code image
        try await generateQRCodeImage(for: share)
        
        return share
    }
    
    /// 获取所有 QR 分享
    func getAllQRShares(
        filter: QRShareFilter = .all,
        sortBy: QRShareSort = .createdAt,
        ascending: Bool = false
    ) throws -> [DreamQRShare] {
        var descriptor = FetchDescriptor<DreamQRShare>()
        
        // Apply filter
        switch filter {
        case .all:
            break
        case .active:
            descriptor.predicate = #Predicate<DreamQRShare> { share in
                share.isActive && !share.isExpired
            }
        case .expired:
            descriptor.predicate = #Predicate<DreamQRShare> { share in
                share.isExpired
            }
        case .byDreamId(let dreamId):
            descriptor.predicate = #Predicate<DreamQRShare> { share in
                share.dreamId == dreamId && share.isActive
            }
        }
        
        // Apply sorting
        switch sortBy {
        case .createdAt:
            descriptor.sortBy = [SortDescriptor(\DreamQRShare.createdAt, order: ascending ? .forward : .reverse)]
        case .expiresAt:
            descriptor.sortBy = [SortDescriptor(\DreamQRShare.expiresAt, order: ascending ? .forward : .reverse)]
        case .scanCount:
            descriptor.sortBy = [SortDescriptor(\DreamQRShare.scanCount, order: ascending ? .forward : .reverse)]
        case .shareCode:
            descriptor.sortBy = [SortDescriptor(\DreamQRShare.shareCode, order: ascending ? .forward : .reverse)]
        }
        
        return try context.fetch(descriptor)
    }
    
    /// 获取单个 QR 分享
    func getQRShare(by id: UUID) throws -> DreamQRShare? {
        let descriptor = FetchDescriptor<DreamQRShare>(predicate: #Predicate<DreamQRShare> { $0.id == id })
        return try context.fetch(descriptor).first
    }
    
    /// 通过分享码获取 QR 分享
    func getQRShare(byCode code: String) throws -> DreamQRShare? {
        let descriptor = FetchDescriptor<DreamQRShare>(predicate: #Predicate<DreamQRShare> { $0.shareCode == code })
        return try context.fetch(descriptor).first
    }
    
    /// 更新 QR 分享
    func updateQRShare(_ share: DreamQRShare) throws {
        try context.save()
    }
    
    /// 删除 QR 分享
    func deleteQRShare(_ share: DreamQRShare) throws {
        // Delete QR code image
        let qrCodePath = qrDirectory.appendingPathComponent("\(share.shareCode).png")
        try? fileManager.removeItem(at: qrCodePath)
        
        // Delete scan records
        let scanRecords = try context.fetch(FetchDescriptor<DreamQRScanRecord>(
            predicate: #Predicate<DreamQRScanRecord> { $0.shareId == share.id }
        ))
        scanRecords.forEach { context.delete($0) }
        
        context.delete(share)
        try context.save()
    }
    
    /// 过期清理
    func cleanupExpiredShares() throws -> Int {
        let expiredShares = try context.fetch(FetchDescriptor<DreamQRShare>(
            predicate: #Predicate<DreamQRShare> { $0.isExpired && $0.isActive }
        ))
        
        var deletedCount = 0
        for share in expiredShares {
            share.isActive = false
            deletedCount += 1
        }
        
        try context.save()
        return deletedCount
    }
    
    // MARK: - QR Code Generation
    
    /// 生成 QR 码图片
    func generateQRCodeImage(for share: DreamQRShare, config: QRCodeConfig = .default) throws {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(share.webPreviewURL.utf8)
        filter.correctionLevel = config.errorCorrectionLevel.rawValue
        
        guard let outputImage = filter.outputImage else {
            throw QRError.generationFailed
        }
        
        // Scale the QR code
        let transform = CGAffineTransform(scaleX: config.size.width / outputImage.extent.width, y: config.size.height / outputImage.extent.height)
        let scaledImage = outputImage.transformed(by: transform)
        
        // Apply colors
        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = scaledImage
        colorFilter.color0 = CIColor(red: 0, green: 0, blue: 0, alpha: 1) // Black
        colorFilter.color1 = CIColor(red: 1, green: 1, blue: 1, alpha: 1) // White
        
        guard let coloredImage = colorFilter.outputImage else {
            throw QRError.generationFailed
        }
        
        // Convert to PNG
        guard let pngData = context.pngRepresentation(of: coloredImage, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()) else {
            throw QRError.generationFailed
        }
        
        // Save to file
        let qrCodePath = qrDirectory.appendingPathComponent("\(share.shareCode).png")
        try pngData.write(to: qrCodePath)
        
        // Update share with QR code data
        share.qrCodeData = pngData
        try context.save()
    }
    
    /// 获取 QR 码图片路径
    func getQRCodeImagePath(for shareCode: String) -> URL {
        qrDirectory.appendingPathComponent("\(shareCode).png")
    }
    
    // MARK: - Scan Tracking
    
    /// 记录扫描
    func recordScan(
        for shareCode: String,
        deviceInfo: String? = nil,
        location: String? = nil,
        referrer: String? = nil
    ) throws {
        guard let share = try getQRShare(byCode: shareCode), share.isActive else {
            return
        }
        
        // Create scan record
        let scanRecord = DreamQRScanRecord(
            shareId: share.id,
            deviceInfo: deviceInfo,
            location: location,
            referrer: referrer
        )
        context.insert(scanRecord)
        
        // Update scan count
        share.scanCount += 1
        share.lastScannedAt = Date()
        
        try context.save()
    }
    
    /// 获取扫描记录
    func getScanRecords(for shareId: UUID) throws -> [DreamQRScanRecord] {
        try context.fetch(FetchDescriptor<DreamQRScanRecord>(
            predicate: #Predicate<DreamQRScanRecord> { $0.shareId == shareId }
        ))
    }
    
    // MARK: - Statistics
    
    /// 获取统计信息
    func getStatistics() throws -> DreamQRShareStats {
        let allShares = try context.fetch(FetchDescriptor<DreamQRShare>())
        let allScans = try context.fetch(FetchDescriptor<DreamQRScanRecord>())
        
        let activeShares = allShares.filter { $0.isActive && !$0.isExpired }
        let expiredShares = allShares.filter { $0.isExpired || !$0.isActive }
        
        let totalScans = allShares.reduce(0) { $0 + $1.scanCount }
        let uniqueScans = Set(allScans.map { $0.shareId }).count
        
        let averageScans = allShares.isEmpty ? 0 : Double(totalScans) / Double(allShares.count)
        
        // Find most popular theme
        let themeCounts = Dictionary(grouping: allShares, by: { $0.theme })
            .mapValues { $0.count }
        let mostPopularTheme = themeCounts.max(by: { $0.value < $1.value })?.key
        
        // Calculate scan trend (last 7 days)
        let calendar = Calendar.current
        var scanTrend: [Date: Int] = [:]
        
        for scan in allScans {
            let day = calendar.startOfDay(for: scan.scannedAt)
            scanTrend[day, default: 0] += 1
        }
        
        return DreamQRShareStats(
            totalShares: allShares.count,
            activeShares: activeShares.count,
            expiredShares: expiredShares.count,
            totalScans: totalScans,
            uniqueScans: uniqueScans,
            averageScansPerShare: averageScans,
            mostPopularTheme: mostPopularTheme,
            scanTrend: scanTrend
        )
    }
    
    // MARK: - Web Preview Generation
    
    /// 生成 Web 预览 HTML
    func generateWebPreviewHTML(
        for share: DreamQRShare,
        dreamTitle: String,
        dreamContent: String,
        dreamDate: Date,
        aiAnalysis: String?,
        tags: [String],
        emotions: [String]
    ) -> String {
        let config = WebPreviewConfig(
            showHeader: true,
            showFooter: true,
            showDreamContent: true,
            showAIAnalysis: share.includeAIAnalysis,
            showTags: share.includeTags,
            showEmotions: share.includeEmotions,
            showShareButton: true,
            allowComments: false,
            theme: share.theme,
            customMessage: share.customMessage
        )
        
        let gradientBackground = config.theme.gradientColors.map { "linear-gradient(135deg, \($0) 0%, \($0) 50%, \($0) 100%)" }.joined(separator: ", ")
        
        var html = """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(dreamTitle) - DreamLog</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: \(gradientBackground);
                    min-height: 100vh;
                    color: \(config.theme.textColor);
                }
                .container {
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }
                .header {
                    text-align: center;
                    padding: 40px 20px;
                }
                .logo {
                    font-size: 48px;
                    margin-bottom: 10px;
                }
                .app-name {
                    font-size: 24px;
                    font-weight: 600;
                    opacity: 0.9;
                }
                .card {
                    background: rgba(255, 255, 255, 0.1);
                    backdrop-filter: blur(10px);
                    border-radius: 20px;
                    padding: 30px;
                    margin: 20px 0;
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                }
                .dream-title {
                    font-size: 28px;
                    font-weight: 700;
                    margin-bottom: 15px;
                }
                .dream-date {
                    font-size: 14px;
                    opacity: 0.7;
                    margin-bottom: 20px;
                }
                .dream-content {
                    font-size: 16px;
                    line-height: 1.8;
                    opacity: 0.95;
                    white-space: pre-wrap;
                }
                .tags {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 8px;
                    margin-top: 20px;
                }
                .tag {
                    background: rgba(255, 255, 255, 0.2);
                    padding: 6px 14px;
                    border-radius: 20px;
                    font-size: 13px;
                }
                .emotions {
                    display: flex;
                    gap: 10px;
                    margin-top: 15px;
                }
                .emotion {
                    font-size: 24px;
                }
                .ai-analysis {
                    background: rgba(255, 255, 255, 0.15);
                    border-radius: 15px;
                    padding: 20px;
                    margin-top: 25px;
                }
                .ai-label {
                    font-size: 14px;
                    font-weight: 600;
                    margin-bottom: 10px;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                .footer {
                    text-align: center;
                    padding: 30px 20px;
                    opacity: 0.8;
                    font-size: 14px;
                }
                .download-btn {
                    display: inline-block;
                    background: rgba(255, 255, 255, 0.2);
                    color: \(config.theme.textColor);
                    text-decoration: none;
                    padding: 12px 30px;
                    border-radius: 25px;
                    margin-top: 20px;
                    font-weight: 600;
                    transition: all 0.3s;
                }
                .download-btn:hover {
                    background: rgba(255, 255, 255, 0.3);
                }
                .expired-notice {
                    background: rgba(255, 100, 100, 0.3);
                    padding: 20px;
                    border-radius: 15px;
                    text-align: center;
                    margin: 20px 0;
                }
            </style>
        </head>
        <body>
            <div class="container">
        """
        
        if config.showHeader {
            html += """
                <div class="header">
                    <div class="logo">🌙</div>
                    <div class="app-name">DreamLog</div>
                </div>
            """
        }
        
        if share.isExpired {
            html += """
                <div class="expired-notice">
                    <h2>⏰ 分享已过期</h2>
                    <p style="margin-top: 10px; opacity: 0.8;">此梦境分享链接已过期，无法查看内容。</p>
                </div>
            """
        } else if config.showDreamContent {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let formattedDate = dateFormatter.string(from: dreamDate)
            
            html += """
                <div class="card">
                    <div class="dream-title">\(dreamTitle)</div>
                    <div class="dream-date">📅 \(formattedDate)</div>
                    <div class="dream-content">\(dreamContent)</div>
            """
            
            if config.showEmotions && !emotions.isEmpty {
                html += """
                    <div class="emotions">
                """
                for emotion in emotions {
                    html += "<span class=\"emotion\">\(emotion)</span>"
                }
                html += """
                    </div>
                """
            }
            
            if config.showTags && !tags.isEmpty {
                html += """
                    <div class="tags">
                """
                for tag in tags {
                    html += "<span class=\"tag\">#\(tag)</span>"
                }
                html += """
                    </div>
                """
            }
            
            if config.showAIAnalysis, let aiAnalysis = aiAnalysis {
                html += """
                    <div class="ai-analysis">
                        <div class="ai-label">🧠 AI 解析</div>
                        <div style="line-height: 1.6;">\(aiAnalysis)</div>
                    </div>
                """
            }
            
            html += """
                </div>
            """
        }
        
        if config.showFooter {
            html += """
                <div class="footer">
                    <p>✨ 记录你的梦，发现潜意识的秘密</p>
                    <a href="https://dreamlog.app" class="download-btn">下载 DreamLog</a>
                </div>
            """
        }
        
        html += """
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    // MARK: - Utilities
    
    /// 生成分享码
    private func generateShareCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Exclude confusing chars
        let charArray = Array(characters)
        return String((0..<8).map { _ in charArray.randomElement() ?? "A" })
    }
}

// MARK: - Filter & Sort Options

enum QRShareFilter {
    case all
    case active
    case expired
    case byDreamId(UUID)
}

enum QRShareSort {
    case createdAt
    case expiresAt
    case scanCount
    case shareCode
}

// MARK: - Errors

enum QRError: LocalizedError {
    case generationFailed
    case shareNotFound
    case shareExpired
    case shareInactive
    case invalidURL
    case documentsDirectoryNotFound
    
    var errorDescription: String? {
        switch self {
        case .generationFailed: return "QR 码生成失败"
        case .shareNotFound: return "分享不存在"
        case .shareExpired: return "分享已过期"
        case .shareInactive: return "分享已停用"
        case .invalidURL: return "无效的 URL"
        case .documentsDirectoryNotFound: return "文档目录不存在"
        }
    }
}
