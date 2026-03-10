//
//  DreamBackupModels.swift
//  DreamLog
//
//  梦境备份与恢复系统 - 数据模型
//  Phase 15 - 数据备份与恢复
//

import Foundation

// MARK: - 备份配置

/// 备份类型
enum BackupType: String, Codable, CaseIterable, Identifiable {
    case full = "完整备份"
    case partial = "部分备份"
    case incremental = "增量备份"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .full: return "square.stack.3d.up.fill"
        case .partial: return "square.split.1x2"
        case .incremental: return "arrow.triangle.2.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .full: return "备份所有梦境数据和设置"
        case .partial: return "仅备份选定的梦境"
        case .incremental: return "仅备份上次备份后的变更"
        }
    }
}

/// 备份加密选项
enum BackupEncryption: String, Codable, CaseIterable, Identifiable {
    case none = "不加密"
    case password = "密码保护"
    case faceID = "Face ID / Touch ID"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "lock.open"
        case .password: return "lock.fill"
        case .faceID: return "faceid"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "备份文件不加密，可快速访问"
        case .password: return "使用密码加密备份文件"
        case .faceID: return "使用生物识别加密备份"
        }
    }
}

/// 备份配置
struct BackupConfig: Codable {
    var backupType: BackupType = .full
    var encryption: BackupEncryption = .password
    var includeSettings: Bool = true
    var includeStatistics: Bool = true
    var includeAIHistory: Bool = false
    var compressData: Bool = true
    var autoBackup: Bool = false
    var autoBackupInterval: AutoBackupInterval = .weekly
    
    enum AutoBackupInterval: String, Codable, CaseIterable {
        case daily = "每天"
        case weekly = "每周"
        case monthly = "每月"
        
        var days: Int {
            switch self {
            case .daily: return 1
            case .weekly: return 7
            case .monthly: return 30
            }
        }
    }
    
    var estimatedSize: String {
        switch backupType {
        case .full: return "~50-200 MB"
        case .partial: return "~10-50 MB"
        case .incremental: return "~5-20 MB"
        }
    }
}

// MARK: - 备份元数据

/// 备份文件元数据
struct BackupMetadata: Codable {
    let id: String
    let version: String
    let appName: String
    let bundleID: String
    let createdAt: Date
    var modifiedAt: Date
    let deviceName: String
    let deviceModel: String
    let iOSVersion: String
    let backupType: BackupType
    let encryption: BackupEncryption
    let dreamCount: Int
    let fileSize: Int64
    let checksum: String
    var notes: String?
    var tags: [String]
    
    init(
        id: String = UUID().uuidString,
        version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        appName: String = "DreamLog",
        bundleID: String = Bundle.main.bundleIdentifier ?? "com.dreamlog.app",
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        deviceName: String = UIDevice.current.name,
        deviceModel: String = UIDevice.current.model,
        iOSVersion: String = UIDevice.current.systemVersion,
        backupType: BackupType,
        encryption: BackupEncryption,
        dreamCount: Int,
        fileSize: Int64,
        checksum: String,
        notes: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.version = version
        self.appName = appName
        self.bundleID = bundleID
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.iOSVersion = iOSVersion
        self.backupType = backupType
        self.encryption = encryption
        self.dreamCount = dreamCount
        self.fileSize = fileSize
        self.checksum = checksum
        self.notes = notes
        self.tags = tags
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - 备份数据容器

/// 备份数据容器
struct BackupData: Codable {
    let metadata: BackupMetadata
    let dreams: [Dream]
    let tags: [DreamTag]
    let settings: AppSettings?
    let statistics: DreamStatistics?
    let aiHistory: [AIInteraction]?
    
    struct DreamTag: Codable {
        let id: String
        let name: String
        let color: String
        let createdAt: Date
    }
    
    struct AppSettings: Codable {
        let theme: String
        let language: String
        let notifications: [String: Bool]
        let privacy: [String: Bool]
    }
    
    struct DreamStatistics: Codable {
        let totalDreams: Int
        let totalLucidDreams: Int
        let averageClarity: Double
        let moodDistribution: [String: Int]
        let streakDays: Int
    }
    
    struct AIInteraction: Codable {
        let id: String
        let type: String
        let input: String
        let output: String
        let createdAt: Date
    }
}

// MARK: - 恢复选项

/// 恢复冲突解决策略
enum ConflictResolution: String, Codable, CaseIterable, Identifiable {
    case keepBoth = "保留两者"
    case keepNewer = "保留较新的"
    case keepOlder = "保留较旧的"
    case skip = "跳过"
    case overwrite = "覆盖现有"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .keepBoth: return "doc.on.doc"
        case .keepNewer: return "clock.fill"
        case .keepOlder: return "clock"
        case .skip: return "xmark.circle"
        case .overwrite: return "arrow.counterclockwise"
        }
    }
    
