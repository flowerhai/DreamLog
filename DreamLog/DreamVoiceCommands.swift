//
//  DreamVoiceCommands.swift
//  DreamLog
//
//  Phase 71 - 梦境语音命令系统
//  支持语音控制应用功能，提升无障碍体验和便捷性
//

import Foundation
import Speech
import AVFoundation
import UIKit

// MARK: - 语音命令枚举

/// 支持的语音命令类型
enum VoiceCommand: String, CaseIterable {
    // 记录相关
    case recordDream = "记录梦境"
    case quickRecord = "快速记录"
    case startRecording = "开始录音"
    case stopRecording = "停止录音"
    
    // 查询相关
    case showStats = "查看统计"
    case showToday = "今天有什么梦"
    case showRecent = "最近的梦境"
    case searchDream = "搜索梦境"
    
    // 导航相关
    case openGallery = "打开画廊"
    case openInsights = "打开洞察"
    case openCalendar = "打开日历"
    case openSettings = "打开设置"
    
    // 功能相关
    case shareDream = "分享梦境"
    case lockDream = "锁定梦境"
    case analyzeDream = "分析梦境"
    case setReminder = "设置提醒"
    
    // 帮助
    case help = "帮助"
    case whatCanISay = "我可以说什么"
    
    var keywords: [String] {
        switch self {
        case .recordDream:
            return ["记录梦境", "记梦", "写梦", "记录", "记一下"]
        case .quickRecord:
            return ["快速记录", "快记", "录音"]
        case .startRecording:
            return ["开始录音", "开始记录", "录音开始"]
        case .stopRecording:
            return ["停止录音", "结束录音", "录音结束", "好了"]
        case .showStats:
            return ["查看统计", "统计数据", "我的统计", "数据分析"]
        case .showToday:
            return ["今天", "今天的梦", "今天有什么梦"]
        case .showRecent:
            return ["最近", "最近的梦", "最新梦境"]
        case .searchDream:
            return ["搜索", "查找", "找一下"]
        case .openGallery:
            return ["画廊", "梦境画廊", "图片", "AI 绘画"]
        case .openInsights:
            return ["洞察", "分析", "数据"]
        case .openCalendar:
            return ["日历", "日程"]
        case .openSettings:
            return ["设置", "选项", "配置"]
        case .shareDream:
            return ["分享", "发送"]
        case .lockDream:
            return ["锁定", "加密", "隐藏"]
        case .analyzeDream:
            return ["分析", "解析", "解梦"]
        case .setReminder:
            return ["提醒", "闹钟", "定时"]
        case .help:
            return ["帮助", "怎么用", "如何使用"]
        case .whatCanISay:
            return ["可以说什么", "命令", "指令"]
        }
    }
    
    var description: String {
        switch self {
        case .recordDream: return "开始记录新的梦境"
        case .quickRecord: return "快速语音记录"
        case .startRecording: return "开始录音"
        case .stopRecording: return "停止录音"
        case .showStats: return "查看梦境统计"
        case .showToday: return "查看今天的梦境"
        case .showRecent: return "查看最近的梦境"
        case .searchDream: return "搜索梦境"
        case .openGallery: return "打开梦境画廊"
        case .openInsights: return "打开洞察页面"
        case .openCalendar: return "打开日历视图"
        case .openSettings: return "打开设置"
        case .shareDream: return "分享当前梦境"
        case .lockDream: return "锁定当前梦境"
        case .analyzeDream: return "分析当前梦境"
        case .setReminder: return "设置记录提醒"
        case .help: return "查看帮助"
        case .whatCanISay: return "查看可用命令"
        }
    }
    
    var icon: String {
        switch self {
        case .recordDream, .quickRecord, .startRecording: return "mic.fill"
        case .stopRecording: return "mic.slash.fill"
        case .showStats: return "chart.bar.fill"
        case .showToday, .showRecent: return "calendar"
        case .searchDream: return "magnifyingglass"
        case .openGallery: return "photo.on.rectangle"
        case .openInsights: return "lightbulb.fill"
        case .openCalendar: return "calendar"
        case .openSettings: return "gear"
        case .shareDream: return "square.and.arrow.up"
        case .lockDream: return "lock.fill"
        case .analyzeDream: return "brain.head.profile"
        case .setReminder: return "bell.fill"
        case .help, .whatCanISay: return "questionmark.circle.fill"
        }
    }
}

// MARK: - 语音命令结果

/// 语音识别结果
struct VoiceCommandResult: Identifiable, Equatable {
    let id = UUID()
    let command: VoiceCommand?
    let confidence: Double
    let transcribedText: String
    let timestamp: Date
    
    var isSuccess: Bool {
        command != nil && confidence > 0.6
    }
    
    var displayText: String {
        if let cmd = command {
            return "识别：\(cmd.description)"
        } else {
            return "未识别：\"\(transcribedText)\""
        }
    }
}

// MARK: - 语音命令配置

/// 语音命令配置
struct VoiceCommandConfig: Codable {
    var enabled: Bool
    var language: String
    var requiresConfirmation: Bool
    var showVisualFeedback: Bool
    var hapticFeedback: Bool
    var wakeWord: String?
    
    static var `default`: VoiceCommandConfig {
        VoiceCommandConfig(
            enabled: true,
            language: "zh-CN",
            requiresConfirmation: false,
            showVisualFeedback: true,
            hapticFeedback: true,
            wakeWord: nil
        )
    }
}

