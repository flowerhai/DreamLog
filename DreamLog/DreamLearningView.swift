//
//  DreamLearningView.swift
//  DreamLog - Dream Learning Path Main View
//
//  Phase 82: Dream Learning & Education System
//  Main hub for browsing courses, tracking progress, and viewing achievements
//

import SwiftUI
import SwiftData

struct DreamLearningView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = DreamLearningViewModel()
    
    @State private var selectedCategory: DreamLearningCategory?
    @State private var selectedCourse: DreamLearningCourse?
    @State private var showingProfile = false
    @State private var showingBadges = false
    @State private var searchQuery = ""
    @State private var selectedTab = LearningTab.courses
    
    enum LearningTab {
        case courses
        case myLearning
        case achievements
        case stats
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with stats
                learningHeader
                
                // Tab picker
                tabPicker
                
                // Content based on selected tab
                tabContent
            }
            .navigationTitle("学习中心")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showingBadges = true }) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.amber)
                        }
                        
                        Button(action: { showingProfile = true }) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                LearningProfileView()
            }
            .sheet(isPresented: $showingBadges) {
                BadgesCollectionView()
            }
            .sheet(item: $selectedCourse) { course in
                CourseDetailView(course: course)
            }
        }
        .onAppear {
            service.initialize(modelContext: modelContext)
        }
    }
    
    // MARK: - Header
    
    private var learningHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("欢迎回来")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Level \(service.userLevel)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(service.totalXP) XP")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Level progress
                LevelProgressView(level: service.userLevel, xp: service.totalXP)
                    .frame(width: 80, height: 80)
            }
            .padding()
            
            // Quick stats
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    QuickStatCard(
                        icon: "📚",
                        value: "\(service.coursesCompleted)",
                        label: "已完成课程"
                    )
                    
                    QuickStatCard(
                        icon: "📖",
                        value: "\(service.lessonsCompleted)",
                        label: "已完成课时"
                    )
                    
                    QuickStatCard(
                        icon: "🔥",
                        value: "\(service.currentStreak)",
                        label: "连续学习"
                    )
                    
                    QuickStatCard(
                        icon: "⏱️",
                        value: "\(service.totalLearningTime / 60)h",
                        label: "学习时长"
                    )
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Tab Picker
    
    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            Text("课程").tag(LearningTab.courses)
            Text("我的学习").tag(LearningTab.myLearning)
            Text("成就").tag(LearningTab.achievements)
            Text("统计").tag(LearningTab.stats)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .courses:
            coursesTab
        case .myLearning:
            myLearningTab
        case .achievements:
            achievementsTab
        case .stats:
            statsTab
        }
    }
    
    private var coursesTab: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索课程...", text: $searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "全部",
                        icon: "📚",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(DreamLearningCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Course list
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let recommended = service.recommendedCourses.prefix(3).first {
                        Section {
                            Text("推荐课程")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            CourseCard(course: recommended) {
                                selectedCourse = recommended
                            }
                        }
                    }
                    
                    Section {
                        Text("所有课程")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(filteredCourses) { course in
                            CourseCard(course: course) {
                                selectedCourse = course
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    private var myLearningTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if service.inProgressCourses.isEmpty {
                    EmptyStateView(
                        icon: "📚",
                        title: "还没有开始学习",
                        subtitle: "浏览课程并开始你的学习之旅吧！"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(service.inProgressCourses, id: \.id) { enrollment in
                        if let course = enrollment.course {
                            InProgressCourseCard(enrollment: enrollment, course: course) {
                                selectedCourse = course
                            }
                        }
                    }
                }
                
                if !service.completedCourses.isEmpty {
                    Section {
                        Text("已完成的课程")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(service.completedCourses, id: \.id) { enrollment in
                            if let course = enrollment.course {
                                CompletedCourseCard(enrollment: enrollment, course: course) {
                                    selectedCourse = course
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var achievementsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Earned badges section
                Section {
                    HStack {
                        Text("已获得的徽章")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(service.earnedBadges.count)/\(DreamLearningBadge.allCases.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(service.earnedBadges, id: \.self) { badge in
                            BadgeCard(badge: badge, size: .medium)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Locked badges section
                Section {
                    Text("待解锁徽章")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(service.lockedBadges, id: \.self) { badge in
                            BadgeCard(badge: badge, size: .medium, isLocked: true)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var statsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall stats
                LearningStatsCard(stats: service.learningStats)
                
                // Category distribution
                CategoryDistributionChart(distribution: service.categoryDistribution)
                
                // Learning activity
                LearningActivityChart()
                
                // Recent activity
                RecentActivityList()
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Helper Properties
    
    private var filteredCourses: [DreamLearningCourse] {
        var courses = service.allCourses
        
        if let category = selectedCategory {
            courses = courses.filter { $0.categoryEnum == category }
        }
        
        if !searchQuery.isEmpty {
            courses = courses.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.description.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        return courses
    }
}

// MARK: - Supporting Views

struct LevelProgressView: View {
    let level: Int
    let xp: Int
    
    private var progressToNextLevel: Double {
        let currentLevelXP = (level - 1) * (level - 1) * 100
        let nextLevelXP = level * level * 100
        let xpInCurrentLevel = Double(xp - currentLevelXP)
        let xpNeeded = Double(nextLevelXP - currentLevelXP)
        return min(xpInCurrentLevel / xpNeeded, 1.0)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progressToNextLevel)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progressToNextLevel)
            
            VStack {
                Text("L\(level)")
                    .font(.system(size: 16, weight: .bold))
                Text("级")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 90)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct CourseCard: View {
    let course: DreamLearningCourse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(gradientForCategory(course.categoryEnum))
                        .frame(height: 120)
                    
                    // Difficulty badge
                    HStack {
                        Text(course.difficultyEnum.icon)
                        Text(course.difficultyEnum.displayName)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .padding(8)
                }
                .cornerRadius(12)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(course.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(course.lessonCount) 课时", systemImage: "book.fill")
                        Label("\(course.estimatedHours, specifier: "%.1f") 小时", systemImage: "clock.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    private func gradientForCategory(_ category: DreamLearningCategory) -> LinearGradient {
        let colors: [Color]
        switch category {
        case .lucidDreaming:
            colors = [.purple, .indigo]
        case .dreamInterpretation:
            colors = [.indigo, .blue]
        case .dreamRecall:
            colors = [.blue, .cyan]
        case .mindfulness:
            colors = [.green, .teal]
        case .creativity:
            colors = [.orange, .yellow]
        case .sleepScience:
            colors = [.cyan, .blue]
        case .wellness:
            colors = [.pink, .rose]
        }
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct InProgressCourseCard: View {
    let enrollment: DreamLearningEnrollment
    let course: DreamLearningCourse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(gradientForCategory(course.categoryEnum))
                        .frame(width: 60, height: 60)
                    
                    Text(course.categoryEnum.icon)
                        .font(.title2)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: geo.size.width * enrollment.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(Int(enrollment.progress * 100))% 完成")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    private func gradientForCategory(_ category: DreamLearningCategory) -> LinearGradient {
        let colors: [Color]
        switch category {
        case .lucidDreaming: colors = [.purple, .indigo]
        case .dreamInterpretation: colors = [.indigo, .blue]
        case .dreamRecall: colors = [.blue, .cyan]
        case .mindfulness: colors = [.green, .teal]
        case .creativity: colors = [.orange, .yellow]
        case .sleepScience: colors = [.cyan, .blue]
        case .wellness: colors = [.pink, .rose]
        }
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct CompletedCourseCard: View {
    let enrollment: DreamLearningEnrollment
    let course: DreamLearningCourse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline)
                        .strikethrough()
                    
                    if let completedAt = enrollment.completedAt {
                        Text("完成于 \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .opacity(0.7)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

struct BadgeCard: View {
    let badge: DreamLearningBadge
    let size: BadgeSize
    let isLocked: Bool
    
    enum BadgeSize {
        case small, medium, large
    }
    
    init(badge: DreamLearningBadge, size: BadgeSize = .medium, isLocked: Bool = false) {
        self.badge = badge
        self.size = size
        self.isLocked = isLocked
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isLocked ? Color.gray.opacity(0.2) : Color.amber.opacity(0.2))
                    .frame(size: sizeDimension)
                
                Text(badge.icon)
                    .font(.system(size: sizeIconDimension))
                    .opacity(isLocked ? 0.3 : 1.0)
            }
            
            Text(badge.displayName)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: sizeDimension)
    }
    
    private var sizeDimension: CGFloat {
        switch size {
        case .small: return 50
        case .medium: return 70
        case .large: return 100
        }
    }
    
    private var sizeIconDimension: CGFloat {
        switch size {
        case .small: return 24
        case .medium: return 32
        case .large: return 48
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 60))
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - ViewModel

@MainActor
class DreamLearningViewModel: ObservableObject {
    @Published var allCourses: [DreamLearningCourse] = []
    @Published var recommendedCourses: [DreamLearningCourse] = []
    @Published var inProgressCourses: [DreamLearningEnrollment] = []
    @Published var completedCourses: [DreamLearningEnrollment] = []
    @Published var earnedBadges: [DreamLearningBadge] = []
    @Published var lockedBadges: [DreamLearningBadge] = []
    @Published var categoryDistribution: [String: Int] = [:]
    
    @Published var totalXP: Int = 0
    @Published var userLevel: Int = 1
    @Published var coursesCompleted: Int = 0
    @Published var lessonsCompleted: Int = 0
    @Published var currentStreak: Int = 0
    @Published var totalLearningTime: Int = 0
    
    var learningStats: DreamLearningStats {
        DreamLearningStats(
            totalEnrollments: inProgressCourses.count + completedCourses.count,
            activeLearners: 1,
            averageCompletionRate: 0.5,
            totalLessonsCompleted: lessonsCompleted,
            totalXPEarned: totalXP,
            popularCourses: [],
            categoryDistribution: categoryDistribution
        )
    }
    
    private var modelContext: ModelContext?
    private let service = DreamLearningService.shared
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        service.initialize(modelContext: modelContext)
        loadAllData()
    }
    
    func loadAllData() {
        Task {
            allCourses = await service.getAllCourses()
            recommendedCourses = await service.getRecommendedCourses()
            
            let enrollments = await service.getUserEnrollments()
            inProgressCourses = enrollments.filter { !$0.isCompleted }
            completedCourses = enrollments.filter { $0.isCompleted }
            
            earnedBadges = await service.getEarnedBadges()
            let allBadges = await service.getAvailableBadges()
            lockedBadges = allBadges.filter { !$0.earned }.map { $0.badge }
            
            let profile = await service.getUserProfile()
            totalXP = profile.totalXP
            userLevel = profile.level
            coursesCompleted = profile.coursesCompleted
            lessonsCompleted = profile.lessonsCompleted
            currentStreak = profile.currentStreak
            totalLearningTime = profile.totalLearningTime
            
            let stats = await service.getLearningStats()
            categoryDistribution = stats.categoryDistribution
        }
    }
}

// MARK: - Preview

#Preview {
    DreamLearningView()
        .modelContainer(for: DreamLearningCourse.self, inMemory: true)
}
