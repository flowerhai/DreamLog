//
//  DreamBreathingExerciseView.swift
//  DreamLog
//
//  Phase 65: 梦境冥想与放松增强
//  呼吸练习界面
//

import SwiftUI

// MARK: - 呼吸练习视图

struct DreamBreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: BreathingExercise = .boxBreathing
    @State private var isPlaying = false
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var cycleCount: Int = 0
    @State private var totalTime: TimeInterval = 0
    @State private var showCompletionSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航
            navigationBar
            
            // 练习选择器
            if !isPlaying {
                exerciseSelector
            }
            
            // 主练习区域
            practiceArea
            
            Spacer()
            
            // 底部控制
            if !isPlaying {
                startButton
            }
        }
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showCompletionSheet) {
            BreathingCompletionSheet(
                cycles: cycleCount,
                duration: totalTime
            )
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
            
            Text("呼吸练习")
                .font(.headline)
            
            Spacer()
            
            Button {
                // 显示信息
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .padding()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Exercise Selector
    
    private var exerciseSelector: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("选择呼吸练习")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(BreathingExercise.allCases, id: \.self) { exercise in
                    ExerciseCard(
                        exercise: exercise,
                        isSelected: selectedExercise == exercise
                    ) {
                        selectedExercise = exercise
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Practice Area
    
    private var practiceArea: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 呼吸动画
            breathingAnimation
            
            // 阶段指示
            phaseIndicator
            
            // 计数
            cycleCounter
            
            Spacer()
            
            // 指导文字
            instructionText
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Breathing Animation
    
    private var breathingAnimation: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )
                .frame(width: 280, height: 280)
                .scaleEffect(currentScale)
                .animation(
                    Animation.easeInOut(duration: currentPhaseDuration)
                        .repeatForever(autoreverses: currentPhase == .hold ? false : true),
                    value: isPlaying ? currentPhase : .inhale
                )
            
            // 中圈
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.blue.opacity(0.2), .purple.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
            
            // 内圈图标
            Image(systemName: phaseIcon)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(height: 300)
    }
    
    private var currentScale: CGFloat {
        guard isPlaying else { return 1.0 }
        
        switch currentPhase {
        case .inhale: return 1.2
        case .hold: return 1.2
        case .exhale: return 0.8
        }
    }
    
    private var currentPhaseDuration: Double {
        Double(selectedExercise.phaseDuration(for: currentPhase))
    }
    
    private var phaseIcon: String {
        guard isPlaying else { return "wind" }
        
        switch currentPhase {
        case .inhale: return "arrow.up"
        case .hold: return "pause.fill"
        case .exhale: return "arrow.down"
        }
    }
    
    // MARK: - Phase Indicator
    
    private var phaseIndicator: some View {
        VStack(spacing: 8) {
            Text(phaseText)
                .font(.title)
                .fontWeight(.medium)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // 阶段进度条
            HStack(spacing: 4) {
                ForEach(0..<selectedExercise.totalPhases, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index == currentPhaseIndex ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                }
            }
        }
    }
    
    private var phaseText: String {
        guard isPlaying else { return "准备开始" }
        
        switch currentPhase {
        case .inhale: return "吸气"
        case .hold: return "屏息"
        case .exhale: return "呼气"
        }
    }
    
    private var currentPhaseIndex: Int {
        switch currentPhase {
        case .inhale: return 0
        case .hold: return 1
        case .exhale: return 2
        }
    }
    
    // MARK: - Cycle Counter
    
    private var cycleCounter: some View {
        VStack(spacing: 4) {
            Text("\(cycleCount)")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            Text("个循环")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Instruction Text
    
    private var instructionText: some View {
        VStack(spacing: 12) {
            Text(selectedExercise.name)
                .font(.headline)
            
            Text(selectedExercise.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // 呼吸节奏
            HStack(spacing: 16) {
                BreathPhaseLabel(phase: "吸", duration: selectedExercise.inhaleDuration)
                BreathPhaseLabel(phase: "屏", duration: selectedExercise.holdDuration)
                BreathPhaseLabel(phase: "呼", duration: selectedExercise.exhaleDuration)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button {
            startExercise()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("开始练习")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
        .padding()
    }
    
    // MARK: - Methods
    
    private func startExercise() {
        isPlaying = true
        cycleCount = 0
        totalTime = 0
        currentPhase = .inhale
        
        runBreathingCycle()
    }
    
    private func runBreathingCycle() {
        guard isPlaying else { return }
        
        let phases: [BreathingPhase] = selectedExercise.phases
        
        for (index, phase) in phases.enumerated() {
            let duration = selectedExercise.phaseDuration(for: phase)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * Double(duration)) {
                guard isPlaying else { return }
                currentPhase = phase
                
                if phase == .exhale && index == phases.count - 1 {
                    cycleCount += 1
                }
            }
        }
        
        // 更新总时间
        let cycleDuration = phases.reduce(0) { $0 + selectedExercise.phaseDuration(for: $1) }
        totalTime += Double(cycleDuration)
        
        // 安排下一个循环
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(cycleDuration)) {
            guard isPlaying else { return }
            runBreathingCycle()
        }
    }
    
    private func stopExercise() {
        isPlaying = false
        showCompletionSheet = true
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: BreathingExercise
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: exercise.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .purple)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.purple : Color.purple.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text("\(exercise.totalDuration / 60) 分钟 · \(exercise.difficulty.displayName)")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.purple)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple : Color(.systemBackground))
            )
        }
    }
}

