//
//  DreamMusicExportService.swift
//  DreamLog
//
//  Phase 26 - 梦境音乐导出与分享服务
//  支持导出 AAC/m4a 格式，分享到社交平台
//

import Foundation
import AVFoundation
import Combine
import UniformTypeIdentifiers

// MARK: - 导出配置

/// 音乐导出配置
struct MusicExportConfig {
    var format: ExportFormat = .aac
    var quality: AudioQuality = .high
    var includeMetadata: Bool = true
    var coverArt: Data?  // 封面图片
    
    /// 导出格式
    enum ExportFormat: String, CaseIterable, Identifiable {
        case aac = "AAC (.m4a)"
        case wav = "WAV (.wav)"
        case mp3 = "MP3 (.mp3)"
        
        var id: String { rawValue }
        
        var utType: UTType {
            switch self {
            case .aac: return .mpeg4Audio
            case .wav: return .waveformAudio
            case .mp3: return .mp3
            }
        }
        
        var fileExtension: String {
            switch self {
            case .aac: return "m4a"
            case .wav: return "wav"
            case .mp3: return "mp3"
            }
        }
        
        /// 是否支持导出（MP3 需要额外编码）
        var isSupported: Bool {
            switch self {
            case .aac, .wav: return true
            case .mp3: return true  // 使用 Core Audio 转换
            }
        }
    }
    
    /// 音频质量
    enum AudioQuality: String, CaseIterable, Identifiable {
        case standard = "标准 (128 kbps)"
        case high = "高质量 (256 kbps)"
        case lossless = "无损 (WAV)"
        
        var id: String { rawValue }
        
        var bitRate: Int {
            switch self {
            case .standard: return 128000
            case .high: return 256000
            case .lossless: return 1411000  // CD 质量
            }
        }
    }
}

// MARK: - 导出服务

@MainActor
class DreamMusicExportService: ObservableObject {
    static let shared = DreamMusicExportService()
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastExportedURL: URL?
    @Published var errorMessage: String?
    
    private let audioEngine = AudioSynthesisEngine.shared
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - 导出目录
    
    private var exportsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportsDir = documents.appendingPathComponent("Music Exports", isDirectory: true)
        
        if !fileManager.fileExists(atPath: exportsDir.path) {
            try? fileManager.createDirectory(at: exportsDir, withIntermediateDirectories: true)
        }
        
