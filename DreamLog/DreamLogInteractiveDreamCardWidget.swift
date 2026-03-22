//
//  DreamLogInteractiveDreamCardWidget.swift
//  DreamLog
//
//  Phase 90 - 交互式梦境卡片小组件
//

import WidgetKit
import SwiftUI

struct DreamLogInteractiveDreamCardWidget: Widget {
    let kind: String = "dream_card"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamCardProvider()) { entry in
            DreamCardWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("梦境卡片")
        .description("随机展示历史梦境，支持滑动切换")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 时间线提供者

struct DreamCardProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamCardEntry {
        DreamCardEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamCardEntry) -> Void) {
        let entry = DreamCardEntry.placeholder
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamCardEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            let recentDreams = await service.getRecentDreams(limit: 10)
            
            let entry = DreamCardEntry(
                date: Date(),
                currentDream: recentDreams.dreams.first ?? DreamCardEntry.DreamCard.empty,
                allDreams: recentDreams.dreams,
                currentIndex: 0,
                totalCount: recentDreams.dreams.count,
                theme: service.getCurrentTheme(),
                layout: service.getCurrentLayout()
            )
            
            // 每小时刷新
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - 小组件条目

struct DreamCardEntry: TimelineEntry {
    var date: Date
    var currentDream: DreamCard
    var allDreams: [DreamCard]
    var currentIndex: Int
    var totalCount: Int
    var theme: WidgetTheme
    var layout: WidgetLayout
    
    struct DreamCard: Identifiable {
        var id: String
        var title: String
        var preview: String
        var date: Date
        var emotions: [String]
        var tags: [String]
        var clarity: Int
        
        static var empty: DreamCard {
            DreamCard(
                id: UUID().uuidString,
                title: "无梦境",
                preview: "开始记录你的第一个梦境吧...",
                date: Date(),
                emotions: [],
                tags: [],
                clarity: 0
            )
        }
    }
    
    static var placeholder: DreamCardEntry {
        DreamCardEntry(
            date: Date(),
            currentDream: DreamCard(
                id: UUID().uuidString,
                title: "神秘的飞行",
                preview: "我在夜空中自由飞翔，穿过云层，看到下方的城市灯火辉煌...",
                date: Date().addingTimeInterval(-86400),
                emotions: ["兴奋", "自由"],
                tags: ["飞行", "夜晚"],
                clarity: 4
            ),
            allDreams: [],
            currentIndex: 0,
            totalCount: 5,
            theme: .default,
            layout: .default
        )
    }
}

// MARK: - 小组件视图

struct DreamCardWidgetEntryView: View {
    let entry: DreamCardEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallDreamCardView(entry: entry)
            case .systemMedium:
                MediumDreamCardView(entry: entry)
            case .systemLarge:
                LargeDreamCardView(entry: entry)
            default:
                SmallDreamCardView(entry: entry)
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

struct SmallDreamCardView: View {
    let entry: DreamCardEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 头部
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Text(entry.currentDream.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // 预览
            Text(entry.currentDream.preview)
                .font(.caption)
                .lineLimit(4)
                .opacity(0.9)
            
            // 情绪标签
            if !entry.currentDream.emotions.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(entry.currentDream.emotions.prefix(2), id: \.self) { emotion in
                        Text(emotion)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // 底部信息
            HStack {
                Text(entry.currentDream.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.caption2)
                    .opacity(0.6)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(entry.currentDream.clarity)/5")
                        .font(.caption2)
                }
            }
        }
        .padding()
    }
}

struct MediumDreamCardView: View {
    let entry: DreamCardEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text(entry.currentDream.title)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text(entry.currentDream.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                        .font(.caption2)
                        .opacity(0.6)
                }
                
                Spacer()
                
                // 清晰度
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: index < entry.currentDream.clarity ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    Text("清晰度")
                        .font(.caption2)
                        .opacity(0.6)
                }
            }
            
            Divider()
            
            // 梦境内容
            Text(entry.currentDream.preview)
                .font(.body)
                .lineLimit(5)
                .opacity(0.9)
            
            // 标签
            if !entry.currentDream.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(entry.currentDream.tags.prefix(4), id: \.self) { tag in
                        Label(tag, systemImage: "tag")
                            .font(.caption)
                            .labelStyle(.titleOnly)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // 底部
            HStack {
                Text("\(entry.currentIndex + 1)/\(entry.totalCount)")
                    .font(.caption)
                    .opacity(0.6)
                
                Spacer()
                
                if !entry.currentDream.emotions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.currentDream.emotions.prefix(3), id: \.self) { emotion in
                            Text(emotion)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.3))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct LargeDreamCardView: View {
    let entry: DreamCardEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "moon.stars.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.currentDream.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(entry.currentDream.date.formatted(.dateTime.year().month(.abbreviated).day().hour().minute()))
                                .font(.caption)
                                .opacity(0.6)
                        }
                    }
                    
                    // 清晰度评分
                    HStack(spacing: 4) {
                        Text("清晰度:")
                            .font(.caption)
                            .opacity(0.7)
                        
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: index < entry.currentDream.clarity ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Spacer()
                
                // 统计
                VStack(spacing: 8) {
                    StatPill(icon: "moon.fill", value: "\(entry.totalCount)", label: "梦境")
                    StatPill(icon: "tag.fill", value: "\(entry.currentDream.tags.count)", label: "标签")
                }
            }
            
            Divider()
            
            // 梦境内容
            VStack(alignment: .leading, spacing: 8) {
                Text("梦境记录")
                    .font(.headline)
                
                Text(entry.currentDream.preview)
                    .font(.body)
                    .lineLimit(6)
                    .opacity(0.9)
                    .textSelection(.enabled)
            }
            
            // 情绪和标签
            HStack(spacing: 16) {
                // 情绪
                VStack(alignment: .leading, spacing: 6) {
                    Text("情绪")
                        .font(.caption)
                        .opacity(0.7)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(entry.currentDream.emotions, id: \.self) { emotion in
                            Label(emotion, systemImage: "heart.fill")
                                .font(.caption)
                                .labelStyle(.titleOnly)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.3))
                                .cornerRadius(10)
                        }
                    }
                }
                
                // 标签
                VStack(alignment: .leading, spacing: 6) {
                    Text("标签")
                        .font(.caption)
                        .opacity(0.7)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(entry.currentDream.tags, id: \.self) { tag in
                            Label(tag, systemImage: "tag")
                                .font(.caption)
                                .labelStyle(.titleOnly)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 底部导航提示
            HStack {
                Text("滑动查看更多梦境")
                    .font(.caption)
                    .opacity(0.5)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                    Text("\(entry.currentIndex + 1)/\(entry.totalCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .opacity(0.6)
        }
    }
}

// MARK: - 预览

#Preview(as: .systemSmall) {
    DreamLogInteractiveDreamCardWidget()
} timeline: {
    DreamCardEntry.placeholder
}

#Preview(as: .systemMedium) {
    DreamLogInteractiveDreamCardWidget()
} timeline: {
    DreamCardEntry.placeholder
}

#Preview(as: .systemLarge) {
    DreamLogInteractiveDreamCardWidget()
} timeline: {
    DreamCardEntry.placeholder
}
