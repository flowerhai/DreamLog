//
//  DreamEBookExportView.swift
//  DreamLog
//
//  Phase 83: 梦境电子书导出功能
//  UI 界面：电子书配置、预览和导出
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 电子书导出主视图

struct DreamEBookExportView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: DreamEBookExportViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        _viewModel = StateObject(wrappedValue: DreamEBookExportViewModel(modelContainer: modelContainer))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                basicInfoSection
                
                // 主题选择
                themeSection
                
                // 日期范围
                dateRangeSection
                
                // 章节配置
                chaptersSection
                
                // 导出选项
                exportOptionsSection
                
                // 预览
                previewSection
            }
            .navigationTitle("导出电子书")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("导出") {
                        Task {
                            await viewModel.exportEBook()
                        }
                    }
                    .disabled(viewModel.isExporting)
                }
            }
            .overlay {
                if viewModel.isExporting {
                    exportingOverlay
                }
            }
            .alert("导出完成", isPresented: $viewModel.showSuccessAlert) {
                Button("查看文件") {
                    viewModel.openGeneratedFile()
                }
                Button("完成", role: .cancel) { }
            } message: {
                Text("电子书已生成并保存到文件 App")
            }
            .alert("导出失败", isPresented: $viewModel.showErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        Section("基本信息") {
            TextField("标题", text: $viewModel.config.title)
                .textFieldStyle(.roundedBorder)
            
            TextField("副标题 (可选)", text: $viewModel.config.subtitle)
                .textFieldStyle(.roundedBorder)
            
            TextField("作者名 (可选)", text: $viewModel.config.authorName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Text("封面图标")
                Spacer()
                TextField("图标", text: $viewModel.config.coverEmoji)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private var themeSection: some View {
        Section("视觉主题") {
            Picker("主题", selection: $viewModel.config.theme) {
                ForEach(EBookTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)
            
            // 主题预览
            VStack(alignment: .leading, spacing: 8) {
                Text("预览")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    ColorPreviewCircle(color: viewModel.config.theme.primaryColor, label: "主色")
                    ColorPreviewCircle(color: viewModel.config.theme.accentColor, label: "强调色")
                    ColorPreviewCircle(color: viewModel.config.theme.backgroundColor, label: "背景")
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var dateRangeSection: some View {
        Section("日期范围") {
            Picker("范围", selection: $viewModel.config.dateRange) {
                ForEach(EBookDateRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.menu)
            
            if viewModel.config.dateRange == .custom {
                DatePicker("开始日期", selection: $viewModel.customStartDate, displayedComponents: .date)
                DatePicker("结束日期", selection: $viewModel.customEndDate, displayedComponents: .date)
            }
        }
    }
    
    private var chaptersSection: some View {
        Section("章节设置") {
            Toggle("包含目录", isOn: $viewModel.config.tableOfContents)
            Toggle("页码", isOn: $viewModel.config.pageNumbering)
            
            NavigationLink("自定义章节") {
                ChapterEditorView(config: $viewModel.config)
            }
        }
    }
    
    private var exportOptionsSection: some View {
        Section("导出选项") {
            Picker("格式", selection: $viewModel.config.exportFormat) {
                ForEach(EBookExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
            
            DisclosureGroup("梦境详情") {
                Toggle("日期", isOn: $viewModel.config.dreamDetails.includeDate)
                Toggle("情绪", isOn: $viewModel.config.dreamDetails.includeEmotion)
                Toggle("标签", isOn: $viewModel.config.dreamDetails.includeTags)
                Toggle("AI 分析", isOn: $viewModel.config.dreamDetails.includeAIAnalysis)
                Toggle("心情评分", isOn: $viewModel.config.dreamDetails.includeMood)
                Toggle("清晰度", isOn: $viewModel.config.dreamDetails.includeClarity)
                Toggle("时长", isOn: $viewModel.config.dreamDetails.includeDuration)
                Toggle("备注", isOn: $viewModel.config.dreamDetails.includeNotes)
            }
        }
    }
    
    private var previewSection: some View {
        Section("预览") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("统计信息")
                        .font(.headline)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    StatItem(icon: "book.fill", value: "\(viewModel.dreamCount)", label: "梦境数")
                    StatItem(icon: "character.cursor.ibeam", value: "\(viewModel.estimatedWords)", label: "字数")
                    StatItem(icon: "doc.text.fill", value: "\(viewModel.estimatedPages)", label: "页数")
                }
                .padding(.vertical, 8)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Overlays
    
    private var exportingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: Double(viewModel.currentProgress), total: Double(viewModel.totalProgress))
                    .progressViewStyle(.linear)
                    .frame(width: 250)
                
                Text(viewModel.exportStatusText)
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// MARK: - 章节编辑器视图

struct ChapterEditorView: View {
    
    @Binding var config: EBookExportConfig
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddChapter = false
    
    var body: some View {
        Form {
            Section("章节列表") {
                ForEach($config.chapters) { $chapter in
                    ChapterRowView(chapter: $chapter)
                }
                .onMove { indices, newOffset in
                    config.chapters.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            
            Section {
                Button(action: { showingAddChapter = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("添加章节")
                    }
                }
                
                if !config.chapters.isEmpty {
                    Button("使用预设模板", action: {
                        config.chapters = []
                    })
                    .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("章节编辑")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingAddChapter) {
            AddChapterView(config: $config)
        }
    }
}

// MARK: - 章节行视图

struct ChapterRowView: View {
    @Binding var chapter: EBookChapter
    @State private var showingEdit = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(chapter.title)
                    .font(.headline)
                Text(chapter.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingEdit = true }) {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditChapterView(chapter: $chapter)
        }
    }
}

// MARK: - 添加章节视图

struct AddChapterView: View {
    @Binding var config: EBookExportConfig
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var type: EBookChapterType = .manual
    
    var body: some View {
        NavigationStack {
            Form {
                Section("章节信息") {
                    TextField("章节标题", text: $title)
                    
                    Picker("类型", selection: $type) {
                        ForEach(EBookChapterType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("添加章节")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let chapter = EBookChapter(
                            title: title,
                            type: type,
                            sortOrder: config.chapters.count
                        )
                        config.chapters.append(chapter)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - 编辑章节视图

struct EditChapterView: View {
    @Binding var chapter: EBookChapter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("章节信息") {
                    TextField("标题", text: $chapter.title)
                    
                    Picker("类型", selection: $chapter.type) {
                        ForEach(EBookChapterType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("编辑章节")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 辅助视图

struct ColorPreviewCircle: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .shadow(radius: 2)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View Model

@MainActor
class DreamEBookExportViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var config: EBookExportConfig
    @Published var isExporting = false
    @Published var currentProgress: Int = 0
    @Published var totalProgress: Int = 0
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage: String?
    @Published var generatedFileURL: URL?
    
    // MARK: - Properties
    
    private let service: DreamEBookExportService
    private var cancellables = Set<AnyCancellable>()
    
    // 自定义日期范围
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var customEndDate: Date = Date()
    
    // 统计信息
    var dreamCount: Int { 0 } // 将在实际实现中计算
    var estimatedWords: Int { dreamCount * 500 } // 估算
    var estimatedPages: Int { max(1, estimatedWords / 300) }
    
    var exportStatusText: String {
        "正在生成第 \(currentProgress) 章，共 \(totalProgress) 章"
    }
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.config = EBookExportConfig()
        self.service = DreamEBookExportService(modelContainer: modelContainer)
        
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        service.$exportStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleExportStatus(status)
            }
            .store(in: &cancellables)
        
        service.$currentProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentProgress)
        
        service.$totalProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$totalProgress)
    }
    
    private func handleExportStatus(_ status: EBookExportStatus) {
        switch status {
        case .idle:
            isExporting = false
            
        case .preparing:
            isExporting = true
            currentProgress = 0
            
        case .generating(let current, let total):
            isExporting = true
            currentProgress = current
            totalProgress = total
            
        case .completing:
            isExporting = true
            currentProgress = totalProgress
            
        case .success(let url):
            isExporting = false
            generatedFileURL = url
            showSuccessAlert = true
            
        case .failure(let message):
            isExporting = false
            errorMessage = message
            showErrorAlert = true
        }
    }
    
    // MARK: - Public Methods
    
    func exportEBook() async {
        // 更新自定义日期范围
        if config.dateRange == .custom {
            config.dateRange = .custom
        }
        
        await service.generateEBook(config: config)
    }
    
    func openGeneratedFile() {
        guard let url = generatedFileURL else { return }
        // 使用 UIDocumentInteractionController 或 shareSheet 打开文件
        // 简化实现
    }
    
    func cancelExport() {
        service.cancelExport()
    }
}

// MARK: - Preview

#Preview {
    DreamEBookExportView(modelContainer: SampleData.shared.modelContainer)
}
