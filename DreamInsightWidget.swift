//
//  DreamInsightWidget.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  梦境洞察小组件
//

import WidgetKit
import SwiftUI

// MARK: - 每日洞察小组件

struct DreamInsightEntry: TimelineEntry {
    let date: Date
    let insightType: InsightType
    let title: String
    let content: String
    let icon: String
}

enum InsightType: String, CaseIterable {
    case pattern = "模式发现"
    case suggestion = "建议"
    case symbol = "符号解读"
    case statistic = "统计"
    
    var icon: String {
        switch self {
        case .pattern: return "🔍"
        case .suggestion: return "💡"
        case .symbol: return "🔮"
        case .statistic: return "📊"
        }
    }
}

struct DreamInsightProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamInsightEntry {
        DreamInsightEntry(
            date: Date(),
            insightType: .pattern,
            title: "模式发现",
            content: "你最近经常梦到水，这可能代表情绪波动",
            icon: "🔍"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamInsightEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamInsightEntry>) -> Void) {
        let insights = [
            DreamInsightEntry(
                date: Date(),
                insightType: .pattern,
                title: "模式发现",
                content: "你最近经常梦到水，这可能代表情绪波动",
                icon: "🔍"
            ),
            DreamInsightEntry(
                date: Date(),
                insightType: .suggestion,
                title: "今日建议",
                content: "尝试睡前冥想，提高梦境回忆质量",
                icon: "💡"
            ),
            DreamInsightEntry(
                date: Date(),
                insightType: .symbol,
                title: "符号解读",
                content: "飞行梦通常象征自由和解脱",
                icon: "🔮"
            ),
            DreamInsightEntry(
                date: Date(),
                insightType: .statistic,
                title: "本周统计",
                content: "记录了 5 个梦，平均清晰度 3.8",
                icon: "📊"
            )
        ]
        
        let randomInsight = insights.randomElement() ?? insights[0]
        let timeline = Timeline(entries: [randomInsight], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamInsightSmallView: View {
    let entry: DreamInsightEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.icon)
                    .font(.title2)
                Text(entry.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(entry.content)
                .font(.caption)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack {
                Text("点击刷新")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct DreamInsightMediumView: View {
    let entry: DreamInsightEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.icon)
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(entry.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(entry.insightType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Text(entry.content)
                .font(.subheadline)
                .lineLimit(4)
                .padding(.vertical, 4)
            
            Divider()
            
            HStack(spacing: 12) {
                ActionButton(icon: "arrow.clockwise", label: "刷新")
                ActionButton(icon: "square.and.arrow.up", label: "分享")
                ActionButton(icon: "bookmark", label: "收藏")
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    struct ActionButton: View {
        let icon: String
        let label: String
        
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DreamInsightWidget: Widget {
    let kind: String = "DreamInsight"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamInsightProvider()
        ) { entry in
            if #available(iOS 17.0, *) {
                DreamInsightSmallView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DreamInsightSmallView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("每日洞察")
        .description("获取 AI 生成的梦境洞察")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 梦境符号小组件

struct DreamSymbolEntry: TimelineEntry {
    let date: Date
    let symbol: String
    let symbolName: String
    let meaning: String
    let relatedDreams: Int
}

struct DreamSymbolProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamSymbolEntry {
        DreamSymbolEntry(
            date: Date(),
            symbol: "💧",
            symbolName: "水",
            meaning: "象征情绪、潜意识和生命力",
            relatedDreams: 12
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamSymbolEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamSymbolEntry>) -> Void) {
        let symbols = [
            DreamSymbolEntry(
                date: Date(),
                symbol: "💧",
                symbolName: "水",
                meaning: "象征情绪、潜意识和生命力",
                relatedDreams: 12
            ),
            DreamSymbolEntry(
                date: Date(),
                symbol: "✈️",
                symbolName: "飞行",
                meaning: "代表自由、解脱和超越限制",
                relatedDreams: 8
            ),
            DreamSymbolEntry(
                date: Date(),
                symbol: "🏃",
                symbolName: "追逐",
                meaning: "可能表示逃避问题或压力",
                relatedDreams: 15
            ),
            DreamSymbolEntry(
                date: Date(),
                symbol: "🦷",
                symbolName: "牙齿",
                meaning: "象征变化、成长或焦虑",
                relatedDreams: 5
            )
        ]
        
        let randomSymbol = symbols.randomElement() ?? symbols[0]
        let timeline = Timeline(entries: [randomSymbol], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamSymbolView: View {
    let entry: DreamSymbolEntry
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(entry.symbol)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.symbolName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(entry.relatedDreams) 个相关梦境")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(entry.meaning)
                .font(.caption)
                .lineLimit(3)
                .padding(.vertical, 4)
            
            Spacer()
            
            HStack {
                Text("查看更多符号")
                    .font(.caption2)
                    .foregroundColor(.purple)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.purple)
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct DreamSymbolWidget: Widget {
    let kind: String = "DreamSymbol"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamSymbolProvider()
        ) { entry in
            if #available(iOS 17.0, *) {
                DreamSymbolView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DreamSymbolView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("梦境符号")
        .description("随机梦境符号解读")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 快速记录小组件增强版

struct DreamQuickRecordEntry: TimelineEntry {
    let date: Date
    let lastRecordDate: Date?
    let streakDays: Int
}

struct DreamQuickRecordProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamQuickRecordEntry {
        DreamQuickRecordEntry(
            date: Date(),
            lastRecordDate: Date().addingTimeInterval(-3600),
            streakDays: 7
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamQuickRecordEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamQuickRecordEntry>) -> Void) {
        let entry = DreamQuickRecordEntry(
            date: Date(),
            lastRecordDate: Date().addingTimeInterval(-3600),
            streakDays: 7
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamQuickRecordView: View {
    let entry: DreamQuickRecordEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mic.fill")
                    .font(.title2)
                Text("快速记录")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let lastRecord = entry.lastRecordDate {
                Text("上次记录：\(timeAgoString(from: lastRecord))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                RecordButton(icon: "mic.fill", label: "语音", color: .purple)
                RecordButton(icon: "keyboard", label: "文字", color: .blue)
            }
            
            if entry.streakDays > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("连续 \(entry.streakDays) 天")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    struct RecordButton: View {
        let icon: String
        let label: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct DreamQuickRecordWidget: Widget {
    let kind: String = "DreamQuickRecord"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamQuickRecordProvider()
        ) { entry in
            if #available(iOS 17.0, *) {
                DreamQuickRecordView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DreamQuickRecordView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("快速记录")
        .description("一键记录梦境")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 小组件集合

@main
struct DreamHomeWidgets: WidgetBundle {
    var body: some Widget {
        DreamInsightWidget()
        DreamSymbolWidget()
        DreamQuickRecordWidget()
    }
}
