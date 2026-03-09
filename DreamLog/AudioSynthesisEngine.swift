//
//  AudioSynthesisEngine.swift
//  DreamLog
//
//  Phase 10 - 真实音频合成引擎
//  使用 AVAudioEngine 实现梦境音乐的实时音频合成和导出
//

import Foundation
import AVFoundation
import Accelerate

// MARK: - 音频合成引擎

/// 真实音频合成引擎
/// 使用 AVAudioEngine 和 AudioKit 风格的合成器生成梦境音乐
class AudioSynthesisEngine {
    static let shared = AudioSynthesisEngine()
    
    private var audioEngine: AVAudioEngine?
    private var mainMixer: AVAudioMixerNode?
    private var reverbBus: AVAudioAuxiliaryBus?
    private var delayBus: AVAudioAuxiliaryBus?
    
    // 音频合成器节点
    private var activeNodes: [AVAudioNode] = []
    
    // 音频样本缓存
    private var sampleCache: [String: AVAudioPCMBuffer] = [:]
    
    // 导出状态
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    
    private init() {
        setupAudioEngine()
    }
    
    // MARK: - 引擎设置
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        mainMixer = audioEngine?.mainMixerNode
        
        // 设置主混音器
        mainMixer?.outputVolume = 1.0
        
        // 准备引擎
        let outputFormat = audioEngine?.outputNode.outputFormat(forBus: 0)
        audioEngine?.prepare()
        
