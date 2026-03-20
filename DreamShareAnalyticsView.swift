//
//  DreamShareAnalyticsView.swift
//  DreamLog - 梦境分享数据分析视图
//
//  Created by DreamLog Team on 2026-03-15.
//  Phase 46: Dream Share Analytics - 分享数据分析与洞察
//

import SwiftUI
import SwiftData
import Charts

// MARK: - 主视图

struct DreamShareAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ShareAnalyticsViewModel()
    @State private var selectedPeriod: AnalyticsPeriod = .monthly
    @State private var showingInsightsSheet = false
    @State private var showingAchievementsSheet = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error: error)
                } else {
                    contentView
                }
            }
            .navigationTitle("分享分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showingInsightsSheet = true
                        } label: {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showingAchievementsSheet = true
                        } label: {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingInsightsSheet) {
                ShareInsightsView()
            }
            .sheet(isPresented: $showingAchievementsSheet) {
                ShareAchievementsView()
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载分析数据...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("正在加载")
        .accessibilityHint("等待分析数据加载完成")
    }
    
    // MARK: - Error View
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    await loadData()
                }
            } label: {
                Label("重试", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .accessibilityHint("点击重新加载数据")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 周期选择器
                periodSelector
                
                // 核心统计卡片
                statsCards
                
                // 分享趋势图表
                trendChartSection
                
                // 平台分布
                platformBreakdownSection
                
                // 时间分析
                timeAnalysisSection
                
                // 热门内容
                topContentSection
                
                // 分享成就
                achievementsPreview
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("周期", selection: $selectedPeriod) {
            Text("本周").tag(AnalyticsPeriod.weekly)
            Text("本月").tag(AnalyticsPeriod.monthly)
            Text("本年").tag(AnalyticsPeriod.yearly)
            Text("全部").tag(AnalyticsPeriod.all)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadData()
            }
        }
        .accessibilityHint("选择分析数据的时间范围")
    }
    
    // MARK: - Stats Cards
    
    private var statsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "总分享",
                value: "\(viewModel.statistics?.totalShares ?? 0)",
                icon: "square.and.arrow.up.fill",
                color: .blue
            )
            
            StatCard(
                title: "独特梦境",
                value: "\(viewModel.statistics?.uniqueDreamsShared ?? 0)",
                icon: "dream.fill",
                color: .purple
            )
            
            StatCard(
                title: "连续天数",
                value: "\(viewModel.statistics?.streakDays ?? 0)",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "最长连续",
                value: "\(viewModel.statistics?.longestStreak ?? 0)",
                icon: "fire.fill",
                color: .red
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("分享统计概览")
    }
    
    // MARK: - Trend Chart
    
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("分享趋势")
                    .font(.headline)
                Spacer()
            }
            
            if !viewModel.trendPoints.isEmpty {
                Chart(viewModel.trendPoints) { point in
                    LineMark(
                        x: .value("日期", point.date, unit: .day),
                        y: .value("分享次数", point.shareCount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor.gradient)
                    
                    AreaMark(
                        x: .value("日期", point.date, unit: .day),
                        y: .value("分享次数", point.shareCount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month(), granularity: .day)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .accessibilityLabel("分享趋势图表")
                .accessibilityHint("显示每日分享次数的变化趋势")
            } else {
                emptyChartView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Platform Breakdown
    
    private var platformBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                Text("平台分布")
                    .font(.headline)
                Spacer()
            }
            
            if let stats = viewModel.statistics, !stats.platformBreakdown.isEmpty {
                VStack(spacing: 8) {
                    ForEach(platformUsageDetails, id: \.platform.rawValue) { detail in
                        PlatformUsageRow(detail: detail, totalShares: stats.totalShares)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("平台分布列表")
            } else {
                emptyDataView(message: "暂无分享数据")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Time Analysis
    
    private var timeAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.indigo)
                Text("时间分析")
                    .font(.headline)
                Spacer()
            }
            
            if let stats = viewModel.statistics {
                VStack(spacing: 16) {
                    // 高峰时段
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📊 分享高峰时段")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            TimeBadge(
                                hour: stats.peakSharingHour,
                                label: "小时",
                                icon: "clock.fill"
                            )
                            
                            TimeBadge(
                                weekday: stats.peakSharingWeekday,
                                label: "星期",
                                icon: "calendar.fill"
                            )
                        }
                    }
                    
                    // 小时分布热力图
                    if !stats.hourlyDistribution.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("⏰ 24 小时分布")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                                ForEach(0..<24, id: \.self) { hour in
                                    HourlyHeatmapCell(
                                        hour: hour,
                                        count: stats.hourlyDistribution[hour] ?? 0,
                                        maxCount: stats.hourlyDistribution.values.max() ?? 1
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                emptyDataView(message: "暂无时间数据")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Top Content
    
    private var topContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("热门内容")
                    .font(.headline)
                Spacer()
            }
            
            if let stats = viewModel.statistics {
                VStack(spacing: 16) {
                    // 热门标签
                    if !stats.topSharedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🏷️ 热门标签")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(stats.topSharedTags.prefix(10), id: \.self) { tag in
                                    TagBadge(tag: tag)
                                }
                            }
                        }
                    }
                    
                    // 热门情绪
                    if !stats.topSharedEmotions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💭 热门情绪")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(stats.topSharedEmotions.prefix(5), id: \.self) { emotion in
                                    EmotionBadge(emotion: emotion)
                                }
                            }
                        }
                    }
                }
            } else {
                emptyDataView(message: "暂无内容数据")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Achievements Preview
    
    private var achievementsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                Text("分享成就")
                    .font(.headline)
                Spacer()
                
                Button("查看全部") {
                    showingAchievementsSheet = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if !viewModel.achievements.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.achievements.prefix(5)) { achievement in
                            AchievementPreviewCard(achievement: achievement)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("分享成就预览")
            } else {
                emptyDataView(message: "暂无成就数据")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Empty States
    
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.dashed")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("暂无数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private func emptyDataView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Load Data
    
    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await viewModel.loadStatistics(period: selectedPeriod.rawValue)
            try await viewModel.loadTrendPoints(days: 30)
            try await viewModel.loadAchievements()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    private var platformUsageDetails: [PlatformUsageDetail] {
        viewModel.platformDetails
    }
}

// MARK: - View Model

@MainActor
class ShareAnalyticsViewModel: ObservableObject {
    @Published var statistics: ShareStatistics?
    @Published var trendPoints: [ShareTrendPoint] = []
    @Published var achievements: [ShareAchievement] = []
    @Published var platformDetails: [PlatformUsageDetail] = []
    
    private let service = DreamShareAnalyticsService()
    
    func loadStatistics(period: String) async throws {
        statistics = try await service.calculateStatistics(period: period)
        platformDetails = try await service.getPlatformUsageDetails()
    }
    
    func loadTrendPoints(days: Int) async throws {
        trendPoints = try await service.getShareTrend(days: days)
    }
    
    func loadAchievements() async throws {
        achievements = try await service.getAllAchievements()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct PlatformUsageRow: View {
    let detail: PlatformUsageDetail
    let totalShares: Int
    
    var percentage: Double {
        totalShares > 0 ? Double(detail.shareCount) / Double(totalShares) * 100 : 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: detail.platform.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(detail.platform.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ProgressView(value: percentage / 100)
                    .frame(height: 6)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(detail.shareCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
        }
        .padding(.vertical, 4)
    }
}

struct TimeBadge: View {
    var hour: Int = 0
    var weekday: Int = 0
    let label: String
    let icon: String
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday
        let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) ?? Date()
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(hour > 0 ? timeString : weekdayString)
                .font(.headline)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
    }
}

struct HourlyHeatmapCell: View {
    let hour: Int
    let count: Int
    let maxCount: Int
    
    var intensity: Double {
        maxCount > 0 ? Double(count) / Double(maxCount) : 0
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(Color.accentColor.opacity(intensity))
                .frame(height: 20)
                .cornerRadius(2)
            
            Text("\(hour)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(hour)点，\(count)次分享")
    }
}

struct TagBadge: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.caption)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(6)
    }
}

