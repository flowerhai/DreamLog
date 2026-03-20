//
//  DreamARPhotoEditorView.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Photo Editor View

/// AR 照片编辑器界面
struct DreamARPhotoEditorView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var photoMode: DreamARPhotoMode
    @StateObject private var viewModel = PhotoEditorViewModel()
    
    let arView: ARView
    let dream: Dream?
    
    // MARK: - State
    
    @State private var showingShareSheet = false
    @State private var showingFilterPicker = false
    @State private var showingSettings = false
    @State private var lastPhoto: ARPhotoCapture?
    @State private var isCapturing = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // AR 预览层
            ARViewContainer(arView: arView)
                .ignoresSafeArea()
            
            // 网格覆盖层
            if photoMode.showGrid {
                GridOverlay()
                    .ignoresSafeArea()
            }
            
            // 倒计时覆盖层
            if photoMode.isCountdownActive {
                CountdownOverlay(seconds: photoMode.countdownRemaining)
                    .ignoresSafeArea()
            }
            
            // 顶部工具栏
            VStack {
                TopToolbar(
                    isDepthEnabled: photoMode.isDepthEffectEnabled,
                    showGrid: photoMode.showGrid,
                    timerSeconds: photoMode.timerSeconds,
                    onDepthToggle: { photoMode.isDepthEffectEnabled.toggle() },
                    onGridToggle: { photoMode.showGrid.toggle() },
                    onTimerChange: { photoMode.timerSeconds = $0 },
                    onSettings: { showingSettings = true }
                )
                
                Spacer()
                
                // 底部控制栏
                BottomToolbar(
                    photoMode: photoMode,
                    isCapturing: isCapturing,
                    onFilterSelect: { showingFilterPicker = true },
                    onCapture: capturePhoto,
                    onGallery: showGallery
                )
            }
            
            // 滤镜选择器
            if showingFilterPicker {
                FilterPickerView(
                    photoMode: photoMode,
                    onSelect: { showingFilterPicker = false }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showingSettings) {
            PhotoSettingsView(photoMode: photoMode)
        }
        .sheet(isPresented: $viewModel.showingGallery) {
            PhotoGalleryView(photoMode: photoMode)
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let photo = lastPhoto {
                photoMode.sharePhoto(photo)
            }
        }
        .onAppear {
            setupView()
        }
    }
    
    // MARK: - Actions
    
    private func setupView() {
        // 配置 ARView
        arView.autoFocusSession = .enabled
    }
    
    private func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        
        Task {
            let photo = await photoMode.capturePhoto(from: arView, dream: dream)
            lastPhoto = photo
            isCapturing = false
            
            // 显示成功反馈
            if photo != nil {
                viewModel.showShareSheet = true
            }
        }
    }
    
    private func showGallery() {
        viewModel.showingGallery = true
    }
}

// MARK: - Photo Editor ViewModel

@MainActor
class PhotoEditorViewModel: ObservableObject {
    @Published var showingGallery = false
    @Published var showingShareSheet = false
}

// MARK: - Top Toolbar

