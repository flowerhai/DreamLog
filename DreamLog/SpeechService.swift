//
//  SpeechService.swift
//  DreamLog
//
//  语音识别服务
//

import Foundation
import Speech
import AVFoundation
import Combine

class SpeechService: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var transcription: String = ""
    @Published var isProcessing: Bool = false
    @Published var error: String?
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        
        // 检查权限
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("✅ 语音识别已授权")
            case .denied, .restricted, .notDetermined:
                self.error = "需要语音识别权限"
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - 开始录音
    func startRecording() {
        guard !isRecording else { return }
        
        transcription = ""
        isRecording = true
        error = nil
        
        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        // 创建识别任务
        guard let request = recognitionRequest,
              let recognizer = speechRecognizer else {
            error = "语音识别不可用"
            isRecording = false
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                self.transcription = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        // 配置音频
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 开始录音
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    // MARK: - 停止录音
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        isProcessing = true
        
        // 停止音频引擎
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // 结束识别请求
        recognitionRequest?.endAudio()
        
        // 等待处理完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isProcessing = false
        }
    }
    
    // MARK: - 取消录音
    func cancelRecording() {
        recognitionTask?.cancel()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        isProcessing = false
        transcription = ""
    }
    
    // MARK: - 检查权限
    static func checkPermissions() -> (speech: Bool, microphone: Bool) {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        
        return (
            speech: speechStatus == .authorized,
            microphone: micStatus == .granted
        )
    }
    
    // MARK: - 请求权限
    static func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    // 已经处理了 speech 权限
                }
            }
        }
    }
}

// MARK: - 按钮扩展 (长按录音)
import SwiftUI

extension Button {
    func longPressAction(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) -> some View {
        self.simultaneousGesture(
            LongPressGesture(minimumDuration: 0.01)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}
