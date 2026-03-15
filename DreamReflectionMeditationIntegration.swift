//
//  DreamReflectionMeditationIntegration.swift
//  DreamLog
//
//  Phase 50: 反思与冥想集成
//  基于反思内容推荐冥想练习
//

import Foundation
import SwiftData
import AVFoundation

// MARK: - 冥想推荐

/// 反思冥想推荐
struct ReflectionMeditationRecommendation {
    let reflection: DreamReflection
    let meditationType: MeditationType
    let reason: String
    let duration: Int  // 分钟
    let confidence: Double  // 0-1
    
    enum MeditationType: String, CaseIterable {
        case mindfulness = "正念冥想"
        case lovingKindness = "慈心冥想"
        case bodyScan = "身体扫描"
        case visualization = "可视化冥想"
        case breathing = "呼吸冥想"
        case sleep = "睡眠冥想"
        
        var icon: String {
            switch self {
            case .mindfulness: return "🧘"
            case .lovingKindness: return "💖"
            case .bodyScan: return "👤"
            case .visualization: return "🌈"
            case .breathing: return "🌬️"
            case .sleep: return "😴"
            }
        }
        
        var description: String {
            switch self {
            case .mindfulness: return "培养当下觉察，接纳不评判"
            case .lovingKindness: return "培养对自己和他人的善意"
            case .bodyScan: return "逐步觉察身体感受"
            case .visualization: return "引导想象，探索内心"
            case .breathing: return "专注于呼吸，平静心绪"
            case .sleep: return "放松身心，准备入睡"
            }
        }
    }
}

// MARK: - 集成服务

/// 反思冥想集成服务
@MainActor
class ReflectionMeditationIntegration {
    
    static let shared = ReflectionMeditationIntegration()
    
    private let modelContext: ModelContext
    private let meditationService: MeditationService
    
    init(modelContext: ModelContext? = nil,
         meditationService: MeditationService = .shared) {
        self.modelContext = modelContext ?? (try? AppController.shared?.modelContext) ?? AppController.createPreviewContext()
        self.meditationService = meditationService
    }
    
    // MARK: - 推荐冥想
    
    /// 基于反思内容推荐冥想
    func recommendMeditation(for reflection: DreamReflection) -> ReflectionMeditationRecommendation {
        let type = reflection.reflectionType
        let content = reflection.content.lowercased()
        
        // 分析反思内容关键词
        let keywords = analyzeKeywords(content)
        
        // 确定冥想类型
        let meditationType = determineMeditationType(type: type, keywords: keywords, reflection: reflection)
        
        // 生成推荐理由
        let reason = generateReason(type: meditationType, reflection: reflection)
        
        // 确定时长
        let duration = determineDuration(reflection: reflection)
        
        // 计算置信度
        let confidence = calculateConfidence(type: type, keywords: keywords)
        
        return ReflectionMeditationRecommendation(
            reflection: reflection,
            meditationType: meditationType,
            reason: reason,
            duration: duration,
            confidence: confidence
        )
    }
    
    /// 分析关键词
    private func analyzeKeywords(_ content: String) -> Set<String> {
        var keywords: Set<String> = []
        
        // 情绪关键词
        let emotionKeywords = ["焦虑", "恐惧", "紧张", "压力", "不安", "愤怒", "悲伤", "快乐", "平静", "兴奋"]
        for keyword in emotionKeywords {
            if content.contains(keyword) {
                keywords.insert("emotion:\(keyword)")
            }
        }
        
        // 主题关键词
        let themeKeywords = ["工作", "学习", "关系", "家庭", "朋友", "健康", "梦想", "目标", "未来", "过去"]
        for keyword in themeKeywords {
            if content.contains(keyword) {
                keywords.insert("theme:\(keyword)")
            }
        }
        
        // 行动关键词
        let actionKeywords = ["需要", "应该", "想要", "决定", "改变", "接受", "放下", "面对"]
        for keyword in actionKeywords {
            if content.contains(keyword) {
                keywords.insert("action:\(keyword)")
            }
        }
        
        return keywords
    }
    
