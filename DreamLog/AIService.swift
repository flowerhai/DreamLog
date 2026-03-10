//
//  AIService.swift
//  DreamLog
//
//  AI 服务：梦境解析和图像生成
//

import Foundation
import Combine

@MainActor
class AIService: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var isGeneratingImage: Bool = false
    @Published var currentAnalysis: String?
    @Published var generatedImageUrl: String?
    @Published var error: String?
    
    // MARK: - 梦境解析
    func analyzeDream(content: String, tags: [String], emotions: [Emotion]) async -> String {
        isAnalyzing = true
        error = nil
        
        // 模拟 AI 分析 (实际项目中调用 LLM API)
        await Task.sleep(nanoseconds: 2_000_000_000)  // 2 秒延迟
        
        let analysis = generateMockAnalysis(content: content, tags: tags, emotions: emotions)
        
        currentAnalysis = analysis
        isAnalyzing = false
        
        return analysis
    }
    
    // MARK: - 生成梦境图像
    func generateImage(prompt: String) async -> String? {
        isGeneratingImage = true
        error = nil
        
        // 模拟图像生成 (实际项目中调用 Stable Diffusion API)
        await Task.sleep(nanoseconds: 5_000_000_000)  // 5 秒延迟
        
        // 返回示例 URL
        generatedImageUrl = "https://example.com/dream_image.jpg"
        isGeneratingImage = false
        
        return generatedImageUrl
    }
    
    // MARK: - 提取关键词
    func extractKeywords(from content: String) -> [String] {
        // 简单的关键词提取 (实际项目中用 NLP)
        let commonWords = ["我", "在", "的", "了", "是", "不", "有", "这", "个", "很", "但", "说"]
        let words = content.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { $0.count >= 2 }
            .filter { !commonWords.contains($0) }
        
        return Array(words.prefix(5))
    }
    
    // MARK: - 检测情绪
    func detectEmotions(from content: String) -> [Emotion] {
        // 简单的情绪检测 (实际项目中用 ML 模型)
        var detected: [Emotion] = []
        
        let positiveWords = ["开心", "快乐", "高兴", "美好", "自由", "平静", "温暖"]
        let negativeWords = ["害怕", "恐惧", "紧张", "焦虑", "难过", "悲伤", "愤怒"]
        let anxiousWords = ["跑", "追", "逃", "急", "忙", "赶"]
        
        if positiveWords.contains(where: { content.contains($0) }) {
            detected.append(.happy)
        }
        if negativeWords.contains(where: { content.contains($0) }) {
            detected.append(.fearful)
        }
        if anxiousWords.contains(where: { content.contains($0) }) {
            detected.append(.anxious)
        }
        
        return detected.isEmpty ? [.neutral] : detected
    }
    
    // MARK: - 智能标签推荐
    /// 基于梦境内容智能推荐标签
    func recommendTags(content: String, existingTags: [String] = []) -> [String] {
        var recommendations: [String] = []
        let lowercasedContent = content.lowercased()
        
        // 梦境元素关键词映射
        let tagMappings: [String: [String]] = [
            "水": ["海洋", "河流", "湖泊", "游泳", "波浪", "下雨", "泪水"],
            "飞行": ["飞", "天空", "空中", "翅膀", "漂浮"],
            "追逐": ["追", "逃跑", "躲藏", "被追"],
            "坠落": ["掉落", "跌落", "跳下", "悬崖"],
            "考试": ["学校", "教室", "老师", "同学", "学习"],
            "牙齿": ["牙", "掉牙", "嘴巴"],
            "蛇": ["蛇", "蟒蛇", "毒蛇"],
            "房子": ["家", "房间", "门", "窗户", "建筑"],
            "死亡": ["去世", "葬礼", "墓地", "鬼魂"],
            "性": ["亲密", "爱人", "浪漫"],
            "动物": ["猫", "狗", "鸟", "鱼", "老虎", "狮子"],
            "自然": ["树", "花", "草", "山", "森林", "花园"],
            "交通工具": ["车", "飞机", "火车", "船", "地铁"],
            "食物": ["吃", "喝", "饭", "水果", "蛋糕"],
        ]
        
        // 匹配关键词
        for (baseTag, keywords) in tagMappings {
            if !existingTags.contains(baseTag) {
                for keyword in keywords {
                    if lowercasedContent.contains(keyword.lowercased()) {
                        recommendations.append(baseTag)
                        break
                    }
                }
            }
        }
        
        // 情绪相关标签
        let emotionTagMappings: [Emotion: [String]] = [
            .happy: ["开心", "快乐", "高兴", "美好", "愉快"],
            .fearful: ["害怕", "恐惧", "恐怖", "吓人"],
            .anxious: ["紧张", "焦虑", "担心", "不安"],
            .sad: ["难过", "悲伤", "哭泣", "伤心"],
            .angry: ["生气", "愤怒", "恼火"],
            .calm: ["平静", "安宁", "放松", "舒适"],
            .excited: ["兴奋", "激动", "刺激"],
            .confused: ["困惑", "迷茫", "不解"],
            .surprised: ["惊讶", "意外", "吃惊"],
        ]
        
        for (emotion, keywords) in emotionTagMappings {
            if !existingTags.contains(emotion.rawValue) {
                for keyword in keywords {
                    if lowercasedContent.contains(keyword.lowercased()) {
                        recommendations.append(emotion.rawValue)
                        break
                    }
                }
            }
        }
        
        // 场景标签
        if lowercasedContent.contains("晚上") || lowercasedContent.contains("夜晚") || lowercasedContent.contains("黑暗") {
            if !existingTags.contains("夜晚") { recommendations.append("夜晚") }
        }
        if lowercasedContent.contains("白天") || lowercasedContent.contains("阳光") || lowercasedContent.contains("明亮") {
            if !existingTags.contains("白天") { recommendations.append("白天") }
        }
        if lowercasedContent.contains("梦醒") || lowercasedContent.contains("醒来") {
            if !existingTags.contains("清醒") { recommendations.append("清醒") }
        }
        
        // 去重并限制数量
        let uniqueRecommendations = Array(Set(recommendations)).prefix(5).sorted()
        return uniqueRecommendations
    }
    
    // MARK: - 梦境相似度匹配
    /// 计算两个梦境的相似度 (0-1)
    func calculateSimilarity(between dream1: Dream, and dream2: Dream) -> Double {
        var similarityScore: Double = 0.0
        var weightSum: Double = 0.0
        
        // 标签相似度 (权重 0.4)
        let tagSimilarity = jaccardSimilarity(set1: Set(dream1.tags), set2: Set(dream2.tags))
        similarityScore += tagSimilarity * 0.4
        weightSum += 0.4
        
        // 情绪相似度 (权重 0.3)
        let emotionSimilarity = jaccardSimilarity(set1: Set(dream1.emotions), set2: Set(dream2.emotions))
        similarityScore += emotionSimilarity * 0.3
        weightSum += 0.3
        
        // 时间段相似度 (权重 0.15)
        if dream1.timeOfDay == dream2.timeOfDay {
            similarityScore += 0.15
        }
        weightSum += 0.15
        
        // 清晰度相似度 (权重 0.15)
        let clarityDiff = abs(dream1.clarity - dream2.clarity)
        let claritySimilarity = max(0, 1.0 - Double(clarityDiff) / 5.0)
        similarityScore += claritySimilarity * 0.15
        weightSum += 0.15
        
        return similarityScore / weightSum
    }
    
    /// Jaccard 相似度计算
    func jaccardSimilarity<T: Hashable>(set1: Set<T>, set2: Set<T>) -> Double {
        if set1.isEmpty && set2.isEmpty { return 0 }
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        return union > 0 ? Double(intersection) / Double(union) : 0
    }
    
    /// 查找相似梦境
    func findSimilarDreams(to dream: Dream, in dreams: [Dream], limit: Int = 5) -> [(dream: Dream, similarity: Double)] {
        var similarDreams: [(Dream, Double)] = []
        
        for otherDream in dreams where otherDream.id != dream.id {
            let similarity = calculateSimilarity(between: dream, and: otherDream)
            if similarity > 0.2 {  // 阈值：20% 相似度
                similarDreams.append((otherDream, similarity))
            }
        }
        
        // 按相似度排序
        similarDreams.sort { $0.similarity > $1.similarity }
        
        return Array(similarDreams.prefix(limit))
    }
    
    // MARK: - 生成图像提示词
    func generateImagePrompt(from dream: Dream) -> String {
        var prompt = "Dream scene: \(String(dream.content.prefix(100)))"
        
        // 添加情绪色彩
        if dream.emotions.contains(.calm) {
            prompt += ", peaceful atmosphere, soft lighting, pastel colors"
        } else if dream.emotions.contains(.fearful) {
            prompt += ", dark atmosphere, dramatic lighting, mysterious"
        } else if dream.emotions.contains(.excited) {
            prompt += ", vibrant colors, dynamic composition, energetic"
        }
        
        // 添加风格
        prompt += ", surreal art, dreamlike, ethereal, fantasy art style"
        
        return prompt
    }
    
    // MARK: - 模拟分析 (临时)
    private func generateMockAnalysis(content: String, tags: [String], emotions: [Emotion]) -> String {
        var analysis = ""
        
        // 关键词分析
        if tags.contains("水") || tags.contains("海") || tags.contains("河") {
            analysis += "💧 水元素分析:\n"
            analysis += "水通常象征情绪和潜意识。"
            if emotions.contains(.calm) {
                analysis += "平静的水面代表你内心平和，情绪稳定。\n\n"
            } else if emotions.contains(.fearful) {
                analysis += "汹涌的水可能表示情绪波动或压力。\n\n"
            } else {
                analysis += "注意你最近的情感状态。\n\n"
            }
        }
        
        if tags.contains("飞行") {
            analysis += "✈️ 飞行元素分析:\n"
            analysis += "飞行梦常代表自由、解脱或对掌控的渴望。\n"
            analysis += "你可能在现实生活中感到束缚，渴望突破。\n\n"
        }
        
        if tags.contains("追逐") {
            analysis += "🏃 追逐元素分析:\n"
            analysis += "被追逐的梦通常表示你在逃避某个问题。\n"
            analysis += "建议直面压力源，找到解决方案。\n\n"
        }
        
        // 情绪分析
        if !emotions.isEmpty {
            analysis += "😊 情绪分析:\n"
            let emotionNames = emotions.map { $0.rawValue }.joined(separator: "、")
            analysis += "这个梦主要包含 \(emotionNames) 的情绪。\n"
            analysis += "这反映了你近期的心理状态。\n\n"
        }
        
        // 建议
        analysis += "💡 建议:\n"
        analysis += "1. 记录梦境时的感受\n"
        analysis += "2. 思考与现实生活的关联\n"
        analysis += "3. 关注反复出现的元素"
        
        return analysis
    }
}

