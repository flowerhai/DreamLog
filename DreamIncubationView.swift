//
//  DreamIncubationView.swift
//  DreamLog
//
//  梦境孵育功能 UI 界面
//  支持创建、管理和跟踪孵育会话
//

import SwiftUI
import SwiftData

// MARK: - 主视图

/// 梦境孵育主视图
struct DreamIncubationView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var service = DreamIncubationService.shared
    @State private var showingCreateSheet = false
    @State private var selectedType: IncubationType?
    @State private var showingTemplateDetail = false
    @State private var selectedTemplate: IncubationTemplate?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 统计卡片
                    StatsOverviewCard(stats: service.stats)
                    
                    // 活跃会话
                    if let active = service.activeSession {
                        ActiveSessionCard(session: active, onComplete: {
                            Task {
                                await service.completeSession(active.id, successRating: 3)
                            }
                        })
                    }
                    
                    // 快速开始
                    QuickStartSection(
                        templates: service.getTemplates(),
                        onSelectType: { type in
                            selectedType = type
                            showingCreateSheet = true
                        }
                    )
                    
                    // 推荐模板
                    if let recommended = service.getRecommendedTemplate() {
                        RecommendedTemplateCard(
                            template: recommended,
                            onTap: {
                                selectedTemplate = recommended
                                showingTemplateDetail = true
                            }
                        )
                    }
                    
                    // 孵育洞察
                    InsightsSection(insights: service.getInsights())
                    
                    // 会话列表
                    SessionsListSection(
                        sessions: service.sessions,
                        onActivate: { session in
                            Task {
                                await service.activateSession(session.id)
                            }
                        },
                        onComplete: { session in
                            // 显示完成对话框
                        },
                        onDelete: { session in
                            Task {
                                await service.deleteSession(session.id)
                            }
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("🌙 梦境孵育")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateIncubationSheet(
                    service: service,
                    preselectedType: selectedType,
                    onDismiss: {
                        selectedType = nil
                    }
                )
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailSheet(template: template, service: service)
            }
            .task {
                service.setModelContext(modelContext)
                await service.loadSessions()
            }
        }
    }
}

// MARK: - 统计卡片

/// 统计概览卡片
struct StatsOverviewCard: View {
    let stats: IncubationStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                IncubationStatItem(
                    value: "\(stats.totalSessions)",
                    label: "总会话",
                    icon: "list.bullet",
                    color: .blue
                )
                
                IncubationStatItem(
                    value: "\(stats.completedSessions)",
                    label: "已完成",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                IncubationStatItem(
                    value: String(format: "%.1f", stats.averageSuccessRating),
                    label: "平均评分",
                    icon: "star.fill",
                    color: .yellow
                )
            }
            
            HStack(spacing: 20) {
                IncubationStatItem(
                    value: String(format: "%.0f%%", stats.successRate * 100),
                    label: "成功率",
                    icon: "arrow.up.right.circle.fill",
                    color: .purple
                )
                
                IncubationStatItem(
                    value: "\(stats.streakDays)天",
                    label: "连续记录",
                    icon: "flame.fill",
                    color: .orange
                )
                
                IncubationStatItem(
                    value: "\(stats.pendingSessions)",
                    label: "待完成",
                    icon: "clock.fill",
                    color: .gray
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

/// 统计项
struct IncubationStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 活跃会话卡片

/// 活跃会话卡片
struct ActiveSessionCard: View {
    let session: DreamIncubationSession
    let onComplete: () -> Void
    
    @State private var showingRatingSheet = false
    @State private var rating: Int = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: session.incubationType.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: session.incubationType.color))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("🌙 进行中")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text(session.title)
                        .font(.headline)
                }
                
                Spacer()
                
                Button {
                    showingRatingSheet = true
                } label: {
                    Text("完成")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Text(session.intention)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(session.incubationIntensity.description, systemImage: "gauge.medium")
                Spacer()
                Label("\(session.duration)分钟", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: session.incubationType.color).opacity(0.2), Color(.systemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: session.incubationType.color).opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingRatingSheet) {
            RatingSheet(
                rating: $rating,
                onSubmit: {
                    Task {
                        await DreamIncubationService.shared.completeSession(
                            session.id,
                            successRating: rating
                        )
                    }
                }
            )
        }
    }
}

// MARK: - 快速开始区域

