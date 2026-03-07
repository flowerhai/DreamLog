//
//  AdvancedSearchView.swift
//  DreamLog
//
//  高级搜索和过滤视图
//

import SwiftUI

struct AdvancedSearchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    
    @State private var searchText: String = ""
    @State private var selectedEmotions: [Emotion] = []
    @State private var selectedTags: [String] = []
    @State private var dateRange: DateRange = .all
    @State private var clarityRange: ClosedRange<Int> = 1...5
    @State private var intensityRange: ClosedRange<Int> = 1...5
    @State private var includeLucidOnly: Bool = false
    @State private var sortBy: SortOption = .date
    
    enum DateRange: String, CaseIterable {
        case all = "全部时间"
        case today = "今天"
        case week = "本周"
        case month = "本月"
        case year = "今年"
        case custom = "自定义"
    }
    
    enum SortOption: String, CaseIterable {
        case date = "日期"
        case clarity = "清晰度"
        case intensity = "强度"
        case title = "标题"
    }
    
    var filteredDreams: [Dream] {
        var results = dreamStore.dreams
        
        // 文本搜索
        if !searchText.isEmpty {
            results = results.filter { dream in
                dream.title.localizedCaseInsensitiveContains(searchText) ||
                dream.content.localizedCaseInsensitiveContains(searchText) ||
                dream.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // 情绪过滤
        if !selectedEmotions.isEmpty {
            results = results.filter { dream in
                !dream.emotions.filter { selectedEmotions.contains($0) }.isEmpty
            }
        }
        
        // 标签过滤
        if !selectedTags.isEmpty {
            results = results.filter { dream in
                !dream.tags.filter { selectedTags.contains($0) }.isEmpty
            }
        }
        
        // 时间范围过滤
        results = filterByDateRange(results)
        
        // 清晰度过滤
        results = results.filter { dream in
            clarityRange.contains(dream.clarity)
        }
        
        // 强度过滤
        results = results.filter { dream in
            intensityRange.contains(dream.intensity)
        }
        
        // 清醒梦过滤
        if includeLucidOnly {
            results = results.filter { $0.isLucid }
        }
        
        // 排序
        results.sort { dream1, dream2 in
            switch sortBy {
            case .date:
                return dream1.date > dream2.date
            case .clarity:
                return dream1.clarity > dream2.clarity
            case .intensity:
                return dream1.intensity > dream2.intensity
            case .title:
                return dream1.title < dream2.title
            }
        }
        
        return results
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索结果
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredDreams, id: \.id) { dream in
                            NavigationLink(destination: DreamDetailView(dream: dream)) {
                                DreamCard(dream: dream)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if filteredDreams.isEmpty {
                            EmptyStateView()
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // 过滤选项
                FilterOptionsView(
                    searchText: $searchText,
                    selectedEmotions: $selectedEmotions,
                    selectedTags: $selectedTags,
                    dateRange: $dateRange,
                    clarityRange: $clarityRange,
                    intensityRange: $intensityRange,
                    includeLucidOnly: $includeLucidOnly,
                    sortBy: $sortBy
                )
                .padding()
                .background(Color.white.opacity(0.05))
            }
            .navigationTitle("高级搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 按日期范围过滤
    private func filterByDateRange(_ dreams: [Dream]) -> [Dream] {
        let now = Date()
        let calendar = Calendar.current
        
        switch dateRange {
        case .all:
            return dreams
        case .today:
            return dreams.filter { calendar.isDateInToday($0.date) }
        case .week:
            return dreams.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .month:
            return dreams.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .year:
            return dreams.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
        case .custom:
            // 自定义范围可以添加日期选择器
            return dreams
        }
    }
}

// MARK: - 过滤选项视图
struct FilterOptionsView: View {
    @Binding var searchText: String
    @Binding var selectedEmotions: [Emotion]
    @Binding var selectedTags: [String]
    @Binding var dateRange: AdvancedSearchView.DateRange
    @Binding var clarityRange: ClosedRange<Int>
    @Binding var intensityRange: ClosedRange<Int>
    @Binding var includeLucidOnly: Bool
    @Binding var sortBy: AdvancedSearchView.SortOption
    
    @EnvironmentObject var dreamStore: DreamStore
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .frame(width: 150)
                
                // 日期范围
                Menu {
                    ForEach(AdvancedSearchView.DateRange.allCases, id: \.self) { range in
                        Button(action: { dateRange = range }) {
                            HStack {
                                Text(range.rawValue)
                                if dateRange == range {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label(dateRange.rawValue, systemImage: "calendar")
                        .foregroundColor(.white)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 100)
                
                // 排序方式
                Menu {
                    ForEach(AdvancedSearchView.SortOption.allCases, id: \.self) { option in
                        Button(action: { sortBy = option }) {
                            HStack {
                                Text(option.rawValue)
                                if sortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label(sortBy.rawValue, systemImage: "arrow.up.arrow.down")
                        .foregroundColor(.white)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 80)
                
                // 情绪过滤
                HStack(spacing: 4) {
                    ForEach(Array(Emotion.allCases.prefix(5)), id: \.self) { emotion in
                        Button(action: {
                            if selectedEmotions.contains(emotion) {
                                selectedEmotions.removeAll { $0 == emotion }
                            } else {
                                selectedEmotions.append(emotion)
                            }
                        }) {
                            Text(emotion.icon)
                                .font(.system(size: 20))
                        }
                    }
                }
                
                // 清醒梦过滤
                Toggle("清醒梦", isOn: $includeLucidOnly)
                    .toggleStyle(.switch)
                    .tint(.yellow)
                
                // 重置按钮
                Button(action: resetFilters) {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private func resetFilters() {
        searchText = ""
        selectedEmotions = []
        selectedTags = []
        dateRange = .all
        clarityRange = 1...5
        intensityRange = 1...5
        includeLucidOnly = false
        sortBy = .date
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("没有找到匹配的梦境")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("尝试调整搜索条件或过滤器")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}

#Preview {
    AdvancedSearchView()
        .environmentObject(DreamStore())
}
