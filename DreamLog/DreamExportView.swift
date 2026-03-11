//
//  DreamExportView.swift
//  DreamLog
//
//  Phase 19 - Dream Data Export & Integration
//  User interface for exporting dreams
//

import SwiftUI
import UniformTypeIdentifiers

struct DreamExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exportService = DreamExportService.shared
    
    @State private var selectedFormat: ExportFormat = .json
    @State private var dateRange: ExportDateRange = .all
    @State private var includeFields: ExportFields = .all
    @State private var sortOrder: ExportSortOrder = .dateDescending
    
    @State private var isExporting = false
    @State private var exportResult: ExportResult?
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    
    @State private var customStartDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    @State private var customEndDate = Date()
    
    // Integration states
    @State private var selectedTab = 0
    @StateObject private var notionService = NotionIntegrationService.shared
    @StateObject private var obsidianService = ObsidianIntegrationService.shared
    
    @State private var notionApiKey = ""
    @State private var notionDatabaseId = ""
    @State private var notionTestResult: Bool?
    @State private var isNotionTesting = false
    
    @State private var obsidianVaultPath = ""
    @State private var obsidianFolderName = "Dreams"
    @State private var obsidianExportResult: ObsidianSyncResult?
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Export Tab
                exportTab
                    .tabItem {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }
                    .tag(0)
                
                // Notion Integration Tab
                notionTab
                    .tabItem {
                        Label("Notion", systemImage: "network")
                    }
                    .tag(1)
                
                // Obsidian Integration Tab
                obsidianTab
                    .tabItem {
                        Label("Obsidian", systemImage: "folder")
                    }
                    .tag(2)
            }
            .navigationTitle("数据导出")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .alert("导出完成", isPresented: .constant(exportResult?.success == true)) {
            Button("分享") {
                if let url = exportResult?.fileURL {
                    shareURL = url
                    showShareSheet = true
                }
            }
            Button("好的", role: .cancel) {
                exportResult = nil
            }
        } message: {
            if let result = exportResult {
                Text("成功导出 \(result.dreamCount) 个梦境\n文件大小：\(result.fileSize)")
            }
        }
    }
    
    // MARK: - Export Tab
    
    private var exportTab: some View {
        Form {
            // Format Selection
            Section("导出格式") {
                Picker("格式", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Label(format.displayName, systemImage: format.icon)
                            .tag(format)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Date Range
            Section("日期范围") {
                Picker("范围", selection: $dateRange) {
                    ForEach(ExportDateRange.allCases) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                
                if dateRange == .custom {
                    DatePicker("开始日期", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $customEndDate, displayedComponents: .date)
                }
            }
            
            // Sort Order
            Section("排序方式") {
                Picker("排序", selection: $sortOrder) {
                    ForEach(ExportSortOrder.allCases) { order in
                        Text(order.displayName).tag(order)
                    }
                }
            }
            
            // Include Fields
            Section("包含内容") {
                Toggle("标题", isOn: binding(for: .title))
                Toggle("内容", isOn: binding(for: .content))
                Toggle("标签", isOn: binding(for: .tags))
                Toggle("情绪", isOn: binding(for: .emotions))
                Toggle("清晰度", isOn: binding(for: .clarity))
                Toggle("强度", isOn: binding(for: .intensity))
                Toggle("清醒梦", isOn: binding(for: .isLucid))
                Toggle("AI 解析", isOn: binding(for: .aiAnalysis))
                Toggle("日期", isOn: binding(for: .date))
            }
            
            // Export Button
            Section {
                Button(action: performExport) {
                    HStack {
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("导出中...")
                        } else {
                            Label("开始导出", systemImage: "square.and.arrow.up")
                        }
                        Spacer()
                    }
                }
                .disabled(isExporting)
            }
        }
    }
    
    // MARK: - Notion Tab
    
    private var notionTab: some View {
        Form {
            Section("Notion 配置") {
                SecureField("API Key", text: $notionApiKey)
                    .textContentType(.password)
                
                TextField("Database ID", text: $notionDatabaseId)
                
                HStack {
                    Button(action: testNotionConnection) {
                        if isNotionTesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("测试中...")
                        } else {
                            Label("测试连接", systemImage: "checkmark.circle")
                        }
                    }
                    .disabled(isNotionTesting || notionApiKey.isEmpty || notionDatabaseId.isEmpty)
                    
                    Spacer()
                    
                    if let result = notionTestResult {
                        Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result ? .green : .red)
                    }
                }
            }
            
            Section("说明") {
                Text("1. 在 Notion 中创建一个数据库")
                Text("2. 添加必要的属性：Name, Date, Content, Tags, Clarity, Intensity, Lucid Dream")
                Text("3. 从数据库 URL 获取 Database ID")
                Text("4. 在 Notion 设置中创建 API Key")
            }
            
            Section {
                Button(action: syncToNotion) {
                    HStack {
                        Spacer()
                        Label("同步到 Notion", systemImage: "arrow.up.circle")
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            notionApiKey = notionService.config.apiKey
            notionDatabaseId = notionService.config.databaseId
        }
    }
    
    // MARK: - Obsidian Tab
    
    private var obsidianTab: some View {
        Form {
            Section("Obsidian 配置") {
                TextField("Vault 路径", text: $obsidianVaultPath)
                    .textContentType(.fullStreetAddress)
                
                TextField("文件夹名称", text: $obsidianFolderName)
            }
            
            Section("说明") {
                Text("1. 输入你的 Obsidian Vault 路径")
                Text("2. 梦境将导出到指定的文件夹")
                Text("3. 支持 Markdown 格式和 Frontmatter")
                Text("4. 自动创建双向链接标签")
            }
            
            if let result = obsidianExportResult {
                Section("导出结果") {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        Text(result.success ? "导出成功" : "导出失败")
                    }
                    Text("导出数量：\(result.exportedCount)")
                    if let path = result.outputPath {
                        Text("路径：\(path)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: exportToObsidian) {
                    HStack {
                        Spacer()
                        Label("导出到 Obsidian", systemImage: "folder.badge.plus")
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            obsidianVaultPath = obsidianService.config.vaultPath
            obsidianFolderName = obsidianService.config.folderName
        }
    }
    
    // MARK: - Actions
    
    private func binding(for field: ExportFields) -> Binding<Bool> {
        Binding(
            get: { includeFields.contains(field) },
            set: { newValue in
                if newValue {
                    includeFields.insert(field)
                } else {
                    includeFields.remove(field)
                }
            }
        )
    }
    
    private func performExport() {
        isExporting = true
        
        let options = ExportOptions(
            format: selectedFormat,
            dateRange: dateRange,
            includeFields: includeFields,
            sortOrder: sortOrder
        )
        
        let customRange = dateRange == .custom ? (customStartDate, customEndDate) : nil
        
        Task {
            let result = await exportService.exportDreams(options: options, customDateRange: customRange)
            
            await MainActor.run {
                isExporting = false
                exportResult = result
                
                if !result.success, let error = result.errorMessage {
                    // Show error alert
                }
            }
        }
    }
    
    private func testNotionConnection() {
        isNotionTesting = true
        
        Task {
            notionService.updateConfig(
                apiKey: notionApiKey,
                databaseId: notionDatabaseId,
                isEnabled: true
            )
            
            let result = await notionService.testConnection()
            
            await MainActor.run {
                isNotionTesting = false
                notionTestResult = result
            }
        }
    }
    
    private func syncToNotion() {
        Task {
            // Fetch recent dreams
            // In a real implementation, this would fetch from SwiftData
            let dreams: [Dream] = [] // Placeholder
            
            let result = await notionService.syncDreams(dreams)
            
            await MainActor.run {
                if result.success {
                    // Show success message
                } else {
                    // Show error message
                }
            }
        }
    }
    
    private func exportToObsidian() {
        Task {
            obsidianService.updateConfig(
                vaultPath: obsidianVaultPath,
                folderName: obsidianFolderName,
                templateFile: nil,
                isEnabled: true
            )
            
            // In a real implementation, fetch dreams from SwiftData
            let dreams: [Dream] = [] // Placeholder
            
            let result = await obsidianService.exportToObsidian(dreams: dreams)
            
            await MainActor.run {
                obsidianExportResult = result
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DreamExportView()
}