/// 快速开始区域
struct QuickStartSection: View {
    let templates: [IncubationTemplate]
    let onSelectType: (IncubationType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速开始")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(IncubationType.allCases) { type in
                    Button {
                        onSelectType(type)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(Color(hex: type.color))
                            
                            Text(type.rawValue)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
    }
}

// MARK: - 推荐模板卡片

/// 推荐模板卡片
struct RecommendedTemplateCard: View {
    let template: IncubationTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("为你推荐")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Text(template.name)
                    .font(.headline)
                
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(template.type.rawValue, systemImage: template.type.icon)
                    Spacer()
                    Label("强度：\(template.recommendedIntensity.rawValue)", systemImage: "gauge.medium")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.1), Color(.systemBackground)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
    }
}

// MARK: - 洞察区域

/// 洞察区域
struct InsightsSection: View {
    let insights: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 孵育洞察")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.purple)
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.05))
            )
        }
    }
}

// MARK: - 会话列表区域

/// 会话列表区域
struct SessionsListSection: View {
    let sessions: [DreamIncubationSession]
    let onActivate: (DreamIncubationSession) -> Void
    let onComplete: (DreamIncubationSession) -> Void
    let onDelete: (DreamIncubationSession) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史会话")
                .font(.headline)
            
            if sessions.isEmpty {
                Text("还没有孵育会话，点击上方快速开始")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions) { session in
                        SessionRow(
                            session: session,
                            onActivate: onActivate,
                            onComplete: onComplete,
                            onDelete: onDelete
                        )
                    }
                }
            }
        }
    }
}

