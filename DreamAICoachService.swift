//
//  DreamAICoachService.swift
//  DreamLog
//
//  Phase 97: AI 教练 - 核心服务
//  提供个性化数字健康计划、习惯养成追踪、AI 驱动的干预建议
//

import Foundation
import SwiftData

@ModelActor
actor DreamAICoachService {
    
    // MARK: - 单例
    
    static let shared = DreamAICoachService(modelContainer: try! ModelContainer(for: DreamAICoachPlan.self, DreamAICoachHabit.self, DreamAICoachIntervention.self))
    
    // MARK: - 属性
    
    private var planTemplates: [CoachPlanTemplate] = []
    private let userId: UUID
    
    // MARK: - 初始化
    
    init(modelContainer: ModelContainer, userId: UUID = UUID()) {
        self.modelContainer = modelContainer
        self.userId = userId
        setupTemplates()
    }
    
    // MARK: - 预设计划模板
    
    private func setupTemplates() {
        planTemplates = [
            // 睡眠改善计划
            CoachPlanTemplate(
                planType: .sleepImprovement,
                name: "7 天睡眠改善",
                description: "通过科学方法改善睡眠质量，建立健康作息",
                duration: 7,
                habits: [
                    HabitTemplate(habitType: .sleepSchedule, title: "固定作息", description: "每天同一时间上床和起床", frequency: .daily, scheduledTime: "23:00"),
                    HabitTemplate(habitType: .screenTimeLimit, title: "睡前限屏", description: "睡前 1 小时不使用电子设备", frequency: .daily, scheduledTime: "22:00"),
                    HabitTemplate(habitType: .meditation, title: "睡前冥想", description: "10 分钟放松冥想", frequency: .daily, scheduledTime: "22:30"),
                    HabitTemplate(habitType: .dreamJournal, title: "记录梦境", description: "起床后立即记录梦境", frequency: .daily, scheduledTime: "07:00")
                ],
                goals: [
                    GoalTemplate(metric: .sleepDuration, title: "每晚睡眠 7-8 小时", targetValue: 7.5, unit: "小时"),
                    GoalTemplate(metric: .sleepQuality, title: "睡眠质量达到 80%", targetValue: 80, unit: "%"),
                    GoalTemplate(metric: .dreamRecallRate, title: "每周记录 5 个梦", targetValue: 5, unit: "个/周")
                ],
                difficulty: .medium
            ),
            
            // 梦境回忆增强计划
            CoachPlanTemplate(
                planType: .dreamRecall,
                name: "14 天梦境回忆增强",
                description: "提升梦境回忆能力，捕捉更多梦境细节",
                duration: 14,
                habits: [
                    HabitTemplate(habitType: .dreamJournal, title: "晨间记录", description: "醒来后立即记录梦境", frequency: .daily, scheduledTime: "07:00"),
                    HabitTemplate(habitType: .morningReflection, title: "梦境回顾", description: "花 5 分钟回顾梦境细节", frequency: .daily, scheduledTime: "07:30"),
                    HabitTemplate(habitType: .meditation, title: "睡前意图", description: "设定回忆梦境的意图", frequency: .daily, scheduledTime: "23:00"),
                    HabitTemplate(habitType: .gratitudeJournal, title: "感恩日记", description: "记录 3 件感恩的事", frequency: .daily, scheduledTime: "22:00")
                ],
                goals: [
                    GoalTemplate(metric: .dreamCount, title: "14 天记录 20 个梦", targetValue: 20, unit: "个"),
                    GoalTemplate(metric: .dreamRecallRate, title: "平均回忆清晰度 7/10", targetValue: 7, unit: "分"),
                    GoalTemplate(metric: .streak, title: "连续记录 14 天", targetValue: 14, unit: "天")
                ],
                difficulty: .medium
            ),
            
            // 清醒梦训练计划
            CoachPlanTemplate(
                planType: .lucidDreaming,
                name: "30 天清醒梦入门",
                description: "学习清醒梦技巧，体验掌控梦境的能力",
                duration: 30,
                habits: [
                    HabitTemplate(habitType: .realityCheck, title: "现实检查", description: "每天进行 10 次现实检查", frequency: .daily),
                    HabitTemplate(habitType: .dreamJournal, title: "详细记录", description: "记录梦境并标记清醒时刻", frequency: .daily, scheduledTime: "07:00"),
                    HabitTemplate(habitType: .meditation, title: "MILD 技巧", description: "睡前练习 MILD 技巧", frequency: .daily, scheduledTime: "23:00"),
                    HabitTemplate(habitType: .sleepSchedule, title: "规律作息", description: "保持固定睡眠时间", frequency: .daily)
                ],
                goals: [
                    GoalTemplate(metric: .lucidDreamFrequency, title: "体验 3 次清醒梦", targetValue: 3, unit: "次"),
                    GoalTemplate(metric: .dreamRecallRate, title: "每周记录 7 个梦", targetValue: 7, unit: "个/周"),
                    GoalTemplate(metric: .streak, title: "连续练习 30 天", targetValue: 30, unit: "天")
                ],
                difficulty: .hard
            ),
            
            // 压力缓解计划
            CoachPlanTemplate(
                planType: .stressReduction,
                name: "21 天压力缓解",
                description: "通过梦境和冥想来管理和缓解压力",
                duration: 21,
                habits: [
                    HabitTemplate(habitType: .meditation, title: "晨间冥想", description: "15 分钟正念冥想", frequency: .daily, scheduledTime: "07:00"),
                    HabitTemplate(habitType: .breathingExercise, title: "呼吸练习", description: "4-7-8 呼吸法", frequency: .daily),
                    HabitTemplate(habitType: .dreamJournal, title: "情绪记录", description: "记录梦境和情绪", frequency: .daily, scheduledTime: "07:00"),
                    HabitTemplate(habitType: .gratitudeJournal, title: "感恩练习", description: "记录 3 件感恩的事", frequency: .daily, scheduledTime: "21:00"),
                    HabitTemplate(habitType: .exercise, title: "适度运动", description: "30 分钟轻度运动", frequency: .weekdays)
                ],
                goals: [
                    GoalTemplate(metric: .stressLevel, title: "压力水平降低 30%", targetValue: 30, unit: "%"),
                    GoalTemplate(metric: .moodScore, title: "平均情绪评分 7/10", targetValue: 7, unit: "分"),
                    GoalTemplate(metric: .meditationMinutes, title: "总冥想时长 300 分钟", targetValue: 300, unit: "分钟")
                ],
                difficulty: .medium
            ),
            
            // 创意提升计划
            CoachPlanTemplate(
                planType: .creativityBoost,
                name: "14 天创意启发",
                description: "从梦境中获取创意灵感，激发创造力",
                duration: 14,
                habits: [
                    HabitTemplate(habitType: .dreamJournal, title: "创意记录", description: "记录梦境中的创意元素", frequency: .daily, scheduledTime: "07:00"),
                    HabitTemplate(habitType: .dreamIncubation, title: "创意孵化", description: "睡前设定创意意图", frequency: .daily, scheduledTime: "23:00"),
                    HabitTemplate(habitType: .morningReflection, title: "灵感整理", description: "整理梦境中的灵感", frequency: .daily, scheduledTime: "08:00"),
                    HabitTemplate(habitType: .meditation, title: "开放冥想", description: "10 分钟开放觉察冥想", frequency: .daily)
                ],
                goals: [
                    GoalTemplate(metric: .dreamCount, title: "记录 15 个创意梦境", targetValue: 15, unit: "个"),
                    GoalTemplate(metric: .habitCompletion, title: "习惯完成率 80%", targetValue: 80, unit: "%"),
                    GoalTemplate(metric: .streak, title: "连续 14 天练习", targetValue: 14, unit: "天")
                ],
                difficulty: .easy
            ),
            
            // 情绪平衡计划
            CoachPlanTemplate(
                planType: .emotionalBalance,
                name: "28 天情绪平衡",
                description: "通过梦境探索情绪，建立情绪平衡",
                duration: 28,
                habits: [
                    HabitTemplate(habitType: .dreamJournal, title: "情绪记录", description: "记录梦境和情绪", frequency: .daily, scheduledTime: "07:00"),
                    HabitTemplate(habitType: .meditation, title: "情绪冥想", description: "15 分钟情绪觉察冥想", frequency: .daily),
                    HabitTemplate(habitType: .gratitudeJournal, title: "感恩日记", description: "记录感恩事项", frequency: .daily, scheduledTime: "21:00"),
                    HabitTemplate(habitType: .morningReflection, title: "晨间反思", description: "反思情绪状态", frequency: .daily, scheduledTime: "07:30")
                ],
                goals: [
                    GoalTemplate(metric: .moodScore, title: "平均情绪评分 7.5/10", targetValue: 7.5, unit: "分"),
                    GoalTemplate(metric: .stressLevel, title: "压力水平降低 25%", targetValue: 25, unit: "%"),
                    GoalTemplate(metric: .streak, title: "连续 28 天练习", targetValue: 28, unit: "天")
                ],
                difficulty: .medium
            ),
            
            // 正念练习计划
            CoachPlanTemplate(
                planType: .mindfulness,
                name: "30 天正念修行",
                description: "培养正念觉察，提升生活质量",
                duration: 30,
                habits: [
                    HabitTemplate(habitType: .meditation, title: "正念冥想", description: "20 分钟正念冥想", frequency: .daily, scheduledTime: "07:00"),
                    HabitTemplate(habitType: .breathingExercise, title: "觉察呼吸", description: "每日 3 次呼吸觉察", frequency: .daily),
                    HabitTemplate(habitType: .realityCheck, title: "正念检查", description: "每日正念觉察练习", frequency: .daily),
                    HabitTemplate(habitType: .gratitudeJournal, title: "感恩练习", description: "记录感恩事项", frequency: .daily, scheduledTime: "21:00")
                ],
                goals: [
                    GoalTemplate(metric: .meditationMinutes, title: "总冥想时长 600 分钟", targetValue: 600, unit: "分钟"),
                    GoalTemplate(metric: .streak, title: "连续 30 天练习", targetValue: 30, unit: "天"),
                    GoalTemplate(metric: .habitCompletion, title: "习惯完成率 85%", targetValue: 85, unit: "%")
                ],
                difficulty: .hard
            )
        ]
    }
    
    // MARK: - 计划管理
    
    /// 获取所有预设计划模板
    func getPlanTemplates() -> [CoachPlanTemplate] {
        return planTemplates
    }
    
    /// 根据类型获取模板
    func getTemplate(for planType: CoachPlanType) -> CoachPlanTemplate? {
        return planTemplates.first { $0.planType == planType }
    }
    
    /// 创建新计划
    func createPlan(from template: CoachPlanTemplate, startDate: Date = Date()) async throws -> DreamAICoachPlan {
        let habits = template.habits.map { template -> DreamAICoachHabit in
            DreamAICoachHabit(
                planId: UUID(), // 将在计划创建后更新
                habitType: template.habitType,
                title: template.title,
                description: template.description,
                frequency: template.frequency,
                scheduledTime: template.scheduledTime.flatMap { timeString in
                    let components = timeString.split(separator: ":")
                    guard components.count == 2,
                          let hour = Int(components[0]),
                          let minute = Int(components[1]) else { return nil }
                    var calendar = Calendar.current
                    var date = Date()
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    return calendar.date(from: dateComponents)
                },
                reminderEnabled: true
            )
        }
        
        let goals = template.goals.map { template -> CoachGoal in
            CoachGoal(
                title: template.title,
                description: "目标：\(template.targetValue) \(template.unit)",
                metric: template.metric,
                targetValue: template.targetValue,
                unit: template.unit,
                deadline: template.deadline.flatMap { days in
                    Calendar.current.date(byAdding: .day, value: days, to: startDate)
                }
            )
        }
        
        let plan = DreamAICoachPlan(
            userId: userId,
            planType: template.planType,
            title: template.name,
            description: template.description,
            goals: goals,
            duration: template.duration,
            startDate: startDate,
            habits: habits,
            interventions: []
        )
        
        // 更新习惯的 planId
        for habit in habits {
            // 注意：实际实现中需要正确关联
        }
        
        modelContainer.mainContext.insert(plan)
        try modelContainer.mainContext.save()
        
        return plan
    }
    
    /// 获取用户所有计划
    func getUserPlans() async throws -> [DreamAICoachPlan] {
        let descriptor = FetchDescriptor<DreamAICoachPlan>(
            predicate: #Predicate<DreamAICoachPlan> { $0.userId == userId }
        )
        return try modelContainer.mainContext.fetch(descriptor)
    }
    
    /// 获取活跃计划
    func getActivePlans() async throws -> [DreamAICoachPlan] {
        let descriptor = FetchDescriptor<DreamAICoachPlan>(
            predicate: #Predicate<DreamAICoachPlan> { $0.userId == userId && $0.status == .active }
        )
        return try modelContainer.mainContext.fetch(descriptor)
    }
    
    /// 获取计划详情
    func getPlan(by id: UUID) async throws -> DreamAICoachPlan? {
        let descriptor = FetchDescriptor<DreamAICoachPlan>(
            predicate: #Predicate<DreamAICoachPlan> { $0.id == id }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        return results.first
    }
    
    /// 更新计划状态
    func updatePlanStatus(planId: UUID, status: CoachPlanStatus) async throws {
        let descriptor = FetchDescriptor<DreamAICoachPlan>(
            predicate: #Predicate<DreamAICoachPlan> { $0.id == planId }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        guard var plan = results.first else {
            throw CoachError.planNotFound
        }
        
        plan.status = status
        plan.updatedAt = Date()
        try modelContainer.mainContext.save()
    }
    
    /// 删除计划
    func deletePlan(planId: UUID) async throws {
        let descriptor = FetchDescriptor<DreamAICoachPlan>(
            predicate: #Predicate<DreamAICoachPlan> { $0.id == planId }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        guard let plan = results.first else {
            throw CoachError.planNotFound
        }
        
        modelContainer.mainContext.delete(plan)
        try modelContainer.mainContext.save()
    }
    
    // MARK: - 习惯管理
    
    /// 标记习惯完成
    func completeHabit(habitId: UUID, date: Date = Date(), notes: String? = nil, mood: Int? = nil, difficulty: Int? = nil) async throws {
        let descriptor = FetchDescriptor<DreamAICoachHabit>(
            predicate: #Predicate<DreamAICoachHabit> { $0.id == habitId }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        guard var habit = results.first else {
            throw CoachError.habitNotFound
        }
        
        // 检查今天是否已完成
        let todayCompletions = habit.completionHistory.filter {
            Calendar.current.isDateInToday($0.date)
        }
        if !todayCompletions.isEmpty {
            throw CoachError.habitAlreadyCompleted
        }
        
        let completion = HabitCompletion(date: date, notes: notes, mood: mood, difficulty: difficulty)
        habit.completionHistory.append(completion)
        habit.totalCompletions += 1
        habit.updatedAt = Date()
        
        // 更新连续天数
        updateStreak(for: &habit)
        
        try modelContainer.mainContext.save()
        
        // 检查是否需要生成干预（里程碑达成）
        if habit.totalCompletions % 7 == 0 {
            try await createMilestoneIntervention(for: habit, milestone: habit.totalCompletions)
        }
    }
    
    /// 更新连续天数
    private func updateStreak(for habit: inout DreamAICoachHabit) {
        let sortedCompletions = habit.completionHistory.sorted { $0.date > $1.date }
        var currentStreak = 0
        var currentDate = Date()
        
        for completion in sortedCompletions {
            if Calendar.current.isDate(completion.date, inSameDayAs: currentDate) {
                currentStreak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? Date()
            } else if Calendar.current.isDate(completion.date, inSameDayAs: currentDate) {
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? Date()
            } else {
                break
            }
        }
        
        habit.streak = currentStreak
        habit.longestStreak = max(habit.longestStreak, currentStreak)
    }
    
    /// 获取习惯今日状态
    func isHabitCompletedToday(habitId: UUID) async throws -> Bool {
        let descriptor = FetchDescriptor<DreamAICoachHabit>(
            predicate: #Predicate<DreamAICoachHabit> { $0.id == habitId }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        guard let habit = results.first else {
            throw CoachError.habitNotFound
        }
        
        return habit.completionHistory.contains {
            Calendar.current.isDateInToday($0.date)
        }
    }
    
    // MARK: - 干预管理
    
    /// 创建干预
    func createIntervention(
        planId: UUID,
        type: InterventionType,
        title: String,
        message: String,
        triggerReason: String,
        priority: InterventionPriority,
        suggestedAction: String? = nil
    ) async throws -> DreamAICoachIntervention {
        let intervention = DreamAICoachIntervention(
            planId: planId,
            interventionType: type,
            title: title,
            message: message,
            triggerReason: triggerReason,
            priority: priority,
            suggestedAction: suggestedAction
        )
        
        modelContainer.mainContext.insert(intervention)
        try modelContainer.mainContext.save()
        
        return intervention
    }
    
    /// 创建里程碑干预
    private func createMilestoneIntervention(for habit: DreamAICoachHabit, milestone: Int) async throws {
        let intervention = DreamAICoachIntervention(
            planId: habit.planId,
            interventionType: .milestoneAchieved,
            title: "🎉 习惯里程碑！",
            message: "恭喜！你已经连续完成\"\(habit.title)\"\(milestone) 次！继续保持！",
            triggerReason: "habit_milestone_\(milestone)",
            priority: .medium,
            suggestedAction: "继续坚持，你已经很棒了！"
        )
        
        modelContainer.mainContext.insert(intervention)
        try modelContainer.mainContext.save()
    }
    
    /// 获取待处理干预
    func getPendingInterventions() async throws -> [DreamAICoachIntervention] {
        let descriptor = FetchDescriptor<DreamAICoachIntervention>(
            predicate: #Predicate<DreamAICoachIntervention> { $0.status == .pending }
        )
        return try modelContainer.mainContext.fetch(descriptor)
    }
    
    /// 标记干预为已查看
    func markInterventionViewed(interventionId: UUID) async throws {
        let descriptor = FetchDescriptor<DreamAICoachIntervention>(
            predicate: #Predicate<DreamAICoachIntervention> { $0.id == interventionId }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        guard var intervention = results.first else {
            throw CoachError.interventionNotFound
        }
        
        intervention.status = .viewed
        try modelContainer.mainContext.save()
    }
    
    /// 标记干预为已完成
    func markInterventionCompleted(interventionId: UUID) async throws {
        let descriptor = FetchDescriptor<DreamAICoachIntervention>(
            predicate: #Predicate<DreamAICoachIntervention> { $0.id == interventionId }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        guard var intervention = results.first else {
            throw CoachError.interventionNotFound
        }
        
        intervention.status = .completed
        intervention.completedAt = Date()
        try modelContainer.mainContext.save()
    }
    
    /// 忽略干预
    func dismissIntervention(interventionId: UUID) async throws {
        let descriptor = FetchDescriptor<DreamAICoachIntervention>(
            predicate: #Predicate<DreamAICoachIntervention> { $0.id == interventionId }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        guard var intervention = results.first else {
            throw CoachError.interventionNotFound
        }
        
        intervention.status = .dismissed
        intervention.dismissedAt = Date()
        try modelContainer.mainContext.save()
    }
    
    // MARK: - 统计分析
    
    /// 获取用户统计
    func getStatistics() async throws -> CoachStatistics {
        let plans = try await getUserPlans()
        let activePlans = plans.filter { $0.status == .active }
        let completedPlans = plans.filter { $0.status == .completed }
        
        // 获取所有习惯
        let habitDescriptor = FetchDescriptor<DreamAICoachHabit>()
        let allHabits = try modelContainer.mainContext.fetch(habitDescriptor)
        let activeHabits = allHabits.filter { $0.streak > 0 }
        
        // 计算总完成数
        let totalCompletions = allHabits.reduce(0) { $0 + $1.totalCompletions }
        
        // 计算最长连续
        let longestStreak = allHabits.map { $0.longestStreak }.max() ?? 0
        let currentStreak = allHabits.map { $0.streak }.max() ?? 0
        
        // 计算完成率
        let habitCompletionRate = allHabits.isEmpty ? 0 :
            Double(totalCompletions) / Double(allHabits.count * 30) * 100 // 假设 30 天
        
        return CoachStatistics(
            totalPlans: plans.count,
            activePlans: activePlans.count,
            completedPlans: completedPlans.count,
            totalHabits: allHabits.count,
            activeHabits: activeHabits.count,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCompletions: totalCompletions,
            habitCompletionRate: min(habitCompletionRate, 100),
            averageSleepQuality: 0, // 需要从 HealthKit 获取
            averageDreamRecall: 0, // 需要从梦境数据计算
            interventionCount: 0, // 需要查询干预表
            milestonesAchieved: 0
        )
    }
    
    /// 获取每日进度
    func getDailyProgress(for date: Date) async throws -> DailyProgress {
        let habitDescriptor = FetchDescriptor<DreamAICoachHabit>()
        let allHabits = try modelContainer.mainContext.fetch(habitDescriptor)
        
        let completedHabits = allHabits.filter { habit in
            habit.completionHistory.contains { completion in
                Calendar.current.isDate(completion.date, inSameDayAs: date)
            }
        }
        
        return DailyProgress(
            date: date,
            habitsCompleted: completedHabits.count,
            habitsTotal: allHabits.count,
            dreamsRecorded: 0 // 需要从梦境数据获取
        )
    }
    
    // MARK: - 辅助方法
    
    /// 计算连续中断天数
    private func calculateConsecutiveMissedDays(for plan: DreamAICoachPlan) async -> Int {
        guard !plan.habits.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = Date()
        var consecutiveDays = 0
        
        // 从今天往前检查每一天
        for dayOffset in 0..<30 { // 最多检查 30 天
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                break
            }
            
            // 检查这一天是否有任何习惯完成
            let anyHabitCompleted = plan.habits.contains { habit in
                habit.completionHistory.contains { completion in
                    calendar.isDate(completion.date, inSameDayAs: date)
                }
            }
            
            if anyHabitCompleted {
                // 如果这一天有完成，中断计数重置（但已经过去的中断天数已记录）
                if dayOffset > 0 {
                    break
                }
            } else {
                // 今天没完成，增加中断计数
                if dayOffset == 0 {
                    // 检查今天是否已经结束（如果是当天，可能还有机会完成）
                    let hour = calendar.component(.hour, from: today)
                    if hour < 21 { // 晚上 9 点前不算中断
                        break
                    }
                }
                consecutiveDays += 1
            }
        }
        
        return consecutiveDays
    }
    
    // MARK: - AI 智能建议
    
    /// 生成个性化建议
    func generateSuggestions() async throws -> [DreamAICoachIntervention] {
        var suggestions: [DreamAICoachIntervention] = []
        
        // 获取活跃计划
        let activePlans = try await getActivePlans()
        
        for plan in activePlans {
            // 检查习惯完成情况
            if plan.habits.isEmpty { continue }
            
            let completionRate = Double(plan.completedDays) / Double(plan.duration) * 100
            
            // 完成率低于 50% 时生成鼓励建议
            if completionRate < 50 && plan.status == .active {
                let suggestion = try await createIntervention(
                    planId: plan.id,
                    type: .encouragement,
                    title: "💪 加油！你可以的！",
                    message: "你已经完成了\(Int(completionRate))%的进度。坚持下去，每一天都是进步！",
                    triggerReason: "low_completion_rate",
                    priority: .medium,
                    suggestedAction: "今天完成一个小习惯吧！"
                )
                suggestions.append(suggestion)
            }
            
            // 检查连续中断
            let consecutiveMissedDays = await calculateConsecutiveMissedDays(for: plan)
            if consecutiveMissedDays >= 3 {
                let priority: InterventionPriority = consecutiveMissedDays >= 7 ? .urgent : (consecutiveMissedDays >= 5 ? .high : .medium)
                let title: String
                let message: String
                let action: String
                
                if consecutiveMissedDays >= 7 {
                    title = "⚠️ 习惯中断警告"
                    message = "你已经连续\(consecutiveMissedDays)天没有完成计划了。长期中断会影响效果，重新开始吧！"
                    action = "从今天的一个小习惯开始"
                } else if consecutiveMissedDays >= 5 {
                    title = "💡 重新开始吧"
                    message = "注意到你已经休息了\(consecutiveMissedDays)天。没关系，现在重新开始也不晚！"
                    action = "完成今天的习惯打卡"
                } else {
                    title = "🌟 别忘了你的目标"
                    message = "连续\(consecutiveMissedDays)天没有记录啦～继续加油哦！"
                    action = "花 2 分钟完成今日习惯"
                }
                
                let intervention = try await createIntervention(
                    planId: plan.id,
                    type: .habitInterruption,
                    title: title,
                    message: message,
                    triggerReason: "consecutive_missed_days_\(consecutiveMissedDays)",
                    priority: priority,
                    suggestedAction: action
                )
                suggestions.append(intervention)
            }
        }
        
        return suggestions
    }
    
    // MARK: - 错误类型
    
    enum CoachError: LocalizedError {
        case planNotFound
        case habitNotFound
        case habitAlreadyCompleted
        case interventionNotFound
        case invalidDate
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .planNotFound: return "计划不存在"
            case .habitNotFound: return "习惯不存在"
            case .habitAlreadyCompleted: return "今日已完成此习惯"
            case .interventionNotFound: return "干预不存在"
            case .invalidDate: return "日期无效"
            case .permissionDenied: return "权限不足"
            }
        }
    }
}
