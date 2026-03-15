//
//  DreamVoiceJournalService.swift
//  DreamLog
//
//  Phase 51: 梦境语音日记与 AI 摘要 - 核心服务
//

import Foundation
import SwiftData
import AVFoundation
import NaturalLanguage

actor DreamVoiceJournalService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var isRecording = false
    private var currentEntry: VoiceJournalEntry?
    
    private let config: VoiceJournalConfig
    private let fileManager: FileManager
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, config: VoiceJournalConfig = .default) {
        self.modelContext = modelContext
        self.config = config
        self.fileManager = FileManager.default
    }
    
    // MARK: - Recording
    
    /// 开始录音
    func startRecording(title: String = "", dreamId: UUID? = nil) async throws -> VoiceJournalEntry {
        guard !isRecording else {
            throw VoiceJournalError.alreadyRecording
        }
        
        // 创建音频文件 URL
        let audioURL = try createAudioFileURL()
        
        // 录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: config.audioQuality.bitRate
        ]
        
        // 创建录音器
        let recorder = try AVAudioRecorder(url: audioURL, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        
        // 开始录音
        recorder.record()
        audioRecorder = recorder
        isRecording = true
        
        // 创建日记条目
        let entry = VoiceJournalEntry(
            title: title.isEmpty ? "新语音日记" : title,
            audioURL: audioURL,
            isProcessed: false
        )
        
        currentEntry = entry
        modelContext.insert(entry)
        try modelContext.save()
        
        return entry
    }
    
    /// 停止录音
    func stopRecording() async throws -> VoiceJournalEntry? {
        guard isRecording, let recorder = audioRecorder else {
            throw VoiceJournalError.notRecording
        }
        
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        
        guard let entry = currentEntry else {
            throw VoiceJournalError.noEntry
        }
        
        // 更新时长
        entry.duration = recorder.currentTime
        entry.updatedAt = Date()
        
        try modelContext.save()
        
        // 自动处理
        if config.autoTranscribe {
            Task {
                try? await processRecording(entry: entry)
            }
        }
        
        return entry
    }
    
    /// 取消录音
    func cancelRecording() async throws {
        guard isRecording, let recorder = audioRecorder else {
            throw VoiceJournalError.notRecording
        }
        
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        
        // 删除音频文件
        if let entry = currentEntry {
            try? fileManager.removeItem(at: entry.audioURL)
            modelContext.delete(entry)
            try modelContext.save()
        }
        
        currentEntry = nil
    }
    
    // MARK: - Processing
    
    /// 处理录音 (转写 + 摘要 + 情绪分析)
    func processRecording(entry: VoiceJournalEntry) async throws {
        // 转写
        let transcript = try await transcribeAudio(at: entry.audioURL)
        entry.transcript = transcript.text
        entry.keywords = extractKeywords(from: transcript.text)
        
        // 摘要
        let summary = try await generateSummary(from: transcript.text)
        entry.summary = summary.summary
        entry.mood = summary.mood
        
        entry.isProcessed = true
        entry.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 语音转写 (使用 NaturalLanguage 框架模拟)
    func transcribeAudio(at url: URL) async throws -> VoiceTranscript {
        // 在实际实现中，这里会调用语音识别 API
        // 现在使用模拟实现
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 模拟 2 秒处理时间
        
        return VoiceTranscript(
            id: UUID().uuidString,
            text: "这是一个模拟的转写文本。在实际应用中，这里会是真实的语音识别结果。",
            confidence: 0.95,
            language: "zh-CN",
            words: [],
            segments: []
        )
    }
    
    /// 生成摘要
    func generateSummary(from text: String) async throws -> VoiceSummary {
        try await Task.sleep(nanoseconds: 1_500_000_000)  // 模拟 1.5 秒处理时间
        
        // 提取关键词
        let keywords = extractKeywords(from: text)
        
        // 分析情绪
        let mood = analyzeMood(from: text)
        
        // 生成标题
        let title = generateTitle(from: text)
        
        // 生成摘要
        let summary = generateTextSummary(from: text)
        
        return VoiceSummary(
            title: title,
            summary: summary,
            keyPoints: [summary],
            mood: mood,
            keywords: keywords,
            emotionScores: calculateEmotionScores(from: text)
        )
    }
    
    // MARK: - Playback
    
    /// 播放语音日记
    func play(entry: VoiceJournalEntry, speed: Float = 1.0) async throws {
        // 停止当前播放
        audioPlayer?.stop()
        
        // 加载音频
        let player = try AVAudioPlayer(contentsOf: entry.audioURL)
        player.rate = speed
        player.delegate = self
        player.prepareToPlay()
        
        audioPlayer = player
        player.play()
        
        // 更新播放统计
        entry.playCount += 1
        entry.lastPlayedAt = Date()
        entry.playbackSpeed = speed
        try modelContext.save()
    }
    
    /// 暂停播放
    func pause() {
        audioPlayer?.pause()
    }
    
    /// 停止播放
    func stop() {
        audioPlayer?.stop()
    }
    
    /// 跳转到指定时间
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
    }
    
    // MARK: - Query
    
    /// 获取所有语音日记
    func getAllEntries() async throws -> [VoiceJournalEntry] {
        let descriptor = FetchDescriptor<VoiceJournalEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取指定梦境的语音日记
    func getEntries(for dreamId: UUID) async throws -> [VoiceJournalEntry] {
        let descriptor = FetchDescriptor<VoiceJournalEntry>(
            predicate: #Predicate<VoiceJournalEntry> { $0.dreamId == dreamId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 搜索语音日记
    func search(query: String) async throws -> [VoiceJournalEntry] {
        let allEntries = try await getAllEntries()
        
        return allEntries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(query) ||
            (entry.transcript?.localizedCaseInsensitiveContains(query) ?? false) ||
            (entry.summary?.localizedCaseInsensitiveContains(query) ?? false) ||
            entry.keywords.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    /// 获取统计数据
    func getStats() async throws -> VoiceJournalStats {
        let entries = try await getAllEntries()
        
        let totalDuration = entries.reduce(0) { $0 + $1.duration }
        let totalTranscripts = entries.filter { $0.transcript != nil }.count
        let favoriteCount = entries.filter { $0.isFavorite }.count
        
        // 情绪分布
        var moodDistribution: [String: Int] = [:]
        for entry in entries {
            if let mood = entry.mood {
                moodDistribution[mood.rawValue, default: 0] += 1
            }
        }
        
        // 按日期统计
        var entriesByDate: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for entry in entries {
            let dateKey = formatter.string(from: entry.createdAt)
            entriesByDate[dateKey, default: 0] += 1
        }
        
        // 热门关键词
        var keywordCounts: [String: Int] = [:]
        for entry in entries {
            for keyword in entry.keywords {
                keywordCounts[keyword, default: 0] += 1
            }
        }
        let mostUsedKeywords = keywordCounts.sorted { $0.value > $1.value }.prefix(10).map { $0.key }
        
        return VoiceJournalStats(
            totalEntries: entries.count,
            totalDuration: totalDuration,
            totalTranscripts: totalTranscripts,
            averageDuration: entries.isEmpty ? 0 : totalDuration / Double(entries.count),
            moodDistribution: moodDistribution,
            entriesByDate: entriesByDate,
            mostUsedKeywords: mostUsedKeywords,
            favoriteCount: favoriteCount
        )
    }
    
    // MARK: - Management
    
    /// 删除语音日记
    func delete(entry: VoiceJournalEntry) async throws {
        // 删除音频文件
        try? fileManager.removeItem(at: entry.audioURL)
        
        modelContext.delete(entry)
        try modelContext.save()
    }
    
    /// 标记为收藏
    func toggleFavorite(entry: VoiceJournalEntry) async throws {
        entry.isFavorite.toggle()
        entry.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 更新播放速度
    func updatePlaybackSpeed(entry: VoiceJournalEntry, speed: Float) async throws {
        entry.playbackSpeed = speed
        try modelContext.save()
    }
    
    // MARK: - Private Helpers
    
    private func createAudioFileURL() throws -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let voiceFolder = documentsPath.appendingPathComponent("VoiceJournals", isDirectory: true)
        
        // 创建文件夹
        try? fileManager.createDirectory(at: voiceFolder, withIntermediateDirectories: true)
        
        // 生成文件名
        let filename = "voice_\(UUID().uuidString).m4a"
        return voiceFolder.appendingPathComponent(filename)
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var keywords: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag, tag == .personalName || tag == .organizationName || tag == .placeName {
                let word = String(text[range])
                if word.count > 1 {
                    keywords.append(word)
                }
            }
        }
        
        // 添加自定义关键词提取
        let commonDreamWords = ["梦", "飞行", "水", "人", "地方", "感觉", "颜色", "声音"]
        for word in commonDreamWords {
            if text.contains(word) {
                keywords.append(word)
            }
        }
        
        return Array(Set(keywords)).prefix(10).map { String($0) }
    }
    
    private func analyzeMood(from text: String) -> VoiceMood {
        let lowercaseText = text.lowercased()
        
        // 简单的情绪关键词匹配
        if lowercaseText.contains("害怕") || lowercaseText.contains("恐惧") {
            return .fearful
        } else if lowercaseText.contains("开心") || lowercaseText.contains("快乐") {
            return .happy
        } else if lowercaseText.contains("悲伤") || lowercaseText.contains("难过") {
            return .sad
        } else if lowercaseText.contains("兴奋") || lowercaseText.contains("激动") {
            return .excited
        } else if lowercaseText.contains("焦虑") || lowercaseText.contains("紧张") {
            return .anxious
        } else if lowercaseText.contains("平静") || lowercaseText.contains("放松") {
            return .calm
        } else if lowercaseText.contains("困惑") || lowercaseText.contains("迷茫") {
            return .confused
        }
        
        return .neutral
    }
    
    private func generateTitle(from text: String) -> String {
        let words = text.split(separator: " ")
        if words.count >= 5 {
            return String(words.prefix(5).joined(separator: " ")) + "..."
        }
        return text
    }
    
    private func generateTextSummary(from text: String) -> String {
        // 简单摘要：取前 100 个字符
        if text.count > 100 {
            return String(text.prefix(100)) + "..."
        }
        return text
    }
    
    private func calculateEmotionScores(from text: String) -> [String: Double] {
        // 简单的情绪评分
        var scores: [String: Double] = [:]
        let emotions: [(String, [String])] = [
            ("happy", ["开心", "快乐", "高兴", "兴奋"]),
            ("sad", ["悲伤", "难过", "伤心", "哭"]),
            ("anxious", ["焦虑", "紧张", "担心", "害怕"]),
            ("calm", ["平静", "放松", "安静", "平和"])
        ]
        
        for (emotion, keywords) in emotions {
            let count = keywords.filter { text.contains($0) }.count
            scores[emotion] = Double(count) / Double(keywords.count)
        }
        
        return scores
    }
}

// MARK: - AVAudioRecorderDelegate

extension DreamVoiceJournalService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // 录音完成回调
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        // 编码错误回调
    }
}

// MARK: - AVAudioPlayerDelegate

extension DreamVoiceJournalService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 播放完成回调
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        // 解码错误回调
    }
}

// MARK: - Errors

enum VoiceJournalError: LocalizedError {
    case alreadyRecording
    case notRecording
    case noEntry
    case audioUnavailable
    case transcriptionFailed
    case summaryGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .alreadyRecording: return "正在录音中"
        case .notRecording: return "未在录音"
        case .noEntry: return "没有日记条目"
        case .audioUnavailable: return "音频不可用"
        case .transcriptionFailed: return "转写失败"
        case .summaryGenerationFailed: return "摘要生成失败"
        }
    }
}
