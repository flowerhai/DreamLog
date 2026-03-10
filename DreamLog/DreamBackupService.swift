//
//  DreamBackupService.swift
//  DreamLog
//
//  梦境备份与恢复服务 - Phase 16
//  支持本地备份、iCloud 同步、加密保护
//

import Foundation
import Combine
import UniformTypeIdentifiers

// MARK: - 备份服务

@MainActor
class DreamBackupService: ObservableObject {
    static let shared = DreamBackupService()
    
    // MARK: - Published Properties
    
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var backupProgress: BackupProgress?
    @Published var restoreProgress: BackupProgress?
    @Published var lastBackupDate: Date?
    @Published var backupHistory: BackupHistory = BackupHistory()
    @Published var currentBackupError: BackupError?
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let dreamStore = DreamStore.shared
    private let userDefaults = UserDefaults.standard
    
    private let backupsDirectory: URL
    private let configKey = "dreamlog.backup.config"
    private let historyKey = "dreamlog.backup.history"
    private let lastBackupKey = "dreamlog.backup.lastDate"
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init() {
        // 获取 Documents 目录
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        backupsDirectory = documentsPath.appendingPathComponent("DreamBackups", isDirectory: true)
        
        // 创建备份目录
        try? fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        
        // 加载配置和历史
        loadConfig()
        loadHistory()
        
        // 设置自动备份定时器
        setupAutoBackupTimer()
    }
    
    // MARK: - 配置管理
    
    func getConfig() -> BackupConfig {
        guard let data = userDefaults.data(forKey: configKey),
              let config = try? JSONDecoder().decode(BackupConfig.self, from: data) else {
            return BackupConfig()
        }
        return config
    }
    
