//
//  DreamShareCardView.swift
//  DreamLog
//
//  Phase 54 - Dream Share Cards (梦境分享卡片)
//  UI 界面 - 卡片创建、预览、分享
//

import SwiftUI

// MARK: - 分享卡片主视图

struct DreamShareCardView: View {
    @ObservedObject private var service = DreamShareCardService.shared
    @State private var cards: [DreamShareCard] = []
    @State private var selectedCard: DreamShareCard?
    @State private var showingCreateSheet = false
    @State private var showingStatsSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            Group {
                if cards.isEmpty {
                    ShareCardEmptyStateView()
                } else {
                    CardsGridView
                }
            }
            .navigationTitle("分享卡片")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingStatsSheet = true }) {
                            Image(systemName: "chart.bar")
                        }
                        Button(action: { showingCreateSheet = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索卡片")
            .onAppear(perform: loadCards)
            .sheet(isPresented: $showingCreateSheet) {
                CreateCardView()
            }
            .sheet(isPresented: $showingStatsSheet) {
                ShareStatsView(stats: service.getStats())
            }
            .sheet(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
        }
    }
    
    private var filteredCards: [DreamShareCard] {
        if searchText.isEmpty {
            return cards
        }
        return cards.filter { card in
            // 这里需要关联梦境数据进行过滤
            true
        }
    }
    
    private var CardsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredCards, id: \.id) { card in
                    CardThumbnailView(card: card)
                        .onTapGesture {
                            selectedCard = card
                        }
                }
            }
            .padding()
        }
    }
    
    private func loadCards() {
        cards = service.getAllShareCards()
    }
}

// MARK: - 空状态视图

