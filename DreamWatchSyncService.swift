//
//  DreamWatchSyncService.swift
//  DreamLog
//
//  Apple Watch 与 iPhone 数据同步服务
//  Phase 32 - Apple Watch 增强与多端协同
//

import Foundation
import WatchConnectivity
import CloudKit
import os.log

// MARK: - 同步状态枚举

enum SyncStatus {
    case idle
    case syncing
    case completed
    case failed(Error)
    
    var description: String {
        switch self {
        case .idle: return "等待同步"
        case .syncing: return "同步中..."
        case .completed: return "同步完成"
        case .failed: return "同步失败"
        }
    }
}

// MARK: - 同步错误

enum SyncError: LocalizedError {
    case watchNotPaired
    case connectionFailed
    case dataCorrupted
    case cloudKitError
    case handoffNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .watchNotPaired: return "Apple Watch 未配对"
        case .connectionFailed: return "连接失败"
        case .dataCorrupted: return "数据损坏"
        case .cloudKitError: return "CloudKit 同步错误"
        case .handoffNotAvailable: return "接力功能不可用"
        }
    }
}

// MARK: - Watch 同步服务

@MainActor
class DreamWatchSyncService: NSObject, ObservableObject {
    static let shared = DreamWatchSyncService()
    
    private let logger = Logger(subsystem: "com.dreamlog.app", category: "WatchSync")
    
    // 同步状态
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var isWatchConnected: Bool = false
    @Published var pendingSyncCount: Int = 0
    
    // WatchConnectivity
    private var session: WCSession?
    private var messageQueue: [[String: Any]] = []
    private var isSending = false
    
    // CloudKit
    private let cloudKitManager = CloudKitManager.shared
    
    // 同步配置
    private let maxRetryCount = 3
    private let syncInterval: TimeInterval = 30 // 30 秒自动同步
    
    // MARK: - 初始化
    
    override init() {
        super.init()
        setupWatchConnectivity()
        startAutoSync()
    }
    
    // MARK: - WatchConnectivity 设置
    
