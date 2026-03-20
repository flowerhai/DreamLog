//
//  DreamInsightsDashboardView.swift
//  DreamLog
//
//  Phase 55 - AI 梦境推荐与智能洞察
//  洞察仪表板界面
//

import SwiftUI
import SwiftData

struct DreamInsightsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamInsight.createdAt, order: .reverse) private var insights: [DreamInsight]
    
    @State private var selectedTimeRange: TimeRange = .last30Days
    @State private var showingImportantOnly = false
    @State private var refreshTrigger = false
    
    @State private var stats: DashboardStats?
    
    private var filteredInsights: [DreamInsight] {
        var result = insights.filter { $0.timeRange == selectedTimeRange }
        if showingImportantOnly {
            result = result.filter { $0.isImportant }
        }
        return result
    }
    
    private var importantInsights: [DreamInsight] {
        insights.filter { $0.isImportant && !$0.isDismissed }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计概览
                    statsSection
                    
                    // 时间范围选择器
                    timeRangeSelector
                    
                    // 重要洞察
                    if !importantInsights.isEmpty {
                        importantInsightsSection
                    }
                    
                    // 所有洞察
                    allInsightsSection
                    
                    // 空状态
                    if filteredInsights.isEmpty && importantInsights.isEmpty {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("梦境洞察")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingImportantOnly.toggle() }) {
                        Image(systemName: showingImportantOnly ? "star.fill" : "star")
                            .foregroundColor(showingImportantOnly ? .yellow : .secondary)
                    }
                    .accessibilityLabel(showingImportantOnly ? "已显示重要洞察" : "仅显示重要洞察")
                    .accessibilityHint(showingImportantOnly ? "双击显示所有洞察" : "双击仅显示重要洞察")
                }
            }
            .refreshable {
                await refreshInsights()
            }
            .task {
                await loadStats()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("梦境洞察仪表板")
        .accessibilityHint("查看 AI 生成的梦境洞察和统计分析")
    }
    
    // MARK: - 统计概览
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            Text("洞察概览")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                InsightsStatCard(
                    title: "总洞察",
                    value: "\(insights.count)",
                    icon: "lightbulb.fill",
                    color: .yellow
                )
                
                InsightsStatCard(
                    title: "重要洞察",
                    value: "\(importantInsights.count)",
                    icon: "star.fill",
                    color: .orange
                )
                
                InsightsStatCard(
                    title: "模式识别",
                    value: "\(insights.filter { $0.type == .pattern }.count)",
                    icon: "repeat",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 时间范围选择器
    
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    TimeRangeChip(
                        title: range.displayName,
                        isSelected: selectedTimeRange == range,
                        action: { selectedTimeRange = range }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 重要洞察
    
    private var importantInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("重要洞察", systemImage: "star.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            ForEach(importantInsights.prefix(3), id: \.id) { insight in
                InsightsDashInsightCard(insight: insight, isImportant: true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 所有洞察
    
    private var allInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("所有洞察", systemImage: "list.bullet")
                .font(.headline)
            
            if filteredInsights.isEmpty {
                Text("暂无洞察")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(filteredInsights, id: \.id) { insight in
                    InsightsDashInsightCard(insight: insight, isImportant: insight.isImportant)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 空状态
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("暂无洞察数据")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("继续记录梦境，积累足够数据后自动生成洞察")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Methods
    
    private func loadStats() async {
        // 加载统计数据
        await refreshInsights()
    }
    
    private func refreshInsights() async {
        refreshTrigger.toggle()
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// MARK: - 洞察卡片

struct InsightsDashInsightCard: View {
    let insight: DreamInsight
    let isImportant: Bool
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Image(systemName: insight.type.icon)
                    .font(.title2)
                    .foregroundColor(typeColor)
                
                VStack(alignment: .leading) {
                    Text(insight.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(insight.title)
                        .font(.headline)
                }
                
                Spacer()
                
                if isImportant {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                }
                
                // 置信度
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(8)
            }
            
            // 描述
            Text(insight.description)
                .font(.body)
                .foregroundColor(.primary)
            
            // 详细信息
            if isExpanded && !insight.details.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text(insight.details)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 数据点
                    if !insight.dataPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(insight.dataPoints.keys.sorted(), id: \.self) { key in
                                HStack {
                                    Text("\(key):")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                    
                                    Text("\(insight.dataPoints[key]?.value ?? "N/A")")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .transition(.opacity)
            }
            
            // 展开按钮
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Spacer()
                    Text(isExpanded ? "收起" : "查看更多")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var typeColor: Color {
        switch insight.type {
        case .pattern: return .blue
        case .trend: return .green
        case .correlation: return .purple
        case .prediction: return .orange
        case .anomaly: return .red
        case .achievement: return .yellow
        }
    }
    
    private var confidenceColor: Color {
        if insight.confidence >= 0.7 {
            return .green
        } else if insight.confidence >= 0.4 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - 统计卡片

struct InsightsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 时间范围芯片

struct TimeRangeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - 仪表板统计

struct DashboardStats: Codable {
    var totalInsights: Int
    var importantCount: Int
    var patternCount: Int
    var trendCount: Int
    var correlationCount: Int
    var achievementCount: Int
    var averageConfidence: Double
    
    init(
        totalInsights: Int = 0,
        importantCount: Int = 0,
        patternCount: Int = 0,
        trendCount: Int = 0,
        correlationCount: Int = 0,
        achievementCount: Int = 0,
        averageConfidence: Double = 0
    ) {
        self.totalInsights = totalInsights
        self.importantCount = importantCount
        self.patternCount = patternCount
        self.trendCount = trendCount
        self.correlationCount = correlationCount
        self.achievementCount = achievementCount
        self.averageConfidence = averageConfidence
    }
}

// MARK: - Preview

#Preview {
    DreamInsightsDashboardView()
        .modelContainer(for: [DreamInsight.self, DreamRecommendation.self, DreamSuggestion.self], inMemory: true)
}
