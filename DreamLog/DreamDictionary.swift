//
//  DreamDictionary.swift
//  DreamLog
//
//  梦境词典：提供常见梦境元素的象征意义和心理学解读
//

import Foundation
import SwiftUI

/// 梦境元素类别
enum DreamSymbolCategory: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case natural = "自然元素"
    case animals = "动物"
    case people = "人物"
    case places = "场所"
    case actions = "行为"
    case objects = "物品"
    case body = "身体"
    case emotions = "情绪"
    
    var icon: String {
        switch self {
        case .natural: return "🌿"
        case .animals: return "🐾"
        case .people: return "👤"
        case .places: return "🏠"
        case .actions: return "🏃"
        case .objects: return "📦"
        case .body: return "🧍"
        case .emotions: return "💭"
        }
    }
}

/// 梦境符号
struct DreamSymbol: Identifiable, Codable {
    let id: String
    let name: String
    let category: DreamSymbolCategory
    let keywords: [String]
    let meaning: String
    let psychologicalInterpretation: String
    let culturalVariations: [String]
    let relatedSymbols: [String]
    let frequency: Int  // 出现频率统计
    
    var displayKeywords: String {
        keywords.joined(separator: " · ")
    }
}

/// 梦境词典服务
@MainActor
class DreamDictionaryService: ObservableObject {
    @Published var symbols: [DreamSymbol] = []
    @Published var searchQuery: String = ""
    @Published var selectedCategory: DreamSymbolCategory?
    
    static let shared = DreamDictionaryService()
    
    init() {
        loadDefaultSymbols()
    }
    
    // MARK: - 加载默认符号
    
