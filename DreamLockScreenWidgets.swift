//
//  DreamLockScreenWidgets.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  Phase 72 - 集成真实 SwiftData 数据
//  锁屏小组件实现
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - 锁屏统计小组件

struct DreamLockScreenStatsEntry: TimelineEntry {
    let date: Date
    let totalDreams: Int
    let thisWeek: Int
    let clarity: Double
    let lucidCount: Int
}

struct DreamLockScreenStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenStatsEntry {
        DreamLockScreenStatsEntry(
            date: Date(),
            totalDreams: 42,
            thisWeek: 5,
            clarity: 3.8,
            lucidCount: 8
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenStatsEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenStatsEntry>) -> Void) {
        // Phase 72: 从 SwiftData 获取真实数据
        let store = DreamStore.shared
        let allDreams = store.getAllDreams()
        
        let totalDreams = allDreams.count
        
        // 计算本周梦境数
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let thisWeek = allDreams.filter { $0.date >= startOfWeek }.count
        
        // 计算平均清晰度
        let clarityValues = allDreams.map { Double($0.clarity) }
        let clarity = clarityValues.isEmpty ? 0 : clarityValues.reduce(0, +) / Double(clarityValues.count)
        
        // 计算清醒梦数量
        let lucidCount = allDreams.filter { $0.isLucid }.count
        
        let entry = DreamLockScreenStatsEntry(
            date: Date(),
            totalDreams: totalDreams,
            thisWeek: thisWeek,
            clarity: clarity,
            lucidCount: lucidCount
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamLockScreenStatsView: View {
    let entry: DreamLockScreenStatsEntry
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                Text("DreamLog")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                LockScreenStatItem(icon: "📊", value: "\(entry.thisWeek)", label: "本周")
                LockScreenStatItem(icon: "✨", value: "\(entry.lucidCount)", label: "清醒梦")
                LockScreenStatItem(icon: "💫", value: String(format: "%.1f", entry.clarity), label: "清晰度")
            }
        }
    }
    
    struct LockScreenStatItem: View {
        let icon: String
        let value: String
        let label: String
        
        var body: some View {
            VStack(spacing: 2) {
                Text(icon)
                    .font(.caption2)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DreamLockScreenStatsWidget: Widget {
    let kind: String = "DreamLockScreenStats"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenStatsProvider()
        ) { entry in
            DreamLockScreenStatsView(entry: entry)
        }
        .configurationDisplayName("梦境统计")
        .description("查看梦境记录概览")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏昨夜梦境小组件

struct DreamLockScreenLastNightEntry: TimelineEntry {
    let date: Date
    let hasDream: Bool
    let dreamTitle: String
    let clarity: Int
    let emotions: [String]
}

struct DreamLockScreenLastNightProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenLastNightEntry {
        DreamLockScreenLastNightEntry(
            date: Date(),
            hasDream: true,
            dreamTitle: "在天空中飞行",
            clarity: 4,
            emotions: ["平静", "兴奋"]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenLastNightEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenLastNightEntry>) -> Void) {
        // Phase 72: 从 SwiftData 获取昨夜梦境
        let store = DreamStore.shared
        let allDreams = store.getAllDreams()
        
        // 获取最近的梦境（昨夜）
        let sortedDreams = allDreams.sorted { $0.date > $1.date }
        let lastNightDream = sortedDreams.first
        
        let entry: DreamLockScreenLastNightEntry
        if let dream = lastNightDream {
            entry = DreamLockScreenLastNightEntry(
                date: Date(),
                hasDream: true,
                dreamTitle: dream.title.isEmpty ? "无标题梦境" : dream.title,
                clarity: dream.clarity,
                emotions: dream.emotions.map { $0.emoji }
            )
        } else {
            entry = DreamLockScreenLastNightEntry(
                date: Date(),
                hasDream: false,
                dreamTitle: "",
                clarity: 0,
                emotions: []
            )
        }
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamLockScreenLastNightView: View {
    let entry: DreamLockScreenLastNightEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                Text("昨夜梦境")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            if entry.hasDream {
                Text(entry.dreamTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    clarityBadges
                    emotionBadges
                }
            } else {
                Text("昨晚没有记录梦境")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var clarityBadges: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < entry.clarity ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var emotionBadges: some View {
        HStack(spacing: 2) {
            ForEach(entry.emotions.prefix(2), id: \.self) { emotion in
                Text(emotion)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(3)
            }
        }
    }
}

struct DreamLockScreenLastNightWidget: Widget {
    let kind: String = "DreamLockScreenLastNight"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenLastNightProvider()
        ) { entry in
            DreamLockScreenLastNightView(entry: entry)
        }
        .configurationDisplayName("昨夜梦境")
        .description("快速查看昨晚的梦境")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏连续记录小组件

struct DreamLockScreenStreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let goal: Int
    let progress: Double
}

struct DreamLockScreenStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenStreakEntry {
        DreamLockScreenStreakEntry(
            date: Date(),
            currentStreak: 7,
            longestStreak: 21,
            goal: 30,
            progress: 0.23
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenStreakEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenStreakEntry>) -> Void) {
        // Phase 72: 从 SwiftData 计算真实连续记录天数
        let store = DreamStore.shared
        let allDreams = store.getAllDreams()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 计算当前连续记录天数
        var currentStreak = 0
        var checkDate = today
        let dreamDates = Set(allDreams.map { calendar.startOfDay(for: $0.date) })
        
        while dreamDates.contains(checkDate) {
            currentStreak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        // 如果今天还没有记录，但从昨天开始的连续记录
        if currentStreak == 0 && dreamDates.contains(calendar.date(byAdding: .day, value: -1, to: today) ?? today) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            while dreamDates.contains(checkDate) {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            }
        }
        
        // 计算最长连续记录
        var longestStreak = 0
        var tempStreak = 0
        var sortedDates = Array(dreamDates).sorted()
        
        for i in 0..<sortedDates.count {
            if i == 0 {
                tempStreak = 1
            } else {
                let daysDiff = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
                if daysDiff == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            }
        }
        longestStreak = max(longestStreak, tempStreak)
        
        // 计算进度（假设目标是 30 天）
        let goal = 30
        let progress = min(Double(currentStreak) / Double(goal), 1.0)
        
        let entry = DreamLockScreenStreakEntry(
            date: Date(),
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            goal: goal,
            progress: progress
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct DreamLockScreenStreakView: View {
    let entry: DreamLockScreenStreakEntry
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("连续记录")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.currentStreak) 天")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("当前连续")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 进度环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(Color.orange, lineWidth: 4)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(entry.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(width: 40, height: 40)
            }
            
            Text("最长记录：\(entry.longestStreak) 天")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct DreamLockScreenStreakWidget: Widget {
    let kind: String = "DreamLockScreenStreak"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenStreakProvider()
        ) { entry in
            DreamLockScreenStreakView(entry: entry)
        }
        .configurationDisplayName("连续记录")
        .description("追踪连续记录天数")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏情绪小组件

struct DreamLockScreenMoodEntry: TimelineEntry {
    let date: Date
    let dominantMood: String
    let moodIcon: String
    let moodPercentage: Double
    let weeklyMoods: [(icon: String, percentage: Double)]
}

struct DreamLockScreenMoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamLockScreenMoodEntry {
        DreamLockScreenMoodEntry(
            date: Date(),
            dominantMood: "平静",
            moodIcon: "😌",
            moodPercentage: 0.45,
            weeklyMoods: [
                ("😌", 0.45),
                ("😊", 0.25),
                ("😨", 0.15),
                ("😴", 0.15)
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DreamLockScreenMoodEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamLockScreenMoodEntry>) -> Void) {
        // Phase 72: 从 SwiftData 计算真实情绪分布
        let store = DreamStore.shared
        let allDreams = store.getAllDreams()
        
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let thisWeekDreams = allDreams.filter { $0.date >= startOfWeek }
        
        // 统计情绪分布
        var moodCounts: [String: Int] = [:]
        for dream in thisWeekDreams {
            for emotion in dream.emotions {
                let emoji = emotion.emoji
                moodCounts[emoji, default: 0] += 1
            }
        }
        
        let totalMoods = moodCounts.values.reduce(0, +)
        
        // 找出主导情绪
        let dominantMoodEntry = moodCounts.max(by: { $0.value < $1.value })
        let dominantMood = dominantMoodEntry?.key ?? "😌"
        let dominantPercentage = totalMoods > 0 ? Double(dominantMoodEntry?.value ?? 0) / Double(totalMoods) : 0
        
        // 构建情绪列表
        var weeklyMoods: [(icon: String, percentage: Double)] = moodCounts
            .sorted { $0.value > $1.value }
            .prefix(4)
            .map { (icon: $0.key, percentage: Double($0.value) / Double(totalMoods)) }
        
        if weeklyMoods.isEmpty {
            weeklyMoods = [
                ("😌", 0.45),
                ("😊", 0.25),
                ("😨", 0.15),
                ("😴", 0.15)
            ]
        }
        
        let entry = DreamLockScreenMoodEntry(
            date: Date(),
            dominantMood: getMoodName(for: dominantMood),
            moodIcon: dominantMood,
            moodPercentage: dominantPercentage,
            weeklyMoods: weeklyMoods
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func getMoodName(for emoji: String) -> String {
        switch emoji {
        case "😌": return "平静"
        case "😊": return "快乐"
        case "😨": return "恐惧"
        case "😴": return "困倦"
        case "😠": return "愤怒"
        case "😢": return "悲伤"
        case "😲": return "惊讶"
        case "🤔": return "困惑"
        default: return "平静"
        }
    }
}

struct DreamLockScreenMoodView: View {
    let entry: DreamLockScreenMoodEntry
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("本周情绪")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 8) {
                Text(entry.moodIcon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.dominantMood)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ProgressView(value: entry.moodPercentage)
                        .frame(width: 80)
                }
            }
            
            HStack(spacing: 4) {
                ForEach(entry.weeklyMoods, id: \.icon) { mood in
                    Text(mood.icon)
                        .font(.caption)
                }
            }
        }
    }
}

struct DreamLockScreenMoodWidget: Widget {
    let kind: String = "DreamLockScreenMood"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DreamLockScreenMoodProvider()
        ) { entry in
            DreamLockScreenMoodView(entry: entry)
        }
        .configurationDisplayName("情绪分布")
        .description("查看本周梦境情绪")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - 锁屏小组件集合

@main
struct DreamLockScreenWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DreamLockScreenStatsWidget()
        DreamLockScreenLastNightWidget()
        DreamLockScreenStreakWidget()
        DreamLockScreenMoodWidget()
    }
}