struct ShareCardEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有分享卡片")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("创建精美的卡片，分享你的梦境到社交平台")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {}) {
                Label("创建第一张卡片", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - 卡片缩略图视图

struct CardThumbnailView: View {
    let card: DreamShareCard
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        VStack(spacing: 8) {
            // 卡片预览
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: card.theme.gradientColors.map { Color(hex: $0.description) }),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(card.theme.layout.aspectRatio, contentMode: .fit)
                    .shadow(radius: 8)
                
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    VStack(spacing: 8) {
                        Text(card.theme.icon)
                            .font(.system(size: 40))
                        Text(card.theme.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                // 收藏标记
                if card.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                }
            }
            
            // 信息
            HStack {
                Text(card.theme.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(card.shareCount) 次分享")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 创建卡片视图

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var service = DreamShareCardService.shared
    @State private var selectedDream: Dream?
    @State private var selectedTemplate: ShareCardTemplate = .presets[0]
    @State private var selectedTheme: ShareCardTheme = .starry
    @State private var showTags = true
    @State private var showEmotions = true
    @State private var showDate = true
    @State private var showWatermark = true
    @State private var isGenerating = false
    @State private var previewImage: UIImage?
    
    // 梦境列表
    @State private var dreams: [Dream] = []
    
    var body: some View {
        NavigationView {
            Form {
                // 选择梦境
                Section("选择梦境") {
                    if let dream = selectedDream {
                        Button(action: { /* 选择梦境 */ }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(dream.title)
                                        .font(.headline)
                                    Text(dream.content.prefix(50) + "...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.purple)
                            }
                        }
                    } else {
                        Button(action: { /* 打开梦境选择器 */ }) {
                            HStack {
                                Text("选择梦境")
                                    .foregroundColor(.purple)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 选择模板
                Section("选择模板") {
                    ForEach(ShareCardTemplate.presets) { template in
                        Button(action: { selectedTemplate = template }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(template.icon) \(template.name)")
                                        .font(.headline)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedTemplate.id == template.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
                
                // 选择主题
                Section("选择主题") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(ShareCardTheme.allCases) { theme in
                            ThemeButton(theme: theme, isSelected: selectedTheme == theme) {
                                selectedTheme = theme
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 显示选项
                Section("显示选项") {
                    Toggle("显示标签", isOn: $showTags)
                    Toggle("显示情绪", isOn: $showEmotions)
                    Toggle("显示日期", isOn: $showDate)
                    Toggle("显示水印", isOn: $showWatermark)
                }
                
                // 预览
                Section("预览") {
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    } else {
                        Text("生成预览...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("创建分享卡片")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("生成") {
                        generateCard()
                    }
                    .disabled(selectedDream == nil || isGenerating)
                }
            }
            .onAppear(perform: loadDreams)
        }
    }
    
    private func loadDreams() {
        // 加载梦境列表
        let descriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        dreams = try? SharedModelContainer.shared.container.viewContext.fetch(descriptor) ?? []
    }
    
    private func generateCard() {
        guard let dream = selectedDream else { return }
        
        isGenerating = true
        
        Task {
            do {
                // 创建卡片
                let config = ShareCardConfig(
                    showTags: showTags,
                    showEmotions: showEmotions,
                    showDate: showDate,
                    showWatermark: showWatermark
                )
                
                let card = try await service.createShareCard(
                    dreamId: dream.id,
                    template: selectedTemplate,
                    customConfig: config
                )
                
                // 生成预览图片
                let image = try await service.generateCardImage(card: card, dream: dream)
                previewImage = image
                
                isGenerating = false
            } catch {
                print("生成卡片失败：\(error)")
                isGenerating = false
            }
        }
    }
}

// MARK: - 主题按钮

struct ThemeButton: View {
    let theme: ShareCardTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: theme.gradientColors.map { Color(hex: $0.description) }),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 3)
                        )
                    
                    Text(theme.icon)
                        .font(.title2)
                }
                
                Text(theme.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 卡片详情视图

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var service = DreamShareCardService.shared
    let card: DreamShareCard
    @State private var cardImage: UIImage?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 卡片图片
                    if let image = cardImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            .shadow(radius: 12)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 20) {
                        Button(action: shareCard) {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                Text("分享")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: toggleFavorite) {
                            VStack {
                                Image(systemName: card.isFavorite ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(card.isFavorite ? .red : .gray)
                                Text(card.isFavorite ? "已收藏" : "收藏")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: deleteCard) {
                            VStack {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                Text("删除")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 统计信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text("卡片信息")
                            .font(.headline)
                        
                        HStack {
                            Label("\(card.shareCount) 次分享", systemImage: "square.and.arrow.up")
                            Spacer()
                            Label(card.theme.displayName, systemImage: "paintpalette")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Text("创建于 \(card.createdAt.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("卡片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadCardImage)
        }
    }
    
    private func loadCardImage() {
        // 加载卡片图片
        if let data = card.generatedImageData {
            cardImage = UIImage(data: data)
        }
    }
    
    private func shareCard() {
        showingShareSheet = true
    }
    
    private func toggleFavorite() {
        do {
            try service.toggleFavorite(card)
        } catch {
            print("切换收藏失败：\(error)")
        }
    }
    
    private func deleteCard() {
        do {
            try service.deleteCard(card)
            dismiss()
        } catch {
            print("删除卡片失败：\(error)")
        }
    }
}

// MARK: - 分享统计视图

struct ShareStatsView: View {
    @Environment(\.dismiss) private var dismiss
    let stats: ShareCardStats
    
    var body: some View {
        NavigationView {
            Form {
                Section("总览") {
                    StatRow(title: "总卡片数", value: "\(stats.totalCards)", icon: "photo")
                    StatRow(title: "总分享次数", value: "\(stats.totalShares)", icon: "square.and.arrow.up")
                    StatRow(title: "收藏卡片", value: "\(stats.favoriteCards)", icon: "heart")
                }
                
                if let mostUsed = stats.mostUsedTheme {
                    Section("常用主题") {
                        HStack {
                            Text(mostUsed.icon)
                            Text(mostUsed.displayName)
                        }
                    }
                }
                
                Section("按主题分布") {
                    ForEach(stats.cardsByTheme.sorted(by: { $0.value > $1.value }), id: \.key) { theme, count in
                        HStack {
                            Text(ShareCardTheme(rawValue: theme)?.icon ?? "🎨")
                            Text(ShareCardTheme(rawValue: theme)?.displayName ?? theme)
                            Spacer()
                            Text("\(count) 张")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("最近分享") {
                    ForEach(stats.recentShares, id: \.cardId) { record in
                        HStack {
                            Text(record.platform)
                            Spacer()
                            Text(record.timestamp.formatted())
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("分享统计")
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

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 30)
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    DreamShareCardView()
}