    func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            logger.warning("WCSession 不支持此设备")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        logger.info("WCSession 已激活")
    }
    
    // MARK: - 同步方法
    
    /// 同步梦境到 Watch
    func syncDreamsToWatch(_ dreams: [Dream]) async throws {
        guard let session = session, session.isReachable else {
            throw SyncError.watchNotPaired
        }
        
        @Sendable func syncDreams() async throws {
            try await withCheckedThrowingContinuation { continuation in
                do {
                    // 转换为 Watch 兼容格式
                    let watchDreams = dreams.map { dream -> [String: Any] in
                        [
                            "id": dream.id.uuidString,
                            "title": dream.title,
                            "content": dream.content,
                            "date": dream.date.timeIntervalSince1970,
                            "tags": dream.tags,
                            "emotions": dream.emotions.map { $0.rawValue },
                            "clarity": dream.clarity,
                            "isLucid": dream.isLucid,
                            "hasAudio": dream.audioURL != nil
                        ]
                    }
                    
                    let message: [String: Any] = [
                        "type": "syncDreams",
                        "dreams": watchDreams,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                    
                    session.sendMessage(message, replyHandler: { reply in
                        self.logger.info("Watch 确认接收：\(reply)")
                        continuation.resume()
                    }, errorHandler: { error in
                        self.logger.error("发送失败：\(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    })
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        syncStatus = .syncing
        try await syncDreams()
        syncStatus = .completed
        lastSyncDate = Date()
    }
    
    /// 从 Watch 接收梦境
    func receiveDreamFromWatch(_ data: [String: Any]) async throws -> Dream {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let content = data["content"] as? String,
              let dateInterval = data["date"] as? TimeInterval else {
            throw SyncError.dataCorrupted
        }
        
        let tags = data["tags"] as? [String] ?? []
        let emotionRawValues = data["emotions"] as? [String] ?? []
        let emotions = emotionRawValues.compactMap { DreamEmotion(rawValue: $0) }
        let clarity = data["clarity"] as? Int ?? 3
        let isLucid = data["isLucid"] as? Bool ?? false
        
        let dream = Dream(
            id: id,
            title: title,
            content: content,
            tags: tags,
            emotions: emotions,
            clarity: clarity,
            intensity: 3,
            isLucid: isLucid,
            date: Date(timeIntervalSince1970: dateInterval),
            audioURL: nil
        )
        
        logger.info("从 Watch 接收梦境：\(dream.title)")
        return dream
    }
    
    // MARK: - 接力 (Handoff)
    
    /// 开始接力活动
    func startActivity(for dream: Dream?) {
        guard let activityData = prepareHandoffData(for: dream) else { return }
        
        #if os(iOS)
        NSUserActivity(activityType: "com.dreamlog.app.continue").with { activity in
            activity.title = dream != nil ? "继续编辑梦境" : "记录新梦境"
            activity.userInfo = activityData
            activity.isEligibleForHandoff = true
            activity.becomeCurrent()
            logger.info("Handoff 活动已开始")
        }
        #endif
    }
    
    /// 准备接力数据
    private func prepareHandoffData(for dream: Dream?) -> [String: Any]? {
        var data: [String: Any] = [
            "version": "1.0",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let dream = dream {
            data["dreamId"] = dream.id.uuidString
            data["action"] = "edit"
        } else {
            data["action"] = "record"
        }
        
        return data
    }
    
    /// 处理接力活动
    func handleHandoff(_ userActivity: NSUserActivity) async -> DreamAction {
        guard let userInfo = userActivity.userInfo,
              let action = userInfo["action"] as? String else {
            return .viewList
        }
        
        if action == "edit", let dreamIdString = userInfo["dreamId"] as? String {
            return .editDream(UUID(uuidString: dreamIdString) ?? UUID())
        } else {
            return .recordNew
        }
    }
    
    // MARK: - 自动同步
    
    private func startAutoSync() {
        // 定时检查同步状态
        Task.detached {
            while true {
                try? await Task.sleep(nanoseconds: UInt64(self.syncInterval * 1_000_000_000))
                await self.checkSyncStatus()
            }
        }
    }
    
    private func checkSyncStatus() {
        if let session = session {
            Task { @MainActor in
                self.isWatchConnected = session.activationState == .activated
                self.pendingSyncCount = self.messageQueue.count
            }
        }
    }
    
    // MARK: - 消息队列
    
    private func addToQueue(_ message: [String: Any]) {
        messageQueue.append(message)
        processQueue()
    }
    
    private func processQueue() {
        guard !isSending, !messageQueue.isEmpty,
              let session = session, session.isReachable else {
            return
        }
        
        isSending = true
        let message = messageQueue.removeFirst()
        
        session.sendMessage(message, replyHandler: { [weak self] _ in
            Task { @MainActor in
                self?.isSending = false
                self?.processQueue()
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                self?.isSending = false
                self?.logger.error("队列消息发送失败：\(error.localizedDescription)")
                // 重新加入队列
                if let self = self {
                    self.messageQueue.insert(message, at: 0)
                }
            }
        })
    }
}

// MARK: - DreamAction 枚举

enum DreamAction {
    case viewList
    case recordNew
    case editDream(UUID)
    case viewStats
}

// MARK: - WCSessionDelegate

extension DreamWatchSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.error("WCSession 激活失败：\(error.localizedDescription)")
            Task { @MainActor in
                self.syncStatus = .failed(error)
            }
        } else {
            logger.info("WCSession 激活成功：\(activationState.rawValue)")
            Task { @MainActor in
                self.isWatchConnected = activationState == .activated
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WCSession 变为非活跃")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WCSession 已停用")
        session.activate()
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        logger.info("收到 Watch 消息：\(message.keys.description)")
        
        Task { @MainActor in
            await handleWatchMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @Sendable ([String: Any]) -> Void) {
        logger.info("收到 Watch 消息 (需要回复): \(message.keys.description)")
        
        Task { @MainActor in
            let reply = await handleWatchMessageWithReply(message)
            replyHandler(reply)
        }
    }
    
    private func handleWatchMessage(_ message: [String: Any]) async {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "dreamSaved":
            logger.info("Watch 保存了梦境")
            // 触发 iCloud 同步
            await cloudKitManager.syncToCloud()
            
        case "syncRequest":
            logger.info("Watch 请求同步")
            // 发送最新梦境数据
            
        default:
            logger.warning("未知的消息类型：\(type)")
        }
    }
    
    private func handleWatchMessageWithReply(_ message: [String: Any]) async -> [String: Any] {
        guard let type = message["type"] as? String else {
            return ["error": "Unknown message type"]
        }
        
        switch type {
        case "getDreamCount":
            let dreamStore = DreamStore.shared
            return [
                "type": "dreamCount",
                "count": dreamStore.dreams.count,
                "thisWeek": dreamStore.dreamsThisWeek
            ]
            
        case "getRecentDreams":
            let dreamStore = DreamStore.shared
            let recent = dreamStore.dreams.prefix(5).map { dream -> [String: Any] in
                [
                    "id": dream.id.uuidString,
                    "title": dream.title,
                    "date": dream.date.timeIntervalSince1970
                ]
            }
            return ["type": "recentDreams", "dreams": recent]
            
        default:
            return ["error": "Unhandled message type"]
        }
    }
}

// MARK: - CloudKitManager (简化版)

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let logger = Logger(subsystem: "com.dreamlog.app", category: "CloudKit")
    private let container: CKContainer
    
    init() {
        container = CKContainer(identifier: "iCloud.com.dreamlog.app")
    }
    
    func syncToCloud() async {
        logger.info("开始 CloudKit 同步")
        // 实现 CloudKit 同步逻辑
    }
}

// MARK: - NSUserActivity 扩展

extension NSUserActivity {
    func with(_ configure: (NSUserActivity) -> Void) {
        configure(self)
    }
}
