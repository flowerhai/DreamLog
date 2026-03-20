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
    
    // Phase 10 - 导出进度
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    
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
            let template = musicTemplates[mood] ?? musicTemplates[.peaceful] ?? MusicTemplate(
                mood: .peaceful,
                tempo: .slow,
                instruments: [.piano, .strings, .ambientPad],
                baseDuration: 180
            )
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
        let content = (dream.content + " " + dream.title).lowercased()
        
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
        
        if !dream.title.isEmpty {
            return "《\(dream.title)》- \(moodName)混音"
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
    
    // MARK: - 音乐导出
    
    // Phase 10 - 真实音频合成引擎
    private let audioEngine = AudioSynthesisEngine.shared
    
    /// 导出音乐为音频文件 (AAC/m4a 格式) - Phase 10 真实音频合成
    func exportMusic(_ music: DreamMusic) async -> URL? {
        await MainActor.run {
            isExporting = true
            exportProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isExporting = false
            }
        }
        
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return nil
        }
        
        let exportsDirectory = URL(fileURLWithPath: documentsPath)
            .appendingPathComponent("DreamMusicExports", isDirectory: true)
        
        // 创建导出目录
        try? FileManager.default.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        
        // 生成文件名
        let safeTitle = music.title.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = "\(safeTitle)_\(music.id.uuidString.prefix(8)).m4a"
        let fileURL = exportsDirectory.appendingPathComponent(fileName)
        
        // Phase 10: 使用真实音频合成引擎生成音频
        do {
            // 合成所有音频层并混合
            let mixedBuffer = try await synthesizeMusic(music)
            
            // 导出为 AAC 格式
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                audioEngine.exportToAAC(buffer: mixedBuffer, to: fileURL) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? NSError(domain: "AudioExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "导出失败"]))
                    }
                }
            }
            
            // 导出元数据文件
            let exportInfo: [String: Any] = [
                "musicId": music.id.uuidString,
                "title": music.title,
                "duration": music.duration,
                "mood": music.mood.rawValue,
                "tempo": music.tempo.rawValue,
                "instruments": music.instruments.map { $0.rawValue },
                "audioLayers": music.audioLayers.map { layer in
                    [
                        "instrument": layer.instrument.rawValue,
                        "volume": layer.volume,
                        "pan": layer.pan,
                        "reverb": layer.reverb,
                        "delay": layer.delay,
                        "loop": layer.loop
                    ]
                },
                "exportDate": Date().ISO8601Format(),
                "format": "AAC",
                "sampleRate": 44100,
                "bitRate": 256,
                "channels": 2,
                "fileSize": try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
            ]
            
            let metadataURL = fileURL.deletingPathExtension().appendingPathExtension("json")
            if let jsonData = try? JSONSerialization.data(withJSONObject: exportInfo, options: .prettyPrinted) {
                try jsonData.write(to: metadataURL)
            }
            
            // 更新音乐的文件路径
            if var updatedMusic = musicLibrary.first(where: { $0.id == music.id }) {
                updatedMusic.filePath = fileURL.path
                if let index = musicLibrary.firstIndex(where: { $0.id == music.id }) {
                    musicLibrary[index] = updatedMusic
                    saveMusicLibrary()
                }
            }
            
            print("🎵 音乐导出成功：\(fileURL.path)")
            return fileURL
            
        } catch {
            print("❌ 音乐导出失败：\(error.localizedDescription)")
            // 回退到旧版本 (创建元数据文件)
            let exportInfo: [String: Any] = [
                "musicId": music.id.uuidString,
                "title": music.title,
                "duration": music.duration,
                "mood": music.mood.rawValue,
                "tempo": music.tempo.rawValue,
                "instruments": music.instruments.map { $0.rawValue },
                "exportDate": Date().ISO8601Format(),
                "format": "AAC",
                "sampleRate": 44100,
                "bitRate": 256,
                "channels": 2,
                "error": error.localizedDescription
            ]
            
            let metadataURL = fileURL.deletingPathExtension().appendingPathExtension("json")
            if let jsonData = try? JSONSerialization.data(withJSONObject: exportInfo, options: .prettyPrinted) {
                try? jsonData.write(to: metadataURL)
            }
            
            return nil
        }
    }
    
    /// 合成音乐 - 将所有音频层混合
    private func synthesizeMusic(_ music: DreamMusic) async throws -> AVAudioPCMBuffer {
        let sampleRate = 44100.0
        let duration = music.duration
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            throw NSError(domain: "AudioSynthesis", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建音频格式"])
        }
        
        guard let mixedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioSynthesis", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建音频缓冲区"])
        }
        mixedBuffer.frameLength = frameCount
        
        // 初始化缓冲区为静音
        if let floatChannelData = mixedBuffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                memset(floatChannelData[channel], 0, Int(frameCount) * MemoryLayout<Float>.stride)
            }
        }
        
        // 合成并混合每个音频层
        for (index, layer) in music.audioLayers.enumerated() {
            guard let layerBuffer = audioEngine.synthesizeAudioLayer(layer, duration: duration, sampleRate: sampleRate) else {
                continue
            }
            
            // 混合到主缓冲区
            mixBuffer(mixedBuffer, with: layerBuffer, volume: layer.volume)
            
            // 更新进度
            await MainActor.run {
                let progress = Double(index + 1) / Double(music.audioLayers.count)
                exportProgress = progress
            }
        }
        
        return mixedBuffer
    }
    
    /// 混合两个音频缓冲区
    private func mixBuffer(_ target: AVAudioPCMBuffer, with source: AVAudioPCMBuffer, volume: Float) {
        guard let targetData = target.floatChannelData,
              let sourceData = source.floatChannelData else { return }
        
        let frameCount = Int(target.frameLength)
        
        for channel in 0..<Int(target.format.channelCount) {
            for i in 0..<frameCount {
                targetData[channel][i] += sourceData[channel][i] * volume
            }
        }
    }
    
    /// 批量导出音乐
    func exportMusicBatch(_ musics: [DreamMusic]) async -> [URL] {
        var exportedURLs: [URL] = []
        
        for music in musics {
            if let url = await exportMusic(music) {
                exportedURLs.append(url)
            }
        }
        
        return exportedURLs
    }
    
    // MARK: - 音乐分享
    
    /// 生成音乐分享链接 (本地文件分享)
    func shareMusic(_ music: DreamMusic) async -> ShareItem? {
        guard let exportURL = await exportMusic(music) else {
            return nil
        }
        
        return ShareItem(
            musicId: music.id,
            title: music.title,
            mood: music.mood,
            exportURL: exportURL,
            shareText: "我刚刚为梦境「\(music.title)」生成了一首\(music.mood.rawValue)风格的音乐，来自 DreamLog App 🎵"
        )
    }
    
    /// 分享音乐到社交平台
    func shareMusicToSocial(_ music: DreamMusic, platform: MusicSharePlatform) async -> Bool {
        guard let shareItem = await shareMusic(music) else {
            return false
        }
        
        // 实际分享需要通过 UIActivityViewController 或平台 SDK
        // 这里提供分享数据
        print("分享音乐到 \(platform.rawValue): \(shareItem.shareText)")
        print("文件路径：\(shareItem.exportURL.path)")
        
        // 使用 iOS 原生分享 (UIActivityViewController)
        // 在 SwiftUI 中通过 ShareLink 或 UIActivityViewController 实现
        // 参考 ShareService 中的实现方式
        return true
    }
    
    /// 获取音乐分享 URL (用于 ShareLink)
    func getShareURL(for music: DreamMusic) async -> URL? {
        guard let filePath = music.filePath,
              FileManager.default.fileExists(atPath: filePath) else {
            // 如果文件不存在，尝试导出
            return await exportMusicAsFile(music)
        }
        return URL(fileURLWithPath: filePath)
    }
    
    /// 生成音乐分享预览 (用于 ShareLink preview)
    func generateSharePreview(for music: DreamMusic) -> MusicSharePreview {
        return MusicSharePreview(
            title: music.title,
            subtitle: "\(music.mood.rawValue) · \(formatDuration(music.duration))",
            mood: music.mood,
            instruments: music.instruments,
            thumbnailData: generateThumbnailData(for: music)
        )
    }
    
    /// 生成音乐缩略图数据 (用于分享预览)
    private func generateThumbnailData(for music: DreamMusic) -> Data? {
        // 生成带有音乐情绪颜色的渐变缩略图
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            
            // 创建渐变背景
            let colors = [
                UIColor(hex: music.mood.color).cgColor,
                UIColor(hex: music.mood.color).withAlphaComponent(0.6).cgColor
            ]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0, 1]) else {
                // Fallback: draw solid color
                UIColor(hex: music.mood.color).setFill()
                context.fill(CGRect(origin: .zero, size: CGSize(width: 400, height: 400)))
                return
            }
            
            context.drawLinearGradient(gradient,
                                      start: CGPoint(x: 0, y: 0),
                                      end: CGPoint(x: 400, y: 400),
                                      options: [])
            
            // 绘制情绪图标
            let icon = UIImage(systemName: music.mood.icon)?.withTintColor(.white, renderingMode: .alwaysOriginal)
            icon?.draw(in: CGRect(x: 150, y: 150, width: 100, height: 100))
        }
        
        return image.jpegData(compressionQuality: 0.8)
    }
    
    /// 生成音乐分享卡片数据
    func generateShareCardData(for music: DreamMusic) -> MusicShareCardData {
        return MusicShareCardData(
            musicId: music.id,
            title: music.title,
            mood: music.mood,
            moodColor: music.mood.color,
            moodIcon: music.mood.icon,
            instruments: music.instruments.map { $0.rawValue },
            duration: formatDuration(music.duration),
            createdAt: music.createdAt,
            dreamContent: getDreamContent(for: music.dreamId)
        )
    }
    
    // MARK: - 睡眠定时器
    
    @Published var sleepTimerDuration: TimeInterval = 0  // 0 = 关闭
    @Published var isSleepTimerActive = false
    @Published var sleepTimerRemaining: TimeInterval = 0
    private var sleepTimer: Timer?
    
    /// 设置睡眠定时器
    func setSleepTimer(duration: TimeInterval) {
        sleepTimer?.invalidate()
        sleepTimerDuration = duration
        sleepTimerRemaining = duration
        
        if duration > 0 {
            isSleepTimerActive = true
            
            sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    if self.sleepTimerRemaining > 0 {
                        self.sleepTimerRemaining -= 1
                    } else {
                        self.stopSleepTimer()
                        self.stop()  // 停止播放
                    }
                }
            }
        } else {
            isSleepTimerActive = false
        }
    }
    
    /// 停止睡眠定时器
    func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        isSleepTimerActive = false
        sleepTimerRemaining = 0
    }
    
    /// 获取常用的睡眠定时选项 (分钟)
    func getSleepTimerOptions() -> [TimeInterval] {
        return [0, 15 * 60, 30 * 60, 45 * 60, 60 * 60, 90 * 60]  // 0, 15m, 30m, 45m, 60m, 90m
    }
    
    /// 格式化睡眠定时剩余时间
    func formatSleepTimerRemaining() -> String {
        let minutes = Int(sleepTimerRemaining) / 60
        let seconds = Int(sleepTimerRemaining) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    // MARK: - 与冥想功能集成
    
    /// 获取推荐的音乐冥想组合
    func getRecommendedMusicForMeditation(meditationType: MeditationType) -> [DreamMusic] {
        let targetMood: DreamMusicMood
        
        switch meditationType {
        case .sleepPreparation:
            targetMood = .peaceful
        case .dreamRecall:
            targetMood = .ethereal
        case .lucidInduction:
            targetMood = .mysterious
        case .relaxation:
            targetMood = .peaceful
        case .morningAnchor:
            targetMood = .joyful
        }
        
        // 返回匹配情绪的音乐
        return musicLibrary.filter { $0.mood == targetMood && $0.tempo == .verySlow || $0.tempo == .slow }
    }
    
    /// 创建冥想播放列表
    func createMeditationPlaylist(type: MeditationType, duration: TimeInterval) async -> [DreamMusic] {
        let recommended = getRecommendedMusicForMeditation(meditationType: type)
        var playlist: [DreamMusic] = []
        var totalDuration: TimeInterval = 0
        
        for music in recommended {
            if totalDuration >= duration {
                break
            }
            playlist.append(music)
            totalDuration += music.duration
        }
        
        return playlist
    }
    
    // MARK: - 辅助方法
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func getDreamContent(for dreamId: UUID) -> String {
        // 从 DreamStore 获取梦境内容
        // 这里简化处理
        return "梦境内容..."
    }
}

