//
//  DreamsGoalView.swift
//  DreamLog
//
//  梦境目标 - 追踪记录习惯
//

import SwiftUI

struct DreamsGoalView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @AppStorage("weeklyGoal") private var weeklyGoal = 5
    @AppStorage("streakCount") private var streakCount = 0
    @AppStorage("lastRecordDate") private var lastRecordDate = ""
    
    @State private var showingGoalSettings = false
    
    var weeklyProgress: Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let dreamsThisWeek = dreamStore.dreams.filter { $0.date >= startOfWeek }.count
        return min(Double(dreamsThisWeek) / Double(weeklyGoal), 1.0)
    }
    
    var dreamsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return dreamStore.dreams.filter { $0.date >= startOfWeek }.count
    }
    
    var currentStreak: Int {
        calculateStreak()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 本周目标进度
                    WeeklyGoalCard(
                        progress: weeklyProgress,
                        current: dreamsThisWeek,
                        goal: weeklyGoal,
                        onEdit: { showingGoalSettings = true }
                    )
                    
                    // 连续记录
                    StreakCard(streak: currentStreak)
                    
                    // 成就徽章
                    AchievementsSection()
                    
                    // 统计概览
                    StatsSummarySection()
                    
                    // 激励语录
                    MotivationQuoteCard()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("梦境目标 🎯")
            .sheet(isPresented: $showingGoalSettings) {
                GoalSettingsView(weeklyGoal: $weeklyGoal)
            }
        }
        .onAppear {
            updateStreak()
        }
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // 检查今天是否已记录
        let hasRecordedToday = dreamStore.dreams.contains { dream in
            calendar.isDate(dream.date, inSameDayAs: today)
        }
        
        if !hasRecordedToday {
            // 检查是否是昨天记录的
            if let lastDate = DateFormatter.yyyyMMdd.date(from: lastRecordDate) {
                if calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? Date()) {
                    return streakCount
                } else if !calendar.isDate(lastDate, inSameDayAs: today) {
                    return 0
                }
            }
            return streakCount
        }
        
        return streakCount
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = Date()
        
        // 检查今天是否已记录
        let hasRecordedToday = dreamStore.dreams.contains { dream in
            calendar.isDate(dream.date, inSameDayAs: today)
        }
        
        if hasRecordedToday && lastRecordDate.isEmpty {
            // 第一次记录
            streakCount = 1
            lastRecordDate = DateFormatter.yyyyMMdd.string(from: today)
        } else if hasRecordedToday, let lastDate = DateFormatter.yyyyMMdd.date(from: lastRecordDate) {
            // 检查连续天数
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? Date()
            if calendar.isDate(lastDate, inSameDayAs: yesterday) || calendar.isDate(lastDate, inSameDayAs: today) {
                if !calendar.isDate(lastDate, inSameDayAs: today) {
                    streakCount += 1
                    lastRecordDate = DateFormatter.yyyyMMdd.string(from: today)
                }
            } else if !calendar.isDate(lastDate, inSameDayAs: today) {
                streakCount = 1
                lastRecordDate = DateFormatter.yyyyMMdd.string(from: today)
            }
        }
    }
}

// MARK: - 本周目标卡片
struct WeeklyGoalCard: View {
    let progress: Double
    let current: Int
    let goal: Int
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本周目标")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(current)/\(goal) 个梦境")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6B4E9A"), Color(hex: "9B7EBD")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 12)
            
            // 进度百分比
            HStack {
                Text(progress >= 1.0 ? "🎉 目标达成!" : "加油！")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 连续记录卡片
struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        HStack(spacing: 20) {
            // 火焰图标
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FF4500")],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("连续记录")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("\(streak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("天")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 成就徽章
struct AchievementsSection: View {
    let achievements: [Achievement] = [
        Achievement(icon: "🌟", title: "初次记录", description: "记录第一个梦境", unlocked: true),
        Achievement(icon: "🔥", title: "持之以恒", description: "连续记录 7 天", unlocked: true),
        Achievement(icon: "🎯", title: "目标达成", description: "完成周目标", unlocked: true),
        Achievement(icon: "📚", title: "梦境大师", description: "记录 100 个梦境", unlocked: false),
        Achievement(icon: "✨", title: "清醒梦者", description: "记录 10 个清醒梦", unlocked: false),
        Achievement(icon: "🌙", title: "月常记录", description: "连续记录 30 天", unlocked: false),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成就徽章")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(achievements, id: \.title) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Text(achievement.icon)
                .font(.system(size: 32))
                .opacity(achievement.unlocked ? 1.0 : 0.3)
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(achievement.unlocked ? .white : .secondary)
                .lineLimit(1)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .opacity(0.7)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.unlocked ? Color.white.opacity(0.1) : Color.clear)
        )
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let unlocked: Bool
}

// MARK: - 统计概览
struct StatsSummarySection: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var stats: DreamStatistics {
        dreamStore.getStatistics()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("统计概览")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                GoalsStatItem(icon: "🌙", value: "\(stats.totalDreams)", label: "总梦境")
                GoalsStatItem(icon: "✨", value: "\(stats.lucidDreams)", label: "清醒梦")
                GoalsStatItem(icon: "⭐", value: String(format: "%.1f", stats.averageClarity), label: "平均清晰")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct GoalsStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 激励语录
struct MotivationQuoteCard: View {
    let quotes: [Quote] = [
        Quote(text: "梦境是潜意识的语言，记录它们是了解自己的开始。", author: "卡尔·荣格"),
        Quote(text: "每个梦都是一扇门，通往你内心深处的秘密花园。", author: "DreamLog"),
        Quote(text: "清醒梦不是逃避现实，而是探索自我的另一种方式。", author: "史蒂芬·拉伯格"),
    ]
    
    @State private var currentQuote = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            Text(quotes[currentQuote].text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("— \(quotes[currentQuote].author)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 切换按钮
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        currentQuote = (currentQuote - 1 + quotes.count) % quotes.count
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.secondary)
                }
                
                ForEach(0..<quotes.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentQuote ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                
                Button(action: {
                    withAnimation {
                        currentQuote = (currentQuote + 1) % quotes.count
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct Quote {
    let text: String
    let author: String
}

// MARK: - 目标设置
struct GoalSettingsView: View {
    @Binding var weeklyGoal: Int
    @Environment(\.dismiss) var dismiss
    
    let goals = [3, 5, 7, 10, 14]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(goals, id: \.self) { goal in
                        Button(action: {
                            weeklyGoal = goal
                            dismiss()
                        }) {
                            HStack {
                                Text("每周 \(goal) 个梦境")
                                    .font(.body)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if weeklyGoal == goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(weeklyGoal == goal ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.05))
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 建议")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("从较小的目标开始，逐渐增加记录频率。关键是保持连续性，而不是追求数量。")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .padding()
            }
            .navigationTitle("设置周目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 日期格式化
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

#Preview {
    DreamsGoalView()
        .environmentObject(DreamStore())
}
