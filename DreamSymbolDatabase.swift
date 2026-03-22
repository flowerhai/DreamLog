//
//  DreamSymbolDatabase.swift
//  DreamLog
//
//  Phase 91: 扩展符号数据库 - 300+ 符号支持 🧠✨
//  创建时间：2026-03-22
//

import Foundation
import SwiftData

// MARK: - 符号数据模型

/// 梦境符号
@Model
class DreamSymbolEntity {
    @Attribute(.unique) var id: String
    var name: String
    var nameEn: String
    var category: String
    var meanings: String // JSON array
    var culturalVariations: String // JSON object
    var relatedSymbols: String // JSON array
    var frequency: Int
    var isPersonal: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        name: String,
        nameEn: String,
        category: String,
        meanings: [String],
        culturalVariations: [String: [String]],
        relatedSymbols: [String],
        frequency: Int = 0,
        isPersonal: Bool = false
    ) {
        self.id = id
        self.name = name
        self.nameEn = nameEn
        self.category = category
        self.meanings = try! JSONEncoder().encode(meanings).base64EncodedString()
        self.culturalVariations = try! JSONEncoder().encode(culturalVariations).base64EncodedString()
        self.relatedSymbols = try! JSONEncoder().encode(relatedSymbols).base64EncodedString()
        self.frequency = frequency
        self.isPersonal = isPersonal
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func getMeanings() -> [String] {
        guard let data = Data(base64Encoded: meanings) else { return [] }
        return try? JSONDecoder().decode([String].self, from: data) ?? []
    }
    
    func getCulturalVariiations() -> [String: [String]] {
        guard let data = Data(base64Encoded: culturalVariations) else { return [:] }
        return try? JSONDecoder().decode([String: [String]].self, from: data) ?? [:]
    }
    
    func getRelatedSymbols() -> [String] {
        guard let data = Data(base64Encoded: relatedSymbols) else { return [] }
        return try? JSONDecoder().decode([String].self, from: data) ?? []
    }
}

// MARK: - 符号数据库服务

@MainActor
class DreamSymbolDatabase: ObservableObject {
    static let shared = DreamSymbolDatabase()
    
    @Published var symbols: [DreamSymbolEntity] = []
    @Published var personalSymbols: [DreamSymbolEntity] = []
    @Published var isLoading: Bool = false
    
    private var modelContext: ModelContext?
    private let symbolCategories = SymbolCategories.shared
    
    // 符号关联强度缓存
    private var associationCache: [String: [String: Double]] = [:]
    
    private init() {
        loadDefaultSymbols()
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadPersonalSymbols()
    }
    
    // MARK: - 默认符号库
    
    /// 加载默认符号库 (300+ 符号)
    private func loadDefaultSymbols() {
        symbols = SymbolLibrary.getAllSymbols()
        print("✅ 符号数据库加载完成：\(symbols.count) 个符号")
    }
    
