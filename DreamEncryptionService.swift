//
//  DreamEncryptionService.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import CryptoKit
import Security

/// 梦境加密服务
final class DreamEncryptionService {
    
    // MARK: - Singleton
    
    static let shared = DreamEncryptionService()
    
    // MARK: - Constants
    
    private let encryptionVersion = 1
    private let keychainServiceName = "com.dreamlog.encryption"
    private let masterKeyName = "dreamlog.master.key"
    private let keyTagKey = "com.dreamlog.keytag"
    
    // MARK: - Properties
    
    private var masterKey: SymmetricKey?
    
    // MARK: - Initialization
    
    private init() {
        loadOrCreateMasterKey()
    }
    
    // MARK: - Public Methods
    
    /// 加密梦境内容
    func encryptDreamContent(_ content: String, title: String = "") throws -> EncryptedData {
        guard let masterKey = masterKey else {
            throw EncryptionError.keyNotFound
        }
        
        // 生成随机 nonce (IV)
        let nonce = AES.GCM.Nonce()
        
        // 准备明文数据
        let plainText = "\(title)|\(content)"
        let plainData = Data(plainText.utf8)
        
        // 加密
        let sealedBox = try AES.GCM.seal(plainData, using: masterKey, nonce: nonce)
        
        return EncryptedData(
            ciphertext: sealedBox.ciphertext,
            nonce: Data(nonce),
            tag: sealedBox.tag,
            version: encryptionVersion
        )
    }
    
