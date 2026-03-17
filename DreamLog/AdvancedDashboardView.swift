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
    @State private var appearsWithAnimation = false
    @State private var showingExportSheet = false
    @State private var isExporting = false
    
    private let animationDuration: Double = 0.3
    
    enum DashboardTab: String, CaseIterable {
        case overview = "概览"
        case correlations = "关联"
        case predictions = "预测"
        case insights = "洞察"
    }
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF 报告"
        case csv = "CSV 数据"
        case json = "JSON 原始数据"
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 导出按钮
                    Menu {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                exportData(format: format)
                            }) {
                                Label(format.rawValue, systemImage: exportIcon(for: format))
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .symbolEffect(.pulse, options: .repeating, value: isExporting)
                    }
                    .disabled(isExporting)
                    
                    // 刷新按钮
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
            }
            .confirmationDialog("导出数据", isPresented: $showingExportSheet) {
                Text("选择导出格式")
            } message: {
                Text("将当前仪表板数据导出为指定格式")
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
                        .symbolEffect(.pulse, options: .repeating, value: isRefreshing)
                    Text(periodLabel)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.15))
                        .shadow(color: .accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                )
                .foregroundColor(.accentColor)
                .scaleEffect(appearsWithAnimation ? 1 : 0.95)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .confirmationDialog("选择分析周期", isPresented: $showingPeriodPicker) {
            Button("7 天") { selectedPeriod = 7; loadData() }
            Button("14 天") { selectedPeriod = 14; loadData() }
            Button("30 天") { selectedPeriod = 30; loadData() }
            Button("90 天") { selectedPeriod = 90; loadData() }
            Button("180 天") { selectedPeriod = 180; loadData() }
            Button("取消", role: .cancel) {}
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appearsWithAnimation = true
            }
        }
    }
    
    @ViewBuilder
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tabIcon(for: tab))
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.subheadline)
                        }
                        .fontWeight(selectedTab == tab ? .semibold : .medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                                } else {
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.08))
                                }
                            }
                        )
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    private func tabIcon(for tab: DashboardTab) -> String {
        switch tab {
        case .overview: return "chart.bar.fill"
        case .correlations: return "link"
        case .predictions: return "crystal.ball"
        case .insights: return "lightbulb.fill"
        }
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
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
                
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 8) {
                Text("正在分析数据...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("AI 正在为你生成深度洞察")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 进度指示器装饰
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isRefreshing ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isRefreshing
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .padding()
    }
    
    @ViewBuilder
    private var emptyCorrelationsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "chart.scatter")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
            }
            .symbolEffect(.bounce, options: .repeating)
            
            VStack(spacing: 8) {
                Text("暂无关联数据")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("记录更多梦境后，AI 将为你分析关联模式")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // 提示卡片
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("小提示")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                Text("建议记录至少 10 个梦境，并添加标签和情绪，这样可以发现更多有趣的关联模式")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                loadData()
            }) {
                Label("生成报告", systemImage: "sparkles")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 350)
        .padding()
    }
    
    @ViewBuilder
    private var emptyPredictionsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crystal.ball")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)
            }
            .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text("暂无预测数据")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("生成趋势报告后，AI 将为你提供预测")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // 预测能力说明
            VStack(alignment: .leading, spacing: 10) {
                Text("AI 可以预测:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(["情绪趋势变化", "清醒梦出现概率", "梦境主题演变", "记录习惯建议"], id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task {
                    await trendService.generateTrendReport(dreams: dreamStore.dreams, periodDays: selectedPeriod)
                }
            }) {
                Label("生成报告", systemImage: "sparkles")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 380)
        .padding()
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
            async let correlationReport = correlationService.generateCorrelationReport(dreams: dreamStore.dreams, periodDays: selectedPeriod)
            async let trendReport = trendService.generateTrendReport(dreams: dreamStore.dreams, periodDays: selectedPeriod)
            
            _ = await (correlationReport, trendReport)
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func refreshData() {
        loadData()
    }
    
    private func exportData(format: ExportFormat) {
        isExporting = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        Task {
            do {
                let filename = "DreamLog_分析报表_\(Date().formatted(.dateTime.year().month().day().hour().minute()))"
                
                switch format {
                case .csv:
                    try await exportAsCSV(filename: filename)
                case .json:
                    try await exportAsJSON(filename: filename)
                case .pdf:
                    try await exportAsPDF(filename: filename)
                }
                
                await MainActor.run {
                    isExporting = false
                    showExportSuccess(format: format)
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    showExportError(error: error)
                }
            }
        }
    }
    
    private func exportAsCSV(filename: String) async throws {
        let stats = dreamStore.getStatistics()
        var csvContent = "指标，数值\n"
        
        csvContent += "总梦境数，\(stats.totalDreams)\n"
        csvContent += "记录天数，\(stats.totalDays)\n"
        csvContent += "清醒梦数量，\(stats.lucidDreamCount)\n"
        csvContent += "清醒梦比例，\(String(format: "%.1f", stats.lucidDreamPercentage))%\n"
        csvContent += "平均清晰度，\(String(format: "%.1f", stats.averageClarity))\n"
        csvContent += "平均情绪值，\(String(format: "%.2f", stats.averageMood))\n"
        
        // 添加情绪分布
        csvContent += "\n情绪分布\n"
        for (emotion, count) in stats.moodDistribution {
            csvContent += "\(emotion),\(count)\n"
        }
        
        // 添加热门标签
        csvContent += "\n热门标签\n"
        for item in stats.topThemes {
            csvContent += "\(item.theme),\(item.count)\n"
        }
        
        // 保存文件
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(filename).csv")
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func exportAsJSON(filename: String) async throws {
        let stats = dreamStore.getStatistics()
        let exportData: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "period": selectedPeriod,
            "statistics": [
                "totalDreams": stats.totalDreams,
                "totalDays": stats.totalDays,
                "lucidDreamCount": stats.lucidDreamCount,
                "lucidDreamPercentage": stats.lucidDreamPercentage,
                "averageClarity": stats.averageClarity,
                "averageMood": stats.averageMood
            ],
            "moodDistribution": stats.moodDistribution,
            "topThemes": stats.topThemes.map { ["theme": $0.theme, "count": $0.count] },
            "dreamsPerTimeOfDay": stats.dreamsPerTimeOfDay
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(filename).json")
        try jsonData.write(to: fileURL)
    }
    
    private func exportAsPDF(filename: String) async throws {
        // 使用 DreamReportExportService 导出 PDF
        let exportService = DreamReportExportService.shared
        let config = DreamReportExportService.ExportConfig(
            style: .modern,
            includeCoverPage: true,
            includeTableOfContents: true,
            includeStatistics: true,
            includeCharts: true
        )
        
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod, to: Date()) ?? Date()
        let endDate = Date()
        
        try await exportService.exportPDF(
            dreams: dreamStore.dreams.filter { $0.date >= startDate && $0.date <= endDate },
            config: config,
            filename: "\(filename).pdf"
        )
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func showExportSuccess(format: ExportFormat) {
        // 这里可以添加 Toast 提示
        print("✅ 成功导出 \(format.rawValue)")
    }
    
    private func showExportError(error: Error) {
        print("❌ 导出失败：\(error.localizedDescription)")
    }
    
    private func exportIcon(for format: ExportFormat) -> String {
        switch format {
        case .pdf: return "doc.fill"
        case .csv: return "tablecells"
        case .json: return "curlybraces.square.fill"
        }
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
    
    @State private var isHovering = false
    @State private var appears = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
                
                Spacer()
                
                // 装饰性小圆点
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .opacity(isHovering ? 1 : 0.5)
            }
            
            Spacer()
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .scaleEffect(appears ? 1 : 0.9)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            color.opacity(0.03)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(isHovering ? 0.3 : 0.15), radius: isHovering ? 12 : 8, x: 0, y: isHovering ? 6 : 3)
        )
        .scaleEffect(appears ? 1 : 0.95)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
                appears = true
            }
        }
    }
}

