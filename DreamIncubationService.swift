//
//  DreamIncubationService.swift
//  DreamLog - 梦境孵化核心服务
//
//  提供梦境孵化的创建、管理、跟踪和分析功能
//

import Foundation
import SwiftData
import Combine

// MARK: - 梦境孵化服务

@MainActor
final class DreamIncubationService: ObservableObject {
    // MARK: - Published Properties
    
    @Published var incubations: [DreamIncubation] = []
    @Published var activeIncubation: DreamIncubation?
    @Published var stats: IncubationStats = IncubationStats()
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchIncubations()
        calculateStats()
    }
    
    // MARK: - CRUD Operations
    
    /// 获取所有孵化记录
    func fetchIncubations() {
        isLoading = true
        error = nil
        
        do {
            let descriptor = FetchDescriptor<DreamIncubation>(
                sortBy: [SortDescriptor(\.targetDate, order: .reverse)]
            )
            incubations = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    /// 创建新的孵化记录
    func createIncubation(
        targetType: IncubationTargetType,
        title: String,
        description: String = "",
        intention: String,
        intensity: IncubationIntensity = .moderate,
        targetDate: Date = Date(),
        tags: [String] = [],
        affirmations: [String] = []
    ) async throws -> DreamIncubation {
        isLoading = true
        error = nil
        
        do {
            let incubation = DreamIncubation(
                targetDate: targetDate,
                targetType: targetType,
                title: title,
                description: description,
                intention: intention,
                intensity: intensity,
                tags: tags,
                affirmations: affirmations
            )
            
            modelContext.insert(incubation)
            try modelContext.save()
            
            incubations.insert(incubation, at: 0)
            calculateStats()
            
            isLoading = false
            return incubation
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
    }
    
    /// 更新孵化记录
    func updateIncubation(_ incubation: DreamIncubation) async throws {
        error = nil
        
        do {
            try modelContext.save()
            if let index = incubations.firstIndex(where: { $0.id == incubation.id }) {
                incubations[index] = incubation
            }
            calculateStats()
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// 标记孵化为已完成
    func markAsCompleted(_ incubation: DreamIncubation, meditationMinutes: Int = 0) async throws {
        incubation.completed = true
        incubation.completedAt = Date()
        incubation.meditationMinutes = meditationMinutes
        try await updateIncubation(incubation)
    }
    
    /// 删除孵化记录
    func deleteIncubation(_ incubation: DreamIncubation) async throws {
        error = nil
        
        do {
            modelContext.delete(incubation)
            try modelContext.save()
            
            incubations.removeAll { $0.id == incubation.id }
            calculateStats()
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// 批量删除孵化记录
    func deleteIncubations(_ incubations: [DreamIncubation]) async throws {
        for incubation in incubations {
            modelContext.delete(incubation)
        }
        try modelContext.save()
        
        self.incubations.removeAll { incubations.contains($0) }
        calculateStats()
    }
    
    // MARK: - Success Tracking
    
    /// 记录孵化成功评级
    func recordSuccessRating(_ incubation: DreamIncubation, rating: Int, notes: String = "") async throws {
        guard rating >= 1 && rating <= 5 else {
            throw IncubationError.invalidRating
        }
        
        incubation.successRating = rating
        incubation.success = rating >= 3
        if !notes.isEmpty {
            incubation.notes = notes
        }
        
        try await updateIncubation(incubation)
    }
    
    /// 关联梦境到孵化记录
    func linkDream(_ dreamId: UUID, to incubation: DreamIncubation) async throws {
        if !incubation.relatedDreamIds.contains(dreamId) {
            incubation.relatedDreamIds.append(dreamId)
            try await updateIncubation(incubation)
        }
    }
    
    // MARK: - Templates
    
    /// 获取所有预设模板
    func getTemplates() -> [IncubationTemplate] {
        return IncubationTemplate.templates
    }
    
    /// 从模板创建孵化
    func createFromTemplate(
        _ template: IncubationTemplate,
        customIntention: String? = nil,
        intensity: IncubationIntensity? = nil
    ) async throws -> DreamIncubation {
        try await createIncubation(
            targetType: template.targetType,
            title: template.name,
            description: template.guidance,
            intention: customIntention ?? template.defaultIntention,
            intensity: intensity ?? template.recommendedIntensity,
            affirmations: template.suggestedAffirmations
        )
    }
    
    // MARK: - Statistics
    
    /// 计算统计数据
    func calculateStats() {
        var newStats = IncubationStats()
        
        newStats.totalIncubations = incubations.count
        newStats.completedIncubations = incubations.filter { $0.completed }.count
        
        let ratedIncubations = incubations.filter { $0.successRating != nil }
        if !ratedIncubations.isEmpty {
            let totalRating = ratedIncubations.reduce(0) { $0 + ($1.successRating ?? 0) }
            newStats.averageSuccessRating = Double(totalRating) / Double(ratedIncubations.count)
            newStats.successRate = Double(incubations.filter { $0.success == true }.count) / Double(ratedIncubations.count)
        }
        
        // 按类型统计
        var typeCounts: [IncubationTargetType: Int] = [:]
        var typeSuccess: [IncubationTargetType: (success: Int, total: Int)] = [:]
        
        for incubation in incubations {
            typeCounts[incubation.targetType, default: 0] += 1
            
            if let success = incubation.success {
                var entry = typeSuccess[incubation.targetType] ?? (success: 0, total: 0)
                if success { entry.success += 1 }
                entry.total += 1
                typeSuccess[incubation.targetType] = entry
            }
        }
        
        newStats.incubationsByType = typeCounts
        
        // 计算各类型成功率
        for (type, data) in typeSuccess {
            if data.total > 0 {
                newStats.successByType[type] = Double(data.success) / Double(data.total)
            }
        }
        
        // 找出最成功的类型
        if let bestType = newStats.successByType.max(by: { $0.value < $1.value })?.key {
            newStats.mostSuccessfulType = bestType
        }
        
        // 计算连续天数
        calculateStreaks(&newStats)
        
        // 总冥想时长
        newStats.totalMeditationMinutes = incubations.reduce(0) { $0 + $1.meditationMinutes }
        
        stats = newStats
    }
    
    /// 计算连续天数
    private func calculateStreaks(_ stats: inout IncubationStats) {
        let completedDates = incubations
            .filter { $0.completed }
            .map { Calendar.current.startOfDay(for: $0.completedAt ?? $0.targetDate) }
            .sorted(by: >)
        
        guard !completedDates.isEmpty else {
            stats.currentStreak = 0
            stats.longestStreak = 0
            return
        }
        
        // 当前连续天数
        var currentStreak = 1
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        if completedDates[0] == today || completedDates[0] == yesterday {
            for i in 1..<completedDates.count {
                let expectedDate = Calendar.current.date(byAdding: .day, value: -i, to: completedDates[0])!
                if completedDates[i] == expectedDate {
                    currentStreak += 1
                } else {
                    break
                }
            }
        } else {
            currentStreak = 0
        }
        
        stats.currentStreak = currentStreak
        
        // 最长连续天数
        var longestStreak = 1
        var tempStreak = 1
        
        for i in 1..<completedDates.count {
            let expectedDate = Calendar.current.date(byAdding: .day, value: -1, to: completedDates[i-1])!
            if completedDates[i] == expectedDate {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 1
            }
        }
        
        stats.longestStreak = longestStreak
    }
    
    // MARK: - Filtering & Searching
    
    /// 按类型筛选
    func filterByType(_ type: IncubationTargetType) -> [DreamIncubation] {
        return incubations.filter { $0.targetType == type }
    }
    
    /// 按完成状态筛选
    func filterByCompleted(_ completed: Bool) -> [DreamIncubation] {
        return incubations.filter { $0.completed == completed }
    }
    
    /// 按日期范围筛选
    func filterByDateRange(start: Date, end: Date) -> [DreamIncubation] {
        return incubations.filter { $0.targetDate >= start && $0.targetDate <= end }
    }
    
    /// 搜索孵化记录
    func search(_ query: String) -> [DreamIncubation] {
        let lowercasedQuery = query.lowercased()
        return incubations.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.intention.lowercased().contains(lowercasedQuery) ||
            $0.description.lowercased().contains(lowercasedQuery) ||
            $0.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    // MARK: - Guidance
    
    /// 获取孵化指南
    func getGuidance(for targetType: IncubationTargetType, intensity: IncubationIntensity) -> String {
        let baseGuidance: [IncubationTargetType: String] = [
            .problemSolving: """
                1. 清晰定义你的问题
                2. 睡前回顾问题的各个方面
                3. 想象在梦中获得答案的场景
                4. 相信你的潜意识会工作
                5. 醒来后立即记录任何梦境
                """,
            .creativity: """
                1. 明确你的创作目标
                2. 收集相关的灵感素材
                3. 睡前进行创意冥想
                4. 想象作品完成的样子
                5. 保持开放的心态接受任何灵感
                """,
            .emotionalHealing: """
                1. 创造一个安全的心理空间
                2. 允许情绪自然浮现
                3. 对自己保持温柔和耐心
                4. 想象疗愈的光包围你
                5. 信任内在的疗愈力量
                """,
            .skillPractice: """
                1. 了解清醒梦的技巧
                2. 白天进行现实检查
                3. 睡前回顾梦境迹象
                4. 设定清晰的意图
                5. 保持放松和专注
                """,
            .exploration: """
                1. 选择你想探索的场景
                2. 收集相关的视觉素材
                3. 睡前进行可视化练习
                4. 想象身临其境的感觉
                5. 保持好奇和开放
                """,
            .spiritual: """
                1. 设定你的精神意图
                2. 进行冥想或祈祷
                3. 创造神圣的空间
                4. 保持谦卑和开放
                5. 信任更高的智慧
                """,
            .memory: """
                1. 温和地回顾记忆
                2. 不强迫或评判
                3. 允许新的视角出现
                4. 相信时间的疗愈
                5. 寻求整合和理解
                """,
            .general: """
                1. 设定清晰的意图
                2. 保持放松的状态
                3. 信任这个过程
                4. 记录任何梦境内容
                5. 保持耐心和练习
                """
        ]
        
        let intensityNote: [IncubationIntensity: String] = [
            .light: "💡 轻度：简单思考即可，不需要太多准备",
            .moderate: "🧘 中度：建议花 5-10 分钟专注冥想",
            .strong: "🌟 强烈：需要 15-20 分钟的深度准备",
            .intense: "✨ 极致：进行完整的孵化仪式，包括冥想、可视化和肯定语"
        ]
        
        return """
            \(baseGuidance[targetType] ?? "")
            
            \(intensityNote[intensity] ?? "")
            """
    }
    
    /// 生成个性化肯定语
    func generateAffirmations(for targetType: IncubationTargetType) -> [String] {
        let commonAffirmations = [
            "我会记住我的梦境",
            "我的梦境充满智慧和启示",
            "我醒来时感觉 refreshed 和 inspired"
        ]
        
        let typeSpecific: [IncubationTargetType: [String]] = [
            .problemSolving: [
                "我的潜意识拥有所有答案",
                "我会在梦中看到清晰的解决方案",
                "我信任我的内在智慧"
            ],
            .creativity: [
                "创意能量在我体内自由流动",
                "我的梦境是创意的源泉",
                "我醒来时会记住所有灵感"
            ],
            .emotionalHealing: [
                "我释放所有的恐惧和担忧",
                "我的内心充满平静和爱",
                "我在梦中得到完全的疗愈"
            ],
            .skillPractice: [
                "我会意识到自己在做梦",
                "我能控制我的梦境",
                "每次做梦我都变得更熟练"
            ],
            .exploration: [
                "我的梦境是无限的冒险",
                "我可以去任何我想去的地方",
                "我享受每一次梦境探索"
            ],
            .spiritual: [
                "我与更高的智慧连接",
                "我的梦境是精神的指引",
                "我在梦中获得深刻的领悟"
            ],
            .memory: [
                "我温和地处理我的记忆",
                "我允许疗愈自然发生",
                "我在梦中找到平静"
            ],
            .general: commonAffirmations
        ]
        
        return typeSpecific[targetType] ?? commonAffirmations
    }
}

// MARK: - Errors

enum IncubationError: LocalizedError {
    case invalidRating
    case invalidDate
    case notFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidRating: return "评级必须在 1-5 之间"
        case .invalidDate: return "日期无效"
        case .notFound: return "孵化记录未找到"
        case .saveFailed: return "保存失败"
        }
    }
}

// MARK: - Preview Data

extension DreamIncubation {
    static var preview: DreamIncubation {
        let incubation = DreamIncubation(
            targetType: .creativity,
            title: "获取写作灵感",
            intention: "今晚我将在梦中获得关于新故事的灵感",
            intensity: .moderate,
            tags: ["写作", "创意", "故事"],
            affirmations: [
                "创意能量在我体内流动",
                "我的梦境充满创意的启示"
            ]
        )
        incubation.completed = true
        incubation.meditationMinutes = 15
        incubation.successRating = 4
        incubation.success = true
        return incubation
    }
}
