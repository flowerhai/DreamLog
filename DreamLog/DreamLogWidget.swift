//
//  DreamLogWidget.swift
//  DreamLogWidget
//
//  iOS 小组件 - 快速记录梦境
//

import WidgetKit
import SwiftUI

// MARK: - 梦境时间线提供者
struct DreamTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamEntry {
        DreamEntry(date: Date(), dreamCount: 3, lastDreamTitle: "昨晚的冒险", mood: .happy)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamEntry) -> Void) {
        let entry = DreamEntry(date: Date(), dreamCount: 3, lastDreamTitle: "昨晚的冒险", mood: .happy)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamEntry>) -> Void) {
        // 从 UserDefaults 加载梦境数据
        let dreamCount = UserDefaults.standard.integer(forKey: "dreamCount")
        let lastDreamTitle = UserDefaults.standard.string(forKey: "lastDreamTitle") ?? "记录你的梦"
        let lastMoodRaw = UserDefaults.standard.integer(forKey: "lastMood")
        let lastMood = Emotion(rawValue: lastMoodRaw) ?? .neutral
        
        let entry = DreamEntry(
            date: Date(),
            dreamCount: dreamCount > 0 ? dreamCount : 0,
            lastDreamTitle: lastDreamTitle,
            mood: lastMood
        )
        
        // 每小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .atEnd(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 梦境条目
struct DreamEntry: TimelineEntry {
    let date: Date
    let dreamCount: Int
    let lastDreamTitle: String
    let mood: Emotion
}

// MARK: - 小组件视图
struct DreamLogWidgetEntryView: View {
    var entry: DreamTimelineProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Text("DreamLog")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
            }
            
            // 梦境统计
            if entry.dreamCount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("已记录 \(entry.dreamCount) 个梦")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\"\(entry.lastDreamTitle)\"")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(entry.mood.icon)
                            .font(.caption)
                        Text(entry.mood.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("还没有梦境记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("今晚开始记录吧")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // 快速操作提示
            HStack {
                Image(systemName: "mic.fill")
                    .font(.caption)
                Text("长按快速记录")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - 小组件配置
struct DreamLogWidget: Widget {
    let kind: String = "DreamLogWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamTimelineProvider()
        ) { entry in
            DreamLogWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DreamLog 🌙")
        .description("快速查看梦境记录和统计")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 预览
struct DreamLogWidget_Previews: PreviewProvider {
    static var previews: some View {
        DreamLogWidgetEntryView(entry: DreamEntry(
            date: Date(),
            dreamCount: 5,
            lastDreamTitle: "飞翔在星空下",
            mood: .happy
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        DreamLogWidgetEntryView(entry: DreamEntry(
            date: Date(),
            dreamCount: 0,
            lastDreamTitle: "",
            mood: .neutral
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

// MARK: - Emotion 扩展 (小组件用)
extension Emotion {
    var icon: String {
        switch self {
        case .calm: return "😌"
        case .happy: return "😊"
        case .anxious: return "😰"
        case .fearful: return "😨"
        case .confused: return "😕"
        case .excited: return "🤩"
        case .sad: return "😢"
        case .angry: return "😠"
        case .surprised: return "😲"
        case .neutral: return "😐"
        @unknown default: return "😐"
        }
    }
    
    var name: String {
        switch self {
        case .calm: return "平静"
        case .happy: return "快乐"
        case .anxious: return "焦虑"
        case .fearful: return "恐惧"
        case .confused: return "困惑"
        case .excited: return "兴奋"
        case .sad: return "悲伤"
        case .angry: return "愤怒"
        case .surprised: return "惊讶"
        case .neutral: return "中性"
        @unknown default: return "未知"
        }
    }
}
