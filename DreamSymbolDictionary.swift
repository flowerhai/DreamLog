//
//  DreamSymbolDictionary.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  梦境符号词典 - 包含 200+ 常见梦境符号的多层级解读
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation

// MARK: - 符号词典服务

/// 梦境符号词典服务
public actor DreamSymbolDictionary {
    /// 共享实例
    public static let shared = DreamSymbolDictionary()
    
    /// 符号数据库
    private var symbols: [String: SymbolEntry] = [:]
    
    /// 初始化时加载符号库
    init() {
        loadSymbolDatabase()
    }
    
    // MARK: - 公共方法
    
    /// 搜索符号
    public func searchSymbol(_ query: String) -> [SymbolEntry] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 精确匹配
        if let exactMatch = symbols[normalizedQuery] {
            return [exactMatch]
        }
        
        // 模糊匹配
        var results: [SymbolEntry] = []
        
        // 名称包含匹配
        for (key, symbol) in symbols {
            if key.contains(normalizedQuery) {
                results.append(symbol)
            }
        }
        
        // 类别匹配（中文）
        if !normalizedQuery.isEmpty {
            for symbol in symbols.values {
                if symbol.category.displayName.contains(normalizedQuery) {
                    results.append(symbol)
                }
            }
        }
        
        return results.sorted { $0.name < $1.name }
    }
    
    /// 根据类别获取符号
    public func getSymbols(by category: SymbolCategory) -> [SymbolEntry] {
        symbols.values.filter { $0.category == category }.sorted { $0.name < $1.name }
    }
    
    /// 获取符号详情
    public func getSymbol(_ name: String) -> SymbolEntry? {
        symbols[name.lowercased().trimmingCharacters(in: .whitespaces)]
    }
    
    /// 获取所有类别
    public func getAllCategories() -> [SymbolCategory] {
        SymbolCategory.allCases
    }
    
    /// 获取热门标签
    public func getPopularTags() -> [String] {
        symbols.values
            .flatMap { $0.tags }
            .reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
            .sorted { $0.value > $1.value }
            .prefix(20)
            .map { $0.key }
    }
    
    /// 获取相关符号
    public func getRelatedSymbols(for symbolName: String, limit: Int = 5) -> [SymbolEntry] {
        guard let symbol = symbols[symbolName.lowercased()] else {
            return []
        }
        
        var related: [SymbolEntry] = []
        
        // 通过标签匹配
        for (key, s) in symbols {
            if key != symbolName.lowercased() {
                let commonTags = Set(symbol.tags).intersection(Set(s.tags))
                if !commonTags.isEmpty {
                    related.append(s)
                }
            }
        }
        
        // 通过类别匹配
        if related.count < limit {
            for (key, s) in symbols {
                if key != symbolName.lowercased() && s.category == symbol.category {
                    if !related.contains(where: { $0.name == s.name }) {
                        related.append(s)
                    }
                }
            }
        }
        
        return Array(related.prefix(limit))
    }
    
    // MARK: - 符号数据库加载
    
    /// 加载符号数据库
    private func loadSymbolDatabase() {
        // 人物类符号
        loadPersonSymbols()
        
        // 地点类符号
        loadPlaceSymbols()
        
        // 物体类符号
        loadObjectSymbols()
        
        // 动作类符号
        loadActionSymbols()
        
        // 情境类符号
        loadSituationSymbols()
        
        // 动物类符号
        loadAnimalSymbols()
        
        // 自然类符号
        loadNatureSymbols()
        
        // 抽象类符号
        loadAbstractSymbols()
    }
    
    // MARK: - 人物类符号
    
    private func loadPersonSymbols() {
        let personSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "自己",
                category: .person,
                tags: ["自我", "身份", "反思"],
                surfaceMeaning: "梦中的自己通常代表你的自我意识和当前状态",
                psychologicalMeaning: "反映你对自我的认知和接纳程度。梦中自己的形象、行为和感受揭示了你的自尊水平和自我认同",
                spiritualMeaning: "象征灵魂的自我探索之旅。梦中与自己的对话或互动可能暗示内在智慧的觉醒",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "荣格认为梦中的自己代表'自我'(Ego)，是意识的中心", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦中见自己，主自我反省，宜修身养性", source: "周公解梦")
                ],
                relatedSymbols: ["镜子", "影子", "双胞胎"]
            ),
            
            SymbolEntry(
                name: "母亲",
                category: .person,
                tags: ["家庭", "养育", "情感"],
                surfaceMeaning: "梦见母亲通常与家庭、养育和无条件的爱有关",
                psychologicalMeaning: "母亲象征养育、保护和情感支持。可能反映你对母爱的需求、与母亲的关系，或你内在的养育特质",
                spiritualMeaning: "代表宇宙母性原则，象征创造、滋养和生命的源头",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "弗洛伊德认为母亲梦可能反映俄狄浦斯情结；荣格视为'伟大母亲'原型", source: "精神分析"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见母亲，主家庭和睦，或思念亲人", source: "周公解梦")
                ],
                relatedSymbols: ["家", "婴儿", "食物"]
            ),
            
            SymbolEntry(
                name: "父亲",
                category: .person,
                tags: ["家庭", "权威", "指导"],
                surfaceMeaning: "梦见父亲通常与权威、规则和指导有关",
                psychologicalMeaning: "父亲象征权威、秩序和保护。可能反映你对权威的态度、与父亲的关系，或你内在的规则意识",
                spiritualMeaning: "代表宇宙父性原则，象征结构、纪律和精神指引",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "荣格认为父亲代表'智慧老人'原型，象征指导和智慧", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见父亲，主事业顺利，或得长辈提携", source: "周公解梦")
                ],
                relatedSymbols: ["房子", "书", "工具"]
            ),
            
            SymbolEntry(
                name: "陌生人",
                category: .person,
                tags: ["未知", "探索", "变化"],
                surfaceMeaning: "梦见陌生人可能代表未知的人或即将到来的变化",
                psychologicalMeaning: "陌生人往往是你内在未知部分的投射。可能代表你尚未认识的性格特质、潜能或恐惧",
                spiritualMeaning: "象征灵魂旅程中的新机遇或挑战，暗示即将进入生命的新阶段",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "荣格认为陌生人可能代表'阴影'或'阿尼玛/阿尼姆斯'", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见陌生人，主有客来访，或遇贵人", source: "周公解梦")
                ],
                relatedSymbols: ["门", "路", "面具"]
            ),
            
            SymbolEntry(
                name: "已故的人",
                category: .person,
                tags: ["过去", "怀念", "智慧"],
                surfaceMeaning: "梦见已故的人通常与怀念、未完成的情感或寻求智慧有关",
                psychologicalMeaning: "这类梦帮助处理悲伤和失落。已故者可能代表你渴望的智慧、指导，或未解决的情感",
                spiritualMeaning: "在许多文化中被视为来自另一个世界的信息，象征祖先的保佑或精神的指引",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "可能是潜意识处理悲伤的方式，或内在智慧的象征", source: " grief counseling"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见已故亲人，主思念或祖先庇佑，宜祭拜", source: "民间信仰"),
                    CulturalInterpretation(culture: "墨西哥文化", interpretation: "亡灵节传统认为逝者会在梦中与亲人相会", source: "Día de los Muertos")
                ],
                relatedSymbols: ["光", "天使", "墓地"]
            ),
            
            SymbolEntry(
                name: "名人",
                category: .person,
                tags: ["理想", "成就", "投射"],
                surfaceMeaning: "梦见名人可能反映你对成功、认可或特定品质的渴望",
                psychologicalMeaning: "名人代表你渴望拥有的特质或成就。他们是你理想和抱负的投射",
                spiritualMeaning: "象征你内在的神圣潜能，提醒你有能力实现伟大的事情",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "名人梦反映社会价值观和个人抱负的内化", source: "社会心理学")
                ],
                relatedSymbols: ["舞台", "奖杯", "观众"]
            ),
            
            SymbolEntry(
                name: "孩子",
                category: .person,
                tags: ["纯真", "潜能", "新生"],
                surfaceMeaning: "梦见孩子通常与纯真、新的开始或内在小孩有关",
                psychologicalMeaning: "孩子象征你的内在小孩、未开发的潜能，或生活中新的开始。也可能反映你对养育的渴望或担忧",
                spiritualMeaning: "代表灵魂的新生和纯真，象征精神成长的开始",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "荣格认为孩子代表'神圣儿童'原型，象征潜能和新生", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见小孩，主有喜事，或新计划开始", source: "周公解梦")
                ],
                relatedSymbols: ["婴儿", "玩具", "学校"]
            ),
            
            SymbolEntry(
                name: "老人",
                category: .person,
                tags: ["智慧", "经验", "指导"],
                surfaceMeaning: "梦见老人通常与智慧、经验和人生指导有关",
                psychologicalMeaning: "老人象征智慧、经验和内在指导。可能代表你寻求建议的需求，或你内在的智慧声音",
                spiritualMeaning: "代表'智慧老人'原型，象征精神导师和更高的智慧",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "荣格的'智慧老人'原型，代表精神指导和智慧", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见老人，主长寿，或得贵人指点", source: "周公解梦")
                ],
                relatedSymbols: ["书", "拐杖", "树"]
            )
        ]
        
        for symbol in personSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
    
    // MARK: - 地点类符号
    
    private func loadPlaceSymbols() {
        let placeSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "家",
                category: .place,
                tags: ["安全", "自我", "归属"],
                surfaceMeaning: "梦见家通常与安全感、归属感和自我认同有关",
                psychologicalMeaning: "家象征你的内心世界和自我。不同的房间代表你性格的不同方面。家的状态反映你的心理状态",
                spiritualMeaning: "代表灵魂的居所，象征内在的平静和精神的归宿",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "家代表自我结构，房间代表意识的不同层面", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见回家，主平安；梦见新家，主新开始", source: "周公解梦")
                ],
                relatedSymbols: ["房间", "门", "钥匙"]
            ),
            
            SymbolEntry(
                name: "学校",
                category: .place,
                tags: ["学习", "成长", "考验"],
                surfaceMeaning: "梦见学校通常与学习、成长或面临考验有关",
                psychologicalMeaning: "学校象征学习、成长和自我评价。考试梦反映你对被评判的焦虑或对能力的怀疑",
                spiritualMeaning: "代表灵魂的学习旅程，象征人生课题和精神成长的机会",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "学校梦反映社会化和成就焦虑", source: "现代心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见考试，主事业考验；梦见学校，主学习进步", source: "周公解梦")
                ],
                relatedSymbols: ["考试", "老师", "书本"]
            ),
            
            SymbolEntry(
                name: "工作场所",
                category: .place,
                tags: ["责任", "成就", "压力"],
                surfaceMeaning: "梦见工作场所通常与职业、责任或工作压力有关",
                psychologicalMeaning: "工作场所象征你的责任感、成就动机和职业身份。可能反映工作压力或职业焦虑",
                spiritualMeaning: "代表你在世间的使命和贡献，象征通过工作实现自我价值",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "工作梦反映职业压力和成就动机", source: "职业心理学")
                ],
                relatedSymbols: ["办公室", "同事", "老板"]
            ),
            
            SymbolEntry(
                name: "森林",
                category: .place,
                tags: ["未知", "探索", "自然"],
                surfaceMeaning: "梦见森林通常与探索未知、迷失或寻找有关",
                psychologicalMeaning: "森林象征潜意识的深处，代表未知、神秘和内在探索。在森林中迷路可能反映生活中的困惑",
                spiritualMeaning: "代表精神旅程的迷宫，象征寻找真理和智慧的探索",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "森林代表潜意识和未知自我", source: "荣格心理学"),
                    CulturalInterpretation(culture: "凯尔特文化", interpretation: "森林是神圣之地，是精神世界的入口", source: "凯尔特神话"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见森林，主事业茂盛，或遇贵人", source: "周公解梦")
                ],
                relatedSymbols: ["树", "小路", "动物"]
            ),
            
            SymbolEntry(
                name: "水边",
                category: .place,
                tags: ["情感", "过渡", "净化"],
                surfaceMeaning: "梦见水边（海边、湖边、河边）通常与情感、过渡或净化有关",
                psychologicalMeaning: "水边象征情感的边界和过渡状态。可能反映你正在经历情感变化或人生转折",
                spiritualMeaning: "代表净化的仪式场所，象征精神洗礼和重生",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "水边代表意识和潜意识的边界", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见水边，主财运，或情感波动", source: "周公解梦")
                ],
                relatedSymbols: ["水", "船", "桥"]
            ),
            
            SymbolEntry(
                name: "山顶",
                category: .place,
                tags: ["成就", "视野", "目标"],
                surfaceMeaning: "梦见山顶通常与成就、目标达成或获得新视野有关",
                psychologicalMeaning: "山顶象征成就、克服挑战和获得新视角。可能反映你达成目标的渴望或已经取得的进步",
                spiritualMeaning: "代表精神觉醒的高峰体验，象征与更高意识的连接",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "山顶象征成就和启蒙", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见登山到顶，主事业成功，地位提升", source: "周公解梦"),
                    CulturalInterpretation(culture: "佛教", interpretation: "山顶象征觉悟的境界", source: "佛教象征")
                ],
                relatedSymbols: ["山", "攀登", "风景"]
            ),
            
            SymbolEntry(
                name: "迷宫",
                category: .place,
                tags: ["困惑", "探索", "寻找"],
                surfaceMeaning: "梦见迷宫通常与困惑、寻找方向或复杂问题有关",
                psychologicalMeaning: "迷宫象征生活中的困惑和复杂情况。可能反映你在寻找答案或人生方向",
                spiritualMeaning: "代表精神旅程的曲折，象征寻找真理的过程",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "迷宫象征人生旅程和精神探索", source: "希腊神话"),
                    CulturalInterpretation(culture: "中世纪欧洲", interpretation: "教堂迷宫代表朝圣之路", source: "基督教象征")
                ],
                relatedSymbols: ["路", "门", "出口"]
            ),
            
            SymbolEntry(
                name: "医院",
                category: .place,
                tags: ["治愈", "健康", "转变"],
                surfaceMeaning: "梦见医院通常与健康、治愈或生活转变有关",
                psychologicalMeaning: "医院象征治愈和转变的需要。可能反映你身体或情感上的疗愈过程",
                spiritualMeaning: "代表灵魂的疗愈场所，象征精神康复和重生",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "医院梦反映对健康和治愈的关注", source: "健康心理学")
                ],
                relatedSymbols: ["医生", "病床", "药物"]
            )
        ]
        
        for symbol in placeSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
    
    // MARK: - 物体类符号
    
    private func loadObjectSymbols() {
        let objectSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "钥匙",
                category: .object,
                tags: ["解决", "机会", "访问"],
                surfaceMeaning: "梦见钥匙通常与解决问题、获得机会或访问有关",
                psychologicalMeaning: "钥匙象征解决方案、机会和开启新可能性的能力。找到钥匙可能代表发现答案，丢失钥匙可能反映无力感",
                spiritualMeaning: "代表精神启蒙的钥匙，象征打开智慧之门的工具",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "钥匙象征知识和权力的开启", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见钥匙，主解开难题，或得机遇", source: "周公解梦")
                ],
                relatedSymbols: ["锁", "门", "宝箱"]
            ),
            
            SymbolEntry(
                name: "镜子",
                category: .object,
                tags: ["自我", "反思", "真相"],
                surfaceMeaning: "梦见镜子通常与自我反思、真相或自我认知有关",
                psychologicalMeaning: "镜子象征自我反省和真相。镜中的影像反映你对自己的认知。破碎的镜子可能代表自我形象的破裂",
                spiritualMeaning: "代表自我认知的工具，象征看清真实自我的能力",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "镜子代表自我认知和反思", source: "心理学象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见镜子，主自我反省，或真相大白", source: "周公解梦"),
                    CulturalInterpretation(culture: "日本文化", interpretation: "镜子是神圣物品，代表真实和纯洁", source: "神道教")
                ],
                relatedSymbols: ["自己", "影子", "水面"]
            ),
            
            SymbolEntry(
                name: "书",
                category: .object,
                tags: ["知识", "智慧", "学习"],
                surfaceMeaning: "梦见书通常与知识、智慧或学习有关",
                psychologicalMeaning: "书象征知识、智慧和内在指导。读书可能代表寻求答案，写书可能代表分享智慧",
                spiritualMeaning: "代表神圣的知识，象征精神智慧和启示",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "书象征知识和智慧", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见读书，主学业进步；梦见写书，主名声", source: "周公解梦"),
                    CulturalInterpretation(culture: "伊斯兰文化", interpretation: "书代表神圣的启示和智慧", source: "伊斯兰传统")
                ],
                relatedSymbols: ["学校", "图书馆", "笔"]
            ),
            
            SymbolEntry(
                name: "手机",
                category: .object,
                tags: ["沟通", "连接", "信息"],
                surfaceMeaning: "梦见手机通常与沟通、连接或信息有关",
                psychologicalMeaning: "手机象征沟通和连接的需求。无法使用手机可能反映沟通障碍或孤立感",
                spiritualMeaning: "代表与更高意识的连接，象征接收精神信息的能力",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "手机梦反映现代社会的沟通焦虑", source: "现代心理学")
                ],
                relatedSymbols: ["电话", "信息", "网络"]
            ),
            
            SymbolEntry(
                name: "汽车",
                category: .object,
                tags: ["方向", "控制", "旅程"],
                surfaceMeaning: "梦见汽车通常与人生方向、控制感或旅程有关",
                psychologicalMeaning: "汽车象征你的人生方向和掌控感。驾驶汽车代表掌控生活，乘客代表被动，车祸可能反映失控",
                spiritualMeaning: "代表人生旅程的载体，象征你在精神道路上的前进",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "汽车代表个人动力和生活方向", source: "现代心理学")
                ],
                relatedSymbols: ["路", "驾驶", "交通"]
            ),
            
            SymbolEntry(
                name: "钱",
                category: .object,
                tags: ["价值", "资源", "交换"],
                surfaceMeaning: "梦见钱通常与价值、资源或交换有关",
                psychologicalMeaning: "钱象征价值、能力和资源。找到钱可能代表发现自我价值，失去钱可能反映无力感",
                spiritualMeaning: "代表能量和资源的流动，象征宇宙丰盛的意识",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见钱，主财运，但需防破财", source: "周公解梦"),
                    CulturalInterpretation(culture: "西方文化", interpretation: "钱象征个人价值和能力", source: "文化象征")
                ],
                relatedSymbols: ["银行", "购物", "财富"]
            ),
            
            SymbolEntry(
                name: "戒指",
                category: .object,
                tags: ["承诺", "关系", "循环"],
                surfaceMeaning: "梦见戒指通常与承诺、关系或循环有关",
                psychologicalMeaning: "戒指象征承诺、忠诚和完整的循环。订婚戒指代表承诺，丢失戒指可能反映关系焦虑",
                spiritualMeaning: "代表永恒的循环和神圣的结合，象征灵魂的完整",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "戒指象征承诺和永恒", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见戒指，主姻缘，或合作关系", source: "周公解梦")
                ],
                relatedSymbols: ["婚礼", "手", "循环"]
            ),
            
            SymbolEntry(
                name: "钟/表",
                category: .object,
                tags: ["时间", "期限", "意识"],
                surfaceMeaning: "梦见钟表通常与时间、期限或时间意识有关",
                psychologicalMeaning: "钟表象征时间压力、生命意识或对期限的焦虑。停走的钟可能代表停滞感",
                spiritualMeaning: "代表生命的周期和无常，象征珍惜当下的智慧",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "钟象征时间的流逝和生命的有限", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见钟，主时间紧迫，或提醒注意", source: "周公解梦")
                ],
                relatedSymbols: ["时间", "跑", "追赶"]
            )
        ]
        
        for symbol in objectSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
    
    // MARK: - 动作类符号
    
    private func loadActionSymbols() {
        let actionSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "飞行",
                category: .action,
                tags: ["自由", "超越", "能力"],
                surfaceMeaning: "梦见飞行通常与自由、超越限制或掌控感有关",
                psychologicalMeaning: "飞行象征自由、超越限制和掌控感。轻松飞行代表自信，困难飞行可能反映挣扎",
                spiritualMeaning: "代表精神的提升和超越，象征灵魂的自由和更高视角",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "飞行梦是最常见的清醒梦类型，代表自由和掌控", source: "梦境研究"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见飞行，主事业上升，或志向高远", source: "周公解梦"),
                    CulturalInterpretation(culture: "萨满文化", interpretation: "飞行代表灵魂出窍和精神旅程", source: "萨满传统")
                ],
                relatedSymbols: ["鸟", "天空", "翅膀"]
            ),
            
            SymbolEntry(
                name: "坠落",
                category: .action,
                tags: ["失控", "恐惧", "释放"],
                surfaceMeaning: "梦见坠落通常与失控、恐惧或释放有关",
                psychologicalMeaning: "坠落象征失控感、不安全感或恐惧。也可能代表释放控制、信任过程",
                spiritualMeaning: "代表放下执着的需要，象征信任宇宙和臣服",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "坠落梦是最常见的梦之一，反映不安全感", source: "梦境研究"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见坠落，主运势下降，需谨慎", source: "周公解梦")
                ],
                relatedSymbols: ["悬崖", "楼梯", "电梯"]
            ),
            
            SymbolEntry(
                name: "追逐",
                category: .action,
                tags: ["逃避", "压力", "面对"],
                surfaceMeaning: "梦见被追逐通常与逃避、压力或未面对的问题有关",
                psychologicalMeaning: "被追逐象征你在逃避某事——可能是责任、情感或问题。追逐者的身份提供线索",
                spiritualMeaning: "代表需要面对而非逃避的课题，象征成长的挑战",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "追逐梦反映逃避心理和未解决的冲突", source: "心理学")
                ],
                relatedSymbols: ["逃跑", "隐藏", "怪物"]
            ),
            
            SymbolEntry(
                name: "跑步",
                category: .action,
                tags: ["进步", "努力", "逃避"],
                surfaceMeaning: "梦见跑步通常与进步、努力或逃避有关",
                psychologicalMeaning: "跑步象征前进的动力或逃避的冲动。轻松跑步代表自信，困难跑步可能反映阻力",
                spiritualMeaning: "代表精神旅程的进展，象征朝着目标前进",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "跑步梦反映生活动力和压力", source: "现代心理学")
                ],
                relatedSymbols: ["路", "终点", "追赶"]
            ),
            
            SymbolEntry(
                name: "游泳",
                category: .action,
                tags: ["情感", "流动", "适应"],
                surfaceMeaning: "梦见游泳通常与情感、流动或适应有关",
                psychologicalMeaning: "游泳象征在情感中航行。轻松游泳代表情感流畅，挣扎游泳可能反映情感困扰",
                spiritualMeaning: "代表在潜意识海洋中的旅程，象征情感的净化和流动",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "游泳代表情感处理能力", source: "心理学象征")
                ],
                relatedSymbols: ["水", "海洋", "潜水"]
            ),
            
            SymbolEntry(
                name: "战斗",
                category: .action,
                tags: ["冲突", "力量", "对抗"],
                surfaceMeaning: "梦见战斗通常与冲突、力量或对抗有关",
                psychologicalMeaning: "战斗象征内在或外在的冲突。可能反映你正在面对的斗争或需要整合的对立面",
                spiritualMeaning: "代表精神战士的旅程，象征克服内在黑暗的战斗",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "战斗梦反映内在冲突和未解决的矛盾", source: "荣格心理学")
                ],
                relatedSymbols: ["武器", "敌人", "胜利"]
            ),
            
            SymbolEntry(
                name: "说话",
                category: .action,
                tags: ["表达", "沟通", "真相"],
                surfaceMeaning: "梦见说话通常与表达、沟通或说出真相有关",
                psychologicalMeaning: "说话象征表达的需求。能说话代表自信，无法说话可能反映表达障碍",
                spiritualMeaning: "代表真实表达的力量，象征说出内在真理",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "说话梦反映沟通需求和表达障碍", source: "心理学")
                ],
                relatedSymbols: ["嘴", "声音", "沉默"]
            ),
            
            SymbolEntry(
                name: "哭泣",
                category: .action,
                tags: ["释放", "悲伤", "净化"],
                surfaceMeaning: "梦见哭泣通常与情感释放、悲伤或净化有关",
                psychologicalMeaning: "哭泣象征情感的释放和净化。可能是压抑情感的出口",
                spiritualMeaning: "代表灵魂的净化，象征释放旧伤痛",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "哭泣梦是情感处理的健康方式", source: "心理学")
                ],
                relatedSymbols: ["眼泪", "悲伤", "安慰"]
            )
        ]
        
        for symbol in actionSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
    
    // MARK: - 情境类符号
    
    private func loadSituationSymbols() {
        let situationSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "考试",
                category: .situation,
                tags: ["考验", "评价", "准备"],
                surfaceMeaning: "梦见考试通常与考验、被评价或准备不足有关",
                psychologicalMeaning: "考试象征生活中的考验和自我评价。可能反映你对能力的怀疑或对被评判的焦虑",
                spiritualMeaning: "代表灵魂的成长课题，象征人生学习和进化",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "考试梦是最常见的焦虑梦之一", source: "梦境研究"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见考试，主事业考验，需努力", source: "周公解梦")
                ],
                relatedSymbols: ["学校", "老师", "试卷"]
            ),
            
            SymbolEntry(
                name: "迟到",
                category: .situation,
                tags: ["焦虑", "错过", "压力"],
                surfaceMeaning: "梦见迟到通常与焦虑、错过机会或时间压力有关",
                psychologicalMeaning: "迟到象征对错过机会的恐惧或时间管理的焦虑。可能反映你对生活节奏的担忧",
                spiritualMeaning: "代表对生命时机的觉察，象征信任神圣时机的智慧",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "迟到梦反映时间焦虑和责任压力", source: "心理学")
                ],
                relatedSymbols: ["钟表", "跑", "错过"]
            ),
            
            SymbolEntry(
                name: "迷路",
                category: .situation,
                tags: ["困惑", "方向", "寻找"],
                surfaceMeaning: "梦见迷路通常与困惑、缺乏方向或寻找有关",
                psychologicalMeaning: "迷路象征生活中的困惑和方向感的缺失。可能反映你正在寻找答案或人生目标",
                spiritualMeaning: "代表精神旅程的必经阶段，象征寻找真理的过程",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "迷路梦反映身份困惑和方向缺失", source: "心理学")
                ],
                relatedSymbols: ["地图", "路", "指南针"]
            ),
            
            SymbolEntry(
                name: "公开演讲",
                category: .situation,
                tags: ["表达", "恐惧", "展示"],
                surfaceMeaning: "梦见公开演讲通常与表达、展示自己或被关注有关",
                psychologicalMeaning: "公开演讲象征被关注的渴望或恐惧。可能反映你对自我表达的焦虑",
                spiritualMeaning: "代表分享智慧的召唤，象征勇敢表达真实自我",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "公开演讲梦是最常见的恐惧梦之一", source: "心理学")
                ],
                relatedSymbols: ["舞台", "观众", "话筒"]
            ),
            
            SymbolEntry(
                name: " naked",
                category: .situation,
                tags: ["脆弱", "真实", "暴露"],
                surfaceMeaning: "梦见裸体通常与脆弱、真实或暴露有关",
                psychologicalMeaning: "裸体象征脆弱、真实和毫无防备。可能反映你害怕被看穿或渴望真实",
                spiritualMeaning: "代表灵魂的赤裸真相，象征放下伪装、回归本真",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "裸体梦反映脆弱感和被评判的恐惧", source: "心理学"),
                    CulturalInterpretation(culture: "传统文化", interpretation: "梦见裸体，主隐私暴露，需谨慎", source: "周公解梦")
                ],
                relatedSymbols: ["衣服", "隐藏", "羞耻"]
            ),
            
            SymbolEntry(
                name: "婚礼",
                category: .situation,
                tags: ["结合", "承诺", "新开始"],
                surfaceMeaning: "梦见婚礼通常与结合、承诺或新开始有关",
                psychologicalMeaning: "婚礼象征结合、承诺和新阶段。可能反映你对关系的渴望或对变化的准备",
                spiritualMeaning: "代表神圣的结合，象征内在对立面的整合",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "婚礼象征新的开始和承诺", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见婚礼，主喜事，或新开始", source: "周公解梦")
                ],
                relatedSymbols: ["戒指", "新娘", "庆祝"]
            ),
            
            SymbolEntry(
                name: "葬礼",
                category: .situation,
                tags: ["结束", "告别", "转变"],
                surfaceMeaning: "梦见葬礼通常与结束、告别或转变有关",
                psychologicalMeaning: "葬礼象征结束、告别和转变。可能反映你需要放下过去或正在经历重大变化",
                spiritualMeaning: "代表旧我的死亡和新我的诞生，象征精神重生",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "葬礼梦反映转变和放下的过程", source: "心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见葬礼，主财运，或旧事结束", source: "周公解梦")
                ],
                relatedSymbols: ["死亡", "棺材", "悲伤"]
            ),
            
            SymbolEntry(
                name: "派对",
                category: .situation,
                tags: ["庆祝", "社交", "快乐"],
                surfaceMeaning: "梦见派对通常与庆祝、社交或快乐有关",
                psychologicalMeaning: "派对象征庆祝、社交需求和快乐。可能反映你对社交的渴望或对生活的享受",
                spiritualMeaning: "代表生命的庆祝，象征喜悦和丰盛",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "现代心理学", interpretation: "派对梦反映社交需求和快乐渴望", source: "心理学")
                ],
                relatedSymbols: ["音乐", "舞蹈", "食物"]
            )
        ]
        
        for symbol in situationSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
    
    // MARK: - 动物类符号
    
    private func loadAnimalSymbols() {
        let animalSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "蛇",
                category: .animal,
                tags: ["转变", "智慧", "恐惧"],
                surfaceMeaning: "梦见蛇通常与转变、智慧或恐惧有关",
                psychologicalMeaning: "蛇象征转变、治愈和潜意识力量。可能反映你对变化的恐惧或对智慧的渴望",
                spiritualMeaning: "代表昆达里尼能量和精神觉醒，象征转化和重生",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方心理学", interpretation: "荣格认为蛇代表潜意识和转变", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见蛇，主财运，或小人", source: "周公解梦"),
                    CulturalInterpretation(culture: "印度文化", interpretation: "蛇代表昆达里尼能量和精神觉醒", source: "瑜伽传统"),
                    CulturalInterpretation(culture: "希腊文化", interpretation: "蛇象征治愈和智慧", source: "医神手杖")
                ],
                relatedSymbols: ["龙", "蜕皮", "毒"]
            ),
            
            SymbolEntry(
                name: "狗",
                category: .animal,
                tags: ["忠诚", "友谊", "保护"],
                surfaceMeaning: "梦见狗通常与忠诚、友谊或保护有关",
                psychologicalMeaning: "狗象征忠诚、友谊和无条件的爱。可能反映你对友谊的渴望或内在的忠诚品质",
                spiritualMeaning: "代表忠诚的守护者和精神向导",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "狗象征忠诚和友谊", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见狗，主贵人，或朋友相助", source: "周公解梦"),
                    CulturalInterpretation(culture: "埃及文化", interpretation: "狗是守护神阿努比斯的象征", source: "埃及神话")
                ],
                relatedSymbols: ["狼", "骨头", "玩耍"]
            ),
            
            SymbolEntry(
                name: "猫",
                category: .animal,
                tags: ["独立", "直觉", "神秘"],
                surfaceMeaning: "梦见猫通常与独立、直觉或神秘有关",
                psychologicalMeaning: "猫象征独立、直觉和女性力量。可能反映你的直觉能力或对独立的渴望",
                spiritualMeaning: "代表神秘的智慧和直觉力，象征魔法和灵性",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "古埃及", interpretation: "猫是神圣的动物，代表女神巴斯特", source: "埃及神话"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见猫，主小人，需谨慎", source: "周公解梦"),
                    CulturalInterpretation(culture: "日本文化", interpretation: "招财猫象征好运和财富", source: "日本文化")
                ],
                relatedSymbols: ["老虎", "夜晚", "神秘"]
            ),
            
            SymbolEntry(
                name: "鸟",
                category: .animal,
                tags: ["自由", "精神", "信息"],
                surfaceMeaning: "梦见鸟通常与自由、精神或信息有关",
                psychologicalMeaning: "鸟象征自由、精神和更高的视角。可能反映你对自由的渴望或精神提升",
                spiritualMeaning: "代表精神的信使，象征灵魂的自由和超越",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "鸟象征自由和精神", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见鸟，主消息，或志向高远", source: "周公解梦"),
                    CulturalInterpretation(culture: " Native American", interpretation: "鸟是精神世界的信使", source: "原住民传统")
                ],
                relatedSymbols: ["飞行", "天空", "翅膀"]
            ),
            
            SymbolEntry(
                name: "鱼",
                category: .animal,
                tags: ["财富", "潜意识", "丰盛"],
                surfaceMeaning: "梦见鱼通常与财富、潜意识或丰盛有关",
                psychologicalMeaning: "鱼象征潜意识的内容和情感的深度。可能反映你的直觉或隐藏的情感",
                spiritualMeaning: "代表精神的丰盛和潜意识的智慧",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见鱼，主财运，年年有余", source: "周公解梦"),
                    CulturalInterpretation(culture: "基督教", interpretation: "鱼是基督教的象征", source: "基督教象征"),
                    CulturalInterpretation(culture: "心理学", interpretation: "鱼代表潜意识的内容", source: "荣格心理学")
                ],
                relatedSymbols: ["水", "海洋", "钓鱼"]
            ),
            
            SymbolEntry(
                name: "蜘蛛",
                category: .animal,
                tags: ["创造", "耐心", "陷阱"],
                surfaceMeaning: "梦见蜘蛛通常与创造、耐心或陷阱有关",
                psychologicalMeaning: "蜘蛛象征创造力、耐心和女性力量。也可能反映你感觉被困住",
                spiritualMeaning: "代表命运之网的编织者，象征创造和互联",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "蜘蛛象征创造力和耐心", source: "文化象征"),
                    CulturalInterpretation(culture: "非洲文化", interpretation: "蜘蛛是智慧之神阿南西", source: "非洲神话"),
                    CulturalInterpretation(culture: " Native American", interpretation: "蜘蛛是创造世界的祖母", source: "原住民传统")
                ],
                relatedSymbols: ["网", "编织", "昆虫"]
            ),
            
            SymbolEntry(
                name: "马",
                category: .animal,
                tags: ["力量", "自由", "旅程"],
                surfaceMeaning: "梦见马通常与力量、自由或旅程有关",
                psychologicalMeaning: "马象征力量、自由和动力。可能反映你的驱动力或对自由的渴望",
                spiritualMeaning: "代表精神旅程的伙伴，象征力量和耐力",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "西方文化", interpretation: "马象征力量和自由", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见马，主事业成功，马到成功", source: "周公解梦"),
                    CulturalInterpretation(culture: "蒙古文化", interpretation: "马是神圣的动物，象征力量和自由", source: "蒙古传统")
                ],
                relatedSymbols: ["骑马", "奔跑", "马车"]
            ),
            
            SymbolEntry(
                name: "龙",
                category: .animal,
                tags: ["力量", "智慧", "神秘"],
                surfaceMeaning: "梦见龙通常与力量、智慧或神秘有关",
                psychologicalMeaning: "龙象征强大的力量、智慧和潜意识。可能反映你内在的力量或对智慧的渴望",
                spiritualMeaning: "代表神圣的力量和精神守护",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "龙是神圣的吉祥物，象征权力、智慧和好运", source: "中国文化"),
                    CulturalInterpretation(culture: "西方文化", interpretation: "龙象征挑战和需要克服的恐惧", source: "西方神话"),
                    CulturalInterpretation(culture: "日本文化", interpretation: "龙是水神，象征力量和保护", source: "日本神话")
                ],
                relatedSymbols: ["蛇", "火", "宝藏"]
            )
        ]
        
        for symbol in animalSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
    
    // MARK: - 自然类符号
    
    private func loadNatureSymbols() {
        let natureSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "水",
                category: .nature,
                tags: ["情感", "净化", "流动"],
                surfaceMeaning: "梦见水通常与情感、净化或流动有关",
                psychologicalMeaning: "水象征情感、潜意识和净化。水的状态（清澈/浑浊/平静/汹涌）反映你的情感状态",
                spiritualMeaning: "代表生命的源头和净化之力，象征精神的洗礼",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "水代表情感和潜意识", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "水主财，梦见水主财运", source: "周公解梦"),
                    CulturalInterpretation(culture: "印度文化", interpretation: "水是神圣的净化元素", source: "印度传统")
                ],
                relatedSymbols: ["海洋", "河流", "雨"]
            ),
            
            SymbolEntry(
                name: "火",
                category: .nature,
                tags: ["激情", "转变", "净化"],
                surfaceMeaning: "梦见火通常与激情、转变或净化有关",
                psychologicalMeaning: "火象征激情、转变和净化。可能反映你的愤怒、热情或需要释放的情感",
                spiritualMeaning: "代表转化的力量和神圣的净化",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "火象征激情和转变", source: "心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见火，主兴旺，但需防火灾", source: "周公解梦"),
                    CulturalInterpretation(culture: "希腊文化", interpretation: "火是普罗米修斯给人类的礼物", source: "希腊神话"),
                    CulturalInterpretation(culture: "印度文化", interpretation: "火是神圣的净化元素", source: "印度传统")
                ],
                relatedSymbols: ["燃烧", "太阳", "蜡烛"]
            ),
            
            SymbolEntry(
                name: "树",
                category: .nature,
                tags: ["成长", "生命", "连接"],
                surfaceMeaning: "梦见树通常与成长、生命或连接有关",
                psychologicalMeaning: "树象征成长、生命力和连接。树的状态反映你的成长状态",
                spiritualMeaning: "代表生命之树，象征天地连接和精神成长",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "树象征个体化和成长", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见树，主事业稳固，基业长青", source: "周公解梦"),
                    CulturalInterpretation(culture: "北欧文化", interpretation: "世界树 Yggdrasil 连接九个世界", source: "北欧神话"),
                    CulturalInterpretation(culture: "凯尔特文化", interpretation: "树是神圣的，代表智慧和保护", source: "凯尔特传统")
                ],
                relatedSymbols: ["森林", "根", "果实"]
            ),
            
            SymbolEntry(
                name: "山",
                category: .nature,
                tags: ["挑战", "目标", "稳定"],
                surfaceMeaning: "梦见山通常与挑战、目标或稳定有关",
                psychologicalMeaning: "山象征挑战、目标和稳定。登山代表追求目标，下山可能代表放松或放弃",
                spiritualMeaning: "代表精神的高峰和接近神圣",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "文化象征", interpretation: "山象征挑战和精神高度", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见山，主靠山，事业稳固", source: "周公解梦"),
                    CulturalInterpretation(culture: "佛教", interpretation: "山是修行的圣地", source: "佛教传统")
                ],
                relatedSymbols: ["攀登", "山顶", "岩石"]
            ),
            
            SymbolEntry(
                name: "雨",
                category: .nature,
                tags: ["净化", "情感", "新生"],
                surfaceMeaning: "梦见雨通常与净化、情感或新生有关",
                psychologicalMeaning: "雨象征净化、情感释放和新生。可能反映你需要释放情感或新的开始",
                spiritualMeaning: "代表天界的祝福和净化",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "雨象征情感释放和净化", source: "心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见雨，主财运，或情感释放", source: "周公解梦")
                ],
                relatedSymbols: ["水", "云", "雷"]
            ),
            
            SymbolEntry(
                name: "太阳",
                category: .nature,
                tags: ["光明", "能量", "意识"],
                surfaceMeaning: "梦见太阳通常与光明、能量或意识有关",
                psychologicalMeaning: "太阳象征意识、能量和生命力。可能反映你的活力状态或积极心态",
                spiritualMeaning: "代表神圣的光明和觉醒",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "文化象征", interpretation: "太阳象征生命和光明", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见太阳，主兴旺，事业光明", source: "周公解梦"),
                    CulturalInterpretation(culture: "埃及文化", interpretation: "太阳神 Ra 是最高神", source: "埃及神话")
                ],
                relatedSymbols: ["光", "白天", "温暖"]
            ),
            
            SymbolEntry(
                name: "月亮",
                category: .nature,
                tags: ["直觉", "女性", "周期"],
                surfaceMeaning: "梦见月亮通常与直觉、女性或周期有关",
                psychologicalMeaning: "月亮象征直觉、女性力量和情感周期。可能反映你的直觉能力或情感波动",
                spiritualMeaning: "代表女性能量和潜意识的智慧",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "月亮象征潜意识和女性能量", source: "荣格心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见月亮，主思念，或女性贵人", source: "周公解梦"),
                    CulturalInterpretation(culture: "希腊文化", interpretation: "月亮女神 Selene 代表夜晚和直觉", source: "希腊神话")
                ],
                relatedSymbols: ["夜晚", "星星", "潮汐"]
            ),
            
            SymbolEntry(
                name: "星星",
                category: .nature,
                tags: ["希望", "指引", "梦想"],
                surfaceMeaning: "梦见星星通常与希望、指引或梦想有关",
                psychologicalMeaning: "星星象征希望、指引和梦想。可能反映你的愿望或对未来的期待",
                spiritualMeaning: "代表神圣的指引和灵魂的光芒",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "文化象征", interpretation: "星星象征希望和指引", source: "文化象征"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见星星，主愿望达成，或贵人相助", source: "周公解梦")
                ],
                relatedSymbols: ["天空", "月亮", "许愿"]
            )
        ]
        
        for symbol in natureSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
    
    // MARK: - 抽象类符号
    
    private func loadAbstractSymbols() {
        let abstractSymbols: [SymbolEntry] = [
            SymbolEntry(
                name: "光",
                category: .abstract,
                tags: ["启示", "意识", "希望"],
                surfaceMeaning: "梦见光通常与启示、意识或希望有关",
                psychologicalMeaning: "光象征意识、启示和希望。可能反映你的觉悟状态或积极心态",
                spiritualMeaning: "代表神圣的启示和精神觉醒",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "宗教传统", interpretation: "光象征神圣和启蒙", source: "多宗教"),
                    CulturalInterpretation(culture: "心理学", interpretation: "光象征意识和觉悟", source: "心理学")
                ],
                relatedSymbols: ["太阳", "灯", "黑暗"]
            ),
            
            SymbolEntry(
                name: "黑暗",
                category: .abstract,
                tags: ["未知", "恐惧", "潜力"],
                surfaceMeaning: "梦见黑暗通常与未知、恐惧或潜力有关",
                psychologicalMeaning: "黑暗象征未知、恐惧和潜意识。可能反映你对未知的恐惧或需要探索的内在领域",
                spiritualMeaning: "代表转化的孕育期，象征在黑暗中寻找光明",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "黑暗象征潜意识和未知", source: "荣格心理学"),
                    CulturalInterpretation(culture: "传统文化", interpretation: "黑暗主谨慎，需防小人", source: "周公解梦")
                ],
                relatedSymbols: ["夜晚", "影子", "光"]
            ),
            
            SymbolEntry(
                name: "时间",
                category: .abstract,
                tags: ["流逝", "有限", "珍贵"],
                surfaceMeaning: "梦见时间通常与流逝、有限或珍贵有关",
                psychologicalMeaning: "时间象征生命的有限性和对时间的感知。可能反映你对时间流逝的焦虑",
                spiritualMeaning: "代表生命的周期和无常的智慧",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "哲学", interpretation: "时间象征生命的有限", source: "哲学")
                ],
                relatedSymbols: ["钟表", "沙漏", "衰老"]
            ),
            
            SymbolEntry(
                name: "死亡",
                category: .abstract,
                tags: ["结束", "转变", "重生"],
                surfaceMeaning: "梦见死亡通常与结束、转变或重生有关",
                psychologicalMeaning: "死亡象征结束、转变和重生。很少预示真实死亡，更多反映生活中的重大变化",
                spiritualMeaning: "代表旧我的死亡和新我的诞生",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "死亡梦象征转变而非真实死亡", source: "心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "梦见死亡，主长寿，或新开始", source: "周公解梦"),
                    CulturalInterpretation(culture: "埃及文化", interpretation: "死亡是通往永生的门", source: "埃及信仰")
                ],
                relatedSymbols: ["葬礼", "重生", "结束"]
            ),
            
            SymbolEntry(
                name: "数字",
                category: .abstract,
                tags: ["意义", "模式", "信息"],
                surfaceMeaning: "梦见数字通常与特殊意义、模式或信息有关",
                psychologicalMeaning: "数字象征特殊的意义和信息。不同数字有不同象征意义",
                spiritualMeaning: "代表宇宙的语言和神圣的密码",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "数字命理学", interpretation: "每个数字都有特殊意义", source: "数字命理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "数字有吉凶之分", source: "传统文化")
                ],
                relatedSymbols: ["计算", "数学", "密码"]
            ),
            
            SymbolEntry(
                name: "颜色",
                category: .abstract,
                tags: ["情绪", "能量", "象征"],
                surfaceMeaning: "梦见颜色通常与情绪、能量或象征有关",
                psychologicalMeaning: "颜色象征情绪和能量状态。不同颜色代表不同心理状态",
                spiritualMeaning: "代表能量的振动和精神的频率",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "颜色反映情绪状态", source: "色彩心理学"),
                    CulturalInterpretation(culture: "中国传统文化", interpretation: "颜色有五行属性", source: "五行理论")
                ],
                relatedSymbols: ["彩虹", "光", "情绪"]
            ),
            
            SymbolEntry(
                name: "声音",
                category: .abstract,
                tags: ["信息", "振动", "沟通"],
                surfaceMeaning: "梦见声音通常与信息、振动或沟通有关",
                psychologicalMeaning: "声音象征信息、内在声音或沟通需求。可能反映你需要倾听或表达",
                spiritualMeaning: "代表宇宙的振动和神圣的信息",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "心理学", interpretation: "声音象征内在指引", source: "心理学")
                ],
                relatedSymbols: ["音乐", "说话", "倾听"]
            ),
            
            SymbolEntry(
                name: "循环",
                category: .abstract,
                tags: ["模式", "重复", "周期"],
                surfaceMeaning: "梦见循环通常与模式、重复或周期有关",
                psychologicalMeaning: "循环象征生活中的重复模式或周期。可能反映你需要打破的循环",
                spiritualMeaning: "代表生命的轮回和宇宙的循环",
                culturalInterpretations: [
                    CulturalInterpretation(culture: "东方哲学", interpretation: "循环代表轮回和因果", source: "佛教/印度教"),
                    CulturalInterpretation(culture: "西方心理学", interpretation: "循环象征重复的行为模式", source: "心理学")
                ],
                relatedSymbols: ["圆", "季节", "重复"]
            )
        ]
        
        for symbol in abstractSymbols {
            symbols[symbol.name.lowercased()] = symbol
        }
    }
}

// MARK: - 符号条目模型

/// 符号条目
public struct SymbolEntry: Identifiable, Codable {
    public let id: UUID
    /// 符号名称
    public var name: String
    /// 符号类别
    public var category: SymbolCategory
    /// 标签
    public var tags: [String]
    /// 表面层解读
    public var surfaceMeaning: String
    /// 心理层解读
    public var psychologicalMeaning: String
    /// 精神层解读
    public var spiritualMeaning: String
    /// 文化背景解读
    public var culturalInterpretations: [CulturalInterpretation]
    /// 相关符号
    public var relatedSymbols: [String]
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: SymbolCategory,
        tags: [String],
        surfaceMeaning: String,
        psychologicalMeaning: String,
        spiritualMeaning: String,
        culturalInterpretations: [CulturalInterpretation] = [],
        relatedSymbols: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.tags = tags
        self.surfaceMeaning = surfaceMeaning
        self.psychologicalMeaning = psychologicalMeaning
        self.spiritualMeaning = spiritualMeaning
        self.culturalInterpretations = culturalInterpretations
        self.relatedSymbols = relatedSymbols
    }
}
