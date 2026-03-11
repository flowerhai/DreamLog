//
//  AdvancedDashboardView.swift
//  DreamLog
//
//  Phase 20: 高级数据分析仪表板
//  交互式数据可视化、关联分析、趋势预测
//

import SwiftUI
import Charts

struct AdvancedDashboardView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @ObservedObject private var correlationService = DreamCorrelationService.shared
    @ObservedObject private var trendService = DreamTrendService.shared
    
    @State private var selectedPeriod: Int = 30
    @State private var showingPeriodPicker = false
    @State private var selectedTab: DashboardTab = .overview
    @State private var isRefreshing = false
    
    enum DashboardTab: String, CaseIterable {
        case overview = "概览"
        case correlations = "关联"
        case predictions = "预测"
        case insights = "洞察"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 周期选择器
                periodSelector
                
                // 标签页选择
                tabSelector
                
                // 内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .correlations:
                            correlationsContent
                        case .predictions:
                            predictionsContent
                        case .insights:
                            insightsContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("数据分析仪表板")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    // MARK: - 子视图
    
    @ViewBuilder
    private var periodSelector: some View {
        HStack {
            Text("分析周期:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { showingPeriodPicker = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(periodLabel)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .confirmationDialog("选择分析周期", isPresented: $showingPeriodPicker) {
            Button("7 天") { selectedPeriod = 7; loadData() }
            Button("14 天") { selectedPeriod = 14; loadData() }
            Button("30 天") { selectedPeriod = 30; loadData() }
            Button("90 天") { selectedPeriod = 90; loadData() }
            Button("180 天") { selectedPeriod = 180; loadData() }
            Button("取消", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTab == tab ? Color.accentColor : Color.accentColor.opacity(0.1))
                            )
                            .foregroundColor(selectedTab == tab ? .white : .accentColor)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    @ViewBuilder
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 统计卡片
            statsCards
            
            Divider()
            
            // 情绪趋势图
            emotionTrendSection
            
            Divider()
            
            // 主题分布
            themeDistributionSection
            
            Divider()
            
            // 时间模式
            timePatternSection
        }
    }
    
    @ViewBuilder
    private var correlationsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if correlationService.isAnalyzing {
                loadingView
            } else if let report = correlationService.correlationReport {
                // 强关联发现
                strongCorrelationsSection(report: report)
                
                Divider()
                
                // 标签 - 情绪关联
                tagEmotionSection(report: report)
                
                Divider()
                
                // 时间 - 主题关联
                timeThemeSection(report: report)
                
                Divider()
                
                // 星期模式
                weekdayPatternSection(report: report)
            } else {
                emptyCorrelationsView
            }
        }
    }
    
    @ViewBuilder
    private var predictionsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if trendService.isAnalyzing {
                loadingView
            } else if let report = trendService.trendReport {
                // 预测卡片
                predictionCards(report: report)
                
                Divider()
                
                // 趋势分析
                trendAnalysisSection(report: report)
                
                Divider()
                
                // 建议
                recommendationsSection(report: report)
            } else {
                emptyPredictionsView
            }
        }
    }
    
    @ViewBuilder
    private var insightsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // AI 洞察
            aiInsightsSection
            
            Divider()
            
            // 模式发现
            patternDiscoveriesSection
            
            Divider()
            
            // 个性化建议
            personalizedRecommendationsSection
        }
    }
    
    // MARK: - 概览内容
    
    @ViewBuilder
    private var statsCards: some View {
        let stats = dreamStore.getStatistics()
        
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                title: "总梦境数",
                value: "\(stats.totalDreams)",
                icon: "book.fill",
                color: .blue
            )
            
            StatCard(
                title: "记录天数",
                value: "\(stats.totalDays)",
                icon: "calendar",
                color: .green
            )
            
            StatCard(
                title: "清醒梦",
                value: "\(stats.lucidDreamCount)",
                subtitle: "\(String(format: "%.1f", stats.lucidDreamPercentage))%",
                icon: "sparkles",
                color: .purple
            )
            
            StatCard(
                title: "平均清晰度",
                value: String(format: "%.1f", stats.averageClarity),
                subtitle: "/ 5.0",
                icon: "eye.fill",
                color: .orange
            )
        }
    }
    
    @ViewBuilder
    private var emotionTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("情绪趋势")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(emotionTrendData, id: \.date) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("情绪值", item.value)
                    )
                    .foregroundStyle(by: .value("情绪", item.emotion))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                Text("需要 iOS 16+ 以显示图表")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var themeDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主题分布")
                .font(.headline)
            
            let stats = dreamStore.getStatistics()
            
            ForEach(stats.topThemes.prefix(5), id: \.theme) { item in
                HStack {
                    Text(item.theme)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    ProgressBar(progress: Double(item.count) / Double(stats.totalDreams))
                        .frame(width: 100, height: 8)
                    
                    Text("\(item.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var timePatternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间模式")
                .font(.headline)
            
            let stats = dreamStore.getStatistics()
            
            HStack(spacing: 12) {
                TimeBlock(title: "早晨", count: stats.dreamsPerTimeOfDay["早晨"] ?? 0, icon: "sunrise.fill", color: .orange)
                TimeBlock(title: "下午", count: stats.dreamsPerTimeOfDay["下午"] ?? 0, icon: "sun.max.fill", color: .yellow)
                TimeBlock(title: "傍晚", count: stats.dreamsPerTimeOfDay["傍晚"] ?? 0, icon: "sunset.fill", color: .pink)
                TimeBlock(title: "夜晚", count: stats.dreamsPerTimeOfDay["夜晚"] ?? 0, icon: "moon.fill", color: .purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - 关联内容
    
    @ViewBuilder
    private func strongCorrelationsSection(report: DreamCorrelationService.DreamCorrelationReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("强关联发现")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            
            ForEach(report.strongCorrelations.prefix(3), id: \.id) { corr in
                CorrelationCard(correlation: corr)
            }
            
            if report.strongCorrelations.isEmpty {
                Text("暂无强关联发现，继续记录梦境以发现更多模式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func tagEmotionSection(report: DreamCorrelationService.DreamCorrelationReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标签 - 情绪关联")
                .font(.headline)
            
            ForEach(report.tagEmotionCorrelations.prefix(5), id: \.id) { corr in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(corr.tag) → \(corr.emotion.rawValue)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(corr.insight)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(String(format: "%.0f", corr.correlationStrength * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.05))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func timeThemeSection(report: DreamCorrelationService.DreamCorrelationReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间 - 主题关联")
                .font(.headline)
            
            ForEach(report.timeThemeCorrelations.prefix(5), id: \.id) { corr in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: timeOfDayIcon(corr.timeOfDay))
                                .foregroundColor(.accentColor)
                            
                            Text("\(corr.timeOfDay.rawValue) · \(corr.theme)")
                                .font(.subheadline)
                        }
                        
                        Text("占比 \(String(format: "%.1f", corr.percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ProgressBar(progress: corr.correlationStrength)
                        .frame(width: 80, height: 6)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.05))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func weekdayPatternSection(report: DreamCorrelationService.DreamCorrelationReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("星期模式")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(report.weekdayPatterns, id: \.weekday) { pattern in
                        WeekdayCard(pattern: pattern)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - 预测内容
    
    @ViewBuilder
    private func predictionCards(report: DreamTrendService.DreamTrendReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
            ForEach(report.predictions.prefix(3), id: \.id) { prediction in
                PredictionCard(prediction: prediction)
            }
        }
    }
    
    @ViewBuilder
    private func trendAnalysisSection(report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趋势分析")
                .font(.headline)
            
            TrendRow(title: "情绪稳定性", value: String(format: "%.0f", report.emotionStability * 100), trend: report.emotionStability > 0.7 ? .stable : .fluctuating)
            TrendRow(title: "清晰度趋势", value: report.clarityTrend.rawValue, trend: trendDirectionToTrend(report.clarityTrend))
            TrendRow(title: "清醒梦频率", value: String(format: "%.1f%%", report.lucidDreamFrequency), trend: report.lucidTrend)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func recommendationsSection(report: DreamTrendService.DreamTrendReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("个性化建议")
                .font(.headline)
            
            ForEach(report.recommendations.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.accentColor))
                    
                    Text(report.recommendations[index])
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - 洞察内容
    
    @ViewBuilder
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 洞察")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
            }
            
            if let report = correlationService.correlationReport {
                ForEach(report.insights, id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            } else if let report = trendService.trendReport {
                ForEach(report.predictions.prefix(3), id: \.id) { prediction in
                    InsightCard(
                        title: prediction.type.rawValue,
                        description: prediction.description,
                        confidence: prediction.confidence,
                        actionable: true
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var patternDiscoveriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模式发现")
                .font(.headline)
            
            Text("基于你的梦境记录，AI 发现了以下模式:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 这里可以添加更多模式发现内容
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var personalizedRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("个性化建议")
                .font(.headline)
            
            if let report = correlationService.correlationReport {
                ForEach(report.recommendations.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text(report.recommendations[index])
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else if let report = trendService.trendReport {
                ForEach(report.recommendations.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text(report.recommendations[index])
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - 辅助视图
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在分析数据...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    @ViewBuilder
    private var emptyCorrelationsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.scatter")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无关联数据")
                .font(.headline)
            
            Text("记录更多梦境后，AI 将为你分析关联模式")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: loadData) {
                Label("生成报告", systemImage: "sparkles")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    @ViewBuilder
    private var emptyPredictionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "crystal.ball")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无预测数据")
                .font(.headline)
            
            Text("生成趋势报告后，AI 将为你提供预测")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await trendService.generateTrendReport(dreams: dreamStore.dreams, periodDays: selectedPeriod)
                }
            }) {
                Label("生成报告", systemImage: "sparkles")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - 方法
    
    private var periodLabel: String {
        switch selectedPeriod {
        case 7: return "7 天"
        case 14: return "14 天"
        case 30: return "30 天"
        case 90: return "90 天"
        case 180: return "180 天"
        default: return "\(selectedPeriod)天"
        }
    }
    
    private func loadData() {
        isRefreshing = true
        
        Task {
            // 并行加载数据
            async let _ = correlationService.generateCorrelationReport(dreams: dreamStore.dreams, periodDays: selectedPeriod)
            async let _ = trendService.generateTrendReport(dreams: dreamStore.dreams, periodDays: selectedPeriod)
            
            _ = await (_ , _)
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func refreshData() {
        loadData()
    }
    
    private func timeOfDayIcon(_ timeOfDay: TimeOfDay) -> String {
        switch timeOfDay {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }
    
    private func trendDirectionToTrend(_ direction: DreamTrendService.TrendDirection) -> Trend {
        switch direction {
        case .increasing: return .up
        case .decreasing: return .down
        case .stable: return .stable
        case .fluctuating: return .fluctuating
        }
    }
    
    // MARK: - 数据类型
    
    struct EmotionTrendData: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let emotion: String
    }
    
    var emotionTrendData: [EmotionTrendData] {
        // 生成模拟数据用于图表
        let calendar = Calendar.current
        var data: [EmotionTrendData] = []
        
        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            data.append(EmotionTrendData(date: date, value: Double.random(in: 3...8), emotion: "平静"))
        }
        
        return data.reversed()
    }
    
    enum Trend {
        case up, down, stable, fluctuating
    }
}

// MARK: - 子组件

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 2)
        )
    }
}

struct TimeBlock: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

struct CorrelationCard: View {
    let correlation: DreamCorrelationService.StrongCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.accentColor)
                
                Text("\(correlation.factorA) ↔ \(correlation.factorB)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(correlation.insight)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text("关联强度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ProgressBar(progress: correlation.strength)
                    .frame(width: 60, height: 4)
                
                Text(correlation.confidence == "high" ? "高置信" : "中置信")
                    .font(.caption2)
                    .foregroundColor(correlation.confidence == "high" ? .green : .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.05))
        )
    }
}

struct PredictionCard: View {
    let prediction: DreamTrendService.DreamPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: predictionIcon(prediction.type))
                    .foregroundColor(.purple)
                
                Text(prediction.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(String(format: "%.0f", prediction.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(prediction.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(prediction.timeFrame)
                .font(.caption2)
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.purple.opacity(0.1))
        )
    }
    
    private func predictionIcon(_ type: DreamTrendService.PredictionType) -> String {
        switch type {
        case .emotion: return "face.smiling"
        case .theme: return "tag.fill"
        case .clarity: return "eye.fill"
        case .lucid: return "sparkles"
        case .recurrence: return "repeat"
        }
    }
}

struct TrendRow: View {
    let title: String
    let value: String
    let trend: AdvancedDashboardView.Trend
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Image(systemName: trendIcon)
                .foregroundColor(trendColor)
        }
        .padding(.vertical, 4)
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        case .fluctuating: return "arrow.left.and.right"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        case .fluctuating: return .orange
        }
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let confidence: Double
    let actionable: Bool
    
    init(title: String, description: String, confidence: Double, actionable: Bool) {
        self.title = title
        self.description = description
        self.confidence = confidence
        self.actionable = actionable
    }
    
    init(insight: DreamCorrelationService.CorrelationInsight) {
        self.title = insight.title
        self.description = insight.description
        self.confidence = insight.confidence
        self.actionable = insight.actionable
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if actionable {
                    Text("可操作")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .foregroundColor(.green)
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("置信度 \(String(format: "%.0f", confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

struct WeekdayCard: View {
    let pattern: DreamCorrelationService.WeekdayPattern
    
    var body: some View {
        VStack(spacing: 8) {
            Text(pattern.weekdayName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Image(systemName: weekdayIcon(pattern.weekday))
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text("\(String(format: "%.1f", pattern.avgDreamCount))")
                .font(.title3)
                .fontWeight(.bold)
            
            if let lucidPercent = pattern.lucidDreamPercentage as Double? {
                Text("\(String(format: "%.0f", lucidPercent))% 清醒梦")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
    
    private func weekdayIcon(_ weekday: Int) -> String {
        weekday == 1 || weekday == 7 ? "calendar.badge.weekend" : "calendar"
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * min(progress, 1.0))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AdvancedDashboardView()
        .environmentObject(DreamStore())
}
