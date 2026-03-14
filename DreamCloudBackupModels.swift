//
//  DreamCloudBackupModels.swift
//  DreamLog - Phase 37: Cloud Backup Integration
//
//  Created by DreamLog Team on 2026-03-14.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Cloud Provider Types

/// 支持的云备份服务提供商
enum CloudProvider: String, Codable, CaseIterable, Identifiable {
    case googleDrive = "google_drive"
    case dropbox = "dropbox"
    case onedrive = "onedrive"
    case webdav = "webdav"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .googleDrive: return "Google Drive"
        case .dropbox: return "Dropbox"
        case .onedrive: return "OneDrive"
        case .webdav: return "WebDAV"
        }
    }
    
    var iconName: String {
        switch self {
        case .googleDrive: return "circle.fill"
        case .dropbox: return "square.fill"
        case .onedrive: return "cloud.fill"
        case .webdav: return "server.rack"
        }
    }
    
    var color: String {
        switch self {
        case .googleDrive: return "34A853"
        case .dropbox: return "0061FF"
        case .onedrive: return "0078D4"
        case .webdav: return "6B7280"
        }
    }
    
    var authType: AuthType {
        switch self {
        case .googleDrive, .dropbox, .onedrive:
            return .oauth2
        case .webdav:
            return .basic
        }
    }
}

// MARK: - Authentication Types

/// 认证方式
enum AuthType: String, Codable {
    case oauth2 = "oauth2"
    case basic = "basic"
    case token = "token"
}

// MARK: - Cloud Backup Configuration

/// 云备份配置
@Model
final class CloudBackupConfig {
    var id: UUID
    var provider: String
    var accountName: String
    var isConnected: Bool
    var accessToken: String?
    var refreshToken: String?
    var tokenExpiry: Date?
    var webdavUrl: String?
    var webdavUsername: String?
    var webdavPassword: String?
    var autoBackupEnabled: Bool
    var autoBackupFrequency: BackupFrequency
    var lastBackupDate: Date?
    var nextBackupDate: Date?
    var totalBackups: Int
    var storageUsed: Int64
    var storageQuota: Int64
    var createdAt: Date
    var updatedAt: Date
    
    init(
        provider: CloudProvider,
        accountName: String = "",
        autoBackupEnabled: Bool = false,
        autoBackupFrequency: BackupFrequency = .weekly
    ) {
        self.id = UUID()
        self.provider = provider.rawValue
        self.accountName = accountName
        self.isConnected = false
        self.autoBackupEnabled = autoBackupEnabled
        self.autoBackupFrequency = autoBackupFrequency
        self.totalBackups = 0
        self.storageUsed = 0
        self.storageQuota = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Backup Frequency

/// 自动备份频率
enum BackupFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .manual: return "手动"
        }
    }
    
    var intervalSeconds: TimeInterval {
        switch self {
        case .daily: return 86400
        case .weekly: return 604800
        case .monthly: return 2592000
        case .manual: return 0
        }
    }
}

// MARK: - Cloud Backup Record

/// 云备份记录
@Model
final class CloudBackupRecord {
    var id: UUID
    var configId: UUID
    var provider: String
    var fileName: String
    var fileSize: Int64
    var cloudFileId: String
    var cloudFilePath: String
    var backupType: BackupType
    var dreamCount: Int
    var includesAudio: Bool
    var includesImages: Bool
    var isEncrypted: Bool
    var checksum: String
    var uploadDate: Date
    var expiryDate: Date?
    var downloadUrl: String?
    var status: BackupStatus
    var errorMessage: String?
    var createdAt: Date
    
    init(
        configId: UUID,
        provider: CloudProvider,
        fileName: String,
        cloudFileId: String,
        cloudFilePath: String,
        backupType: BackupType,
        dreamCount: Int,
        fileSize: Int64,
        includesAudio: Bool = false,
        includesImages: Bool = false,
        isEncrypted: Bool = true
    ) {
        self.id = UUID()
        self.configId = configId
        self.provider = provider.rawValue
        self.fileName = fileName
        self.fileSize = fileSize
        self.cloudFileId = cloudFileId
        self.cloudFilePath = cloudFilePath
        self.backupType = backupType
        self.dreamCount = dreamCount
        self.includesAudio = includesAudio
        self.includesImages = includesImages
        self.isEncrypted = isEncrypted
        self.checksum = ""
        self.uploadDate = Date()
        self.status = .completed
        self.createdAt = Date()
    }
}