    private func loadDefaultSymbols() {
        symbols = [
            // 自然元素
            DreamSymbol(
                id: "water",
                name: "水",
                category: .natural,
                keywords: ["情绪", "潜意识", "流动", "变化", "净化"],
                meaning: "水通常象征情绪状态和潜意识。平静的水代表内心平和，湍急的水表示情绪波动。",
                psychologicalInterpretation: "从心理学角度，水代表情感的流动。梦见清澈的水通常预示情绪健康，而浑浊的水可能表示内心混乱。",
                culturalVariations: [
                    "中国：水代表财富和好运",
                    "西方：水象征净化和重生",
                    "印度：水代表生命和神圣"
                ],
                relatedSymbols: ["海", "河", "雨", "泪"],
                frequency: 0
            ),
            DreamSymbol(
                id: "fire",
                name: "火",
                category: .natural,
                keywords: ["激情", "转化", "愤怒", "能量", "净化"],
                meaning: "火象征强烈的能量、激情或愤怒。也可以代表转化和重生的过程。",
                psychologicalInterpretation: "火代表被压抑的情绪或欲望。控制良好的火表示健康的激情，失控的火可能表示愤怒管理问题。",
                culturalVariations: [
                    "中国：火代表热情和活力",
                    "希腊：火象征智慧和启蒙",
                    " Native American: 火代表净化和精神力量"
                ],
                relatedSymbols: ["太阳", "蜡烛", "熔岩"],
                frequency: 0
            ),
            DreamSymbol(
                id: "wind",
                name: "风",
                category: .natural,
                keywords: ["变化", "自由", "信息", "精神", "流动"],
                meaning: "风象征变化、自由和不可见的力量。轻柔的风代表平和的变化，狂风表示剧烈的变动。",
                psychologicalInterpretation: "风代表生活中的变化或新的想法。风向可能暗示变化的方向。",
                culturalVariations: [
                    "中国：风代表消息和传播",
                    "日本：风象征精神和无形力量",
                    "凯尔特：风代表旅行和冒险"
                ],
                relatedSymbols: ["空气", "呼吸", "羽毛"],
                frequency: 0
            ),
            
            // 动物
            DreamSymbol(
                id: "snake",
                name: "蛇",
                category: .animals,
                keywords: ["转化", "治愈", "恐惧", "智慧", "性"],
                meaning: "蛇是最复杂的梦境符号之一。可以代表转化、治愈、恐惧或智慧。",
                psychologicalInterpretation: "蛇象征潜意识的智慧和转化过程。被蛇咬可能表示觉醒或伤害。",
                culturalVariations: [
                    "中国：蛇代表智慧和财富",
                    "西方：蛇象征诱惑和危险",
                    "印度：蛇代表昆达里尼能量"
                ],
                relatedSymbols: ["龙", "蜥蜴", "蠕虫"],
                frequency: 0
            ),
            DreamSymbol(
                id: "bird",
                name: "鸟",
                category: .animals,
                keywords: ["自由", "精神", "消息", "希望", "超越"],
                meaning: "鸟象征自由、精神提升和好消息。飞翔的鸟代表解脱和远大目标。",
                psychologicalInterpretation: "鸟代表超越物质世界的渴望。不同种类的鸟有不同含义。",
                culturalVariations: [
                    "中国：凤凰代表吉祥和重生",
                    "西方：鸽子象征和平",
                    "埃及：鹰代表神圣保护"
                ],
                relatedSymbols: ["飞行", "羽毛", "巢"],
                frequency: 0
            ),
            DreamSymbol(
                id: "cat",
                name: "猫",
                category: .animals,
                keywords: ["直觉", "独立", "神秘", "女性", "灵性"],
                meaning: "猫象征直觉、独立和神秘。可能代表梦者自身的女性特质或直觉能力。",
                psychologicalInterpretation: "猫代表独立性和直觉。黑猫可能象征未知或隐藏的智慧。",
                culturalVariations: [
                    "中国：猫代表好运和财富",
                    "埃及：猫是神圣的动物",
                    "欧洲：黑猫曾被视为不祥"
                ],
                relatedSymbols: ["老虎", "狮子", "夜晚"],
                frequency: 0
            ),
            
            // 场所
            DreamSymbol(
                id: "house",
                name: "房子",
                category: .places,
                keywords: ["自我", "心灵", "安全", "家庭", "身份"],
                meaning: "房子通常象征梦者自己或心灵状态。不同房间代表不同的心理层面。",
                psychologicalInterpretation: "房子是自我的象征。地下室代表潜意识，阁楼代表精神层面，客厅代表社交自我。",
                culturalVariations: [
                    "中国：房子代表家庭和祖先",
                    "西方：房子象征个人成就",
                    "印度：房子代表宇宙秩序"
                ],
                relatedSymbols: ["门", "窗", "房间", "钥匙"],
                frequency: 0
            ),
            DreamSymbol(
                id: "school",
                name: "学校",
                category: .places,
                keywords: ["学习", "成长", "压力", "测试", "童年"],
                meaning: "学校象征学习、成长或面临的考验。可能反映对表现的焦虑。",
                psychologicalInterpretation: "学校代表生活中的学习阶段或当前面临的挑战。考试梦常见于压力时期。",
                culturalVariations: [
                    "普遍：学校代表知识和成长",
                    "亚洲：学校强调成就和期望",
                    "西方：学校也代表社交经历"
                ],
                relatedSymbols: ["考试", "老师", "同学", "书本"],
                frequency: 0
            ),
            
            // 行为
            DreamSymbol(
                id: "flying",
                name: "飞行",
                category: .actions,
                keywords: ["自由", "解脱", "掌控", "野心", "逃避"],
                meaning: "飞行是最常见的梦境之一。象征自由、解脱或对掌控的渴望。",
                psychologicalInterpretation: "飞行梦通常表示想要摆脱限制或压力。控制飞行表示自信，失控飞行表示焦虑。",
                culturalVariations: [
                    "中国：飞行代表升官发财",
                    "西方：飞行象征自由和独立",
                    "原住民：飞行代表精神旅程"
                ],
                relatedSymbols: ["鸟", "飞机", "天使", "超人"],
                frequency: 0
            ),
            DreamSymbol(
                id: "falling",
                name: "坠落",
                category: .actions,
                keywords: ["失控", "恐惧", "失败", "放手", "焦虑"],
                meaning: "坠落梦通常表示失控感或对失败的恐惧。也可能表示需要放手。",
                psychologicalInterpretation: "坠落反映现实生活中的不安全感或焦虑。从高处坠落可能表示地位或自信的丧失。",
                culturalVariations: [
                    "普遍：坠落代表失败和恐惧",
                    "中国：坠落可能预示健康问题",
                    "西方：坠落象征失去控制"
                ],
                relatedSymbols: ["跌倒", "跳下", "悬崖"],
                frequency: 0
            ),
            DreamSymbol(
                id: "chase",
                name: "被追逐",
                category: .actions,
                keywords: ["逃避", "压力", "恐惧", "问题", "焦虑"],
                meaning: "被追逐的梦表示你在逃避某个问题、情绪或责任。",
                psychologicalInterpretation: "追逐者通常代表你不愿面对的事情。停下来面对追逐者可能带来启示。",
                culturalVariations: [
                    "普遍：被追逐代表逃避问题",
                    "中国：被鬼追逐可能表示健康问题",
                    "西方：被怪物追逐象征内心恐惧"
                ],
                relatedSymbols: ["逃跑", "躲藏", "怪物", "敌人"],
                frequency: 0
            ),
            
            // 物品
            DreamSymbol(
                id: "key",
                name: "钥匙",
                category: .objects,
                keywords: ["机会", "解答", "控制", "进入", "秘密"],
                meaning: "钥匙象征机会、解答或进入新领域的途径。找到钥匙表示发现解决方案。",
                psychologicalInterpretation: "钥匙代表解决问题的方法或开启潜意识的工具。丢失钥匙表示错失机会。",
                culturalVariations: [
                    "中国：钥匙代表财富和权力",
                    "西方：钥匙象征知识和启蒙",
                    "印度：钥匙代表精神解脱"
                ],
                relatedSymbols: ["锁", "门", "宝箱"],
                frequency: 0
            ),
            DreamSymbol(
                id: "mirror",
                name: "镜子",
                category: .objects,
                keywords: ["自我", "反思", "真相", "幻觉", "双重"],
                meaning: "镜子象征自我反思、真相或自我认知。破碎的镜子可能表示自我形象受损。",
                psychologicalInterpretation: "镜子代表自我审视。镜中的影像可能揭示你如何看待自己或希望成为的样子。",
                culturalVariations: [
                    "中国：镜子辟邪，也代表真相",
                    "西方：镜子象征虚荣或自我认知",
                    "日本：镜子是神圣的物品"
                ],
                relatedSymbols: ["倒影", "玻璃", "影像"],
                frequency: 0
            ),
            
            // 身体
            DreamSymbol(
                id: "teeth",
                name: "牙齿",
                category: .body,
                keywords: ["变化", "成长", "焦虑", "力量", "表达"],
                meaning: "牙齿掉落的梦非常常见。通常象征变化、成长焦虑或对失去力量的恐惧。",
                psychologicalInterpretation: "牙齿代表力量和自信。掉牙可能表示对生活变化的焦虑或沟通问题。",
                culturalVariations: [
                    "中国：掉牙可能预示家人健康问题",
                    "西方：掉牙表示焦虑和变化",
                    "中东：掉牙代表长寿"
                ],
                relatedSymbols: ["嘴巴", "流血", "疼痛"],
                frequency: 0
            ),
            DreamSymbol(
                id: "hair",
                name: "头发",
                category: .body,
                keywords: ["力量", "美丽", "身份", "成长", "自由"],
                meaning: "头发象征力量、美丽和个人身份。剪发可能表示改变或失去力量。",
                psychologicalInterpretation: "头发代表个人力量和吸引力。脱发可能表示对衰老或失去吸引力的担忧。",
                culturalVariations: [
                    "中国：头发代表健康和生命力",
                    "圣经：头发象征力量（如参孙）",
                    "印度：头发代表精神修行"
                ],
                relatedSymbols: ["剪刀", "梳子", "长发"],
                frequency: 0
            )
        ]
    }
    
