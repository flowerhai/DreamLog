//
//  DreamLogLockScreenWidgets.swift
//  DreamLog
//
//  Phase 90 - 锁屏小组件
//

import WidgetKit
import SwiftUI

// MARK: - 圆形锁屏小组件

struct DreamLogLockScreenCircularWidget: Widget {
    let kind: String = "lock_screen_circular"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenCircularProvider()) { entry in
            LockScreenCircularView(entry: entry)
        }
        .configurationDisplayName("连续记录")
        .description("显示连续记录天数")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenCircularProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenCircularEntry {
        LockScreenCircularEntry(streakDays: 12, todayRecorded: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenCircularEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenCircularEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let streak = await service.getStreakData()
            
            let entry = LockScreenCircularEntry(
                streakDays: streak.currentStreak,
                todayRecorded: streak.weeklyProgress > 0
            )
            
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct LockScreenCircularEntry: TimelineEntry {
    var date = Date()
    var streakDays: Int
    var todayRecorded: Bool
}

struct LockScreenCircularView: View {
    let entry: LockScreenCircularEntry
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: entry.todayRecorded ? 1.0 : 0.3)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // 内容
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("\(entry.streakDays)")
                    .font(.system(size: 20, weight: .bold))
            }
        }
        .widgetBackground(Color.clear)
    }
}

// MARK: - 矩形锁屏小组件

struct DreamLogLockScreenRectangularWidget: Widget {
    let kind: String = "lock_screen_rectangular"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenRectangularProvider()) { entry in
            LockScreenRectangularView(entry: entry)
        }
        .configurationDisplayName("梦境摘要")
        .description("显示昨日梦境摘要和统计")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenRectangularProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenRectangularEntry {
        LockScreenRectangularEntry(
            dreamTitle: "神秘的飞行",
            dreamPreview: "在夜空中飞翔...",
            todayCount: 2,
            streakDays: 12
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenRectangularEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenRectangularEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let stats = await service.getDreamStats()
            let streak = await service.getStreakData()
            let recent = await service.getRecentDreams(limit: 1)
            
            let entry = LockScreenRectangularEntry(
                dreamTitle: recent.dreams.first?.title ?? "无梦境",
                dreamPreview: recent.dreams.first?.preview ?? "开始记录你的梦境",
                todayCount: stats.todayCount,
                streakDays: streak.currentStreak
            )
            
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct LockScreenRectangularEntry: TimelineEntry {
    var date = Date()
    var dreamTitle: String
    var dreamPreview: String
    var todayCount: Int
    var streakDays: Int
}

struct LockScreenRectangularView: View {
    let entry: LockScreenRectangularEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text(entry.dreamTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(entry.todayCount) 今日")
                    .font(.caption2)
                    .opacity(0.7)
            }
            
            Text(entry.dreamPreview)
                .font(.caption2)
                .lineLimit(2)
                .opacity(0.8)
            
            HStack {
                Label("\(entry.streakDays) 天", systemImage: "flame.fill")
                    .font(.caption2)
                    .labelStyle(.iconOnly)
            }
        }
        .widgetBackground(Color.clear)
    }
}

// MARK: - 紧凑锁屏小组件

struct DreamLogLockScreenCompactWidget: Widget {
    let kind: String = "lock_screen_compact"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenCompactProvider()) { entry in
            LockScreenCompactView(entry: entry)
        }
        .configurationDisplayName("梦境计数")
        .description("显示梦境总数")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenCompactProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenCompactEntry {
        LockScreenCompactEntry(totalCount: 128)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenCompactEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenCompactEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let stats = await service.getDreamStats()
            
            let entry = LockScreenCompactEntry(totalCount: stats.totalCount)
            
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct LockScreenCompactEntry: TimelineEntry {
    var date = Date()
    var totalCount: Int
}

struct LockScreenCompactView: View {
    let entry: LockScreenCompactEntry
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "moon.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            Text("\(entry.totalCount)")
                .font(.system(size: 18, weight: .bold))
        }
        .widgetBackground(Color.clear)
    }
}

// MARK: - 预览

#Preview(as: .accessoryCircular) {
    DreamLogLockScreenCircularWidget()
} timeline: {
    LockScreenCircularEntry(streakDays: 12, todayRecorded: true)
}

#Preview(as: .accessoryRectangular) {
    DreamLogLockScreenRectangularWidget()
} timeline: {
    LockScreenRectangularEntry(
        dreamTitle: "神秘的飞行",
        dreamPreview: "在夜空中飞翔...",
        todayCount: 2,
        streakDays: 12
    )
}

#Preview(as: .accessoryCircular) {
    DreamLogLockScreenCompactWidget()
} timeline: {
    LockScreenCompactEntry(totalCount: 128)
}
