//
//  DreamExportTemplateEditorView.swift
//  DreamLog
//
//  Phase 53 - 导出模板编辑器
//  创建时间：2026-03-16
//

import SwiftUI
import SwiftData

// MARK: - 模板编辑器主视图

struct DreamExportTemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var templates: [DreamExportTemplate] = []
    @State private var presetTemplates: [DreamExportTemplate] = []
    @State private var showingCreateSheet = false
    @State private var selectedCategory: TemplateCategory?
    @State private var searchText = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("导出模板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreateSheet = true }) {
                        Label("新建", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateTemplateView {
                    Task {
                        await loadTemplates()
                    }
                }
            }
            .task {
                await loadTemplates()
            }
            .searchable(text: $searchText, prompt: "搜索模板")
        }
    }
    
    // MARK: - 子视图
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载模板...")
                .foregroundColor(.secondary)
        }
    }
    
    private var contentView: some View {
        List {
            // 分类筛选
            categoryFilterSection
            
            // 收藏模板
            if !searchText.isEmpty || selectedCategory == nil {
                favoriteSection
            }
            
            // 预设模板
            if !searchText.isEmpty || selectedCategory == nil {
                presetSection
            }
            
            // 自定义模板
            customSection
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 分区视图
    
    private var categoryFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "全部",
                        icon: "📋",
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation {
                            selectedCategory = nil
                        }
                    }
                    
                    ForEach(TemplateCategory.allCases) { category in
                        FilterChip(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var favoriteSection: some View {
        Section("收藏") {
            let favorites = filteredTemplates.filter { $0.isFavorite }
            if favorites.isEmpty {
                Text("暂无收藏模板")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(favorites) { template in
                    TemplateRow(template: template, onDelete: deleteTemplate)
                }
            }
        }
    }
    
    private var presetSection: some View {
        Section("预设模板") {
            let presets = filteredTemplates.filter { $0.isPreset }
            ForEach(presets) { template in
                TemplateRow(template: template, onDelete: nil)
            }
        }
    }
    
    private var customSection: some View {
        Section("我的模板") {
            let customs = filteredTemplates.filter { !$0.isPreset }
            if customs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无自定义模板")
                        .foregroundColor(.secondary)
                    Text("点击右上角 + 创建新模板")
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ForEach(customs) { template in
                    TemplateRow(template: template, onDelete: deleteTemplate)
                }
            }
        }
    }
    
    // MARK: - 过滤逻辑
    
    private var filteredTemplates: [DreamExportTemplate] {
        var result = templates
        
        // 按分类过滤
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // 按搜索过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    // MARK: - 操作
    
    private func loadTemplates() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let service = DreamExportTemplateService.shared
            templates = try await service.getAllTemplates()
            presetTemplates = try await service.getPresetTemplates()
        } catch {
            print("加载模板失败：\(error)")
        }
    }
    
    private func refresh() {
        Task {
            await loadTemplates()
        }
    }
    
    private func deleteTemplate(_ template: DreamExportTemplate) {
        Task {
            do {
                try await DreamExportTemplateService.shared.deleteTemplate(template)
                await loadTemplates()
            } catch {
                print("删除模板失败：\(error)")
            }
        }
    }
}

// MARK: - 模板行视图

struct TemplateRow: View {
    let template: DreamExportTemplate
    let onDelete: ((DreamExportTemplate) -> Void)?
    
