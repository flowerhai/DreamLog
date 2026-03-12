//
//  DreamBackupModels.swift
//  DreamLog
//
//  Phase 29 - Dream Backup & Restore System
//  Data models for backup functionality
//

import Foundation
import SwiftData

// MARK: - Backup Models

/// Backup file metadata
struct BackupMetadata: Codable {
    let version: String
    let appVersion: String
    let backupDate: Date
    let deviceName: String
    let deviceModel: String
    let iosVersion: String
    let dreamCount: Int
    let includesAudio: Bool
    let includesImages: Bool
    let encryptionMethod: String?
    let checksum: String
    
    enum CodingKeys: String, CodingKey {
        case version, appVersion, backupDate, deviceName, deviceModel
        case iosVersion, dreamCount, includesAudio, includesImages
        case encryptionMethod, checksum
    }
}

/// Backup options for selective backup
struct BackupOptions: Codable {
    var includeAllDreams: Bool
    var dateRange: (start: Date, end: Date)?
    var includeTags: [String]?
    var includeAudio: Bool
    var includeImages: Bool
    var includeMetadata: Bool
    var encryptBackup: Bool
    var backupPassword: String?
    
    enum CodingKeys: String, CodingKey {
        case includeAllDreams, dateRange, includeTags
        case includeAudio, includeImages, includeMetadata
        case encryptBackup, backupPassword
    }
}

/// Backup progress information
struct BackupProgress {
    let currentStep: Int
    let totalSteps: Int
    let currentDreamIndex: Int
    let totalDreamCount: Int
    let status: BackupStatus
    let message: String
}

enum BackupStatus: String {
    case preparing = "preparing"
    case exporting = "exporting"
    case encrypting = "encrypting"
    case writing = "writing"
    case verifying = "verifying"
    case completed = "completed"
    case failed = "failed"
    case restoring = "restoring"
    case decrypting = "decrypting"
    case importing = "importing"
}

/// Backup result
struct BackupResult {
    let success: Bool
    let fileURL: URL?
    let backupSize: String
    let dreamCount: Int
    let errorMessage: String?
    let completedAt: Date
    
    init(
        success: Bool,
        fileURL: URL? = nil,
        backupSize: String = "0 KB",
        dreamCount: Int = 0,
        errorMessage: String? = nil,
        completedAt: Date = Date()
    ) {
        self.success = success
        self.fileURL = fileURL
        self.backupSize = backupSize
        self.dreamCount = dreamCount
        self.errorMessage = errorMessage
        self.completedAt = completedAt
    }
}

/// Restore result
struct RestoreResult {
    let success: Bool
    let dreamsRestored: Int
    let tagsRestored: Int
    let audioRestored: Int
    let imagesRestored: Int
    let skippedDuplicates: Int
    let errorMessage: String?
    let completedAt: Date
    
    init(
        success: Bool,
        dreamsRestored: Int = 0,
        tagsRestored: Int = 0,
        audioRestored: Int = 0,
        imagesRestored: Int = 0,
        skippedDuplicates: Int = 0,
        errorMessage: String? = nil,
        completedAt: Date = Date()
    ) {
        self.success = success
        self.dreamsRestored = dreamsRestored
        self.tagsRestored = tagsRestored
        self.audioRestored = audioRestored
        self.imagesRestored = imagesRestored
        self.skippedDuplicates = skippedDuplicates
        self.errorMessage = errorMessage
        self.completedAt = completedAt
    }
}

/// Backup history entry
@Model
final class BackupHistory {
    var id: UUID
    var backupDate: Date
    var backupType: BackupType
    var fileSize: Int64
    var dreamCount: Int
    var filePath: String
    var isEncrypted: Bool
    var verificationStatus: VerificationStatus
    var notes: String?
    
    enum BackupType: String, Codable {
        case manual = "manual"
        case automatic = "automatic"
        case beforeUpdate = "before_update"
        case export = "export"
    }
    
    enum VerificationStatus: String, Codable {
        case pending = "pending"
        case verified = "verified"
        case failed = "failed"
        case notChecked = "not_checked"
    }
    
    init(
        id: UUID = UUID(),
        backupDate: Date = Date(),
        backupType: BackupType = .manual,
        fileSize: Int64 = 0,
        dreamCount: Int = 0,
        filePath: String = "",
        isEncrypted: Bool = false,
        verificationStatus: VerificationStatus = .pending,
        notes: String? = nil
    ) {
        self.id = id
        self.backupDate = backupDate
        self.backupType = backupType
        self.fileSize = fileSize
        self.dreamCount = dreamCount
        self.filePath = filePath
        self.isEncrypted = isEncrypted
        self.verificationStatus = verificationStatus
        self.notes = notes
    }
}

/// Automatic backup schedule
@Model
final class BackupSchedule {
    var id: UUID
    var isEnabled: Bool
    var frequency: BackupFrequency
    var time: Date
    var lastBackupDate: Date?
    var nextBackupDate: Date
    var keepLastNBackups: Int
    
    enum BackupFrequency: String, Codable, CaseIterable {
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
    
    init(
        id: UUID = UUID(),
        isEnabled: Bool = false,
        frequency: BackupFrequency = .weekly,
        time: Date = Date(),
        lastBackupDate: Date? = nil,
        nextBackupDate: Date = Date(),
        keepLastNBackups: Int = 5
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.frequency = frequency
        self.time = time
        self.lastBackupDate = lastBackupDate
        self.nextBackupDate = nextBackupDate
        self.keepLastNBackups = keepLastNBackups
    }
}

// MARK: - Export Models

/// Dream export data structure
struct ExportDreamData: Codable {
    let id: UUID
    let title: String
    let content: String
    let date: Date
    var tags: [String]
    var emotions: [String]
    let clarity: Int
    let intensity: Int
    let isLucid: Bool
    let audioURL: String?
    let imageURLs: [String]
    let location: String?
    let weather: String?
    let sleepQuality: Int?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, date, tags, emotions
        case clarity, intensity, isLucid, audioURL, imageURLs
        case location, weather, sleepQuality, createdAt, updatedAt
    }
}

/// Complete backup data structure
struct BackupData: Codable {
    let metadata: BackupMetadata
    let dreams: [ExportDreamData]
    let tags: [String]
    let audioFiles: [String: Data]  // filename: data
    let imageFiles: [String: Data]  // filename: data
    
    enum CodingKeys: String, CodingKey {
        case metadata, dreams, tags, audioFiles, imageFiles
    }
}
