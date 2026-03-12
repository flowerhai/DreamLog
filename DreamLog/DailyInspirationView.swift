//
//  DailyInspirationView.swift
//  DreamLog - Phase 23: Dream Inspiration & Creative Prompts
//
//  每日灵感界面 - 展示每日灵感语录和提示
//

import SwiftUI
import SwiftData

// MARK: - 每日灵感主界面

struct DailyInspirationView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var service = DreamInspirationService.shared
    
    @Query(sort: \DailyInspiration.date, order: .reverse)
    private var inspirations: [DailyInspiration]
    
    @State private var showingHistory = false
    @State private var selectedInspiration: DailyInspiration?
    
    var todayInspiration: DailyInspiration? {
        let today = Calendar.current.startOfDay(for: Date())
        return inspirations.first {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 今日灵感卡片
                    if let inspiration = todayInspiration {
                        TodayInspirationCard(inspiration: inspiration)
                    } else {
                        GenerateTodayCard()
                    }
                    
                    // 创意挑战
                    ActiveChallengesSection()
                    
                    // 推荐提示
                    RecommendedPromptsSection()
                    
                    // 历史灵感
                    HistorySection(showingHistory: $showingHistory)
                }
                .padding()
            }
            .navigationTitle("📅 每日灵感")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock")
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                InspirationHistoryView()
            }
        }
    }
}

// MARK: - 今日灵感卡片

struct TodayInspirationCard: View {
    let inspiration: DailyInspiration
    @State private var isSaved = false
    @State private var showingShare = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日灵感")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                    Text(inspiration.theme)
                        .font(.title2.bold())
                }
                
                Spacer()
                
                Button(action: {
                    isSaved.toggle()
                }) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundColor(isSaved ? .purple : .gray)
                }
            }
            
            Divider()
            
            // 语录
            VStack(spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.title)
                    .foregroundColor(.purple.opacity(0.5))
                
                Text(inspiration.quote)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Image(systemName: "quote.closing")
                    .font(.title)
                    .foregroundColor(.purple.opacity(0.5))
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            
            // 今日提示
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("今日创意提示")
                        .font(.headline)
                }
                
                Text(inspiration.prompt)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: { showingShare = true }) {
                    Label("分享", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                }
                
                Button(action: { }) {
                    Label("生成提示", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .sheet(isPresented: $showingShare) {
            ShareSheet(items: [inspiration.quote, inspiration.prompt])
        }
    }
}

// MARK: - 生成今日卡片

struct GenerateTodayCard: View {
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("今日灵感尚未生成")
                .font(.headline)
            
            Text("点击生成属于你的每日灵感")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                isGenerating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    let inspiration = DreamInspirationService.shared.generateDailyInspiration()
                    DreamInspirationService.shared.saveDailyInspiration(inspiration)
                    isGenerating = false
                }
            }) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isGenerating ? "生成中..." : "生成今日灵感")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isGenerating)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - 活跃挑战

struct ActiveChallengesSection: View {
    @ObservedObject private var service = DreamInspirationService.shared
    @State private var challenges: [CreativeChallenge] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                Text("进行中挑战")
                    .font(.headline)
                Spacer()
                Button("查看全部") { }
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
            
            if challenges.isEmpty {
                Text("暂无进行中的挑战")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(challenges) { challenge in
                    ChallengeCard(challenge: challenge)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .task {
            challenges = service.fetchActiveChallenges()
        }
    }
}

// MARK: - 挑战卡片

struct ChallengeCard: View {
    let challenge: CreativeChallenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(challenge.badge)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.name)
                        .font(.headline)
                    Text("剩余 \(challenge.duration) 天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(challenge.progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.purple)
            }
            
            ProgressView(value: challenge.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
            
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 推荐提示

struct RecommendedPromptsSection: View {
    @Query(sort: \CreativePrompt.createdAt, order: .reverse, fetchLimit: 3)
    private var recentPrompts: [CreativePrompt]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("推荐提示")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(recentPrompts) { prompt in
                MiniPromptCard(prompt: prompt)
            }
            
            if recentPrompts.isEmpty {
                Text("还没有创意提示")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct MiniPromptCard: View {
    let prompt: CreativePrompt
    
    var body: some View {
        HStack(spacing: 12) {
            Text(prompt.inspirationType.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.title)
                    .font(.subheadline.bold())
                Text("\(prompt.estimatedTime) 分钟 · \(prompt.inspirationType.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if prompt.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 历史部分

struct HistorySection: View {
    @Binding var showingHistory: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("历史灵感")
                    .font(.headline)
                Spacer()
                Button("查看全部") {
                    showingHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            
            Text("查看过往的每日灵感和创意提示")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - 历史界面

struct InspirationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DailyInspiration.date, order: .reverse)
    private var inspirations: [DailyInspiration]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(inspirations) { inspiration in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(inspiration.theme)
                            .font(.headline)
                        Text(inspiration.quote)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Text(inspiration.date.formatted(date: .long, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("历史灵感")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 分享

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DailyInspirationView()
        .modelContainer(for: [CreativePrompt.self, DailyInspiration.self, CreativeChallenge.self])
}
