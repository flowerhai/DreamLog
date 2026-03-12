//
//  DreamOnboardingView.swift
//  DreamLog
//
//  Phase 25 - App Store 发布准备
//  新用户引导流程主界面
//

import SwiftUI

// MARK: - 主引导视图

struct DreamOnboardingView: View {
    @State private var currentPage = 0
    @State private var showPermissions = false
    @State private var showGoals = false
    @State private var showSubscription = false
    
    let pages = OnboardingPage.pages
    
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
                // 跳过按钮
                HStack {
                    Spacer()
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("跳过")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index }
                    { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // 下一步按钮
                Button(action: {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        showPermissions = true
                    }
                }) {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "下一步" : "开始使用")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "checkmark.circle.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            
            // 顶部 Logo
            VStack {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    Text("DreamLog")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showPermissions) {
            PermissionRequestView(onComplete: {
                showPermissions = false
                showGoals = true
            })
        }
        .fullScreenCover(isPresented: $showGoals) {
            GoalSetupView(onComplete: {
                showGoals = false
                completeOnboarding()
            })
        }
        .onAppear {
            // 检查是否已完成引导
            if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                // 直接跳转到主界面（由父视图处理）
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        // 通知父视图关闭引导
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }
}

// MARK: - 单个引导页面视图

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: page.image)
                    .font(.system(size: 80))
                    .foregroundColor(page.accentColor)
                    .symbolEffect(.pulse)
            }
            .padding(.top, 40)
            
            // 标题
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // 描述
            Text(page.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 50)
            
            Spacer()
            
            // 装饰星星
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                        .symbolEffect(.twinkle)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - 权限请求视图

struct PermissionRequestView: View {
    let onComplete: () -> Void
    
    @State private var grantedPermissions: Set<PermissionInfo.PermissionType> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 头部
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("权限说明")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("为了保护你的隐私，我们需要以下权限。你可以随时在设置中更改。")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)
                .padding(.bottom, 30)
                
                // 权限列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(PermissionInfo.allPermissions) { permission in
                            PermissionRow(
                                permission: permission,
                                isGranted: grantedPermissions.contains(permission.type)
                            ) {
                                requestPermission(for: permission)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // 继续按钮
                Button(action: {
                    onComplete()
                }) {
                    Text("继续")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func requestPermission(for permission: PermissionInfo) {
        switch permission.type {
        case .microphone:
            requestMicrophonePermission()
        case .notifications:
            requestNotificationPermission()
        case .health:
            requestHealthPermission()
        case .photos:
            requestPhotosPermission()
        }
    }
    
    private func requestMicrophonePermission() {
        // 麦克风权限请求
        grantedPermissions.insert(.microphone)
    }
    
    private func requestNotificationPermission() {
        // 通知权限请求
        grantedPermissions.insert(.notifications)
    }
    
    private func requestHealthPermission() {
        // 健康权限请求
        grantedPermissions.insert(.health)
    }
    
    private func requestPhotosPermission() {
        // 照片权限请求
        grantedPermissions.insert(.photos)
    }
}

// MARK: - 权限行组件

struct PermissionRow: View {
    let permission: PermissionInfo
    let isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: permission.icon)
                .font(.system(size: 24))
                .foregroundColor(isGranted ? .green : .purple)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isGranted ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                )
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !permission.required {
                        Text("(可选)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Text(permission.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 状态指示
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            } else {
                Button(action: onRequest) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.purple)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - 目标设置视图

struct GoalSetupView: View {
    let onComplete: () -> Void
    
    @State private var selectedGoals: [UserGoal] = UserGoal.defaultGoals
    @State private var showingCustomGoal = false
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 头部
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("设置你的目标")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("设定小目标，让记录梦境成为习惯")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)
                .padding(.bottom, 30)
                
                // 目标列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach($selectedGoals) { $goal in
                            GoalRow(goal: $goal)
                        }
                        
                        // 添加自定义目标按钮
                        Button(action: {
                            showingCustomGoal = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("添加自定义目标")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // 完成按钮
                Button(action: {
                    saveGoals()
                    onComplete()
                }) {
                    Text("完成设置")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func saveGoals() {
        // 保存目标到 UserDefaults 或数据库
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(selectedGoals) {
            UserDefaults.standard.set(encoded, forKey: "userGoals")
        }
    }
}

// MARK: - 目标行组件

struct GoalRow: View {
    @Binding var goal: UserGoal
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: goal.goalType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.purple)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.goalType.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("目标：\(goal.targetValue) \(goal.goalType.unit)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // 进度指示
                Text("\(Int(goal.progressPercentage * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.purple)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * goal.progressPercentage, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - 通知扩展

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

// MARK: - 预览

#Preview("Onboarding") {
    DreamOnboardingView()
}

#Preview("Permission") {
    PermissionRequestView(onComplete: {})
}

#Preview("Goals") {
    GoalSetupView(onComplete: {})
}
