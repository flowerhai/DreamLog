//
//  InsightsView.swift
//  DreamLog
//
//  洞察页面 - 梦境统计和模式分析
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var stats: DreamStatistics {
        dreamStore.getStatistics()
    }
    
    var patterns: [DreamPattern] {
        dreamStore.findPatterns()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 统计卡片
                    StatsOverviewSection(stats: stats)
                    
                    // 情绪分布
                    EmotionDistributionSection(stats: stats)
                    
                    // 热门标签
                    TopTagsSection(stats: stats)
                    
                    // 时间段分析
                    TimeAnalysisSection(stats: stats)
                    
                    // 梦境模式
                    PatternSection(patterns: patterns)
                    
                    // 图表入口
                    ChartsEntrySection()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("梦境洞察 📊")
        }
    }
}

// MARK: - 统计概览
struct StatsOverviewSection: View {
    let stats: DreamStatistics
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "总梦境",
                value: "\(stats.totalDreams)",
                icon: "🌙",
                color: Color(hex: "6B4E9A")
            )
            
            StatCard(
                title: "清醒梦",
                value: "\(stats.lucidDreams)",
                icon: "✨",
                color: Color(hex: "FFD700")
            )
            
            StatCard(
                title: "平均清晰",
                value: String(format: "%.1f", stats.averageClarity),
                icon: "⭐",
                color: Color(hex: "6BB6FF")
            )
        }
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 32))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.2))
        )
    }
}

// MARK: - 情绪分布
struct EmotionDistributionSection: View {
    let stats: DreamStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("情绪分布")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(Array(stats.topEmotions.prefix(5)), id: \.emotion) { item in
                HStack {
                    Text(item.emotion.icon)
                        .font(.system(size: 20))
                    Text(item.emotion.rawValue)
                        .font(.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(item.count)次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 热门标签
struct TopTagsSection: View {
    let stats: DreamStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门标签")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(Array(stats.topTags.prefix(5)), id: \.tag) { item in
                HStack {
                    Text("#\(item.tag)")
                        .font(.body)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Text("\(item.count)次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 时间段分析
struct TimeAnalysisSection: View {
    let stats: DreamStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("做梦时间段")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(TimeOfDay.allCases, id: \.self) { time in
                    VStack(spacing: 4) {
                        Text("\(stats.dreamsByTimeOfDay[time] ?? 0)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(time.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 梦境模式
struct PatternSection: View {
    let patterns: [DreamPattern]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("发现的梦境模式 💡")
                .font(.headline)
                .foregroundColor(.white)
            
            if patterns.isEmpty {
                Text("继续记录梦境，发现更多模式")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(patterns) { pattern in
                    PatternCard(pattern: pattern)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 模式卡片
struct PatternCard: View {
    let pattern: DreamPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.pattern)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(pattern.frequency)次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(pattern.insight)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            Text("最近：\(pattern.lastOccurrence.formatted(.dateTime.month().day()))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 图表入口
struct ChartsEntrySection: View {
    var body: some View {
        NavigationLink(destination: ChartsView()) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text("查看详细图表")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("情绪饼图 · 趋势折线图 · 分布柱状图 · 热力图")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.15))
            )
        }
    }
}

#Preview {
    InsightsView()
        .environmentObject(DreamStore())
}
