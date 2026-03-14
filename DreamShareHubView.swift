//
//  DreamShareHubView.swift
//  DreamLog - 梦境分享中心主界面
//
//  Created by DreamLog Team on 2026-03-14.
//  Phase 36: Dream Share Hub - 一键多平台分享中心
//

import SwiftUI
import SwiftData
import UIKit

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
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error: error)
                } else {
                    contentView
                }
            }
            .navigationTitle("分享中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载分享数据...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("正在加载")
        .accessibilityHint("等待分享数据加载完成")
    }
    
    // MARK: - Error View
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    await loadData()
                }
            } label: {
                Label("重试", systemImage: "arrow.clockwise")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .accessibilityHint("点击重新加载数据")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
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
    }
    
    // MARK: - Load Data
    
    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let stats = viewModel.loadStats()
            async let platforms = viewModel.detectPlatforms()
            
            try await Task.sleep(nanoseconds: 300_000_000) // 最小加载时间，避免闪烁
            
            await stats
            await platforms
            
            withAnimation(.easeOut(duration: 0.3)) {
                isLoading = false
            }
        } catch {
            withAnimation(.easeOut(duration: 0.3)) {
                isLoading = false
                errorMessage = "无法加载分享数据：\(error.localizedDescription)"
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
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
                .accessibilityAddTraits(.isHeader)
                
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
                        .accessibilityHidden(true)
                    Text("最常用平台：\(platformName(favoritePlatform))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .accessibilityLabel("最常用的分享平台是 \(platformName(favoritePlatform))")
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
                .accessibilityAddTraits(.isHeader)
            
            if viewModel.installedPlatforms.isEmpty {
                Text("未检测到已安装的分享平台")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .accessibilityLabel("未检测到已安装的分享平台")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.installedPlatforms.prefix(6)) { platform in
                            PlatformButton(platform: platform) {
                                selectedDream = nil
                                showingShareSheet = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedDream = nil
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
            .accessibilityHint("点击选择要分享的梦境")
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
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingConfigSheet = true
                } label: {
                    Text("管理")
                        .font(.subheadline)
                }
                .accessibilityHint("管理分享配置")
            }
            .padding(.horizontal)
            
            if let defaultConfig = viewModel.defaultConfig {
                ConfigCard(config: defaultConfig) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingShareSheet = true
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("暂无分享配置")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("点击右上角齿轮创建默认配置")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .accessibilityLabel("暂无分享配置，请创建默认配置")
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
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingHistorySheet = true
                } label: {
                    Text("查看全部")
                        .font(.subheadline)
                }
                .accessibilityHint("查看完整的分享历史记录")
            }
            .padding(.horizontal)
            
            if shareHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("暂无分享记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("选择一个梦境开始分享吧")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .accessibilityLabel("暂无分享记录")
            } else {
                ForEach(shareHistory.prefix(5)) { history in
                    HistoryRow(history: history)
                        .padding(.horizontal)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
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
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .scaleEffect(isHovering ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.numericText())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.1), color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(isHovering ? 0.3 : 0.1), lineWidth: 1)
                )
                .shadow(color: color.opacity(isHovering ? 0.2 : 0.1), radius: isHovering ? 8 : 4, x: 0, y: 4)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint("")
    }
}

// MARK: - 平台按钮

struct PlatformButton: View {
    let platform: SharePlatform
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: platform.iconName)
                    .font(.title2)
                    .foregroundColor(platformColor(platform))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                
                Text(platform.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(platformColor(platform).opacity(isPressed ? 0.15 : 0.1))
                    .shadow(color: platformColor(platform).opacity(0.2), radius: isPressed ? 2 : 4, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("分享到 \(platform.displayName)")
        .accessibilityHint("点击选择此平台进行分享")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func platformColor(_ platform: SharePlatform) -> Color {
        Color(hex: platform.brandColor) ?? .gray
    }
}

// MARK: - 配置卡片

struct ConfigCard: View {
    let config: ShareConfig
    let action: () -> Void
    
    @State private var isPressed = false
    
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(isPressed ? 0.4 : 0.2), lineWidth: 1)
                    )
                    .shadow(color: .accentColor.opacity(isPressed ? 0.1 : 0.05), radius: isPressed ? 4 : 8, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("使用配置 \(config.name) 进行分享")
        .accessibilityHint("包含 \(platformsFromConfig(config).count) 个平台，点击开始分享")
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
    
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(history.dreamTitle)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(history.platforms.count) 个平台", systemImage: "app.badge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text(successRate(history))
                        .font(.caption)
                        .foregroundColor(successColor(history))
                }
            }
            
            Spacer()
            
            Text(timeAgo(history.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHovering ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .accessibilityLabel("分享到 \(history.platforms.count) 个平台，\(successRate(history))，\(timeAgo(history.createdAt))")
        .accessibilityHint("点击查看分享详情")
    }
    
    private func successRate(_ history: ShareHistory) -> String {
        let rate = history.platforms.filter { $0.isSuccess }.count
        return "\(rate)/\(history.platforms.count) 成功"
    }
    
    private func successColor(_ history: ShareHistory) -> Color {
        let successCount = history.platforms.filter { $0.isSuccess }.count
        if successCount == history.platforms.count {
            return .green
        } else if successCount > 0 {
            return .orange
        } else {
            return .red
        }
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
class ShareHubViewModel: ObservableObject {
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