    /// 解密梦境内容
    func decryptDreamContent(_ encryptedData: EncryptedData) throws -> DecryptedContent {
        guard let masterKey = masterKey else {
            throw EncryptionError.keyNotFound
        }
        
        // 构建 sealed box
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: encryptedData.nonce),
            ciphertext: encryptedData.ciphertext,
            tag: encryptedData.tag
        )
        
        // 解密
        let plainData = try AES.GCM.open(sealedBox, using: masterKey)
        guard let plainText = String(data: plainData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        // 分离标题和内容
        let components = plainText.split(separator: "|", maxSplits: 1)
        let title = components.count > 0 ? String(components[0]) : ""
        let content = components.count > 1 ? String(components[1]) : ""
        
        return DecryptedContent(title: title, content: content)
    }
    
    /// 加密梦境标题
    func encryptTitle(_ title: String) throws -> Data {
        guard let masterKey = masterKey else {
            throw EncryptionError.keyNotFound
        }
        
        let nonce = AES.GCM.Nonce()
        let plainData = Data(title.utf8)
        
        let sealedBox = try AES.GCM.seal(plainData, using: masterKey, nonce: nonce)
        
        // 将 nonce 和密文组合存储
        var result = Data()
        result.append(Data(nonce))
        result.append(sealedBox.ciphertext)
        result.append(sealedBox.tag)
        
        return result
    }
    
    /// 解密梦境标题
    func decryptTitle(_ data: Data) throws -> String {
        guard let masterKey = masterKey else {
            throw EncryptionError.keyNotFound
        }
        
        // 提取 nonce、密文和 tag
        let nonceSize = AES.GCM.Nonce.byteCount
        let tagSize = 16 // AES.GCM tag size
        
        guard data.count >= nonceSize + tagSize else {
            throw EncryptionError.invalidData
        }
        
        let nonceData = data.prefix(nonceSize)
        let tag = data.suffix(tagSize)
        let ciphertext = data.dropFirst(nonceSize).dropLast(tagSize)
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonceData),
            ciphertext: Data(ciphertext),
            tag: Data(tag)
        )
        
        let plainData = try AES.GCM.open(sealedBox, using: masterKey)
        guard let title = String(data: plainData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        return title
    }
    
    /// 设置主密钥 (用户密码派生)
    func setMasterKeyFromPassword(_ password: String, salt: Data? = nil) throws {
        let actualSalt = salt ?? generateRandomSalt()
        
        // 使用 PBKDF2 从密码派生密钥
        let derivedKey = try deriveKeyFromPassword(password, salt: actualSalt)
        masterKey = SymmetricKey(data: derivedKey)
        
        // 保存 salt 到 keychain (用于后续密钥派生)
        try saveSaltToKeychain(actualSalt)
    }
    
    /// 从 Keychain 加载主密钥
    func loadMasterKeyFromPassword(_ password: String) throws -> Bool {
        guard let salt = loadSaltFromKeychain() else {
            return false
        }
        
        let derivedKey = try deriveKeyFromPassword(password, salt: salt)
        masterKey = SymmetricKey(data: derivedKey)
        
        return true
    }
    
    /// 生成随机盐
    func generateRandomSalt() -> Data {
        var salt = Data(count: 16)
        let result = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 16, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            fatalError("Failed to generate random salt")
        }
        
        return salt
    }
    
    /// 更改加密密码
    func changePassword(oldPassword: String, newPassword: String) throws {
        // 验证旧密码
        let oldVerified = try loadMasterKeyFromPassword(oldPassword)
        guard oldVerified else {
            throw EncryptionError.incorrectPassword
        }
        
        // 生成新盐并设置新密钥
        let newSalt = generateRandomSalt()
        try setMasterKeyFromPassword(newPassword, salt: newSalt)
    }
    
    /// 移除加密
    func removeEncryption() {
        masterKey = nil
        deleteSaltFromKeychain()
    }
    
    /// 检查是否已启用加密
    var isEncryptionEnabled: Bool {
        return masterKey != nil && loadSaltFromKeychain() != nil
    }
    
    // MARK: - Private Methods
    
    private func loadOrCreateMasterKey() {
        // 尝试从 keychain 加载现有密钥
        if let existingKey = loadKeyFromKeychain() {
            masterKey = existingKey
            return
        }
        
        // 生成新密钥
        masterKey = SymmetricKey(size: .bits256)
        
        // 保存到 keychain
        try? saveKeyToKeychain(masterKey!)
    }
    
    private func deriveKeyFromPassword(_ password: String, salt: Data) throws -> Data {
        // 使用 PBKDF2 派生 256 位密钥
        let passwordData = Data(password.utf8)
        var derivedKey = Data(count: 32) // 256 bits
        
        let result = derivedKey.withUnsafeMutableBytes { keyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        password,
                        passwordData.count,
                        saltBytes.baseAddress!,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        100000, // iterations
                        keyBytes.baseAddress!,
                        32
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw EncryptionError.keyDerivationFailed
        }
        
        return derivedKey
    }
    
    // MARK: - Keychain Operations
    
    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: masterKeyName,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 先删除旧密钥
        SecItemDelete(query as CFDictionary)
        
        // 添加新密钥
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    private func loadKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: masterKeyName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func saveSaltToKeychain(_ salt: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: "salt",
            kSecValueData as String: salt,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    private func loadSaltFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: "salt",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let salt = result as? Data else {
            return nil
        }
        
        return salt
    }
    
    private func deleteSaltFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: "salt"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Data Models

/// 加密数据
struct EncryptedData {
    let ciphertext: Data
    let nonce: Data
    let tag: Data
    let version: Int
}

/// 解密内容
struct DecryptedContent {
    let title: String
    let content: String
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case incorrectPassword
    case keyDerivationFailed
    case keychainError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .keyNotFound:
            return "加密密钥未找到"
        case .encryptionFailed:
            return "加密失败"
        case .decryptionFailed:
            return "解密失败"
        case .invalidData:
            return "无效的加密数据"
        case .incorrectPassword:
            return "密码错误"
        case .keyDerivationFailed:
            return "密钥派生失败"
        case .keychainError(let status):
            return "Keychain 错误：\(status)"
        }
    }
}

// MARK: - String Extension for Encryption

extension String {
    func encrypted() throws -> EncryptedData {
        try DreamEncryptionService.shared.encryptDreamContent(self)
    }
    
    func decrypted(from encryptedData: EncryptedData) throws -> String {
        let decrypted = try DreamEncryptionService.shared.decryptDreamContent(encryptedData)
        return decrypted.content
    }
}