// MARK: - 梦境象征知识库
struct DreamSymbolDictionary {
    static let shared = DreamSymbolDictionary()
    
    private let symbols: [String: [String]] = [
        "水": ["情绪", "潜意识", "变化", "净化"],
        "海": ["广阔", "未知", "情感深度", "母性"],
        "河": ["时间流逝", "生命历程", "方向"],
        "飞行": ["自由", "解脱", "野心", "视角"],
        "掉落": ["失控", "焦虑", "不安全感"],
        "追逐": ["逃避", "压力", "恐惧"],
        "牙齿": ["变化", "成长", "焦虑", "力量"],
        "考试": ["被评判", "准备不足", "压力"],
        "蛇": ["转变", "智慧", "恐惧", "性能量"],
        "房子": ["自我", "心灵", "安全感"],
        "门": ["机会", "过渡", "选择"],
        "楼梯": ["进步", "提升", "努力"],
        "车": ["人生方向", "控制", "动力"],
        "手机": ["沟通", "联系", "信息"],
        "钱": ["价值", "资源", "安全感"],
    ]
    
    func getMeanings(for symbol: String) -> [String] {
        symbols[symbol] ?? ["个人化象征，需要结合情境理解"]
    }
    
    func getAllSymbols() -> [String] {
        Array(symbols.keys).sorted()
    }
}
