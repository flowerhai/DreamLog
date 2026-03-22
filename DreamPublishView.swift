//
//  DreamPublishView.swift
//  DreamLog
//
//  Phase 47: Dream Newsletter & Auto-Publishing
//  梦境发布 UI 界面
//

import SwiftUI
import SwiftData

// MARK: - 主界面

struct DreamPublishView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PublishTemplate.name) private var templates: [PublishTemplate]
    @Query(sort: \PublishTask.createdAt, order: .reverse) private var tasks: [PublishTask]
    
    @State private var selectedTab = 0
    @State private var showingNewTask = false
    @State private var selectedDream: Dream?
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // 发布任务标签
                TasksTabView(
                    tasks: tasks,
                    showingNewTask: $showingNewTask,
                    selectedDream: $selectedDream
                )
                .tabItem {
                    Label("发布任务", systemImage: "paperplane")
                }
                .tag(0)
                
                // 模板管理标签
                TemplatesTabView(templates: templates)
                    .tabItem {
                        Label("发布模板", systemImage: "doc.text")
                    }
                    .tag(1)
                
                // 平台设置标签
                PlatformsTabView()
                    .tabItem {
                        Label("平台设置", systemImage: "gearshape")
                    }
                    .tag(2)
                
                // 统计标签
                StatsTabView()
                    .tabItem {
                        Label("统计", systemImage: "chart.bar")
                    }
                    .tag(3)
            }
            .navigationTitle("梦境发布")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTask) {
                if let dream = selectedDream {
                    NewPublishTaskView(dream: dream, isPresented: $showingNewTask)
                } else {
                    NewPublishTaskView(isPresented: $showingNewTask)
                }
            }
        }
    }
}

// MARK: - 任务列表标签页

struct TasksTabView: View {
    let tasks: [PublishTask]
    @Binding var showingNewTask: Bool
    @Binding var selectedDream: Dream?
    
    @State private var filterStatus: PublishTaskStatus?
    
    var filteredTasks: [PublishTask] {
        if let status = filterStatus {
            return tasks.filter { $0.taskStatus == status }
        }
        return tasks
    }
    
