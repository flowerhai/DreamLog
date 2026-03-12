//
//  DreamARInteractionView.swift
//  DreamLog - Phase 22: AR Enhancement & 3D Dream World
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - Interaction View

/// AR 交互控制面板
struct DreamARInteractionView: View {
    @ObservedObject var interactionService: DreamARInteractionService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedElement: DreamARElement3D?
    @State private var showTransformControls = false
    @State private var showSceneOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前选择
                if let element = interactionService.selectedElement {
                    selectedElementHeader(element)
                } else {
                    emptySelectionHeader
                }
                
                Divider()
                
                // 交互模式
                interactionModeSection
                
                Divider()
                
                // 变换控制
                if interactionService.selectedElement != nil {
                    transformControlsSection
                }
                
                Divider()
                
                // 场景管理
                sceneManagementSection
                
                Spacer()
            }
            .navigationTitle("AR 交互")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: saveScene) {
                            Label("保存场景", systemImage: "arrow.down.doc")
                        }
                        
                        Button(action: loadScene) {
                            Label("加载场景", systemImage: "arrow.up.doc")
                        }
                        
                        Button(action: clearScene) {
                            Label("清空场景", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showSceneOptions) {
                ARSceneSelectionView { scene in
                    // 加载场景逻辑 - 从文件加载
                    do {
                        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
                        let sceneURL = documentsPath.appendingPathComponent("ARScenes/\(scene.id).json")
                        try interactionService.loadScene(from: sceneURL)
                        showSceneOptions = false
                    } catch {
                        print("加载场景失败：\(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Selected Element Header
    
    private func selectedElementHeader(_ element: DreamARElement3D) -> some View {
        HStack(spacing: 16) {
            // 元素图标
            ZStack {
                Circle()
                    .fill(element.category.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: element.category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(element.category.color)
            }
            
            // 元素信息
            VStack(alignment: .leading, spacing: 4) {
                Text(element.name)
                    .font(.headline)
                
                Text(element.category.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    Label(String(format: "%.1f", element.position.x), systemImage: "arrow.left.right")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Label(String(format: "%.1f", element.position.y), systemImage: "arrow.up.down")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Label(String(format: "%.1f", element.position.z), systemImage: "arrow.forward.backward")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // 删除按钮
            Button(action: deleteSelectedElement) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Empty Selection Header
    
    private var emptySelectionHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.point.up.left")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("点击元素进行选择")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.gray.opacity(0.03))
    }
    
    // MARK: - Interaction Mode Section
    
    private var interactionModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("交互模式")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(InteractionMode.allCases, id: \.self) { mode in
                        ModeButton(
                            mode: mode,
                            isSelected: interactionService.currentMode == mode
                        ) {
                            interactionService.currentMode = mode
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Transform Controls Section
    
    private var transformControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("变换控制")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // 位置控制
                if interactionService.currentMode == .move {
                    positionControls
                }
                
                // 旋转控制
                if interactionService.currentMode == .rotate {
                    rotationControls
                }
                
                // 缩放控制
                if interactionService.currentMode == .scale {
                    scaleControls
                }
                
                // 重置按钮
                resetButton
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Position Controls
    
    private var positionControls: some View {
        VStack(spacing: 12) {
            ControlSlider(
                label: "X 轴",
                icon: "arrow.left.right",
                value: interactionService.selectedElement?.position.x ?? 0,
                range: -5...5,
                step: 0.1
            ) { newValue in
                if let element = interactionService.selectedElement {
                    var newPosition = element.position
                    newPosition.x = newValue
                    interactionService.moveElement(element, to: newPosition)
                }
            }
            
            ControlSlider(
                label: "Y 轴",
                icon: "arrow.up.down",
                value: interactionService.selectedElement?.position.y ?? 0,
                range: -5...5,
                step: 0.1
            ) { newValue in
                if let element = interactionService.selectedElement {
                    var newPosition = element.position
                    newPosition.y = newValue
                    interactionService.moveElement(element, to: newPosition)
                }
            }
            
            ControlSlider(
                label: "Z 轴",
                icon: "arrow.forward.backward",
                value: interactionService.selectedElement?.position.z ?? 0,
                range: -5...5,
                step: 0.1
            ) { newValue in
                if let element = interactionService.selectedElement {
                    var newPosition = element.position
                    newPosition.z = newValue
                    interactionService.moveElement(element, to: newPosition)
                }
            }
        }
    }
    
    // MARK: - Rotation Controls
    
    private var rotationControls: some View {
        VStack(spacing: 12) {
            ControlSlider(
                label: "X 旋转",
                icon: "arrow.2.square",
                value: interactionService.selectedElement?.rotation.x ?? 0,
                range: 0...360,
                step: 1
            ) { newValue in
                if let element = interactionService.selectedElement {
                    var newRotation = element.rotation
                    newRotation.x = newValue
                    interactionService.rotateElement(element, by: newRotation)
                }
            }
            
            ControlSlider(
                label: "Y 旋转",
                icon: "arrow.2.square",
                value: interactionService.selectedElement?.rotation.y ?? 0,
                range: 0...360,
                step: 1
            ) { newValue in
                if let element = interactionService.selectedElement {
                    var newRotation = element.rotation
                    newRotation.y = newValue
                    interactionService.rotateElement(element, by: newRotation)
                }
            }
            
            ControlSlider(
                label: "Z 旋转",
                icon: "arrow.2.square",
                value: interactionService.selectedElement?.rotation.z ?? 0,
                range: 0...360,
                step: 1
            ) { newValue in
                if let element = interactionService.selectedElement {
                    var newRotation = element.rotation
                    newRotation.z = newValue
                    interactionService.rotateElement(element, by: newRotation)
                }
            }
        }
    }
    
    // MARK: - Scale Controls
    
    private var scaleControls: some View {
        VStack(spacing: 12) {
            ControlSlider(
                label: "大小",
                icon: "arrow.up.left.and.arrow.down.right",
                value: Float(interactionService.selectedElement?.scale ?? 1.0),
                range: 0.1...5,
                step: 0.1
            ) { newValue in
                if let element = interactionService.selectedElement {
                    interactionService.scaleElement(element, to: CGFloat(newValue))
                }
            }
        }
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button(action: resetTransform) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("重置变换")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.primary)
            .cornerRadius(10)
        }
    }
    
    // MARK: - Scene Management Section
    
    private var sceneManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("场景管理")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                SceneActionButton(
                    title: "保存场景",
                    icon: "arrow.down.doc",
                    color: .blue
                ) {
                    saveScene()
                }
                
                SceneActionButton(
                    title: "加载场景",
                    icon: "arrow.up.doc",
                    color: .green
                ) {
                    loadScene()
                }
                
                SceneActionButton(
                    title: "清空场景",
                    icon: "trash",
                    color: .red
                ) {
                    clearScene()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Actions
    
    private func deleteSelectedElement() {
        if let element = interactionService.selectedElement {
            interactionService.removeElement(element)
        }
    }
    
    private func resetTransform() {
        if let element = interactionService.selectedElement {
            interactionService.resetElementTransform(element)
        }
    }
    
    private func saveScene() {
        Task {
            do {
                try await interactionService.saveScene(name: "场景_\(Date().timeIntervalSince1970)")
            } catch {
                print("保存场景失败：\(error)")
            }
        }
    }
    
    private func loadScene() {
        showSceneOptions = true
    }
    
    private func clearScene() {
        interactionService.clearScene()
    }
}

// MARK: - Mode Button

struct ModeButton: View {
    let mode: InteractionMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.title2)
                
                Text(mode.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mode.color : mode.color.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : mode.color)
        }
    }
}

// MARK: - Control Slider

struct ControlSlider: View {
    let label: String
    let icon: String
    let value: Float
    let range: ClosedRange<Float>
    let step: Float
    let onChange: (Float) -> Void
    
    @State private var sliderValue: Double
    
    init(
        label: String,
        icon: String,
        value: Float,
        range: ClosedRange<Float>,
        step: Float,
        onChange: @escaping (Float) -> Void
    ) {
        self.label = label
        self.icon = icon
        self.value = value
        self.range = range
        self.step = step
        self.onChange = onChange
        _sliderValue = State(initialValue: Double(value))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 50)
            }
            
            Slider(
                value: $sliderValue,
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            ) { editingChanged in
                if !editingChanged {
                    onChange(Float(sliderValue))
                }
            }
        }
    }
}

// MARK: - Scene Action Button

struct SceneActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 30)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    DreamARInteractionView(
        interactionService: DreamARInteractionService.shared
    )
}