struct EmotionBadge: View {
    let emotion: String
    
    var emoji: String {
        switch emotion.lowercased() {
        case "happy", "joy": return "😊"
        case "sad": return "😢"
        case "anxious", "fear": return "😰"
        case "angry": return "😠"
        case "surprised": return "😲"
        case "calm", "peaceful": return "😌"
        case "confused": return "😕"
        case "excited": return "🤩"
        default: return "💭"
        }
    }
    
    var body: some View {
        Text("\(emoji) \(emotion)")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(6)
    }
}

struct AchievementPreviewCard: View {
    let achievement: ShareAchievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? .orange : .secondary)
            
            Text(achievement.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            ProgressView(value: Double(achievement.progress) / Double(achievement.requirement))
                .frame(height: 4)
            
            Text("\(achievement.progress)/\(achievement.requirement)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 100)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Insights Sheet

struct ShareInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ShareAnalyticsViewModel()
    @State private var insights: [ShareInsight] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    List(insights) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
            .navigationTitle("智能洞察")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .task {
                await loadInsights()
            }
        }
    }
    
    private func loadInsights() async {
        isLoading = true
        do {
            let service = DreamShareAnalyticsService()
            insights = try await service.generateInsights()
        } catch {
            print("Failed to load insights: \(error)")
        }
        isLoading = false
    }
}

