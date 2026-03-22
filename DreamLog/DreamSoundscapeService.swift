//
//  DreamSoundscapeService.swift
//  DreamLog
//
//  氛围音景生成与混合服务 - Phase 86 梦境音乐与氛围音景 🎵💤✨
//  创建时间：2026-03-21
//

import Foundation
import AVFoundation
import Combine

// MARK: - 音景分类枚举

/// 氛围音景分类
enum SoundscapeCategory: String, Codable, CaseIterable, Identifiable {
    case nature = "自然"           // 雨声/海浪/森林
    case city = "城市"             // 交通/人群/咖啡馆
    case indoor = "室内"           // 壁炉/时钟/翻书
    case fantasy = "奇幻"          // 魔法/太空/梦境
    case whiteNoise = "白噪音"     // 粉红/棕色/白噪音
    case meditation = "冥想"       // 双耳节拍/引导音
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .city: return "building.2.fill"
        case .indoor: return "house.fill"
        case .fantasy: return "sparkles"
        case .whiteNoise: return "waveform"
        case .meditation: return "figure.mind.and.body"
        }
    }
    
    var color: String {
        switch self {
        case .nature: return "34D399"
        case .city: return "6B7280"
        case .indoor: return "F59E0B"
        case .fantasy: return "8B5CF6"
        case .whiteNoise: return "9CA3AF"
        case .meditation: return "6366F1"
        }
    }
    
    /// 该分类下的音景预设
    var presets: [SoundscapePreset] {
        switch self {
        case .nature:
            return [.stormyNight, .forestMorning, .oceanBeach, .gentleRain, .flowingStream]
        case .city:
            return [.cityTraffic, .cafeAmbience, .nightCity, .distantSirens]
        case .indoor:
            return [.cozyFireplace, .clockTicking, .pageTurning, .keyboardTyping]
        case .fantasy:
            return [.magicForest, .spaceAmbience, .dreamscape, .etherealPad]
        case .whiteNoise:
            return [.whiteNoise, .pinkNoise, .brownNoise, .blueNoise]
        case .meditation:
            return [.binauralTheta, .binauralAlpha, .singingBowl, .meditationDrone]
        }
    }
}

// MARK: - 音景预设模板

