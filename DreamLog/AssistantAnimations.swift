//
//  AssistantAnimations.swift
//  DreamLog
//
//  AI 助手 UI 动画效果库
//  Phase 13 - AI 助手体验优化
//

import SwiftUI

// MARK: - 动画配置

/// 助手动画配置
struct AssistantAnimations {
    /// 消息出现动画 - 弹簧效果
    static let messageAppear = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0
    )
    
    /// 卡片翻转动画
    static let cardFlip = Animation.easeInOut(duration: 0.6)
    
    /// 脉冲动画 (用于加载状态)
    static let pulse = Animation.easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true)
    
    /// 波形动画 (用于语音)
    static let waveform = Animation.linear(duration: 0.1)
        .repeatForever(autoreverses: false)
    
    /// 渐显动画
    static let fadeIn = Animation.easeIn(duration: 0.3)
    
    /// 渐隐动画
    static let fadeOut = Animation.easeOut(duration: 0.3)
    
    /// 缩放动画
    static let scale = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6
    )
    
    /// 滑动进入动画
    static let slideIn = Animation.spring(
        response: 0.5,
        dampingFraction: 0.8
    )
}

// MARK: - 消息气泡动画视图

/// 带动画的消息气泡
struct AnimatedMessageBubble: View {
    let message: ChatMessage
    let isLast: Bool
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.95
    @State private var offsetX: CGFloat = 20
    
    var body: some View {
        MessageBubbleView(message: message)
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(x: message.sender == .user ? offsetX : -offsetX)
            .onAppear {
                withAnimation(AssistantAnimations.messageAppear) {
                    opacity = 1
                    scale = 1
                    offsetX = 0
                }
            }
    }
}

// MARK: - 语音波形动画视图

/// 语音波形动画
struct WaveformAnimationView: View {
    let isRecording: Bool
    let barCount: Int
    
    @State private var barHeights: [CGFloat] = []
    
    init(isRecording: Bool, barCount: Int = 5) {
        self.isRecording = isRecording
        self.barCount = barCount
        _barHeights = State(initialValue: Array(repeating: 0.3, count: barCount))
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.purple)
                    .frame(width: 4, height: barHeights[index] * 30)
                    .animation(
                        isRecording ?
                            Animation.easeInOut(duration: 0.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.05) :
                            Animation.default,
                        value: isRecording
                    )
            }
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                animateWaveform()
            } else {
                withAnimation {
                    barHeights = Array(repeating: 0.3, count: barCount)
                }
            }
        }
    }
    
    private func animateWaveform() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if !self.isRecording {
                timer.invalidate()
                return
            }
            
            withAnimation(.waveform) {
                self.barHeights = (0..<self.barCount).map { _ in
                    CGFloat.random(in: 0.2...1.0)
                }
            }
        }
    }
}

// MARK: - 预测卡片动画视图

/// 带动画效果的预测卡片
struct AnimatedPredictionCard: View {
    let prediction: DreamPrediction
    let isFlipped: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            if isFlipped {
                PredictionDetailCard(prediction: prediction)
                    .transition(.asymmetric(
                        insertion: .rotate3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0)),
                        removal: .rotate3DEffect(.degrees(-90), axis: (x: 0, y: 1, z: 0))
                    ))
            } else {
                PredictionSummaryCard(prediction: prediction)
                    .transition(.asymmetric(
                        insertion: .rotate3DEffect(.degrees(-90), axis: (x: 0, y: 1, z: 0)),
                        removal: .rotate3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0))
                    ))
            }
        }
        .animation(AssistantAnimations.cardFlip, value: isFlipped)
    }
}

// MARK: - 加载状态动画视图

/// 思考中加载动画
struct ThinkingIndicatorView: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.purple.opacity(opacity))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == 1 ? scale : 1.0)
            }
        }
        .onAppear {
            withAnimation(AssistantAnimations.pulse) {
                scale = 1.3
                opacity = 1.0
            }
        }
    }
}

/// 骨架屏加载动画
struct SkeletonLoadingView: View {
    @State private var gradientPosition: CGFloat = -1
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.2),
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: index == 2 ? 60 : 20)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .leading(attachment: gradientPosition),
                            endPoint: .trailing(attachment: gradientPosition)
                        )
                    )
            }
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                gradientPosition = 2
            }
        }
    }
}

// MARK: - 进度条动画视图

/// 带动画的进度条
struct AnimatedProgressBar: View {
    let progress: Double
    let height: CGFloat
    