    // MARK: - 搜索功能
    
    /// 搜索梦境符号
    func searchSymbols(query: String) -> [DreamSymbol] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            return filteredSymbols
        }
        
        return symbols.filter { symbol in
            symbol.name.lowercased().contains(trimmedQuery) ||
            symbol.keywords.contains { $0.lowercased().contains(trimmedQuery) } ||
            symbol.meaning.lowercased().contains(trimmedQuery)
        }
    }
    
    /// 按类别过滤
    var filteredSymbols: [DreamSymbol] {
        let baseSymbols = searchSymbols(query: searchQuery)
        
        if let category = selectedCategory {
            return baseSymbols.filter { $0.category == category }
        }
        
        return baseSymbols
    }
    
    // MARK: - 符号解析
    
    /// 解析梦境内容，提取符号
    func analyzeDreamContent(_ content: String) -> [DreamSymbol] {
        var foundSymbols: [DreamSymbol] = []
        let lowercasedContent = content.lowercased()
        
        for symbol in symbols {
            // 检查符号名称
            if lowercasedContent.contains(symbol.name.lowercased()) {
                foundSymbols.append(symbol)
                continue
            }
            
            // 检查关键词
            for keyword in symbol.keywords {
                if lowercasedContent.contains(keyword.lowercased()) {
                    if !foundSymbols.contains(where: { $0.id == symbol.id }) {
                        foundSymbols.append(symbol)
                    }
                    break
                }
            }
        }
        
        return foundSymbols
    }
    
    /// 获取符号的详细解读
    func getSymbolInterpretation(_ symbolId: String) -> DreamSymbol? {
        symbols.first { $0.id == symbolId }
    }
    
    // MARK: - 统计
    
    /// 更新符号出现频率
    func updateSymbolFrequency(_ symbolId: String) {
        if let index = symbols.firstIndex(where: { $0.id == symbolId }) {
            // 由于是 struct，需要重新创建
            var symbol = symbols[index]
            // 这里简化处理，实际应该使用可变的存储
        }
    }
    
    /// 获取最常见的符号
    func getTopSymbols(limit: Int = 10) -> [DreamSymbol] {
        symbols.sorted { $0.frequency > $1.frequency }.prefix(limit).map { $0 }
    }
}

