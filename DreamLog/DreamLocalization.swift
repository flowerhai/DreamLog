//
//  DreamLocalization.swift
//  DreamLog
//
//  多语言本地化支持 - Phase 24
//  支持中文、英文、日文、韩文、法文、德文、西班牙文
//

import Foundation
import UIKit
import SwiftUI

// MARK: - 支持的语言

/// 支持的语言枚举
enum SupportedLanguage: String, Codable, CaseIterable, Identifiable {
    case chineseSimplified = "zh-Hans"      // 简体中文
    case chineseTraditional = "zh-Hant"     // 繁体中文
    case english = "en"                     // 英文
    case japanese = "ja"                    // 日文
    case korean = "ko"                      // 韩文
    case french = "fr"                      // 法文
    case german = "de"                      // 德文
    case spanish = "es"                     // 西班牙文
    
    var id: String { rawValue }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        }
    }
    
    /// 带旗帜图标的显示名称
    var displayNameWithFlag: String {
        switch self {
        case .chineseSimplified: return "🇨🇳 简体中文"
        case .chineseTraditional: return "🇭🇰 繁體中文"
        case .english: return "🇺🇸 English"
        case .japanese: return "🇯🇵 日本語"
        case .korean: return "🇰🇷 한국어"
        case .french: return "🇫🇷 Français"
        case .german: return "🇩🇪 Deutsch"
        case .spanish: return "🇪🇸 Español"
        }
    }
    
    /// 本地化文件前缀
    var localizationTable: String {
        switch self {
        case .chineseSimplified, .chineseTraditional: return "zh-Hans"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .german: return "de"
        case .spanish: return "es"
        }
    }
}

// MARK: - 本地化字符串键

/// 本地化字符串键枚举
enum LocalizationKey: String {
    // MARK: - 通用
    case appName = "app_name"
    case cancel = "cancel"
    case confirm = "confirm"
    case save = "save"
    case delete = "delete"
    case edit = "edit"
    case done = "done"
    case loading = "loading"
    case error = "error"
    case success = "success"
    case retry = "retry"
    case close = "close"
    case settings = "settings"
    case help = "help"
    case about = "about"
    
    // MARK: - 首页
    case homeTitle = "home_title"
    case homeGreeting = "home_greeting"
    case homeGreetingMorning = "home_greeting_morning"
    case homeGreetingAfternoon = "home_greeting_afternoon"
    case homeGreetingEvening = "home_greeting_evening"
    case homeGreetingNight = "home_greeting_night"
    case recordDreamPlaceholder = "record_dream_placeholder"
    case holdToSpeak = "hold_to_speak"
    case releaseToStop = "release_to_stop"
    case recentKeywords = "recent_keywords"
    case quickActions = "quick_actions"
    
    // MARK: - 梦境记录
    case recordTitle = "record_title"
    case dreamTitle = "dream_title"
    case dreamContent = "dream_content"
    case addTags = "add_tags"
    selectEmotions = "select_emotions"
    clarityLevel = "clarity_level"
    intensityLevel = "intensity_level"
    isLucidDream = "is_lucid_dream"
    saveDream = "save_dream"
    discardChanges = "discard_changes"
    
    // MARK: - 情绪
    case emotionCalm = "emotion_calm"
    case emotionHappy = "emotion_happy"
    case emotionAnxious = "emotion_anxious"
    case emotionFearful = "emotion_fearful"
    case emotionConfused = "emotion_confused"
    case emotionExcited = "emotion_excited"
    case emotionSad = "emotion_sad"
    case emotionAngry = "emotion_angry"
    case emotionSurprised = "emotion_surprised"
    case emotionNeutral = "emotion_neutral"
    
    // MARK: - 洞察分析
    case insightsTitle = "insights_title"
    case dreamStats = "dream_stats"
    case totalDreams = "total_dreams"
    case lucidDreams = "lucid_dreams"
    case averageClarity = "average_clarity"
    case currentStreak = "current_streak"
    case moodDistribution = "mood_distribution"
    case tagCloud = "tag_cloud"
    case timePattern = "time_pattern"
    case weeklyTrend = "weekly_trend"
    
