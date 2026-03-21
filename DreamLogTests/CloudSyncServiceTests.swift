//
//  CloudSyncServiceTests.swift
//  DreamLogTests
//
//  iCloud 云同步服务单元测试
//  测试 CloudKit 同步功能、冲突检测和解决
//

import XCTest
import CloudKit
@testable import DreamLog

// MARK: - 云同步状态测试

final class CloudSyncStatusTests: XCTestCase {
    
    func testStatusDescription() {
        XCTAssertEqual(CloudSyncStatus.idle.description, "未同步")
        XCTAssertEqual(CloudSyncStatus.syncing.description, "同步中...")
        XCTAssertEqual(CloudSyncStatus.success.description, "已同步")
        XCTAssertEqual(CloudSyncStatus.failed("错误").description, "同步失败：错误")
        XCTAssertEqual(CloudSyncStatus.unavailable.description, "云同步不可用")
        XCTAssertEqual(CloudSyncStatus.conflict.description, "检测到冲突")
    }
    
    func testStatusIcon() {
        XCTAssertEqual(CloudSyncStatus.idle.icon, "☁️")
        XCTAssertEqual(CloudSyncStatus.syncing.icon, "🔄")
        XCTAssertEqual(CloudSyncStatus.success.icon, "✅")
        XCTAssertEqual(CloudSyncStatus.failed("错误").icon, "❌")
        XCTAssertEqual(CloudSyncStatus.unavailable.icon, "⚠️")
        XCTAssertEqual(CloudSyncStatus.conflict.icon, "⚔️")
    }
}

// MARK: - 同步冲突信息测试

final class SyncConflictTests: XCTestCase {
    
    func testConflictDescription() {
        let dream = Dream(
            date: Date(),
            content: "测试梦境",
            emotion: "平静",
            mood: 4.0,
            clarity: 3.5,
            duration: 45.0,
            tags: [],
            aiAnalysisSummary: nil
        )
        
        let conflict = SyncConflict(
            dreamId: UUID(),
            localVersion: dream,
            cloudVersion: dream,
            modifiedField: "content"
        )
        
        XCTAssertTrue(conflict.resolutionDescription.contains("梦境"))
        XCTAssertTrue(conflict.resolutionDescription.contains("本地和云端都有修改"))
    }
}

// MARK: - 云同步历史测试

final class SyncHistoryEntryTests: XCTestCase {
    
    func testSyncTypeRawValues() {
        XCTAssertEqual(SyncType.manual.rawValue, "manual")
        XCTAssertEqual(SyncType.automatic.rawValue, "automatic")
        XCTAssertEqual(SyncType.background.rawValue, "background")
    }
    
    func testSyncResultRawValues() {
        XCTAssertEqual(SyncResult.success.rawValue, "success")
        XCTAssertEqual(SyncResult.failed.rawValue, "failed")
        XCTAssertEqual(SyncResult.partial.rawValue, "partial")
        XCTAssertEqual(SyncResult.conflict.rawValue, "conflict")
    }
    
    func testSyncHistoryEntryCreation() {
        let entry = SyncHistoryEntry(
            date: Date(),
            type: .manual,
            result: .success,
            recordsSynced: 10,
            errorMessage: nil
        )
        
        XCTAssertEqual(entry.type, .manual)
        XCTAssertEqual(entry.result, .success)
        XCTAssertEqual(entry.recordsSynced, 10)
        XCTAssertNil(entry.errorMessage)
        XCTAssertEqual(entry.statusDescription, "同步成功")
    }
    
    func testFailedSyncEntry() {
        let entry = SyncHistoryEntry(
            date: Date(),
            type: .automatic,
            result: .failed,
            recordsSynced: 0,
            errorMessage: "网络错误"
        )
        
        XCTAssertEqual(entry.result, .failed)
        XCTAssertEqual(entry.recordsSynced, 0)
        XCTAssertEqual(entry.errorMessage, "网络错误")
        XCTAssertEqual(entry.statusDescription, "同步失败：网络错误")
    }
}

// MARK: - 云同步配置测试

final class CloudSyncConfigTests: XCTestCase {
    
