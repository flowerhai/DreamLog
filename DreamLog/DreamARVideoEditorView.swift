//
//  DreamARVideoEditorView.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit

// MARK: - AR Video Editor View

/// AR 视频编辑器界面
struct DreamARVideoEditorView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var videoMode: DreamARVideoMode
    @StateObject private var viewModel = VideoEditorViewModel()
    
    let arView: ARView
    let dream: Dream?
    
    // MARK: - State
    
    @State private var showingShareSheet = false
    @State private var showingFilterPicker = false
    @State private var showingQualitySettings = false
    @State private var lastVideo: ARVideoCapture?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // AR 预览层
            ARViewContainer(arView: arView)
                .ignoresSafeArea()
            
            // 录制指示器
            if videoMode.isRecording {
                RecordingOverlay(
                    isRecording: videoMode.isRecording,
                    timeRemaining: videoMode.recordingTimeRemaining,
                    progress: videoMode.recordingProgress,
                    isPaused: viewModel.isPaused,
                    mode: videoMode.recordingModeDescription
                )
                .ignoresSafeArea()
            }
            
            // 顶部工具栏
            VStack {
                TopVideoToolbar(
                    videoMode: videoMode,
                    onQualityChange: { showingQualitySettings = true },
                    onSpatialAudioToggle: { videoMode.isSpatialAudioEnabled.toggle() }
                )
                
                Spacer()
                
                // 底部控制栏
                BottomVideoToolbar(
                    videoMode: videoMode,
                    onFilterSelect: { showingFilterPicker = true },
                    onRecordToggle: toggleRecording,
                    onPauseToggle: { viewModel.isPaused.toggle() },
                    onCancel: cancelRecording
                )
            }
            
            // 滤镜选择器
            if showingFilterPicker {
                VideoFilterPickerView(
                    videoMode: videoMode,
                    onSelect: { showingFilterPicker = false }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .sheet(isPresented: $showingQualitySettings) {
            VideoQualitySettingsView(videoMode: videoMode)
        }
        .sheet(isPresented: $viewModel.showingGallery) {
            VideoGalleryView(videoMode: videoMode)
        }
        .onChange(of: videoMode.isRecording) { oldValue, newValue in
            if !newValue && lastVideo != nil {
                // 录制完成，显示分享
                showingShareSheet = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleRecording() {
        if videoMode.isRecording {
            // 停止录制
            Task {
                lastVideo = await videoMode.stopRecording(from: arView, dream: dream)
            }
        } else {
            // 开始录制
            Task {
                await videoMode.startRecording(from: arView, dream: dream)
            }
        }
    }
    
    private func cancelRecording() {
        videoMode.cancelRecording()
    }
}

// MARK: - Video Editor ViewModel

@MainActor
class VideoEditorViewModel: ObservableObject {
    @Published var showingGallery = false
    @Published var showingShareSheet = false
    @Published var isPaused = false
}

// MARK: - Top Video Toolbar

struct TopVideoToolbar: View {
    @ObservedObject var videoMode: DreamARVideoMode
    let onQualityChange: () -> Void
    let onSpatialAudioToggle: () -> Void
    
    var body: some View {
        HStack {
            // 质量指示器
            Button(action: onQualityChange) {
                HStack(spacing: 4) {
                    Image(systemName: "video.badge.checkmark")
                        .font(.caption)
                    Text(videoMode.recordingQuality.resolution)
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 空间音频开关
            Button(action: onSpatialAudioToggle) {
                HStack(spacing: 4) {
                    Image(systemName: videoMode.isSpatialAudioEnabled ? "waveform.circle.fill" : "waveform.circle")
                        .font(.caption)
                    Text("空间音频")
                        .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(videoMode.isSpatialAudioEnabled ? Color.purple.opacity(0.7) : Color.black.opacity(0.5))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            // 模式指示器
            if videoMode.isSlowMotionMode {
                Text("慢动作 \(videoMode.slowMotionRate.rawValue)")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(8)
            } else if videoMode.isTimeLapseMode {
                Text("延时摄影")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.7))
                    .cornerRadius(8)
            }
        }
        .padding()
        .foregroundColor(.white)
    }
}

// MARK: - Bottom Video Toolbar

struct BottomVideoToolbar: View {
    @ObservedObject var videoMode: DreamARVideoMode
    let onFilterSelect: () -> Void
    let onRecordToggle: () -> Void
    let onPauseToggle: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 模式切换
            HStack(spacing: 12) {
                ModeButton(
                    title: "视频",
                    icon: "video",
                    isActive: !videoMode.isSlowMotionMode && !videoMode.isTimeLapseMode
                ) {
                    videoMode.isSlowMotionMode = false
                    videoMode.isTimeLapseMode = false
                }
                
                ModeButton(
                    title: "慢动作",
                    icon: "slowmo",
                    isActive: videoMode.isSlowMotionMode
                ) {
                    videoMode.isSlowMotionMode = true
                    videoMode.isTimeLapseMode = false
                }
                
                ModeButton(
                    title: "延时",
                    icon: "timer",
                    isActive: videoMode.isTimeLapseMode
                ) {
                    videoMode.isSlowMotionMode = false
                    videoMode.isTimeLapseMode = true
                }
            }
            .padding(.horizontal)
            
            // 滤镜快捷栏
            FilterQuickBar(
                selectedFilter: videoMode.selectedFilter,
                filters: Array(videoMode.availableFilters.prefix(5)),
                onSelect: onFilterSelect
            )
            
            // 录制控制
            HStack(spacing: 40) {
                // 画廊按钮
                Button(action: { }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // 录制按钮
                ZStack {
                    if videoMode.isRecording {
                        // 停止按钮
                        Button(action: onRecordToggle) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 64, height: 64)
                        }
                    } else {
                        // 开始录制按钮
                        Button(action: onRecordToggle) {
                            Circle()
                                .stroke(Color.red, lineWidth: 4)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 56, height: 56)
                                )
                        }
                    }
                }
                
                // 设置按钮
                Button(action: { }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.bottom)
    }
}

// MARK: - Mode Button

struct ModeButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isActive ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isActive ? Color.purple.opacity(0.7) : Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Quick Bar

struct FilterQuickBar: View {
    let selectedFilter: ARVideoFilter
    let filters: [ARVideoFilter]
    let onSelect: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        // 快速切换滤镜
                    }
                }
                
                // 更多滤镜按钮
                Button(action: onSelect) {
                    VStack {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                        Text("更多")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let filter: ARVideoFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(filter.color.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: filter.icon)
                            .foregroundColor(.white)
                            .font(.caption)
                    )
                
                Text(filter.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .purple : .white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recording Overlay

struct RecordingOverlay: View {
    let isRecording: Bool
    let timeRemaining: Int
    let progress: Double
    let isPaused: Bool
    let mode: String
    
    var body: some View {
        VStack {
            HStack {
                // 录制指示器
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .animation(.repeatForever(every: 1.0), value: isRecording)
                    
                    Text("录制中")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(16)
                
                Spacer()
                
                // 模式标签
                Text(mode)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.7))
                    .cornerRadius(16)
            }
            .padding()
            
            Spacer()
            
            // 进度条
            VStack(spacing: 8) {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress > 0.8 ? Color.red : Color.purple)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal: 40)
                
                if isPaused {
                    Text("已暂停")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
            }
            .padding(.bottom: 40)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Video Quality Settings View

struct VideoQualitySettingsView: View {
    @ObservedObject var videoMode: DreamARVideoMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("录制质量")) {
                    ForEach(VideoQuality.allCases) { quality in
                        Button(action: {
                            videoMode.recordingQuality = quality
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(quality.rawValue)
                                        .font(.body)
                                    Text("\(quality.resolution) · \(quality.frameRate)fps")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if videoMode.recordingQuality == quality {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("录制时长")) {
                    Picker("时长", selection: $videoMode.recordingDuration) {
                        Text("15 秒").tag(15)
                        Text("30 秒").tag(30)
                        Text("60 秒").tag(60)
                        Text("120 秒").tag(120)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("慢动作设置")) {
                    Toggle("慢动作模式", isOn: $videoMode.isSlowMotionMode)
                    
                    if videoMode.isSlowMotionMode {
                        Picker("倍率", selection: $videoMode.slowMotionRate) {
                            ForEach(SlowMotionRate.allCases) { rate in
                                Text(rate.rawValue).tag(rate)
                            }
                        }
                    }
                }
                
                Section(header: Text("延时摄影设置")) {
                    Toggle("延时摄影模式", isOn: $videoMode.isTimeLapseMode)
                    
                    if videoMode.isTimeLapseMode {
                        Picker("间隔", selection: $videoMode.timeLapseInterval) {
                            Text("0.5 秒").tag(0.5)
                            Text("1 秒").tag(1.0)
                            Text("2 秒").tag(2.0)
                            Text("5 秒").tag(5.0)
                        }
                    }
                }
            }
            .navigationTitle("视频设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Video Filter Picker View

struct VideoFilterPickerView: View {
    @ObservedObject var videoMode: DreamARVideoMode
    let onSelect: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Text("选择滤镜")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(videoMode.availableFilters) { filter in
                        FilterSelectionButton(
                            filter: filter,
                            isSelected: videoMode.selectedFilter == filter
                        ) {
                            videoMode.selectedFilter = filter
                            onSelect()
                        }
                    }
                }
                .padding()
                
                // 滤镜强度滑块
                if videoMode.selectedFilter != .none {
                    VStack(alignment: .leading) {
                        Text("滤镜强度")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Slider(value: $videoMode.filterIntensity, in: 0...100, step: 1)
                            .accentColor(.purple)
                        
                        HStack {
                            Text("弱")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(videoMode.filterIntensity))%")
                                .font(.caption)
                                .foregroundColor(.white)
                            Spacer()
                            Text("强")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: onSelect) {
                    Text("完成")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.black.opacity(0.9))
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Filter Selection Button

struct FilterSelectionButton: View {
    let filter: ARVideoFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(filter.color.opacity(0.7))
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: filter.icon)
                            .foregroundColor(.white)
                            .font(.title2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 3)
                    )
                
                Text(filter.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Video Gallery View

struct VideoGalleryView: View {
    @ObservedObject var videoMode: DreamARVideoMode
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            if videoMode.videos.isEmpty {
                VStack {
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("暂无视频")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("开始录制你的第一个 AR 视频吧")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(videoMode.videos) { video in
                            VideoThumbnailCard(video: video)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("视频库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Video Thumbnail Card

struct VideoThumbnailCard: View {
    let video: ARVideoCapture
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 缩略图占位
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(9/16, contentMode: .fit)
                .overlay(
                    VStack {
                        Image(systemName: "video")
                            .font(.title)
                            .foregroundColor(.white)
                        Text(video.formattedDuration)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                )
            
            // 视频信息
            VStack(alignment: .leading, spacing: 2) {
                Text(video.dreamTitle ?? "AR 视频")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(video.modeDescription)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(video.quality.resolution)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