    var body: some View {
        Group {
            if filteredTasks.isEmpty {
                PublishEmptyStateView()
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Picker("筛选", selection: $filterStatus) {
                    Text("全部").tag(nil as PublishTaskStatus?)
                    Text("待发布").tag(PublishTaskStatus.pending)
                    Text("发布中").tag(PublishTaskStatus.processing)
                    Text("已成功").tag(PublishTaskStatus.success)
                    Text("已失败").tag(PublishTaskStatus.failed)
                    Text("已计划").tag(PublishTaskStatus.scheduled)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        // 删除逻辑
    }
}

// MARK: - 任务行视图

struct TaskRowView: View {
    let task: PublishTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                StatusBadge(status: task.taskStatus)
            }
            
            HStack {
                Text(task.platform)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let scheduledAt = task.scheduledAt {
                    Text("计划：\(formatDate(scheduledAt))")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if let publishedAt = task.publishedAt {
                    Text("发布：\(formatDate(publishedAt))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let error = task.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let url = task.publishedURL, let destinationURL = URL(string: url) {
                Link("查看发布", destination: destinationURL)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 状态徽章

struct StatusBadge: View {
    let status: PublishTaskStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(8)
    }
}

extension PublishTaskStatus {
    var displayName: String {
        switch self {
        case .pending: return "待发布"
        case .processing: return "发布中"
        case .success: return "成功"
        case .failed: return "失败"
        case .scheduled: return "已计划"
        case .cancelled: return "已取消"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .processing: return .blue
        case .success: return .green
        case .failed: return .red
        case .scheduled: return .purple
        case .cancelled: return .gray
        }
    }
}

// MARK: - 模板管理标签页

struct TemplatesTabView: View {
    let templates: [PublishTemplate]
    
    @State private var showingNewTemplate = false
    @State private var editingTemplate: PublishTemplate?
    
    var body: some View {
        Group {
            if templates.isEmpty {
                EmptyStateView(
                    title: "暂无模板",
                    message: "点击 + 创建第一个发布模板",
                    icon: "doc.text"
                )
            } else {
                List {
                    ForEach(templates) { template in
                        TemplateRowView(template: template)
                            .onTapGesture {
                                editingTemplate = template
                            }
                    }
                }
            }
        }
        .navigationTitle("发布模板")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewTemplate = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewTemplate) {
            EditTemplateView(template: nil, isPresented: $showingNewTemplate)
        }
        .sheet(item: $editingTemplate) { template in
            EditTemplateView(template: template, isPresented: Binding(
                get: { editingTemplate != nil },
                set: { if !$0 { editingTemplate = nil } }
            ))
        }
    }
}

// MARK: - 模板行视图

struct TemplateRowView: View {
    let template: PublishTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(template.name)
                    .font(.headline)
                
                Spacer()
                
                if template.isDefault {
                    Text("默认")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Text(PublishPlatform(rawValue: template.platform)?.displayName ?? template.platform)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("包含：\(contentDescription(template))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func contentDescription(_ template: PublishTemplate) -> String {
        var items: [String] = []
        if template.includeTags { items.append("标签") }
        if template.includeEmotions { items.append("情绪") }
        if template.includeAIAnalysis { items.append("AI 解析") }
        if template.includeImages { items.append("图片") }
        return items.joined(separator: "、")
    }
}

// MARK: - 平台设置标签页

struct PlatformsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var configs: [PublishConfig]
    
    @State private var showingAddPlatform = false
    
    var body: some View {
        List {
            Section("已配置平台") {
                ForEach(PublishPlatform.allCases) { platform in
                    if let config = configs.first(where: { $0.platform == platform.rawValue }) {
                        PlatformConfigRow(platform: platform, config: config)
                    } else if platform.requiresAPIKey || platform.supportsAutoPublish {
                        PlatformConfigRow(platform: platform, config: nil)
                    }
                }
            }
            
            Section("发布说明") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• 支持自动发布的平台：Medium、WordPress、Ghost、Twitter")
                        .font(.caption)
                    Text("• 需要手动发布的平台：微信公众号、小红书（生成内容后复制粘贴）")
                        .font(.caption)
                    Text("• API Key 可在各平台的开发者设置中获取")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("平台设置")
        .sheet(isPresented: $showingAddPlatform) {
            AddPlatformView()
        }
    }
}

// MARK: - 平台配置行

struct PlatformConfigRow: View {
    let platform: PublishPlatform
    let config: PublishConfig?
    
    var body: some View {
        HStack {
            Image(systemName: platform.icon)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(platform.displayName)
                    .font(.headline)
                
                if let config = config {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("已配置")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(platform.requiresAPIKey ? "需要 API Key" : "手动发布")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            NavigationLink {
                PlatformConfigDetailView(platform: platform, config: config)
            } label: {
                Text(config == nil ? "配置" : "编辑")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 平台配置详情

struct PlatformConfigDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let platform: PublishPlatform
    let config: PublishConfig?
    
    @State private var apiKey: String
    @State private var endpoint: String
    @State private var blogId: String
    @State private var autoPublish: Bool
    
    init(platform: PublishPlatform, config: PublishConfig?) {
        self.platform = platform
        self.config = config
        _apiKey = State(initialValue: config?.apiKey ?? "")
        _endpoint = State(initialValue: config?.endpoint ?? "")
        _blogId = State(initialValue: config?.blogId ?? "")
        _autoPublish = State(initialValue: config?.autoPublish ?? false)
    }
    
    var body: some View {
        Form {
            Section("API 配置") {
                if platform.requiresAPIKey {
                    SecureField("API Key", text: $apiKey)
                        .autocapitalization(.none)
                    
                    if platform == .wordpress || platform == .ghost {
                        TextField("API Endpoint (可选)", text: $endpoint)
                            .autocapitalization(.none)
                    }
                    
                    TextField("Blog ID (可选)", text: $blogId)
                        .autocapitalization(.none)
                } else {
                    Text("此平台支持手动发布，无需 API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("发布设置") {
                Toggle("自动发布", isOn: $autoPublish)
                
                if platform == .twitter {
                    Text("Twitter 发布将作为线程发送长内容")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: save) {
                    Text("保存配置")
                }
                .disabled(platform.requiresAPIKey && apiKey.isEmpty)
                
                if config != nil {
                    Button(role: .destructive) {
                        delete()
                    } label: {
                        Text("删除配置")
                    }
                }
            }
        }
        .navigationTitle(platform.displayName)
    }
    
    private func save() {
        if let existingConfig = config {
            existingConfig.apiKey = apiKey
            existingConfig.endpoint = endpoint
            existingConfig.blogId = blogId
            existingConfig.autoPublish = autoPublish
        } else {
            let newConfig = PublishConfig(
                platform: platform.rawValue,
                apiKey: apiKey.isEmpty ? nil : apiKey,
                endpoint: endpoint.isEmpty ? nil : endpoint,
                blogId: blogId.isEmpty ? nil : blogId,
                autoPublish: autoPublish
            )
            modelContext.insert(newConfig)
        }
        
        try? modelContext.save()
    }
    
    private func delete() {
        if let config = config {
            modelContext.delete(config)
            try? modelContext.save()
        }
    }
}

// MARK: - 统计标签页

struct PublishStatsTabView: View {
    @EnvironmentObject var publishService: DreamPublishService
    
    @State private var stats: PublishStats = .empty
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载统计...")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 总览卡片
                        OverviewCard(stats: stats)
                        
                        // 平台分布
                        PlatformBreakdownCard(stats: stats)
                        
                        // 互动统计
                        EngagementCard(stats: stats)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("发布统计")
        .onAppear {
            Task {
                stats = await publishService.getStats()
                isLoading = false
            }
        }
    }
}

// MARK: - 统计卡片

struct OverviewCard: View {
    let stats: PublishStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("总览")
                .font(.headline)
            
            HStack(spacing: 20) {
                PublishStatItem(title: "已发布", value: "\(stats.totalPublished)", icon: "checkmark.circle")
                PublishStatItem(title: "总浏览", value: formatNumber(stats.totalViews), icon: "eye")
                PublishStatItem(title: "总点赞", value: formatNumber(stats.totalLikes), icon: "heart")
            }
            
            if let popular = stats.mostPopularPlatform {
                Text("最常用平台：\(popular)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

struct PublishStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PlatformBreakdownCard: View {
    let stats: PublishStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("平台分布")
                .font(.headline)
            
            ForEach(stats.byPlatform.sorted(by: { $0.value > $1.value }), id: \.key) { platform, count in
                HStack {
                    Text(platform)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            if stats.byPlatform.isEmpty {
                Text("暂无发布数据")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
}

struct EngagementCard: View {
    let stats: PublishStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("互动统计")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总分享")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.totalShares)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均互动率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", stats.averageEngagement * 100))
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
}

// MARK: - 空状态视图

struct PublishEmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    init(title: String = "暂无内容", message: String = "点击 + 添加新内容", icon: "plus.circle") {
        self.title = title
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DreamPublishView()
        .environmentObject(DreamPublishService(modelContext: {
            do {
                let container = try ModelContainer(for: Dream.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                return ModelContext(container)
            } catch {
                fatalError("Preview setup failed: \(error)")
            }
        }()))
}