    func testDefaultConfig() {
        let config = CloudSyncConfig()
        
        XCTAssertTrue(config.autoSyncEnabled)
        XCTAssertEqual(config.autoSyncInterval, 300) // 5 分钟
        XCTAssertTrue(config.syncOnWifiOnly)
        XCTAssertFalse(config.syncAudioFiles)
        XCTAssertEqual(config.conflictResolution, .keepBoth)
    }
    
    func testConfigCodable() throws {
        var config = CloudSyncConfig()
        config.autoSyncEnabled = false
        config.autoSyncInterval = 600
        config.syncOnWifiOnly = false
        config.syncAudioFiles = true
        config.conflictResolution = .keepNewest
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(CloudSyncConfig.self, from: data)
        
        XCTAssertEqual(decodedConfig.autoSyncEnabled, false)
        XCTAssertEqual(decodedConfig.autoSyncInterval, 600)
        XCTAssertEqual(decodedConfig.syncOnWifiOnly, false)
        XCTAssertEqual(decodedConfig.syncAudioFiles, true)
        XCTAssertEqual(decodedConfig.conflictResolution, .keepNewest)
    }
}

// MARK: - 冲突解决策略测试

final class ConflictResolutionTests: XCTestCase {
    
    func testResolutionRawValues() {
        XCTAssertEqual(ConflictResolution.keepLocal.rawValue, "keepLocal")
        XCTAssertEqual(ConflictResolution.keepCloud.rawValue, "keepCloud")
        XCTAssertEqual(ConflictResolution.keepNewest.rawValue, "keepNewest")
        XCTAssertEqual(ConflictResolution.keepBoth.rawValue, "keepBoth")
        XCTAssertEqual(ConflictResolution.manual.rawValue, "manual")
    }
    
    func testResolutionDescription() {
        XCTAssertEqual(ConflictResolution.keepLocal.description, "保留本地版本")
        XCTAssertEqual(ConflictResolution.keepCloud.description, "保留云端版本")
        XCTAssertEqual(ConflictResolution.keepNewest.description, "保留最新版本")
        XCTAssertEqual(ConflictResolution.keepBoth.description, "保留两个版本")
        XCTAssertEqual(ConflictResolution.manual.description, "手动选择")
    }
}

// MARK: - 云同步服务模拟测试

@MainActor
final class CloudSyncServiceMockTests: XCTestCase {
    
    var service: CloudSyncService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = CloudSyncService.shared
    }
    
    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }
    
    func testServiceInitialization() {
        XCTAssertNotNil(service)
        XCTAssertEqual(service.syncStatus, .idle)
        XCTAssertFalse(service.isCloudEnabled) // 模拟器中 CloudKit 不可用
    }
    
    func testInitialProperties() {
        XCTAssertEqual(service.syncStatus, .idle)
        XCTAssertFalse(service.isCloudEnabled)
        XCTAssertNil(service.lastSyncDate)
        XCTAssertEqual(service.pendingChanges, 0)
        XCTAssertTrue(service.conflicts.isEmpty)
    }
    
    func testSyncStatusTransitions() {
        // 初始状态
        XCTAssertEqual(service.syncStatus, .idle)
        
        // 模拟状态变化（实际测试中需要 mock CloudKit）
        service.syncStatus = .syncing
        XCTAssertEqual(service.syncStatus, .syncing)
        
        service.syncStatus = .success
        XCTAssertEqual(service.syncStatus, .success)
    }
}

// MARK: - 云同步工具方法测试

final class CloudSyncUtilityTests: XCTestCase {
    
    func testRecordIDGeneration() {
        let dreamId = UUID()
        let recordId = CKRecord.ID(recordName: dreamId.uuidString, zoneID: CKRecordZone.Default)
        
        XCTAssertEqual(recordId.recordName, dreamId.uuidString)
        XCTAssertEqual(recordId.zoneID, CKRecordZone.Default)
    }
    
    func testRecordZoneCreation() {
        let zoneID = CKRecordZone.ID(zoneName: "DreamLogZone", ownerName: CKOwnerDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        
        XCTAssertEqual(zone.zoneID.zoneName, "DreamLogZone")
    }
    
    func testQueryCreation() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Dream", predicate: predicate)
        
        XCTAssertEqual(query.recordType, "Dream")
        XCTAssertEqual(query.predicate, predicate)
    }
    
