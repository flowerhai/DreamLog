//
//  DreamChallengeWidget.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  挑战进度小组件
//

import WidgetKit
import SwiftUI

// MARK: - 时间线提供者

struct DreamChallengeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamChallengeEntry {
        DreamChallengeEntry(
            date: Date(),
            challenges: [
                ChallengeWidgetData(
                    id: "1",
                    name: "晨间记录者",
                    progress: 0.6,
                    target: 5,
                    current: 3,
                    icon: "sunrise.fill"
                ),
                ChallengeWidgetData(
                    id: "2",
                    name: "清醒梦挑战",
                    progress: 0.25,
                    target: 4,
                    current: 1,
                    icon: "eye.fill"
                )
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamChallengeEntry) -> Void) {
        let entry = DreamChallengeEntry(
            date: Date(),
            challenges: [
                ChallengeWidgetData(
                    name: "晨间记录者",
                    progress: 0.6,
                    current: 3,
                    target: 5,
                    icon: "sunrise.fill"
                )
            ]
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamChallengeEntry>) -> Void) {
        // TODO: 从 DreamChallengeService 获取真实数据
        let entry = DreamChallengeEntry(
            date: Date(),
            challenges: [
                ChallengeWidgetData(
                    id: "1",
                    name: "晨间记录者",
                    progress: Double.random(in: 0.3...0.9),
                    target: 5,
                    current: Int.random(in: 2...4),
                    icon: "sunrise.fill"
                ),
                ChallengeWidgetData(
                    id: "2",
                    name: "清醒梦挑战",
                    progress: Double.random(in: 0.1...0.5),
                    target: 4,
                    current: Int.random(in: 0...2),
                    icon: "eye.fill"
                )
            ]
        )
        
        // 每小时更新 - Calendar.date(byAdding:...) with valid inputs never fails
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .atEnd(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 条目模型

struct DreamChallengeEntry: TimelineEntry {
    let date: Date
    let challenges: [ChallengeWidgetData]
}

// MARK: - 小型挑战组件

struct DreamChallengeSmall: View {
    var entry: DreamChallengeTimelineProvider.Entry
    
    var topChallenge: ChallengeWidgetData? {
        entry.challenges.max(by: { $0.progress < $1.progress })
    }
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://challenges") ?? URL(fileURLWithPath: "/")) {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 6) {
                    // 图标
                    Image(systemName: topChallenge?.icon ?? "target")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    // 进度环
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        
                        Circle()
                            .trim(from: 0, to: topChallenge?.progress ?? 0)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((topChallenge?.progress ?? 0) * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    
                    // 名称
                    Text(topChallenge?.name ?? "挑战")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(8)
            }
        }
    }
}

// MARK: - 中型挑战组件

struct DreamChallengeMedium: View {
    var entry: DreamChallengeTimelineProvider.Entry
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://challenges") ?? URL(fileURLWithPath: "/")) {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.9), Color.red.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    // 头部
                    HStack {
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("进行中挑战")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(entry.challenges.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // 挑战列表
                    ForEach(entry.challenges.prefix(3), id: \.id) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                    
                    Spacer()
                }
                .padding(12)
            }
        }
    }
}

// MARK: - 挑战行视图

struct ChallengeRow: View {
    let challenge: ChallengeWidgetData
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: challenge.icon)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 20)
                
                Text(challenge.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(challenge.current)/\(challenge.target)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            ProgressView(value: challenge.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.white.opacity(0.8)))
        }
    }
}

// MARK: - 大型挑战组件

struct DreamChallengeLarge: View {
    var entry: DreamChallengeTimelineProvider.Entry
    
    var body: some View {
        Link(destination: URL(string: "dreamlog://challenges") ?? URL(fileURLWithPath: "/")) {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.9), Color.red.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 头部
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            
                            Text("挑战中心")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // 活跃挑战
                        Text("活跃挑战")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        
                        ForEach(entry.challenges, id: \.id) { challenge in
                            DetailedChallengeRow(challenge: challenge)
                        }
                        
                        // 统计
                        HStack(spacing: 16) {
                            StatBox(
                                value: "\(entry.challenges.count)",
                                label: "进行中",
                                icon: "list.bullet"
                            )
                            
                            StatBox(
                                value: "\(entry.challenges.filter { $0.progress >= 1.0 }.count)",
                                label: "已完成",
                                icon: "checkmark.circle.fill"
                            )
                            
                            StatBox(
                                value: "\(Int(entry.challenges.reduce(0) { $0 + $1.progress } / Double(max(entry.challenges.count, 1)) * 100))%",
                                label: "平均进度",
                                icon: "chart.bar.fill"
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding(12)
                }
            }
        }
    }
}

// MARK: - 详细挑战行

struct DetailedChallengeRow: View {
    let challenge: ChallengeWidgetData
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: challenge.icon)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("进度")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(challenge.current)/\(challenge.target)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                Text("\(Int(challenge.progress * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            ProgressView(value: challenge.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.white))
        }
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - 统计框

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 入口点

@main
struct DreamChallengeWidget: Widget {
    let kind: String = "DreamChallengeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamChallengeTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                DreamChallengeLarge(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DreamChallengeLarge(entry: entry)
            }
        }
        .configurationDisplayName("挑战进度")
        .description("追踪你的梦境挑战进度")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - 预览

struct DreamChallengeWidget_Previews: PreviewProvider {
    static var previews: some View {
        DreamChallengeSmall(
            entry: DreamChallengeEntry(
                date: Date(),
                challenges: [
                    ChallengeWidgetData(
                        name: "晨间记录者",
                        progress: 0.6,
                        current: 3,
                        target: 5,
                        icon: "sunrise.fill"
                    )
                ]
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        DreamChallengeMedium(
            entry: DreamChallengeEntry(
                date: Date(),
                challenges: [
                    ChallengeWidgetData(
                        name: "晨间记录者",
                        progress: 0.6,
                        current: 3,
                        target: 5,
                        icon: "sunrise.fill"
                    ),
                    ChallengeWidgetData(
                        name: "清醒梦挑战",
                        progress: 0.25,
                        current: 1,
                        target: 4,
                        icon: "eye.fill"
                    )
                ]
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
