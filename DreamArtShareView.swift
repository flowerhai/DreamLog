//
//  DreamArtShareView.swift
//  DreamLog
//
//  Phase 54 - AI 梦境艺术分享卡片界面
//  创建时间：2026-03-16
//

import SwiftUI
import SwiftData

// MARK: - 主视图

struct DreamArtShareView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamArtShareService?
    
    @Query(sort: \ArtShareTemplate.name) private var templates: [ArtShareTemplate]
    @Query(sort: \ArtShareHistory.createdAt, order: .reverse) private var history: [ArtShareHistory]
    
    @State private var selectedDream: Dream?
    @State private var selectedTemplate: ArtShareTemplate?
    @State private var selectedCardType: ArtShareCardType = .instagramStory
    @State private var isShowingTemplatePicker = false
    @State private var isShowingDreamPicker = false
    @State private var isGenerating = false
    @State private var generatedImageURL: URL?
    @State private var showingShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var selectedCategory: TemplateCategory?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 卡片预览区
                cardPreviewSection
                
                Divider()
                
                // 配置区
                configurationSection
                
                Divider()
                
                // 模板选择区
                templateSelectionSection
            }
            .navigationTitle("艺术分享卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock")
                    }
                }
            }
            .task {
                service = DreamArtShareService(modelContext: modelContext)
                try? await service?.initializePresetTemplates()
            }
            .sheet(isPresented: $isShowingTemplatePicker) {
                TemplatePickerView(selectedTemplate: $selectedTemplate)
            }
            .sheet(isPresented: $isShowingDreamPicker) {
                DreamPickerView(selectedDream: $selectedDream)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = generatedImageURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingHistory) {
                ShareHistoryView()
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Card Preview Section
    
    private var cardPreviewSection: some View {
        ZStack {
            // 背景
            Rectangle()
                .fill(Color(backgroundColor: selectedTemplate?.backgroundColor ?? "#1a1a2e"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if let template = selectedTemplate,
               template.gradientStart != nil, template.gradientEnd != nil {
                LinearGradient(
                    colors: [
                        Color(hex: template.gradientStart!) ?? .clear,
                        Color(hex: template.gradientEnd!) ?? .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            
            // 预览内容
            VStack(spacing: 16) {
                Spacer()
                
                if let dream = selectedDream {
                    VStack(spacing: 12) {
                        Text(dream.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: selectedTemplate?.textColor ?? "#ffffff"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(dream.formattedDate)
                            .font(.caption)
                            .foregroundColor(Color(hex: selectedTemplate?.textColor ?? "#ffffff").opacity(0.7))
                        
                        if !dream.emotions.isEmpty {
                            Text(dream.emotionIcons)
                                .font(.title2)
                        }
                        
                        if !dream.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(dream.tags.prefix(5), id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: selectedTemplate?.accentColor ?? "#ffd700"))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .stroke(Color(hex: selectedTemplate?.accentColor ?? "#ffd700") ?? .clear, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("选择梦境开始")
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Logo
                Text("DreamLog 🌙")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
            }
        }
        .frame(height: 400)
        .cornerRadius(16)
        .padding()
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("配置")
                .font(.headline)
                .padding(.horizontal)
            
            // 选择梦境
            Button(action: { isShowingDreamPicker = true }) {
                HStack {
                    Image(systemName: "dream")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text(selectedDream?.title ?? "选择梦境")
                            .font(.subheadline)
                        Text(selectedDream != nil ? "已选择" : "点击选择")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // 选择卡片类型
            VStack(alignment: .leading, spacing: 8) {
                Text("卡片尺寸")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ArtShareCardType.allCases) { cardType in
                            Button(action: {
                                selectedCardType = cardType
                                updateTemplateForCardType(cardType)
                            }) {
                                VStack(spacing: 4) {
                                    Text(cardType.icon)
                                        .font(.title2)
                                    Text(cardType.displayName)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .frame(width: 70, height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCardType == cardType ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCardType == cardType ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 生成按钮
            Button(action: generateCard) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGenerating ? "生成中..." : "生成分享卡片")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedDream == nil || isGenerating)
            .padding(.horizontal)
            
            // 分享按钮
            if let _ = generatedImageURL {
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享卡片")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Template Selection Section
    
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("选择模板")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { isShowingTemplatePicker = true }) {
                    Text("全部")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // 分类筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { selectedCategory = nil }) {
                        Text("全部")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == nil ? Color.accentColor : Color.secondary.opacity(0.2))
                            )
                            .foregroundColor(selectedCategory == nil ? .white : .primary)
                    }
                    
                    ForEach(TemplateCategory.allCases) { category in
                        Button(action: { selectedCategory = category }) {
                            HStack(spacing: 4) {
                                Text(category.icon)
                                Text(category.displayName)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? Color.accentColor : Color.secondary.opacity(0.2))
                            )
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 模板列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        ) {
                            selectedTemplate = template
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Methods
    
    private var filteredTemplates: [ArtShareTemplate] {
        if let category = selectedCategory {
            return templates.filter { $0.category == category }
        }
        return templates
    }
    
    private func updateTemplateForCardType(_ cardType: ArtShareCardType) {
        // 根据卡片类型更新模板
        if let template = selectedTemplate {
            template.type = cardType
        }
    }
    
    private func generateCard() {
        guard let dream = selectedDream,
              let template = selectedTemplate,
              let service = service else { return }
        
        isGenerating = true
        
        Task {
            do {
                let url = try await service.generateCard(
                    dreamId: dream.id,
                    dreamTitle: dream.title,
                    dreamContent: dream.content,
                    dreamDate: dream.date,
                    tags: dream.tags,
                    emotions: dream.emotions.map { $0.rawValue },
                    aiAnalysis: dream.aiAnalysis,
                    aiImageUrl: dream.aiImageUrl,
                    template: template
                )
                
                await MainActor.run {
                    generatedImageURL = url
                    isGenerating = false
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isGenerating = false
                }
            }
        }
    }
    
    @State private var showingHistory = false
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: ArtShareTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: template.gradientStart ?? template.backgroundColor) ?? .gray,
                                Color(hex: template.gradientEnd ?? template.backgroundColor) ?? .gray
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 160)
                    .overlay(
                        VStack {
                            Text(template.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(8)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                
                Text(template.category.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Template Picker View

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ArtShareTemplate.name) private var templates: [ArtShareTemplate]
    @Binding var selectedTemplate: ArtShareTemplate?
    
    @State private var selectedCategory: TemplateCategory?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "全部",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(TemplateCategory.allCases) { category in
                            FilterChip(
                                title: "\(category.icon) \(category.displayName)",
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // 模板列表
                List {
                    ForEach(filteredTemplates) { template in
                        TemplateRow(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        ) {
                            selectedTemplate = template
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("选择模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "搜索模板")
        }
    }
    
    private var filteredTemplates: [ArtShareTemplate] {
        templates.filter { template in
            let matchesCategory = selectedCategory == nil || template.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
}

// MARK: - Dream Picker View

struct DreamPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @Binding var selectedDream: Dream?
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredDreams) { dream in
                    DreamRow(dream: dream) {
                        selectedDream = dream
                        dismiss()
                    }
                }
            }
            .navigationTitle("选择梦境")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索梦境")
        }
    }
    
    private var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreams
        }
        return dreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Share History View

struct ShareHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ArtShareHistory.createdAt, order: .reverse) private var history: [ArtShareHistory]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView(
                        "暂无分享记录",
                        systemImage: "photo.on.rectangle",
                        description: Text("生成的分享卡片将显示在这里")
                    )
                } else {
                    List {
                        ForEach(history) { item in
                            ShareHistoryRow(item: item)
                        }
                        .onDelete(perform: deleteHistory)
                    }
                }
            }
            .navigationTitle("分享历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !history.isEmpty {
                        Button(role: .destructive) {
                            clearAllHistory()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private func deleteHistory(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(history[index])
        }
        try? modelContext.save()
    }
    
    private func clearAllHistory() {
        for item in history {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

// MARK: - Share History Row

struct ShareHistoryRow: View {
    let item: ArtShareHistory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.cardType.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.dreamTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text("\(item.templateName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.platform.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(item.createdAt.formatted())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(item.fileSizeFormatted)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Dream Row

struct DreamRow: View {
    let dream: Dream
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "moon.stars")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dream.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(dream.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !dream.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(dream.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: ArtShareTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: template.gradientStart ?? template.backgroundColor) ?? .gray,
                                Color(hex: template.gradientEnd ?? template.backgroundColor) ?? .gray
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if template.isPreset {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        
                        if template.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text("\(template.category.displayName) · \(template.type.displayName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    init(backgroundColor hex: String) {
        self.init(hex: hex) ?? .gray
    }
}

// MARK: - Int64 Extension for File Size

extension Int64 {
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}

// MARK: - Preview

#Preview {
    DreamArtShareView()
        .modelContainer(for: [ArtShareTemplate.self, ArtShareHistory.self], inMemory: true)
}
