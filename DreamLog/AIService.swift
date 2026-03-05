//
//  AIService.swift
//  DreamLog
//
//  AI 服务：梦境解析和图像生成
//

import Foundation
import Combine

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
    
    // MARK: - 生成图像提示词
    func generateImagePrompt(from dream: Dream) -> String {
        var prompt = "Dream scene: \(dream.content.prefix(100))"
        
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
