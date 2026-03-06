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
    
    var description: String {
        switch self {
        case .idle: return "未同步"
        case .syncing: return "同步中..."
        case .success: return "已同步"
        case .failed(let message): return "同步失败：\(message)"
        case .unavailable: return "云同步不可用"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "☁️"
        case .syncing: return "🔄"
        case .success: return "✅"
        case .failed: return "❌"
        case .unavailable: return "⚠️"
        }
    }
}

/// 云同步服务
class CloudSyncService: ObservableObject {
    @Published var syncStatus: CloudSyncStatus = .idle
    @Published var isCloudEnabled: Bool = false
    @Published var lastSyncDate: Date?
    @Published var pendingChanges: Int = 0
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "Dream"
    private var subscriptions: [AnyCancellable] = []
    
    // 单例
    static let shared = CloudSyncService()
    
    init(containerIdentifier: String = "iCloud.com.starry.dreamlog") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        
        checkCloudStatus()
        setupSubscriptions()
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
    
    /// 同步所有梦境到云端
    func syncAllDreams(_ dreams: [Dream]) {
        guard isCloudEnabled else {
            syncStatus = .unavailable
            return
        }
        
        syncStatus = .syncing
        pendingChanges = dreams.count
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 3
        
        for dream in dreams {
            let operation = BlockOperation { [weak self] in
                self?.saveDreamToCloud(dream)
            }
            operationQueue.addOperation(operation)
        }
        
        operationQueue.addOperation { [weak self] in
            DispatchQueue.main.async {
                self?.syncStatus = .success
                self?.pendingChanges = 0
                self?.lastSyncDate = Date()
                self?.saveLastSyncDate()
                print("✅ 云同步完成：\(dreams.count) 个梦境")
            }
        }
    }
    
    /// 保存单个梦境到云端
    private func saveDreamToCloud(_ dream: Dream) {
        let record = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: dream.id.uuidString))
        
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
        
        // 情绪数组需要特殊处理
        let emotionStrings = dream.emotions.map { $0.rawValue }
        record["emotions"] = emotionStrings as CKRecordValue
        
        database.save(record) { [weak self] savedRecord, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.syncStatus = .failed(error.localizedDescription)
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
}

// MARK: - Dream 转 CKRecordValue 扩展

extension Array: CKRecordValue where Element == String {
    public var ckRecordValue: CKRecordValue {
        self as CKRecordValue
    }
}

extension Date: CKRecordValue {}
extension String: CKRecordValue {}
extension Int: CKRecordValue {}
extension Bool: CKRecordValue {}
