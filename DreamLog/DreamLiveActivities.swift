//
//  DreamLiveActivities.swift
//  DreamLog
//
//  iOS 实时活动 - Phase 33
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - 梦境记录提醒活动

struct DreamRecordAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var reminderType: ReminderType
        var message: String
        var timeRemaining: TimeInterval
        
        enum ReminderType: String, Codable {
            case bedtime = "bedtime"
            case morning = "morning"
            case weekly = "weekly"
        }
    }
    
    var dreamId: String?
    var userName: String
}

// MARK: - 连续记录激励活动

struct StreakAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentStreak: Int
        var longestStreak: Int
        var weeklyProgress: Int
        var weeklyGoal: Int
        var nextMilestone: Int
        var encouragement: String
    }
    
    var userId: String
}

// MARK: - 梦境挑战活动

struct DreamChallengeAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var challengeName: String
        var challengeDescription: String
        var currentProgress: Int
        var targetProgress: Int
        var timeRemaining: TimeInterval
        var reward: String
        var isCompleted: Bool
    }
    
    var challengeId: String
}

// MARK: - 实时活动管理器

@MainActor
class DreamLiveActivityManager {
    
    static let shared = DreamLiveActivityManager()
    
    private let userDefaults: UserDefaults
    private var dreamStore: DreamStore?
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func setDreamStore(_ store: DreamStore) {
        self.dreamStore = store
    }
    
    // MARK: - 梦境记录提醒
    
    func startBedtimeReminder() async {
        guard isActivityAvailable() else { return }
        
        let attributes = DreamRecordAttributes(
            dreamId: nil,
            userName: await getCurrentUserName()
        )
        
        let contentState = DreamRecordAttributes.ContentState(
            reminderType: .bedtime,
            message: "睡前记录时间到！捕捉你的梦境灵感 🌙",
            timeRemaining: 30 * 60 // 30 分钟
        )
        
        let content = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        do {
            let activity = try Activity<DreamRecordAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("🌙 睡前提醒活动已启动：\(activity.id)")
        } catch {
            print("❌ 启动睡前提醒活动失败：\(error)")
        }
    }
    
    func startMorningReminder() async {
        guard isActivityAvailable() else { return }
        
        let attributes = DreamRecordAttributes(
            dreamId: nil,
            userName: await getCurrentUserName()
        )
        
        let contentState = DreamRecordAttributes.ContentState(
            reminderType: .morning,
            message: "早安！还记得昨晚的梦吗？☀️",
            timeRemaining: 60 * 60 // 1 小时
        )
        
        let content = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
        
        do {
            let activity = try Activity<DreamRecordAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("☀️ 晨间提醒活动已启动：\(activity.id)")
        } catch {
            print("❌ 启动晨间提醒活动失败：\(error)")
        }
    }
    
    func stopRecordReminders() {
        Task {
            for activity in Activity<DreamRecordAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            print("🛑 所有记录提醒活动已停止")
        }
    }
    
    // MARK: - 连续记录激励
    
    func startStreakActivity() async {
        guard isActivityAvailable() else { return }
        guard let store = dreamStore else { return }
        
        let allDreams = await store.fetchAllDreams()
        let currentStreak = calculateStreak(dreams: allDreams)
        let longestStreak = calculateLongestStreak(dreams: allDreams)
        
        let weeklyGoal = userDefaults.integer(forKey: "weekly_dream_goal") ?? 7
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let weekDreams = await store.fetchDreams(from: weekStart, to: Date())
        
        let attributes = StreakAttributes(userId: UUID().uuidString)
        
        let encouragement = getStreakEncouragement(currentStreak: currentStreak)
        
        let contentState = StreakAttributes.ContentState(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weeklyProgress: weekDreams.count,
            weeklyGoal: weeklyGoal,
            nextMilestone: currentStreak >= 7 ? 14 : 7,
            encouragement: encouragement
        )
        
        let content = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
        
        do {
            let activity = try Activity<StreakAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("🔥 连续记录活动已启动：\(activity.id)")
        } catch {
            print("❌ 启动连续记录活动失败：\(error)")
        }
    }
    
    func updateStreakActivity() async {
        guard let store = dreamStore else { return }
        
        let allDreams = await store.fetchAllDreams()
        let currentStreak = calculateStreak(dreams: allDreams)
        let longestStreak = calculateLongestStreak(dreams: allDreams)
        
        let weeklyGoal = userDefaults.integer(forKey: "weekly_dream_goal") ?? 7
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let weekDreams = await store.fetchDreams(from: weekStart, to: Date())
        
        let encouragement = getStreakEncouragement(currentStreak: currentStreak)
        
        let contentState = StreakAttributes.ContentState(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weeklyProgress: weekDreams.count,
            weeklyGoal: weeklyGoal,
            nextMilestone: currentStreak >= 7 ? 14 : 7,
            encouragement: encouragement
        )
        
        let content = ActivityContent(state: contentState, staleDate: nil)
        
        for activity in Activity<StreakAttributes>.activities {
            await activity.update(content)
        }
    }
    
    func stopStreakActivity() {
        Task {
            for activity in Activity<StreakAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            print("🛑 连续记录活动已停止")
        }
    }
    
    // MARK: - 梦境挑战
    
    func startDreamChallenge(name: String, description: String, target: Int, days: Int, reward: String) async {
        guard isActivityAvailable() else { return }
        
        let attributes = DreamChallengeAttributes(challengeId: UUID().uuidString)
        
        let contentState = DreamChallengeAttributes.ContentState(
            challengeName: name,
            challengeDescription: description,
            currentProgress: 0,
            targetProgress: target,
            timeRemaining: Double(days) * 24 * 60 * 60,
            reward: reward,
            isCompleted: false
        )
        
        let content = ActivityContent(
            state: contentState,
            staleDate: Calendar.current.date(byAdding: .day, value: days, to: Date())
        )
        
        do {
            let activity = try Activity<DreamChallengeAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("🎯 梦境挑战已启动：\(name) (\(activity.id))")
        } catch {
            print("❌ 启动梦境挑战失败：\(error)")
        }
    }
    
