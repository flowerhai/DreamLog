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
        // 保存梦境到存储 (通过 AppDelegate 或 SceneDelegate 获取 dreamStore)
        // 注意：实际使用时需要通过适当的方式获取 DreamStore 实例
        let dream = Dream(
            title: "梦境记录",
            content: content.isEmpty ? "刚刚做的梦" : content,
            originalText: content,
            tags: tags,
            emotions: emotions.compactMap { Emotion(rawValue: $0) },
            clarity: 3,
            intensity: 3
        )
        
        // 实际应用中需要通过合适的方式获取 dreamStore
        // 这里仅作示例
        print("📝 记录梦境：\(dream.title)")
        
        return .result(
            dialog: "梦境已记录"
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
        // 实际应用中需要通过合适的方式获取 dreamStore
        // 这里仅作示例
        let dialog = "梦境统计功能需要应用支持"
        
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
        // 实际应用中需要通过合适的方式获取 dreamStore
        // 这里仅作示例
        let dialog = "搜索功能需要应用支持：\"\(keyword)\""
        
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
        // 实际应用中需要通过合适的方式获取 dreamStore
        // 这里仅作示例
        let dialog = "最近梦境功能需要应用支持"
        
        return .result(dialog: dialog)
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
