//
//  InsightsView.swift
//  DreamLog
//
//  洞察页面 - 梦境统计和模式分析
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var hapticService: DreamHapticFeedback
    
    var stats: DreamStatistics {
        dreamStore.getStatistics()
    }
    
    var patterns: [DreamPattern] {
        dreamStore.findPatterns()
    }
    
    var hasNoDreams: Bool {
        dreamStore.dreams.isEmpty
    }
    
    var body: some View {
        NavigationView {
            if hasNoDreams {
                // 空状态 - 需要更多梦境才能生成洞察
                DreamInsightsEmptyView(
                    dreamCount: 0,
                    onDismiss: {
                        hapticService.trigger(.selection)
                    }
                )
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                    // AI 趋势分析入口 ✨ NEW
                    NavigationLink(destination: DreamTrendView().environmentObject(dreamStore)) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "crystal.ball.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("AI 梦境趋势")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                
                                Text("发现你的梦境模式和未来预测")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 梦境时间轴入口 ✨ NEW (Phase 6)
                    NavigationLink(destination: DreamTimelineView().environmentObject(dreamStore)) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.teal],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "timeline.selection")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("梦境时间轴")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                
                                Text("可视化你的梦境分布和密度")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 梦境关联图谱入口 ✨ NEW
                    NavigationLink(destination: DreamGraphView().environmentObject(dreamStore)) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "network")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("梦境关联图谱")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                
                                Text("可视化梦境之间的隐藏关联")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 睡眠质量深度分析入口 ✨ NEW
                    NavigationLink(destination: SleepQualityAnalysisView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.green],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "moon.zzz.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("睡眠质量分析")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                                
                                Text("HealthKit 深度分析与梦境关联")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
