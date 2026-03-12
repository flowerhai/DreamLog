//
//  MeditationService.swift
//  DreamLog - 梦境冥想与睡眠音效服务
//  Phase 8: 睡眠增强功能
//

import Foundation
import AVFoundation
import UserNotifications

/// 音效类型
enum SoundType: String, CaseIterable, Identifiable {
    case rain = "rain"           // 雨声
    case ocean = "ocean"         // 海浪
    case forest = "forest"       // 森林
    case whiteNoise = "whiteNoise"  // 白噪音
    case pinkNoise = "pinkNoise"    // 粉红噪音
    case brownNoise = "brownNoise"  // 棕色噪音
    case binaural40Hz = "binaural40Hz"  // 40Hz 双耳节拍 (γ波)
    case binaural10Hz = "binaural10Hz"  // 10Hz 双耳节拍 (α波)
    case binaural5Hz = "binaural5Hz"   // 5Hz 双耳节拍 (θ波)
    case binaural1Hz = "binaural1Hz"   // 1Hz 双耳节拍 (δ波)
    case singingBowl = "singingBowl"   // 颂钵
    case windChimes = "windChimes"     // 风铃
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rain: return "🌧️ 雨声"
        case .ocean: return "🌊 海浪"
        case .forest: return "🌲 森林"
        case .whiteNoise: return "⚪ 白噪音"
        case .pinkNoise: return "🌸 粉红噪音"
        case .brownNoise: return "🟤 棕色噪音"
        case .binaural40Hz: return "🧠 40Hz (γ波)"
        case .binaural10Hz: return "😌 10Hz (α波)"
        case .binaural5Hz: return "🌙 5Hz (θ波)"
        case .binaural1Hz: return "💤 1Hz (δ波)"
        case .singingBowl: return "🔔 颂钵"
        case .windChimes: return "🎐 风铃"
        }
    }
    
    var category: SoundCategory {
        switch self {
        case .rain, .ocean, .forest: return .nature
        case .whiteNoise, .pinkNoise, .brownNoise: return .noise
        case .binaural40Hz, .binaural10Hz, .binaural5Hz, .binaural1Hz: return .binaural
        case .singingBowl, .windChimes: return .meditation
        }
    }
    
    var description: String {
        switch self {
        case .rain: return "舒缓的雨声，帮助放松入睡"
        case .ocean: return "海浪拍打沙滩，带来宁静感"
        case .forest: return "森林中的自然声音，鸟鸣与微风"
        case .whiteNoise: return "均匀的背景音，屏蔽外界噪音"
        case .pinkNoise: return "更柔和的噪音，适合深度睡眠"
        case .brownNoise: return "低沉的噪音，最适合专注"
        case .binaural40Hz: return "γ波，提升意识和专注力"
        case .binaural10Hz: return "α波，放松与冥想状态"
        case .binaural5Hz: return "θ波，深度放松与创意"
        case .binaural1Hz: return "δ波，深度无梦睡眠"
        case .singingBowl: return "藏式颂钵，帮助进入冥想状态"
        case .windChimes: return "轻柔的风铃声，带来平静"
        }
    }
}

/// 音效分类
enum SoundCategory: String, CaseIterable {
    case nature = "自然"
    case noise = "噪音"
    case binaural = "双耳节拍"
    case meditation = "冥想"
    
    var icon: String {
        switch self {
        case .nature: return "🌿"
        case .noise: return "🔊"
        case .binaural: return "🧠"
        case .meditation: return "🧘"
        }
    }
}

