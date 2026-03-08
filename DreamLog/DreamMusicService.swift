//
//  DreamMusicService.swift
//  DreamLog
//
//  梦境音乐生成服务 - 根据梦境内容生成匹配的 ambient 音乐
//  Phase 9 - AI 音乐增强功能
//

import Foundation
import AVFoundation
import Combine

// MARK: - 梦境音乐模型

/// 梦境音乐
struct DreamMusic: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var dreamId: UUID
    var title: String
    var duration: TimeInterval  // 秒
    var mood: DreamMusicMood
    var tempo: DreamMusicTempo
    var instruments: [DreamMusicInstrument]
    var audioLayers: [AudioLayer]
    var createdAt: Date
    var isFavorite: Bool = false
    var filePath: String?  // 本地文件路径
    
    /// 音乐情绪
    enum DreamMusicMood: String, Codable, CaseIterable, Identifiable {
        case peaceful = "平静"
        case mysterious = "神秘"
        case dreamy = "梦幻"
        case energetic = "活力"
        case melancholic = "忧郁"
        case ethereal = "空灵"
        case tense = "紧张"
        case joyful = "欢快"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .peaceful: return "moon.fill"
            case .mysterious: return "eye.fill"
            case .dreamy: return "sparkles"
            case .energetic: return "bolt.fill"
            case .melancholic: return "cloud.rain.fill"
            case .ethereal: return "cloud.sun.fill"
            case .tense: return "bolt.horizontal.fill"
            case .joyful: return "sun.max.fill"
            }
        }
        
        var color: String {
            switch self {
            case .peaceful: return "5B91F5"
            case .mysterious: return "8B5CF6"
            case .dreamy: return "EC4899"
            case .energetic: return "F59E0B"
            case .melancholic: return "64748B"
            case .ethereal: return "06B6D4"
            case .tense: return "DC2626"
            case .joyful: return "10B981"
            }
        }
        
        var description: String {
            switch self {
            case .peaceful: return "宁静祥和，如月光般温柔"
            case .mysterious: return "深邃神秘，探索未知"
            case .dreamy: return "飘渺梦幻，如入仙境"
            case .energetic: return "充满活力，动感十足"
            case .melancholic: return "略带忧伤，深情内敛"
            case .ethereal: return "超凡脱俗，空灵飘渺"
            case .tense: return "紧张刺激，扣人心弦"
            case .joyful: return "欢快明亮，充满喜悦"
            }
        }
    }
    
    /// 音乐节奏
    enum DreamMusicTempo: String, Codable, CaseIterable {
        case verySlow = "极慢 (40-60 BPM)"
        case slow = "慢速 (60-80 BPM)"
        case moderate = "中速 (80-100 BPM)"
        case moderateFast = "中快 (100-120 BPM)"
        case fast = "快速 (120-140 BPM)"
        
        var bpmRange: ClosedRange<Int> {
            switch self {
            case .verySlow: return 40...60
            case .slow: return 60...80
            case .moderate: return 80...100
            case .moderateFast: return 100...120
            case .fast: return 120...140
            }
        }
        
        var icon: String {
            switch self {
            case .verySlow: return "tortoise"
            case .slow: return "hare"
            case .moderate: return "metronome"
            case .moderateFast: return "speedometer"
            case .fast: return "bolt.fill"
            }
        }
    }
    
    /// 乐器类型
    enum DreamMusicInstrument: String, Codable, CaseIterable, Identifiable {
        case piano = "钢琴"
        case strings = "弦乐"
        case flute = "长笛"
        case harp = "竖琴"
        case synth = "合成器"
        case ambientPad = "氛围 Pad"
        case natureSounds = "自然音效"
        case singingBowl = "颂钵"
        case windChimes = "风铃"
        case oceanWaves = "海浪"
        case rainSounds = "雨声"
        case forestAmbience = "森林氛围"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .piano: return "music.note"
            case .strings: return "guitars.fill"
            case .flute: return "wind"
            case .harp: return "music.note.house"
            case .synth: return "waveform"
            case .ambientPad: return "cloud.fill"
            case .natureSounds: return "leaf.fill"
            case .singingBowl: return "bell.fill"
            case .windChimes: return "wind.snow"
            case .oceanWaves: return "water.waves"
            case .rainSounds: return "cloud.rain.fill"
            case .forestAmbience: return "tree.fill"
            }
        }
    }
    
    /// 音频层
    struct AudioLayer: Codable, Identifiable {
        var id: UUID = UUID()
        var instrument: DreamMusicInstrument
        var volume: Float  // 0.0 - 1.0
        var pan: Float  // -1.0 (左) 到 1.0 (右)
        var reverb: Float  // 0.0 - 1.0
        var delay: Float  // 0.0 - 1.0
        var loop: Bool
        var sampleName: String?
    }
}

// MARK: - 梦境音乐生成服务

@MainActor
class DreamMusicService: ObservableObject {
    static let shared = DreamMusicService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var currentMusic: DreamMusic?
    @Published var errorMessage: String?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var musicLibrary: [DreamMusic] = []
    