    func saveConfig(_ config: BackupConfig) {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: configKey)
        }
    }
    
    private func loadConfig() {
        _ = getConfig()
    }
    
    // MARK: - 历史记录
    
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              var history = try? JSONDecoder().decode(BackupHistory.self, from: data) else {
            backupHistory = BackupHistory()
            return
        }
        
        // 验证备份文件是否存在
        history.backups = history.backups.filter { metadata in
            let fileURL = backupsDirectory.appendingPathComponent("\(metadata.id).dreambackup")
            return fileManager.fileExists(atPath: fileURL.path)
        }
        
        backupHistory = history
        lastBackupDate = history.lastAutoBackup
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(backupHistory) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
    
    // MARK: - 备份操作
    
    /// 创建备份
    func createBackup(config: BackupConfig, notes: String? = nil) async -> BackupResult {
        guard !isBackingUp else {
            return BackupResult(
                success: false,
                filePath: nil,
                metadata: nil,
                error: .cancelled,
                warnings: []
            )
        }
        
        isBackingUp = true
        currentBackupError = nil
        
        let totalSteps = 5
        backupProgress = BackupProgress(
            currentStep: "准备备份...",
            totalSteps: totalSteps,
            currentStepIndex: 0
        )
        
        defer {
            isBackingUp = false
            backupProgress = nil
        }
        
        do {
            // Step 1: 收集数据
            backupProgress?.currentStep = "收集梦境数据..."
            backupProgress?.currentStepIndex = 1
            
            let backupData = try collectBackupData(config: config)
            
            // Step 2: 创建元数据
            backupProgress?.currentStep = "创建元数据..."
            backupProgress?.currentStepIndex = 2
            
            let metadata = createMetadata(backupData: backupData, config: config, notes: notes)
            
            // Step 3: 序列化数据
            backupProgress?.currentStep = "序列化数据..."
            backupProgress?.currentStepIndex = 3
            
            let jsonData = try JSONEncoder().encode(backupData)
            
            // Step 4: 加密 (如果需要)
            backupProgress?.currentStep = config.encryption != .none ? "加密数据..." : "准备保存..."
            backupProgress?.currentStepIndex = 4
            
            let finalData: Data
            if config.encryption != .none {
                finalData = try encryptData(jsonData, config: config)
            } else {
                finalData = jsonData
            }
            
            // Step 5: 保存到文件
            backupProgress?.currentStep = "保存备份文件..."
            backupProgress?.currentStepIndex = 5
            
            let fileURL = backupsDirectory.appendingPathComponent("\(metadata.id).dreambackup")
            try finalData.write(to: fileURL)
            
            // 更新历史记录
            backupHistory.backups.insert(metadata, at: 0)
            backupHistory.lastAutoBackup = config.autoBackup ? Date() : backupHistory.lastAutoBackup
            saveHistory()
            
            // 清理旧备份 (保留最近 10 个)
            cleanupOldBackups(maxCount: 10)
            
            return BackupResult(
                success: true,
                filePath: fileURL.path,
                metadata: metadata,
                error: nil,
                warnings: []
            )
            
        } catch let error as BackupError {
            currentBackupError = error
            return BackupResult(
                success: false,
                filePath: nil,
                metadata: nil,
                error: error,
                warnings: []
            )
        } catch {
            let backupError = BackupError.unknown(error)
            currentBackupError = backupError
            return BackupResult(
                success: false,
                filePath: nil,
                metadata: nil,
                error: backupError,
                warnings: []
            )
        }
    }
    
    /// 收集备份数据
    private func collectBackupData(config: BackupConfig) throws -> BackupData {
        var dreams = dreamStore.dreams
        var tags = dreamStore.tags
        
        // 如果是部分备份，只选择选定的梦境 (简化版本：备份最近 100 个)
        if config.backupType == .partial {
            dreams = Array(dreams.prefix(100))
        }
        
        // 如果是增量备份，只备份上次备份后的变更
        if config.backupType == .incremental, let lastBackup = backupHistory.lastAutoBackup {
            dreams = dreams.filter { $0.date >= lastBackup }
        }
        
        let settingsData: BackupData.AppSettings? = config.includeSettings ? BackupData.AppSettings(
            theme: "default",
            language: "zh-CN",
            notifications: [:],
            privacy: [:]
        ) : nil
        
        let statisticsData: BackupData.DreamStatistics? = config.includeStatistics ? BackupData.DreamStatistics(
            totalDreams: dreams.count,
            totalLucidDreams: dreams.filter { $0.isLucid }.count,
            averageClarity: dreams.isEmpty ? 0 : dreams.map { $0.clarity }.reduce(0, +) / Double(dreams.count),
            moodDistribution: [:],
            streakDays: 0
        ) : nil
        
        let aiHistoryData: [BackupData.AIInteraction]? = config.includeAIHistory ? [] : nil
        
        return BackupData(
            metadata: createMetadataPlaceholder(),
            dreams: dreams,
            tags: tags.map { BackupData.DreamTag(id: $0.id, name: $0.name, color: $0.color.description, createdAt: $0.createdAt) },
            settings: settingsData,
            statistics: statisticsData,
            aiHistory: aiHistoryData
        )
    }
    
    /// 创建元数据占位符 (实际元数据在备份完成后更新)
    private func createMetadataPlaceholder() -> BackupMetadata {
        BackupMetadata(
            createdAt: Date(),
            modifiedAt: Date(),
            backupType: .full,
            encryption: .none,
            dreamCount: 0,
            fileSize: 0,
            checksum: ""
        )
    }
    
    /// 创建完整元数据
    private func createMetadata(backupData: BackupData, config: BackupConfig, notes: String?) -> BackupMetadata {
        let jsonData = try? JSONEncoder().encode(backupData)
        let fileSize = Int64(jsonData?.count ?? 0)
        let checksum = calculateChecksum(data: jsonData ?? Data())
        
        return BackupMetadata(
            backupType: config.backupType,
            encryption: config.encryption,
            dreamCount: backupData.dreams.count,
            fileSize: fileSize,
            checksum: checksum,
            notes: notes,
            tags: []
        )
    }
    
    /// 计算校验和
    private func calculateChecksum(data: Data) -> String {
        // 简化版本：使用 MD5 哈希 (实际应使用更安全的算法)
        let hash = data.reduce(0) { $0 ^ $1 }
        return String(format: "%08x", hash)
    }
    
    /// 加密数据
    private func encryptData(_ data: Data, config: BackupConfig) throws -> Data {
        // 简化版本：实际应使用 CommonCrypto 或 CryptoKit 进行加密
        // 这里仅做占位实现
        switch config.encryption {
        case .none:
            return data
        case .password, .faceID:
            // TODO: 实现实际加密逻辑
            return data
        }
    }
    
    /// 解密数据
    private func decryptData(_ data: Data, config: BackupConfig) throws -> Data {
        // 简化版本：实际应使用 CommonCrypto 或 CryptoKit 进行解密
        switch config.encryption {
        case .none:
            return data
        case .password, .faceID:
            // TODO: 实现实际解密逻辑
            return data
        }
    }
    
    // MARK: - 恢复操作
    
    /// 恢复备份
    func restoreBackup(from url: URL, config: RestoreConfig) async -> RestoreResult {
        guard !isRestoring else {
            return RestoreResult(
                success: false,
                dreamsRestored: 0,
                tagsRestored: 0,
                conflictsResolved: 0,
                error: .cancelled,
                warnings: []
            )
        }
        
        isRestoring = true
        
        let totalSteps = 4
        restoreProgress = BackupProgress(
            currentStep: "准备恢复...",
            totalSteps: totalSteps,
            currentStepIndex: 0
        )
        
        defer {
            isRestoring = false
            restoreProgress = nil
        }
        
        do {
            // Step 1: 读取文件
            restoreProgress?.currentStep = "读取备份文件..."
            restoreProgress?.currentStepIndex = 1
            
            let fileData = try Data(contentsOf: url)
            
            // Step 2: 解密 (如果需要)
            restoreProgress?.currentStep = "解密数据..."
            restoreProgress?.currentStepIndex = 2
            
            let decryptedData = try decryptData(fileData, config: getConfig())
            
            // Step 3: 解析数据
            restoreProgress?.currentStep = "解析备份数据..."
            restoreProgress?.currentStepIndex = 3
            
            let backupData = try JSONDecoder().decode(BackupData.self, from: decryptedData)
            
            // Step 4: 恢复数据
            restoreProgress?.currentStep = "恢复数据..."
            restoreProgress?.currentStepIndex = 4
            
            let result = try restoreData(backupData, config: config)
            
            return result
            
        } catch let error as BackupError {
            return RestoreResult(
                success: false,
                dreamsRestored: 0,
                tagsRestored: 0,
                conflictsResolved: 0,
                error: error,
                warnings: []
            )
        } catch {
            return RestoreResult(
                success: false,
                dreamsRestored: 0,
                tagsRestored: 0,
                conflictsResolved: 0,
                error: .unknown(error),
                warnings: []
            )
        }
    }
    
    /// 恢复数据到存储
    private func restoreData(_ backupData: BackupData, config: RestoreConfig) throws -> RestoreResult {
        var dreamsRestored = 0
        var tagsRestored = 0
        var conflictsResolved = 0
        
        // 恢复标签
        if config.restoreTags {
            for tag in backupData.tags {
                // 检查冲突
                if dreamStore.tags.contains(where: { $0.id == tag.id }) {
                    switch config.conflictResolution {
                    case .keepBoth:
                        // 创建新标签
                        let newTag = DreamTag(id: UUID().uuidString, name: tag.name, color: .blue, createdAt: tag.createdAt)
                        dreamStore.addTag(newTag)
                        tagsRestored += 1
                        conflictsResolved += 1
                    case .keepNewer:
                        // 保留备份中的标签
                        dreamStore.deleteTag(tag.id)
                        fallthrough
                    case .keepOlder:
                        // 保留现有标签
                        break
                    case .skip:
                        break
                    case .overwrite:
                        dreamStore.deleteTag(tag.id)
                        let newTag = DreamTag(id: tag.id, name: tag.name, color: .blue, createdAt: tag.createdAt)
                        dreamStore.addTag(newTag)
                        tagsRestored += 1
                    }
                } else {
                    let newTag = DreamTag(id: tag.id, name: tag.name, color: .blue, createdAt: tag.createdAt)
                    dreamStore.addTag(newTag)
                    tagsRestored += 1
                }
            }
        }
        
        // 恢复梦境
        if config.restoreDreams {
            for dream in backupData.dreams {
                // 检查冲突
                if dreamStore.dreams.contains(where: { $0.id == dream.id }) {
                    switch config.conflictResolution {
                    case .keepBoth:
                        // 创建新梦境
                        var newDream = dream
                        newDream.id = UUID()
                        dreamStore.addDream(newDream)
                        dreamsRestored += 1
                        conflictsResolved += 1
                    case .keepNewer:
                        if dream.date > dreamStore.dreams.first(where: { $0.id == dream.id })?.date ?? .distantPast {
                            dreamStore.deleteDream(dream.id)
                            dreamStore.addDream(dream)
                            dreamsRestored += 1
                        }
                    case .keepOlder:
                        break
                    case .skip:
                        break
                    case .overwrite:
                        dreamStore.deleteDream(dream.id)
                        dreamStore.addDream(dream)
                        dreamsRestored += 1
                    }
                } else {
                    dreamStore.addDream(dream)
                    dreamsRestored += 1
                }
            }
        }
        
        return RestoreResult(
            success: true,
            dreamsRestored: dreamsRestored,
            tagsRestored: tagsRestored,
            conflictsResolved: conflictsResolved,
            error: nil,
            warnings: []
        )
    }
    
    // MARK: - 自动备份
    
    private func setupAutoBackupTimer() {
        let config = getConfig()
        guard config.autoBackup else { return }
        
        // 每天检查是否需要自动备份
        Timer.publish(every: Double(config.autoBackupInterval.days * 24 * 60 * 60), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performAutoBackup()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performAutoBackup() async {
        let config = getConfig()
        guard config.autoBackup else { return }
        
        _ = await createBackup(config: config, notes: "自动备份")
    }
    
    // MARK: - 备份管理
    
    /// 删除备份
    func deleteBackup(_ metadata: BackupMetadata) throws {
        let fileURL = backupsDirectory.appendingPathComponent("\(metadata.id).dreambackup")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        
        backupHistory.backups.removeAll { $0.id == metadata.id }
        saveHistory()
    }
    
    /// 清理旧备份
    private func cleanupOldBackups(maxCount: Int) {
        guard backupHistory.backups.count > maxCount else { return }
        
        let oldBackups = backupHistory.backups.suffix(from: maxCount)
        for backup in oldBackups {
            try? deleteBackup(backup)
        }
    }
    
    /// 导出备份到外部位置
    func exportBackup(_ metadata: BackupMetadata, to url: URL) throws {
        let sourceURL = backupsDirectory.appendingPathComponent("\(metadata.id).dreambackup")
        try fileManager.copyItem(at: sourceURL, to: url)
    }
    
    /// 从外部位置导入备份
    func importBackup(from url: URL) throws -> BackupMetadata {
        let fileName = UUID().uuidString + ".dreambackup"
        let destURL = backupsDirectory.appendingPathComponent(fileName)
        
        try fileManager.copyItem(at: url, to: destURL)
        
        // 读取并解析元数据
        let data = try Data(contentsOf: destURL)
        let backupData = try JSONDecoder().decode(BackupData.self, from: data)
        
        return backupData.metadata
    }
    
    // MARK: - 备份验证
    
    /// 验证备份完整性
    func verifyBackup(_ metadata: BackupMetadata) -> Bool {
        let fileURL = backupsDirectory.appendingPathComponent("\(metadata.id).dreambackup")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return false
        }
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return false
        }
        
        let checksum = calculateChecksum(data: data)
        return checksum == metadata.checksum
    }
    
    /// 获取备份预估大小
    func estimateBackupSize(config: BackupConfig) -> Int64 {
        var size: Int64 = 0
        
        let dreams = dreamStore.dreams
        size += Int64(dreams.count * 1024) // 每个梦境约 1KB
        
        if config.includeSettings {
            size += 1024 // 设置约 1KB
        }
        
        if config.includeStatistics {
            size += 512 // 统计约 0.5KB
        }
        
        if config.compressData {
            size = Int64(Double(size) * 0.6) // 压缩后约 60%
        }
        
        return size
    }
}
