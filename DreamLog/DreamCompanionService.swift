//
//  DreamCompanionService.swift
//  DreamLog
//
//  Phase 56 - 梦境 AI 伙伴系统
//  核心服务
//

import Foundation
import SwiftData

import Combine

@MainActor
class DreamCompanionService: ObservableObject {
    
    // MARK: - Properties
    
    @Published private var modelContext: ModelContext?
    @Published private var currentSession: CompanionSession?
    @Published private var conversationHistory: [CompanionMessage] = []
    private let maxHistoryLength = 50
    
    // 对话模板库
    private var templates: [CompanionTemplate] = CompanionTemplate.defaultTemplates
    
    // 符号解释数据库
    private let symbolDatabase: [String: SymbolInterpretation] = SymbolDatabase.shared.interpretations
    
    // 用户偏好
    private var userPreferences: CompanionContext.UserPreferences = .default
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Session Management
    
    /// 创建新对话会话
    func createSession(dreamId: UUID? = nil, topic: String = "梦境探索") async -> CompanionSession {
        let session = CompanionSession(
            title: generateSessionTitle(topic: topic),
            dreamId: dreamId,
            topic: topic
        )
        
        currentSession = session
        conversationHistory = []
        
        // 添加到数据存储
        if let context = modelContext {
            context.insert(session)
            try? context.save()
        }
        
        // 发送欢迎消息
        await sendWelcomeMessage(session: session)
        
        return session
    }
    
