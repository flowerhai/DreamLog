//
//  DreamStore.swift
//  DreamLog
//
//  数据存储：管理梦境记录 (支持持久化 + iCloud 同步)
//

import Foundation
import Combine

class DreamStore: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var filteredDreams: [Dream] = []
    @Published var tags: [String] = []
    @Published var isRecording: Bool = false
    @Published var isLoading: Bool = false
    @Published var cloudSyncStatus: CloudSyncStatus = .idle
    
    private var searchText: String = ""
    private let saveKey = "dreams_data"
    private let cloudSyncService: CloudSyncService
    
    init(cloudSyncService: CloudSyncService = .shared) {
        self.cloudSyncService = cloudSyncService
        loadDreams()
        setupCloudSyncObserver()
    }
    
    // MARK: - 加载示例数据
    private func loadSampleDreams() {
        dreams = [
            Dream(
                title: "海边漫步",
                content: "我梦见自己在海边散步，海浪轻轻拍打着沙滩，阳光温暖地洒在身上，感觉非常平静和自由。远处有几只海鸥在飞翔，天空中飘着几朵白云。这个梦让我感到很放松。",
                originalText: "我梦见自己在海边散步，海浪轻轻拍打着沙滩，感觉很平静",
                date: Date(),
                timeOfDay: .morning,
                tags: ["水", "海滩", "平静", "自由", "海鸥"],
                emotions: [.calm, .happy],
                clarity: 4,
                intensity: 2,
                isLucid: false,
                aiAnalysis: "💧 水元素分析:\n水通常象征情绪和潜意识。平静的水面代表你内心平和，情绪稳定。\n\n😊 情绪分析:\n这个梦主要包含平静、快乐的情绪，反映了你近期的心理状态。\n\n💡 建议:\n1. 记录梦境时的感受\n2. 思考与现实生活的关联\n3. 关注反复出现的元素"
            ),
            Dream(
                title: "飞行体验",
                content: "我突然飞起来了，在城市上空自由翱翔。风在耳边呼啸，俯瞰着下方的建筑和街道。那种自由的感觉太棒了，我可以去任何想去的地方。",
                originalText: "我突然飞起来了，在城市上空自由翱翔，风在耳边呼啸",
                date: Date().daysFromNow(-2),
                timeOfDay: .evening,
                tags: ["飞行", "自由", "城市"],
                emotions: [.excited, .happy],
                clarity: 5,
                intensity: 5,
                isLucid: true,
                aiAnalysis: "✈️ 飞行元素分析:\n飞行梦常代表自由、解脱或对掌控的渴望。你可能在现实生活中感到束缚，渴望突破。\n\n😊 情绪分析:\n兴奋和快乐的情绪表明你对这种自由状态非常享受。\n\n💡 建议:\n1. 思考生活中哪些地方让你感到束缚\n2. 寻找更多表达自由的方式\n3. 尝试清醒梦练习"
            ),
            Dream(
                title: "被追逐",
                content: "有什么东西在追我，我拼命跑但跑不动。周围的环境很陌生，我想喊但发不出声音。最后躲进了一个柜子里，心跳得很快。",
                originalText: "有什么东西在追我，我拼命跑但跑不动，很害怕",
                date: Date().daysFromNow(-5),
                timeOfDay: .earlyMorning,
                tags: ["追逐", "恐惧", "逃跑", "躲藏"],
                emotions: [.fearful, .anxious],
                clarity: 3,
                intensity: 5,
                isLucid: false,
                aiAnalysis: "🏃 追逐元素分析:\n被追逐的梦通常表示你在逃避某个问题或压力源。\n\n😰 情绪分析:\n恐惧和焦虑的情绪表明你可能正面临一些压力。\n\n💡 建议:\n1. 识别生活中的压力源\n2. 尝试直面而非逃避问题\n3. 练习放松技巧"
            ),
            Dream(
                title: "回到学校",
                content: "我回到了高中教室，但是找不到自己的座位。考试马上就要开始了，我还没有准备好。同学们都在认真复习，我却什么都不会。",
                originalText: "回到学校考试，找不到座位，很焦虑",
                date: Date().daysFromNow(-10),
                timeOfDay: .afternoon,
                tags: ["学校", "考试", "焦虑", "准备"],
                emotions: [.anxious, .confused],
                clarity: 4,
                intensity: 4,
                isLucid: false
            ),
            Dream(
                title: "神秘花园",
                content: "我发现了一个隐藏的花园，里面开满了从未见过的花朵。每朵花都散发着不同的光芒，空气中弥漫着奇异的香气。花园中央有一个喷泉，水柱呈现出彩虹色。",
                originalText: "发现神秘花园，花朵发光，彩虹喷泉",
                date: Date().daysFromNow(-15),
                timeOfDay: .morning,
                tags: ["花园", "花朵", "神秘", "彩虹", "自然"],
                emotions: [.surprised, .calm, .happy],
                clarity: 5,
                intensity: 3,
                isLucid: true,
                aiAnalysis: "🌸 花园元素分析:\n花园象征内心世界和个人成长。发光的花朵可能代表潜在的才能或灵感。\n\n🌈 彩虹元素:\n彩虹通常象征希望、转变和美好前景。\n\n💡 建议:\n1. 关注内心的创造力和灵感\n2. 这是一个积极的梦，表明你正处于成长期\n3. 记录下这些美好的感受"
            ),
        ]
        filteredDreams = dreams
        extractTags()
        // 自动保存示例数据
        saveDreams()
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
        saveDreams()
    }
    
    // MARK: - 更新梦境
    func updateDream(_ dream: Dream) {
        if let index = dreams.firstIndex(where: { $0.id == dream.id }) {
            dreams[index] = dream
            extractTags()
            saveDreams()
        }
    }
    
    // MARK: - 删除梦境
    func deleteDream(_ dream: Dream) {
        dreams.removeAll { $0.id == dream.id }
        extractTags()
        saveDreams()
    }
    
    // MARK: - 删除所有梦境
    func deleteAllDreams() {
        dreams.removeAll()
        filteredDreams.removeAll()
        tags.removeAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
        print("✅ 已删除所有梦境记录")
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
        guard !dreams.isEmpty else {
            return DreamStatistics(
                totalDreams: 0,
                lucidDreams: 0,
                averageClarity: 0,
                averageIntensity: 0,
                topEmotions: [],
                topTags: [],
                dreamsByTimeOfDay: [:],
                dreamsByWeekday: [:]
            )
        }
        
        let total = dreams.count
        let lucid = dreams.filter { $0.isLucid }.count
        let avgClarity = Double(dreams.reduce(0) { $0 + $1.clarity }) / Double(total)
        let avgIntensity = Double(dreams.reduce(0) { $0 + $1.intensity }) / Double(total)
        
        // 情绪统计
        var emotionCount: [Emotion: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                emotionCount[emotion, default: 0] += 1
            }
        }
        let topEmotions: [DreamStatistics.EmotionCount] = emotionCount.sorted { $0.value > $1.value }.prefix(5).map { 
            DreamStatistics.EmotionCount(emotion: $0.key, count: $0.value) 
        }
        
        // 标签统计
        var tagCount: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCount[tag, default: 0] += 1
            }
        }
        let topTags: [DreamStatistics.TagCount] = tagCount.sorted { $0.value > $1.value }.prefix(5).map { 
            DreamStatistics.TagCount(tag: $0.key, count: $0.value) 
        }
        
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
    
    // MARK: - 导出梦境为 JSON
    func exportDreams() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(dreams)
        } catch {
            print("❌ 导出失败：\(error)")
            return nil
        }
    }
    
    // MARK: - 导入梦境从 JSON
    func importDreams(from data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importedDreams = try decoder.decode([Dream].self, from: data)
            dreams.append(contentsOf: importedDreams)
            extractTags()
            saveDreams()
            print("✅ 成功导入 \(importedDreams.count) 个梦境")
            return true
        } catch {
            print("❌ 导入失败：\(error)")
            return false
        }
    }
    
    // MARK: - 导出梦境文本
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

