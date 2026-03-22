//
//  DreamQRShareModels.swift
//  DreamLog
//
//  Dream QR Code Sharing & Web Preview Models
//  Phase 88: Enhanced Social Sharing
//

import Foundation
import SwiftData

// MARK: - QR Share Data Models

/// QR 分享码模型
@Model
final class DreamQRShare {
    var id: UUID
    var dreamId: UUID
    var shareCode: String // 8 位分享码
    var qrCodeData: Data? // QR 码图片数据
    var webPreviewURL: String
    var createdAt: Date
    var expiresAt: Date
    var scanCount: Int
    var lastScannedAt: Date?
    var isActive: Bool
    var theme: QRShareTheme
    var includeAIAnalysis: Bool
    var includeTags: Bool
    var includeEmotions: Bool
    var customMessage: String?
    
    init(
        dreamId: UUID,
        shareCode: String,
        webPreviewURL: String,
        theme: QRShareTheme = .starry,
        includeAIAnalysis: Bool = true,
        includeTags: Bool = true,
        includeEmotions: Bool = true,
        customMessage: String? = nil,
        expirationDays: Int = 7
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.shareCode = shareCode
        self.webPreviewURL = webPreviewURL
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: expirationDays, to: self.createdAt) ?? Date().addingTimeInterval(604800)
        self.scanCount = 0
        self.isActive = true
        self.theme = theme
        self.includeAIAnalysis = includeAIAnalysis
        self.includeTags = includeTags
        self.includeEmotions = includeEmotions
        self.customMessage = customMessage
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }
    
    var formattedExpiresAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expiresAt)
    }
}

/// QR 分享主题
enum QRShareTheme: String, CaseIterable, Codable, Identifiable {
    case starry = "starry"          // 星空紫
    case sunset = "sunset"          // 日落橙
    case ocean = "ocean"            // 海洋蓝
    case forest = "forest"          // 森林绿
    case midnight = "midnight"      // 午夜黑
    case rose = "rose"              // 玫瑰粉
    case gold = "gold"              // 奢华金
    case lavender = "lavender"      // 薰衣草
    case aurora = "aurora"          // 极光绿
    case crystal = "crystal"        // 水晶蓝
    case minimal = "minimal"        // 极简白
    case custom = "custom"          // 自定义
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .starry: return "星空紫"
        case .sunset: return "日落橙"
        case .ocean: return "海洋蓝"
        case .forest: return "森林绿"
        case .midnight: return "午夜黑"
        case .rose: return "玫瑰粉"
        case .gold: return "奢华金"
        case .lavender: return "薰衣草"
        case .aurora: return "极光绿"
        case .crystal: return "水晶蓝"
        case .minimal: return "极简白"
        case .custom: return "自定义"
        }
    }
    
    var primaryColor: String {
        switch self {
        case .starry: return "#6B46C1"
        case .sunset: return "#ED8936"
        case .ocean: return "#4299E1"
        case .forest: return "#48BB78"
        case .midnight: return "#1A202C"
        case .rose: return "#EC4899"
        case .gold: return "#D69E2E"
        case .lavender: return "#9F7AEA"
        case .aurora: return "#38B2AC"
        case .crystal: return "#63B3ED"
        case .minimal: return "#F7FAFC"
        case .custom: return "#6B46C1"
        }
    }
    
    var secondaryColor: String {
        switch self {
        case .starry: return "#805AD5"
        case .sunset: return "#F6AD55"
        case .ocean: return "#63B3ED"
        case .forest: return "#68D391"
        case .midnight: return "#2D3748"
        case .rose: return "#F687B3"
        case .gold: return "#ECC94B"
        case .lavender: return "#B794F4"
        case .aurora: return "#4FD1C5"
        case .crystal: return "#90CDF4"
        case .minimal: return "#EDF2F7"
        case .custom: return "#805AD5"
        }
    }
    
    var gradientColors: [String] {
        switch self {
        case .starry: return ["#1A1C3A", "#4C1D95", "#6B46C1"]
        case .sunset: return ["#C05621", "#DD6B20", "#ED8936"]
        case .ocean: return ["#1A365D", "#2C5282", "#4299E1"]
        case .forest: return ["#22543D", "#276749", "#48BB78"]
        case .midnight: return ["#000000", "#1A202C", "#2D3748"]
        case .rose: return ["#831843", "#97266D", "#EC4899"]
        case .gold: return ["#744210", "#975A16", "#D69E2E"]
        case .lavender: return ["#44337A", "#553C9A", "#9F7AEA"]
        case .aurora: return ["#234E52", "#285E61", "#38B2AC"]
        case .crystal: return ["#2B6CB0", "#3182CE", "#63B3ED"]
        case .minimal: return ["#FFFFFF", "#F7FAFC", "#EDF2F7"]
        case .custom: return ["#1A1C3A", "#4C1D95", "#6B46C1"]
        }
    }
    
    var textColor: String {
        switch self {
        case .midnight: return "#FFFFFF"
        case .minimal: return "#1A202C"
        default: return "#FFFFFF"
        }
    }
    
    var icon: String {
        switch self {
        case .starry: return "⭐"
        case .sunset: return "🌅"
        case .ocean: return "🌊"
        case .forest: return "🌲"
        case .midnight: return "🌙"
        case .rose: return "🌹"
        case .gold: return "✨"
        case .lavender: return "💜"
        case .aurora: return "🌌"
        case .crystal: return "💎"
        case .minimal: return "◻️"
        case .custom: return "🎨"
        }
    }
}

