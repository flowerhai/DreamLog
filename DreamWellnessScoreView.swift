//
//  DreamWellnessScoreView.swift
//  DreamLog
//
//  Phase 100: 梦境健康评分与预测引擎
//  健康评分主界面
//

import SwiftUI
import SwiftData

// MARK: - 健康评分主视图

struct DreamWellnessScoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamWellnessScore.date, order: .reverse) private var scores: [DreamWellnessScore]
    @Query(sort: \DreamPrediction.date, order: .reverse) private var predictions: [DreamPrediction]
    
    @State private var selectedPeriod = 7
    @State private var showingDetails = false
    @State private var selectedDimension: ScoreDimension?
    
    private let periods = [7, 14, 30]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 头部评分卡片
                    scoreHeaderCard
                    
                    // 维度详情
                    dimensionCards
                    
                    // 趋势图表
                    trendChartCard
                    
                    // 预测洞察
                    predictionCards
                    
                    // 建议列表
                    recommendationsCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("梦境健康")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            try await DreamWellnessScoreService(modelContext: modelContext)
                                .calculateTodayScore()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
    
    // MARK: - 头部评分卡片
    
    private var scoreHeaderCard: some View {
        VStack(spacing: 16) {
            if let todayScore = scores.first {
                // 评分等级徽章
                HStack {
                    Text(todayScore.scoreLevel.emoji)
                        .font(.system(size: 40))
                    VStack(alignment: .leading) {
                        Text(todayScore.scoreLevel.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(todayScore.scoreLevel.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(todayScore.trend.emoji)
                        .font(.title2)
                }
                
                Divider()
                
                // 综合评分
                HStack(spacing: 30) {
                    // 环形进度条
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: todayScore.overallScore / 100)
                            .stroke(
                                scoreColor(score: todayScore.overallScore),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: todayScore.overallScore)
                        
                        VStack {
                            Text(String(format: "%.0f", todayScore.overallScore))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                            Text("分")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)
                    
                    // 评分信息
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("睡眠质量")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f", todayScore.sleepQualityScore))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                            Text("梦境回忆")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f", todayScore.dreamRecallScore))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Image(systemName: "face.smiling.fill")
                                .foregroundColor(.green)
                            Text("情绪健康")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f", todayScore.emotionalHealthScore))
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.purple)
                            Text("模式健康")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f", todayScore.patternHealthScore))
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.subheadline)
                }
                
                // 趋势指示
                HStack {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                    Text(trendText)
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                
            } else {
                // 无数据状态
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("暂无健康评分")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("开始记录梦境，获取你的健康评分")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("计算评分") {
                        Task {
                            try await DreamWellnessScoreService(modelContext: modelContext)
                                .calculateTodayScore()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 40)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 维度卡片
    
    private var dimensionCards: some View {
        VStack(spacing: 12) {
            Text("评分维度")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DimensionCard(
                    title: "睡眠质量",
                    icon: "heart.fill",
                    color: .red,
                    score: scores.first?.sleepQualityScore ?? 0
                )
                
                DimensionCard(
                    title: "梦境回忆",
                    icon: "book.fill",
                    color: .blue,
                    score: scores.first?.dreamRecallScore ?? 0
                )
                
                DimensionCard(
                    title: "情绪健康",
                    icon: "face.smiling.fill",
                    color: .green,
                    score: scores.first?.emotionalHealthScore ?? 0
                )
                
                DimensionCard(
                    title: "模式健康",
                    icon: "chart.bar.fill",
                    color: .purple,
                    score: scores.first?.patternHealthScore ?? 0
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 趋势图表卡片
    
    private var trendChartCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("评分趋势")
                    .font(.headline)
                
                Spacer()
                
                Picker("周期", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { period in
                        Text("\(period)天").tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            // 简化的趋势图表 (实际应使用图表库)
            TrendChartView(scores: getScoresForPeriod(), height: 200)
                .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 预测卡片
    
    private var predictionCards: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI 预测")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
            }
            
            if predictions.isEmpty {
                Text("暂无预测，继续记录梦境以获取个性化预测")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(predictions.prefix(3)) { prediction in
                    PredictionCard(prediction: prediction)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 建议卡片
    
    private var recommendationsCard: some View {
        VStack(spacing: 12) {
            Text("改进建议")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let recommendations = scores.first?.recommendations, !recommendations.isEmpty {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 20)
                        Text(recommendation)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("保持当前的良好习惯！")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helpers
    
    private func getScoresForPeriod() -> [DreamWellnessScore] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod, to: Date()) ?? Date()
        return scores.filter { $0.date >= startDate }
    }
    
    private var trendIcon: String {
        guard let score = scores.first else { return "minus" }
        switch score.trend {
        case .rising: return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    private var trendColor: Color {
        guard let score = scores.first else { return .gray }
        switch score.trend {
        case .rising: return .green
        case .falling: return .red
        case .stable: return .gray
        }
    }
    
    private var trendText: String {
        guard let score = scores.first else { return "暂无趋势数据" }
        switch score.trend {
        case .rising: return "较过去 7 天上升"
        case .falling: return "较过去 7 天下降"
        case .stable: return "较过去 7 天保持稳定"
        }
    }
    
    private func scoreColor(score: Double) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .teal
        case 50..<70: return .yellow
        case 30..<50: return .orange
        default: return .red
        }
    }
}

// MARK: - 维度卡片组件

struct DimensionCard: View {
    let title: String
    let icon: String
    let color: Color
    let score: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Text(String(format: "%.0f", score))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * (score / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 趋势图表视图

struct TrendChartView: View {
    let scores: [DreamWellnessScore]
    let height: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            if scores.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let width = geometry.size.width
                let spacing: CGFloat = 4
                let barWidth = (width - CGFloat(scores.count - 1) * spacing) / CGFloat(scores.count)
                
                HStack(spacing: spacing) {
                    ForEach(scores.reversed(), id: \.date) { score in
                        VStack {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(scoreColor(score: score.overallScore))
                                .frame(width: barWidth, height: CGFloat(score.overallScore / 100) * (height - 30))
                            
                            Spacer()
                                .frame(height: 20)
                            
                            Text(score.date, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
    }
    
    private func scoreColor(score: Double) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .teal
        case 50..<70: return .yellow
        case 30..<50: return .orange
        default: return .red
        }
    }
}

// MARK: - 预测卡片组件

struct PredictionCard: View {
    let prediction: DreamPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(prediction.predictionType.emoji)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(prediction.predictionType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("置信度：\(Int(prediction.confidence))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                confidenceBadge
            }
            
            Text(prediction.predictedContent)
                .font(.body)
                .lineSpacing(4)
            
            if !prediction.recommendations.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("建议")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(prediction.recommendations, id: \.self) { rec in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(rec)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(confidenceColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var confidenceBadge: some View {
        Text(prediction.confidenceLevel.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor.opacity(0.1))
            .foregroundColor(confidenceColor)
            .cornerRadius(6)
    }
    
    private var confidenceColor: Color {
        switch prediction.confidenceLevel {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }
}

// MARK: - 预览

#Preview {
    DreamWellnessScoreView()
        .modelContainer(for: [DreamWellnessScore.self, DreamPrediction.self], inMemory: true)
}