    /// 确定冥想类型
    private func determineMeditationType(type: ReflectionType,
                                         keywords: Set<String>,
                                         reflection: DreamReflection) -> ReflectionMeditationRecommendation.MeditationType {
        // 基于反思类型
        switch type {
        case .emotion:
            if keywords.contains("emotion:焦虑") || keywords.contains("emotion:恐惧") {
                return .breathing
            }
            if keywords.contains("emotion:愤怒") || keywords.contains("emotion:悲伤") {
                return .lovingKindness
            }
            return .mindfulness
            
        case .question:
            return .mindfulness
            
        case .intention:
            return .visualization
            
        case .insight:
            return .mindfulness
            
        case .connection:
            return .mindfulness
            
        case .gratitude:
            return .lovingKindness
        }
    }
    
    /// 生成推荐理由
    private func generateReason(type: ReflectionMeditationRecommendation.MeditationType,
                                reflection: DreamReflection) -> String {
        switch type {
        case .mindfulness:
            return "通过正念冥想，你可以更深入地观察这个洞察，不加评判地接纳它"
        case .lovingKindness:
            return "慈心冥想可以帮助你培养对自己和他人的善意，特别适合处理情绪相关的反思"
        case .bodyScan:
            return "身体扫描可以帮助你觉察身体中储存的情绪和感受"
        case .visualization:
            return "可视化冥想可以帮助你更清晰地探索这个意图或目标"
        case .breathing:
            return "专注于呼吸可以帮助你平静心绪，更好地处理焦虑或压力"
        case .sleep:
            return "睡前冥想可以帮助你整合今天的反思，获得更好的睡眠"
        }
    }
    
    /// 确定冥想时长
    private func determineDuration(reflection: DreamReflection) -> Int {
        // 基于反思深度
        if reflection.rating >= 5 {
            return 15  // 深度反思，较长冥想
        } else if reflection.rating >= 3 {
            return 10  // 中等反思
        } else {
            return 5   // 简单反思
        }
    }
    