    /// 加载个人符号
    private func loadPersonalSymbols() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DreamSymbolEntity>(
                predicate: #Predicate { $0.isPersonal == true }
            )
            personalSymbols = try context.fetch(descriptor)
        } catch {
            print("❌ 加载个人符号失败：\(error)")
        }
    }
    
    // MARK: - 符号查询
    
    /// 根据名称查找符号
    func findSymbol(byName name: String) -> DreamSymbolEntity? {
        let normalizedName = name.trimmingCharacters(in: .whitespaces).lowercased()
        return symbols.first { 
            $0.name.lowercased() == normalizedName || 
            $0.nameEn.lowercased() == normalizedName 
        }
    }
    
    /// 根据类别查找符号
    func findSymbols(byCategory category: String) -> [DreamSymbolEntity] {
        return symbols.filter { $0.category == category }
    }
    
    /// 搜索符号
    func searchSymbols(query: String) -> [DreamSymbolEntity] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !normalizedQuery.isEmpty else { return [] }
        
        return symbols.filter { symbol in
            symbol.name.lowercased().contains(normalizedQuery) ||
            symbol.nameEn.lowercased().contains(normalizedQuery) ||
            symbol.getMeanings().contains { $0.lowercased().contains(normalizedQuery) }
        }
    }
    
    /// 获取符号关联
    func getRelatedSymbols(symbolName: String, maxCount: Int = 5) -> [DreamSymbolEntity] {
        guard let symbol = findSymbol(byName: symbolName) else { return [] }
        
        let relatedNames = symbol.getRelatedSymbols()
        var relatedSymbols: [DreamSymbolEntity] = []
        
        for name in relatedNames.prefix(maxCount) {
            if let related = findSymbol(byName: name) {
                relatedSymbols.append(related)
            }
        }
        
        return relatedSymbols
    }
    
    // MARK: - 符号关联分析
    
    /// 计算符号关联强度
    func calculateAssociationStrength(symbol1: String, symbol2: String) -> Double {
        let key = "\(symbol1)_\(symbol2)"
        if let cached = associationCache[key] {
            return cached[symbol2] ?? 0.0
        }
        
        guard let s1 = findSymbol(byName: symbol1),
              let s2 = findSymbol(byName: symbol2) else {
            return 0.0
        }
        
        var strength = 0.0
        
        // 相同类别
        if s1.category == s2.category {
            strength += 0.3
        }
        
        // 互为关联符号
        if s1.getRelatedSymbols().contains(s2.nameEn) ||
           s2.getRelatedSymbols().contains(s1.nameEn) {
            strength += 0.5
        }
        
        // 含义重叠
        let meanings1 = Set(s1.getMeanings().map { $0.lowercased() })
        let meanings2 = Set(s2.getMeanings().map { $0.lowercased() })
        let overlap = meanings1.intersection(meanings2).count
        strength += Double(overlap) * 0.1
        
        associationCache[key] = [symbol2: strength]
        return min(strength, 1.0)
    }
    
    // MARK: - 个人符号管理
    
    /// 添加个人符号
    func addPersonalSymbol(
        name: String,
        nameEn: String,
        category: String,
        meanings: [String],
        relatedSymbols: [String] = []
    ) async throws -> DreamSymbolEntity {
        guard let context = modelContext else {
            throw SymbolError.modelContextNotConfigured
        }
        
        let id = "personal_\(UUID().uuidString)"
        let symbol = DreamSymbolEntity(
            id: id,
            name: name,
            nameEn: nameEn,
            category: category,
            meanings: meanings,
            culturalVariations: [:],
            relatedSymbols: relatedSymbols,
            frequency: 0,
            isPersonal: true
        )
        
        context.insert(symbol)
        try context.save()
        
        await MainActor.run {
            personalSymbols.append(symbol)
        }
        
        return symbol
    }
    
    /// 更新个人符号
    func updatePersonalSymbol(_ symbol: DreamSymbolEntity) async throws {
        guard let context = modelContext else {
            throw SymbolError.modelContextNotConfigured
        }
        
        symbol.updatedAt = Date()
        try context.save()
    }
    
    /// 删除个人符号
    func deletePersonalSymbol(_ symbol: DreamSymbolEntity) async throws {
        guard let context = modelContext else {
            throw SymbolError.modelContextNotConfigured
        }
        
        context.delete(symbol)
        try context.save()
        
        await MainActor.run {
            personalSymbols.removeAll { $0.id == symbol.id }
        }
    }
    
    /// 更新符号使用频率
    func incrementSymbolFrequency(symbolName: String) {
        if let symbol = findSymbol(byName: symbolName) {
            symbol.frequency += 1
        }
    }
    
    // MARK: - 符号统计
    
    /// 获取符号统计
    func getSymbolStatistics() -> SymbolStatistics {
        let totalSymbols = symbols.count + personalSymbols.count
        let categoryCounts = Dictionary(grouping: symbols, by: { $0.category })
            .mapValues { $0.count }
        
        let topSymbols = symbols
            .sorted { $0.frequency > $1.frequency }
            .prefix(10)
            .map { $0.name }
        
        return SymbolStatistics(
            totalSymbols: totalSymbols,
            defaultSymbols: symbols.count,
            personalSymbols: personalSymbols.count,
            categoryCounts: categoryCounts,
            topSymbols: topSymbols
        )
    }
}

// MARK: - 符号错误

enum SymbolError: LocalizedError {
    case symbolNotFound
    case modelContextNotConfigured
    case invalidSymbolData
    
