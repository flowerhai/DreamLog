//
//  DreamLogInteractiveQuickRecordWidget.swift
//  DreamLog
//
//  Phase 90 - 交互式快速记录小组件
//

import WidgetKit
import SwiftUI

struct DreamLogInteractiveQuickRecordWidget: Widget {
    let kind: String = DreamWidgetKind.quickRecord.rawValue
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickRecordProvider()) { entry in
            QuickRecordWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("快速记录")
        .description("一键开始语音或文字记录梦境")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 时间线提供者

struct QuickRecordProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickRecordEntry {
        QuickRecordEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickRecordEntry) -> Void) {
        let entry = QuickRecordEntry.placeholder
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickRecordEntry>) -> Void) {
        Task {
            let service = DreamWidgetService.shared
            
            let quickRecord = await service.getQuickRecordEntry()
            let stats = await service.getDreamStats()
            
            let entry = QuickRecordEntry(
                date: Date(),
                isRecording: quickRecord.isRecording,
                lastRecordDate: quickRecord.lastRecordDate,
                todayCount: quickRecord.todayCount,
                weeklyGoal: quickRecord.weeklyGoal,
                weeklyProgress: Int(stats.weekCount),
                theme: service.getCurrentTheme(),
                layout: service.getCurrentLayout()
            )
            
            // 15 分钟后刷新
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - 小组件条目

struct QuickRecordEntry: TimelineEntry {
    var date: Date
    var isRecording: Bool
    var lastRecordDate: Date?
    var todayCount: Int
    var weeklyGoal: Int
    var weeklyProgress: Int
    var theme: WidgetTheme
    var layout: WidgetLayout
    
    static var placeholder: QuickRecordEntry {
        QuickRecordEntry(
            date: Date(),
            isRecording: false,
            lastRecordDate: Date(),
            todayCount: 2,
            weeklyGoal: 7,
            weeklyProgress: 5,
            theme: .default,
            layout: .default
        )
    }
}

// MARK: - 小组件视图

struct QuickRecordWidgetEntryView: View {
    let entry: QuickRecordEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // 头部
            HStack {
                Image(systemName: entry.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.title2)
                    .foregroundColor(entry.isRecording ? .red : .accentColor)
                
                Text(entry.isRecording ? "录音中..." : "快速记录")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 今日计数
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.todayCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("今日")
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
            
            // 进度条
            if entry.weeklyGoal > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("本周进度")
                            .font(.caption)
                            .opacity(0.8)
                        Spacer()
                        Text("\(entry.weeklyProgress)/\(entry.weeklyGoal)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: entry.theme.gradientStart) ?? .accentColor,
                                            Color(hex: entry.theme.gradientEnd) ?? .accentColor
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: min(geo.size.width * CGFloat(entry.weeklyProgress) / CGFloat(entry.weeklyGoal), geo.size.width), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                // 语音记录按钮
                Button(action: {
                    WidgetCenter.shared.reloadAllTimelines()
                    NotificationCenter.default.post(name: .widgetStartRecording, object: nil)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                        Text("语音")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                // 文字记录按钮
                Button(action: {
                    WidgetCenter.shared.reloadAllTimelines()
                    NotificationCenter.default.post(name: .widgetStartTextRecording, object: nil)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "text.badge.checkmark")
                            .font(.title3)
                        Text("文字")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            
            // 最后记录时间
            if let lastDate = entry.lastRecordDate {
                Text("上次记录：\(lastDate.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .opacity(0.6)
            }
        }
        .padding()
        .widgetBackground(
            Color(hex: entry.theme.backgroundColor) ?? Color.clear,
            gradientStart: Color(hex: entry.theme.gradientStart),
            gradientEnd: Color(hex: entry.theme.gradientEnd)
        )
        .foregroundColor(Color(hex: entry.theme.textColor) ?? .primary)
    }
}

// MARK: - 预览

#Preview(as: .systemSmall) {
    DreamLogInteractiveQuickRecordWidget()
} timeline: {
    QuickRecordEntry.placeholder
}

#Preview(as: .systemMedium) {
    DreamLogInteractiveQuickRecordWidget()
} timeline: {
    QuickRecordEntry.placeholder
}