/// 音景预设
struct SoundscapePreset: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var category: SoundscapeCategory
    var icon: String
    var color: String
    var layers: [SoundscapeLayerData]
    var recommendedMoods: [String]
    var description: String
    
    init(
        id: UUID = UUID(),
        name: String,
        category: SoundscapeCategory,
        icon: String,
        color: String,
        layers: [SoundscapeLayerData],
        recommendedMoods: [String] = [],
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.icon = icon
        self.color = color
        self.layers = layers
        self.recommendedMoods = recommendedMoods
        self.description = description
    }
    
    // MARK: - 自然类预设
    
    static let stormyNight = SoundscapePreset(
        name: "暴风雨夜",
        category: .nature,
        icon: "⛈️",
        color: "4C1D95",
        layers: [
            SoundscapeLayerData(soundId: "rain_heavy", soundName: "大雨", volume: 0.8),
            SoundscapeLayerData(soundId: "thunder_distant", soundName: "远雷", volume: 0.4, fadeIn: 5, fadeOut: 5),
            SoundscapeLayerData(soundId: "wind", soundName: "风声", volume: 0.3)
        ],
        recommendedMoods: ["平静", "中性"],
        description: "深沉的雨声与遥远的雷声，营造宁静的睡眠氛围"
    )
    
    static let forestMorning = SoundscapePreset(
        name: "森林清晨",
        category: .nature,
        icon: "🌲",
        color: "059669",
        layers: [
            SoundscapeLayerData(soundId: "birds", soundName: "鸟鸣", volume: 0.6),
            SoundscapeLayerData(soundId: "leaves", soundName: "树叶沙沙", volume: 0.3),
            SoundscapeLayerData(soundId: "stream", soundName: "溪流", volume: 0.4)
        ],
        recommendedMoods: ["快乐", "平静"],
        description: "清晨森林的生机勃勃，鸟鸣与溪流交织"
    )
    
    static let oceanBeach = SoundscapePreset(
        name: "海边日落",
        category: .nature,
        icon: "🌊",
        color: "0891B2",
        layers: [
            SoundscapeLayerData(soundId: "waves", soundName: "海浪", volume: 0.7),
            SoundscapeLayerData(soundId: "seagulls", soundName: "海鸥", volume: 0.2),
            SoundscapeLayerData(soundId: "wind_light", soundName: "微风", volume: 0.2)
        ],
        recommendedMoods: ["平静", "快乐"],
        description: "温柔的海浪声，带来放松与宁静"
    )
    
    static let gentleRain = SoundscapePreset(
        name: "绵绵细雨",
        category: .nature,
        icon: "🌧️",
        color: "64748B",
        layers: [
            SoundscapeLayerData(soundId: "rain_light", soundName: "细雨", volume: 0.6),
            SoundscapeLayerData(soundId: "roof_drops", soundName: "屋檐滴水", volume: 0.3)
        ],
        recommendedMoods: ["平静", "悲伤"],
        description: "轻柔的雨声，适合专注工作或冥想"
    )
    
    static let flowingStream = SoundscapePreset(
        name: "山间溪流",
        category: .nature,
        icon: "💧",
        color: "06B6D4",
        layers: [
            SoundscapeLayerData(soundId: "stream_flow", soundName: "溪流", volume: 0.7),
            SoundscapeLayerData(soundId: "water_stones", soundName: "水击石", volume: 0.3)
        ],
        recommendedMoods: ["平静"],
        description: "清澈的溪水流淌声，净化心灵"
    )
    
    // MARK: - 室内类预设
    
    static let cozyFireplace = SoundscapePreset(
        name: "温暖壁炉",
        category: .indoor,
        icon: "🔥",
        color: "DC2626",
        layers: [
            SoundscapeLayerData(soundId: "fireplace", soundName: "壁炉", volume: 0.7),
            SoundscapeLayerData(soundId: "clock", soundName: "时钟滴答", volume: 0.2)
        ],
        recommendedMoods: ["平静", "中性"],
        description: "温暖的壁炉火光声，家的感觉"
    )
    
    static let clockTicking = SoundscapePreset(
        name: "时钟滴答",
        category: .indoor,
        icon: "🕰️",
        color: "78350F",
        layers: [
            SoundscapeLayerData(soundId: "grandfather_clock", soundName: "落地钟", volume: 0.5)
        ],
        recommendedMoods: ["平静", "中性"],
        description: "规律的时钟滴答声，帮助集中注意力"
    )
    
    static let pageTurning = SoundscapePreset(
        name: "翻书声",
        category: .indoor,
        icon: "📖",
        color: "92400E",
        layers: [
            SoundscapeLayerData(soundId: "pages", soundName: "翻书", volume: 0.4),
            SoundscapeLayerData(soundId: "library_ambience", soundName: "图书馆环境", volume: 0.2)
        ],
        recommendedMoods: ["平静"],
        description: "安静的图书馆氛围，适合阅读和学习"
    )
    
    // MARK: - 白噪音预设
    
    static let whiteNoise = SoundscapePreset(
        name: "白噪音",
        category: .whiteNoise,
        icon: "〰️",
        color: "9CA3AF",
        layers: [
            SoundscapeLayerData(soundId: "white_noise", soundName: "白噪音", volume: 0.6)
        ],
        recommendedMoods: ["平静", "中性"],
        description: "均匀的白噪音，遮蔽外界干扰"
    )
    
    static let pinkNoise = SoundscapePreset(
        name: "粉红噪音",
        category: .whiteNoise,
        icon: "📊",
        color: "6B7280",
        layers: [
            SoundscapeLayerData(soundId: "pink_noise", soundName: "粉红噪音", volume: 0.5)
        ],
        recommendedMoods: ["平静"],
        description: "比白噪音更柔和，有助于深度睡眠"
    )
    
    static let brownNoise = SoundscapePreset(
        name: "棕色噪音",
        category: .whiteNoise,
        icon: "📈",
        color: "4B5563",
        layers: [
            SoundscapeLayerData(soundId: "brown_noise", soundName: "棕色噪音", volume: 0.5)
        ],
        recommendedMoods: ["平静", "焦虑"],
        description: "深沉的低频噪音，最适合睡眠"
    )
    
    // MARK: - 冥想类预设
    
    static let binauralTheta = SoundscapePreset(
        name: "θ波双耳节拍",
        category: .meditation,
        icon: "🧘",
        color: "7C3AED",
        layers: [
            SoundscapeLayerData(soundId: "binaural_theta", soundName: "θ波 (4-8Hz)", volume: 0.5),
            SoundscapeLayerData(soundId: "ambient_drone", soundName: "环境长音", volume: 0.3)
        ],
        recommendedMoods: ["平静"],
        description: "θ波诱导深度放松和冥想状态"
    )
    
    static let binauralAlpha = SoundscapePreset(
        name: "α波双耳节拍",
        category: .meditation,
        icon: "🧠",
        color: "8B5CF6",
        layers: [
            SoundscapeLayerData(soundId: "binaural_alpha", soundName: "α波 (8-14Hz)", volume: 0.5),
            SoundscapeLayerData(soundId: "ambient_drone", soundName: "环境长音", volume: 0.3)
        ],
        recommendedMoods: ["平静", "快乐"],
        description: "α波促进放松和创意状态"
    )
    
    static let singingBowl = SoundscapePreset(
        name: "颂钵冥想",
        category: .meditation,
        icon: "🔔",
        color: "F59E0B",
        layers: [
            SoundscapeLayerData(soundId: "singing_bowl", soundName: "颂钵", volume: 0.6),
            SoundscapeLayerData(soundId: "tibetan_bell", soundName: "藏式铃", volume: 0.2)
        ],
        recommendedMoods: ["平静"],
        description: "传统的颂钵声音，引导深度冥想"
    )
    
    // MARK: - 所有预设
    
    static let allPresets: [SoundscapePreset] = [
        // 自然类
        .stormyNight, .forestMorning, .oceanBeach, .gentleRain, .flowingStream,
        // 室内类
        .cozyFireplace, .clockTicking, .pageTurning,
        // 白噪音
        .whiteNoise, .pinkNoise, .brownNoise,
        // 冥想类
        .binauralTheta, .binauralAlpha, .singingBowl
    ]
    
    /// 根据情绪推荐音景
    static func recommendedForMood(_ mood: String) -> [SoundscapePreset] {
        allPresets.filter { $0.recommendedMoods.contains(mood) }
    }
}