        print("🎵 AudioSynthesisEngine 初始化完成")
    }
    
    // MARK: - 音频层合成
    
    /// 合成单个音频层
    /// - Parameters:
    ///   - layer: 音频层配置
    ///   - duration: 持续时间 (秒)
    ///   - sampleRate: 采样率
    /// - Returns: 合成的音频缓冲区
    func synthesizeAudioLayer(_ layer: DreamMusic.AudioLayer, duration: Double, sampleRate: Double = 44100) -> AVAudioPCMBuffer? {
        guard let engine = audioEngine else { return nil }
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            return nil
        }
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        
        // 根据乐器类型生成音频
        let audioData = generateAudioForInstrument(
            layer.instrument,
            duration: duration,
            sampleRate: sampleRate,
            volume: layer.volume,
            pan: layer.pan,
            reverb: layer.reverb,
            delay: layer.delay
        )
        
        // 将音频数据写入缓冲区
        if let floatChannelData = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                memcpy(floatChannelData[channel], audioData, Int(frameCount) * MemoryLayout<Float>.stride)
            }
        }
        
        return buffer
    }
    
    /// 为乐器生成音频数据
    private func generateAudioForInstrument(
        _ instrument: DreamMusic.DreamMusicInstrument,
        duration: Double,
        sampleRate: Double,
        volume: Float,
        pan: Float,
        reverb: Float,
        delay: Float
    ) -> UnsafeMutablePointer<Float> {
        let frameCount = Int(duration * sampleRate)
        let audioData = UnsafeMutablePointer<Float>.allocate(capacity: frameCount)
        
        // 生成基础波形
        switch instrument {
        case .piano:
            generatePianoSound(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .strings:
            generateStringSound(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .flute:
            generateFluteSound(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .harp:
            generateHarpSound(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .synth:
            generateSynthSound(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .ambientPad:
            generateAmbientPadSound(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .natureSounds, .windChimes, .singingBowl:
            generatePercussiveSound(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume, type: instrument)
        case .oceanWaves:
            generateOceanWaves(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .rainSounds:
            generateRainSounds(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        case .forestAmbience:
            generateForestAmbience(audioData, frameCount: frameCount, sampleRate: sampleRate, volume: volume)
        }
        
        // 应用效果器
        applyEffects(audioData, frameCount: frameCount, reverb: reverb, delay: delay, pan: pan)
        
        return audioData
    }
    
    // MARK: - 乐器合成
    
    /// 生成钢琴声音
    private func generatePianoSound(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        // 使用加法合成生成钢琴音色
        let baseFrequency: Double = 440.0  // A4
        let harmonics = [1.0, 2.0, 2.01, 3.0, 4.0, 4.02, 5.0, 6.0]  // 钢琴谐波
        let harmonicAmplitudes = [0.5, 0.25, 0.15, 0.1, 0.05, 0.03, 0.02, 0.01]
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // 叠加谐波
            for (index, harmonic) in harmonics.enumerated() {
                let freq = baseFrequency * harmonic
                let amplitude = harmonicAmplitudes[index] * volume
                sample += sin(2.0 * .pi * freq * t) * amplitude
            }
            
            // 应用包络 (ADSR)
            let envelope = pianoEnvelope(time: t, duration: Double(frameCount) / sampleRate)
            sample *= envelope
            
            // 添加轻微失谐
            sample += sin(2.0 * .pi * baseFrequency * 1.001 * t) * volume * 0.05
            
            data[i] = sample
        }
    }
    
    /// 生成弦乐声音
    private func generateStringSound(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        let baseFrequency: Double = 440.0
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // 多个振荡器模拟弦乐群
            for detune in [-0.005, 0.0, 0.005] {
                sample += sin(2.0 * .pi * baseFrequency * (1 + detune) * t)
            }
            
            // 弦乐包络
            let envelope = stringEnvelope(time: t, duration: Double(frameCount) / sampleRate)
            sample *= envelope * volume
            
            data[i] = sample / 3.0
        }
    }
    
    /// 生成笛子声音
    private func generateFluteSound(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        let baseFrequency: Double = 523.25  // C5
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // 长笛主要是基频和少量谐波
            sample = sin(2.0 * .pi * baseFrequency * t) * 0.8
            sample += sin(2.0 * .pi * baseFrequency * 2 * t) * 0.2
            
            let envelope = fluteEnvelope(time: t, duration: Double(frameCount) / sampleRate)
            sample *= envelope * volume
            
            data[i] = sample
        }
    }
    
    /// 生成竖琴声音
    private func generateHarpSound(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        let baseFrequency: Double = 392.0  // G4
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // 竖琴的拨弦音色
            sample = sin(2.0 * .pi * baseFrequency * t) * 0.6
            sample += sin(2.0 * .pi * baseFrequency * 3 * t) * 0.3
            sample += sin(2.0 * .pi * baseFrequency * 5 * t) * 0.1
            
            let envelope = harpEnvelope(time: t, duration: Double(frameCount) / sampleRate)
            sample *= envelope * volume
            
            data[i] = sample
        }
    }
    
    /// 生成合成器声音
    private func generateSynthSound(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        let baseFrequency: Double = 220.0  // A3
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // 锯齿波
            sample = sawtooth(frequency: baseFrequency, time: t)
            
            // 添加滤波器效果
            sample *= sin(2.0 * .pi * baseFrequency * 0.5 * t)
            
            let envelope = synthEnvelope(time: t, duration: Double(frameCount) / sampleRate)
            sample *= envelope * volume
            
            data[i] = sample * 0.5
        }
    }
    
    /// 生成氛围 Pad 声音
    private func generateAmbientPadSound(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        let baseFrequency: Double = 110.0  // A2
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            // 多个正弦波叠加
            for freq in [baseFrequency, baseFrequency * 1.5, baseFrequency * 2] {
                sample += sin(2.0 * .pi * freq * t) * 0.3
            }
            
            // 低频调制
            sample *= sin(2.0 * .pi * 0.5 * t) * 0.1 + 0.9
            
            let envelope = padEnvelope(time: t, duration: Double(frameCount) / sampleRate)
            sample *= envelope * volume
            
            data[i] = sample
        }
    }
    
    /// 生成打击乐/效果音
    private func generatePercussiveSound(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float, type: DreamMusic.DreamMusicInstrument) {
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            
            switch type {
            case .singingBowl:
                // 颂钵 - 正弦波 + 长衰减
                let freq = 432.0  // 432Hz 疗愈频率
                sample = sin(2.0 * .pi * freq * t) * exp(-t * 0.5)
                sample += sin(2.0 * .pi * freq * 2 * t) * exp(-t * 0.3) * 0.5
            case .windChimes:
                // 风铃 - 高频随机叮当声
                let bellFreq = 880.0 + Double.random(in: -50...50)
                let bellEnvelope = exp(-t * 3.0)
                sample = sin(2.0 * .pi * bellFreq * t) * bellEnvelope
            case .natureSounds:
                // 自然音效 - 粉红噪声
                sample = pinkNoise() * exp(-t * 2.0)
            default:
                sample = 0
            }
            
            data[i] = sample * volume
        }
    }
    
    /// 生成海浪声
    private func generateOceanWaves(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            // 多层噪声模拟海浪
            var sample: Float = 0.0
            sample += pinkNoise() * 0.5
            sample += brownNoise() * 0.3
            // 波浪调制
            sample *= sin(2.0 * .pi * 0.1 * t) * 0.5 + 0.5
            data[i] = sample * volume
        }
    }
    
    /// 生成雨声
    private func generateRainSounds(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        for i in 0..<frameCount {
            // 白噪声 + 高通滤波模拟雨声
            data[i] = whiteNoise() * volume * 0.3
        }
    }
    
    /// 生成森林氛围
    private func generateForestAmbience(_ data: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double, volume: Float) {
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0.0
            // 粉红噪声作为基础
            sample += pinkNoise() * 0.2
            // 偶尔添加鸟鸣 (简化为高频短音)
            if Int(t * 10) % 17 == 0 && t.truncatingRemainder(dividingBy: 1.0) < 0.1 {
                sample += sin(2.0 * .pi * 2000 * t) * exp(-(t.truncatingRemainder(dividingBy: 1.0)) * 10) * 0.3
            }
            data[i] = sample * volume
        }
    }
    
    // MARK: - 效果器
    
    /// 应用效果器 (混响、延迟、声相)
    private func applyEffects(_ data: UnsafeMutablePointer<Float>, frameCount: Int, reverb: Float, delay: Float, pan: Float) {
        // 简单的混响效果 (使用多个延迟模拟)
        if reverb > 0.01 {
            applyReverb(data, frameCount: frameCount, amount: reverb)
        }
        
        // 延迟效果
        if delay > 0.01 {
            applyDelay(data, frameCount: frameCount, amount: delay)
        }
        
        // 声相 (简化处理，实际应该分别处理左右声道)
        if pan != 0 {
            applyPan(data, frameCount: frameCount, pan: pan)
        }
    }
    
    private func applyReverb(_ data: UnsafeMutablePointer<Float>, frameCount: Int, amount: Float) {
        // 简单的混响实现 (多个梳状滤波器)
        let delayTimes = [0.029, 0.037, 0.041, 0.043]  // 秒
        let sampleRate = 44100.0
        
        for (index, delayTime) in delayTimes.enumerated() {
            let delaySamples = Int(delayTime * sampleRate)
            let feedback = 0.3 * amount
            
            for i in delaySamples..<frameCount {
                data[i] += data[i - delaySamples] * feedback * (1.0 - Float(index) * 0.2)
            }
        }
    }
    
    private func applyDelay(_ data: UnsafeMutablePointer<Float>, frameCount: Int, amount: Float) {
        let delayTime = 0.3  // 300ms
        let sampleRate = 44100.0
        let delaySamples = Int(delayTime * sampleRate)
        let feedback = 0.4 * amount
        
        for i in delaySamples..<frameCount {
            data[i] += data[i - delaySamples] * feedback
        }
    }
    
    private func applyPan(_ data: UnsafeMutablePointer<Float>, frameCount: Int, pan: Float) {
        // 简化处理：调整整体音量模拟声相
        let panGain = 1.0 - abs(pan) * 0.2
        for i in 0..<frameCount {
            data[i] *= panGain
        }
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
    
    private func harpEnvelope(time: Double, duration: Double) -> Float {
        let attack = 0.005
        let decay = 0.5
        
        if time < attack {
            return Float(time / attack)
        } else {
            return Float(exp(-time / decay))
        }
    }
    
    private func synthEnvelope(time: Double, duration: Double) -> Float {
        let attack = 0.02
        let sustain = 0.7
        
        if time < attack {
            return Float(time / attack)
        } else {
            return Float(sustain)
        }
    }
    
    private func padEnvelope(time: Double, duration: Double) -> Float {
        let attack = 0.5
        let release = 1.0
        
        if time < attack {
            return Float(time / attack)
        } else if time < duration - release {
            return 1.0
        } else {
            let releaseTime = duration - time
            return Float(releaseTime / release)
        }
    }
    
    // MARK: - 噪声生成
    
    private func whiteNoise() -> Float {
        return Float.random(in: -1...1)
    }
    
    private func pinkNoise() -> Float {
        // 简化粉红噪声生成
        var sum: Float = 0
        for _ in 0..<16 {
            sum += Float.random(in: -1...1)
        }
        return sum / 16.0
    }
    
    private func brownNoise() -> Float {
        // 简化布朗噪声生成
        var lastOut: Float = 0
        let white = whiteNoise()
        lastOut = (lastOut + (0.02 * white)) / 1.02
        return lastOut * 3.5
    }
    
    private func sawtooth(frequency: Double, time: Double) -> Float {
        return 2.0 * Float((frequency * time).truncatingRemainder(dividingBy: 1.0)) - 1.0
    }
    
    // MARK: - 音频导出
    
    /// 将音频缓冲区导出为 AAC/m4a 文件
    func exportToAAC(buffer: AVAudioPCMBuffer, to url: URL, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(false, NSError(domain: "AudioSynthesisEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Engine not available"]))
                return
            }
            
            do {
                self.isExporting = true
                self.exportProgress = 0.0
                
                // 创建音频文件
                try self.writePCMBufferToAAC(buffer: buffer, to: url)
                
                await MainActor.run {
                    self.isExporting = false
                    self.exportProgress = 1.0
                }
                
                completion(true, nil)
                
            } catch {
                await MainActor.run {
                    self.isExporting = false
                }
                completion(false, error)
            }
        }
    }
    
    /// 将 PCM 缓冲区写入 AAC 文件
    private func writePCMBufferToAAC(buffer: AVAudioPCMBuffer, to url: URL) throws {
        // 使用 AVAudioFile 写入
        let outputFile = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: buffer.format.sampleRate,
            AVNumberOfChannelsKey: buffer.format.channelCount,
            AVEncoderBitRateKey: 256000,  // 256 kbps
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])
        
        // 写入音频数据
        try outputFile.write(from: buffer)
    }
    
    // MARK: - 清理
    
    func cleanup() {
        audioEngine?.stop()
        activeNodes.forEach { $0.removeFromEngine() }
        activeNodes.removeAll()
        sampleCache.removeAll()
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - 音乐模板

struct MusicTemplate {
    let mood: DreamMusic.DreamMusicMood
    let tempo: DreamMusic.DreamMusicTempo
    let instruments: [DreamMusic.DreamMusicInstrument]
    let baseDuration: Int  // 秒
}
