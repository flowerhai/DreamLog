//
//  DreamPatternPredictionView.swift
//  DreamLog - Dream Pattern Prediction UI
//
//  Created by DreamLog AI on 2026/3/17.
//  Phase 55: Dream Pattern Prediction & Forecasting
//

import SwiftUI
import SwiftData

// MARK: - Main View

struct DreamPatternPredictionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var response: PredictionResponse?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTimeRange: PredictionTimeRange = .next7days
    @State private var selectedPredictionTypes: Set<PredictionType> = [.theme, .emotion, .clarity, .lucid]
    
    private var predictionService: DreamPatternPredictionService {
        DreamPatternPredictionService(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    loadingView
                } else if let response = response {
                    predictionContentView(response: response)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("梦境预测 🔮")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: generatePrediction) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在分析梦境数据...")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("AI 正在生成个性化预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "crystal.ball")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            VStack(spacing: 12) {
                Text("梦境预测")
                    .font(.title)
                    .fontWeight(.bold)
                Text("基于你的历史记录，AI 将预测未来的梦境模式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                timeRangePicker
                
                predictionTypeSelector
                
                Button(action: generatePrediction) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("生成预测")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Prediction Content View
    
    private func predictionContentView(response: PredictionResponse) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Data Quality Badge
                dataQualityBadge(response: response)
                
                // Statistics Overview
                statisticsCards(statistics: response.statistics)
                
                // Predictions
                predictionsSection(predictions: response.prediction.predictions)
                
                // Insights
                insightsSection(insights: response.prediction.insights)
                
                // Suggestions
                suggestionsSection(suggestions: response.prediction.suggestions)
                
                // Configuration Button
                Button(action: { /* Show configuration */ }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("调整预测设置")
                    }
                    .font(.headline)
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 2)
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // MARK: - Data Quality Badge
    
    private func dataQualityBadge(response: PredictionResponse) -> some View {
        HStack {
            Image(systemName: response.dataQuality == .excellent ? "checkmark.seal.fill" : "info.circle.fill")
                .foregroundColor(dataQualityColor(response.dataQuality))
            VStack(alignment: .leading) {
                Text("数据质量：\(response.dataQuality.displayName)")
                    .font(.headline)
                Text(response.dataQuality.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
    
    private func dataQualityColor(_ quality: DataQualityScore) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .yellow
        case .insufficient: return .red
        }
    }
    
    // MARK: - Statistics Cards
    
    private func statisticsCards(statistics: PatternStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("梦境统计概览")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PatternPredStatCard(
                    title: "总梦境数",
                    value: "\(statistics.totalDreams)",
                    icon: "📝",
                    color: .blue
                )
                
                PatternPredStatCard(
                    title: "平均清晰度",
                    value: String(format: "%.1f", statistics.averageClarity),
                    icon: "✨",
                    color: .purple
                )
                
                PatternPredStatCard(
                    title: "清醒梦比例",
                    value: String(format: "%.1f%%", statistics.lucidDreamPercentage),
                    icon: "🌟",
                    color: .orange
                )
                
                PatternPredStatCard(
                    title: "连续记录",
                    value: "\(statistics.recordingStreak) 天",
                    icon: "🔥",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Predictions Section
    
    private func predictionsSection(predictions: [PredictionData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("未来预测")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(predictions.prefix(7)) { prediction in
                PredictionCard(prediction: prediction)
            }
        }
    }
    
    // MARK: - Insights Section
    
    private func insightsSection(insights: [PredictionInsight]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智能洞察")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(insights) { insight in
                PatternPredInsightCard(insight: insight)
            }
            
            if insights.isEmpty {
                Text("暂无洞察，继续记录梦境以获取个性化洞察")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Suggestions Section
    
    private func suggestionsSection(suggestions: [PredictionSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("个性化建议")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(suggestions) { suggestion in
                SuggestionCard(suggestion: suggestion)
            }
            
            if suggestions.isEmpty {
                Text("暂无建议，继续记录梦境以获取个性化建议")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Configuration Views
    
    private var timeRangePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("预测时间范围")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("时间范围", selection: $selectedTimeRange) {
                ForEach(PredictionTimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var predictionTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("预测类型")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(PredictionType.allCases, id: \.self) { type in
                    Button(action: {
                        if selectedPredictionTypes.contains(type) {
                            selectedPredictionTypes.remove(type)
                        } else {
                            selectedPredictionTypes.insert(type)
                        }
                    }) {
                        HStack {
                            Text(type.icon)
                            Text(type.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedPredictionTypes.contains(type) ?
                                Color.purple.opacity(0.2) : Color(.systemGray6)
                        )
                        .cornerRadius(8)
                    }
                    .foregroundColor(selectedPredictionTypes.contains(type) ? .purple : .primary)
                }
            }
        }
    }
    
    // MARK: - Action
    
    private func generatePrediction() {
        isLoading = true
        showError = false
        
        let request = PredictionRequest(
            timeRange: selectedTimeRange,
            predictionTypes: Array(selectedPredictionTypes),
            includeInsights: true,
            includeSuggestions: true,
            minConfidence: 0.3
        )
        
        Task {
            do {
                let result = try await service.generatePrediction(request: request)
                await MainActor.run {
                    response = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Stat Card Component

struct PatternPredStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.2), radius: 5)
    }
}

// MARK: - Prediction Card Component

struct PredictionCard: View {
    let prediction: PredictionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(prediction.type.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(prediction.type.displayName)
                        .font(.headline)
                    Text(formatDate(prediction.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                confidenceBadge(confidence: prediction.confidence)
            }
            
            Text(prediction.value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
            
            Text(prediction.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !prediction.factors.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("影响因素")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(prediction.factors) { factor in
                        HStack {
                            Circle()
                                .fill(influenceColor(factor.influence))
                                .frame(width: 8, height: 8)
                            Text(factor.name)
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.0f%%", factor.influence * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd EEE"
        return formatter.string(from: date)
    }
    
    private func confidenceBadge(confidence: Double) -> some View {
        let color: Color
        let text: String
        
        if confidence >= 0.7 {
            color = .green
            text = "高"
        } else if confidence >= 0.5 {
            color = .orange
            text = "中"
        } else {
            color = .red
            text = "低"
        }
        
        return Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
    
    private func influenceColor(_ influence: Double) -> Color {
        if influence > 0.4 {
            return .red
        } else if influence > 0.2 {
            return .orange
        } else {
            return .gray
        }
    }
}

// MARK: - Insight Card Component

struct PatternPredInsightCard: View {
    let insight: PredictionInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(insight.type.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(insight.title)
                        .font(.headline)
                    Text(insight.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                priorityBadge(priority: insight.priority)
            }
            
            Text(insight.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !insight.relatedTags.isEmpty {
                HStack {
                    ForEach(insight.relatedTags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func priorityBadge(priority: PriorityLevel) -> some View {
        let color: Color
        switch priority {
        case .high: color = .red
        case .medium: color = .orange
        case .low: color = .green
        }
        
        return Text(priority.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Suggestion Card Component

struct SuggestionCard: View {
    let suggestion: PredictionSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(suggestion.type.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(suggestion.title)
                        .font(.headline)
                    Text(suggestion.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                difficultyBadge(difficulty: suggestion.difficulty)
            }
            
            Text(suggestion.action)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(suggestion.expectedBenefit, systemImage: "checkmark.star")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Label(suggestion.estimatedTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func difficultyBadge(difficulty: DifficultyLevel) -> some View {
        let color: Color
        switch difficulty {
        case .easy: color = .green
        case .medium: color = .orange
        case .hard: color = .red
        }
        
        return Text(difficulty.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    DreamPatternPredictionView()
        .modelContainer(for: Dream.self, inMemory: true)
}
