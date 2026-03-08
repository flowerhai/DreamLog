//
//  SleepQualityAnalysisView.swift
//  DreamLog
//
//  睡眠质量深度分析视图 - Phase 5 智能增强功能
//

import SwiftUI
import HealthKit

// MARK: - 主视图

struct SleepQualityAnalysisView: View {
    @ObservedObject private var analysisService = SleepQualityAnalysisService.shared
    @ObservedObject private var healthKitService = HealthKitService.shared
    @State private var selectedPeriod: Int = 30
    @State private var showingRecommendations = false
    @State private var showingCorrelationDetails = false
    
    var body: some View {
        ZStack {
            if analysisService.isLoading {
                LoadingAnalysisView()
            } else if let report = analysisService.currentReport {
                AnalysisContentView(report: report)
            } else if let error = analysisService.errorMessage {
                ErrorAnalysisView(message: error) {
                    Task {
                        await analysisService.generateReport(periodDays: selectedPeriod)
                    }
                }
            } else {
                EmptyAnalysisView {
                    Task {
                        await analysisService.generateReport(periodDays: selectedPeriod)
                    }
                }
            }
        }
        .navigationTitle("睡眠质量分析")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("周期", selection: $selectedPeriod) {
                    Text("7 天").tag(7)
                    Text("14 天").tag(14)
                    Text("30 天").tag(30)
                    Text("90 天").tag(90)
                }
                .pickerStyle(.menu)
                .onChange(of: selectedPeriod) { _, newValue in
                    Task {
                        await analysisService.generateReport(periodDays: newValue)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingRecommendations = true }) {
                    Label("建议", systemImage: "lightbulb")
                }
            }
        }
        .sheet(isPresented: $showingRecommendations) {
            RecommendationsView(recommendations: analysisService.currentReport?.recommendations ?? [])
        }
        .sheet(isPresented: $showingCorrelationDetails) {
            CorrelationDetailView(correlation: analysisService.currentReport?.dreamCorrelation)
        }
        .onAppear {
            if analysisService.currentReport == nil && !analysisService.isLoading {
                Task {
                    await analysisService.generateReport(periodDays: selectedPeriod)
                }
            }
        }
        .refreshable {
            await analysisService.generateReport(periodDays: selectedPeriod)
        }
    }
}

// MARK: - 内容视图

struct AnalysisContentView: View {
    let report: SleepQualityReport
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 概览卡片
                OverviewSection(report: report)
                
                // 睡眠阶段分析
                SleepStagesSection(distribution: report.stageDistribution)
                
                // 作息时间分析
                ScheduleSection(report: report)
                
                // 睡眠质量趋势
                QualityTrendSection(report: report)
                
                // 梦境关联分析
                DreamCorrelationSection(correlation: report.dreamCorrelation) {
                    showingCorrelationDetails = true
                }
                
                // 快速建议
                QuickRecommendationsSection(recommendations: report.recommendations)
            }
            .padding()
        }
    }
}

// MARK: - 概览部分

struct OverviewSection: View {
    let report: SleepQualityReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠概览")
                .font(.headline)
            