// MARK: - Breath Phase Label

struct BreathPhaseLabel: View {
    let phase: String
    let duration: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text(phase)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(duration)秒")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Completion Sheet

struct BreathingCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let cycles: Int
    let duration: TimeInterval
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                
                Text("练习完成！")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    StatRow(label: "完成循环", value: "\(cycles)")
                    StatRow(label: "总时长", value: duration.formattedDuration)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(12)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("完成")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding()
            .navigationTitle("练习总结")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Breathing Exercise Model

enum BreathingExercise: String, CaseIterable {
    case boxBreathing = "box"           // 盒子呼吸
    case fourSevenEight = "478"         // 4-7-8 呼吸
    case coherent = "coherent"          // 共振呼吸
    case energizing = "energizing"      // 活力呼吸
    case relaxing = "relaxing"          // 放松呼吸
    case wild = "wild"                  // WILD 呼吸
    
    var name: String {
        switch self {
        case .boxBreathing: return "盒子呼吸法"
        case .fourSevenEight: return "4-7-8 呼吸法"
        case .coherent: return "共振呼吸"
        case .energizing: return "活力呼吸"
        case .relaxing: return "放松呼吸"
        case .wild: return "WILD 呼吸"
        }
    }
    
    var description: String {
        switch self {
        case .boxBreathing: return "提升专注力，减轻压力"
        case .fourSevenEight: return "帮助快速入睡，缓解焦虑"
        case .coherent: return "平衡神经系统，提升心率变异性"
        case .energizing: return "提升能量，唤醒身心"
        case .relaxing: return "深度放松，释放压力"
        case .wild: return "清醒梦诱导呼吸法"
        }
    }
    
    var icon: String {
        switch self {
        case .boxBreathing: return "square.grid.3x3"
        case .fourSevenEight: return "moon.stars"
        case .coherent: return "heart"
        case .energizing: return "bolt"
        case .relaxing: return "figure.mind.and.body"
        case .wild: return "eye"
        }
    }
    
    var difficulty: MeditationDifficulty {
        switch self {
        case .boxBreathing, .fourSevenEight, .relaxing: return .beginner
        case .coherent, .energizing: return .intermediate
        case .wild: return .advanced
        }
    }
    
    // 呼吸阶段时长（秒）
    var inhaleDuration: Int {
        switch self {
        case .boxBreathing: return 4
        case .fourSevenEight: return 4
        case .coherent: return 5
        case .energizing: return 3
        case .relaxing: return 4
        case .wild: return 5
        }
    }
    
    var holdDuration: Int {
        switch self {
        case .boxBreathing: return 4
        case .fourSevenEight: return 7
        case .coherent: return 1
        case .energizing: return 1
        case .relaxing: return 2
        case .wild: return 2
        }
    }
    
    var exhaleDuration: Int {
        switch self {
        case .boxBreathing: return 4
        case .fourSevenEight: return 8
        case .coherent: return 5
        case .energizing: return 3
        case .relaxing: return 6
        case .wild: return 5
        }
    }
    
    var phases: [BreathingPhase] {
        switch self {
        case .boxBreathing, .fourSevenEight:
            return [.inhale, .hold, .exhale]
        case .coherent, .energizing, .relaxing, .wild:
            return [.inhale, .hold, .exhale]
        }
    }
    
    var totalPhases: Int {
        phases.count
    }
    
    func phaseDuration(for phase: BreathingPhase) -> Int {
        switch phase {
        case .inhale: return inhaleDuration
        case .hold: return holdDuration
        case .exhale: return exhaleDuration
        }
    }
    
    var totalDuration: Int {
        // 一个循环的时长（秒）
        inhaleDuration + holdDuration + exhaleDuration
    }
}

enum BreathingPhase {
    case inhale
    case hold
    case exhale
}

// MARK: - Extensions

extension TimeInterval {
    var formattedDuration: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
}

// MARK: - Preview

#Preview {
    DreamBreathingExerciseView()
}
