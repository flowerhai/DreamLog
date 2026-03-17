//
//  CloudSyncService.swift
//  DreamLog
//
//  iCloud 云同步服务：使用 CloudKit 实现跨设备数据同步
//

import Foundation
import CloudKit
import Combine

/// 云同步状态
enum CloudSyncStatus {
    case idle              // 空闲
    case syncing           // 同步中
    case success           // 同步成功
    case failed(String)    // 同步失败
    case unavailable       // 云同步不可用
    case conflict          // 检测到冲突
    
    var description: String {
        switch self {
        case .idle: return "未同步"
        case .syncing: return "同步中..."
        case .success: return "已同步"
        case .failed(let message): return "同步失败：\(message)"
        case .unavailable: return "云同步不可用"
        case .conflict: return "检测到冲突"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "☁️"
        case .syncing: return "🔄"
        case .success: return "✅"
        case .failed: return "❌"
        case .unavailable: return "⚠️"
        case .conflict: return "⚔️"
        }
    }
}

/// 同步冲突信息
struct SyncConflict {
    let dreamId: UUID
    let localVersion: Dream
    let cloudVersion: Dream
    let modifiedField: String
    
    var resolutionDescription: String {
        "梦境 '\(localVersion.title)' 在本地和云端都有修改"
    }
}

/// 云同步服务
@MainActor
class CloudSyncService: ObservableObject {
    @Published var syncStatus: CloudSyncStatus = .idle
    @Published var isCloudEnabled: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingChanges: Int = 0
    @Published var conflicts: [SyncConflict] = []
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "Dream"
    private var subscriptions: [AnyCancellable] = []
    private var syncHistory: [SyncHistoryEntry] = []
    
    // 单例
    static let shared = CloudSyncService()
    