    func updateChallengeProgress(challengeId: String, progress: Int, isCompleted: Bool) async {
        let contentState = DreamChallengeAttributes.ContentState(
            challengeName: "",
            challengeDescription: "",
            currentProgress: progress,
            targetProgress: 100,
            timeRemaining: 0,
            reward: "",
            isCompleted: isCompleted
        )
        
        let content = ActivityContent(state: contentState, staleDate: nil)
        
        for activity in Activity<DreamChallengeAttributes>.activities {
            if activity.attributes.challengeId == challengeId {
                await activity.update(content)
                if isCompleted {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }
    
    func stopAllChallenges() {
        Task {
            for activity in Activity<DreamChallengeAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            print("🛑 所有挑战活动已停止")
        }
    }
    
    // MARK: - 辅助方法
    
    private func isActivityAvailable() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    private func getCurrentUserName() async -> String {
        return userDefaults.string(forKey: "user_name") ?? "追梦者"
    }
    
    private func calculateStreak(dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedDates = Set(dreams.compactMap { calendar.startOfDay(for: $0.date ?? Date()) })
            .sorted(by: >)
        
        var streak = 0
        var currentDate = today
        
        for date in sortedDates {
            let daysDiff = calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0
            if daysDiff <= 1 {
                streak += 1
                currentDate = date
            } else {
                break
            }
        }
        
        if !sortedDates.contains(today) {
            streak = 0
        }
        
        return streak
    }
    
    private func calculateLongestStreak(dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = Set(dreams.compactMap { calendar.startOfDay(for: $0.date ?? Date()) })
            .sorted(by: <)
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let daysDiff = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysDiff == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    private func getStreakEncouragement(currentStreak: Int) -> String {
        switch currentStreak {
        case 0:
            return "今天记得记录梦境哦！🌙"
        case 1:
            return "好的开始！继续保持！✨"
        case 2...6:
            return "🔥 连续 \(currentStreak) 天！加油！"
        case 7:
            return "🎉 一周成就达成！太棒了！"
        case 14:
            return "🏆 两周连续记录！你是真正的追梦人！"
        case 21:
            return "👑 三周传奇！不可思议的坚持！"
        case 30:
            return "🌟 月度大师！一个月的梦境记录！"
        default:
            return "🔥 连续 \(currentStreak) 天！继续创造记录！"
        }
    }
    
    // MARK: - 自动管理
    
    func setupAutomaticReminders() {
        let bedtimeReminderEnabled = userDefaults.bool(forKey: "bedtime_reminder_enabled")
        let morningReminderEnabled = userDefaults.bool(forKey: "morning_reminder_enabled")
        let streakActivityEnabled = userDefaults.bool(forKey: "streak_activity_enabled")
        
        if bedtimeReminderEnabled {
            let bedtimeHour = userDefaults.integer(forKey: "bedtime_hour") ?? 22
            scheduleBedtimeReminder(hour: bedtimeHour)
        }
        
        if morningReminderEnabled {
            let morningHour = userDefaults.integer(forKey: "morning_hour") ?? 8
            scheduleMorningReminder(hour: morningHour)
        }
        
        if streakActivityEnabled {
            Task {
                await startStreakActivity()
            }
        }
    }
    
    private func scheduleBedtimeReminder(hour: Int) {
        // 实际应用中应使用 BackgroundTasks 或本地通知
        print("⏰ 计划睡前提醒：\(hour):00")
    }
    
    private func scheduleMorningReminder(hour: Int) {
        print("⏰ 计划晨间提醒：\(hour):00")
    }
}

// MARK: - 实时活动视图

struct BedtimeReminderLiveView: View {
    let activity: ActivityContent<DreamRecordAttributes.ContentState>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.purple)
                Text("睡前记录")
                    .font(.headline)
            }
            
            Text(activity.state.message)
                .font(.caption)
            
            Text("剩余 \(Int(activity.state.timeRemaining / 60)) 分钟")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct StreakLiveView: View {
    let activity: ActivityContent<StreakAttributes.ContentState>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🔥")
                    .font(.title2)
                Text("连续记录")
                    .font(.headline)
            }
            
            Text("\(activity.state.currentStreak) 天")
                .font(.title)
                .fontWeight(.bold)
            
            Text(activity.state.encouragement)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(activity.state.weeklyProgress) / Double(activity.state.weeklyGoal))
                .progressViewStyle(.linear)
            
            HStack {
                Text("本周：\(activity.state.weeklyProgress)/\(activity.state.weeklyGoal)")
                    .font(.caption2)
                Spacer()
                Text("下一个目标：\(activity.state.nextMilestone) 天")
                    .font(.caption2)
            }
        }
        .padding()
    }
}

struct ChallengeLiveView: View {
    let activity: ActivityContent<DreamChallengeAttributes.ContentState>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🎯")
                    .font(.title2)
                Text(activity.state.challengeName)
                    .font(.headline)
            }
            
            Text(activity.state.challengeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(activity.state.currentProgress) / Double(activity.state.targetProgress))
                .progressViewStyle(.linear)
            
            HStack {
                Text("进度：\(activity.state.currentProgress)/\(activity.state.targetProgress)")
                    .font(.caption2)
                Spacer()
                if activity.state.isCompleted {
                    Text("🎉 完成!")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Text("奖励：\(activity.state.reward)")
                        .font(.caption2)
                }
            }
        }
        .padding()
    }
}
