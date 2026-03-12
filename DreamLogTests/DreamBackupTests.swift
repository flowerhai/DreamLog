//
//  DreamBackupTests.swift
//  DreamLogTests
//
//  Phase 29 - Dream Backup & Restore System
//  Unit tests for backup functionality
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamBackupTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var backupService: DreamBackupService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            Dream.self,
            DreamTag.self,
            BackupHistory.self,
            BackupSchedule.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        backupService = DreamBackupService(modelContext: modelContext)
        
        // Create test dreams
        try await createTestDreams()
    }
    
    override func tearDown() async throws {
        backupService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Data Setup
    
    private func createTestDreams() throws {
        let tags = ["测试", "梦境", "AI"]
        
        for i in 1...5 {
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "这是第 \(i) 个测试梦境的内容。包含一些详细的描述和感受。",
                date: Date().addingTimeInterval(-Double(i) * 24 * 3600),
                clarity: Int.random(in: 1...5),
                intensity: Int.random(in: 1...5),
                isLucid: Bool.random(),
                emotions: ["开心", "惊讶", "平静"].randomSubarray(count: Int.random(in: 1...3)),
                location: nil,
                weather: nil,
                sleepQuality: Int.random(in: 1...5)
            )
            
            // Add tags
            for tagName in tags {
                let tag = DreamTag(name: tagName)
                dream.tags.append(tag)
            }
            
            modelContext.insert(dream)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Backup Creation Tests
    
    func testCreateBackup_Success() async throws {
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let result = await backupService.createBackup(options: options)
        
        XCTAssertTrue(result.success, "备份应该成功")
        XCTAssertNotNil(result.fileURL, "应该生成备份文件 URL")
        XCTAssertEqual(result.dreamCount, 5, "应该备份 5 条梦境")
        XCTAssertNil(result.errorMessage, "不应该有错误消息")
        
        // Verify file exists
        if let fileURL = result.fileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "备份文件应该存在")
        }
    }
    
    func testCreateBackup_WithEncryption() async throws {
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: true,
            backupPassword: "test_password_123"
        )
        
        let result = await backupService.createBackup(options: options)
        
        XCTAssertTrue(result.success, "加密备份应该成功")
        XCTAssertNotNil(result.fileURL, "应该生成备份文件 URL")
        XCTAssertEqual(result.dreamCount, 5, "应该备份 5 条梦境")
    }
    
    func testCreateBackup_WithDateRange() async throws {
        let endDate = Date()
        let startDate = Date().addingTimeInterval(-3 * 24 * 3600) // Last 3 days
        
        let options = BackupOptions(
            includeAllDreams: false,
            dateRange: (start: startDate, end: endDate),
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let result = await backupService.createBackup(options: options)
        
        XCTAssertTrue(result.success, "日期范围备份应该成功")
        XCTAssertGreaterThan(result.dreamCount, 0, "应该至少备份一些梦境")
        XCTAssertLessThanOrEqual(result.dreamCount, 5, "不应该超过总梦境数")
    }
    
    func testCreateBackup_EmptyResult() async throws {
        // Delete all dreams first
        let dreams = try modelContext.fetch(FetchDescriptor<Dream>())
        for dream in dreams {
            modelContext.delete(dream)
        }
        try modelContext.save()
        
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let result = await backupService.createBackup(options: options)
        
        XCTAssertFalse(result.success, "没有梦境时备份应该失败")
        XCTAssertNotNil(result.errorMessage, "应该有错误消息")
    }
    
    // MARK: - Restore Tests
    
    func testRestoreBackup_Success() async throws {
        // First create a backup
        let backupOptions = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let backupResult = await backupService.createBackup(options: backupOptions)
        XCTAssertTrue(backupResult.success, "备份应该成功")
        
        guard let backupFileURL = backupResult.fileURL else {
            XCTFail("备份文件 URL 不应该为 nil")
            return
        }
        
        // Delete all dreams
        let dreams = try modelContext.fetch(FetchDescriptor<Dream>())
        for dream in dreams {
            modelContext.delete(dream)
        }
        try modelContext.save()
        
        // Verify dreams are deleted
        let remainingDreams = try modelContext.fetch(FetchDescriptor<Dream>())
        XCTAssertEqual(remainingDreams.count, 0, "所有梦境应该被删除")
        
        // Restore from backup
        let restoreResult = await backupService.restoreBackup(from: backupFileURL, password: nil)
        
        XCTAssertTrue(restoreResult.success, "恢复应该成功")
        XCTAssertEqual(restoreResult.dreamsRestored, 5, "应该恢复 5 条梦境")
        XCTAssertEqual(restoreResult.skippedDuplicates, 0, "不应该跳过重复项")
        
        // Verify dreams are restored
        let restoredDreams = try modelContext.fetch(FetchDescriptor<Dream>())
        XCTAssertEqual(restoredDreams.count, 5, "应该有 5 条梦境")
    }
    
    func testRestoreBackup_WithSkipDuplicates() async throws {
        // Create backup
        let backupOptions = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let backupResult = await backupService.createBackup(options: backupOptions)
        XCTAssertTrue(backupResult.success)
        
        guard let backupFileURL = backupResult.fileURL else {
            XCTFail("备份文件 URL 不应该为 nil")
            return
        }
        
        // Don't delete dreams, restore directly (should skip duplicates)
        let restoreResult = await backupService.restoreBackup(
            from: backupFileURL,
            password: nil,
            skipDuplicates: true
        )
        
        XCTAssertTrue(restoreResult.success, "恢复应该成功")
        XCTAssertEqual(restoreResult.dreamsRestored, 0, "应该跳过所有重复的梦境")
        XCTAssertEqual(restoreResult.skippedDuplicates, 5, "应该跳过 5 条重复梦境")
    }
    
    func testRestoreBackup_WithEncryption() async throws {
        let password = "test_password_123"
        
        // Create encrypted backup
        let backupOptions = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: true,
            backupPassword: password
        )
        
        let backupResult = await backupService.createBackup(options: backupOptions)
        XCTAssertTrue(backupResult.success, "加密备份应该成功")
        
        guard let backupFileURL = backupResult.fileURL else {
            XCTFail("备份文件 URL 不应该为 nil")
            return
        }
        
        // Delete dreams
        let dreams = try modelContext.fetch(FetchDescriptor<Dream>())
        for dream in dreams {
            modelContext.delete(dream)
        }
        try modelContext.save()
        
        // Restore with correct password
        let restoreResult = await backupService.restoreBackup(from: backupFileURL, password: password)
        
        XCTAssertTrue(restoreResult.success, "使用正确密码恢复应该成功")
        XCTAssertEqual(restoreResult.dreamsRestored, 5, "应该恢复 5 条梦境")
    }
    
    func testRestoreBackup_WrongPassword() async throws {
        let password = "test_password_123"
        let wrongPassword = "wrong_password"
        
        // Create encrypted backup
        let backupOptions = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: true,
            backupPassword: password
        )
        
        let backupResult = await backupService.createBackup(options: backupOptions)
        XCTAssertTrue(backupResult.success)
        
        guard let backupFileURL = backupResult.fileURL else {
            XCTFail("备份文件 URL 不应该为 nil")
            return
        }
        
        // Try to restore with wrong password
        let restoreResult = await backupService.restoreBackup(from: backupFileURL, password: wrongPassword)
        
        XCTAssertFalse(restoreResult.success, "使用错误密码恢复应该失败")
        XCTAssertNotNil(restoreResult.errorMessage, "应该有错误消息")
    }
    
    // MARK: - Backup History Tests
    
    func testBackupHistory_Created() async throws {
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        _ = await backupService.createBackup(options: options)
        
        // Check backup history
        let history = try modelContext.fetch(FetchDescriptor<BackupHistory>())
        
        XCTAssertGreaterThan(history.count, 0, "应该创建备份历史记录")
        
        let latestHistory = history.first!
        XCTAssertEqual(latestHistory.dreamCount, 5, "梦境数量应该正确")
        XCTAssertEqual(latestHistory.backupType, .manual, "备份类型应该是手动")
        XCTAssertEqual(latestHistory.verificationStatus, .verified, "验证状态应该是已验证")
    }
    
    // MARK: - Backup Schedule Tests
    
    func testBackupSchedule_CreateAndUpdate() throws {
        // Create schedule
        let schedule = BackupSchedule(
            isEnabled: true,
            frequency: .daily,
            time: Date(),
            keepLastNBackups: 7
        )
        
        modelContext.insert(schedule)
        try modelContext.save()
        
        // Fetch and verify
        let schedules = try modelContext.fetch(FetchDescriptor<BackupSchedule>())
        XCTAssertEqual(schedules.count, 1, "应该有 1 个备份计划")
        
        let fetchedSchedule = schedules.first!
        XCTAssertTrue(fetchedSchedule.isEnabled, "计划应该启用")
        XCTAssertEqual(fetchedSchedule.frequency, .daily, "频率应该是每天")
        XCTAssertEqual(fetchedSchedule.keepLastNBackups, 7, "应该保留 7 个备份")
        
        // Update schedule
        fetchedSchedule.isEnabled = false
        fetchedSchedule.frequency = .weekly
        try modelContext.save()
        
        // Verify update
        let updatedSchedules = try modelContext.fetch(FetchDescriptor<BackupSchedule>())
        let updatedSchedule = updatedSchedules.first!
        XCTAssertFalse(updatedSchedule.isEnabled, "计划应该禁用")
        XCTAssertEqual(updatedSchedule.frequency, .weekly, "频率应该更新为每周")
    }
    
    func testBackupSchedule_NextBackupDate() throws {
        let schedule = BackupSchedule(
            isEnabled: true,
            frequency: .daily,
            time: Date(),
            lastBackupDate: Date(),
            keepLastNBackups: 5
        )
        
        let calendar = Calendar.current
        let nextDate = calendar.date(byAdding: .day, value: 1, to: schedule.lastBackupDate!)!
        
        XCTAssertGreaterThan(nextDate, schedule.lastBackupDate!, "下次备份日期应该晚于上次")
    }
    
    // MARK: - Backup Management Tests
    
    func testGetAvailableBackups() async throws {
        // Create multiple backups
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        for _ in 1...3 {
            _ = await backupService.createBackup(options: options)
            try await Task.sleep(nanoseconds: 100_000_000) // Small delay to ensure unique timestamps
        }
        
        let backups = backupService.getAvailableBackups()
        
        XCTAssertGreaterThanOrEqual(backups.count, 3, "应该至少有 3 个备份文件")
    }
    
    func testDeleteBackup() async throws {
        // Create backup
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let result = await backupService.createBackup(options: options)
        XCTAssertTrue(result.success)
        
        guard let backupFileURL = result.fileURL else {
            XCTFail("备份文件 URL 不应该为 nil")
            return
        }
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupFileURL.path), "备份文件应该存在")
        
        // Delete backup
        try backupService.deleteBackup(at: backupFileURL)
        
        // Verify file is deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: backupFileURL.path), "备份文件应该被删除")
    }
    
    // MARK: - Performance Tests
    
    func testBackupPerformance() async throws {
        // Create more test dreams
        for i in 6...50 {
            let dream = Dream(
                title: "性能测试梦境 \(i)",
                content: String(repeating: "这是测试内容。", count: 100),
                date: Date().addingTimeInterval(-Double(i) * 24 * 3600),
                clarity: Int.random(in: 1...5),
                intensity: Int.random(in: 1...5),
                isLucid: Bool.random(),
                emotions: ["开心", "惊讶", "平静"],
                sleepQuality: Int.random(in: 1...5)
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
        
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let startTime = Date()
        let result = await backupService.createBackup(options: options)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(result.success, "备份应该成功")
        XCTAssertLessThan(duration, 10.0, "备份 50 条梦境应该在 10 秒内完成")
        
        print("备份 50 条梦境耗时：\(String(format: "%.2f", duration))秒")
    }
    
    // MARK: - Edge Case Tests
    
    func testBackup_WithSpecialCharacters() async throws {
        // Create dream with special characters
        let dream = Dream(
            title: "特殊字符测试！@#$%^&*()",
            content: "包含特殊字符：\n\t 换行符、制表符、引号\"'和 emoji 🌙✨🎨",
            date: Date(),
            clarity: 5,
            intensity: 5,
            isLucid: true,
            emotions: ["兴奋"],
            sleepQuality: 5
        )
        modelContext.insert(dream)
        try modelContext.save()
        
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let result = await backupService.createBackup(options: options)
        
        XCTAssertTrue(result.success, "包含特殊字符的备份应该成功")
    }
    
    func testBackup_WithVeryLongContent() async throws {
        // Create dream with very long content
        let longContent = String(repeating: "这是一段很长的内容。", count: 10000)
        let dream = Dream(
            title: "长内容测试",
            content: longContent,
            date: Date(),
            clarity: 5,
            intensity: 5,
            isLucid: false,
            emotions: ["平静"],
            sleepQuality: 4
        )
        modelContext.insert(dream)
        try modelContext.save()
        
        let options = BackupOptions(
            includeAllDreams: true,
            includeAudio: false,
            includeImages: false,
            includeMetadata: true,
            encryptBackup: false
        )
        
        let result = await backupService.createBackup(options: options)
        
        XCTAssertTrue(result.success, "包含长内容的备份应该成功")
    }
}

// MARK: - Helper Extensions

extension Array {
    func randomSubarray(count: Int) -> [Element] {
        guard count <= self.count else { return self }
        return Array(self.shuffled().prefix(count))
    }
}
