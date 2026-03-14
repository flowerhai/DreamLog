//
//  DreamARSocialService.swift
//  DreamLog
//
//  Created for Phase 40 - AR 社交功能
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftUI
import ARKit
import MultipeerConnectivity
import SwiftData
import Combine

// MARK: - AR 社交服务

/// AR 社交功能核心服务
@MainActor
class DreamARSocialService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentSession: ARSession?
    @Published var sessionState: ARSessionState = .disconnected
    @Published var participants: [ARParticipant] = []
    @Published var elements: [ARElement] = []
    @Published var messages: [ARMessage] = []
    @Published var availableSessions: [ARSession] = []
    @Published var lastError: Error?
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private var modelContext: ModelContext { modelContainer.mainContext }
    
    // Multipeer Connectivity
    private var mcSession: MCSession?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var myPeerID: MCPeerID
    
    // Sync Engine
    private let syncEngine: DreamARSyncEngine
    
    // Timers
    private var heartbeatTimer: Timer?
    private var cleanupTimer: Timer?
    
    // Callbacks
    var onParticipantJoined: ((ARParticipant) -> Void)?
    var onParticipantLeft: ((ARParticipant) -> Void)?
    var onElementAdded: ((ARElement) -> Void)?
    var onElementUpdated: ((ARElement) -> Void)?
    var onMessageReceived: ((ARMessage) -> Void)?
    var onSessionStateChange: ((ARSessionState) -> Void)?
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer, userID: UUID, displayName: String) {
        self.modelContainer = modelContainer
        self.myPeerID = MCPeerID(displayName: displayName)
        self.syncEngine = DreamARSyncEngine()
        
        super.init()
        
        setupMultipeerConnectivity()
        setupTimers()
    }
    
    deinit {
        stopHeartbeatTimer()
        stopCleanupTimer()
        disconnect()
    }
    
    // MARK: - Setup
    
    private func setupMultipeerConnectivity() {
        mcSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        
        let serviceType = "dreamlog-ar"
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: ["version": "1.0"],
            serviceType: serviceType
        )
        serviceAdvertiser?.delegate = self
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        serviceBrowser?.delegate = self
    }
    
    private func setupTimers() {
        startHeartbeatTimer()
        startCleanupTimer()
    }
    
    private func startHeartbeatTimer() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.sendHeartbeat()
            }
        }
    }
    
    private func stopHeartbeatTimer() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.cleanupExpiredItems()
            }
        }
    }
    
    private func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    // MARK: - Session Management
    
    /// 创建新的 AR 会话
    func createSession(
        sceneTemplate: ARSceneTemplate = .starryNight,
        maxParticipants: Int = 8,
        isPublic: Bool = false,
        dreamID: UUID? = nil,
        durationMinutes: Int = 60
    ) async throws -> ARSession {
        guard sessionState == .disconnected || sessionState == .error else {
            throw ARSocialError.sessionAlreadyActive
        }
        
        // 生成 6 位邀请码
        let sessionCode = generateSessionCode()
        
        // 创建会话
        let session = ARSession(
            sessionCode: sessionCode,
            hostUserID: UUID(), // TODO: 从用户服务获取
            hostDisplayName: myPeerID.displayName,
            dreamID: dreamID,
            sceneTemplate: sceneTemplate,
            maxParticipants: maxParticipants,
            isPublic: isPublic,
            durationMinutes: durationMinutes
        )
        
        // 添加到数据存储
        modelContext.insert(session)
        
        // 创建主机参与者
        let hostParticipant = ARParticipant(
            sessionID: session.id,
            userID: session.hostUserID,
            displayName: myPeerID.displayName,
            isHost: true
        )
        modelContext.insert(hostParticipant)
        session.participants.append(hostParticipant)
        
        try modelContext.save()
        
        currentSession = session
        participants = [hostParticipant]
        sessionState = .hosting
        
        // 开始广播会话
        try serviceAdvertiser?.startAdvertisingPeer()
        
        onSessionStateChange?(.hosting)
        
        return session
    }
    
    /// 通过邀请码加入会话
    func joinSession(withCode code: String) async throws -> ARSession {
        guard sessionState == .disconnected || sessionState == .error else {
            throw ARSocialError.sessionAlreadyActive
        }
        
        sessionState = .connecting
        onSessionStateChange?(.connecting)
        
        // 查询会话
        let descriptor = FetchDescriptor<ARSession>(
            predicate: #Predicate<ARSession> { $0.sessionCode == code && $0.isActive }
        )
        
        let sessions = try modelContext.fetch(descriptor)
        
        guard let session = sessions.first else {
            sessionState = .error
            throw ARSocialError.sessionNotFound
        }
        
        guard session.canJoin(for: UUID()) else {
            sessionState = .error
            throw ARSocialError.sessionFullOrExpired
        }
        
        // 创建参与者
        let participant = ARParticipant(
            sessionID: session.id,
            userID: UUID(), // TODO: 从用户服务获取
            displayName: myPeerID.displayName,
            isHost: false
        )
        modelContext.insert(participant)
        session.participants.append(participant)
        session.participantCount += 1
        
        try modelContext.save()
        
        currentSession = session
        participants = session.participants
        sessionState = .joined
        
        // 连接到主机
        try await connectToHost(session: session)
        
        onSessionStateChange?(.joined)
        onParticipantJoined?(participant)
        
        return session
    }
    
    /// 离开当前会话
    func leaveSession() async {
        guard let session = currentSession else { return }
        
        // 找到当前参与者
        if let participant = participants.first(where: { $0.displayName == myPeerID.displayName }) {
            // 发送离开消息
            await sendMessage(
                messageType: .system,
                content: "\(participant.displayName) 离开了会话"
            )
            
            // 如果是主机，转移主机权限或结束会话
            if participant.isHost {
                await endSession()
            } else {
                // 移除参与者
                session.participants.removeAll { $0.id == participant.id }
                session.participantCount -= 1
                modelContext.delete(participant)
                
                try? modelContext.save()
            }
        }
        
        disconnect()
        
        currentSession = nil
        participants = []
        elements = []
        sessionState = .disconnected
        
        onSessionStateChange?(.disconnected)
    }
    
    /// 结束会话（主机专用）
    func endSession() async {
        guard let session = currentSession else { return }
        
        // 通知所有参与者
        await broadcastSessionEnd()
        
        // 标记会话为结束
        session.isActive = false
        
        // 清理数据
        for participant in session.participants {
            modelContext.delete(participant)
        }
        for element in session.elements {
            modelContext.delete(element)
        }
        
        try? modelContext.save()
        
        disconnect()
        
        currentSession = nil
        participants = []
        elements = []
        sessionState = .disconnected
        
        onSessionStateChange?(.disconnected)
    }
    
    // MARK: - Connection Management
    
    private func connectToHost(session: ARSession) async throws {
        // 开始搜索主机
        serviceBrowser?.startBrowsingForPeers()
        
        // 等待连接（最多 10 秒）
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 10 {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            if sessionState == .joined {
                serviceBrowser?.stopBrowsingForPeers()
                return
            }
        }
        
        serviceBrowser?.stopBrowsingForPeers()
        throw ARSocialError.connectionTimeout
    }
    
    private func disconnect() {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceBrowser?.stopBrowsingForPeers()
        mcSession?.disconnect()
    }
    
    // MARK: - Element Management
    
    /// 添加 AR 元素
    func addElement(
        type: ARElementType,
        position: SIMD3<Float>,
        rotation: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 1),
        scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
        color: Color = .white,
        metadata: [String: String] = [:]
    ) async throws -> ARElement {
        guard let session = currentSession else {
            throw ARSocialError.noActiveSession
        }
        
        let creatorID = UUID() // TODO: 从用户服务获取
        let creatorName = myPeerID.displayName
        
        let element = ARElement(
            sessionID: session.id,
            creatorID: creatorID,
            creatorName: creatorName,
            elementType: type,
            position: position,
            rotation: rotation,
            scale: scale,
            color: color,
            metadata: metadata
        )
        
        modelContext.insert(element)
        try modelContext.save()
        
        elements.append(element)
        
        // 同步到其他参与者
        await syncEngine.syncElementCreation(element, to: mcSession)
        
        onElementAdded?(element)
        
        return element
    }
    
    /// 更新 AR 元素
    func updateElement(
        _ element: ARElement,
        position: SIMD3<Float>? = nil,
        rotation: SIMD4<Float>? = nil,
        scale: SIMD3<Float>? = nil,
        color: Color? = nil
    ) async {
        element.update(
            position: position,
            rotation: rotation,
            scale: scale,
            color: color
        )
        
        try? modelContext.save()
        
        // 同步更新
        await syncEngine.syncElementUpdate(element, to: mcSession)
        
        onElementUpdated?(element)
    }
    
    /// 删除 AR 元素
    func removeElement(_ element: ARElement) async {
        guard let session = currentSession else { return }
        
        elements.removeAll { $0.id == element.id }
        session.elements.removeAll { $0.id == element.id }
        modelContext.delete(element)
        
        try? modelContext.save()
        
        // 同步删除
        await syncEngine.syncElementDeletion(element.id, to: mcSession)
    }
    
    // MARK: - Message Management
    
    /// 发送消息
    func sendMessage(
        messageType: ARMessageType,
        content: String,
        position: SIMD3<Float>? = nil,
        targetElementID: UUID? = nil,
        expiresInSeconds: Int? = nil
    ) async {
        guard let session = currentSession else { return }
        
        let senderID = UUID() // TODO: 从用户服务获取
        let senderName = myPeerID.displayName
        
        let message = ARMessage(
            sessionID: session.id,
            senderID: senderID,
            senderName: senderName,
            messageType: messageType,
            content: content,
            position: position,
            targetElementID: targetElementID,
            expiresInSeconds: expiresInSeconds
        )
        
        modelContext.insert(message)
        try? modelContext.save()
        
        messages.append(message)
        
        // 同步消息
        await syncEngine.syncMessage(message, to: mcSession)
        
        onMessageReceived?(message)
    }
    
    /// 发送快速反应
    func sendReaction(_ reaction: String, at position: SIMD3<Float>?) async {
        await sendMessage(
            messageType: .reaction,
            content: reaction,
            position: position,
            expiresInSeconds: 5
        )
    }
    
    // MARK: - Participant Management
    
    /// 更新自己的位置
    func updateMyPosition(_ position: SIMD3<Float>, rotation: SIMD4<Float>) {
        guard let participant = participants.first(where: { $0.displayName == myPeerID.displayName }) else { return }
        
        participant.position = position
        participant.rotation = rotation
        participant.updateActivity()
        
        try? modelContext.save()
        
        // 同步位置
        Task {
            await syncEngine.syncParticipantUpdate(participant, to: mcSession)
        }
    }
    
    // MARK: - Query Methods
    
    /// 获取可用会话列表
    func fetchAvailableSessions() async throws -> [ARSession] {
        let descriptor = FetchDescriptor<ARSession>(
            predicate: #Predicate<ARSession> { $0.isActive && $0.isPublic && $0.participantCount < $0.maxParticipants }
        )
        
        let sessions = try modelContext.fetch(descriptor)
        availableSessions = sessions.filter { $0.isValid }
        
        return availableSessions
    }
    
    // MARK: - Private Methods
    
    private func generateSessionCode() -> String {
        let digits = (0..<6).map { _ in Int.random(in: 0...9) }
        return digits.map { String($0) }.joined()
    }
    
    private func sendHeartbeat() async {
        guard let session = currentSession, sessionState == .joined || sessionState == .hosting else { return }
        
        // 更新自己的活跃状态
        if let participant = participants.first(where: { $0.displayName == myPeerID.displayName }) {
            participant.updateActivity()
            try? modelContext.save()
            
            // 同步心跳
            await syncEngine.syncParticipantUpdate(participant, to: mcSession)
        }
        
        // 清理不活跃的参与者
        await cleanupInactiveParticipants()
    }
    
    private func cleanupInactiveParticipants() async {
        guard let session = currentSession else { return }
        
        let inactiveParticipants = session.participants.filter { !$0.isActive && !$0.isHost }
        
        for participant in inactiveParticipants {
            participants.removeAll { $0.id == participant.id }
            session.participants.removeAll { $0.id == participant.id }
            session.participantCount -= 1
            modelContext.delete(participant)
            
            onParticipantLeft?(participant)
        }
        
        try? modelContext.save()
    }
    
    private func cleanupExpiredItems() async {
        // 清理过期消息
        messages.removeAll { $0.isExpired }
        
        // 清理过期会话
        do {
            let descriptor = FetchDescriptor<ARSession>(
                predicate: #Predicate<ARSession> { $0.expiresAt < Date() }
            )
            let expiredSessions = try modelContext.fetch(descriptor)
            
            for session in expiredSessions {
                session.isActive = false
            }
            
            try modelContext.save()
        } catch {
            print("清理过期项目失败：\(error)")
        }
    }
    
    private func broadcastSessionEnd() async {
        guard let session = currentSession else { return }
        
        let packet = ARSyncPacket(
            type: .sessionState,
            sessionID: session.id,
            timestamp: Date(),
            data: Data()
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(packet)
            try mcSession?.send(data, toPeers: mcSession?.connectedPeers ?? [], with: .reliable)
        } catch {
            print("广播会话结束失败：\(error)")
        }
    }
    
    // MARK: - Error Handling
    
    enum ARSocialError: LocalizedError {
        case sessionAlreadyActive
        case sessionNotFound
        case sessionFullOrExpired
        case noActiveSession
        case connectionTimeout
        case notHost
        
        var errorDescription: String? {
            switch self {
            case .sessionAlreadyActive: return "已有活跃的 AR 会话"
            case .sessionNotFound: return "会话不存在或已过期"
            case .sessionFullOrExpired: return "会话已满或已过期"
            case .noActiveSession: return "没有活跃的 AR 会话"
            case .connectionTimeout: return "连接超时"
            case .notHost: return "只有主持人可以执行此操作"
            }
        }
    }
}

