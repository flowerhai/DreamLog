//
//  DreamMoodBoardTests.swift
//  DreamLogTests
//
//  梦境情绪板单元测试
//  Phase 76 - 梦境情绪板功能
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamMoodBoardTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var service: DreamMoodBoardService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存中的 ModelContainer
        let schema = Schema([
            DreamMoodBoard.self,
            Dream.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // 创建 Service
        service = DreamMoodBoardService(modelContainer: modelContainer)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 创建测试
    
    func testCreateBoard() async throws {
        let config = MoodBoardCreationConfig(
            title: "测试情绪板",
            description: "这是一个测试描述",
            theme: .starry,
            layout: .grid,
            dreamIds: [],
            isPublic: false
        )
        
        let board = try await service.createBoard(config: config)
        
        XCTAssertEqual(board.title, "测试情绪板")
        XCTAssertEqual(board.description, "这是一个测试描述")
        XCTAssertEqual(board.theme, .starry)
        XCTAssertEqual(board.layout, .grid)
        XCTAssertFalse(board.isPublic)
        XCTAssertEqual(board.dreamIds.count, 0)
        XCTAssertNotNil(board.id)
    }
    
    func testCreateBoardWithDreams() async throws {
        let dreamIds = [UUID(), UUID(), UUID()]
        let config = MoodBoardCreationConfig(
            title: "带梦境的情绪板",
            theme: .ocean,
            layout: .timeline,
            dreamIds: dreamIds,
            isPublic: true
        )
        
        let board = try await service.createBoard(config: config)
        
        XCTAssertEqual(board.dreamIds.count, 3)
        XCTAssertEqual(board.dreamIds, dreamIds)
        XCTAssertTrue(board.isPublic)
    }
    
    func testCreateBoardEmptyTitle() async throws {
        let config = MoodBoardCreationConfig(
            title: "",
            theme: .forest,
            dreamIds: []
        )
        
        let board = try await service.createBoard(config: config)
        
        XCTAssertEqual(board.title, "未命名情绪板")
    }
    
    // MARK: - 查询测试
    
    func testLoadAllBoards() async throws {
        // 创建多个情绪板
        for i in 1...5 {
            let config = MoodBoardCreationConfig(
                title: "情绪板 \(i)",
                theme: MoodBoardTheme.allCases[i % MoodBoardTheme.allCases.count],
                dreamIds: []
            )
            try await service.createBoard(config: config)
        }
        
        let boards = try await service.loadAllBoards()
        
        XCTAssertEqual(boards.count, 5)
    }
    
    func testGetBoardById() async throws {
        let config = MoodBoardCreationConfig(
            title: "查找测试",
            theme: .starry,
            dreamIds: []
        )
        let createdBoard = try await service.createBoard(config: config)
        
        let fetchedBoard = try await service.getBoard(id: createdBoard.id)
        
        XCTAssertNotNil(fetchedBoard)
        XCTAssertEqual(fetchedBoard?.id, createdBoard.id)
        XCTAssertEqual(fetchedBoard?.title, "查找测试")
    }
    
    func testGetBoardNotFound() async throws {
        let nonExistentId = UUID()
        let board = try await service.getBoard(id: nonExistentId)
        
        XCTAssertNil(board)
    }
    
    // MARK: - 更新测试
    
    func testUpdateBoard() async throws {
        let config = MoodBoardCreationConfig(
            title: "原始标题",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        board.title = "更新后的标题"
        board.description = "新的描述"
        board.theme = .sunset
        
        try await service.updateBoard(board)
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.title, "更新后的标题")
        XCTAssertEqual(updatedBoard?.description, "新的描述")
        XCTAssertEqual(updatedBoard?.theme, .sunset)
    }
    
    func testUpdateBoardTimestamp() async throws {
        let config = MoodBoardCreationConfig(
            title: "时间戳测试",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        let oldUpdatedAt = board.updatedAt
        
        // 等待一小段时间
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        
        board.title = "更新标题"
        try await service.updateBoard(board)
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertGreaterThan(updatedBoard?.updatedAt ?? Date(), oldUpdatedAt)
    }
    
    // MARK: - 删除测试
    
    func testDeleteBoard() async throws {
        let config = MoodBoardCreationConfig(
            title: "待删除",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        try await service.deleteBoard(id: board.id)
        
        let fetchedBoard = try await service.getBoard(id: board.id)
        XCTAssertNil(fetchedBoard)
        
        let allBoards = try await service.loadAllBoards()
        XCTAssertEqual(allBoards.count, 0)
    }
    
    func testDeleteNonExistentBoard() async throws {
        let nonExistentId = UUID()
        
        // 删除不存在的板不应该抛出错误
        try await service.deleteBoard(id: nonExistentId)
    }
    
    // MARK: - 梦境管理测试
    
    func testAddDreamToBoard() async throws {
        let config = MoodBoardCreationConfig(
            title: "添加梦境测试",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        let dreamId = UUID()
        try await service.addDreamToBoard(boardId: board.id, dreamId: dreamId)
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.dreamIds.count, 1)
        XCTAssertTrue(updatedBoard?.dreamIds.contains(dreamId) ?? false)
    }
    
    func testAddDuplicateDreamToBoard() async throws {
        let dreamId = UUID()
        let config = MoodBoardCreationConfig(
            title: "重复梦境测试",
            theme: .starry,
            dreamIds: [dreamId]
        )
        let board = try await service.createBoard(config: config)
        
        // 尝试添加相同的梦境
        try await service.addDreamToBoard(boardId: board.id, dreamId: dreamId)
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.dreamIds.count, 1) // 不应该重复
    }
    
    func testRemoveDreamFromBoard() async throws {
        let dreamId1 = UUID()
        let dreamId2 = UUID()
        let config = MoodBoardCreationConfig(
            title: "移除梦境测试",
            theme: .starry,
            dreamIds: [dreamId1, dreamId2]
        )
        let board = try await service.createBoard(config: config)
        
        try await service.removeDreamFromBoard(boardId: board.id, dreamId: dreamId1)
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.dreamIds.count, 1)
        XCTAssertEqual(updatedBoard?.dreamIds.first, dreamId2)
    }
    
    // MARK: - 笔记管理测试
    
    func testAddNoteToBoard() async throws {
        let config = MoodBoardCreationConfig(
            title: "笔记测试",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        let note = MoodBoardNote(
            content: "测试笔记内容",
            position: CGPointCodable(x: 100, y: 200),
            fontSize: 18,
            fontColor: "#FFFFFF"
        )
        
        try await service.addNoteToBoard(boardId: board.id, note: note)
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.customNotes.count, 1)
        XCTAssertEqual(updatedBoard?.customNotes.first?.content, "测试笔记内容")
    }
    
    func testUpdateNoteInBoard() async throws {
        let noteId = UUID()
        let note = MoodBoardNote(
            id: noteId,
            content: "原始内容",
            position: CGPointCodable(x: 0, y: 0)
        )
        
        let config = MoodBoardCreationConfig(
            title: "更新笔记测试",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        // 先添加笔记
        board.customNotes.append(note)
        try await service.updateBoard(board)
        
        // 更新笔记
        try await service.updateNoteInBoard(
            boardId: board.id,
            noteId: noteId,
            content: "更新后的内容",
            position: CGPointCodable(x: 50, y: 100)
        )
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.customNotes.first?.content, "更新后的内容")
        XCTAssertEqual(updatedBoard?.customNotes.first?.position.x, 50)
        XCTAssertEqual(updatedBoard?.customNotes.first?.position.y, 100)
    }
    
    func testDeleteNoteFromBoard() async throws {
        let noteId = UUID()
        let note = MoodBoardNote(id: noteId, content: "待删除笔记")
        
        let config = MoodBoardCreationConfig(
            title: "删除笔记测试",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        board.customNotes.append(note)
        try await service.updateBoard(board)
        
        try await service.deleteNoteFromBoard(boardId: board.id, noteId: noteId)
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.customNotes.count, 0)
    }
    
    // MARK: - 统计测试
    
    func testGetStats() async throws {
        // 创建多个情绪板
        for i in 1...3 {
            let config = MoodBoardCreationConfig(
                title: "情绪板 \(i)",
                theme: .starry,
                dreamIds: Array(repeating: UUID(), count: i),
                isPublic: i % 2 == 0
            )
            let board = try await service.createBoard(config: config)
            board.shareCount = i
            board.viewCount = i * 10
            try await service.updateBoard(board)
        }
        
        let stats = try await service.getStats()
        
        XCTAssertEqual(stats.totalBoards, 3)
        XCTAssertEqual(stats.publicBoards, 1) // 只有 i=2 是公开的
        XCTAssertEqual(stats.privateBoards, 2)
        XCTAssertEqual(stats.totalShares, 6) // 1+2+3
        XCTAssertEqual(stats.totalViews, 60) // 10+20+30
        XCTAssertEqual(stats.averageDreamsPerBoard, 2.0, accuracy: 0.01) // (1+2+3)/3
    }
    
    func testGetStatsEmpty() async throws {
        let stats = try await service.getStats()
        
        XCTAssertEqual(stats.totalBoards, 0)
        XCTAssertEqual(stats.averageDreamsPerBoard, 0)
    }
    
    // MARK: - 分享功能测试
    
    func testGenerateShareCard() async throws {
        let config = MoodBoardCreationConfig(
            title: "分享测试",
            theme: .ocean,
            dreamIds: [UUID(), UUID()]
        )
        let board = try await service.createBoard(config: config)
        
        let shareCard = try await service.generateShareCard(boardId: board.id)
        
        XCTAssertEqual(shareCard.boardId, board.id)
        XCTAssertEqual(shareCard.boardTitle, "分享测试")
        XCTAssertEqual(shareCard.dreamCount, 2)
        XCTAssertEqual(shareCard.theme, .ocean)
        XCTAssertEqual(shareCard.shareCode.count, 8)
        
        // 验证分享计数增加
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.shareCount, 1)
        XCTAssertNotNil(updatedBoard?.lastSharedAt)
    }
    
    func testIncrementViewCount() async throws {
        let config = MoodBoardCreationConfig(
            title: "浏览计数测试",
            theme: .starry,
            dreamIds: []
        )
        let board = try await service.createBoard(config: config)
        
        // 增加 5 次浏览
        for _ in 1...5 {
            try await service.incrementViewCount(boardId: board.id)
        }
        
        let updatedBoard = try await service.getBoard(id: board.id)
        XCTAssertEqual(updatedBoard?.viewCount, 5)
    }
    
    // MARK: - 推荐功能测试
    
    func testRecommendTheme() async {
        let dreamIds = [UUID(), UUID(), UUID()]
        let theme = await service.recommendTheme(for: dreamIds)
        
        XCTAssertTrue(MoodBoardTheme.allCases.contains(theme))
    }
    
    func testRecommendLayout() async {
        // 少量梦境推荐拼贴布局
        let layout1 = await service.recommendLayout(for: 2)
        XCTAssertEqual(layout1, .collage)
        
        // 中等数量推荐网格布局
        let layout2 = await service.recommendLayout(for: 5)
        XCTAssertEqual(layout2, .grid)
        
        // 较多数推荐瀑布流
        let layout3 = await service.recommendLayout(for: 8)
        XCTAssertEqual(layout3, .masonry)
        
        // 大量推荐时间线
        let layout4 = await service.recommendLayout(for: 15)
        XCTAssertEqual(layout4, .timeline)
    }
    
    // MARK: - 预设模板测试
    
    func testGetPresets() async {
        let presets = await service.getPresets()
        
        XCTAssertGreaterThanOrEqual(presets.count, 1)
        
        // 验证预设包含必要的信息
        for preset in presets {
            XCTAssertFalse(preset.title.isEmpty)
            XCTAssertTrue(MoodBoardTheme.allCases.contains(preset.theme))
            XCTAssertTrue(MoodBoardLayout.allCases.contains(preset.layout))
        }
    }
    
    // MARK: - 模型扩展测试
    
    func testDreamMoodBoardContainsDream() {
        let dreamId = UUID()
        let board = DreamMoodBoard(
            title: "测试",
            dreamIds: [dreamId, UUID()]
        )
        
        XCTAssertTrue(board.containsDream(id: dreamId))
        XCTAssertFalse(board.containsDream(id: UUID()))
    }
    
    func testDreamMoodBoardDreamCount() {
        let dreamIds = [UUID(), UUID(), UUID(), UUID()]
        let board = DreamMoodBoard(
            title: "测试",
            dreamIds: dreamIds
        )
        
        XCTAssertEqual(board.dreamCount, 4)
    }
    
    // MARK: - 主题枚举测试
    
    func testMoodBoardThemeCases() {
        XCTAssertEqual(MoodBoardTheme.allCases.count, 12)
    }
    
    func testMoodBoardThemeDisplayName() {
        XCTAssertEqual(MoodBoardTheme.starry.displayName, "星空紫")
        XCTAssertEqual(MoodBoardTheme.ocean.displayName, "海洋蓝")
        XCTAssertEqual(MoodBoardTheme.forest.displayName, "森林绿")
    }
    
    func testMoodBoardThemeGradientColors() {
        let colors = MoodBoardTheme.starry.gradientColors
        XCTAssertEqual(colors.count, 3)
    }
    
    // MARK: - 布局枚举测试
    
    func testMoodBoardLayoutCases() {
        XCTAssertEqual(MoodBoardLayout.allCases.count, 5)
    }
    
    func testMoodBoardLayoutDisplayName() {
        XCTAssertEqual(MoodBoardLayout.grid.displayName, "网格布局")
        XCTAssertEqual(MoodBoardLayout.freeform.displayName, "自由布局")
        XCTAssertEqual(MoodBoardLayout.timeline.displayName, "时间线")
    }
    
    // MARK: - 分享卡片测试
    
    func testShareCardGeneration() {
        let card = MoodBoardShareCard(
            boardId: UUID(),
            boardTitle: "测试卡片",
            boardDescription: "描述",
            theme: .starry,
            dreamCount: 5
        )
        
        XCTAssertEqual(card.shareCode.count, 8)
        XCTAssertGreaterThan(card.expiresAt, Date())
    }
    
    func testShareCodeUniqueness() {
        let cards = (1...10).map { _ in
            MoodBoardShareCard(
                boardId: UUID(),
                boardTitle: "测试",
                boardDescription: "",
                theme: .starry,
                dreamCount: 0
            )
        }
        
        let codes = cards.map { $0.shareCode }
        let uniqueCodes = Set(codes)
        
        XCTAssertEqual(uniqueCodes.count, codes.count, "分享码应该是唯一的")
    }
    
    // MARK: - 性能测试
    
    func testPerformanceCreateBoards() async throws {
        self.measure {
            let expectation = XCTestExpectation(description: "Create boards")
            
            Task {
                for _ in 1...10 {
                    let config = MoodBoardCreationConfig(
                        title: "性能测试",
                        theme: .starry,
                        dreamIds: []
                    )
                    _ = try? await service.createBoard(config: config)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}
