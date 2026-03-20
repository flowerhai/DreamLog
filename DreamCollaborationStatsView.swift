//
//  DreamCollaborationStatsView.swift
//  DreamLog - 协作统计 UI
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import SwiftUI
import Charts

// MARK: - 协作统计视图

struct DreamCollaborationStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamCollaborationSession.createdAt, order: .reverse)
    private var sessions: [DreamCollaborationSession]
    
    @State private var selectedPeriod: StatsPeriod = .month
    @State private var showDetail = false
    
    var currentUserId: String {
        UserDefaults.standard.string(forKey: "dreamlog_current_user_id") ?? "unknown"
    }
    
    var userSessions: [DreamCollaborationSession] {
        sessions.filter { $0.createdBy == currentUserId }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 周期选择器
                    periodSelector
                    
                    // 概览统计
                    overviewStats
                    
                    // 图表区域
                    chartsSection
                    
                    // 最近会话
                    recentSessions
                    
                    // 成就进度
                    achievementProgress
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("协作统计")
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("周期", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerType(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Overview Stats
    
    private var overviewStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            OverviewStatCard(
                icon: "📝",
                title: "总会话",
                value: "\(userSessions.count)",
                trend: "+2",
                color: .blue
            )
            
            OverviewStatCard(
                icon: "💡",
                title: "总解读",
                value: "\(totalInterpretations)",
                trend: "+5",
                color: .purple
            )
            
            OverviewStatCard(
                icon: "✅",
                title: "采纳解读",
                value: "\(adoptedInterpretations)",
                trend: "+1",
                color: .green
            )
            
            OverviewStatCard(
                icon: "👥",
                title: "参与人数",
                value: "\(totalParticipants)",
                trend: "+3",
                color: .orange
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(spacing: 16) {
            // 会话趋势图
            sessionTrendChart
            
            // 参与度分布
            participationDistribution
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Session Trend Chart
    
    private var sessionTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("会话趋势")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(sessionTrendData, id: \.date) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("数量", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("日期", item.date),
                        y: .value("数量", item.count)
                    )
                    .foregroundStyle(Color.blue.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7))
                }
            } else {
                Text("图表需要 iOS 16.0+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
    }
    
    // MARK: - Participation Distribution
    
    private var participationDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参与度分布")
                .font(.headline)
            
            VStack(spacing: 8) {
                ParticipationBar(
                    role: "创建者",
                    count: userSessions.count,
                    total: userSessions.count,
                    color: .blue
                )
                
                ParticipationBar(
                    role: "参与者",
                    count: totalParticipations,
                    total: totalParticipations + userSessions.count,
                    color: .green
                )
                
                ParticipationBar(
                    role: "观察者",
                    count: 0,
                    total: totalParticipations + userSessions.count,
                    color: .gray
                )
            }
        }
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近会话")
                    .font(.headline)
                
                Spacer()
                
                Button("查看全部") {
                    showDetail.toggle()
                }
                .font(.caption)
            }
            
            VStack(spacing: 8) {
                ForEach(userSessions.prefix(3), id: \.id) { session in
                    RecentSessionRow(session: session)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Achievement Progress
    
    private var achievementProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就进度")
                .font(.headline)
            
            VStack(spacing: 12) {
                AchievementProgressRow(
                    icon: "📝",
                    title: "会话达人",
                    current: userSessions.count,
                    target: 10,
                    color: .blue
                )
                
                AchievementProgressRow(
                    icon: "💡",
                    title: "解读大师",
                    current: totalInterpretations,
                    target: 50,
                    color: .purple
                )
                
                AchievementProgressRow(
                    icon: "✅",
                    title: "被采纳",
                    current: adoptedInterpretations,
                    target: 10,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Computed Properties
    
    private var totalInterpretations: Int {
        userSessions.reduce(0) { $0 + $1.interpretationCount }
    }
    
    private var adoptedInterpretations: Int {
        userSessions.reduce(0) { $0 + $1.adoptedCount }
    }
    
    private var totalParticipants: Int {
        userSessions.reduce(0) { $0 + $1.participantCount }
    }
    
    private var totalParticipations: Int {
        // 计算参与的会话数量（非创建的）
        let allSessions = sessions
        let participatedSessions = allSessions.filter { session in
            session.participants.contains { $0.userId == currentUserId }
        }
        return participatedSessions.count
    }
    
    private var sessionTrendData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        
        // 根据选择的周期计算天数
        let days: Int
        switch selectedPeriod {
        case .week: days = 7
        case .month: days = 30
        case .year: days = 365
        }
        
        // 生成趋势数据
        var trendData: [(date: Date, count: Int)] = []
        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let count = userSessions.filter { session in
                calendar.isDate(session.createdAt, inSameDayAs: date)
            }.count
            trendData.append((date: startOfDay, count: count))
        }
        
        return trendData
    }
}

// MARK: - Supporting Types

enum StatsPeriod: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case year = "本年"
    case all = "全部"
}

// MARK: - Supporting Views

struct OverviewStatCard: View {
    let icon: String
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.title2)
                Spacer()
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ParticipationBar: View {
    let role: String
    let count: Int
    let total: Int
    let color: Color
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(role)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct RecentSessionRow: View {
    let session: DreamCollaborationSession
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(session.interpretationCount)", systemImage: "text.bubble")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label("\(session.participantCount)", systemImage: "person.2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(session.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch session.status {
        case .active: return .green
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}

struct AchievementProgressRow: View {
    let icon: String
    let title: String
    let current: Int
    let target: Int
    let color: Color
    
    var percentage: Double {
        min(1.0, Double(current) / Double(target))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(current)/\(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview

#Preview {
    DreamCollaborationStatsView()
}
