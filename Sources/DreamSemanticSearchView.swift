//
//  DreamSemanticSearchView.swift
//  DreamLog - 梦境语义搜索 UI 界面
//
//  Phase 88: 梦境语义搜索功能
//  提供直观的智能搜索界面
//

import SwiftUI
import SwiftData

struct DreamSemanticSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [DreamSearchResult] = []
    @State private var suggestions: [SearchSuggestion] = []
    @State private var showFilters: Bool = false
    @State private var searchFilters: SearchFilters = SearchFilters()
    @State private var selectedTab: SearchTab = .search
    @State private var errorMessage: String?
    
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    
    private enum SearchTab {
        case search
        case history
        case saved
        case statistics
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                searchHeader
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    searchTab
                        .tabItem {
                            Label("搜索", systemImage: "magnifyingglass")
                        }
                        .tag(SearchTab.search)
                    
                    historyTab
                        .tabItem {
                            Label("历史", systemImage: "clock")
                        }
                        .tag(SearchTab.history)
                    
                    savedTab
                        .tabItem {
                            Label("已保存", systemImage: "bookmark")
                        }
                        .tag(SearchTab.saved)
                    
                    statisticsTab
                        .tabItem {
                            Label("统计", systemImage: "chart.bar")
                        }
                        .tag(SearchTab.statistics)
                }
            }
            .navigationTitle("智能搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filters: $searchFilters)
            }
        }
    }
    
    // MARK: - Search Header
    
    private var searchHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索梦境内容、情绪、主题...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .onChange(of: searchText) { oldValue, newValue in
                        Task {
                            await onSearchTextChanged(newValue)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        suggestions = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 搜索建议
            if !suggestions.isEmpty && searchText.isEmpty {
                suggestionsList
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Search Tab
    
    private var searchTab: some View {
        Group {
            if isSearching {
                loadingView
            } else if !searchResults.isEmpty {
                resultsList
            } else if !searchText.isEmpty {
                emptyResultsView
            } else {
                searchPromptView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在搜索梦境...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 结果统计
                resultSummary
                
                // 结果列表
                ForEach(searchResults, id: \.id) { result in
                    SearchResultCard(result: result, dreams: dreams)
                        .onTapGesture {
                            // TODO: 导航到梦境详情
                        }
                }
            }
            .padding()
        }
    }
    
    private var resultSummary: some View {
        HStack {
            Text("找到 \(searchResults.count) 个相关梦境")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Menu {
                ForEach(["相关性", "日期", "清晰度"], id: \.self) { option in
                    Button(option) {
                        // TODO: 实现排序
                    }
                }
            } label: {
                HStack {
                    Text("排序")
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("未找到相关梦境")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("尝试使用不同的关键词或调整搜索条件")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("清除筛选条件") {
                searchFilters = SearchFilters()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var searchPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("智能语义搜索")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                SearchExampleRow(icon: "text.magnifyingglass", text: "试试搜索：\"飞行相关的梦\"")
                SearchExampleRow(icon: "face.smiling", text: "试试搜索：\"快乐的梦境\"")
                SearchExampleRow(icon: "star.fill", text: "试试搜索：\"关于水的梦\"")
                SearchExampleRow(icon: "brain.head.profile", text: "试试搜索：\"被追逐的噩梦\"")
            }
            .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - History Tab
    
    private var historyTab: some View {
        VStack {
            HStack {
                Text("搜索历史")
                    .font(.headline)
                
                Spacer()
                
                Button("清除全部") {
                    Task {
                        try? await DreamSemanticSearchService().clearSearchHistory()
                    }
                }
                .foregroundColor(.red)
            }
            .padding()
            
            // TODO: 加载和显示历史
            Text("搜索历史将显示在这里")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Saved Tab
    
    private var savedTab: some View {
        VStack {
            HStack {
                Text("已保存的搜索")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    // TODO: 添加新保存的搜索
                } label: {
                    Image(systemName: "plus")
                }
            }
            .padding()
            
            // TODO: 加载和显示保存的搜索
            Text("保存的搜索将显示在这里")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Statistics Tab
    
    private var statisticsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 统计卡片
                StatisticsOverviewCard()
                
                // 热门搜索
                PopularSearchesCard()
                
                // 搜索趋势
                SearchTrendsCard()
            }
            .padding()
        }
    }
    
    // MARK: - Suggestions
    
    private var suggestionsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.text) { suggestion in
                    Button {
                        searchText = suggestion.text
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: suggestion.icon)
                            Text(suggestion.text)
                            if let count = suggestion.count {
                                Text("(\(count))")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Handlers
    
    private func onSearchTextChanged(_ newValue: String) async {
        if newValue.isEmpty {
            searchResults = []
            return
        }
        
        // 获取建议
        suggestions = await DreamSemanticSearchService().getSuggestions(for: newValue)
    }
    
    private func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            let service = DreamSemanticSearchService()
            searchResults = await service.search(query: searchText, filters: searchFilters)
        } catch {
            errorMessage = "搜索失败：\(error.localizedDescription)"
        }
        
        isSearching = false
    }
}

// MARK: - Subviews

struct SearchExampleRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(text)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}

struct SearchResultCard: View {
    let result: DreamSearchResult
    let dreams: [Dream]
    
    private var dream: Dream? {
        dreams.first { $0.id == result.dreamId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 匹配类型标识
                matchTypeBadge
                
                Spacer()
                
                // 相关性分数
                relevanceScoreBadge
            }
            
            // 梦境标题
            Text(dream?.title ?? "无标题")
                .font(.headline)
                .lineLimit(2)
            
            // 梦境内容预览
            Text(dream?.content ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // 匹配的关键词
            if !result.matchedKeywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(result.matchedKeywords, id: \.self) { keyword in
                            Text("#\(keyword)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 底部信息
            HStack {
                Text(formatDate(dream?.date ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if dream?.isLucid == true {
                    Label("清醒梦", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var matchTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForMatchType(result.matchType))
                .font(.caption)
            Text(textForMatchType(result.matchType))
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colorForMatchType(result.matchType).opacity(0.1))
        .foregroundColor(colorForMatchType(result.matchType))
        .cornerRadius(6)
    }
    
    private var relevanceScoreBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(relevanceColor)
                .frame(width: 8, height: 8)
            
            Text("\(Int(result.relevanceScore * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
    
    private var relevanceColor: Color {
        if result.relevanceScore >= 0.8 {
            return .green
        } else if result.relevanceScore >= 0.5 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    private func iconForMatchType(_ type: SearchMatchType) -> String {
        switch type {
        case .exact: return "checkmark.circle.fill"
        case .semantic: return "brain.head.profile"
        case .emotion: return "face.smiling"
        case .theme: return "tag"
        case .symbol: return "star.fill"
        case .concept: return "lightbulb"
        }
    }
    
    private func textForMatchType(_ type: SearchMatchType) -> String {
        switch type {
        case .exact: return "精确匹配"
        case .semantic: return "语义匹配"
        case .emotion: return "情绪匹配"
        case .theme: return "主题匹配"
        case .symbol: return "符号匹配"
        case .concept: return "概念匹配"
        }
    }
    
    private func colorForMatchType(_ type: SearchMatchType) -> Color {
        switch type {
        case .exact: return .green
        case .semantic: return .purple
        case .emotion: return .pink
        case .theme: return .blue
        case .symbol: return .orange
        case .concept: return .teal
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: SearchFilters
    
    var body: some View {
        NavigationStack {
            Form {
                // 日期范围
                Section("日期范围") {
                    Picker("时间", selection: $filters.dateRange) {
                        ForEach(DateRangeFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                }
                
                // 清晰度范围
                Section("清晰度") {
                    VStack(alignment: .leading) {
                        Text("最小清晰度：\(filters.minClarity)")
                        Slider(value: Binding(
                            get: { Double(filters.minClarity) },
                            set: { filters.minClarity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("最大清晰度：\(filters.maxClarity)")
                        Slider(value: Binding(
                            get: { Double(filters.maxClarity) },
                            set: { filters.maxClarity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                }
                
                // 特殊筛选
                Section("筛选条件") {
                    Toggle("仅清醒梦", isOn: $filters.lucidOnly)
                    Toggle("包含 AI 解析", isOn: $filters.withAIAnalysis)
                    Toggle("包含图片", isOn: $filters.withImages)
                    Toggle("包含音频", isOn: $filters.withAudio)
                }
            }
            .navigationTitle("筛选条件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        filters = SearchFilters()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatisticsOverviewCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("搜索统计")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatBox(title: "总搜索次数", value: "0", icon: "magnifyingglass")
                StatBox(title: "已保存", value: "0", icon: "bookmark")
                StatBox(title: "平均结果", value: "0", icon: "list.bullet")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PopularSearchesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门搜索")
                .font(.headline)
            
            ForEach(["飞行", "水", "追逐", "考试", "牙齿"], id: \.self) { term in
                HStack {
                    Text(term)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SearchTrendsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("搜索趋势")
                .font(.headline)
            
            Text("搜索趋势图表将显示在这里")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 150)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    DreamSemanticSearchView()
        .modelContainer(for: Dream.self, inMemory: true)
}
