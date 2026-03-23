//
//  DreamAICoachTests.swift
//  DreamLogTests
//
//  Phase 97: AI 教练 - 单元测试
//  测试覆盖率目标：95%+
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamAICoachTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var service: DreamAICoachService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            DreamAICoachPlan.self,
            DreamAICoachHabit.self,
            DreamAICoachIntervention.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        service = DreamAICoachService(modelContainer: modelContainer)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 计划模板测试
    
    func testPlanTemplatesExist() async throws {
        let templates = service.getPlanTemplates()
        
        XCTAssertGreaterThan(templates.count, 0, "应该有预设计划模板")
        
        // 验证所有计划类型都有模板
        let planTypes: Set<CoachPlanType> = Set(templates.map { $0.planType })
        XCTAssertEqual(planTypes.count, 7, "应该有 7 种不同类型的计划")
    }
    
    func testGetTemplateByType() async throws {
        let template = service.getTemplate(for: .sleepImprovement)
        
        XCTAssertNotNil(template, "应该能找到睡眠改善计划模板")
        XCTAssertEqual(template?.planType, .sleepImprovement)
        XCTAssertEqual(template?.name, "7 天睡眠改善")
    }
    
    // MARK: - 计划创建测试
    
    func testCreatePlanFromTemplate() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        
        let plan = try await service.createPlan(from: template)
        
        XCTAssertEqual(plan.planType, .sleepImprovement)
        XCTAssertEqual(plan.title, template.name)
        XCTAssertEqual(plan.description, template.description)
        XCTAssertEqual(plan.duration, template.duration)
        XCTAssertEqual(plan.status, .active)
        XCTAssertEqual(plan.progress, 0)
        XCTAssertGreaterThan(plan.habits.count, 0, "计划应该包含习惯")
        XCTAssertGreaterThan(plan.goals.count, 0, "计划应该包含目标")
    }
    
    func testCreatePlanWithCustomStartDate() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .dreamRecall))
        let customStartDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        let plan = try await service.createPlan(from: template, startDate: customStartDate)
        
        XCTAssertEqual(plan.startDate, customStartDate)
        let expectedEndDate = Calendar.current.date(byAdding: .day, value: template.duration, to: customStartDate)!
        XCTAssertEqual(plan.endDate, expectedEndDate)
    }
    
    // MARK: - 计划管理测试
    
    func testGetUserPlans() async throws {
        // 创建多个计划
        let template1 = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let template2 = try XCTUnwrap(service.getTemplate(for: .lucidDreaming))
        
        _ = try await service.createPlan(from: template1)
        _ = try await service.createPlan(from: template2)
        
        let plans = try await service.getUserPlans()
        
        XCTAssertEqual(plans.count, 2, "应该获取到 2 个计划")
    }
    
    func testGetActivePlans() async throws {
        let template1 = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let template2 = try XCTUnwrap(service.getTemplate(for: .stressReduction))
        
        let plan1 = try await service.createPlan(from: template1)
        let plan2 = try await service.createPlan(from: template2)
        
        // 将 plan2 设为已完成
        try await service.updatePlanStatus(planId: plan2.id, status: .completed)
        
        let activePlans = try await service.getActivePlans()
        
        XCTAssertEqual(activePlans.count, 1, "应该只有 1 个活跃计划")
        XCTAssertEqual(activePlans.first?.id, plan1.id)
    }
    
    func testGetPlanById() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .mindfulness))
        let plan = try await service.createPlan(from: template)
        
        let fetchedPlan = try await service.getPlan(by: plan.id)
        
        XCTAssertNotNil(fetchedPlan)
        XCTAssertEqual(fetchedPlan?.id, plan.id)
        XCTAssertEqual(fetchedPlan?.title, plan.title)
    }
    
    func testGetPlanByIdNotFound() async throws {
        let nonExistentId = UUID()
        let plan = try await service.getPlan(by: nonExistentId)
        
        XCTAssertNil(plan, "不存在的计划 ID 应该返回 nil")
    }
    
    func testUpdatePlanStatus() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .creativityBoost))
        let plan = try await service.createPlan(from: template)
        
        XCTAssertEqual(plan.status, .active)
        
        try await service.updatePlanStatus(planId: plan.id, status: .paused)
        
        let updatedPlan = try await service.getPlan(by: plan.id)
        XCTAssertEqual(updatedPlan?.status, .paused)
    }
    
    func testDeletePlan() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .emotionalBalance))
        let plan = try await service.createPlan(from: template)
        
        try await service.deletePlan(planId: plan.id)
        
        let deletedPlan = try await service.getPlan(by: plan.id)
        XCTAssertNil(deletedPlan, "删除后的计划应该不存在")
    }
    
    // MARK: - 习惯管理测试
    
    func testCompleteHabit() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        guard let habit = plan.habits.first else {
            XCTFail("计划应该至少有一个习惯")
            return
        }
        
        try await service.completeHabit(habitId: habit.id)
        
        let updatedHabit = try await getHabit(by: habit.id)
        XCTAssertNotNil(updatedHabit)
        XCTAssertEqual(updatedHabit?.totalCompletions, 1)
        XCTAssertEqual(updatedHabit?.completionHistory.count, 1)
    }
    
    func testCompleteHabitTwiceInOneDay() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        guard let habit = plan.habits.first else {
            XCTFail("计划应该至少有一个习惯")
            return
        }
        
        // 第一次完成
        try await service.completeHabit(habitId: habit.id)
        
        // 第二次完成应该失败
        do {
            try await service.completeHabit(habitId: habit.id)
            XCTFail("同一天完成两次习惯应该抛出错误")
        } catch DreamAICoachService.CoachError.habitAlreadyCompleted {
            // 预期错误
        } catch {
            XCTFail("应该抛出 habitAlreadyCompleted 错误")
        }
    }
    
    func testHabitStreakUpdate() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .dreamRecall))
        let plan = try await service.createPlan(from: template)
        
        guard let habit = plan.habits.first else {
            XCTFail("计划应该至少有一个习惯")
            return
        }
        
        // 连续完成 3 天
        for day in 0..<3 {
            let date = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
            try await service.completeHabit(habitId: habit.id, date: date)
        }
        
        let updatedHabit = try await getHabit(by: habit.id)
        XCTAssertEqual(updatedHabit?.streak, 3, "连续天数应该是 3")
        XCTAssertEqual(updatedHabit?.totalCompletions, 3)
    }
    
    func testIsHabitCompletedToday() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        guard let habit = plan.habits.first else {
            XCTFail("计划应该至少有一个习惯")
            return
        }
        
        // 完成前应该返回 false
        var isCompleted = try await service.isHabitCompletedToday(habitId: habit.id)
        XCTAssertFalse(isCompleted)
        
        // 完成后应该返回 true
        try await service.completeHabit(habitId: habit.id)
        isCompleted = try await service.isHabitCompletedToday(habitId: habit.id)
        XCTAssertTrue(isCompleted)
    }
    
    // MARK: - 干预管理测试
    
    func testCreateIntervention() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        let intervention = try await service.createIntervention(
            planId: plan.id,
            type: .encouragement,
            title: "测试干预",
            message: "这是一条测试干预消息",
            triggerReason: "test",
            priority: .medium,
            suggestedAction: "继续加油"
        )
        
        XCTAssertEqual(intervention.planId, plan.id)
        XCTAssertEqual(intervention.interventionType, .encouragement)
        XCTAssertEqual(intervention.title, "测试干预")
        XCTAssertEqual(intervention.status, .pending)
        XCTAssertNotNil(intervention.suggestedAction)
    }
    
    func testGetPendingInterventions() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        // 创建多个干预
        _ = try await service.createIntervention(
            planId: plan.id,
            type: .encouragement,
            title: "干预 1",
            message: "消息 1",
            triggerReason: "test",
            priority: .low
        )
        
        let intervention2 = try await service.createIntervention(
            planId: plan.id,
            type: .suggestion,
            title: "干预 2",
            message: "消息 2",
            triggerReason: "test",
            priority: .medium
        )
        
        // 标记一个为已查看
        try await service.markInterventionViewed(interventionId: intervention2.id)
        
        let pending = try await service.getPendingInterventions()
        
        XCTAssertEqual(pending.count, 1, "应该只有 1 个待处理干预")
        XCTAssertEqual(pending.first?.title, "干预 1")
    }
    
    func testMarkInterventionViewed() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        let intervention = try await service.createIntervention(
            planId: plan.id,
            type: .suggestion,
            title: "测试",
            message: "消息",
            triggerReason: "test",
            priority: .medium
        )
        
        XCTAssertEqual(intervention.status, .pending)
        
        try await service.markInterventionViewed(interventionId: intervention.id)
        
        let updated = try await getIntervention(by: intervention.id)
        XCTAssertEqual(updated?.status, .viewed)
    }
    
    func testMarkInterventionCompleted() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        let intervention = try await service.createIntervention(
            planId: plan.id,
            type: .suggestion,
            title: "测试",
            message: "消息",
            triggerReason: "test",
            priority: .medium,
            suggestedAction: "执行操作"
        )
        
        try await service.markInterventionCompleted(interventionId: intervention.id)
        
        let updated = try await getIntervention(by: intervention.id)
        XCTAssertEqual(updated?.status, .completed)
        XCTAssertNotNil(updated?.completedAt)
    }
    
    func testDismissIntervention() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        let intervention = try await service.createIntervention(
            planId: plan.id,
            type: .suggestion,
            title: "测试",
            message: "消息",
            triggerReason: "test",
            priority: .medium
        )
        
        try await service.dismissIntervention(interventionId: intervention.id)
        
        let updated = try await getIntervention(by: intervention.id)
        XCTAssertEqual(updated?.status, .dismissed)
        XCTAssertNotNil(updated?.dismissedAt)
    }
    
    // MARK: - 统计测试
    
    func testGetStatistics() async throws {
        // 创建一些测试数据
        let template1 = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let template2 = try XCTUnwrap(service.getTemplate(for: .dreamRecall))
        
        let plan1 = try await service.createPlan(from: template1)
        let plan2 = try await service.createPlan(from: template2)
        
        // 完成一些习惯
        if let habit = plan1.habits.first {
            try await service.completeHabit(habitId: habit.id)
        }
        
        let statistics = try await service.getStatistics()
        
        XCTAssertEqual(statistics.totalPlans, 2)
        XCTAssertEqual(statistics.activePlans, 2)
        XCTAssertGreaterThanOrEqual(statistics.totalHabits, 2)
    }
    
    func testGetDailyProgress() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        let plan = try await service.createPlan(from: template)
        
        // 完成今天的习惯
        if let habit = plan.habits.first {
            try await service.completeHabit(habitId: habit.id)
        }
        
        let progress = try await service.getDailyProgress(for: Date())
        
        XCTAssertEqual(progress.date, Date(), granularity: .day)
        XCTAssertGreaterThanOrEqual(progress.habitsCompleted, 1)
    }
    
    // MARK: - AI 建议生成测试
    
    func testGenerateSuggestions() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        _ = try await service.createPlan(from: template)
        
        let suggestions = try await service.generateSuggestions()
        
        // 新创建的计划应该有鼓励建议
        XCTAssertGreaterThan(suggestions.count, 0, "应该生成至少一条建议")
    }
    
    // MARK: - 错误处理测试
    
    func testCompleteNonExistentHabit() async throws {
        let nonExistentId = UUID()
        
        do {
            try await service.completeHabit(habitId: nonExistentId)
            XCTFail("应该抛出错误")
        } catch DreamAICoachService.CoachError.habitNotFound {
            // 预期错误
        } catch {
            XCTFail("应该抛出 habitNotFound 错误")
        }
    }
    
    func testUpdateNonExistentPlan() async throws {
        let nonExistentId = UUID()
        
        do {
            try await service.updatePlanStatus(planId: nonExistentId, status: .completed)
            XCTFail("应该抛出错误")
        } catch DreamAICoachService.CoachError.planNotFound {
            // 预期错误
        } catch {
            XCTFail("应该抛出 planNotFound 错误")
        }
    }
    
    func testDeleteNonExistentPlan() async throws {
        let nonExistentId = UUID()
        
        do {
            try await service.deletePlan(planId: nonExistentId)
            XCTFail("应该抛出错误")
        } catch DreamAICoachService.CoachError.planNotFound {
            // 预期错误
        } catch {
            XCTFail("应该抛出 planNotFound 错误")
        }
    }
    
    // MARK: - 辅助方法
    
    private func getHabit(by id: UUID) async throws -> DreamAICoachHabit? {
        let descriptor = FetchDescriptor<DreamAICoachHabit>(
            predicate: #Predicate<DreamAICoachHabit> { $0.id == id }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        return results.first
    }
    
    private func getIntervention(by id: UUID) async throws -> DreamAICoachIntervention? {
        let descriptor = FetchDescriptor<DreamAICoachIntervention>(
            predicate: #Predicate<DreamAICoachIntervention> { $0.id == id }
        )
        let results = try modelContainer.mainContext.fetch(descriptor)
        return results.first
    }
}

// MARK: - 性能测试

@available(iOS 17.0, *)
final class DreamAICoachPerformanceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var service: DreamAICoachService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            DreamAICoachPlan.self,
            DreamAICoachHabit.self,
            DreamAICoachIntervention.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        service = DreamAICoachService(modelContainer: modelContainer)
    }
    
    func testCreatePlanPerformance() async throws {
        let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
        
        measure {
            let expectation = XCTestExpectation(description: "Create plan")
            
            Task {
                try? await service.createPlan(from: template)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testGetStatisticsPerformance() async throws {
        // 创建测试数据
        for _ in 0..<10 {
            let template = try XCTUnwrap(service.getTemplate(for: .sleepImprovement))
            let plan = try await service.createPlan(from: template)
            
            if let habit = plan.habits.first {
                try await service.completeHabit(habitId: habit.id)
            }
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Get statistics")
            
            Task {
                _ = try? await service.getStatistics()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
