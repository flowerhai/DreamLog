//
//  DreamSceneAnalysisService.swift
//  DreamLog
//
//  梦境场景分析服务：分析梦境场景并提供洞察
//

import Foundation
import SwiftUI

actor DreamSceneAnalysisService {
    
    // MARK: - Properties
    
    private var analyses: [DreamSceneAnalysis] = []
    private var config: SceneAnalysisConfig = .default
    private let store: DreamStore
    
    // 场景关键词映射
    private let sceneKeywords: [DreamSceneType: [String]] = [
        .indoor: ["房间", "室内", "里面", "屋内", "建筑", "大楼", "商场", "酒店", "餐厅", "咖啡馆"],
        .outdoor: ["户外", "外面", "露天", "野外", "公园", "广场", "街道"],
        .urban: ["城市", "都市", "高楼", "大厦", "马路", "车流", "霓虹", "市中心"],
        .nature: ["自然", "森林", "树木", "草地", "花朵", "山野", "田园", "植物"],
        .water: ["水", "海洋", "河流", "湖泊", "泳池", "海边", "沙滩", "波浪", "雨"],
        .sky: ["天空", "云", "飞行", "空中", "飞机", "鸟", "太阳", "月亮", "星星"],
        .underground: ["地下", "洞穴", "隧道", "地铁", "地底", "深渊", "矿井"],
        .fantastical: ["奇幻", "魔法", "神秘", "异世界", "超现实", "梦境", "幻想", "神奇"],
        .familiar: ["熟悉", "认识", "来过", "以前", "记得"],
        .unfamiliar: ["陌生", "不认识", "第一次", "新奇", "未知"],
        .childhood: ["童年", "小时候", "儿时", "幼儿园", "老家", "外婆", "奶奶"],
        .school: ["学校", "教室", "老师", "同学", "考试", "作业", "操场", "图书馆"],
        .home: ["家", "家里", "房间", "卧室", "客厅", "厨房", "卫生间", "阳台"],
        .workplace: ["工作", "公司", "办公室", "会议", "同事", "老板", "上班"],
        .transportation: ["车", "火车", "飞机", "船", "公交", "地铁", "出租车", "驾驶"],
        .other: []
    ]
    
    // 环境因素关键词
    private let environmentKeywords: [EnvironmentalFactor.EnvironmentalFactorType: [String]] = [
        .lighting: ["亮", "暗", "光", "阳光", "灯光", "昏暗", "明亮", "阴影", "黑暗"],
        .weather: ["晴", "雨", "雪", "风", "云", "雾", "雷", "闪电", "阴天"],
        .temperature: ["热", "冷", "温暖", "凉爽", "炎热", "寒冷", "温度"],
        .sound: ["声音", "安静", "吵闹", "音乐", "噪音", "寂静", "响声"],
        .crowding: ["人多", "拥挤", "热闹", "空旷", "无人", "稀少", "拥挤"],
        .familiarity: ["熟悉", "陌生", "认识", "不认识", "来过", "第一次"],
        .safety: ["安全", "危险", "害怕", "恐惧", "安心", "威胁", "保护"],
        .openness: ["开阔", "狭窄", "宽敞", "封闭", "开放", "压抑"]
    ]
    
    // MARK: - Initialization
    
    init(store: DreamStore = DreamStore.shared) {
        self.store = store
        loadAnalyses()
    }
    
    // MARK: - Public Methods
    
    /// 分析梦境场景
    func analyzeDream(_ dream: Dream) async -> DreamSceneAnalysis {
        let content = (dream.title + " " + dream.content).lowercased()
        
        // 检测场景类型
        var detectedScenes: [(scene: DreamSceneType, score: Int)] = []
        
        for (sceneType, keywords) in sceneKeywords {
            guard !keywords.isEmpty else { continue }
            let score = keywords.reduce(0) { count, keyword in
                count + (content.contains(keyword.lowercased()) ? 1 : 0)
            }
            if score > 0 {
                detectedScenes.append((scene: sceneType, score: score))
            }
        }
        
        // 排序并获取主要场景
        detectedScenes.sort { $0.score > $1.score }
        let primaryScene = detectedScenes.first?.scene ?? .other
        let detectedSceneTypes = detectedScenes.map { $0.scene }
        
        // 计算置信度
        let totalScore = detectedScenes.reduce(0) { $0 + $1.score }
        let confidence = min(1.0, Double(totalScore) / 10.0)
        
        // 检测环境因素
        let environmentalFactors = detectEnvironmentalFactors(in: content)
        
        // 生成场景描述
        let sceneDescription = generateSceneDescription(
            primaryScene: primaryScene,
            detectedScenes: detectedSceneTypes,
            factors: environmentalFactors
        )
        
        let analysis = DreamSceneAnalysis(
            dreamId: dream.id,
            detectedScenes: detectedSceneTypes,
            primaryScene: primaryScene,
            confidence: confidence,
            sceneDescription: sceneDescription,
            environmentalFactors: environmentalFactors
        )
        
        // 保存分析结果
        await saveAnalysis(analysis)
        
        return analysis
    }
    
    /// 批量分析梦境
    func analyzeDreams(_ dreams: [Dream]) async -> [DreamSceneAnalysis] {
        var results: [DreamSceneAnalysis] = []
        
        for dream in dreams {
            let analysis = await analyzeDream(dream)
            results.append(analysis)
        }
        
        return results
    }
    
    /// 获取梦境的场景分析
    func getAnalysis(for dreamId: UUID) async -> DreamSceneAnalysis? {
        return analyses.first { $0.dreamId == dreamId }
    }
    
    /// 获取所有分析
    func getAllAnalyses() async -> [DreamSceneAnalysis] {
        return analyses
    }
    
    /// 获取统计摘要
    func getSummary(dateRange: ClosedRange<Date>? = nil) async -> SceneAnalysisSummary {
        let filteredAnalyses: [DreamSceneAnalysis]
        if let range = dateRange {
            filteredAnalyses = analyses.filter { range.contains($0.createdAt) }
        } else {
            filteredAnalyses = analyses
        }
        
        let totalDreams = await store.dreams.count
        let analyzedDreams = filteredAnalyses.count
        
        // 计算场景分布
        var sceneCounts: [DreamSceneType: Int] = [:]
        for analysis in filteredAnalyses {
            for scene in analysis.detectedScenes {
                sceneCounts[scene, default: 0] += 1
            }
        }
        
        let topScenes = sceneCounts.map { sceneType, count in
            let trend = calculateTrend(for: sceneType, in: allDreams)
            return SceneDistribution(
                sceneType: sceneType,
                count: count,
                percentage: Double(count) / Double(max(1, analyzedDreams)) * 100,
                trend: trend
            )
        }.sorted { $0.count > $1.count }
        
        // 计算场景多样性
        let sceneDiversity = calculateDiversity(sceneCounts: sceneCounts)
        
        // 找出最常见和最少见的场景
        let favoriteScene = topScenes.first?.sceneType
        let rareScene = topScenes.last?.sceneType
        
        // 平均置信度
        let averageConfidence = filteredAnalyses.isEmpty ? 0 :
            filteredAnalyses.reduce(0) { $0 + $1.confidence } / Double(filteredAnalyses.count)
        
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        return SceneAnalysisSummary(
            totalDreams: totalDreams,
            analyzedDreams: analyzedDreams,
            topScenes: Array(topScenes.prefix(10)),
            sceneDiversity: sceneDiversity,
            favoriteScene: favoriteScene,
            rareScene: rareScene,
            averageConfidence: averageConfidence,
            timeRange: SceneAnalysisSummary.DateRange(
                startDate: thirtyDaysAgo,
                endDate: now
            )
        )
    }
    
    /// 生成场景洞察
    func generateInsights() async -> [SceneInsight] {
        var insights: [SceneInsight] = []
        
        let summary = await getSummary()
        
        // 偏好洞察
        if let favoriteScene = summary.favoriteScene, summary.topScenes.first?.percentage ?? 0 > 30 {
            insights.append(SceneInsight(
                id: UUID(),
                type: .preference,
                title: "场景偏好",
                description: "你的梦境经常出现在\(favoriteScene.displayName)，这可能反映了你的心理舒适区",
                icon: favoriteScene.icon,
                color: favoriteScene.color,
                relatedScenes: [favoriteScene],
                actionable: true,
                suggestion: "尝试记录在这些场景中的梦境细节，探索为什么这些地方经常出现"
            ))
        }
        
        // 多样性洞察
        if summary.sceneDiversity < 0.3 {
            insights.append(SceneInsight(
                id: UUID(),
                type: .pattern,
                title: "场景单一",
                description: "你的梦境场景比较单一，可能意味着生活模式较为固定",
                icon: "repeat",
                color: .orange,
                relatedScenes: summary.topScenes.map { $0.sceneType },
                actionable: true,
                suggestion: "尝试新的活动和体验，可能会带来更丰富的梦境内容"
            ))
        } else if summary.sceneDiversity > 0.7 {
            insights.append(SceneInsight(
                id: UUID(),
                type: .pattern,
                title: "场景丰富",
                description: "你的梦境场景非常多样化，想象力丰富",
                icon: "sparkles",
                color: .purple,
                relatedScenes: summary.topScenes.map { $0.sceneType },
                actionable: false,
                suggestion: nil
            ))
        }
        
        // 场景 - 情绪关联洞察
        let correlations = await getSceneEmotionCorrelations()
        for correlation in correlations.prefix(3) where abs(correlation.correlationStrength) > 0.5 {
            insights.append(SceneInsight(
                id: UUID(),
                type: .emotional,
                title: "场景情绪关联",
                description: "在\(correlation.sceneType.displayName)场景中，你经常感到\(correlation.emotion.displayName)",
                icon: "heart.fill",
                color: correlation.emotion.color,
                relatedScenes: [correlation.sceneType],
                actionable: true,
                suggestion: "注意这种场景和情绪的关联，可能有助于理解潜意识"
            ))
        }
        
        return insights
    }
    
    /// 获取场景 - 情绪关联
    func getSceneEmotionCorrelations() async -> [SceneEmotionCorrelation] {
        var correlations: [SceneEmotionCorrelation] = []
        let dreams = await store.dreams
        
        for sceneType in DreamSceneType.allCases {
            let sceneDreams = dreams.filter { dream in
                analyses.contains { $0.dreamId == dream.id && $0.detectedScenes.contains(sceneType) }
            }
            
            for emotion in DreamEmotion.allCases {
                let emotionDreams = sceneDreams.filter { $0.emotions.contains(emotion) }
                guard !emotionDreams.isEmpty else { continue }
                
                let correlationStrength = Double(emotionDreams.count) / Double(max(1, sceneDreams.count))
                let avgIntensity = emotionDreams.reduce(0.0) { 
                    $0 + Double($1.emotionIntensity) 
                } / Double(emotionDreams.count)
                
                correlations.append(SceneEmotionCorrelation(
                    sceneType: sceneType,
                    emotion: emotion,
                    correlationStrength: correlationStrength,
                    occurrenceCount: emotionDreams.count,
                    averageIntensity: avgIntensity
                ))
            }
        }
        
        return correlations.sorted { abs($0.correlationStrength) > abs($1.correlationStrength) }
    }
    
    /// 更新配置
    func updateConfig(_ newConfig: SceneAnalysisConfig) async {
        config = newConfig
        saveConfig()
    }
    
    /// 获取配置
    func getConfig() async -> SceneAnalysisConfig {
        return config
    }
    
    // MARK: - Private Methods
    
    private func detectEnvironmentalFactors(in content: String) -> [EnvironmentalFactor] {
        var factors: [EnvironmentalFactor] = []
        
        for (factorType, keywords) in environmentKeywords {
            let matches = keywords.filter { content.contains($0.lowercased()) }
            if !matches.isEmpty {
                let intensity = min(1.0, Double(matches.count) / 5.0)
                factors.append(EnvironmentalFactor(
                    type: factorType,
                    intensity: intensity,
                    description: "检测到\(matches.joined(separator: ", "))"
                ))
            }
        }
        
        return factors
    }
    
    private func generateSceneDescription(primaryScene: DreamSceneType, 
                                          detectedScenes: [DreamSceneType],
                                          factors: [EnvironmentalFactor]) -> String {
        var description = "这个梦境主要发生在\(primaryScene.displayName)"
        
        if detectedScenes.count > 1 {
            let otherScenes = detectedScenes.filter { $0 != primaryScene }.prefix(2)
            description += "，也包含\(otherScenes.map { $0.displayName }.joined(separator: "和"))的元素"
        }
        
        if !factors.isEmpty {
            let factorDescs = factors.prefix(3).map { $0.type.displayName }
            description += "。环境特征包括\(factorDescs.joined(separator: "、"))"
        }
        
        return description + "。"
    }
    
    private func calculateDiversity(sceneCounts: [DreamSceneType: Int]) -> Double {
        guard !sceneCounts.isEmpty else { return 0 }
        
        let total = Double(sceneCounts.values.reduce(0) { $0 + $1 })
        guard total > 0 else { return 0 }
        
        // 使用 Shannon 多样性指数
        var diversity = 0.0
        for count in sceneCounts.values {
            let proportion = Double(count) / total
            if proportion > 0 {
                diversity -= proportion * log2(proportion)
            }
        }
        
        // 归一化到 0-1
        let maxDiversity = log2(Double(sceneCounts.count))
        return maxDiversity > 0 ? diversity / maxDiversity : 0
    }
    
    // Phase 72: 实现趋势计算
    private func calculateTrend(for sceneType: DreamSceneType, in dreams: [Dream]) -> TrendDirection {
        let calendar = Calendar.current
        let now = Date()
        
        // 将梦境按时间分成两半
        let sortedDreams = dreams.sorted { $0.date > $1.date }
        guard sortedDreams.count >= 4 else { return .stable }
        
        let midPoint = sortedDreams.count / 2
        let recentDreams = Array(sortedDreams.prefix(midPoint))
        let olderDreams = Array(sortedDreams.suffix(from: midPoint))
        
        // 计算近期和早期的场景出现频率
        let recentCount = recentDreams.filter { dream in
            if let analysis = analyzeDream(dream).analysis,
               analysis.detectedScenes.contains(sceneType) {
                return true
            }
            return false
        }.count
        
        let olderCount = olderDreams.filter { dream in
            if let analysis = analyzeDream(dream).analysis,
               analysis.detectedScenes.contains(sceneType) {
                return true
            }
            return false
        }.count
        
        // 计算趋势
        let recentRate = Double(recentCount) / Double(max(1, recentDreams.count))
        let olderRate = Double(olderCount) / Double(max(1, olderDreams.count))
        
        let diff = recentRate - olderRate
        
        if diff > 0.1 {
            return .increasing
        } else if diff < -0.1 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // Phase 72: 持久化实现
    private let analysesSaveKey = "dream_scene_analyses_data"
    private let configSaveKey = "dream_scene_analysis_config"
    
    private func loadAnalyses() {
        // Phase 72: 从 UserDefaults 加载持久化数据
        guard let data = UserDefaults.standard.data(forKey: analysesSaveKey),
              let loadedAnalyses = try? JSONDecoder().decode([DreamSceneAnalysis].self, from: data) else {
            return
        }
        analyses = loadedAnalyses
        print("✅ 加载了 \(analyses.count) 条场景分析记录")
    }
    
    private func saveAnalysis(_ analysis: DreamSceneAnalysis) {
        if let index = analyses.firstIndex(where: { $0.dreamId == analysis.dreamId }) {
            analyses[index] = analysis
        } else {
            analyses.append(analysis)
        }
        // Phase 72: 持久化保存到 UserDefaults
        if let encoded = try? JSONEncoder().encode(analyses) {
            UserDefaults.standard.set(encoded, forKey: analysesSaveKey)
        }
    }
    
    private func saveConfig() {
        // Phase 72: 持久化保存配置
        let configData = SceneAnalysisConfig(
            enabledSceneTypes: enabledSceneTypes,
            confidenceThreshold: confidenceThreshold,
            autoAnalyzeNewDreams: autoAnalyzeNewDreams
        )
        if let encoded = try? JSONEncoder().encode(configData) {
            UserDefaults.standard.set(encoded, forKey: configSaveKey)
        }
    }
}
