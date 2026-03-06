//
//  SiriShortcuts.swift
//  DreamLog
//
//  Siri 快捷指令集成 - 支持语音记录梦境、查询统计等
//

import Foundation
import Intents

// MARK: - 记录梦境 Intent
@available(iOS 16.0, *)
public struct RecordDreamIntent: AppIntent {
    public static var title: LocalizedStringResource = "记录梦境"
    public static var description: LocalizedStringResource = "使用语音快速记录一个新的梦境"
    public static var openAppWhenRun: Bool = true
    
    @Parameter(title: "梦境内容", default: "")
    var content: String
    
    @Parameter(title: "情绪", default: [])
    var emotions: [String]
    
    @Parameter(title: "标签", default: [])
    var tags: [String]
    
    public init() {}
    
    public init(content: String, emotions: [String] = [], tags: [String] = []) {
        self.content = content
        self.emotions = emotions
        self.tags = tags
    }
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        // 保存梦境到存储
        let dreamStore = DreamStore.shared
        
        let dream = Dream(
            content: content.isEmpty ? "刚刚做的梦" : content,
            tags: tags,
            emotions: emotions.map { Emotion(rawValue: $0) ?? .neutral },
            clarity: 3,
            intensity: 3
        )
        
        try await dreamStore.addDream(dream)
        
        return .result(
            dialog: "梦境已记录，共 \(dreamStore.dreams.count) 个梦境"
        )
    }
}

// MARK: - 查询梦境统计 Intent
@available(iOS 16.0, *)
public struct GetDreamStatsIntent: AppIntent {
    public static var title: LocalizedStringResource = "获取梦境统计"
    public static var description: LocalizedStringResource = "查询梦境记录统计数据"
    
    @Parameter(title: "时间范围", default: "本周")
    var timeRange: String
    
    public init() {}
    
    public init(timeRange: String = "本周") {
        self.timeRange = timeRange
    }
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let dreamStore = DreamStore.shared
        
        let totalDreams = dreamStore.dreams.count
        let thisWeekDreams = dreamStore.dreams.filter { dream in
            guard let date = dream.timestamp else { return false }
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        
        let dialog: String
        if timeRange.contains("周") {
            dialog = "本周记录了 \(thisWeekDreams) 个梦境，总共 \(totalDreams) 个梦境"
        } else {
            dialog = "你总共记录了 \(totalDreams) 个梦境"
        }
        
        return .result(dialog: dialog)
    }
}

// MARK: - 搜索梦境 Intent
@available(iOS 16.0, *)
public struct SearchDreamsIntent: AppIntent {
    public static var title: LocalizedStringResource = "搜索梦境"
    public static var description: LocalizedStringResource = "根据关键词搜索梦境"
    
    @Parameter(title: "搜索关键词")
    var keyword: String
    
    public init() {}
    
    public init(keyword: String) {
        self.keyword = keyword
    }
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let dreamStore = DreamStore.shared
        
        let results = dreamStore.dreams.filter { dream in
            dream.content.localizedCaseInsensitiveContains(keyword) ||
            dream.tags.contains { $0.localizedCaseInsensitiveContains(keyword) }
        }
        
        let count = results.count
        let dialog: String
        
        if count == 0 {
            dialog = "没有找到包含\"\(keyword)\"的梦境"
        } else if count == 1 {
            dialog = "找到 1 个相关梦境"
        } else {
            dialog = "找到 \(count) 个包含\"\(keyword)\"的梦境"
        }
        
        return .result(dialog: dialog)
    }
}

// MARK: - 获取最近梦境 Intent
@available(iOS 16.0, *)
public struct GetRecentDreamIntent: AppIntent {
    public static var title: LocalizedStringResource = "获取最近梦境"
    public static var description: LocalizedStringResource = "获取最近记录的梦境内容"
    
    @Parameter(title: "数量", default: 1)
    var count: Int
    
    public init() {}
    
    public init(count: Int = 1) {
        self.count = max(1, min(count, 5))
    }
    
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let dreamStore = DreamStore.shared
        
        let sortedDreams = dreamStore.dreams.sorted {
            ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast)
        }.prefix(count)
        
        if sortedDreams.isEmpty {
            return .result(dialog: "还没有记录任何梦境")
        }
        
        let dream = sortedDreams.first!
        let content = dream.content.prefix(100)
        let dateStr = dream.timestamp.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short) } ?? ""
        
        return .result(dialog: "\(dateStr)的梦境：\(content)...")
    }
}

// MARK: - 快捷指令建议提供者
@available(iOS 16.0, *)
public struct DreamShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordDreamIntent(),
            phrases: [
                "记录我的梦境",
                "记一下昨晚的梦",
                "我要记录梦境",
                "打开梦境日记"
            ],
            shortTitle: "记录梦境",
            systemImageName: "moon.stars.fill"
        )
        
        AppShortcut(
            intent: GetDreamStatsIntent(),
            phrases: [
                "我的梦境统计",
                "查看梦境数据",
                "我记录了多少个梦"
            ],
            shortTitle: "梦境统计",
            systemImageName: "chart.bar.fill"
        )
        
        AppShortcut(
            intent: GetRecentDreamIntent(),
            phrases: [
                "我最近做了什么梦",
                "查看最近的梦境",
                "上次记录的梦"
            ],
            shortTitle: "最近梦境",
            systemImageName: "clock.fill"
        )
    }
}

// MARK: - 梦境快捷指令贡献者
@available(iOS 16.0, *)
public struct DreamIntentContributor: IntentContributor {
    public static let contribution: IntentContribution = .init(
        intent: RecordDreamIntent.self,
        phrases: [
            "记录梦境",
            "记梦",
            "写梦境日记"
        ]
    )
}
