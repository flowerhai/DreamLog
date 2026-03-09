//
//  DreamJournalExportView.swift
//  DreamLog
//
//  梦境日记 PDF 导出界面
//

import SwiftUI
import UniformTypeIdentifiers

/// PDF 导出配置视图
struct DreamJournalExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    
    @State private var config = PDFExportConfig.default
    @State private var isGenerating = false
    @State private var showSuccess = false
    @State private var exportedFileURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 日期范围选择
    @State private var selectedDateRange: DateRangeOption = .all
    @State private var customStartDate = Date().addingTimeInterval(-86400 * 30)
    @State private var customEndDate = Date()
    
    enum DateRangeOption: String, CaseIterable, Identifiable {
        case all = "全部"
        case thisWeek = "本周"
        case thisMonth = "本月"
        case thisYear = "今年"
        case custom = "自定义"
        
        var id: String { rawValue }
        
        var dateRange: PDFExportConfig.DateRange {
            switch self {
            case .all: return .all
            case .thisWeek: return .thisWeek
            case .thisMonth: return .thisMonth
            case .thisYear: return .thisYear
            case .custom: return PDFExportConfig.DateRange(startDate: customStartDate, endDate: customEndDate)
            }
        }
    }
    
    var filteredDreamsCount: Int {
        let dreams = dreamStore.dreams.filter { dream in
            let range = selectedDateRange.dateRange
            return dream.date >= range.startDate && dream.date <= range.endDate
        }
        return dreams.count
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 导出风格
                Section("📐 导出风格") {
                    Picker("风格", selection: $config.style) {
                        ForEach(PDFExportStyle.allCases) { style in
                            Label {
                                Text(style.rawValue)
                            } icon: {
                                Image(systemName: style.iconName)
                            }
                            .tag(style)
                        }
                    }
                    
                    Text(config.style.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("语言", selection: $config.language) {
                        ForEach(PDFExportLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    
                    Picker("页面尺寸", selection: $config.pageSize) {
                        ForEach(PDFPageSize.allCases) { size in
                            VStack(alignment: .leading) {
                                Text(size.rawValue)
                                Text(size.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tag(size)
                        }
                    }
                }
                
                // 日期范围
                Section("📅 日期范围") {
                    Picker("范围", selection: $selectedDateRange) {
                        ForEach(DateRangeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedDateRange == .custom {
                        DatePicker("开始日期", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("结束日期", selection: $customEndDate, displayedComponents: .date)
                    }
                    
                    HStack {
                        Text("将导出 \(filteredDreamsCount) 个梦境")
                        Spacer()
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                    }
                    .font(.caption)
                }
                
                // 内容选项
                Section("📝 内容选项") {
                    Toggle("封面页", isOn: $config.includeCoverPage)
                    Toggle("目录页", isOn: $config.includeTableOfContents)
                    Toggle("统计页面", isOn: $config.includeStatistics)
                    Toggle("AI 图片", isOn: $config.includeAIImages)
                    Toggle("标签", isOn: $config.includeTags)
                    Toggle("情绪", isOn: $config.includeEmotions)
                }
                
                // 排序选项
                Section("🔀 排序方式") {
                    Picker("排序", selection: $config.sortBy) {
                        ForEach(PDFExportConfig.SortOption.allCases, id: \.rawValue) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
                
                // 自定义标题
                Section("✏️ 自定义") {
                    TextField("日记标题", text: $config.customTitle)
                    TextField("副标题", text: $config.customSubtitle)
                }
                
                // 批量导出
                Section("📦 批量导出") {
                    Button(action: batchExportByPeriod) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("按时间段批量导出")
                        }
                    }
                    .disabled(isGenerating || dreamStore.dreams.isEmpty)
                    
                    Button(action: exportMultiLanguage) {
                        HStack {
                            Image(systemName: "globe")
                            Text("导出多语言版本")
                        }
                    }
                    .disabled(isGenerating || dreamStore.dreams.isEmpty)
                    
                    Button(action: exportAllStyles) {
                        HStack {
                            Image(systemName: "paintpalette")
                            Text("导出所有风格")
                        }
                    }
                    .disabled(isGenerating || dreamStore.dreams.isEmpty)
                }
                
                // 导出按钮
                Section {
                    Button(action: generatePDF) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text("生成中...")
                            } else {
                                Image(systemName: "doc.badge.plus.fill")
                                    .font(.title2)
                                Text("生成 PDF 日记")
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(isGenerating || filteredDreamsCount == 0)
                }
                
                // 预览
                Section("👁️ 预览") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("导出配置预览")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("风格", systemImage: config.style.iconName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(config.style.rawValue)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Label("尺寸", systemImage: "rectangle.dashed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(config.pageSize.rawValue)
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("梦境数", systemImage: "moon.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(filteredDreamsCount) 个")
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Label("排序", systemImage: "arrow.up.arrow.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(config.sortBy.rawValue.components(separatedBy: " ").first ?? "")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("导出 PDF 日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("分享") {
                        sharePDF()
                    }
                    .disabled(exportedFileURL == nil)
                }
            }
            .alert("导出成功", isPresented: $showSuccess) {
                Button("完成") {
                    dismiss()
                }
                Button("分享") {
                    sharePDF()
                }
            } message: {
                Text("PDF 日记已生成，包含 \(filteredDreamsCount) 个梦境记录。")
            }
            .alert("导出失败", isPresented: $showError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func generatePDF() {
        isGenerating = true
        
        // 更新配置
        config.dateRange = selectedDateRange.dateRange
        
        Task {
            do {
                let dreams = dreamStore.dreams
                let service = DreamJournalExportService.shared
                service.updateConfig(config)
                
                let pdfData = try await service.generatePDF(dreams: dreams)
                
                // 保存 PDF 到临时目录
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "\(config.customTitle)_\(Date().formatted(.dateTime.year().month().day())).pdf"
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                try pdfData.write(to: fileURL)
                exportedFileURL = fileURL
                
                await MainActor.run {
                    isGenerating = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func batchExportByPeriod() {
        isGenerating = true
        
        Task {
            do {
                let dreams = dreamStore.dreams
                let service = DreamJournalExportService.shared
                let batchConfig = DreamJournalExportService.BatchExportConfig.default
                
                let exportedFiles = try await service.batchExport(dreams: dreams, batchConfig: batchConfig)
                
                await MainActor.run {
                    isGenerating = false
                    if exportedFiles.isEmpty {
                        errorMessage = "没有梦境可导出"
                        showError = true
                    } else {
                        errorMessage = "成功导出 \(exportedFiles.count) 个 PDF 文件到 Documents/DreamLogExports"
                        showError = true // 复用错误弹窗显示成功消息
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func exportMultiLanguage() {
        isGenerating = true
        
        Task {
            do {
                let dreams = dreamStore.dreams
                let service = DreamJournalExportService.shared
                
                let exportedFiles = try await service.exportMultiLanguage(dreams: dreams)
                
                await MainActor.run {
                    isGenerating = false
                    if exportedFiles.isEmpty {
                        errorMessage = "没有梦境可导出"
                        showError = true
                    } else {
                        errorMessage = "成功导出 \(exportedFiles.count) 种语言版本到 Documents/DreamLogExports/MultiLanguage"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func exportAllStyles() {
        isGenerating = true
        
        Task {
            do {
                let dreams = dreamStore.dreams
                let service = DreamJournalExportService.shared
                
                let exportedFiles = try await service.exportAllStyles(dreams: dreams)
                
                await MainActor.run {
                    isGenerating = false
                    if exportedFiles.isEmpty {
                        errorMessage = "没有梦境可导出"
                        showError = true
                    } else {
                        errorMessage = "成功导出 \(exportedFiles.count) 种风格版本到 Documents/DreamLogExports/AllStyles"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func sharePDF() {
        guard let fileURL = exportedFileURL else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - 预览

struct DreamJournalExportView_Previews: PreviewProvider {
    static var previews: some View {
        DreamJournalExportView()
            .environmentObject(DreamStore.shared)
    }
}
