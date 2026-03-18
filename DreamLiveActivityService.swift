//
//  DreamLiveActivityService.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  实时活动 (Live Activities) 服务
//

import Foundation
import ActivityKit

/// 实时活动服务 - 管理挑战和孵育的实时活动
@available(iOS 16.2, *)
actor DreamLiveActivityService {
    
    static let shared = DreamLiveActivityService()
    
    private var activeChallengeActivities: [String: Activity<DreamChallengeAttributes>] = [:]
    private var activeIncubationActivities: [String: Activity<DreamIncubationAttributes>] = [:]
    
    private init() {}
    
    // MARK: - 权限检查
    
    /// 检查实时活动是否可用
    var isAvailable: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    /// 请求实时活动授权
    func requestAuthorization() async throws -> Bool {
        guard #available(iOS 16.2, *) else {
            return false
        }
        
        let authInfo = ActivityAuthorizationInfo()
        if authInfo.areActivitiesEnabled {
            return true
        }
        
        // iOS 16.2+ 不支持动态请求，需要在 Info.plist 中配置
        // 这里只返回当前状态
        return authInfo.areActivitiesEnabled
    }
    
    // MARK: - 挑战实时活动
    
    /// 开始挑战实时活动
    func startChallengeActivity(challenge: UserChallenge) async throws {
        guard #available(iOS 16.2, *) else { return }
        guard isAvailable else { return }
        
        let attributes = DreamChallengeAttributes(challengeId: challenge.id.uuidString)
        let contentState = ChallengeActivityContentState(
            challengeName: getChallengeName(challenge),
            progress: Double(challenge.progress) / Double(max(challenge.targetProgress, 1)),
            currentCount: challenge.progress,
            targetCount: challenge.targetProgress,
            timeRemaining: calculateTimeRemaining(challenge),
            state: .active
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: calculateStaleDate(challenge)
        )
        
        let activity = try Activity<DreamChallengeAttributes>.request(
            attributes: attributes,
            content: activityContent,
            pushType: nil
        )
        
        activeChallengeActivities[challenge.id] = activity
        
        print("🔔 挑战实时活动已启动：\(challenge.name)")
    }
    
    /// 更新挑战实时活动
    func updateChallengeActivity(challengeId: String, challenge: UserChallenge) async {
        guard #available(iOS 16.2, *) else { return }
        
        if let activity = activeChallengeActivities[challengeId] {
            let contentState = ChallengeActivityContentState(
                challengeName: getChallengeName(challenge),
                progress: Double(challenge.progress) / Double(max(challenge.targetProgress, 1)),
                currentCount: challenge.progress,
                targetCount: challenge.targetProgress,
                timeRemaining: calculateTimeRemaining(challenge),
                state: challenge.isCompleted ? .completed : .active
            )
            
            let activityContent = ActivityContent(
                state: contentState,
                staleDate: calculateStaleDate(challenge)
            )
            
            await activity.update(activityContent)
            
            print("🔔 挑战实时活动已更新：\(challenge.name)")
        }
    }
    
    /// 结束挑战实时活动
    func endChallengeActivity(challengeId: String, reason: ActivityEndReason = .completed) async {
        guard #available(iOS 16.2, *) else { return }
        
        if let activity = activeChallengeActivities.removeValue(forKey: challengeId) {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("🔔 挑战实时活动已结束：\(challengeId)")
        }
    }
    
    /// 结束所有挑战实时活动
    func endAllChallengeActivities() async {
        for challengeId in activeChallengeActivities.keys {
            await endChallengeActivity(challengeId: challengeId)
        }
    }
    
    // MARK: - 孵育实时活动
    
    /// 开始孵育实时活动
    func startIncubationActivity(incubation: DreamIncubationSession) async throws {
        guard #available(iOS 16.2, *) else { return }
        guard isAvailable else { return }
        
        let attributes = DreamIncubationAttributes(incubationId: incubation.id)
        let contentState = IncubationActivityContentState(
            goal: incubation.goal,
            currentAffirmation: getCurrentAffirmation(incubation),
            timeRemaining: calculateTimeRemaining(incubation),
            state: .active
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: calculateStaleDate(incubation)
        )
        
        let activity = try Activity<DreamIncubationAttributes>.request(
            attributes: attributes,
            content: activityContent,
            pushType: nil
        )
        
        activeIncubationActivities[incubation.id] = activity
        
        print("🔔 孵育实时活动已启动：\(incubation.goal)")
    }
    
    /// 更新孵育实时活动
    func updateIncubationActivity(incubationId: String, incubation: DreamIncubationSession) async {
        guard #available(iOS 16.2, *) else { return }
        
        if let activity = activeIncubationActivities[incubationId] {
            let contentState = IncubationActivityContentState(
                goal: incubation.goal,
                currentAffirmation: getCurrentAffirmation(incubation),
                timeRemaining: calculateTimeRemaining(incubation),
                state: incubation.isCompleted ? .completed : .active
            )
            
            let activityContent = ActivityContent(
                state: contentState,
                staleDate: calculateStaleDate(incubation)
            )
            
            await activity.update(activityContent)
            
            print("🔔 孵育实时活动已更新：\(incubation.goal)")
        }
    }
    
    /// 结束孵育实时活动
    func endIncubationActivity(incubationId: String, reason: ActivityEndReason = .completed) async {
        guard #available(iOS 16.2, *) else { return }
        
        if let activity = activeIncubationActivities.removeValue(forKey: incubationId) {
            await activity.end(nil, dismissalPolicy: .immediate)
            print("🔔 孵育实时活动已结束：\(incubationId)")
        }
    }
    
    /// 结束所有孵育实时活动
    func endAllIncubationActivities() async {
        for incubationId in activeIncubationActivities.keys {
            await endIncubationActivity(incubationId: incubationId)
        }
    }
    
    // MARK: - 辅助方法
    
    private func calculateTimeRemaining(_ challenge: UserChallenge) -> TimeInterval {
        guard let expiresAt = challenge.expiresAt else { return 0 }
        return max(0, expiresAt.timeIntervalSinceNow)
    }
    
    private func calculateTimeRemaining(_ incubation: DreamIncubationSession) -> TimeInterval {
        guard let targetSleepTime = incubation.targetSleepTime else { return 0 }
        return max(0, targetSleepTime.timeIntervalSinceNow)
    }
    
    private func calculateStaleDate(_ challenge: UserChallenge) -> Date {
        guard let expiresAt = challenge.expiresAt else {
            return Date().addingTimeInterval(24 * 60 * 60) // 默认 24 小时
        }
        return expiresAt.addingTimeInterval(15 * 60) // 结束后 15 分钟过期
    }
    
    private func calculateStaleDate(_ incubation: DreamIncubationSession) -> Date {
        guard let targetSleepTime = incubation.targetSleepTime else {
            return Date().addingTimeInterval(24 * 60 * 60)
        }
        return targetSleepTime.addingTimeInterval(15 * 60)
    }
    
    private func getChallengeName(_ challenge: UserChallenge) -> String {
        // 从模板获取挑战名称 (简化实现，实际应从服务获取)
        return "挑战 #\(challenge.id.uuidString.prefix(8))"
    }
    
    private func getCurrentAffirmation(_ incubation: DreamIncubationSession) -> String {
        if incubation.affirmations.isEmpty {
            return incubation.goal
        }
        let index = incubation.currentAffirmationIndex % incubation.affirmations.count
        return incubation.affirmations[index]
    }
}

