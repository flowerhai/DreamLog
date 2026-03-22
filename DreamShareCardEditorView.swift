//
//  DreamShareCardEditorView.swift
//  DreamLog - Phase 70: 梦境社交分享增强
//
//  Created by DreamLog Team on 2026-03-19.
//  Phase 70: Share Card Editor - 自定义卡片编辑器
//

import SwiftUI

// MARK: - 分享卡片编辑器主视图

/// 分享卡片编辑器 - 支持自定义布局、贴纸、滤镜等
struct DreamShareCardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let dream: Dream
    @State private var template: ShareCardTemplate
    @State private var layoutConfig: CustomLayoutConfig
    @State private var stickers: [DynamicStickerConfig]
    @State private var customTitle: String
    @State private var customContent: String
    @State private var selectedFilters: [ImageFilter]
    @State private var showTemplatePicker = false
    @State private var showStickerPicker = false
    @State private var showFilterPicker = false
    @State private var showPreview = false
    @State private var generatedImage: UIImage?
    
    init(dream: Dream) {
        self.dream = dream
        _template = State(initialValue: ShareCardTemplateLibrary.starry)
        _layoutConfig = State(initialValue: CustomLayoutConfig())
        _stickers = State(initialValue: [])
        _customTitle = State(initialValue: dream.title)
        _customContent = State(initialValue: dream.content)
        _selectedFilters = State(initialValue: [])
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 卡片预览区域
                CardPreviewCanvas(
                    template: template,
                    layoutConfig: layoutConfig,
                    stickers: stickers,
                    dream: dream,
                    customTitle: customTitle,
                    customContent: customContent,
                    filters: selectedFilters
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
                
                // 底部工具栏
                VStack {
                    Spacer()
                    
                    // 工具栏
                    EditorToolbar(
                        showTemplatePicker: $showTemplatePicker,
                        showStickerPicker: $showStickerPicker,
                        showFilterPicker: $showFilterPicker,
                        showPreview: $showPreview
                    )
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding()
                }
            }
            .navigationTitle("编辑分享卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        generateAndSave()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView(selectedTemplate: $template)
            }
            .sheet(isPresented: $showStickerPicker) {
                StickerPickerView(onSelectSticker: addSticker)
            }
            .sheet(isPresented: $showFilterPicker) {
                FilterPickerView(selectedFilters: $selectedFilters)
            }
            .fullScreenCover(isPresented: $showPreview) {
                if let image = generatedImage {
                    SharePreviewView(image: image, dream: dream)
                }
            }
        }
    }
    
    private func addSticker(_ type: StickerType) {
        let sticker = DynamicStickerConfig(
            stickerType: type,
            position: CGPoint(x: 0.5, y: 0.5),
            scale: 1.0,
            rotation: 0,
            opacity: 1.0,
            animationType: .float
        )
        stickers.append(sticker)
    }
    
    private func generateAndSave() {
        // 渲染卡片视图为图片
        Task {
            await MainActor.run {
                let cardView = CardPreviewCanvas(
                    template: selectedTemplate,
                    layoutConfig: layoutConfig,
                    stickers: stickers,
                    dream: dream,
                    customTitle: customTitle.isEmpty ? (dream.title ?? "梦境") : customTitle,
                    customContent: customContent.isEmpty ? (dream.content ?? "") : customContent,
                    filters: filters
                )
                .frame(width: 1080, height: 1080)
                
                // 使用 ImageRenderer 渲染
                let renderer = ImageRenderer(content: cardView)
                renderer.scale = 3.0  // 高分辨率
                
                if let uiImage = renderer.uiImage {
                    // 保存到相册
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                    showFeedback("卡片已保存到相册 📸")
                    showPreview = true
                } else {
                    showFeedback("生成卡片失败")
                }
            }
        }
    }
}

// MARK: - 卡片预览画布

struct CardPreviewCanvas: View {
    let template: ShareCardTemplate
    let layoutConfig: CustomLayoutConfig
    let stickers: [DynamicStickerConfig]
    let dream: Dream
    let customTitle: String
    let customContent: String
    let filters: [ImageFilter]
    
