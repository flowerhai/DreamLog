//
//  DreamInsightsDashboardView.swift
//  DreamLog - Phase 28: AI 梦境解析增强与智能洞察 2.0
//
//  梦境洞察仪表板 UI
//

import SwiftUI

struct DreamInsightsDashboardView: View {
    @ObservedObject var analysisService = DreamAIAnalysisService.shared
    @State private var selectedDepth: AnalysisDepth = .deep
    @State private var showConfigSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 头部卡片
                    headerCard
                    
                    // 心理健康概览
                    if let result = analysisService.lastAnalysisResult {
                        mentalHealthOverview(metrics: result.mentalHealthMetrics)
                        
                        // 梦境类型
                        dreamTypeCard(dreamType: result.dreamType)
                        
                        // 洞察列表
                        insightsSection(insights: result.insights)
                        
                        // 建议列表
                        suggestionsSection(suggestions: result.suggestions)
                        
                        // 预警列表
                        if !result.warnings.isEmpty {
                            warningsSection(warnings: result.warnings)
                        }
                        
                        // 符号解析
                        symbolsSection(symbols: result.keySymbols)
                        
                        // 原型分析
                        if !result.identifiedArchetypes.isEmpty {
                            archetypesSection(archetypes: result.identifiedArchetypes)
                        }
                    } else {
                        emptyStateView
                    }
                    
