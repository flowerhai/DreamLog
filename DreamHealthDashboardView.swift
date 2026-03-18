//
//  DreamHealthDashboardView.swift
//  DreamLog - 健康仪表板 UI
//
//  Phase 64: 健康集成与睡眠追踪 🍎💤
//  创建时间：2026-03-18
//

import SwiftUI
import SwiftData

// MARK: - 健康仪表板主视图

struct DreamHealthDashboardView: View {
    @Environment(ModelContext.self) var modelContext
    @State private var healthService: DreamHealthIntegrationService
    @State private var sleepSessions: [SleepSession] = []
    @State private var statistics: SleepStatistics?
    @State private var correlations: [DreamSleepCorrelation] = []
    @State private var recommendations: [DreamRecommendation] = []
    @State private var selectedPeriod: TimePeriod = .week
    @State private var isAuthorizing = false
    @State private var authorizationStatus: HealthAuthorizationStatus = .notDetermined
    @State private var showingSettings = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "7 天"
        case month = "30 天"
        case quarter = "90 天"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    init() {
        // 在实际应用中，service 会通过 environment 注入
        _healthService = State(initialValue: DreamHealthIntegrationService(modelContext: ModelContext(ModelContainer(for: SleepSession.self)!)))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 授权状态卡片
                    AuthorizationCard(
                        status: authorizationStatus,
                        isAuthorizing: isAuthorizing,
                        onAuthorize: authorizeHealthKit
                    )
                    
                    if authorizationStatus.canAccess {
                        // 睡眠概览
                        SleepOverviewCard(statistics: statistics)
                        
                        // 睡眠阶段分布
                        SleepStageDistributionCard(sessions: sleepSessions)
                        
                        // 睡眠质量趋势
                        SleepQualityTrendCard(
                            sessions: sleepSessions,
                            period: selectedPeriod
                        )
                        
                        // 梦境 - 睡眠关联
                        DreamSleepCorrelationCard(correlations: correlations)
                        
                        // 智能推荐
                        SmartRecommendationsCard(recommendations: recommendations)
                        
                        // 连续记录
                        StreakCard(statistics: statistics)
                    }
                    
                    // 周期选择器
                    PeriodSelector(selectedPeriod: $selectedPeriod)
                }
                .padding()
            }
            .navigationTitle("健康与睡眠")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                HealthSettingsView()
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    // MARK: - 数据加载
    
    private func loadData() async {
        do {
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) ?? endDate
            
            // 同步睡眠数据
            sleepSessions = try await healthService.syncSleepSessions(from: startDate, to: endDate)
            
            // 计算统计
            statistics = try await healthService.calculateSleepStatistics(from: startDate, to: endDate)
            
            // 关联分析
            correlations = try await healthService.correlateDreamsWithSleep(from: startDate, to: endDate)
            
            // 智能推荐
            if let latestSession = sleepSessions.first {
                recommendations = healthService.getDreamRecommendations(basedOn: latestSession.quality)
            }
            
            // 检查授权状态
            authorizationStatus = await healthService.checkAuthorizationStatus()
        } catch {
            print("加载健康数据失败：\(error)")
        }
    }
    
    // MARK: - HealthKit 授权
    
    private func authorizeHealthKit() {
        isAuthorizing = true
        
        Task {
            do {
                let success = try await healthService.requestAuthorization()
                authorizationStatus = success ? .sharingAuthorized : .sharingDenied
            } catch {
                print("HealthKit 授权失败：\(error)")
                authorizationStatus = .sharingDenied
            }
            
            isAuthorizing = false
            
            if authorizationStatus.canAccess {
                await loadData()
            }
        }
    }
}

// MARK: - 授权状态卡片

struct AuthorizationCard: View {
    let status: HealthAuthorizationStatus
    let isAuthorizing: Bool
    let onAuthorize: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("HealthKit 连接")
                        .font(.headline)
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if status == .notDetermined || status == .sharingDenied {
                    Button(action: onAuthorize) {
                        Text(isAuthorizing ? "授权中..." : "连接")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAuthorizing)
                } else if status.canAccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var statusIcon: String {
        switch status {
        case .notDetermined: return "heart.circle"
        case .sharingDenied: return "heart.slash"
        case .sharingAuthorized: return "heart.fill"
        case .unavailable: return "heart.slash.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .notDetermined: return .blue
        case .sharingDenied: return .red
        case .sharingAuthorized: return .green
        case .unavailable: return .gray
        }
    }
    