/// 会话行
struct SessionRow: View {
    let session: DreamIncubationSession
    let onActivate: (DreamIncubationSession) -> Void
    let onComplete: (DreamIncubationSession) -> Void
    let onDelete: (DreamIncubationSession) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: session.incubationType.icon)
                .foregroundColor(Color(hex: session.incubationType.color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.subheadline.bold())
                
                Text(session.incubationType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: session.status)
            
            if session.status == "pending" {
                Button {
                    onActivate(session)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .swipeActions(edge: .trailing) {
            if session.status == "pending" {
                Button(role: .destructive) {
                    onDelete(session)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}

/// 状态徽章
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(statusLocalized(status))
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.2))
            .foregroundColor(statusColor(status))
            .cornerRadius(4)
    }
    
    func statusLocalized(_ status: String) -> String {
        switch status {
        case "pending": return "待开始"
        case "active": return "进行中"
        case "completed": return "已完成"
        case "cancelled": return "已取消"
        default: return status
        }
    }
    
    func statusColor(_ status: String) -> Color {
        switch status {
        case "pending": return .orange
        case "active": return .green
        case "completed": return .blue
        case "cancelled": return .gray
        default: return .secondary
        }
    }
}

// MARK: - 创建孵育表单

/// 创建孵育表单
struct CreateIncubationSheet: View {
    @ObservedObject var service: DreamIncubationService
    let preselectedType: IncubationType?
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: IncubationType = .creative
    @State private var title: String = ""
    @State private var intention: String = ""
    @State private var selectedIntensity: IncubationIntensity = .moderate
    @State private var selectedAffirmations: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                // 类型选择
                Section("孵育类型") {
                    Picker("类型", selection: $selectedType) {
                        ForEach(IncubationType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(IncubationType.allCases.first { $0 == selectedType }?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 标题
                Section("标题") {
                    TextField("给你的孵育起个名字", text: $title)
                }
                
                // 意图
                Section("意图陈述") {
                    TextField("今晚我会在梦中...", text: $intention, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Text("用现在时、积极的语言描述你的目标")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 肯定语
                Section("肯定语") {
                    ForEach(service.getTemplate(for: selectedType)?.suggestedAffirmations ?? [], id: \.self) { affirmation in
                        Toggle(affirmation, isOn: Binding(
                            get: { selectedAffirmations.contains(affirmation) },
                            set: { isSelected in
                                if isSelected {
                                    selectedAffirmations.append(affirmation)
                                } else {
                                    selectedAffirmations.removeAll { $0 == affirmation }
                                }
                            }
                        ))
                    }
                }
                
                // 强度
                Section("孵育强度") {
                    Picker("强度", selection: $selectedIntensity) {
                        ForEach(IncubationIntensity.allCases) { intensity in
                            Text(intensity.rawValue).tag(intensity)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(selectedIntensity.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("创建孵育")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task {
                            try await service.createSession(
                                type: selectedType,
                                title: title.isEmpty ? selectedType.rawValue : title,
                                intention: intention,
                                affirmations: selectedAffirmations,
                                intensity: selectedIntensity
                            )
                            dismiss()
                            onDismiss()
                        }
                    }
                    .disabled(intention.isEmpty)
                }
            }
            .onAppear {
                if let preselected = preselectedType {
                    selectedType = preselected
                }
                if let template = service.getTemplate(for: selectedType) {
                    intention = template.defaultIntention
                    selectedAffirmations = Array(template.suggestedAffirmations.prefix(2))
                }
            }
            .onChange(of: selectedType) { newType in
                if let template = service.getTemplate(for: newType) {
                    intention = template.defaultIntention
                }
            }
        }
    }
}

// MARK: - 模板详情表单

/// 模板详情表单
struct TemplateDetailSheet: View {
    let template: IncubationTemplate
    @ObservedObject var service: DreamIncubationService
    
    @Environment(\.dismiss) private var dismiss
    @State private var intention: String = ""
    @State private var showingCreateConfirm = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 头部
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: template.type.icon)
                                .font(.title)
                                .foregroundColor(Color(hex: template.type.color))
                            Text(template.name)
                                .font(.title2.bold())
                        }
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 睡前仪式
                    RitualSection(
                        title: "🌙 睡前仪式",
                        steps: template.preSleepRitual
                    )
                    
                    // 晨间反思
                    RitualSection(
                        title: "☀️ 晨间反思",
                        steps: template.morningReflection
                    )
                    
                    // 肯定语
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💬 推荐肯定语")
                            .font(.headline)
                        
                        ForEach(template.suggestedAffirmations, id: \.self) { affirmation in
                            HStack {
                                Image(systemName: "quote.opening")
                                    .foregroundColor(.purple)
                                Text(affirmation)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    
                    // 意图输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🎯 你的意图")
                            .font(.headline)
                        
                        TextField("今晚我会在梦中...", text: $intention, axis: .vertical)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button {
                        showingCreateConfirm = true
                    } label: {
                        Text("开始孵育")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(intention.isEmpty)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("模板详情")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("确认创建", isPresented: $showingCreateConfirm) {
                Button("取消", role: .cancel) {}
                Button("创建") {
                    Task {
                        try await service.createSession(
                            type: template.type,
                            title: template.name,
                            intention: intention.isEmpty ? template.defaultIntention : intention,
                            affirmations: template.suggestedAffirmations,
                            intensity: template.recommendedIntensity
                        )
                        dismiss()
                    }
                }
            } message: {
                Text("准备好开始你的梦境孵育了吗？")
            }
        }
    }
}

/// 仪式步骤区域
struct RitualSection: View {
    let title: String
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 24, height: 24)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    
                    Text(step)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - 评分表单

/// 评分表单
struct RatingSheet: View {
    @Binding var rating: Int
    let onSubmit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("这次孵育效果如何？")
                    .font(.title2.bold())
                
                // 星星评分
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            rating = value
                        } label: {
                            Image(systemName: value <= rating ? "star.fill" : "star")
                                .font(.system(size: 40))
                                .foregroundColor(value <= rating ? .yellow : .gray.opacity(0.3))
                        }
                    }
                }
                
                // 评分说明
                VStack(spacing: 8) {
                    Text(ratingDescription(rating))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(ratingDetail(rating))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    onSubmit()
                    dismiss()
                } label: {
                    Text("提交")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("评分")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func ratingDescription(_ rating: Int) -> String {
        switch rating {
        case 1: return "😞 没什么效果"
        case 2: return "😐 效果一般"
        case 3: return "🙂 还不错"
        case 4: return "😊 效果很好"
        case 5: return "🤩 非常成功！"
        default: return "请选择评分"
        }
    }
    
    func ratingDetail(_ rating: Int) -> String {
        switch rating {
        case 1: return "没关系，下次再试试"
        case 2: return "继续练习会有改善"
        case 3: return "不错的进展！"
        case 4: return "你的孵育技巧很棒！"
        case 5: return "太棒了！继续保持！"
        default: return ""
        }
    }
}

// Note: Color(hex:) is defined in Theme.swift to avoid duplicate declarations

// MARK: - Preview

#Preview {
    DreamIncubationView()
        .modelContainer(for: DreamIncubationSession.self, inMemory: true)
}
