//
//  DreamCloudBackupService.swift
//  DreamLog - Phase 37: Cloud Backup Integration
//
//  Created by DreamLog Team on 2026-03-14.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData
import CryptoKit

// MARK: - Cloud Backup Service Actor

@ModelActor
actor DreamCloudBackupService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let fileManager: FileManager
    private let backupDirectory: URL
    
    // OAuth 配置 (实际应用中应从安全配置读取)
    private let oauthConfigs: [CloudProvider: OAuthConfig] = [
        .googleDrive: OAuthConfig(
            clientId: "YOUR_GOOGLE_CLIENT_ID",
            clientSecret: "YOUR_GOOGLE_CLIENT_SECRET",
            redirectUri: "dreamlog://oauth/google",
            authUrl: "https://accounts.google.com/o/oauth2/v2/auth",
            tokenUrl: "https://oauth2.googleapis.com/token",
            scopes: ["https://www.googleapis.com/auth/drive.file"]
        ),
        .dropbox: OAuthConfig(
            clientId: "YOUR_DROPBOX_CLIENT_ID",
            clientSecret: "YOUR_DROPBOX_CLIENT_SECRET",
            redirectUri: "dreamlog://oauth/dropbox",
            authUrl: "https://www.dropbox.com/oauth2/authorize",
            tokenUrl: "https://api.dropboxapi.com/oauth2/token",
            scopes: []
        ),
        .onedrive: OAuthConfig(
            clientId: "YOUR_ONEDRIVE_CLIENT_ID",
            clientSecret: "YOUR_ONEDRIVE_CLIENT_SECRET",
            redirectUri: "dreamlog://oauth/onedrive",
            authUrl: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
            tokenUrl: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
            scopes: ["Files.ReadWrite.AppFolder"]
        )
    ]
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.fileManager = FileManager.default
        self.backupDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CloudBackups", isDirectory: true)
        
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Configuration Management
    
    /// 获取所有云备份配置
    func getAllConfigs() -> [CloudBackupConfig] {
        let descriptor = FetchDescriptor<CloudBackupConfig>()
        return try? modelContext.fetch(descriptor) ?? [] ?? []
    }
    
    /// 获取指定提供商的配置
    func getConfig(for provider: CloudProvider) -> CloudBackupConfig? {
        let descriptor = FetchDescriptor<CloudBackupConfig>(
            predicate: #Predicate { $0.provider == provider.rawValue }
        )
        return try? modelContext.fetch(descriptor)?.first ?? nil
    }
    
    /// 创建新的云备份配置
    func createConfig(for provider: CloudProvider, accountName: String = "") -> CloudBackupConfig {
        let config = CloudBackupConfig(
            provider: provider,
            accountName: accountName,
            autoBackupEnabled: false
        )
        modelContext.insert(config)
        try? modelContext.save()
        return config
    }
    
    /// 更新配置
    func updateConfig(_ config: CloudBackupConfig) {
        config.updatedAt = Date()
        try? modelContext.save()
    }
    
    /// 删除配置
    func deleteConfig(_ config: CloudBackupConfig) {
        modelContext.delete(config)
        try? modelContext.save()
    }
    
    // MARK: - OAuth Authentication
    
    /// 获取 OAuth 授权 URL
    func getOAuthURL(for provider: CloudProvider) -> URL? {
        guard let oauthConfig = oauthConfigs[provider] else { return nil }
        
        var components = URLComponents(string: oauthConfig.authUrl)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: oauthConfig.clientId),
            URLQueryItem(name: "redirect_uri", value: oauthConfig.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: oauthConfig.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: UUID().uuidString),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        return components?.url
    }
    
    /// 处理 OAuth 回调，交换令牌
    func handleOAuthCallback(url: URL, for provider: CloudProvider) async throws -> CloudBackupConfig {
        guard let oauthConfig = oauthConfigs[provider] else {
            throw CloudBackupError.invalidProvider
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw CloudBackupError.invalidCallback
        }
        
        // 交换访问令牌
        let tokenResponse = try await exchangeToken(code: code, config: oauthConfig, provider: provider)
        
        // 获取或创建配置
        var config = getConfig(for: provider) ?? createConfig(for: provider)
        
        // 更新令牌信息
        config.accessToken = tokenResponse.accessToken
        config.refreshToken = tokenResponse.refreshToken
        config.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn ?? 3600))
        config.isConnected = true
        config.updatedAt = Date()
        
        // 获取账户信息
        let accountInfo = try await fetchAccountInfo(provider: provider, accessToken: tokenResponse.accessToken)
        config.accountName = accountInfo.name
        
        // 获取存储信息
        let storageInfo = try await fetchStorageInfo(provider: provider, accessToken: tokenResponse.accessToken)
        config.storageUsed = storageInfo.used
        config.storageQuota = storageInfo.total
        
        try? modelContext.save()
        
        return config
    }
    
    /// 交换 OAuth 令牌
    private func exchangeToken(code: String, config: OAuthConfig, provider: CloudProvider) async throws -> OAuthTokenResponse {
        guard let url = URL(string: config.tokenUrl) else {
            throw CloudBackupError.invalidConfiguration("Invalid token URL for \(provider)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(config.redirectUri)&client_id=\(config.clientId)&client_secret=\(config.clientSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.tokenExchangeFailed
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    /// 刷新访问令牌
    func refreshAccessToken(for config: CloudBackupConfig) async throws -> String {
        guard let provider = CloudProvider(rawValue: config.provider),
              let oauthConfig = oauthConfigs[provider],
              let refreshToken = config.refreshToken else {
            throw CloudBackupError.noRefreshToken
        }
        
        guard let url = URL(string: oauthConfig.tokenUrl) else {
            throw CloudBackupError.invalidConfiguration("Invalid token URL for \(provider)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(oauthConfig.clientId)&client_secret=\(oauthConfig.clientSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.tokenRefreshFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        
        // 更新配置
        config.accessToken = tokenResponse.accessToken
        config.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn ?? 3600))
        if let newRefreshToken = tokenResponse.refreshToken {
            config.refreshToken = newRefreshToken
        }
        config.updatedAt = Date()
        try? modelContext.save()
        
        return tokenResponse.accessToken
    }
    
    /// 断开连接
    func disconnect(_ config: CloudBackupConfig) async {
        config.isConnected = false
        config.accessToken = nil
        config.refreshToken = nil
        config.tokenExpiry = nil
        config.updatedAt = Date()
        try? modelContext.save()
    }
    
    // MARK: - Backup Operations
    
    /// 执行云备份
    func performBackup(
        config: CloudBackupConfig,
        options: CloudBackupOptions = CloudBackupOptions()
    ) async throws -> CloudBackupRecord {
        guard config.isConnected, let accessToken = config.accessToken else {
            throw CloudBackupError.notConnected
        }
        
        guard let provider = CloudProvider(rawValue: config.provider) else {
            throw CloudBackupError.invalidProvider
        }
        
        // 准备备份数据
        let backupData = try await prepareBackupData(options: options)
        
        // 压缩数据
        let compressedData = options.compressData ? try compressData(backupData.jsonData) : backupData.jsonData
        
        // 加密数据
        let finalData: Data
        let isEncrypted: Bool
        if options.encryptData, let password = options.encryptionPassword {
            finalData = try encryptData(compressedData, password: password)
            isEncrypted = true
        } else {
            finalData = compressedData
            isEncrypted = false
        }
        
        // 生成文件名
        let fileName = generateFileName(provider: provider, backupType: options.backupType)
        let cloudPath = "/DreamLog/Backups/\(fileName)"
        
        // 上传到云端
        let uploadResult = try await uploadToCloud(
            provider: provider,
            accessToken: accessToken,
            data: finalData,
            fileName: fileName,
            path: cloudPath
        )
        
        // 计算校验和
        let checksum = SHA256.hash(data: finalData).compactMap { String(format: "%02x", $0) }.joined()
        
        // 创建备份记录
        let record = CloudBackupRecord(
            configId: config.id,
            provider: provider,
            fileName: fileName,
            cloudFileId: uploadResult.fileId,
            cloudFilePath: cloudPath,
            backupType: options.backupType,
            dreamCount: backupData.dreamCount,
            fileSize: Int64(finalData.count),
            includesAudio: options.includeAudio,
            includesImages: options.includeImages,
            isEncrypted: isEncrypted
        )
        record.checksum = checksum
        modelContext.insert(record)
        
        // 更新配置
        config.lastBackupDate = Date()
        config.nextBackupDate = calculateNextBackupDate(frequency: config.autoBackupFrequency)
        config.totalBackups += 1
        config.storageUsed += Int64(finalData.count)
        config.updatedAt = Date()
        
        try? modelContext.save()
        
        return record
    }
    
    /// 准备备份数据
    private func prepareBackupData(options: CloudBackupOptions) async throws -> BackupData {
        let descriptor = FetchDescriptor<Dream>(
            predicate: options.dateRange == .all ? nil : createDatePredicate(for: options.dateRange)
        )
        let dreams = try modelContext.fetch(descriptor) ?? []
        
        var backupDreams: [BackupDream] = []
        
        for dream in dreams {
            var backupDream = BackupDream(
                id: dream.id,
                title: dream.title,
                content: dream.content,
                createdAt: dream.createdAt,
                updatedAt: dream.updatedAt,
                tags: dream.tags,
                emotions: dream.emotions.map { $0.rawValue },
                clarity: dream.clarity,
                intensity: dream.intensity,
                isLucid: dream.isLucid
            )
            
            if options.includeAIAnalysis {
                backupDream.aiAnalysis = dream.aiAnalysis
            }
            
            // 位置 - 暂不支持
            // if options.includeLocations, let location = dream.location {
            //     backupDream.location = BackupLocation(
            //         latitude: location.latitude,
            //         longitude: location.longitude,
            //         name: dream.locationName
            //     )
            // }
            
            // 处理音频 - 暂不支持
            // if options.includeAudio, let audioPath = dream.audioPath {
            //     let audioUrl = URL(fileURLWithPath: audioPath)
            //     if fileManager.fileExists(atPath: audioUrl.path) {
            //         let audioData = try Data(contentsOf: audioUrl)
            //         let base64Audio = audioData.base64EncodedString()
            //         backupDream.audioData = base64Audio
            //     }
            // }
            
            // 处理图片 - 暂不支持
            // if options.includeImages, !dream.images.isEmpty {
            //     var imageData: [String] = []
            //     for imagePath in dream.images {
            //         let imageUrl = URL(fileURLWithPath: imagePath)
            //         if fileManager.fileExists(atPath: imageUrl.path) {
            //             let imgData = try Data(contentsOf: imageUrl)
            //             imageData.append(imgData.base64EncodedString())
            //         }
            //     }
            //     backupDream.imageData = imageData
            // }
            
            backupDreams.append(backupDream)
        }
        
        let backupContainer = BackupContainer(
            version: "1.0",
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            dreamCount: backupDreams.count,
            dreams: backupDreams
        )
        
        let jsonData = try JSONEncoder().encode(backupContainer)
        
        return BackupData(jsonData: jsonData, dreamCount: backupDreams.count)
    }
    
    /// 上传到云端
    private func uploadToCloud(
        provider: CloudProvider,
        accessToken: String,
        data: Data,
        fileName: String,
        path: String
    ) async throws -> UploadResult {
        switch provider {
        case .googleDrive:
            return try await uploadToGoogleDrive(accessToken: accessToken, data: data, fileName: fileName, path: path)
        case .dropbox:
            return try await uploadToDropbox(accessToken: accessToken, data: data, fileName: fileName, path: path)
        case .onedrive:
            return try await uploadToOneDrive(accessToken: accessToken, data: data, fileName: fileName, path: path)
        case .webdav:
            throw CloudBackupError.webdavNotConfigured
        }
    }
    
    /// 上传到 Google Drive
    private func uploadToGoogleDrive(accessToken: String, data: Data, fileName: String, path: String) async throws -> UploadResult {
        guard let uploadURL = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart") else {
            throw CloudBackupError.uploadFailed("Invalid Google Drive upload URL")
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Metadata
        guard let metadata = """
        --\(boundary)\r\n
        Content-Type: application/json; charset=UTF-8\r\n\r\n
        {"name":"\(fileName)","parents":["appfolder"]}\r\n
        --\(boundary)\r\n
        Content-Type: application/octet-stream\r\n\r\n
        """.data(using: .utf8),
        let boundaryEnd = "\r\n--\(boundary)--\r\n".data(using: .utf8) else {
            throw CloudBackupError.uploadFailed
        }
        body.append(metadata)
        body.append(data)
        body.append(boundaryEnd)
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.uploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(GoogleDriveUploadResponse.self, from: responseData)
        
        return UploadResult(fileId: uploadResponse.id, downloadUrl: uploadResponse.webViewLink)
    }
    
    /// 上传到 Dropbox
    private func uploadToDropbox(accessToken: String, data: Data, fileName: String, path: String) async throws -> UploadResult {
        guard let uploadURL = URL(string: "https://content.dropboxapi.com/2/files/upload") else {
            throw CloudBackupError.uploadFailed("Invalid Dropbox upload URL")
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let uploadArg: [String: Any] = [
            "path": path,
            "mode": "overwrite",
            "autorename": true
        ]
        let uploadArgJson = try JSONSerialization.data(withJSONObject: uploadArg)
        let uploadArgBase64 = uploadArgJson.base64EncodedString().replacingOccurrences(of: "\n", with: "")
        request.setValue(uploadArgBase64, forHTTPHeaderField: "Dropbox-API-Arg")
        
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.uploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(DropboxUploadResponse.self, from: responseData)
        
        return UploadResult(fileId: uploadResponse.id, downloadUrl: nil)
    }
    
    /// 上传到 OneDrive
    private func uploadToOneDrive(accessToken: String, data: Data, fileName: String, path: String) async throws -> UploadResult {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        guard let uploadURL = URL(string: "https://graph.microsoft.com/v1.0/me/drive/special/appfolder:\(encodedPath):/content") else {
            throw CloudBackupError.uploadFailed("Invalid OneDrive upload URL")
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw CloudBackupError.uploadFailed
        }
        
        let uploadResponse = try JSONDecoder().decode(OneDriveUploadResponse.self, from: responseData)
        
        return UploadResult(fileId: uploadResponse.id, downloadUrl: uploadResponse.webUrl)
    }
    
    // MARK: - Restore Operations
    
    /// 从云端恢复备份
    func restoreFromBackup(record: CloudBackupRecord, password: String? = nil) async throws {
        guard let config = getConfig(for: CloudProvider(rawValue: record.provider) ?? .googleDrive),
              let accessToken = config.accessToken else {
            throw CloudBackupError.notConnected
        }
        
        // 下载文件
        let data = try await downloadFromCloud(
            provider: CloudProvider(rawValue: record.provider) ?? .googleDrive,
            accessToken: accessToken,
            fileId: record.cloudFileId
        )
        
        // 解密数据
        let decryptedData: Data
        if record.isEncrypted, let pwd = password {
            decryptedData = try decryptData(data, password: pwd)
        } else {
            decryptedData = data
        }
        
        // 解压数据
        let decompressedData = try decompressData(decryptedData)
        
        // 解析备份
        let backupContainer = try JSONDecoder().decode(BackupContainer.self, from: decompressedData)
        
        // 恢复梦境
        for backupDream in backupContainer.dreams {
            let dream = Dream(
                title: backupDream.title,
                content: backupDream.content,
                createdAt: backupDream.createdAt,
                tags: backupDream.tags,
                emotions: backupDream.emotions.compactMap { Emotion(rawValue: $0) },
                clarity: backupDream.clarity,
                intensity: backupDream.intensity,
                isLucid: backupDream.isLucid
            )
            dream.id = backupDream.id
            dream.updatedAt = backupDream.updatedAt
            dream.aiAnalysis = backupDream.aiAnalysis
            
            // 恢复位置 - 暂不支持
            // if let location = backupDream.location {
            //     dream.location = DreamLocation(latitude: location.latitude, longitude: location.longitude)
            //     dream.locationName = location.name
            // }
            
            // 恢复音频 - 暂不支持
            // if let audioBase64 = backupDream.audioData,
            //    let audioData = Data(base64Encoded: audioBase64) {
            //     let audioPath = backupDirectory.appendingPathComponent("audio/\(dream.id.uuidString).m4a")
            //     try? fileManager.createDirectory(at: audioPath.deletingLastPathComponent(), withIntermediateDirectories: true)
            //     try audioData.write(to: audioPath)
            //     dream.audioPath = audioPath.path
            // }
            
            // 恢复图片 - 暂不支持
            // if let imageBase64Array = backupDream.imageData {
            //     var imagePaths: [String] = []
            //     for (index, base64) in imageBase64Array.enumerated() {
            //         if let imgData = Data(base64Encoded: base64) {
            //             let imagePath = backupDirectory.appendingPathComponent("images/\(dream.id.uuidString)_\(index).jpg")
            //             try? fileManager.createDirectory(at: imagePath.deletingLastPathComponent(), withIntermediateDirectories: true)
            //             try imgData.write(to: imagePath)
            //             imagePaths.append(imagePath.path)
            //         }
            //     }
            //     dream.images = imagePaths
            // }
            
            modelContext.insert(dream)
        }
        
        try? modelContext.save()
    }
    
    /// 从云端下载文件
    private func downloadFromCloud(provider: CloudProvider, accessToken: String, fileId: String) async throws -> Data {
        switch provider {
        case .googleDrive:
            return try await downloadFromGoogleDrive(accessToken: accessToken, fileId: fileId)
        case .dropbox:
            return try await downloadFromDropbox(accessToken: accessToken, fileId: fileId)
        case .onedrive:
            return try await downloadFromOneDrive(accessToken: accessToken, fileId: fileId)
        case .webdav:
            throw CloudBackupError.webdavNotConfigured
        }
    }
    
    private func downloadFromGoogleDrive(accessToken: String, fileId: String) async throws -> Data {
        guard let downloadURL = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media") else {
            throw CloudBackupError.downloadFailed("Invalid Google Drive download URL")
        }
        var request = URLRequest(url: downloadURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.downloadFailed
        }
        
        return data
    }
    
    private func downloadFromDropbox(accessToken: String, fileId: String) async throws -> Data {
        guard let downloadURL = URL(string: "https://content.dropboxapi.com/2/files/download") else {
            throw CloudBackupError.downloadFailed("Invalid Dropbox download URL")
        }
        var request = URLRequest(url: downloadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let downloadArg: [String: Any] = ["path": fileId]
        let downloadArgJson = try JSONSerialization.data(withJSONObject: downloadArg)
        let downloadArgBase64 = downloadArgJson.base64EncodedString().replacingOccurrences(of: "\n", with: "")
        request.setValue(downloadArgBase64, forHTTPHeaderField: "Dropbox-API-Arg")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.downloadFailed
        }
        
        return data
    }
    
    private func downloadFromOneDrive(accessToken: String, fileId: String) async throws -> Data {
        guard let downloadURL = URL(string: "https://graph.microsoft.com/v1.0/me/drive/items/\(fileId)/content") else {
            throw CloudBackupError.downloadFailed("Invalid OneDrive download URL")
        }
        var request = URLRequest(url: downloadURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.downloadFailed
        }
        
        return data
    }
    
    // MARK: - Utility Functions
    
    /// 获取备份历史
    func getBackupHistory(config: CloudBackupConfig, limit: Int = 20) -> [CloudBackupRecord] {
        let descriptor = FetchDescriptor<CloudBackupRecord>(
            predicate: #Predicate { $0.configId == config.id },
            sortBy: [SortDescriptor(\.uploadDate, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor) ?? [] ?? []
    }
    
    /// 获取统计信息
    func getStatistics() -> CloudBackupStatistics {
        let configs = getAllConfigs()
        let connectedConfigs = configs.filter { $0.isConnected }
        
        let allRecords: [CloudBackupRecord] = {
            let descriptor = FetchDescriptor<CloudBackupRecord>()
            return try? modelContext.fetch(descriptor) ?? [] ?? []
        }()
        
        let totalBackups = allRecords.count
        let successfulBackups = allRecords.filter { $0.status == .completed }.count
        let failedBackups = allRecords.filter { $0.status == .failed }.count
        let totalSize = allRecords.reduce(0) { $0 + $1.fileSize }
        let lastBackup = allRecords.max(by: { $0.uploadDate < $1.uploadDate })?.uploadDate
        let providers = Set(configs.compactMap { CloudProvider(rawValue: $0.provider) })
        
        return CloudBackupStatistics(
            totalConfigs: configs.count,
            connectedConfigs: connectedConfigs.count,
            totalBackups: totalBackups,
            totalSizeBytes: totalSize,
            successfulBackups: successfulBackups,
            failedBackups: failedBackups,
            lastBackupDate: lastBackup,
            nextScheduledBackup: connectedConfigs.compactMap { $0.nextBackupDate }.min(),
            providers: Array(providers)
        )
    }
    
    /// 删除云备份
    func deleteBackup(_ record: CloudBackupRecord) async throws {
        guard let config = getConfig(for: CloudProvider(rawValue: record.provider) ?? .googleDrive),
              let accessToken = config.accessToken else {
            throw CloudBackupError.notConnected
        }
        
        // 从云端删除
        try await deleteFromCloud(
            provider: CloudProvider(rawValue: record.provider) ?? .googleDrive,
            accessToken: accessToken,
            fileId: record.cloudFileId
        )
        
        // 删除本地记录
        modelContext.delete(record)
        try? modelContext.save()
    }
    
    private func deleteFromCloud(provider: CloudProvider, accessToken: String, fileId: String) async throws {
        switch provider {
        case .googleDrive:
            guard let deleteURL = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)") else {
                throw CloudBackupError.deleteFailed("Invalid Google Drive delete URL")
            }
            var request = URLRequest(url: deleteURL)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            _ = try await URLSession.shared.data(for: request)
            
        case .dropbox:
            guard let deleteURL = URL(string: "https://api.dropboxapi.com/2/files/delete_v2") else {
                throw CloudBackupError.deleteFailed("Invalid Dropbox delete URL")
            }
            var request = URLRequest(url: deleteURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let deleteArg: [String: Any] = ["path": fileId]
            let deleteArgJson = try JSONSerialization.data(withJSONObject: deleteArg)
            request.setValue(deleteArgJson.base64EncodedString(), forHTTPHeaderField: "Dropbox-API-Arg")
            _ = try await URLSession.shared.data(for: request)
            
        case .onedrive:
            guard let deleteURL = URL(string: "https://graph.microsoft.com/v1.0/me/drive/items/\(fileId)") else {
                throw CloudBackupError.deleteFailed("Invalid OneDrive delete URL")
            }
            var request = URLRequest(url: deleteURL)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            _ = try await URLSession.shared.data(for: request)
            
        case .webdav:
            throw CloudBackupError.webdavNotConfigured
        }
    }
    
    // MARK: - Data Compression & Encryption
    
    private func compressData(_ data: Data) throws -> Data {
        try (data as NSData).compressed(using: .lzma) as Data
    }
    
    private func decompressData(_ data: Data) throws -> Data {
        try (data as NSData).decompressed(using: .lzma) as Data
    }
    
    private func encryptData(_ data: Data, password: String) throws -> Data {
        let key = SHA256.hash(data: Data(password.utf8))
        let sealedBox = try AES.GCM.seal(data, using: SymmetricKey(data: Data(key)))
        return sealedBox.combined ?? data
    }
    
    private func decryptData(_ data: Data, password: String) throws -> Data {
        let key = SHA256.hash(data: Data(password.utf8))
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: SymmetricKey(data: Data(key)))
    }
    
    // MARK: - Helper Functions
    
    private func generateFileName(provider: CloudProvider, backupType: BackupType) -> String {
        let date = DateFormatter()
        date.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = date.string(from: Date())
        let typePrefix = backupType == .full ? "full" : backupType == .incremental ? "incr" : "sel"
        return "dreamlog_\(provider.rawValue)_\(typePrefix)_\(timestamp).dreamlog"
    }
    
    private func createDatePredicate(for dateRange: DateRange) -> Predicate<Dream>? {
        let now = Date()
        switch dateRange {
        case .all:
            return nil
        case .last7Days:
            guard let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) else {
                return nil
            }
            return #Predicate { $0.createdAt >= startDate }
        case .last30Days:
            guard let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now) else {
                return nil
            }
            return #Predicate { $0.createdAt >= startDate }
        case .last3Months:
            guard let startDate = Calendar.current.date(byAdding: .month, value: -3, to: now) else {
                return nil
            }
            return #Predicate { $0.createdAt >= startDate }
        case .lastYear:
            guard let startDate = Calendar.current.date(byAdding: .year, value: -1, to: now) else {
                return nil
            }
            return #Predicate { $0.createdAt >= startDate }
        case .custom:
            return nil
        }
    }
    
    private func calculateNextBackupDate(frequency: BackupFrequency) -> Date? {
        guard frequency != .manual else { return nil }
        return Date().addingTimeInterval(frequency.intervalSeconds)
    }
    
    private func fetchAccountInfo(provider: CloudProvider, accessToken: String) async throws -> (name: String, email: String?) {
        // 简化实现，实际应根据不同提供商调用对应的 API
        return (name: "User", email: nil)
    }
    
    private func fetchStorageInfo(provider: CloudProvider, accessToken: String) async throws -> CloudStorageInfo {
        // 简化实现，返回默认值
        return CloudStorageInfo(used: 0, total: 15 * 1024 * 1024 * 1024, available: 15 * 1024 * 1024 * 1024, percentUsed: 0)
    }
}

