//
//  DreamAICoachView.swift
//  DreamLog
//
//  Phase 97: AI 教练 - UI 界面
//  提供个性化数字健康计划、习惯养成追踪、AI 驱动的干预建议
//

import SwiftUI
import SwiftData

// MARK: - AI 教练主界面

struct DreamAICoachView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DreamAICoachViewModel
    @State private var selectedTab: CoachTab = .plans
    @State private var showingCreatePlan = false
    @State private var selectedPlan: DreamAICoachPlan?
    
    enum CoachTab: String, CaseIterable {
        case plans = "计划"
        case habits = "习惯"
        case progress = "进度"
        case insights = "洞察"
        
        var icon: String {
            switch self {
            case .plans: return "list.bullet.clipboard"
            case .habits: return "checkmark.circle"
            case .progress: return "chart.bar"
            case .insights: return "lightbulb"
            }
        }
    }
    
    init() {
        _viewModel = StateObject(wrappedValue: DreamAICoachViewModel())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部统计卡片
                statisticsHeader
                
                // 主内容区
                TabView(selection: $selectedTab) {
                    plansTab
                        .tag(CoachTab.plans)
                    
                    habitsTab
                        .tag(CoachTab.habits)
                    
                    progressTab
                        .tag(CoachTab.progress)
                    
                    insightsTab
                        .tag(CoachTab.insights)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 底部导航
                bottomNavigationBar
            }
            .navigationTitle("AI 教练")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreatePlan = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreatePlanView()
            }
            .task {
                await viewModel.loadPlans()
                await viewModel.loadStatistics()
            }
        }
    }
    
    // MARK: - 统计头部
    
    private var statisticsHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatCard(
                    title: "活跃计划",
                    value: "\(viewModel.statistics.activePlans)",
                    icon: "list.bullet.clipboard",
                    color: .blue
                )
                
                StatCard(
                    title: "当前连续",
                    value: "\(viewModel.statistics.currentStreak)天",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "总完成",
                    value: "\(viewModel.statistics.totalCompletions)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "完成率",
                    value: String(format: "%.0f%%", viewModel.statistics.habitCompletionRate),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - 计划标签页
    
    private var plansTab: some View {
        Group {
            if viewModel.plans.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.clipboard",
                    title: "还没有计划",
                    subtitle: "创建一个 AI 教练计划开始你的成长之旅",
                    action: "创建计划"
                ) {
                    showingCreatePlan = true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.plans, id: \.id) { plan in
                            PlanCard(plan: plan) {
                                selectedPlan = plan
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - 习惯标签页
    
    private var habitsTab: some View {
        Group {
            if viewModel.allHabits.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "还没有习惯",
                    subtitle: "创建一个计划来开始培养好习惯",
                    action: "创建计划"
                ) {
                    showingCreatePlan = true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.allHabits, id: \.id) { habit in
                            HabitRow(habit: habit, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - 进度标签页
    
    private var progressTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 周进度图表
                WeeklyProgressChart(viewModel: viewModel)
                
                // 习惯完成趋势
                HabitTrendChart(viewModel: viewModel)
                
                // 成就展示
                AchievementsSection(viewModel: viewModel)
            }
            .padding()
        }
    }
    
    // MARK: - 洞察标签页
    
    private var insightsTab: some View {
        Group {
            if viewModel.interventions.isEmpty {
                EmptyStateView(
                    icon: "lightbulb",
                    title: "暂无新洞察",
                    subtitle: "继续你的计划，AI 教练会为你提供个性化建议",
                    action: nil
                ) {}
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.interventions, id: \.id) { intervention in
                            InterventionCard(intervention: intervention, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - 底部导航
    
    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            ForEach(CoachTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .top
        )
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
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 计划卡片组件

struct PlanCard: View {
    let plan: DreamAICoachPlan
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plan.planType.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.headline)
                    Text(plan.planType.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                StatusBadge(status: plan.status)
            }
            
            Text(plan.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // 进度条
            VStack(spacing: 4) {
                HStack {
                    Text("进度")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.0f%%", plan.progress))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: plan.progress / 100)
                    .progressViewStyle(.linear)
            }
            
            HStack {
                Label("\(plan.completedDays)/\(plan.duration)天", systemImage: "calendar")
                    .font(.caption)
                
                Spacer()
                
                Label("\(plan.streak)天连续", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 状态徽章

struct StatusBadge: View {
    let status: CoachPlanStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(8)
    }
}

extension CoachPlanStatus {
    var displayName: String {
        switch self {
        case .draft: return "草稿"
        case .active: return "进行中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .archived: return "已归档"
        }
    }
    
    var color: Color {
        switch self {
        case .draft: return .gray
        case .active: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .archived: return .gray
        }
    }
}

// MARK: - 习惯行组件

struct HabitRow: View {
    let habit: DreamAICoachHabit
    let viewModel: DreamAICoachViewModel
    @State private var isCompletedToday = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.habitType.icon)
                .font(.title2)
                .foregroundColor(isCompletedToday ? .green : .blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label("\(habit.streak)天连续", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Label("总计\(habit.totalCompletions)次", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    try? await viewModel.completeHabit(habitId: habit.id)
                    isCompletedToday = true
                }
            }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompletedToday ? .green : .gray)
            }
            .disabled(isCompletedToday)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .task {
            do {
                isCompletedToday = try await viewModel.isHabitCompletedToday(habitId: habit.id)
            } catch {
                isCompletedToday = false
            }
        }
    }
}

// MARK: - 周进度图表

struct WeeklyProgressChart: View {
    let viewModel: DreamAICoachViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周进度")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day < viewModel.currentWeekDay ? Color.blue : Color.gray.opacity(0.2))
                            .frame(width: 30, height: 80 * Double.random(in: 0.3...1.0))
                        
                        Text(dayName(for: day))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func dayName(for index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let date = Calendar.current.date(byAdding: .day, value: index - 6, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private var currentWeekDay: Int {
        Calendar.current.component(.weekday, from: Date()) - 1
    }
}

// MARK: - 习惯趋势图表

struct HabitTrendChart: View {
    let viewModel: DreamAICoachViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("习惯完成趋势")
                .font(.headline)
            
            // 简化版趋势图
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let points: [(x: CGFloat, y: CGFloat)] = [
                        (0, height * 0.7),
                        (width * 0.2, height * 0.5),
                        (width * 0.4, height * 0.6),
                        (width * 0.6, height * 0.3),
                        (width * 0.8, height * 0.4),
                        (width, height * 0.2)
                    ]
                    
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.blue, lineWidth: 3)
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - 成就部分

struct AchievementsSection: View {
    let viewModel: DreamAICoachViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就徽章")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AchievementBadge(icon: "flame.fill", title: "7 天连续", achieved: viewModel.statistics.currentStreak >= 7)
                    AchievementBadge(icon: "star.fill", title: "30 天连续", achieved: viewModel.statistics.currentStreak >= 30)
                    AchievementBadge(icon: "trophy.fill", title: "完成计划", achieved: viewModel.statistics.completedPlans > 0)
                    AchievementBadge(icon: "checkmark.circle.fill", title: "100 次完成", achieved: viewModel.statistics.totalCompletions >= 100)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - 成就徽章

struct AchievementBadge: View {
    let icon: String
    let title: String
    let achieved: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(achieved ? .yellow : .gray)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(achieved ? .primary : .gray)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(achieved ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 干预卡片

struct InterventionCard: View {
    let intervention: DreamAICoachIntervention
    let viewModel: DreamAICoachViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: intervention.icon)
                    .font(.title2)
                    .foregroundColor(intervention.priorityColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(intervention.title)
                        .font(.headline)
                    Text(intervention.interventionType.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(intervention.priority.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(intervention.priorityColor.opacity(0.2))
                    .foregroundColor(intervention.priorityColor)
                    .cornerRadius(4)
            }
            
            Text(intervention.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let action = intervention.suggestedAction {
                Button(action: {
                    Task {
                        try? await viewModel.markInterventionCompleted(interventionId: intervention.id)
                    }
                }) {
                    Text(action)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Spacer()
                Button("忽略") {
                    Task {
                        try? await viewModel.dismissIntervention(interventionId: intervention.id)
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

extension DreamAICoachIntervention {
    var icon: String {
        switch interventionType {
        case .sleepQualityAlert: return "moon.zzz"
        case .stressWarning: return "heart.circle"
        case .dreamPatternChange: return "chart.line.uptrend.xyaxis"
        case .habitSlip: return "flame"
        case .milestoneAchieved: return "trophy"
        case .encouragement: return "star.fill"
        case .suggestion: return "lightbulb"
        case .healthAlert: return "cross.case"
        }
    }
    
    var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - 空状态视图

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: String?
    let actionHandler: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if let action = action {
                Button(action: actionHandler) {
                    Text(action)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 创建计划视图

struct CreatePlanView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = DreamAICoachViewModel()
    @State private var selectedTemplate: CoachPlanTemplate?
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.templates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        ) {
                            selectedTemplate = template
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("创建计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        showingConfirmation = true
                    }
                    .disabled(selectedTemplate == nil)
                }
            }
            .alert("确认创建计划", isPresented: $showingConfirmation) {
                Button("取消", role: .cancel) {}
                Button("创建") {
                    Task {
                        if let template = selectedTemplate {
                            try? await viewModel.createPlan(from: template)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("确定要创建\"\(selectedTemplate?.name ?? "")\"计划吗？")
            }
        }
    }
}

// MARK: - 模板卡片

struct TemplateCard: View {
    let template: CoachPlanTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.planType.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                    Text("\(template.duration)天 • \(template.difficulty.displayName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 习惯预览
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(template.habits, id: \.habitType) { habit in
                        Label(habit.title, systemImage: habit.habitType.icon)
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
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - View Model

@MainActor
class DreamAICoachViewModel: ObservableObject {
    @Published var plans: [DreamAICoachPlan] = []
    @Published var allHabits: [DreamAICoachHabit] = []
    @Published var interventions: [DreamAICoachIntervention] = []
    @Published var statistics = CoachStatistics.empty
    @Published var templates: [CoachPlanTemplate] = []
    @Published var currentWeekDay = 0
    
    private let service = DreamAICoachService.shared
    
    init() {
        currentWeekDay = Calendar.current.component(.weekday, from: Date()) - 1
    }
    
    func loadPlans() async {
        do {
            plans = try await service.getUserPlans()
        } catch {
            print("Failed to load plans: \(error)")
        }
    }
    
    func loadStatistics() async {
        do {
            statistics = try await service.getStatistics()
            templates = service.getPlanTemplates()
        } catch {
            print("Failed to load statistics: \(error)")
        }
    }
    
    func createPlan(from template: CoachPlanTemplate) async throws {
        _ = try await service.createPlan(from: template)
        await loadPlans()
        await loadStatistics()
    }
    
    func completeHabit(habitId: UUID) async throws {
        try await service.completeHabit(habitId: habitId)
        await loadStatistics()
    }
    
    func isHabitCompletedToday(habitId: UUID) async throws -> Bool {
        try await service.isHabitCompletedToday(habitId: habitId)
    }
    
    func markInterventionCompleted(interventionId: UUID) async throws {
        try await service.markInterventionCompleted(interventionId: interventionId)
        await loadInterventions()
    }
    
    func dismissIntervention(interventionId: UUID) async throws {
        try await service.dismissIntervention(interventionId: interventionId)
        await loadInterventions()
    }
    
    func loadInterventions() async {
        do {
            interventions = try await service.getPendingInterventions()
        } catch {
            print("Failed to load interventions: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    DreamAICoachView()
}
