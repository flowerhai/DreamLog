//
//  DreamShareCardView.swift
//  DreamLog
//
//  Phase 25 - Dream Sharing Cards & Social Templates
//  梦境分享卡片 UI 界面
//

import SwiftUI

struct DreamShareCardView: View {
    @StateObject private var viewModel = DreamShareCardViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let dream: Dream
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 卡片预览
                    cardPreviewSection
                    
                    // 平台选择
                    platformSelectionSection
                    
                    // 卡片类型选择
                    cardTypeSelectionSection
                    
                    // 自定义选项
                    customizationSection
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("分享卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            viewModel.loadDream(dream)
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let shareItems = viewModel.shareItems {
                ActivityViewController(activityItems: shareItems)
            }
        }
    }
    
    // MARK: - 卡片预览
    
    private var cardPreviewSection: some View {
        VStack(spacing: 12) {
            Text("卡片预览")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                ShareCardView(
                    dream: viewModel.dream ?? dream,
                    config: viewModel.config,
                    template: viewModel.selectedTemplate
                )
                .aspectRatio(viewModel.config.platform.recommendedSize.width / viewModel.config.platform.recommendedSize.height, contentMode: .fit)
                .shadow(radius: 10)
            }
            .frame(maxWidth: 350)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - 平台选择
    
    private var platformSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择平台")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(SocialPlatform.allCases) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: viewModel.config.platform == platform
                    ) {
                        viewModel.selectPlatform(platform)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 卡片类型选择
    
    private var cardTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("卡片风格")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShareCardType.allCases) { type in
                        CardTypeButton(
                            cardType: type,
                            isSelected: viewModel.config.cardType == type
                        ) {
                            viewModel.selectCardType(type)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 自定义选项
    
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("自定义选项")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 显示选项
            GroupBox("显示内容") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("梦境标题", isOn: $viewModel.config.showDreamTitle)
                    Toggle("梦境内容", isOn: $viewModel.config.showDreamContent)
                    Toggle("标签", isOn: $viewModel.config.showTags)
                    Toggle("情绪", isOn: $viewModel.config.showEmotions)
                    Toggle("清晰度", isOn: $viewModel.config.showClarity)
                    Toggle("日期", isOn: $viewModel.config.showDate)
                    Toggle("DreamLog 标识", isOn: $viewModel.config.showAILogo)
                }
                .padding(.vertical, 8)
            }
            
            // 自定义语录
            GroupBox("自定义语录") {
                TextField("输入想说的话（可选）", text: Binding(
                    get: { viewModel.config.customQuote ?? "" },
                    set: { viewModel.config.customQuote = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 模板选择
            GroupBox("选择模板") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CardTemplate.template(for: viewModel.config.cardType)) { template in
                            TemplateButton(
                                template: template,
                                isSelected: viewModel.selectedTemplate?.id == template.id
                            ) {
                                viewModel.selectTemplate(template)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 操作按钮
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await viewModel.generateAndShare()
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享卡片")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    await viewModel.exportToPhotoLibrary()
                }
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("保存到相册")
                }
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            }
            
            if viewModel.generatedCards.count > 0 {
                NavigationLink(destination: ShareHistoryView(cards: viewModel.generatedCards)) {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("分享历史 (\(viewModel.generatedCards.count))")
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 视图模型

@MainActor
class DreamShareCardViewModel: ObservableObject {
    @Published var dream: Dream?
    @Published var config = ShareCardConfig()
    @Published var selectedTemplate: CardTemplate?
    @Published var generatedCards: [GeneratedShareCard] = []
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showShareSheet = false
    @Published var shareItems: [Any]?
    
    private let service = DreamShareCardService.shared
    
    func loadDream(_ dream: Dream) {
        self.dream = dream
        self.selectedTemplate = CardTemplate.templates.first { $0.type == config.cardType }
    }
    
    func selectPlatform(_ platform: SocialPlatform) {
        config.platform = platform
        // 自动调整配置
        if platform == .twitter {
            config.showDreamContent = true
        }
    }
    
    func selectCardType(_ type: ShareCardType) {
        config.cardType = type
        selectedTemplate = CardTemplate.template(for: type).first
    }
    
    func selectTemplate(_ template: CardTemplate) {
        selectedTemplate = template
    }
    
    func generateAndShare() async {
        guard let dream = dream else {
            showError = true
            errorMessage = "梦境数据不存在"
            return
        }
        
        do {
            let card = try await service.generateCard(
                for: dream,
                config: config,
                template: selectedTemplate
            )
            
            generatedCards.insert(card, at: 0)
            
            // 准备分享内容
            var text = dream.title
            if let content = dream.content.preview(200) {
                text += "\n\n" + content
            }
            if !dream.tags.isEmpty {
                text += "\n\n" + dream.tags.map { "#\($0)" }.joined(separator: " ")
            }
            text += "\n\n来自 @DreamLog"
            
            shareItems = [text, card.imageUrl]
            showShareSheet = true
            
            // 记录分享
            try await service.shareCard(card, with: text)
            
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func exportToPhotoLibrary() async {
        guard let card = generatedCards.first else {
            showError = true
            errorMessage = "先生成卡片"
            return
        }
        
        do {
            try await service.exportCardToPhotoLibrary(card)
        } catch {
            showError = true
            errorMessage = "导出失败：\(error.localizedDescription)"
        }
    }
}

// MARK: - 平台按钮

struct PlatformButton: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(platform.icon)
                    .font(.title)
                Text(platform.displayName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - 卡片类型按钮

struct CardTypeButton: View {
    let cardType: ShareCardType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(cardType.icon)
                    .font(.title2)
                Text(cardType.displayName)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - 模板按钮

struct TemplateButton: View {
    let template: CardTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: template.gradientColors.map { Color(hex: $0) ?? .gray },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    if template.showDecorations {
                        Text("✨")
                            .font(.caption)
                    }
                }
                
                Text(template.name)
                    .font(.caption)
            }
            .frame(width: 80)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

// MARK: - 分享历史视图

struct ShareHistoryView: View {
    let cards: [GeneratedShareCard]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("最近的分享") {
                ForEach(cards) { card in
                    ShareHistoryRow(card: card)
                }
            }
        }
        .navigationTitle("分享历史")
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

struct ShareHistoryRow: View {
    let card: GeneratedShareCard
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: card.imageUrl) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.platform?.displayName ?? "未知平台")
                        .font(.headline)
                    Spacer()
                    Text(card.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("分享 \(card.shareCount) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ActivityViewController

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 预览

#Preview {
    DreamShareCardView(
        dream: Dream(
            title: "飞翔的梦",
            content: "我梦见自己在天空中自由飞翔，穿过云层，感受着风的轻抚...",
            tags: ["飞行", "自由", "天空"],
            emotions: [.happy, .excited],
            clarity: 4,
            intensity: 5,
            isLucid: true
        )
    )
}