    @State private var showingDetail = false
    @State private var showingEdit = false
    @State private var showingShare = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            VStack {
                Text(template.category.icon)
                    .font(.title2)
                Text(template.format.fileExtension.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                    
                    if template.isPreset {
                        Text("预设")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    if template.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(template.platform.displayName, systemImage: "square.grid.2x2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if template.usageCount > 0 {
                        Label("\(template.usageCount)次", systemImage: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 操作按钮
            Menu {
                Button(action: { showingDetail = true }) {
                    Label("查看详情", systemImage: "eye")
                }
                
                if !template.isPreset {
                    Button(action: { showingEdit = true }) {
                        Label("编辑", systemImage: "pencil")
                    }
                }
                
                Button(action: toggleFavorite) {
                    Label(template.isFavorite ? "取消收藏" : "收藏", systemImage: template.isFavorite ? "heart.slash" : "heart")
                }
                
                Button(action: { showingShare = true }) {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                
                if let onDelete = onDelete {
                    Divider()
                    Button(role: .destructive, action: { onDelete(template) }) {
                        Label("删除", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetail) {
            TemplateDetailView(template: template)
        }
        .sheet(isPresented: $showingEdit) {
            EditTemplateView(template: template) {
                // 刷新列表
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareTemplateView(template: template)
        }
    }
    
    private func toggleFavorite() {
        Task {
            do {
                try await DreamExportTemplateService.shared.toggleFavorite(template)
            } catch {
                print("切换收藏失败：\(error)")
            }
        }
    }
}

// MARK: - 分类筛选芯片

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - 创建模板视图

struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var content = ""
    @State private var platform: ExportPlatform = .markdown
    @State private var format: ExportFormat = .markdown
    @State private var category: TemplateCategory = .general
    @State private var showingVariablePicker = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("模板名称", text: $name)
                    TextField("描述（可选）", text: $description)
                    
                    Picker("分类", selection: $category) {
                        ForEach(TemplateCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("导出设置") {
                    Picker("目标平台", selection: $platform) {
                        ForEach(ExportPlatform.allCases) { platform in
                            Text("\(platform.icon) \(platform.displayName)").tag(platform)
                        }
                    }
                    
                    Picker("文件格式", selection: $format) {
                        ForEach(ExportFormat.allCases, id: \.rawValue) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }
                
                Section("模板内容") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("内容")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showingVariablePicker = true }) {
                                Label("插入变量", systemImage: "plus.app")
                            }
                            .font(.caption)
                        }
                        
                        TextEditor(text: $content)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Section("可用变量") {
                    ForEach(TemplateVariable.allCases) { variable in
                        HStack {
                            Text(variable.placeholder)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text(variable.displayName)
                                    .font(.caption)
                                Text(variable.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("新建模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTemplate()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingVariablePicker) {
                VariablePickerView { variable in
                    content += variable.placeholder
                }
            }
        }
    }
    
    private func saveTemplate() {
        isSaving = true
        
        Task {
            do {
                try await DreamExportTemplateService.shared.createTemplate(
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces),
                    content: content,
                    platform: platform,
                    format: format,
                    category: category
                )
                
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - 变量选择器

struct VariablePickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onInsert: (TemplateVariable) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(TemplateVariable.allCases) { variable in
                    Button(action: {
                        onInsert(variable)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(variable.placeholder)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                            
                            Text(variable.displayName)
                                .font(.subheadline)
                            
                            Text(variable.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("插入变量")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 模板详情视图

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let template: DreamExportTemplate
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    InfoCard(title: template.name, subtitle: template.description)
                    
                    // 设置
                    SettingsCard(template: template)
                    
                    // 内容预览
                    ContentCard(content: template.content)
                    
                    // 变量列表
                    VariablesCard(variables: template.variables)
                    
                    // 统计
                    StatsCard(template: template)
                }
                .padding()
            }
            .navigationTitle("模板详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 卡片组件

struct InfoCard: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsCard: View {
    let template: DreamExportTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("导出设置")
                .font(.headline)
            
            HStack {
                Label("平台", systemImage: "square.grid.2x2")
                Spacer()
                Text("\(template.platform.icon) \(template.platform.displayName)")
            }
            
            HStack {
                Label("格式", systemImage: "doc")
                Spacer()
                Text(template.format.displayName)
            }
            
            HStack {
                Label("分类", systemImage: "folder")
                Spacer()
                Text("\(template.category.icon) \(template.category.displayName)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ContentCard: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模板内容")
                .font(.headline)
            
            ScrollView {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct VariablesCard: View {
    let variables: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用变量")
                .font(.headline)
            
            if variables.isEmpty {
                Text("未使用变量")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(variables, id: \.self) { variable in
                        Text("{{\(variable)}}")
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatsCard: View {
    let template: DreamExportTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("统计")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(label: "使用次数", value: "\(template.usageCount)", icon: "arrow.up.right")
                StatItem(label: "创建时间", value: formatDate(template.createdAt), icon: "calendar")
                StatItem(label: "更新时间", value: formatDate(template.updatedAt), icon: "clock")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - 编辑模板视图（简化版）

struct EditTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    
    let template: DreamExportTemplate
    let onSave: () -> Void
    
    @State private var name: String
    @State private var description: String
    @State private var content: String
    @State private var category: TemplateCategory
    
    init(template: DreamExportTemplate, onSave: @escaping () -> Void) {
        self.template = template
        self.onSave = onSave
        _name = State(initialValue: template.name)
        _description = State(initialValue: template.description)
        _content = State(initialValue: template.content)
        _category = State(initialValue: template.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("模板名称", text: $name)
                TextField("描述", text: $description)
                
                Picker("分类", selection: $category) {
                    ForEach(TemplateCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
            }
            .navigationTitle("编辑模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTemplate()
                    }
                }
            }
        }
    }
    
    private func saveTemplate() {
        Task {
            template.name = name
            template.description = description
            template.content = content
            template.category = category
            
            do {
                try await DreamExportTemplateService.shared.updateTemplate(template)
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                print("保存失败：\(error)")
            }
        }
    }
}

// MARK: - 分享模板视图

struct ShareTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    
    let template: DreamExportTemplate
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("分享模板功能开发中...")
                    .foregroundColor(.secondary)
                
                Button("导出为 JSON") {
                    // TODO: 实现导出功能
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("分享模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