            HStack(spacing: 12) {
                // 平均时长
                OverviewCard(
                    title: "平均时长",
                    value: formatDuration(report.averageDuration),
                    icon: "moon.fill",
                    color: .blue
                )
                
                // 睡眠效率
                OverviewCard(
                    title: "睡眠效率",
                    value: String(format: "%.0f%%", report.averageEfficiency * 100),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                // 一致性评分
                OverviewCard(
                    title: "规律性",
                    value: String(format: "%.0f", report.consistencyScore),
                    icon: "clock.fill",
                    color: .purple
                )
            }
            
            // 主导质量
            if let dominantQuality = report.dominantQuality {
                HStack {
                    Image(systemName: dominantQuality.icon)
                        .font(.title2)
                    Text("主要睡眠质量")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(dominantQuality.rawValue)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: dominantQuality.color))
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return "\(hours)h\(minutes)m"
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - 睡眠阶段部分

struct SleepStagesSection: View {
    let distribution: SleepStageDistribution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠阶段分析")
                .font(.headline)
            
            // 环形图
            SleepStageRingChart(distribution: distribution)
            
            // 详细数据
            VStack(spacing: 8) {
                StageRow(
                    name: "深度睡眠",
                    icon: "💤",
                    percent: distribution.deepSleepPercent,
                    duration: distribution.deepSleepDuration,
                    quality: distribution.deepSleepQuality,
                    color: "7E57C2"
                )
                
                StageRow(
                    name: "REM 睡眠",
                    icon: "✨",
                    percent: distribution.remSleepPercent,
                    duration: distribution.remSleepDuration,
                    quality: distribution.remSleepQuality,
                    color: "FFA726"
                )
                
                StageRow(
                    name: "核心睡眠",
                    icon: "😴",
                    percent: distribution.coreSleepPercent,
                    duration: distribution.coreSleepDuration,
                    quality: .good,
                    color: "42A5F5"
                )
                
                StageRow(
                    name: "清醒时间",
                    icon: "👁️",
                    percent: distribution.awakePercent,
                    duration: distribution.awakeDuration,
                    quality: distribution.awakePercent < 5 ? .excellent : .fair,
                    color: "EF5350"
                )
            }
            
            // 理想范围提示
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("理想范围：深度睡眠 15-25%，REM 睡眠 20-25%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct SleepStageRingChart: View {
    let distribution: SleepStageDistribution
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: CGFloat(distribution.deepSleepPercent / 100))
                .stroke(Color(hex: "7E57C2"), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Circle()
                .trim(from: CGFloat(distribution.deepSleepPercent / 100), to: CGFloat((distribution.deepSleepPercent + distribution.remSleepPercent) / 100))
                .stroke(Color(hex: "FFA726"), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack {
                Text("睡眠阶段")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f%%", distribution.deepSleepPercent + distribution.remSleepPercent))
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(height: 180)
        .padding(.vertical)
    }
}

struct StageRow: View {
    let name: String
    let icon: String
    let percent: Double
    let duration: TimeInterval
    let quality: SleepStageDistribution.SleepQualityRating
    let color: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    // 进度条
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: color))
                                .frame(width: geo.size.width * CGFloat(percent / 100), height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text(String(format: "%.1f%%", percent))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 45)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(quality.rawValue)
                    .font(.caption)
                    .foregroundColor(Color(hex: quality.color))
            }
            .frame(width: 70)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - 作息时间部分

struct ScheduleSection: View {
    let report: SleepQualityReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("作息规律性")
                .font(.headline)
            
            HStack(spacing: 16) {
                // 就寝时间
                ScheduleCard(
                    title: "平均就寝",
                    time: report.averageBedtime,
                    consistency: report.bedtimeConsistency,
                    icon: "moon.stars.fill"
                )
                
                // 起床时间
                ScheduleCard(
                    title: "平均起床",
                    time: report.averageWakeTime,
                    consistency: report.wakeTimeConsistency,
                    icon: "sun.max.fill"
                )
            }
            
            // 规律性提示
            HStack {
                Image(systemName: report.bedtimeConsistency > 0.8 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(report.bedtimeConsistency > 0.8 ? .green : .orange)
                Text(regularityMessage(report.bedtimeConsistency))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    private func regularityMessage(_ consistency: Double) -> String {
        if consistency > 0.8 {
            return "作息非常规律，继续保持！"
        } else if consistency > 0.6 {
            return "作息较为规律，可以进一步改善"
        } else {
            return "作息波动较大，建议固定睡眠时间"
        }
    }
}

struct ScheduleCard: View {
    let title: String
    let time: DateComponents
    let consistency: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(formatTime(time))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 一致性指示器
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index < Int(consistency * 5) ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatTime(_ components: DateComponents) -> String {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - 质量趋势部分

struct QualityTrendSection: View {
    let report: SleepQualityReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("质量趋势")
                .font(.headline)
            
            HStack {
                TrendIndicator(trend: report.qualityTrend)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("整体睡眠质量")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(report.qualityTrend.rawValue)
                        .font(.headline)
                }
                
                Spacer()
                
                // 质量分布
                HStack(spacing: 8) {
                    ForEach(SleepRecord.SleepQuality.allCases, id: \.self) { quality in
                        let count = report.qualityDistribution[quality] ?? 0
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color(hex: quality.color))
                                .frame(width: 12, height: 12)
                            Text("\(count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct TrendIndicator: View {
    let trend: SleepQualityReport.TrendDirection
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 50, height: 50)
            
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(foregroundColor)
        }
    }
    
    private var iconName: String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .stable: return "minus"
        case .declining: return "arrow.down.right"
        case .fluctuating: return "arrow.left.and.right"
        }
    }
    
    private var backgroundColor: Color {
        switch trend {
        case .improving: return .green.opacity(0.2)
        case .stable: return .blue.opacity(0.2)
        case .declining: return .red.opacity(0.2)
        case .fluctuating: return .orange.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .red
        case .fluctuating: return .orange
        }
    }
}

// MARK: - 梦境关联部分

struct DreamCorrelationSection: View {
    let correlation: DreamSleepCorrelation
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("梦境与睡眠关联")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onTap) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            
            Text(correlation.insight)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            HStack(spacing: 16) {
                CorrelationStatCard(
                    title: "好睡眠后梦境",
                    value: "\(correlation.bestSleepQualityDreams)",
                    subtitle: String(format: "清晰度 %.1f", correlation.averageClarityAfterGoodSleep),
                    icon: "😴",
                    color: .green
                )
                
                CorrelationStatCard(
                    title: "差睡眠后梦境",
                    value: "\(correlation.poorSleepQualityDreams)",
                    subtitle: String(format: "清晰度 %.1f", correlation.averageClarityAfterPoorSleep),
                    icon: "😫",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct CorrelationStatCard: View {
    let title: String
    let value: String
    let subtitle: String
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
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 快速建议部分

struct QuickRecommendationsSection: View {
    let recommendations: [SleepRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("优先建议")
                .font(.headline)
            
            ForEach(recommendations.prefix(3)) { recommendation in
                RecommendationRow(recommendation: recommendation)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct RecommendationRow: View {
    let recommendation: SleepRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: priorityIcon(recommendation.priority))
                .foregroundColor(Color(hex: recommendation.priority.color))
                .font(.title2)
            
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
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func priorityIcon(_ priority: SleepRecommendation.Priority) -> String {
        switch priority {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark.circle"
        case .low: return "info.circle"
        }
    }
}

// MARK: - 加载/错误/空状态视图

struct LoadingAnalysisView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在分析睡眠数据...")
                .font(.headline)
            
            Text("计算睡眠阶段、趋势和梦境关联")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorAnalysisView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("分析失败")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Label("重试", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct EmptyAnalysisView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无睡眠分析")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("需要 HealthKit 睡眠数据才能生成分析报告")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onGenerate) {
                Label("生成报告", systemImage: "sparkles")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - 建议详情视图

struct RecommendationsView: View {
    let recommendations: [SleepRecommendation]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SleepRecommendation.Category.allCases, id: \.self) { category in
                    let categoryRecs = recommendations.filter { $0.category == category }
                    if !categoryRecs.isEmpty {
                        Section(header: Text(category.rawValue)) {
                            ForEach(categoryRecs) { recommendation in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: priorityIcon(recommendation.priority))
                                            .foregroundColor(Color(hex: recommendation.priority.color))
                                        Text(recommendation.title)
                                            .fontWeight(.medium)
                                    }
                                    
                                    Text(recommendation.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if let action = recommendation.action {
                                        HStack {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(.green)
                                            Text(action)
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("睡眠建议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func priorityIcon(_ priority: SleepRecommendation.Priority) -> String {
        switch priority {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark.circle"
        case .low: return "info.circle"
        }
    }
}

// MARK: - 关联详情视图

struct CorrelationDetailView: View {
    let correlation: DreamSleepCorrelation?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let correlation = correlation {
                    Section(header: Text("关联强度")) {
                        HStack {
                            Text("整体关联")
                            Spacer()
                            Text(String(format: "%.0f%%", correlation.correlationStrength * 100))
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: correlation.correlationStrength)
                            .progressViewStyle(.linear)
                    }
                    
                    Section(header: Text("梦境清晰度")) {
                        HStack {
                            Text("优质睡眠后")
                            Spacer()
                            Text(String(format: "%.1f / 5.0", correlation.averageClarityAfterGoodSleep))
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("较差睡眠后")
                            Spacer()
                            Text(String(format: "%.1f / 5.0", correlation.averageClarityAfterPoorSleep))
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section(header: Text("清醒梦关联")) {
                        HStack {
                            Text("相关性")
                            Spacer()
                            Text(correlation.lucidDreamCorrelation > 0 ? "正相关" : "无明显关联")
                                .fontWeight(.semibold)
                        }
                        
                        Text(correlation.lucidDreamCorrelation > 0.3 ?
                             "优质睡眠可能增加清醒梦发生频率" :
                             "睡眠质量与清醒梦无明显关联")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Section(header: Text("情绪关联")) {
                        ForEach(Emotion.allCases, id: \.self) { emotion in
                            if let corr = correlation.emotionCorrelation[emotion] {
                                HStack {
                                    Text(emotion.rawValue)
                                    Spacer()
                                    Text(correlationText(corr))
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("洞察")) {
                        Text(correlation.insight)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("关联详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
    
    private func correlationText(_ value: Double) -> String {
        if value > 0.3 { return "强正相关" }
        if value > 0.1 { return "正相关" }
        if value < -0.3 { return "强负相关" }
        if value < -0.1 { return "负相关" }
        return "无关联"
    }
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 预览

#Preview {
    SleepQualityAnalysisView()
}
