//
//  DreamVideoEditorView.swift
//  DreamLog
//
//  Dream Video Editor UI - Phase 14 Completion
//  User interface for editing videos with crop, trim, filters, and text
//

import SwiftUI
import AVKit

// MARK: - 视频编辑器主界面

struct DreamVideoEditorView: View {
    @ObservedObject private var editor = DreamVideoEditor.shared
    @ObservedObject private var templateMarket = DreamVideoTemplateMarket.shared
    
    let sourceVideoURL: URL
    let onExportComplete: (URL) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var editConfig = VideoEditConfig()
    @State private var selectedFilter: VideoFilterConfig.FilterType = .none
    @State private var filterIntensity: Double = 1.0
    @State private var showingTextEditor = false
    @State private var showingCropEditor = false
    @State private var showingTrimEditor = false
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showingTemplatePicker = false
    @State private var selectedTemplate: VideoTemplate?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 视频预览
                videoPreviewSection
                
                Divider()
                
                // 编辑工具
                editingToolsSection
                
                Divider()
                
                // 底部操作栏
                actionBar
            }
            .navigationTitle("视频编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("导出") {
                        exportVideo()
                    }
                    .fontWeight(.bold)
                    .disabled(isExporting || editor.isEditing)
                }
            }
            .sheet(isPresented: $showingTextEditor) {
                TextOverlayEditor(overlays: $editConfig.textOverlays, duration: editor.videoDuration)
            }
            .sheet(isPresented: $showingCropEditor) {
                CropEditor(cropRegion: $editConfig.cropRegion, videoSize: editor.videoSize)
            }
            .sheet(isPresented: $showingTrimEditor) {
                TrimEditor(
                    duration: editor.videoDuration,
                    trimRange: $editConfig.trimRange
                )
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView(
                    selectedTemplate: $selectedTemplate,
                    onApplyTemplate: applyTemplate
                )
            }
            .onChange(of: selectedFilter) { oldValue, newValue in
                editConfig.filterConfig.filterType = newValue
                editConfig.filterConfig.intensity = CGFloat(filterIntensity)
            }
            .onChange(of: filterIntensity) { oldValue, newValue in
                editConfig.filterConfig.intensity = CGFloat(newValue)
            }
        }
        .onAppear {
            loadVideo()
        }
    }
    
    // MARK: - 视频预览
    
    private var videoPreviewSection: some View {
        ZStack {
            Color.black
            
            if let previewImage = editor.previewFrame {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        // 应用裁剪预览
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.purple, lineWidth: 2)
                            .opacity(editConfig.cropRegion != .default ? 1 : 0)
                    )
            } else {
                ProgressView()
            }
            
            // 文字叠加预览
            if !editConfig.textOverlays.isEmpty {
                VStack {
                    ForEach(editConfig.textOverlays.filter { $0.startTime == 0 }) { overlay in
                        Text(overlay.text)
                            .font(.system(size: overlay.fontSize, weight: .bold))
                            .foregroundColor(Color(hex: overlay.textColor) ?? .white)
                            .padding()
                            .background(
                                Color(hex: overlay.backgroundColor ?? "00000000")
                            )
                    }
                }
            }
            
            // 导出进度
            if isExporting {
                VStack(spacing: 16) {
                    ProgressView(value: exportProgress)
                        .progressViewStyle(.linear)
                        .padding(.horizontal, 40)
                    
                    Text("导出中... \(Int(exportProgress * 100))%")
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(editor.videoSize.width / editor.videoSize.height, contentMode: .fit)
    }
    
    // MARK: - 编辑工具
    
    private var editingToolsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                // 模板
                EditToolButton(
                    icon: "wand.and.stars",
                    label: "模板",
                    action: { showingTemplatePicker = true }
                )
                
                // 裁剪
                EditToolButton(
                    icon: "crop",
                    label: "裁剪",
                    action: { showingCropEditor = true }
                )
                
                // 修剪
                EditToolButton(
                    icon: "scissors",
                    label: "修剪",
                    action: { showingTrimEditor = true }
                )
                
                // 文字
                EditToolButton(
                    icon: "textformat",
                    label: "文字",
                    action: { showingTextEditor = true }
                )
                
                // 滤镜
                Menu {
                    ForEach(VideoFilterConfig.FilterType.allCases) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            HStack {
                                Image(systemName: filter.icon)
                                Text(filter.rawValue)
                                if filter == selectedFilter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    EditToolButton(
                        icon: selectedFilter.icon,
                        label: "滤镜",
                        action: {}
                    )
                }
                
                // 滤镜强度滑块
                if selectedFilter != .none {
                    VStack(spacing: 4) {
                        Slider(value: $filterIntensity, in: 0...1)
                            .frame(width: 80)
                        Text("强度")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - 底部操作栏
    
    private var actionBar: some View {
        HStack(spacing: 16) {
            // 视频信息
            VStack(alignment: .leading, spacing: 4) {
                Text("时长：\(String(format: "%.1f", editor.videoDuration))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("尺寸：\(Int(editor.videoSize.width))x\(Int(editor.videoSize.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 编辑状态
            if editConfig.hasEdits {
                Label("已编辑", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - 操作
    
    private func loadVideo() {
        Task {
            try? await editor.loadVideo(url: sourceVideoURL)
        }
    }
    
    private func exportVideo() {
        isExporting = true
        
        Task {
            do {
                let outputURL = getOutputURL()
                try await editor.exportEditedVideo(
                    sourceURL: sourceVideoURL,
                    config: editConfig,
                    outputURL: outputURL
                )
                
                await MainActor.run {
                    isExporting = false
                    exportProgress = 1.0
                    onExportComplete(outputURL)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    // 显示错误
                }
            }
        }
    }
    
    private func getOutputURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? 
                        FileManager.default.temporaryDirectory
        let filename = "edited_video_\(Date().timeIntervalSince1970).mp4"
        return documents.appendingPathComponent(filename)
    }
    
    private func applyTemplate(_ template: VideoTemplate) {
        editConfig.filterConfig = template.filterConfig
        selectedFilter = template.filterConfig.filterType
        filterIntensity = Double(template.filterConfig.intensity)
        
        // 应用文字叠加
        editConfig.textOverlays = template.textOverlays
        
        showingTemplatePicker = false
    }
}

// MARK: - 编辑工具按钮

struct EditToolButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 文字叠加编辑器

struct TextOverlayEditor: View {
    @Binding var overlays: [VideoTextOverlay]
    let duration: Double
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var newText = ""
    @State private var selectedPosition: VideoTextOverlay.TextPosition = .center
    @State private var selectedAnimation: VideoTextOverlay.TextAnimation = .fadeIn
    @State private var fontSize: Double = 32
    @State private var textColor = "FFFFFF"
    
    var body: some View {
        NavigationView {
            List {
                // 现有文字列表
                Section("文字叠加") {
                    ForEach($overlays) { $overlay in
                        HStack {
                            Text(overlay.text)
                                .lineLimit(1)
                            Spacer()
                            Text("\(String(format: "%.1f", overlay.startTime))s - \(String(format: "%.1f", overlay.endTime))s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button(action: {
                                overlays.removeAll { $0.id == overlay.id }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        overlays.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                
                // 添加新文字
                Section("添加文字") {
                    TextField("输入文字", text: $newText)
                    
                    Picker("位置", selection: $selectedPosition) {
                        ForEach(VideoTextOverlay.TextPosition.allCases, id: \.self) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                    
                    Picker("动画", selection: $selectedAnimation) {
                        ForEach(VideoTextOverlay.TextAnimation.allCases, id: \.self) { animation in
                            Text(animation.rawValue).tag(animation)
                        }
                    }
                    
                    Stepper("字号：\(Int(fontSize))", value: $fontSize, in: 16...72)
                    
                    Button("添加") {
                        addTextOverlay()
                    }
                    .disabled(newText.isEmpty)
                }
            }
            .navigationTitle("文字编辑")
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
    
    private func addTextOverlay() {
        let overlay = VideoTextOverlay(
            text: newText,
            startTime: 0,
            endTime: min(3.0, duration),
            position: selectedPosition,
            fontSize: CGFloat(fontSize),
            fontName: "Helvetica",
            textColor: textColor,
            backgroundColor: "00000060",
            animation: selectedAnimation,
            alignment: .center
        )
        overlays.append(overlay)
        newText = ""
    }
}

// MARK: - 裁剪编辑器

struct CropEditor: View {
    @Binding var cropRegion: VideoCropRegion
    let videoSize: CGSize
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var x: Double = 0
    @State private var y: Double = 0
    @State private var width: Double = 1
    @State private var height: Double = 1
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 预览
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(videoSize.width / videoSize.height, contentMode: .fit)
                    
                    Rectangle()
                        .stroke(Color.purple, lineWidth: 3)
                        .padding(.horizontal, CGFloat(x) * 100)
                        .padding(.vertical, CGFloat(y) * 100)
                }
                .padding()
                
                // 滑块控制
                VStack(alignment: .leading, spacing: 16) {
                    SliderControl(label: "X 位置", value: $x, range: 0...(1 - width))
                    SliderControl(label: "Y 位置", value: $y, range: 0...(1 - height))
                    SliderControl(label: "宽度", value: $width, range: 0.2...1)
                    SliderControl(label: "高度", value: $height, range: 0.2...1)
                }
                .padding(.horizontal)
                
                // 预设按钮
                VStack(spacing: 12) {
                    Text("预设")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        PresetButton("原始") { resetToDefault() }
                        PresetButton("1:1") { applyPreset(.square) }
                        PresetButton("9:16") { applyPreset(.portrait) }
                        PresetButton("16:9") { applyPreset(.landscape) }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("裁剪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        cropRegion = VideoCropRegion(x: x, y: y, width: width, height: height)
                        dismiss()
                    }
                }
            }
            .onAppear {
                x = cropRegion.x
                y = cropRegion.y
                width = cropRegion.width
                height = cropRegion.height
            }
        }
    }
    
    private func resetToDefault() {
        x = 0; y = 0; width = 1; height = 1
    }
    
    private func applyPreset(_ region: VideoCropRegion) {
        x = region.x; y = region.y; width = region.width; height = region.height
    }
}

struct SliderControl: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Slider(value: $value, in: range)
        }
    }
}

struct PresetButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .cornerRadius(8)
        }
    }
}

// MARK: - 修剪编辑器

struct TrimEditor: View {
    let duration: Double
    @Binding var trimRange: VideoTrimRange?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var startTime: Double = 0
    @State private var endTime: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 时间轴
                VStack(spacing: 12) {
                    Text("拖动滑块选择修剪范围")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("0s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            // 双滑块实现简化版本
                            Slider(value: $startTime, in: 0...(duration - 1), step: 0.5)
                            Slider(value: $endTime, in: (startTime + 1)...duration, step: 0.5)
                        }
                        
                        Text("\(String(format: "%.1f", duration))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("已选择：\(String(format: "%.1f", endTime - startTime))s")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                .padding()
                
                // 预览
                HStack(spacing: 16) {
                    TimePreview(time: 0, label: "开始")
                    TimePreview(time: duration * 0.5, label: "中间")
                    TimePreview(time: duration, label: "结束")
                }
                
                Spacer()
            }
            .navigationTitle("修剪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        trimRange = VideoTrimRange.fromSeconds(start: startTime, end: endTime)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let range = trimRange {
                    startTime = CMTimeGetSeconds(range.startTime)
                    endTime = CMTimeGetSeconds(range.endTime)
                } else {
                    startTime = 0
                    endTime = duration
                }
            }
        }
    }
}

struct TimePreview: View {
    let time: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 60)
                .overlay(
                    Text("\(String(format: "%.1f", time))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 模板选择器

struct TemplatePickerView: View {
    @Binding var selectedTemplate: VideoTemplate?
    let onApplyTemplate: (VideoTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var templateMarket = DreamVideoTemplateMarket.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templateMarket.templates) { template in
                    Button(action: {
                        selectedTemplate = template
                        onApplyTemplate(template)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("选择模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    DreamVideoEditorView(
        sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mp4"),
        onExportComplete: { _ in }
    )
}