// MARK: - 语音命令服务

/// 语音命令服务 - 核心语音识别和命令处理
@MainActor
class VoiceCommandService: ObservableObject {
    static let shared = VoiceCommandService()
    
    // MARK: - Published Properties
    
    @Published var isListening: Bool = false
    @Published var isProcessing: Bool = false
    @Published var lastResult: VoiceCommandResult?
    @Published var results: [VoiceCommandResult] = []
    @Published var config: VoiceCommandConfig = .default
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initialization
    
    private init() {
        setupSpeechRecognizer()
        loadConfig()
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        checkAuthorization()
    }
    
    private func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "voiceCommandConfig"),
           let decoded = try? JSONDecoder().decode(VoiceCommandConfig.self, from: data) {
            config = decoded
        }
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
    }
    
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    // MARK: - Voice Recognition
    
    func startListening() async throws {
        guard config.enabled else {
            throw VoiceCommandError.disabled
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceCommandError.unavailable
        }
        
        let status = await requestAuthorization()
        guard status == .authorized else {
            throw VoiceCommandError.notAuthorized
        }
        
        // 停止之前的识别
        stopListening()
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceCommandError.failedToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 创建识别任务
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result: result, error: error)
            }
        }
        
        // 配置音频引擎
        try setupAudioEngine()
        
        isListening = true
        isProcessing = true
        
        // 触觉反馈
        if config.hapticFeedback {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        isListening = false
        isProcessing = false
    }
    
    private func setupAudioEngine() throws {
        let audioEngine = self.audioEngine
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        isProcessing = false
        
        if let error = error {
            print("语音识别错误：\(error.localizedDescription)")
            return
        }
        
        guard let result = result, result.isFinal else { return }
        
        let transcribedText = result.bestTranscription.formattedString
        let command = identifyCommand(from: transcribedText)
        let confidence = result.bestTranscription.confidence
        
        let voiceResult = VoiceCommandResult(
            command: command,
            confidence: confidence,
            transcribedText: transcribedText,
            timestamp: Date()
        )
        
        lastResult = voiceResult
        results.insert(voiceResult, at: 0)
        
        // 限制历史记录数量
        if results.count > 50 {
            results.removeLast()
        }
        
        // 触觉反馈
        if config.hapticFeedback && command != nil {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        // 执行命令
        if let command = command {
            executeCommand(command)
        }
    }
    
    // MARK: - Command Identification
    
    private func identifyCommand(from text: String) -> VoiceCommand? {
        let lowercasedText = text.lowercased()
        
        // 遍历所有命令，找到匹配度最高的
        var bestMatch: VoiceCommand?
        var bestScore = 0.0
        
        for command in VoiceCommand.allCases {
            for keyword in command.keywords {
                if lowercasedText.contains(keyword.lowercased()) {
                    let score = Double(keyword.count) / Double(text.count)
                    if score > bestScore {
                        bestScore = score
                        bestMatch = command
                    }
                }
            }
        }
        
        // 只有匹配度足够高才返回
        return bestScore > 0.3 ? bestMatch : nil
    }
    
    // MARK: - Command Execution
    
    private func executeCommand(_ command: VoiceCommand) {
        // 通知监听者执行命令
        NotificationCenter.default.post(
            name: .voiceCommandExecuted,
            object: nil,
            userInfo: ["command": command]
        )
        
        // 语音反馈
        if config.showVisualFeedback {
            showCommandFeedback(command)
        }
    }
    
    private func showCommandFeedback(_ command: VoiceCommand) {
        // 通过通知中心显示反馈，具体 UI 由视图层处理
        NotificationCenter.default.post(
            name: .voiceCommandFeedback,
            object: nil,
            userInfo: [
                "command": command,
                "message": "执行：\(command.description)"
            ]
        )
    }
    
    // MARK: - Configuration
    
    func updateConfig(_ newConfig: VoiceCommandConfig) {
        config = newConfig
        saveConfig()
        
        if config.enabled {
            setupSpeechRecognizer()
        }
    }
    
    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "voiceCommandConfig")
        }
    }
    
    // MARK: - Utility
    
    func clearHistory() {
        results.removeAll()
        lastResult = nil
    }
    
    func getAvailableCommands() -> [VoiceCommand] {
        VoiceCommand.allCases
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let voiceCommandExecuted = Notification.Name("voiceCommandExecuted")
    static let voiceCommandFeedback = Notification.Name("voiceCommandFeedback")
}

// MARK: - Errors

enum VoiceCommandError: LocalizedError {
    case disabled
    case unavailable
    case notAuthorized
    case failedToCreateRequest
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .disabled:
            return "语音命令已禁用"
        case .unavailable:
            return "语音识别不可用"
        case .notAuthorized:
            return "未授权语音识别"
        case .failedToCreateRequest:
            return "创建识别请求失败"
        case .audioEngineFailed:
            return "音频引擎启动失败"
        }
    }
}

// MARK: - Preview Data

extension VoiceCommandService {
    static var preview: VoiceCommandService {
        let service = VoiceCommandService()
        service.results = [
            VoiceCommandResult(
                command: .recordDream,
                confidence: 0.95,
                transcribedText: "记录梦境",
                timestamp: Date()
            ),
            VoiceCommandResult(
                command: .showStats,
                confidence: 0.88,
                transcribedText: "查看统计",
                timestamp: Date().addingTimeInterval(-60)
            )
        ]
        return service
    }
}
