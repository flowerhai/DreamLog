//
//  DreamLogWidget.swift
//  DreamLogWidget
//
//  iOS 小组件 - 快速记录梦境 (支持个性化定制)
//

import WidgetKit
import SwiftUI

// MARK: - 梦境时间线提供者
struct DreamTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamEntry {
        DreamEntry(
            date: Date(),
            dreamCount: 3,
            lastDreamTitle: "昨晚的冒险",
            mood: .happy,
            weeklyCount: 3,
            weeklyGoal: 7,
            streak: 5,
            quote: "记录你的梦境，发现潜意识的秘密"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamEntry) -> Void) {
        let entry = DreamEntry(
            date: Date(),
            dreamCount: 3,
            lastDreamTitle: "昨晚的冒险",
            mood: .happy,
            weeklyCount: 3,
            weeklyGoal: 7,
            streak: 5,
            quote: "记录你的梦境，发现潜意识的秘密"
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamEntry>) -> Void) {
        // 从 UserDefaults 加载梦境数据
        let dreamCount = UserDefaults.standard.integer(forKey: "dreamCount")
        let lastDreamTitle = UserDefaults.standard.string(forKey: "lastDreamTitle") ?? "记录你的梦"
        let lastMoodRaw = UserDefaults.standard.integer(forKey: "lastMood")
        let lastMood = Emotion(rawValue: lastMoodRaw) ?? .neutral
        
        // 加载小组件配置
        let config = loadWidgetConfig()
        
        // 加载额外数据
        let weeklyCount = UserDefaults.standard.integer(forKey: "weeklyDreamCount")
        let weeklyGoal = UserDefaults.standard.integer(forKey: "weeklyGoal")
        let streak = UserDefaults.standard.integer(forKey: "streakDays")
        
        // 获取语录
        let quote = getQuote(for: config)
        
        let entry = DreamEntry(
            date: Date(),
            dreamCount: dreamCount > 0 ? dreamCount : 0,
            lastDreamTitle: lastDreamTitle,
            mood: lastMood,
            weeklyCount: weeklyCount > 0 ? weeklyCount : 0,
            weeklyGoal: weeklyGoal > 0 ? weeklyGoal : 7,
            streak: streak > 0 ? streak : 0,
            quote: quote
        )
        
        // 每小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .atEnd(nextUpdate))
        completion(timeline)
    }
    
    // 加载小组件配置
    private func loadWidgetConfig() -> WidgetCustomizationConfig {
        guard let data = UserDefaults.standard.data(forKey: "widgetCustomizationConfig"),
              let config = try? JSONDecoder().decode(WidgetCustomizationConfig.self, from: data)
        else {
            return .default
        }
        return config
    }
    
    // 获取语录
    private func getQuote(for config: WidgetCustomizationConfig) -> String {
        if config.dataConfig.showQuote && !config.dataConfig.customQuote.isEmpty {
            return config.dataConfig.customQuote
        }
        
        let defaultQuotes = [
            "记录你的梦境，发现潜意识的秘密",
            "每个梦都是内心的声音",
            "梦境是现实的镜子",
            "今晚你会梦见什么？",
            "捕捉醒来即逝的梦境"
        ]
        return defaultQuotes.randomElement() ?? "记录你的梦"
    }
}

// MARK: - 梦境条目
struct DreamEntry: TimelineEntry {
    let date: Date
    let dreamCount: Int
    let lastDreamTitle: String
    let mood: Emotion
    let weeklyCount: Int
    let weeklyGoal: Int
    let streak: Int
    let quote: String
}

// MARK: - 小组件视图
struct DreamLogWidgetEntryView: View {
    var entry: DreamTimelineProvider.Entry
    @State private var config: WidgetCustomizationConfig = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Text(config.customName.isEmpty ? "DreamLog" : config.customName)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: config.theme.iconSFSymbol)
                    .foregroundColor(config.theme.textColorValue)
            }
            
            // 梦境统计
            if entry.dreamCount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    if config.dataConfig.showDreamCount {
                        Text("已记录 \(entry.dreamCount) 个梦")
                            .font(.caption)
                            .foregroundColor(config.theme.textColorValue.opacity(0.8))
                    }
                    
                    if config.dataConfig.showLastDreamTitle {
                        Text("\"\(entry.lastDreamTitle)\"")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundColor(config.theme.textColorValue)
                    }
                    
                    if config.dataConfig.showMood {
                        HStack {
                            Text(entry.mood.icon)
                                .font(.caption)
                            Text(entry.mood.name)
                                .font(.caption2)
                                .foregroundColor(config.theme.textColorValue.opacity(0.8))
                        }
                    }
                    
                    if config.dataConfig.showWeeklyGoal {
                        HStack {
                            Text("本周：\(entry.weeklyCount)/\(entry.weeklyGoal)")
                                .font(.caption2)
                                .foregroundColor(config.theme.textColorValue.opacity(0.7))
                            
                            if entry.weeklyCount >= entry.weeklyGoal {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(config.theme.textColorValue)
                            }
                        }
                    }
                    
                    if config.dataConfig.showStreak && entry.streak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("连续 \(entry.streak) 天")
                                .font(.caption2)
                                .foregroundColor(config.theme.textColorValue.opacity(0.7))
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("还没有梦境记录")
                        .font(.caption)
                        .foregroundColor(config.theme.textColorValue.opacity(0.8))
                    
                    Text("今晚开始记录吧")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(config.theme.textColorValue)
                }
            }
            
            // 自定义语录
            if config.dataConfig.showQuote && !entry.quote.isEmpty {
                Text("\"\(entry.quote)\"")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(config.theme.textColorValue.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 快速操作提示
            HStack {
                Image(systemName: "mic.fill")
                    .font(.caption)
                Text("长按快速记录")
                    .font(.caption2)
                    .foregroundColor(config.theme.textColorValue.opacity(0.8))
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: config.theme.colors.map { $0.opacity(0.15) }),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        guard let data = UserDefaults.standard.data(forKey: "widgetCustomizationConfig"),
              let loadedConfig = try? JSONDecoder().decode(WidgetCustomizationConfig.self, from: data)
        else {
            return
        }
        config = loadedConfig
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
        .configurationDisplayName("DreamLog 🌙 个性化")
        .description("可定制主题和内容的梦境小组件")
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
