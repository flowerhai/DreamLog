//
//  DreamTrendView.swift
//  DreamLog
//
//  Phase 5: 梦境趋势分析视图
//

import SwiftUI

struct DreamTrendView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @StateObject private var trendService = DreamTrendService.shared
    @State private var selectedPeriod: Int = 30 // 默认分析 30 天
    @State private var showingPeriodPicker = false
    
    var body: some View {
        NavigationView {
            Group {
                if trendService.isAnalyzing {
                    loadingView
                } else if let report = trendService.trendReport {
                    reportView(report)
                } else {
                    emptyView
                }
            }
            .navigationTitle("梦境趋势")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingPeriodPicker = true }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(periodLabel)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: generateReport) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if trendService.trendReport == nil {
                    generateReport()
                }
            }
            .confirmationDialog("选择分析周期", isPresented: $showingPeriodPicker) {
                Button("7 天") { selectedPeriod = 7; generateReport() }
                Button("14 天") { selectedPeriod = 14; generateReport() }
                Button("30 天") { selectedPeriod = 30; generateReport() }
                Button("90 天") { selectedPeriod = 90; generateReport() }
                Button("取消", role: .cancel) {}
            }
        }
    }
    
    // MARK: - 子视图
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在分析梦境趋势...")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("AI 正在识别你的梦境模式")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无趋势数据")
                .font(.headline)
            Text("记录更多梦境后，AI 将为你分析梦境趋势")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: generateReport) {
                Label("生成报告", systemImage: "sparkles")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
    }
    
    private func reportView(_ report: DreamTrendService.DreamTrendReport) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 概览卡片
                overviewCard(report)
                
                // 情绪趋势
                emotionTrendsCard(report)
                
                // 主题趋势
                themeTrendsCard(report)
                
                // 时间模式
                timePatternsCard(report)
                
                // AI 预测
                predictionsCard(report)
                
                // 个性化建议
                recommendationsCard(report)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 卡片组件
    
    private func overviewCard(_ report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("趋势概览")
                    .font(.headline)
                Spacer()
                Text(periodLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                // 平均清晰度
                StatItem(
                    icon: "eye.fill",
                    label: "平均清晰度",
                    value: String(format: "%.1f", report.averageClarity),
                    max: "5.0",
                    trend: report.clarityTrend
                )
                
                // 清醒梦频率
                StatItem(
                    icon: "brain.head.profile",
                    label: "清醒梦",
                    value: String(format: "%.0f%%", report.lucidDreamFrequency),
                    max: "100%",
                    trend: report.lucidTrend
                )
                
                // 情绪稳定性
                StatItem(
                    icon: "heart.fill",
                    label: "情绪稳定",
                    value: String(format: "%.0f%%", report.emotionStability * 100),
                    max: "100%",
                    trend: .stable
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func emotionTrendsCard(_ report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.pink)
                Text("情绪趋势")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            if let dominant = report.dominantEmotion {
                HStack {
                    Text("主导情绪:")
                        .foregroundColor(.secondary)
                    Text(dominant.rawValue)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            
            VStack(spacing: 8) {
                ForEach(report.emotionTrends.prefix(5)) { trend in
                    EmotionTrendRow(trend: trend)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func themeTrendsCard(_ report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("主题趋势")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // 新兴主题
            if !report.emergingThemes.isEmpty {
                HStack {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.green)
                    Text("新兴主题")
                        .fontWeight(.medium)
                    Spacer()
                }
                .font(.subheadline)
                
                FlowLayout(spacing: 8) {
                    ForEach(report.emergingThemes, id: \.self) { theme in
                        TagBadge(text: theme, color: .green)
                    }
                }
            }
            
            // 减弱主题
            if !report.fadingThemes.isEmpty {
                HStack {
                    Image(systemName: "arrow.down.right.circle.fill")
                        .foregroundColor(.orange)
                    Text("减弱主题")
                        .fontWeight(.medium)
                    Spacer()
                }
                .font(.subheadline)
                .padding(.top, 8)
                
                FlowLayout(spacing: 8) {
                    ForEach(report.fadingThemes, id: \.self) { theme in
                        TagBadge(text: theme, color: .orange)
                    }
                }
            }
            
            // 热门主题
            VStack(spacing: 8) {
                ForEach(report.themeTrends.prefix(5)) { trend in
                    ThemeTrendRow(trend: trend)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func timePatternsCard(_ report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("时间模式")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("最佳回忆时段:")
                    .foregroundColor(.secondary)
                Text(report.bestRecallTime.localizedName)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            .font(.subheadline)
            
            // 时间段分布
            VStack(spacing: 8) {
                TimeBar(label: "清晨", value: report.timePatterns.morningDreams, max: maxTimeValue(report.timePatterns), color: .orange)
                TimeBar(label: "下午", value: report.timePatterns.afternoonDreams, max: maxTimeValue(report.timePatterns), color: .yellow)
                TimeBar(label: "傍晚", value: report.timePatterns.eveningDreams, max: maxTimeValue(report.timePatterns), color: .purple)
                TimeBar(label: "深夜", value: report.timePatterns.nightDreams, max: maxTimeValue(report.timePatterns), color: .indigo)
            }
            
            // 工作日 vs 周末
            HStack(spacing: 20) {
                VStack {
                    Text("工作日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(report.timePatterns.weekdayVsWeekend.weekday)")
                        .font(.headline)
                }
                
                VStack {
                    Text("周末")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(report.timePatterns.weekdayVsWeekend.weekend)")
                        .font(.headline)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func predictionsCard(_ report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crystal.ball.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("AI 预测")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 10) {
                ForEach(report.predictions) { prediction in
                    PredictionRow(prediction: prediction)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func recommendationsCard(_ report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("个性化建议")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(report.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 辅助方法
    
    private func generateReport() {
        Task {
            await trendService.generateTrendReport(
                dreams: dreamStore.dreams,
                periodDays: selectedPeriod
            )
        }
    }
    
    private var periodLabel: String {
        switch selectedPeriod {
        case 7: return "近 7 天"
        case 14: return "近 2 周"
        case 30: return "近 1 月"
        case 90: return "近 3 月"
        default: return "近\(selectedPeriod)天"
        }
    }
    
    private func maxTimeValue(_ patterns: DreamTrendService.TimePatternAnalysis) -> Int {
        max(patterns.morningDreams, patterns.afternoonDreams, patterns.eveningDreams, patterns.nightDreams, 1)
    }
}

// MARK: - 子组件

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let max: String
    let trend: DreamTrendService.TrendDirection
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            TrendIndicator(trend: trend)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TrendIndicator: View {
    let trend: DreamTrendService.TrendDirection
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trendIcon)
                .font(.caption2)
                .foregroundColor(trendColor)
        }
    }
    
    private var trendIcon: String {
        switch trend {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "minus"
        case .fluctuating: return "arrow.left.and.right"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .secondary
        case .fluctuating: return .orange
        }
    }
}

struct EmotionTrendRow: View {
    let trend: DreamTrendService.EmotionTrend
    
    var body: some View {
        HStack {
            Text(trend.emotion.rawValue)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(emotionColor)
                        .frame(width: geo.size.width * min(CGFloat(trend.frequency) / 10, 1), height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(trend.frequency)次")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50)
            
            TrendIndicator(trend: trend.trend)
        }
    }
    
    private var emotionColor: Color {
        switch trend.emotion {
        case .calm: return .blue
        case .happy: return .yellow
        case .anxious: return .orange
        case .fearful: return .purple
        case .confused: return .gray
        case .excited: return .pink
        case .sad: return .indigo
        case .angry: return .red
        case .surprised: return .green
        case .neutral: return .secondary
        }
    }
}

struct ThemeTrendRow: View {
    let trend: DreamTrendService.ThemeTrend
    
    var body: some View {
        HStack {
            Text(trend.theme)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * min(CGFloat(trend.frequency) / 10, 1), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(trend.frequency)次")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50)
            
            TrendIndicator(trend: trend.trend)
        }
    }
}

struct PredictionRow: View {
    let prediction: DreamTrendService.DreamPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: predictionIcon)
                    .foregroundColor(predictionColor)
                Text(prediction.description)
                    .font(.subheadline)
                Spacer()
            }
            
            HStack {
                Text(prediction.timeFrame)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("置信度 \(Int(prediction.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private var predictionIcon: String {
        switch prediction.type {
        case .emotion: return "heart.fill"
        case .theme: return "tag.fill"
        case .clarity: return "eye.fill"
        case .lucid: return "brain.head.profile"
        case .recurrence: return "repeat"
        }
    }
    
    private var predictionColor: Color {
        switch prediction.type {
        case .emotion: return .pink
        case .theme: return .blue
        case .clarity: return .purple
        case .lucid: return .green
        case .recurrence: return .orange
        }
    }
}

struct TimeBar: View {
    let label: String
    let value: Int
    let max: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / CGFloat(max), height: 10)
                }
            }
            .frame(height: 10)
            
            Text("\(value)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30)
        }
    }
}

struct TagBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
    }
}

struct FlowLayout: View {
    let spacing: CGFloat
    @Builder var content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60, maximum: 100))], spacing: spacing) {
            content()
        }
    }
}

// MARK: - 扩展

extension DreamTrendService.TimeOfDay {
    var localizedName: String {
        switch self {
        case .morning: return "清晨 (6-12 点)"
        case .afternoon: return "下午 (12-18 点)"
        case .evening: return "傍晚 (18-24 点)"
        case .night: return "深夜 (0-6 点)"
        }
    }
}

// MARK: - 预览

#Preview {
    DreamTrendView()
        .environmentObject(DreamStore.shared)
}
