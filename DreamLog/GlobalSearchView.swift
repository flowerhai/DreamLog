//
//  GlobalSearchView.swift
//  DreamLog
//
//  Phase 43 - 全局搜索界面
//

import SwiftUI

/// 全局搜索视图
struct GlobalSearchView: View {
    @ObservedObject private var searchService = GlobalSearchService.shared
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var selectedResult: SearchResult?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dreamStore: DreamStore
    
    enum SearchFilter: String, CaseIterable {
        case all = "全部"
        case dreams = "梦境"
        case tags = "标签"
        case emotions = "情绪"
        case community = "社区"
        case challenges = "挑战"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2.fill"
            case .dreams: return "moon.fill"
            case .tags: return "tag.fill"
            case .emotions: return "heart.fill"
            case .community: return "globe"
            case .challenges: return "trophy.fill"
            }
        }
    }
    
    var filteredResults: [SearchResult] {
        let results = searchService.searchResults
        switch selectedFilter {
        case .all:
            return results
        case .dreams:
            return results.filter { $0.type is Dream }
        case .tags:
            return results.filter { case .tag = $0.type }
        case .emotions:
            return results.filter { case .emotion = $0.type }
        case .community:
            return results.filter { case .communityPost = $0.type }
        case .challenges:
            return results.filter { case .challenge = $0.type }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchField
                
                // 筛选器
                filterBar
                
                // 搜索结果
                if searchService.isSearching {
                    loadingView
                } else if searchText.isEmpty && searchService.searchHistory.isEmpty {
                    emptyStateView
                } else if searchText.isEmpty {
                    historyView
                } else if filteredResults.isEmpty {
                    noResultsView
                } else {
                    resultsView
                }
            }
            .background(Color(hex: "1A1A2E"))
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !searchText.isEmpty || !searchService.searchHistory.isEmpty {
                        Button("清除") {
                            searchText = ""
                            searchService.clearSearchHistory()
                        }
                        .foregroundColor(Color(hex: "9B7EBD"))
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms 防抖
                if newValue == searchText {
                    await searchService.search(query: newValue)
                }
            }
        }
    }
    
    // MARK: - 搜索栏
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索梦境、标签、情绪...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "16213E"))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - 筛选器
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    GlobalSearchFilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - 加载视图
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "9B7EBD"))
            Text("正在搜索...")
                .foregroundColor(.gray)
                .padding(.top)
            Spacer()
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "9B7EBD").opacity(0.5))
            
            Text("搜索梦境")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("输入关键词搜索梦境、标签、情绪等")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // 热门搜索
            if !searchService.getPopularSearches().isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("热门搜索")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(searchService.getPopularSearches(), id: \.self) { term in
                            Chip(text: term) {
                                searchText = term
                            }
                        }
                    }
                }
                .padding()
                .background(Color(hex: "16213E"))
                .cornerRadius(12)
                .padding()
            }
        }
    }
    
    // MARK: - 历史记录视图
    
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("搜索历史")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button("清除") {
                    searchService.clearSearchHistory()
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "9B7EBD"))
            }
            .padding(.horizontal)
            
            ForEach(searchService.searchHistory, id: \.self) { term in
                HistoryRow(term: term) {
                    searchText = term
                }
            }
        }
        .padding(.top)
    }
    
    // MARK: - 无结果视图
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("未找到结果")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("尝试其他关键词或筛选条件")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: - 结果视图
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 结果统计
                HStack {
                    Text("找到 \(filteredResults.count) 个结果")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if filteredResults.count > 0 {
                        Text("按相关性排序")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // 结果列表
                ForEach(filteredResults) { result in
                    SearchResultRow(result: result) {
                        handleResultSelection(result)
                    }
                }
                .navigationDestination(item: $selectedResult) { result in
                    resultDestinationView(result)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 结果处理
    
    private func handleResultSelection(_ result: SearchResult) {
        selectedResult = result
    }
    
    @ViewBuilder
    private func resultDestinationView(_ result: SearchResult) -> some View {
        switch result.type {
        case .dream(let dream):
            // 导航到梦境详情
            DreamDetailView(dream: dream, dreamStore: dreamStore)
        case .tag(let tag):
            // 导航到标签筛选视图
            TagFilterView(selectedTag: tag)
        case .emotion(let emotion):
            // 导航到情绪筛选视图
            EmotionFilterView(selectedEmotion: Emotion(rawValue: emotion) ?? .calm)
        case .communityPost(let post):
            // 导航到社区帖子详情
            CommunityPostDetailView(sharedDream: post)
        case .challenge(let challenge):
            // 导航到挑战详情
            ChallengeDetailView(challenge: challenge)
        }
    }
}

// MARK: - 筛选器芯片

struct GlobalSearchFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: "9B7EBD") : Color(hex: "16213E"))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(16)
        }
    }
}

// MARK: - 历史记录行

struct HistoryRow: View {
    let term: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Text(term)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color(hex: "16213E"))
            .cornerRadius(8)
        }
    }
}

// MARK: - 搜索结果行

struct SearchResultRow: View {
    let result: SearchResult
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color(hex: "9B7EBD").opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: result.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "9B7EBD"))
                }
                
                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(result.subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 相关性指示器
                if result.relevance > 0.5 {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "FFC000"))
                }
            }
            .padding()
            .background(Color(hex: "16213E"))
            .cornerRadius(12)
        }
    }
}

// MARK: - 芯片组件

struct Chip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "16213E"))
                .foregroundColor(.gray)
                .cornerRadius(16)
        }
    }
}

// MARK: - 预览

#Preview {
    GlobalSearchView()
        .environmentObject(DreamStore())
}
