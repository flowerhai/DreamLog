//
//  DreamMeditationView.swift
//  DreamLog
//
//  Phase 65: 梦境冥想与放松增强
//  冥想主界面
//

import SwiftUI
import SwiftData

// MARK: - 冥想主页

struct DreamMeditationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var service: DreamMeditationService?
    @State private var selectedCategory: MeditationCategory?
    @State private var showingPlayer = false
    @State private var selectedTemplate: MeditationTemplate?
    @State private var stats: MeditationStats = .empty
    @State private var preferences: MeditationPreference?
    
    @Query(sort: \MeditationTemplate.usageCount, order: .reverse)
    private var popularTemplates: [MeditationTemplate]
    
    @Query(sort: \MeditationSession.createdAt, order: .reverse)
    private var recentSessions: [MeditationSession]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部统计
                    statsHeader
                    
                    // 快速开始
                    quickStartSection
                    
                    // 今日推荐
                    recommendationSection
                    
                    // 分类浏览
                    categorySection
                    
                    // 最近练习
                    recentSection
                    
                    // 热门冥想
                    popularSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("🧘 梦境冥想")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DreamMeditationStatsView()) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .task {
                service = DreamMeditationService(modelContext: modelContext)
                await loadStats()
                await loadPreferences()
            }
            .sheet(isPresented: $showingPlayer) {
                if let template = selectedTemplate {
                    DreamMeditationPlayerView(
                        template: template,
                        service: service
                    )
                }
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续练习")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(stats.currentStreak) 天")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("总时长")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(stats.totalDurationFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundStyle(.white)
        }
    }
    
    // MARK: - Quick Start
    
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速开始")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickStartCard(
                    title: "睡前放松",
                    icon: "moon.stars",
                    duration: "10 分钟",
                    color: .indigo
                ) {
                    startQuickMeditation(type: .bodyScan, duration: 600)
                }
                
                QuickStartCard(
                    title: "晨间唤醒",
                    icon: "sunrise",
                    duration: "5 分钟",
                    color: .orange
                ) {
                    startQuickMeditation(type: .morningWake, duration: 300)
                }
            }
        }
    }
    
    // MARK: - Recommendation Section
    
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日推荐")
                    .font(.headline)
                
                Spacer()
                
                Button("换一批") {
                    // TODO: 刷新推荐
                }
                .font(.caption)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getRecommendedTemplates(), id: \.id) { template in
                        MeditationTemplateCard(
                            template: template,
                            onTap: {
                                selectedTemplate = template
                                showingPlayer = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类浏览")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MeditationCategory.allCases, id: \.rawValue) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            withAnimation {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    )
                }
            }
            
            // 展开的类型列表
            if let selectedCategory = selectedCategory {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(getTemplates(for: selectedCategory), id: \.id) { template in
                        MeditationTypeCard(template: template) {
                            selectedTemplate = template
                            showingPlayer = true
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Recent Section
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近练习")
                .font(.headline)
            
            if recentSessions.isEmpty {
                Text("还没有练习记录")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(recentSessions.prefix(3), id: \.id) { session in
                    RecentSessionRow(session: session) {
                        // 重新开始
                        if let type = session.meditationType {
                            startQuickMeditation(type: type, duration: session.duration)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Popular Section
    
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("热门冥想")
                .font(.headline)
            
            ForEach(popularTemplates.prefix(5), id: \.id) { template in
                PopularMeditationRow(
                    template: template,
                    onTap: {
                        selectedTemplate = template
                        showingPlayer = true
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadStats() async {
        if let service = service {
            stats = service.getMeditationStats()
        }
    }
    
    private func loadPreferences() async {
        if let service = service {
            preferences = service.getPreference()
        }
    }
    
    private func getRecommendedTemplates() -> [MeditationTemplate] {
        guard let service = service else { return [] }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        if hour >= 5 && hour < 12 {
            timeOfDay = "morning"
        } else if hour >= 12 && hour < 17 {
            timeOfDay = "afternoon"
        } else if hour >= 17 && hour < 22 {
            timeOfDay = "evening"
        } else {
            timeOfDay = "night"
        }
        
        let config = MeditationRecommendationConfig(timeOfDay: timeOfDay)
        return service.getRecommendedTemplates(config: config)
    }
    
    private func getTemplates(for category: MeditationCategory) -> [MeditationTemplate] {
        service?.getTemplates(category: category) ?? []
    }
    
    private func startQuickMeditation(type: MeditationType, duration: TimeInterval) {
        // 创建临时模板并开始播放
        let template = MeditationTemplate(
            name: type.displayName,
            type: type,
            category: type.category,
            duration: duration,
            script: "",
            description: "快速冥想练习"
        )
        selectedTemplate = template
        showingPlayer = true
    }
}

// MARK: - Quick Start Card

struct QuickStartCard: View {
    let title: String
    let icon: String
    let duration: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white)
                
                Text(duration)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: MeditationCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple : Color(.systemBackground))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Meditation Template Card

struct MeditationTemplateCard: View {
    let template: MeditationTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 缩略图
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                    
                    Image(systemName: template.meditationType?.icon ?? "sparkles")
                        .font(.title)
                        .foregroundStyle(.purple)
                }
                
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(template.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "play.circle")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4)
        }
        .frame(width: 140)
    }
}

// MARK: - Meditation Type Card

struct MeditationTypeCard: View {
    let template: MeditationTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: template.meditationType?.icon ?? "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)
                    .frame(width: 44, height: 44)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(template.durationFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let difficulty = template.meditationDifficulty {
                            Image(systemName: difficulty.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: MeditationSession
    let onRestart: () -> Void
    
    var body: some View {
        Button(action: onRestart) {
            HStack(spacing: 12) {
                Image(systemName: session.meditationType?.icon ?? "sparkles")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.meditationType?.displayName ?? "冥想")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(session.createdAt.relativeTimeFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Popular Meditation Row

struct PopularMeditationRow: View {
    let template: MeditationTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: template.meditationType?.icon ?? "sparkles")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 44, height: 44)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(template.durationFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("·")
                            .foregroundStyle(.secondary)
                        
                        Text("\(template.usageCount) 次")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Extensions

extension MeditationStats {
    var totalDurationFormatted: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

extension MeditationTemplate {
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        return "\(minutes)分钟"
    }
}

extension Date {
    var relativeTimeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    DreamMeditationView()
        .modelContainer(for: [
            MeditationSession.self,
            MeditationTemplate.self,
            MeditationPreference.self,
            MeditationAchievement.self
        ], inMemory: true)
}
