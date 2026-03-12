//
//  DreamARShareService.swift
//  DreamLog - Phase 22: AR Enhancement & 3D Dream World
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import Combine
import MultipeerConnectivity

// MARK: - Share Service

/// AR 场景分享服务
/// 支持多人实时共享 AR 场景，使用 MultipeerConnectivity 框架
class DreamARShareService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DreamARShareService()
    
    // MARK: - Published Properties
    
    @Published var isHost = false
    @Published var isConnected = false
    @Published var participantCount = 1
    @Published var participants: [ARParticipant] = []
    @Published var shareCode: String?
    @Published var shareURL: URL?
    @Published var isSharing = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    
    // MARK: - Properties
    
    private var service: MCNearbyServiceAdvertiser?
    private var session: MCSession?
    private var peerID: MCPeerID
    private var invitedPeers: [MCPeerID] = []
    
    // 场景数据缓存
    private var currentSceneData: Data?
    
    // 定时器
    private var syncTimer: Timer?
    
    // MARK: - Init
    
    private override init() {
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        setupSession()
    }
    
    // MARK: - Setup
    
    private func setupSession() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }
    
    // MARK: - Host Functions
    
    /// 开始主持共享会话
    func startHosting(sceneData: Data) {
        guard !isSharing else { return }
        
        isHost = true
        isSharing = true
        currentSceneData = sceneData
        participantCount = 1
        participants = []
        
        // 生成分享码
        shareCode = generateShareCode()
        
        // 创建广告器
        let serviceInfo: [String: Any] = [
            "shareCode": shareCode ?? "",
            "hostName": peerID.displayName,
            "sceneSize": sceneData.count
        ]
        
        service = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: serviceInfo,
            serviceType: "dreamlog-ar"
        )
        service?.delegate = self
        service?.startAdvertisingPeer()
        
        // 启动同步定时器
        startSyncTimer()
        
        print("🎤 开始主持 AR 共享会话，分享码：\(shareCode ?? "未知")")
    }
    
    /// 停止主持
    func stopHosting() {
        service?.stopAdvertisingPeer()
        service = nil
        endSession()
    }
    
    // MARK: - Client Functions
    
    /// 加入共享会话
    func joinSession(shareCode: String) {
        guard !isSharing else { return }
        
        isHost = false
        isSharing = true
        
        // 查找主持者
        let browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: "dreamlog-ar"
        )
        browser.delegate = self
        
        // 存储 browser 引用以便后续使用
        // 实际实现中需要更复杂的查找逻辑
        print("🔍 正在查找分享码：\(shareCode) 的主持者...")
    }
    
    /// 离开共享会话
    func leaveSession() {
        endSession()
    }
    
    // MARK: - Sync Functions
    
    /// 同步场景数据给所有参与者
    func syncScene(_ sceneData: Data) {
        guard isHost, isConnected else { return }
        
        currentSceneData = sceneData
        
        do {
            try session?.send(
                sceneData,
                toPeers: session?.connectedPeers ?? [],
                with: .reliable
            )
            lastSyncTime = Date()
            syncStatus = .synced
        } catch {
            print("❌ 同步场景失败：\(error)")
            syncStatus = .failed
        }
    }
    
    /// 广播消息
    func broadcastMessage(_ message: ARChatMessage) {
        guard isConnected else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            try session?.send(
                data,
                toPeers: session?.connectedPeers ?? [],
                with: .reliable
            )
        } catch {
            print("❌ 广播消息失败：\(error)")
        }
    }
    
    /// 更新参与者位置
    func updateParticipantPosition(_ position: SIMD3<Float>) {
        guard isConnected else { return }
        
        let positionData = Data(bytes: &position, count: MemoryLayout<SIMD3<Float>>.size)
        
        do {
            try session?.send(
                positionData,
                toPeers: session?.connectedPeers ?? [],
                with: .unreliable
            )
        } catch {
            print("❌ 更新位置失败：\(error)")
        }
    }
    
    // MARK: - Private Functions
    
    private func endSession() {
        session?.disconnect()
        service?.stopAdvertisingPeer()
        stopSyncTimer()
        
        isSharing = false
        isConnected = false
        participantCount = 1
        participants = []
        shareCode = nil
        shareURL = nil
        syncStatus = .idle
        
        print("👋 AR 共享会话已结束")
    }
    
    private func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).compactMap { _ in chars.randomElement() })
    }
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkSyncStatus()
        }
    }
    
    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func checkSyncStatus() {
        guard isHost else { return }
        syncStatus = .synced
    }
    
    // MARK: - Invite Handler
    
    func handleInvite(_ invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
        print("✅ 已接受连接邀请")
    }
}

// MARK: - MCSessionDelegate

extension DreamARShareService: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                if !self.participants.contains(where: { $0.peerID == peerID.displayName }) {
                    let participant = ARParticipant(
                        id: UUID(),
                        peerID: peerID.displayName,
                        role: .viewer,
                        joinedAt: Date(),
                        permissions: .viewer
                    )
                    self.participants.append(participant)
                    self.participantCount = self.participants.count + 1
                }
                self.isConnected = true
                self.syncStatus = .synced
                print("✅ 参与者已连接：\(peerID.displayName)")
                
            case .connecting:
                self.syncStatus = .syncing
                print("🔄 正在连接：\(peerID.displayName)")
                
            case .notConnected:
                self.participants.removeAll { $0.peerID == peerID.displayName }
                self.participantCount = self.participants.count + 1
                if self.participants.isEmpty {
                    self.isConnected = false
                }
                print("❌ 参与者已断开：\(peerID.displayName)")
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            // 处理接收到的数据
            // 可能是场景更新、聊天消息或位置更新
            print("📥 收到来自 \(peerID.displayName) 的数据：\(data.count) 字节")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 处理流数据
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 处理资源接收
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 处理资源接收完成
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension DreamARShareService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        handleInvite(invitationHandler)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ 无法开始广告：\(error)")
        stopHosting()
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension DreamARShareService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("🔍 发现主持者：\(peerID.displayName)")
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("❌ 失去主持者连接：\(peerID.displayName)")
    }
}

// MARK: - Sync Status

enum SyncStatus {
    case idle
    case syncing
    case synced
    case failed
    
    var description: String {
        switch self {
        case .idle: return "未同步"
        case .syncing: return "同步中..."
        case .synced: return "已同步"
        case .failed: return "同步失败"
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "circle"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
}
