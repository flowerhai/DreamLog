//
//  DreamInspirationView.swift
//  DreamLog - Phase 23: Dream Inspiration & Creative Prompts
//
//  梦境灵感主界面 - 浏览和完成创意提示
//

import SwiftUI
import SwiftData

// MARK: - 灵感主界面

struct DreamInspirationView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var service = DreamInspirationService.shared
    
    @Query(sort: \CreativePrompt.createdAt, order: .reverse)
    private var prompts: [CreativePrompt]
    
    @State private var selectedType: InspirationType?
    @State private var showingFilters = false
    @State private var selectedDream: Dream?
    @State private var showingGenerator = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 统计卡片
                InspirationStatsCard()
                
                // 筛选栏
                FilterBar(selectedType: $selectedType)
                
                // 提示列表
                PromptListView(
                    prompts: filteredPrompts,
                    selectedDream: $selectedDream
                )
            }
            .navigationTitle("✨ 创意灵感")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingGenerator = true }) {
                            Label("生成新提示", systemImage: "wand.and.stars")
                        }
                        Button(action: { }) {
                            Label("创意挑战", systemImage: "trophy")
                        }
                        Button(action: { }) {
                            Label("我的收藏", systemImage: "heart")
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingGenerator) {
                PromptGeneratorSheet(selectedDream: $selectedDream)
            }
        }
    }
    
    private var filteredPrompts: [CreativePrompt] {
        if let type = selectedType {
            return prompts.filter { $0.inspirationType == type }
        }
        return prompts
    }
}

// MARK: - 统计卡片

struct InspirationStatsCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stats: InspirationStatistics = .empty
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                InspirationStatItem(
                    value: "\(stats.totalPrompts)",
                    label: "总提示",
                    icon: "lightbulb",
                    color: .purple
                )
                
                InspirationStatItem(
                    value: "\(stats.completedPrompts)",
                    label: "已完成",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                InspirationStatItem(
                    value: "\(stats.streakDays)",
                    label: "连续天数",
                    icon: "flame",
                    color: .orange
                )
                
                InspirationStatItem(
                    value: "\(stats.activeChallenges)",
                    label: "进行中挑战",
                    icon: "trophy",
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .padding()
        .task {
            stats = DreamInspirationService.shared.getStatistics()
        }
    }
}

struct InspirationStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 筛选栏

struct FilterBar: View {
    @Binding var selectedType: InspirationType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                InspirationFilterChip(
                    title: "全部",
                    icon: "grid",
                    isSelected: selectedType == nil,
                    color: .purple
                ) {
                    selectedType = nil
                }
                
                ForEach(InspirationType.allCases) { type in
                    InspirationFilterChip(
                        title: type.rawValue,
                        icon: type.icon,
                        isSelected: selectedType == type,
                        color: Color(hex: type.color)
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct InspirationFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : color)
        }
    }
}

// MARK: - 提示列表

struct PromptListView: View {
    let prompts: [CreativePrompt]
    @Binding var selectedDream: Dream?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(prompts) { prompt in
                    PromptCard(prompt: prompt)
                }
                