/// 引导冥想类型
enum GuidedMeditationType: String, CaseIterable, Identifiable {
    case dreamRecall = "dreamRecall"      // 增强梦境回忆
    case lucidInduction = "lucidInduction" // 清醒梦诱导
    case sleepPreparation = "sleepPreparation" // 睡前准备
    case stressRelief = "stressRelief"    // 减压放松
    case morningGrounding = "morningGrounding" // 晨间锚定
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dreamRecall: return "🌙 增强梦境回忆"
        case .lucidInduction: return "✨ 清醒梦诱导"
        case .sleepPreparation: return "😴 睡前准备"
        case .stressRelief: return "😌 减压放松"
        case .morningGrounding: return "☀️ 晨间锚定"
        }
    }
    
    var duration: Int {
        switch self {
        case .dreamRecall: return 10 * 60  // 10 分钟
        case .lucidInduction: return 15 * 60 // 15 分钟
        case .sleepPreparation: return 20 * 60 // 20 分钟
        case .stressRelief: return 10 * 60  // 10 分钟
        case .morningGrounding: return 5 * 60  // 5 分钟
        }
    }
    
    var description: String {
        switch self {
        case .dreamRecall: return "通过冥想增强梦境记忆能力，提高醒来后的回忆清晰度"
        case .lucidInduction: return "MILD 技巧引导，帮助你在梦中保持意识"
        case .sleepPreparation: return "渐进式放松，为高质量睡眠做准备"
        case .stressRelief: return "释放日常压力，让心灵平静"
        case .morningGrounding: return "回顾梦境，锚定记忆，开始新的一天"
        }
    }
    
    var script: [String] {
        switch self {
        case .dreamRecall:
            return [
                "找一个舒适的姿势，轻轻闭上眼睛...",
                "深呼吸，吸气... 呼气...",
                "将注意力集中在你的呼吸上",
                "想象你正在进入一个宁静的空间",
                "在这个空间里，你的梦境清晰可见",
                "告诉自己：'我会记住我的梦'",
                "重复这个意图三次...",
                "感受这个意图深入你的潜意识",
                "当你醒来时，梦境会清晰地呈现在你脑海中",
                "慢慢回到当下，记住这个感觉..."
            ]
        case .lucidInduction:
            return [
                "放松身体，从脚趾到头顶...",
                "深呼吸，让身体完全放松",
                "想象你正在做一个梦",
                "在梦中，你注意到一些奇怪的事情",
                "你问自己：'这是梦吗？'",
                "你环顾四周，发现这确实是梦",
                "你意识到：'我在做梦！'",
                "感受这种觉醒的喜悦",
                "记住这个感觉，它会出现在你的梦中",
                "每晚睡前重复这个练习..."
            ]
        case .sleepPreparation:
            return [
                "躺在床上，保持舒适的姿势",
                "从脚趾开始，感受每个部位放松",
                "脚趾放松... 脚掌放松... 脚踝放松...",
                "小腿放松... 膝盖放松... 大腿放松...",
                "臀部放松... 腹部放松... 胸部放松...",
                "肩膀放松... 手臂放松... 手指放松...",
                "脖子放松... 脸部放松... 头皮放松...",
                "全身都放松了，感觉温暖而沉重",
                "呼吸变得缓慢而深沉",
                "让自己慢慢进入梦乡..."
            ]
        case .stressRelief:
            return [
                "找一个安静的地方坐下或躺下",
                "闭上眼睛，深呼吸三次",
                "想象压力像黑色的烟雾",
                "每次呼气，黑烟就离开你的身体",
                "吸气，吸入金色的光",
                "呼气，释放所有的紧张",
                "感受身体变得越来越轻",
                "心灵变得越来越平静",
                "你安全、放松、平静",
                "带着这份平静回到当下..."
            ]
        case .morningGrounding:
            return [
                "醒来后，先不要移动",
                "回想刚才的梦境",
                "记住梦中的感觉和画面",
                "如果有印象，在脑海中重播",
                "给这个梦一个标题",
                "记住关键的情绪和场景",
                "告诉自己：'我会记住这个梦'",
                "慢慢起身，开始新的一天",
                "带着梦境的智慧生活",
                "今晚，你会记得更多..."
            ]
        }
    }
}

/// 混音配置
struct SoundMix: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var sounds: [SoundMixItem]
    var masterVolume: Float
    var timer: Int?  // 秒，nil 表示不自动停止
    
    struct SoundMixItem: Codable, Identifiable {
        var id: UUID = UUID()
        var soundType: SoundType
        var volume: Float
        var isEnabled: Bool
    }
}

