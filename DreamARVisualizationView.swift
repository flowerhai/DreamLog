//
//  DreamARVisualizationView.swift
//  DreamLog
//
//  Created for Phase 48 - AR 梦境场景可视化
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import ARKit
import SwiftData

// MARK: - AR 梦境可视化主视图

struct DreamARVisualizationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service = DreamARVisualizationService.shared
    @State private var isARActive = false
    @State private var showSceneSelector = false
    @State private var selectedScene: ARDreamScene?
    @State private var showSettings = false
    @State private var errorMessage: String?
    
    let dreamID: UUID
    let dreamContent: String
    let dreamSymbols: [String]
    let dreamEmotions: [String]
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 顶部导航栏
                headerView
                
                Spacer()
                
                // 主内容区
                if isARActive {
                    arContentView
                } else {
                    welcomeView
                }
                
                Spacer()
                
                // 底部控制栏
                controlBarView
            }
            .padding()
            
            // 错误提示
            if let error = errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                    Spacer()
                }
            }
            
            // 场景选择器
            if showSceneSelector {
                SceneSelectorView(
                    selectedScene: $selectedScene,
                    onSelect: { scene in
                        selectedScene = scene
                        showSceneSelector = false
                        startARExperience()
                    },
                    onCreateNew: {
                        showSceneSelector = false
                        createNewScene()
                    }
                )
            }
        }
        .onAppear {
            service.configure(modelContext: modelContext)
        }
    }
    
    // MARK: - 子视图
    
    private var headerView: some View {
        HStack {
            Button(action: { showSceneSelector = true }) {
                HStack {
                    Image(systemName: "cube.box.fill")
                    Text(selectedScene?.sceneName ?? "选择场景")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Image(systemName: "arkit")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
            
            Text("AR 梦境可视化")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("将你的梦境带入现实")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "star.fill", text: "梦境符号 3D 呈现")
                FeatureRow(icon: "heart.fill", text: "情绪光效可视化")
                FeatureRow(icon: "sparkles", text: "粒子特效渲染")
                FeatureRow(icon: "move.3d", text: "自由移动探索")
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            Button(action: { showSceneSelector = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始 AR 体验")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.white)
                .cornerRadius(30)
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var arContentView: some View {
        ZStack {
            ARViewContainer(
                scene: selectedScene,
                service: service
            )
            .ignoresSafeArea()
            
            // AR 覆盖层
            VStack {
                HStack {
                    Spacer()
                    ARControlButtons(
                        onScreenshot: takeScreenshot,
                        onRecord: startRecording,
                        onPause: togglePause
                    )
                }
                .padding()
                
                Spacer()
                
                // 元素信息面板
                if let scene = selectedScene {
                    ElementInfoPanel(scene: scene)
                        .padding()
                }
            }
        }
    }
    
    private var controlBarView: some View {
        HStack(spacing: 30) {
            ControlButton(icon: "list.bullet", label: "场景") {
                showSceneSelector = true
            }
            
            ControlButton(icon: "plus", label: "添加") {
                addNewElement()
            }
            
            ControlButton(icon: "wand.and.stars", label: "特效") {
                toggleEffects()
            }
            
            ControlButton(icon: "photo.on.rectangle", label: "截图") {
                takeScreenshot()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.black.opacity(0.5))
        .cornerRadius(25)
    }
    
    // MARK: - 动作方法
    
    private func createNewScene() {
        Task {
            do {
                let scene = try await service.createScene(
                    for: dreamID,
                    dreamContent: dreamContent,
                    dreamSymbols: dreamSymbols,
                    dreamEmotions: dreamEmotions
                )
                selectedScene = scene
                startARExperience()
            } catch {
                errorMessage = "创建场景失败：\(error.localizedDescription)"
            }
        }
    }
    
    private func startARExperience() {
        withAnimation(.spring()) {
            isARActive = true
        }
        
        Task {
            if let scene = selectedScene {
                await service.recordSceneView(scene)
            }
        }
    }
    
    private func takeScreenshot() {
        // 截图功能
        print("截取 AR 场景截图")
    }
    
    private func startRecording() {
        // 录制功能
        print("开始录制 AR 场景")
    }
    
    private func togglePause() {
        // 暂停/继续
        print("切换暂停状态")
    }
    
    private func addNewElement() {
        // 添加新元素
        print("添加新元素")
    }
    
    private func toggleEffects() {
        // 切换特效
        print("切换特效")
    }
}

// MARK: - 功能行组件

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 24)
            
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - 控制按钮组件

struct ControlButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: - AR 控制按钮

struct ARControlButtons: View {
    let onScreenshot: () -> Void
    let onRecord: () -> Void
    let onPause: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ARButton(icon: "camera.fill", action: onScreenshot)
            ARButton(icon: "record.circle", action: onRecord)
            ARButton(icon: "pause.fill", action: onPause)
        }
    }
}

struct ARButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
}

// MARK: - 元素信息面板

struct ElementInfoPanel: View {
    @ObservedObject var scene: ARDreamScene
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("场景元素")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(scene.elements.count) 个元素")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(scene.elements.prefix(5).array, id: \.id) { element in
                        ElementBadge(element: element)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
    }
}

