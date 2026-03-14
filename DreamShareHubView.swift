//
//  DreamShareHubView.swift
//  DreamLog - 梦境分享中心主界面
//
//  Created by DreamLog Team on 2026-03-14.
//  Phase 36: Dream Share Hub - 一键多平台分享中心
//

import SwiftUI
import SwiftData

// MARK: - 主界面

struct DreamShareHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \ShareHistory.createdAt, order: .reverse)
    private var shareHistory: [ShareHistory]
    
    @StateObject private var viewModel = ShareHubViewModel()
    @State private var showingConfigSheet = false
    @State private var showingHistorySheet = false
    @State private var selectedDream: Dream?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 统计卡片
                statsSection
                
                Divider()
                
                // 快速分享
                quickShareSection
                
                Divider()
                
                // 分享配置
                configsSection
                
                Divider()
                
                // 分享历史
                historySection
            }
            .navigationTitle("分享中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingConfigSheet = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingConfigSheet) {
                ShareConfigListView()
            }
            .sheet(isPresented: $showingHistorySheet) {
                ShareHistoryDetailView()
            }
            .sheet(item: $selectedDream) { dream in
                ShareDreamSheet(dream: dream)
            }
            .task {
                await viewModel.loadStats()
                await viewModel.detectPlatforms()
            }
        }
    }
    
    // MARK: - 统计卡片
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // 总分享数
                StatCard(
                    title: "总分享",
                    value: "\(viewModel.stats.totalShares)",
                    icon: "paperplane.fill",
                    color: .blue
                )
                
                // 本周分享
                StatCard(
                    title: "本周",
                    value: "\(viewModel.stats.thisWeekShares)",
                    icon: "calendar",
                    color: .green
                )
                
                // 平台数
                StatCard(
                    title: "平台",
                    value: "\(viewModel.stats.totalPlatforms)",
                    icon: "app.badge",
                    color: .purple
                )
            }
            
            // 最常用平台
            if let favoritePlatform = viewModel.stats.favoritePlatform {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("最常用平台：\(platformName(favoritePlatform))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - 快速分享
    
    private var quickShareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速分享")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.installedPlatforms.prefix(6)) { platform in
                        PlatformButton(platform: platform) {
                            // 选择梦境进行分享
                            showingShareSheet = true
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Button {
                showingShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("选择梦境分享")
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 分享配置
    
    private var configsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("分享配置")
                    .font(.headline)
                
                Spacer()
                
                Button("管理") {
                    showingConfigSheet = true
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            if let defaultConfig = viewModel.defaultConfig {
                ConfigCard(config: defaultConfig) {
                    showingShareSheet = true
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 分享历史
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("分享历史")
                    .font(.headline)
                
                Spacer()
                
                Button("查看全部") {
                    showingHistorySheet = true
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            if shareHistory.isEmpty {
                Text("暂无分享记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(shareHistory.prefix(5)) { history in
                    HistoryRow(history: history)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helpers
    
    private func platformName(_ rawValue: String) -> String {
        SharePlatform(rawValue: rawValue)?.displayName ?? rawValue
    }
}

// MARK: - 统计卡片组件

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 平台按钮

struct PlatformButton: View {
    let platform: SharePlatform
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: platform.iconName)
                    .font(.title2)
                    .foregroundColor(platformColor(platform))
                
                Text(platform.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 70)
            .background(platformColor(platform).opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func platformColor(_ platform: SharePlatform) -> Color {
        Color(hex: platform.brandColor) ?? .gray
    }
}

// MARK: - 配置卡片

struct ConfigCard: View {
    let config: ShareConfig
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(config.name)
                        .font(.headline)
                    
                    if config.isDefault {
                        Text("默认")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    ForEach(platformsFromConfig(config).prefix(4)) { platform in
                        Image(systemName: platform.iconName)
                            .font(.caption)
                            .foregroundColor(platformColor(platform))
                    }
                    
                    if platformsFromConfig(config).count > 4 {
                        Text("+\(platformsFromConfig(config).count - 4)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("模板：\(templateName(config.defaultTemplate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func platformsFromConfig(_ config: ShareConfig) -> [SharePlatform] {
        config.selectedPlatforms.compactMap { SharePlatform(rawValue: $0) }
    }
    
    private func templateName(_ rawValue: String) -> String {
        ShareTemplate(rawValue: rawValue)?.displayName ?? rawValue
    }
    
    private func platformColor(_ platform: SharePlatform) -> Color {
        Color(hex: platform.brandColor) ?? .gray
    }
}

// MARK: - 历史行

struct HistoryRow: View {
    let history: ShareHistory
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(history.dreamTitle)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("\(history.platforms.count) 个平台")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(successRate(history))
                        .font(.caption)
                        .foregroundColor(successColor(history))
                }
            }
            
            Spacer()
            
            Text(timeAgo(history.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func successRate(_ history: ShareHistory) -> String {
        let total = history.successCount + history.failCount
        guard total > 0 else { return "0%" }
        let rate = Int(Double(history.successCount) / Double(total) * 100)
        return "\(rate)% 成功"
    }
    
    private func successColor(_ history: ShareHistory) -> Color {
        let rate = Double(history.successCount) / Double(history.successCount + history.failCount)
        if rate >= 0.8 { return .green }
        if rate >= 0.5 { return .yellow }
        return .red
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 分享梦境表单

struct ShareDreamSheet: View {
    let dream: Dream
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ShareHubViewModel()
    
    @State private var selectedPlatforms: Set<SharePlatform> = []
    @State private var selectedTemplate: ShareTemplate = .starry
    @State private var shareMessage: String = ""
    @State private var includeAIAnalysis: Bool = false
    @State private var includeImage: Bool = true
    @State private var isSharing: Bool = false
    @State private var shareResult: BatchShareResult?
    @State private var showingResult = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 平台选择
                Section("选择平台") {
                    ForEach(viewModel.installedPlatforms) { platform in
                        Toggle(
                            isOn: Binding(
                                get: { selectedPlatforms.contains(platform) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedPlatforms.insert(platform)
                                    } else {
                                        selectedPlatforms.remove(platform)
                                    }
                                }
                            )
                        ) {
                            HStack {
                                Image(systemName: platform.iconName)
                                    .foregroundColor(platformColor(platform))
                                    .frame(width: 30)
                                Text(platform.displayName)
                            }
                        }
                    }
                }
                
                // 模板选择
                Section("卡片模板") {
                    Picker("模板", selection: $selectedTemplate) {
                        ForEach(ShareTemplate.allCases) { template in
                            Text(template.displayName).tag(template)
                        }
                    }
                    PickerStyle(.menu)
                    
                    Text(ShareTemplate.allCases.first { $0 == selectedTemplate }?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 自定义消息
                Section("自定义消息") {
                    TextEditor(text: $shareMessage)
                        .frame(height: 80)
                }
                
                // 内容选项
                Section("内容选项") {
                    Toggle("包含 AI 解析", isOn: $includeAIAnalysis)
                    Toggle("包含梦境图片", isOn: $includeImage)
                }
                
                // 分享按钮
                Section {
                    Button {
                        Task {
                            await share()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSharing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("分享中...")
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("分享到 \(selectedPlatforms.count) 个平台")
                            }
                            Spacer()
                        }
                    }
                    .disabled(selectedPlatforms.isEmpty || isSharing)
                }
            }
            .navigationTitle("分享梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("分享完成", isPresented: $showingResult) {
                Button("完成") {
                    dismiss()
                }
            } message: {
                if let result = shareResult {
                    Text("成功：\(result.successCount) / 失败：\(result.failCount)")
                }
            }
        }
    }
    
    private func share() async {
        isSharing = true
        
        let result = await DreamShareHubService.shared.batchShare(
            dreamId: dream.id,
            dreamTitle: dream.title,
            dreamContent: dream.content,
            platforms: Array(selectedPlatforms),
            template: selectedTemplate,
            shareMessage: shareMessage.isEmpty ? nil : shareMessage,
            includeAIAnalysis: includeAIAnalysis,
            includeImage: includeImage
        )
        
        shareResult = result
        isSharing = false
        showingResult = true
    }
    
    private func platformColor(_ platform: SharePlatform) -> Color {
        Color(hex: platform.brandColor) ?? .gray
    }
}

// MARK: - 配置列表

struct ShareConfigListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var configs: [ShareConfig]
    
    @State private var showingNewConfig = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(configs) { config in
                    NavigationLink {
                        ShareConfigEditView(config: config)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(config.name)
                                        .font(.headline)
                                    
                                    if config.isDefault {
                                        Text("默认")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text("\(config.selectedPlatforms.count) 个平台")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteConfigs(at: indexSet)
                }
            }
            .navigationTitle("分享配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewConfig = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewConfig) {
                ShareConfigEditView()
            }
        }
    }
    
    private func deleteConfigs(at indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(configs[index])
        }
    }
}

// MARK: - 配置编辑

struct ShareConfigEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var config: ShareConfig?
    
    @State private var name: String = ""
    @State private var selectedPlatforms: Set<String> = []
    @State private var defaultTemplate: String = "starry"
    @State private var isDefault: Bool = false
    @State private var autoAddHashtags: Bool = true
    @State private var autoAddEmotions: Bool = true
    @State private var includeAIAnalysis: Bool = false
    @State private var includeImage: Bool = true
    
    init(config: ShareConfig? = nil) {
        self.config = config
        
        if let config = config {
            _name = State(initialValue: config.name)
            _selectedPlatforms = State(initialValue: Set(config.selectedPlatforms))
            _defaultTemplate = State(initialValue: config.defaultTemplate)
            _isDefault = State(initialValue: config.isDefault)
            _autoAddHashtags = State(initialValue: config.autoAddHashtags)
            _autoAddEmotions = State(initialValue: config.autoAddEmotions)
            _includeAIAnalysis = State(initialValue: config.includeAIAnalysis)
            _includeImage = State(initialValue: config.includeDreamImage)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("配置名称", text: $name)
                    
                    Toggle("设为默认配置", isOn: $isDefault)
                }
                
                Section("分享平台") {
                    ForEach(SharePlatform.allCases) { platform in
                        Toggle(
                            isOn: Binding(
                                get: { selectedPlatforms.contains(platform.rawValue) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedPlatforms.insert(platform.rawValue)
                                    } else {
                                        selectedPlatforms.remove(platform.rawValue)
                                    }
                                }
                            )
                        ) {
                            HStack {
                                Image(systemName: platform.iconName)
                                    .foregroundColor(platformColor(platform))
                                    .frame(width: 30)
                                Text(platform.displayName)
                            }
                        }
                    }
                }
                
                Section("默认模板") {
                    Picker("模板", selection: $defaultTemplate) {
                        ForEach(ShareTemplate.allCases) { template in
                            Text(template.displayName).tag(template.rawValue)
                        }
                    }
                }
                
                Section("内容选项") {
                    Toggle("自动添加标签", isOn: $autoAddHashtags)
                    Toggle("自动添加情绪", isOn: $autoAddEmotions)
                    Toggle("包含 AI 解析", isOn: $includeAIAnalysis)
                    Toggle("包含梦境图片", isOn: $includeImage)
                }
            }
            .navigationTitle(config == nil ? "新建配置" : "编辑配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(name.isEmpty || selectedPlatforms.isEmpty)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        if let config = config {
            // 更新现有配置
            config.name = name
            config.selectedPlatforms = Array(selectedPlatforms)
            config.defaultTemplate = defaultTemplate
            config.isDefault = isDefault
            config.autoAddHashtags = autoAddHashtags
            config.autoAddEmotions = autoAddEmotions
            config.includeAIAnalysis = includeAIAnalysis
            config.includeDreamImage = includeImage
        } else {
            // 创建新配置
            let newConfig = ShareConfig(
                name: name,
                selectedPlatforms: Array(selectedPlatforms),
                defaultTemplate: defaultTemplate,
                autoAddHashtags: autoAddHashtags,
                autoAddEmotions: autoAddEmotions,
                includeAIAnalysis: includeAIAnalysis,
                includeDreamImage: includeImage,
                isDefault: isDefault
            )
            modelContext.insert(newConfig)
        }
        
        dismiss()
    }
    
    private func platformColor(_ platform: SharePlatform) -> Color {
        Color(hex: platform.brandColor) ?? .gray
    }
}

// MARK: - 历史详情

struct ShareHistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ShareHistory.createdAt, order: .reverse)
    private var history: [ShareHistory]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(history) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.dreamTitle)
                            .font(.headline)
                        
                        HStack {
                            Text("\(item.platforms.count) 个平台")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(item.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("\(item.successCount) 成功", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            if item.failCount > 0 {
                                Label("\(item.failCount) 失败", systemImage: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("分享历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class ShareHubViewModel: ObservableMock {
    @Published var stats: ShareStats = .empty
    @Published var installedPlatforms: [SharePlatform] = []
    @Published var defaultConfig: ShareConfig?
    
    func loadStats() async {
        stats = await DreamShareHubService.shared.getStats()
        
        // 加载默认配置
        if let config = await DreamShareHubService.shared.getDefaultConfig() {
            defaultConfig = config
        }
    }
    
    func detectPlatforms() async {
        installedPlatforms = await DreamShareHubService.shared.detectInstalledPlatforms()
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    DreamShareHubView()
        .modelContainer(for: [ShareConfig.self, ShareHistory.self], inMemory: true)
}