    /// 加载现有会话
    func loadSession(sessionId: UUID) async -> CompanionSession? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<CompanionSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            if let session = sessions.first {
                currentSession = session
                conversationHistory = session.messages.sorted { $0.timestamp < $1.timestamp }
                return session
            }
        } catch {
            print("加载会话失败：\(error)")
        }
        
        return nil
    }
    
    /// 获取所有会话
    func getAllSessions() async -> [CompanionSession] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<CompanionSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("获取会话列表失败：\(error)")
            return []
        }
    }
    
    /// 归档会话
    func archiveSession(sessionId: UUID) async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<CompanionSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            if let session = sessions.first {
                session.isArchived = true
                session.updatedAt = Date()
                try context.save()
            }
        } catch {
            print("归档会话失败：\(error)")
        }
    }
    
    /// 删除会话
    func deleteSession(sessionId: UUID) async {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<CompanionSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            for session in sessions {
                context.delete(session)
            }
            try context.save()
        } catch {
            print("删除会话失败：\(error)")
        }
    }
    
    // MARK: - Message Handling
    
    /// 发送用户消息并获取 AI 响应
    func sendMessage(_ content: String, dreamId: UUID? = nil) async -> CompanionResponse {
        guard let session = currentSession else {
            // 自动创建新会话
            _ = await createSession(dreamId: dreamId)
        }
        
        // 添加用户消息
        let userMessage = CompanionMessage(
            sessionId: currentSession!.id,
            messageType: .question,
            content: content,
            dreamId: dreamId,
            isFromUser: true
        )
        
        await addMessage(userMessage)
        
        // 生成 AI 响应
        let response = await generateResponse(userMessage: content, dreamId: dreamId)
        
        // 添加 AI 响应消息
        let aiMessage = CompanionMessage(
            sessionId: currentSession!.id,
            messageType: response.messageType,
            tone: response.tone,
            content: response.message,
            dreamId: dreamId
        )
        
        await addMessage(aiMessage)
        
        // 更新会话
        await updateSession()
        
        return response
    }
    
    /// 添加消息到会话
    private func addMessage(_ message: CompanionMessage) async {
        if let context = modelContext {
            context.insert(message)
            try? context.save()
        }
        
        currentSession?.messages.append(message)
        currentSession?.messageCount += 1
        currentSession?.updatedAt = Date()
        
        conversationHistory.append(message)
        
        // 限制历史记录长度
        if conversationHistory.count > maxHistoryLength {
            conversationHistory.removeFirst()
        }
    }
    
    /// 更新会话信息
    private func updateSession() async {
        guard let session = currentSession else { return }
        
        session.updatedAt = Date()
        session.messageCount = session.messages.count
        
        // 基于对话内容更新标签
        session.tags = extractTagsFromConversation()
        
        // 基于第一条消息更新标题
        if session.messages.count == 2 {  // 欢迎消息 + 第一条用户消息
            if let firstUserMessage = session.messages.first(where: { $0.isFromUser }) {
                session.title = generateTitle(from: firstUserMessage.content)
            }
        }
        
        if let context = modelContext {
            try? context.save()
        }
    }
    
    // MARK: - AI Response Generation
    
    /// 生成 AI 响应
    private func generateResponse(userMessage: String, dreamId: UUID?) async -> CompanionResponse {
        // 分析用户意图
        let intent = analyzeIntent(userMessage)
        
        // 获取梦境上下文（如果有）
        var dreamContext: DreamContext? = nil
        if let dreamId = dreamId {
            dreamContext = await loadDreamContext(dreamId: dreamId)
        }
        
        // 基于意图生成响应
        switch intent {
        case .interpretation:
            return await generateInterpretationResponse(message: userMessage, dream: dreamContext)
        case .exploration:
            return await generateExplorationResponse(message: userMessage, dream: dreamContext)
        case .question:
            return await generateQuestionResponse(message: userMessage, dream: dreamContext)
        case .reflection:
            return await generateReflectionResponse(message: userMessage, dream: dreamContext)
        case .greeting:
            return generateGreetingResponse()
        default:
            return generateDefaultResponse(message: userMessage)
        }
    }
    
    /// 分析用户意图
    private func analyzeIntent(_ message: String) -> UserIntent {
        let lowercased = message.lowercased()
        
        // 解析类意图
        if lowercased.contains("解析") || lowercased.contains("含义") || 
           lowercased.contains("代表") || lowercased.contains("说明") {
            return .interpretation
        }
        
        // 探索类意图
        if lowercased.contains("探索") || lowercased.contains("了解") || 
           lowercased.contains("深入") || lowercased.contains("为什么") {
            return .exploration
        }
        
        // 反思类意图
        if lowercased.contains("反思") || lowercased.contains("学到") || 
           lowercased.contains("启示") || lowercased.contains "应用" {
            return .reflection
        }
        
        // 问候
        if lowercased.contains("你好") || lowercased.contains("hi") || 
           lowercased.contains("hello") || lowercased.contains("早") {
            return .greeting
        }
        
        return .question
    }
    
    /// 生成解析响应
    private func generateInterpretationResponse(message: String, dream: DreamContext?) async -> CompanionResponse {
        var insights: [CompanionResponse.Insight] = []
        var suggestedQuestions: [String] = []
        
        // 提取梦境符号
        let symbols = extractSymbols(from: message)
        
        // 为每个符号生成解释
        for symbol in symbols {
            if let interpretation = symbolDatabase[symbol.lowercased()] {
                insights.append(CompanionResponse.Insight(
                    title: "符号：\(interpretation.symbol)",
                    description: interpretation.meaning,
                    confidence: interpretation.confidence
                ))
            }
        }
        
        // 生成智能解析
        let interpretation = await generateAIInterpretation(message: message, dream: dream)
        
        // 生成追问
        suggestedQuestions = [
            "这个解析让你有什么感受？",
            "梦中还有其他印象深刻的元素吗？",
            "最近生活中有什么相关的事情发生吗？"
        ]
        
        return CompanionResponse(
            message: interpretation,
            messageType: .interpretation,
            tone: .thoughtful,
            suggestedQuestions: suggestedQuestions,
            relatedDreams: await findRelatedDreams(message: message),
            insights: insights,
            actions: [.init(actionType: .viewDream, title: "查看相关梦境", icon: "📖")]
        )
    }
    
    /// 生成探索响应
    private func generateExplorationResponse(message: String, dream: DreamContext?) async -> CompanionResponse {
        var questions: [String] = []
        
        // 生成探索性问题
        questions = [
            "能详细描述一下梦中的场景吗？",
            "当时你有什么感觉？",
            "这个场景让你联想到什么？",
            "如果梦境有颜色，会是什么颜色？"
        ]
        
        return CompanionResponse(
            message: generateExplorationMessage(message: message, dream: dream),
            messageType: .question,
            tone: .curious,
            suggestedQuestions: questions,
            relatedDreams: [],
            insights: [],
            actions: []
        )
    }
    
    /// 生成问题响应
    private func generateQuestionResponse(message: String, dream: DreamContext?) async -> CompanionResponse {
        return CompanionResponse(
            message: generateAnswer(message: message, dream: dream),
            messageType: .insight,
            tone: .supportive,
            suggestedQuestions: ["还有其他想了解的吗？"],
            relatedDreams: [],
            insights: [],
            actions: []
        )
    }
    
    /// 生成反思响应
    private func generateReflectionResponse(message: String, dream: DreamContext?) async -> CompanionResponse {
        let reflection = generateReflectionGuidance(message: message, dream: dream)
        
        return CompanionResponse(
            message: reflection,
            messageType: .reflection,
            tone: .warm,
            suggestedQuestions: [
                "这个反思对你有帮助吗？",
                "你想把这个洞察记录下来吗？"
            ],
            relatedDreams: [],
            insights: [.init(
                title: "个人洞察",
                description: extractPersonalInsight(message: message),
                confidence: 0.8
            )],
            actions: [.init(actionType: .setGoal, title: "设定相关目标", icon: "🎯")]
        )
    }
    
    /// 生成问候响应
    private func generateGreetingResponse() -> CompanionResponse {
        let hour = Calendar.current.component(.hour, from: Date())
        var greeting: String
        
        if hour < 6 {
            greeting = "夜深了，还在思考梦境吗？🌙"
        } else if hour < 12 {
            greeting = "早上好！昨晚做了什么有趣的梦吗？☀️"
        } else if hour < 18 {
            greeting = "下午好！今天有什么想探索的梦境吗？🌤️"
        } else {
            greeting = "晚上好！准备好记录今天的梦境了吗？🌙"
        }
        
        return CompanionResponse(
            message: greeting + "\n\n我是你的梦境 AI 伙伴，随时帮你解析和探索梦境的奥秘。你可以：\n• 分享一个梦境让我解析\n• 询问梦境符号的含义\n• 探索梦境与现实的联系\n• 或者随便聊聊你的梦",
            messageType: .greeting,
            tone: .warm,
            suggestedQuestions: QuickQuestion.defaultQuestions.map { $0.question },
            relatedDreams: [],
            insights: [],
            actions: []
        )
    }
    
    /// 生成默认响应
    private func generateDefaultResponse(message: String) -> CompanionResponse {
        return CompanionResponse(
            message: "我理解你想了解关于梦境的事情。能告诉我更多细节吗？比如：\n• 梦境的具体内容\n• 梦中的情绪感受\n• 特别印象深刻的场景或符号",
            messageType: .followup,
            tone: .supportive,
            suggestedQuestions: [
                "想分享一个具体的梦境吗？",
                "对某个梦境符号好奇？",
                "想了解梦境的模式？"
            ],
            relatedDreams: [],
            insights: [],
            actions: []
        )
    }
    
    // MARK: - Helper Methods
    
    /// 发送欢迎消息
    private func sendWelcomeMessage(session: CompanionSession) async {
        let welcomeMessage = CompanionMessage(
            sessionId: session.id,
            messageType: .greeting,
            tone: .warm,
            content: """
            你好！我是你的梦境 AI 伙伴 🌙
            
            我在这里帮你：
            ✨ 解析梦境的深层含义
            💭 探索梦境与现实的联系
            🎯 发现重复出现的梦境模式
            💡 从梦境中获取创意和启示
            
            分享一个你的梦境，让我们开始探索吧！
            """
        )
        
        await addMessage(welcomeMessage)
    }
    
    /// 生成会话标题
    private func generateSessionTitle(topic: String) -> String {
        let prefixes = ["梦境探索", "梦境解析", "梦境对话", "梦境洞察", "梦境反思"]
        let randomPrefix = prefixes.randomElement() ?? "梦境对话"
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        return "\(randomPrefix) · \(dateStr)"
    }
    
    /// 从内容生成标题
    private func generateTitle(from content: String) -> String {
        let words = content.split(separator: " ")
        let titleWords = words.prefix(5)
        return String(titleWords.joined(separator: " ")) + (words.count > 5 ? "..." : "")
    }
    
    /// 提取对话标签
    private func extractTagsFromConversation() -> [String] {
        // 基于对话内容提取关键词作为标签
        return []
    }
    
    /// 提取梦境符号
    private func extractSymbols(from message: String) -> [String] {
        // 简单的符号提取逻辑
        let commonSymbols = ["水", "火", "飞", "掉落", "追逐", "牙齿", "蛇", "猫", "狗", "房子", "路", "桥", "门", "楼梯"]
        var found: [String] = []
        
        for symbol in commonSymbols {
            if message.contains(symbol) {
                found.append(symbol)
            }
        }
        
        return found
    }
    
    /// 生成 AI 解析
    private func generateAIInterpretation(message: String, dream: DreamContext?) async -> String {
        // 这里会集成实际的 AI 模型
        // 目前使用模板响应
        return """
        从心理学角度来看，这个梦境可能反映了：
        
        🧠 **潜意识信息**
        梦境往往是我们潜意识的表达。你描述的内容可能象征着内心深处的某些想法或情感。
        
        💭 **情绪映射**
        梦中的情绪通常与清醒时的心理状态相关。留意你在梦中的感受，它们可能是理解梦境的关键。
        
        🔗 **现实联系**
        思考一下最近生活中发生的事情，梦境常常以象征性的方式处理日常经历。
        
        想更深入地探索某个特定方面吗？
        """
    }
    
    /// 生成探索消息
    private func generateExplorationMessage(message: String, dream: DreamContext?) -> String {
        return """
        很好的问题！让我们一起深入探索这个梦境。
        
        梦境的每一个细节都可能是重要的线索。我想邀请你：
        
        🎨 **描绘场景**
        试着回忆梦中的环境、颜色、光线和氛围。
        
        💓 **关注感受**
        你在梦中经历了哪些情绪？这些情绪在醒来后是否还在？
        
        🔍 **寻找关联**
        梦中的元素是否让你联想到生活中的某些人或事？
        
        慢慢来，不用着急。想到什么都可以告诉我。
        """
    }
    
    /// 生成答案
    private func generateAnswer(message: String, dream: DreamContext?) -> String {
        return """
        这是个好问题！
        
        关于你提到的内容，从梦境研究的角度来看：
        
        📚 **研究视角**
        梦境是大脑在睡眠中处理信息和情感的方式。每个梦都有其独特的意义。
        
        💡 **个人意义**
        最重要的是这个梦对**你**意味着什么。你的直觉和感受是最有价值的指引。
        
        🌱 **成长机会**
        每个梦境都是一次自我了解的机会。保持开放和好奇的心态去探索。
        
        还有其他想了解的吗？
        """
    }
    
    /// 生成反思指导
    private func generateReflectionGuidance(message: String, dream: DreamContext?) -> String {
        return """
        很高兴你能进行这样的反思！🪞
        
        梦境反思是自我成长的重要途径。让我引导你：
        
        📝 **记录洞察**
        把此刻的想法记录下来，即使它们看起来不完整。
        
        🎯 **寻找行动点**
        这个梦境是否提示你需要关注生活中的某个方面？
        
        🌟 **整合智慧**
        如何将梦境带来的启示应用到日常生活中？
        
        记住，梦境的智慧需要时间去整合。不用急于得出结论。
        """
    }
    
    /// 提取个人洞察
    private func extractPersonalInsight(message: String) -> String {
        return "从你的反思中，可以看出你正在积极地探索内心世界，这是非常宝贵的自我成长过程。"
    }
    
    /// 查找相关梦境
    private func findRelatedDreams(message: String) async -> [UUID] {
        // 基于内容相似度查找相关梦境
        return []
    }
    
    /// 加载梦境上下文
    private func loadDreamContext(dreamId: UUID) async -> DreamContext? {
        guard let context = modelContext else { return nil }
        
        // 这里需要 Dream 模型的定义
        // 简化处理，返回 nil
        return nil
    }
}

