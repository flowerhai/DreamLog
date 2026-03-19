//
//  DreamVoiceCommandViewModel.swift
//  DreamLog
//
//  Phase 71 - 语音命令视图模型
//  连接语音服务与应用功能
//

import SwiftUI
import Combine
import SwiftData

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
    @Published var isAnalyzing = false
    @Published var analysisResult: String?
    
    // MARK: - Services
    
    private let voiceService: VoiceCommandService
    private let modelContext: ModelContext
    private let shareService: ShareService
    private let aiService: AIService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        voiceService: VoiceCommandService = .shared,
        modelContext: ModelContext,
        shareService: ShareService = .init(),
        aiService: AIService = .init()
    ) {
        self.voiceService = voiceService
        self.modelContext = modelContext
        self.shareService = shareService
        self.aiService = aiService
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
            let descriptor = FetchDescriptor<Dream>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            dreams = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "加载梦境失败：\(error.localizedDescription)"
            print("❌ 加载梦境错误：\(error)")
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
        
        Task {
            showFeedback("正在生成分享卡片...")
            
            // 使用默认风格生成分享卡片
            let style = ShareCardStyle.starry
            if let image = await shareService.generateShareImage(dream: dream, style: style) {
                showFeedback("分享卡片已生成，准备分享")
                // 可以通过 UIActivityViewController 分享
            } else {
                showFeedback("生成分享卡片失败")
            }
        }
    }
    
    func lockCurrentDream() {
        guard let dream = selectedDream else {
            showFeedback("请先选择一个梦境")
            return
        }
        
        Task {
            do {
                // 使用生物识别锁定梦境
                try await DreamPrivacyService(modelContext: modelContext).lockDream(dream, lockType: .biometric)
                showFeedback("梦境已锁定 🔒")
            } catch {
                showFeedback("锁定失败：\(error.localizedDescription)")
                print("❌ 锁定梦境错误：\(error)")
            }
        }
    }
    
    func analyzeCurrentDream() {
        guard let dream = selectedDream else {
            showFeedback("请先选择一个梦境")
            return
        }
        
        Task {
            isAnalyzing = true
            showFeedback("AI 正在分析梦境...")
            
            do {
                let analysis = await aiService.analyzeDream(
                    content: dream.content ?? "",
                    tags: dream.tags ?? [],
                    emotions: dream.emotions ?? []
                )
                
                analysisResult = analysis
                isAnalyzing = false
                showFeedback("梦境分析完成 ✨")
            } catch {
                isAnalyzing = false
                showFeedback("分析失败：\(error.localizedDescription)")
                print("❌ AI 分析错误：\(error)")
            }
        }
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

#if DEBUG
extension DreamVoiceCommandViewModel {
    static var preview: DreamVoiceCommandViewModel {
        do {
            let container = try ModelContainer(for: Dream.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            
            let viewModel = DreamVoiceCommandViewModel(modelContext: context)
            viewModel.dreams = [
                Dream(title: "飞行梦", content: "我在天空中自由飞翔", date: Date()),
                Dream(title: "追逐梦", content: "有人在追我", date: Date().addingTimeInterval(-86400))
            ]
            return viewModel
        } catch {
            fatalError("Preview setup failed: \(error)")
        }
    }
}
#endif