    // MARK: - 画廊
    case galleryTitle = "gallery_title"
    case aiArtworks = "ai_artworks"
    case generateArt = "generate_art"
    case viewDetails = "view_details"
    case shareArtwork = "share_artwork"
    
    // MARK: - 日历
    case calendarTitle = "calendar_title"
    case today = "today"
    case noDreamsToday = "no_dreams_today"
    case tapToView = "tap_to_view"
    
    // MARK: - 目标
    case goalsTitle = "goals_title"
    case weeklyGoal = "weekly_goal"
    case dailyStreak = "daily_streak"
    case achievements = "achievements"
    case goalProgress = "goal_progress"
    
    // MARK: - 清醒梦
    case lucidTitle = "lucid_title"
    case techniques = "techniques"
    case realityChecks = "reality_checks"
    case trainingPlans = "training_plans"
    case startTraining = "start_training"
    case completionRate = "completion_rate"
    
    // MARK: - 社区
    case communityTitle = "community_title"
    case shareDream = "share_dream"
    case browseDreams = "browse_dreams"
    case popularDreams = "popular_dreams"
    case recentDreams = "recent_dreams"
    case likeDream = "like_dream"
    case commentDream = "comment_dream"
    
    // MARK: - 设置
    case settingsTitle = "settings_title"
    case accountSettings = "account_settings"
    case notificationSettings = "notification_settings"
    case privacySettings = "privacy_settings"
    case dataExport = "data_export"
    case backupRestore = "backup_restore"
    case languageSettings = "language_settings"
    case themeSettings = "theme_settings"
    case aboutApp = "about_app"
    case version = "version"
    
    // MARK: - 通知
    case notificationTitle = "notification_title"
    case morningReminder = "morning_reminder"
    case eveningReminder = "evening_reminder"
    case weeklySummary = "weekly_summary"
    case goalAchieved = "goal_achieved"
    case streakMilestone = "streak_milestone"
    
    // MARK: - AR 功能
    case arTitle = "ar_title"
    case arScene = "ar_scene"
    case arElements = "ar_elements"
    case arTemplates = "ar_templates"
    case arModels = "ar_models"
    case arRecording = "ar_recording"
    case arFaceTracking = "ar_face_tracking"
    case arPhotoMode = "ar_photo_mode"
    case arVideoMode = "ar_video_mode"
    
    // MARK: - 音乐
    case musicTitle = "music_title"
    case generateMusic = "generate_music"
    case musicLibrary = "music_library"
    case nowPlaying = "now_playing"
    case musicMood = "music_mood"
    case musicTempo = "music_tempo"
    
    // MARK: - 视频
    case videoTitle = "video_title"
    case generateVideo = "generate_video"
    case videoLibrary = "video_library"
    case editVideo = "edit_video"
    case videoTemplates = "video_templates"
    
    // MARK: - 导出
    case exportTitle = "export_title"
    case exportPDF = "export_pdf"
    case exportJSON = "export_json"
    case exportCSV = "export_csv"
    case exportMarkdown = "export_markdown"
    case exportToNotion = "export_to_notion"
    case exportToObsidian = "export_to_obsidian"
    case exportDateRange = "export_date_range"
    
    // MARK: - 助手
    case assistantTitle = "assistant_title"
    case askAssistant = "ask_assistant"
    case suggestionChips = "suggestion_chips"
    case quickActions = "quick_actions_menu"
    
    // MARK: - 灵感
    case inspirationTitle = "inspiration_title"
    case dailyInspiration = "daily_inspiration"
    case creativePrompts = "creative_prompts"
    case challenges = "challenges"
    case myCollection = "my_collection"
    
    // MARK: - 分享
    case shareTitle = "share_title"
    case shareTo = "share_to"
    case shareCard = "share_card"
    case copyLink = "copy_link"
    case generateQR = "generate_qr"
    
    // MARK: - 错误信息
    case errorNetwork = "error_network"
    case errorPermission = "error_permission"
    case errorStorage = "error_storage"
    case errorAI = "error_ai"
    case errorGeneric = "error_generic"
}

// MARK: - 本地化服务

/// 本地化服务
@MainActor
final class DreamLocalizationService: ObservableObject {
    static let shared = DreamLocalizationService()
    
