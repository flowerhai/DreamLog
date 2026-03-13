//
//  DreamSiriShortcuts.swift
//  DreamLog
//
//  Siri 快捷指令集成
//  Phase 32 - Apple Watch 增强与多端协同
//

import Foundation
import Intents
import os.log

// MARK: - Siri 快捷指令服务

@MainActor
class DreamSiriShortcuts: ObservableObject {
    static let shared = DreamSiriShortcuts()
    
    private let logger = Logger(subsystem: "com.dreamlog.app", category: "SiriShortcuts")
    
    @Published var isListening: Bool = false
    @Published var lastVoiceCommand: String?
    @Published var shortcutSuggestions: [DreamShortcut] = []
    
    // MARK: - 快捷指令定义
    
    struct DreamShortcut: Identifiable, Hashable {
        let id: UUID
        let title: String
        let subtitle: String
        let iconName: String
        let intentType: ShortcutIntentType
        var isPopular: Bool = false
        
        enum ShortcutIntentType {
            case recordDream
            case viewDreams
            case viewStats
            case analyzeDream
            case setReminder
        }
    }
    
    // MARK: - 初始化
    
    init() {
        generateSuggestions()
    }
    
    // MARK: - 快捷指令建议
    
    func generateSuggestions() {
        let dreamStore = DreamStore.shared
        
        var suggestions: [DreamShortcut] = []
        
        // 基于时间的建议
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour <= 10 {
            suggestions.append(DreamShortcut(
                id: UUID(),
                title: "记录晨间梦境",
                subtitle: "趁记忆还清晰",
                iconName: "sunrise.fill",
                intentType: .recordDream,
                isPopular: true
            ))
        }
        
        if hour >= 20 || hour <= 5 {
            suggestions.append(DreamShortcut(
                id: UUID(),
                title: "准备记录梦境",
                subtitle: "放在枕边",
                iconName: "moon.fill",
                intentType: .setReminder
            ))
        }
        
        // 基于使用习惯的建议
        if dreamStore.dreamsThisWeek > 0 {
            suggestions.append(DreamShortcut(
                id: UUID(),
                title: "查看本周统计",
                subtitle: "\(dreamStore.dreamsThisWeek) 个梦境",
                iconName: "chart.bar.fill",
                intentType: .viewStats
            ))
        }
        
        // 热门快捷指令
        suggestions.append(DreamShortcut(
            id: UUID(),
            title: "快速记录",
            subtitle: "语音输入梦境",
            iconName: "mic.fill",
            intentType: .recordDream,
            isPopular: true
        ))
        
        suggestions.append(DreamShortcut(
            id: UUID(),
            title: "浏览梦境",
            subtitle: "查看所有记录",
            iconName: "book.fill",
            intentType: .viewDreams
        ))
        
        if !dreamStore.dreams.isEmpty {
            suggestions.append(DreamShortcut(
                id: UUID(),
                title: "AI 解梦",
                subtitle: "分析最近的梦",
                iconName: "sparkles",
                intentType: .analyzeDream
            ))
        }
        
        shortcutSuggestions = suggestions
        logger.info("生成了 \(suggestions.count) 个快捷指令建议")
    }
    
    // MARK: - 语音命令处理
    
    func handleVoiceCommand(_ command: String) async -> SiriCommandResult {
        lastVoiceCommand = command
        let lowercased = command.lowercased()
        
        // 记录梦境
        if lowercased.contains("记录") && lowercased.contains("梦境") ||
           lowercased.contains("记一下") && (lowercased.contains("梦") || lowercased.contains("昨晚")) {
            return await handleRecordDream()
        }
        
        // 查看梦境
        if lowercased.contains("查看") && lowercased.contains("梦境") ||
           lowercased.contains("我的梦") || lowercased.contains("昨天的梦") {
            return await handleViewDreams()
        }
        
        // 查看统计
        if lowercased.contains("统计") || lowercased.contains("有多少梦") {
            return await handleViewStats()
        }
        
        // AI 解梦
        if lowercased.contains("解梦") || lowercased.contains("分析") && lowercased.contains("梦") {
            return await handleAnalyzeDream()
        }
        
        // 设置提醒
        if lowercased.contains("提醒") && lowercased.contains("梦") {
            return await handleSetReminder()
        }
        
        // 默认响应
        return SiriCommandResult(
            success: false,
            title: "没听清楚",
            message: "你可以说'记录梦境'、'查看统计'或'解梦'",
            action: .none
        )
    }
    
