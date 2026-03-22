//
//  DreamiCloudSyncService.swift
//  DreamLog - Phase 88: iCloud CloudKit Sync
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import CloudKit
import SwiftData
import Combine

// MARK: - iCloud Sync Service

/// iCloud 云同步服务
@MainActor
final class DreamiCloudSyncService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DreamiCloudSyncService()
    
    // MARK: - Published Properties
    
    @Published var isAvailable: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var syncMessage: String = "等待同步"
    @Published var statistics: SyncStatistics = SyncStatistics(
        totalRecordsSynced: 0,
        totalUploads: 0,
        totalDownloads: 0,
        totalConflicts: 0,
        totalErrors: 0,
        lastSyncDate: nil,
        nextSyncDate: nil,
        syncDuration: 0,
        dataSize: 0
    )
    @Published var conflicts: [SyncConflict] = []
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private let modelContext: ModelContext
    private let queue = DispatchQueue(label: "com.dreamlog.icloudsync", qos: .utility)
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.container = CKContainer(identifier: "iCloud.com.dreamlog.app")
        self.database = container.privateCloudDatabase
        
        setupObservers()
        checkAvailability()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // 监听 iCloud 账号状态变化
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkAuthentication()
            }
            .store(in: &cancellables)
        
        // 监听网络状态变化
        NotificationCenter.default.publisher(for: .NSNetworkReachabilityDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkAvailability()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Availability & Authentication
    
    /// 检查 iCloud 可用性
    func checkAvailability() {
        CKContainer(identifier: "iCloud.com.dreamlog.app").accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.isAvailable = (status == .available)
                self?.isAuthenticated = (status == .available)
                
                if let error = error {
                    print("iCloud 检查错误：\(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 检查认证状态
    func checkAuthentication() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isAuthenticated = true
                    self?.isAvailable = true
                case .noAccount, .restricted, .couldNotDetermine:
                    self?.isAuthenticated = false
                    self?.isAvailable = false
                @unknown default:
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Setup Zone
    
    /// 创建自定义区域
    func setupZone() async throws {
        let zone = CloudKitZone.sharedZone
        
        do {
            try await database.save(zone)
            print("CloudKit 区域创建成功")
        } catch CKError.zoneAlreadyExists {
            print("CloudKit 区域已存在")
        } catch {
            print("创建 CloudKit 区域失败：\(error)")
            throw error
        }
    }
    
    // MARK: - Sync Operations
    
    /// 开始同步
    func startSync() async {
        guard isAuthenticated else {
            syncStatus = .error
            syncMessage = "未登录 iCloud"
            return
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        syncMessage = "准备同步..."
        
        let startTime = Date()
        var uploads = 0
        var downloads = 0
        var conflicts = 0
        var errors = 0
        
        do {
            // 1. 设置区域
            try await setupZone()
            
            // 2. 获取同步配置
            let config = try getSyncConfig()
            
            // 3. 同步梦境
            if config.syncDreams {
                let result = try await syncDreams()
                uploads += result.uploads
                downloads += result.downloads
                conflicts += result.conflicts
                errors += result.errors
            }
            
            // 4. 同步收藏集
            if config.syncCollections {
                let result = try await syncCollections()
                uploads += result.uploads
                downloads += result.downloads
                conflicts += result.conflicts
                errors += result.errors
            }
            
            // 5. 更新统计
            let duration = Date().timeIntervalSince(startTime)
            await MainActor.run {
                self.statistics.totalUploads += uploads
                self.statistics.totalDownloads += downloads
                self.statistics.totalConflicts += conflicts
                self.statistics.totalErrors += errors
                self.statistics.totalRecordsSynced += (uploads + downloads)
                self.statistics.lastSyncDate = Date()
                self.statistics.syncDuration = duration
                self.lastSyncDate = Date()
                self.syncStatus = .completed
                self.syncProgress = 1.0
                self.syncMessage = "同步完成"
            }
            
            // 6. 更新配置
            try await updateSyncConfig { config in
                config.lastSyncDate = Date()
                config.syncStatus = .completed
                config.updatedAt = Date()
            }
            
        } catch {
            await MainActor.run {
                self.syncStatus = .error
                self.syncMessage = "同步失败：\(error.localizedDescription)"
                self.statistics.totalErrors += 1
            }
        }
        
        // 重置状态
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            if self.syncStatus == .completed {
                self.syncStatus = .idle
                self.syncMessage = "等待同步"
            }
        }
    }
    
    /// 同步梦境
    private func syncDreams() async throws -> SyncResult {
        var result = SyncResult(uploads: 0, downloads: 0, conflicts: 0, errors: 0)
        
        // 获取本地梦境
        let localDreams = try modelContext.fetch(FetchDescriptor<DreamEntity>())
        
        // 获取云端梦境
        let query = CKQuery(recordType: .dream, predicate: NSPredicate(value: true))
        let cloudDreams = try await database.records(matching: query).results
        
        // 上传本地修改
        for dream in localDreams {
            do {
                try await uploadDream(dream)
                result.uploads += 1
            } catch {
                print("上传梦境失败：\(error)")
                result.errors += 1
            }
        }
        
        // 下载云端修改
        for case .success(let record) in cloudDreams {
            do {
                try await downloadDream(record)
                result.downloads += 1
            } catch {
                print("下载梦境失败：\(error)")
                result.errors += 1
            }
        }
        
        return result
    }
    
    /// 上传梦境
    private func uploadDream(_ dream: DreamEntity) async throws {
        let record = CKRecord(recordType: CloudKitRecordType.dream.rawValue)
        
        // 设置记录字段
        record["title"] = CKAsset(fileURL: createTempFile(with: dream.title ?? ""))
        record["content"] = CKAsset(fileURL: createTempFile(with: dream.content ?? ""))
        record["date"] = dream.date as CKRecordValue
        record["emotion"] = dream.emotion as CKRecordValue
        record["isLucid"] = dream.isLucid as CKRecordValue
        record["clarity"] = dream.clarity as CKRecordValue
        record["modifiedDate"] = Date() as CKRecordValue
        record["version"] = 1 as CKRecordValue
        
        // 保存到云端
        try await database.save(record)
        
        // 更新同步元数据
        try updateSyncMetadata(for: dream, cloudKitRecordName: record.recordID.recordName)
    }
    
    /// 下载梦境
    private func downloadDream(_ record: CKRecord) async throws {
        // 检查是否已存在
        let metadata = try modelContext.fetch(FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.cloudKitRecordName == record.recordID.recordName }
        ))
        
        if metadata.isEmpty {
            // 新记录，创建本地梦境
            try createDream(from: record)
        } else {
            // 已存在，检查冲突
            try handleConflict(for: record, localMetadata: metadata.first!)
        }
    }
    
    /// 同步收藏集
    private func syncCollections() async throws -> SyncResult {
        // TODO: 实现收藏集同步
        return SyncResult(uploads: 0, downloads: 0, conflicts: 0, errors: 0)
    }
    
    // MARK: - Helper Methods
    
    private func getSyncConfig() throws -> iCloudSyncConfig {
        let configs = try modelContext.fetch(FetchDescriptor<iCloudSyncConfig>())
        if let config = configs.first {
            return config
        }
        
        // 创建默认配置
        let config = iCloudSyncConfig()
        modelContext.insert(config)
        try modelContext.save()
        return config
    }
    
    private func updateSyncConfig(_ update: (iCloudSyncConfig) -> Void) async throws {
        let configs = try modelContext.fetch(FetchDescriptor<iCloudSyncConfig>())
        if var config = configs.first {
            update(config)
            try modelContext.save()
        }
    }
    
    private func createTempFile(with string: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(UUID().uuidString)
        try? string.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func updateSyncMetadata(for dream: DreamEntity, cloudKitRecordName: String) throws {
        let metadata = SyncMetadata(
            recordID: dream.id?.uuidString ?? UUID().uuidString,
            recordType: CloudKitRecordType.dream.rawValue,
            localIdentifier: dream.id?.uuidString ?? UUID().uuidString,
            cloudKitRecordName: cloudKitRecordName
        )
        modelContext.insert(metadata)
        try modelContext.save()
    }
    
    private func createDream(from record: CKRecord) throws {
        // TODO: 从 CKRecord 创建 DreamEntity
    }
    
    private func handleConflict(for record: CKRecord, localMetadata: SyncMetadata) throws {
        // TODO: 实现冲突处理
    }
    
    // MARK: - Conflict Resolution
    
    /// 解决冲突
    func resolveConflict(_ conflict: SyncConflict, choice: ConflictChoice) async {
        // TODO: 实现冲突解决
    }
    
    // MARK: - Manual Sync Control
    
    /// 暂停同步
    func pauseSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        syncStatus = .paused
        syncMessage = "同步已暂停"
    }
    
    /// 恢复同步
    func resumeSync() {
        syncStatus = .idle
        syncMessage = "等待同步"
        startScheduledSync()
    }
    
    /// 启动定时同步
    func startScheduledSync() {
        syncTimer?.invalidate()
        
        guard let config = try? getSyncConfig(),
              config.isEnabled,
              config.syncFrequency != .manual else {
            return
        }
        
        let interval: TimeInterval
        switch config.syncFrequency {
        case .hourly: interval = 3600
        case .daily: interval = 86400
        case .weekly: interval = 604800
        case .automatic, .manual: return
        }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.startSync()
            }
        }
    }
}

// MARK: - Supporting Types

struct SyncResult {
    var uploads: Int
    var downloads: Int
    var conflicts: Int
    var errors: Int
}

struct SyncConflict: Identifiable {
    let id = UUID()
    let recordID: String
    let recordType: String
    let localData: Data
    let cloudData: Data
    let localModifiedDate: Date
    let cloudModifiedDate: Date
}

enum ConflictChoice {
    case useLocal
    case useCloud
    case merge
}

// MARK: - Notifications

extension Notification.Name {
    static let iCloudSyncDidStart = Notification.Name("iCloudSyncDidStart")
    static let iCloudSyncDidComplete = Notification.Name("iCloudSyncDidComplete")
    static let iCloudSyncDidFail = Notification.Name("iCloudSyncDidFail")
    static let iCloudSyncConflictDetected = Notification.Name("iCloudSyncConflictDetected")
}
