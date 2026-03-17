//
//  DreamReflectionView.swift
//  DreamLog
//
//  梦境反思日记 - UI 界面
//  Phase 49: 梦境反思与洞察整合
//

import SwiftUI
import SwiftData

// MARK: - 主界面

struct DreamReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamReflectionService?
    @State private var reflections: [DreamReflection] = []
    @State private var stats: ReflectionStats?
    @State private var showingCreateSheet = false
    @State private var selectedType: ReflectionType?
    @State private var searchQuery = ""
    @State private var selectedReflection: DreamReflection?
    
    var body: some View {
        NavigationStack {
            Group {
                if let stats = stats {
                    reflectionList(stats: stats)
                } else {
                    loadingView
                }
            }
            .navigationTitle("📔 梦境反思")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !searchQuery.isEmpty {
                        Button("取消") {
                            searchQuery = ""
                        }
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "搜索反思内容...")
            .sheet(isPresented: $showingCreateSheet) {
                CreateReflectionView(service: service)
            }
            .sheet(item: $selectedReflection) { reflection in
                ReflectionDetailView(reflection: reflection, service: service)
            }
            .task {
                await loadReflections()
            }
            .refreshable {
                await loadReflections()
            }
        }
    }
    
    // MARK: - Reflection List
    
    @ViewBuilder
    private func reflectionList(stats: ReflectionStats) -> some View {
        if reflections.isEmpty && searchQuery.isEmpty {
            emptyState(stats: stats)
        } else {
            LazyVStack(spacing: 12) {
                // 统计概览
                if searchQuery.isEmpty {
                    statsOverview(stats: stats)
                }
                
                // 反思列表
                if reflections.isEmpty {
                    noResultsView
                } else {
                    ForEach(reflections, id: \.id) { reflection in
                        ReflectionCard(
                            reflection: reflection,
                            onTap: { selectedReflection = reflection }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Stats Overview
    
    private func statsOverview(stats: ReflectionStats) -> some View {
        VStack(spacing: 16) {
            // 总览卡片
            HStack(spacing: 12) {
                StatCard(
                    title: "总反思",
                    value: "\(stats.totalReflections)",
                    icon: "📝",
                    color: .blue
                )
                
                StatCard(
                    title: "本周",
                    value: "\(stats.reflectionsThisWeek)",
                    icon: "📅",
                    color: .green
                )
                
                StatCard(
                    title: "连续天数",
                    value: "\(stats.reflectionStreak)",
                    icon: "🔥",
                    color: .orange
                )
            }
            
            // 按类型分布
            typeDistribution(stats: stats)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func typeDistribution(stats: ReflectionStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("反思类型分布")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(ReflectionType.allCases) { type in
                if let count = stats.byType[type], count > 0 {
                    HStack {
                        Text(type.icon)
                        Text(type.displayName.replacingOccurrences(of: "💡 ", with: "")
                            .replacingOccurrences(of: "🔗 ", with: "")
                            .replacingOccurrences(of: "💭 ", with: "")
                            .replacingOccurrences(of: "❓ ", with: "")
                            .replacingOccurrences(of: "🎯 ", with: "")
                            .replacingOccurrences(of: "🙏 ", with: ""))
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Empty States
    
    @ViewBuilder
    private func emptyState(stats: ReflectionStats) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("开始你的反思之旅")
                    .font(.title2.bold())
                
                Text("记录梦境带来的洞察和启示")
                    .foregroundColor(.secondary)
            }
            
            Button {
                showingCreateSheet = true
            } label: {
                Label("创建第一条反思", systemImage: "plus.circle")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // 预设提示
            presetPrompts
        }
        .padding(40)
    }
    
    private func presetPrompts -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 反思提示")
                .font(.headline)
            
            ForEach(ReflectionPrompt.defaultPrompts.prefix(3)) { prompt in
                PromptCard(prompt: prompt) {
                    showingCreateSheet = true
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func noResultsView -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("未找到相关反思")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }
    
    private func loadingView -> some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载中...")
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // MARK: - Load Data
    
    private func loadReflections() async {
        let reflectionService = DreamReflectionService(modelContext: modelContext)
        service = reflectionService
        
        reflectionService.onReflectionsChanged = {
            Task { @MainActor in
                await loadReflections()
            }
        }
        
        do {
            if !searchQuery.isEmpty {
                reflections = try await reflectionService.searchReflections(query: searchQuery)
            } else {
                reflections = try await reflectionService.fetchAllReflections(limit: 50)
            }
            stats = try await reflectionService.getReflectionStats()
        } catch {
            print("加载反思失败：\(error)")
        }
    }
}

// MARK: - Reflection Card

struct ReflectionCard: View {
    let reflection: DreamReflection
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text(reflection.reflectionType.icon)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(reflection.reflectionType.displayName)
                            .font(.subheadline.bold())
                        
                        if let dream = reflection.dream {
                            Text(dream.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(reflection.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Content preview
                Text(reflection.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.primary)
                
                // Tags
                if !reflection.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(reflection.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                // Footer
                HStack {
                    // Rating
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= reflection.rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(star <= reflection.rating ? .yellow : .gray.opacity(0.3))
                        }
                    }
                    
                    Spacer()
                    
                    // Action items indicator
                    if reflection.hasActionItems {
                        Label("\(reflection.actionItems.count)", systemImage: "checklist")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    // Private indicator
                    if reflection.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
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

// MARK: - Prompt Card

struct PromptCard: View {
    let prompt: ReflectionPrompt
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(prompt.question)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(prompt.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Create Reflection View

struct CreateReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDream: Dream?
    @State private var selectedType: ReflectionType = .insight
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var rating = 4
    @State private var isPrivate = false
    @State private var relatedLifeEvents: [String] = []
    @State private var actionItems: [String] = []
    @State private var showingDreamPicker = false
    @State private var newTag = ""
    @State private var newLifeEvent = ""
    @State private var newActionItem = ""
    
    var service: DreamReflectionService?
    
    var body: some View {
        NavigationStack {
            Form {
                // 梦境选择
                Section {
                    Button {
                        showingDreamPicker = true
                    } label: {
                        HStack {
                            if let dream = selectedDream {
                                Text(dream.title)
                                    .foregroundColor(.primary)
                            } else {
                                Text("选择梦境")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("关联梦境")
                }
                
                // 反思类型
                Section {
                    Picker("类型", selection: $selectedType) {
                        ForEach(ReflectionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 反思内容
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                    
                    if let prompt = suggestedPrompt {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("💡 提示：\(prompt.question)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("反思内容")
                } footer: {
                    Text("记录你的洞察、感受或想法")
                }
                
                // 标签
                Section {
                    if tags.isEmpty {
                        Text("暂无标签")
                            .foregroundColor(.secondary)
                    } else {
                        FlowLayout {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                        .font(.caption)
                                    
                                    Button {
                                        tags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("添加标签", text: $newTag)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            if !newTag.isEmpty {
                                tags.append(newTag)
                                newTag = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("标签")
                }
                
                // 重要性评分
                Section {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                rating = star
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                            }
                        }
                        Spacer()
                        Text(ratingDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("重要性")
                }
                
                // 关联事件
                Section {
                    ForEach(relatedLifeEvents, id: \.self) { event in
                        HStack {
                            Text(event)
                            Spacer()
                            Button {
                                relatedLifeEvents.removeAll { $0 == event }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("添加关联事件", text: $newLifeEvent)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            if !newLifeEvent.isEmpty {
                                relatedLifeEvents.append(newLifeEvent)
                                newLifeEvent = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("关联现实事件")
                } footer: {
                    Text("记录与梦境相关的现实生活事件")
                }
                
                // 行动项
                Section {
                    ForEach(actionItems, id: \.self) { item in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(.green)
                            Text(item)
                            Spacer()
                            Button {
                                actionItems.removeAll { $0 == item }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("添加行动项", text: $newActionItem)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            if !newActionItem.isEmpty {
                                actionItems.append(newActionItem)
                                newActionItem = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("行动项")
                } footer: {
                    Text("基于反思想要采取的行动")
                }
                
                // 隐私设置
                Section {
                    Toggle("私密反思", isOn: $isPrivate)
                } header: {
                    Text("隐私")
                } footer: {
                    Text("私密反思仅自己可见")
                }
            }
            .navigationTitle("创建反思")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveReflection()
                    }
                    .disabled(content.isEmpty || selectedDream == nil)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingDreamPicker) {
                DreamPickerView(selectedDream: $selectedDream)
            }
        }
    }
    
    private var suggestedPrompt: ReflectionPrompt? {
        ReflectionPrompt.defaultPrompts.first { $0.type == selectedType }
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1: return "一般"
        case 2: return "有点重要"
        case 3: return "重要"
        case 4: return "很重要"
        case 5: return "非常重要"
        default: return ""
        }
    }
    
    private func saveReflection() {
        guard let service = service, let dream = selectedDream else { return }
        
        Task {
            do {
                try await service.createReflection(
                    dreamId: dream.id,
                    type: selectedType,
                    content: content,
                    tags: tags,
                    rating: rating,
                    isPrivate: isPrivate,
                    relatedLifeEvents: relatedLifeEvents,
                    actionItems: actionItems
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("保存反思失败：\(error)")
            }
        }
    }
}

// MARK: - Dream Picker View

struct DreamPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedDream: Dream?
    @State private var dreams: [Dream] = []
    @State private var searchQuery = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredDreams) { dream in
                    Button {
                        selectedDream = dream
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dream.title)
                                .font(.body)
                            
                            Text(dream.content.prefix(100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            Text(dream.date.formatted())
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("选择梦境")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "搜索梦境")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadDreams()
            }
        }
    }
    
    private var filteredDreams: [Dream] {
        if searchQuery.isEmpty {
            return dreams
        }
        return dreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            $0.content.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    private func loadDreams() async {
        let descriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: 100
        )
        
        do {
            dreams = try modelContext.fetch(descriptor)
        } catch {
            print("加载梦境失败：\(error)")
        }
    }
}

// MARK: - Reflection Detail View

struct ReflectionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let reflection: DreamReflection
    var service: DreamReflectionService?
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Content
                    contentSection
                    
                    // Tags
                    if !reflection.tags.isEmpty {
                        tagsSection
                    }
                    
                    // Related Events
                    if !reflection.relatedLifeEvents.isEmpty {
                        relatedEventsSection
                    }
                    
                    // Action Items
                    if !reflection.actionItems.isEmpty {
                        actionItemsSection
                    }
                    
                    // Metadata
                    metadataSection
                }
                .padding()
            }
            .navigationTitle("反思详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("确定删除？", isPresented: $showingDeleteConfirm) {
                Button("删除", role: .destructive) {
                    deleteReflection()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(reflection.reflectionType.icon)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text(reflection.reflectionType.displayName)
                        .font(.title2.bold())
                    
                    if let dream = reflection.dream {
                        Text("梦境：\(dream.title)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= reflection.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(star <= reflection.rating ? .yellow : .gray.opacity(0.3))
                    }
                }
            }
            
            Text(reflection.createdAt.formatted())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(reflection.content)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签")
                .font(.headline)
                .foregroundColor(.secondary)
            
            FlowLayout {
                ForEach(reflection.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
            }
        }
    }
    
    private var relatedEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关联事件")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(reflection.relatedLifeEvents, id: \.self) { event in
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                    Text(event)
                }
            }
        }
    }
    
    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("行动项")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(reflection.actionItems, id: \.self) { item in
                HStack {
                    Image(systemName: "circle")
                        .foregroundColor(.green)
                    Text(item)
                }
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("元数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "clock")
                Text("创建：\(reflection.createdAt.formatted())")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "pencil")
                Text("更新：\(reflection.updatedAt.formatted())")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if reflection.isPrivate {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("私密")
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
    }
    
    private func deleteReflection() {
        guard let service = service else { return }
        
        Task {
            do {
                try await service.deleteReflection(id: reflection.id)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("删除失败：\(error)")
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineH: CGFloat = 0
            var positions: [CGPoint] = []
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineH + spacing
                    lineH = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineH = max(lineH, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineH)
            self.positions = positions
        }
    }
}

// MARK: - Preview

#Preview {
    DreamReflectionView()
        .modelContainer(for: DreamReflection.self)
}