// MARK: - 挑战实时活动属性

@available(iOS 16.2, *)
struct DreamChallengeAttributes: ActivityAttributes {
    var challengeId: String
    
    public struct ContentState: Codable, Hashable {
        var challengeName: String
        var progress: Double
        var currentCount: Int
        var targetCount: Int
        var timeRemaining: TimeInterval
        var state: LiveActivityState
    }
}

// MARK: - 孵育实时活动属性

@available(iOS 16.2, *)
struct DreamIncubationAttributes: ActivityAttributes {
    var incubationId: String
    
    public struct ContentState: Codable, Hashable {
        var goal: String
        var currentAffirmation: String
        var timeRemaining: TimeInterval
        var state: LiveActivityState
    }
}

// MARK: - 内容状态类型别名

@available(iOS 16.2, *)
typealias ChallengeActivityContentState = DreamChallengeAttributes.ContentState

@available(iOS 16.2, *)
typealias IncubationActivityContentState = DreamIncubationAttributes.ContentState

// MARK: - 活动结束原因

enum ActivityEndReason {
    case completed
    case cancelled
    case expired
}

// MARK: - 实时活动扩展配置

/*
 要在 Widget Extension 中显示实时活动，需要在 Widget 中添加：
 
 #if canImport(ActivityKit)
 if #available(iOS 16.2, *) {
     ActivityConfiguration(for: DreamChallengeAttributes.self) { context in
         // Lock Screen 和 Dynamic Island 的展示内容
         ChallengeLiveActivityView(activityContext: context)
     } dynamicIsland: { context in
         // Dynamic Island 的展示内容
         ChallengeDynamicIsland(activityContext: context)
     }
 }
 #endif
 
 同样为 DreamIncubationAttributes 添加配置
 */

