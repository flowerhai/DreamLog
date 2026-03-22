//
//  OnboardingView.swift
//  DreamLog
//
//  Phase 87 Session 2 - Onboarding Flow
//  完整的用户引导流程：欢迎页面、权限请求、功能介绍
//

import SwiftUI

// MARK: - 引导状态管理

class OnboardingManager: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isCompleted: Bool = false
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case feature1 = 1
        case feature2 = 2
        case feature3 = 3
        case permissions = 4
        case tutorial = 5
        case complete = 6
    }
    
    @AppStorage("onboardingCompleted") private var storedCompleted: Bool = false
    
    init() {
        self.isCompleted = storedCompleted
    }
    
    func next() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            complete()
            return
        }
        currentStep = nextIndex
    }
    
    func previous() {
        guard currentStep.rawValue > 0,
              let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = prevIndex
    }
    
    func complete() {
        isCompleted = true
        storedCompleted = true
    }
    
    func reset() {
        currentStep = .welcome
        isCompleted = false
        storedCompleted = false
    }
}

// MARK: - 主引导视图

struct OnboardingView: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(hex: "1A1A2E"),
                    Color(hex: "16213E"),
                    Color(hex: "0F3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 内容
            VStack {
                // 进度指示器
                if manager.currentStep != .complete {
                    OnboardingProgressView(currentStep: manager.currentStep)
                        .padding(.top, 20)
                }
                
                // 步骤内容
                TabView(selection: $manager.currentStep) {
                    WelcomeSlideView()
                        .tag(OnboardingManager.OnboardingStep.welcome)
                    
                    Feature1SlideView()
                        .tag(OnboardingManager.OnboardingStep.feature1)
                    
                    Feature2SlideView()
                        .tag(OnboardingManager.OnboardingStep.feature2)
                    
                    Feature3SlideView()
                        .tag(OnboardingManager.OnboardingStep.feature3)
                    
                    PermissionRequestView()
                        .tag(OnboardingManager.OnboardingStep.permissions)
                    
                    TutorialSlideView()
                        .tag(OnboardingManager.OnboardingStep.tutorial)
                    
                    CompletionView(manager: manager)
                        .tag(OnboardingManager.OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: manager.currentStep)
                
                // 底部按钮
                if manager.currentStep != .complete {
                    OnboardingButtonsView(manager: manager)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - 进度指示器

struct OnboardingProgressView: View {
    let currentStep: OnboardingManager.OnboardingStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingManager.OnboardingStep.allCases.filter { $0 != .complete }, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color(hex: "9B7EBD") : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .accessibilityLabel("引导进度")
    }
}

// MARK: - 底部按钮

struct OnboardingButtonsView: View {
    @ObservedObject var manager: OnboardingManager
    @State private var showingSkipAlert = false
    
    var body: some View {
        HStack(spacing: 20) {
            // 跳过按钮
            if manager.currentStep.rawValue > 0 {
                Button(action: { showingSkipAlert = true }) {
                    Text("跳过引导")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(30)
                }
                .accessibilityLabel("跳过引导")
            }
            
            Spacer()
            
            // 下一步按钮
            Button(action: { manager.next() }) {
                HStack {
                    Text(manager.currentStep.rawValue == 3 ? "开始体验" : "下一步")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "9B7EBD"), Color(hex: "7B68A8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: Color(hex: "9B7EBD").opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel(manager.currentStep.rawValue == 3 ? "开始体验" : "下一步")
        }
        .padding(.horizontal, 24)
        .alert("跳过引导", isPresented: $showingSkipAlert) {
            Button("取消", role: .cancel) { }
            Button("确定") {
                manager.complete()
            }
        } message: {
            Text("确定要跳过引导吗？您可以稍后在设置中查看功能介绍。")
        }
    }
}

// MARK: - 欢迎页面

struct WelcomeSlideView: View {
    @State private var animateLogo = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "9B7EBD"), Color(hex: "7B68A8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: "9B7EBD").opacity(0.5), radius: 20, x: 0, y: 10)
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(animateLogo ? 5 : -5))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateLogo = true
                }
            }
            
            VStack(spacing: 16) {
                Text("DreamLog")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("探索你的梦境世界")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Text("记录 · 解析 · 探索")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("AI 驱动的梦境日记")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
                .frame(height: 60)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 功能介绍页面 1 - AI 解析

struct Feature1SlideView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color(hex: "9B7EBD").opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "9B7EBD"))
            }
            
            VStack(spacing: 16) {
                Text("AI 智能解析")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("深入了解梦境背后的含义")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 功能列表
            VStack(alignment: .leading, spacing: 12) {
                FeatureBulletPoint(icon: "sparkles", text: "深度梦境分析")
                FeatureBulletPoint(icon: "lightbulb", text: "符号解读与象征")
                FeatureBulletPoint(icon: "chart.line.uptrend.xyaxis", text: "情绪模式识别")
                FeatureBulletPoint(icon: "wand.and.stars", text: "个性化洞察建议")
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 功能介绍页面 2 - 统计分析

struct Feature2SlideView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color(hex: "5E9CD3").opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "5E9CD3"))
            }
            
            VStack(spacing: 16) {
                Text("深度数据分析")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("发现你的睡眠与梦境模式")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 功能列表
            VStack(alignment: .leading, spacing: 12) {
                FeatureBulletPoint(icon: "moon.fill", text: "睡眠质量追踪")
                FeatureBulletPoint(icon: "calendar", text: "梦境频率统计")
                FeatureBulletPoint(icon: "face.smiling", text: "情绪变化趋势")
                FeatureBulletPoint(icon: "arrow.triangle.2.circlepath", text: "梦境主题分析")
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 功能介绍页面 3 - 创意功能

struct Feature3SlideView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color(hex: "F5A623").opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "F5A623"))
            }
            
            VStack(spacing: 16) {
                Text("创意与探索")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("将梦境转化为艺术与灵感")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 功能列表
            VStack(alignment: .leading, spacing: 12) {
                FeatureBulletPoint(icon: "photo.on.rectangle", text: "AI 梦境绘画")
                FeatureBulletPoint(icon: "music.note", text: "梦境音乐生成")
                FeatureBulletPoint(icon: "book.fill", text: "创意写作提示")
                FeatureBulletPoint(icon: "globe", text: "社区分享交流")
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 功能要点

struct FeatureBulletPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "9B7EBD"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 教程页面

struct TutorialSlideView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("开始你的梦境之旅")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("记录第一个梦境只需几步")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 步骤指示
            VStack(spacing: 20) {
                TutorialStep(number: 1, title: "点击底部 + 按钮", description: "在首页点击添加按钮")
                TutorialStep(number: 2, title: "描述你的梦境", description: "写下你记得的内容")
                TutorialStep(number: 3, title: "选择情绪标签", description: "标记梦境的情绪色彩")
                TutorialStep(number: 4, title: "获取 AI 解析", description: "立即获得深度分析")
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - 教程步骤

struct TutorialStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 数字圆圈
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "9B7EBD"), Color(hex: "7B68A8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text("\(number)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 完成页面

struct CompletionView: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.dismiss) var dismiss
    @State private var animateCheckmark = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 成功动画
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "9B7EBD"), Color(hex: "7B68A8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateCheckmark ? 1.1 : 1.0)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundColor(.white)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateCheckmark = true
                }
            }
            
            VStack(spacing: 16) {
                Text("准备好了吗？")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("开始记录你的第一个梦境吧")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 开始按钮
            Button(action: {
                manager.complete()
                dismiss()
            }) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                    Text("开始记录梦境")
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "9B7EBD"), Color(hex: "7B68A8")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: Color(hex: "9B7EBD").opacity(0.5), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(manager: OnboardingManager())
}
