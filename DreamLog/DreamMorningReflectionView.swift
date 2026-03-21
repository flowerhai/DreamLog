//
//  DreamMorningReflectionView.swift
//  DreamLog
//
//  Phase 79: Morning Reflection Guide - 晨间反思引导
//  晨间反思 UI 界面
//

import SwiftUI
import SwiftData
import UIKit

@available(iOS 17.0, *)
struct DreamMorningReflectionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: MorningReflectionViewModel
    @State private var selectedType: MorningReflectionType?
    @State private var showingSettings = false
    @State private var newReflectionContent = ""
    @State private var showingNewReflection = false
    
    init() {
        _viewModel = StateObject(wrappedValue: MorningReflectionViewModel())
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.reflections.isEmpty {
                    emptyView
                } else {
                    reflectionsList
                }
            }
            .navigationTitle("晨间反思")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewReflection = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewReflection) {
                NewReflectionView(
                    viewModel: viewModel,
                    isPresented: $showingNewReflection
                )
            }
            .sheet(isPresented: $showingSettings) {
                ReflectionSettingsView()
            }
            .refreshable {
                await viewModel.loadReflections()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadReflections()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            
            Text("加载反思记录...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Text("🌅")
                .font(.system(size: 80))
            
            Text("开始你的晨间反思之旅")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("每天花几分钟回顾梦境，\n发现潜意识的智慧")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("开始第一次反思") {
                showingNewReflection = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 100)
    }
    
    private var reflectionsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 统计卡片
                statisticsCard
                
                // 类型筛选
                typeFilter
                
                // 反思列表
                ForEach(filteredReflections, id: \.id) { reflection in
                    ReflectionCard(
                        reflection: reflection,
                        onDelete: { viewModel.deleteReflection(id: reflection.id) }
                    )
                }
            }
            .padding()
        }
    }
    
    private var statisticsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatBox(
                    value: "\(viewModel.statistics.totalReflections)",
                    label: "总反思",
                    icon: "📝"
                )
                
                StatBox(
                    value: "\(viewModel.statistics.streakDays)",
                    label: "连续天数",
                    icon: "🔥"
                )
                
                StatBox(
                    value: "\(viewModel.statistics.completedToday)",
                    label: "今日完成",
                    icon: "✅"
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedType == nil,
                    icon: "📋"
                ) {
                    selectedType = nil
                }
                
                ForEach(MorningReflectionType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.title,
                        isSelected: selectedType == type,
                        icon: type.icon
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var filteredReflections: [DreamMorningReflection] {
        if let type = selectedType {
            return viewModel.reflections.filter { $0.type == type }
        }
        return viewModel.reflections
    }
}

// MARK: - 反思卡片

@available(iOS 17.0, *)
struct ReflectionCard: View {
    let reflection: DreamMorningReflection
    let onDelete: () -> Void
    @State private var showingDeleteConfirm = false
    
