//
//  DreamVoiceCommandViewModel.swift
//  DreamLog
//
//  Phase 71 - 语音命令视图模型
//  连接语音服务与应用功能
//

import SwiftUI
import Combine

// MARK: - 视图模型

@MainActor
class DreamVoiceCommandViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentView: VoiceCommandViewType = .gallery
    @Published var isShowingFeedback = false
    @Published var feedbackMessage = ""
    @Published var selectedDream: Dream?
    @Published var dreams: [Dream] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    
    private let voiceService: VoiceCommandService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(voiceService: VoiceCommandService = .shared) {
        self.voiceService = voiceService
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // 监听语音命令执行
        NotificationCenter.default.publisher(for: .voiceCommandExecuted)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let command = notification.userInfo?["command"] as? VoiceCommand else { return }
                self.handleCommand(command)
            }
            .store(in: &cancellables)
        
        // 监听反馈显示
        NotificationCenter.default.publisher(for: .voiceCommandFeedback)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let message = notification.userInfo?["message"] as? String else { return }
                self.showFeedback(message)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Command Handling
    
    func handleCommand(_ command: VoiceCommand) {
        print("执行语音命令：\(command)")
        
        switch command {
        case .recordDream, .quickRecord, .startRecording:
            navigateTo(.addDream)
            
        case .stopRecording:
            stopRecording()
            
        case .showStats:
            navigateTo(.insights)
            
        case .showToday:
            showTodayDreams()
            
        case .showRecent:
            navigateTo(.gallery)
            
        case .searchDream:
            navigateTo(.search)
            
        case .openGallery:
            navigateTo(.gallery)
            
        case .openInsights:
            navigateTo(.insights)
            
        case .openCalendar:
            navigateTo(.calendar)
            
        case .openSettings:
            navigateTo(.settings)
            
        case .shareDream:
            shareCurrentDream()
            
        case .lockDream:
            lockCurrentDream()
            
        case .analyzeDream:
            analyzeCurrentDream()
            
        case .setReminder:
            navigateTo(.settings)
            
        case .help, .whatCanISay:
            showHelp()
        }
    }
    
    // MARK: - Navigation
    
    enum VoiceCommandViewType {
        case gallery
        case addDream
        case insights
        case calendar
        case search
        case settings
        case detail
    }
    
    func navigateTo(_ view: VoiceCommandViewType) {
        currentView = view
        showFeedback("正在打开...")
    }
    
    // MARK: - Dream Operations
    
    func loadDreams() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: 从 DreamService 加载梦境
            // 这里是占位实现
            try await Task.sleep(nanoseconds: 500_000_000)
            dreams = []
        } catch {
            errorMessage = "加载梦境失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func showTodayDreams() {
        let calendar = Calendar.current
        let today = Date()
        
        dreams = dreams.filter { dream in
            calendar.isDateInToday(dream.createdAt)
        }
        
        navigateTo(.gallery)
        showFeedback("显示今天的梦境")
    }
    
    func shareCurrentDream() {
        guard let dream = selectedDream else {
            showFeedback("请先选择一个梦境")
            return
        }
        
        // TODO: 调用分享服务
        showFeedback("准备分享：\(dream.title ?? "梦境")")
    }
    
    func lockCurrentDream() {
        guard let dream = selectedDream else {
            showFeedback("请先选择一个梦境")
            return
        }
        
        // TODO: 调用隐私服务锁定梦境
        showFeedback("已锁定梦境")
    }
    
    func analyzeCurrentDream() {
        guard let dream = selectedDream else {
            showFeedback("请先选择一个梦境")
            return
        }
        
        // TODO: 调用 AI 分析服务
        showFeedback("正在分析梦境...")
    }
    
    // MARK: - Recording
    
    func stopRecording() {
        voiceService.stopListening()
        showFeedback("录音已停止")
    }
    
    // MARK: - Feedback
    
    func showFeedback(_ message: String) {
        feedbackMessage = message
        isShowingFeedback = true
        
        // 2 秒后自动隐藏
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isShowingFeedback = false
        }
    }
    
    // MARK: - Help
    
    func showHelp() {
        showFeedback("可用的语音命令：记录梦境、查看统计、打开画廊...")
    }
    
    // MARK: - Utility
    
    func selectDream(_ dream: Dream) {
        selectedDream = dream
        navigateTo(.detail)
    }
    
    func clearSelection() {
        selectedDream = nil
    }
}

// MARK: - Preview

extension DreamVoiceCommandViewModel {
    static var preview: DreamVoiceCommandViewModel {
        let viewModel = DreamVoiceCommandViewModel()
        viewModel.dreams = [
            Dream(title: "飞行梦", content: "我在天空中自由飞翔", createdAt: Date()),
            Dream(title: "追逐梦", content: "有人在追我", createdAt: Date().addingTimeInterval(-86400))
        ]
        return viewModel
    }
}