struct ElementBadge: View {
    let element: ARDreamElement
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: element.type.icon)
                .font(.caption)
            Text(element.name)
                .font(.caption)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - 场景选择器视图

struct SceneSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var scenes: [ARDreamScene] = []
    @State private var isLoading = true
    
    @Binding var selectedScene: ARDreamScene?
    let onSelect: (ARDreamScene) -> Void
    let onCreateNew: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("选择 AR 场景")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                // 场景列表
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if scenes.isEmpty {
                    EmptyStateView(onCreate: onCreateNew)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(scenes) { scene in
                                SceneCard(
                                    scene: scene,
                                    onSelect: {
                                        selectedScene = scene
                                        onSelect(scene)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                // 创建新场景按钮
                Button(action: onCreateNew) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("创建新场景")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadScenes()
        }
    }
    
    private func loadScenes() {
        Task {
            let service = DreamARVisualizationService.shared
            service.configure(modelContext: modelContext)
            scenes = (try? await service.getAllScenes()) ?? []
            isLoading = false
        }
    }
}

// MARK: - 场景卡片

struct SceneCard: View {
    let scene: ARDreamScene
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 15) {
                // 场景图标
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "cube.box.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                
                // 场景信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(scene.sceneName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if scene.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(scene.sceneDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(scene.elements.count)", systemImage: "star.fill")
                        Label("\(scene.viewCount)", systemImage: "eye.fill")
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
    }
}

// MARK: - 空状态视图

struct EmptyStateView: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.box")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("暂无 AR 场景")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("为你的梦境创建第一个 AR 场景")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: onCreate) {
                Text("立即创建")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.purple)
            .cornerRadius(20)
        }
        .padding(40)
    }
}

// MARK: - AR 视图容器

struct ARVisualizationViewContainer: UIViewRepresentable {
    let scene: ARDreamScene?
    let service: DreamARVisualizationService
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // 更新场景内容
        if let scene = scene {
            context.coordinator.loadScene(scene, into: uiView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(service: service)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var service: DreamARVisualizationService
        
        init(service: DreamARVisualizationService) {
            self.service = service
        }
        
        func loadScene(_ scene: ARDreamScene, into arView: ARSCNView) {
            // 加载场景元素到 AR 视图
            for element in scene.elements {
                addElementToScene(element, in: arView.scene)
            }
        }
        
        private func addElementToScene(_ element: ARDreamElement, in scene: SCNScene) {
            let node = SCNNode()
            node.position = SCNVector3(element.position.x, element.position.y, element.position.z)
            
            // 根据元素类型创建几何体
            if element.type == .symbol, let symbol = DreamSymbol(rawValue: element.content) {
                let geometry = SCNText(string: symbol.sfSymbol, extrusionDepth: 1)
                geometry.firstMaterial?.diffuse.contents = UIColor(hex: element.color ?? "#FFFFFF")
                node.geometry = geometry
            } else if element.type == .particle {
                // 创建粒子系统
                let particleSystem = createParticleSystem(for: element)
                node.emitterNode = SCNEmitterNode(emitter: particleSystem)
            }
            
            scene.rootNode.addChildNode(node)
        }
        
        private func createParticleSystem(for element: ARDreamElement) -> SCNParticleSystem {
            let particleSystem = SCNParticleSystem()
            particleSystem.particleImage = UIImage(systemName: "sparkles")
            particleSystem.birthRate = 20
            particleSystem.lifetime = 3
            particleSystem.particleSize = 0.02
            return particleSystem
        }
    }
}

// MARK: - 颜色扩展

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - 数组扩展

extension Array {
    var array: [Element] { self }
}

// MARK: - 预览

#Preview {
    DreamARVisualizationView(
        dreamID: UUID(),
        dreamContent: "我在一个星空下飞翔",
        dreamSymbols: ["star", "flying", "night"],
        dreamEmotions: ["平静", "自由"]
    )
}
