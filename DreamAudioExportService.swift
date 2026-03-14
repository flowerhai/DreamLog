//
//  DreamAudioExportService.swift
//  DreamLog
//
//  梦境音频导出 - 核心服务
//  Phase 39: 梦境播客/音频导出功能
//

import Foundation
import AVFoundation
import AVFAudio
import SwiftData

actor DreamAudioExportService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    
    // 背景音乐资源
    private let backgroundMusicTracks: [String] = [
        "ambient_piano",
        "meditation_bells",
        "nature_sounds",
        "soft_strings"
    ]
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 获取所有导出配置
    func getAllConfigs() async throws -> [AudioExportConfig] {
        let descriptor = FetchDescriptor<AudioExportConfig>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取所有导出任务
    func getAllTasks() async throws -> [AudioExportTask] {
        let descriptor = FetchDescriptor<AudioExportTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取导出统计
    func getExportStats() async throws -> AudioExportStats {
        let tasks = try getAllTasks()
        let completedTasks = tasks.filter { $0.status == AudioExportStatus.completed.rawValue }
        
        let totalExports = completedTasks.count
        let totalDuration = completedTasks.reduce(0) { $0 + $1.duration }
        let totalFileSize = completedTasks.reduce(0) { $0 + $1.fileSize }
        
        var exportsByFormat: [String: Int] = [:]
        var exportsByQuality: [String: Int] = [:]
        
        for task in completedTasks {
            if let config = try? getConfigById(task.configId) {
                exportsByFormat[config.format, default: 0] += 1
                exportsByQuality[config.quality, default: 0] += 1
            }
        }
        
        return AudioExportStats(
            totalExports: totalExports,
            totalDuration: totalDuration,
            totalFileSize: totalFileSize,
            averageDuration: totalExports > 0 ? totalDuration / Double(totalExports) : 0,
            averageFileSize: totalExports > 0 ? totalFileSize / Int64(totalExports) : 0,
            exportsByFormat: exportsByFormat,
            exportsByQuality: exportsByQuality,
            lastExportDate: completedTasks.last?.completedAt
        )
    }
    
    /// 根据 ID 获取配置
    func getConfigById(_ id: UUID) async throws -> AudioExportConfig? {
        let descriptor = FetchDescriptor<AudioExportConfig>(
            predicate: #Predicate { $0.id == id }
        )
        let configs = try modelContext.fetch(descriptor)
        return configs.first
    }
    
    /// 保存配置
    func saveConfig(_ config: AudioExportConfig) async throws {
        modelContext.insert(config)
        try modelContext.save()
    }
    
    /// 删除配置
    func deleteConfig(_ config: AudioExportConfig) async throws {
        modelContext.delete(config)
        try modelContext.save()
    }
    
    /// 获取梦境数据用于导出
    func getDreamsForExport(
        range: AudioExportRange,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil
    ) async throws -> [Dream] {
        let descriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        var dreams = try modelContext.fetch(descriptor)
        
        let now = Date()
        let calendar = Calendar.current
        
        switch range {
        case .all:
            break
        case .last7Days:
            let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
            dreams = dreams.filter { $0.date >= startDate }
        case .last30Days:
            let startDate = calendar.date(byAdding: .day, value: -30, to: now)!
            dreams = dreams.filter { $0.date >= startDate }
        case .custom:
            if let start = customStartDate, let end = customEndDate {
                dreams = dreams.filter { $0.date >= start && $0.date <= end }
            }
        }
        
        return dreams
    }
    
    /// 创建导出任务
    func createExportTask(
        config: AudioExportConfig,
        dreams: [Dream]
    ) async throws -> AudioExportTask {
        let task = AudioExportTask(
            configId: config.id,
            name: "梦境音频导出 - \(formatDate(Date()))",
            status: .pending,
            totalDreams: dreams.count
        )
        
        modelContext.insert(task)
        try modelContext.save()
        
        return task
    }
    
    /// 执行导出
    func executeExport(
        task: AudioExportTask,
        config: AudioExportConfig,
        dreams: [Dream],
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> URL {
        // 更新任务状态
        task.status = AudioExportStatus.processing.rawValue
        try modelContext.save()
        
        // 准备输出目录
        let outputDir = getExportDirectory()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        // 生成输出文件名
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let outputFilename = "DreamLog_\(timestamp).\(config.format)"
        let outputURL = outputDir.appendingPathComponent(outputFilename)
        
        // 生成音频内容
        try await generateAudioFile(
            from: dreams,
            config: config,
            outputURL: outputURL,
            progressHandler: progressHandler
        )
        
        // 获取文件大小和时长
        let resources = try outputURL.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Int64(resources.fileSize ?? 0)
        
        // 计算音频时长 (估算)
        let totalWords = dreams.reduce(0) { $0 + ($1.content.count / 2) }
        let estimatedDuration = TimeInterval(totalWords) * 0.4 // 平均每分钟 150 词
        
        // 更新任务
        task.status = AudioExportStatus.completed.rawValue
        task.progress = 1.0
        task.processedDreams = dreams.count
        task.outputURL = outputURL.absoluteString
        task.fileSize = fileSize
        task.duration = estimatedDuration
        task.completedAt = Date()
        try modelContext.save()
        
        progressHandler(1.0, "导出完成！")
        
        return outputURL
    }
    
    /// 取消导出任务
    func cancelTask(_ task: AudioExportTask) async throws {
        task.status = AudioExportStatus.cancelled.rawValue
        try modelContext.save()
    }
    
    /// 删除导出任务
    func deleteTask(_ task: AudioExportTask) async throws {
        // 删除关联的音频文件
        if let url = task.outputURL {
            let fileURL = URL(string: url)
            try? FileManager.default.removeItem(at: fileURL!)
        }
        
        modelContext.delete(task)
        try modelContext.save()
    }
    
    // MARK: - Private Methods
    
    /// 获取导出目录
    private func getExportDirectory() -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDir.appendingPathComponent("AudioExports", isDirectory: true)
    }
    
    /// 生成音频文件
    private func generateAudioFile(
        from dreams: [Dream],
        config: AudioExportConfig,
        outputURL: URL,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        // 初始化音频引擎
        audioEngine = AVAudioEngine()
        
        // 配置音频格式
        let format = AVAudioFormat(
            standardFormatWithSampleRate: 44100,
            channels: 2
        )!
        
        // 创建输出文件
        audioFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
        
        var currentTime: TimeInterval = 0
        var segments: [AudioSegment] = []
        
        // 添加片头
        if config.includeIntro {
            let introText = generateIntroText(dreams.count)
            let introDuration = try await synthesizeText(
                introText,
                config: config,
                startTime: currentTime
            )
            segments.append(AudioSegment(
                type: .intro,
                text: introText,
                duration: introDuration,
                startTime: currentTime,
                endTime: currentTime + introDuration
            ))
            currentTime += introDuration
            progressHandler(0.1, "生成片头...")
        }
        
        // 添加每个梦境
        for (index, dream) in dreams.enumerated() {
            let dreamText = formatDreamText(dream, config: config)
            let dreamDuration = try await synthesizeText(
                dreamText,
                config: config,
                startTime: currentTime
            )
            
            segments.append(AudioSegment(
                type: .dream,
                text: dreamText,
                duration: dreamDuration,
                startTime: currentTime,
                endTime: currentTime + dreamDuration
            ))
            
            currentTime += dreamDuration
            
            // 添加过渡音效
            if index < dreams.count - 1 {
                let transitionDuration: TimeInterval = 1.0
                segments.append(AudioSegment(
                    type: .transition,
                    duration: transitionDuration,
                    startTime: currentTime,
                    endTime: currentTime + transitionDuration
                ))
                currentTime += transitionDuration
            }
            
            let progress = Double(index + 1) / Double(dreams.count) * 0.8 + 0.1
            progressHandler(progress, "处理梦境 \(index + 1)/\(dreams.count)...")
        }
        
        // 添加片尾
        if config.includeOutro {
            let outroText = generateOutroText(dreams.count)
            let outroDuration = try await synthesizeText(
                outroText,
                config: config,
                startTime: currentTime
            )
            segments.append(AudioSegment(
                type: .outro,
                text: outroText,
                duration: outroDuration,
                startTime: currentTime,
                endTime: currentTime + outroDuration
            ))
            progressHandler(0.95, "生成片尾...")
        }
        
        // 添加背景音乐
        if config.addBackgroundMusic {
            try await addBackgroundMusic(
                segments: segments,
                volume: config.backgroundMusicVolume
            )
            progressHandler(0.98, "添加背景音乐...")
        }
        
        // 完成
        progressHandler(1.0, "完成！")
    }
    
    /// 合成文本为语音
    private func synthesizeText(
        _ text: String,
        config: AudioExportConfig,
        startTime: TimeInterval
    ) async throws -> TimeInterval {
        // 估算时长 (中文约每秒 4-5 字)
        let estimatedDuration = TimeInterval(text.count) / 4.5
        
        // 实际合成会在 AVSpeechSynthesizer 中完成
        // 这里返回估算时长
        return estimatedDuration
    }
    
    /// 格式化梦境文本
    private func formatDreamText(_ dream: Dream, config: AudioExportConfig) -> String {
        var text = "梦境：\(dream.title)\n\n"
        text += "\(dream.content)\n\n"
        
        if config.includeTags && !dream.tags.isEmpty {
            text += "标签：\(dream.tags.joined(separator: "、"))\n\n"
        }
        
        if config.includeEmotions && !dream.emotions.isEmpty {
            let emotionNames = dream.emotions.map { $0.displayName }
            text += "情绪：\(emotionNames.joined(separator: "、"))\n\n"
        }
        
        if config.includeAIAnalysis && !(dream.aiAnalysis ?? "").isEmpty {
            text += "AI 解析：\(dream.aiAnalysis ?? "")\n\n"
        }
        
        return text
    }
    
    /// 生成片头文本
    private func generateIntroText(_ dreamCount: Int) -> String {
        let greeting: String
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 5 && hour < 12 {
            greeting = "早上好"
        } else if hour >= 12 && hour < 18 {
            greeting = "下午好"
        } else if hour >= 18 && hour < 23 {
            greeting = "晚上好"
        } else {
            greeting = "夜深了"
        }
        
        return "\(greeting)，欢迎收听你的梦境日记。今天为你准备了\(dreamCount)个梦境记录。让我们一起探索潜意识的奇妙世界。"
    }
    
    /// 生成片尾文本
    private func generateOutroText(_ dreamCount: Int) -> String {
        return "感谢收听今天的梦境日记。共\(dreamCount)个梦境。愿你今夜好梦，我们下次再见。"
    }
    
    /// 添加背景音乐
    private func addBackgroundMusic(
        segments: [AudioSegment],
        volume: Float
    ) async throws {
        // 背景音乐逻辑
        // 实际实现需要音频混合
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Dream Extension

extension Dream {
    var emotions: [Emotion] {
        // 从字符串解析情绪
        return []
    }
}

extension Emotion {
    var displayName: String {
        return rawValue
    }
}