// MARK: - Supporting Types

struct OAuthConfig {
    let clientId: String
    let clientSecret: String
    let redirectUri: String
    let authUrl: String
    let tokenUrl: String
    let scopes: [String]
}

struct BackupData {
    let jsonData: Data
    let dreamCount: Int
}

struct BackupDream: Codable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    var tags: [String]
    var emotions: [String]
    let clarity: Int
    let intensity: Int
    let isLucid: Bool
    var aiAnalysis: String?
    var location: BackupLocation?
    var audioData: String?
    var imageData: [String]?
}

struct BackupLocation: Codable {
    let latitude: Double
    let longitude: Double
    let name: String?
}

struct BackupContainer: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let dreamCount: Int
    let dreams: [BackupDream]
}

struct UploadResult {
    let fileId: String
    let downloadUrl: String?
}

// Google Drive API Responses
struct GoogleDriveUploadResponse: Codable {
    let id: String
    let name: String
    let webViewLink: String?
}

struct DropboxUploadResponse: Codable {
    let id: String
    let name: String
    let pathDisplay: String
}

struct OneDriveUploadResponse: Codable {
    let id: String
    let name: String
    let webUrl: String?
}

// MARK: - Error Types

enum CloudBackupError: LocalizedError {
    case invalidProvider
    case notConnected
    case noRefreshToken
    case tokenExchangeFailed
    case tokenRefreshFailed
    case invalidCallback
    case uploadFailed
    case downloadFailed
    case webdavNotConfigured
    case encryptionFailed
    case decryptionFailed
    case compressionFailed
    case decompressionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidProvider: return "无效的云服务提供商"
        case .notConnected: return "未连接到云服务"
        case .noRefreshToken: return "缺少刷新令牌"
        case .tokenExchangeFailed: return "令牌交换失败"
        case .tokenRefreshFailed: return "令牌刷新失败"
        case .invalidCallback: return "无效的 OAuth 回调"
        case .uploadFailed: return "上传失败"
        case .downloadFailed: return "下载失败"
        case .webdavNotConfigured: return "WebDAV 未配置"
        case .encryptionFailed: return "加密失败"
        case .decryptionFailed: return "解密失败"
        case .compressionFailed: return "压缩失败"
        case .decompressionFailed: return "解压失败"
        }
    }
}