    var body: some View {
        ZStack {
            // 背景渐变
            backgroundGradient
            
            // 梦境图片 (如果有)
            if let imageData = dream.images?.first {
                FilteredImageView(imageData: imageData, filters: filters)
                    .opacity(0.3)
            }
            
            // 内容区域
            contentArea
            
            // 贴纸层
            stickerLayer
            
            // 水印
            if layoutConfig.showBorder {
                watermarkView
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .cornerRadius(layoutConfig.borderRadius)
        .shadow(radius: 20)
        .padding()
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: template.swiftUIGradients),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: layoutConfig.spacing) {
            // 标题
            Text(customTitle.isEmpty ? dream.title : customTitle)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(template.swiftUITextColor)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, layoutConfig.padding)
            
            // 内容
            Text(customContent.isEmpty ? String(dream.content.prefix(200)) : customContent)
                .font(.system(size: 16))
                .foregroundColor(template.swiftUITextColor.opacity(0.9))
                .lineLimit(6)
                .padding(.horizontal, layoutConfig.padding)
            
            Spacer()
            
            // 标签
            if !dream.tags.isEmpty {
                TagsView(tags: dream.tags, accentColor: template.swiftUIAccentColor)
                    .padding(.horizontal, layoutConfig.padding)
            }
            
            // 日期
            Text(formatDate(dream.createdAt))
                .font(.caption)
                .foregroundColor(template.swiftUITextColor.opacity(0.7))
                .padding(.horizontal, layoutConfig.padding)
                .padding(.bottom, layoutConfig.padding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentFor(layoutConfig.contentPosition))
    }
    
    private var stickerLayer: some View {
        ForEach(stickers) { sticker in
            StickerView(config: sticker)
                .position(sticker.position)
        }
    }
    
    private var watermarkView: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "moon.stars.fill")
                    Text("DreamLog")
                }
                .font(.caption2)
                .foregroundColor(template.swiftUITextColor.opacity(0.5))
                .padding(8)
            }
            .padding(.trailing, 12)
            .padding(.bottom, 12)
        }
    }
    
    private func alignmentFor(_ position: ElementPosition) -> Alignment {
        switch position {
        case .top, .topLeft, .topRight: return .top
        case .center, .left, .right: return .center
        case .bottom, .bottomLeft, .bottomRight: return .bottom
        default: return .center
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        return formatter.string(from: date)
    }
}

// MARK: - 编辑器工具栏

struct EditorToolbar: View {
    @Binding var showTemplatePicker: Bool
    @Binding var showStickerPicker: Bool
    @Binding var showFilterPicker: Bool
    @Binding var showPreview: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            ToolbarButton(icon: "paintpalette.fill", label: "模板") {
                showTemplatePicker = true
            }
            
            ToolbarButton(icon: "sparkles", label: "贴纸") {
                showStickerPicker = true
            }
            
            ToolbarButton(icon: "wand.and.stars", label: "滤镜") {
                showFilterPicker = true
            }
            
            ToolbarButton(icon: "eye.fill", label: "预览") {
                showPreview = true
            }
            
            Spacer()
            
            ToolbarButton(icon: "square.and.arrow.up", label: "分享", isPrimary: true) {
                // 分享操作
            }
        }
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    let isPrimary: Bool
    let action: () -> Void
    
    init(icon: String, label: String, isPrimary: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.isPrimary = isPrimary
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(isPrimary ? .white : .primary)
            .frame(width: 60, height: 60)
            .background(isPrimary ? Color.blue : Color(.systemGray5))
            .cornerRadius(12)
        }
    }
}

// MARK: - 模板选择器

struct ShareCardTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTemplate: ShareCardTemplate
    @State private var selectedCategory: TemplateCategory = .nature
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分类选择
                categoryPicker
                
                Divider()
                
                // 模板网格
                templateGrid
            }
            .navigationTitle("选择模板")
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
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TemplateCategory.allCases) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding()
        }
    }
    
    private var templateGrid: some View {
        let templates = ShareCardTemplateLibrary.templates(in: selectedCategory)
        
        return ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(templates) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate.id == template.id
                    ) {
                        selectedTemplate = template
                    }
                }
            }
            .padding()
        }
    }
}

