//
//  DreamSceneAnalysisView.swift
//  DreamLog
//
//  梦境场景分析视图：展示场景分布和洞察
//

import SwiftUI
import Charts

struct DreamSceneAnalysisView: View {
    @StateObject private var viewModel = DreamSceneAnalysisViewModel()
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingConfig = false
    
    enum TimeRange: String, CaseIterable {
        case week = "week"
        case month = "month"
        case quarter = "quarter"
        case year = "year"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .week: return "近 7 天"
            case .month: return "近 30 天"
            case .quarter: return "近 90 天"
            case .year: return "近 1 年"
            case .all: return "全部"
            }
        }
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            case .all: return nil
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计概览卡片
                    overviewCards
                    
                    // 场景分布图表
                    sceneDistributionChart
                    
                    // 场景类型详情
                    sceneTypeDetails
                    
                    // 场景洞察
                    insightsSection
                    
                    // 场景 - 情绪关联
                    emotionCorrelationSection
                }
                .padding()
            }
            .navigationTitle("场景分析")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingConfig.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingConfig) {
                SceneAnalysisConfigView(config: $viewModel.config)
            }
            .onAppear {
                Task {
                    await viewModel.loadData(timeRange: selectedTimeRange)
                }
            }
        }
    }
    
    // MARK: - Overview Cards
    
    private var overviewCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SceneAnalysisStatCard(
                    title: "已分析梦境",
                    value: "\(viewModel.summary.analyzedDreams)",
                    subtitle: "共 \(viewModel.summary.totalDreams) 个",
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                SceneAnalysisStatCard(
                    title: "场景多样性",
                    value: String(format: "%.2f", viewModel.summary.sceneDiversity),
                    subtitle: diversityDescription(viewModel.summary.sceneDiversity),
                    icon: "chart.pie.fill",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                SceneAnalysisStatCard(
                    title: "最常见场景",
                    value: viewModel.summary.favoriteScene?.displayName ?? "-",
                    subtitle: topScenePercentage,
                    icon: viewModel.summary.favoriteScene?.icon ?? "questionmark",
                    color: viewModel.summary.favoriteScene?.color ?? .gray
                )
                
                SceneAnalysisStatCard(
                    title: "平均置信度",
                    value: String(format: "%.0f%%", viewModel.summary.averageConfidence * 100),
                    subtitle: "分析准确度",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    private var topScenePercentage: String {
        guard let firstScene = viewModel.summary.topScenes.first else { return "-" }
        return String(format: "%.1f%%", firstScene.percentage)
    }
    
    private func diversityDescription(_ diversity: Double) -> String {
        if diversity < 0.3 { return "较低" }
        else if diversity < 0.6 { return "中等" }
        else { return "丰富" }
    }
    
    // MARK: - Scene Distribution Chart
    
    private var sceneDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("场景分布")
                .font(.headline)
            
            if viewModel.summary.topScenes.isEmpty {
                emptyStateView
            } else {
                Chart {
                    ForEach(viewModel.summary.topScenes.prefix(8), id: \.sceneType) { distribution in
                        BarMark(
                            x: .value("场景", distribution.sceneType.displayName),
                            y: .value("数量", distribution.count)
                        )
                        .foregroundStyle(by: .value("场景", distribution.sceneType.displayName))
                        .annotation(position: .top, alignment: .center) {
                            Text("\(distribution.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel(rotation: .degrees(-45), anchor: .topTrailing) { value in
                            if let sceneType = value.as(DreamSceneType.self) {
                                Label(sceneType.displayName, systemImage: sceneType.icon)
                            }
                        }
                    }
                }
                .chartForegroundStyleScale(
                    domain: viewModel.summary.topScenes.map { $0.sceneType.displayName },
                    range: viewModel.summary.topScenes.map { Color($0.sceneType.color) }
                )
            }
            
            // 时间范围选择器
            timeRangePicker
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var timeRangePicker: some View {
        Picker("时间范围", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerSegmented
        .onChange(of: selectedTimeRange) { newValue in
            Task {
                await viewModel.loadData(timeRange: newValue)
            }
        }
    }
    
    // MARK: - Scene Type Details
    
    private var sceneTypeDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("场景类型详情")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(DreamSceneType.allCases.prefix(12), id: \.self) { sceneType in
                    if let distribution = viewModel.summary.topScenes.first(where: { $0.sceneType == sceneType }) {
                        SceneTypeCard(
                            sceneType: sceneType,
                            count: distribution.count,
                            percentage: distribution.percentage,
                            trend: distribution.trend
                        )
                    } else {
                        SceneTypeCard(
                            sceneType: sceneType,
                            count: 0,
                            percentage: 0,
                            trend: .stable
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("场景洞察")
                .font(.headline)
            
            if viewModel.insights.isEmpty {
                Text("暂无洞察，继续记录梦境以获取更多分析")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.insights) { insight in
                    SceneAnalysisInsightCard(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Emotion Correlation Section
    
    private var emotionCorrelationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("场景 - 情绪关联")
                .font(.headline)
            
            if viewModel.correlations.isEmpty {
                Text("暂无关联数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.correlations.prefix(5), id: \.sceneType) { correlation in
                    EmotionCorrelationCard(correlation: correlation)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("记录更多梦境以获取场景分析")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

// MARK: - Supporting Views

struct SceneAnalysisStatCard: View {
    let title: String
    let value: String
    let subtitle: String
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SceneTypeCard: View {
    let sceneType: DreamSceneType
    let count: Int
    let percentage: Double
    let trend: SceneDistribution.TrendDirection
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: sceneType.icon)
                    .foregroundColor(sceneType.color)
                Text(sceneType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                trendIcon
            }
            
            HStack {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sceneType.color.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var trendIcon: some View {
        Group {
            switch trend {
            case .increasing:
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
            case .decreasing:
                Image(systemName: "arrow.down.right")
                    .foregroundColor(.red)
            case .stable:
                Image(systemName: "minus")
                    .foregroundColor(.gray)
            }
        }
        .font(.caption)
    }
}

struct SceneAnalysisInsightCard: View {
    let insight: SceneInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(insight.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                    Text(insight.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            if let suggestion = insight.suggestion {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct EmotionCorrelationCard: View {
    let correlation: SceneEmotionCorrelation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: correlation.sceneType.icon)
                .font(.title2)
                .foregroundColor(correlation.sceneType.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(correlation.sceneType.displayName) → \(correlation.emotion.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Text(correlation.correlationDescription)
                        .font(.caption)
                        .foregroundColor(correlationColor)
                    
                    Text("\(correlation.occurrenceCount) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 关联强度指示器
            CorrelationStrengthIndicator(strength: correlation.correlationStrength)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private var correlationColor: Color {
        if correlation.correlationStrength > 0.5 { return .green }
        else if correlation.correlationStrength > 0.2 { return .blue }
        else if correlation.correlationStrength > -0.2 { return .gray }
        else if correlation.correlationStrength > -0.5 { return .orange }
        else { return .red }
    }
}

struct CorrelationStrengthIndicator: View {
    let strength: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(indicatorColor)
                    .frame(width: CGFloat(abs(strength)) * 60, height: 8)
                    .offset(x: strength < 0 ? (60 - CGFloat(abs(strength)) * 60) / 2 : 0)
            }
        }
        .frame(width: 60, height: 8)
    }
    
    private var indicatorColor: Color {
        if strength > 0.5 { return .green }
        else if strength > 0.2 { return .blue }
        else if strength > -0.2 { return .gray }
        else if strength > -0.5 { return .orange }
        else { return .red }
    }
}

// MARK: - Config View

struct SceneAnalysisConfigView: View {
    @Binding var config: SceneAnalysisConfig
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("分析设置")) {
                    Toggle("自动分析新梦境", isOn: $config.autoAnalyze)
                    
                    Stepper("最低置信度：\(Int(config.minConfidence * 100))%",
                           value: $config.minConfidence,
                           in: 0.3...0.9,
                           step: 0.1)
                    
                    Toggle("显示场景洞察", isOn: $config.showInsights)
                    
                    Toggle("发现模式时通知", isOn: $config.notifyOnPattern)
                }
                
                Section(header: Text("启用的场景类型")) {
                    ForEach(DreamSceneType.allCases, id: \.self) { sceneType in
                        Toggle(sceneType.displayName, isOn: bindingFor(sceneType: sceneType))
                    }
                }
            }
            .navigationTitle("场景分析设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func bindingFor(sceneType: DreamSceneType) -> Binding<Bool> {
        Binding(
            get: { config.enabledSceneTypes.contains(sceneType) },
            set: { isEnabled in
                if isEnabled {
                    if !config.enabledSceneTypes.contains(sceneType) {
                        config.enabledSceneTypes.append(sceneType)
                    }
                } else {
                    config.enabledSceneTypes.removeAll { $0 == sceneType }
                }
            }
        )
    }
}

// MARK: - View Model

@MainActor
class DreamSceneAnalysisViewModel: ObservableObject {
    @Published var summary: SceneAnalysisSummary = SceneAnalysisSummary(
        totalDreams: 0,
        analyzedDreams: 0,
        topScenes: [],
        sceneDiversity: 0,
        favoriteScene: nil,
        rareScene: nil,
        averageConfidence: 0,
        timeRange: SceneAnalysisSummary.DateRange(startDate: Date(), endDate: Date())
    )
    @Published var insights: [SceneInsight] = []
    @Published var correlations: [SceneEmotionCorrelation] = []
    @Published var config: SceneAnalysisConfig = .default
    
    private let service = DreamSceneAnalysisService()
    
    func loadData(timeRange: DreamSceneAnalysisView.TimeRange) async {
        // 计算日期范围
        let dateRange: ClosedRange<Date>?
        if let days = timeRange.days {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            dateRange = startDate...endDate
        } else {
            dateRange = nil
        }
        
        // 加载数据
        summary = await service.getSummary(dateRange: dateRange)
        insights = await service.generateInsights()
        correlations = await service.getSceneEmotionCorrelations()
        config = await service.getConfig()
    }
}

// MARK: - Preview

#Preview {
    DreamSceneAnalysisView()
}
