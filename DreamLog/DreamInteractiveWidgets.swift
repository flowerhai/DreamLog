//
//  DreamInteractiveWidgets.swift
//  DreamLog
//
//  iOS 交互式小组件 - Phase 33
//

import WidgetKit
import SwiftUI

// MARK: - 快速记录交互式小组件

struct QuickRecordInteractiveEntry: TimelineEntry {
    let date: Date
    let isRecording: Bool
    let todayCount: Int
    let weeklyProgress: Double
    let theme: WidgetTheme
}

struct QuickRecordInteractiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickRecordInteractiveEntry {
        QuickRecordInteractiveEntry(
            date: Date(),
            isRecording: false,
            todayCount: 3,
            weeklyProgress: 0.6,
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickRecordInteractiveEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickRecordInteractiveEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let entry = await QuickRecordInteractiveEntry(
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

struct QuickRecordInteractiveWidget: View {
    let entry: QuickRecordInteractiveEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("快速记录")
                        .font(.headline)
                    Text(entry.isRecording ? "录音中..." : "点击开始记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: entry.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(entry.isRecording ? .red : .accentColor)
            }
            
            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("本周目标")
                        .font(.caption2)
                    Spacer()
                    Text("\(Int(entry.weeklyProgress * 100))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: entry.weeklyProgress)
                    .progressViewStyle(.linear)
            }
            
            HStack {
                Label("\(entry.todayCount)", systemImage: "moon.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("今日梦境")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

struct QuickRecordInteractive: Widget {
    let kind: String = DreamWidgetKind.quickRecord.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRecordInteractiveProvider()) { entry in
            QuickRecordInteractiveWidget(entry: entry)
        }
        .configurationDisplayName("快速记录")
        .description("一键开始梦境语音记录")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 标签筛选交互式小组件

struct TagFilterInteractiveEntry: TimelineEntry {
    let date: Date
    let tags: [TagFilterData.TagInfo]
    let theme: WidgetTheme
}

struct TagFilterInteractiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> TagFilterInteractiveEntry {
        TagFilterInteractiveEntry(
            date: Date(),
            tags: [
                TagFilterData.TagInfo(name: "飞行", count: 12, category: nil),
                TagFilterData.TagInfo(name: "追逐", count: 8, category: nil),
                TagFilterData.TagInfo(name: "水", count: 15, category: nil)
            ],
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TagFilterInteractiveEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TagFilterInteractiveEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let tagData = await service.getTagFilterData()
            
            let entry = TagFilterInteractiveEntry(
                date: Date(),
                tags: Array(tagData.frequentTags.prefix(6)),
                theme: service.getCurrentTheme()
            )
            
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct TagFilterInteractiveWidget: View {
    let entry: TagFilterInteractiveEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.headline)
                Text("常用标签")
                    .font(.headline)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(entry.tags, id: \.name) { tag in
                    VStack(spacing: 4) {
                        Text(tag.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text("\(tag.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

struct TagFilterInteractive: Widget {
    let kind: String = DreamWidgetKind.tagFilter.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TagFilterInteractiveProvider()) { entry in
            TagFilterInteractiveWidget(entry: entry)
        }
        .configurationDisplayName("标签筛选")
        .description("快速筛选常用标签")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 最近梦境交互式小组件

struct RecentDreamsInteractiveEntry: TimelineEntry {
    let date: Date
    let dreams: [RecentDreamsData.DreamSummary]
    let theme: WidgetTheme
}

struct RecentDreamsInteractiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentDreamsInteractiveEntry {
        RecentDreamsInteractiveEntry(
            date: Date(),
            dreams: [
                RecentDreamsData.DreamSummary(
                    id: UUID().uuidString,
                    title: "飞翔的梦",
                    preview: "我在空中自由飞翔...",
                    date: Date(),
                    emotions: ["快乐"],
                    tags: ["飞行"],
                    clarity: 4
                )
            ],
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RecentDreamsInteractiveEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentDreamsInteractiveEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let dreamsData = await service.getRecentDreams(limit: 5)
            
            let entry = RecentDreamsInteractiveEntry(
                date: Date(),
                dreams: dreamsData.dreams,
                theme: service.getCurrentTheme()
            )
            
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct RecentDreamsInteractiveWidget: View {
    let entry: RecentDreamsInteractiveEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.fill")
                    .font(.headline)
                Text("最近梦境")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(entry.dreams, id: \.id) { dream in
                    DreamRowView(dream: dream)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

struct DreamRowView: View {
    let dream: RecentDreamsData.DreamSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dream.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(clarityEmoji(dream.clarity))
                    .font(.caption)
            }
            
            Text(dream.preview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 6) {
                ForEach(dream.emotions.prefix(2), id: \.self) { emotion in
                    Text(emotion)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                }
            }
        }
    }
    
    func clarityEmoji(_ clarity: Int) -> String {
        switch clarity {
        case 5: return "✨"
        case 4: return "🌟"
        case 3: return "⭐"
        case 2: return "🌙"
        default: return "💭"
        }
    }
}

struct RecentDreamsInteractive: Widget {
    let kind: String = DreamWidgetKind.recentDreams.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentDreamsInteractiveProvider()) { entry in
            RecentDreamsInteractiveWidget(entry: entry)
        }
        .configurationDisplayName("最近梦境")
        .description("查看最近的梦境记录")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 连续记录交互式小组件

struct StreakInteractiveEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let weeklyProgress: Int
    let weeklyGoal: Int
    let theme: WidgetTheme
}

struct StreakInteractiveProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakInteractiveEntry {
        StreakInteractiveEntry(
            date: Date(),
            currentStreak: 7,
            longestStreak: 21,
            weeklyProgress: 5,
            weeklyGoal: 7,
            theme: WidgetTheme.default
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StreakInteractiveEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakInteractiveEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let streakData = await service.getStreakData()
            
            let entry = StreakInteractiveEntry(
                date: Date(),
                currentStreak: streakData.currentStreak,
                longestStreak: streakData.longestStreak,
                weeklyProgress: streakData.weeklyProgress,
                weeklyGoal: streakData.weeklyGoal,
                theme: service.getCurrentTheme()
            )
            
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct StreakInteractiveWidget: View {
    let entry: StreakInteractiveEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔥 连续记录")
                        .font(.headline)
                    Text("\(entry.currentStreak) 天")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("最长")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(entry.longestStreak) 天")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // 周目标进度
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("本周目标")
                        .font(.caption2)
                    Spacer()
                    Text("\(entry.weeklyProgress)/\(entry.weeklyGoal)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: Double(entry.weeklyProgress) / Double(entry.weeklyGoal))
                    .progressViewStyle(.linear)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
}

struct StreakInteractive: Widget {
    let kind: String = DreamWidgetKind.streakCounter.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakInteractiveProvider()) { entry in
            StreakInteractiveWidget(entry: entry)
        }
        .configurationDisplayName("连续记录")
        .description("追踪连续记录天数")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 交互式小组件_bundle

@main
struct DreamInteractiveWidgets: WidgetBundle {
    var body: some WidgetBundle {
        QuickRecordInteractive()
        TagFilterInteractive()
        RecentDreamsInteractive()
        StreakInteractive()
    }
}
