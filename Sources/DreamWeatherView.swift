//
//  DreamWeatherView.swift
//  DreamLog
//
//  Phase 66: Dream Weather & Environmental Correlation Dashboard
//  Visualizing how weather and moon phases affect dreams
//

import SwiftUI
import SwiftData
import Charts

struct DreamWeatherView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamWeatherService?
    @State private var statistics: DreamWeatherStatistics?
    @State private var isLoading = false
    @State private var selectedDateRange: DateRange = .last30Days
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum DateRange: String, CaseIterable {
        case last7Days = "最近 7 天"
        case last30Days = "最近 30 天"
        case last90Days = "最近 90 天"
        case lastYear = "最近 1 年"
        case all = "全部"
        
        var dateRange: ClosedRange<Date>? {
            let now = Date()
            switch self {
            case .last7Days:
                return Calendar.current.date(byAdding: .day, value: -7, to: now)!...now
            case .last30Days:
                return Calendar.current.date(byAdding: .day, value: -30, to: now)!...now
            case .last90Days:
                return Calendar.current.date(byAdding: .day, value: -90, to: now)!...now
            case .lastYear:
                return Calendar.current.date(byAdding: .year, value: -1, to: now)!...now
            case .all:
                return nil
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let stats = statistics {
                    contentView(stats)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("梦境天气")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("时间范围", selection: $selectedDateRange) {
                            ForEach(DateRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                initializeService()
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("分析环境数据中...")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.rain")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无天气数据")
                .font(.title2)
                .fontWeight(.semibold)
            Text("开始记录梦境，我们将自动分析天气与梦境的关联")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("刷新") {
                refresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func contentView(_ stats: DreamWeatherStatistics) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overview Cards
                overviewCards(stats)
                
                // Weather Distribution
                if !stats.weatherDistribution.isEmpty {
                    weatherDistributionCard(stats)
                }
                
                // Moon Phase Distribution
                if !stats.moonPhaseDistribution.isEmpty {
                    moonPhaseDistributionCard(stats)
                }
                
                // Top Correlations
                if !stats.topCorrelations.isEmpty {
                    correlationsCard(stats)
                }
                
                // Moon Correlations
                if !stats.moonCorrelations.isEmpty {
                    moonCorrelationsCard(stats)
                }
                
                // Insights
                if !stats.insights.isEmpty {
                    insightsCard(stats)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Card Views
    
    @ViewBuilder
    private func overviewCards(_ stats: DreamWeatherStatistics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "有天气数据的梦境",
                    value: "\(stats.totalDreamsWithWeather)",
                    icon: "cloud.sun",
                    color: .blue
                )
                
                StatCard(
                    title: "平均温度",
                    value: stats.averageTemperature.map { String(format: "%.1f°C", $0) } ?? "N/A",
                    icon: "thermometer.medium",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "平均湿度",
                    value: stats.averageHumidity.map { String(format: "%.0f%%", $0) } ?? "N/A",
                    icon: "drop",
                    color: .cyan
                )
                
                StatCard(
                    title: "平均气压",
                    value: stats.averagePressure.map { String(format: "%.0f hPa", $0) } ?? "N/A",
                    icon: "gauge.medium",
                    color: .purple
                )
            }
        }
    }
    
    @ViewBuilder
    private func weatherDistributionCard(_ stats: DreamWeatherStatistics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("天气分布")
                    .font(.headline)
                
                Chart {
                    ForEach(stats.weatherDistribution.sorted(by: >), id: \.key) { condition, count in
                        BarMark(
                            x: .value("天气", condition.displayName),
                            y: .value("梦境数", count)
                        )
                        .foregroundStyle(by: .value("天气", condition.displayName))
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartLegend(position: .hidden)
                
                // Top weather condition
                if let topWeather = stats.weatherConditionWithMostDreams {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("您记录梦境最多的天气：\(topWeather.icon) \(topWeather.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func moonPhaseDistributionCard(_ stats: DreamWeatherStatistics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("月相分布")
                    .font(.headline)
                
                Chart {
                    ForEach(stats.moonPhaseDistribution.sorted(by: >), id: \.key) { phase, count in
                        SectorMark(
                            angle: .value("梦境数", count),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("月相", phase.displayName))
                        .annotation(position: .overlay) {
                            Text(phase.icon)
                                .font(.caption)
                        }
                    }
                }
                .frame(height: 200)
                
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.yellow)
                    Text("满月期间清醒梦最多")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func correlationsCard(_ stats: DreamWeatherStatistics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("天气 - 梦境关联")
                    .font(.headline)
                
                ForEach(stats.topCorrelations, id: \.weatherCondition) { correlation in
                    WeatherCorrelationRow(correlation: correlation)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func moonCorrelationsCard(_ stats: DreamWeatherStatistics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("月相 - 梦境关联")
                    .font(.headline)
                
                ForEach(stats.moonCorrelations, id: \.moonPhase) { correlation in
                    MoonCorrelationRow(correlation: correlation)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func insightsCard(_ stats: DreamWeatherStatistics) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("环境洞察")
                    .font(.headline)
                
                ForEach(stats.insights, id: \.id) { insight in
                    InsightRow(insight: insight)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func initializeService() {
        service = DreamWeatherService(modelContext: modelContext)
    }
    
    private func refresh() {
        isLoading = true
        Task {
            do {
                guard let service = service else { return }
                
                let dateRange: ClosedRange<Date>
                if let range = selectedDateRange.dateRange {
                    dateRange = range
                } else {
                    // For "all", use a very wide range
                    let calendar = Calendar.current
                    let past = calendar.date(byAdding: .year, value: -10, to: Date())!
                    dateRange = past...Date()
                }
                
                let stats = try await service.getStatistics(dateRange: dateRange)
                
                await MainActor.run {
                    statistics = stats
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

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct WeatherCorrelationRow: View {
    let correlation: DreamWeatherCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(correlation.weatherCondition.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(correlation.weatherCondition.displayName)
                        .font(.headline)
                    Text("\(correlation.dreamCount) 个梦境 • 清晰度 \(String(format: "%.1f", correlation.averageClarity))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CorrelationBadge(strength: correlation.correlationStrength)
            }
            
            if !correlation.commonTags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                    ForEach(correlation.commonTags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct MoonCorrelationRow: View {
    let correlation: DreamMoonCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(correlation.moonPhase.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(correlation.moonPhase.displayName)
                        .font(.headline)
                    Text("\(correlation.dreamCount) 个梦境 • 清醒梦 \(String(format: "%.0f%%", correlation.lucidDreamRate * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CorrelationBadge(strength: correlation.correlationStrength)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CorrelationBadge: View {
    let strength: DreamWeatherCorrelation.CorrelationStrength
    
    var body: some View {
        Text(strength.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: strength.color).opacity(0.2))
            .foregroundColor(Color(hex: strength.color))
            .cornerRadius(4)
    }
}

struct InsightRow: View {
    let insight: DreamEnvironmentalInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insightTypeIcon(insight.type))
                    .foregroundColor(.blue)
                Text(insight.title)
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.0f", insight.confidence * 100))% 置信度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !insight.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(insight.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(rec)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func insightTypeIcon(_ type: DreamEnvironmentalInsight.InsightType) -> String {
        switch type {
        case .weatherPattern: return "cloud.sun"
        case .moonInfluence: return "moon.stars.fill"
        case .seasonalTrend: return "calendar"
        case .pressureEffect: return "gauge.medium"
        case .temperatureEffect: return "thermometer.medium"
        case .precipitationEffect: return "drop"
        }
    }
}

// MARK: - Preview

#Preview {
    DreamWeatherView()
        .modelContainer(for: Dream.self, inMemory: true)
}
