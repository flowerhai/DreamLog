//
//  DreamCloudBackupProvidersModels.swift
//  DreamLog
//
//  Phase 62: Dream Cloud Backup Enhancement
//  Models for Google Drive and Dropbox backup providers
//

import Foundation
import SwiftData

// MARK: - Cloud Backup Provider Types

/// Supported cloud backup providers
enum CloudBackupProvider: String, Codable, CaseIterable, Identifiable {
    case googleDrive = "google_drive"
    case dropbox = "dropbox"
    case onedrive = "onedrive"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .googleDrive: return "Google Drive"
        case .dropbox: return "Dropbox"
        case .onedrive: return "OneDrive"
        }
    }
    
    var iconName: String {
        switch self {
        case .googleDrive: return "folder.fill"
        case .dropbox: return "externaldrive.fill"
        case .onedrive: return "cloud.fill"
        }
    }
    
    var brandColor: String {
        switch self {
        case .googleDrive: return "4285F4"
        case .dropbox: return "0061FF"
        case .onedrive: return "0078D4"
        }
    }
}

// MARK: - Cloud Backup Account

/// Represents a connected cloud backup account
@Model
final class CloudBackupAccount {
    var id: UUID
    var provider: String
    var accountName: String
    var accountEmail: String?
    var accessToken: String
    var refreshToken: String?
    var tokenExpiry: Date?
    var isConnected: Bool
    var createdAt: Date
    var lastBackupAt: Date?
    var totalBackups: Int
    var storageUsedBytes: Int64
    var storageQuotaBytes: Int64
    
    init(
        id: UUID = UUID(),
        provider: String,
        accountName: String,
        accountEmail: String? = nil,
        accessToken: String,
        refreshToken: String? = nil,
        tokenExpiry: Date? = nil,
        isConnected: Bool = true,
        createdAt: Date = Date(),
        lastBackupAt: Date? = nil,
        totalBackups: Int = 0,
        storageUsedBytes: Int64 = 0,
        storageQuotaBytes: Int64 = 0
    ) {
        self.id = id
        self.provider = provider
        self.accountName = accountName
        self.accountEmail = accountEmail
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiry = tokenExpiry
        self.isConnected = isConnected
        self.createdAt = createdAt
        self.lastBackupAt = lastBackupAt
        self.totalBackups = totalBackups
        self.storageUsedBytes = storageUsedBytes
        self.storageQuotaBytes = storageQuotaBytes
    }
    
    var providerEnum: CloudBackupProvider? {
        CloudBackupProvider(rawValue: provider)
    }
    
    var storageUsagePercent: Double {
        guard storageQuotaBytes > 0 else { return 0 }
        return Double(storageUsedBytes) / Double(storageQuotaBytes) * 100
    }
    
    var formattedStorageUsed: String {
        ByteCountFormatter.string(fromByteCount: storageUsedBytes, countStyle: .file)
    }
    
    var formattedStorageQuota: String {
        ByteCountFormatter.string(fromByteCount: storageQuotaBytes, countStyle: .file)
    }
}

// MARK: - Cloud Backup Task

/// Represents a cloud backup task
@Model
final class CloudBackupTask {
    var id: UUID
    var accountId: UUID
    var status: String
    var progress: Double
    var totalItems: Int
    var processedItems: Int
    var backupSize: Int64
    var remoteFilePath: String
    var errorMessage: String?
    var startedAt: Date?
    var completedAt: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        accountId: UUID,
        status: String = "pending",
        progress: Double = 0,
        totalItems: Int = 0,
        processedItems: Int = 0,
        backupSize: Int64 = 0,
        remoteFilePath: String = "",
        errorMessage: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.accountId = accountId
        self.status = status
        self.progress = progress
        self.totalItems = totalItems
        self.processedItems = processedItems
        self.backupSize = backupSize
        self.remoteFilePath = remoteFilePath
        self.errorMessage = errorMessage
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
    
    var statusEnum: CloudBackupTaskStatus {
        CloudBackupTaskStatus(rawValue: status) ?? .pending
    }
    
    var formattedBackupSize: String {
        ByteCountFormatter.string(fromByteCount: backupSize, countStyle: .file)
    }
    
    var duration: TimeInterval? {
        guard let started = startedAt, let completed = completedAt else { return nil }
        return completed.timeIntervalSince(started)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: duration)
    }
}

// MARK: - Cloud Backup Task Status

enum CloudBackupTaskStatus: String, Codable {
    case pending = "pending"
    case uploading = "uploading"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

// MARK: - Cloud Backup Configuration

struct CloudBackupConfig: Codable {
    var provider: CloudBackupProvider
    var autoBackupEnabled: Bool
    var autoBackupFrequency: AutoBackupFrequency
    var backupTime: Date?
    var includeAudio: Bool
    var includeImages: Bool
    var compressBackup: Bool
    var encryptBackup: Bool
    var backupPassword: String?
    var retainCount: Int
    
    init(
        provider: CloudBackupProvider,
        autoBackupEnabled: Bool = false,
        autoBackupFrequency: AutoBackupFrequency = .weekly,
        backupTime: Date? = nil,
        includeAudio: Bool = true,
        includeImages: Bool = true,
        compressBackup: Bool = true,
        encryptBackup: Bool = true,
        backupPassword: String? = nil,
        retainCount: Int = 10
    ) {
        self.provider = provider
        self.autoBackupEnabled = autoBackupEnabled
        self.autoBackupFrequency = autoBackupFrequency
        self.backupTime = backupTime
        self.includeAudio = includeAudio
        self.includeImages = includeImages
        self.compressBackup = compressBackup
        self.encryptBackup = encryptBackup
        self.backupPassword = backupPassword
        self.retainCount = retainCount
    }
}

// MARK: - Auto Backup Frequency

enum AutoBackupFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        }
    }
}

// MARK: - Cloud Backup Item

struct CloudBackupItem: Codable, Identifiable {
    var id: UUID
    var fileName: String
    var fileSize: Int64
    var remotePath: String
    var createdAt: Date
    var dreamCount: Int
    var checksum: String
    
    init(
        id: UUID = UUID(),
        fileName: String,
        fileSize: Int64,
        remotePath: String,
        createdAt: Date,
        dreamCount: Int,
        checksum: String
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.remotePath = remotePath
        self.createdAt = createdAt
        self.dreamCount = dreamCount
        self.checksum = checksum
    }
    
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - OAuth Token Response

struct OAuthTokenResponse: Codable {
    var accessToken: String
    var tokenType: String
    var expiresIn: Int?
    var refreshToken: String?
    var scope: String?
    var idToken: String?
}

// MARK: - Cloud Storage Info

struct CloudStorageInfo: Codable {
    var used: Int64
    var total: Int64
    var normal: Int64
    var trash: Int64
    
    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
    }
    
    var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    var usagePercent: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }
}
