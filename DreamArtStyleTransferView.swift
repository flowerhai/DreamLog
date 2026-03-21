//
//  DreamArtStyleTransferView.swift
//  DreamLog
//
//  Phase 81: 梦境 AI 绘画增强 - 艺术风格迁移与滤镜系统
//  Created: 2026-03-21
//

import SwiftUI
import SwiftData

// MARK: - Main View

struct DreamArtStyleTransferView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service = DreamArtStyleTransferService()
    
    @Query(sort: \DreamArtStyleTransfer.createdAt, order: .reverse)
    private var transfers: [DreamArtStyleTransfer]
    
    @State private var selectedImage: UIImage?
    @State private var selectedStyle: ArtStyleType = .postImpressionist
    @State private var styleIntensity: Double = 0.7
    @State private var isProcessing: Bool = false
    @State private var processedImage: UIImage?
    @State private var showingStylePicker: Bool = false
    @State private var showingHistory: Bool = false
    @State private var errorMessage: String?
    
    @State private var stats: StyleTransferStats?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 统计卡片
                    statsSection
                    
                    // 图像选择区
                    imageSelectionSection
                    
                    // 风格选择区
                    styleSelectionSection
                    
                    // 强度调节
                    intensityControlSection
                    
                    // 处理按钮
                    processButtonSection
                    
                    // 结果预览
                    if let processedImage = processedImage {
                        resultPreviewSection(image: processedImage)
                    }
                    
                    // 历史记录
                    historySection
                }
                .padding()
            }
            .navigationTitle("艺术风格迁移")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingHistory.toggle() }) {
                        Image(systemName: "clock")
                    }
                }
            }
            .sheet(isPresented: $showingStylePicker) {
                StylePickerView(selectedStyle: $selectedStyle)
            }
            .task {
                await loadStats()
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var statsSection: some View {
        if let stats = stats {
            VStack(alignment: .leading, spacing: 12) {
                Text("📊 风格迁移统计")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    StatCard(
                        title: "总迁移",
                        value: "\(stats.totalCount)",
                        icon: "photo.on.rectangle",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "收藏",
                        value: "\(stats.favoriteCount)",
                        icon: "heart",
                        color: .red
                    )
                    
                    StatCard(
                        title: "平均耗时",
                        value: String(format: "%.1fs", stats.averageProcessingTime),
                        icon: "timer",
                        color: .green
                    )
                }
                
                if let mostUsed = stats.mostUsedStyle {
                    HStack {
                        Text("最常使用:")
                            .foregroundColor(.secondary)
                        Text(mostUsed.displayName)
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var imageSelectionSection: some View {
        VStack(spacing: 12) {
            Text("🖼️ 选择图像")
                .font(.headline)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                
                Button("更换图像") {
                    selectImage()
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: selectImage) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("点击选择图像")
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎨 选择艺术风格")
                .font(.headline)
            
            Button(action: { showingStylePicker.toggle() }) {
                HStack {
                    StylePreviewCard(style: selectedStyle)
                        .frame(width: 80, height: 80)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedStyle.displayName)
                            .font(.headline)
                        Text(selectedStyle.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Text("艺术家：\(selectedStyle.artists.joined(separator: "、"))")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // 快速选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ArtStyleType.allCases.prefix(8)) { style in
                        Button(action: { selectedStyle = style }) {
                            StylePreviewCard(style: style)
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var intensityControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎚️ 风格强度")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(styleIntensity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $styleIntensity, in: 0...1, step: 0.05) {
                Text("强度")
            } minimumValueLabel: {
                Text("弱")
            } maximumValueLabel: {
                Text("强")
            }
            
            // 预设强度
            HStack(spacing: 8) {
                Button("柔和") { styleIntensity = 0.3 }
                    .buttonStyle(.bordered)
                
                Button("中等") { styleIntensity = 0.5 }
                    .buttonStyle(.bordered)
                
                Button("强烈") { styleIntensity = 0.7 }
                    .buttonStyle(.bordered)
                
                Button("极致") { styleIntensity = 1.0 }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var processButtonSection: some View {
        Button(action: processImage) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("处理中...")
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("应用风格")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedImage == nil ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(selectedImage == nil || isProcessing)
    }
    
    @ViewBuilder
    private func resultPreviewSection(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✨ 处理结果")
                .font(.headline)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .shadow(radius: 5)
            
            HStack(spacing: 12) {
                Button(action: saveResult) {
                    Label("保存", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                
                Button(action: shareResult) {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                
                Button(action: toggleFavorite) {
                    Label("收藏", systemImage: "heart")
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📜 最近迁移")
                .font(.headline)
            
            if transfers.isEmpty {
                Text("暂无历史记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(transfers.prefix(5)) { transfer in
                    TransferHistoryRow(transfer: transfer)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func selectImage() {
        // 实际应用中应使用 UIImagePickerController 或 PHPickerViewController
        // 这里简化处理
        if let sampleImage = UIImage(named: "sample_dream") {
            selectedImage = sampleImage
        }
    }
    
    private func processImage() async {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "无法加载图像"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let config = StyleTransferConfig(
                styleType: selectedStyle,
                intensity: styleIntensity
            )
            
            let resultData = try await service.applyStyleTransfer(
                to: imageData,
                config: config
            )
            
            if let resultImage = UIImage(data: resultData) {
                processedImage = resultImage
                
                // 保存记录
                _ = try await service.saveStyleTransfer(
                    dreamId: UUID(),
                    originalImageId: UUID().uuidString,
                    styleType: selectedStyle.rawValue,
                    styleIntensity: styleIntensity,
                    resultImageId: UUID().uuidString,
                    processingTime: 0
                )
                
                // 刷新统计
                await loadStats()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    private func saveResult() {
        // 保存结果到相册
    }
    
    private func shareResult() {
        // 分享结果
    }
    
    private func toggleFavorite() {
        // 切换收藏状态
    }
    
    private func loadStats() async {
        do {
            stats = try await service.getStatistics()
        } catch {
            print("加载统计失败：\(error)")
        }
    }
}

// MARK: - Subviews

struct StylePreviewCard: View {
    let style: ArtStyleType
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .cornerRadius(8)
        .overlay(
            Text(style.displayName.prefix(2))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        )
    }
    
    private var gradientColors: [Color] {
        ArtStyleType.allStylesWithPreview
            .first { $0.style == style }?
            .gradient
            .map { Color(hex: $0) } ?? [.gray, .gray]
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: color.opacity(0.2), radius: 5)
    }
}

struct TransferHistoryRow: View {
    let transfer: DreamArtStyleTransfer
    
    var body: some View {
        HStack(spacing: 12) {
            // 风格预览
            if let styleType = ArtStyleType(rawValue: transfer.styleType) {
                StylePreviewCard(style: styleType)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let styleType = ArtStyleType(rawValue: transfer.styleType) {
                    Text(styleType.displayName)
                        .font(.headline)
                }
                
                Text(transfer.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("强度：\(Int(transfer.styleIntensity * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: transfer.isFavorite ? "heart.fill" : "heart")
                .foregroundColor(transfer.isFavorite ? .red : .gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct StylePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStyle: ArtStyleType
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(ArtStyleType.allCases) { style in
                    Button(action: {
                        selectedStyle = style
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            StylePreviewCard(style: style)
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.displayName)
                                    .font(.headline)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("选择艺术风格")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DreamArtStyleTransferView()
        .modelContainer(for: DreamArtStyleTransfer.self, inMemory: true)
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
