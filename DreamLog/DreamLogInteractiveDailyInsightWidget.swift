//
//  DreamLogInteractiveDailyInsightWidget.swift
//  DreamLog
//
//  Phase 90 - 交互式每日洞察小组件
//

import WidgetKit
import SwiftUI

struct DreamLogInteractiveDailyInsightWidget: Widget {
    let kind: String = "daily_insight"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyInsightProvider()) { entry in
            DailyInsightWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("每日洞察")
        .description("查看今日梦境关键词、情绪趋势和连续记录天数")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 时间线提供者

struct DailyInsightProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyInsightEntry {
        DailyInsightEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DailyInsightEntry) -> Void) {
        let entry = DailyInsightEntry.placeholder
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyInsightEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            
            let stats = await service.getDreamStats()
            let mood = await service.getMoodTracking()
            let streak = await service.getStreakData()
            
            let entry = DailyInsightEntry(
                date: Date(),
                keywords: stats.commonEmotions.prefix(3).map { String($0.prefix(4)) },
                currentMood: mood.currentMood,
                moodTrend: mood.commonMoods.keys.prefix(3).map { String($0.prefix(4)) },
                streakDays: streak.currentStreak,
                longestStreak: streak.longestStreak,
                todayCount: stats.todayCount,
                weekCount: stats.weekCount,
                theme: service.getCurrentTheme(),
                layout: service.getCurrentLayout()
            )
            
            // 每小时刷新
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - 小组件条目

struct DailyInsightEntry: TimelineEntry {
    var date: Date
    var keywords: [String]
    var currentMood: String?
    var moodTrend: [String]
    var streakDays: Int
    var longestStreak: Int
    var todayCount: Int
    var weekCount: Int
    var theme: WidgetTheme
    var layout: WidgetLayout
    
    static var placeholder: DailyInsightEntry {
        DailyInsightEntry(
            date: Date(),
            keywords: ["平静", "探索", "创意"],
            currentMood: "平静",
            moodTrend: ["平静", "快乐", "好奇"],
            streakDays: 12,
            longestStreak: 28,
            todayCount: 2,
            weekCount: 9,
            theme: .default,
            layout: .default
        )
    }
}

// MARK: - 小组件视图

struct DailyInsightWidgetEntryView: View {
    let entry: DailyInsightEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallInsightView(entry: entry)
            case .systemMedium:
                MediumInsightView(entry: entry)
            case .systemLarge:
                LargeInsightView(entry: entry)
            default:
                SmallInsightView(entry: entry)
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

struct SmallInsightView: View {
    let entry: DailyInsightEntry
    
    var body: some View {
        VStack(spacing: 10) {
            // 连续记录
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("\(entry.streakDays) 天")
                    .font(.title)
                    .fontWeight(.bold)
                Text("连续记录")
                    .font(.caption2)
                    .opacity(0.7)
            }
            
            Divider()
            
            // 关键词
            VStack(alignment: .leading, spacing: 4) {
                Text("今日关键词")
                    .font(.caption)
                    .opacity(0.8)
                
                ForEach(entry.keywords, id: \.self) { keyword in
                    Text("• \(keyword)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // 情绪
            if let mood = entry.currentMood {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(mood)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
    }
}

struct MediumInsightView: View {
    let entry: DailyInsightEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧：连续记录
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                
                Text("\(entry.streakDays)")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                
                Text("连续天数")
                    .font(.caption2)
                    .opacity(0.7)
                
                Text("最长：\(entry.longestStreak)")
                    .font(.caption2)
                    .opacity(0.6)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(maxHeight: .infinity)
            
            // 右侧：洞察
            VStack(alignment: .leading, spacing: 12) {
                // 关键词
                VStack(alignment: .leading, spacing: 4) {
                    Text("关键词")
                        .font(.caption)
                        .opacity(0.8)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(entry.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // 情绪趋势
                VStack(alignment: .leading, spacing: 4) {
                    Text("情绪趋势")
                        .font(.caption)
                        .opacity(0.8)
                    
                    HStack(spacing: 4) {
                        ForEach(entry.moodTrend, id: \.self) { mood in
                            Text(mood)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                }
                
                // 今日统计
                HStack(spacing: 12) {
                    StatBadge(icon: "moon.fill", value: "\(entry.todayCount)", label: "今日")
                    StatBadge(icon: "calendar", value: "\(entry.weekCount)", label: "本周")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

struct LargeInsightView: View {
    let entry: DailyInsightEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部：连续记录
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("连续记录 \(entry.streakDays) 天")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("个人最长记录：\(entry.longestStreak) 天")
                        .font(.caption)
                        .opacity(0.7)
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(entry.weekCount, entry.weekCount)) / 7.0)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(entry.weekCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            
            Divider()
            
            // 中部：关键词云
            VStack(alignment: .leading, spacing: 8) {
                Text("今日关键词")
                    .font(.headline)
                
                FlowLayout(spacing: 8) {
                    ForEach(Array(entry.keywords.enumerated()), id: \.offset) { index, keyword in
                        Text(keyword)
                            .font(.system(size: 14 + CGFloat(3 - index) * 2))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
            
            // 底部：情绪和统计
            HStack(spacing: 16) {
                // 情绪趋势
                VStack(alignment: .leading, spacing: 6) {
                    Text("本周情绪")
                        .font(.caption)
                        .opacity(0.8)
                    
                    HStack(spacing: 4) {
                        ForEach(entry.moodTrend, id: \.self) { mood in
                            Label(mood, systemImage: "heart.fill")
                                .font(.caption)
                                .labelStyle(.iconOnly)
                            Text(mood)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
                
                // 统计
                VStack(spacing: 6) {
                    HStack(spacing: 12) {
                        StatBadge(icon: "moon.fill", value: "\(entry.todayCount)", label: "今日")
                        StatBadge(icon: "calendar", value: "\(entry.weekCount)", label: "本周")
                    }
                }
            }
        }
        .padding()
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .opacity(0.7)
        }
    }
}

// MARK: - 预览

#Preview(as: .systemSmall) {
    DreamLogInteractiveDailyInsightWidget()
} timeline: {
    DailyInsightEntry.placeholder
}

#Preview(as: .systemMedium) {
    DreamLogInteractiveDailyInsightWidget()
} timeline: {
    DailyInsightEntry.placeholder
}

#Preview(as: .systemLarge) {
    DreamLogInteractiveDailyInsightWidget()
} timeline: {
    DailyInsightEntry.placeholder
}
