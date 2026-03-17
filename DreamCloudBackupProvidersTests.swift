//
//  DreamCloudBackupProvidersTests.swift
//  DreamLogTests
//
//  Phase 62: Dream Cloud Backup Enhancement
//  Unit tests for cloud backup providers
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamCloudBackupProvidersTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            CloudBackupAccount.self,
            CloudBackupTask.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Account Management Tests
    
    func testCreateGoogleDriveAccount() async throws {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test User",
            accountEmail: "test@example.com",
            accessToken: "test_access_token",
            refreshToken: "test_refresh_token"
        )
        
        modelContext.insert(account)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<CloudBackupAccount>()
        let accounts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].provider, CloudBackupProvider.googleDrive.rawValue)
        XCTAssertEqual(accounts[0].accountEmail, "test@example.com")
        XCTAssertTrue(accounts[0].isConnected)
    }
    
    func testCreateDropboxAccount() async throws {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.dropbox.rawValue,
            accountName: "Dropbox User",
            accountEmail: "dropbox@example.com",
            accessToken: "dropbox_token"
        )
        
        modelContext.insert(account)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<CloudBackupAccount>(
            predicate: #Predicate<CloudBackupAccount> { $0.provider == CloudBackupProvider.dropbox.rawValue }
        )
        let accounts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].providerEnum, .dropbox)
    }
    
    func testCreateOneDriveAccount() async throws {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.onedrive.rawValue,
            accountName: "OneDrive User",
            accessToken: "onedrive_token"
        )
        
        modelContext.insert(account)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<CloudBackupAccount>(
            predicate: #Predicate<CloudBackupAccount> { $0.provider == CloudBackupProvider.onedrive.rawValue }
        )
        let accounts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].providerEnum, .onedrive)
    }
    
    func testDisconnectAccount() async throws {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token"
        )
        
        modelContext.insert(account)
        try modelContext.save()
        
        // Disconnect
        account.isConnected = false
        account.accessToken = ""
        try modelContext.save()
        
        let fetched = try modelContext.fetch(FetchDescriptor<CloudBackupAccount>()).first
        XCTAssertFalse(fetched?.isConnected ?? true)
        XCTAssertEqual(fetched?.accessToken, "")
    }
    
    func testDeleteAccount() async throws {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token"
        )
        
        modelContext.insert(account)
        try modelContext.save()
        
        modelContext.delete(account)
        try modelContext.save()
        
        let accounts = try modelContext.fetch(FetchDescriptor<CloudBackupAccount>())
        XCTAssertEqual(accounts.count, 0)
    }
    
    // MARK: - Storage Calculation Tests
    
    func testStorageUsagePercent() {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token",
            storageUsedBytes: 5 * 1024 * 1024 * 1024, // 5GB
            storageQuotaBytes: 15 * 1024 * 1024 * 1024 // 15GB
        )
        
        XCTAssertEqual(account.storageUsagePercent, 33.33, accuracy: 0.01)
    }
    
    func testStorageUsagePercentZeroQuota() {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token",
            storageUsedBytes: 1000,
            storageQuotaBytes: 0
        )
        
        XCTAssertEqual(account.storageUsagePercent, 0)
    }
    
    func testStorageUsagePercentFull() {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token",
            storageUsedBytes: 15 * 1024 * 1024 * 1024,
            storageQuotaBytes: 15 * 1024 * 1024 * 1024
        )
        
        XCTAssertEqual(account.storageUsagePercent, 100.0, accuracy: 0.01)
    }
    
    // MARK: - Formatted Storage Tests
    
    func testFormattedStorageUsed() {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token",
            storageUsedBytes: 1024 * 1024 * 1024 // 1GB
        )
        
        XCTAssertTrue(account.formattedStorageUsed.contains("GB"))
    }
    
    func testFormattedStorageQuota() {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token",
            storageQuotaBytes: 15 * 1024 * 1024 * 1024 // 15GB
        )
        
        XCTAssertTrue(account.formattedStorageQuota.contains("GB"))
    }
    
    // MARK: - Cloud Backup Task Tests
    
    func testCreateBackupTask() async throws {
        let account = CloudBackupAccount(
            provider: CloudBackupProvider.googleDrive.rawValue,
            accountName: "Test",
            accessToken: "token"
        )
        modelContext.insert(account)
        try modelContext.save()
        
        let task = CloudBackupTask(
            accountId: account.id,
            status: CloudBackupTaskStatus.uploading.rawValue,
            progress: 0.5,
            totalItems: 100,
            processedItems: 50,
            backupSize: 1024 * 1024 * 50 // 50MB
        )
        
        modelContext.insert(task)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<CloudBackupTask>()
        let tasks = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].statusEnum, .uploading)
        XCTAssertEqual(tasks[0].progress, 0.5)
        XCTAssertEqual(tasks[0].processedItems, 50)
    }
    
    func testBackupTaskStatusEnum() {
        XCTAssertEqual(CloudBackupTaskStatus.pending.rawValue, "pending")
        XCTAssertEqual(CloudBackupTaskStatus.uploading.rawValue, "uploading")
        XCTAssertEqual(CloudBackupTaskStatus.completed.rawValue, "completed")
        XCTAssertEqual(CloudBackupTaskStatus.failed.rawValue, "failed")
        XCTAssertEqual(CloudBackupTaskStatus.cancelled.rawValue, "cancelled")
    }
    
    func testBackupTaskFormattedSize() {
        let task = CloudBackupTask(
            accountId: UUID(),
            backupSize: 1024 * 1024 * 100 // 100MB
        )
        
        XCTAssertTrue(task.formattedBackupSize.contains("MB"))
    }
    
    // MARK: - Cloud Backup Config Tests
    
    func testCloudBackupConfigDefaultValues() {
        let config = CloudBackupConfig(provider: .googleDrive)
        
        XCTAssertFalse(config.autoBackupEnabled)
        XCTAssertEqual(config.autoBackupFrequency, .weekly)
        XCTAssertTrue(config.includeAudio)
        XCTAssertTrue(config.includeImages)
        XCTAssertTrue(config.compressBackup)
        XCTAssertTrue(config.encryptBackup)
        XCTAssertEqual(config.retainCount, 10)
    }
    
    func testCloudBackupConfigCustomValues() {
        let config = CloudBackupConfig(
            provider: .dropbox,
            autoBackupEnabled: true,
            autoBackupFrequency: .daily,
            includeAudio: false,
            includeImages: false,
            compressBackup: false,
            encryptBackup: false,
            retainCount: 5
        )
        
        XCTAssertTrue(config.autoBackupEnabled)
        XCTAssertEqual(config.autoBackupFrequency, .daily)
        XCTAssertFalse(config.includeAudio)
        XCTAssertFalse(config.includeImages)
        XCTAssertFalse(config.compressBackup)
        XCTAssertFalse(config.encryptBackup)
        XCTAssertEqual(config.retainCount, 5)
    }
    
    // MARK: - Auto Backup Frequency Tests
    
    func testAutoBackupFrequencyDisplayNames() {
        XCTAssertEqual(AutoBackupFrequency.daily.displayName, "每天")
        XCTAssertEqual(AutoBackupFrequency.weekly.displayName, "每周")
        XCTAssertEqual(AutoBackupFrequency.monthly.displayName, "每月")
    }
    
    func testAutoBackupFrequencyAllCases() {
        XCTAssertEqual(AutoBackupFrequency.allCases.count, 3)
        XCTAssertTrue(AutoBackupFrequency.allCases.contains(.daily))
        XCTAssertTrue(AutoBackupFrequency.allCases.contains(.weekly))
        XCTAssertTrue(AutoBackupFrequency.allCases.contains(.monthly))
    }
    
    // MARK: - Cloud Backup Item Tests
    
    func testCloudBackupItemFormattedSize() {
        let item = CloudBackupItem(
            fileName: "backup.dreamlog",
            fileSize: 1024 * 1024 * 25, // 25MB
            remotePath: "/DreamLog/backup.dreamlog",
            createdAt: Date(),
            dreamCount: 50,
            checksum: "abc123"
        )
        
        XCTAssertTrue(item.formattedFileSize.contains("MB"))
    }
    
    func testCloudBackupItemIdentifiable() {
        let item1 = CloudBackupItem(
            fileName: "backup1.dreamlog",
            fileSize: 1000,
            remotePath: "/path1",
            createdAt: Date(),
            dreamCount: 10,
            checksum: "abc"
        )
        
        let item2 = CloudBackupItem(
            fileName: "backup2.dreamlog",
            fileSize: 2000,
            remotePath: "/path2",
            createdAt: Date(),
            dreamCount: 20,
            checksum: "def"
        )
        
        XCTAssertNotEqual(item1.id, item2.id)
    }
    
    // MARK: - Cloud Storage Info Tests
    
    func testCloudStorageInfoUsagePercent() {
        let info = CloudStorageInfo(
            used: 5 * 1024 * 1024 * 1024,
            total: 15 * 1024 * 1024 * 1024,
            normal: 4 * 1024 * 1024 * 1024,
            trash: 1 * 1024 * 1024 * 1024
        )
        
        XCTAssertEqual(info.usagePercent, 33.33, accuracy: 0.01)
    }
    
    func testCloudStorageInfoFormattedValues() {
        let info = CloudStorageInfo(
            used: 1024 * 1024 * 1024,
            total: 15 * 1024 * 1024 * 1024,
            normal: 0,
            trash: 0
        )
        
        XCTAssertTrue(info.usedFormatted.contains("GB"))
        XCTAssertTrue(info.totalFormatted.contains("GB"))
    }
    
    // MARK: - Cloud Backup Provider Tests
    
    func testCloudBackupProviderAllCases() {
        XCTAssertEqual(CloudBackupProvider.allCases.count, 3)
        XCTAssertTrue(CloudBackupProvider.allCases.contains(.googleDrive))
        XCTAssertTrue(CloudBackupProvider.allCases.contains(.dropbox))
        XCTAssertTrue(CloudBackupProvider.allCases.contains(.onedrive))
    }
    
    func testCloudBackupProviderDisplayNames() {
        XCTAssertEqual(CloudBackupProvider.googleDrive.displayName, "Google Drive")
        XCTAssertEqual(CloudBackupProvider.dropbox.displayName, "Dropbox")
        XCTAssertEqual(CloudBackupProvider.onedrive.displayName, "OneDrive")
    }
    
    func testCloudBackupProviderIconNames() {
        XCTAssertEqual(CloudBackupProvider.googleDrive.iconName, "folder.fill")
        XCTAssertEqual(CloudBackupProvider.dropbox.iconName, "externaldrive.fill")
        XCTAssertEqual(CloudBackupProvider.onedrive.iconName, "cloud.fill")
    }
    
    func testCloudBackupProviderBrandColors() {
        XCTAssertEqual(CloudBackupProvider.googleDrive.brandColor, "4285F4")
        XCTAssertEqual(CloudBackupProvider.dropbox.brandColor, "0061FF")
        XCTAssertEqual(CloudBackupProvider.onedrive.brandColor, "0078D4")
    }
    
    func testCloudBackupProviderIdentifiable() {
        XCTAssertEqual(CloudBackupProvider.googleDrive.id, "google_drive")
        XCTAssertEqual(CloudBackupProvider.dropbox.id, "dropbox")
        XCTAssertEqual(CloudBackupProvider.onedrive.id, "onedrive")
    }
    
    // MARK: - OAuth Token Response Tests
    
    func testOAuthTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "test_token",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "test_refresh",
            "scope": "drive.file"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: json)
        
        XCTAssertEqual(response.accessToken, "test_token")
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 3600)
        XCTAssertEqual(response.refreshToken, "test_refresh")
        XCTAssertEqual(response.scope, "drive.file")
    }
    
    // MARK: - Error Tests
    
    func testCloudBackupErrorMessages() {
        XCTAssertEqual(CloudBackupError.accountNotFound.errorDescription, "备份账户未找到")
        XCTAssertEqual(CloudBackupError.invalidProvider.errorDescription, "无效的云服务提供商")
        XCTAssertEqual(CloudBackupError.tokenRefreshFailed.errorDescription, "令牌刷新失败")
        XCTAssertTrue(CloudBackupError.authenticationFailed("test").errorDescription?.contains("认证失败") ?? false)
        XCTAssertTrue(CloudBackupError.uploadFailed("test").errorDescription?.contains("上传失败") ?? false)
        XCTAssertTrue(CloudBackupError.downloadFailed("test").errorDescription?.contains("下载失败") ?? false)
        XCTAssertTrue(CloudBackupError.networkError("test").errorDescription?.contains("网络错误") ?? false)
        XCTAssertTrue(CloudBackupError.encryptionError("test").errorDescription?.contains("加密错误") ?? false)
    }
    
    // MARK: - Performance Tests
    
    func testFetchMultipleAccountsPerformance() async throws {
        // Create 100 test accounts
        for i in 0..<100 {
            let account = CloudBackupAccount(
                provider: i % 3 == 0 ? CloudBackupProvider.googleDrive.rawValue :
                        i % 3 == 1 ? CloudBackupProvider.dropbox.rawValue : CloudBackupProvider.onedrive.rawValue,
                accountName: "Test User \(i)",
                accountEmail: "test\(i)@example.com",
                accessToken: "token_\(i)"
            )
            modelContext.insert(account)
        }
        try modelContext.save()
        
        // Measure fetch performance
        let startTime = Date()
        let descriptor = FetchDescriptor<CloudBackupAccount>()
        let accounts = try modelContext.fetch(descriptor)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertEqual(accounts.count, 100)
        XCTAssertLessThan(duration, 1.0, "Fetching 100 accounts should take less than 1 second")
    }
}