    /// 计算置信度
    private func calculateConfidence(type: ReflectionType, keywords: Set<String>) -> Double {
        var confidence = 0.5  // 基础置信度
        
        // 关键词越多，置信度越高
        confidence += min(Double(keywords.count) * 0.1, 0.3)
        
        // 某些反思类型置信度更高
        switch type {
        case .emotion, .question:
            confidence += 0.1
        case .insight:
            confidence += 0.05
        default:
            break
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - 冥想会话追踪
    
    /// 记录冥想会话
    func logMeditationSession(for reflection: DreamReflection,
                              meditationType: ReflectionMeditationRecommendation.MeditationType,
                              duration: Int) {
        let session = MeditationSession(
            reflectionId: reflection.id,
            meditationType: meditationType.rawValue,
            duration: duration,
            completedAt: Date()
        )
        
        try? modelContext.insert(session)
        try? modelContext.save()
        
        print("📝 记录冥想会话：\(reflection.id) - \(meditationType) - \(duration)分钟")
    }
    
    /// 获取反思冥想统计
    func getMeditationStats() -> ReflectionMeditationStats {
        let descriptor = FetchDescriptor<MeditationSession>()
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        
        let totalSessions = sessions.count
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration }
        
        // 计算最喜欢的冥想类型
        let typeCounts = Dictionary(grouping: sessions, by: { $0.meditationType })
            .mapValues { $0.count }
        let favoriteTypeRaw = typeCounts.max(by: { $0.value < $1.value })?.key ?? ReflectionMeditationRecommendation.MeditationType.mindfulness.rawValue
        let favoriteType = ReflectionMeditationRecommendation.MeditationType(rawValue: favoriteTypeRaw) ?? .mindfulness
        
        // 计算连续天数
        let streakDays = calculateStreak(sessions: sessions)
        
        return ReflectionMeditationStats(
            totalSessions: totalSessions,
            totalMinutes: totalMinutes,
            favoriteType: favoriteType,
            streakDays: streakDays
        )
    }
    
    /// 计算连续冥想天数
    private func calculateStreak(sessions: [MeditationSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedSessions = sessions.sorted { $0.completedAt > $1.completedAt }
        
        var streak = 1
        var currentDate = calendar.startOfDay(for: sortedSessions[0].completedAt)
        
        for i in 1..<sortedSessions.count {
            let sessionDate = calendar.startOfDay(for: sortedSessions[i].completedAt)
            let daysDiff = calendar.dateComponents([.day], from: sessionDate, to: currentDate).day ?? 0
            
            if daysDiff == 1 {
                streak += 1
                currentDate = sessionDate
            } else if daysDiff > 1 {
                break
            }
            // daysDiff == 0 表示同一天多次冥想，继续
        }
        
        return streak
    }
    
    // MARK: - 开始冥想
    
    /// 开始推荐冥想
    func startMeditation(_ recommendation: ReflectionMeditationRecommendation) async {
        // 调用冥想服务开始冥想
        await meditationService.startMeditation(
            type: mapToMeditationType(recommendation.meditationType),
            duration: recommendation.duration
        )
        
        // 记录会话
        logMeditationSession(
            for: recommendation.reflection,
            meditationType: recommendation.meditationType,
            duration: recommendation.duration
        )
    }
    
    private func mapToMeditationType(_ type: ReflectionMeditationRecommendation.MeditationType) -> MeditationType {
        // 映射到冥想服务的类型
        switch type {
        case .mindfulness: return .mindfulness
        case .lovingKindness: return .lovingKindness
        case .bodyScan: return .bodyScan
        case .visualization: return .visualization
        case .breathing: return .breathing
        case .sleep: return .sleep
        }
    }
}

// MARK: - 统计模型

/// 反思冥想统计
struct ReflectionMeditationStats {
    var totalSessions: Int
    var totalMinutes: Int
    var favoriteType: ReflectionMeditationRecommendation.MeditationType
    var streakDays: Int
}

// MARK: - 冥想会话模型

/// 冥想会话记录 (SwiftData 模型)
@Model
class MeditationSession {
    var id: UUID
    var reflectionId: UUID
    var meditationType: String
    var duration: Int  // 分钟
    var completedAt: Date
    
    init(reflectionId: UUID,
         meditationType: String,
         duration: Int,
         completedAt: Date = Date()) {
        self.id = UUID()
        self.reflectionId = reflectionId
        self.meditationType = meditationType
        self.duration = duration
        self.completedAt = completedAt
    }
}

// MARK: - 冥想服务

/// 冥想服务
@MainActor
class MeditationService {
    
    static let shared = MeditationService()
    
    private var currentSession: UUID?
    private var isPlaying: Bool = false
    
    /// 开始冥想
    func startMeditation(type: MeditationType, duration: Int) async {
        print("🧘 开始冥想：\(type) - \(duration)分钟")
        
        // 在真实场景中，这里会：
        // 1. 播放冥想音频 (使用 AVPlayer)
        // 2. 显示冥想引导界面
        // 3. 设置定时器提醒结束
        // 4. 追踪冥想进度
        
        isPlaying = true
        currentSession = UUID()
        
        // 模拟冥想音频播放
        try? await Task.sleep(nanoseconds: UInt64(duration * 60 * 1_000_000_000))
        
        isPlaying = false
        currentSession = nil
        
        print("✅ 冥想完成")
    }
    
    /// 暂停冥想
    func pauseMeditation() {
        isPlaying = false
        print("⏸️ 冥想已暂停")
    }
    
    /// 恢复冥想
    func resumeMeditation() {
        isPlaying = true
        print("▶️ 冥想已恢复")
    }
    
    /// 停止冥想
    func stopMeditation() {
        isPlaying = false
        currentSession = nil
        print("⏹️ 冥想已停止")
    }
    
    /// 获取当前冥想状态
    func isMeditating() -> Bool {
        return isPlaying
    }
}

/// 冥想类型
enum MeditationType: String {
    case mindfulness = "正念冥想"
    case lovingKindness = "慈心冥想"
    case bodyScan = "身体扫描"
    case visualization = "可视化冥想"
    case breathing = "呼吸冥想"
    case sleep = "睡眠冥想"
    
    var icon: String {
        switch self {
        case .mindfulness: return "🧘"
        case .lovingKindness: return "💖"
        case .bodyScan: return "👤"
        case .visualization: return "🌈"
        case .breathing: return "🌬️"
        case .sleep: return "😴"
        }
    }
}