struct CategoryChip: View {
    let category: TemplateCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.iconName)
                Text(category.displayName)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct TemplateCard: View {
    let template: ShareCardTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                // 模板预览
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: template.swiftUIGradients),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .aspectRatio(1.0, contentMode: .fill)
                    .cornerRadius(12)
                    
                    Image(systemName: template.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(template.swiftUITextColor)
                }
                
                // 模板信息
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(template.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if template.isPremium {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(template.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
    }
}

// MARK: - 贴纸选择器

struct StickerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectSticker: (StickerType) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(StickerType.allCases) { stickerType in
                        StickerButton(stickerType: stickerType) {
                            onSelectSticker(stickerType)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("添加贴纸")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StickerButton: View {
    let stickerType: StickerType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: stickerType.sfSymbolName)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                Text(stickerType.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - 滤镜选择器

struct ShareCardFilterPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilters: [ImageFilter]
    
    var body: some View {
        NavigationView {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ImageFilter.allCases) { filter in
                        ShareCardEditFilterChip(
                            filter: filter,
                            isSelected: selectedFilters.contains(filter)
                        ) {
                            if selectedFilters.contains(filter) {
                                selectedFilters.removeAll { $0 == filter }
                            } else {
                                selectedFilters.append(filter)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择滤镜")
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

struct ShareCardEditFilterChip: View {
    let filter: ImageFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(filter.previewColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                
                Text(filter.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

/// 图片滤镜
enum ImageFilter: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case vintage = "vintage"
    case blackAndWhite = "blackAndWhite"
    case warm = "warm"
    case cool = "cool"
    case vibrant = "vibrant"
    case faded = "faded"
    case dramatic = "dramatic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "无"
        case .vintage: return "复古"
        case .blackAndWhite: return "黑白"
        case .warm: return "暖色"
        case .cool: return "冷色"
        case .vibrant: return "鲜艳"
        case .faded: return "褪色"
        case .dramatic: return "戏剧"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .none: return .gray
        case .vintage: return Color(hex: "d4a574")
        case .blackAndWhite: return .black
        case .warm: return Color(hex: "ff9966")
        case .cool: return Color(hex: "6699ff")
        case .vibrant: return Color(hex: "ff6699")
        case .faded: return Color(hex: "cccccc")
        case .dramatic: return Color(hex: "330033")
        }
    }
}

// MARK: - 分享预览视图

struct SharePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let dream: Dream
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                ShareOptionsView(dream: dream, image: image)
            }
            .navigationTitle("预览")
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

struct ShareOptionsView: View {
    let dream: Dream
    let image: UIImage
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 快速分享按钮
                QuickShareButtons(image: image)
                
                Divider()
                
                // 更多选项
                MoreShareOptions(image: image)
            }
            .padding()
        }
    }
}

struct QuickShareButtons: View {
    let image: UIImage
    
    var body: some View {
        HStack(spacing: 16) {
            ShareButton(platform: .wechat, image: image)
            ShareButton(platform: .moments, image: image)
            ShareButton(platform: .weibo, image: image)
            ShareButton(platform: .copy, image: image)
        }
    }
}

struct ShareButton: View {
    let platform: ShareCardEditorPlatform
    let image: UIImage
    
    var body: some View {
        Button {
            // 执行分享
        } label: {
            VStack {
                Image(systemName: platform.iconName)
                    .font(.system(size: 24))
                Text(platform.displayName)
                    .font(.caption2)
            }
            .frame(width: 70)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

enum ShareCardEditorPlatform {
    case wechat, moments, weibo, copy
    
    var displayName: String {
        switch self {
        case .wechat: return "微信"
        case .moments: return "朋友圈"
        case .weibo: return "微博"
        case .copy: return "复制"
        }
    }
    
    var iconName: String {
        switch self {
        case .wechat, .moments: return "message.fill"
        case .weibo: return "square.grid.2x2.fill"
        case .copy: return "doc.on.doc.fill"
        }
    }
}

struct MoreShareOptions: View {
    let image: UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("更多选项")
                .font(.headline)
            
            HStack {
                OptionButton(icon: "photo.on.rectangle", label: "保存到相册") {}
                OptionButton(icon: "link", label: "复制链接") {}
                OptionButton(icon: "square.and.arrow.up", label: "更多分享") {}
            }
        }
    }
}

struct OptionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - 辅助视图

struct FilteredImageView: View {
    let imageData: Data
    let filters: [ImageFilter]
    
    var body: some View {
        Image(data: imageData)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .applyFilters(filters)
    }
}

struct TagsView: View {
    let tags: [String]
    let accentColor: Color
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags.prefix(5), id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption)
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.2))
                    .cornerRadius(12)
            }
        }
    }
}

