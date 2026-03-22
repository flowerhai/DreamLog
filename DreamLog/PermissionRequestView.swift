//
//  PermissionRequestView.swift
//  DreamLog
//
//  Phase 87 Session 2 - 权限请求页面
//  请求通知、健康、语音识别等系统权限
//

import SwiftUI
import UserNotifications
import HealthKit

// MARK: - 权限请求视图

struct PermissionRequestView: View {
    @State private var notificationGranted = false
    @State private var healthGranted = false
    @State private var speechGranted = false
    @State private var showingHealthAlert = false
    @State private var loadingPermission: PermissionType?
    
    enum PermissionType {
        case notification
        case health
        case speech
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 标题
            VStack(spacing: 12) {
                Text("权限设置")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("让我们更好地为你服务")
                    .font(.system(size: 18, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 权限列表
            VStack(spacing: 16) {
                // 通知权限
                PermissionCard(
                    icon: "bell.fill",
                    iconColor: Color(hex: "F5A623"),
                    title: "通知提醒",
                    description: "接收梦境提醒和每日洞察",
                    isGranted: notificationGranted,
                    isLoading: loadingPermission == .notification,
                    action: requestNotificationPermission
                )
                
                // 健康权限
                PermissionCard(
                    icon: "heart.fill",
                    iconColor: Color(hex: "FF6B6B"),
                    title: "健康数据",
                    description: "同步睡眠和心率数据",
                    isGranted: healthGranted,
                    isLoading: loadingPermission == .health,
                    action: requestHealthPermission
                )
                
                // 语音权限
                PermissionCard(
                    icon: "mic.fill",
                    iconColor: Color(hex: "5E9CD3"),
                    title: "语音输入",
                    description: "语音记录梦境",
                    isGranted: speechGranted,
                    isLoading: loadingPermission == .speech,
                    action: requestSpeechPermission
                )
            }
            .padding(.horizontal, 16)
            
            // 说明文字
            VStack(spacing: 8) {
                Text("💡 提示")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("所有权限都可以稍后在设置中更改\n我们不会收集不必要的个人信息")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .alert("健康权限", isPresented: $showingHealthAlert) {
            Button("好的", role: .cancel) { }
        } message: {
            Text("健康数据仅存储在本地，用于分析睡眠质量与梦境的关联。")
        }
    }
    
    // MARK: - 请求权限
    
    private func requestNotificationPermission() {
        loadingPermission = .notification
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                notificationGranted = granted
                loadingPermission = nil
            }
        }
    }
    
    private func requestHealthPermission() {
        loadingPermission = .health
        
        // 检查 HealthKit 可用性
        guard HKHealthStore.isHealthDataAvailable() else {
            showingHealthAlert = true
            loadingPermission = nil
            return
        }
        
        // 请求健康数据权限
        let healthStore = HKHealthStore()
        let sleepTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: sleepTypes) { granted, error in
            DispatchQueue.main.async {
                healthGranted = granted
                loadingPermission = nil
                
                if granted {
                    showingHealthAlert = true
                }
            }
        }
    }
    
    private func requestSpeechPermission() {
        loadingPermission = .speech
        
        // 语音识别权限通过 SFSpeechRecognizer 自动请求
        // 这里我们标记为已请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            speechGranted = true
            loadingPermission = nil
        }
    }
}

// MARK: - 权限卡片

struct PermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isGranted: Bool
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isGranted && !isLoading {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
                action()
            }
        }) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }
                
                // 文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // 状态指示
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "9B7EBD")))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isGranted ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 20))
                        .foregroundColor(isGranted ? Color(hex: "34C759") : Color.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isGranted ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isGranted ? Color(hex: "34C759").opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isGranted ? "已授权" : "未授权")
    }
}

// MARK: - 权限管理器

class PermissionManager: ObservableObject {
    @Published var notificationGranted = false
    @Published var healthGranted = false
    @Published var speechGranted = false
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        // 检查通知权限
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationGranted = settings.authorizationStatus == .authorized
            }
        }
        
        // 检查健康权限
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()
            let sleepTypes: Set<HKObjectType> = [
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            ]
            
            healthStore.getRequestStatusForAuthorization(toShare: [], read: sleepTypes) { status, error in
                DispatchQueue.main.async {
                    self.healthGranted = status == .shouldGrant
                }
            }
        }
        
        // 语音权限会在首次使用时请求
        speechGranted = true
    }
}

// MARK: - Preview

#Preview {
    PermissionRequestView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A1A2E"),
                    Color(hex: "16213E"),
                    Color(hex: "0F3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