                    // 分析配置
                    configSection
                }
                .padding()
            }
            .navigationTitle("梦境洞察")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showConfigSheet = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showConfigSheet) {
                AnalysisConfigView()
            }
        }
    }
    
    // MARK: - 头部卡片
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.purple)
                Text("AI 梦境解析")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if analysisService.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if analysisService.isAnalyzing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("正在分析...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProgressView(value: analysisService.currentProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                }
            } else if let result = analysisService.lastAnalysisResult {
                HStack {
                    Label("置信度", systemImage: "checkmark.seal")
                        .font(.caption)
                    Text("\(Int(result.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Label("耗时", systemImage: "clock")
                        .font(.caption)
                    Text("\(result.processingTimeMs)ms")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
        )
    }
    
    // MARK: - 心理健康概览
    
    private func mentalHealthOverview(metrics: MentalHealthMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("心理健康概览")
                .font(.headline)
            
            // 综合评分
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("综合评分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(metrics.compositeDescription)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.red, .yellow, .green]),
                            center: .center
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("\(metrics.compositeScore)")
                            .font(.title3)
                            .fontWeight(.bold)
                    )
            }
            
            // 各项指标
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(title: "压力", value: metrics.stressLevel, description: metrics.stressLevelDescription, color: .orange)
                MetricCard(title: "焦虑", value: metrics.anxietyIndex, description: metrics.anxietyIndexDescription, color: .red)
                MetricCard(title: "情绪", value: metrics.moodScore, description: "情绪评分", color: .blue)
                MetricCard(title: "睡眠", value: metrics.sleepQualityScore, description: "睡眠质量", color: .indigo)
                MetricCard(title: "稳定", value: metrics.emotionalStability, description: "情绪稳定", color: .green)
                MetricCard(title: "健康", value: metrics.overallWellbeing, description: metrics.overallWellbeingDescription, color: .purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - 梦境类型卡片
    
    private func dreamTypeCard(dreamType: DreamType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(dreamType.icon)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(dreamType.displayName)
                        .font(.headline)
                    Text(dreamType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            
            // 常见原因
            if !dreamType.commonCauses.isEmpty {
                Text("常见原因")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                ForEach(dreamType.commonCauses, id: \.self) { cause in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Text(cause)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.05))
        )
    }
    
    // MARK: - 洞察部分
    
    private func insightsSection(insights: [DreamInsight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智能洞察")
                .font(.headline)
            
            ForEach(insights) { insight in
                InsightsDash2InsightCard(insight: insight)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - 建议部分
    
    private func suggestionsSection(suggestions: [DreamSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("个性化建议")
                .font(.headline)
            
            ForEach(suggestions) { suggestion in
                SuggestionCard(suggestion: suggestion)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - 预警部分
    
    private func warningsSection(warnings: [DreamWarning]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("重要提醒")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            ForEach(warnings) { warning in
                WarningCard(warning: warning)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - 符号部分
    
    private func symbolsSection(symbols: [DreamSymbol]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关键符号")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(symbols) { symbol in
                    SymbolCard(symbol: symbol)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - 原型部分
    
    private func archetypesSection(archetypes: [JungianArchetype]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("荣格原型")
                .font(.headline)
            
            ForEach(archetypes, id: \.rawValue) { archetype in
                ArchetypeCard(archetype: archetype)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.05))
        )
    }
    
    // MARK: - 配置部分
    
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解析配置")
                .font(.headline)
            
            Picker("解析深度", selection: $selectedDepth) {
                ForEach(AnalysisDepth.allCases, id: \.self) { depth in
                    Text(depth.displayName).tag(depth)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Text("预计时间:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(selectedDepth.estimatedTime)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - 空状态
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("暂无解析结果")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("选择一个梦境开始 AI 深度解析")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - 小组件

struct MetricCard: View {
    let title: String
    let value: Int
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct InsightsDash2InsightCard: View {
    let insight: DreamInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.type.icon)
                    .font(.title2)
                Text(insight.title)
                    .font(.headline)
                Spacer()
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.2))
                    )
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !insight.evidence.isEmpty {
                Text("依据：\(insight.evidence.prefix(2).joined(separator: "、"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct SuggestionCard: View {
    let suggestion: DreamSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.type.displayName)
                    .font(.headline)
                Spacer()
                Text(suggestion.priority.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorForPriority(suggestion.priority))
                    )
            }
            
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !suggestion.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(suggestion.actionItems, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func colorForPriority(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .green.opacity(0.3)
        case .medium: return .yellow.opacity(0.3)
        case .high: return .orange.opacity(0.3)
        case .urgent: return .red.opacity(0.3)
        }
    }
}

struct WarningCard: View {
    let warning: DreamWarning
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(warning.title)
                    .font(.headline)
                Spacer()
                Text(warning.severity.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorForSeverity(warning.severity))
                    )
            }
            
            Text(warning.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("建议：\(warning.recommendedAction)")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private func colorForSeverity(_ severity: Severity) -> Color {
        switch severity {
        case .low: return .green.opacity(0.3)
        case .moderate: return .yellow.opacity(0.3)
        case .high: return .orange.opacity(0.3)
        case .severe: return .red.opacity(0.3)
        }
    }
}

struct SymbolCard: View {
    let symbol: DreamSymbol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(symbol.category.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if symbol.frequency > 1 {
                    Text("出现\(symbol.frequency)次")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Text(symbol.name)
                .font(.headline)
            
            if let meaning = symbol.meanings.first {
                Text(meaning.interpretation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ArchetypeCard: View {
    let archetype: JungianArchetype
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(archetype.displayName)
                    .font(.headline)
                Spacer()
            }
            
            Text(archetype.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if !archetype.dreamSymbols.isEmpty {
                Text("相关符号：\(archetype.dreamSymbols.prefix(5).joined(separator: "、"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
}

struct AnalysisConfigView: View {
    @Environment(\.dismiss) var dismiss
    @State private var includeArchetypes = true
    @State private var includeMentalHealth = true
    @State private var includeSuggestions = true
    @State private var includeWarnings = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("解析选项")) {
                    Toggle("包含荣格原型分析", isOn: $includeArchetypes)
                    Toggle("包含心理健康评估", isOn: $includeMentalHealth)
                    Toggle("包含个性化建议", isOn: $includeSuggestions)
                    Toggle("包含预警提示", isOn: $includeWarnings)
                }
                
                Section(header: Text("说明")) {
                    Text("启用更多分析选项会增加解析时间，但能提供更全面的洞察。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("解析配置")
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

// MARK: - 预览

#Preview {
    DreamInsightsDashboardView()
}