/// 冥想服务 - 管理音频播放
class MeditationService: NSObject, ObservableObject {
    static let shared = MeditationService()
    
    @Published var isPlaying: Bool = false
    @Published var currentMix: SoundMix?
    @Published var currentGuidedMeditation: GuidedMeditationType?
    @Published var playbackProgress: Double = 0.0
    @Published var remainingTime: Int = 0
    @Published var volume: Float = 0.5
    
    // Phase 26 - 音乐集成
    @Published var isMusicEnabled: Bool = false
    @Published var currentMusicId: UUID?
    @Published var musicVolume: Float = 0.3
    
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var guidedAudioPlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var progressTimer: Timer?
    
    // 音频会话配置
    private func configureAudioSession() {
        do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to configure audio session: \(error)")
            }
        }
    
    /// 加载音效文件
    func loadSound(_ type: SoundType) -> AVAudioPlayer? {
        // 在实际应用中，这里会加载本地音频文件
        // 由于这是示例代码，我们返回 nil，实际使用需要添加音频资源
        let fileName = type.rawValue
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1  // 循环播放
                player.prepareToPlay()
                return player
            } catch {
                print("Failed to load sound \(fileName): \(error)")
            }
        }
        return nil
    }
    
    /// 播放混音
    func playMix(_ mix: SoundMix) {
        stopAll()
        currentMix = mix
        configureAudioSession()
        
        for item in mix.sounds where item.isEnabled {
            if let player = loadSound(item.soundType) {
                player.volume = item.volume * volume * mix.masterVolume
                player.play()
                audioPlayers[item.soundType] = player
            }
        }
        
        isPlaying = true
        remainingTime = mix.timer ?? 0
        
        if let timerSeconds = mix.timer {
            startTimer(timerSeconds)
        }
        
        startProgressTimer()
    }
    
    /// 播放引导冥想
    func playGuidedMeditation(_ type: GuidedMeditationType) {
        stopAll()
        currentGuidedMeditation = type
        configureAudioSession()
        
        // 在实际应用中，这里会播放录制的引导音频
        // 示例代码使用 TTS 或占位符
        print("Playing guided meditation: \(type.displayName)")
        
        isPlaying = true
        remainingTime = type.duration
        startTimer(type.duration)
        startProgressTimer()
    }
    
    /// 暂停播放
    func pause() {
        audioPlayers.values.forEach { $0.pause() }
        guidedAudioPlayer?.pause()
        progressTimer?.invalidate()
        isPlaying = false
    }
    
    /// 恢复播放
    func resume() {
        audioPlayers.values.forEach { $0.play() }
        guidedAudioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    /// 停止所有播放
    func stopAll() {
        audioPlayers.values.forEach { $0.stop() }
        guidedAudioPlayer?.stop()
        musicPlayer?.stop()
        audioPlayers.removeAll()
        guidedAudioPlayer = nil
        musicPlayer = nil
        timer?.invalidate()
        progressTimer?.invalidate()
        isPlaying = false
        currentMix = nil
        currentGuidedMeditation = nil
        currentMusicId = nil
        isMusicEnabled = false
        playbackProgress = 0.0
        remainingTime = 0
    }
    
    /// 更新音量
    func updateVolume(_ newVolume: Float) {
        volume = newVolume
        if let mix = currentMix {
            for (type, player) in audioPlayers {
                if let item = mix.sounds.first(where: { $0.soundType == type && $0.isEnabled }) {
                    player.volume = item.volume * volume * mix.masterVolume
                }
            }
        }
    }
    
    /// 更新单个音效音量
    func updateSoundVolume(_ type: SoundType, volume: Float) {
        if let player = audioPlayers[type] {
            player.volume = volume * self.volume * (currentMix?.masterVolume ?? 1.0)
        }
    }
    
    /// 切换音效启用状态
    func toggleSound(_ type: SoundType, enabled: Bool) {
        if enabled {
            if let player = loadSound(type) {
                player.volume = volume * (currentMix?.masterVolume ?? 1.0)
                player.play()
                audioPlayers[type] = player
            }
        } else {
            audioPlayers[type]?.stop()
            audioPlayers.removeValue(forKey: type)
        }
    }
    
    /// 开始倒计时
    private func startTimer(_ seconds: Int) {
        timer?.invalidate()
        remainingTime = seconds
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingTime -= 1
            
            if self.remainingTime <= 0 {
                self.stopAll()
                self.scheduleSleepNotification()
            }
        }
    }
    
    /// 开始进度计时器
    private func startProgressTimer() {
        progressTimer?.invalidate()
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if let mix = self.currentMix, let timerSeconds = mix.timer {
                let total = Double(timerSeconds)
                let elapsed = Double(timerSeconds - self.remainingTime)
                self.playbackProgress = elapsed / total
            } else if let meditation = self.currentGuidedMeditation {
                let total = Double(meditation.duration)
                let elapsed = Double(meditation.duration - self.remainingTime)
                self.playbackProgress = elapsed / total
            }
        }
    }
    
    /// 安排睡眠通知
    private func scheduleSleepNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🌙 梦境冥想"
        content.body = "播放结束，祝你有个好梦"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "meditation_complete",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 保存混音预设
    func saveMixPreset(_ mix: SoundMix) {
        let presets = loadMixPresets()
        var newPresets = presets.filter { $0.id != mix.id }
        newPresets.append(mix)
        
        if let data = try? JSONEncoder().encode(newPresets) {
            UserDefaults.standard.set(data, forKey: "meditation_mix_presets")
        }
    }
    
    /// 加载混音预设
    func loadMixPresets() -> [SoundMix] {
        guard let data = UserDefaults.standard.data(forKey: "meditation_mix_presets") else {
            return defaultMixPresets
        }
        
        return (try? JSONDecoder().decode([SoundMix].self, from: data)) ?? defaultMixPresets
    }
    
    /// 默认混音预设
    var defaultMixPresets: [SoundMix] {
        [
            SoundMix(
                name: "🌧️ 雨夜好眠",
                sounds: [
                    SoundMix.SoundMixItem(soundType: .rain, volume: 0.8, isEnabled: true),
                    SoundMix.SoundMixItem(soundType: .brownNoise, volume: 0.3, isEnabled: true)
                ],
                masterVolume: 1.0,
                timer: 30 * 60
            ),
            SoundMix(
                name: "🌊 海边冥想",
                sounds: [
                    SoundMix.SoundMixItem(soundType: .ocean, volume: 0.7, isEnabled: true),
                    SoundMix.SoundMixItem(soundType: .windChimes, volume: 0.4, isEnabled: true)
                ],
                masterVolume: 1.0,
                timer: 20 * 60
            ),
            SoundMix(
                name: "🧘 深度放松",
                sounds: [
                    SoundMix.SoundMixItem(soundType: .binaural5Hz, volume: 0.6, isEnabled: true),
                    SoundMix.SoundMixItem(soundType: .singingBowl, volume: 0.3, isEnabled: true)
                ],
                masterVolume: 1.0,
                timer: 15 * 60
            ),
            SoundMix(
                name: "🌲 森林清晨",
                sounds: [
                    SoundMix.SoundMixItem(soundType: .forest, volume: 0.8, isEnabled: true),
                    SoundMix.SoundMixItem(soundType: .windChimes, volume: 0.5, isEnabled: true)
                ],
                masterVolume: 1.0,
                timer: nil
            )
        ]
    }
    
    // MARK: - Phase 26: 音乐集成功能
    
    /// 播放梦境音乐与冥想结合
    func playWithMusic(music: DreamMusic, mix: SoundMix? = nil) {
        stopAll()
        currentMusicId = music.id
        isMusicEnabled = true
        configureAudioSession()
        
        // 播放背景音乐
        if let filePath = music.filePath, let url = URL(string: filePath) {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1
                musicPlayer?.volume = musicVolume
                musicPlayer?.prepareToPlay()
                musicPlayer?.play()
            } catch {
                print("Failed to play music: \(error)")
            }
        }
        
        // 播放音效混音（可选）
        if let mix = mix {
            currentMix = mix
            for item in mix.sounds where item.isEnabled {
                if let player = loadSound(item.soundType) {
                    player.volume = item.volume * volume * mix.masterVolume
                    player.play()
                    audioPlayers[item.soundType] = player
                }
            }
        }
        
        isPlaying = true
        remainingTime = Int(music.duration)
        startProgressTimer()
        
        print("🎵 开始播放冥想音乐：\(music.title)")
    }
    
    /// 为冥想类型推荐音乐
    func recommendMusicForMeditation(type: GuidedMeditationType, from library: [DreamMusic]) -> [DreamMusic] {
        var recommended: [DreamMusic] = []
        
        switch type {
        case .dreamRecall:
            // 梦境回忆：平静、神秘
            recommended = library.filter { [.peaceful, .mysterious, .ethereal].contains($0.mood) }
        case .lucidInduction:
            // 清醒梦：神秘、梦幻
            recommended = library.filter { [.mysterious, .dreamy, .ethereal].contains($0.mood) }
        case .sleepPreparation:
            // 睡前准备：平静、舒缓
            recommended = library.filter { [.peaceful, .melancholic].contains($0.mood) && $0.tempo == .verySlow }
        case .stressRelief:
            // 减压：平静、欢快
            recommended = library.filter { [.peaceful, .joyful, .ethereal].contains($0.mood) }
        case .morningGrounding:
            // 晨间：欢快、活力
            recommended = library.filter { [.joyful, .energetic, .peaceful].contains($0.mood) }
        }
        
        return Array(recommended.prefix(5))
    }
    
    /// 创建冥想 + 音乐场景预设
    func createMeditationMusicScene(type: GuidedMeditationType, music: DreamMusic) -> SoundMix {
        var sounds: [SoundMix.SoundMixItem] = []
        
        switch type {
        case .dreamRecall:
            sounds = [
                SoundMix.SoundMixItem(soundType: .binaural5Hz, volume: 0.4, isEnabled: true),
                SoundMix.SoundMixItem(soundType: .singingBowl, volume: 0.2, isEnabled: true)
            ]
        case .lucidInduction:
            sounds = [
                SoundMix.SoundMixItem(soundType: .binaural10Hz, volume: 0.3, isEnabled: true),
                SoundMix.SoundMixItem(soundType: .windChimes, volume: 0.3, isEnabled: true)
            ]
        case .sleepPreparation:
            sounds = [
                SoundMix.SoundMixItem(soundType: .brownNoise, volume: 0.3, isEnabled: true),
                SoundMix.SoundMixItem(soundType: .rain, volume: 0.5, isEnabled: true)
            ]
        case .stressRelief:
            sounds = [
                SoundMix.SoundMixItem(soundType: .ocean, volume: 0.6, isEnabled: true),
                SoundMix.SoundMixItem(soundType: .forest, volume: 0.4, isEnabled: true)
            ]
        case .morningGrounding:
            sounds = [
                SoundMix.SoundMixItem(soundType: .forest, volume: 0.5, isEnabled: true),
                SoundMix.SoundMixItem(soundType: .windChimes, volume: 0.4, isEnabled: true)
            ]
        }
        
        return SoundMix(
            name: "🎵 \(type.displayName) + \(music.title)",
            sounds: sounds,
            masterVolume: 1.0,
            timer: Int(music.duration)
        )
    }
    
    /// 停止音乐播放
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicId = nil
        isMusicEnabled = false
    }
    
    /// 更新音乐音量
    func setMusicVolume(_ volume: Float) {
        musicVolume = volume
        musicPlayer?.volume = volume
    }
    
    deinit {
        stopAll()
    }
}