    init(containerIdentifier: String = "iCloud.com.starry.dreamlog") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        
        checkCloudStatus()
        setupSubscriptions()
        loadSyncHistory()
    }
    
    // MARK: - 检查云状态
    
    /// 检查 iCloud 可用性
    func checkCloudStatus() {
        CKContainer(identifier: container.containerIdentifier).accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = .failed(error.localizedDescription)
                    self?.isCloudEnabled = false
                    return
                }
                
                switch status {
                case .available:
                    self?.isCloudEnabled = true
                    self?.syncStatus = .idle
                    self?.loadLastSyncDate()
                case .noAccount, .restricted, .couldNotDetermine:
                    self?.isCloudEnabled = false
                    self?.syncStatus = .unavailable
                @unknown default:
                    self?.isCloudEnabled = false
                    self?.syncStatus = .unavailable
                }
            }
        }
    }
    
    // MARK: - 同步操作
    
    /// 同步所有梦境到云端（增量同步）
    func syncAllDreams(_ dreams: [Dream]) {
        guard isCloudEnabled else {
            syncStatus = .unavailable
            return
        }
        
        syncStatus = .syncing
        pendingChanges = dreams.count
        conflicts.removeAll()
        
        // 先查询云端现有记录，进行增量同步
        fetchCloudDreams { [weak self] cloudDreams in
            guard let self = self else { return }
            
            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 3
            
            for dream in dreams {
                let operation = BlockOperation {
                    // 检查是否有冲突
                    if let cloudDream = cloudDreams.first(where: { $0.id == dream.id }) {
                        // 比较修改时间，检测冲突
                        if dream.updatedAt > cloudDream.updatedAt {
                            self.saveDreamToCloud(dream, recordName: dream.id.uuidString)
                        } else if cloudDream.updatedAt > dream.updatedAt {
                            // 云端版本更新，标记为冲突
                            let conflict = SyncConflict(
                                dreamId: dream.id,
                                localVersion: dream,
                                cloudVersion: cloudDream,
                                modifiedField: "content"
                            )
                            DispatchQueue.main.async {
                                self.conflicts.append(conflict)
                                self.syncStatus = .conflict
                            }
                        }
                    } else {
                        // 新梦境，直接保存
                        self.saveDreamToCloud(dream, recordName: dream.id.uuidString)
                    }
                }
                operationQueue.addOperation(operation)
            }
            
            operationQueue.addOperation { [weak self] in
                DispatchQueue.main.async {
                    if self?.conflicts.isEmpty ?? true {
                        self?.syncStatus = .success
                        self?.addSyncHistoryEntry(.push, count: dreams.count, success: true)
                    }
                    self?.pendingChanges = 0
                    self?.lastSyncDate = Date()
                    self?.saveLastSyncDate()
                    print("✅ 云同步完成：\(dreams.count) 个梦境")
                }
            }
        }
    }
    
    /// 从云端获取梦境列表
    private func fetchCloudDreams(completion: @escaping ([Dream]) -> Void) {
        guard isCloudEnabled else {
            completion([])
            return
        }
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        database.perform(query, in: .privateCloud) { records, error in
            if let error = error {
                print("⚠️ 查询云端记录失败：\(error)")
                completion([])
                return
            }
            
            guard let records = records else {
                completion([])
                return
            }
            
            let cloudDreams = records.compactMap { self.dream(from: $0) }
            completion(cloudDreams)
        }
    }
    
    /// 保存单个梦境到云端
    private func saveDreamToCloud(_ dream: Dream, recordName: String? = nil) {
        let recordName = recordName ?? dream.id.uuidString
        let record = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: recordName))
        
        record["title"] = dream.title as CKRecordValue
        record["content"] = dream.content as CKRecordValue
        record["originalText"] = dream.originalText as CKRecordValue
        record["date"] = dream.date as CKRecordValue
        record["timeOfDay"] = dream.timeOfDay.rawValue as CKRecordValue
        record["tags"] = dream.tags as CKRecordValue
        record["clarity"] = dream.clarity as CKRecordValue
        record["intensity"] = dream.intensity as CKRecordValue
        record["isLucid"] = dream.isLucid as CKRecordValue
        record["aiAnalysis"] = dream.aiAnalysis as CKRecordValue
        record["aiImageUrl"] = dream.aiImageUrl as CKRecordValue
        record["updatedAt"] = dream.updatedAt as CKRecordValue
        record["createdAt"] = dream.createdAt as CKRecordValue
        
        // 情绪数组需要特殊处理
        let emotionStrings = dream.emotions.map { $0.rawValue }
        record["emotions"] = emotionStrings as CKRecordValue
        
        database.save(record) { [weak self] savedRecord, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.syncStatus = .failed(error.localizedDescription)
                    self?.addSyncHistoryEntry(.push, count: 1, success: false, error: error.localizedDescription)
                    print("❌ 保存梦境到云端失败：\(error)")
                }
            } else {
                print("✅ 梦境 '\(dream.title)' 已保存到云端")
            }
        }
    }
    
    /// 从云端加载所有梦境
    func loadDreamsFromCloud(completion: @escaping ([Dream]) -> Void) {
        guard isCloudEnabled else {
            completion([])
            return
        }
        
        syncStatus = .syncing
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        database.perform(query, in: .privateCloud) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = .failed(error.localizedDescription)
                    print("❌ 从云端加载梦境失败：\(error)")
                    completion([])
                    return
                }
                
                guard let records = records else {
                    completion([])
                    return
                }
                
                let dreams = records.compactMap { self?.dream(from: $0) }
                self?.syncStatus = .success
                self?.lastSyncDate = Date()
                self?.saveLastSyncDate()
                print("✅ 从云端加载 \(dreams.count) 个梦境")
                completion(dreams)
            }
        }
    }
    
    /// 从 CKRecord 创建 Dream 对象
    private func dream(from record: CKRecord) -> Dream? {
        guard let title = record["title"] as? String,
              let content = record["content"] as? String,
              let originalText = record["originalText"] as? String,
              let date = record["date"] as? Date,
              let timeOfDayRaw = record["timeOfDay"] as? String,
              let tags = record["tags"] as? [String],
              let clarity = record["clarity"] as? Int,
              let intensity = record["intensity"] as? Int,
              let isLucid = record["isLucid"] as? Bool else {
            return nil
        }
        
        let timeOfDay = TimeOfDay(rawValue: timeOfDayRaw) ?? .morning
        
        var emotions: [Emotion] = []
        if let emotionStrings = record["emotions"] as? [String] {
            emotions = emotionStrings.compactMap { Emotion(rawValue: $0) }
        }
        
        let aiAnalysis = record["aiAnalysis"] as? String
        let aiImageUrl = record["aiImageUrl"] as? String
        
        return Dream(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            title: title,
            content: content,
            originalText: originalText,
            date: date,
            timeOfDay: timeOfDay,
            tags: tags,
            emotions: emotions,
            clarity: clarity,
            intensity: intensity,
            isLucid: isLucid,
            aiAnalysis: aiAnalysis,
            aiImageUrl: aiImageUrl
        )
    }
    
    /// 删除云端梦境
    func deleteDreamFromCloud(_ dreamId: UUID) {
        guard isCloudEnabled else { return }
        
        let recordID = CKRecord.ID(recordName: dreamId.uuidString)
        database.delete(withRecordID: recordID) { _, error in
            if let error = error {
                print("❌ 从云端删除梦境失败：\(error)")
            } else {
                print("✅ 梦境已从云端删除")
            }
        }
    }
    
    // MARK: - 订阅通知
    
    /// 设置云数据库变更订阅
    private func setupSubscriptions() {
        // 创建订阅以监听数据库变更
        let subscription = CKDatabaseSubscription(subscriptionID: "DreamChanges")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription) { _, error in
            if let error = error {
                print("⚠️ 创建订阅失败：\(error)")
            } else {
                print("✅ 云同步订阅已创建")
            }
        }
    }
    
    // MARK: - 本地持久化
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "cloudLastSyncDate")
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "cloudLastSyncDate") as? Date
    }
    
    // MARK: - 手动触发同步
    
    /// 立即同步
    func triggerSync(_ dreams: [Dream]) {
        checkCloudStatus()
        
        guard isCloudEnabled else {
            syncStatus = .unavailable
            return
        }
        
        syncAllDreams(dreams)
    }
    
    /// 从云端拉取
    func pullFromCloud(completion: @escaping ([Dream]) -> Void) {
        loadDreamsFromCloud(completion: completion)
    }
    
    /// 推送到云端
    func pushToCloud(_ dreams: [Dream]) {
        syncAllDreams(dreams)
    }
    
    // MARK: - 冲突解决
    
    /// 解决冲突 - 保留本地版本
    func resolveConflictKeepLocal(_ conflict: SyncConflict) {
        saveDreamToCloud(conflict.localVersion, recordName: conflict.dreamId.uuidString)
        conflicts.removeAll { $0.dreamId == conflict.dreamId }
        if conflicts.isEmpty {
            syncStatus = .success
        }
        addSyncHistoryEntry(.conflictResolved, count: 1, success: true, details: "保留本地版本")
    }
    
    /// 解决冲突 - 保留云端版本
    func resolveConflictKeepCloud(_ conflict: SyncConflict, completion: @escaping (Dream) -> Void) {
        conflicts.removeAll { $0.dreamId == conflict.dreamId }
        if conflicts.isEmpty {
            syncStatus = .success
        }
        addSyncHistoryEntry(.conflictResolved, count: 1, success: true, details: "保留云端版本")
        completion(conflict.cloudVersion)
    }
    
    /// 解决冲突 - 合并版本（保留两者内容）
    func resolveConflictMerge(_ conflict: SyncConflict) -> Dream {
        var merged = conflict.localVersion
        merged.content = conflict.localVersion.content + "\n\n---\n\n[云端版本]\n" + conflict.cloudVersion.content
        merged.updatedAt = Date()
        saveDreamToCloud(merged, recordName: conflict.dreamId.uuidString)
        conflicts.removeAll { $0.dreamId == conflict.dreamId }
        if conflicts.isEmpty {
            syncStatus = .success
        }
        addSyncHistoryEntry(.conflictResolved, count: 1, success: true, details: "合并版本")
        return merged
    }
    
    // MARK: - 同步历史
    
    /// 添加同步历史记录
    private func addSyncHistoryEntry(_ type: SyncHistoryType, count: Int, success: Bool, error: String? = nil, details: String? = nil) {
        let entry = SyncHistoryEntry(
            id: UUID(),
            timestamp: Date(),
            type: type,
            count: count,
            success: success,
            error: error,
            details: details
        )
        syncHistory.insert(entry, at: 0)
        
        // 只保留最近 100 条记录
        if syncHistory.count > 100 {
            syncHistory.removeLast()
        }
        
        saveSyncHistory()
        print("📝 同步历史：\(type.description) - \(count) 个项目 - \(success ? "成功" : "失败")")
    }
    
    /// 获取同步历史
    func getSyncHistory(limit: Int = 20) -> [SyncHistoryEntry] {
        Array(syncHistory.prefix(limit))
    }
    
    /// 保存同步历史
    private func saveSyncHistory() {
        if let encoded = try? JSONEncoder().encode(syncHistory) {
            UserDefaults.standard.set(encoded, forKey: "cloudSyncHistory")
        }
    }
    
    /// 加载同步历史
    private func loadSyncHistory() {
        if let data = UserDefaults.standard.data(forKey: "cloudSyncHistory"),
           let history = try? JSONDecoder().decode([SyncHistoryEntry].self, from: data) {
            syncHistory = history
        }
    }
    
    /// 清除同步历史
    func clearSyncHistory() {
        syncHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "cloudSyncHistory")
    }
}

// MARK: - 同步历史类型

enum SyncHistoryType: String, Codable {
    case push = "推送"
    case pull = "拉取"
    case autoSync = "自动同步"
    case conflictResolved = "冲突解决"
    case error = "错误"
    
    var description: String {
        switch self {
        case .push: return "☁️ 推送到云端"
        case .pull: return "📥 从云端拉取"
        case .autoSync: return "🔄 自动同步"
        case .conflictResolved: return "⚔️ 冲突解决"
        case .error: return "❌ 错误"
        }
    }
}

// MARK: - 同步历史记录

struct SyncHistoryEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: SyncHistoryType
    let count: Int
    let success: Bool
    let error: String?
    let details: String?
    
    var formattedDate: String {
        timestamp.formatted(.dateTime.year().month().day().hour().minute())
    }
    
    var statusIcon: String {
        success ? "✅" : "❌"
    }
}

// Note: Date, String, Int, Bool, and Array<String> already conform to CKRecordValue in CloudKit
// No additional extensions needed