// MARK: - MCSessionDelegate

extension DreamARSocialService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("已连接到对等体：\(peerID.displayName)")
            case .connecting:
                print("正在连接到对等体：\(peerID.displayName)")
            case .notConnected:
                print("未连接到对等体：\(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            await handleReceivedData(data, from: peerID)
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 处理流数据（用于大文件传输）
    }
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 处理资源接收进度
    }
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 处理资源接收完成
    }
    
    @MainActor
    private func handleReceivedData(_ data: Data, from peerID: MCPeerID) async {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let packet = try decoder.decode(ARSyncPacket.self, from: data)
            
            switch packet.type {
            case .participantUpdate:
                let participant = try decoder.decode(ARParticipant.self, from: packet.data)
                await handleParticipantUpdate(participant)
                
            case .elementCreate:
                let element = try decoder.decode(ARElement.self, from: packet.data)
                await handleElementCreate(element)
                
            case .elementUpdate:
                let element = try decoder.decode(ARElement.self, from: packet.data)
                await handleElementUpdate(element)
                
            case .elementDelete:
                let elementID = try decoder.decode(UUID.self, from: packet.data)
                await handleElementDelete(elementID)
                
            case .message:
                let message = try decoder.decode(ARMessage.self, from: packet.data)
                await handleMessage(message)
                
            case .sessionState:
                await handleSessionStateChange()
                
            default:
                break
            }
        } catch {
            print("处理接收数据失败：\(error)")
        }
    }
    
    private func handleParticipantUpdate(_ participant: ARParticipant) async {
        if let index = participants.firstIndex(where: { $0.id == participant.id }) {
            participants[index] = participant
        } else {
            participants.append(participant)
            onParticipantJoined?(participant)
        }
    }
    
    private func handleElementCreate(_ element: ARElement) async {
        elements.append(element)
        onElementAdded?(element)
    }
    
    private func handleElementUpdate(_ element: ARElement) async {
        if let index = elements.firstIndex(where: { $0.id == element.id }) {
            elements[index] = element
            onElementUpdated?(element)
        }
    }
    
    private func handleElementDelete(_ elementID: UUID) async {
        elements.removeAll { $0.id == elementID }
    }
    
    private func handleMessage(_ message: ARMessage) async {
        messages.append(message)
        onMessageReceived?(message)
    }
    
    private func handleSessionStateChange() async {
        // 主机结束了会话
        await leaveSession()
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension DreamARSocialService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            // 接受加入请求
            invitationHandler(true, mcSession)
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            lastError = error
            sessionState = .error
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension DreamARSocialService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            // 尝试连接找到的对等体
            browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            print("失去对等体：\(peerID.displayName)")
        }
    }
}
