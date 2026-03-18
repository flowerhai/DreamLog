//
//  DreamMeditationPlayerView.swift
//  DreamLog
//
//  Phase 65: 梦境冥想与放松增强
//  冥想播放界面
//

import SwiftUI
import AVFoundation

// MARK: - 冥想播放器

struct DreamMeditationPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service: DreamMeditationService?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var showSettings = false
    @State private var volume: Double = 0.8
    @State private var timerDuration: TimeInterval = 1800 // 30 分钟
    @State private var selectedBackgroundSound: String?
    @State private var showFeedbackSheet = false
    @State private var session: MeditationSession?
    
    let template: MeditationTemplate
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航
            navigationBar
            
            // 主要内容
            ScrollView {
                VStack(spacing: 32) {
                    // 动画插图
                    animationSection
                    
                    // 进度条
                    progressSection
                    
                    // 控制按钮
                    controlsSection
                    
                    // 设置
                    settingsSection
                    
                    // 描述
                    descriptionSection
                }
                .padding()
            }
            
            // 底部按钮
            bottomBar
        }
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .blue.opacity(0.1), .indigo.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .task {
            service = DreamMeditationService(modelContext: modelContext)
            setupCallbacks()
            await startSession()
        }
        .onDisappear {
            Task {
                await service?.stopSession(completed: currentTime >= template.duration * 0.8)
            }
        }
        .sheet(isPresented: $showSettings) {
            MeditationSettingsSheet(
                volume: $volume,
                timerDuration: $timerDuration,
                backgroundSound: $selectedBackgroundSound
            )
        }
        .sheet(isPresented: $showFeedbackSheet) {
            MeditationFeedbackSheet(session: session)
        }
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding()
            }
            
            Spacer()
            
            Text(template.name)
                .font(.headline)
            
            Spacer()
            
            Button {
                showSettings = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .padding()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground).opacity(0.8))
    }
    
    // MARK: - Animation Section
    
    private var animationSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景光晕
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .scaleEffect(isPlaying ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true),
                        value: isPlaying
                    )
                
                // 主图标
                Image(systemName: template.meditationType?.icon ?? "sparkles")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isPlaying ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isPlaying
                    )
            }
            .frame(height: 300)
            
            // 呼吸提示（如果是呼吸练习）
            if template.meditationType?.category == .breathing {
                breathingHint
            }
        }
    }
    
    private var breathingHint: some View {
        Text(breathingInstruction)
            .font(.headline)
            .foregroundStyle(.purple)
            .opacity(isPlaying ? 1.0 : 0.5)
            .animation(
                Animation.easeInOut(duration: breathingCycleDuration)
                    .repeatForever(autoreverses: true),
                value: isPlaying
            )
    }
    
    private var breathingInstruction: String {
        guard let type = template.meditationType else { return "呼吸" }
        
        switch type {
        case .breathing478:
            return currentTime.truncatingRemainder(dividingBy: 19) < 4 ? "吸气" :
                   currentTime.truncatingRemainder(dividingBy: 19) < 11 ? "屏息" : "呼气"
        case .boxBreathing:
            let phase = Int(currentTime.truncatingRemainder(dividingBy: 16)) / 4
            return ["吸气", "屏息", "呼气", "屏息"][phase]
        default:
            return "呼吸"
        }
    }
    
    private var breathingCycleDuration: Double {
        guard let type = template.meditationType else { return 4.0 }
        
        switch type {
        case .breathing478: return 9.5 // 4+7+8 的一半
        case .boxBreathing: return 8.0 // 4+4+4+4 的一半
        default: return 4.0
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .animation(.linear, value: progressPercentage)
                }
            }
            .frame(height: 8)
            
            // 时间
            HStack {
                Text(currentTime.formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(template.durationFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var progressPercentage: Double {
        min(currentTime / template.duration, 1.0)
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        HStack(spacing: 40) {
            // 快退 15 秒
            Button {
                currentTime = max(0, currentTime - 15)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
            
            // 播放/暂停
            Button {
                togglePlayPause()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // 快进 15 秒
            Button {
                currentTime = min(template.duration, currentTime + 15)
            } label: {
                Image(systemName: "goforward.15")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(spacing: 16) {
            // 音量
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                
                Slider(value: $volume, in: 0...1)
                    .tint(.purple)
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
            
            // 定时关闭
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
                
                Picker("定时", selection: $timerDuration) {
                    Text("关闭").tag(TimeInterval(0))
                    Text("15 分钟").tag(TimeInterval(900))
                    Text("30 分钟").tag(TimeInterval(1800))
                    Text("45 分钟").tag(TimeInterval(2700))
                    Text("60 分钟").tag(TimeInterval(3600))
                    Text("播完").tag(TimeInterval(template.duration))
                }
                .pickerStyle(.menu)
                
                Spacer()
            }
            
            // 背景音
            HStack {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
                
                Text(selectedBackgroundSound ?? "无")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("选择") {
                    showSettings = true
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关于这个冥想")
                .font(.headline)
            
            Text(template.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !template.benefits.isEmpty {
                Text("益处")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 8)
                
                ForEach(template.benefits, id: \.self) { benefit in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        
                        Text(benefit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button {
                // 标记为完成
                Task {
                    await service?.stopSession(completed: true)
                    showFeedbackSheet = true
                }
            } label: {
                Label("完成", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            Button {
                // 跳过
                dismiss()
            } label: {
                Label("跳过", systemImage: "forward.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Methods
    
    private func setupCallbacks() {
        service?.onPlaybackStateChange = { playing in
            DispatchQueue.main.async {
                isPlaying = playing
            }
        }
        
        service?.onSessionTick = {
            DispatchQueue.main.async {
                currentTime += 1
            }
        }
        
        service?.onSessionComplete = { session in
            DispatchQueue.main.async {
                self.session = session
                showFeedbackSheet = true
            }
        }
    }
    
    private func startSession() async {
        do {
            session = try await service?.startSession(
                type: template.meditationType ?? .guidedDream,
                duration: template.duration,
                template: template,
                volume: volume,
                timerDuration: timerDuration > 0 ? timerDuration : nil
            )
            isPlaying = true
        } catch {
            print("启动冥想失败：\(error)")
        }
    }
    
    private func togglePlayPause() {
        Task {
            if isPlaying {
                service?.pauseSession()
            } else {
                try? await service?.resumeSession()
            }
        }
    }
}

// MARK: - Meditation Settings Sheet

struct MeditationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var volume: Double
    @Binding var timerDuration: TimeInterval
    @Binding var backgroundSound: String?
    
    let backgroundSounds = ["无", "雨声", "海浪", "森林", "篝火", "白噪音"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("音量") {
                    Slider(value: $volume, in: 0...1)
                    Text("\(Int(volume * 100))%")
                }
                
                Section("定时关闭") {
                    Picker("时长", selection: $timerDuration) {
                        Text("关闭").tag(TimeInterval(0))
                        Text("15 分钟").tag(TimeInterval(900))
                        Text("30 分钟").tag(TimeInterval(1800))
                        Text("45 分钟").tag(TimeInterval(2700))
                        Text("60 分钟").tag(TimeInterval(3600))
                    }
                }
                
                Section("背景音") {
                    ForEach(backgroundSounds, id: \.self) { sound in
                        Button {
                            backgroundSound = sound == "无" ? nil : sound
                        } label: {
                            HStack {
                                Text(sound)
                                Spacer()
                                if (sound == "无" && backgroundSound == nil) || backgroundSound == sound {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.purple)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("冥想设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Meditation Feedback Sheet

struct MeditationFeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var moodAfter: String?
    @State private var sleepQuality: Int = 3
    @State private var focusLevel: Int = 3
    @State private var relaxationLevel: Int = 3
    @State private var wouldRecommend: Bool = true
    @State private var notes: String = ""
    
    let session: MeditationSession?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("感受如何？") {
                    Picker("练习后情绪", selection: $moodAfter) {
                        Text("未选择").tag(nil as String?)
                        Text("平静").tag("calm")
                        Text("放松").tag("relaxed")
                        Text("专注").tag("focused")
                        Text("振奋").tag("energized")
                        Text("困倦").tag("sleepy")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("练习评价") {
                    VStack(alignment: .leading, spacing: 12) {
                        RatingRow(title: "专注度", rating: $focusLevel)
                        RatingRow(title: "放松度", rating: $relaxationLevel)
                        RatingRow(title: "睡眠质量", rating: $sleepQuality)
                    }
                }
                
                Section("推荐") {
                    Toggle("会推荐这个冥想", isOn: $wouldRecommend)
                }
                
                Section("笔记") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("练习反馈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("提交") {
                        submitFeedback()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitFeedback() {
        Task {
            await DreamMeditationService(modelContext: modelContext).updateSessionFeedback(
                sessionId: session?.id ?? UUID(),
                moodAfter: moodAfter,
                sleepQuality: sleepQuality,
                focusLevel: focusLevel,
                relaxationLevel: relaxationLevel,
                wouldRecommend: wouldRecommend,
                notes: notes.isEmpty ? nil : notes
            )
        }
    }
}

struct RatingRow: View {
    let title: String
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .foregroundStyle(value <= rating ? .yellow : .gray)
                        .onTapGesture {
                            rating = value
                        }
                }
            }
        }
    }
}

// MARK: - Extensions

extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    DreamMeditationPlayerView(
        template: MeditationTemplate(
            name: "睡前放松冥想",
            type: .bodyScan,
            category: .relaxation,
            duration: 600,
            description: "帮助你放松身心，准备入睡",
            benefits: ["缓解压力", "改善睡眠", "放松肌肉"]
        )
    )
    .modelContainer(for: [
        MeditationSession.self,
        MeditationTemplate.self
    ], inMemory: true)
}