// MARK: - 分享相关模型

/// 分享平台
enum MusicSharePlatform: String {
    case wechat = "微信"
    case weibo = "微博"
    case qq = "QQ"
    case telegram = "Telegram"
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case copyLink = "复制链接"
}

/// 分享项目
struct ShareItem {
    let musicId: UUID
    let title: String
    let mood: DreamMusic.DreamMusicMood
    let exportURL: URL
    let shareText: String
}

/// 音乐分享卡片数据
struct MusicShareCardData {
    let musicId: UUID
    let title: String
    let mood: DreamMusic.DreamMusicMood
    let moodColor: String
    let moodIcon: String
    let instruments: [String]
    let duration: String
    let createdAt: Date
    let dreamContent: String
}

/// 音乐分享预览 (用于 ShareLink)
struct MusicSharePreview {
    let title: String
    let subtitle: String
    let mood: DreamMusic.DreamMusicMood
    let instruments: [DreamMusic.DreamMusicInstrument]
    let thumbnailData: Data?
}

/// 冥想类型 (与 MeditationService 集成)
enum MeditationType: String {
    case sleepPreparation = "睡前准备"
    case dreamRecall = "梦境回忆"
    case lucidInduction = "清醒梦诱导"
    case relaxation = "减压放松"
    case morningAnchor = "晨间锚定"
}

// MARK: - 音乐模板

struct MusicTemplate {
    let mood: DreamMusic.DreamMusicMood
    let tempo: DreamMusic.DreamMusicTempo
    let instruments: [DreamMusic.DreamMusicInstrument]
    let baseDuration: Int
}