    // MARK: - Published Properties
    
    /// 当前语言
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            saveLanguagePreference()
            applyLanguage()
        }
    }
    
    /// 是否使用系统语言
    @Published var useSystemLanguage: Bool {
        didSet {
            if useSystemLanguage {
                currentLanguage = systemLanguage
            }
            UserDefaults.standard.set(useSystemLanguage, forKey: "DreamLog.useSystemLanguage")
        }
    }
    
    // MARK: - Private Properties
    
    private let supportedLanguages: [SupportedLanguage] = SupportedLanguage.allCases
    private var bundle: Bundle?
    
    // MARK: - 初始化
    
    private init() {
        // 加载保存的语言偏好
        self.useSystemLanguage = UserDefaults.standard.object(forKey: "DreamLog.useSystemLanguage") as? Bool ?? true
        
        if self.useSystemLanguage {
            self.currentLanguage = systemLanguage
        } else {
            let savedLanguageCode = UserDefaults.standard.string(forKey: "DreamLog.selectedLanguage") ?? SupportedLanguage.chineseSimplified.rawValue
            self.currentLanguage = SupportedLanguage(rawValue: savedLanguageCode) ?? .chineseSimplified
        }
        
        setupBundle()
    }
    
    // MARK: - 公共方法
    
    /// 获取本地化字符串
    func localized(_ key: LocalizationKey, comment: String = "") -> String {
        return bundle?.localizedString(forKey: key.rawValue, value: nil, table: nil)
            ?? key.rawValue
    }
    
    /// 获取本地化字符串（带参数）
    func localized(_ key: LocalizationKey, arguments: CVarArg..., comment: String = "") -> String {
        let format = bundle?.localizedString(forKey: key.rawValue, value: nil, table: nil) ?? key.rawValue
        return String(format: format, arguments: arguments)
    }
    
    /// 设置语言
    func setLanguage(_ language: SupportedLanguage) {
        useSystemLanguage = false
        currentLanguage = language
    }
    
    /// 重置为系统语言
    func resetToSystemLanguage() {
        useSystemLanguage = true
    }
    
    /// 获取系统语言
    var systemLanguage: SupportedLanguage {
        let preferredLanguages = Locale.preferredLanguages
        for languageCode in preferredLanguages {
            if languageCode.hasPrefix("zh-Hans") || languageCode.hasPrefix("zh-CN") {
                return .chineseSimplified
            } else if languageCode.hasPrefix("zh-Hant") || languageCode.hasPrefix("zh-TW") || languageCode.hasPrefix("zh-HK") {
                return .chineseTraditional
            } else if languageCode.hasPrefix("en") {
                return .english
            } else if languageCode.hasPrefix("ja") {
                return .japanese
            } else if languageCode.hasPrefix("ko") {
                return .korean
            } else if languageCode.hasPrefix("fr") {
                return .french
            } else if languageCode.hasPrefix("de") {
                return .german
            } else if languageCode.hasPrefix("es") {
                return .spanish
            }
        }
        return .chineseSimplified // 默认
    }
    
    // MARK: - 私有方法
    
    private func setupBundle() {
        if let bundlePath = Bundle.main.path(forResource: currentLanguage.localizationTable, ofType: "lproj") {
            bundle = Bundle(path: bundlePath)
        } else {
            bundle = Bundle.main
        }
    }
    
    private func applyLanguage() {
        setupBundle()
        
        // 通知语言变更
        NotificationCenter.default.post(
            name: NSNotification.Name("DreamLogLanguageDidChange"),
            object: nil
        )
    }
    
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "DreamLog.selectedLanguage")
    }
}

// MARK: - String 扩展

extension String {
    /// 本地化字符串
    func localized() -> String {
        if let key = LocalizationKey(rawValue: self) {
            return DreamLocalizationService.shared.localized(key)
        }
        return self
    }
}

// MARK: - 本地化视图修饰符

struct LocalizedViewModifier: ViewModifier {
    @ObservedObject var localizationService = DreamLocalizationService.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.locale, .init(identifier: localizationService.currentLanguage.rawValue))
    }
}

extension View {
    /// 应用本地化
    func localized() -> some View {
        modifier(LocalizedViewModifier())
    }
}