    // MARK: - 命令处理器
    
    private func handleRecordDream() async -> SiriCommandResult {
        logger.info("处理记录梦境命令")
        
        return SiriCommandResult(
            success: true,
            title: "准备记录",
            message: "请开始讲述你的梦境",
            action: .openToRecord
        )
    }
    
    private func handleViewDreams() async -> SiriCommandResult {
        let dreamStore = DreamStore.shared
        let recentCount = min(5, dreamStore.dreams.count)
        
        return SiriCommandResult(
            success: true,
            title: "最近梦境",
            message: "你有 \(dreamStore.dreams.count) 个梦境记录，最近的是\(recentCount)个",
            action: .openToDreams
        )
    }
    
    private func handleViewStats() async -> SiriCommandResult {
        let dreamStore = DreamStore.shared
        
        var stats = "你总共记录了 \(dreamStore.dreams.count) 个梦境"
        
        if dreamStore.dreamsThisWeek > 0 {
            stats += "，本周 \(dreamStore.dreamsThisWeek) 个"
        }
        
        if dreamStore.lucidDreamCount > 0 {
            stats += "，其中 \(dreamStore.lucidDreamCount) 个清醒梦"
        }
        
        return SiriCommandResult(
            success: true,
            title: "梦境统计",
            message: stats,
            action: .openToStats
        )
    }
    
    private func handleAnalyzeDream() async -> SiriCommandResult {
        let dreamStore = DreamStore.shared
        
        guard let recentDream = dreamStore.dreams.first else {
            return SiriCommandResult(
                success: false,
                title: "暂无梦境",
                message: "先记录一些梦境吧",
                action: .openToRecord
            )
        }
        
        return SiriCommandResult(
            success: true,
            title: "AI 解梦",
            message: "正在分析\"\(recentDream.title)\"...",
            action: .analyzeDream(recentDream.id)
        )
    }
    
    private func handleSetReminder() async -> SiriCommandResult {
        return SiriCommandResult(
            success: true,
            title: "设置提醒",
            message: "已设置每天早上 7 点提醒你记录梦境",
            action: .setReminder
        )
    }
}

// MARK: - Siri 命令结果

struct SiriCommandResult {
    let success: Bool
    let title: String
    let message: String
    let action: SiriAction
    
    enum SiriAction {
        case none
        case openToRecord
        case openToDreams
        case openToStats
        case analyzeDream(UUID)
        case setReminder
    }
}

// MARK: - INIntent 扩展 (Intent 定义)

// 记录梦境 Intent
@available(iOS 15.0, watchOS 8.0, *)
class RecordDreamIntent: INIntent {
    @NSManaged var dreamContent: INSpeakableString?
    @NSManaged var tags: [String]?
    @NSManaged var emotions: [String]?
}

// 查看梦境 Intent
@available(iOS 15.0, watchOS 8.0, *)
class ViewDreamsIntent: INIntent {
    @NSManaged var dateRange: String?
    @NSManaged var tagFilter: String?
    @NSManaged var emotionFilter: String?
}

// 查看统计 Intent
@available(iOS 15.0, watchOS 8.0, *)
class ViewStatsIntent: INIntent {
    @NSManaged var period: String? // "week", "month", "year", "all"
}

// 解梦 Intent
@available(iOS 15.0, watchOS 8.0, *)
class AnalyzeDreamIntent: INIntent {
    @NSManaged var dreamId: String?
}

// MARK: - Intent Handler

@available(iOS 15.0, watchOS 8.0, *)
class DreamIntentHandler: NSObject, RecordDreamIntentHandling, ViewDreamsIntentHandling, ViewStatsIntentHandling, AnalyzeDreamIntentHandling {
    
    private let dreamStore = DreamStore.shared
    private let logger = Logger(subsystem: "com.dreamlog.app", category: "IntentHandler")
    
    // MARK: - RecordDreamIntentHandling
    
