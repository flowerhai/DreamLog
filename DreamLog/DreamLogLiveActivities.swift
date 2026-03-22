//
//  DreamLogLiveActivities.swift
//  DreamLog
//
//  Phase 90 - 实时活动增强
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - 梦境孵育实时活动

struct DreamLogIncubationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DreamIncubationAttributes.self) { context in
            IncubationLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.incubationTheme)
                            .font(.headline)
                        Text(context.state.timeRemaining, format: .timer)
                            .font(.title2)
                            .monospacedDigit()
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        Text("孵育主题：\(context.state.incubationTheme)")
                            .font(.headline)
                        
                        Text("目标：\(context.state.incubationGoal)")
                            .font(.subheadline)
                            .opacity(0.8)
                        
                        ProgressView(value: context.state.progress, total: 1.0)
                            .progressViewStyle(.linear)
                        
                        Text("剩余：\(context.state.timeRemaining, format: .timer)")
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
            } compactLeading: {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
            } compactTrailing: {
                Text(context.state.timeRemaining, format: .timer)
                    .font(.caption)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
            }
            .keylineTint(.yellow)
        }
    }
}

struct DreamIncubationAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var incubationTheme: String
        var incubationGoal: String
        var timeRemaining: Duration
        var progress: Double
    }
    
    var dreamTitle: String
    var startTime: Date
}

struct IncubationLiveActivityView: View {
    @Environment(\.colorScheme) var colorScheme
    let context: ActivityViewContext<DreamIncubationAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // 头部
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("梦境孵育中")
                        .font(.headline)
                    Text(context.state.incubationTheme)
                        .font(.subheadline)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Text(context.state.timeRemaining, format: .timer)
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.orange)
            }
            
            // 进度
            VStack(spacing: 8) {
                HStack {
                    Text("进度")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f%%", context.state.progress * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: context.state.progress, total: 1.0)
                    .progressViewStyle(.linear)
            }
            
            // 目标
            VStack(alignment: .leading, spacing: 4) {
                Text("孵育目标")
                    .font(.caption)
                    .opacity(0.7)
                Text(context.state.incubationGoal)
                    .font(.subheadline)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .widgetBackground(colorScheme == .dark ? Color.black : Color.white)
    }
}

// MARK: - 晨间反思实时活动

struct DreamLogMorningReflectionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MorningReflectionAttributes.self) { context in
            ReflectionLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("晨间反思")
                            .font(.headline)
                        Text(context.state.question)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "sunrise.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        Text("今日反思问题")
                            .font(.headline)
                        
                        Text(context.state.question)
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        HStack(spacing: 12) {
                            Text("连续 \(context.state.streakDays) 天")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                            
                            Text("完成率 \(String(format: "%.0f%%", context.state.completionRate * 100))")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "sunrise.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text("\(context.state.streakDays)")
                    .font(.caption)
                    .fontWeight(.bold)
            } minimal: {
                Image(systemName: "sunrise.fill")
                    .font(.caption)
            }
            .keylineTint(.orange)
        }
    }
}

struct MorningReflectionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var question: String
        var streakDays: Int
        var completionRate: Double
    }
    
    var reflectionDate: Date
}

struct ReflectionLiveActivityView: View {
    @Environment(\.colorScheme) var colorScheme
    let context: ActivityViewContext<MorningReflectionAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // 头部
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "sunrise.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("晨间反思")
                        .font(.headline)
                    Text(context.state.question)
                        .font(.subheadline)
                        .opacity(0.8)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(context.state.streakDays) 天")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            
            // 问题卡片
            VStack(alignment: .leading, spacing: 8) {
                Text("今日问题")
                    .font(.caption)
                    .opacity(0.7)
                
                Text(context.state.question)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // 统计
            HStack(spacing: 16) {
                StatBadge(
                    icon: "checkmark.circle.fill",
                    value: String(format: "%.0f%%", context.state.completionRate * 100),
                    label: "完成率",
                    color: .green
                )
                
                StatBadge(
                    icon: "calendar",
                    value: "\(context.state.streakDays)",
                    label: "连续天数",
                    color: .orange
                )
            }
        }
        .padding()
        .widgetBackground(colorScheme == .dark ? Color.black : Color.white)
    }
}

// MARK: - 预览

#Preview("梦境孵育", notification: .default) {
    DreamLogIncubationLiveActivity()
} contentStates: {
    DreamIncubationAttributes.ContentState(
        incubationTheme: "问题解答",
        incubationGoal: "找到项目灵感",
        timeRemaining: Duration(hours: 6, minutes: 30),
        progress: 0.65
    )
} attributes: {
    DreamIncubationAttributes(
        dreamTitle: "问题解答孵育",
        startTime: Date()
    )
}

#Preview("晨间反思", notification: .default) {
    DreamLogMorningReflectionLiveActivity()
} contentStates: {
    MorningReflectionAttributes.ContentState(
        question: "昨晚的梦境给你什么启示？",
        streakDays: 12,
        completionRate: 0.85
    )
} attributes: {
    MorningReflectionAttributes(
        reflectionDate: Date()
    )
}