                if prompts.isEmpty {
                    EmptyStateView(
                        icon: "💡",
                        title: "还没有创意提示",
                        subtitle: "从你的梦境中生成第一个创意提示吧！"
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 提示卡片

struct PromptCard: View {
    @Environment(\.modelContext) private var modelContext
    let prompt: CreativePrompt
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Text(prompt.inspirationType.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(prompt.title)
                        .font(.headline)
                    Text(prompt.inspirationType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 难度
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= prompt.difficulty ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(i <= prompt.difficulty ? .orange : .gray.opacity(0.3))
                    }
                }
            }
            
            // 描述
            Text(prompt.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // 底部信息
            HStack {
                Label("\(prompt.estimatedTime) 分钟", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 标签
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(prompt.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }
                    }
                }
                
                // 完成状态
                if prompt.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                // 收藏状态
                Image(systemName: prompt.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(prompt.isFavorite ? .red : .gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            PromptDetailView(prompt: prompt)
        }
    }
}

// MARK: - 提示详情

struct PromptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let prompt: CreativePrompt
    @State private var isCompleted = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 类型和标题
                    HStack {
                        Text(prompt.inspirationType.icon)
                            .font(.title)
                        Text(prompt.inspirationType.rawValue)
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    
                    Text(prompt.title)
                        .font(.title2.bold())
                    
                    Divider()
                    
                    // 描述
                    Text("提示内容")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(prompt.description)
                        .font(.body)
                        .lineSpacing(4)
                    
                    // 信息卡片
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "clock", label: "预计时间", value: "\(prompt.estimatedTime) 分钟")
                        InfoRow(icon: "star", label: "难度", value: String(repeating: "★", count: prompt.difficulty) + String(repeating: "☆", count: 5 - prompt.difficulty))
                        InfoRow(icon: "calendar", label: "创建时间", value: prompt.createdAt.formatted())
                        
                        if let completedDate = prompt.completedDate {
                            InfoRow(icon: "checkmark.circle", label: "完成时间", value: completedDate.formatted())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // 标签
                    Text("标签")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HorizontalFlowLayout(data: prompt.tags, spacing: 8) { tag in
                        Text("#\(tag)")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("创意提示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if prompt.isCompleted {
                        Button("已完成") {
                            dismiss()
                        }
                        .foregroundColor(.green)
                    } else {
                        Button("标记完成") {
                            DreamInspirationService.shared.markPromptAsCompleted(prompt)
                            isCompleted = true
                            dismiss()
                        }
                        .foregroundColor(.purple)
                    }
                }
                
                ToolbarItem(placement: .destructionAction) {
                    Button(action: {
                        DreamInspirationService.shared.toggleFavorite(prompt)
                    }) {
                        Image(systemName: prompt.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(prompt.isFavorite ? .red : .gray)
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.purple)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - 生成器

struct PromptGeneratorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDream: Dream?
    @State private var selectedType: InspirationType?
    @State private var generatedPrompt: CreativePrompt?
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let prompt = generatedPrompt {
                    PromptPreviewCard(prompt: prompt)
                } else {
                    GeneratorForm(
                        selectedType: $selectedType,
                        isGenerating: $isGenerating,
                        onGenerate: {
                            isGenerating = true
                            // 模拟生成
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                generatedPrompt = CreativePrompt(
                                    title: "梦境续写",
                                    description: "如果这个梦继续下去，接下来会发生什么？写一个 500 字的续集。",
                                    type: selectedType ?? .writing,
                                    difficulty: 3,
                                    estimatedTime: 30,
                                    tags: ["写作", "创意", "续写"]
                                )
                                isGenerating = false
                            }
                        }
                    )
                }
            }
            .padding()
            .navigationTitle("生成创意提示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if generatedPrompt != nil {
                        Button("保存") {
                            if let prompt = generatedPrompt {
                                DreamInspirationService.shared.savePrompt(prompt)
                            }
                            dismiss()
                        }
                        .foregroundColor(.purple)
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PromptPreviewCard: View {
    let prompt: CreativePrompt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(prompt.inspirationType.icon)
                    .font(.title2)
                Text(prompt.inspirationType.rawValue)
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            
            Text(prompt.title)
                .font(.title2.bold())
            
            Text(prompt.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Label("\(prompt.estimatedTime) 分钟", systemImage: "clock")
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= prompt.difficulty ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(i <= prompt.difficulty ? .orange : .gray.opacity(0.3))
                    }
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct GeneratorForm: View {
    @Binding var selectedType: InspirationType?
    @Binding var isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("选择创意类型")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(InspirationType.allCases) { type in
                    Button(action: {
                        selectedType = type
                    }) {
                        VStack(spacing: 8) {
                            Text(type.icon)
                                .font(.title)
                            Text(type.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedType == type ? Color.purple : Color(.secondarySystemBackground))
                        )
                        .foregroundColor(selectedType == type ? .white : .primary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onGenerate) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isGenerating ? "生成中..." : "生成提示")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedType == nil || isGenerating)
        }
    }
}

// MARK: - 辅助视图

struct HorizontalFlowLayout<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Hashable, Content: View {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    init(data: Data = [], spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        // Simplified flow layout
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(data, id: \.self) { element in
                    content(element)
                }
            }
        }
    }
}

#Preview {
    DreamInspirationView()
        .modelContainer(for: CreativePrompt.self)
}
