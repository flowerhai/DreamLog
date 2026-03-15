//
//  NewPublishTaskView.swift
//  DreamLog
//
//  Phase 47: Dream Newsletter & Auto-Publishing
//  创建新发布任务视图
//

import SwiftUI
import SwiftData

struct NewPublishTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PublishTemplate.name) private var templates: [PublishTemplate]
    
    let dream: Dream?
    @Binding var isPresented: Bool
    
    @State private var selectedPlatform: PublishPlatform = .medium
    @State private var selectedTemplate: PublishTemplate?
    @State private var scheduledDate: Date?
    @State private var isMultiDream = false
    @State private var selectedDreams: [Dream] = []
    @State private var preview: PublishPreview?
    @State private var showingPreview = false
    @State private var isPublishing = false
    @State private var publishResult: Result<String, Error>?
    
    init(dream: Dream? = nil, isPresented: Binding<Bool>) {
        self.dream = dream
        _isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 平台选择
                Section("选择平台") {
                    Picker("平台", selection: $selectedPlatform) {
                        ForEach(PublishPlatform.allCases) { platform in
                            Label(platform.displayName, systemImage: platform.icon)
                                .tag(platform)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if !selectedPlatform.supportsAutoPublish {
                        Text("此平台需要手动发布，我们将为您生成优化后的内容")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 模板选择
                Section("发布模板") {
                    Picker("模板", selection: $selectedTemplate) {
                        ForEach(platformTemplates) { template in
                            Text(template.name).tag(template as PublishTemplate?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    NavigationLink {
                        TemplateEditorView(template: selectedTemplate)
                    } label: {
                        Text("编辑模板")
                    }
                }
                
                // 梦境选择
                if dream == nil {
                    Section("选择梦境") {
                        Toggle("发布多篇梦境（通讯）", isOn: $isMultiDream)
                        
                        if isMultiDream {
                            DreamMultiSelector(selectedDreams: $selectedDreams)
                        } else {
                            DreamSingleSelector(selectedDream: .constant(nil))
                        }
                    }
                }
                
                // 定时发布
                Section("发布时间") {
                    Toggle("定时发布", isOn: .init(
                        get: { scheduledDate != nil },
                        set: { if !$0 { scheduledDate = nil } }
                    ))
                    
                    if scheduledDate != nil {
                        DatePicker("计划时间", selection: Binding(
                            get: { scheduledDate ?? Date() },
                            set: { scheduledDate = $0 }
                        ), in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                // 预览
                Section {
                    Button(action: generatePreview) {
                        HStack {
                            Image(systemName: "eye")
                            Text("生成预览")
                        }
                    }
                    .disabled(dream == nil && !isMultiDream)
                }
                
                // 发布按钮
                Section {
                    Button(action: publish) {
                        HStack {
                            Spacer()
                            if isPublishing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("发布中...")
                            } else {
                                Text(scheduledDate != nil ? "计划发布" : "立即发布")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canPublish)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("新建发布")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let preview = preview {
                    PublishPreviewView(preview: preview, isPresented: $showingPreview)
                }
            }
            .alert("发布成功", isPresented: .init(
                get: { publishResult?.isSuccess ?? false },
                set: { if !$0 { isPresented = false } }
            )) {
                Button("确定") { }
            } message: {
                if case .success(let url) = publishResult {
                    Text("内容已发布到 \(selectedPlatform.displayName)\n\n\(url)")
                }
            }
            .alert("发布失败", isPresented: .init(
                get: { publishResult?.isFailure ?? false },
                set: { if !$0 { publishResult = nil } }
            )) {
                Button("确定") { }
            } message: {
                if case .failure(let error) = publishResult {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private var platformTemplates: [PublishTemplate] {
        templates.filter { $0.platform == selectedPlatform.rawValue }
    }
    
    private var canPublish: Bool {
        if isMultiDream {
            return !selectedDreams.isEmpty && selectedTemplate != nil
        } else {
            return dream != nil && selectedTemplate != nil
        }
    }
    
    private func generatePreview() {
        guard let template = selectedTemplate else { return }
        
        if let dream = dream {
            let service = DreamPublishService(modelContext: modelContext)
            preview = Task {
                await service.generateContent(dream: dream, template: template)
            }.result ?? nil
        }
        
        showingPreview = true
    }
    
    private func publish() {
        guard let template = selectedTemplate else { return }
        
        isPublishing = true
        
        Task {
            do {
                let service = DreamPublishService(modelContext: modelContext)
                
                if isMultiDream {
                    // 创建通讯任务
                    try await service.createNewsletterTask(
                        dreams: selectedDreams,
                        platform: selectedPlatform,
                        template: template,
                        scheduledAt: scheduledDate
                    )
                } else if let dream = dream {
                    // 创建单篇任务
                    try await service.createPublishTask(
                        dream: dream,
                        platform: selectedPlatform,
                        template: template,
                        scheduledAt: scheduledDate
                    )
                }
                
                await MainActor.run {
                    isPublishing = false
                    publishResult = .success("内容已\(scheduledDate != nil ? "计划" : "")发布")
                }
            } catch {
                await MainActor.run {
                    isPublishing = false
                    publishResult = .failure(error)
                }
            }
        }
    }
}

// MARK: - 梦境多选器

struct DreamMultiSelector: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    
    @Binding var selectedDreams: [Dream]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已选择 \(selectedDreams.count) 篇梦境")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(dreams.prefix(20)) { dream in
                HStack {
                    Button(action: {
                        if selectedDreams.contains(where: { $0.id == dream.id }) {
                            selectedDreams.removeAll { $0.id == dream.id }
                        } else {
                            selectedDreams.append(dream)
                        }
                    }) {
                        Image(systemName: selectedDreams.contains(where: { $0.id == dream.id }) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedDreams.contains(where: { $0.id == dream.id }) ? .blue : .gray)
                    }
                    .buttonStyle(.plain)
                    
                    Text(dream.title)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - 梦境单选器

struct DreamSingleSelector: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    
    @Binding var selectedDream: Dream?
    
    var body: some View {
        Picker("梦境", selection: $selectedDream) {
            ForEach(dreams.prefix(20)) { dream in
                Text(dream.title).tag(dream as Dream?)
            }
        }
    }
}

// MARK: - 发布预览视图

struct PublishPreviewView: View {
    let preview: PublishPreview
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题预览
                    VStack(alignment: .leading, spacing: 4) {
                        Text("标题")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preview.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    // 内容预览
                    VStack(alignment: .leading, spacing: 4) {
                        Text("内容")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preview.content)
                            .font(.body)
                    }
                    
                    Divider()
                    
                    // 统计信息
                    HStack(spacing: 20) {
                        StatBadge(label: "字符数", value: "\(preview.characterCount)")
                        StatBadge(label: "阅读时间", value: preview.formattedReadTime)
                        StatBadge(label: "标签数", value: "\(preview.hashtags.count)")
                    }
                    
                    // 标签预览
                    if !preview.hashtags.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("标签")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            FlowLayout(spacing: 8) {
                                ForEach(preview.hashtags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("发布预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("复制") {
                        UIPasteboard.general.string = preview.title + "\n\n" + preview.content
                    }
                }
            }
        }
    }
}

// MARK: - 统计徽章

struct StatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
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

#Preview {
    NewPublishTaskView(isPresented: .constant(true))
}
