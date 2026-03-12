//
//  DreamARView.swift
//  DreamLog - Phase 21: Dream AR Visualization
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import ARKit

// MARK: - Main AR View

/// 梦境 AR 可视化主界面
struct DreamARView: View {
    @StateObject private var arService: DreamARService
    @ObservedObject private var interactionService = DreamARInteractionService.shared
    @ObservedObject private var modelsLibrary = DreamARModelsLibrary.shared
    @ObservedObject private var templateService = DreamARTemplateService.shared
    
    @State private var selectedDream: Dream?
    @State private var showScenePicker = false
    @State private var showRecordingOptions = false
    @State private var showShareSheet = false
    @State private var showModelBrowser = false
    @State private var showTemplateGallery = false
    @State private var showInteractionPanel = false
    @State private var recordedVideoURL: URL?
    
    @Environment(\.dismiss) private var dismiss
    
    init(dream: Dream? = nil) {
        _arService = StateObject(wrappedValue: DreamARService())
        _selectedDream = State(initialValue: dream)
    }
    
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
                // 导航栏
                arNavigationBar
                
                Divider()
                
                // 主内容区
                if arService.sessionState == .idle {
                    idleView
                } else {
                    arContentView
                }
            }
        }
        .task {
            if let dream = selectedDream {
                await createARScene(from: dream)
            }
        }
        .alert("错误", isPresented: .constant(arService.errorMessage != nil)) {
            Button("确定") {
                arService.errorMessage = nil
            }
        } message: {
            Text(arService.errorMessage ?? "")
        }
    }
    
    // MARK: - Navigation Bar
    
    private var arNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("梦境 AR")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            if arService.currentScene != nil {
                HStack(spacing: 16) {
                    // 添加元素按钮
                    Menu {
                        Button(action: { showModelBrowser = true }) {
                            Label("浏览模型", systemImage: "cube.box")
                        }
                        
                        Button(action: { showTemplateGallery = true }) {
                            Label("场景模板", systemImage: "photo.on.rectangle.angled")
                        }
                    } label: {
                        Image(systemName: "plus.app")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    // 交互控制按钮
                    Button(action: { showInteractionPanel = true }) {
                        Image(systemName: "hand.point.up.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    // 更多选项
                    Menu {
                        Button(action: { showScenePicker = true }) {
                            Label("选择场景", systemImage: "list.bullet")
                        }
                        
                        Button(action: { showRecordingOptions = true }) {
                            Label("录制视频", systemImage: "video")
                        }
                        
                        Button(action: { shareCurrentScene() }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Idle View
    
    private var idleView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // AR 图标
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "cube.transparent")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
            }
            
            Text("梦境 AR 可视化")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("将你的梦境带入现实")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            // 操作按钮
            VStack(spacing: 15) {
                if selectedDream == nil {
                    Button(action: { showScenePicker = true }) {
                        HStack {
                            Image(systemName: "dream")
                            Text("选择梦境")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: { checkARSupport() }) {
                    HStack {
                        Image(systemName: "arkit")
                        Text("体验 AR")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // 功能说明
            featureList
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
        }
    }
    
    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            FeatureRow(icon: "sparkles", text: "AI 自动分析梦境元素")
            FeatureRow(icon: "cube.transparent", text: "3D 可视化梦境场景")
            FeatureRow(icon: "video", text: "录制 AR 视频分享")
            FeatureRow(icon: "wand.and.stars", text: "自定义环境和灯光")
        }
    }
    
    // MARK: - AR Content View
    
    private var arContentView: some View {
        ZStack {
            // AR 视图容器
            ARViewContainer(arService: arService)
                .ignoresSafeArea()
            
            // 录制指示器
            if arService.isRecording {
                recordingOverlay
            }
            
            // 底部控制栏
            bottomControlBar
        }
    }
    
    private var recordingOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text("录制中")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    
                    // 进度条
                    ProgressView(value: arService.recordingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .frame(width: 150)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var bottomControlBar: some View {
        HStack(spacing: 30) {
            // 截图按钮
            Button(action: { takeScreenshot() }) {
                VStack {
                    Image(systemName: "camera")
                        .font(.title2)
                    Text("截图")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            
            // 录制按钮
            Button(action: { toggleRecording() }) {
                ZStack {
                    Circle()
                        .fill(arService.isRecording ? Color.red : Color.white.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .fill(arService.isRecording ? Color.white : Color.red)
                        .frame(width: arService.isRecording ? 50 : 60,
                              height: arService.isRecording ? 50 : 60)
                }
            }
            
            // 分享按钮
            Button(action: { shareCurrentScene() }) {
                VStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                    Text("分享")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
        .padding()
    }
    
    // MARK: - Actions
    
    private func createARScene(from dream: Dream) async {
        do {
            try await arService.createScene(from: dream)
        } catch {
            arService.errorMessage = error.localizedDescription
        }
    }
    
    private func checkARSupport() {
        if !DreamARService.isARAvailable() {
            arService.errorMessage = "设备不支持 AR 功能"
            return
        }
        
        Task {
            let hasPermission = await DreamARService.checkCameraPermission()
            if !hasPermission {
                arService.errorMessage = "需要相机权限才能使用 AR"
                return
            }
            
            // 启动 AR
            if let dream = selectedDream {
                await createARScene(from: dream)
            }
        }
    }
    
    private func toggleRecording() {
        if arService.isRecording {
            arService.stopRecording()
        } else {
            Task {
                do {
                    recordedVideoURL = try await arService.startRecording()
                    showShareSheet = true
                } catch {
                    arService.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func takeScreenshot() {
        // 截图功能 (实际应使用 SCNView 的 snapshot 方法)
        print("截图功能")
    }
    
    private func shareCurrentScene() {
        guard let scene = arService.currentScene else { return }
        
        Task {
            do {
                let share = try await arService.shareScene(scene)
                // 显示分享界面
                showShareSheet = true
            } catch {
                arService.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arService: DreamARService
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = arService.setupARView()
        
        // 配置 AR 会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        
        if let scene = arService.currentScene {
            arService.displayScene(scene, in: arView)
        }
        
        arView.session.run(configuration)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // 更新 AR 视图
    }
}

// MARK: - Scene Picker

struct ARScenePicker: View {
    @ObservedObject var arService: DreamARService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(arService.availableScenes) { scene in
                Button(action: {
                    arService.currentScene = scene
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text(scene.sceneName)
                            .font(.headline)
                        Text("\(scene.elements.count) 个元素 • \(scene.environment.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("选择场景")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Recording Options

struct ARRecordingOptions: View {
    @State var duration: Double = 30
    @State var includeAudio: Bool = true
    @State var quality: ARVideoQuality = .high
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("录制时长")) {
                    Slider(value: $duration, in: 10...120, step: 10)
                    Text("\(Int(duration)) 秒")
                }
                
                Section(header: Text("选项")) {
                    Toggle("包含音频", isOn: $includeAudio)
                }
                
                Section(header: Text("视频质量")) {
                    Picker("质量", selection: $quality) {
                        Text("低").tag(ARVideoQuality.low)
                        Text("中").tag(ARVideoQuality.medium)
                        Text("高").tag(ARVideoQuality.high)
                        Text("超高").tag(ARVideoQuality.ultra)
                    }
                }
            }
            .navigationTitle("录制选项")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("开始录制") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Preview

#Preview {
    DreamARView()
}
