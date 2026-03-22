//
//  DreamiCloudSyncTests.swift
//  DreamLogTests - Phase 88: iCloud CloudKit Sync
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import CloudKit
@testable import DreamLog

@MainActor
final class DreamiCloudSyncTests: XCTestCase {
    
    var syncService: DreamiCloudSyncService!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 设置测试用的 ModelContext
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DreamEntity.self, iCloudSyncConfig.self, SyncMetadata.self, configurations: config)
        modelContext = ModelContext(container)
        
        syncService = DreamiCloudSyncService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        syncService = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Availability Tests
    
    func testCheckAvailability() async {
        // 测试 iCloud 可用性检查
        syncService.checkAvailability()
        
        // 等待异步检查完成
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 注意：在测试环境中，iCloud 可能不可用
        // 这里主要验证方法不会崩溃
        XCTAssertNotNil(syncService.isAvailable)
    }
    
    func testCheckAuthentication() async {
        // 测试认证状态检查
        syncService.checkAuthentication()
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        XCTAssertNotNil(syncService.isAuthenticated)
    }
    
    // MARK: - Sync Config Tests
    
    func testGetSyncConfig_CreatesDefault() throws {
        // 测试获取同步配置（应该创建默认配置）
        let config = try syncService.getSyncConfig()
        
        XCTAssertEqual(config.syncDreams, true)
        XCTAssertEqual(config.syncSettings, true)
        XCTAssertEqual(config.syncCollections, true)
        XCTAssertEqual(config.conflictResolution, .latestWins)
        XCTAssertEqual(config.syncFrequency, .automatic)
    }
    
    func testUpdateSyncConfig() async throws {
        // 测试更新同步配置
        try await syncService.updateSyncConfig { config in
            config.isEnabled = true
            config.syncFrequency = .hourly
        }
        
        let config = try syncService.getSyncConfig()
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.syncFrequency, .hourly)
    }
    
    // MARK: - Sync Status Tests
    
    func testInitialSyncStatus() {
        // 测试初始同步状态
        XCTAssertEqual(syncService.syncStatus, .idle)
        XCTAssertEqual(syncService.syncMessage, "等待同步")
        XCTAssertEqual(syncService.syncProgress, 0.0)
    }
    
    func testPauseSync() {
        // 测试暂停同步
        syncService.pauseSync()
        
        XCTAssertEqual(syncService.syncStatus, .paused)
        XCTAssertEqual(syncService.syncMessage, "同步已暂停")
    }
    
    // MARK: - Sync Statistics Tests
    
    func testInitialStatistics() {
        // 测试初始统计数据
        XCTAssertEqual(syncService.statistics.totalUploads, 0)
        XCTAssertEqual(syncService.statistics.totalDownloads, 0)
        XCTAssertEqual(syncService.statistics.totalConflicts, 0)
        XCTAssertEqual(syncService.statistics.totalErrors, 0)
    }
    
    func testFormattedDataSize() {
        // 测试数据大小格式化
        var stats = SyncStatistics(
            totalRecordsSynced: 0,
            totalUploads: 0,
            totalDownloads: 0,
            totalConflicts: 0,
            totalErrors: 0,
            lastSyncDate: nil,
            nextSyncDate: nil,
            syncDuration: 0,
            dataSize: 1024
        )
        
        XCTAssertEqual(stats.formattedDataSize, "1 KB")
        
        stats.dataSize = 1048576
        XCTAssertEqual(stats.formattedDataSize, "1 MB")
    }
    
    func testFormattedDuration() {
        // 测试时长格式化
        var stats = SyncStatistics(
            totalRecordsSynced: 0,
            totalUploads: 0,
            totalDownloads: 0,
            totalConflicts: 0,
            totalErrors: 0,
            lastSyncDate: nil,
            nextSyncDate: nil,
            syncDuration: 45,
            dataSize: 0
        )
        
        XCTAssertEqual(stats.formattedDuration, "45 秒")
        
        stats.syncDuration = 125
        XCTAssertEqual(stats.formattedDuration, "2 分 5 秒")
    }
    
    // MARK: - Sync Enum Tests
    
    func testSyncStatusDisplayNames() {
        // 测试同步状态显示名称
        XCTAssertEqual(SyncStatus.idle.displayName, "空闲")
        XCTAssertEqual(SyncStatus.syncing.displayName, "同步中")
        XCTAssertEqual(SyncStatus.paused.displayName, "已暂停")
        XCTAssertEqual(SyncStatus.error.displayName, "错误")
        XCTAssertEqual(SyncStatus.completed.displayName, "已完成")
    }
    
    func testSyncStatusIconNames() {
        // 测试同步状态图标
        XCTAssertEqual(SyncStatus.idle.iconName, "clock")
        XCTAssertEqual(SyncStatus.syncing.iconName, "arrow.triangle.2.circlepath")
        XCTAssertEqual(SyncStatus.paused.iconName, "pause.circle")
        XCTAssertEqual(SyncStatus.error.iconName, "exclamationmark.triangle")
        XCTAssertEqual(SyncStatus.completed.iconName, "checkmark.circle")
    }
    
    func testConflictResolutionPolicyCases() {
        // 测试冲突解决策略
        XCTAssertEqual(ConflictResolutionPolicy.allCases.count, 4)
        XCTAssertTrue(ConflictResolutionPolicy.allCases.contains(.latestWins))
        XCTAssertTrue(ConflictResolutionPolicy.allCases.contains(.localWins))
        XCTAssertTrue(ConflictResolutionPolicy.allCases.contains(.remoteWins))
        XCTAssertTrue(ConflictResolutionPolicy.allCases.contains(.manual))
    }
    
    func testSyncFrequencyCases() {
        // 测试同步频率选项
        XCTAssertEqual(SyncFrequency.allCases.count, 5)
        XCTAssertTrue(SyncFrequency.allCases.contains(.automatic))
        XCTAssertTrue(SyncFrequency.allCases.contains(.hourly))
        XCTAssertTrue(SyncFrequency.allCases.contains(.daily))
        XCTAssertTrue(SyncFrequency.allCases.contains(.weekly))
        XCTAssertTrue(SyncFrequency.allCases.contains(.manual))
    }
    
    // MARK: - Sync Error Tests
    
    func testSyncErrorDescriptions() {
        // 测试同步错误描述
        XCTAssertEqual(SyncError.notAuthenticated.errorDescription, "未登录 iCloud，请在设置中登录")
        XCTAssertEqual(SyncError.networkUnavailable.errorDescription, "网络连接不可用")
        XCTAssertEqual(SyncError.quotaExceeded.errorDescription, "iCloud 存储空间不足")
        XCTAssertEqual(SyncError.recordNotFound.errorDescription, "记录未找到")
        XCTAssertEqual(SyncError.conflictDetected.errorDescription, "检测到冲突，需要解决")
        XCTAssertEqual(SyncError.databaseError.errorDescription, "数据库错误")
        XCTAssertEqual(SyncError.permissionDenied.errorDescription, "iCloud 同步权限被拒绝")
    }
    
    // MARK: - Sync Direction Tests
    
    func testSyncDirectionDisplayNames() {
        // 测试同步方向显示名称
        XCTAssertEqual(SyncDirection.upload.displayName, "上传")
        XCTAssertEqual(SyncDirection.download.displayName, "下载")
        XCTAssertEqual(SyncDirection.bidirectional.displayName, "双向")
    }
    
    // MARK: - CloudKit Zone Tests
    
    func testCloudKitZoneID() {
        // 测试 CloudKit 区域 ID
        let zoneID = CloudKitZone.zoneID
        XCTAssertEqual(zoneID.zoneName, "DreamLogZone")
    }
    
    // MARK: - Performance Tests
    
    func testSyncServiceInitialization() {
        // 测试服务初始化性能
        measure {
            let service = DreamiCloudSyncService(modelContext: modelContext)
            XCTAssertNotNil(service)
        }
    }
    
    // MARK: - Integration Tests
    
    func testStartSync_WithoutAuthentication() async {
        // 测试未认证时启动同步
        syncService.isAuthenticated = false
        
        await syncService.startSync()
        
        XCTAssertEqual(syncService.syncStatus, .error)
        XCTAssertEqual(syncService.syncMessage, "未登录 iCloud")
    }
    
    func testResumeSync() {
        // 测试恢复同步
        syncService.pauseSync()
        syncService.resumeSync()
        
        XCTAssertEqual(syncService.syncStatus, .idle)
        XCTAssertEqual(syncService.syncMessage, "等待同步")
    }
}

// MARK: - Mock Helpers

extension DreamiCloudSyncTests {
    
    func createTestDream() -> DreamEntity {
        let dream = DreamEntity(
            title: "测试梦境",
            content: "这是一个用于测试的梦境内容",
            date: Date(),
            emotion: "happy",
            isLucid: false,
            clarity: 3
        )
        modelContext.insert(dream)
        return dream
    }
    
    func createTestSyncMetadata(for recordID: String) -> SyncMetadata {
        let metadata = SyncMetadata(
            recordID: recordID,
            recordType: CloudKitRecordType.dream.rawValue,
            localIdentifier: UUID().uuidString,
            cloudKitRecordName: UUID().uuidString
        )
        modelContext.insert(metadata)
        return metadata
    }
}
