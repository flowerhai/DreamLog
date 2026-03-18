//
//  DreamAIAnalysisView.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  UI 界面 - AI 梦境解析结果展示
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import SwiftData

// MARK: - 主视图

struct DreamAIAnalysisView: View {
    
    // MARK: - Properties
    
    let analysis: DreamAnalysis
    let dream: DreamEntry
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLayer: AnalysisLayerType = .surface
    @State private var showingShareSheet = false
    @State private var expandedSections: Set<String> = ["symbols", "insights"]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 置信度指示器
                    confidenceIndicator
                    
                    // 三层级解读切换
                    layerSelector
                    
                    // 选中的解读内容
                    selectedLayerContent
                    
                    // 符号解析
                    symbolsSection
                    
                    // 模式识别
                    if !analysis.patterns.isEmpty {
                        patternsSection
                    }
                    
                    // 趋势预测
                    if let trend = analysis.trendPrediction {
                        trendSection(trend)
                    }
                    
                    // 个性化洞察
                    insightsSection
                    
                    // 行动建议
                    suggestionsSection
                }
                .padding()
            }
            .navigationTitle("AI 梦境解析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    shareButton
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var confidenceIndicator: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.purple)
            
            Text("解析置信度")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(Int(analysis.confidence * 100))%")
                .font(.headline)
                .foregroundColor(confidenceColor)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var confidenceColor: Color {
        if analysis.confidence >= 0.8 {
            return .green
        } else if analysis.confidence >= 0.6 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    private var layerSelector: some View {
        Picker("解读层级", selection: $selectedLayer) {
            Text("表面层").tag(AnalysisLayerType.surface)
            Text("心理层").tag(AnalysisLayerType.psychological)
            Text("精神层").tag(AnalysisLayerType.spiritual)
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    private var selectedLayerContent: some View {
        let content = layerContent(for: selectedLayer)
        
        VStack(alignment: .leading, spacing: 12) {
            Text(content.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            if !content.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(content.keyPoints, id: \.self) { point in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text(point)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var symbolsSection: some View {
        ExpandableSection(
            title: "符号解析",
            icon: "sparkles",
            isExpanded: $expandedSections.contains("symbols"),
            count: analysis.symbols.count
        ) {
            VStack(spacing: 12) {
                ForEach(analysis.symbols) { symbol in
                    SymbolCard(symbol: symbol)
                }
            }
        }
    }
    
    private var patternsSection: some View {
        ExpandableSection(
            title: "模式识别",
            icon: "chart.line.uptrend.xyaxis",
            isExpanded: $expandedSections.contains("patterns"),
            count: analysis.patterns.count
        ) {
            VStack(spacing: 12) {
                ForEach(analysis.patterns) { pattern in
                    PatternCard(pattern: pattern)
                }
            }
        }
    }
    
    private func trendSection(_ trend: TrendPrediction) -> some View {
        ExpandableSection(
            title: "趋势预测",
            icon: "future",
            isExpanded: $expandedSections.contains("trend"),
            count: nil
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(trend.prediction)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    TrendIndicator(label: "清晰度", trend: trend.clarityTrend)
                    Spacer()
                    Text("清醒梦概率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(trend.lucidDreamProbability * 100))%")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                
                Text("预测范围：\(trend.timeRange)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var insightsSection: some View {
        ExpandableSection(
            title: "个性化洞察",
            icon: "lightbulb",
            isExpanded: $expandedSections.contains("insights"),
            count: analysis.insights.count
        ) {
            VStack(spacing: 12) {
                ForEach(analysis.insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
    
    private var suggestionsSection: some View {
        ExpandableSection(
            title: "行动建议",
            icon: "checkmark.circle",
            isExpanded: $expandedSections.contains("suggestions"),
            count: analysis.suggestions.count
        ) {
            VStack(spacing: 12) {
                ForEach(analysis.suggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
        }
    }
    
    private var shareButton: some View {
        Button(action: { showingShareSheet = true }) {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    // MARK: - Helper Methods
    
    private func layerContent(for layerType: AnalysisLayerType) -> AnalysisLayerContent {
        switch layerType {
        case .surface:
            return analysis.surfaceLayer
        case .psychological:
            return analysis.psychologicalLayer
        case .spiritual:
            return analysis.spiritualLayer
        }
    }
}

// MARK: - 符号卡片

struct SymbolCard: View {
    let symbol: DreamSymbolAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbolIcon(for: symbol.category))
                    .foregroundColor(.purple)
                
                Text(symbol.name)
                    .font(.headline)
                
                Spacer()
                
                Text(symbol.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(symbol.surfaceMeaning)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if symbol.recurring {
                HStack {
                    Image(systemName: "repeat")
                        .font(.caption)
                    Text("重复出现")
                        .font(.caption)
                }
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func symbolIcon(for category: SymbolCategory) -> String {
        switch category {
        case .person: return "person.fill"
        case .place: return "house.fill"
        case .object: return "cube.box.fill"
        case .action: return "figure.run"
        case .emotion: return "face.smiling"
        case .nature: return "leaf.fill"
        case .animal: return "pawprint.fill"
        case .other: return "sparkles"
        }
    }
}

// MARK: - 模式卡片

struct PatternCard: View {
    let pattern: DreamPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: patternIcon(for: pattern.type))
                    .foregroundColor(.blue)
                
                Text(patternTypeText(for: pattern.type))
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(pattern.significance * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(pattern.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func patternIcon(for type: PatternType) -> String {
        switch type {
        case .recurringSymbol: return "repeat"
        case .emotionPattern: return "face.smiling"
        case .themePattern: return "text.book.closed"
        case .timePattern: return "clock"
        case .lucidPattern: return "eye.fill"
        }
    }
    
    private func patternTypeText(for type: PatternType) -> String {
        switch type {
        case .recurringSymbol: return "重复符号"
        case .emotionPattern: return "情绪模式"
        case .themePattern: return "主题模式"
        case .timePattern: return "时间模式"
        case .lucidPattern: return "清醒梦模式"
        }
    }
}

// MARK: - 洞察卡片

struct InsightCard: View {
    let insight: DreamInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insightIcon(for: insight.type))
                    .foregroundColor(insightColor(for: insight.category))
                
                Text(insight.title)
                    .font(.headline)
                
                Spacer()
                
                Text(insight.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(for: insight.priority).opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(insight.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "arrow.right.circle")
                    .font(.caption)
                Text(insight.actionText)
                    .font(.caption)
            }
            .foregroundColor(.purple)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func insightIcon(for type: InsightType) -> String {
        switch type {
        case .symbolDiscovery: return "sparkles"
        case .patternRecognition: return "chart.line.uptrend.xyaxis"
        case .trendAwareness: return "future"
        case .lucidOpportunity: return "eye.fill"
        case .emotionalInsight: return "heart.fill"
        }
    }
    
    private func insightColor(for category: InsightCategory) -> Color {
        switch category {
        case .awareness: return .blue
        case .growth: return .green
        case .healing: return .pink
        case .creativity: return .orange
        }
    }
    
    private func priorityColor(for priority: InsightPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - 建议卡片

struct SuggestionCard: View {
    let suggestion: ActionSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestionIcon(for: suggestion.category))
                    .foregroundColor(.green)
                
                Text(suggestion.title)
                    .font(.headline)
                
                Spacer()
                
                Text(suggestion.estimatedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(suggestion.actionTypeText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func suggestionIcon(for category: SuggestionCategory) -> String {
        switch category {
        case .recording: return "pencil.and.outline"
        case .meditation: return "figure.mind.and.body"
        case .creative: return "paintpalette"
        case .sleep: return "moon.fill"
        case .selfExploration: return "book.fill"
        case .lifestyle: return "heart.fill"
        }
    }
    
    private var suggestionActionTypeText: String {
        switch suggestion.actionType {
        case .journaling: return "书写练习"
        case .meditation: return "冥想练习"
        case .creative: return "创意表达"
        case .reflection: return "深度反思"
        case .lifestyle: return "生活方式"
        }
    }
}

// MARK: - 可展开区块

struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let count: Int?
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.purple)
                    
                    Text(title)
                        .font(.headline)
                    
                    if let count = count {
                        Text("(\(count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 趋势指示器

struct TrendIndicator: View {
    let label: String
    let trend: TrendDirection
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Image(systemName: trendIcon)
                .foregroundColor(trendColor)
        }
    }
    
    private var trendIcon: String {
        switch trend {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    DreamAIAnalysisView(
        analysis: DreamAnalysis(
            dreamId: UUID(),
            surfaceLayer: AnalysisLayerContent(
                title: "表面层解读",
                content: "这是一个关于飞行的梦境...",
                keyPoints: ["飞行：代表自由和解放"],
                confidence: 0.9
            ),
            psychologicalLayer: AnalysisLayerContent(
                title: "心理层解读",
                content: "从心理学角度...",
                keyPoints: ["渴望突破限制"],
                confidence: 0.75
            ),
            spiritualLayer: AnalysisLayerContent(
                title: "精神层解读",
                content: "从精神成长角度...",
                keyPoints: ["灵魂的成长"],
                confidence: 0.65
            ),
            symbols: [
                DreamSymbolAnalysis(
                    symbol: "fly",
                    name: "飞行",
                    category: .action,
                    surfaceMeaning: "在空中移动",
                    psychologicalMeaning: "渴望自由",
                    spiritualMeaning: "精神提升",
                    emotionalTone: "joy",
                    prominence: 0.8,
                    recurring: true
                )
            ],
            patterns: [
                DreamPattern(
                    type: .recurringSymbol,
                    description: "飞行主题反复出现",
                    significance: 0.7,
                    relatedDreams: [],
                    firstOccurrence: nil,
                    lastOccurrence: nil,
                    metadata: [:]
                )
            ],
            trendPrediction: TrendPrediction(
                prediction: "梦境清晰度正在提升",
                clarityTrend: .increasing,
                emotionTrend: "积极情绪增加",
                lucidDreamProbability: 0.65,
                timeRange: "未来 7 天",
                confidence: 0.6
            ),
            insights: [
                DreamInsight(
                    type: .lucidOpportunity,
                    title: "清醒梦机会",
                    content: "这是练习清醒梦的好时机",
                    category: .growth,
                    priority: .high,
                    actionText: "尝试清醒梦技巧"
                )
            ],
            suggestions: [
                ActionSuggestion(
                    category: .meditation,
                    title: "冥想练习",
                    description: "尝试 10 分钟冥想",
                    priority: .high,
                    estimatedTime: "10 分钟",
                    actionType: .meditation
                )
            ]
        ),
        dream: DreamEntry(
            title: "飞行的梦",
            content: "我在天空中自由飞翔...",
            date: Date(),
            emotions: [.joy],
            tags: ["飞行", "自由"],
            clarity: 4,
            intensity: 4
        )
    )
}
