//
//  DreamSymbolExplorerView.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  UI 界面 - 梦境符号探索浏览器
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI
import SwiftData

// MARK: - 主视图

struct DreamSymbolExplorerView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = SymbolExplorerViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: SymbolCategory? = nil
    @State private var showingFilters = false
    @State private var selectedSymbol: DreamSymbolData? = nil
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.symbols.isEmpty && !searchText.isEmpty {
                    emptySearchView
                } else {
                    symbolGridView
                }
            }
            .navigationTitle("符号词典")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索符号...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(item: $selectedSymbol) { symbol in
                SymbolDetailView(symbol: symbol)
            }
        }
        .task {
            await viewModel.loadSymbols()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载符号词典...")
                .foregroundColor(.secondary)
        }
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("未找到相关符号")
                .font(.headline)
            
            Text("试试其他关键词")
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var symbolGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200))
            ], spacing: 16) {
                ForEach(filteredSymbols) { symbol in
                    SymbolCard(
                        symbol: symbol,
                        isFavorite: viewModel.isFavorite(symbol.id),
                        onTap: { selectedSymbol = symbol },
                        onToggleFavorite: { viewModel.toggleFavorite(symbol.id) }
                    )
                }
            }
            .padding()
        }
    }
    
    private var filteredSymbols: [DreamSymbolData] {
        var symbols = viewModel.symbols
        
        // 搜索过滤
        if !searchText.isEmpty {
            symbols = symbols.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.surfaceMeaning.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 分类过滤
        if let category = selectedCategory {
            symbols = symbols.filter { $0.category == category }
        }
        
        // 收藏过滤
        if viewModel.showFavoritesOnly {
            symbols = symbols.filter { viewModel.isFavorite($0.id) }
        }
        
        return symbols
    }
    
    private var filterButton: some View {
        Button(action: { showingFilters.toggle() }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .confirmationDialog("筛选", isPresented: $showingFilters) {
            Picker("分类", selection: $selectedCategory) {
                Text("全部").tag(nil as SymbolCategory?)
                ForEach(SymbolCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category as SymbolCategory?)
                }
            }
            
            Button(viewModel.showFavoritesOnly ? "显示全部" : "仅收藏") {
                viewModel.showFavoritesOnly.toggle()
            }
            
            Button("取消", role: .cancel) { }
        }
    }
}

// MARK: - 符号卡片

struct SymbolCard: View {
    let symbol: DreamSymbolData
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: symbolIcon(for: symbol.category))
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    Spacer()
                    
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                    }
                    .buttonStyle(.plain)
                }
                
                Text(symbol.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(symbol.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                
                Text(symbol.surfaceMeaning)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private func symbolIcon(for category: SymbolCategory) -> String {
        switch category {
        case .person: return "person.fill"
        case .place: return "house.fill"
        case .object: return "cube.box.fill"
        case .action: return "figure.run"
        case .emotion: return "face.smiling"
        case .nature: return "leaf.fill"
        case .animal: return "pawprint.fill"
        case .other: return "sparkles"
        }
    }
}

// MARK: - 符号详情视图

struct SymbolDetailView: View {
    let symbol: DreamSymbolData
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLayer: SymbolLayer = .surface
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部
                    headerSection
                    
                    // 层级切换
                    layerPicker
                    
                    // 解读内容
                    interpretationSection
                    
                    // 文化解读
                    if !symbol.culturalInterpretations.isEmpty {
                        culturalSection
                    }
                    
                    // 相关符号
                    if !symbol.relatedSymbols.isEmpty {
                        relatedSection
                    }
                    
                    // 出现统计
                    if let stats = symbol.appearanceStats {
                        statsSection(stats)
                    }
                }
                .padding()
            }
            .navigationTitle(symbol.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: symbolIcon(for: symbol.category))
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text(symbol.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(symbol.category.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var layerPicker: some View {
        Picker("解读层级", selection: $selectedLayer) {
            Text("表面").tag(SymbolLayer.surface)
            Text("心理").tag(SymbolLayer.psychological)
            Text("精神").tag(SymbolLayer.spiritual)
        }
        .pickerStyle(.segmented)
    }
    
    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(layerTitle)
                .font(.headline)
            
            Text(layerContent)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            if !layerKeyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(layerKeyPoints, id: \.self) { point in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text(point)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var culturalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("文化解读")
                .font(.headline)
            
            ForEach(symbol.culturalInterpretations, id: \.culture) { interpretation in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(interpretation.culture)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(interpretation.origin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(interpretation.meaning)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相关符号")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(symbol.relatedSymbols, id: \.self) { related in
                    Text(related)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func statsSection(_ stats: SymbolAppearanceStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("出现统计")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatBox(
                    value: "\(stats.totalAppearances)",
                    label: "总出现次数"
                )
                
                StatBox(
                    value: "\(stats.dreamsCount)",
                    label: "梦境数量"
                )
                
                if let first = stats.firstAppearance {
                    StatBox(
                        value: formatDate(first),
                        label: "首次出现"
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Properties
    
    private var layerTitle: String {
        switch selectedLayer {
        case .surface: return "表面含义"
        case .psychological: return "心理含义"
        case .spiritual: return "精神含义"
        }
    }
    
    private var layerContent: String {
        switch selectedLayer {
        case .surface: return symbol.surfaceMeaning
        case .psychological: return symbol.psychologicalMeaning
        case .spiritual: return symbol.spiritualMeaning
        }
    }
    
    private var layerKeyPoints: [String] {
        switch selectedLayer {
        case .surface: return symbol.surfaceKeyPoints
        case .psychological: return symbol.psychologicalKeyPoints
        case .spiritual: return symbol.spiritualKeyPoints
        }
    }
    
    private func symbolIcon(for category: SymbolCategory) -> String {
        switch category {
        case .person: return "person.fill"
        case .place: return "house.fill"
        case .object: return "cube.box.fill"
        case .action: return "figure.run"
        case .emotion: return "face.smiling"
        case .nature: return "leaf.fill"
        case .animal: return "pawprint.fill"
        case .other: return "sparkles"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 统计盒子

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 视图模型

@MainActor
class SymbolExplorerViewModel: ObservableObject {
    
    @Published var symbols: [DreamSymbolData] = []
    @Published var isLoading = false
    @Published var showFavoritesOnly = false
    
    private var favorites: Set<String> = []
    private let symbolDictionary = DreamSymbolDictionary()
    
    func loadSymbols() async {
        isLoading = true
        
        // 从符号词典加载所有符号
        let allSymbols = await symbolDictionary.getAllSymbols()
        
        await MainActor.run {
            self.symbols = allSymbols
            self.isLoading = false
        }
    }
    
    func isFavorite(_ symbolId: String) -> Bool {
        favorites.contains(symbolId)
    }
    
    func toggleFavorite(_ symbolId: String) {
        if favorites.contains(symbolId) {
            favorites.remove(symbolId)
        } else {
            favorites.insert(symbolId)
        }
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            var positions: [CGPoint] = []
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
            self.positions = positions
        }
    }
}

// MARK: - 符号层级枚举

enum SymbolLayer {
    case surface
    case psychological
    case spiritual
}

// MARK: - Preview

#Preview {
    DreamSymbolExplorerView()
}