    private var audioPlayer: AVAudioPlayer?
    private var playTimer: Timer?
    
    // 音乐生成模板库
    private let musicTemplates: [DreamMusicMood: MusicTemplate] = [
        .peaceful: MusicTemplate(
            mood: .peaceful,
            tempo: .slow,
            instruments: [.piano, .strings, .ambientPad],
            baseDuration: 180
        ),
        .mysterious: MusicTemplate(
            mood: .mysterious,
            tempo: .verySlow,
            instruments: [.synth, .ambientPad, .singingBowl],
            baseDuration: 240
        ),
        .dreamy: MusicTemplate(
            mood: .dreamy,
            tempo: .slow,
            instruments: [.harp, .flute, .ambientPad, .windChimes],
            baseDuration: 200
        ),
        .energetic: MusicTemplate(
            mood: .energetic,
            tempo: .moderateFast,
            instruments: [.piano, .strings, .synth],
            baseDuration: 160
        ),
        .melancholic: MusicTemplate(
            mood: .melancholic,
            tempo: .slow,
            instruments: [.piano, .strings, .rainSounds],
            baseDuration: 220
        ),
        .ethereal: MusicTemplate(
            mood: .ethereal,
            tempo: .verySlow,
            instruments: [.synth, .ambientPad, .windChimes, .singingBowl],
            baseDuration: 260
        ),
        .tense: MusicTemplate(
            mood: .tense,
            tempo: .moderate,
            instruments: [.strings, .synth, .ambientPad],
            baseDuration: 150
        ),
        .joyful: MusicTemplate(
            mood: .joyful,
            tempo: .moderateFast,
            instruments: [.piano, .flute, .strings],
            baseDuration: 170
        )
    ]
    
    private init() {
        loadMusicLibrary()
    }
    
    // MARK: - 音乐生成
    
    /// 根据梦境内容生成音乐
    func generateMusic(for dream: Dream) async -> DreamMusic? {
        await MainActor.run {
            isGenerating = true
            generationProgress = 0.0
            errorMessage = nil
        }
        
        do {
            // Step 1: 分析梦境情绪 (20%)
            await updateProgress(0.2)
            let mood = analyzeDreamMood(from: dream)
            
            // Step 2: 确定节奏和乐器 (40%)
            await updateProgress(0.4)
            let template = musicTemplates[mood] ?? musicTemplates[.peaceful]!
            let instruments = selectInstruments(for: dream, template: template)
            
            // Step 3: 生成音频层配置 (60%)
            await updateProgress(0.6)
            let audioLayers = generateAudioLayers(instruments: instruments, mood: mood)
            
            // Step 4: 创建音乐对象 (80%)
            await updateProgress(0.8)
            let music = DreamMusic(
                dreamId: dream.id,
                title: generateMusicTitle(for: dream, mood: mood),
                duration: TimeInterval(template.baseDuration),
                mood: mood,
                tempo: template.tempo,
                instruments: instruments,
                audioLayers: audioLayers,
                createdAt: Date()
            )
            
            // Step 5: 完成 (100%)
            await updateProgress(1.0)
            
            await MainActor.run {
                currentMusic = music
                isGenerating = false
            }
            
            return music
            
        } catch {
            await MainActor.run {
                isGenerating = false
                errorMessage = "音乐生成失败：\(error.localizedDescription)"
            }
            return nil
        }
    }
    
    /// 分析梦境情绪
    private func analyzeDreamMood(from dream: Dream) -> DreamMusic.DreamMusicMood {
        // 基于梦境情绪标签决定音乐情绪
        if dream.emotions.contains(where: { $0.rawValue == "平静" || $0.rawValue == "快乐" }) {
            return .peaceful
        } else if dream.emotions.contains(where: { $0.rawValue == "焦虑" || $0.rawValue == "恐惧" }) {
            return .tense
        } else if dream.emotions.contains(where: { $0.rawValue == "悲伤" }) {
            return .melancholic
        } else if dream.emotions.contains(where: { $0.rawValue == "兴奋" }) {
            return .energetic
        } else if dream.emotions.contains(where: { $0.rawValue == "惊讶" }) {
            return .mysterious
        } else if dream.isLucid {
            return .ethereal
        } else if dream.clarity >= 4 {
            return .dreamy
        } else {
            return .peaceful
        }
    }
    
    /// 选择乐器
    private func selectInstruments(for dream: Dream, template: MusicTemplate) -> [DreamMusic.DreamMusicInstrument] {
        var instruments = template.instruments
        
        // 根据梦境内容添加特殊乐器
        let content = (dream.content + " " + (dream.title ?? "")).lowercased()
        
        if content.contains("水") || content.contains("海") || content.contains("河") || content.contains("雨") {
            instruments.append(.oceanWaves)
        }
        if content.contains("森林") || content.contains("树") || content.contains("自然") {
            instruments.append(.forestAmbience)
        }
        if content.contains("风") || content.contains("天空") || content.contains("云") {
            instruments.append(.windChimes)
        }
        if content.contains("冥想") || content.contains("禅") || content.contains("宁静") {
            instruments.append(.singingBowl)
        }
        
        // 去重
        return Array(Set(instruments))
    }
    