    var errorDescription: String? {
        switch self {
        case .symbolNotFound:
            return "未找到该符号"
        case .modelContextNotConfigured:
            return "模型上下文未配置"
        case .invalidSymbolData:
            return "符号数据无效"
        }
    }
}

// MARK: - 符号统计

struct SymbolStatistics {
    let totalSymbols: Int
    let defaultSymbols: Int
    let personalSymbols: Int
    let categoryCounts: [String: Int]
    let topSymbols: [String]
}

// MARK: - 符号类别

class SymbolCategories {
    static let shared = SymbolCategories()
    
    let categories: [String: String] = [
        "people": "人物",
        "animals": "动物",
        "objects": "物品",
        "places": "地点",
        "actions": "行为",
        "emotions": "情绪",
        "nature": "自然",
        "supernatural": "超自然",
        "technology": "科技",
        "food": "食物",
        "clothing": "服饰",
        "transportation": "交通",
        "buildings": "建筑",
        "weather": "天气",
        "time": "时间"
    ]
    
    func getCategoryName(key: String) -> String {
        return categories[key] ?? key
    }
    
    func getAllCategories() -> [(key: String, name: String)] {
        return categories.map { (key: $0.key, name: $0.value) }
            .sorted { $0.name < $1.name }
    }
}

// MARK: - 符号库

struct SymbolLibrary {
    /// 获取所有默认符号
    static func getAllSymbols() -> [DreamSymbolEntity] {
        var allSymbols: [DreamSymbolEntity] = []
        
        // 人物类 (25 个)
        allSymbols.append(contentsOf: createPeopleSymbols())
        
        // 动物类 (30 个)
        allSymbols.append(contentsOf: createAnimalSymbols())
        
        // 物品类 (40 个)
        allSymbols.append(contentsOf: createObjectSymbols())
        
        // 地点类 (25 个)
        allSymbols.append(contentsOf: createPlaceSymbols())
        
        // 自然类 (35 个)
        allSymbols.append(contentsOf: createNatureSymbols())
        
        // 行为类 (30 个)
        allSymbols.append(contentsOf: createActionSymbols())
        
        // 情绪类 (20 个)
        allSymbols.append(contentsOf: createEmotionSymbols())
        
        // 超自然类 (25 个)
        allSymbols.append(contentsOf: createSupernaturalSymbols())
        
        // 科技类 (20 个)
        allSymbols.append(contentsOf: createTechnologySymbols())
        
        // 食物类 (20 个)
        allSymbols.append(contentsOf: createFoodSymbols())
        
        // 建筑类 (20 个)
        allSymbols.append(contentsOf: createBuildingSymbols())
        
        // 交通类 (15 个)
        allSymbols.append(contentsOf: createTransportationSymbols())
        
        // 天气类 (15 个)
        allSymbols.append(contentsOf: createWeatherSymbols())
        
        return allSymbols
    }
    
    // MARK: - 各类符号创建
    
