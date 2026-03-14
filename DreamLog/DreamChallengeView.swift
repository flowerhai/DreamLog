//
//  DreamChallengeView.swift
//  DreamLog
//
//  Phase 41 - 梦境挑战系统
//  用户界面
//

import SwiftUI
import SwiftData

// MARK: - 挑战主界面

struct DreamChallengeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamChallengeService?
    @State private var challenges: [DreamChallenge] = []
    @State private var badges: [ChallengeBadge] = []
    @State private var stats: ChallengeStats?
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    @State private var selectedFilter: DreamChallengeType?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计概览
                statsView
                
                // 筛选器
                filterBar
                
                // 挑战列表
                challengeList
                
                // 底部徽章栏
                badgeBar
            }
            .navigationTitle("🎯 梦境挑战")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .task {
                await loadChallenges()
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateChallengeView()
            }
        }
    }
    
    // MARK: - 统计概览
    
    private var statsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                StatCard(
                    title: "进行中",
                    value: "\(stats?.inProgressChallenges ?? 0)",
                    icon: "🔥",
                    color: .orange
                )
                
                StatCard(
                    title: "已完成",
                    value: "\(stats?.completedChallenges ?? 0)",
                    icon: "✅",
                    color: .green
                )
                
                StatCard(
                    title: "总积分",
                    value: "\(stats?.totalPoints ?? 0)",
                    icon: "⭐",
                    color: .purple
                )
                
                StatCard(
                    title: "徽章",
                    value: "\(stats?.totalBadges ?? 0)",
                    icon: "🏆",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - 筛选器
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "全部",
                    icon: "📋",
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }
                
                ForEach(DreamChallengeType.allCases) { type in
                    FilterChip(
                        title: type.displayName.replacingOccurrences(of: " ", with: ""),
                        icon: type.icon,
                        isSelected: selectedFilter == type
                    ) {
                        selectedFilter = type
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - 挑战列表
    
    private var challengeList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 进行中的挑战
                if selectedFilter == nil || selectedFilter == .streak {
                    if !challenges.filter({ $0.isOngoing }).isEmpty {
                        SectionHeader(title: "🔥 进行中")
                        ForEach(challenges.filter { $0.isOngoing }) { challenge in
                            ChallengeCard(challenge: challenge, service: service)
                        }
                    }
                }
                
                // 可参与的挑战
                if selectedFilter == nil {
                    SectionHeader(title: "✨ 可参与")
                    ForEach(challenges.filter { $0.status == .available && !$0.isExpired }) { challenge in
                        ChallengeCard(challenge: challenge, service: service)
                    }
                }
                
                // 已完成的挑战
                if selectedFilter == nil {
                    SectionHeader(title: "✅ 已完成")
                    ForEach(challenges.filter { $0.status == .completed }) { challenge in
                        ChallengeCard(challenge: challenge, service: service)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - 徽章栏
    
    private var badgeBar: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Text("🏆 最近徽章")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(badges.prefix(5)) { badge in
                            VStack {
                                Text(badge.icon)
                                    .font(.title2)
                                Text(badge.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .frame(width: 50)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Methods
    
    private func loadChallenges() async {
        service = DreamChallengeService(modelContext: modelContext)
        await service?.initializePresetChallenges()
        challenges = await service?.getAllChallenges() ?? []
        badges = await service?.getAllBadges() ?? []
        stats = await service?.getChallengeStats()
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
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
                Text(icon)
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - 章节标题

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }
}

// MARK: - 挑战卡片

struct ChallengeCard: View {
    let challenge: DreamChallenge
    var service: DreamChallengeService?
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(challenge.type.icon)
                            .font(.title2)
                        Text(challenge.title)
                            .font(.headline)
                    }
                    
                    Text(challenge.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: challenge.status)
                    DifficultyBadge(difficulty: challenge.difficulty)
                }
            }
            
            // 进度条
            if challenge.isOngoing {
                VStack(spacing: 4) {
                    HStack {
                        Text("进度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(challenge.progressPercentage)%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: challenge.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                }
            }
            
            // 任务列表
            if challenge.isOngoing {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(challenge.tasks.prefix(3), id: \.id) { task in
                        TaskRow(task: task)
                    }
                    
                    if challenge.tasks.count > 3 {
                        Text("+ \(challenge.tasks.count - 3) 更多任务")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 底部信息
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(challenge.earnedPoints)/\(challenge.totalPoints) 积分")
                        .font(.caption)
                }
                
                Spacer()
                
                if challenge.isOngoing {
                    Text("⏰ 剩余 \(challenge.daysRemaining) 天")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Button(action: { showingDetail = true }) {
                    Text("详情")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingDetail) {
            ChallengeDetailView(challenge: challenge, service: service)
        }
    }
}

// MARK: - 状态徽章

struct StatusBadge: View {
    let status: ChallengeStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .available: return .green
        case .inProgress: return .blue
        case .completed: return .purple
        case .failed: return .red
        case .expired: return .gray
        }
    }
}

// MARK: - 难度徽章

struct DifficultyBadge: View {
    let difficulty: ChallengeDifficulty
    
    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray5))
            .cornerRadius(8)
    }
}

// MARK: - 任务行

struct TaskRow: View {
    let task: ChallengeTask
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isCompleted)
                Text("\(task.currentCount)/\(task.targetCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(task.points)")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
}

// MARK: - 挑战详情

struct ChallengeDetailView: View {
    let challenge: DreamChallenge
    var service: DreamChallengeService?
    @Environment(\.dismiss) private var dismiss
    @State private var isStarting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部信息
                    ChallengeHeader(challenge: challenge)
                    
                    // 任务列表
                    TaskList(challenge: challenge, service: service)
                    
                    // 操作按钮
                    ActionButtons(challenge: challenge, service: service, isStarting: $isStarting)
                }
                .padding()
            }
            .navigationTitle("挑战详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

struct ChallengeHeader: View {
    let challenge: DreamChallenge
    
    var body: some View {
        VStack(spacing: 12) {
            Text(challenge.type.icon)
                .font(.system(size: 60))
            
            Text(challenge.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(challenge.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                InfoBadge(icon: "📅", text: "\(challenge.totalDays)天")
                InfoBadge(icon: "⭐", text: "\(challenge.totalPoints)积分")
                InfoBadge(icon: "👥", text: "\(challenge.participantCount)人参与")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct InfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
            Text(text)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
}

struct TaskList: View {
    let challenge: DreamChallenge
    var service: DreamChallengeService?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 挑战任务")
                .font(.headline)
            
            ForEach(challenge.tasks, id: \.id) { task in
                TaskRow(task: task)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
}

struct ActionButtons: View {
    let challenge: DreamChallenge
    var service: DreamChallengeService?
    @Binding var isStarting: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            if challenge.status == .available {
                Button(action: startChallenge) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始挑战")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isStarting)
            } else if challenge.isOngoing {
                Button(action: quitChallenge) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("放弃挑战")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func startChallenge() {
        isStarting = true
        Task {
            try? await service?.startChallenge(id: challenge.id)
            dismiss()
        }
    }
    
    private func quitChallenge() {
        Task {
            try? await service?.quitChallenge(id: challenge.id)
            dismiss()
        }
    }
}

// MARK: - 创建挑战

struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var description = ""
    @State private var selectedType: DreamChallengeType = .recall
    @State private var selectedDifficulty: ChallengeDifficulty = .easy
    @State private var duration = 7
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("挑战标题", text: $title)
                    TextField("挑战描述", text: $description)
                    
                    Picker("挑战类型", selection: $selectedType) {
                        ForEach(DreamChallengeType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("难度等级", selection: $selectedDifficulty) {
                        ForEach(ChallengeDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                    
                    Stepper("持续时间：\(duration) 天", value: $duration, in: 1...90)
                }
                
                Section(header: Text("提示")) {
                    Text("创建自定义挑战后，您可以添加具体任务和目标。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("创建挑战")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        Task {
                            await createChallenge()
                        }
                    }
                    .disabled(title.isEmpty || isCreating)
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func createChallenge() async {
        isCreating = true
        defer { isCreating = false }
        
        do {
            // 根据类型创建默认任务
            let tasks = createDefaultTasks(for: selectedType, difficulty: selectedDifficulty)
            
            let service = DreamChallengeService(modelContext: modelContext)
            let challenge = try await service.createChallenge(
                title: title,
                description: description,
                type: selectedType,
                difficulty: selectedDifficulty,
                duration: duration,
                tasks: tasks
            )
            
            await MainActor.run {
                alertMessage = "✅ 挑战\"\(challenge.title)\"创建成功！"
                showingAlert = true
                
                // 延迟关闭
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                alertMessage = "❌ 创建失败：\(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultTasks(for type: DreamChallengeType, difficulty: ChallengeDifficulty) -> [ChallengeTask] {
        var tasks: [ChallengeTask] = []
        let pointsMultiplier = difficulty.pointsMultiplier
        
        switch type {
        case .recall:
            tasks = [
                ChallengeTask(
                    type: .recordDream,
                    title: "记录梦境",
                    description: "每天醒来后记录至少一个梦境",
                    targetCount: duration,
                    points: Int(10 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .dreamRecall,
                    title: "回忆练习",
                    description: "睡前进行 5 分钟回忆练习",
                    targetCount: Int(Double(duration) * 0.8),
                    points: Int(15 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .creativeWriting,
                    title: "梦境写作",
                    description: "选择一个梦境进行详细描写",
                    targetCount: Int(Double(duration) * 0.3),
                    points: Int(20 * pointsMultiplier)
                )
            ]
            
        case .lucid:
            tasks = [
                ChallengeTask(
                    type: .realityCheck,
                    title: "现实检查",
                    description: "每天进行至少 5 次现实检查",
                    targetCount: duration * 5,
                    points: Int(8 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .meditation,
                    title: "冥想练习",
                    description: "睡前进行 10 分钟冥想",
                    targetCount: Int(Double(duration) * 0.7),
                    points: Int(15 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .achieveLucid,
                    title: "清醒梦体验",
                    description: "至少体验一次清醒梦",
                    targetCount: 1,
                    points: Int(50 * pointsMultiplier)
                )
            ]
            
        case .theme:
            tasks = [
                ChallengeTask(
                    type: .recordDream,
                    title: "主题梦境记录",
                    description: "记录与主题相关的梦境",
                    targetCount: Int(Double(duration) * 0.6),
                    points: Int(12 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .meditation,
                    title: "主题冥想",
                    description: "睡前冥想主题相关内容",
                    targetCount: Int(Double(duration) * 0.5),
                    points: Int(15 * pointsMultiplier)
                )
            ]
            
        case .creative:
            tasks = [
                ChallengeTask(
                    type: .recordDream,
                    title: "创意梦境记录",
                    description: "记录富有创意的梦境",
                    targetCount: Int(Double(duration) * 0.5),
                    points: Int(15 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .creativeWriting,
                    title: "创意写作",
                    description: "基于梦境进行创意写作",
                    targetCount: Int(Double(duration) * 0.4),
                    points: Int(25 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .shareDream,
                    title: "分享灵感",
                    description: "分享梦境中的创意想法",
                    targetCount: Int(Double(duration) * 0.2),
                    points: Int(20 * pointsMultiplier)
                )
            ]
            
        case .mindfulness:
            tasks = [
                ChallengeTask(
                    type: .meditation,
                    title: "正念冥想",
                    description: "每天进行正念冥想",
                    targetCount: duration,
                    points: Int(12 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .sleepSchedule,
                    title: "规律作息",
                    description: "保持固定的睡眠时间",
                    targetCount: Int(Double(duration) * 0.8),
                    points: Int(15 * pointsMultiplier)
                ),
                ChallengeTask(
                    type: .recordDream,
                    title: "梦境记录",
                    description: "记录梦境中的感受",
                    targetCount: Int(Double(duration) * 0.7),
                    points: Int(10 * pointsMultiplier)
                )
            ]
            
        case .streak:
            tasks = [
                ChallengeTask(
                    type: .recordDream,
                    title: "连续记录",
                    description: "每天记录至少一个梦境",
                    targetCount: duration,
                    points: Int(20 * pointsMultiplier)
                )
            ]
        }
        
        return tasks
    }
}

// MARK: - 预览

#Preview {
    DreamChallengeView()
        .modelContainer(for: [DreamChallenge.self, ChallengeTask.self, ChallengeBadge.self])
}
