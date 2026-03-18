//
//  DreamArtCardView.swift
//  DreamLog
//
//  Phase 54 - AI 梦境艺术分享卡片
//  艺术卡片生成与分享界面
//

import SwiftUI
import UIKit

// MARK: - 主视图

struct DreamArtCardView: View {
    @StateObject private var viewModel = DreamArtCardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let dream: Dream
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 预览区域
                    previewSection
                    
                    // 风格选择
                    styleSelectionSection
                    
                    // AI 文本增强
                    textEnhancementSection
                    
                    // 平台优化
                    platformSection
                    
                    // 配置选项
                    configSection
                    
                    // 生成按钮
                    generateButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("艺术卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("分享") {
                        shareCard()
                    }
                    .disabled(!viewModel.isGenerated)
                }
            }
        }
        .task {
            await viewModel.autoMatchStyle(for: dream)
        }
    }
    
    // MARK: - 预览区域
    
    private var previewSection: some View {
        VStack(spacing: 12) {
            Text("卡片预览")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                if let image = viewModel.previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 300, height: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("点击生成预览")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
            
            if viewModel.isGenerating {
                ProgressView("生成中...")
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 风格选择
    
    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择风格")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 120))
            ], spacing: 12) {
                ForEach(ArtCardStyle.allCases) { style in
                    StyleButton(
                        style: style,
                        isSelected: viewModel.selectedStyle == style,
                        action: {
                            viewModel.selectedStyle = style
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - AI 文本增强
    
    private var textEnhancementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 文本增强")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("增强模式", selection: $viewModel.textEnhancementMode) {
                ForEach(TextEnhancementMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            Text(viewModel.textEnhancementMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 平台优化
    
    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("平台优化")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("目标平台", selection: $viewModel.selectedPlatform) {
                Text("通用").tag(nil as String?)
                Text("微信朋友圈").tag("wechat" as String?)
                Text("小红书").tag("xiaohongshu" as String?)
                Text("Instagram").tag("instagram" as String?)
            }
            .pickerStyle(.menu)
            
            if let platform = viewModel.selectedPlatform {
                let opt = PlatformOptimization.default(for: platform)
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("尺寸：\(Int(opt.resolution.width))x\(Int(opt.resolution.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 配置选项
    
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("显示选项")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("显示标签", isOn: $viewModel.includeTags)
            Toggle("显示情绪", isOn: $viewModel.includeEmotions)
            Toggle("显示日期", isOn: $viewModel.includeDate)
            Toggle("显示水印", isOn: $viewModel.showWatermark)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 生成按钮
    
    private var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generateCard(dream: dream)
            }
        }) {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                
                Text(viewModel.isGenerating ? "生成中..." : "生成艺术卡片")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isGenerating)
    }
    
    // MARK: - 分享
    
    private func shareCard() {
        guard let imagePath = viewModel.generatedImagePath,
              let image = UIImage(contentsOfFile: imagePath) else {
            print("⚠️ 无法加载分享图片：\(viewModel.generatedImagePath ?? "unknown")")
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - 风格按钮

struct StyleButton: View {
    let style: ArtCardStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(style.icon)
                    .font(.system(size: 32))
                
                Text(style.displayName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.2) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - ViewModel

@MainActor
class DreamArtCardViewModel: ObservableObject {
    @Published var selectedStyle: ArtCardStyle = .starry
    @Published var textEnhancementMode: TextEnhancementMode = .none
    @Published var selectedPlatform: String? = nil
    @Published var includeTags: Bool = true
    @Published var includeEmotions: Bool = true
    @Published var includeDate: Bool = false
    @Published var showWatermark: Bool = true
    
    @Published var isGenerating: Bool = false
    @Published var isGenerated: Bool = false
    @Published var previewImage: UIImage?
    @Published var generatedImagePath: String?
    @Published var errorMessage: String?
    
    private let service = DreamArtCardService.shared
    
    func autoMatchStyle(for dream: Dream) async {
        let matchedStyle = await service.matchStyle(for: dream)
        selectedStyle = matchedStyle
    }
    
    func generateCard(dream: Dream) async {
        isGenerating = true
        errorMessage = nil
        
        let config = CardGenerationConfig(
            dreamId: dream.id,
            style: selectedStyle.rawValue,
            templateId: nil,
            platform: selectedPlatform,
            textEnhancementMode: textEnhancementMode,
            showWatermark: showWatermark,
            customText: nil,
            includeTags: includeTags,
            includeEmotions: includeEmotions,
            includeDate: includeDate
        )
        
        do {
            // 注意：由于 Dream 不是 SwiftData 模型，需要特殊处理
            // 这里简化实现，直接调用生成器
            let generator = DreamArtCardGenerator()
            
            // AI 文本增强
            let enhancedText = try await service.enhanceText(
                dream.content,
                mode: textEnhancementMode
            )
            
            // 创建模板
            let template = createTemplateFromStyle(selectedStyle)
            
            // 渲染卡片
            let result = try await generator.renderCard(
                dream: dream,
                template: template,
                enhancedText: enhancedText,
                config: config
            )
            
            if result.success {
                previewImage = UIImage(contentsOfFile: result.imagePath)
                generatedImagePath = result.imagePath
                isGenerated = true
            } else {
                errorMessage = result.errorMessage ?? "生成失败"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    private func createTemplateFromStyle(_ style: ArtCardStyle) -> ArtCardTemplate {
        ArtCardTemplate(
            name: style.displayName + "模板",
            description: style.description,
            style: style.rawValue,
            background: BackgroundConfig(
                colors: ["deepPurple", "midnightBlue"],
                gradientType: "linear",
                gradientAngle: 45,
                opacity: 0.9,
                blurRadius: 0,
                noiseIntensity: 0
            ),
            textConfig: .default,
            decorations: style.defaultDecorations.map {
                DecorationConfig(type: $0.rawValue, count: 20, size: 8, opacity: 0.8, animation: nil)
            },
            isPreset: true,
            category: .artistic
        )
    }
}

// MARK: - 预览

#Preview {
    DreamArtCardView(
        dream: Dream(
            title: "测试梦境",
            content: "这是一个测试梦境的内容，用于预览艺术卡片生成效果。",
            tags: ["测试", "预览"],
            emotions: [.calm, .happy]
        )
    )
}
