//
//  DreamLockScreenWidgets.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  锁屏小组件
//

import WidgetKit
import SwiftUI

// MARK: - 时间线提供者

struct DreamLockScreenTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenEntry {
        DreamLockScreenEntry(
            date: Date(),
            dreamsToday: 0,
            streakDays: 5,
            averageClarity: 3.5,
            currentChallenge: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenEntry) -> Void) {
        let entry = DreamLockScreenEntry(
            date: Date(),
            dreamsToday: 2,
            streakDays: 5,
            averageClarity: 3.8,
            currentChallenge: ChallengeWidgetData(
                name: "晨间记录者",
                progress: 0.6,
                current: 3,
                target: 5,
                icon: "sunrise.fill"
            )
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenEntry>) -> Void) {
        // TODO: 从 DreamStore 获取真实数据
        let entry = DreamLockScreenEntry(
            date: Date(),
            dreamsToday: Int.random(in: 0...5),
            streakDays: Int.random(in: 1...30),
            averageClarity: Double.random(in: 2.0...5.0),
            currentChallenge: nil
        )
        
        // 每 30 分钟更新
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .atEnd(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 条目模型

struct DreamLockScreenEntry: TimelineEntry {
    let date: Date
    let dreamsToday: Int
    let streakDays: Int
    let averageClarity: Double
    let currentChallenge: ChallengeWidgetData?
}

// MARK: - 小型锁屏组件

struct DreamLockScreenSmall: View {
    var entry: DreamLockScreenTimelineProvider.Entry
    
    var body: some View {
        VStack(spacing: 4) {
            // 梦境图标
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundColor(.purple)
            
            // 今日记录数
            Text("\(entry.dreamsToday)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("今日梦境")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 中型锁屏组件

struct DreamLockScreenMedium: View {
    var entry: DreamLockScreenTimelineProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("DreamLog")
                    .font(.headline)
            }
            
            Divider()
            
            HStack(spacing: 16) {
                // 今日梦境
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.dreamsToday)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("今日")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 连续记录
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.streakDays)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("连续天数")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 平均清晰度
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f", entry.averageClarity))
                        .font(.title)
                        .fontWeight(.bold)
                    Text("平均清晰")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 挑战进度
            if let challenge = entry.currentChallenge {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: challenge.icon)
                            .font(.caption)
                        Text(challenge.name)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(challenge.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    ProgressView(value: challenge.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                }
            }
        }
        .padding(8)
    }
}

// MARK: - 圆形锁屏组件

struct DreamLockScreenCircular: View {
    var entry: DreamLockScreenTimelineProvider.Entry
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.purple.opacity(0.3), lineWidth: 3)
            
            // 进度圆环（使用连续天数作为进度）
            Circle()
                .trim(from: 0, to: min(Double(entry.streakDays) / 30.0, 1.0))
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // 中心图标
            Image(systemName: "moon.stars.fill")
                .font(.caption)
                .foregroundColor(.purple)
        }
    }
}

// MARK: - 伽利略锁屏组件

struct DreamLockScreenGauge: View {
    var entry: DreamLockScreenTimelineProvider.Entry
    
    var body: some View {
        Gauge(value: entry.averageClarity, in: 1...5) {
            Label("平均清晰度", systemImage: "star.fill")
        } currentValueLabel: {
            Text(String(format: "%.1f", entry.averageClarity))
                .font(.title2)
                .fontWeight(.bold)
        } minimumValueLabel: {
            Text("1")
        } maximumValueLabel: {
            Text("5")
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.purple)
    }
}

// MARK: - 入口点

@main
struct DreamLockScreenWidgets: Widget {
    let kind: String = "DreamLockScreenWidgets"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamLockScreenTimelineProvider()) { entry in
            DreamLockScreenMedium(entry: entry)
        }
        .configurationDisplayName("梦境统计")
        .description("查看今日梦境记录和连续天数")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - 预览

struct DreamLockScreenWidgets_Previews: PreviewProvider {
    static var previews: some View {
        DreamLockScreenSmall(
            entry: DreamLockScreenEntry(
                date: Date(),
                dreamsToday: 3,
                streakDays: 12,
                averageClarity: 4.2,
                currentChallenge: nil
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        DreamLockScreenMedium(
            entry: DreamLockScreenEntry(
                date: Date(),
                dreamsToday: 3,
                streakDays: 12,
                averageClarity: 4.2,
                currentChallenge: ChallengeWidgetData(
                    name: "清醒梦挑战",
                    progress: 0.75,
                    current: 3,
                    target: 4,
                    icon: "eye.fill"
                )
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
