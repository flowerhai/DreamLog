//
//  DreamiCloudSyncModels.swift
//  DreamLog - Phase 88: iCloud CloudKit Sync
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import CloudKit
import SwiftData

// MARK: - iCloud Sync Configuration

/// iCloud 同步配置
@Model
final class iCloudSyncConfig {
    var id: UUID
    var isEnabled: Bool
    var syncDreams: Bool
    var syncSettings: Bool
    var syncCollections: Bool
    var lastSyncDate: Date?
    var syncStatus: SyncStatus
    var conflictResolution: ConflictResolutionPolicy
    var cellularSyncEnabled: Bool
    var syncFrequency: SyncFrequency
    var createdAt: Date
    var updatedAt: Date
    
    init(
        isEnabled: Bool = false,
        syncDreams: Bool = true,
        syncSettings: Bool = true,
        syncCollections: Bool = true,
        conflictResolution: ConflictResolutionPolicy = .latestWins,
        cellularSyncEnabled: Bool = false,
        syncFrequency: SyncFrequency = .automatic
    ) {
        self.id = UUID()
        self.isEnabled = isEnabled
        self.syncDreams = syncDreams
        self.syncSettings = syncSettings
        self.syncSettings = syncSettings
        self.syncCollections = syncCollections
        self.lastSyncDate = nil
        self.syncStatus = .idle
        self.conflictResolution = conflictResolution
        self.cellularSyncEnabled = cellularSyncEnabled
        self.syncFrequency = syncFrequency
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Sync Status

/// 同步状态
enum SyncStatus: String, Codable {
    case idle = "idle"
    case syncing = "syncing"
    case paused = "paused"
    case error = "error"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .idle: return "空闲"
        case .syncing: return "同步中"
        case .paused: return "已暂停"
        case .error: return "错误"
        case .completed: return "已完成"
        }
    }
    
    var iconName: String {
        switch self {
        case .idle: return "clock"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .paused: return "pause.circle"
        case .error: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        }
    }
}

// MARK: - Conflict Resolution Policy

/// 冲突解决策略
enum ConflictResolutionPolicy: String, Codable, CaseIterable {
    case latestWins = "latestWins"
    case localWins = "localWins"
    case remoteWins = "remoteWins"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .latestWins: return "最新获胜"
        case .localWins: return "本地优先"
        case .remoteWins: return "云端优先"
        case .manual: return "手动选择"
        }
    }
    
    var description: String {
        switch self {
        case .latestWins: return "自动保留最新修改的版本"
        case .localWins: return "始终保留本地修改"
        case .remoteWins: return "始终保留云端版本"
        case .manual: return "每次冲突时手动选择"
        }
    }
}

// MARK: - Sync Frequency

/// 同步频率
enum SyncFrequency: String, Codable, CaseIterable {
    case automatic = "automatic"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .automatic: return "自动（实时）"
        case .hourly: return "每小时"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .manual: return "手动"
        }
    }
}

// MARK: - Sync Record Types

/// CloudKit 记录类型
enum CloudKitRecordType: String {
    case dream = "Dream"
    case collection = "Collection"
    case tag = "Tag"
    case userPreference = "UserPreference"
    case syncMetadata = "SyncMetadata"
}

// MARK: - Sync Metadata

/// 同步元数据 - 用于跟踪每个记录的同步状态
@Model
final class SyncMetadata {
    var id: UUID
    var recordID: String
    var recordType: String
    var localIdentifier: String
    var cloudKitRecordName: String
    var lastModifiedDate: Date
    var lastSyncDate: Date?
    var syncDirection: SyncDirection
    var isDeleted: Bool
    var version: Int
    var conflictData: Data?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        recordID: String,
        recordType: String,
        localIdentifier: String,
        cloudKitRecordName: String,
        syncDirection: SyncDirection = .bidirectional
    ) {
        self.id = UUID()
        self.recordID = recordID
        self.recordType = recordType
        self.localIdentifier = localIdentifier
        self.cloudKitRecordName = cloudKitRecordName
        self.lastModifiedDate = Date()
        self.lastSyncDate = nil
        self.syncDirection = syncDirection
        self.isDeleted = false
        self.version = 1
        self.conflictData = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Sync Direction

/// 同步方向
enum SyncDirection: String, Codable {
    case upload = "upload"
    case download = "download"
    case bidirectional = "bidirectional"
    
    var displayName: String {
        switch self {
        case .upload: return "上传"
        case .download: return "下载"
        case .bidirectional: return "双向"
        }
    }
}

// MARK: - Sync Error

/// 同步错误类型
enum SyncError: LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case quotaExceeded
    case recordNotFound
    case conflictDetected
    case databaseError
    case permissionDenied
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "未登录 iCloud，请在设置中登录"
        case .networkUnavailable:
            return "网络连接不可用"
        case .quotaExceeded:
            return "iCloud 存储空间不足"
        case .recordNotFound:
            return "记录未找到"
        case .conflictDetected:
            return "检测到冲突，需要解决"
        case .databaseError:
            return "数据库错误"
        case .permissionDenied:
            return "iCloud 同步权限被拒绝"
        case .unknown(let error):
            return "同步错误：\(error.localizedDescription)"
        }
    }
}

// MARK: - Sync Statistics

/// 同步统计信息
struct SyncStatistics {
    var totalRecordsSynced: Int
    var totalUploads: Int
    var totalDownloads: Int
    var totalConflicts: Int
    var totalErrors: Int
    var lastSyncDate: Date?
    var nextSyncDate: Date?
    var syncDuration: TimeInterval
    var dataSize: Int64
    
    var formattedDataSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: dataSize)
    }
    
    var formattedDuration: String {
        let minutes = Int(syncDuration) / 60
        let seconds = Int(syncDuration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        }
        return "\(seconds)秒"
    }
}

// MARK: - CloudKit Zone

/// CloudKit 自定义区域
struct CloudKitZone {
    static let zoneName = "DreamLogZone"
    static let zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName)
    }
    
    static var sharedZone: CKRecordZone {
        CKRecordZone(zoneID: zoneID)
    }
}