// MARK: - 音景层数据

/// 音景层数据结构
struct SoundscapeLayerData: Codable, Identifiable, Equatable {
    var id: UUID
    var soundId: String
    var soundName: String
    var volume: Float // 0.0 - 1.0
    var pan: Float // -1.0 (左) 到 1.0 (右)
    var fadeIn: TimeInterval
    var fadeOut: TimeInterval
    var loop: Bool
    var pitch: Float // 0.5 - 2.0
    
    init(
        id: UUID = UUID(),
        soundId: String,
        soundName: String,
        volume: Float = 0.7,
        pan: Float = 0.0,
        fadeIn: TimeInterval = 2.0,
        fadeOut: TimeInterval = 2.0,
        loop: Bool = true,
        pitch: Float = 1.0
    ) {
        self.id = id
        self.soundId = soundId
        self.soundName = soundName
        self.volume = volume
        self.pan = pan
        self.fadeIn = fadeIn
        self.fadeOut = fadeOut
        self.loop = loop
        self.pitch = pitch
    }
    
    /// 复制并修改音量
    func withVolume(_ newVolume: Float) -> SoundscapeLayerData {
        var copy = self
        copy.volume = min(max(newVolume, 0.0), 1.0)
        return copy
    }
}

// MARK: - 音景服务

/// 氛围音景服务 - 生成、混合和管理音景
@MainActor
final class DreamSoundscapeService: ObservableObject {
    static let shared = DreamSoundscapeService()
    
    // MARK: - Published Properties
    