// MARK: - Date 扩展
extension Date {
    func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

// MARK: - Dream Codable 支持
// 使用 CodableDream 结构体进行序列化，避免与 @Published 冲突
struct CodableDream: Codable {
    let id: UUID
    let title: String
    let content: String
    let originalText: String
    let date: Date
    let timeOfDay: TimeOfDay
    let tags: [String]
    let emotions: [Emotion]
    let clarity: Int
    let intensity: Int
    let isLucid: Bool
    let aiAnalysis: String?
    let aiImageUrl: String?
    let isPublic: Bool
    let likeCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    init(from dream: Dream) {
        self.id = dream.id
        self.title = dream.title
        self.content = dream.content
        self.originalText = dream.originalText
        self.date = dream.date
        self.timeOfDay = dream.timeOfDay
        self.tags = dream.tags
        self.emotions = dream.emotions
        self.clarity = dream.clarity
        self.intensity = dream.intensity
        self.isLucid = dream.isLucid
        self.aiAnalysis = dream.aiAnalysis
        self.aiImageUrl = dream.aiImageUrl
        self.isPublic = dream.isPublic
        self.likeCount = dream.likeCount
        self.createdAt = dream.createdAt
        self.updatedAt = dream.updatedAt
    }
    
    func toDream() -> Dream {
        Dream(
            id: id,
            title: title,
            content: content,
            originalText: originalText,
            date: date,
            timeOfDay: timeOfDay,
            tags: tags,
            emotions: emotions,
            clarity: clarity,
            intensity: intensity,
            isLucid: isLucid,
            aiAnalysis: aiAnalysis,
            aiImageUrl: aiImageUrl,
            isPublic: isPublic,
            likeCount: likeCount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension DreamStore {
    func loadDreams() {
        // 尝试从 UserDefaults 加载
        if let savedData = UserDefaults.standard.data(forKey: saveKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let savedDreams = try decoder.decode([CodableDream].self, from: savedData)
                dreams = savedDreams.map { $0.toDream() }
                print("✅ 成功加载 \(dreams.count) 个梦境记录")
            } catch {
                print("❌ 加载梦境失败：\(error)")
                // 如果加载失败，使用示例数据
                loadSampleDreams()
            }
        } else {
            // 首次使用，加载示例数据
            loadSampleDreams()
        }
        filteredDreams = dreams
        extractTags()
    }
    
    func saveDreams() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let codableDreams = dreams.map { CodableDream(from: $0) }
            let encoded = try encoder.encode(codableDreams)
            UserDefaults.standard.set(encoded, forKey: saveKey)
            print("✅ 成功保存 \(dreams.count) 个梦境记录")
            
            // 自动同步到云端 (如果启用)
            if cloudSyncService.isCloudEnabled {
                cloudSyncService.pushToCloud(dreams)
                cloudSyncStatus = cloudSyncService.syncStatus
            }
        } catch {
            print("❌ 保存梦境失败：\(error)")
        }
    }
    
