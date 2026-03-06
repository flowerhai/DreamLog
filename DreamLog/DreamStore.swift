//
//  DreamStore.swift
//  DreamLog
//
//  数据存储：管理梦境记录
//

import Foundation
import Combine

class DreamStore: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var filteredDreams: [Dream] = []
    @Published var tags: [String] = []
    @Published var isRecording: Bool = false
    @Published var isLoading: Bool = false
    
    private var searchText: String = ""
    
    init() {
        loadDreams()
    }
    
    // MARK: - 加载梦境
    func loadDreams() {
        // 示例数据
        dreams = [
            Dream(
                title: "海边漫步",
                content: "我梦见自己在海边散步，海浪轻轻拍打着沙滩...",
                originalText: "我梦见自己在海边散步，海浪轻轻拍打着沙滩，感觉很平静",
                date: Date(),
                tags: ["水", "海滩", "平静"],
                emotions: [.calm],
                clarity: 4,
                intensity: 2
            ),
            Dream(
                title: "飞行体验",
                content: "我突然飞起来了，在城市上空自由翱翔...",
                originalText: "我突然飞起来了，在城市上空自由翱翔，风在耳边呼啸",
                date: Date().daysFromNow(-2),
                tags: ["飞行", "自由", "城市"],
                emotions: [.excited, .happy],
                clarity: 5,
                intensity: 5,
                isLucid: true
            ),
            Dream(
                title: "被追逐",
                content: "有什么东西在追我，我拼命跑但跑不动...",
                originalText: "有什么东西在追我，我拼命跑但跑不动，很害怕",
                date: Date().daysFromNow(-5),
                tags: ["追逐", "恐惧", "逃跑"],
                emotions: [.fearful, .anxious],
                clarity: 3,
                intensity: 5
            ),
        ]
        filteredDreams = dreams
        extractTags()
    }
    
    // MARK: - 提取标签
    private func extractTags() {
        var tagSet = Set<String>()
        for dream in dreams {
            tagSet.formUnion(dream.tags)
        }
        tags = Array(tagSet).sorted()
    }
    
    // MARK: - 添加梦境
    func addDream(_ dream: Dream) {
        dreams.insert(dream, at: 0)
        extractTags()
        filterDreams(searchText: searchText)
    }
    
    // MARK: - 更新梦境
    func updateDream(_ dream: Dream) {
        if let index = dreams.firstIndex(where: { $0.id == dream.id }) {
            dreams[index] = dream
            extractTags()
        }
    }
    
    // MARK: - 删除梦境
    func deleteDream(_ dream: Dream) {
        dreams.removeAll { $0.id == dream.id }
        extractTags()
    }
    
    // MARK: - 搜索梦境
    func filterDreams(searchText: String) {
        self.searchText = searchText
        
        if searchText.isEmpty {
            filteredDreams = dreams
        } else {
            filteredDreams = dreams.filter { dream in
                dream.title.localizedCaseInsensitiveContains(searchText) ||
                dream.content.localizedCaseInsensitiveContains(searchText) ||
                dream.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    // MARK: - 按标签过滤
    func filterByTag(_ tag: String) {
        filteredDreams = dreams.filter { $0.tags.contains(tag) }
    }
    
    // MARK: - 按情绪过滤
    func filterByEmotion(_ emotion: Emotion) {
        filteredDreams = dreams.filter { $0.emotions.contains(emotion) }
    }
    
    // MARK: - 获取梦境详情
    func getDream(by id: UUID) -> Dream? {
        dreams.first { $0.id == id }
    }
    
    // MARK: - 获取统计数据
    func getStatistics() -> DreamStatistics {
        let total = dreams.count
        let lucid = dreams.filter { $0.isLucid }.count
        let avgClarity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.clarity }) / Double(total)
        let avgIntensity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.intensity }) / Double(total)
        
        // 情绪统计
        var emotionCount: [Emotion: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                emotionCount[emotion, default: 0] += 1
            }
        }
        let topEmotions = emotionCount.sorted { $0.value > $1.value }.prefix(5).map { EmotionCount(emotion: $0.key, count: $0.value) }
        
        // 标签统计
        var tagCount: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCount[tag, default: 0] += 1
            }
        }
        let topTags = tagCount.sorted { $0.value > $1.value }.prefix(5).map { TagCount(tag: $0.key, count: $0.value) }
        
        // 时间段统计
        var timeCount: [TimeOfDay: Int] = [:]
        for dream in dreams {
            timeCount[dream.timeOfDay, default: 0] += 1
        }
        
        // 星期统计
        var weekdayCount: [Int: Int] = [:]
        for dream in dreams {
            let weekday = Calendar.current.component(.weekday, from: dream.date)
            weekdayCount[weekday, default: 0] += 1
        }
        
        return DreamStatistics(
            totalDreams: total,
            lucidDreams: lucid,
            averageClarity: avgClarity,
            averageIntensity: avgIntensity,
            topEmotions: topEmotions,
            topTags: topTags,
            dreamsByTimeOfDay: timeCount,
            dreamsByWeekday: weekdayCount
        )
    }
    
    // MARK: - 发现模式
    func findPatterns() -> [DreamPattern] {
        var patterns: [DreamPattern] = []
        
        // 统计标签频率
        var tagFrequency: [String: [Dream]] = [:]
        for dream in dreams {
            for tag in dream.tags {
                if tagFrequency[tag] == nil {
                    tagFrequency[tag] = []
                }
                tagFrequency[tag]?.append(dream)
            }
        }
        
        // 找出高频标签
        for (tag, dreams) in tagFrequency {
            if dreams.count >= 3 {  // 至少出现 3 次
                let insight = generateInsight(for: tag, dreams: dreams)
                patterns.append(DreamPattern(
                    id: UUID(),
                    pattern: "经常梦到\(tag)",
                    frequency: dreams.count,
                    lastOccurrence: dreams.max(by: { $0.date < $1.date })?.date ?? Date(),
                    insight: insight,
                    relatedTags: dreams.flatMap { $0.tags }.unique
                ))
            }
        }
        
        return patterns.sorted { $0.frequency > $1.frequency }
    }
    
    // MARK: - 生成洞察
    private func generateInsight(for tag: String, dreams: [Dream]) -> String {
        let count = dreams.count
        let emotions = dreams.flatMap { $0.emotions }
        let topEmotion = emotions.mostCommon
        
        switch tag {
        case "水", "海", "河":
            return "水通常象征情绪和潜意识。\(count > 5 ? "频繁出现可能表示情绪波动较大。" : "这可能反映当前的情感状态。")"
        case "飞行":
            return "飞行梦常代表自由、解脱或掌控感。\(topEmotion != nil ? "伴随\(topEmotion!.rawValue)的情绪。" : "")"
        case "追逐":
            return "被追逐的梦可能表示你在逃避某个问题或压力。"
        case "牙齿":
            return "牙齿掉落的梦通常与变化、成长或焦虑有关。"
        default:
            return "这个元素在你的梦中出现了\(count)次，值得注意。"
        }
    }
    
    // MARK: - 获取最近的梦
    func getRecentDreams(limit: Int = 10) -> [Dream] {
        Array(dreams.prefix(limit))
    }
    
    // MARK: - 获取清醒梦
    func getLucidDreams() -> [Dream] {
        dreams.filter { $0.isLucid }
    }
    
    // MARK: - 导出梦境
    func exportDream(_ dream: Dream) -> String {
        var text = "🌙 DreamLog - \(dream.title)\n\n"
        text += "日期：\(dream.date.formatted(.dateTime.year().month().day().hour().minute()))\n"
        text += "时间：\(dream.timeOfDay.rawValue)\n"
        text += "清晰度：\(String(repeating: "⭐", count: dream.clarity))\n"
        text += "强度：\(String(repeating: "🔥", count: dream.intensity))\n"
        if dream.isLucid {
            text += "✨ 清醒梦\n"
        }
        text += "\n\(dream.content)\n"
        if !dream.tags.isEmpty {
            text += "\n标签：\(dream.tags.joined(separator: " "))\n"
        }
        if !dream.emotions.isEmpty {
            text += "情绪：\(dream.emotions.map { $0.icon + $0.rawValue }.joined(separator: " "))\n"
        }
        if let analysis = dream.aiAnalysis {
            text += "\n🧠 AI 解析:\n\(analysis)\n"
        }
        return text
    }
}

// MARK: - 日期扩展
extension Date {
    func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

// MARK: - 数组扩展
extension Array where Element: Hashable {
    var unique: [Element] {
        Array(Set(self))
    }
    
    var mostCommon: Element? {
        guard !isEmpty else { return nil }
        let counts = reduce(into: [Element: Int]()) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - 预览数据
extension DreamStore {
    static var preview: DreamStore {
        let store = DreamStore()
        return store
    }
}
