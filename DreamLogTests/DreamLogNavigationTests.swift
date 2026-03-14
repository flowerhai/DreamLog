//
//  DreamLogNavigationTests.swift
//  DreamLogTests
//
//  Phase 43 - 导航重构单元测试
//

import XCTest
@testable import DreamLog

final class DreamLogNavigationTests: XCTestCase {
    
    // MARK: - MainTab 测试
    
    func testMainTabCount() {
        XCTAssertEqual(MainTab.allCases.count, 5, "应该有 5 个主标签")
    }
    
    func testMainTabTitles() {
        XCTAssertEqual(MainTab.dreams.title, "梦境")
        XCTAssertEqual(MainTab.insights.title, "分析")
        XCTAssertEqual(MainTab.explore.title, "探索")
        XCTAssertEqual(MainTab.growth.title, "成长")
        XCTAssertEqual(MainTab.profile.title, "我的")
    }
    
    func testMainTabIcons() {
        XCTAssertEqual(MainTab.dreams.icon, "book.fill")
        XCTAssertEqual(MainTab.insights.icon, "chart.bar.fill")
        XCTAssertEqual(MainTab.explore.icon, "compass.fill")
        XCTAssertEqual(MainTab.growth.icon, "leaf.fill")
        XCTAssertEqual(MainTab.profile.icon, "person.circle.fill")
    }
    
    func testMainTabColors() {
        XCTAssertNotNil(MainTab.dreams.color)
        XCTAssertNotNil(MainTab.insights.color)
        XCTAssertNotNil(MainTab.explore.color)
        XCTAssertNotNil(MainTab.growth.color)
        XCTAssertNotNil(MainTab.profile.color)
    }
    
    func testMainTabViews() {
        for tab in MainTab.allCases {
            XCTAssertFalse(tab.views.isEmpty, "\(tab.title) 应该有至少一个视图")
        }
        
        XCTAssertEqual(MainTab.dreams.views.count, 4)
        XCTAssertEqual(MainTab.insights.views.count, 5)
        XCTAssertEqual(MainTab.explore.views.count, 5)
        XCTAssertEqual(MainTab.growth.views.count, 6)
        XCTAssertEqual(MainTab.profile.views.count, 7)
    }
    
    func testMainTabDefaultView() {
        for tab in MainTab.allCases {
            XCTAssertNotNil(tab.defaultView)
            XCTAssertTrue(tab.views.contains(tab.defaultView))
        }
    }
    
    // MARK: - NavigationViewItem 测试
    
    func testNavigationViewItemIdentity() {
        let item1 = NavigationViewItem(id: "test", title: "测试", icon: "star", destination: AnyView(Text("Test")), isFavorite: false)
        let item2 = NavigationViewItem(id: "test", title: "测试", icon: "star", destination: AnyView(Text("Test")), isFavorite: true)
        
        XCTAssertEqual(item1.id, item2.id)
        XCTAssertEqual(item1, item2)
        XCTAssertEqual(item1.hashValue, item2.hashValue)
    }
    
    func testNavigationViewItemFavoriteToggle() {
        var item = NavigationViewItem(id: "test", title: "测试", icon: "star", destination: AnyView(Text("Test")), isFavorite: false)
        XCTAssertFalse(item.isFavorite)
        
        item.isFavorite = true
        XCTAssertTrue(item.isFavorite)
    }
    
    // MARK: - FavoriteManager 测试
    
    func testFavoriteManagerSharedInstance() {
        let manager1 = FavoriteManager.shared
        let manager2 = FavoriteManager.shared
        
        XCTAssertIdentical(manager1, manager2)
    }
    
    func testFavoriteManagerToggle() {
        let manager = FavoriteManager.shared
        
        let viewId = "test-view-\(UUID().uuidString)"
        XCTAssertFalse(manager.isFavorite(viewId))
        
        manager.toggleFavorite(viewId)
        XCTAssertTrue(manager.isFavorite(viewId))
        
        manager.toggleFavorite(viewId)
        XCTAssertFalse(manager.isFavorite(viewId))
    }
    
    func testFavoriteManagerPersistence() {
        let manager = FavoriteManager.shared
        let viewId = "persistent-test-\(UUID().uuidString)"
        
        manager.toggleFavorite(viewId)
        
        // 创建新实例模拟重新加载
        let newManager = FavoriteManager.shared
        XCTAssertTrue(newManager.isFavorite(viewId))
        
        // 清理
        newManager.toggleFavorite(viewId)
    }
    
    // MARK: - NavigationHistory 测试
    
    func testNavigationHistoryPush() {
        let history = NavigationHistory.shared
        history.clear()
        
        history.push("view1")
        XCTAssertEqual(history.history.count, 1)
        XCTAssertEqual(history.currentIndex, 0)
        
        history.push("view2")
        XCTAssertEqual(history.history.count, 2)
        XCTAssertEqual(history.currentIndex, 1)
    }
    
    func testNavigationHistoryPop() {
        let history = NavigationHistory.shared
        history.clear()
        
        history.push("view1")
        history.push("view2")
        history.push("view3")
        
        let popped = history.pop()
        XCTAssertEqual(popped, "view2")
        XCTAssertEqual(history.currentIndex, 1)
    }
    
    func testNavigationHistoryClear() {
        let history = NavigationHistory.shared
        history.clear()
        
        history.push("view1")
        history.push("view2")
        
        history.clear()
        XCTAssertEqual(history.history.count, 0)
        XCTAssertEqual(history.currentIndex, -1)
    }
    