struct StickerView: View {
    let config: DynamicStickerConfig
    
    var body: some View {
        Image(systemName: config.stickerType.sfSymbolName)
            .font(.system(size: 30 * config.scale))
            .foregroundColor(.white)
            .opacity(config.opacity)
            .rotationEffect(.degrees(Double(config.rotation)))
            .animation(animationFor(config.animationType), value: config)
    }
    
    private func animationFor(_ type: StickerAnimation) -> Animation? {
        switch type {
        case .none: return nil
        case .bounce: return .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
        case .rotate: return .linear(duration: 3).repeatForever(autoreverses: false)
        case .scale: return .easeInOut(duration: 1).repeatForever(autoreverses: true)
        case .float: return .easeInOut(duration: 2).repeatForever(autoreverses: true)
        case .pulse: return .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        case .sparkle: return .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
        }
    }
}

extension View {
    func applyFilters(_ filters: [ImageFilter]) -> some View {
        self
            .modifier(FilterEffectModifier(filters: filters))
    }
}

/// 滤镜效果修饰符
struct FilterEffectModifier: ViewModifier {
    let filters: [ImageFilter]
    
    func body(content: Content) -> some View {
        content
            .applyFilterEffects(filters)
    }
}

/// 应用多个滤镜效果
extension View {
    func applyFilterEffects(_ filters: [ImageFilter]) -> some View {
        self
            .modifier(VintageFilterModifier(enabled: filters.contains(.vintage)))
            .modifier(BlackAndWhiteFilterModifier(enabled: filters.contains(.blackAndWhite)))
            .modifier(WarmFilterModifier(enabled: filters.contains(.warm)))
            .modifier(CoolFilterModifier(enabled: filters.contains(.cool)))
            .modifier(VibrantFilterModifier(enabled: filters.contains(.vibrant)))
            .modifier(FadedFilterModifier(enabled: filters.contains(.faded)))
            .modifier(DramaticFilterModifier(enabled: filters.contains(.dramatic)))
    }
}

// MARK: - 单个滤镜修饰符

struct VintageFilterModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .hueRotation(enabled ? .degrees(20) : .zero)
            .saturation(enabled ? 0.8 : 1.0)
            .overlay(enabled ? Color(hex: "d4a574").opacity(0.15) : Color.clear)
    }
}

struct BlackAndWhiteFilterModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .grayscale(enabled ? 1.0 : 0.0)
    }
}

struct WarmFilterModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(enabled ? Color(hex: "ff9966").opacity(0.1) : Color.clear)
            .hueRotation(enabled ? .degrees(-10) : .zero)
    }
}

struct CoolFilterModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(enabled ? Color(hex: "6699ff").opacity(0.1) : Color.clear)
            .hueRotation(enabled ? .degrees(10) : .zero)
    }
}

struct VibrantFilterModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .saturation(enabled ? 1.5 : 1.0)
            .contrast(enabled ? 1.1 : 1.0)
    }
}

struct FadedFilterModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(enabled ? Color.white.opacity(0.2) : Color.clear)
            .contrast(enabled ? 0.8 : 1.0)
    }
}

struct DramaticFilterModifier: ViewModifier {
    let enabled: Bool
    
    func body(content: Content) -> some View {
        content
            .contrast(enabled ? 1.3 : 1.0)
            .saturation(enabled ? 0.7 : 1.0)
            .overlay(enabled ? Color(hex: "330033").opacity(0.15) : Color.clear)
    }
}
