//
//  DreamARModelBrowserView.swift
//  DreamLog - Phase 22: AR Enhancement & 3D Dream World
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - Model Browser View

/// 3D 模型浏览器界面
struct DreamARModelBrowserView: View {
    @ObservedObject private var modelsLibrary = DreamARModelsLibrary.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: ModelCategory? = nil
    @State private var searchText = ""
    @State private var selectedElement: DreamARElement3D? = nil
    @State private var showElementDetail = false
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    private var filteredModels: [DreamARElement3D] {
        var models = modelsLibrary.availableModels
        
        // 按类别筛选
        if let category = selectedCategory {
            models = models.filter { $0.category == category }
        }
        
        // 按搜索过滤
        if !searchText.isEmpty {
            models = models.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.nameLocalizable.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return models
    }
    
    private var categories: [ModelCategory] {
        ModelCategory.allCases
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar
                
                Divider()
                
                // 类别选择器
                categorySelector
                
                Divider()
                
                // 模型网格
                modelGrid
                
                // 底部统计
                if !filteredModels.isEmpty {
                    statsBar
                }
            }
            .navigationTitle("3D 模型库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 显示收藏
                    } label: {
                        Image(systemName: "heart")
                    }
                }
            }
            .sheet(isPresented: $showElementDetail) {
                if let element = selectedElement {
                    ElementDetailView(element: element, modelsLibrary: modelsLibrary)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索模型...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Category Selector
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部类别
                CategoryChip(
                    title: "全部",
                    icon: "square.grid.2x2",
                    color: .purple,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // 各个类别
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Model Grid
    
    private var modelGrid: some View {
        ScrollView {
            if filteredModels.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 16
                ) {
                    ForEach(filteredModels, id: \.id) { model in
                        ModelCard(
                            model: model,
                            isDownloading: modelsLibrary.downloadTasks[model.id] != nil
                        ) {
                            selectedElement = model
                            showElementDetail = true
                        } onDownload: {
                            downloadModel(model)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(searchText.isEmpty ? "暂无模型" : "未找到模型")
                .font(.headline)
                .foregroundColor(.gray)
            
            if !searchText.isEmpty {
                Text("尝试其他搜索词")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Stats Bar
    
    private var statsBar: some View {
        HStack {
            Text("\(filteredModels.count) 个模型")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text("\(modelsLibrary.favoriteModels.count) 个收藏")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Download Action
    
    private func downloadModel(_ model: DreamARElement3D) {
        guard model.downloadStatus == .notDownloaded else { return }
        
        isDownloading = true
        
        Task {
            do {
                try await modelsLibrary.downloadModel(model)
                isDownloading = false
            } catch {
                isDownloading = false
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : color)
        }
    }
}

// MARK: - Model Card

struct ModelCard: View {
    let model: DreamARElement3D
    let isDownloading: Bool
    let onSelect: () -> Void
    let onDownload: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // 模型预览
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(model.category.color.opacity(0.1))
                        .frame(height: 100)
                    
                    // 3D 图标
                    Image(systemName: model.category.icon)
                        .font(.system(size: 40))
                        .foregroundColor(model.category.color)
                    
                    // 下载状态
                    if model.downloadStatus == .downloaded {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .padding(4)
                        }
                    } else if isDownloading {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            .padding(4)
                        }
                    }
                }
                
                // 模型信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(model.category.displayName)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Element Detail View

struct ElementDetailView: View {
    let element: DreamARElement3D
    let modelsLibrary: DreamARModelsLibrary
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAddingToScene = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 预览区域
                    previewSection
                    
                    // 基本信息
                    infoSection
                    
                    // 材质配置
                    materialSection(element.material)
                    
                    // 元素信息
                    elementInfoSection(element)
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(element.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        modelsLibrary.toggleFavorite(element)
                    } label: {
                        Image(systemName: modelsLibrary.favoriteModels.contains(where: { $0.id == element.id }) ? "heart.fill" : "heart")
                            .foregroundColor(modelsLibrary.favoriteModels.contains(where: { $0.id == element.id }) ? .red : .gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(element.category.color.opacity(0.1))
                .frame(height: 250)
            
            VStack(spacing: 16) {
                Image(systemName: element.category.icon)
                    .font(.system(size: 80))
                    .foregroundColor(element.category.color)
                
                Text(element.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(element.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.headline)
            
            InfoRow(label: "模型 ID", value: String(element.id.prefix(8)))
            InfoRow(label: "类别", value: element.category.displayName)
            InfoRow(label: "尺寸", value: "\(element.scale.x, specifier: "%.1f")m")
            InfoRow(label: "状态", value: downloadStatusText)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var downloadStatusText: String {
        switch element.downloadStatus {
        case .notDownloaded: return "未下载"
        case .downloading: return "下载中"
        case .downloaded: return "已下载"
        case .failed: return "下载失败"
        }
    }
    
    // MARK: - Material Section
    
    private func materialSection(_ material: MaterialConfig) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("材质配置")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                MaterialPropertyRow(name: "金属度", value: material.metallic, format: "percentage")
                MaterialPropertyRow(name: "粗糙度", value: material.roughness, format: "percentage")
                MaterialPropertyRow(name: "透明度", value: material.opacity, format: "percentage")
                
                if material.emissiveIntensity > 0 {
                    MaterialPropertyRow(name: "自发光", value: material.emissiveIntensity, format: "intensity")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Element Info Section
    
    private var elementInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("元素信息")
                .font(.headline)
            
            InfoRow(label: "类别", value: element.category.displayName)
            InfoRow(label: "类型", value: element.elementType.displayName)
            InfoRow(label: "大小", value: String(format: "%.1f", Float(element.scale)))
            InfoRow(label: "动画", value: element.animation?.displayName ?? "无")
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if element.downloadStatus == .notDownloaded {
                Button(action: downloadElement) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("下载模型")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else if element.downloadStatus == .downloaded {
                Button(action: addToScene) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("添加到场景")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Button(action: { dismiss() }) {
                Text("完成")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Actions
    
    private func downloadElement() {
        Task {
            do {
                try await modelsLibrary.downloadModel(element)
            } catch {
                print("下载失败：\(error)")
            }
        }
    }
    
    private func addToScene() {
        // 通知父视图添加到场景
        NotificationCenter.default.post(
            name: NSNotification.Name("AddElementToScene"),
            object: element
        )
        dismiss()
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Material Property Row

struct MaterialPropertyRow: View {
    let name: String
    let value: Float
    let format: String
    
    var body: some View {
        HStack {
            Text(name)
                .foregroundColor(.gray)
            Spacer()
            Text(formattedValue)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
    
    private var formattedValue: String {
        switch format {
        case "percentage":
            return String(format: "%.0f%%", value * 100)
        case "intensity":
            return String(format: "%.1f", value)
        default:
            return String(format: "%.2f", value)
        }
    }
}

#Preview {
    DreamARModelBrowserView()
}
