//
//  DreamTrashService.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Dream Trash Service

/// 梦境回收站服务
@MainActor
final class DreamTrashService {
    
    // MARK: - Singleton
    
    static let shared = DreamTrashService()
    
    // MARK: - Constants
    
    private let retentionDays = 30
    private let cleanupInterval: TimeInterval = 24 * 60 * 60 // 每天清理一次
    
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    private var cleanupTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        setupCleanupTimer()
    }
    
    // MARK: - Public Methods
    
    /// 设置模型上下文
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// 移动梦境到回收站
    func moveToTrash(dream: Dream) throws {
        guard let context = modelContext else {
            throw TrashError.contextNotFound
        }
        
        // 创建回收站项目
        let trashItem = DreamTrashItem(
            dreamId: dream.id,
            dreamTitle: dream.title ?? "无标题",
            dreamContent: dream.content ?? "",
            dreamData: dream.dreamData ?? Data(),
            retentionDays: retentionDays
        )
        
        context.insert(trashItem)
        
        // 标记原梦境为已删除 (软删除)
        dream.isDeleted = true
        dream.deletedDate = Date()
        
        try context.save()
        
        // 通知回收站更新
        NotificationCenter.default.post(
            name: .dreamMovedToTrash,
            object: nil,
            userInfo: ["dreamId": dream.id]
        )
    }
    
    /// 恢复梦境
    func recoverDream(trashItemId: UUID) throws {
        guard let context = modelContext else {
            throw TrashError.contextNotFound
        }
        
        // 查找回收站项目
        let descriptor = FetchDescriptor<DreamTrashItem>(
            predicate: #Predicate { $0.id == trashItemId }
        )
        
        let trashItems = try context.fetch(descriptor)
        guard let trashItem = trashItems.first else {
            throw TrashError.itemNotFound
        }
        
        // 查找原梦境
        let dreamDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.id == trashItem.dreamId }
        )
        
        let dreams = try context.fetch(dreamDescriptor)
        guard let dream = dreams.first else {
            throw TrashError.dreamNotFound
        }
        
        // 恢复梦境
        dream.isDeleted = false
        dream.deletedDate = nil
        
        // 标记回收站项目为已恢复
        trashItem.isRecovered = true
        trashItem.recoveryDate = Date()
        
        try context.save()
        
        // 通知回收站更新
        NotificationCenter.default.post(
            name: .dreamRecoveredFromTrash,
            object: nil,
            userInfo: ["dreamId": dream.id, "trashItemId": trashItemId]
        )
    }
    
    /// 永久删除梦境
    func permanentlyDelete(trashItemId: UUID) throws {
        guard let context = modelContext else {
            throw TrashError.contextNotFound
        }
        
        // 查找回收站项目
        let descriptor = FetchDescriptor<DreamTrashItem>(
            predicate: #Predicate { $0.id == trashItemId }
        )
        
        let trashItems = try context.fetch(descriptor)
        guard let trashItem = trashItems.first else {
            throw TrashError.itemNotFound
        }
        
        // 删除回收站项目
        context.delete(trashItem)
        
        // 删除原梦境 (硬删除)
        let dreamDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.id == trashItem.dreamId }
        )
        
        let dreams = try context.fetch(dreamDescriptor)
        if let dream = dreams.first {
            context.delete(dream)
        }
        
        try context.save()
        
        // 通知回收站更新
        NotificationCenter.default.post(
            name: .dreamPermanentlyDeleted,
            object: nil,
            userInfo: ["trashItemId": trashItemId]
        )
    }
    
    /// 清空回收站
    func emptyTrash() throws -> Int {
        guard let context = modelContext else {
            throw TrashError.contextNotFound
        }
        
        // 获取所有回收站项目
        let descriptor = FetchDescriptor<DreamTrashItem>(
            predicate: #Predicate { $0.isRecovered == false }
        )
        
        let trashItems = try context.fetch(descriptor)
        let count = trashItems.count
        
        // 删除所有项目
        for trashItem in trashItems {
            context.delete(trashItem)
        }
        
        try context.save()
        
        // 通知回收站更新
        NotificationCenter.default.post(
            name: .trashEmptied,
            object: nil,
            userInfo: ["deletedCount": count]
        )
        
        return count
    }
    
    /// 获取回收站中的梦境列表
    func getTrashItems() throws -> [DreamTrashItem] {
        guard let context = modelContext else {
            throw TrashError.contextNotFound
        }
        
        let descriptor = FetchDescriptor<DreamTrashItem>(
            predicate: #Predicate { $0.isRecovered == false },
            sortBy: [SortDescriptor(\.deletedDate, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// 获取即将过期的梦境
    func getExpiringItems(withinDays days: Int = 7) throws -> [DreamTrashItem] {
        guard let context = modelContext else {
            throw TrashError.contextNotFound
        }
        
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<DreamTrashItem>(
            predicate: #Predicate {
                $0.isRecovered == false &&
                $0.willBePermanentlyDeletedOn <= futureDate
            },
            sortBy: [SortDescriptor(\.willBePermanentlyDeletedOn, order: .forward)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// 自动清理过期项目
    func cleanupExpiredItems() throws -> Int {
        guard let context = modelContext else {
            throw TrashError.contextNotFound
        }
        
        let descriptor = FetchDescriptor<DreamTrashItem>(
            predicate: #Predicate {
                $0.isRecovered == false &&
                $0.willBePermanentlyDeletedOn < Date()
            }
        )
        
        let expiredItems = try context.fetch(descriptor)
        let count = expiredItems.count
        
        for item in expiredItems {
            context.delete(item)
        }
        
        try context.save()
        
        return count
    }
    
    /// 获取回收站统计信息
    func getTrashStats() throws -> TrashStats {
        let items = try getTrashItems()
        
        let totalSize = items.reduce(0) { $0 + $1.dreamData.count }
        let expiringSoon = try getExpiringItems().count
        
        return TrashStats(
            totalCount: items.count,
            totalSize: totalSize,
            expiringSoonCount: expiringSoon,
            oldestDeletionDate: items.last?.deletedDate
        )
    }
    
    // MARK: - Private Methods
    
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performCleanup()
            }
        }
    }
    
    private func performCleanup() {
        do {
            let count = try cleanupExpiredItems()
            if count > 0 {
                print("自动清理了 \(count) 个过期回收站项目")
            }
        } catch {
            print("清理回收站失败：\(error)")
        }
    }
}

// MARK: - Trash Stats

/// 回收站统计信息
struct TrashStats {
    let totalCount: Int
    let totalSize: Int
    let expiringSoonCount: Int
    let oldestDeletionDate: Date?
    
    var totalSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSize))
    }
}

// MARK: - Trash Error

enum TrashError: LocalizedError {
    case contextNotFound
    case itemNotFound
    case dreamNotFound
    case recoveryFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotFound: return "数据上下文未设置"
        case .itemNotFound: return "回收站项目不存在"
        case .dreamNotFound: return "梦境不存在"
        case .recoveryFailed: return "恢复失败"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dreamMovedToTrash = Notification.Name("dreamMovedToTrash")
    static let dreamRecoveredFromTrash = Notification.Name("dreamRecoveredFromTrash")
    static let dreamPermanentlyDeleted = Notification.Name("dreamPermanentlyDeleted")
    static let trashEmptied = Notification.Name("trashEmptied")
}

// MARK: - Dream Model Extension

/// Dream 模型扩展 (假设已存在)
extension Dream {
    var isDeleted: Bool {
        get { deletedDate != nil }
        set {
            if newValue && deletedDate == nil {
                deletedDate = Date()
            } else if !newValue {
                deletedDate = nil
            }
        }
    }
    
    var deletedDate: Date? {
        get { nil } // 实际实现需要从模型获取
        set { } // 实际实现需要设置到模型
    }
    
    var dreamData: Data? {
        get { nil }
        set { }
    }
}