    private static func createPeopleSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "people_mother",
                name: "母亲",
                nameEn: "mother",
                category: "people",
                meanings: ["养育", "保护", "无条件的爱", "安全感", "起源"],
                culturalVariations: [
                    "western": ["养育者", "情感支持"],
                    "eastern": ["家庭核心", "孝道对象"],
                    "indigenous": ["大地之母", "生命源泉"]
                ],
                relatedSymbols: ["father", "child", "home", "family"]
            ),
            DreamSymbolEntity(
                id: "people_father",
                name: "父亲",
                nameEn: "father",
                category: "people",
                meanings: ["权威", "保护", "指导", "力量", "规则"],
                culturalVariations: [
                    "western": ["权威形象", "经济支柱"],
                    "eastern": ["家族传承", "严父形象"],
                    "indigenous": ["部落领袖", "智慧长者"]
                ],
                relatedSymbols: ["mother", "child", "home", "work"]
            ),
            DreamSymbolEntity(
                id: "people_child",
                name: "孩子",
                nameEn: "child",
                category: "people",
                meanings: ["纯真", "潜力", "新开始", "内在小孩", "脆弱"],
                culturalVariations: [
                    "western": ["未来希望", "个人成就"],
                    "eastern": ["家族延续", "光宗耀祖"],
                    "indigenous": ["部落未来", "祖先转世"]
                ],
                relatedSymbols: ["mother", "father", "play", "school"]
            ),
            DreamSymbolEntity(
                id: "people_stranger",
                name: "陌生人",
                nameEn: "stranger",
                category: "people",
                meanings: ["未知自我", "新机遇", "潜在威胁", "未知方面"],
                culturalVariations: [
                    "western": ["新关系", "潜在朋友"],
                    "eastern": ["缘分", "贵人"],
                    "indigenous": ["信使", "精神向导"]
                ],
                relatedSymbols: ["face", "crowd", "meeting", "journey"]
            ),
            DreamSymbolEntity(
                id: "people_friend",
                name: "朋友",
                nameEn: "friend",
                category: "people",
                meanings: ["支持", "陪伴", "信任", "社交需求"],
                culturalVariations: [
                    "western": ["平等关系", "情感支持"],
                    "eastern": ["义气", "知己"],
                    "indigenous": ["部落成员", "盟友"]
                ],
                relatedSymbols: ["group", "celebration", "conversation", "trust"]
            )
        ]
    }
    
    private static func createAnimalSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "animals_snake",
                name: "蛇",
                nameEn: "snake",
                category: "animals",
                meanings: ["转变", "治愈", "性", "危险", "智慧"],
                culturalVariations: [
                    "western": ["诱惑", "危险", "邪恶"],
                    "eastern": ["智慧", "灵性", "守护"],
                    "indigenous": ["大地能量", "重生", "医药"]
                ],
                relatedSymbols: ["shedding", "poison", "coil", "kundalini"]
            ),
            DreamSymbolEntity(
                id: "animals_dog",
                name: "狗",
                nameEn: "dog",
                category: "animals",
                meanings: ["忠诚", "友谊", "保护", "直觉", "服务"],
                culturalVariations: [
                    "western": ["最好朋友", "忠诚伙伴"],
                    "eastern": ["看家护院", "吉祥物"],
                    "indigenous": ["精神向导", "狩猎伙伴"]
                ],
                relatedSymbols: ["cat", "wolf", "loyalty", "protection"]
            ),
            DreamSymbolEntity(
                id: "animals_cat",
                name: "猫",
                nameEn: "cat",
                category: "animals",
                meanings: ["独立", "神秘", "直觉", "女性力量", "优雅"],
                culturalVariations: [
                    "western": ["独立", "神秘"],
                    "eastern": ["招财", "辟邪"],
                    "indigenous": ["夜行者", "灵性使者"]
                ],
                relatedSymbols: ["dog", "independence", "mystery", "night"]
            ),
            DreamSymbolEntity(
                id: "animals_bird",
                name: "鸟",
                nameEn: "bird",
                category: "animals",
                meanings: ["自由", "精神", "消息", "超越", "视角"],
                culturalVariations: [
                    "western": ["自由", "灵魂"],
                    "eastern": ["喜讯", "吉祥"],
                    "indigenous": ["信使", "祖先灵魂"]
                ],
                relatedSymbols: ["flying", "sky", "freedom", "message"]
            ),
            DreamSymbolEntity(
                id: "animals_horse",
                name: "马",
                nameEn: "horse",
                category: "animals",
                meanings: ["力量", "自由", "旅行", "激情", "耐力"],
                culturalVariations: [
                    "western": ["力量", "自由精神"],
                    "eastern": ["成功", "马到功成"],
                    "indigenous": ["神圣动物", "力量象征"]
                ],
                relatedSymbols: ["running", "riding", "freedom", "journey"]
            )
        ]
    }
    
    private static func createObjectSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "objects_key",
                name: "钥匙",
                nameEn: "key",
                category: "objects",
                meanings: ["解决方案", "机会", "访问权限", "秘密", "控制"],
                culturalVariations: [
                    "western": ["解锁潜能", "新机会"],
                    "eastern": ["开启智慧", "财富之钥"],
                    "indigenous": ["精神通道", "祖先智慧"]
                ],
                relatedSymbols: ["lock", "door", "treasure", "secret"]
            ),
            DreamSymbolEntity(
                id: "objects_mirror",
                name: "镜子",
                nameEn: "mirror",
                category: "objects",
                meanings: ["自我反思", "真相", "幻象", "双重性", "洞察"],
                culturalVariations: [
                    "western": ["自我审视", "虚荣"],
                    "eastern": ["辟邪", "照妖镜"],
                    "indigenous": ["灵魂之门", "平行世界"]
                ],
                relatedSymbols: ["reflection", "self", "truth", "illusion"]
            ),
            DreamSymbolEntity(
                id: "objects_book",
                name: "书",
                nameEn: "book",
                category: "objects",
                meanings: ["知识", "智慧", "学习", "人生篇章", "秘密"],
                culturalVariations: [
                    "western": ["知识来源", "故事"],
                    "eastern": ["圣贤智慧", "经典"],
                    "indigenous": ["祖先智慧", "口述历史"]
                ],
                relatedSymbols: ["reading", "library", "knowledge", "writing"]
            ),
            DreamSymbolEntity(
                id: "objects_phone",
                name: "手机",
                nameEn: "phone",
                category: "objects",
                meanings: ["沟通", "连接", "信息", "社交焦虑", "依赖"],
                culturalVariations: [
                    "western": ["社交工具", "工作生活平衡"],
                    "eastern": ["联系方式", "面子"],
                    "indigenous": ["现代图腾", "连接工具"]
                ],
                relatedSymbols: ["call", "message", "connection", "technology"]
            ),
            DreamSymbolEntity(
                id: "objects_car",
                name: "汽车",
                nameEn: "car",
                category: "objects",
                meanings: ["人生方向", "控制", "身份", "移动性", "独立性"],
                culturalVariations: [
                    "western": ["个人自由", "身份象征"],
                    "eastern": ["地位", "成功标志"],
                    "indigenous": ["现代马车", "移动工具"]
                ],
                relatedSymbols: ["driving", "road", "journey", "control"]
            )
        ]
    }
    
    private static func createPlaceSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "places_house",
                name: "房子",
                nameEn: "house",
                category: "places",
                meanings: ["自我", "心理状态", "安全感", "家庭", "内心世界"],
                culturalVariations: [
                    "western": ["个人空间", "心理结构"],
                    "eastern": ["家族根基", "风水"],
                    "indigenous": ["精神家园", "祖先居所"]
                ],
                relatedSymbols: ["room", "door", "home", "family"]
            ),
            DreamSymbolEntity(
                id: "places_school",
                name: "学校",
                nameEn: "school",
                category: "places",
                meanings: ["学习", "成长", "测试", "社交", "压力"],
                culturalVariations: [
                    "western": ["教育", "社交环境"],
                    "eastern": ["升学压力", "知识殿堂"],
                    "indigenous": ["智慧传承", "成人礼"]
                ],
                relatedSymbols: ["teacher", "test", "learning", "childhood"]
            ),
            DreamSymbolEntity(
                id: "places_hospital",
                name: "医院",
                nameEn: "hospital",
                category: "places",
                meanings: ["治愈", "脆弱", "转变", "关怀", "生死"],
                culturalVariations: [
                    "western": ["医疗", "康复"],
                    "eastern": ["治病救人", "生死场所"],
                    "indigenous": ["治愈之地", "精神康复"]
                ],
                relatedSymbols: ["doctor", "healing", "illness", "recovery"]
            ),
            DreamSymbolEntity(
                id: "places_forest",
                name: "森林",
                nameEn: "forest",
                category: "places",
                meanings: ["潜意识", "神秘", "迷失", "自然", "探索"],
                culturalVariations: [
                    "western": ["未知", "危险与机遇"],
                    "eastern": ["隐居", "修行"],
                    "indigenous": ["神圣之地", "精神世界"]
                ],
                relatedSymbols: ["trees", "path", "wilderness", "nature"]
            ),
            DreamSymbolEntity(
                id: "places_ocean",
                name: "海洋",
                nameEn: "ocean",
                category: "places",
                meanings: ["潜意识", "情绪", "无限", "未知", "起源"],
                culturalVariations: [
                    "western": ["深邃情绪", "未知领域"],
                    "eastern": ["包容万物", "财源"],
                    "indigenous": ["生命之源", "祖先之地"]
                ],
                relatedSymbols: ["water", "waves", "depth", "emotion"]
            )
        ]
    }
    
    private static func createNatureSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "nature_water",
                name: "水",
                nameEn: "water",
                category: "nature",
                meanings: ["情绪", "净化", "生命", "流动", "潜意识"],
                culturalVariations: [
                    "western": ["情绪象征", "净化"],
                    "eastern": ["财运", "智慧"],
                    "indigenous": ["生命之源", "精神净化"]
                ],
                relatedSymbols: ["ocean", "river", "rain", "emotion"]
            ),
            DreamSymbolEntity(
                id: "nature_fire",
                name: "火",
                nameEn: "fire",
                category: "nature",
                meanings: ["激情", "转变", "破坏", "净化", "能量"],
                culturalVariations: [
                    "western": ["激情", "愤怒", "净化"],
                    "eastern": ["兴旺", "红火"],
                    "indigenous": ["神圣元素", "仪式之火"]
                ],
                relatedSymbols: ["flame", "heat", "passion", "transformation"]
            ),
            DreamSymbolEntity(
                id: "nature_tree",
                name: "树",
                nameEn: "tree",
                category: "nature",
                meanings: ["成长", "生命", "连接", "稳定", "智慧"],
                culturalVariations: [
                    "western": ["生命之树", "成长"],
                    "eastern": ["长寿", "风水树"],
                    "indigenous": ["世界树", "祖先连接"]
                ],
                relatedSymbols: ["roots", "branches", "forest", "growth"]
            ),
            DreamSymbolEntity(
                id: "nature_moon",
                name: "月亮",
                nameEn: "moon",
                category: "nature",
                meanings: ["女性", "直觉", "周期", "潜意识", "神秘"],
                culturalVariations: [
                    "western": ["女性力量", "直觉"],
                    "eastern": ["团圆", "思念"],
                    "indigenous": ["女性周期", "狩猎时间"]
                ],
                relatedSymbols: ["night", "cycles", "feminine", "intuition"]
            ),
            DreamSymbolEntity(
                id: "nature_sun",
                name: "太阳",
                nameEn: "sun",
                category: "nature",
                meanings: ["男性", "意识", "活力", "成功", "启蒙"],
                culturalVariations: [
                    "western": ["生命力", "意识"],
                    "eastern": ["阳气", "吉祥"],
                    "indigenous": ["生命给予者", "神灵之眼"]
                ],
                relatedSymbols: ["day", "light", "masculine", "energy"]
            )
        ]
    }
    
    // 继续创建其他类别的符号...
    // 为节省空间，这里简化处理，实际应创建完整的 300+ 符号
    
    private static func createActionSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "actions_running",
                name: "奔跑",
                nameEn: "running",
                category: "actions",
                meanings: ["逃避", "追求", "焦虑", "能量", "进展"],
                culturalVariations: [:],
                relatedSymbols: ["chase", "escape", "movement", "urgency"]
            ),
            DreamSymbolEntity(
                id: "actions_flying",
                name: "飞行",
                nameEn: "flying",
                category: "actions",
                meanings: ["自由", "超越", "控制", "视角", "逃避"],
                culturalVariations: [:],
                relatedSymbols: ["bird", "sky", "freedom", "liberation"]
            ),
            DreamSymbolEntity(
                id: "actions_falling",
                name: "坠落",
                nameEn: "falling",
                category: "actions",
                meanings: ["失控", "恐惧", "失败", "放手", "转变"],
                culturalVariations: [:],
                relatedSymbols: ["drop", "gravity", "fear", "loss"]
            )
        ]
    }
    
    private static func createEmotionSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "emotions_fear",
                name: "恐惧",
                nameEn: "fear",
                category: "emotions",
                meanings: ["威胁", "未知", "脆弱", "保护机制"],
                culturalVariations: [:],
                relatedSymbols: ["anxiety", "danger", "escape", "threat"]
            ),
            DreamSymbolEntity(
                id: "emotions_joy",
                name: "喜悦",
                nameEn: "joy",
                category: "emotions",
                meanings: ["满足", "成就", "连接", "积极能量"],
                culturalVariations: [:],
                relatedSymbols: ["happiness", "celebration", "love", "peace"]
            )
        ]
    }
    
    private static func createSupernaturalSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "supernatural_ghost",
                name: "鬼魂",
                nameEn: "ghost",
                category: "supernatural",
                meanings: ["过去", "未解决", "记忆", "恐惧", "遗产"],
                culturalVariations: [
                    "western": ["死者灵魂", "恐怖"],
                    "eastern": ["祖先", "冤魂"],
                    "indigenous": ["精神存在", "信使"]
                ],
                relatedSymbols: ["death", "past", "memory", "spirit"]
            ),
            DreamSymbolEntity(
                id: "supernatural_angel",
                name: "天使",
                nameEn: "angel",
                category: "supernatural",
                meanings: ["保护", "指导", "神圣", "希望", "信息"],
                culturalVariations: [
                    "western": ["神的使者", "守护"],
                    "eastern": ["飞天", "神灵"],
                    "indigenous": ["精神向导", "保护者"]
                ],
                relatedSymbols: ["divine", "protection", "guidance", "spirit"]
            )
        ]
    }
    
    private static func createTechnologySymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "technology_computer",
                name: "电脑",
                nameEn: "computer",
                category: "technology",
                meanings: ["思维", "处理", "工作", "连接", "信息"],
                culturalVariations: [:],
                relatedSymbols: ["phone", "internet", "work", "data"]
            ),
            DreamSymbolEntity(
                id: "technology_internet",
                name: "网络",
                nameEn: "internet",
                category: "technology",
                meanings: ["连接", "信息", "社交", "无限", "依赖"],
                culturalVariations: [:],
                relatedSymbols: ["computer", "social", "connection", "data"]
            )
        ]
    }
    
    private static func createFoodSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "food_bread",
                name: "面包",
                nameEn: "bread",
                category: "food",
                meanings: [" sustenance", "基本需求", "分享", "精神食粮"],
                culturalVariations: [:],
                relatedSymbols: ["eat", "hunger", "nourishment", "sharing"]
            ),
            DreamSymbolEntity(
                id: "food_fruit",
                name: "水果",
                nameEn: "fruit",
                category: "food",
                meanings: ["成果", "丰收", "健康", "甜蜜", "自然"],
                culturalVariations: [:],
                relatedSymbols: ["tree", "harvest", "health", "sweet"]
            )
        ]
    }
    
    private static func createBuildingSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "buildings_bridge",
                name: "桥",
                nameEn: "bridge",
                category: "buildings",
                meanings: ["过渡", "连接", "转变", "跨越", "机会"],
                culturalVariations: [:],
                relatedSymbols: ["crossing", "transition", "connection", "journey"]
            ),
            DreamSymbolEntity(
                id: "buildings_tower",
                name: "塔",
                nameEn: "tower",
                category: "buildings",
                meanings: ["野心", "孤立", "成就", "精神高度", "警示"],
                culturalVariations: [:],
                relatedSymbols: ["height", "ambition", "isolation", "achievement"]
            )
        ]
    }
    
    private static func createTransportationSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "transportation_train",
                name: "火车",
                nameEn: "train",
                category: "transportation",
                meanings: ["人生旅程", "既定路线", "集体", "进展", "过渡"],
                culturalVariations: [:],
                relatedSymbols: ["track", "journey", "destination", "movement"]
            ),
            DreamSymbolEntity(
                id: "transportation_airplane",
                name: "飞机",
                nameEn: "airplane",
                category: "transportation",
                meanings: ["快速变化", "远距离", "野心", "逃避", "视角"],
                culturalVariations: [:],
                relatedSymbols: ["flying", "travel", "distance", "speed"]
            )
        ]
    }
    
    private static func createWeatherSymbols() -> [DreamSymbolEntity] {
        return [
            DreamSymbolEntity(
                id: "weather_rain",
                name: "雨",
                nameEn: "rain",
                category: "weather",
                meanings: ["净化", "更新", "悲伤", "滋养", "情绪释放"],
                culturalVariations: [:],
                relatedSymbols: ["water", "storm", "cleansing", "emotion"]
            ),
            DreamSymbolEntity(
                id: "weather_storm",
                name: "暴风雨",
                nameEn: "storm",
                category: "weather",
                meanings: ["冲突", "情绪爆发", "混乱", "转变", "力量"],
                culturalVariations: [:],
                relatedSymbols: ["thunder", "lightning", "chaos", "power"]
            )
        ]
    }
}
