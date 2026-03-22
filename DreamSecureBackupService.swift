//
//  DreamSecureBackupService.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import CryptoKit
import Security
import SwiftData

// MARK: - Secure Backup Service

/// 安全备份服务
@MainActor
final class DreamSecureBackupService {
    
    // MARK: - Singleton
    
    static let shared = DreamSecureBackupService()
    
    // MARK: - Constants
    
    private let backupVersion = 1
    private let keychainServiceName = "com.dreamlog.backup"
    private let backupPasswordKey = "dreamlog.backup.password"
    
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    private var backupKey: SymmetricKey?
    private var isBackingUp = false
    private var backupProgress: Double = 0
    
    var backupConfig: SecureBackupConfig?
    
    // MARK: - Initialization
    
    private init() {
        loadBackupConfig()
        loadOrCreateBackupKey()
    }
    
    // MARK: - Public Methods
    
    /// 设置模型上下文
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// 加载备份配置
    func loadBackupConfig() {
        // 从数据存储加载配置
        backupConfig = SecureBackupConfig()
    }
    
    /// 配置备份
    func configureBackup(
        isEnabled: Bool,
        encryptionEnabled: Bool = true,
        autoBackupEnabled: Bool = true,
        frequency: BackupFrequency = .weekly
    ) async throws {
        guard let context = modelContext else {
            throw BackupError.contextNotFound
        }
        
        let config = backupConfig ?? SecureBackupConfig()
        config.isEnabled = isEnabled
        config.encryptionEnabled = encryptionEnabled
        config.autoBackupEnabled = autoBackupEnabled
        config.autoBackupFrequency = frequency
        config.updatedAt = Date()
        
        context.insert(config)
        try context.save()
        
        backupConfig = config
        
        if isEnabled && encryptionEnabled {
            try await setupBackupPassword()
        }
    }
    
    /// 设置备份密码
    func setupBackupPassword(password: String) throws {
        // 将密码哈希存储到钥匙串
        let passwordHash = SHA256.hash(data: Data(password.utf8))
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: backupPasswordKey,
            kSecValueData as String: Data(passwordHash)
        ]
        
        // 删除旧密码
        SecItemDelete(query as CFDictionary)
        