    // MARK: - QuickAction 测试
    
    func testQuickActionCount() {
        XCTAssertEqual(QuickAction.allCases.count, 6)
    }
    
    func testQuickActionTitles() {
        XCTAssertEqual(QuickAction.addDream.title, "记录梦境")
        XCTAssertEqual(QuickAction.voiceRecord.title, "语音记录")
        XCTAssertEqual(QuickAction.scanQR.title, "扫描二维码")
        XCTAssertEqual(QuickAction.arCapture.title, "AR 捕获")
        XCTAssertEqual(QuickAction.todayStats.title, "今日统计")
        XCTAssertEqual(QuickAction.weeklyReport.title, "周报")
    }
    
    func testQuickActionIcons() {
        XCTAssertEqual(QuickAction.addDream.icon, "plus.circle.fill")
        XCTAssertEqual(QuickAction.voiceRecord.icon, "mic.fill")
        XCTAssertEqual(QuickAction.scanQR.icon, "qrcode.viewfinder")
        XCTAssertEqual(QuickAction.arCapture.icon, "viewfinder")
        XCTAssertEqual(QuickAction.todayStats.icon, "chart.bar.fill")
        XCTAssertEqual(QuickAction.weeklyReport.icon, "doc.richtext.fill")
    }
    
    func testQuickActionColors() {
        for action in QuickAction.allCases {
            XCTAssertNotNil(action.color)
        }
    }
    
    // MARK: - GlobalSearchService 测试
    
    func testGlobalSearchServiceSharedInstance() {
        let service1 = GlobalSearchService.shared
        let service2 = GlobalSearchService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    func testGlobalSearchServiceInitialState() {
        let service = GlobalSearchService.shared
        
        XCTAssertFalse(service.isSearching)
        XCTAssertTrue(service.searchResults.isEmpty)
        XCTAssertTrue(service.searchQuery.isEmpty)
    }
    
    func testGlobalSearchServiceEmptyQuery() async {
        let service = GlobalSearchService.shared
        
        await service.search(query: "")
        
        XCTAssertTrue(service.searchResults.isEmpty)
    }
    
    func testGlobalSearchServiceSearchHistory() {
        let service = GlobalSearchService.shared
        
        service.searchHistory = []
        
        // 模拟添加到历史
        let query = "测试搜索"
        service.searchHistory.insert(query, at: 0)
        
        XCTAssertEqual(service.searchHistory.count, 1)
        XCTAssertEqual(service.searchHistory.first, query)
    }
    
    func testGlobalSearchServiceClearHistory() {
        let service = GlobalSearchService.shared
        
        service.searchHistory = ["test1", "test2", "test3"]
        service.clearSearchHistory()
        
        XCTAssertTrue(service.searchHistory.isEmpty)
    }
    
    // MARK: - SearchResultType 测试
    
    func testSearchResultTypeTitle() {
        let dream = Dream(content: "测试梦境")
        let dreamResult = SearchResultType.dream(dream)
        XCTAssertEqual(dreamResult.title, "无标题梦境")
        
        let tagResult = SearchResultType.tag("测试标签")
        XCTAssertEqual(tagResult.title, "#测试标签")
        
        let emotionResult = SearchResultType.emotion("平静")
        XCTAssertEqual(emotionResult.title, "平静")
    }
    
    func testSearchResultTypeIcon() {
        XCTAssertEqual(SearchResultType.dream(Dream(content: "")).icon, "moon.fill")
        XCTAssertEqual(SearchResultType.tag("").icon, "tag.fill")
        XCTAssertEqual(SearchResultType.emotion("").icon, "heart.fill")
        XCTAssertEqual(SearchResultType.communityPost(CommunityPost(title: "", content: "")).icon, "globe")
        XCTAssertEqual(SearchResultType.challenge(DreamChallenge(title: "", description: "", type: .recall, difficulty: .easy, duration: 7)).icon, "trophy.fill")
    }
    
    // MARK: - SearchResult 测试
    
    func testSearchResultProperties() {
        let dream = Dream(content: "测试")
        let result = SearchResult(type: .dream(dream), relevance: 0.8)
        
        XCTAssertNotNil(result.id)
        XCTAssertEqual(result.title, "无标题梦境")
        XCTAssertEqual(result.relevance, 0.8)
        XCTAssertEqual(result.icon, "moon.fill")
    }
    
    func testSearchResultRelevanceSorting() {
        let dream1 = Dream(content: "测试 1")
        let dream2 = Dream(content: "测试 2")
        
        let result1 = SearchResult(type: .dream(dream1), relevance: 0.9)
        let result2 = SearchResult(type: .dream(dream2), relevance: 0.5)
        
        let results = [result2, result1].sorted { $0.relevance > $1.relevance }
        
        XCTAssertEqual(results.first?.relevance, 0.9)
        XCTAssertEqual(results.last?.relevance, 0.5)
    }
    
    // MARK: - 性能测试
    
    func testNavigationModelCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = MainTab.allCases.map { $0.views }
            }
        }
    }
    
    func testSearchResultCreationPerformance() {
        let dream = Dream(content: "测试内容")
        
        measure {
            for _ in 0..<1000 {
                _ = SearchResult(type: .dream(dream), relevance: 0.5)
            }
        }
    }
}