    /// 生成音频层
    private func generateAudioLayers(instruments: [DreamMusic.DreamMusicInstrument], mood: DreamMusic.DreamMusicMood) -> [DreamMusic.AudioLayer] {
        return instruments.map { instrument in
            DreamMusic.AudioLayer(
                instrument: instrument,
                volume: instrumentVolume(for: instrument, mood: mood),
                pan: Float.random(in: -0.3...0.3),
                reverb: moodReverb(for: mood),
                delay: moodDelay(for: mood),
                loop: true,
                sampleName: "\(instrument.rawValue)_\(mood.rawValue)"
            )
        }
    }
    
    private func instrumentVolume(for instrument: DreamMusic.DreamMusicInstrument, mood: DreamMusic.DreamMusicMood) -> Float {
        // 基础音量
        let baseVolume: Float = 0.6
        
        // 根据情绪调整
        switch mood {
        case .peaceful, .ethereal:
            return baseVolume * 0.8
        case .energetic, .joyful:
            return baseVolume * 1.2
        case .tense:
            return baseVolume * 1.0
        default:
            return baseVolume
        }
    }
    
    private func moodReverb(for mood: DreamMusic.DreamMusicMood) -> Float {
        switch mood {
        case .ethereal, .dreamy, .mysterious:
            return 0.8
        case .peaceful, .melancholic:
            return 0.6
        case .energetic, .joyful:
            return 0.3
        case .tense:
            return 0.4
        }
    }
    
    private func moodDelay(for mood: DreamMusic.DreamMusicMood) -> Float {
        switch mood {
        case .ethereal, .dreamy:
            return 0.5
        case .mysterious, .melancholic:
            return 0.3
        default:
            return 0.2
        }
    }
    
    /// 生成音乐标题
    private func generateMusicTitle(for dream: Dream, mood: DreamMusic.DreamMusicMood) -> String {
        let date = DateFormatter.localizedString(from: dream.createdAt, dateStyle: .medium, timeStyle: .none)
        let moodName = mood.rawValue
        
        if let title = dream.title, !title.isEmpty {
            return "《\(title)》- \(moodName)混音"
        } else {
            return "\(date) 的梦境 - \(moodName)"
        }
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            generationProgress = progress
        }
        try? await Task.sleep(nanoseconds: 300_000_000)  // 模拟处理时间
    }
    
    // MARK: - 播放控制
    
    func play(_ music: DreamMusic) {
        // 模拟播放 - 实际实现需要音频文件
        isPlaying = true
        currentTime = 0
        
        playTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime += 1
                if self.currentTime >= music.duration {
                    self.stop()
                }
            }
        }
    }
    
    func pause() {
        playTimer?.invalidate()
        isPlaying = false
    }
    
    func stop() {
        playTimer?.invalidate()
        isPlaying = false
        currentTime = 0
        audioPlayer?.stop()
    }
    
    func seek(to time: TimeInterval) {
        currentTime = time
        audioPlayer?.currentTime = time
    }
    
    // MARK: - 音乐库管理
    
    func saveMusic(_ music: DreamMusic) {
        musicLibrary.append(music)
        saveMusicLibrary()
    }
    
    func deleteMusic(_ music: DreamMusic) {
        musicLibrary.removeAll { $0.id == music.id }
        saveMusicLibrary()
    }
    
    func toggleFavorite(_ music: DreamMusic) {
        if let index = musicLibrary.firstIndex(where: { $0.id == music.id }) {
            musicLibrary[index].isFavorite.toggle()
            saveMusicLibrary()
        }
    }
    
    private func saveMusicLibrary() {
        // 保存到本地存储
        if let encoded = try? JSONEncoder().encode(musicLibrary) {
            UserDefaults.standard.set(encoded, forKey: "DreamMusicLibrary")
        }
    }
    
    private func loadMusicLibrary() {
        if let data = UserDefaults.standard.data(forKey: "DreamMusicLibrary"),
           let decoded = try? JSONDecoder().decode([DreamMusic].self, from: data) {
            musicLibrary = decoded
        }
    }
    
    // MARK: - 快捷生成
    
    /// 为多个梦境生成播放列表
    func generatePlaylist(for dreams: [Dream]) async -> [DreamMusic] {
        var playlist: [DreamMusic] = []
        
        for dream in dreams {
            if let music = await generateMusic(for: dream) {
                playlist.append(music)
                saveMusic(music)
            }
        }
        
        return playlist
    }
}

// MARK: - 音乐模板

struct MusicTemplate {
    let mood: DreamMusic.DreamMusicMood
    let tempo: DreamMusic.DreamMusicTempo
    let instruments: [DreamMusic.DreamMusicInstrument]
    let baseDuration: Int
}