    private var statusDescription: String {
        switch status {
        case .notDetermined: return "连接 Apple Health 以同步睡眠数据"
        case .sharingDenied: return "请在设置中允许访问健康数据"
        case .sharingAuthorized: return "已连接，睡眠数据自动同步"
        case .unavailable: return "HealthKit 在此设备上不可用"
        }
    }
}

// MARK: - 睡眠概览卡片

struct SleepOverviewCard: View {
    let statistics: SleepStatistics?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠概览")
                .font(.headline)
            
            if let stats = statistics {
                HStack(spacing: 20) {
                    // 平均睡眠时长
                    VStack(alignment: .leading, spacing: 4) {
                        Text("平均时长")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(stats.formattedAverageDuration)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 平均质量
                    VStack(alignment: .leading, spacing: 4) {
                        Text("平均质量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: averageQualitySymbol)
                                .foregroundColor(averageQualityColor)
                            Text(stats.averageQuality.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 连续达标
                    VStack(alignment: .leading, spacing: 4) {
                        Text("连续达标")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(stats.currentStreak) 天")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var averageQualitySymbol: String {
        guard let stats = statistics else { return "moon" }
        return stats.averageQuality.symbol
    }
    
    private var averageQualityColor: Color {
        guard let stats = statistics else { return .gray }
        switch stats.averageQuality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - 睡眠阶段分布卡片

struct SleepStageDistributionCard: View {
    let sessions: [SleepSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠阶段分布")
                .font(.headline)
            
            if !sessions.isEmpty {
                // 计算平均百分比
                let avgRem = sessions.compactMap { $0.remPercentage }.average ?? 0
                let avgDeep = sessions.compactMap { $0.deepPercentage }.average ?? 0
                let avgCore = sessions.compactMap { $0.corePercentage }.average ?? 0
                let avgAwake = sessions.compactMap { $0.awakePercentage }.average ?? 0
                
                // 环形图
                SleepStageRingChart(
                    rem: avgRem,
                    deep: avgDeep,
                    core: avgCore,
                    awake: avgAwake
                )
                .frame(height: 150)
                .padding(.vertical, 8)
                
                // 图例
                HStack(spacing: 16) {
                    StageLegendItem(color: .purple, label: "REM", value: avgRem)
                    StageLegendItem(color: .blue, label: "深度", value: avgDeep)
                    StageLegendItem(color: .green, label: "核心", value: avgCore)
                    StageLegendItem(color: .orange, label: "清醒", value: avgAwake)
                }
            } else {
                Text("暂无睡眠数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 睡眠阶段环形图

struct SleepStageRingChart: View {
    let rem: Double
    let deep: Double
    let core: Double
    let awake: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: CGFloat(rem))
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: CGFloat(rem), to: CGFloat(rem + deep))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: CGFloat(rem + deep), to: CGFloat(rem + deep + core))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: CGFloat(rem + deep + core), to: CGFloat(rem + deep + core + awake))
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("睡眠")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("阶段")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 阶段图例项

struct StageLegendItem: View {
    let color: Color
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
            Text(String(format: "%.0f%%", value * 100))
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 睡眠质量趋势卡片

struct SleepQualityTrendCard: View {
    let sessions: [SleepSession]
    let period: DreamHealthDashboardView.TimePeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠质量趋势")
                .font(.headline)
            
            if !sessions.isEmpty {
                // 简化的趋势图
                SleepQualityTrendChart(sessions: sessions)
                    .frame(height: 120)
            } else {
                Text("暂无趋势数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 睡眠质量趋势图

struct SleepQualityTrendChart: View {
    let sessions: [SleepSession]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 20
            
            if sessions.count > 1 {
                Path { path in
                    let stepX = (width - padding * 2) / CGFloat(max(sessions.count - 1, 1))
                    
                    for (index, session) in sessions.enumerated() {
                        let x = padding + CGFloat(index) * stepX
                        let y = height - padding - CGFloat(session.quality.score) / 100 * (height - padding * 2)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // 数据点
                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                    let x = padding + CGFloat(index) * ((width - padding * 2) / CGFloat(max(sessions.count - 1, 1)))
                    let y = height - padding - CGFloat(session.quality.score) / 100 * (height - padding * 2)
                    
                    Circle()
                        .fill(qualityColor(session.quality))
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
    
    private func qualityColor(_ quality: SleepQuality) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - 梦境 - 睡眠关联卡片

struct DreamSleepCorrelationCard: View {
    let correlations: [DreamSleepCorrelation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("梦境 - 睡眠关联")
                .font(.headline)
            
            if !correlations.isEmpty {
                // 显示最新的关联分析
                if let latest = correlations.first {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: latest.sleepQuality.symbol)
                                .foregroundColor(qualityColor(latest.sleepQuality))
                            Text("睡眠质量：\(latest.sleepQuality.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 16) {
                            CorrelationStatItem(
                                icon: "brain.head.profile",
                                label: "梦境数",
                                value: "\(latest.dreamCount)"
                            )
                            
                            CorrelationStatItem(
                                icon: "star.fill",
                                label: "清晰度",
                                value: String(format: "%.1f", latest.averageClarity)
                            )
                            
                            CorrelationStatItem(
                                icon: "eye.fill",
                                label: "清醒梦",
                                value: "\(latest.lucidDreamCount)"
                            )
                        }
                        
                        if !latest.topEmotions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("主要情绪")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(latest.topEmotions.joined(separator: " · "))
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            } else {
                Text("暂无关联数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func qualityColor(_ quality: SleepQuality) -> Color {
        switch quality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - 关联统计项

struct CorrelationStatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
}

// MARK: - 智能推荐卡片

struct SmartRecommendationsCard: View {
    let recommendations: [DreamRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("智能推荐")
                .font(.headline)
            
            if !recommendations.isEmpty {
                VStack(spacing: 12) {
                    ForEach(recommendations, id: \.title) { recommendation in
                        RecommendationRow(recommendation: recommendation)
                    }
                }
            } else {
                Text("暂无推荐")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 推荐行

struct RecommendationRow: View {
    let recommendation: DreamRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon(recommendation.type))
                .font(.title2)
                .foregroundColor(typeColor(recommendation.type))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text(recommendation.action)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
    
    private func typeIcon(_ type: DreamRecommendationType) -> String {
        switch type {
        case .incubation: return "lightbulb.fill"
        case .lucid: return "eye.fill"
        case .exploration: return "sparkles"
        case .meditation: return "figure.mind.and.body"
        case .healing: return "heart.fill"
        case .relaxation: return "moon.zzz"
        case .recording: return "mic.fill"
        case .reflection: return "book.fill"
        }
    }
    
    private func typeColor(_ type: DreamRecommendationType) -> Color {
        switch type {
        case .incubation: return .yellow
        case .lucid: return .purple
        case .exploration: return .blue
        case .meditation: return .green
        case .healing: return .pink
        case .relaxation: return .indigo
        case .recording: return .orange
        case .reflection: return .teal
        }
    }
}

// MARK: - 连续记录卡片

struct StreakCard: View {
    let statistics: SleepStatistics?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("睡眠目标")
                .font(.headline)
            
            if let stats = statistics {
                HStack(spacing: 20) {
                    // 当前连续
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前连续")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(stats.currentStreak) 天")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 最长连续
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最长连续")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.yellow)
                            Text("\(stats.longestStreak) 天")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Spacer()
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 周期选择器

struct PeriodSelector: View {
    @Binding var selectedPeriod: DreamHealthDashboardView.TimePeriod
    
    var body: some View {
        Picker("周期", selection: $selectedPeriod) {
            ForEach(DreamHealthDashboardView.TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - 健康设置视图

struct HealthSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sleepGoal: Double = 8
    @State private var bedtimeReminder: Bool = true
    @State private var wakeUpReminder: Bool = true
    @State private var bedtime: Date = Date()
    @State private var wakeUpTime: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("睡眠目标") {
                    HStack {
                        Text("目标时长")
                        Spacer()
                        Stepper("\(Int(sleepGoal)) 小时", value: $sleepGoal, in: 4...12, step: 0.5)
                    }
                }
                
                Section("提醒设置") {
                    Toggle("睡前提醒", isOn: $bedtimeReminder)
                    if bedtimeReminder {
                        DatePicker("睡前时间", selection: $bedtime, displayedComponents: .hourAndMinute)
                    }
                    
                    Toggle("晨间记录提醒", isOn: $wakeUpReminder)
                    if wakeUpReminder {
                        DatePicker("起床时间", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("数据来源") {
                    Text("Apple Health")
                    Text("睡眠数据来自 Apple Health 应用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("健康设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DreamHealthDashboardView()
}