// MARK: - 语言设置界面

struct LanguageSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var localizationService = DreamLocalizationService.shared
    @State private var showingFeedbackAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("语言选择")) {
                    Toggle("使用系统语言", isOn: $localizationService.useSystemLanguage)
                    
                    if !localizationService.useSystemLanguage {
                        ForEach(localizationService.supportedLanguages) { language in
                            Button(action: {
                                localizationService.setLanguage(language)
                            }) {
                                HStack {
                                    Text(language.displayNameWithFlag)
                                    Spacer()
                                    if localizationService.currentLanguage == language {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("关于翻译")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🌍 多语言支持")
                            .font(.headline)
                        
                        Text("DreamLog 支持 8 种语言，包括简体中文、繁体中文、英文、日文、韩文、法文、德文和西班牙文。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("翻译质量正在持续改进中。如果您发现任何翻译问题，欢迎通过设置中的反馈功能告诉我们。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("帮助改进翻译") {
                        openFeedbackForm()
                    }
                }
            }
            .navigationTitle("语言设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("反馈翻译问题", isPresented: $showingFeedbackAlert) {
                Button("取消", role: .cancel) { }
                Button("发送邮件") {
                    openEmailFeedback()
                }
                Button("在 App 内反馈") {
                    openInAppFeedback()
                }
            } message: {
                Text("请选择您喜欢的反馈方式，我们会认真对待每一条反馈！")
            }
        }
    }
    
    /// 打开反馈表单
    private func openFeedbackForm() {
        showingFeedbackAlert = true
    }
    
    /// 通过邮件反馈
    private func openEmailFeedback() {
        guard let url = URL(string: "mailto:1559743577@qq.com?subject=DreamLog 翻译反馈&body=请描述您发现的翻译问题：") else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// 在 App 内反馈（未来可扩展）
    private func openInAppFeedback() {
        // 未来可以打开 App 内反馈界面
        // 目前先显示提示
        print("In-app feedback form will be implemented in future updates")
    }
}

// MARK: - 本地化字符串文件生成器

/// 本地化字符串文件生成器（开发工具）
struct LocalizationStringsGenerator {
    /// 生成所有语言的字符串文件
    static func generateAllFiles() {
        for language in SupportedLanguage.allCases {
            generateStringsFile(for: language)
        }
    }
    
    /// 生成指定语言的字符串文件
    static func generateStringsFile(for language: SupportedLanguage) {
        var content = "//\n"
        content += "//  \(language.displayName) Localizable Strings\n"
        content += "//  DreamLog\n"
        content += "//\n"
        content += "//  Generated by LocalizationStringsGenerator\n"
        content += "//\n\n"
        
        // 按类别分组
        let categories = groupKeysByCategory()
        
        for (category, keys) in categories.sorted(by: { $0.key < $1.key }) {
            content += "// MARK: - \(category)\n\n"
            
            for key in keys.sorted(by: { $0.rawValue < $1.rawValue }) {
                let translation = getTranslation(for: key, in: language)
                content += "\"\(key.rawValue)\" = \"\(translation)\";\n"
            }
            
            content += "\n"
        }
        
        // 这里应该写入到文件，但为了简化，只打印
        print("Generated \(language.localizationTable).strings")
        print(content)
    }
    
    /// 按类别分组键
    private static func groupKeysByCategory() -> [String: [LocalizationKey]] {
        var categories: [String: [LocalizationKey]] = [:]
        
        for key in LocalizationKey.allCases {
            let category = categoryFor(key)
            if categories[category] == nil {
                categories[category] = []
            }
            categories[category]?.append(key)
        }
        
        return categories
    }
    
    /// 获取键的类别
    private static func categoryFor(_ key: LocalizationKey) -> String {
        let rawValue = key.rawValue
        if rawValue.hasPrefix("home") { return "Home" }
        if rawValue.hasPrefix("record") { return "Record" }
        if rawValue.hasPrefix("emotion") { return "Emotions" }
        if rawValue.hasPrefix("insights") { return "Insights" }
        if rawValue.hasPrefix("gallery") { return "Gallery" }
        if rawValue.hasPrefix("calendar") { return "Calendar" }
        if rawValue.hasPrefix("goals") { return "Goals" }
        if rawValue.hasPrefix("lucid") { return "Lucid Dream" }
        if rawValue.hasPrefix("community") { return "Community" }
        if rawValue.hasPrefix("settings") { return "Settings" }
        if rawValue.hasPrefix("notification") { return "Notifications" }
        if rawValue.hasPrefix("ar") { return "AR" }
        if rawValue.hasPrefix("music") { return "Music" }
        if rawValue.hasPrefix("video") { return "Video" }
        if rawValue.hasPrefix("export") { return "Export" }
        if rawValue.hasPrefix("assistant") { return "Assistant" }
        if rawValue.hasPrefix("inspiration") { return "Inspiration" }
        if rawValue.hasPrefix("share") { return "Share" }
        if rawValue.hasPrefix("error") { return "Errors" }
        return "General"
    }
    
    /// 获取翻译（示例实现）
    private static func getTranslation(for key: LocalizationKey, in language: SupportedLanguage) -> String {
        // 这里应该从翻译服务或文件中获取实际翻译
        // 为了简化，返回英文或中文作为示例
        
        switch language {
        case .english:
            return englishTranslation(for: key)
        case .japanese:
            return "（日本語翻訳）" + key.rawValue
        case .korean:
            return "（한국어 번역）" + key.rawValue
        case .french:
            return "（Traduction française）" + key.rawValue
        case .german:
            return "（Deutsche Übersetzung）" + key.rawValue
        case .spanish:
            return "（Traducción al español）" + key.rawValue
        default:
            return key.rawValue // 中文作为默认
        }
    }
    
    /// 英文翻译（示例）
    private static func englishTranslation(for key: LocalizationKey) -> String {
        switch key {
        case .appName: return "DreamLog"
        case .cancel: return "Cancel"
        case .confirm: return "Confirm"
        case .save: return "Save"
        case .delete: return "Delete"
        case .edit: return "Edit"
        case .done: return "Done"
        case .loading: return "Loading..."
        case .error: return "Error"
        case .success: return "Success"
        case .retry: return "Retry"
        case .close: return "Close"
        case .settings: return "Settings"
        case .help: return "Help"
        case .about: return "About"
        case .homeTitle: return "Home"
        case .homeGreeting: return "What did you dream about last night?"
        case .recordDreamPlaceholder: return "Describe your dream..."
        case .holdToSpeak: return "Hold to Speak"
        case .releaseToStop: return "Release to Stop"
        case .recentKeywords: return "Recent Keywords"
        case .totalDreams: return "Total Dreams"
        case .lucidDreams: return "Lucid Dreams"
        case .averageClarity: return "Average Clarity"
        case .currentStreak: return "Current Streak"
        default:
            return key.rawValue
        }
    }
}

// MARK: - 枚举扩展

extension LocalizationKey: CaseIterable {
    public static var allCases: [LocalizationKey] {
        return [
            // 通用
            .appName, .cancel, .confirm, .save, .delete, .edit, .done,
            .loading, .error, .success, .retry, .close, .settings, .help, .about,
            
            // 首页
            .homeTitle, .homeGreeting, .recordDreamPlaceholder,
            .holdToSpeak, .releaseToStop, .recentKeywords,
            
            // 情绪
            .emotionCalm, .emotionHappy, .emotionAnxious, .emotionFearful,
            .emotionConfused, .emotionExcited, .emotionSad, .emotionAngry,
            .emotionSurprised, .emotionNeutral,
            
            // 洞察
            .insightsTitle, .dreamStats, .totalDreams, .lucidDreams,
            .averageClarity, .currentStreak, .moodDistribution, .tagCloud,
            
            // 设置
            .settingsTitle, .languageSettings, .themeSettings, .aboutApp, .version,
            
            // AR
            .arTitle, .arScene, .arElements, .arTemplates, .arModels,
            .arRecording, .arFaceTracking, .arPhotoMode, .arVideoMode,
            
            // 错误
            .errorNetwork, .errorPermission, .errorStorage, .errorAI, .errorGeneric
        ]
    }
}

// MARK: - 预览

#Preview {
    LanguageSettingsView()
}
