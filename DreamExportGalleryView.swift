//
//  DreamExportGalleryView.swift
//  DreamLog - 梦境导出画廊 UI 界面
//
//  Phase 75: 梦境导出画廊
//  统一管理所有导出内容 (PDF/音频/视频/分享卡片)
//

import SwiftUI
import SwiftData

// MARK: - 主视图

public struct DreamExportGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamExportGalleryService?
    @State private var stats: DreamExportStats = DreamExportStats()
    @State private var filter: ExportGalleryFilter = ExportGalleryFilter()
    @State private var searchText: String = ""
    @State private var showingTypeFilter: Bool = false
    @State private var selectedExport: DreamExportItem?
    @State private var showingDeleteConfirm: Bool = false
    @State private var exports: [DreamExportItem] = []
    @State private var isLoading: Bool = true
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if exports.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle("导出画廊")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    statsButton
                }
            }
            .searchable(text: $searchText, prompt: "搜索导出内容")
            .onChange(of: searchText) { _, newValue in
                filter.searchText = newValue
                loadExports()
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .sheet(item: $selectedExport) { export in
                ExportDetailView(export: export, service: service)
            }
            .confirmationDialog("删除导出", isPresented: $showingDeleteConfirm) {
                Button("删除", role: .destructive) {
                    deleteSelected()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这个导出吗？此操作不可撤销。")
            }
        }
    }
    
    // MARK: - 子视图
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载导出内容...")
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("暂无导出内容")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("开始导出你的梦境，创建精美的 PDF、音频或视频")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {}) {
                Label("开始导出", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 统计卡片
                statsOverviewCard
                
                // 类型筛选
                typeFilterSection
                
                // 导出列表
                exportsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 统计卡片
    
    private var statsOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("导出概览")
                    .font(.headline)
                Spacer()
                Text("共 \(stats.totalExports) 项")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                StatBox(
                    value: "\(stats.totalExports)",
                    label: "总导出",
                    icon: "doc.fill",
                    color: .blue
                )
                
                StatBox(
                    value: stats.storageUsage,
                    label: "存储空间",
                    icon: "externaldrive.fill",
                    color: .purple
                )
                
                StatBox(
                    value: "\(stats.totalShareCount)",
                    label: "分享次数",
                    icon: "square.and.arrow.up",
                    color: .green
                )
                
                StatBox(
                    value: "\(stats.totalViewCount)",
                    label: "浏览次数",
                    icon: "eye.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 类型筛选
    
    private var typeFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("导出类型")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "全部",
                        icon: "square.grid.2x2",
                        isSelected: filter.type == nil
                    ) {
                        filter.type = nil
                        loadExports()
                    }
                    
                    ForEach(DreamExportType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            icon: type.icon,
                            isSelected: filter.type == type
                        ) {
                            filter.type = type
                            loadExports()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 导出列表
    
    private var exportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("导出内容")
                    .font(.headline)
                Spacer()
                Menu {
                    ForEach(ExportGalleryFilter.ExportSortOption.allCases, id: \.self) { option in
                        Button(action: {
                            filter.sortBy = option
                            loadExports()
                        }) {
                            HStack {
                                Text(option.displayName)
                                if filter.sortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(filter.sortBy.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(exports, id: \.id) { export in
                    ExportCard(
                        export: export,
                        onTap: {
                            Task {
                                if let service = service {
                                    try? await service.incrementViewCount(export)
                                    await loadData()
                                }
                            }
                            selectedExport = export
                        },
                        onFavorite: {
                            Task {
                                if let service = service {
                                    try? await service.toggleFavorite(export)
                                    await loadData()
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 工具栏按钮
    
    private var filterButton: some View {
        Button(action: { showingTypeFilter.toggle() }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    private var statsButton: some View {
        Button(action: { }) {
            Image(systemName: "chart.bar.fill")
        }
    }
    
    // MARK: - 数据加载
    
    private func loadData() async {
        isLoading = true
        
        // 初始化服务
        if service == nil {
            service = DreamExportGalleryService(modelContext: modelContext)
        }
        
        // 加载数据
        await MainActor.run {
            if let service = service {
                stats = service.getExportStats()
                exports = service.getAllExports(filter: filter)
            }
            isLoading = false
        }
    }
    
    private func loadExports() {
        Task {
            await loadData()
        }
    }
    
    private func deleteSelected() {
        guard let selected = selectedExport, let service = service else { return }
        
        Task {
            try? await service.deleteExport(selected)
            await loadData()
            selectedExport = nil
        }
    }
}

// MARK: - 统计卡片组件

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 筛选芯片组件

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 导出卡片组件

struct ExportCard: View {
    let export: DreamExportItem
    let onTap: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(typeColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: export.type.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                if export.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .offset(x: 20, y: -20)
                }
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(export.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(export.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let duration = export.formattedDuration {
                        Text("•")
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                    Text(export.formattedExportDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Label("\(export.shareCount)", systemImage: "square.and.arrow.up")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label("\(export.viewCount)", systemImage: "eye")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(export.formattedFileSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 收藏按钮
            Button(action: onFavorite) {
                Image(systemName: export.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(export.isFavorite ? .red : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onTapGesture(perform: onTap)
    }
    
    private var typeColor: Color {
        switch export.type {
        case .pdf: return .blue
        case .audio: return .purple
        case .video: return .pink
        case .shareCard: return .orange
        case .arScene: return .green
        case .story: return .indigo
        }
    }
}

// MARK: - 详情视图

struct ExportDetailView: View {
    let export: DreamExportItem
    let service: DreamExportGalleryService?
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet: Bool = false
    @State private var showingRenameSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 预览区域
                    previewSection
                    
                    // 信息区域
                    infoSection
                    
                    // 统计区域
                    statsSection
                    
                    // 操作按钮
                    actionSection
                }
                .padding()
            }
            .navigationTitle(export.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    shareButton
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [export.title])
            }
            .sheet(isPresented: $showingRenameSheet) {
                RenameSheet(title: $export.title)
            }
        }
    }
    
    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(typeGradient)
                .frame(height: 200)
            
            VStack(spacing: 12) {
                Image(systemName: export.type.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text(export.type.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var typeGradient: LinearGradient {
        switch export.type {
        case .pdf:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .audio:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .video:
            return LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .shareCard:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .arScene:
            return LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .story:
            return LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("信息")
                .font(.headline)
            
            InfoRow(label: "标题", value: export.title)
            InfoRow(label: "描述", value: export.description)
            InfoRow(label: "类型", value: export.type.displayName)
            InfoRow(label: "导出日期", value: export.formattedExportDate)
            if let duration = export.formattedDuration {
                InfoRow(label: "时长", value: duration)
            }
            InfoRow(label: "梦境数量", value: "\(export.dreamCount)")
            InfoRow(label: "文件大小", value: export.formattedFileSize)
            
            if !export.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(export.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("统计")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatItem(icon: "square.and.arrow.up", value: "\(export.shareCount)", label: "分享")
                StatItem(icon: "eye", value: "\(export.viewCount)", label: "浏览")
                StatItem(icon: "calendar", value: export.formattedExportDate, label: "日期")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            ActionButton(title: "分享", icon: "square.and.arrow.up", color: .blue) {
                showingShareSheet = true
            }
            
            ActionButton(title: "重命名", icon: "pencil", color: .purple) {
                showingRenameSheet = true
            }
            
            ActionButton(title: export.isFavorite ? "取消收藏" : "收藏", icon: export.isFavorite ? "heart.slash" : "heart", color: .red) {
                Task {
                    try? await service?.toggleFavorite(export)
                    dismiss()
                }
            }
            
            ActionButton(title: "删除", icon: "trash", color: .red, isDestructive: true) {
                Task {
                    try? await service?.deleteExport(export)
                    dismiss()
                }
            }
        }
    }
    
    private var shareButton: some View {
        Button(action: { showingShareSheet = true }) {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

// MARK: - 辅助组件

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .font(.headline)
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(isDestructive ? .red : color)
            .cornerRadius(12)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct RenameSheet: View {
    @Binding var title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("标题", text: $title)
                }
            }
            .navigationTitle("重命名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    DreamExportGalleryView()
        .modelContainer(for: DreamExportItem.self, inMemory: true)
}