    // MARK: - iCloud 云同步
    
    /// 设置云同步观察者
    private func setupCloudSyncObserver() {
        cloudSyncService.$syncStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.cloudSyncStatus = status
            }
            .store(in: &subscriptions)
        
        cloudSyncService.$isCloudEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                if enabled {
                    self?.triggerCloudSync()
                }
            }
            .store(in: &subscriptions)
    }
    
    private var subscriptions: Set<AnyCancellable> = []
    
    /// 触发云同步
    func triggerCloudSync() {
        guard cloudSyncService.isCloudEnabled else {
            cloudSyncStatus = .unavailable
            return
        }
        
        cloudSyncService.triggerSync(dreams)
    }
    
    /// 从云端拉取梦境
    func pullFromCloud() {
        cloudSyncService.pullFromCloud { [weak self] cloudDreams in
            guard let self = self, !cloudDreams.isEmpty else { return }
            
            // 合并云端和本地梦境 (避免重复)
            let localIds = Set(self.dreams.map { $0.id })
            let newDreams = cloudDreams.filter { !localIds.contains($0.id) }
            
            if !newDreams.isEmpty {
                self.dreams.append(contentsOf: newDreams)
                self.dreams.sort { $0.date > $1.date }
                self.extractTags()
                self.saveDreams()
                print("✅ 从云端同步 \(newDreams.count) 个新梦境")
            }
        }
    }
    
    /// 检查云同步状态
    func checkCloudStatus() {
        cloudSyncService.checkCloudStatus()
    }
    
    /// 获取上次同步时间
    var lastSyncDate: Date? {
        cloudSyncService.lastSyncDate
    }
}
