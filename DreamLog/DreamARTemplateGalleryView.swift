//
//  DreamARTemplateGalleryView.swift
//  DreamLog - Phase 22: AR Enhancement & 3D Dream World
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - Template Gallery View

/// AR 场景模板画廊界面
struct DreamARTemplateGalleryView: View {
    @ObservedObject private var templateService = DreamARTemplateService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var selectedDifficulty: TemplateDifficulty? = nil
    @State private var searchText = ""
    @State private var selectedTemplate: DreamARTemplate? = nil
    @State private var showTemplateDetail = false
    @State private var applyingTemplate = false
    
    private var filteredTemplates: [DreamARTemplate] {
        var templates = templateService.availableTemplates
        
        // 按类别筛选
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        // 按难度筛选
        if let difficulty = selectedDifficulty {
            templates = templates.filter { $0.difficulty == difficulty }
        }
        
        // 按搜索过滤
        if !searchText.isEmpty {
            templates = templates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return templates
    }
    
    private var categories: [TemplateCategory] {
        TemplateCategory.allCases
    }
    
    private var difficulties: [TemplateDifficulty] {
        TemplateDifficulty.allCases
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchBar
                
                Divider()
                
                // 筛选器
                filterSection
                
                Divider()
                
                // 模板网格
                templateGrid
                
                // 底部统计
                if !filteredTemplates.isEmpty {
                    statsBar
                }
            }
            .navigationTitle("场景模板")
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
                        Image(systemName: "star")
                    }
                }
            }
            .sheet(isPresented: $showTemplateDetail) {
                if let template = selectedTemplate {
                    TemplateDetailView(
                        template: template,
                        templateService: templateService,
                        onApply: applyTemplate
                    )
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索模板...", text: $searchText)
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
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // 类别筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ARTemplateFilterChip(
                        title: "全部",
                        icon: "square.grid.2x2",
                        color: .purple,
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(categories, id: \.self) { category in
                        ARTemplateFilterChip(
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
                .padding(.vertical, 10)
            }
            
            // 难度筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ARTemplateFilterChip(
                        title: "全部难度",
                        icon: "star",
                        color: .orange,
                        isSelected: selectedDifficulty == nil
                    ) {
                        selectedDifficulty = nil
                    }
                    
                    ForEach(difficulties, id: \.self) { difficulty in
                        ARTemplateFilterChip(
                            title: difficulty.displayName,
                            icon: difficulty.icon,
                            color: difficulty.color,
                            isSelected: selectedDifficulty == difficulty
                        ) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(Color.gray.opacity(0.03))
    }
    
    // MARK: - Template Grid
    
    private var templateGrid: some View {
        ScrollView {
            if filteredTemplates.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredTemplates, id: \.id) { template in
                        TemplateCard(
                            template: template,
                            isFavorite: templateService.favoriteTemplates.contains(template.id),
                            onSelect: {
                                selectedTemplate = template
                                showTemplateDetail = true
                            },
                            onToggleFavorite: {
                                templateService.toggleFavorite(template.id)
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(searchText.isEmpty ? "暂无模板" : "未找到模板")
                .font(.headline)
                .foregroundColor(.gray)
            
            if !searchText.isEmpty {
                Text("尝试其他搜索词或筛选条件")
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
            Text("\(filteredTemplates.count) 个模板")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text("\(templateService.favoriteTemplates.count) 个收藏")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Apply Template
    
    private func applyTemplate(_ template: DreamARTemplate) {
        applyingTemplate = true
        
        // 通知应用模板
        NotificationCenter.default.post(
            name: NSNotification.Name("ApplyARTemplate"),
            object: template
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            applyingTemplate = false
            dismiss()
        }
    }
}

// MARK: - Filter Chip

struct ARTemplateFilterChip: View {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : color)
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: DreamARTemplate
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 模板预览图
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(template.category.color.gradient)
                        .frame(width: 100, height: 100)
                    
                    VStack(spacing: 4) {
                        Image(systemName: template.category.icon)
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        
                        Text("\(template.elements.count) 个元素")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // 收藏按钮
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                onToggleFavorite()
                            }) {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(isFavorite ? .yellow : .white.opacity(0.7))
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                                    .padding(4)
                            }
                        }
                        Spacer()
                    }
                }
                
                // 模板信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // 难度标识
                        HStack(spacing: 2) {
                            let stars = template.difficulty == .easy ? 1 : (template.difficulty == .medium ? 2 : 3)
                            ForEach(0..<stars, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label(template.category.displayName, systemImage: template.category.icon)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Label("难度", systemImage: "chart.bar")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(template.difficulty.displayName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(isHovering ? 0.08 : 0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Template Detail View

struct TemplateDetailView: View {
    let template: DreamARTemplate
    let templateService: DreamARTemplateService
    let onApply: (DreamARTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isApplying = false
    
    private var isFavorite: Bool {
        templateService.favoriteTemplates.contains(template.id)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 预览区域
                    previewSection
                    
                    // 基本信息
                    infoSection
                    
                    // 元素列表
                    elementsSection
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        templateService.toggleFavorite(template.id)
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .yellow : .gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(template.category.color.gradient)
                .frame(height: 200)
            
            VStack(spacing: 12) {
                Image(systemName: template.category.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text(template.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    let stars = template.difficulty == .easy ? 1 : (template.difficulty == .medium ? 2 : 3)
                    ForEach(0..<stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模板信息")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "类别", value: template.category.displayName)
                InfoRow(label: "难度", value: template.difficulty.displayName)
                InfoRow(label: "元素数量", value: "\(template.elements.count) 个")
                InfoRow(label: "ID", value: String(template.id.uuidString.prefix(8)))
            }
            
            Divider()
            
            Text("描述")
                .font(.headline)
            
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Elements Section
    
    private var elementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("场景元素")
                .font(.headline)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                ForEach(template.elements, id: \.id) { element in
                    VStack(spacing: 4) {
                        Image(systemName: element.category.icon)
                            .font(.system(size: 30))
                            .foregroundColor(element.category.color)
                        
                        Text(element.name)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: applyTemplate) {
                HStack {
                    if isApplying {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isApplying ? "应用模板中..." : "应用此模板")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isApplying ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isApplying)
            
            Button(action: { dismiss() }) {
                Text("取消")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Apply Template
    
    private func applyTemplate() {
        isApplying = true
        onApply(template)
    }
}

#Preview {
    DreamARTemplateGalleryView()
}
