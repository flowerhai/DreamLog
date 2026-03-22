//
//  DreamScreenTimeView.swift
//  DreamLog
//
//  Phase 93: 屏幕时间追踪界面
//  数字健康与梦境质量关联分析
//

import SwiftUI

// MARK: - 主视图

struct DreamScreenTimeView: View {
    @StateObject private var service = DreamScreenTimeService.shared
    @State private var selectedDate = Date()
    @State private var showSettings = false
    @State private var showCorrelationDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 快速统计卡片
                    quickStatsCard
                    
                    // 今日屏幕时间
                    todayScreenTimeCard
                    
                    // 睡前使用警告
                    if let beforeBedWarning = beforeBedWarning {
                        beforeBedAlertCard(warning: beforeBedWarning)
                    }
                    
                    // 梦境质量关联
                    correlationCard
                    
                    // 本周趋势
                    weeklyTrendCard
                    
                    // 数字健康目标
                    wellnessGoalsCard
                    
                    // 成就徽章
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("屏幕时间")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                DigitalWellnessSettingsView()
            }
        }
        .task {
            await service.updateTodayStats()
            await service.analyzeCorrelations()
        }
    }
    
    // MARK: - 快速统计卡片
    
    private var quickStatsCard: some View {
        VStack(spacing: 15) {
            HStack {
                Text("快速统计")
                    .font(.headline)
                Spacer()
                if let quickStats = service.quickStats {
                    Text("今日 \(formatDuration(quickStats.todayTotalDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let quickStats = service.quickStats {
                HStack(spacing: 15) {
                    StatBox(
                        title: "今日使用",
                        value: formatDuration(quickStats.todayTotalDuration),
                        icon: "phone.fill",
                        color: .blue
                    )
                    
                    StatBox(
                        title: "睡前使用",
                        value: formatDuration(quickStats.beforeBedDuration),
                        icon: "moon.fill",
                        color: quickStats.beforeBedMinutes > 30 ? .orange : .green
                    )
                    
                    StatBox(
                        title: "启动次数",
                        value: "\(quickStats.pickups)",
                        icon: "hand.raised.fill",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 今日屏幕时间卡片
    
    private var todayScreenTimeCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("今日屏幕时间")
                .font(.headline)
            
            if let stats = service.todayStats {
                // 总时长进度条
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("总使用时长")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(stats.totalDuration))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(gradientForDuration(stats.totalDuration))
                                .frame(width: min(CGFloat(stats.totalDuration / 3600 / 6) * geometry.size.width, geometry.size.width), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("目标：6 小时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 分类统计
                VStack(alignment: .leading, spacing: 10) {
                    Text("分类统计")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(categoryBreakdown(stats), id: \.category) { item in
                        CategoryRow(
                            category: item.category,
                            duration: item.duration,
                            percentage: item.percentage,
                            totalDuration: stats.totalDuration
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 睡前使用警告
    
    @ViewBuilder
    private var beforeBedWarning: BeforeBedWarning? {
        guard let stats = service.todayStats else { return nil }
        let beforeBedMinutes = Int(stats.beforeBedDuration / 60)
        
        if beforeBedMinutes > 60 {
            return BeforeBedWarning(
                level: .high,
                minutes: beforeBedMinutes,
                message: "睡前屏幕使用过长，可能影响睡眠质量"
            )
        } else if beforeBedMinutes > 30 {
            return BeforeBedWarning(
                level: .medium,
                minutes: beforeBedMinutes,
                message: "睡前屏幕使用适中，建议减少"
            )
        }
        return nil
    }
    
    private func beforeBedAlertCard(warning: BeforeBedWarning) -> some View {
        HStack(spacing: 12) {
            Image(systemName: warning.icon)
                .font(.title2)
                .foregroundColor(warning.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(warning.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(warning.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(warning.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 梦境质量关联卡片
    
    private var correlationCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("屏幕时间与梦境质量")
                    .font(.headline)
                Spacer()
                Button(action: { showCorrelationDetails = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            if let correlation = service.correlation {
                VStack(spacing: 12) {
                    // 关联强度指示器
                    HStack {
                        Text("关联强度")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(correlation.strengthDescription)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(correlation.color)
                    }
                    
                    // 影响说明
                    Text(correlation.impactDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    // 建议
                    if !correlation.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("💡 建议")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            ForEach(correlation.recommendations.prefix(2), id: \.self) { rec in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .foregroundColor(.blue)
                                    Text(rec)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .sheet(isPresented: $showCorrelationDetails) {
            CorrelationDetailsView()
        }
    }
    
    // MARK: - 本周趋势卡片
    
    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("本周趋势")
                .font(.headline)
            
            if let report = service.weeklyReport {
                // 简易图表
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(report.dailyStats.prefix(7), id: \.date) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(barColorForDuration(day.totalDuration))
                                .frame(width: 30, height: min(CGFloat(day.totalDuration / 3600) * 40, 120))
                            
                            Text(dayOfWeek(day.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 140)
                
                // 周统计
                HStack {
                    VStack(alignment: .leading) {
                        Text("周平均")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(report.averageDailyDuration))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("vs 上周")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(report.weekOverWeekChange)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(report.trendColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 数字健康目标
    
    private var wellnessGoalsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("数字健康目标")
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    Text("编辑")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 12) {
                GoalRow(
                    title: "每日屏幕时间",
                    current: service.quickStats?.todayTotalDuration ?? 0,
                    target: Double(service.settings.dailyLimitMinutes * 60),
                    unit: "秒"
                )
                
                GoalRow(
                    title: "睡前不使用",
                    current: Double(service.todayStats?.beforeBedDuration ?? 0),
                    target: 0,
                    unit: "秒",
                    inverse: true
                )
                
                GoalRow(
                    title: "每日启动次数",
                    current: Double(service.quickStats?.pickups ?? 0),
                    target: Double(service.settings.pickupLimit),
                    unit: "次"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 成就徽章
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("成就徽章")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(service.achievements.prefix(5), id: \.id) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                    
                    if service.achievements.count > 5 {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("+\(service.achievements.count - 5)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                )
                            Text("更多")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func categoryBreakdown(_ stats: DailyScreenTimeStats) -> [(category: ScreenTimeCategory, duration: TimeInterval, percentage: Double)] {
        return stats.categoryBreakdown
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, duration: $0.value, percentage: $0.value / stats.totalDuration * 100) }
    }
    
    private func gradientForDuration(_ duration: TimeInterval) -> LinearGradient {
        let hours = duration / 3600
        if hours < 2 {
            return LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        } else if hours < 4 {
            return LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private func barColorForDuration(_ duration: TimeInterval) -> Color {
        let hours = duration / 3600
        if hours < 2 {
            return .green
        } else if hours < 4 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 辅助视图

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CategoryRow: View {
    let category: ScreenTimeCategory
    let duration: TimeInterval
    let percentage: Double
    let totalDuration: TimeInterval
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .foregroundColor(Color(hex: category.color))
                    Text(category.displayName)
                        .font(.subheadline)
                }
                
                Spacer()
                
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("(\(Int(percentage))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: category.color))
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct GoalRow: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    var inverse: Bool = false
    
    private var percentage: Double {
        guard target > 0 else { return 0 }
        return min(current / target * 100, 100)
    }
    
    private var isCompleted: Bool {
        if inverse {
            return current <= target
        } else {
            return current >= target
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(formatValue(current))/\(formatValue(target)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isCompleted ? .green : .blue)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if unit == "秒" {
            return String(format: "%.1f", value / 60) + "分钟"
        }
        return String(format: "%.0f", value)
    }
}

struct AchievementBadge: View {
    let achievement: ScreenTimeAchievement
    
    var body: some View {
        VStack(spacing: 6) {
            Text(achievement.icon)
                .font(.title)
            
            Text(achievement.name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 60, height: 70)
        .background(achievement.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct BeforeBedWarning {
    enum Level {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .yellow
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "moon.stars.fill"
            case .medium: return "exclamationmark.moon.fill"
            case .high: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    let level: Level
    let minutes: Int
    let message: String
    
    var title: String {
        switch level {
        case .low: return "注意睡前屏幕使用"
        case .medium: return "睡前屏幕使用过长"
        case .high: return "睡前屏幕使用严重超标"
        }
    }
    
    var color: Color { level.color }
    var icon: String { level.icon }
}

// MARK: - 预览

#Preview {
    DreamScreenTimeView()
}