    var description: String {
        switch self {
        case .keepBoth: return "创建副本，保留两个版本"
        case .keepNewer: return "使用最新的数据"
        case .keepOlder: return "保留原有数据"
        case .skip: return "跳过冲突的项目"
        case .overwrite: return "用备份数据覆盖现有数据"
        }
    }
}

/// 恢复配置
struct RestoreConfig: Codable {
    var conflictResolution: ConflictResolution = .keepNewer
    var restoreDreams: Bool = true
    var restoreTags: Bool = true
    var restoreSettings: Bool = false
    var restoreStatistics: Bool = false
    var dryRun: Bool = false  // 仅预览，不实际恢复
    
    var summary: String {
        var items: [String] = []
        if restoreDreams { items.append("梦境") }
        if restoreTags { items.append("标签") }
        if restoreSettings { items.append("设置") }
        if restoreStatistics { items.append("统计") }
        return items.joined(separator: "、")
    }
}

// MARK: - 备份状态

/// 备份进度
struct BackupProgress: Identifiable {
    let id = UUID()
    var currentStep: String
    var totalSteps: Int
    var currentStepIndex: Int
    var estimatedTimeRemaining: TimeInterval?
    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps)
    }
}

/// 备份结果
struct BackupResult {
    let success: Bool
    let filePath: String?
    let metadata: BackupMetadata?
    let error: BackupError?
    let warnings: [String]
    
    var errorMessage: String? {
        error?.localizedDescription
    }
}

/// 恢复结果
struct RestoreResult {
    let success: Bool
    let dreamsRestored: Int
    let tagsRestored: Int
    let conflictsResolved: Int
    let error: BackupError?
    let warnings: [String]
    
    var summary: String {
        var parts: [String] = []
        if dreamsRestored > 0 { parts.append("\(dreamsRestored) 个梦境") }
        if tagsRestored > 0 { parts.append("\(tagsRestored) 个标签") }
        if conflictsResolved > 0 { parts.append("解决 \(conflictsResolved) 个冲突") }
        return parts.joined(separator: "，")
    }
}

// MARK: - 备份错误

enum BackupError: LocalizedError {
    case fileAccessError(String)
    case encryptionError(String)
    case decryptionError(String)
    case invalidBackupFile(String)
    case checksumMismatch
    case versionMismatch(String)
    case insufficientSpace(Int64, Int64)
    case cancelled
    case unknown(Error)
    case invalidPassword
    case biometricUnavailable
    case authenticationFailed
    case corruptedBackup
    
    var errorDescription: String? {
        switch self {
        case .fileAccessError(let path):
            return "无法访问文件：\(path)"
        case .encryptionError(let reason):
            return "加密失败：\(reason)"
        case .decryptionError(let reason):
            return "解密失败：\(reason)"
        case .invalidBackupFile(let reason):
            return "无效的备份文件：\(reason)"
        case .checksumMismatch:
            return "文件校验失败，备份可能已损坏"
        case .versionMismatch(let version):
            return "版本不兼容，需要 DreamLog \(version) 或更高版本"
        case .insufficientSpace(let needed, let available):
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let neededStr = formatter.string(fromByteCount: needed)
            let availableStr = formatter.string(fromByteCount: available)
            return "存储空间不足，需要 \(neededStr)，可用 \(availableStr)"
        case .cancelled:
            return "操作已取消"
        case .unknown(let error):
            return "发生错误：\(error.localizedDescription)"
        case .invalidPassword:
            return "密码无效或为空"
        case .biometricUnavailable:
            return "生物识别不可用，请检查设备设置"
        case .authenticationFailed:
            return "生物识别验证失败"
        case .corruptedBackup:
            return "备份文件已损坏，无法解密"
        }
    }
}

// MARK: - 备份历史

/// 备份历史记录
struct BackupHistory: Codable {
    var backups: [BackupMetadata]
    var lastAutoBackup: Date?
    var autoBackupEnabled: Bool
    
    init(backups: [BackupMetadata] = [], lastAutoBackup: Date? = nil, autoBackupEnabled: Bool = false) {
        self.backups = backups
        self.lastAutoBackup = lastAutoBackup
        self.autoBackupEnabled = autoBackupEnabled
    }
    
    var totalBackups: Int { backups.count }
    var totalSize: Int64 { backups.reduce(0) { $0 + $1.fileSize } }
    
    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}