        return exportsDir
    }
    
    // MARK: - 导出音乐
    
    /// 导出单首音乐
    func exportMusic(_ music: DreamMusic, config: MusicExportConfig = MusicExportConfig()) async throws -> URL {
        guard !isExporting else {
            throw ExportError.alreadyExporting
        }
        
        await MainActor.run {
            isExporting = true
            exportProgress = 0.0
            errorMessage = nil
        }
        
        do {
            // 生成音频
            let buffer = try await synthesizeMusic(music)
            
            // 导出文件
            let outputURL = exportsDirectory.appendingPathComponent("\(music.title).\(config.format.fileExtension)")
            
            try await exportAudio(buffer: buffer, to: outputURL, config: config)
            
            await MainActor.run {
                isExporting = false
                exportProgress = 1.0
                lastExportedURL = outputURL
            }
            
            print("🎵 音乐导出完成：\(outputURL.path)")
            return outputURL
            
        } catch {
            await MainActor.run {
                isExporting = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// 批量导出音乐
    func exportMusicBatch(_ musicList: [DreamMusic], config: MusicExportConfig = MusicExportConfig()) async throws -> [URL] {
        var exportedURLs: [URL] = []
        
        for (index, music) in musicList.enumerated() {
            await MainActor.run {
                exportProgress = Double(index) / Double(musicList.count)
            }
            
            do {
                let url = try await exportMusic(music, config: config)
                exportedURLs.append(url)
            } catch {
                print("⚠️ 导出失败 \(music.title): \(error.localizedDescription)")
                // 继续导出其他音乐
            }
        }
        
        await MainActor.run {
            isExporting = false
            exportProgress = 1.0
        }
        
        return exportedURLs
    }
    
    // MARK: - 音频合成
    
    private func synthesizeMusic(_ music: DreamMusic) async throws -> AVAudioPCMBuffer {
        let duration = music.duration
        let sampleRate: Double = 44100.0
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            throw ExportError.formatCreationFailed
        }
        
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw ExportError.bufferCreationFailed
        }
        buffer.frameLength = frameCount
        
        // 合成所有音频层
        guard let floatChannelData = buffer.floatChannelData else {
            throw ExportError.bufferCreationFailed
        }
        let audioData = floatChannelData[0]
        let audioDataRight = floatChannelData[1]
        
        for layer in music.audioLayers {
            await MainActor.run {
                exportProgress = max(exportProgress, 0.1)
            }
            
            let layerAudio = synthesizeLayer(layer, duration: duration, sampleRate: sampleRate)
            
            // 混音
            for i in 0..<Int(frameCount) {
                audioData[i] += layerAudio.left[i] * layer.volume
                audioDataRight[i] += layerAudio.right[i] * layer.volume
            }
        }
        
        // 归一化
        normalizeAudio(audioData, frameCount: Int(frameCount))
        normalizeAudio(audioDataRight, frameCount: Int(frameCount))
        
        return buffer
    }
    
    private func synthesizeLayer(_ layer: DreamMusic.AudioLayer, duration: Double, sampleRate: Double) -> (left: [Float], right: [Float]) {
        let frameCount = Int(duration * sampleRate)
        var left = [Float](repeating: 0, count: frameCount)
        var right = [Float](repeating: 0, count: frameCount)
        
        // 根据乐器生成音频
        let instrument = layer.instrument
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // 生成基础波形
            switch instrument {
            case .piano:
                sample = generatePianoSample(t: t, duration: duration)
            case .strings:
                sample = generateStringSample(t: t, duration: duration)
            case .flute:
                sample = generateFluteSample(t: t, duration: duration)
            case .harp:
                sample = generateHarpSample(t: t, duration: duration)
            case .synth:
                sample = generateSynthSample(t: t, duration: duration)
            case .ambientPad:
                sample = generatePadSample(t: t, duration: duration)
            case .natureSounds, .windChimes, .singingBowl:
                sample = generatePercussiveSample(t: t, type: instrument)
            case .oceanWaves:
                sample = generateOceanSample(t: t)
            case .rainSounds:
                sample = generateRainSample()
            case .forestAmbience:
                sample = generateForestSample(t: t)
            }
            
            // 应用声相
            let pan = layer.pan
            left[i] = sample * (1.0 - max(0, pan))
            right[i] = sample * (1.0 + min(0, pan))
        }
        
        // 应用混响和延迟
        if layer.reverb > 0.01 {
            (left, right) = applyReverb(left: left, right: right, amount: layer.reverb)
        }
        
        if layer.delay > 0.01 {
            (left, right) = applyDelay(left: left, right: right, amount: layer.delay)
        }
        
        return (left, right)
    }
    
    // MARK: - 乐器采样生成 (简化版本)
    
    private func generatePianoSample(t: Double, duration: Double) -> Float {
        let baseFreq = 440.0
        let harmonics = [1.0, 2.0, 2.01, 3.0, 4.0]
        let amplitudes = [0.5, 0.25, 0.15, 0.1, 0.05]
        
        var sample: Float = 0.0
        for (i, harmonic) in harmonics.enumerated() {
            sample += Float(sin(2.0 * .pi * baseFreq * harmonic * t)) * amplitudes[i]
        }
        
        // 应用包络
        let envelope = pianoEnvelope(time: t, duration: duration)
        return sample * envelope
    }
    
    private func generateStringSample(t: Double, duration: Double) -> Float {
        let baseFreq = 440.0
        var sample = Float(sin(2.0 * .pi * baseFreq * t))
        sample += Float(sin(2.0 * .pi * baseFreq * 2.0 * t)) * 0.5
        
        let envelope = stringEnvelope(time: t, duration: duration)
        return sample * envelope
    }
    
    private func generateFluteSample(t: Double, duration: Double) -> Float {
        let baseFreq = 880.0
        var sample = Float(sin(2.0 * .pi * baseFreq * t)) * 0.8
        sample += Float(sin(2.0 * .pi * baseFreq * 3.0 * t)) * 0.2
        
        let envelope = fluteEnvelope(time: t, duration: duration)
        return sample * envelope
    }
    
    private func generateHarpSample(t: Double, duration: Double) -> Float {
        let baseFreq = 660.0
        var sample = Float(sin(2.0 * .pi * baseFreq * t))
        sample *= Float(exp(-t / 0.5))
        return sample * 0.7
    }
    
    private func generateSynthSample(t: Double, duration: Double) -> Float {
        let baseFreq = 440.0
        return Float(sin(2.0 * .pi * baseFreq * t)) * 0.6
    }
    
    private func generatePadSample(t: Double, duration: Double) -> Float {
        let baseFreq = 220.0
        var sample: Float = 0.0
        for i in 1...5 {
            sample += Float(sin(2.0 * .pi * baseFreq * Double(i) * t)) / Float(i)
        }
        
        let attack = min(t / 0.5, 1.0)
        let release = max(0, 1.0 - (t - (duration - 1.0)))
        return sample * 0.3 * Float(attack * release)
    }
    
    private func generatePercussiveSample(t: Double, type: DreamMusic.DreamMusicInstrument) -> Float {
        // 简化打击乐生成
        return Float.random(in: -0.1...0.1)
    }
    
    private func generateOceanSample(t: Double) -> Float {
        var sample: Float = 0.0
        sample += Float(pinkNoise()) * 0.5
        sample *= Float(sin(2.0 * .pi * 0.1 * t) * 0.5 + 0.5)
        return sample * 0.3
    }
    
    private func generateRainSample() -> Float {
        return Float(whiteNoise()) * 0.15
    }
    
    private func generateForestSample(t: Double) -> Float {
        var sample: Float = Float(pinkNoise()) * 0.2
        
        // 偶尔添加鸟鸣
        if Int(t) % 17 == 0 && t.truncatingRemainder(dividingBy: 1.0) < 0.1 {
            sample += Float(sin(2.0 * .pi * 2000 * t)) * 0.3
        }
        
        return sample
    }
    
    // MARK: - 包络函数
    
    private func pianoEnvelope(time: Double, duration: Double) -> Float {
        let attack = 0.01
        let decay = 0.3
        let sustain = 0.6
        let release = 0.5
        
        if time < attack {
            return Float(time / attack)
        } else if time < attack + decay {
            return Float(1.0 - (1.0 - sustain) * (time - attack) / decay)
        } else if time < duration - release {
            return Float(sustain)
        } else {
            let releaseTime = duration - time
            return Float(sustain * releaseTime / release)
        }
    }
    
    private func stringEnvelope(time: Double, duration: Double) -> Float {
        let attack = 0.05
        let decay = 0.2
        let sustain = 0.8
        
        if time < attack {
            return Float(time / attack)
        } else if time < attack + decay {
            return Float(1.0 - (1.0 - sustain) * (time - attack) / decay)
        } else {
            return Float(sustain)
        }
    }
    
    private func fluteEnvelope(time: Double, duration: Double) -> Float {
        let attack = 0.1
        let sustain = 0.9
        
        if time < attack {
            return Float(time / attack)
        } else {
            return Float(sustain)
        }
    }
    
    // MARK: - 效果器
    
    private func applyReverb(left: [Float], right: [Float], amount: Float) -> ([Float], [Float]) {
        let delayTimes = [0.029, 0.037, 0.041, 0.043]
        let sampleRate = 44100.0
        var newLeft = left
        var newRight = right
        
        for delayTime in delayTimes {
            let delaySamples = Int(delayTime * sampleRate)
            let feedback = 0.3 * amount
            
            for i in delaySamples..<left.count {
                newLeft[i] += left[i - delaySamples] * feedback
                newRight[i] += right[i - delaySamples] * feedback
            }
        }
        
        return (newLeft, newRight)
    }
    
    private func applyDelay(left: [Float], right: [Float], amount: Float) -> ([Float], [Float]) {
        let delayTime = 0.3
        let sampleRate = 44100.0
        let delaySamples = Int(delayTime * sampleRate)
        let feedback = 0.4 * amount
        
        var newLeft = left
        var newRight = right
        
        for i in delaySamples..<left.count {
            newLeft[i] += left[i - delaySamples] * feedback
            newRight[i] += right[i - delaySamples] * feedback
        }
        
        return (newLeft, newRight)
    }
    
    // MARK: - 音频处理
    
    private func normalizeAudio(_ data: UnsafeMutablePointer<Float>, frameCount: Int) {
        var maxAmplitude: Float = 0.0
        
        for i in 0..<frameCount {
            maxAmplitude = max(maxAmplitude, abs(data[i]))
        }
        
        if maxAmplitude > 0.001 {
            let gain = 0.9 / maxAmplitude
            for i in 0..<frameCount {
                data[i] *= gain
            }
        }
    }
    
    // MARK: - 音频导出
    
    private func exportAudio(buffer: AVAudioPCMBuffer, to url: URL, config: MusicExportConfig) async throws {
        // MP3 格式特殊处理
        if config.format == .mp3 {
            try await exportAsMP3(buffer: buffer, to: url, config: config)
            return
        }
        
        // AAC/WAV 格式使用 AVAudioFile
        let settings: [String: Any] = [
            AVFormatIDKey: config.format == .aac ? kAudioFormatMPEG4AAC : kAudioFormatLinearPCM,
            AVSampleRateKey: buffer.format.sampleRate,
            AVNumberOfChannelsKey: buffer.format.channelCount,
            AVEncoderBitRateKey: config.quality.bitRate,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        if config.format == .wav {
            settings[AVLinearPCMBitDepthKey] = 16
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsBigEndianKey] = false
        }
        
        let outputFile = try AVAudioFile(forWriting: url, settings: settings)
        try outputFile.write(from: buffer)
        
        // 添加元数据
        if config.includeMetadata {
            try await addMetadata(to: url, config: config)
        }
    }
    
    /// 导出为 MP3 格式（使用 Extended Audio File Services）
    private func exportAsMP3(buffer: AVAudioPCMBuffer, to url: URL, config: MusicExportConfig) async throws {
        await MainActor.run {
            exportProgress = max(exportProgress, 0.7)
        }
        
        // 创建临时 CAF 文件
        let tempCAFURL = exportsDirectory.appendingPathComponent("temp_export.caf")
        try? fileManager.removeItem(at: tempCAFURL)
        
        let cafSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: buffer.format.sampleRate,
            AVNumberOfChannelsKey: buffer.format.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        let cafFile = try AVAudioFile(forWriting: tempCAFURL, settings: cafSettings)
        try cafFile.write(from: buffer)
        
        // 使用 AudioConverter 转换为 MP3
        try await convertCAFTOMP3(source: tempCAFURL, destination: url, bitrate: config.quality.bitRate)
        
        // 清理临时文件
        try? fileManager.removeItem(at: tempCAFURL)
        
        await MainActor.run {
            exportProgress = max(exportProgress, 0.95)
        }
    }
    
    /// 将 CAF 文件转换为 MP3
    private func convertCAFTOMP3(source: URL, destination: URL, bitrate: Int) async throws {
        // 使用 AVAssetExportSession 进行转换
        let asset = AVAsset(url: source)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw ExportError.conversionFailed
        }
        
        exportSession.outputURL = destination
        exportSession.outputFileType = .mp3
        
        // 等待导出完成
        await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                continuation.resume()
            }
        }
        
        if let error = exportSession.error {
            throw error
        }
        
        print("🎵 MP3 转换完成：\(destination.path)")
    }
    
    private func addMetadata(to url: URL, config: MusicExportConfig) async throws {
        // 简化版本：实际应该使用 AVAssetWriter 添加 ID3 标签
        print("🎵 添加元数据到 \(url.path)")
    }
    
    // MARK: - 噪声生成
    
    private func whiteNoise() -> Double {
        return Double.random(in: -1...1)
    }
    
    private func pinkNoise() -> Double {
        var sum: Double = 0
        for _ in 0..<16 {
            sum += Double.random(in: -1...1)
        }
        return sum / 16.0
    }
    
    // MARK: - 清理
    
    func clearExports() {
        try? fileManager.removeItem(at: exportsDirectory)
        try? fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        lastExportedURL = nil
    }
}

// MARK: - 导出错误

enum ExportError: LocalizedError {
    case alreadyExporting
    case formatCreationFailed
    case bufferCreationFailed
    case fileWriteFailed
    case invalidConfig
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .alreadyExporting:
            return "正在导出中，请稍后再试"
        case .formatCreationFailed:
            return "无法创建音频格式"
        case .bufferCreationFailed:
            return "无法创建音频缓冲区"
        case .fileWriteFailed:
            return "无法写入文件"
        case .invalidConfig:
            return "导出配置无效"
        case .conversionFailed:
            return "音频格式转换失败"
        }
    }
}