// MARK: - Backup Types

/// 备份类型
enum BackupType: String, Codable, CaseIterable {
    case full = "full"
    case incremental = "incremental"
    case selective = "selective"
    
    var displayName: String {
        switch self {
        case .full: return "完整备份"
        case .incremental: return "增量备份"
        case .selective: return "选择性备份"
        }
    }
}

// MARK: - Backup Status

/// 备份状态
enum BackupStatus: String, Codable {
    case pending = "pending"
    case uploading = "uploading"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "等待中"
        case .uploading: return "上传中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .uploading: return "arrow.up.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "slash.circle"
        }
    }
}

// MARK: - OAuth Token Response

/// OAuth 令牌响应
struct OAuthTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int?
    let refreshToken: String?
    let scope: String?
    let idToken: String?
}

// MARK: - Cloud Storage Info

/// 云存储信息
struct CloudStorageInfo: Codable {
    let used: Int64
    let total: Int64
    let available: Int64
    let percentUsed: Double
    
    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
    }
    
    var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    var availableFormatted: String {
        ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
    }
}

// MARK: - Cloud Backup Options

/// 云备份选项
struct CloudBackupOptions: Codable {
    var backupType: BackupType
    var dateRange: DateRange
    var includeAudio: Bool
    var includeImages: Bool
    var includeAIAnalysis: Bool
    var includeLocations: Bool
    var compressData: Bool
    var encryptData: Bool
    var encryptionPassword: String?
    
    init(
        backupType: BackupType = .full,
        dateRange: DateRange = .all,
        includeAudio: Bool = true,
        includeImages: Bool = true,
        includeAIAnalysis: Bool = true,
        includeLocations: Bool = true,
        compressData: Bool = true,
        encryptData: Bool = true,
        encryptionPassword: String? = nil
    ) {
        self.backupType = backupType
        self.dateRange = dateRange
        self.includeAudio = includeAudio
        self.includeImages = includeImages
        self.includeAIAnalysis = includeAIAnalysis
        self.includeLocations = includeLocations
        self.compressData = compressData
        self.encryptData = encryptData
        self.encryptionPassword = encryptionPassword
    }
}

// MARK: - Date Range

/// 日期范围
enum DateRange: String, Codable, CaseIterable {
    case all = "all"
    case last7Days = "last_7_days"
    case last30Days = "last_30_days"
    case last3Months = "last_3_months"
    case lastYear = "last_year"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .last7Days: return "最近 7 天"
        case .last30Days: return "最近 30 天"
        case .last3Months: return "最近 3 个月"
        case .lastYear: return "最近 1 年"
        case .custom: return "自定义"
        }
    }
}

// MARK: - Cloud Provider Status

/// 云提供商连接状态
struct CloudProviderStatus: Codable {
    let provider: CloudProvider
    let isConnected: Bool
    let accountName: String?
    let storageInfo: CloudStorageInfo?
    let lastSyncDate: Date?
    let autoBackupEnabled: Bool
    let nextAutoBackup: Date?
    let errorMessage: String?
}

// MARK: - WebDAV Configuration

/// WebDAV 配置
struct WebDAVConfig: Codable {
    var serverUrl: String
    var username: String
    var password: String
    var path: String
    var useSSL: Bool
    var port: Int
    
    init(
        serverUrl: String,
        username: String,
        password: String,
        path: String = "/DreamLog",
        useSSL: Bool = true,
        port: Int = 443
    ) {
        self.serverUrl = serverUrl
        self.username = username
        self.password = password
        self.path = path
        self.useSSL = useSSL
        self.port = port
    }
    
    var fullUrl: String {
        let scheme = useSSL ? "https" : "http"
        let portString = (useSSL && port == 443) || (!useSSL && port == 80) ? "" : ":\(port)"
        return "\(scheme)://\(serverUrl)\(portString)\(path)"
    }
}

// MARK: - Cloud Backup Statistics

/// 云备份统计
struct CloudBackupStatistics: Codable {
    let totalConfigs: Int
    let connectedConfigs: Int
    let totalBackups: Int
    let totalSizeBytes: Int64
    let successfulBackups: Int
    let failedBackups: Int
    let lastBackupDate: Date?
    let nextScheduledBackup: Date?
    let providers: [CloudProvider]
    
    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file)
    }
    
    var successRate: Double {
        guard totalBackups > 0 else { return 0 }
        return Double(successfulBackups) / Double(totalBackups) * 100
    }
}
