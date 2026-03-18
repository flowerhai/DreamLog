//
//  DreamInsightWidget.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  梦境洞察小组件
//

import WidgetKit
import SwiftUI

// MARK: - 时间线提供者

struct DreamInsightTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamInsightEntry {
        DreamInsightEntry(
            date: Date(),
            insight: InsightWidgetData(
                title: "梦境模式",
                content: "你最近经常梦到水，这可能代表情绪和潜意识。",
                type: "pattern",
                icon: "water.waves"
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamInsightEntry) -> Void) {
        let entry = DreamInsightEntry(
            date: Date(),
            insight: InsightWidgetData(
                title: "今日符号",
                content: "✨ 蛇 - 象征转变和治愈。梦见蛇可能意味着你正在经历重要的个人成长。",
                type: "symbol",
                icon: "sparkles"
            )
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamInsightEntry>) -> Void) {
        // 生成每日洞察
        let insights = [
            InsightWidgetData(
                title: "梦境模式",
                content: "你最近经常梦到水，这可能代表情绪和潜意识。",
                type: "pattern",
                icon: "water.waves"
            ),
            InsightWidgetData(
                title: "今日符号",
                content: "✨ 蛇 - 象征转变和治愈。梦见蛇可能意味着你正在经历重要的个人成长。",
                type: "symbol",
                icon: "sparkles"
            ),
            InsightWidgetData(
                title: "情绪洞察",
                content: "本周你的梦境以积极情绪为主，说明内心状态良好。继续保持！",
                type: "emotion",
                icon: "heart.fill"
            ),
            InsightWidgetData(
                title: "清醒梦提示",
                content: "今晚试试'现实检验'：问自己'我在做梦吗？'并检查周围细节。",
                type: "lucid",
                icon: "eye.fill"
            ),
            InsightWidgetData(
                title: "创意启发",
                content: "你的梦境充满了创意元素，试试把它们记录下来用于艺术创作。",
                type: "creative",
                icon: "paintbrush.fill"
            )
        ]
        
        // 随机选择一个洞察
        let selectedInsight = insights.randomElement() ?? insights[0]
        
        let entry = DreamInsightEntry(date: Date(), insight: selectedInsight)
        
        // 每天更新一次（在午夜）
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
        let timeline = Timeline(entries: [entry], policy: .atEnd(tomorrow))
        completion(timeline)
    }
}

// MARK: - 条目模型

struct DreamInsightEntry: TimelineEntry {
    let date: Date
    let insight: InsightWidgetData
}

// MARK: - 小型洞察组件

struct DreamInsightSmall: View {
    var entry: DreamInsightTimelineProvider.Entry
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://insights") ?? URL(fileURLWithPath: "/")) {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 8) {
                    // 图标
                    Image(systemName: entry.insight.icon)
                        .font(.title)
                        .foregroundColor(.white)
                    
                    // 标题
                    Text(entry.insight.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(8)
            }
        }
    }
}

// MARK: - 中型洞察组件

struct DreamInsightMedium: View {
    var entry: DreamInsightTimelineProvider.Entry
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://insights") ?? URL(fileURLWithPath: "/")) {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    // 头部
                    HStack {
                        Image(systemName: entry.insight.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(entry.insight.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // 内容
                    Text(entry.insight.content)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // 提示
                    HStack {
                        Spacer()
                        Text("点击查看详情")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(12)
            }
        }
    }
}

// MARK: - 大型洞察组件

struct DreamInsightLarge: View {
    var entry: DreamInsightTimelineProvider.Entry
    @State private var additionalInsights: [InsightWidgetData] = []
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://insights") ?? URL(fileURLWithPath: "/")) {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 主要洞察
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: entry.insight.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text(entry.insight.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Text(entry.insight.content)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // 更多洞察
                        Text("更多洞察")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ForEach(getAdditionalInsights(), id: \.title) { insight in
                            HStack(spacing: 10) {
                                Image(systemName: insight.icon)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(insight.title)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text(insight.content)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
    
    private func getAdditionalInsights() -> [InsightWidgetData] {
        [
            InsightWidgetData(
                title: "本周趋势",
                content: "清晰梦境增加 20%",
                type: "trend",
                icon: "chart.line.uptrend.xyaxis"
            ),
            InsightWidgetData(
                title: "热门符号",
                content: "水、飞行、追逐",
                type: "symbol",
                icon: "star.fill"
            ),
            InsightWidgetData(
                title: "建议",
                content: "尝试睡前冥想",
                type: "suggestion",
                icon: "lightbulb.fill"
            )
        ]
    }
}

// MARK: - 入口点

@main
struct DreamInsightWidget: Widget {
    let kind: String = "DreamInsightWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamInsightTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                DreamInsightLarge(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DreamInsightLarge(entry: entry)
            }
        }
        .configurationDisplayName("每日洞察")
        .description("查看 AI 生成的梦境洞察和建议")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 预览

struct DreamInsightWidget_Previews: PreviewProvider {
    static var previews: some View {
        DreamInsightSmall(
            entry: DreamInsightEntry(
                date: Date(),
                insight: InsightWidgetData(
                    title: "今日符号",
                    content: "蛇 - 象征转变",
                    type: "symbol",
                    icon: "sparkles"
                )
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        DreamInsightMedium(
            entry: DreamInsightEntry(
                date: Date(),
                insight: InsightWidgetData(
                    title: "梦境模式",
                    content: "你最近经常梦到水，这可能代表情绪和潜意识。",
                    type: "pattern",
                    icon: "water.waves"
                )
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
