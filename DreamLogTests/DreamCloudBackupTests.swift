//
//  DreamCloudBackupTests.swift
//  DreamLog - Phase 37: Cloud Backup Integration
//
//  Created by DreamLog Team on 2026-03-14.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamCloudBackupTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([
            CloudBackupConfig.self,
            CloudBackupRecord.self,
            Dream.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Cloud Provider Tests
    
    func testCloudProviderCases() {
        XCTAssertEqual(CloudProvider.allCases.count, 4)
        XCTAssertEqual(CloudProvider.allCases, [.googleDrive, .dropbox, .onedrive, .webdav])
    }
    
    func testCloudProviderDisplayNames() {
        XCTAssertEqual(CloudProvider.googleDrive.displayName, "Google Drive")
        XCTAssertEqual(CloudProvider.dropbox.displayName, "Dropbox")
        XCTAssertEqual(CloudProvider.onedrive.displayName, "OneDrive")
        XCTAssertEqual(CloudProvider.webdav.displayName, "WebDAV")
    }
    
    func testCloudProviderColors() {
        XCTAssertEqual(CloudProvider.googleDrive.color, "34A853")
        XCTAssertEqual(CloudProvider.dropbox.color, "0061FF")
        XCTAssertEqual(CloudProvider.onedrive.color, "0078D4")
        XCTAssertEqual(CloudProvider.webdav.color, "6B7280")
    }
    
    func testCloudProviderAuthTypes() {
        XCTAssertEqual(CloudProvider.googleDrive.authType, .oauth2)
        XCTAssertEqual(CloudProvider.dropbox.authType, .oauth2)
        XCTAssertEqual(CloudProvider.onedrive.authType, .oauth2)
        XCTAssertEqual(CloudProvider.webdav.authType, .basic)
    }
    
    // MARK: - Backup Frequency Tests
    
    func testBackupFrequencyCases() {
        XCTAssertEqual(BackupFrequency.allCases.count, 4)
    }
    
    func testBackupFrequencyDisplayNames() {
        XCTAssertEqual(BackupFrequency.daily.displayName, "每天")
        XCTAssertEqual(BackupFrequency.weekly.displayName, "每周")
        XCTAssertEqual(BackupFrequency.monthly.displayName, "每月")
        XCTAssertEqual(BackupFrequency.manual.displayName, "手动")
    }
    
    func testBackupFrequencyIntervals() {
        XCTAssertEqual(BackupFrequency.daily.intervalSeconds, 86400)
        XCTAssertEqual(BackupFrequency.weekly.intervalSeconds, 604800)
        XCTAssertEqual(BackupFrequency.monthly.intervalSeconds, 2592000)
        XCTAssertEqual(BackupFrequency.manual.intervalSeconds, 0)
    }
    
    // MARK: - Backup Type Tests
    
    func testBackupTypeCases() {
        XCTAssertEqual(BackupType.allCases.count, 3)
    }
    
    func testBackupTypeDisplayNames() {
        XCTAssertEqual(BackupType.full.displayName, "完整备份")
        XCTAssertEqual(BackupType.incremental.displayName, "增量备份")
        XCTAssertEqual(BackupType.selective.displayName, "选择性备份")
    }
    
    // MARK: - Backup Status Tests
    
    func testBackupStatusIcons() {
        XCTAssertEqual(BackupStatus.pending.icon, "clock")
        XCTAssertEqual(BackupStatus.uploading.icon, "arrow.up.circle.fill")
        XCTAssertEqual(BackupStatus.completed.icon, "checkmark.circle.fill")
        XCTAssertEqual(BackupStatus.failed.icon, "xmark.circle.fill")
        XCTAssertEqual(BackupStatus.cancelled.icon, "slash.circle")
    }
    
    // MARK: - Date Range Tests
    
    func testDateRangeCases() {
        XCTAssertEqual(DateRange.allCases.count, 6)
    }
    
    func testDateRangeDisplayNames() {
        XCTAssertEqual(DateRange.all.displayName, "全部")
        XCTAssertEqual(DateRange.last7Days.displayName, "最近 7 天")
        XCTAssertEqual(DateRange.last30Days.displayName, "最近 30 天")
        XCTAssertEqual(DateRange.last3Months.displayName, "最近 3 个月")
        XCTAssertEqual(DateRange.lastYear.displayName, "最近 1 年")
        XCTAssertEqual(DateRange.custom.displayName, "自定义")
    }
    
    // MARK: - Cloud Backup Config Tests
    
    func testCloudBackupConfigCreation() {
        let config = CloudBackupConfig(provider: .googleDrive, accountName: "test@example.com")
        
        XCTAssertNotNil(config.id)
        XCTAssertEqual(config.provider, "google_drive")
        XCTAssertEqual(config.accountName, "test@example.com")
        XCTAssertFalse(config.isConnected)
        XCTAssertFalse(config.autoBackupEnabled)
        XCTAssertEqual(config.autoBackupFrequency, .weekly)
        XCTAssertEqual(config.totalBackups, 0)
        XCTAssertEqual(config.storageUsed, 0)
        XCTAssertNil(config.accessToken)
        XCTAssertNil(config.refreshToken)
    }
    
    func testCloudBackupConfigPersistence() throws {
        let config = CloudBackupConfig(provider: .dropbox)
        config.isConnected = true
        config.accountName = "user@dropbox.com"
        config.accessToken = "test_token"
        config.totalBackups = 5
        
        modelContext.insert(config)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<CloudBackupConfig>()
        let fetchedConfigs = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedConfigs.count, 1)
        let fetchedConfig = fetchedConfigs.first
        XCTAssertEqual(fetchedConfig?.provider, "dropbox")
        XCTAssertEqual(fetchedConfig?.accountName, "user@dropbox.com")
        XCTAssertEqual(fetchedConfig?.totalBackups, 5)
    }
    
    func testCloudBackupConfigUpdate() throws {
        let config = CloudBackupConfig(provider: .googleDrive)
        modelContext.insert(config)
        try modelContext.save()
        
        config.isConnected = true
        config.autoBackupEnabled = true
        config.autoBackupFrequency = .daily
        config.totalBackups = 10
        try modelContext.save()
        
        let descriptor = FetchDescriptor<CloudBackupConfig>()
        let fetchedConfig = try modelContext.fetch(descriptor).first
        
        XCTAssertEqual(fetchedConfig?.isConnected, true)
        XCTAssertEqual(fetchedConfig?.autoBackupEnabled, true)
        XCTAssertEqual(fetchedConfig?.autoBackupFrequency, .daily)
        XCTAssertEqual(fetchedConfig?.totalBackups, 10)
    }
    
    // MARK: - Cloud Backup Record Tests
    
    func testCloudBackupRecordCreation() {
        let config = CloudBackupConfig(provider: .googleDrive)
        let record = CloudBackupRecord(
            configId: config.id,
            provider: .googleDrive,
            fileName: "test_backup.dreamlog",
            cloudFileId: "file_123",
            cloudFilePath: "/DreamLog/Backups/test_backup.dreamlog",
            backupType: .full,
            dreamCount: 50,
            fileSize: 1024 * 1024 * 10
        )
        
        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.fileName, "test_backup.dreamlog")
        XCTAssertEqual(record.dreamCount, 50)
        XCTAssertEqual(record.fileSize, 1024 * 1024 * 10)
        XCTAssertEqual(record.backupType, .full)
        XCTAssertEqual(record.status, .completed)
        XCTAssertTrue(record.isEncrypted)
    }
    
    func testCloudBackupRecordPersistence() throws {
        let config = CloudBackupConfig(provider: .dropbox)
        modelContext.insert(config)
        
        let record = CloudBackupRecord(
            configId: config.id,
            provider: .dropbox,
            fileName: "backup_20260314.dreamlog",
            cloudFileId: "abc123",
            cloudFilePath: "/DreamLog/backup_20260314.dreamlog",
            backupType: .incremental,
            dreamCount: 25,
            fileSize: 5 * 1024 * 1024,
            includesAudio: true,
            includesImages: true
        )
        
        modelContext.insert(record)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<CloudBackupRecord>()
        let fetchedRecords = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedRecords.count, 1)
        let fetchedRecord = fetchedRecords.first
        XCTAssertEqual(fetchedRecord?.fileName, "backup_20260314.dreamlog")
        XCTAssertEqual(fetchedRecord?.dreamCount, 25)
        XCTAssertEqual(fetchedRecord?.includesAudio, true)
        XCTAssertEqual(fetchedRecord?.includesImages, true)
    }
    
    // MARK: - Cloud Backup Options Tests
    
    func testCloudBackupOptionsDefault() {
        let options = CloudBackupOptions()
        
        XCTAssertEqual(options.backupType, .full)
        XCTAssertEqual(options.dateRange, .all)
        XCTAssertTrue(options.includeAudio)
        XCTAssertTrue(options.includeImages)
        XCTAssertTrue(options.includeAIAnalysis)
        XCTAssertTrue(options.includeLocations)
        XCTAssertTrue(options.compressData)
        XCTAssertTrue(options.encryptData)
        XCTAssertNil(options.encryptionPassword)
    }
    
    func testCloudBackupOptionsCustom() {
        let options = CloudBackupOptions(
            backupType: .selective,
            dateRange: .last7Days,
            includeAudio: false,
            includeImages: false,
            includeAIAnalysis: true,
            includeLocations: false,
            compressData: true,
            encryptData: true,
            encryptionPassword: "secure_password"
        )
        
        XCTAssertEqual(options.backupType, .selective)
        XCTAssertEqual(options.dateRange, .last7Days)
        XCTAssertFalse(options.includeAudio)
        XCTAssertFalse(options.includeImages)
        XCTAssertTrue(options.includeAIAnalysis)
        XCTAssertFalse(options.includeLocations)
        XCTAssertTrue(options.encryptData)
        XCTAssertEqual(options.encryptionPassword, "secure_password")
    }
    
    // MARK: - Cloud Storage Info Tests
    
    func testCloudStorageInfoFormatting() {
        let info = CloudStorageInfo(
            used: 5 * 1024 * 1024 * 1024,
            total: 15 * 1024 * 1024 * 1024,
            available: 10 * 1024 * 1024 * 1024,
            percentUsed: 33.3
        )
        
        XCTAssertEqual(info.usedFormatted, "5 GB")
        XCTAssertEqual(info.totalFormatted, "15 GB")
        XCTAssertEqual(info.availableFormatted, "10 GB")
        XCTAssertEqual(info.percentUsed, 33.3)
    }
    
    // MARK: - WebDAV Config Tests
    
    func testWebDAVConfigDefault() {
        let config = WebDAVConfig(
            serverUrl: "example.com",
            username: "user",
            password: "pass"
        )
        
        XCTAssertEqual(config.serverUrl, "example.com")
        XCTAssertEqual(config.username, "user")
        XCTAssertEqual(config.password, "pass")
        XCTAssertEqual(config.path, "/DreamLog")
        XCTAssertTrue(config.useSSL)
        XCTAssertEqual(config.port, 443)
    }
    
    func testWebDAVConfigFullURL() {
        let config1 = WebDAVConfig(
            serverUrl: "example.com",
            username: "user",
            password: "pass",
            useSSL: true,
            port: 443
        )
        XCTAssertEqual(config1.fullUrl, "https://example.com/DreamLog")
        
        let config2 = WebDAVConfig(
            serverUrl: "example.com",
            username: "user",
            password: "pass",
            useSSL: false,
            port: 8080
        )
        XCTAssertEqual(config2.fullUrl, "http://example.com:8080/DreamLog")
    }
    
    // MARK: - Cloud Backup Statistics Tests
    
    func testCloudBackupStatistics() {
        let stats = CloudBackupStatistics(
            totalConfigs: 3,
            connectedConfigs: 2,
            totalBackups: 15,
            totalSizeBytes: 100 * 1024 * 1024,
            successfulBackups: 14,
            failedBackups: 1,
            lastBackupDate: Date(),
            nextScheduledBackup: Date().addingTimeInterval(86400),
            providers: [.googleDrive, .dropbox]
        )
        
        XCTAssertEqual(stats.totalConfigs, 3)
        XCTAssertEqual(stats.connectedConfigs, 2)
        XCTAssertEqual(stats.totalBackups, 15)
        XCTAssertEqual(stats.totalSizeFormatted, "100 MB")
        XCTAssertEqual(stats.successRate, 93.33, accuracy: 0.01)
        XCTAssertEqual(stats.providers.count, 2)
    }
    
    // MARK: - Backup Status Tests
    
    func testBackupStatusDisplayNames() {
        XCTAssertEqual(BackupStatus.pending.displayName, "等待中")
        XCTAssertEqual(BackupStatus.uploading.displayName, "上传中")
        XCTAssertEqual(BackupStatus.completed.displayName, "已完成")
        XCTAssertEqual(BackupStatus.failed.displayName, "失败")
        XCTAssertEqual(BackupStatus.cancelled.displayName, "已取消")
    }
    
    // MARK: - Cloud Backup Error Tests
    
    func testCloudBackupErrorMessages() {
        XCTAssertEqual(CloudBackupError.invalidProvider.errorDescription, "无效的云服务提供商")
        XCTAssertEqual(CloudBackupError.notConnected.errorDescription, "未连接到云服务")
        XCTAssertEqual(CloudBackupError.noRefreshToken.errorDescription, "缺少刷新令牌")
        XCTAssertEqual(CloudBackupError.tokenExchangeFailed.errorDescription, "令牌交换失败")
        XCTAssertEqual(CloudBackupError.uploadFailed.errorDescription, "上传失败")
        XCTAssertEqual(CloudBackupError.downloadFailed.errorDescription, "下载失败")
    }
    
    // MARK: - OAuth Token Response Tests
    
    func testOAuthTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "ya29.test_token",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "1//test_refresh",
            "scope": "https://www.googleapis.com/auth/drive.file"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: json)
        
        XCTAssertEqual(response.accessToken, "ya29.test_token")
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 3600)
        XCTAssertEqual(response.refreshToken, "1//test_refresh")
    }
    
    // MARK: - Backup Container Tests
    
    func testBackupContainerEncoding() throws {
        let backupDream = BackupDream(
            id: UUID(),
            title: "Test Dream",
            content: "This is a test dream",
            createdAt: Date(),
            updatedAt: Date(),
            tags: ["test", "dream"],
            emotions: ["happy", "excited"],
            clarity: 4,
            intensity: 3,
            isLucid: false
        )
        
        let container = BackupContainer(
            version: "1.0",
            exportDate: Date(),
            appVersion: "1.0.0",
            dreamCount: 1,
            dreams: [backupDream]
        )
        
        let data = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(BackupContainer.self, from: data)
        
        XCTAssertEqual(decoded.version, "1.0")
        XCTAssertEqual(decoded.appVersion, "1.0.0")
        XCTAssertEqual(decoded.dreamCount, 1)
        XCTAssertEqual(decoded.dreams.count, 1)
        XCTAssertEqual(decoded.dreams.first?.title, "Test Dream")
    }
    
    // MARK: - Performance Tests
    
    func testConfigCreationPerformance() {
        measure {
            for _ in 0..<100 {
                let config = CloudBackupConfig(provider: .googleDrive)
                _ = config.id
            }
        }
    }
    
    func testRecordCreationPerformance() {
        let config = CloudBackupConfig(provider: .googleDrive)
        
        measure {
            for _ in 0..<100 {
                let record = CloudBackupRecord(
                    configId: config.id,
                    provider: .googleDrive,
                    fileName: "test.dreamlog",
                    cloudFileId: "file_123",
                    cloudFilePath: "/test",
                    backupType: .full,
                    dreamCount: 10,
                    fileSize: 1024 * 1024
                )
                _ = record.id
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testMultipleConfigsAndRecords() throws {
        // 创建多个配置
        let googleConfig = CloudBackupConfig(provider: .googleDrive, accountName: "google@example.com")
        let dropboxConfig = CloudBackupConfig(provider: .dropbox, accountName: "dropbox@example.com")
        let oneDriveConfig = CloudBackupConfig(provider: .onedrive, accountName: "onedrive@example.com")
        
        googleConfig.isConnected = true
        dropboxConfig.isConnected = true
        googleConfig.totalBackups = 5
        dropboxConfig.totalBackups = 3
        
        modelContext.insert(googleConfig)
        modelContext.insert(dropboxConfig)
        modelContext.insert(oneDriveConfig)
        
        // 创建多个备份记录
        for i in 0..<5 {
            let record = CloudBackupRecord(
                configId: googleConfig.id,
                provider: .googleDrive,
                fileName: "google_backup_\(i).dreamlog",
                cloudFileId: "gfile_\(i)",
                cloudFilePath: "/google/\(i)",
                backupType: .full,
                dreamCount: 10 + i,
                fileSize: Int64((10 + i) * 1024 * 1024)
            )
            modelContext.insert(record)
        }
        
        for i in 0..<3 {
            let record = CloudBackupRecord(
                configId: dropboxConfig.id,
                provider: .dropbox,
                fileName: "dropbox_backup_\(i).dreamlog",
                cloudFileId: "dfile_\(i)",
                cloudFilePath: "/dropbox/\(i)",
                backupType: .incremental,
                dreamCount: 5 + i,
                fileSize: Int64((5 + i) * 1024 * 1024)
            )
            modelContext.insert(record)
        }
        
        try modelContext.save()
        
        // 验证配置
        let configDescriptor = FetchDescriptor<CloudBackupConfig>()
        let configs = try modelContext.fetch(configDescriptor)
        XCTAssertEqual(configs.count, 3)
        
        // 验证记录
        let recordDescriptor = FetchDescriptor<CloudBackupRecord>()
        let records = try modelContext.fetch(recordDescriptor)
        XCTAssertEqual(records.count, 8)
        
        // 验证 Google 配置的记录数
        let googleRecords = records.filter { $0.configId == googleConfig.id }
        XCTAssertEqual(googleRecords.count, 5)
        
        // 验证 Dropbox 配置的记录数
        let dropboxRecords = records.filter { $0.configId == dropboxConfig.id }
        XCTAssertEqual(dropboxRecords.count, 3)
    }
}