// MARK: - Supporting Types

enum UserIntent {
    case interpretation
    case exploration
    case question
    case reflection
    case greeting
}

struct DreamContext {
    var id: UUID
    var content: String
    var emotions: [String]
    var tags: [String]
    var date: Date
}

// MARK: - Additional Service Methods

extension DreamCompanionService {
    
    /// 批量删除会话
    func deleteSessions(sessionIds: [UUID]) async {
        guard let context = modelContext else { return }
        
        for sessionId in sessionIds {
            let descriptor = FetchDescriptor<CompanionSession>(
                predicate: #Predicate { $0.id == sessionId }
            )
            
            do {
                let sessions = try context.fetch(descriptor)
                for session in sessions {
                    context.delete(session)
                }
            } catch {
                print("删除会话失败：\(sessionId), 错误：\(error)")
            }
        }
        
        try? context.save()
    }
    
    /// 获取对话统计
    func getStats() async -> CompanionStats {
        guard let context = modelContext else {
            return CompanionStats(
                totalSessions: 0,
                totalMessages: 0,
                averageSessionLength: 0,
                mostCommonTopics: [],
                insightsGenerated: 0,
                userSatisfactionScore: nil,
                weeklyTrend: []
            )
        }
        
        do {
            let descriptor = FetchDescriptor<CompanionSession>()
            let sessions = try context.fetch(descriptor)
            
            let totalSessions = sessions.count
            let totalMessages = sessions.reduce(0) { $0 + $1.messageCount }
            let averageSessionLength = totalSessions > 0 ? Double(totalMessages) / Double(totalSessions) : 0
            
            // 统计话题
            let topicCounts = Dictionary(grouping: sessions) { $0.topic }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            let mostCommonTopics = topicCounts.prefix(5).map { $0.key }
            
            // 统计洞察数量（消息类型为 insight 的数量）
            let insightsGenerated = sessions.reduce(0) { total, session in
                total + session.messages.filter { $0.messageType == .insight }.count
            }
            
            // 计算周趋势
            let calendar = Calendar.current
            let now = Date()
            var weeklyTrend: [CompanionStats.WeeklyStat] = []
            
            for weekOffset in 0..<4 {
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
                let weekEnd = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? now
                
                let sessionsInWeek = sessions.filter { session in
                    session.createdAt >= weekStart && session.createdAt < weekEnd
                }
                
                let messagesInWeek = sessionsInWeek.reduce(0) { $0 + $1.messageCount }
                let avgDuration = sessionsInWeek.isEmpty ? 0 : Double(messagesInWeek) / Double(sessionsInWeek.count)
                
                weeklyTrend.append(CompanionStats.WeeklyStat(
                    weekStart: weekStart,
                    sessionsCount: sessionsInWeek.count,
                    messagesCount: messagesInWeek,
                    averageDuration: avgDuration
                ))
            }
            
            return CompanionStats(
                totalSessions: totalSessions,
                totalMessages: totalMessages,
                averageSessionLength: averageSessionLength,
                mostCommonTopics: mostCommonTopics,
                insightsGenerated: insightsGenerated,
                userSatisfactionScore: nil,  // 需要用户反馈
                weeklyTrend: weeklyTrend.reversed()
            )
        } catch {
            print("获取统计失败：\(error)")
            return CompanionStats(
                totalSessions: 0,
                totalMessages: 0,
                averageSessionLength: 0,
                mostCommonTopics: [],
                insightsGenerated: 0,
                userSatisfactionScore: nil,
                weeklyTrend: []
            )
        }
    }
    
