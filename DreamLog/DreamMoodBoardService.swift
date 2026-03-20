//
//  DreamMoodBoardService.swift
//  DreamLog
//
//  梦境情绪板核心服务
//  Phase 76 - 梦境情绪板功能
//

import Foundation
import SwiftData

@ModelActor
actor DreamMoodBoardService {
    
    // MARK: - 属性
    
    private let modelContainer: ModelContainer
    private var moodBoards: [DreamMoodBoard] = []
    
    // MARK: - 初始化
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        _ = try? loadAllBoards()
    }
    
    // MARK: - CRUD 操作
    
    /// 创建情绪板
    func createBoard(config: MoodBoardCreationConfig) throws -> DreamMoodBoard {
        let board = DreamMoodBoard(
            title: config.title.isEmpty ? "未命名情绪板" : config.title,
            description: config.description,
            theme: config.theme,
            layout: config.layout,
            dreamIds: config.dreamIds,
            isPublic: config.isPublic
        )
        
        modelContext.insert(board)
        try modelContext.save()
        
        moodBoards.append(board)
        return board
    }
    
    /// 获取所有情绪板
    func loadAllBoards() throws -> [DreamMoodBoard] {
        let descriptor = FetchDescriptor<DreamMoodBoard>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        moodBoards = try modelContext.fetch(descriptor)
        return moodBoards
    }
    
    /// 获取情绪板详情
    func getBoard(id: UUID) throws -> DreamMoodBoard? {
        let descriptor = FetchDescriptor<DreamMoodBoard>(
            predicate: #Predicate<DreamMoodBoard> { $0.id == id }
        )
        let boards = try modelContext.fetch(descriptor)
        return boards.first
    }
    
    /// 更新情绪板
    func updateBoard(_ board: DreamMoodBoard) throws {
        board.updatedAt = Date()
        try modelContext.save()
        
        if let index = moodBoards.firstIndex(where: { $0.id == board.id }) {
            moodBoards[index] = board
        }
    }
    
    /// 删除情绪板
    func deleteBoard(id: UUID) throws {
        let descriptor = FetchDescriptor<DreamMoodBoard>(
            predicate: #Predicate<DreamMoodBoard> { $0.id == id }
        )
        let boards = try modelContext.fetch(descriptor)
        
        for board in boards {
            modelContext.delete(board)
        }
        
        try modelContext.save()
        moodBoards.removeAll { $0.id == id }
    }
    
    /// 添加梦境到情绪板
    func addDreamToBoard(boardId: UUID, dreamId: UUID) throws {
        guard let board = try getBoard(id: boardId) else {
            throw MoodBoardError.boardNotFound
        }
        
        if !board.dreamIds.contains(dreamId) {
            board.dreamIds.append(dreamId)
            board.updatedAt = Date()
            try modelContext.save()
            
            if let index = moodBoards.firstIndex(where: { $0.id == boardId }) {
                moodBoards[index].dreamIds.append(dreamId)
            }
        }
    }
    
    /// 从情绪板移除梦境
    func removeDreamFromBoard(boardId: UUID, dreamId: UUID) throws {
        guard let board = try getBoard(id: boardId) else {
            throw MoodBoardError.boardNotFound
        }
        
        board.dreamIds.removeAll { $0 == dreamId }
        board.updatedAt = Date()
        try modelContext.save()
        
        if let index = moodBoards.firstIndex(where: { $0.id == boardId }) {
            moodBoards[index].dreamIds.removeAll { $0 == dreamId }
        }
    }
    
    /// 添加自定义笔记
    func addNoteToBoard(boardId: UUID, note: MoodBoardNote) throws {
        guard let board = try getBoard(id: boardId) else {
            throw MoodBoardError.boardNotFound
        }
        
        board.customNotes.append(note)
        board.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 更新笔记
    func updateNoteInBoard(boardId: UUID, noteId: UUID, content: String, position: CGPointCodable) throws {
        guard let board = try getBoard(id: boardId) else {
            throw MoodBoardError.boardNotFound
        }
        
        if let index = board.customNotes.firstIndex(where: { $0.id == noteId }) {
            board.customNotes[index].content = content
            board.customNotes[index].position = position
            board.updatedAt = Date()
            try modelContext.save()
        }
    }
    
    /// 删除笔记
    func deleteNoteFromBoard(boardId: UUID, noteId: UUID) throws {
        guard let board = try getBoard(id: boardId) else {
            throw MoodBoardError.boardNotFound
        }
        
        board.customNotes.removeAll { $0.id == noteId }
        board.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - 统计功能
    
    /// 获取统计信息
    func getStats() throws -> MoodBoardStats {
        let boards = try loadAllBoards()
        
        let totalBoards = boards.count
        let publicBoards = boards.filter { $0.isPublic }.count
        let privateBoards = totalBoards - publicBoards
        let totalShares = boards.reduce(0) { $0 + $1.shareCount }
        let totalViews = boards.reduce(0) { $0 + $1.viewCount }
        
        // 计算最喜欢的主题
        let themeCounts = Dictionary(grouping: boards, by: { $0.theme })
            .mapValues { $0.count }
        let favoriteTheme = themeCounts.max(by: { $0.value < $1.value })?.key
        
        // 计算最喜欢的布局
        let layoutCounts = Dictionary(grouping: boards, by: { $0.layout })
            .mapValues { $0.count }
        let favoriteLayout = layoutCounts.max(by: { $0.value < $1.value })?.key
        
        // 计算平均梦境数
        let totalDreams = boards.reduce(0) { $0 + $1.dreamIds.count }
        let averageDreamsPerBoard = totalBoards > 0 ? Double(totalDreams) / Double(totalBoards) : 0
        
        return MoodBoardStats(
            totalBoards: totalBoards,
            publicBoards: publicBoards,
            privateBoards: privateBoards,
            totalShares: totalShares,
            totalViews: totalViews,
            favoriteTheme: favoriteTheme,
            favoriteLayout: favoriteLayout,
            averageDreamsPerBoard: averageDreamsPerBoard
        )
    }
    
    // MARK: - 分享功能
    
    /// 生成分享卡片
    func generateShareCard(boardId: UUID) throws -> MoodBoardShareCard {
        guard let board = try getBoard(id: boardId) else {
            throw MoodBoardError.boardNotFound
        }
        
        let shareCard = MoodBoardShareCard(
            boardId: board.id,
            boardTitle: board.title,
            boardDescription: board.description,
            theme: board.theme,
            dreamCount: board.dreamIds.count
        )
        
        // 增加分享计数
        board.shareCount += 1
        board.lastSharedAt = Date()
        board.updatedAt = Date()
        try modelContext.save()
        
        return shareCard
    }
    
    /// 增加浏览计数
    func incrementViewCount(boardId: UUID) throws {
        guard let board = try getBoard(id: boardId) else {
            throw MoodBoardError.boardNotFound
        }
        
        board.viewCount += 1
        try modelContext.save()
    }
    
    // MARK: - 智能推荐
    
    /// 根据梦境推荐情绪板主题
    func recommendTheme(for dreamIds: [UUID]) -> MoodBoardTheme {
        // 简单实现：根据梦境情绪推荐
        // 实际应该分析梦境内容
        let themes: [MoodBoardTheme] = [.starry, .ocean, .forest, .sunset]
        return themes.randomElement() ?? .starry
    }
    
    /// 根据梦境推荐布局
    func recommendLayout(for dreamCount: Int) -> MoodBoardLayout {
        if dreamCount <= 3 {
            return .collage
        } else if dreamCount <= 6 {
            return .grid
        } else if dreamCount <= 10 {
            return .masonry
        } else {
            return .timeline
        }
    }
    
    // MARK: - 导出功能
    
    /// 导出情绪板为图片
    func exportBoardAsImage(boardId: UUID) async throws -> Data {
        // 实际实现需要渲染 UI 为图片
        // 这里返回占位数据
        return Data()
    }
    
    /// 导出情绪板为 PDF
    func exportBoardAsPDF(boardId: UUID) async throws -> Data {
        // 实际实现需要生成 PDF
        return Data()
    }
    
    // MARK: - 预设模板
    
    /// 获取预设模板
    func getPresets() -> [MoodBoardCreationConfig] {
        return [
            MoodBoardCreationConfig(
                title: "本周精选",
                description: "本周最精彩的梦境合集",
                theme: .starry,
                layout: .grid,
                isPublic: false
            ),
            MoodBoardCreationConfig(
                title: "清醒梦之旅",
                description: "所有清醒梦体验的视觉记录",
                theme: .aurora,
                layout: .timeline,
                isPublic: true
            ),
            MoodBoardCreationConfig(
                title: "创意灵感板",
                description: "从梦境中获取的创意和灵感",
                theme: .gold,
                layout: .freeform,
                isPublic: false
            ),
            MoodBoardCreationConfig(
                title: "情绪探索",
                description: "不同情绪状态的梦境对比",
                theme: .rose,
                layout: .masonry,
                isPublic: false
            )
        ]
    }
}

// MARK: - 错误类型

enum MoodBoardError: LocalizedError {
    case boardNotFound
    case dreamNotFound
    case exportFailed
    case shareFailed
    
    var errorDescription: String? {
        switch self {
        case .boardNotFound: return "情绪板不存在"
        case .dreamNotFound: return "梦境不存在"
        case .exportFailed: return "导出失败"
        case .shareFailed: return "分享失败"
        }
    }
}

// MARK: - 扩展

extension DreamMoodBoard {
    /// 检查是否包含某个梦境
    func containsDream(id: UUID) -> Bool {
        return dreamIds.contains(id)
    }
    
    /// 梦境数量
    var dreamCount: Int {
        return dreamIds.count
    }
    
    /// 最后更新时间（格式化）
    var lastUpdatedString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
}
