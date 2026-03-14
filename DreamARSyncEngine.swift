//
//  DreamARSyncEngine.swift
//  DreamLog
//
//  Created for Phase 40 - AR 社交功能
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Combine

// MARK: - AR 同步引擎

/// 负责 AR 社交功能的实时数据同步
actor DreamARSyncEngine {
    
    // MARK: - Properties
    
    private var pendingSyncs: [UUID: SyncTask] = [:]
    private var syncQueue: [SyncTask] = []
    private var isSyncing = false
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // 性能指标
    private var syncCount = 0
    private var lastSyncTime: Date?
    private var totalSyncTime: TimeInterval = 0
    
    // MARK: - Initialization
    
    init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Sync Methods
    
    /// 同步参与者更新
    func syncParticipantUpdate(_ participant: ARParticipant, to session: MCSession?) async {
        guard let session = session else { return }
        
        do {
            let data = try encoder.encode(participant)
            let packet = ARSyncPacket(
                type: .participantUpdate,
                sessionID: participant.sessionID,
                timestamp: Date(),
                data: data
            )
            
            try await sendPacket(packet, to: session)
        } catch {
            print("同步参与者更新失败：\(error)")
        }
    }
    
    /// 同步元素创建
    func syncElementCreation(_ element: ARElement, to session: MCSession?) async {
        guard let session = session else { return }
        
        do {
            let data = try encoder.encode(element)
            let packet = ARSyncPacket(
                type: .elementCreate,
                sessionID: element.sessionID,
                timestamp: Date(),
                data: data
            )
            
            try await sendPacket(packet, to: session)
        } catch {
            print("同步元素创建失败：\(error)")
        }
    }
    
    /// 同步元素更新
    func syncElementUpdate(_ element: ARElement, to session: MCSession?) async {
        guard let session = session else { return }
        
        do {
            let data = try encoder.encode(element)
            let packet = ARSyncPacket(
                type: .elementUpdate,
                sessionID: element.sessionID,
                timestamp: Date(),
                data: data
            )
            
            try await sendPacket(packet, to: session)
        } catch {
            print("同步元素更新失败：\(error)")
        }
    }
    
    /// 同步元素删除
    func syncElementDeletion(_ elementID: UUID, to session: MCSession?) async {
        guard let session = session else { return }
        
        do {
            let data = try encoder.encode(elementID)
            let packet = ARSyncPacket(
                type: .elementDelete,
                sessionID: UUID(), // TODO: 从上下文获取
                timestamp: Date(),
                data: data
            )
            
            try await sendPacket(packet, to: session)
        } catch {
            print("同步元素删除失败：\(error)")
        }
    }
    
    /// 同步消息
    func syncMessage(_ message: ARMessage, to session: MCSession?) async {
        guard let session = session else { return }
        
        do {
            let data = try encoder.encode(message)
            let packet = ARSyncPacket(
                type: .message,
                sessionID: message.sessionID,
                timestamp: Date(),
                data: data
            )
            
            try await sendPacket(packet, to: session)
        } catch {
            print("同步消息失败：\(error)")
        }
    }
    
    /// 同步互动
    func syncInteraction(_ interaction: ARInteraction, to session: MCSession?) async {
        guard let session = session else { return }
        
        do {
            let data = try encoder.encode(interaction)
            let packet = ARSyncPacket(
                type: .interaction,
                sessionID: interaction.sessionID,
                timestamp: Date(),
                data: data
            )
            
            try await sendPacket(packet, to: session)
        } catch {
            print("同步互动失败：\(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func sendPacket(_ packet: ARSyncPacket, to session: MCSession) async throws {
        let startTime = Date()
        
        do {
            let data = try encoder.encode(packet)
            
            // 使用可靠传输确保数据不丢失
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            
            // 更新性能指标
            syncCount += 1
            let syncTime = Date().timeIntervalSince(startTime)
            totalSyncTime += syncTime
            lastSyncTime = Date()
            
        } catch {
            print("发送同步包失败：\(error)")
            throw error
        }
    }
    
    // MARK: - Performance Metrics
    
    /// 获取平均同步时间
    func getAverageSyncTime() -> TimeInterval {
        guard syncCount > 0 else { return 0 }
        return totalSyncTime / Double(syncCount)
    }
    
    /// 获取同步统计
    func getSyncStats() -> SyncStats {
        return SyncStats(
            totalSyncs: syncCount,
            averageSyncTime: getAverageSyncTime(),
            lastSyncTime: lastSyncTime
        )
    }
    
    /// 重置统计
    func resetStats() {
        syncCount = 0
        totalSyncTime = 0
        lastSyncTime = nil
    }
}

// MARK: - 同步统计

struct SyncStats {
    let totalSyncs: Int
    let averageSyncTime: TimeInterval
    let lastSyncTime: Date?
    
    var averageSyncTimeMs: Int {
        Int(averageSyncTime * 1000)
    }
}

// MARK: - 同步任务

struct SyncTask: Identifiable {
    let id: UUID
    let packet: ARSyncPacket
    let retryCount: Int
    let createdAt: Date
    
    init(packet: ARSyncPacket, retryCount: Int = 0) {
        self.id = UUID()
        self.packet = packet
        self.retryCount = retryCount
        self.createdAt = Date()
    }
}

// MARK: - 位置插值器

/// 用于平滑参与者移动的插值器
class PositionInterpolator {
    
    private var positions: [(Date, SIMD3<Float>)] = []
    private let maxHistorySize = 10
    private let interpolationDuration: TimeInterval = 0.1
    
    /// 添加新位置
    func addPosition(_ position: SIMD3<Float>, at time: Date = Date()) {
        positions.append((time, position))
        
        // 保持历史记录大小
        if positions.count > maxHistorySize {
            positions.removeFirst()
        }
    }
    
    /// 获取插值后的位置
    func getInterpolatedPosition(at time: Date = Date()) -> SIMD3<Float> {
        guard positions.count >= 2 else {
            return positions.first?.1 ?? SIMD3<Float>(0, 0, 0)
        }
        
        // 找到插值区间
        for i in 0..<(positions.count - 1) {
            let (time1, pos1) = positions[i]
            let (time2, pos2) = positions[i + 1]
            
            if time >= time1 && time <= time2 {
                let t = time.timeIntervalSince(time1) / time2.timeIntervalSince(time1)
                return interpolate(from: pos1, to: pos2, factor: Float(t))
            }
        }
        
        return positions.last?.1 ?? SIMD3<Float>(0, 0, 0)
    }
    
    /// 线性插值
    private func interpolate(from: SIMD3<Float>, to: SIMD3<Float>, factor: Float) -> SIMD3<Float> {
        return SIMD3<Float>(
            from.x + (to.x - from.x) * factor,
            from.y + (to.y - from.y) * factor,
            from.z + (to.z - from.z) * factor
        )
    }
    
    /// 清除历史
    func clear() {
        positions.removeAll()
    }
}

// MARK: - 旋转插值器

/// 用于平滑参与者旋转的插值器
class RotationInterpolator {
    
    private var rotations: [(Date, SIMD4<Float>)] = []
    private let maxHistorySize = 10
    
    /// 添加新旋转
    func addRotation(_ rotation: SIMD4<Float>, at time: Date = Date()) {
        rotations.append((time, rotation))
        
        if rotations.count > maxHistorySize {
            rotations.removeFirst()
        }
    }
    
    /// 获取插值后的旋转
    func getInterpolatedRotation(at time: Date = Date()) -> SIMD4<Float> {
        guard rotations.count >= 2 else {
            return rotations.first?.1 ?? SIMD4<Float>(0, 0, 0, 1)
        }
        
        for i in 0..<(rotations.count - 1) {
            let (time1, rot1) = rotations[i]
            let (time2, rot2) = rotations[i + 1]
            
            if time >= time1 && time <= time2 {
                let t = time.timeIntervalSince(time1) / time2.timeIntervalSince(time1)
                return slerp(from: rot1, to: rot2, factor: Float(t))
            }
        }
        
        return rotations.last?.1 ?? SIMD4<Float>(0, 0, 0, 1)
    }
    
    /// 球面线性插值（四元数）
    private func slerp(from: SIMD4<Float>, to: SIMD4<Float>, factor: Float) -> SIMD4<Float> {
        let dot = from.x * to.x + from.y * to.y + from.z * to.z + from.w * to.w
        
        // 如果点积为负，翻转一个四元数
        let (from, to) = dot < 0 ? (-from, to) : (from, to)
        
        let theta = acos(min(abs(dot), 1.0))
        
        guard theta > 0.0001 else {
            return from
        }
        
        let sinTheta = sin(theta)
        let ratioA = sin((1 - factor) * theta) / sinTheta
        let ratioB = sin(factor * theta) / sinTheta
        
        return SIMD4<Float>(
            from.x * ratioA + to.x * ratioB,
            from.y * ratioA + to.y * ratioB,
            from.z * ratioA + to.z * ratioB,
            from.w * ratioA + to.w * ratioB
        )
    }
    
    /// 清除历史
    func clear() {
        rotations.removeAll()
    }
}

// MARK: - 冲突解决器

/// 处理并发更新的冲突解决
class ConflictResolver {
    
    enum ResolutionStrategy {
        case lastWriteWins
        case hostWins
        case merge
    }
    
    private let strategy: ResolutionStrategy
    
    init(strategy: ResolutionStrategy = .lastWriteWins) {
        self.strategy = strategy
    }
    
    /// 解决元素冲突
    func resolveElementConflict(local: ARElement, remote: ARElement) -> ARElement {
        switch strategy {
        case .lastWriteWins:
            return local.updatedAt > remote.updatedAt ? local : remote
            
        case .hostWins:
            // TODO: 需要知道哪个是主机创建的
            return local.creatorID == local.sessionID /* 简化判断 */ ? local : remote
            
        case .merge:
            // 合并两个元素的属性
            let merged = local
            merged.position = remote.position
            merged.rotation = remote.rotation
            merged.scale = remote.scale
            merged.color = remote.color
            merged.updatedAt = Date()
            return merged
        }
    }
    
    /// 解决参与者冲突
    func resolveParticipantConflict(local: ARParticipant, remote: ARParticipant) -> ARParticipant {
        switch strategy {
        case .lastWriteWins:
            return local.lastActiveAt > remote.lastActiveAt ? local : remote
            
        case .hostWins:
            return local.isHost ? local : remote
            
        case .merge:
            let merged = local
            merged.position = remote.position
            merged.rotation = remote.rotation
            merged.lastActiveAt = max(local.lastActiveAt, remote.lastActiveAt)
            return merged
        }
    }
}

// MARK: - 网络优化器

/// 优化网络传输
class NetworkOptimizer {
    
    private var lastSentPositions: [UUID: SIMD3<Float>] = [:]
    private var lastSentRotations: [UUID: SIMD4<Float>] = [:]
    
    private let positionThreshold: Float = 0.01  // 位置变化阈值（米）
    private let rotationThreshold: Float = 0.01  // 旋转变化阈值（弧度）
    
    /// 检查是否需要发送位置更新
    func shouldSendPositionUpdate(_ position: SIMD3<Float>, for participantID: UUID) -> Bool {
        guard let lastPosition = lastSentPositions[participantID] else {
            return true
        }
        
        let distance = sqrt(
            pow(position.x - lastPosition.x, 2) +
            pow(position.y - lastPosition.y, 2) +
            pow(position.z - lastPosition.z, 2)
        )
        
        return distance > positionThreshold
    }
    
    /// 检查是否需要发送旋转更新
    func shouldSendRotationUpdate(_ rotation: SIMD4<Float>, for participantID: UUID) -> Bool {
        guard let lastRotation = lastSentRotations[participantID] else {
            return true
        }
        
        let dot = rotation.x * lastRotation.x +
                  rotation.y * lastRotation.y +
                  rotation.z * lastRotation.z +
                  rotation.w * lastRotation.w
        
        let angle = acos(min(abs(dot), 1.0)) * 2
        
        return angle > rotationThreshold
    }
    
    /// 更新已发送的位置
    func markPositionSent(_ position: SIMD3<Float>, for participantID: UUID) {
        lastSentPositions[participantID] = position
    }
    
    /// 更新已发送的旋转
    func markRotationSent(_ rotation: SIMD4<Float>, for participantID: UUID) {
        lastSentRotations[participantID] = rotation
    }
    
    /// 清除缓存
    func clear() {
        lastSentPositions.removeAll()
        lastSentRotations.removeAll()
    }
}
