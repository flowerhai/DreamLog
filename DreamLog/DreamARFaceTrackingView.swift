//
//  DreamARFaceTrackingView.swift
//  DreamLog
//
//  面部追踪 UI 界面 - Phase 24
//

import SwiftUI
import ARKit
import UIKit
import Photos

// MARK: - 面部追踪主界面

struct DreamARFaceTrackingView: View {
    @StateObject private var faceTrackingService = DreamARFaceTrackingService.shared
    @State private var showingConfigSheet = false
    @State private var showingAvatarPicker = false
    @State private var showingAchievements = false
    @State private var screenshotView: UIView?
    @State private var showingScreenshotAlert = false
    @State private var screenshotSaved = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            faceTrackingNavigationBar
            
            Divider()
            
            // 主内容
            if faceTrackingService.isTracking {
                faceTrackingContent
            } else {
                faceTrackingIdleContent
            }
        }
        .sheet(isPresented: $showingConfigSheet) {
            FaceTrackingConfigView()
        }
        .sheet(isPresented: $showingAvatarPicker) {
            AvatarPickerView()
        }
        .sheet(isPresented: $showingAchievements) {
            FaceTrackingAchievementsView()
        }
    }
    
    // MARK: - 导航栏
    
    private var faceTrackingNavigationBar: some View {
        HStack {
            Text("面部追踪")
                .font(.title2.bold())
            
            Spacer()
            
            // 成就按钮
            Button(action: { showingAchievements = true }) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            // 配置按钮
            Button(action: { showingConfigSheet = true }) {
                Image(systemName: "gearshape.fill")
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - 追踪中内容
    
    private var faceTrackingContent: some View {
        ZStack {
            // AR 视图占位符
            ARViewContainerRepresentable()
                .ignoresSafeArea()
            
            // 面部状态覆盖层
            VStack {
                HStack {
                    Spacer()
                    
                    // 面部状态卡片
                    if let faceState = faceTrackingService.currentFaceState {
                        FaceStateCard(faceState: faceState)
                            .padding()
                    }
                }
                
                Spacer()
                
                // 底部控制栏
                faceTrackingControlBar
                    .padding()
            }
        }
    }
    
    // MARK: - 空闲状态内容
    
    private var faceTrackingIdleContent: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 标题和说明
                idleHeader
                
                // 功能特性
                idleFeatures
                
                // 虚拟化身预览
                if let avatar = faceTrackingService.currentAvatar {
                    avatarPreviewCard(avatar)
                }
                
                // 开始按钮
                startTrackingButton
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    private var idleHeader: some View {
        VStack(spacing: 12) {
            Text("🎭 面部追踪")
                .font(.system(size: 60))
            
            Text("用你的表情驱动 AR 元素")
                .font(.title2.bold())
            
            Text("支持实时表情捕捉和虚拟化身")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var idleFeatures: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "😐",
                title: "表情识别",
                description: "5 种基础表情实时捕捉"
            )
            
            FeatureRow(
                icon: "👤",
                title: "虚拟化身",
                description: "多种虚拟化身可选"
            )
            
            FeatureRow(
                icon: "✨",
                title: "表情驱动",
                description: "AR 元素随表情动画"
            )
        }
    }
    
    private func avatarPreviewCard(_ avatar: AvatarModel) -> some View {
        VStack(spacing: 12) {
            Text("当前虚拟化身")
                .font(.headline)
            
            HStack(spacing: 16) {
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(avatar.name)
                        .font(.headline)
                    Text(avatar.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: { showingAvatarPicker = true }) {
                Text("更换虚拟化身")
                    .font(.subheadline.bold())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var startTrackingButton: some View {
        Button(action: {
            faceTrackingService.startTracking()
        }) {
            HStack {
                Image(systemName: "camera.fill")
                Text("开始面部追踪")
            }
            .font(.headline.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - 控制栏
    
    private var faceTrackingControlBar: some View {
        HStack(spacing: 20) {
            // 虚拟化身按钮
            Button(action: { showingAvatarPicker = true }) {
                VStack {
                    Image(systemName: "person.fill")
                        .font(.title2)
                    Text("虚拟化身")
                        .font(.caption)
                }
                .frame(width: 70, height: 70)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // 停止按钮
            Button(action: {
                faceTrackingService.stopTracking()
            }) {
                VStack {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("停止")
                        .font(.caption)
                }
                .frame(width: 70, height: 70)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // 截图按钮
            Button(action: {
                captureScreenshot()
            }) {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(screenshotSaved ? .green : .primary)
                    Text("截图")
                        .font(.caption)
                }
                .frame(width: 70, height: 70)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .alert("截图已保存", isPresented: $showingScreenshotAlert) {
                Button("查看", role: .default) {
                    // 可以跳转到相册
                }
                Button("好的", role: .cancel) { }
            } message: {
                Text("面部追踪截图已保存到相册")
            }
        }
    }
    
    // MARK: - 截图功能
    
    /// 捕获当前面部追踪界面的截图并保存到相册
    private func captureScreenshot() {
        // 获取主窗口
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // 使用 UIGraphicsImageRenderer 捕获屏幕
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        
        // 保存到相册
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        // 触发轻微触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// 图片保存完成回调
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if error == nil {
                screenshotSaved = true
                showingScreenshotAlert = true
                
                // 1 秒后重置状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    screenshotSaved = false
                }
            } else {
                // 保存失败，可能是权限问题
                showingScreenshotAlert = true
            }
        }
    }
}

// MARK: - 面部状态卡片

struct FaceStateCard: View {
    let faceState: FaceExpressionState
    
    var body: some View {
        VStack(spacing: 8) {
            // 表情图标
            Text(faceState.primaryExpression.emoji)
                .font(.system(size: 40))
            
            // 表情名称
            Text(faceState.primaryExpression.displayName.replacingOccurrences(of: " ", with: ""))
                .font(.caption.bold())
            
            // 置信度
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("\(Int(faceState.confidence * 100))%")
                    .font(.caption2)
            }
        }
        .padding(12)
        .background(
            Color(.systemBackground)
                .opacity(0.9)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 功能特性行

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - AR 视图容器

struct ARViewContainerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        // 配置 AR 场景
        return view
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // 更新 AR 场景
    }
}

// MARK: - 配置界面

struct FaceTrackingConfigView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DreamARFaceTrackingService.shared
    @State private var config: FaceTrackingConfig = .default
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本设置")) {
                    Toggle("启用面部追踪", isOn: $config.isEnabled)
                    
                    Toggle("表情驱动动画", isOn: $config.enableExpressionAnimation)
                    
                    Toggle("虚拟化身", isOn: $config.enableAvatar)
                }
                
                Section(header: Text("表情设置")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("表情灵敏度")
                            Spacer()
                            Text("\(Int(config.expressionSensitivity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $config.expressionSensitivity, in: 0.1...1.0)
                    }
                    
                    Toggle("记录表情历史", isOn: $config.recordExpressionHistory)
                    
                    if config.recordExpressionHistory {
                        Stepper("最大历史记录：\(config.maxHistoryCount)",
                                value: $config.maxHistoryCount,
                                in: 10...500,
                                step: 10)
                    }
                }
                
                Section(header: Text("数据管理")) {
                    Button("清除表情历史", role: .destructive) {
                        service.expressionHistory.removeAll()
                    }
                    
                    Button("重置配置") {
                        config = .default
                    }
                }
            }
            .navigationTitle("面部追踪配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        service.updateConfig(config)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 虚拟化身选择器

struct AvatarPickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DreamARFaceTrackingService.shared
    @State private var selectedCategory: AvatarModel.AvatarCategory = .basic
    
    var filteredAvatars: [AvatarModel] {
        AvatarModel.presets.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 类别选择器
                avatarCategoryPicker
                
                Divider()
                
                // 虚拟化身列表
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredAvatars) { avatar in
                            AvatarCard(avatar: avatar) {
                                service.setAvatar(avatar)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("选择虚拟化身")
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
    
    private var avatarCategoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AvatarModel.AvatarCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        Text(category.displayName)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category
                                ? Color.purple
                                : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedCategory == category
                                ? .white
                                : .primary
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - 虚拟化身卡片

struct AvatarCard: View {
    let avatar: AvatarModel
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: avatar.isUnlocked ? "person.fill" : "person.fill.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(avatar.isUnlocked ? .purple : .gray)
                
                Text(avatar.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                
                if !avatar.isUnlocked {
                    Text(avatar.unlockCondition ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Color(.systemBackground)
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .disabled(!avatar.isUnlocked)
        .opacity(avatar.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - 成就界面

struct FaceTrackingAchievementsView: View {
    @Environment(\.dismiss) var dismiss
    
    let achievements = FaceTrackingAchievement.presets
    
    var body: some View {
        NavigationView {
            List {
                ForEach(achievements) { achievement in
                    HStack(spacing: 16) {
                        Text(achievement.icon)
                            .font(.system(size: 32))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(achievement.name)
                                .font(.headline)
                            Text(achievement.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let date = achievement.unlockedDate {
                                Text("解锁于：\(date.formatted())")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        if achievement.isUnlocked {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("面部追踪成就")
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

// MARK: - 预览

#Preview {
    DreamARFaceTrackingView()
}