// MARK: - 梦境词典视图

/// 梦境词典浏览视图
struct DreamDictionaryView: View {
    @ObservedObject private var dictionary = DreamDictionaryService.shared
    @State private var selectedSymbol: DreamSymbol?
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    HStack {
                        symbolList
                        if let symbol = selectedSymbol {
                            symbolDetail(symbol)
                        } else {
                            Text("选择一个符号查看详情")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    symbolList
                }
            }
            .navigationTitle("梦境词典")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch.toggle() }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .searchable(text: $dictionary.searchQuery, prompt: "搜索梦境符号...")
        }
    }
    
    private var symbolList: some View {
        List {
            // 类别选择
            Section("类别") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "全部",
                            icon: "🔍",
                            isSelected: dictionary.selectedCategory == nil
                        ) {
                            dictionary.selectedCategory = nil
                        }
                        
                        ForEach(DreamSymbolCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: dictionary.selectedCategory == category
                            ) {
                                dictionary.selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // 符号列表
            Section("符号 (\(dictionary.filteredSymbols.count))") {
                ForEach(dictionary.filteredSymbols) { symbol in
                    SymbolRow(symbol: symbol)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSymbol = symbol
                        }
                }
            }
        }
    }
    
    private func symbolDetail(_ symbol: DreamSymbol) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                HStack {
                    Text(symbol.category.icon)
                        .font(.largeTitle)
                    Text(symbol.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // 关键词
                VStack(alignment: .leading, spacing: 8) {
                    Text("关键词")
                        .font(.headline)
                    Text(symbol.displayKeywords)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // 基本含义
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 基本含义")
                        .font(.headline)
                    Text(symbol.meaning)
                        .foregroundColor(.primary)
                }
                
                // 心理学解读
                VStack(alignment: .leading, spacing: 8) {
                    Text("🧠 心理学解读")
                        .font(.headline)
                    Text(symbol.psychologicalInterpretation)
                        .foregroundColor(.primary)
                }
                
                // 文化差异
                VStack(alignment: .leading, spacing: 8) {
                    Text("🌍 文化差异")
                        .font(.headline)
                    ForEach(symbol.culturalVariations, id: \.self) { variation in
                        Text("• \(variation)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 相关符号
                if !symbol.relatedSymbols.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔗 相关符号")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(symbol.relatedSymbols, id: \.self) { related in
                                Chip(text: related)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - 辅助视图

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct SymbolRow: View {
    let symbol: DreamSymbol
    
    var body: some View {
        HStack(spacing: 12) {
            Text(symbol.category.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol.name)
                    .font(.headline)
                Text(symbol.displayKeywords)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct Chip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.purple.opacity(0.2))
            .foregroundColor(.purple)
            .cornerRadius(12)
    }
}

#Preview {
    DreamDictionaryView()
}