struct TopToolbar: View {
    let isDepthEnabled: Bool
    let showGrid: Bool
    let timerSeconds: Int
    let onDepthToggle: () -> Void
    let onGridToggle: () -> Void
    let onTimerChange: (Int) -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack {
            // 景深开关
            Button(action: onDepthToggle) {
                Image(systemName: isDepthEnabled ? "circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isDepthEnabled ? .purple : .white)
            }
            .buttonStyle(.plain)
            
            Text("景深")
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            // 网格开关
            Button(action: onGridToggle) {
                Image(systemName: showGrid ? "square.grid.3x3.fill" : "square.grid.3x3")
                    .font(.title2)
                    .foregroundColor(showGrid ? .purple : .white)
            }
            .buttonStyle(.plain)
            
            // 定时器选择
            Menu {
                Button("关闭") { onTimerChange(0) }
                Button("3 秒") { onTimerChange(3) }
                Button("5 秒") { onTimerChange(5) }
                Button("10 秒") { onTimerChange(10) }
            } label: {
                Image(systemName: timerSeconds > 0 ? "timer" : "timer")
                    .font(.title2)
                    .foregroundColor(timerSeconds > 0 ? .purple : .white)
            }
            
            if timerSeconds > 0 {
                Text("\(timerSeconds)s")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            
            Spacer()
            
            // 设置按钮
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Bottom Toolbar

struct BottomToolbar: View {
    @ObservedObject var photoMode: DreamARPhotoMode
    let isCapturing: Bool
    let onFilterSelect: () -> Void
    let onCapture: () -> Void
    let onGallery: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 滤镜快捷栏
            FilterQuickBar(photoMode: photoMode, onSelect: onFilterSelect)
            
            HStack(spacing: 40) {
                // 画廊按钮
                Button(action: onGallery) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "photo.on.photo")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // 快门按钮
                Button(action: onCapture) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                    .scaleEffect(isCapturing ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isCapturing)
                }
                .buttonStyle(.plain)
                .disabled(isCapturing || photoMode.isCountdownActive)
                
                // 连拍开关
                Button(action: { photoMode.isBurstMode.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(photoMode.isBurstMode ? Color.purple : Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                            .foregroundColor(photoMode.isBurstMode ? .white : .white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Filter Quick Bar

struct FilterQuickBar: View {
    @ObservedObject var photoMode: DreamARPhotoMode
    let onSelect: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(photoMode.availableFilters.prefix(6)) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: photoMode.selectedFilter == filter,
                        onSelect: {
                            photoMode.selectedFilter = filter
                            onSelect()
                        }
                    )
                }
                
                Button(action: onSelect) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("更多")
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let filter: ARPhotoFilter
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Circle()
                    .fill(filter.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                
                Text(filter.rawValue)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Picker View

struct FilterPickerView: View {
    @ObservedObject var photoMode: DreamARPhotoMode
    @Environment(\.dismiss) var dismiss
    let onSelect: () -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            // 头部
            HStack {
                Text("选择滤镜")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("完成", action: {
                    dismiss()
                    onSelect()
                })
                .foregroundColor(.purple)
            }
            .padding()
            
            // 滤镜网格
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(photoMode.availableFilters) { filter in
                    FilterGridItem(
                        filter: filter,
                        isSelected: photoMode.selectedFilter == filter,
                        onSelect: {
                            photoMode.selectedFilter = filter
                        }
                    )
                }
            }
            .padding()
            
            // 滤镜强度滑块
            if photoMode.selectedFilter != .none {
                VStack(alignment: .leading) {
                    Text("强度")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Slider(
                        value: $photoMode.filterIntensity,
                        in: 0...100,
                        step: 5
                    )
                    .tint(.purple)
                    
                    Text("\(Int(photoMode.filterIntensity))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .padding()
            }
            
            Spacer()
        }
        .background(Color.black.opacity(0.95))
        .ignoresSafeArea()
    }
}

// MARK: - Filter Grid Item

struct FilterGridItem: View {
    let filter: ARPhotoFilter
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(filter.color)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: filter.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 3)
                )
                
                Text(filter.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid Overlay

struct GridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // 垂直线
                ForEach(1..<3) { i in
                    let x = width * CGFloat(i) / 3
                    Line(start: CGPoint(x: x, y: 0), end: CGPoint(x: x, y: height))
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
                
                // 水平线
                ForEach(1..<3) { i in
                    let y = height * CGFloat(i) / 3
                    Line(start: CGPoint(x: 0, y: y), end: CGPoint(x: width, y: y))
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            }
        }
    }
}

// MARK: - Line Shape

struct Line: Shape {
    let start: CGPoint
    let end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

// MARK: - Countdown Overlay

struct CountdownOverlay: View {
    let seconds: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 150, height: 150)
            
            Text("\(seconds)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .animation(.easeInOut(duration: 0.3), value: seconds)
        }
    }
}

// MARK: - Photo Settings View

struct PhotoSettingsView: View {
    @ObservedObject var photoMode: DreamARPhotoMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("景深效果")) {
                    Toggle("启用景深", isOn: $photoMode.isDepthEffectEnabled)
                    
                    if photoMode.isDepthEffectEnabled {
                        HStack {
                            Text("模糊强度")
                            Slider(value: $photoMode.depthBlurIntensity, in: 0...10, step: 0.5)
                            Text(String(format: "%.1f", photoMode.depthBlurIntensity))
                        }
                    }
                }
                
                Section(header: Text("构图辅助")) {
                    Toggle("显示网格", isOn: $photoMode.showGrid)
                }
                
                Section(header: Text("定时器")) {
                    Picker("倒计时", selection: $photoMode.timerSeconds) {
                        Text("关闭").tag(0)
                        Text("3 秒").tag(3)
                        Text("5 秒").tag(5)
                        Text("10 秒").tag(10)
                    }
                }
                
                Section(header: Text("连拍模式")) {
                    Toggle("启用连拍", isOn: $photoMode.isBurstMode)
                    
                    if photoMode.isBurstMode {
                        Stepper("连拍数量：\(photoMode.burstCount)", value: $photoMode.burstCount, in: 2...10)
                    }
                }
                
                Section(header: Text("存储")) {
                    Button("清除所有照片", role: .destructive) {
                        Task {
                            await photoMode.clearAllPhotos()
                        }
                    }
                    
                    Text("已保存 \(photoMode.photos.count) 张照片")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("照片设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Photo Gallery View

struct PhotoGalleryView: View {
    @ObservedObject var photoMode: DreamARPhotoMode
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhoto: ARPhotoCapture?
    @State private var showingShareSheet = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            Group {
                if photoMode.photos.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.photo.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("暂无照片")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("拍摄 AR 照片后会显示在这里")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(photoMode.photos) { photo in
                            PhotoGridItem(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                        }
                    }
                    .padding(8)
                }
            }
            .navigationTitle("AR 照片库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo, photoMode: photoMode)
        }
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let photo: ARPhotoCapture
    
    var body: some View {
        Image(uiImage: photo.image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 120)
            .clipped()
            .cornerRadius(8)
            .overlay(
                Group {
                    if photo.isBurstPhoto {
                        Image(systemName: "photo.badge.plus")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .padding(4)
                    }
                },
                alignment: .topTrailing
            )
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photo: ARPhotoCapture
    @ObservedObject var photoMode: DreamARPhotoMode
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                VStack {
                    Spacer()
                    
                    // 照片信息
                    VStack(alignment: .leading, spacing: 8) {
                        if let title = photo.dreamTitle {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Label(photo.filter.rawValue, systemImage: photo.filter.icon)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Text(photo.formattedDate)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                }
            }
            .navigationTitle("照片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("分享", action: { showingShareSheet = true })
                        Button("删除", role: .destructive) {
                            Task {
                                await photoMode.deletePhoto(photo)
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            photoMode.sharePhoto(photo)
        }
    }
}

// MARK: - ARView Container

struct ARPhotoEditorViewContainer: UIViewRepresentable {
    let arView: ARView
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - Preview

#Preview {
    DreamARPhotoEditorView(
        photoMode: DreamARPhotoMode.shared,
        arView: ARView(),
        dream: nil
    )
}
