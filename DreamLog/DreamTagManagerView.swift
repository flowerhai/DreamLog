//
//  DreamTagManagerView.swift
//  DreamLog
//
//  智能标签管理界面
//  Phase 32: 智能标签管理
//

import SwiftUI

struct DreamTagManagerView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var tagManager: DreamTagManagerService
    
    @State private var selectedTab: TagManagerTab = .overview
    @State private var searchText: String = ""
    @State private var selectedCategory: TagCategory?
    @State private var showingRenameSheet = false
    @State private var showingMergeSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedTag: TagInfo?
    @State private var tags: [TagInfo] = []
    @State private var statistics: TagStatistics?
    @State private var cleanupSuggestions: [TagCleanupSuggestion] = []
    @State private var tagSuggestions: [TagSuggestion] = []
    
    enum TagManagerTab: String, CaseIterable {
        case overview = "概览"
        case all = "所有标签"
        case suggestions = "建议"
        case cleanup = "清理"
    }
    
    init() {
        _tagManager = StateObject(wrappedValue: DreamTagManagerService(dreamStore: DreamStore.shared))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab 选择器
                Picker("标签管理", selection: $selectedTab) {
                    ForEach(TagManagerTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                // 内容区域
                switch selectedTab {
                case .overview:
                    OverviewTabView(
                        statistics: statistics,
                        tags: tags,
                        onTagSelected: { tag in
                            selectedTag = tag
                            selectedTab = .all
                        }
                    )
                    
                case .all:
                    AllTagsTabView(
                        tags: filteredTags,
                        searchText: $searchText,
                        selectedCategory: $selectedCategory,
                        onTagSelected: { tag in
                            selectedTag = tag
                            showingRenameSheet = true
                        },
                        onCategoryChange: { tag, category in
                            Task {
                                await tagManager.categorizeTag(tag.name, category: category)
                                await loadTags()
                            }
                        }
                    )
                    
                case .suggestions:
                    SuggestionsTabView(
                        suggestions: tagSuggestions,
                        onApply: { suggestion in
                            Task {
                                await tagManager.applySuggestion(suggestion)
                                await loadTagSuggestions()
                            }
                        }
                    )
                    
                case .cleanup:
                    CleanupTabView(
                        suggestions: cleanupSuggestions,
                        onMerge: { source, target in
                            Task {
                                let result = await tagManager.mergeTags(sourceTag: source, targetTag: target)
                                await loadTags()
                                await loadCleanupSuggestions()
                            }
                        },
                        onDelete: { tag in
                            Task {
                                let result = await tagManager.deleteTag(tag)
                                await loadTags()
                                await loadCleanupSuggestions()
                            }
                        }
                    )
                }
            }
            .navigationTitle("标签管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingRenameSheet) {
                if let tag = selectedTag {
                    RenameTagSheet(tag: tag, tagManager: tagManager) {
                        Task {
                            await loadTags()
                            showingRenameSheet = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        await loadTags()
        await loadStatistics()
        await loadCleanupSuggestions()
        await loadTagSuggestions()
    }
    
    private func loadTags() async {
        tags = await tagManager.getAllTags()
    }
    
    private func loadStatistics() async {
        statistics = await tagManager.getStatistics()
    }
    
    private func loadCleanupSuggestions() async {
        cleanupSuggestions = await tagManager.getCleanupSuggestions()
    }
    
    private func loadTagSuggestions() async {
        tagSuggestions = await tagManager.getTagSuggestions()
    }
    
    // MARK: - Filtered Tags
    
    private var filteredTags: [TagInfo] {
        var result = tags
        
        // 搜索过滤
        if !searchText.isEmpty {
            result = result.filter { tag in
                tag.name.localizedCaseInsensitiveContains(searchText) ||
                tag.normalized.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 分类过滤
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        return result.sorted { $0.count > $1.count }
    }
}

// MARK: - Overview Tab

struct OverviewTabView: View {
    let statistics: TagStatistics?
    let tags: [TagInfo]
    let onTagSelected: (TagInfo) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 统计卡片
                if let stats = statistics {
                    StatisticsCards(stats: stats)
                }
                
                // 热门标签
                VStack(alignment: .leading, spacing: 12) {
                    Text("热门标签")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(tags.prefix(10)) { tag in
                                TagChip(tag: tag) {
                                    onTagSelected(tag)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 分类分布
                if let stats = statistics, !stats.categoryDistribution.isEmpty {
                    CategoryDistributionChart(stats: stats)
                }
                
                // 最近使用的标签
                if let stats = statistics {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近使用")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(stats.recentTags.prefix(5)) { tag in
                            RecentTagRow(tag: tag) {
                                onTagSelected(tag)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - All Tags Tab

struct AllTagsTabView: View {
    let tags: [TagInfo]
    @Binding var searchText: String
    @Binding var selectedCategory: TagCategory?
    let onTagSelected: (TagInfo) -> Void
    let onCategoryChange: (TagInfo, TagCategory) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 分类筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    TagManagerFilterChip(
                        title: "全部分类",
                        isSelected: selectedCategory == nil,
                        color: selectedCategory == nil ? "6C63FF" : "E0E0E0"
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(TagCategory.allCases) { category in
                        TagManagerFilterChip(
                            title: category.icon + " " + category.rawValue,
                            isSelected: selectedCategory == category,
                            color: selectedCategory == category ? category.color : "E0E0E0"
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 标签列表
            List {
                Section {
                    ForEach(tags) { tag in
                        TagRow(
                            tag: tag,
                            onTap: { onTagSelected(tag) },
                            onCategoryChange: { category in
                                onCategoryChange(tag, category)
                            }
                        )
                    }
                }
            }
            .listStyle(.plain)
            
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("搜索标签...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding()
        }
    }
}

// MARK: - Suggestions Tab

struct SuggestionsTabView: View {
    let suggestions: [TagSuggestion]
    let onApply: (TagSuggestion) -> Void
    
    var body: some View {
        List {
            if suggestions.isEmpty {
                Text("暂无建议")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(suggestions) { suggestion in
                    SuggestionCard(
                        suggestion: suggestion,
                        onApply: { onApply(suggestion) }
                    )
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Cleanup Tab

struct CleanupTabView: View {
    let suggestions: [TagCleanupSuggestion]
    let onMerge: (String, String) -> Void
    let onDelete: (String) -> Void
    
    var body: some View {
        List {
            if suggestions.isEmpty {
                Text("🎉 标签状态良好，无需清理")
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(suggestions) { suggestion in
                    CleanupSuggestionCard(
                        suggestion: suggestion,
                        onMerge: onMerge,
                        onDelete: onDelete
                    )
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Sub-views

struct StatisticsCards: View {
    let stats: TagStatistics
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TagManagerStatCard(
                    title: "总标签数",
                    value: "\(stats.totalTags)",
                    icon: "🏷️",
                    color: "6C63FF"
                )
                
                TagManagerStatCard(
                    title: "总使用次数",
                    value: "\(stats.totalUsage)",
                    icon: "📊",
                    color: "4ECDC4"
                )
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                TagManagerStatCard(
                    title: "已分类",
                    value: "\(stats.categorizedTags)",
                    subtitle: "\(String(format: "%.1f", stats.categorizedPercentage))%",
                    icon: "📁",
                    color: "7FB069"
                )
                
                TagManagerStatCard(
                    title: "未分类",
                    value: "\(stats.uncategorizedTags)",
                    icon: "📂",
                    color: "FFA07A"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct TagManagerStatCard: View {
    let title: String
    let value: String
    var subtitle: String?
    let icon: String
    let color: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: color).opacity(0.1))
        .cornerRadius(12)
    }
}

struct TagChip: View {
    let tag: TagInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(tag.name)
                    .font(.subheadline)
                Text("×\(tag.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct TagRow: View {
    let tag: TagInfo
    let onTap: () -> Void
    let onCategoryChange: (TagCategory) -> Void
    
    @State private var showingCategoryPicker = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tag.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("\(tag.count) 次使用")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let category = tag.category {
                        Text(category.icon + " " + category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: category.color).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                ForEach(TagCategory.allCases) { category in
                    Button(action: { onCategoryChange(category) }) {
                        Text(category.icon + " " + category.rawValue)
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    // Delete action
                } label: {
                    Text("删除标签")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct RecentTagRow: View {
    let tag: TagInfo
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(tag.name)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(tag.count) 次")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onTapGesture(perform: onTap)
    }
}

struct TagManagerFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: color))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct SuggestionCard: View {
    let suggestion: TagSuggestion
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(suggestion.dreamTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(suggestion.confidence * 100))% 匹配")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            TagManagerWrapLayout(spacing: 8) {
                ForEach(suggestion.suggestedTags, id: \.self) { tag in
                    Text("+" + tag)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                }
            }
            
            Text(suggestion.reason)
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: onApply) {
                Text("应用建议")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CleanupSuggestionCard: View {
    let suggestion: TagCleanupSuggestion
    let onMerge: (String, String) -> Void
    let onDelete: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                switch suggestion.type {
                case .duplicate:
                    Text("🔄 重复标签")
                case .similar:
                    Text("🔗 相似标签")
                case .typo:
                    Text("✏️ 可能拼写错误")
                case .unused:
                    Text("🗑️ 未使用标签")
                case .merge:
                    Text("🔀 建议合并")
                }
                .font(.headline)
                
                Spacer()
                
                Text("影响 \(suggestion.impact) 个梦境")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            TagManagerWrapLayout(spacing: 8) {
                ForEach(suggestion.tags, id: \.id) { tag in
                    Text(tag.name + " (×\(tag.count))")
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                }
            }
            
            Text(suggestion.recommendation)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                if suggestion.type == .duplicate || suggestion.type == .merge || suggestion.type == .similar {
                    Button(action: {
                        if suggestion.tags.count >= 2 {
                            onMerge(suggestion.tags[0].name, suggestion.tags[1].name)
                        }
                    }) {
                        Text("合并")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                if suggestion.type == .unused {
                    Button(role: .destructive) {
                        if let tag = suggestion.tags.first {
                            onDelete(tag.name)
                        }
                    } label: {
                        Text("删除")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RenameTagSheet: View {
    let tag: TagInfo
    let tagManager: DreamTagManagerService
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var newName: String = ""
    @State private var selectedCategory: TagCategory?
    @State private var isProcessing = false
    @State private var resultMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("标签名称")) {
                    TextField("新名称", text: $newName)
                    
                    if let resultMessage = resultMessage {
                        Text(resultMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("分类")) {
                    Picker("分类", selection: $selectedCategory) {
                        Text("无分类").tag(nil as TagCategory?)
                        ForEach(TagCategory.allCases) { category in
                            Text(category.icon + " " + category.rawValue).tag(category as TagCategory?)
                        }
                    }
                }
                
                Section {
                    Button(action: renameTag) {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView()
                            } else {
                                Text("保存")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(newName.isEmpty || isProcessing)
                }
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                newName = tag.name
                selectedCategory = tag.category
            }
        }
    }
    
    private func renameTag() async {
        isProcessing = true
        
        if newName != tag.name {
            let result = await tagManager.renameTag(tag.name, newName: newName)
            resultMessage = result.message
        }
        
        if let category = selectedCategory, category != tag.category {
            await tagManager.categorizeTag(newName.isEmpty ? tag.name : newName, category: category)
        }
        
        isProcessing = false
        onComplete()
    }
}

// MARK: - Helper Views

struct TagManagerWrapLayout: View {
    let spacing: CGFloat
    let content: () -> [View]
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> [View]) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        let items = content()
        return HorizontalFlowLayoutSimple(spacing: spacing, items: items)
    }
}

struct HorizontalFlowLayoutSimple: View {
    let spacing: CGFloat
    let items: [any View]
    
    init(spacing: CGFloat, items: [any View]) {
        self.spacing = spacing
        self.items = items
    }
    
    var body: some View {
        // Simplified flow layout - in production would use GeometryReader
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(items.indices, id: \.self) { index in
                    items[index]
                }
            }
        }
    }
}

struct CategoryDistributionChart: View {
    let stats: TagStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类分布")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(stats.categoryDistribution.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(category.icon)
                                .font(.title3)
                            
                            Text(category.rawValue)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                        .padding()
                        .background(Color(hex: category.color).opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DreamTagManagerView()
        .environmentObject(DreamStore.shared)
}