    private func shareReflection(_ reflection: DreamMorningReflection) {
        var shareText = "🌅 晨间反思\n\n"
        shareText += "\(reflection.type.icon) \(reflection.type.title)\n"
        shareText += "\(reflection.date.formatted(date: .abbreviated, time: .shortened))\n\n"
        shareText += reflection.content
        
        if let mood = reflection.mood {
            shareText += "\n\n情绪：\(mood)"
        }
        
        if !reflection.tags.isEmpty {
            shareText += "\n\n标签：\(reflection.tags.joined(separator: ", "))"
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Text(reflection.type.icon)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(reflection.type.title)
                        .font(.headline)
                    
                    Text(reflection.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if reflection.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Menu {
                    Button("完成") {
                        Task {
                            do {
                                try await viewModel.markReflectionCompleted(id: reflection.id)
                            } catch {
                                print("Failed to mark reflection completed: \(error)")
                            }
                        }
                    }
                    
                    Button("分享") {
                        shareReflection(reflection)
                    }
                    
                    Divider()
                    
                    Button("删除", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // 内容
            Text(reflection.content)
                .font(.body)
                .lineLimit(3)
            
            // 标签
            if !reflection.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(reflection.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .confirmationDialog("删除反思", isPresented: $showingDeleteConfirm) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这条反思记录吗？此操作不可撤销。")
        }
    }
}

// MARK: - 新建反思视图

@available(iOS 17.0, *)
struct NewReflectionView: View {
    @ObservedObject var viewModel: MorningReflectionViewModel
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: MorningReflectionType = .insight
    @State private var content = ""
    @State private var mood = ""
    @State private var tagsText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("反思类型") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(MorningReflectionType.allCases, id: \.self) { type in
                            TypeSelectionCard(
                                type: type,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("提示") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType.prompt)
                            .font(.headline)
                        
                        Text("试着深入思考这个问题，写下你的真实感受。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("你的反思") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
                
                Section("情绪（可选）") {
                    TextField("例如：平静、兴奋、困惑...", text: $mood)
                }
                
                Section("标签（可选）") {
                    TextField("用逗号分隔，例如：成长，觉察，感恩", text: $tagsText)
                }
            }
            .navigationTitle("新建反思")
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
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveReflection() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        do {
            try viewModel.createReflection(
                type: selectedType,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                mood: mood.isEmpty ? nil : mood,
                tags: tags
            )
            dismiss()
        } catch {
            print("Failed to save reflection: \(error)")
        }
    }
}

// MARK: - 类型选择卡片

struct TypeSelectionCard: View {
    let type: MorningReflectionType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Text(type.icon)
                    .font(.title)
                
                Text(type.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 设置视图

@available(iOS 17.0, *)
struct ReflectionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enabled = true
    @State private var reminderTime = "07:00"
    @State private var dailyGoal = 3
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基础设置") {
                    Toggle("启用晨间反思", isOn: $enabled)
                }
                
                Section("提醒设置") {
                    DatePicker("提醒时间", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                    
                    Stepper("每日目标：\(dailyGoal) 条", value: $dailyGoal, in: 1...10)
                }
                
                Section("说明") {
                    Text("晨间反思帮助你从梦境中获得洞察，将潜意识的智慧带入日常生活。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("反思设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        let config = MorningReflectionConfig(
            enabled: enabled,
            reminderTime: reminderTime,
            enabledTypes: MorningReflectionType.allCases,
            showOnWake: enabled,
            dailyGoal: dailyGoal
        )
        
        // Save using service (in a real app, this would use dependency injection)
        do {
            let container = try ModelContainer(for: DreamMorningReflection.self)
            let service = DreamMorningReflectionService(modelContext: ModelContext(container))
            Task {
                try await service.saveConfig(config)
                if enabled {
                    try await service.scheduleMorningReminder(time: reminderTime)
                } else {
                    await service.cancelMorningReminder()
                }
            }
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

// MARK: - ViewModel

@available(iOS 17.0, *)
@MainActor
class MorningReflectionViewModel: ObservableObject {
    @Published var reflections: [DreamMorningReflection] = []
    @Published var statistics = MorningReflectionStats()
    @Published var isLoading = false
    
    private let service: DreamMorningReflectionService
    
    init() {
        // Create in-memory model context for previews/standalone use
        // In production, the view should receive modelContext from environment
        let container: ModelContainer
        if let inMemoryContainer = try? ModelContainer(for: DreamMorningReflection.self, configurations: [.init(isStoredInMemoryOnly: true)]) {
            container = inMemoryContainer
        } else {
            container = try! ModelContainer(for: DreamMorningReflection.self, configurations: [.init(isStoredInMemoryOnly: true)])
        }
        let modelContext = ModelContext(container)
        self.service = DreamMorningReflectionService(modelContext: modelContext)
    }
    
    func loadReflections() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            reflections = try service.getAllReflections(limit: 100)
            statistics = try service.getStatistics()
        } catch {
            print("Failed to load reflections: \(error)")
        }
    }
    
    func createReflection(
        type: MorningReflectionType,
        content: String,
        mood: String?,
        tags: [String]
    ) throws {
        try service.createReflection(type: type, content: content, mood: mood, tags: tags)
        Task {
            await loadReflections()
        }
    }
    
    func deleteReflection(id: UUID) {
        do {
            try service.deleteReflection(id: id)
            reflections.removeAll { $0.id == id }
        } catch {
            print("Failed to delete reflection: \(error)")
        }
    }
    
    func markReflectionCompleted(id: UUID) async throws {
        try service.markReflectionCompleted(id: id)
        // Update local state
        if let index = reflections.firstIndex(where: { $0.id == id }) {
            reflections[index].isCompleted = true
        }
    }
}

// MARK: - Preview

#Preview {
    DreamMorningReflectionView()
}
