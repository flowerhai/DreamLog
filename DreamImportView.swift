//
//  DreamImportView.swift
//  DreamLog - 梦境导入中心界面
//
//  Phase 34: 梦境导入中心 - 支持多格式导入
//  Created: 2026-03-13 20:04 UTC
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - 主导入视图

struct DreamImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var importService: DreamImportService
    @Query(sort: \DreamImportTask.createdAt, order: .reverse) private var importTasks: [DreamImportTask]
    
    @State private var isFilePickerPresented = false
    @State private var selectedSourceType: ImportSourceType?
    @State private var preview: ImportPreview?
    @State private var isImporting = false
    @State private var importSettings = ImportSettings()
    @State private var showError = false
    @State private var errorMessage = ""
    
    init() {
        _importService = StateObject(wrappedValue: DreamImportService())
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 快速导入区域
                Section {
                    quickImportButtons
                } header: {
                    Text("快速导入")
                }
                
                // 导入源选择
                Section {
                    ForEach(ImportSourceType.allCases) { sourceType in
                        sourceTypeButton(sourceType)
                    }
                } header: {
                    Text("选择导入源")
                }
                
                // 导入设置
                Section {
                    Toggle("跳过重复梦境", isOn: $importSettings.skipDuplicates)
                    Toggle("合并重复梦境", isOn: $importSettings.mergeDuplicates)
                        .disabled(importSettings.skipDuplicates)
                    Toggle("导入标签", isOn: $importSettings.importTags)
                    Toggle("导入情绪", isOn: $importSettings.importEmotions)
                    Toggle("自动 AI 分析", isOn: $importSettings.autoAnalyze)
                } header: {
                    Text("导入设置")
                }
                
                // 历史导入记录
                if !importTasks.isEmpty {
                    Section {
                        ForEach(importTasks.prefix(5)) { task in
                            ImportTaskRow(task: task)
                        }
                    } header: {
                        Text("最近导入")
                    }
                }
            }
            .navigationTitle("梦境导入")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isFilePickerPresented,
                allowedContentTypes: [.json, .csv, .plainText, .xml],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(item: $preview) { preview in
                ImportPreviewSheet(
                    preview: preview,
                    settings: $importSettings,
                    onImport: startImport,
                    onCancel: { preview = nil }
                )
            }
            .alert("导入错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            importService.onProgressUpdate = { progress, success, failure, duplicates in
                // 进度更新
            }
            importService.onComplete = { task in
                // 导入完成
                isImporting = false
            }
        }
    }
    
    // MARK: - 快速导入按钮
    
    private var quickImportButtons: some View {
        HStack(spacing: 16) {
            QuickImportButton(
                icon: "doc.text",
                title: "JSON",
                color: .orange
            ) {
                selectSourceType(.json)
            }
            
            QuickImportButton(
                icon: "tablecells",
                title: "CSV",
                color: .green
            ) {
                selectSourceType(.csv)
            }
            
            QuickImportButton(
                icon: "folder",
                title: "Obsidian",
                color: .purple
            ) {
                selectSourceType(.obsidian)
            }
            
            QuickImportButton(
                icon: "cloud",
                title: "Notion",
                color: .blue
            ) {
                selectSourceType(.notion)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 导入源按钮
    
    private func sourceTypeButton(_ sourceType: ImportSourceType) -> some View {
        Button {
            selectSourceType(sourceType)
        } label: {
            HStack {
                Image(systemName: sourceType.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading) {
                    Text(sourceType.displayName)
                        .font(.body)
                    Text(sourceType.supportedExtensions.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 操作
    
    private func selectSourceType(_ sourceType: ImportSourceType) {
        selectedSourceType = sourceType
        isFilePickerPresented = true
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first,
                  let sourceType = selectedSourceType else { return }
            
            Task {
                do {
                    preview = try await importService.previewFile(at: url, sourceType: sourceType)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func startImport() {
        guard let preview = preview else { return }
        
        isImporting = true
        
        Task {
            do {
                // 这里需要从 preview 获取实际文件 URL
                // 简化处理，实际需要传递文件 URL
                try await importService.startImport(
                    from: URL(fileURLWithPath: preview.fileName),
                    sourceType: preview.sourceType,
                    settings: importSettings
                )
                
                await MainActor.run {
                    self.preview = nil
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isImporting = false
                }
            }
        }
    }
}

// MARK: - 快速导入按钮组件

struct QuickImportButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - 导入任务行

struct ImportTaskRow: View {
    let task: DreamImportTask
    
    var body: some View {
        HStack {
            Image(systemName: task.sourceType.icon)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text(task.name)
                    .font(.body)
                HStack {
                    Text(task.sourceType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(task.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                statusBadge
                Text("\(task.successCount)/\(task.totalItems)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var statusBadge: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(task.status.rawValue)
                .font(.caption2)
                .foregroundColor(statusColor)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .partial: return .yellow
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

// MARK: - 导入预览表

struct ImportPreviewSheet: View {
    let preview: ImportPreview
    @Binding var settings: ImportSettings
    let onImport: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // 文件信息
                Section {
                    HStack {
                        Image(systemName: preview.sourceType.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(preview.fileName)
                                .font(.body)
                            Text(preview.estimatedSize)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("文件信息")
                }
                
                // 数据统计
                Section {
                    StatRow(label: "梦境数量", value: "\(preview.itemCount)")
                    StatRow(label: "文件格式", value: preview.sourceType.displayName)
                } header: {
                    Text("数据统计")
                }
                
                // 预览样本
                if !preview.sampleItems.isEmpty {
                    Section {
                        ForEach(preview.sampleItems.prefix(3)) { item in
                            SampleItemRow(item: item)
                        }
                    } header: {
                        Text("内容预览")
                    }
                }
                
                // 潜在问题
                if !preview.potentialIssues.isEmpty {
                    Section {
                        ForEach(preview.potentialIssues) { issue in
                            IssueRow(issue: issue)
                        }
                    } header: {
                        Text("注意事项")
                    }
                }
                
                // 导入设置
                Section {
                    Toggle("跳过重复梦境", isOn: $settings.skipDuplicates)
                    Toggle("合并重复梦境", isOn: $settings.mergeDuplicates)
                        .disabled(settings.skipDuplicates)
                    Toggle("导入标签", isOn: $settings.importTags)
                    Toggle("导入情绪", isOn: $settings.importEmotions)
                    Toggle("自动 AI 分析", isOn: $settings.autoAnalyze)
                } header: {
                    Text("导入选项")
                }
            }
            .navigationTitle("导入预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("开始导入") {
                        onImport()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 统计行

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 样本行

struct SampleItemRow: View {
    let item: ImportDreamData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = item.title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Text(item.content.prefix(100) + "...")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(item.date, style: .date)
                    .font(.caption)
                Spacer()
                if let tags = item.tags, !tags.isEmpty {
                    Label("\(tags.count)", systemImage: "tag")
                        .font(.caption2)
                }
            }
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - 问题行

struct IssueRow: View {
    let issue: ImportIssue
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: issue.severityIcon)
                .foregroundColor(issue.severityColor)
                .font(.body)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.message)
                    .font(.subheadline)
                if issue.affectedItems > 0 {
                    Text("影响 \(issue.affectedItems) 项")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private extension ImportIssue {
    var severityIcon: String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
    
    var severityColor: Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - 预览

#Preview {
    DreamImportView()
        .modelContainer(for: [Dream.self, DreamImportTask.self], inMemory: true)
}
