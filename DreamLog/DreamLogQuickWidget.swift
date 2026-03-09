//
//  DreamLogQuickWidget.swift
//  DreamLogWidget
//
//  快速记录小组件 - 一键开始录音
//

import WidgetKit
import SwiftUI

// MARK: - 快速记录时间线提供者
struct QuickRecordTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickRecordEntry {
        QuickRecordEntry(date: Date(), hasDreamsToday: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickRecordEntry) -> Void) {
        let entry = QuickRecordEntry(date: Date(), hasDreamsToday: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickRecordEntry>) -> Void) {
        // 检查今天是否已有梦境记录
        let hasDreamsToday = UserDefaults.standard.bool(forKey: "hasDreamsToday")
        
        let entry = QuickRecordEntry(date: Date(), hasDreamsToday: hasDreamsToday)
        
        // 每 30 分钟更新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(30 * 60)
        let timeline = Timeline(entries: [entry], policy: .atEnd(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 快速记录条目
struct QuickRecordEntry: TimelineEntry {
    let date: Date
    let hasDreamsToday: Bool
}

// MARK: - 小型快速记录组件
struct QuickRecordSmallWidget: View {
    var entry: QuickRecordTimelineProvider.Entry
    @State private var config: WidgetCustomizationConfig = .default
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://record")!) {
            ZStack {
                // 背景渐变 - 使用用户选择的主题
                LinearGradient(
                    gradient: Gradient(colors: config.theme.colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 8) {
                    // 主题图标
                    Image(systemName: config.theme.iconSFSymbol)
                        .font(.system(size: 32))
                        .foregroundColor(config.theme.textColorValue)
                    
                    // 文字
                    Text("记录梦境")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(config.theme.textColorValue)
                    
                    // 今日状态
                    if entry.hasDreamsToday {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("已记录")
                                .font(.caption2)
                        }
                        .foregroundColor(config.theme.textColorValue.opacity(0.9))
                    }
                }
            }
        }
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

// MARK: - 中型快速记录组件
struct QuickRecordMediumWidget: View {
    var entry: QuickRecordTimelineProvider.Entry
    @State private var config: WidgetCustomizationConfig = .default
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://record")!) {
            ZStack {
                // 背景 - 使用用户选择的主题
                LinearGradient(
                    gradient: Gradient(colors: config.theme.colors.map { $0.opacity(0.85) }),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                HStack(spacing: 16) {
                    // 左侧图标
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(config.theme.textColorValue.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "mic.fill")
                                .font(.system(size: 24))
                                .foregroundColor(config.theme.textColorValue)
                        }
                        
                        Text("按住说话")
                            .font(.caption2)
                            .foregroundColor(config.theme.textColorValue.opacity(0.9))
                    }
                    
                    // 右侧内容
                    VStack(alignment: .leading, spacing: 6) {
                        Text("昨晚你梦见了什么？")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(config.theme.textColorValue)
                        
                        Text("95% 的梦会在醒来 5 分钟内遗忘")
                            .font(.caption)
                            .foregroundColor(config.theme.textColorValue.opacity(0.8))
                        
                        if entry.hasDreamsToday {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("今天已记录")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(config.theme.textColorValue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
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

// MARK: - 圆形进度组件 (显示梦境目标)
struct DreamGoalWidget: View {
    var entry: QuickRecordTimelineProvider.Entry
    var weeklyCount: Int = 3
    var weeklyGoal: Int = 7
    @State private var config: WidgetCustomizationConfig = .default
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://insights")!) {
            ZStack {
                // 背景 - 使用用户选择的主题
                LinearGradient(
                    gradient: Gradient(colors: config.theme.colors),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 8) {
                    Text(config.customName.isEmpty ? "本周目标" : config.customName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(config.theme.textColorValue)
                    
                    // 进度环
                    ZStack {
                        Circle()
                            .stroke(config.theme.textColorValue.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(weeklyCount) / CGFloat(weeklyGoal))
                            .stroke(
                                config.theme.textColorValue,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(weeklyCount)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(config.theme.textColorValue)
                            Text("/ \(weeklyGoal)")
                                .font(.caption2)
                                .foregroundColor(config.theme.textColorValue.opacity(0.7))
                        }
                    }
                    
                    Text("还差 \(weeklyGoal - weeklyCount) 个梦")
                        .font(.caption2)
                        .foregroundColor(config.theme.textColorValue.opacity(0.9))
                }
            }
        }
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

// MARK: - 小组件配置 - 快速记录
struct DreamLogQuickWidget: Widget {
    let kind: String = "DreamLogQuickWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: QuickRecordTimelineProvider()
        ) { entry in
            QuickRecordSmallWidget(entry: entry)
        }
        .configurationDisplayName("快速记录 🎤 个性化")
        .description("可定制主题的快速录音小组件")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 小组件配置 - 梦境目标
struct DreamGoalWidgetBundle: Widget {
    let kind: String = "DreamGoalWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: QuickRecordTimelineProvider()
        ) { entry in
            DreamGoalWidget(entry: entry)
        }
        .configurationDisplayName("梦境目标 🎯 个性化")
        .description("可定制主题的追踪小组件")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 预览
struct DreamLogQuickWidget_Previews: PreviewProvider {
    static var previews: some View {
        // 小型快速记录
        QuickRecordSmallWidget(entry: QuickRecordEntry(date: Date(), hasDreamsToday: false))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        // 中型快速记录
        QuickRecordMediumWidget(entry: QuickRecordEntry(date: Date(), hasDreamsToday: true))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        // 目标组件
        DreamGoalWidget(entry: QuickRecordEntry(date: Date(), hasDreamsToday: false), weeklyCount: 3, weeklyGoal: 7)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