    /// 导出对话为文本
    func exportConversation(sessionId: UUID) async -> String {
        guard let context = modelContext else { return "" }
        
        let descriptor = FetchDescriptor<CompanionSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            guard let session = sessions.first else { return "" }
            
            let messages = session.messages.sorted { $0.timestamp < $1.timestamp }
            
            var exportText = """
            # DreamLog AI 伙伴对话导出
            主题：\(session.topic)
            创建时间：\(formatDate(session.createdAt))
            导出时间：\(formatDate(Date()))
            
            ---
            
            """
            
            for message in messages {
                let sender = message.isFromUser ? "我" : "AI 伙伴"
                let time = formatTime(message.timestamp)
                exportText += """
                [\(time)] \(sender):
                \(message.content)
                
                """
            }
            
            exportText += """
            
            ---
            共 \(messages.count) 条消息
            """
            
            return exportText
        } catch {
            print("导出对话失败：\(error)")
            return ""
        }
    }
    
    /// 分享对话（生成分享文本）
    func shareConversation(sessionId: UUID) async -> String {
        guard let context = modelContext else { return "" }
        
        let descriptor = FetchDescriptor<CompanionSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            guard let session = sessions.first else { return "" }
            
            let messages = session.messages.sorted { $0.timestamp < $1.timestamp }
            
            // 只分享 AI 的洞察和建议
            let insights = messages.filter { !$0.isFromUser && ($0.messageType == .insight || $0.messageType == .suggestion) }
            
            var shareText = """
            🌙 DreamLog AI 伙伴 · \(session.topic)
            
            """
            
            if !insights.isEmpty {
                shareText += "💡 本次对话的洞察：\n\n"
                for insight in insights.prefix(3) {
                    shareText += "• \(insight.content)\n\n"
                }
            } else {
                shareText += "一次有意义的梦境探索之旅 ✨\n\n"
            }
            
            shareText += """
            
            共 \(session.messageCount) 条消息
            通过 DreamLog AI 伙伴生成
            """
            
            return shareText
        } catch {
            print("分享对话失败：\(error)")
            return ""
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Symbol Database

struct SymbolInterpretation {
    var symbol: String
    var meaning: String
    var categories: [String]
    var confidence: Double
}

class SymbolDatabase {
    static let shared = SymbolDatabase()
    
    let interpretations: [String: SymbolInterpretation] = [
        "水": SymbolInterpretation(
            symbol: "水",
            meaning: "水通常象征情感、潜意识和生命力。平静的水面代表内心平和，湍急的水流可能表示情绪波动。",
            categories: ["情感", "潜意识"],
            confidence: 0.85
        ),
        "火": SymbolInterpretation(
            symbol: "火",
            meaning: "火象征激情、转化和净化。可能代表强烈的欲望、创造力，或需要释放的情绪。",
            categories: ["激情", "转化"],
            confidence: 0.82
        ),
        "飞": SymbolInterpretation(
            symbol: "飞",
            meaning: "飞翔通常象征自由、超越限制或逃避现实。轻松的飞行表示自信，困难的飞行可能反映现实压力。",
            categories: ["自由", "超越"],
            confidence: 0.88
        ),
        "掉落": SymbolInterpretation(
            symbol: "掉落",
            meaning: "掉落梦境常与失控感、不安全感或对失败的恐惧相关。也可能表示需要放下某些东西。",
            categories: ["恐惧", "失控"],
            confidence: 0.80
        ),
        "追逐": SymbolInterpretation(
            symbol: "追逐",
            meaning: "被追逐通常表示逃避某个问题或情绪。追逐者可能代表你回避的某种责任或感受。",
            categories: ["逃避", "压力"],
            confidence: 0.83
        ),
        "牙齿": SymbolInterpretation(
            symbol: "牙齿",
            meaning: "牙齿梦境常与沟通、自信心或外貌焦虑相关。掉牙可能表示对失去控制力的担忧。",
            categories: ["沟通", "自信"],
            confidence: 0.75
        ),
        "蛇": SymbolInterpretation(
            symbol: "蛇",
            meaning: "蛇是复杂的象征，可能代表智慧、转化、恐惧或性能量。具体含义取决于梦中的情境和感受。",
            categories: ["转化", "智慧", "恐惧"],
            confidence: 0.78
        )
    ]
}

// MARK: - User Preferences Default

extension CompanionContext.UserPreferences {
    static let `default` = CompanionContext.UserPreferences(
        interpretationStyle: "psychological",
        detailLevel: "detailed",
        focusAreas: ["emotions", "symbols", "patterns"]
    )
}
