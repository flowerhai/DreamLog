//
//  DreamIncubationView.swift
//  DreamLog - 梦境孵化功能界面
//
//  提供完整的梦境孵化创建、管理和跟踪界面
//

import SwiftUI
import SwiftData

// MARK: - 主视图

struct DreamIncubationView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service: DreamIncubationService
    @State private var showingCreateSheet = false
    @State private var selectedType: IncubationTargetType?
    @State private var searchText = ""
    @State private var showingTemplates = false
    @State private var selectedIncubation: DreamIncubation?
    
    init() {
        _service = StateObject(wrappedValue: DreamIncubationService(modelContext: ModelContext(try! ModelContainer(for: DreamIncubation.self))))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading {
                    ProgressView("加载中...")
                } else {
                    incubationList
                }
            }
            .navigationTitle("梦境孵化")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !searchText.isEmpty {
                        Button("取消") {
                            searchText = ""
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showingTemplates = true }) {
                            Image(systemName: "book.fill")
                                .foregroundColor(.purple)
                        }
                        
                        Button(action: { showingCreateSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索孵化记录")
            .sheet(isPresented: $showingCreateSheet) {
                CreateIncubationView(service: service)
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatesView(service: service)
            }
            .sheet(item: $selectedIncubation) { incubation in
                IncubationDetailView(incubation: incubation, service: service)
            }
        }
        .task {
            service.fetchIncubations()
        }
    }
    
    private var incubationList: some View {
        let filteredIncubations = filteredData
        
        if filteredIncubations.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // 活跃孵化卡片
                    if let active = service.activeIncubation {
                        ActiveIncubationCard(incubation: active, service: service)
                            .padding(.horizontal)
                    }
                    
                    // 统计概览
                    StatsOverviewCard(stats: service.stats)
                        .padding(.horizontal)
                    
                    // 孵化列表
                    ForEach(filteredIncubations, id: \.self) { incubation in
                        IncubationCard(incubation: incubation)
                            .onTapGesture {
                                selectedIncubation = incubation
                            }
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    private var filteredData: [DreamIncubation] {
        if searchText.isEmpty {
            return service.incubations
        } else {
            return service.search(searchText)
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("开始你的第一次梦境孵化")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("设定睡前的意图，引导你的梦境内容")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingCreateSheet = true }) {
                Label("创建孵化", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
            
            Button(action: { showingTemplates = true }) {
                Text("查看预设模板")
                    .foregroundColor(.purple)
            }
        }
        .padding()
    }
}

// MARK: - 孵化卡片

struct IncubationCard: View {
    let incubation: DreamIncubation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                Image(systemName: incubation.targetType.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: incubation.targetType.color))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: incubation.targetType.color).opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(incubation.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(incubation.targetType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态指示
                if incubation.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            
            // 意图
            Text(incubation.intention)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // 底部信息
            HStack {
                // 强度
                HStack(spacing: 4) {
                    ForEach(1...4, id: \.self) { level in
                        Image(systemName: level <= incubation.intensity.rawValue ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // 日期
                Text(incubation.targetDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 成功评级
                if let rating = incubation.successRating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - 活跃孵化卡片

struct ActiveIncubationCard: View {
    let incubation: DreamIncubation
    @ObservedObject var service: DreamIncubationService
    @State private var showingCompleteSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Text("🌙 今晚的孵化")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
            }
            
            // 内容
            Text(incubation.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(incubation.intention)
                .font(.body)
                .foregroundColor(.secondary)
            
            // 进度
            if !incubation.completed {
                VStack(alignment: .leading, spacing: 8) {
                    Text("准备进度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: 0.3)
                        .tint(.purple)
                }
                
                Button(action: { showingCompleteSheet = true }) {
                    Text("标记为已完成")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("已完成")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingCompleteSheet) {
            CompleteIncubationView(incubation: incubation, service: service)
        }
    }
}

// MARK: - 统计概览卡片

struct StatsOverviewCard: View {
    let stats: IncubationStats
    
    var body: some View {
        VStack(spacing: 12) {
            Text("📊 孵化统计")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatItem(
                    title: "总次数",
                    value: "\(stats.totalIncubations)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatItem(
                    title: "成功率",
                    value: String(format: "%.0f%%", stats.successRate * 100),
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatItem(
                    title: "连续天数",
                    value: "\(stats.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatItem(
                    title: "冥想时长",
                    value: "\(stats.totalMeditationMinutes)m",
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 创建孵化视图

struct CreateIncubationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var service: DreamIncubationService
    
    @State private var selectedType: IncubationTargetType = .general
    @State private var title = ""
    @State private var intention = ""
    @State private var description = ""
    @State private var selectedIntensity: IncubationIntensity = .moderate
    @State private var tags: String = ""
    @State private var showingGuidance = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 类型选择
                Section("孵化类型") {
                    Picker("类型", selection: $selectedType) {
                        ForEach(IncubationTargetType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(selectedType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 基本信息
                Section("基本信息") {
                    TextField("标题 (例如：获取写作灵感)", text: $title)
                    
                    TextField("你的意图 (例如：今晚我将在梦中获得关于新故事的灵感)", text: $intention, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("描述 (可选)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // 强度选择
                Section("孵化强度") {
                    Picker("强度", selection: $selectedIntensity) {
                        ForEach(IncubationIntensity.allCases, id: \.self) { intensity in
                            VStack(alignment: .leading) {
                                Text(intensity.title)
                                Text(intensity.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(intensity)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    Text("推荐时长：\(selectedIntensity.recommendedDuration) 分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 标签
                Section("标签") {
                    TextField("添加标签 (用逗号分隔)", text: $tags)
                }
                
                // 指南
                Section {
                    Button(action: { showingGuidance = true }) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("查看孵化指南")
                        }
                    }
                }
            }
            .navigationTitle("创建孵化")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        Task {
                            do {
                                _ = try await service.createIncubation(
                                    targetType: selectedType,
                                    title: title,
                                    description: description,
                                    intention: intention,
                                    intensity: selectedIntensity,
                                    tags: tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
                                    affirmations: service.generateAffirmations(for: selectedType)
                                )
                                dismiss()
                            } catch {
                                print("创建失败：\(error)")
                            }
                        }
                    }
                    .disabled(title.isEmpty || intention.isEmpty)
                }
            }
            .sheet(isPresented: $showingGuidance) {
                GuidanceView(
                    targetType: selectedType,
                    intensity: selectedIntensity,
                    service: service
                )
            }
        }
    }
}

// MARK: - 指南视图

struct GuidanceView: View {
    @Environment(\.dismiss) var dismiss
    let targetType: IncubationTargetType
    let intensity: IncubationIntensity
    let service: DreamIncubationService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 类型信息
                    HStack {
                        Image(systemName: targetType.icon)
                            .font(.title)
                            .foregroundColor(Color(hex: targetType.color))
                        Text(targetType.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    // 指南内容
                    Text("孵化指南")
                        .font(.headline)
                    
                    Text(service.getGuidance(for: targetType, intensity: intensity))
                        .font(.body)
                        .lineSpacing(4)
                    
                    Divider()
                    
                    // 肯定语
                    Text("推荐肯定语")
                        .font(.headline)
                    
                    ForEach(service.generateAffirmations(for: targetType), id: \.self) { affirmation in
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text(affirmation)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("孵化指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 模板视图

struct TemplatesView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var service: DreamIncubationService
    @State private var selectedTemplate: IncubationTemplate?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(service.getTemplates()) { template in
                    TemplateRow(template: template)
                        .onTapGesture {
                            selectedTemplate = template
                        }
                }
            }
            .navigationTitle("孵化模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template, service: service)
            }
        }
    }
}

struct TemplateRow: View {
    let template: IncubationTemplate
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.targetType.icon)
                .font(.title2)
                .foregroundColor(Color(hex: template.targetType.color))
                .frame(width: 44, height: 44)
                .background(Color(hex: template.targetType.color).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                
                Text(template.targetType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TemplateDetailView: View {
    @Environment(\.dismiss) var dismiss
    let template: IncubationTemplate
    @ObservedObject var service: DreamIncubationService
    @State private var customIntention = ""
    @State private var showingCreate = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题
                    Text(template.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // 类型
                    HStack {
                        Image(systemName: template.targetType.icon)
                            .foregroundColor(Color(hex: template.targetType.color))
                        Text(template.targetType.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // 默认意图
                    Text("默认意图")
                        .font(.headline)
                    
                    Text(template.defaultIntention)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    TextField("或输入自定义意图", text: $customIntention, axis: .vertical)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // 指南
                    Text("指南")
                        .font(.headline)
                    
                    Text(template.guidance)
                        .font(.body)
                    
                    // 肯定语
                    Text("推荐肯定语")
                        .font(.headline)
                    
                    ForEach(template.suggestedAffirmations, id: \.self) { affirmation in
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text(affirmation)
                        }
                    }
                    
                    // 创建按钮
                    Button(action: {
                        Task {
                            do {
                                _ = try await service.createFromTemplate(
                                    template,
                                    customIntention: customIntention.isEmpty ? nil : customIntention
                                )
                                dismiss()
                            } catch {
                                print("创建失败：\(error)")
                            }
                        }
                    }) {
                        Text("使用此模板")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 完成孵化视图

struct CompleteIncubationView: View {
    @Environment(\.dismiss) var dismiss
    let incubation: DreamIncubation
    @ObservedObject var service: DreamIncubationService
    
    @State private var meditationMinutes: String = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("冥想时长") {
                    TextField("分钟数", text: $meditationMinutes)
                        .keyboardType(.numberPad)
                }
                
                Section("备注") {
                    TextField("记录你的体验 (可选)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: {
                        Task {
                            do {
                                let minutes = Int(meditationMinutes) ?? 0
                                incubation.notes = notes
                                try await service.markAsCompleted(incubation, meditationMinutes: minutes)
                                dismiss()
                            } catch {
                                print("完成失败：\(error)")
                            }
                        }
                    }) {
                        Text("标记为已完成")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("完成孵化")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 详情视图

struct IncubationDetailView: View {
    let incubation: DreamIncubation
    @ObservedObject var service: DreamIncubationService
    @Environment(\.dismiss) var dismiss
    @State private var showingRatingSheet = false
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部
                    HStack {
                        Image(systemName: incubation.targetType.icon)
                            .font(.title)
                            .foregroundColor(Color(hex: incubation.targetType.color))
                        
                        VStack(alignment: .leading) {
                            Text(incubation.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(incubation.targetType.rawValue)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if incubation.completed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    // 意图
                    SectionView(title: "意图") {
                        Text(incubation.intention)
                    }
                    
                    // 描述
                    if !incubation.description.isEmpty {
                        SectionView(title: "描述") {
                            Text(incubation.description)
                        }
                    }
                    
                    // 强度
                    SectionView(title: "强度") {
                        HStack {
                            ForEach(1...4, id: \.self) { level in
                                Image(systemName: level <= incubation.intensity.rawValue ? "star.fill" : "star")
                                    .foregroundColor(.orange)
                            }
                            Text(incubation.intensity.title)
                        }
                    }
                    
                    // 冥想时长
                    if incubation.meditationMinutes > 0 {
                        SectionView(title: "冥想时长") {
                            Text("\(incubation.meditationMinutes) 分钟")
                        }
                    }
                    
                    // 标签
                    if !incubation.tags.isEmpty {
                        SectionView(title: "标签") {
                            FlowLayout(spacing: 8) {
                                ForEach(incubation.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    
                    // 肯定语
                    if !incubation.affirmations.isEmpty {
                        SectionView(title: "肯定语") {
                            ForEach(incubation.affirmations, id: \.self) { affirmation in
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                    Text(affirmation)
                                }
                            }
                        }
                    }
                    
                    // 成功评级
                    SectionView(title: "成功评级") {
                        if let rating = incubation.successRating {
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                            }
                        } else {
                            Button(action: { showingRatingSheet = true }) {
                                Text("添加评级")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    
                    // 备注
                    if !incubation.notes.isEmpty {
                        SectionView(title: "备注") {
                            Text(incubation.notes)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("孵化详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("编辑") {
                        showingEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingRatingSheet) {
                RatingSheet(incubation: incubation, service: service)
            }
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            content
        }
    }
}

struct RatingSheet: View {
    @Environment(\.dismiss) var dismiss
    let incubation: DreamIncubation
    @ObservedObject var service: DreamIncubationService
    
    @State private var rating: Int = 3
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("成功评级") {
                    HStack {
                        Spacer()
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Text(ratingDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Section("备注") {
                    TextField("记录你的体验", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("添加评级")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            try await service.recordSuccessRating(incubation, rating: rating, notes: notes)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1: return "完全没有实现意图"
        case 2: return "很少实现意图"
        case 3: return "部分实现意图"
        case 4: return "大部分实现意图"
        case 5: return "完全实现意图"
        default: return ""
        }
    }
}

// MARK: - FlowLayout (简单实现)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
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
            (a, r, g, b) = (255, 0, 0, 0)
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
    DreamIncubationView()
}
