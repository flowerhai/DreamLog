//
//  DreamLockScreenWidgets.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  锁屏小组件实现
//

import WidgetKit
import SwiftUI

// MARK: - 锁屏统计小组件

struct DreamLockScreenStatsEntry: TimelineEntry {
    let date: Date
    let totalDreams: Int
    let thisWeek: Int
    let clarity: Double
    let lucidCount: Int
}

struct DreamLockScreenStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenStatsEntry {
        DreamLockScreenStatsEntry(
            date: Date(),
            totalDreams: 42,
            thisWeek: 5,
            clarity: 3.8,
            lucidCount: 8
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenStatsEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenStatsEntry>) -> Void) {
        // TODO: 从 SwiftData 获取真实数据
        let entry = DreamLockScreenStatsEntry(
            date: Date(),
            totalDreams: 42,
            thisWeek: 5,
            clarity: 3.8,
            lucidCount: 8
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamLockScreenStatsView: View {
    let entry: DreamLockScreenStatsEntry
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                Text("DreamLog")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                StatItem(icon: "📊", value: "\(entry.thisWeek)", label: "本周")
                StatItem(icon: "✨", value: "\(entry.lucidCount)", label: "清醒梦")
                StatItem(icon: "💫", value: String(format: "%.1f", entry.clarity), label: "清晰度")
            }
        }
    }
    
    struct StatItem: View {
        let icon: String
        let value: String
        let label: String
        
        var body: some View {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.caption2)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DreamLockScreenStatsWidget: Widget {
    let kind: String = "DreamLockScreenStats"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenStatsProvider()
        ) { entry in
            DreamLockScreenStatsView(entry: entry)
        }
        .configurationDisplayName("梦境统计")
        .description("查看梦境记录概览")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏昨夜梦境小组件

struct DreamLockScreenLastNightEntry: TimelineEntry {
    let date: Date
    let hasDream: Bool
    let dreamTitle: String
    let clarity: Int
    let emotions: [String]
}

struct DreamLockScreenLastNightProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenLastNightEntry {
        DreamLockScreenLastNightEntry(
            date: Date(),
            hasDream: true,
            dreamTitle: "在天空中飞行",
            clarity: 4,
            emotions: ["平静", "兴奋"]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenLastNightEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenLastNightEntry>) -> Void) {
        let entry = DreamLockScreenLastNightEntry(
            date: Date(),
            hasDream: true,
            dreamTitle: "在天空中飞行",
            clarity: 4,
            emotions: ["平静", "兴奋"]
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamLockScreenLastNightView: View {
    let entry: DreamLockScreenLastNightEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                Text("昨夜梦境")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            if entry.hasDream {
                Text(entry.dreamTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    clarityBadges
                    emotionBadges
                }
            } else {
                Text("昨晚没有记录梦境")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var clarityBadges: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < entry.clarity ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var emotionBadges: some View {
        HStack(spacing: 2) {
            ForEach(entry.emotions.prefix(2), id: \.self) { emotion in
                Text(emotion)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(3)
            }
        }
    }
}

struct DreamLockScreenLastNightWidget: Widget {
    let kind: String = "DreamLockScreenLastNight"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenLastNightProvider()
        ) { entry in
            DreamLockScreenLastNightView(entry: entry)
        }
        .configurationDisplayName("昨夜梦境")
        .description("快速查看昨晚的梦境")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏连续记录小组件

struct DreamLockScreenStreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let goal: Int
    let progress: Double
}

struct DreamLockScreenStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenStreakEntry {
        DreamLockScreenStreakEntry(
            date: Date(),
            currentStreak: 7,
            longestStreak: 21,
            goal: 30,
            progress: 0.23
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenStreakEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenStreakEntry>) -> Void) {
        let entry = DreamLockScreenStreakEntry(
            date: Date(),
            currentStreak: 7,
            longestStreak: 21,
            goal: 30,
            progress: 0.23
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamLockScreenStreakView: View {
    let entry: DreamLockScreenStreakEntry
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("连续记录")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.currentStreak) 天")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("当前连续")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(Color.orange, lineWidth: 4)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(entry.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(width: 40, height: 40)
            }
            
            Text("最长记录：\(entry.longestStreak) 天")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct DreamLockScreenStreakWidget: Widget {
    let kind: String = "DreamLockScreenStreak"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenStreakProvider()
        ) { entry in
            DreamLockScreenStreakView(entry: entry)
        }
        .configurationDisplayName("连续记录")
        .description("追踪连续记录天数")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏情绪小组件

struct DreamLockScreenMoodEntry: TimelineEntry {
    let date: Date
    let dominantMood: String
    let moodIcon: String
    let moodPercentage: Double
    let weeklyMoods: [(icon: String, percentage: Double)]
}

struct DreamLockScreenMoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenMoodEntry {
        DreamLockScreenMoodEntry(
            date: Date(),
            dominantMood: "平静",
            moodIcon: "😌",
            moodPercentage: 0.45,
            weeklyMoods: [
                ("😌", 0.45),
                ("😊", 0.25),
                ("😨", 0.15),
                ("😴", 0.15)
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenMoodEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenMoodEntry>) -> Void) {
        let entry = DreamLockScreenMoodEntry(
            date: Date(),
            dominantMood: "平静",
            moodIcon: "😌",
            moodPercentage: 0.45,
            weeklyMoods: [
                ("😌", 0.45),
                ("😊", 0.25),
                ("😨", 0.15),
                ("😴", 0.15)
            ]
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamLockScreenMoodView: View {
    let entry: DreamLockScreenMoodEntry
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("本周情绪")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 8) {
                Text(entry.moodIcon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.dominantMood)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ProgressView(value: entry.moodPercentage)
                        .frame(width: 80)
                }
            }
            
            HStack(spacing: 4) {
                ForEach(entry.weeklyMoods, id: \.icon) { mood in
                    Text(mood.icon)
                        .font(.caption)
                }
            }
        }
    }
}

struct DreamLockScreenMoodWidget: Widget {
    let kind: String = "DreamLockScreenMood"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenMoodProvider()
        ) { entry in
            DreamLockScreenMoodView(entry: entry)
        }
        .configurationDisplayName("情绪分布")
        .description("查看本周梦境情绪")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏小组件集合

@main
struct DreamLockScreenWidgets: WidgetBundle {
    var body: some Widget {
        DreamLockScreenStatsWidget()
        DreamLockScreenLastNightWidget()
        DreamLockScreenStreakWidget()
        DreamLockScreenMoodWidget()
    }
}
