//
//  DreamSearchView.swift
//  DreamLog
//
//  梦境搜索和过滤视图
//

import SwiftUI

struct DreamSearchView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var selectedFilter: FilterType = .all
    @State private var selectedEmotion: Emotion?
    @State private var dateRange: DateRange = .all
    
    enum FilterType: String, CaseIterable {
        case all = "全部"
        case lucid = "清醒梦"
        case recent = "最近 7 天"
        case highClarity = "高清晰度"
    }
    
    enum DateRange: String, CaseIterable {
        case all = "全部时间"
        case week = "最近一周"
        case month = "最近一月"
        case year = "最近一年"
    }
    
    var filteredDreams: [Dream] {
        var result = dreamStore.dreams
        
        // 搜索过滤
        if !searchText.isEmpty {
            result = result.filter { dream in
                dream.title.localizedCaseInsensitiveContains(searchText) ||
                dream.content.localizedCaseInsensitiveContains(searchText) ||
                dream.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // 类型过滤
        switch selectedFilter {
        case .lucid:
            result = result.filter { $0.isLucid }
        case .recent:
            let weekAgo = Date().daysFromNow(-7)
            result = result.filter { $0.date >= weekAgo }
        case .highClarity:
            result = result.filter { $0.clarity >= 4 }
        case .all:
            break
        }
        
        // 情绪过滤
        if let emotion = selectedEmotion {
            result = result.filter { $0.emotions.contains(emotion) }
        }
        
        // 时间范围过滤
        switch dateRange {
        case .week:
            let weekAgo = Date().daysFromNow(-7)
            result = result.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Date().daysFromNow(-30)
            result = result.filter { $0.date >= monthAgo }
        case .year:
            let yearAgo = Date().daysFromNow(-365)
            result = result.filter { $0.date >= yearAgo }
        case .all:
            break
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding()
                
                // 过滤器
                FilterBar(
                    selectedFilter: $selectedFilter,
                    selectedEmotion: $selectedEmotion,
                    dateRange: $dateRange
                )
                .padding(.horizontal)
                
                Divider()
                
                // 结果列表
                if filteredDreams.isEmpty {
                    EmptyStateView(
                        icon: "🔍",
                        title: "没有找到梦境",
                        subtitle: "尝试其他搜索词或过滤器"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredDreams, id: \.id) { dream in
                                DreamSearchResultCard(dream: dream)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("搜索梦境")
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
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索梦境内容、标签...", text: $text)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 过滤器栏
struct FilterBar: View {
    @Binding var selectedFilter: DreamSearchView.FilterType
    @Binding var selectedEmotion: Emotion?
    @Binding var dateRange: DreamSearchView.DateRange
    
    var body: some View {
        VStack(spacing: 12) {
            // 类型过滤
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DreamSearchView.FilterType.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            
            // 情绪过滤
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { selectedEmotion = nil }) {
                        Text("全部情绪")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedEmotion == nil
                                    ? Color.accentColor
                                    : Color.white.opacity(0.1)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    
                    ForEach(Emotion.allCases, id: \.self) { emotion in
                        Button(action: {
                            selectedEmotion = selectedEmotion == emotion ? nil : emotion
                        }) {
                            HStack(spacing: 4) {
                                Text(emotion.icon)
                                Text(emotion.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedEmotion == emotion
                                    ? Color(hex: emotion.color)
                                    : Color.white.opacity(0.1)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                }
            }
            
            // 时间范围
            Picker("时间范围", selection: $dateRange) {
                ForEach(DreamSearchView.DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 过滤器芯片
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color.accentColor
                        : Color.white.opacity(0.1)
                )
                .foregroundColor(.white)
                .cornerRadius(20)
        }
    }
}

// MARK: - 搜索结果卡片
struct DreamSearchResultCard: View {
    let dream: Dream
    
    var highlightedText: String {
        String(dream.content.prefix(150))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dream.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if dream.isLucid {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(dream.date.formatted(.dateTime.month().day().hour().minute()))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(highlightedText)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            HStack(spacing: 8) {
                ForEach(dream.tags.prefix(3), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack {
                ForEach(dream.emotions.prefix(3), id: \.self) { emotion in
                    Text(emotion.icon)
                        .font(.caption)
                }
                
                Spacer()
                
                Text("清晰度：\(String(repeating: "⭐", count: dream.clarity))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    DreamSearchView()
        .environmentObject(DreamStore())
}
