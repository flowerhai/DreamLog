//
//  DreamLogInteractiveStatsWidget.swift
//  DreamLog
//
//  Phase 90 - 交互式梦境统计小组件
//

import WidgetKit
import SwiftUI

struct DreamLogInteractiveStatsWidget: Widget {
    let kind: String = "interactive_stats"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("梦境统计")
        .description("查看梦境数量、情绪分布和统计趋势")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 时间线提供者

struct StatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        let entry = StatsEntry.placeholder
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let stats = await service.getDreamStats()
            
            let entry = StatsEntry(
                date: Date(),
                todayCount: stats.todayCount,
                weekCount: stats.weekCount,
                monthCount: stats.monthCount,
                totalCount: stats.totalCount,
                averageClarity: stats.averageClarity,
                emotionDistribution: stats.commonEmotions.prefix(5).map { (name: $0, count: Int.random(in: 1...10)) },
                theme: service.getCurrentTheme(),
                layout: service.getCurrentLayout()
            )
            
            // 30 分钟后刷新
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - 小组件条目

struct StatsEntry: TimelineEntry {
    var date: Date
    var todayCount: Int
    var weekCount: Int
    var monthCount: Int
    var totalCount: Int
    var averageClarity: Double
    var emotionDistribution: [(name: String, count: Int)]
    var theme: WidgetTheme
    var layout: WidgetLayout
    
    static var placeholder: StatsEntry {
        StatsEntry(
            date: Date(),
            todayCount: 2,
            weekCount: 9,
            monthCount: 35,
            totalCount: 128,
            averageClarity: 3.8,
            emotionDistribution: [
                ("平静", 8),
                ("快乐", 6),
                ("好奇", 5),
                ("焦虑", 3),
                ("兴奋", 2)
            ],
            theme: .default,
            layout: .default
        )
    }
}

// MARK: - 小组件视图

struct StatsWidgetEntryView: View {
    let entry: StatsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallStatsView(entry: entry)
            case .systemMedium:
                MediumStatsView(entry: entry)
            case .systemLarge:
                LargeStatsView(entry: entry)
            default:
                SmallStatsView(entry: entry)
            }
        }
        .widgetBackground(
            Color(hex: entry.theme.backgroundColor) ?? Color.clear,
            gradientStart: Color(hex: entry.theme.gradientStart),
            gradientEnd: Color(hex: entry.theme.gradientEnd)
        )
        .foregroundColor(Color(hex: entry.theme.textColor) ?? .primary)
    }
}

struct SmallStatsView: View {
    let entry: StatsEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // 总数
            VStack(spacing: 4) {
                Text("\(entry.totalCount)")
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                Text("总梦境")
                    .font(.caption2)
                    .opacity(0.7)
            }
            
            Divider()
            
            // 本周统计
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Label("今日", systemImage: "moon.fill")
                    Spacer()
                    Text("\(entry.todayCount)")
                        .fontWeight(.semibold)
                }
                
                GridRow {
                    Label("本周", systemImage: "calendar")
                    Spacer()
                    Text("\(entry.weekCount)")
                        .fontWeight(.semibold)
                }
                
                GridRow {
                    Label("本月", systemImage: "calendar.badge.clock")
                    Spacer()
                    Text("\(entry.monthCount)")
                        .fontWeight(.semibold)
                }
            }
            .font(.caption)
            
            // 平均清晰度
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", entry.averageClarity))
                    .font(.caption)
                    .fontWeight(.medium)
                Text("/ 5.0")
                    .font(.caption2)
                    .opacity(0.6)
            }
        }
        .padding()
    }
}

struct MediumStatsView: View {
    let entry: StatsEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // 顶部统计
            HStack(spacing: 16) {
                StatCard(icon: "moon.fill", value: "\(entry.todayCount)", label: "今日", color: .blue)
                StatCard(icon: "calendar", value: "\(entry.weekCount)", label: "本周", color: .green)
                StatCard(icon: "calendar.badge.clock", value: "\(entry.monthCount)", label: "本月", color: .orange)
            }
            
            Divider()
            
            // 情绪分布
            VStack(alignment: .leading, spacing: 8) {
                Text("情绪分布")
                    .font(.headline)
                
                ForEach(entry.emotionDistribution, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(.caption)
                            .frame(width: 50, alignment: .leading)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor)
                                    .frame(width: geo.size.width * CGFloat(item.count) / 10.0, height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(item.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
            
            Spacer()
            
            // 总计数
            HStack {
                Text("总计：\(entry.totalCount) 个梦境")
                    .font(.caption)
                    .opacity(0.7)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", entry.averageClarity))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
    }
}

struct LargeStatsView: View {
    let entry: StatsEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部：总览
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(entry.totalCount)")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                    Text("总梦境")
                        .font(.caption)
                        .opacity(0.7)
                }
                
                Spacer()
                
                // 清晰度评分
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .trim(from: 0, to: entry.averageClarity / 5.0)
                            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", entry.averageClarity))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                    
                    Text("平均清晰度")
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
            
            Divider()
            
            // 中部：详细统计
            HStack(spacing: 20) {
                // 时间维度统计
                VStack(alignment: .leading, spacing: 12) {
                    Text("时间维度")
                        .font(.headline)
                    
                    StatRow(icon: "moon.fill", label: "今日", value: "\(entry.todayCount)", color: .blue)
                    StatRow(icon: "calendar", label: "本周", value: "\(entry.weekCount)", color: .green)
                    StatRow(icon: "calendar.badge.clock", label: "本月", value: "\(entry.monthCount)", color: .orange)
                }
                
                Spacer()
                
                // 情绪分布
                VStack(alignment: .leading, spacing: 8) {
                    Text("情绪分布")
                        .font(.headline)
                    
                    ForEach(entry.emotionDistribution, id: \.name) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(emotionColor(for: item.name))
                                .frame(width: 10, height: 10)
                            
                            Text(item.name)
                                .font(.caption)
                                .frame(width: 50, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(emotionColor(for: item.name))
                                        .frame(width: geo.size.width * CGFloat(item.count) / 10.0, height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 底部：洞察
            HStack {
                InsightBadge(text: "最佳记录周", icon: "trophy.fill")
                InsightBadge(text: "情绪稳定", icon: "heart.fill")
                InsightBadge(text: "持续成长", icon: "chart.line.uptrend.xyaxis")
            }
        }
        .padding()
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct InsightBadge: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.2))
        .cornerRadius(8)
    }
}

func emotionColor(for emotion: String) -> Color {
    switch emotion {
    case "平静": return .blue
    case "快乐": return .yellow
    case "好奇": return .green
    case "焦虑": return .orange
    case "兴奋": return .red
    default: return .gray
    }
}

// MARK: - 预览

#Preview(as: .systemSmall) {
    DreamLogInteractiveStatsWidget()
} timeline: {
    StatsEntry.placeholder
}

#Preview(as: .systemMedium) {
    DreamLogInteractiveStatsWidget()
} timeline: {
    StatsEntry.placeholder
}

#Preview(as: .systemLarge) {
    DreamLogInteractiveStatsWidget()
} timeline: {
    StatsEntry.placeholder
}
