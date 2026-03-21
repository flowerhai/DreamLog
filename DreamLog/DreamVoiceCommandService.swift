//
//  DreamVoiceCommandService.swift
//  DreamLog - 梦境语音命令核心服务
//  Phase 84: 梦境语音命令系统
//
//  Created by DreamLog Team on 2026/3/21.
//

import Foundation
import Speech
import AVFoundation
import SwiftData

@MainActor
class DreamVoiceCommandService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isListening: Bool = false
    @Published var isProcessing: Bool = false
    @Published var recognizedText: String = ""
    @Published var currentCommand: VoiceCommandType?
    @Published var lastResult: VoiceCommandResult?
    @Published var commandHistory: [VoiceCommandHistory] = []
    @Published var config: VoiceCommandConfig = .default
    
    // MARK: - Private Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var commandTriggers: [VoiceTrigger] = []
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        setupTriggers()
        loadConfig()
        loadHistory()
    }
    
    // MARK: - Setup
    
    /// 设置命令触发词
    private func setupTriggers() {
        commandTriggers = [
            VoiceTrigger(commandType: .recordDream, triggers: ["记录梦境", "记梦", "写梦", "我要记梦", "记录一个梦"]),
            VoiceTrigger(commandType: .quickNote, triggers: ["快速备注", "记一下", "备注", "添加笔记"]),
            VoiceTrigger(commandType: .searchDream, triggers: ["搜索", "查找", "找一下", "查询"]),
            VoiceTrigger(commandType: .showStats, triggers: ["统计", "数据", "我的统计", "查看统计"]),
            VoiceTrigger(commandType: .showRecent, triggers: ["最近", "最近的梦", "最新梦境", "上一条"]),
            VoiceTrigger(commandType: .showCalendar, triggers: ["日历", "月历", "梦境日历"]),
            VoiceTrigger(commandType: .showInsights, triggers: ["洞察", "分析", "智能洞察"]),
            VoiceTrigger(commandType: .showTrends, triggers: ["趋势", "走向", "变化趋势"]),
            VoiceTrigger(commandType: .showPatterns, triggers: ["模式", "规律", "梦境模式"]),
            VoiceTrigger(commandType: .startMeditation, triggers: ["冥想", "放松", "开始冥想"]),
            VoiceTrigger(commandType: .playMusic, triggers: ["音乐", "播放音乐", "放首歌"]),
            VoiceTrigger(commandType: .showGallery, triggers: ["画廊", "美术馆", "我的画作"]),
            VoiceTrigger(commandType: .exportData, triggers: ["导出", "备份", "导出数据"]),
            VoiceTrigger(commandType: .openSettings, triggers: ["设置", "配置", "选项"]),
            VoiceTrigger(commandType: .setReminder, triggers: ["提醒", "闹钟", "设置提醒"]),
            VoiceTrigger(commandType: .help, triggers: ["帮助", "怎么办", "求助"]),
            VoiceTrigger(commandType: .whatCanIDo, triggers: ["你能做什么", "功能", "命令", "支持什么"])
        ]
    }
    
    /// 加载配置
    private func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "VoiceCommandConfig"),
           let decoded = try? JSONDecoder().decode(VoiceCommandConfig.self, from: data) {
            config = decoded
        }
    }
    
    /// 保存配置
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "VoiceCommandConfig")
        }
    }
    
    /// 加载历史记录
    private func loadHistory() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<VoiceCommandHistory>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            commandHistory = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load voice command history: \(error)")
        }
    }
    
    // MARK: - Speech Recognition
    
    /// 检查语音识别权限
    func checkAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    /// 开始监听
    func startListening() async throws {
        guard !isListening else { return }
        
        let authorized = await checkAuthorization()
        guard authorized else {
            throw VoiceCommandError.notAuthorized
        }
        
        guard let speechRecognizer = speechRecognizer else {
            throw VoiceCommandError.recognizerNotAvailable
        }
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceCommandError.requestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 创建识别任务
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            Task { @MainActor in
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    self.checkForCommand(self.recognizedText)
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        }
        
        // 配置音频引擎
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
        recognizedText = ""
        
        // 触觉反馈
        if config.hapticFeedback {
            triggerHapticFeedback()
        }
    }
    
    /// 停止监听
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isListening = false
        isProcessing = false
    }
    
    // MARK: - Command Detection
    
    /// 检查文本是否包含命令
    private func checkForCommand(_ text: String) {
        for trigger in commandTriggers where trigger.isEnabled && trigger.matches(text) {
            executeCommand(trigger.commandType, recognizedText: text)
            break
        }
    }
    
    // MARK: - Command Execution
    
    /// 执行语音命令
    func executeCommand(_ type: VoiceCommandType, recognizedText: String) {
        guard config.isEnabled else {
            lastResult = VoiceCommandResult(
                commandType: type,
                recognizedText: recognizedText,
                confidence: 1.0,
                success: false,
                message: "语音命令已禁用"
            )
            return
        }
        
        currentCommand = type
        isProcessing = true
        
        let startTime = Date()
        
        Task {
            do {
                let result = try await executeCommandInternal(type, recognizedText: recognizedText)
                
                let responseTime = Date().timeIntervalSince(startTime)
                
                // 保存历史记录
                saveToHistory(
                    commandType: type.rawValue,
                    recognizedText: recognizedText,
                    confidence: result.confidence,
                    success: result.success,
                    message: result.message,
                    responseTime: responseTime
                )
                
                lastResult = result
                
                // 语音反馈
                if config.voiceFeedback && result.success {
                    await speakFeedback(result.message)
                }
                
                // 触觉反馈
                if config.hapticFeedback {
                    triggerHapticFeedback()
                }
                
            } catch {
                let responseTime = Date().timeIntervalSince(startTime)
                
                let failedResult = VoiceCommandResult(
                    commandType: type,
                    recognizedText: recognizedText,
                    confidence: 0.0,
                    success: false,
                    message: "执行失败：\(error.localizedDescription)"
                )
                
                saveToHistory(
                    commandType: type.rawValue,
                    recognizedText: recognizedText,
                    confidence: 0.0,
                    success: false,
                    message: error.localizedDescription,
                    responseTime: responseTime
                )
                
                lastResult = failedResult
            }
            
            isProcessing = false
        }
    }
    
    /// 执行命令内部实现
    private func executeCommandInternal(_ type: VoiceCommandType, recognizedText: String) async throws -> VoiceCommandResult {
        switch type {
        case .recordDream:
            return try await handleRecordDream(recognizedText: recognizedText)
        case .quickNote:
            return try await handleQuickNote(recognizedText: recognizedText)
        case .searchDream:
            return try await handleSearchDream(recognizedText: recognizedText)
        case .showStats:
            return try await handleShowStats()
        case .showRecent:
            return try await handleShowRecent()
        case .showCalendar:
            return try await handleShowCalendar()
        case .showInsights:
            return try await handleShowInsights()
        case .showTrends:
            return try await handleShowTrends()
        case .showPatterns:
            return try await handleShowPatterns()
        case .startMeditation:
            return try await handleStartMeditation()
        case .playMusic:
            return try await handlePlayMusic()
        case .showGallery:
            return try await handleShowGallery()
        case .exportData:
            return try await handleExportData()
        case .openSettings:
            return try await handleOpenSettings()
        case .setReminder:
            return try await handleSetReminder()
        case .help:
            return try await handleHelp()
        case .whatCanIDo:
            return try await handleWhatCanIDo()
        }
    }
    
    // MARK: - Command Handlers
    
    private func handleRecordDream(recognizedText: String) async throws -> VoiceCommandResult {
        // 这里应该导航到记录页面
        return VoiceCommandResult(
            commandType: .recordDream,
            recognizedText: recognizedText,
            confidence: 0.9,
            success: true,
            message: "已打开梦境记录页面，请开始讲述您的梦境"
        )
    }
    
    private func handleQuickNote(recognizedText: String) async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .quickNote,
            recognizedText: recognizedText,
            confidence: 0.85,
            success: true,
            message: "已打开快速备注"
        )
    }
    
    private func handleSearchDream(recognizedText: String) async throws -> VoiceCommandResult {
        // 提取搜索关键词
        let keywords = extractKeywords(from: recognizedText)
        
        return VoiceCommandResult(
            commandType: .searchDream,
            recognizedText: recognizedText,
            confidence: 0.8,
            success: true,
            message: "正在搜索：\(keywords.joined(separator: ", "))",
            data: ["keywords": AnyCodable(keywords)]
        )
    }
    
    private func handleShowStats() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .showStats,
            recognizedText: "显示统计",
            confidence: 0.95,
            success: true,
            message: "正在加载梦境统计数据"
        )
    }
    
    private func handleShowRecent() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .showRecent,
            recognizedText: "显示最近梦境",
            confidence: 0.9,
            success: true,
            message: "显示最近 10 条梦境"
        )
    }
    
    private func handleShowCalendar() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .showCalendar,
            recognizedText: "显示日历",
            confidence: 0.9,
            success: true,
            message: "打开梦境日历视图"
        )
    }
    
    private func handleShowInsights() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .showInsights,
            recognizedText: "显示洞察",
            confidence: 0.9,
            success: true,
            message: "加载智能洞察"
        )
    }
    
    private func handleShowTrends() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .showTrends,
            recognizedText: "显示趋势",
            confidence: 0.9,
            success: true,
            message: "显示梦境趋势分析"
        )
    }
    
    private func handleShowPatterns() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .showPatterns,
            recognizedText: "显示模式",
            confidence: 0.9,
            success: true,
            message: "分析梦境模式"
        )
    }
    
    private func handleStartMeditation() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .startMeditation,
            recognizedText: "开始冥想",
            confidence: 0.9,
            success: true,
            message: "开始冥想练习"
        )
    }
    
    private func handlePlayMusic() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .playMusic,
            recognizedText: "播放音乐",
            confidence: 0.9,
            success: true,
            message: "播放梦境音乐"
        )
    }
    
    private func handleShowGallery() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .showGallery,
            recognizedText: "显示画廊",
            confidence: 0.9,
            success: true,
            message: "打开梦境画廊"
        )
    }
    
    private func handleExportData() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .exportData,
            recognizedText: "导出数据",
            confidence: 0.9,
            success: true,
            message: "准备导出数据"
        )
    }
    
    private func handleOpenSettings() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .openSettings,
            recognizedText: "打开设置",
            confidence: 0.95,
            success: true,
            message: "打开设置页面"
        )
    }
    
    private func handleSetReminder() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .setReminder,
            recognizedText: "设置提醒",
            confidence: 0.9,
            success: true,
            message: "设置梦境记录提醒"
        )
    }
    
    private func handleHelp() async throws -> VoiceCommandResult {
        return VoiceCommandResult(
            commandType: .help,
            recognizedText: "帮助",
            confidence: 0.95,
            success: true,
            message: "语音命令帮助：说'记录梦境'开始记录，说'查看统计'查看数据"
        )
    }
    
    private func handleWhatCanIDo() async throws -> VoiceCommandResult {
        let commands = VoiceCommandType.allCases.map { "\($0.icon) \($0.displayName)" }.joined(separator: "\n")
        
        return VoiceCommandResult(
            commandType: .whatCanIDo,
            recognizedText: "我能做什么",
            confidence: 0.95,
            success: true,
            message: "支持的命令：\n\(commands)",
            data: ["commands": AnyCodable(VoiceCommandType.allCases.map { $0.rawValue })]
        )
    }
    
    // MARK: - Helper Methods
    
    /// 提取关键词
    private func extractKeywords(from text: String) -> [String] {
        // 简单的关键词提取，实际应该使用 NLP
        let stopWords = ["搜索", "查找", "找一下", "查询", "关于", "的", "我", "想", "要"]
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return words.filter { $0.count > 1 && !stopWords.contains($0) }
    }
    
    /// 保存到历史记录
    private func saveToHistory(commandType: String, recognizedText: String, confidence: Double, success: Bool, message: String, responseTime: Double) {
        guard let modelContext = modelContext else { return }
        
        let history = VoiceCommandHistory(
            commandType: commandType,
            recognizedText: recognizedText,
            confidence: confidence,
            success: success,
            message: message,
            responseTime: responseTime
        )
        
        modelContext.insert(history)
        
        // 清理旧记录
        cleanupOldHistory()
    }
    
    /// 清理旧历史记录
    private func cleanupOldHistory() {
        guard let modelContext = modelContext else { return }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -config.maxHistoryDays, to: Date())!
        
        do {
            let descriptor = FetchDescriptor<VoiceCommandHistory>(
                predicate: #Predicate<VoiceCommandHistory> { $0.timestamp < cutoffDate }
            )
            let oldRecords = try modelContext.fetch(descriptor)
            for record in oldRecords {
                modelContext.delete(record)
            }
        } catch {
            print("Failed to cleanup old history: \(error)")
        }
    }
    
    /// 获取统计信息
    func getStats() -> VoiceCommandStats {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        let totalCommands = commandHistory.count
        let successfulCommands = commandHistory.filter { $0.success }.count
        let failedCommands = totalCommands - successfulCommands
        
        let todayCommands = commandHistory.filter { $0.timestamp >= today }.count
        let weeklyCommands = commandHistory.filter { $0.timestamp >= weekAgo }.count
        
        let averageConfidence = commandHistory.isEmpty ? 0 :
            commandHistory.map { $0.confidence }.reduce(0, +) / Double(commandHistory.count)
        
        let averageResponseTime = commandHistory.isEmpty ? 0 :
            commandHistory.map { $0.responseTime }.reduce(0, +) / Double(commandHistory.count)
        
        // 找出最常用的命令
        let commandCounts = Dictionary(grouping: commandHistory, by: { $0.commandType })
            .mapValues { $0.count }
        let mostUsedCommandRaw = commandCounts.max(by: { $0.value < $1.value })?.key
        
        let mostUsedCommand = mostUsedCommandRaw.flatMap { VoiceCommandType(rawValue: $0) }
        
        return VoiceCommandStats(
            totalCommands: totalCommands,
            successfulCommands: successfulCommands,
            failedCommands: failedCommands,
            averageConfidence: averageConfidence,
            averageResponseTime: averageResponseTime,
            mostUsedCommand: mostUsedCommand,
            todayCommands: todayCommands,
            weeklyCommands: weeklyCommands
        )
    }
    
    /// 语音反馈
    private func speakFeedback(_ message: String) async {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: config.language)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
        
        // 等待语音播放完成
        while synthesizer.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    /// 触觉反馈
    private func triggerHapticFeedback() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Errors

enum VoiceCommandError: LocalizedError {
    case notAuthorized
    case recognizerNotAvailable
    case requestFailed
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "未授权语音识别权限"
        case .recognizerNotAvailable: return "语音识别不可用"
        case .requestFailed: return "识别请求失败"
        case .audioEngineFailed: return "音频引擎启动失败"
        }
    }
}