    @Published var isPlaying: Bool = false
    @Published var currentSoundscape: SoundscapePreset?
    @Published var currentLayers: [SoundscapeLayerData] = []
    @Published var masterVolume: Float = 0.7
    @Published var sleepTimer: SleepTimerConfig?
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var playerNodes: [String: AVAudioPlayerNode] = [:]
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]
    private var sleepTimerTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        setupAudioEngine()
    }
    
    deinit {
        stopAll()
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        audioEngine?.mainMixerNode.outputVolume = masterVolume
        
        do {
            try audioEngine?.start()
        } catch {
            print("❌ 无法启动音频引擎：\(error)")
        }
    }
    
    // MARK: - Public Methods
    
    /// 播放音景预设
    func playSoundscape(_ preset: SoundscapePreset) async {
        stopAll()
        
        currentSoundscape = preset
        currentLayers = preset.layers
        
        for layer in preset.layers {
            await loadAndPlayLayer(layer)
        }
        
        isPlaying = true
    }
    
    /// 加载并播放单个音景层
    private func loadAndPlayLayer(_ layer: SoundscapeLayerData) async {
        guard let audioEngine = audioEngine else { return }
        
        // 创建或获取播放器节点
        if playerNodes[layer.soundId] == nil {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            
            // 连接混音
            let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
            
            playerNodes[layer.soundId] = playerNode
        }
        
        // 加载音频文件 (模拟 - 实际需要从 bundle 加载)
        await loadAudioFile(for: layer.soundId)
        
        // 播放
        if let playerNode = playerNodes[layer.soundId],
           let buffer = audioBuffers[layer.soundId] {
            playerNode.volume = layer.volume * masterVolume
            playerNode.pan = layer.pan
            
            if layer.fadeIn > 0 {
                playerNode.scheduleBuffer(buffer)
                playerNode.play()
                // 渐入效果
                await applyFadeIn(playerNode, duration: layer.fadeIn)
            } else {
                playerNode.play()
            }
        }
    }
    
    /// 加载音频文件
    private func loadAudioFile(for soundId: String) async {
        // TODO: 从 bundle 或网络加载实际音频文件
        // 这里使用模拟实现
        await Task.yield()
    }
    
    /// 应用渐入效果
    private func applyFadeIn(_ playerNode: AVAudioPlayerNode, duration: TimeInterval) async {
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 1...steps {
            let targetVolume = Float(i) / Float(steps)
            playerNode.volume = targetVolume * masterVolume
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
    
    /// 更新音景层音量
    func updateLayerVolume(_ layerId: UUID, volume: Float) {
        guard let index = currentLayers.firstIndex(where: { $0.id == layerId }) else { return }
        currentLayers[index].volume = min(max(volume, 0.0), 1.0)
        
        let layer = currentLayers[index]
        playerNodes[layer.soundId]?.volume = layer.volume * masterVolume
    }
    
    /// 更新主音量
    func updateMasterVolume(_ volume: Float) {
        masterVolume = min(max(volume, 0.0), 1.0)
        audioEngine?.mainMixerNode.outputVolume = masterVolume
        
        // 更新所有层的实际音量
        for layer in currentLayers {
            playerNodes[layer.soundId]?.volume = layer.volume * masterVolume
        }
    }
    
    /// 暂停播放
    func pause() {
        playerNodes.values.forEach { $0.pause() }
        isPlaying = false
    }
    
    /// 恢复播放
    func resume() {
        playerNodes.values.forEach { $0.play() }
        isPlaying = true
    }
    
    /// 停止所有播放
    func stopAll() {
        playerNodes.values.forEach { $0.stop() }
        sleepTimerTask?.cancel()
        sleepTimer = nil
        isPlaying = false
        currentSoundscape = nil
        currentLayers = []
    }
    
    /// 设置睡眠定时器
    func setSleepTimer(_ config: SleepTimerConfig) {
        sleepTimer = config
        sleepTimerTask?.cancel()
        
        guard config.enabled else { return }
        
        sleepTimerTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(config.duration * 1_000_000_000))
            
            if !Task.isCancelled {
                await applySleepTimerAction(config)
            }
        }
    }
    
    /// 应用睡眠定时器动作
    private func applySleepTimerAction(_ config: SleepTimerConfig) async {
        switch config.action {
        case .stop:
            // 渐出后停止
            await fadeOutAndStop(duration: config.fadeOutDuration)
        case .lowerVolume:
            // 降低音量
            await fadeVolume(to: 0.1, duration: config.fadeOutDuration)
        case .switchToWhiteNoise:
            // 切换到白噪音
            await switchToWhiteNoise()
        }
    }
    
    /// 渐出并停止
    private func fadeOutAndStop(duration: TimeInterval) async {
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in (0..<steps).reversed() {
            let targetVolume = Float(i) / Float(steps)
            updateMasterVolume(targetVolume * masterVolume)
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        
        stopAll()
    }
    
    /// 渐出音量
    private func fadeVolume(to targetVolume: Float, duration: TimeInterval) async {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let startVolume = masterVolume
        
        for i in 0...steps {
            let progress = Float(i) / Float(steps)
            let volume = startVolume + (targetVolume - startVolume) * progress
            updateMasterVolume(volume)
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
    
    /// 切换到白噪音
    private func switchToWhiteNoise() async {
        await playSoundscape(.whiteNoise)
    }
    
    /// 根据梦境推荐音景
    func recommendSoundscape(for dream: Dream) -> [SoundscapePreset] {
        var presets: [SoundscapePreset] = []
        
        // 基于情绪推荐
        let emotionPresets = SoundscapePreset.recommendedForMood(dream.emotion.rawValue)
        presets.append(contentsOf: emotionPresets)
        
        // 基于场景推荐
        if dream.content.contains("雨") || dream.content.contains("水") || dream.content.contains("海") {
            presets.append(.oceanBeach)
            presets.append(.gentleRain)
        }
        if dream.content.contains("森林") || dream.content.contains("树") || dream.content.contains("鸟") {
            presets.append(.forestMorning)
        }
        if dream.content.contains("火") || dream.content.contains("温暖") {
            presets.append(.cozyFireplace)
        }
        
        // 基于清晰度推荐
        if dream.clarity >= 4 {
            presets.append(.binauralAlpha)
        }
        
        // 去重
        let uniquePresets = presets.reduce(into: [SoundscapePreset]()) { result, preset in
            if !result.contains(where: { $0.id == preset.id }) {
                result.append(preset)
            }
        }
        
        return Array(uniquePresets.prefix(6))
    }
    
    /// 创建自定义混合
    func createCustomMix(name: String, layers: [SoundscapeLayerData]) -> SoundscapePreset {
        SoundscapePreset(
            name: name,
            category: .nature,
            icon: "🎵",
            color: "6366F1",
            layers: layers,
            description: "自定义混合音景"
        )
    }
}

// MARK: - 睡眠定时器配置

/// 睡眠定时器配置
struct SleepTimerConfig: Codable, Equatable {
    var enabled: Bool
    var duration: TimeInterval // 秒
    var fadeOutDuration: TimeInterval
    var action: SleepTimerAction
    
    init(
        enabled: Bool = false,
        duration: TimeInterval = 1800, // 30 分钟
        fadeOutDuration: TimeInterval = 30,
        action: SleepTimerAction = .stop
    ) {
        self.enabled = enabled
        self.duration = duration
        self.fadeOutDuration = fadeOutDuration
        self.action = action
    }
    
    /// 格式化时长
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)小时\(remainingMinutes)分钟" : "\(hours)小时"
        }
        return "\(minutes)分钟"
    }
    
    /// 预设时长
    static let presets: [(TimeInterval, String)] = [
        (900, "15 分钟"),
        (1800, "30 分钟"),
        (3600, "1 小时"),
        (5400, "1.5 小时"),
        (7200, "2 小时")
    ]
}

/// 睡眠定时器动作
enum SleepTimerAction: String, Codable, CaseIterable {
    case stop = "停止播放"
    case lowerVolume = "降低音量"
    case switchToWhiteNoise = "切换到白噪音"
}

// MARK: - 梦境模型扩展

/// 梦境模型 (简化版，用于服务依赖)
struct Dream {
    var id: UUID
    var emotion: DreamEmotion
    var content: String
    var clarity: Int
    
    init(id: UUID = UUID(), emotion: DreamEmotion = .中性，content: String = "", clarity: Int = 3) {
        self.id = id
        self.emotion = emotion
        self.content = content
        self.clarity = clarity
    }
}

/// 梦境情绪枚举
enum DreamEmotion: String, Codable, CaseIterable {
    case 平静 = "平静"
    case 快乐 = "快乐"
    case 焦虑 = "焦虑"
    case 悲伤 = "悲伤"
    case 困惑 = "困惑"
    case 恐惧 = "恐惧"
    case 兴奋 = "兴奋"
    case 中性 = "中性"
}
