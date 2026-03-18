//
//  DreamYearInReviewView.swift
//  DreamLog - 梦境年度回顾 UI 界面
//  Phase 63: Dream Year in Review (梦境年度回顾)
//
//  Created by DreamLog Team on 2026-03-18.
//

import SwiftUI
import SwiftData

// MARK: - 主界面

struct DreamYearInReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamYearInReview.year, order: .reverse) private var reviews: [DreamYearInReview]
    @State private var selectedYear: Int?
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Group {
                if reviews.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("年度回顾")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: generateCurrentYearReview) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(isGenerating)
                }
            }
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("还没有年度回顾")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("生成你的梦境年度总结，\n回顾这一年的梦境之旅")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: generateCurrentYearReview) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("生成年度回顾")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .disabled(isGenerating)
            
            if isGenerating {
                ProgressView("正在生成...")
                    .padding(.top)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 内容视图
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 年份选择器
                yearSelector
                
                // 当前选中的年度回顾
                if let selectedYear = selectedYear ?? reviews.first?.year,
                   let review = reviews.first(where: { $0.year == selectedYear }) {
                    reviewContent(review)
                }
                
                // 历史回顾列表
                if reviews.count > 1 {
                    historySection
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 年份选择器
    
    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(reviews, id: \.year) { review in
                    Button(action: { selectedYear = review.year }) {
                        Text("\(review.year)年")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                selectedYear == review.year
                                ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedYear == review.year
                                ? .white
                                : .primary
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // MARK: - 回顾内容
    
    @ViewBuilder
    private func reviewContent(_ review: DreamYearInReview) -> some View {
        // 头部卡片
        headerCard(review)
        
        // 统计网格
        statsGrid(review)
        
        // 情绪分布
        emotionSection(review)
        
        // 热门标签
        tagsSection(review)
        
        // AI 洞察
        insightsSection(review)
        
        // 分享卡片
        shareCardsSection(review)
    }
    
    // MARK: - 头部卡片
    
    private func headerCard(_ review: DreamYearInReview) -> some View {
        VStack(spacing: 12) {
            Text("\(review.year) 年度梦境回顾")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Label("\(review.totalDreams)个梦境", systemImage: "moon.fill")
                Spacer()
                Label("\(review.lucidDreams)个清醒梦", systemImage: "eye.fill")
                Spacer()
                Label("\(review.longestStreak)天连续", systemImage: "flame.fill")
            }
            .font(.caption)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("年度主题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(review.yearTheme)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("关键词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(review.yearKeyword)
                        .font(.headline)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
    }
    
    // MARK: - 统计网格
    
    private func statsGrid(_ review: DreamYearInReview) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "moon.fill",
                value: "\(review.totalDreams)",
                label: "总梦境数",
                color: .purple
            )
            
            StatCard(
                icon: "eye.fill",
                value: "\(review.lucidDreams)",
                label: "清醒梦",
                color: .blue
            )
            
            StatCard(
                icon: "star.fill",
                value: String(format: "%.1f", review.averageClarity),
                label: "平均清晰度",
                color: .orange
            )
            
            StatCard(
                icon: "flame.fill",
                value: "\(review.longestStreak)",
                label: "最长连续",
                color: .red
            )
        }
    }
    
    // MARK: - 情绪分布
    
    private func emotionSection(_ review: DreamYearInReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("情绪分布")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(review.emotionDistribution.sorted { $0.value > $1.value }.prefix(5), id: \.key) { emotion, count in
                    let percentage = Double(count) / Double(review.emotionDistribution.values.reduce(0, +)) * 100
                    HStack {
                        Text(emotion)
                            .font(.subheadline)
                            .frame(width: 60, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray4))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(percentage) / 100)
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(Int(percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 热门标签
    
    private func tagsSection(_ review: DreamYearInReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("年度热门标签")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(review.topTags, id: \.self) { tag in
                    TagChip(tag: tag)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - AI 洞察
    
    private func insightsSection(_ review: DreamYearInReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 年度洞察")
                .font(.headline)
            
            ForEach(review.aiInsights, id: \.id) { insight in
                InsightCard(insight: insight)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 分享卡片
    
    private func shareCardsSection(_ review: DreamYearInReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分享卡片")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(review.shareCardIds, id: \.self) { cardId in
                        ShareCardPreview(cardId: cardId)
                            .frame(width: 200, height: 280)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 历史回顾
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史回顾")
                .font(.headline)
            
            ForEach(reviews.filter { $0.year != (selectedYear ?? reviews.first?.year) }, id: \.year) { review in
                Button(action: { selectedYear = review.year }) {
                    HStack {
                        Text("\(review.year)年")
                            .font(.headline)
                        Spacer()
                        Text("\(review.totalDreams)个梦境")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 动作
    
    private func generateCurrentYearReview() {
        isGenerating = true
        
        Task {
            do {
                let currentYear = Calendar.current.component(.year, from: Date())
                let service = DreamYearInReviewService(modelContainer: modelContainer)
                try await service.generateYearInReview(for: currentYear - 1)
                
                // 刷新数据
                try modelContext.fetch(FetchDescriptor<DreamYearInReview>())
            } catch {
                print("生成年度回顾失败：\(error)")
            }
            
            isGenerating = false
        }
    }
}

// MARK: - 统计卡片组件

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 标签芯片组件

struct TagChip: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.purple)
            .cornerRadius(16)
    }
}

// MARK: - 洞察卡片组件

struct InsightCard: View {
    let insight: YearInReviewInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.icon)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(insight.title)
                        .font(.headline)
                    Text(insight.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let suggestion = insight.actionSuggestion {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - 分享卡片预览

struct ShareCardPreview: View {
    let cardId: UUID
    
    var body: some View {
        VStack {
            // 这里应该是实际的分享卡片渲染
            // 简化版本
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    VStack {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("分享卡片")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 流式布局

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult.calculate(in: proposal.width ?? .infinity, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult.calculate(in: bounds.width, subviews: subviews, spacing: spacing)
        
        for (index, subview) in subviews.enumerated() {
            if index < result.subviewFrames.count {
                subview.place(at: CGPoint(x: bounds.minX + result.subviewFrames[index].minX,
                                          y: bounds.minY + result.subviewFrames[index].minY),
                              proposal: .unspecified)
            }
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var subviewFrames: [CGRect] = []
        
        static func calculate(in width: CGFloat, subviews: Subviews, spacing: CGFloat) -> FlowResult {
            var result = FlowResult()
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                result.subviewFrames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            result.size = CGSize(width: width, height: y + lineHeight)
            return result
        }
    }
}

// MARK: - 预览

#Preview {
    DreamYearInReviewView()
        .modelContainer(for: [DreamYearInReview.self, DreamMonthInReview.self, YearInReviewShareCard.self])
}
