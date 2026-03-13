//
//  DreamLockScreenWidgets.swift
//  DreamLog
//
//  iOS 锁屏小组件 - Phase 33
//

import WidgetKit
import SwiftUI

// MARK: - 快速记录锁屏小组件

struct QuickRecordLockScreenEntry: TimelineEntry {
    let date: Date
    let isRecording: Bool
    let todayCount: Int
    let weeklyProgress: Double
    let theme: WidgetTheme
}

struct QuickRecordLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickRecordLockScreenEntry {
        QuickRecordLockScreenEntry(
            date: Date(),
            isRecording: false,
            todayCount: 3,
            weeklyProgress: 0.6,
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickRecordLockScreenEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickRecordLockScreenEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let entry = await QuickRecordLockScreenEntry(
                date: Date(),
                isRecording: false,
                todayCount: service.getQuickRecordEntry().todayCount,
                weeklyProgress: service.getQuickRecordEntry().progress,
                theme: service.getCurrentTheme()
            )
            
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct QuickRecordLockScreenWidget: View {
    let entry: QuickRecordLockScreenEntry
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: entry.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.title2)
                
                Text("DreamLog")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            if entry.isRecording {
                Text("录音中...")
                    .font(.caption2)
                    .foregroundColor(.red)
            } else {
                Text("今日：\(entry.todayCount) 个梦")
                    .font(.caption2)
            }
            
            // 进度条
            ProgressView(value: entry.weeklyProgress)
                .progressViewStyle(.linear)
                .scaleEffect(x: 1, y: 0.6, anchor: .center)
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

// MARK: - 统计锁屏小组件

struct StatsLockScreenEntry: TimelineEntry {
    let date: Date
    let todayCount: Int
    let weekCount: Int
    let streakDays: Int
    let theme: WidgetTheme
}

struct StatsLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsLockScreenEntry {
        StatsLockScreenEntry(
            date: Date(),
            todayCount: 2,
            weekCount: 10,
            streakDays: 5,
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StatsLockScreenEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsLockScreenEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let stats = await service.getDreamStats()
            
            let entry = StatsLockScreenEntry(
                date: Date(),
                todayCount: stats.todayCount,
                weekCount: stats.weekCount,
                streakDays: stats.streakDays,
                theme: service.getCurrentTheme()
            )
            
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct StatsLockScreenWidget: View {
    let entry: StatsLockScreenEntry
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                Text("梦境统计")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(entry.todayCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("本周")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(entry.weekCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("🔥")
                        .font(.caption)
                    Text("\(entry.streakDays)天")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

// MARK: - 梦境名言锁屏小组件

struct QuoteLockScreenEntry: TimelineEntry {
    let date: Date
    let quote: String
    let dateStr: String
    let theme: WidgetTheme
}

struct QuoteLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteLockScreenEntry {
        QuoteLockScreenEntry(
            date: Date(),
            quote: "我梦见自己在飞翔，穿越云层，感受自由...",
            dateStr: "3 月 13 日",
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteLockScreenEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteLockScreenEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let dreamQuote = await service.getDreamQuote()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M 月 d 日"
            
            let entry = QuoteLockScreenEntry(
                date: Date(),
                quote: dreamQuote.content,
                dateStr: formatter.string(from: dreamQuote.date),
                theme: service.getCurrentTheme()
            )
            
            // 每小时更新一次
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct QuoteLockScreenWidget: View {
    let entry: QuoteLockScreenEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "quote.bubble.fill")
                    .font(.caption)
                Text(entry.dateStr)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.quote)
                .font(.caption)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

// MARK: - 情绪追踪锁屏小组件

struct MoodLockScreenEntry: TimelineEntry {
    let date: Date
    let currentMood: String
    let moodIcon: String
    let theme: WidgetTheme
}

struct MoodLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoodLockScreenEntry {
        MoodLockScreenEntry(
            date: Date(),
            currentMood: "平静",
            moodIcon: "😌",
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MoodLockScreenEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodLockScreenEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let mood = await service.getMoodTracking()
            
            let moodIconMap: [String: String] = [
                "平静": "😌",
                "快乐": "😊",
                "焦虑": "😰",
                "恐惧": "😱",
                "困惑": "😕",
                "兴奋": "🤩",
                "悲伤": "😢",
                "愤怒": "😠",
                "惊讶": "😲",
                "中性": "😐"
            ]
            
            let currentMood = mood.currentMood ?? "中性"
            let entry = MoodLockScreenEntry(
                date: Date(),
                currentMood: currentMood,
                moodIcon: moodIconMap[currentMood] ?? "😐",
                theme: service.getCurrentTheme()
            )
            
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct MoodLockScreenWidget: View {
    let entry: MoodLockScreenEntry
    
    var body: some View {
        VStack(spacing: 4) {
            Text(entry.moodIcon)
                .font(.title)
            
            Text(entry.currentMood)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

// MARK: - 锁屏小组件_bundle

@main
struct DreamLockScreenWidgets: WidgetBundle {
    var body: some WidgetBundle {
        QuickRecordLockScreenWidgetBundle()
        StatsLockScreenWidgetBundle()
        QuoteLockScreenWidgetBundle()
        MoodLockScreenWidgetBundle()
    }
}

struct QuickRecordLockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickRecordLockScreen()
    }
}

struct QuickRecordLockScreen: Widget {
    let kind: String = DreamWidgetKind.quickRecord.rawValue
    
    var body: some WidgetConfiguration {
        AccessoryWidgetConfiguration()
            .kind(kind)
            .provider(QuickRecordLockScreenProvider())
            .entryView { entry in
                QuickRecordLockScreenWidget(entry: entry)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("快速记录")
            .description("一键开始梦境记录")
    }
}

struct StatsLockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatsLockScreen()
    }
}

struct StatsLockScreen: Widget {
    let kind: String = DreamWidgetKind.dailyStats.rawValue
    
    var body: some WidgetConfiguration {
        AccessoryWidgetConfiguration()
            .kind(kind)
            .provider(StatsLockScreenProvider())
            .entryView { entry in
                StatsLockScreenWidget(entry: entry)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("梦境统计")
            .description("查看今日和本周统计")
    }
}

struct QuoteLockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuoteLockScreen()
    }
}

struct QuoteLockScreen: Widget {
    let kind: String = DreamWidgetKind.dreamQuote.rawValue
    
    var body: some WidgetConfiguration {
        AccessoryWidgetConfiguration()
            .kind(kind)
            .provider(QuoteLockScreenProvider())
            .entryView { entry in
                QuoteLockScreenWidget(entry: entry)
            }
            .supportedFamilies([.accessoryRectangular])
            .configurationDisplayName("梦境名言")
            .description("随机显示梦境片段")
    }
}

struct MoodLockScreenWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoodLockScreen()
    }
}

struct MoodLockScreen: Widget {
    let kind: String = DreamWidgetKind.moodTracker.rawValue
    
    var body: some WidgetConfiguration {
        AccessoryWidgetConfiguration()
            .kind(kind)
            .provider(MoodLockScreenProvider())
            .entryView { entry in
                MoodLockScreenWidget(entry: entry)
            }
            .supportedFamilies([.accessoryCircular])
            .configurationDisplayName("情绪追踪")
            .description("显示当前情绪状态")
    }
}