    func testDateEncoding() {
        let date = Date()
        let record = CKRecord(recordType: "Dream")
        record["date"] = CKRecord.Field.date(date)
        
        let retrievedDate = record["date"] as? Date
        XCTAssertEqual(retrievedDate, date)
    }
}

// MARK: - 性能测试

final class CloudSyncPerformanceTests: XCTestCase {
    
    func testSyncHistoryEntryCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = SyncHistoryEntry(
                    date: Date(),
                    type: .automatic,
                    result: .success,
                    recordsSynced: Int.random(in: 0...100),
                    errorMessage: nil
                )
            }
        }
    }
    
    func testConflictCreationPerformance() {
        let dream = Dream(
            date: Date(),
            content: "测试梦境",
            emotion: "平静",
            mood: 4.0,
            clarity: 3.5,
            duration: 45.0,
            tags: [],
            aiAnalysisSummary: nil
        )
        
        measure {
            for _ in 0..<100 {
                _ = SyncConflict(
                    dreamId: UUID(),
                    localVersion: dream,
                    cloudVersion: dream,
                    modifiedField: "content"
                )
            }
        }
    }
}

// MARK: - 边界条件测试

final class CloudSyncEdgeCasesTests: XCTestCase {
    
    func testEmptySyncHistory() {
        let config = CloudSyncConfig()
        XCTAssertNotNil(config)
    }
    
    func testZeroRecordsSynced() {
        let entry = SyncHistoryEntry(
            date: Date(),
            type: .background,
            result: .success,
            recordsSynced: 0,
            errorMessage: nil
        )
        
        XCTAssertEqual(entry.recordsSynced, 0)
        XCTAssertEqual(entry.result, .success)
    }
    
    func testLongErrorMessage() {
        let longMessage = String(repeating: "错误详情 ", count: 100)
        let entry = SyncHistoryEntry(
            date: Date(),
            type: .manual,
            result: .failed,
            recordsSynced: 0,
            errorMessage: longMessage
        )
        
        XCTAssertEqual(entry.errorMessage, longMessage)
        XCTAssertTrue(entry.statusDescription.contains(longMessage))
    }
    
    func testMaxAutoSyncInterval() {
        var config = CloudSyncConfig()
        config.autoSyncInterval = 86400 // 24 小时
        
        XCTAssertEqual(config.autoSyncInterval, 86400)
    }
    
    func testMinAutoSyncInterval() {
        var config = CloudSyncConfig()
        config.autoSyncInterval = 60 // 1 分钟
        
        XCTAssertEqual(config.autoSyncInterval, 60)
    }
}

// MARK: - 枚举完整性测试

final class CloudSyncEnumCompletenessTests: XCTestCase {
    
    func testAllSyncTypesCovered() {
        let allTypes: [SyncType] = [.manual, .automatic, .background]
        
        for type in allTypes {
            switch type {
            case .manual:
                XCTAssertEqual(type.rawValue, "manual")
            case .automatic:
                XCTAssertEqual(type.rawValue, "automatic")
            case .background:
                XCTAssertEqual(type.rawValue, "background")
            }
        }
    }
    
    func testAllSyncResultsCovered() {
        let allResults: [SyncResult] = [.success, .failed, .partial, .conflict]
        
        for result in allResults {
            switch result {
            case .success:
                XCTAssertEqual(result.rawValue, "success")
            case .failed:
                XCTAssertEqual(result.rawValue, "failed")
            case .partial:
                XCTAssertEqual(result.rawValue, "partial")
            case .conflict:
                XCTAssertEqual(result.rawValue, "conflict")
            }
        }
    }
    
    func testAllConflictResolutionsCovered() {
        let allResolutions: [ConflictResolution] = [.keepLocal, .keepCloud, .keepNewest, .keepBoth, .manual]
        
        for resolution in allResolutions {
            switch resolution {
            case .keepLocal:
                XCTAssertEqual(resolution.description, "保留本地版本")
            case .keepCloud:
                XCTAssertEqual(resolution.description, "保留云端版本")
            case .keepNewest:
                XCTAssertEqual(resolution.description, "保留最新版本")
            case .keepBoth:
                XCTAssertEqual(resolution.description, "保留两个版本")
            case .manual:
                XCTAssertEqual(resolution.description, "手动选择")
            }
        }
    }
}