struct InsightRow: View {
    let insight: ShareInsight
    
    var icon: String {
        switch insight.type {
        case .bestTime: return "clock.fill"
        case .popularPlatform: return "globe"
        case .trendingTag: return "star.fill"
        case .sharingPattern: return "chart.bar.fill"
        case .improvement: return "arrow.up.right"
        case .milestone: return "trophy.fill"
        }
    }
    
    var color: Color {
        switch insight.type {
        case .bestTime: return .blue
        case .popularPlatform: return .green
        case .trendingTag: return .yellow
        case .sharingPattern: return .purple
        case .improvement: return .orange
        case .milestone: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(insight.title)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f%%", insight.confidence * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("💡 \(insight.suggestion)")
                .font(.subheadline)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Achievements Sheet

struct ShareAchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ShareAnalyticsViewModel()
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        Section("已解锁") {
                            ForEach(viewModel.achievements.filter { $0.isUnlocked }) { achievement in
                                AchievementDetailRow(achievement: achievement)
                            }
                        }
                        
                        Section("进行中") {
                            ForEach(viewModel.achievements.filter { !$0.isUnlocked }) { achievement in
                                AchievementDetailRow(achievement: achievement)
                            }
                        }
                    }
                }
            }
            .navigationTitle("分享成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .task {
                await loadAchievements()
            }
        }
    }
    
    private func loadAchievements() async {
        isLoading = true
        do {
            try await viewModel.loadAchievements()
        } catch {
            print("Failed to load achievements: \(error)")
        }
        isLoading = false
    }
}

struct AchievementDetailRow: View {
    let achievement: ShareAchievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? .orange : .secondary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.headline)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked {
                    ProgressView(value: Double(achievement.progress) / Double(achievement.requirement))
                        .frame(height: 6)
                    
                    Text("进度：\(achievement.progress)/\(achievement.requirement)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let unlockedAt = achievement.unlockedAt {
                    Text("解锁于：\(unlockedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DreamShareAnalyticsView()
    }
    .modelContainer(for: [Dream.self, ShareHistory.self, ShareStatistics.self])
}
