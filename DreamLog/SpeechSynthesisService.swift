//
//  SpeechSynthesisService.swift
//  DreamLog
//
//  梦境语音播放 - 使用 TTS 朗读梦境内容
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - 语音配置

/// 语音播放配置
struct SpeechConfig: Codable, Equatable {
    var voiceIdentifier: String?
    var rate: Float
    var pitchMultiplier: Float
    var volume: Float
    var language: String
    
    static var `default`: SpeechConfig {
        SpeechConfig(
            voiceIdentifier: nil,
            rate: 0.5,
            pitchMultiplier: 1.0,
            volume: 1.0,
            language: "zh-CN"
        )
    }
}

// MARK: - 语音播放服务

@MainActor
class SpeechSynthesisService: NSObject, ObservableObject {
    static let shared = SpeechSynthesisService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechSynthesisUtterance?
    
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var config: SpeechConfig = .default
    
    // MARK: - 初始化
    
    override init() {
        super.init()
        synthesizer.delegate = self
        loadAvailableVoices()
        loadConfig()
    }
    
    // MARK: - 语音加载
    
    func loadAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                voice.language.hasPrefix("zh") || voice.language.hasPrefix("en")
            }
            .sorted { $0.name < $1.name }
    }
    
    func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "SpeechConfig"),
           let decoded = try? JSONDecoder().decode(SpeechConfig.self, from: data) {
            config = decoded
        }
    }
    
    func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "SpeechConfig")
        }
    }
    
    // MARK: - 播放控制
    
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        guard !text.isEmpty else { return }
        
        stop()
        
        let utterance = AVSpeechSynthesisUtterance(string: text)
        
        // 配置语音
        if let voiceId = config.voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            // 默认使用中文语音
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        }
        
        utterance.rate = config.rate
        utterance.pitchMultiplier = config.pitchMultiplier
        utterance.volume = config.volume
        
        currentUtterance = utterance
        
        synthesizer.speak(utterance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isSpeaking = true
            self.isPaused = false
        }
    }
    
    func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .word)
            isPaused = true
        }
    }
    
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentUtterance = nil
    }
    
    func togglePlayPause() {
        if isPaused {
            resume()
        } else if isSpeaking {
            pause()
        }
    }
    
    // MARK: - 语音预览
    
    func previewVoice(_ voice: AVSpeechSynthesisVoice) {
        let utterance = AVSpeechSynthesisUtterance(string: "这是语音预览，测试声音效果。")
        utterance.voice = voice
        utterance.rate = config.rate
        utterance.pitchMultiplier = config.pitchMultiplier
        utterance.volume = config.volume
        
        synthesizer.speak(utterance)
    }
    
    // MARK: - 状态查询
    
    var progress: CGFloat {
        guard isSpeaking, let utterance = currentUtterance else { return 0 }
        return 0 // AVSpeechSynthesizer 不提供进度回调，需要时可实现
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechSynthesisUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentUtterance = nil
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechSynthesisUtterance) {
        // 开始播放
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechSynthesisUtterance) {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechSynthesisUtterance) {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechSynthesisUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
        }
    }
}

// MARK: - 梦境朗读视图组件

struct DreamAudioPlayerView: View {
    let dreamContent: String
    @StateObject private var speechService = SpeechSynthesisService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // 播放/暂停按钮
            Button(action: {
                if speechService.isSpeaking {
                    speechService.togglePlayPause()
                } else {
                    speechService.speak(dreamContent)
                }
            }) {
                Image(systemName: speechService.isSpeaking && !speechService.isPaused ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
            
            // 停止按钮
            if speechService.isSpeaking {
                Button(action: { speechService.stop() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }
            }
            
            // 状态指示
            if speechService.isSpeaking {
                Text(speechService.isPaused ? "已暂停" : "播放中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: speechService.isSpeaking)
            }
        }
        .onDisappear {
            speechService.stop()
        }
    }
}

// MARK: - 语音设置视图

struct SpeechSettingsView: View {
    @StateObject private var speechService = SpeechSynthesisService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 语速
                Section(header: Text("🎛️ 语速")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("慢")
                            Slider(value: $speechService.config.rate, in: 0.3...1.0, step: 0.1)
                                .onChange(of: speechService.config.rate) { _ in
                                    speechService.saveConfig()
                                }
                            Text("快")
                        }
                        Text("当前：\(speechService.config.rate, specifier: "%.1f")x")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // 音调
                Section(header: Text("🎵 音调")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("低")
                            Slider(value: $speechService.config.pitchMultiplier, in: 0.5...2.0, step: 0.1)
                                .onChange(of: speechService.config.pitchMultiplier) { _ in
                                    speechService.saveConfig()
                                }
                            Text("高")
                        }
                        Text("当前：\(speechService.config.pitchMultiplier, specifier: "%.1f")x")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // 音量
                Section(header: Text("🔊 音量")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("小")
                            Slider(value: $speechService.config.volume, in: 0.1...1.0, step: 0.1)
                                .onChange(of: speechService.config.volume) { _ in
                                    speechService.saveConfig()
                                }
                            Text("大")
                        }
                        Text("当前：\(Int(speechService.config.volume * 100))%")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // 语音选择
                Section(header: Text("🎙️ 语音")) {
                    Picker("语音", selection: $speechService.config.voiceIdentifier) {
                        Text("默认").tag(nil as String?)
                        
                        ForEach(speechService.availableVoices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))")
                                .tag(voice.identifier as String?)
                        }
                    }
                    .onChange(of: speechService.config.voiceIdentifier) { _ in
                        speechService.saveConfig()
                    }
                    
                    // 语音预览
                    Button("🔊 预览选中语音") {
                        if let voiceId = speechService.config.voiceIdentifier,
                           let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                            speechService.previewVoice(voice)
                        } else {
                            speechService.previewVoice(AVSpeechSynthesisVoice(language: "zh-CN")!)
                        }
                    }
                }
                
                // 重置
                Section {
                    Button("🔄 重置为默认设置") {
                        speechService.config = .default
                        speechService.saveConfig()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("🎙️ 语音播放设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