    func handle(intent: RecordDreamIntent, completion: @escaping (RecordDreamIntentResponse) -> Void) {
        Task { @MainActor in
            guard let content = intent.dreamContent?.spokenPhrase else {
                let response = RecordDreamIntentResponse(code: .failure, userActivity: nil)
                response.failureReason = "未提供梦境内容"
                completion(response)
                return
            }
            
            let dream = Dream(
                title: String(content.prefix(30)),
                content: content,
                tags: intent.tags ?? [],
                emotions: (intent.emotions ?? []).compactMap { DreamEmotion(rawValue: $0) },
                clarity: 3,
                intensity: 3,
                isLucid: false
            )
            
            dreamStore.addDream(dream)
            
            let response = RecordDreamIntentResponse(code: .success, userActivity: nil)
            response.successMessage = "梦境已保存"
            completion(response)
            
            logger.info("通过 Siri 记录了梦境：\(dream.title)")
        }
    }
    
    // MARK: - ViewDreamsIntentHandling
    
    func handle(intent: ViewDreamsIntent, completion: @escaping (ViewDreamsIntentResponse) -> Void) {
        Task { @MainActor in
            let dreams = dreamStore.dreams
            
            if dreams.isEmpty {
                let response = ViewDreamsIntentResponse(code: .failure, userActivity: nil)
                response.failureReason = "暂无梦境记录"
                completion(response)
                return
            }
            
            let response = ViewDreamsIntentResponse(code: .success, userActivity: nil)
            response.dreamCount = Int32(dreams.count)
            response.successMessage = "你有 \(dreams.count) 个梦境"
            completion(response)
        }
    }
    
    // MARK: - ViewStatsIntentHandling
    
    func handle(intent: ViewStatsIntent, completion: @escaping (ViewStatsIntentResponse) -> Void) {
        Task { @MainActor in
            let dreamStore = DreamStore.shared
            
            let response = ViewStatsIntentResponse(code: .success, userActivity: nil)
            response.totalDreams = Int32(dreamStore.dreams.count)
            response.thisWeek = Int32(dreamStore.dreamsThisWeek)
            response.lucidDreams = Int32(dreamStore.lucidDreamCount)
            response.successMessage = "统计信息已准备"
            completion(response)
        }
    }
    
    // MARK: - AnalyzeDreamIntentHandling
    
    func handle(intent: AnalyzeDreamIntent, completion: @escaping (AnalyzeDreamIntentResponse) -> Void) {
        Task { @MainActor in
            guard let dreamIdString = intent.dreamId,
                  let dreamId = UUID(uuidString: dreamIdString),
                  let dream = dreamStore.dreams.first(where: { $0.id == dreamId }) else {
                let response = AnalyzeDreamIntentResponse(code: .failure, userActivity: nil)
                response.failureReason = "未找到指定梦境"
                completion(response)
                return
            }
            
            let response = AnalyzeDreamIntentResponse(code: .success, userActivity: nil)
            response.dreamTitle = dream.title
            response.successMessage = "正在分析梦境..."
            completion(response)
        }
    }
}

// MARK: - 快捷指令贡献

extension DreamSiriShortcuts {
    /// 向 Siri 贡献快捷指令
    func donateShortcut(_ shortcut: DreamShortcut) {
        #if canImport(Intents)
        let interaction = INInteraction(intent: createIntent(for: shortcut), response: nil)
        interaction.groupIdentifier = "DreamLogShortcuts"
        
        interaction.donate { error in
            if let error = error {
                self.logger.error("贡献快捷指令失败：\(error.localizedDescription)")
            } else {
                self.logger.info("快捷指令已贡献：\(shortcut.title)")
            }
        }
        #endif
    }
    
    private func createIntent(for shortcut: DreamShortcut) -> INIntent {
        switch shortcut.intentType {
        case .recordDream:
            let intent = RecordDreamIntent()
            intent.spokenPhrase = "记录梦境"
            return intent
            
        case .viewDreams:
            let intent = ViewDreamsIntent()
            intent.spokenPhrase = "查看梦境"
            return intent
            
        case .viewStats:
            let intent = ViewStatsIntent()
            intent.spokenPhrase = "查看统计"
            return intent
            
        case .analyzeDream:
            let intent = AnalyzeDreamIntent()
            intent.spokenPhrase = "解梦"
            return intent
            
        case .setReminder:
            let intent = RecordDreamIntent()
            intent.spokenPhrase = "设置梦境提醒"
            return intent
        }
    }
}
