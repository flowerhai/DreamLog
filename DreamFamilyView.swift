//
//  DreamFamilyView.swift
//  DreamLog - Family Sharing UI
//  Phase 96: Family Sharing 👨‍👩‍👧‍👦✨
//
//  Created on 2026-03-23
//

import SwiftUI

// MARK: - Main Family View

public struct DreamFamilyView: View {
    @StateObject private var viewModel: FamilyViewModel
    @State private var selectedTab = 0
    @State private var showingCreateFamily = false
    @State private var showingJoinFamily = false
    @State private var inviteCode = ""
    
    public init(userId: UUID) {
        _viewModel = StateObject(wrappedValue: FamilyViewModel(userId: userId))
    }
    
    public var body: some View {
        Group {
            if viewModel.families.isEmpty {
                emptyStateView
            } else {
                mainView
            }
        }
        .sheet(isPresented: $showingCreateFamily) {
            CreateFamilyView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingJoinFamily) {
            JoinFamilyView(viewModel: viewModel, inviteCode: $inviteCode)
        }
        .task {
            await viewModel.loadFamilies()
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text("创建或加入家庭组")
                .font(.title)
                .fontWeight(.bold)
            
            Text("与家人分享梦境，发现家族共同的梦境模式")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 15) {
                Button(action: { showingCreateFamily = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("创建家庭组")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                
                Button(action: { showingJoinFamily = true }) {
                    HStack {
                        Image(systemName: "arrow.down.right.square.fill")
                        Text("加入家庭组")
                    }
                    .font(.headline)
                    .foregroundColor(.purple)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private var mainView: some View {
        TabView(selection: $selectedTab) {
            FamilyOverviewView(viewModel: viewModel)
                .tabItem {
                    Label("概览", systemImage: "house.fill")
                }
                .tag(0)
            
            FamilySharedDreamsView(viewModel: viewModel)
                .tabItem {
                    Label("共享梦境", systemImage: "book.fill")
                }
                .tag(1)
            
            FamilyPatternsView(viewModel: viewModel)
                .tabItem {
                    Label("家族模式", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            FamilyChallengesView(viewModel: viewModel)
                .tabItem {
                    Label("家庭挑战", systemImage: "trophy.fill")
                }
                .tag(3)
            
            FamilySettingsView(viewModel: viewModel)
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if let family = viewModel.selectedFamily {
                    Text(family.name)
                        .font(.headline)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingCreateFamily = true }) {
                        Label("创建新家庭", systemImage: "plus.circle")
                    }
                    
                    Button(action: { showingJoinFamily = true }) {
                        Label("加入其他家庭", systemImage: "arrow.down.right.square")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - Family Overview View

struct FamilyOverviewView: View {
    @ObservedObject var viewModel: FamilyViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let stats = viewModel.selectedFamily?.statistics {
                    statisticsCard(stats: stats)
                }
                
                membersSection
                
                recentActivitySection
                
                achievementsSection
            }
            .padding()
        }
        .navigationTitle("家庭概览")
    }
    
    private func statisticsCard(stats: FamilyStatistics) -> some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("家庭等级")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Lv.\(stats.familyLevel)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("经验值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(stats.familyXP) / \(stats.xpForNextLevel)")
                        .font(.headline)
                }
            }
            
            ProgressView(value: stats.levelProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
            
            HStack(spacing: 20) {
                StatItem(icon: "book.fill", value: "\(stats.totalDreams)", label: "梦境")
                StatItem(icon: "person.2.fill", value: "\(stats.activeMembers)", label: "活跃")
                StatItem(icon: "trophy.fill", value: "\(stats.completedChallenges)", label: "挑战")
                StatItem(icon: "chart.bar.fill", value: "\(stats.discoveredPatterns)", label: "模式")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("家庭成员")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(viewModel.members.count) 人")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.members) { member in
                    MemberCard(member: member)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("最近活动")
                .font(.title3)
                .fontWeight(.bold)
            
            ForEach(viewModel.recentActivities.prefix(5)) { activity in
                ActivityRow(activity: activity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("家庭成就")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.achievements) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Shared Dreams View

struct FamilySharedDreamsView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.sharedDreams.isEmpty {
                    emptyState
                } else {
                    dreamList
                }
            }
            .navigationTitle("共享梦境")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareDreamView(viewModel: viewModel)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无共享梦境")
                .font(.headline)
            
            Text("点击右上角分享你的第一个梦境")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var dreamList: some View {
        List(viewModel.sharedDreams) { dream in
            SharedDreamRow(dream: dream, viewModel: viewModel)
        }
    }
}

// MARK: - Family Patterns View

struct FamilyPatternsView: View {
    @ObservedObject var viewModel: FamilyViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.patterns.isEmpty {
                    emptyState
                } else {
                    ForEach(groupPatternsByType()) { group in
                        PatternSection(type: group.type, patterns: group.patterns)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("家族模式")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await viewModel.analyzePatterns() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无家族模式")
                .font(.headline)
            
            Text("当家庭共享更多梦境后，我们会发现共同的梦境模式")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    private func groupPatternsByType() -> [(type: PatternType, patterns: [FamilyPattern])] {
        Dictionary(grouping: viewModel.patterns, by: { $0.patternType })
            .map { (type: $0.key, patterns: $0.value) }
            .sorted { $0.patterns.count > $1.patterns.count }
    }
}

struct PatternSection: View {
    let type: PatternType
    let patterns: [FamilyPattern]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(type.icon)
                    .font(.title2)
                Text(type.displayName)
                    .font(.headline)
            }
            
            ForEach(patterns) { pattern in
                PatternCard(pattern: pattern)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Family Challenges View

struct FamilyChallengesView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @State private var showingCreateChallenge = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    activeChallengesSection
                    
                    completedChallengesSection
                }
                .padding()
            }
            .navigationTitle("家庭挑战")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateChallenge = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateChallenge) {
                CreateChallengeView(viewModel: viewModel)
            }
        }
    }
    
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("进行中的挑战")
                .font(.headline)
            
            ForEach(viewModel.activeChallenges) { challenge in
                ChallengeCard(challenge: challenge, viewModel: viewModel)
            }
            
            if viewModel.activeChallenges.isEmpty {
                Text("暂无进行中的挑战")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var completedChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已完成的挑战")
                .font(.headline)
            
            ForEach(viewModel.completedChallenges) { challenge in
                ChallengeCard(challenge: challenge, viewModel: viewModel, isCompleted: true)
            }
        }
    }
}

// MARK: - Family Settings View

struct FamilySettingsView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @State private var showingEditFamily = false
    
    var body: some View {
        Form {
            if let family = viewModel.selectedFamily {
                Section(header: Text("家庭信息")) {
                    HStack {
                        Text("家庭名称")
                        Spacer()
                        Text(family.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("邀请码")
                        Spacer()
                        Text(family.inviteCode)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    
                    Button(action: { showingEditFamily = true }) {
                        Text("编辑家庭信息")
                    }
                }
                
                Section(header: Text("隐私设置")) {
                    Toggle("启用内容过滤", isOn: $viewModel.contentFilterEnabled)
                    Toggle("儿童保护模式", isOn: $viewModel.childProtectionMode)
                    
                    Picker("默认隐私级别", selection: $viewModel.defaultPrivacyLevel) {
                        ForEach(PrivacyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
                
                Section(header: Text("通知设置")) {
                    Toggle("新成员加入", isOn: $viewModel.notifyNewMember)
                    Toggle("新梦境分享", isOn: $viewModel.notifyNewDream)
                    Toggle("挑战提醒", isOn: $viewModel.notifyChallenge)
                    Toggle("发现新模式", isOn: $viewModel.notifyPattern)
                }
                
                Section(header: Text("成员管理")) {
                    ForEach(viewModel.members) { member in
                        MemberSettingsRow(member: member, viewModel: viewModel)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        Task { await viewModel.leaveFamily() }
                    } label: {
                        Text("离开家庭")
                    }
                }
            }
        }
        .navigationTitle("家庭设置")
        .sheet(isPresented: $showingEditFamily) {
            EditFamilyView(viewModel: viewModel)
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MemberCard: View {
    let member: FamilyMember
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.nickname)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(member.relationship.icon)
                    Text(member.role.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if member.role == .admin {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let activity: FamilyActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Text(activity.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                Text(activity.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AchievementBadge: View {
    let achievement: FamilyAchievement
    
    var body: some View {
        VStack(spacing: 8) {
            Text(achievement.icon)
                .font(.title)
            Text(achievement.title)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 90)
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SharedDreamRow: View {
    let dream: SharedDream
    @ObservedObject var viewModel: FamilyViewModel
    @State private var showingReactions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dream.title)
                        .font(.headline)
                    Text(dream.ownerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(dream.dreamDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(dream.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if !dream.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(dream.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            HStack(spacing: 20) {
                Button(action: { showingReactions = true }) {
                    HStack {
                        Image(systemName: "heart")
                        Text("\(dream.reactions.count)")
                    }
                    .foregroundColor(.red)
                }
                
                Button {
                    // Add comment
                } label: {
                    HStack {
                        Image(systemName: "message")
                        Text("\(dream.comments.count)")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(dream.privacyLevel.icon)
                    .font(.caption)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct PatternCard: View {
    let pattern: FamilyPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(pattern.patternType.icon)
                    .font(.title2)
                Text(pattern.title)
                    .font(.headline)
                Spacer()
                Text("\(Int(pattern.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(pattern.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "book.fill")
                Text("\(pattern.dreamCount) 个梦境")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                Text("\(pattern.involvedMembers.count) 人")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ChallengeCard: View {
    let challenge: FamilyChallenge
    @ObservedObject var viewModel: FamilyViewModel
    var isCompleted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(challenge.challengeType.icon)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(challenge.title)
                        .font(.headline)
                    Text(challenge.status.displayName)
                        .font(.caption)
                        .foregroundColor(challenge.status == .active ? .green : .secondary)
                }
                Spacer()
            }
            
            Text(challenge.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if challenge.status == .active {
                ProgressView(value: challenge.participationRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                
                HStack {
                    Text("\(challenge.submissions.count)/\(challenge.participants.count) 参与")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("剩余 \(challenge.daysRemaining) 天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - View Models

public class FamilyViewModel: ObservableObject {
    @Published var families: [FamilyGroup] = []
    @Published var selectedFamily: FamilyGroup?
    @Published var members: [FamilyMember] = []
    @Published var sharedDreams: [SharedDream] = []
    @Published var patterns: [FamilyPattern] = []
    @Published var challenges: [FamilyChallenge] = []
    @Published var achievements: [FamilyAchievement] = []
    @Published var recentActivities: [FamilyActivity] = []
    
    @Published var contentFilterEnabled: Bool = true
    @Published var childProtectionMode: Bool = false
    @Published var defaultPrivacyLevel: PrivacyLevel = .family
    @Published var notifyNewMember: Bool = true
    @Published var notifyNewDream: Bool = true
    @Published var notifyChallenge: Bool = true
    @Published var notifyPattern: Bool = true
    
    private var service: DreamFamilyService?
    private let userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
    }
    
    func loadFamilies() async {
        service = DreamFamilyService(currentUserId: userId)
        families = await service?.getUserFamilies() ?? []
        
        if let firstFamily = families.first {
            await selectFamily(firstFamily)
        }
    }
    
    func selectFamily(_ family: FamilyGroup) async {
        selectedFamily = family
        members = await service?.getFamilyMembers(familyId: family.id) ?? []
        sharedDreams = await service?.getFamilyDreams(familyId: family.id) ?? []
        patterns = await service?.getFamilyPatterns(familyId: family.id) ?? []
        challenges = await service?.getFamilyChallenges(familyId: family.id) ?? []
        achievements = await service?.getFamilyAchievements(familyId: family.id) ?? []
    }
    
    func analyzePatterns() async {
        guard let family = selectedFamily else { return }
        patterns = await service?.analyzeFamilyPatterns(familyId: family.id) ?? []
    }
    
    func leaveFamily() async {
        guard let family = selectedFamily else { return }
        try? await service?.leaveFamilyGroup(familyId: family.id)
        await loadFamilies()
    }
    
    var activeChallenges: [FamilyChallenge] {
        challenges.filter { $0.status == .active }
    }
    
    var completedChallenges: [FamilyChallenge] {
        challenges.filter { $0.status == .completed }
    }
}

// MARK: - Supporting Models

struct FamilyActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let time: String
}

// MARK: - Placeholder Views (to be implemented)

struct CreateFamilyView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    @State private var familyName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("家庭信息")) {
                    TextField("家庭名称", text: $familyName)
                }
                
                Section {
                    Button(action: {
                        // Create family
                        dismiss()
                    }) {
                        Text("创建")
                    }
                    .disabled(familyName.isEmpty)
                }
            }
            .navigationTitle("创建家庭")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct JoinFamilyView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @Binding var inviteCode: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("邀请码")) {
                    TextField("输入邀请码", text: $inviteCode)
                        .textCase(.uppercase)
                }
                
                Section {
                    Button(action: {
                        // Join family
                        dismiss()
                    }) {
                        Text("加入")
                    }
                    .disabled(inviteCode.count < 8)
                }
            }
            .navigationTitle("加入家庭")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct ShareDreamView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Text("分享梦境表单（待实现）")
            }
            .navigationTitle("分享梦境")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct CreateChallengeView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Text("创建挑战表单（待实现）")
            }
            .navigationTitle("创建挑战")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct EditFamilyView: View {
    @ObservedObject var viewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Text("编辑家庭信息（待实现）")
            }
            .navigationTitle("编辑家庭")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct MemberSettingsRow: View {
    let member: FamilyMember
    @ObservedObject var viewModel: FamilyViewModel
    
    var body: some View {
        HStack {
            Text(member.nickname)
            Spacer()
            Text(member.role.displayName)
                .foregroundColor(.secondary)
        }
    }
}
