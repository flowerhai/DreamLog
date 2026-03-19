//
//  DreamCloudBackupProvidersService.swift
//  DreamLog
//
//  Phase 62: Dream Cloud Backup Enhancement
//  Core service for Google Drive, Dropbox, and OneDrive backup integration
//

import Foundation
import SwiftData

// MARK: - Cloud Backup Provider Service

@ModelActor
actor DreamCloudBackupProvidersService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // OAuth configuration
    private let googleClientId = "YOUR_GOOGLE_CLIENT_ID"
    private let googleClientSecret = "YOUR_GOOGLE_CLIENT_SECRET"
    private let googleRedirectUri = "com.dreamlog.app:/oauth2callback"
    
    private let dropboxAppKey = "YOUR_DROPBOX_APP_KEY"
    private let dropboxAppSecret = "YOUR_DROPBOX_APP_SECRET"
    private let dropboxRedirectUri = "com.dreamlog.app:/dropbox/oauth2"
    
    private let onedriveClientId = "YOUR_ONEDRIVE_CLIENT_ID"
    private let onedriveClientSecret = "YOUR_ONEDRIVE_CLIENT_SECRET"
    private let onedriveRedirectUri = "com.dreamlog.app:/oauth2/onedrive"
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Account Management
    
    /// Get all connected backup accounts
    func getConnectedAccounts() async throws -> [CloudBackupAccount] {
        let descriptor = FetchDescriptor<CloudBackupAccount>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get account by provider
    func getAccount(by provider: CloudBackupProvider) async throws -> CloudBackupAccount? {
        let descriptor = FetchDescriptor<CloudBackupAccount>(
            predicate: #Predicate<CloudBackupAccount> { $0.provider == provider.rawValue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let accounts = try modelContext.fetch(descriptor)
        return accounts.first
    }
    
    /// Get account by ID
    func getAccount(by id: UUID) async throws -> CloudBackupAccount? {
        let descriptor = FetchDescriptor<CloudBackupAccount>(
            predicate: #Predicate<CloudBackupAccount> { $0.id == id }
        )
        let accounts = try modelContext.fetch(descriptor)
        return accounts.first
    }
    
    /// Save or update account
    func saveAccount(_ account: CloudBackupAccount) async throws {
        modelContext.insert(account)
        try modelContext.save()
    }
    
    /// Delete account
    func deleteAccount(_ account: CloudBackupAccount) async throws {
        modelContext.delete(account)
        try modelContext.save()
    }
    
    /// Disconnect account
    func disconnectAccount(_ account: CloudBackupAccount) async throws {
        account.isConnected = false
        account.accessToken = ""
        account.refreshToken = nil
        try modelContext.save()
    }
    
    // MARK: - OAuth Authentication
    
    /// Generate Google OAuth URL
    func generateGoogleOAuthURL() -> String {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: googleClientId),
            URLQueryItem(name: "redirect_uri", value: googleRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/drive.file"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components?.url?.absoluteString ?? ""
    }
    
    /// Generate Dropbox OAuth URL
    func generateDropboxOAuthURL() -> String {
        var components = URLComponents(string: "https://www.dropbox.com/oauth2/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: dropboxAppKey),
            URLQueryItem(name: "redirect_uri", value: dropboxRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "token_access_type", value: "offline"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components?.url?.absoluteString ?? ""
    }
    
    /// Generate OneDrive OAuth URL
    func generateOneDriveOAuthURL() -> String {
        var components = URLComponents(string: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: onedriveClientId),
            URLQueryItem(name: "redirect_uri", value: onedriveRedirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "Files.ReadWrite.AppFolder"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components?.url?.absoluteString ?? ""
    }
    
    /// Exchange authorization code for tokens (Google)
    func exchangeGoogleCode(for code: String) async throws -> OAuthTokenResponse {
        // Hardcoded URL - known to be valid
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            throw CloudBackupError.invalidConfiguration("Invalid Google token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": googleClientId,
            "client_secret": googleClientSecret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": googleRedirectUri
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
          .joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.authenticationFailed("Failed to exchange code")
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    /// Exchange authorization code for tokens (Dropbox)
    func exchangeDropboxCode(for code: String) async throws -> OAuthTokenResponse {
        // Hardcoded URL - known to be valid
        guard let url = URL(string: "https://api.dropboxapi.com/oauth2/token") else {
            throw CloudBackupError.invalidConfiguration("Invalid Dropbox token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("\(dropboxAppKey):\(dropboxAppSecret)", forHTTPHeaderField: "Authorization")
        
        let body = [
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": dropboxRedirectUri
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
          .joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.authenticationFailed("Failed to exchange code")
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    /// Exchange authorization code for tokens (OneDrive)
    func exchangeOneDriveCode(for code: String) async throws -> OAuthTokenResponse {
        // Hardcoded URL - known to be valid
        guard let url = URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token") else {
            throw CloudBackupError.invalidConfiguration("Invalid OneDrive token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": onedriveClientId,
            "client_secret": onedriveClientSecret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": onedriveRedirectUri
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
          .joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.authenticationFailed("Failed to exchange code")
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    // MARK: - Backup Operations
    
    /// Create backup on cloud provider
    func createBackup(
        accountId: UUID,
        data: Data,
        fileName: String,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> CloudBackupItem {
        guard let account = try await getAccount(by: accountId) else {
            throw CloudBackupError.accountNotFound
        }
        
        let provider = CloudBackupProvider(rawValue: account.provider)
        guard let provider = provider else {
            throw CloudBackupError.invalidProvider
        }
        
        // Refresh token if needed
        try await refreshAccessTokenIfNeeded(for: account)
        
        // Upload file based on provider
        let remotePath: String
        let checksum: String
        
        switch provider {
        case .googleDrive:
            (remotePath, checksum) = try await uploadToGoogleDrive(
                data: data,
                fileName: fileName,
                accessToken: account.accessToken,
                progressHandler: progressHandler
            )
        case .dropbox:
            (remotePath, checksum) = try await uploadToDropbox(
                data: data,
                fileName: fileName,
                accessToken: account.accessToken,
                progressHandler: progressHandler
            )
        case .onedrive:
            (remotePath, checksum) = try await uploadToOneDrive(
                data: data,
                fileName: fileName,
                accessToken: account.accessToken,
                progressHandler: progressHandler
            )
        }
        
        // Create backup item
        let item = CloudBackupItem(
            fileName: fileName,
            fileSize: Int64(data.count),
            remotePath: remotePath,
            createdAt: Date(),
            dreamCount: 0, // Will be updated by caller
            checksum: checksum
        )
        
        // Update account stats
        account.totalBackups += 1
        account.lastBackupAt = Date()
        account.storageUsedBytes += Int64(data.count)
        
        try modelContext.save()
        
        return item
    }
    
    /// Upload to Google Drive
    private func uploadToGoogleDrive(
        data: Data,
        fileName: String,
        accessToken: String,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (String, String) {
        // Create file metadata
        let metadata = [
            "name": fileName,
            "parents": ["app_data_folder"]
        ]
        
        let boundary = UUID().uuidString
        guard let uploadURL = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart") else {
            throw CloudBackupError.uploadFailed("Invalid Google Drive upload URL")
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Metadata part - UTF-8 encoding of ASCII strings never fails
        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8) ?? Data())
        body.append(try JSONSerialization.data(withJSONObject: metadata))
        body.append("\r\n".data(using: .utf8) ?? Data())
        
        // File part
        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8) ?? Data())
        body.append(data)
        body.append("\r\n".data(using: .utf8) ?? Data())
        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.uploadFailed("Google Drive upload failed")
        }
        
        let result = try JSONDecoder().decode(GoogleDriveFileResponse.self, from: responseData)
        progressHandler?(1.0)
        
        return (result.id, calculateChecksum(data: data))
    }
    
    /// Upload to Dropbox
    private func uploadToDropbox(
        data: Data,
        fileName: String,
        accessToken: String,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (String, String) {
        let path = "/DreamLog/\(fileName)"
        
        guard let uploadURL = URL(string: "https://content.dropboxapi.com/2/files/upload") else {
            throw CloudBackupError.uploadFailed("Invalid Dropbox upload URL")
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let uploadArg: [String: Any] = [
            "path": path,
            "mode": "add",
            "autorename": true,
            "mute": false
        ]
        request.setValue(try JSONSerialization.data(withJSONObject: uploadArg).base64EncodedString(), forHTTPHeaderField: "Dropbox-API-Arg")
        
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.uploadFailed("Dropbox upload failed")
        }
        
        let result = try JSONDecoder().decode(DropboxFileResponse.self, from: responseData)
        progressHandler?(1.0)
        
        return (result.id, calculateChecksum(data: data))
    }
    
    /// Upload to OneDrive
    private func uploadToOneDrive(
        data: Data,
        fileName: String,
        accessToken: String,
        progressHandler: ((Double) -> Void)?
    ) async throws -> (String, String) {
        let path = "/DreamLog/\(fileName)"
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        guard let uploadURL = URL(string: "https://graph.microsoft.com/v1.0/me/drive/special/approot:\(encodedPath):/content") else {
            throw CloudBackupError.uploadFailed("Invalid OneDrive upload URL")
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw CloudBackupError.uploadFailed("OneDrive upload failed")
        }
        
        let result = try JSONDecoder().decode(OneDriveFileResponse.self, from: responseData)
        progressHandler?(1.0)
        
        return (result.id, calculateChecksum(data: data))
    }
    
    /// List backup files from cloud provider
    func listBackupFiles(accountId: UUID) async throws -> [CloudBackupItem] {
        guard let account = try await getAccount(by: accountId) else {
            throw CloudBackupError.accountNotFound
        }
        
        let provider = CloudBackupProvider(rawValue: account.provider)
        guard let provider = provider else {
            throw CloudBackupError.invalidProvider
        }
        
        try await refreshAccessTokenIfNeeded(for: account)
        
        switch provider {
        case .googleDrive:
            return try await listGoogleDriveFiles(accessToken: account.accessToken)
        case .dropbox:
            return try await listDropboxFiles(accessToken: account.accessToken)
        case .onedrive:
            return try await listOneDriveFiles(accessToken: account.accessToken)
        }
    }
    
    /// Download backup file from cloud provider
    func downloadBackupFile(accountId: UUID, fileId: String) async throws -> Data {
        guard let account = try await getAccount(by: accountId) else {
            throw CloudBackupError.accountNotFound
        }
        
        let provider = CloudBackupProvider(rawValue: account.provider)
        guard let provider = provider else {
            throw CloudBackupError.invalidProvider
        }
        
        try await refreshAccessTokenIfNeeded(for: account)
        
        switch provider {
        case .googleDrive:
            return try await downloadFromGoogleDrive(fileId: fileId, accessToken: account.accessToken)
        case .dropbox:
            return try await downloadFromDropbox(fileId: fileId, accessToken: account.accessToken)
        case .onedrive:
            return try await downloadFromOneDrive(fileId: fileId, accessToken: account.accessToken)
        }
    }
    
    /// Delete backup file from cloud provider
    func deleteBackupFile(accountId: UUID, fileId: String) async throws {
        guard let account = try await getAccount(by: accountId) else {
            throw CloudBackupError.accountNotFound
        }
        
        let provider = CloudBackupProvider(rawValue: account.provider)
        guard let provider = provider else {
            throw CloudBackupError.invalidProvider
        }
        
        try await refreshAccessTokenIfNeeded(for: account)
        
        switch provider {
        case .googleDrive:
            try await deleteFromGoogleDrive(fileId: fileId, accessToken: account.accessToken)
        case .dropbox:
            try await deleteFromDropbox(fileId: fileId, accessToken: account.accessToken)
        case .onedrive:
            try await deleteFromOneDrive(fileId: fileId, accessToken: account.accessToken)
        }
    }
    
    /// Get storage info from cloud provider
    func getStorageInfo(accountId: UUID) async throws -> CloudStorageInfo {
        guard let account = try await getAccount(by: accountId) else {
            throw CloudBackupError.accountNotFound
        }
        
        let provider = CloudBackupProvider(rawValue: account.provider)
        guard let provider = provider else {
            throw CloudBackupError.invalidProvider
        }
        
        try await refreshAccessTokenIfNeeded(for: account)
        
        switch provider {
        case .googleDrive:
            return try await getGoogleDriveStorageInfo(accessToken: account.accessToken)
        case .dropbox:
            return try await getDropboxStorageInfo(accessToken: account.accessToken)
        case .onedrive:
            return try await getOneDriveStorageInfo(accessToken: account.accessToken)
        }
    }
    
    // MARK: - Token Management
    
    /// Refresh access token if expired
    private func refreshAccessTokenIfNeeded(for account: CloudBackupAccount) async throws {
        guard let expiry = account.tokenExpiry, expiry < Date(),
              let refreshToken = account.refreshToken else {
            return
        }
        
        let provider = CloudBackupProvider(rawValue: account.provider)
        guard let provider = provider else { return }
        
        let newToken: OAuthTokenResponse
        
        switch provider {
        case .googleDrive:
            newToken = try await refreshGoogleToken(refreshToken: refreshToken)
        case .dropbox:
            newToken = try await refreshDropboxToken(refreshToken: refreshToken)
        case .onedrive:
            newToken = try await refreshOneDriveToken(refreshToken: refreshToken)
        }
        
        account.accessToken = newToken.accessToken
        account.refreshToken = newToken.refreshToken ?? account.refreshToken
        account.tokenExpiry = Date().addingTimeInterval(TimeInterval(newToken.expiresIn ?? 3600))
        
        try modelContext.save()
    }
    
    private func refreshGoogleToken(refreshToken: String) async throws -> OAuthTokenResponse {
        // Hardcoded URL - known to be valid
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            throw CloudBackupError.invalidConfiguration("Invalid Google token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": googleClientId,
            "client_secret": googleClientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.tokenRefreshFailed
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    private func refreshDropboxToken(refreshToken: String) async throws -> OAuthTokenResponse {
        // Hardcoded URL - known to be valid
        guard let url = URL(string: "https://api.dropboxapi.com/oauth2/token") else {
            throw CloudBackupError.invalidConfiguration("Invalid Dropbox token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("\(dropboxAppKey):\(dropboxAppSecret)", forHTTPHeaderField: "Authorization")
        
        let body = [
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.tokenRefreshFailed
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    private func refreshOneDriveToken(refreshToken: String) async throws -> OAuthTokenResponse {
        // Hardcoded URL - known to be valid
        guard let url = URL(string: "https://login.microsoftonline.com/common/oauth2/v2.0/token") else {
            throw CloudBackupError.invalidConfiguration("Invalid OneDrive token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": onedriveClientId,
            "client_secret": onedriveClientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CloudBackupError.tokenRefreshFailed
        }
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    // MARK: - Helper Methods
    
    private func calculateChecksum(data: Data) -> String {
        let hash = Insecure.SHA1.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Placeholder implementations for provider-specific methods
    private func listGoogleDriveFiles(accessToken: String) async throws -> [CloudBackupItem] { [] }
    private func listDropboxFiles(accessToken: String) async throws -> [CloudBackupItem] { [] }
    private func listOneDriveFiles(accessToken: String) async throws -> [CloudBackupItem] { [] }
    
    private func downloadFromGoogleDrive(fileId: String, accessToken: String) async throws -> Data { Data() }
    private func downloadFromDropbox(fileId: String, accessToken: String) async throws -> Data { Data() }
    private func downloadFromOneDrive(fileId: String, accessToken: String) async throws -> Data { Data() }
    
    private func deleteFromGoogleDrive(fileId: String, accessToken: String) async throws {}
    private func deleteFromDropbox(fileId: String, accessToken: String) async throws {}
    private func deleteFromOneDrive(fileId: String, accessToken: String) async throws {}
    
    private func getGoogleDriveStorageInfo(accessToken: String) async throws -> CloudStorageInfo {
        CloudStorageInfo(used: 0, total: 15 * 1024 * 1024 * 1024, normal: 0, trash: 0)
    }
    private func getDropboxStorageInfo(accessToken: String) async throws -> CloudStorageInfo {
        CloudStorageInfo(used: 0, total: 2 * 1024 * 1024 * 1024, normal: 0, trash: 0)
    }
    private func getOneDriveStorageInfo(accessToken: String) async throws -> CloudStorageInfo {
        CloudStorageInfo(used: 0, total: 5 * 1024 * 1024 * 1024, normal: 0, trash: 0)
    }
}

// MARK: - API Response Models

struct GoogleDriveFileResponse: Codable {
    let id: String
    let name: String
    let mimeType: String
    let size: String?
}

struct DropboxFileResponse: Codable {
    let id: String
    let name: String
    let pathDisplay: String
    let clientModified: Date
    let size: Int
}

struct OneDriveFileResponse: Codable {
    let id: String
    let name: String
    let size: Int
    let lastModifiedDateTime: Date
}

// MARK: - Cloud Backup Errors

enum CloudBackupError: LocalizedError {
    case accountNotFound
    case invalidProvider
    case authenticationFailed(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case tokenRefreshFailed
    case networkError(String)
    case encryptionError(String)
    
    var errorDescription: String? {
        switch self {
        case .accountNotFound:
            return "备份账户未找到"
        case .invalidProvider:
            return "无效的云服务提供商"
        case .authenticationFailed(let message):
            return "认证失败：\(message)"
        case .uploadFailed(let message):
            return "上传失败：\(message)"
        case .downloadFailed(let message):
            return "下载失败：\(message)"
        case .tokenRefreshFailed:
            return "令牌刷新失败"
        case .networkError(let message):
            return "网络错误：\(message)"
        case .encryptionError(let message):
            return "加密错误：\(message)"
        }
    }
}
