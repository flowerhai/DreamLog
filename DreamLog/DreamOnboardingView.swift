//
//  DreamOnboardingView.swift
//  DreamLog
//
//  新手引导界面 - Phase 30 用户体验优化
//  5 屏引导流程：记录梦境 → AI 解析 → 智能洞察 → 时间胶囊 → 隐私保护
//

import SwiftUI

struct DreamOnboardingView: View {
    @State private var currentPage = 0
    @State private var showGetStarted = false
    @State private var selectedTimePreference: UserPreferences.RecordingTimePreference = .morning
    @State private var selectedAnalysisDepth: UserPreferences.AnalysisDepth = .standard
    
    let pages = OnboardingPage.pages
    let totalPages = 5
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 进度指示器
                progressIndicator
                
                Spacer()
                
                // 当前页面内容
                if currentPage < totalPages {
                    pageContent(pages[currentPage])
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    // 偏好设置页面
                    preferenceSetupView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                
                Spacer()
                
                // 底部按钮
                bottomButtons
            }
            .padding()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
    }
    
    // MARK: - 进度指示器
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages + 1, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index <= currentPage ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - 页面内容
    
    @ViewBuilder
    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            // 图标
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundColor(page.iconColor)
            }
            .padding(.top, 40)
            
            // 标题
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // 描述
            Text(page.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // 功能列表
            VStack(spacing: 12) {
                ForEach(page.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                        
                        Text(feature)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 偏好设置视图
    
    private var preferenceSetupView: some View {
        VStack(spacing: 25) {
            // 标题
            VStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                Text("个性化设置")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("让我们更了解你的需求")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 20)
            
            // 记录时间偏好
            preferenceSection(
                title: "你通常什么时候记录梦境？",
                icon: "clock.fill"
            ) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(UserPreferences.RecordingTimePreference.allCases, id: \.self) { preference in
                        TimePreferenceCard(
                            preference: preference,
                            isSelected: selectedTimePreference == preference
                        ) {
                            selectedTimePreference = preference
                        }
                    }
                }
            }
            
            // 解析深度偏好
            preferenceSection(
                title: "梦境解析深度",
                icon: "brain.head.profile"
            ) {
                VStack(spacing: 12) {
                    ForEach(UserPreferences.AnalysisDepth.allCases, id: \.self) { depth in
                        AnalysisDepthCard(
                            depth: depth,
                            isSelected: selectedAnalysisDepth == depth
                        ) {
                            selectedAnalysisDepth = depth
                        }
                    }
                }
            }
        }
    }
    
    private func preferenceSection<T: View>(
        title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> T
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - 底部按钮
    
    private var bottomButtons: some View {
        VStack(spacing: 16) {
            if currentPage < totalPages {
                // 跳过按钮
                Button(action: {
                    currentPage = totalPages
                }) {
                    Text("跳过")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 8)
                
                // 继续/开始按钮
                Button(action: {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    } else {
                        currentPage = totalPages
                    }
                }) {
                    HStack {
                        Text(currentPage == totalPages - 1 ? "开始设置" : "继续")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Image(systemName: currentPage == totalPages - 1 ? "arrow.right" : "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // 完成按钮
                Button(action: completeOnboarding) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("完成设置，开始探索")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - 完成引导
    
    private func completeOnboarding() {
        // 保存用户偏好
        var preferences = UserPreferences.default
        preferences.hasCompletedOnboarding = true
        preferences.isFirstLaunch = false
        preferences.preferredRecordingTime = selectedTimePreference
        preferences.analysisDepth = selectedAnalysisDepth
        
        // 保存到 UserDefaults
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "userPreferences")
        }
        
        // 触发 Haptic 反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 关闭引导
        showGetStarted = true
    }
}

// MARK: - 时间偏好卡片

struct TimePreferenceCard: View {
    let preference: UserPreferences.RecordingTimePreference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preference.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .purple : .white.opacity(0.7))
                
                Text(preference.displayText.components(separatedBy: " ")[0])
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .purple : .white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 解析深度卡片

struct AnalysisDepthCard: View {
    let depth: UserPreferences.AnalysisDepth
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(depth.displayText.components(separatedBy: "（").first ?? "")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? .purple : .white)
                    
                    if let detail = depth.displayText.components(separatedBy: "（").last?.replacingOccurrences(of: ")", with: "") {
                        Text(detail)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .purple : .white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览

#Preview {
    DreamOnboardingView()
}