struct TimeBlock: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolEffect(.bounce, value: isHovering)
            }
            .scaleEffect(isHovering ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.15),
                            color.opacity(0.08)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: color.opacity(isHovering ? 0.25 : 0.15), radius: isHovering ? 10 : 6, x: 0, y: isHovering ? 5 : 2)
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
    }
}

struct CorrelationCard: View {
    let correlation: DreamCorrelationService.StrongCorrelation
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                
                Text("\(correlation.factorA) ↔ \(correlation.factorB)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 关联强度指示器
                Circle()
                    .fill(correlationStrengthColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: correlationStrengthColor.opacity(0.5), radius: 4, x: 0, y: 2)
            }
            
            Text(correlation.insight)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.vertical, 4)
            
            HStack(spacing: 8) {
                Text("关联强度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 70, height: 6)
                    
                    Capsule()
                        .fill(correlationStrengthColor)
                        .frame(width: 70 * correlation.strength, height: 6)
                }
                
                Text(correlation.confidence == "high" ? "高置信" : "中置信")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(correlation.confidence == "high" ? .green : .orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((correlation.confidence == "high" ? Color.green : Color.orange).opacity(0.15))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color.accentColor.opacity(0.04)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .accentColor.opacity(isHovering ? 0.2 : 0.1), radius: isHovering ? 12 : 6, x: 0, y: isHovering ? 6 : 2)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
    }
    
    private var correlationStrengthColor: Color {
        if correlation.strength >= 0.7 { return .green }
        if correlation.strength >= 0.5 { return .orange }
        return .blue
    }
}