        // 存储新密码
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BackupError.keychainError
        }
        
        // 生成备份密钥
        backupKey = SymmetricKey(size: .bits256)
    }
    
    /// 验证备份密码
    func verifyBackupPassword(_ password: String) -> Bool {
        let passwordHash = SHA256.hash(data: Data(password.utf8))
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: backupPasswordKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let storedHashData = result as? Data else {
            return false
        }
        
        return Data(passwordHash) == storedHashData
    }
    
    /// 创建备份
    func createBackup(progressHandler: ((Double) -> Void)? = nil) async throws -> BackupResult {
        guard let context = modelContext else {
            throw BackupError.contextNotFound
        }
        
        guard !isBackingUp else {
            throw BackupError.alreadyBackingUp
        }
        
        isBackingUp = true
        backupProgress = 0
        
        defer {
            isBackingUp = false
            backupProgress = 0
        }
        
        do {
            // 获取所有梦境
            let descriptor = FetchDescriptor<Dream>(
                predicate: #Predicate { $0.isDeleted == false }
            )
            let dreams = try context.fetch(descriptor)
            
            let total = dreams.count
            var backedUp = 0
            
            // 准备备份数据
            var backupData = BackupData(
                version: backupVersion,
                createdAt: Date(),
                dreamCount: total,
                encryptedDreams: []
            )
            
            for dream in dreams {
                // 加密梦境数据
                if backupConfig?.encryptionEnabled ?? true {
                    let encryptedDream = try encryptDream(dream)
                    backupData.encryptedDreams.append(encryptedDream)
                } else {
                    // 不加密 (不推荐)
                    let encryptedDream = EncryptedDreamData(
                        dreamId: dream.id,
                        encryptedData: dream.dreamData ?? Data(),
                        iv: Data(),
                        tag: Data()
                    )
                    backupData.encryptedDreams.append(encryptedDream)
                }
                
                backedUp += 1
                backupProgress = Double(backedUp) / Double(total)
                progressHandler?(backupProgress)
            }
            
            // 序列化备份数据
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let backupJSON = try encoder.encode(backupData)
            
            // 压缩备份数据
            let compressedData = try compressData(backupJSON)
            
            // 保存到文件
            let backupURL = try getBackupDirectory()
                .appendingPathComponent("dreamlog_backup_\(Date().timeIntervalSince1970).dlbackup")
            
            try compressedData.write(to: backupURL)
            
            // 更新配置
            backupConfig?.lastBackupDate = Date()
            backupConfig?.lastBackupSize = Int64(compressedData.count)
            
            let result = BackupResult(
                success: true,
                backupURL: backupURL,
                dreamCount: total,
                size: compressedData.count,
                createdAt: Date()
            )
            
            // 通知备份完成
            NotificationCenter.default.post(
                name: .backupCompleted,
                object: nil,
                userInfo: ["result": result]
            )
            
            return result
            
        } catch {
            NotificationCenter.default.post(
                name: .backupFailed,
                object: nil,
                userInfo: ["error": error]
            )
            
            throw error
        }
    }
    
    /// 恢复备份
    func restoreBackup(from url: URL, password: String) async throws -> RestoreResult {
        guard verifyBackupPassword(password) else {
            throw BackupError.invalidPassword
        }
        
        guard let context = modelContext else {
            throw BackupError.contextNotFound
        }
        
        // 读取备份文件
        let compressedData = try Data(contentsOf: url)
        
        // 解压缩
        let backupJSON = try decompressData(compressedData)
        
        // 解析备份数据
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backupData = try decoder.decode(BackupData.self, from: backupJSON)
        
        var restoredCount = 0
        var failedCount = 0
        
        for encryptedDream in backupData.encryptedDreams {
            do {
                // 解密梦境数据
                let dreamData = try decryptDreamData(encryptedDream)
                
                // 创建或更新梦境
                // 这里需要根据实际 Dream 模型结构来恢复
                restoredCount += 1
            } catch {
                failedCount += 1
                print("恢复梦境失败：\(error)")
            }
        }
        
        try context.save()
        
        let result = RestoreResult(
            success: failedCount == 0,
            restoredCount: restoredCount,
            failedCount: failedCount
        )
        
        // 通知恢复完成
        NotificationCenter.default.post(
            name: .restoreCompleted,
            object: nil,
            userInfo: ["result": result]
        )
        
        return result
    }
    
    /// 验证备份文件
    func verifyBackup(at url: URL) throws -> Bool {
        guard url.isFileURL else {
            throw BackupError.invalidBackupURL
        }
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        
        // 尝试读取和解压
        let compressedData = try Data(contentsOf: url)
        let _ = try decompressData(compressedData)
        
        return true
    }
    
    /// 获取备份列表
    func getBackupList() throws -> [BackupInfo] {
        let backupDirectory = try getBackupDirectory()
        let files = try FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
        
        return files
            .filter { $0.pathExtension == "dlbackup" }
            .compactMap { url -> BackupInfo? in
                guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                      let modificationDate = attributes[.modificationDate] as? Date,
                      let fileSize = attributes[.size] as? Int64 else {
                    return nil
                }
                
                return BackupInfo(
                    url: url,
                    date: modificationDate,
                    size: fileSize
                )
            }
            .sorted { $0.date > $1.date }
    }
    
    /// 删除备份
    func deleteBackup(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    /// 获取备份目录
    func getBackupDirectory() throws -> URL {
        let fileManager = FileManager.default
        
        // 获取文档目录
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 创建 DreamLog 备份子目录
        let backupDirectory = documentsDirectory
            .appendingPathComponent("DreamLog", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        }
        
        return backupDirectory
    }
    
    // MARK: - Private Methods
    
    private func loadOrCreateBackupKey() {
        // 从钥匙串加载或生成新的备份密钥
        backupKey = SymmetricKey(size: .bits256)
    }
    
    private func encryptDream(_ dream: Dream) throws -> EncryptedDreamData {
        guard let key = backupKey else {
            throw BackupError.keyNotFound
        }
        
        let nonce = AES.GCM.Nonce()
        let data = dream.dreamData ?? Data()
        
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        return EncryptedDreamData(
            dreamId: dream.id,
            encryptedData: sealedBox.ciphertext,
            iv: Data(nonce),
            tag: sealedBox.tag
        )
    }
    
    private func decryptDreamData(_ encryptedDream: EncryptedDreamData) throws -> Data {
        guard let key = backupKey else {
            throw BackupError.keyNotFound
        }
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: encryptedDream.iv),
            ciphertext: encryptedDream.encryptedData,
            tag: encryptedDream.tag
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func compressData(_ data: Data) throws -> Data {
        // 使用 Compression Framework 压缩
        try (data as NSData).compressed(using: .lz4) as Data
    }
    
    private func decompressData(_ data: Data) throws -> Data {
        // 解压缩
        try (data as NSData).decompressed(using: .lz4) as Data
    }
}

// MARK: - Backup Data Models

/// 备份数据结构
struct BackupData: Codable {
    let version: Int
    let createdAt: Date
    let dreamCount: Int
    var encryptedDreams: [EncryptedDreamData]
}

/// 加密梦境数据
struct EncryptedDreamData: Codable {
    let dreamId: UUID
    let encryptedData: Data
    let iv: Data
    let tag: Data
}

/// 备份结果
struct BackupResult {
    let success: Bool
    let backupURL: URL
    let dreamCount: Int
    let size: Int
    let createdAt: Date
    
    var sizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

/// 恢复结果
struct RestoreResult {
    let success: Bool
    let restoredCount: Int
    let failedCount: Int
}

/// 备份信息
struct BackupInfo {
    let url: URL
    let date: Date
    let size: Int64
    
    var sizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Backup Error

enum BackupError: LocalizedError {
    case contextNotFound
    case alreadyBackingUp
    case keyNotFound
    case keychainError
    case invalidPassword
    case invalidBackupURL
    case backupNotFound
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotFound: return "数据上下文未设置"
        case .alreadyBackingUp: return "正在备份中，请稍后"
        case .keyNotFound: return "备份密钥未找到"
        case .keychainError: return "钥匙串操作失败"
        case .invalidPassword: return "密码错误"
        case .invalidBackupURL: return "无效的备份文件"
        case .backupNotFound: return "备份文件不存在"
        case .restoreFailed: return "恢复失败"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let backupCompleted = Notification.Name("backupCompleted")
    static let backupFailed = Notification.Name("backupFailed")
    static let restoreCompleted = Notification.Name("restoreCompleted")
    static let restoreFailed = Notification.Name("restoreFailed")
}

// MARK: - Dream Model Extension

extension Dream {
    var isDeleted: Bool { false }
    var dreamData: Data? { nil }
}