    @State private var displayProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)
                
                // 进度
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(geometry.size.width * displayProgress, geometry.size.width)), height: height)
                    .animation(.easeInOut(duration: 0.3), value: displayProgress)
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                displayProgress = newProgress
            }
        }
    }
}

// MARK: - 数字滚动动画视图

/// 数字滚动动画
struct AnimatedNumberView: View {
    let value: Int
    let duration: Double
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .monospacedDigit()
            .onAppear {
                animateNumber(from: 0, to: value, duration: duration)
            }
            .onChange(of: value) { newValue in
                animateNumber(from: displayValue, to: newValue, duration: duration)
            }
    }
    
    private func animateNumber(from: Int, to: Int, duration: Double) {
        let steps = 30
        let increment = (to - from) / steps
        var current = from
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * (duration / Double(steps))) {
                current += increment
                withAnimation {
                    displayValue = current
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayValue = to
        }
    }
}

// MARK: - 标签云动画视图

/// 带动画的标签云
struct AnimatedTagCloud: View {
    let tags: [(key: String, value: Int)]
    
    @State private var visibleTags: [(key: String, value: Int)] = []
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(visibleTags.enumerated()), id: \.element.key) { index, tag in
                TagBubble(tag: tag.key, count: tag.value)
                    .opacity(0)
                    .scaleEffect(0.5)
                    .onAppear {
                        withAnimation(
                            AssistantAnimations.scale.delay(Double(index) * 0.05)
                        ) {
                            self.visibleTags[index].1 = tag.value
                        }
                    }
            }
        }
        .onAppear {
            visibleTags = tags.map { ($0.key, 0) }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AssistantAnimations.messageAppear) {
                    visibleTags = tags
                }
            }
        }
    }
}

// MARK: - 情绪云动画视图

/// 带动画的情绪云
struct AnimatedEmotionCloud: View {
    let emotions: [(key: Emotion, value: Int)]
    
    @State private var displayEmotions: [(key: Emotion, value: Int)] = []
    
    var body: some View {
        FlowLayout(spacing: 12) {
            ForEach(Array(displayEmotions.enumerated()), id: \.element.key.rawValue) { index, emotion in
                EmotionBubble(emotion: emotion.key, count: emotion.value)
                    .opacity(0)
                    .scaleEffect(0.5)
                    .onAppear {
                        withAnimation(
                            AssistantAnimations.scale.delay(Double(index) * 0.08)
                        ) {
                            self.displayEmotions[index].1 = emotion.value
                        }
                    }
            }
        }
        .onAppear {
            displayEmotions = emotions.map { ($0.key, 0) }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AssistantAnimations.messageAppear) {
                    displayEmotions = emotions
                }
            }
        }
    }
}

// MARK: - 成功反馈动画视图

/// 成功动画
struct SuccessAnimationView: View {
    let onComplete: () -> Void
    
    @State private var scale: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
            
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.green)
                .rotationEffect(.degrees(rotation))
        }
        .opacity(opacity)
        .onAppear {
            // 放大动画
            withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1
            }
            
            // 旋转动画
            withAnimation(Animation.easeInOut(duration: 0.3).delay(0.2)) {
                rotation = 360
            }
            
            // 淡出动画
            withAnimation(Animation.easeOut(duration: 0.3).delay(0.8)) {
                opacity = 0
            } completion: {
                onComplete()
            }
        }
    }
}

// MARK: - 辅助组件

/// 标签气泡
struct TagBubble: View {
    let tag: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("(\(count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(16)
    }
}

/// 情绪气泡
struct EmotionBubble: View {
    let emotion: Emotion
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Text(emotion.icon)
                .font(.body)
            
            Text(emotion.displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("(\(count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(16)
    }
}

/// 流式布局
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var horizontalAlignment: HorizontalAlignment = .leading
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - 预览

#Preview {
    VStack(spacing: 20) {
        // 消息气泡
        AnimatedMessageBubble(
            message: ChatMessage(content: "你好，我是你的梦境助手！", sender: .assistant),
            isLast: true
        )
        
        // 波形动画
        WaveformAnimationView(isRecording: true)
        
        // 加载指示器
        ThinkingIndicatorView()
        
        // 进度条
        AnimatedProgressBar(progress: 0.7, height: 8)
        
        // 成功动画
        SuccessAnimationView(onComplete: {})
    }
    .padding()
}