struct PredictionCard: View {
    let prediction: DreamTrendService.DreamPrediction
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: predictionIcon(prediction.type))
                        .font(.caption)
                        .foregroundColor(.purple)
                        .symbolEffect(.pulse, options: .repeating)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(prediction.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(prediction.timeFrame)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 置信度徽章
                VStack(spacing: 2) {
                    Text("\(String(format: "%.0f", prediction.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("置信")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.purple.opacity(0.1))
                )
            }
            
            Text(prediction.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(.vertical, 4)
            
            // 预测方向指示器
            HStack(spacing: 4) {
                Image(systemName: predictionTrendIcon)
                    .font(.caption)
                    .foregroundColor(trendColor)
                
                Text(trendDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(trendColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(trendColor.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color.purple.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .purple.opacity(isHovering ? 0.25 : 0.12), radius: isHovering ? 12 : 6, x: 0, y: isHovering ? 6 : 2)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
    }
    
    private var predictionTrendIcon: String {
        if prediction.description.contains("上升") || prediction.description.contains("增加") { return "arrow.up.right" }
        if prediction.description.contains("下降") || prediction.description.contains("减少") { return "arrow.down.right" }
        return "arrow.right"
    }
    
    private var trendColor: Color {
        if prediction.description.contains("上升") || prediction.description.contains("增加") { return .green }
        if prediction.description.contains("下降") || prediction.description.contains("减少") { return .orange }
        return .blue
    }
    
    private var trendDescription: String {
        if prediction.description.contains("上升") || prediction.description.contains("增加") { return "上升趋势" }
        if prediction.description.contains("下降") || prediction.description.contains("减少") { return "下降趋势" }
        return "稳定趋势"
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
    var color: Color = .accentColor
    var height: CGFloat = 6
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: height)
                
                // 进度条
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(animatedProgress, 1.0), height: height)
                    .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 2)
                
                // 高光效果
                if animatedProgress > 0.1 {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: geometry.size.width * min(animatedProgress, 1.0) - 4, height: height / 3)
                        .offset(y: -height / 6)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatedProgress = min(progress, 1.0)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AdvancedDashboardView()
        .environmentObject(DreamStore())
}