/// QR 扫描记录模型
@Model
final class DreamQRScanRecord {
    var id: UUID
    var shareId: UUID
    var scannedAt: Date
    var deviceInfo: String?
    var location: String?
    var referrer: String?
    
    init(shareId: UUID, deviceInfo: String? = nil, location: String? = nil, referrer: String? = nil) {
        self.id = UUID()
        self.shareId = shareId
        self.scannedAt = Date()
        self.deviceInfo = deviceInfo
        self.location = location
        self.referrer = referrer
    }
}

/// QR 分享统计模型
struct DreamQRShareStats {
    var totalShares: Int
    var activeShares: Int
    var expiredShares: Int
    var totalScans: Int
    var uniqueScans: Int
    var averageScansPerShare: Double
    var mostPopularTheme: QRShareTheme?
    var scanTrend: [Date: Int]
    
    static var empty: DreamQRShareStats {
        DreamQRShareStats(
            totalShares: 0,
            activeShares: 0,
            expiredShares: 0,
            totalScans: 0,
            uniqueScans: 0,
            averageScansPerShare: 0,
            mostPopularTheme: nil,
            scanTrend: [:]
        )
    }
}

/// Web 预览页面配置
struct WebPreviewConfig {
    var showHeader: Bool
    var showFooter: Bool
    var showDreamContent: Bool
    var showAIAnalysis: Bool
    var showTags: Bool
    var showEmotions: Bool
    var showShareButton: Bool
    var allowComments: Bool
    var theme: QRShareTheme
    var customCSS: String?
    var customMessage: String?
    
    static var `default`: WebPreviewConfig {
        WebPreviewConfig(
            showHeader: true,
            showFooter: true,
            showDreamContent: true,
            showAIAnalysis: true,
            showTags: true,
            showEmotions: true,
            showShareButton: true,
            allowComments: false,
            theme: .starry
        )
    }
}

/// QR 码生成配置
struct QRCodeConfig {
    var size: CGSize
    var cornerRadius: CGFloat
    var logoImage: String? // SF Symbol name
    var foregroundColor: String
    var backgroundColor: String
    var errorCorrectionLevel: QRErrorCorrectionLevel
    
    static var `default`: QRCodeConfig {
        QRCodeConfig(
            size: CGSize(width: 300, height: 300),
            cornerRadius: 16,
            logoImage: "moon.fill",
            foregroundColor: "#000000",
            backgroundColor: "#FFFFFF",
            errorCorrectionLevel: .high
        )
    }
}

enum QRErrorCorrectionLevel: String {
    case low = "L"      // 7%
    case medium = "M"   // 15%
    case quartile = "Q" // 25%
    case high = "H"     // 30%
}