// MARK: - 实时活动视图 (供 Widget Extension 使用)

#if canImport(ActivityKit) && canImport(SwiftUI)

@available(iOS 16.2, *)
struct ChallengeLiveActivityView: View {
    let context: ActivityViewContext<DreamChallengeAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(context.state.challengeName)
                    .font(.caption)
                    .bold()
                Spacer()
                Text(formatTime(context.state.timeRemaining))
                    .font(.caption2)
                    .monospacedDigit()
            }
            
            ProgressView(value: context.state.progress)
                .progressViewStyle(.linear)
            
            HStack {
                Text("\(context.state.currentCount) / \(context.state.targetCount)")
                    .font(.caption2)
                Spacer()
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption2)
                    .bold()
            }
        }
        .padding(12)
    }
}

@available(iOS 16.2, *)
struct IncubationLiveActivityView: View {
    let context: ActivityViewContext<DreamIncubationAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                Text("梦境孵育")
                    .font(.caption)
                    .bold()
                Spacer()
                Text(formatTime(context.state.timeRemaining))
                    .font(.caption2)
                    .monospacedDigit()
            }
            
            Text(context.state.currentAffirmation)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
    }
}

@available(iOS 16.2, *)
struct ChallengeDynamicIsland: View {
    let context: ActivityViewContext<DreamChallengeAttributes>
    
    var body: some View {
        DynamicIsland {
            // 展开视图
            DynamicIslandExpandedRegion(.leading) {
                VStack(alignment: .leading) {
                    Text(context.state.challengeName)
                        .font(.caption)
                        .bold()
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(.linear)
                }
            }
            DynamicIslandExpandedRegion(.trailing) {
                VStack {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.title3)
                        .bold()
                    Text("\(context.state.currentCount)/\(context.state.targetCount)")
                        .font(.caption2)
                }
            }
        } compactLeading: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        } compactTrailing: {
            Text("\(Int(context.state.progress * 100))%")
                .font(.caption)
                .bold()
        } minimal: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

@available(iOS 16.2, *)
struct IncubationDynamicIsland: View {
    let context: ActivityViewContext<DreamIncubationAttributes>
    
    var body: some View {
        DynamicIsland {
            // 展开视图
            DynamicIslandExpandedRegion(.leading) {
                VStack(alignment: .leading) {
                    Text("梦境孵育")
                        .font(.caption)
                        .bold()
                    Text(context.state.currentAffirmation)
                        .font(.caption2)
                        .lineLimit(2)
                }
            }
            DynamicIslandExpandedRegion(.trailing) {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
            }
        } compactLeading: {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(.purple)
        } compactTrailing: {
            Text(formatTime(context.state.timeRemaining))
                .font(.caption)
                .monospacedDigit()
        } minimal: {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(.purple)
        }
    }
}

#endif

// MARK: - 时间格式化辅助

private func formatTime(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}
