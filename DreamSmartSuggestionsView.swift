//
//  DreamSmartSuggestionsView.swift
//  DreamLog - Phase 85: 梦境智能建议与个性化推荐系统
//
//  创建时间：2026-03-22
//  功能：智能建议 UI 界面
//

import SwiftUI
import SwiftData

// MARK: - 智能建议主界面

struct DreamSmartSuggestionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SmartSuggestion.createdAt, order: .reverse) private var suggestions: [SmartSuggestion]
    @StateObject private var service = DreamSmartSuggestionsService.shared
    @State private var selectedType: SmartSuggestionType?
    @State private var showingConfig = false
    @State private var searchText = ""
    @State private var filter: SuggestionFilter = .all
    
    enum SuggestionFilter: String, CaseIterable {
        case all = "全部"
        case active = "进行中"
        case completed = "已完成"
        case dismissed = "已关闭"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "clock.fill"
            case .completed: return "checkmark.circle.fill"
            case .dismissed: return "xmark.circle.fill"
            }
        }
    }
    
    var filteredSuggestions: [SmartSuggestion] {
        var result = suggestions
        
        // 按筛选条件过滤
        switch filter {
        case .all:
            break
        case .active:
            result = result.filter { $0.isActive }
        case .completed:
            result = result.filter { $0.isCompleted }
        case .dismissed:
            result = result.filter { $0.isDismissed }
        }
        
        // 按类型过滤
        if let selectedType = selectedType {
            result = result.filter { $0.type == selectedType.rawValue }
        }
        
        // 搜索过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var stats: SuggestionStats {
        service.calculateStats(suggestions: suggestions)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计概览
                statsOverview
                
                // 筛选器
                filterBar
                
                // 建议列表
                if filteredSuggestions.isEmpty {
                    emptyState
                } else {
                    suggestionsList
                }
            }
            .navigationTitle("智能建议")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingConfig = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !searchText.isEmpty {
                        Button("取消") {
                            searchText = ""
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索建议")
            .sheet(isPresented: $showingConfig) {
                SuggestionConfigView()
            }
        }
    }
    
    // MARK: - 统计概览
    
    private var statsOverview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    title: "总建议",
                    value: "\(stats.totalSuggestions)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: "进行中",
                    value: "\(stats.activeSuggestions)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "已完成",
                    value: "\(stats.completedSuggestions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "完成率",
                    value: String(format: "%.0f%%", stats.completionRate * 100),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 筛选栏
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SuggestionFilter.allCases, id: \.self) { filterOption in
                    FilterChip(
                        title: filterOption.rawValue,
                        icon: filterOption.icon,
                        isSelected: filter == filterOption
                    ) {
                        withAnimation(.spring()) {
                            filter = filterOption
                        }
                    }
                }
                
                Divider()
                    .frame(height: 24)
                
                ForEach(SmartSuggestionType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.spring()) {
                            selectedType = selectedType == type ? nil : type
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - 建议列表
    
    private var suggestionsList: some View {
        List(filteredSuggestions) { suggestion in
            SuggestionCard(suggestion: suggestion)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }
    
    // MARK: - 空状态
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无建议")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("继续记录梦境，智能建议将基于您的梦境模式生成")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { service.generateDailySuggestions() }) {
                Label("手动生成建议", systemImage: "sparkles")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - 统计卡片

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
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 90)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 筛选芯片

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 建议卡片

struct SuggestionCard: View {
    @ObservedObject var suggestion: SmartSuggestion
    @StateObject private var service = DreamSmartSuggestionsService.shared
    @State private var showingDetail = false
    @State private var showingCompleteConfirm = false
    
    var type: SmartSuggestionType? {
        SmartSuggestionType(rawValue: suggestion.type)
    }
    
    var priority: SuggestionPriority {
        SuggestionPriority(rawValue: suggestion.priority) ?? .medium
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack(spacing: 8) {
                Image(systemName: type?.icon ?? "lightbulb")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        PriorityBadge(priority: priority)
                        
                        if let type = type {
                            Text(type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 状态指示
                if suggestion.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if suggestion.isDismissed {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            // 描述
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // 可执行步骤预览
            if !suggestion.actionableSteps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("执行步骤")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(suggestion.actionableSteps.prefix(2), id: \.self) { step in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                            Text(step)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if suggestion.actionableSteps.count > 2 {
                        Text("还有 \(suggestion.actionableSteps.count - 2) 个步骤...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            
            // 底部信息
            HStack {
                Label(suggestion.timeCommitment, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("难度 \(suggestion.difficultyLevel)/5", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                if !suggestion.isCompleted && !suggestion.isDismissed {
                    Button(action: { showingCompleteConfirm = true }) {
                        Label("标记完成", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        withAnimation {
                            suggestion.isDismissed = true
                            suggestion.dismissedAt = Date()
                        }
                    }) {
                        Label("关闭", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                } else if suggestion.isCompleted {
                    Button(action: {
                        withAnimation {
                            suggestion.isCompleted = false
                            suggestion.completedAt = nil
                        }
                    }) {
                        Label("撤销完成", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            SuggestionDetailView(suggestion: suggestion)
        }
        .alert("标记为完成？", isPresented: $showingCompleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认") {
                withAnimation {
                    suggestion.isCompleted = true
                    suggestion.completedAt = Date()
                }
            }
        } message: {
            Text("完成后您可以获得相关成就徽章，并看到更多类似建议。")
        }
    }
}

// MARK: - 优先级徽章

struct PriorityBadge: View {
    let priority: SuggestionPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.15))
            .foregroundColor(priorityColor)
            .cornerRadius(8)
    }
    
    var priorityColor: Color {
        switch priority {
        case .low: return .secondary
        case .medium: return .blue
        case .high: return .orange
        }
    }
}

// MARK: - 建议详情界面

struct SuggestionDetailView: View {
    @ObservedObject var suggestion: SmartSuggestion
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DreamSmartSuggestionsService.shared
    @State private var showingCompleteConfirm = false
    @State private var helpfulnessRating: Int = 0
    
    var type: SmartSuggestionType? {
        SmartSuggestionType(rawValue: suggestion.type)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部卡片
                    headerCard
                    
                    // 详细描述
                    descriptionSection
                    
                    // 可执行步骤
                    actionableStepsSection
                    
                    // 预期效果
                    benefitSection
                    
                    // 基于的模式
                    if !suggestion.basedOnPatterns.isEmpty {
                        patternsSection
                    }
                    
                    // 有用性评分
                    helpfulnessSection
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("建议详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: type?.icon ?? "lightbulb.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text(suggestion.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                PriorityBadge(priority: SuggestionPriority(rawValue: suggestion.priority) ?? .medium)
                
                if let type = type {
                    Text(type.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 20) {
                Label(suggestion.timeCommitment, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("难度 \(suggestion.difficultyLevel)/5", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("详细描述")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(suggestion.description)
                .font(.body)
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var actionableStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("执行步骤")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(suggestion.actionableSteps.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    
                    Text(suggestion.actionableSteps[index])
                        .font(.body)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var benefitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text("预期效果")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(suggestion.expectedBenefit)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("基于以下模式")
                .font(.headline)
                .foregroundColor(.secondary)
            
            SmartSuggestionsFlowLayout(spacing: 8) {
                ForEach(suggestion.basedOnPatterns, id: \.self) { pattern in
                    Text(pattern)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(16)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var helpfulnessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("这个建议有帮助吗？")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button(action: {
                        helpfulnessRating = rating
                        suggestion.helpfulness = rating
                    }) {
                        Image(systemName: rating <= helpfulnessRating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(rating <= helpfulnessRating ? .yellow : .gray)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !suggestion.isCompleted && !suggestion.isDismissed {
                Button(action: { showingCompleteConfirm = true }) {
                    Label("标记为完成", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    withAnimation {
                        suggestion.isDismissed = true
                        suggestion.dismissedAt = Date()
                        dismiss()
                    }
                }) {
                    Label("关闭建议", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            } else if suggestion.isCompleted {
                Text("已完成 ✓")
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .alert("标记为完成？", isPresented: $showingCompleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认") {
                withAnimation {
                    suggestion.isCompleted = true
                    suggestion.completedAt = Date()
                    dismiss()
                }
            }
        } message: {
            Text("完成后您可以获得相关成就徽章，并看到更多类似建议。")
        }
    }
}

// MARK: - 流式布局

struct SmartSuggestionsFlowLayout: Layout {
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
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - 建议配置界面

struct SuggestionConfigView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var service = DreamSmartSuggestionsService.shared
    @State private var config = SuggestionConfig()
    @State private var enabledTypes: Set<SmartSuggestionType> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("建议类型")) {
                    ForEach(SmartSuggestionType.allCases, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { enabledTypes.contains(type) },
                            set: { isEnabled in
                                if isEnabled {
                                    enabledTypes.insert(type)
                                } else {
                                    enabledTypes.remove(type)
                                }
                            }
                        )) {
                            Label(type.displayName, systemImage: type.icon)
                        }
                    }
                }
                
                Section(header: Text("通知设置")) {
                    Toggle("显示通知", isOn: $config.showNotifications)
                    
                    if config.showNotifications {
                        HStack {
                            Text("通知时间")
                            Spacer()
                            TextField("08:00", text: $config.notificationTime)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }
                
                Section(header: Text("生成设置")) {
                    Stepper("每日建议上限：\(config.dailyLimit)", value: $config.dailyLimit, in: 1...10)
                    
                    Toggle("发现模式时自动生成", isOn: $config.autoGenerateOnPattern)
                    
                    Toggle("包含教育性内容", isOn: $config.includeEducational)
                }
                
                Section(header: Text("优先级")) {
                    Picker("最小优先级", selection: $config.minPriority) {
                        Text("可选").tag(0)
                        Text("推荐").tag(1)
                        Text("重要").tag(2)
                    }
                }
            }
            .navigationTitle("建议设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        config.enabledTypes = enabledTypes.map { $0.rawValue }
                        service.saveConfig(config)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                config = service.loadConfig()
                enabledTypes = Set(config.enabledTypes.compactMap { SmartSuggestionType(rawValue: $0) })
            }
        }
    }
}

// MARK: - 预览

#Preview {
    DreamSmartSuggestionsView()
        .modelContainer(for: [SmartSuggestion.self, SuggestionConfig.self], inMemory: true)
}
