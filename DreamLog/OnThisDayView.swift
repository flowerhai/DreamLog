//
//  OnThisDayView.swift
//  DreamLog
//
//  梦境回顾 - "去年的今天"功能
//  Phase 6 - 个性化体验
//

import SwiftUI

struct OnThisDayView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedYear: Int?
    @State private var showingDreamDetail = false
    @State private var selectedDream: Dream?
    
    var today: Date
    var yearsWithDreams: [Int]
    var dreamsForSelectedYear: [Dream]
    
    init(today: Date = Date()) {
        self.today = today
        _dreamStore = EnvironmentObject()
        
        // 计算有梦境的年份
        let calendar = Calendar.current
        var years: Set<Int> = []
        for dream in dreamStore.dreams {
            if calendar.isDate(dream.date, inSameDayAs: today) {
                years.insert(calendar.component(.year, from: dream.date))
            }
        }
        self.yearsWithDreams = years.sorted().reversed()
        
        // 获取选中年份的梦境
        if let selectedYear = yearsWithDreams.first {
            self.selectedYear = selectedYear
            self.dreamsForSelectedYear = dreamStore.dreams.filter { dream in
                calendar.component(.year, from: dream.date) == selectedYear &&
                calendar.isDate(dream.date, inSameDayAs: today)
            }.sorted { $0.date > $1.date }
        } else {
            self.dreamsForSelectedYear = []
        }
    }
    
    var calendar: Calendar { Calendar.current }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 头部区域
                    headerSection
                    
                    if yearsWithDreams.isEmpty {
                        // 空状态
                        emptyStateView
                    } else {
                        // 年份选择
                        yearSelectorSection
                        
                        // 梦境列表
                        dreamsSection
                    }
                }
                .padding()
            }
            .navigationTitle("📅 梦境回顾")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [Color(hex: "1A1A2E"), Color(hex: "16213E"), Color(hex: "0F3460")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .sheet(isPresented: $showingDreamDetail) {
                if let dream = selectedDream {
                    DreamDetailView(dream: dream)
                        .environmentObject(dreamStore)
                }
            }
        }
    }
    
    // MARK: - 头部区域
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("历史上的今天")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(today.formatted(.dateTime.month().day()))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            if !yearsWithDreams.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.accentColor)
                    Text("你在 \(yearsWithDreams.count) 个年份的今天记录过梦境")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 空状态
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("还没有今天的梦境")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.5))
            
            Text("在今年的今天记录一个梦境，\n明年今日就能回顾它")
                .font(.body)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - 年份选择
    
    private var yearSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择年份")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(yearsWithDreams, id: \.self) { year in
                        Button(action: {
                            withAnimation(.spring()) {
                                selectedYear = year
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text("\(year)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedYear == year ? .white : .white.opacity(0.6))
                                
                                Text("年")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                if selectedYear == year {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedYear == year ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.05))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - 梦境列表
    
    private var dreamsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("梦境列表")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            ForEach(dreamsForSelectedYear) { dream in
                DreamReviewCard(dream: dream)
                    .onTapGesture {
                        selectedDream = dream
                        showingDreamDetail = true
                    }
            }
        }
    }
}

// MARK: - 梦境回顾卡片

struct DreamReviewCard: View {
    let dream: Dream
    @EnvironmentObject var dreamStore: DreamStore
    
    var timeAgo: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: dream.date, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years) 年前"
        } else if let months = components.month, months > 0 {
            return "\(months) 个月前"
        } else if let days = components.day, days > 0 {
            return "\(days) 天前"
        } else {
            return "今天"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部信息
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    Text(dream.date.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // 标题
            Text(dream.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            // 内容预览
            Text(dream.content.prefix(100))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
                .if(dream.content.count > 100) { $0.text("...") }
            
            // 底部标签
            HStack {
                if dream.isLucid {
                    Label("清醒梦", systemImage: "sparkles")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.yellow)
                        .cornerRadius(8)
                }
                
                ForEach(dream.emotions.prefix(3), id: \.self) { emotion in
                    Text(emotion.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(emotion.color.opacity(0.2))
                        .foregroundColor(emotion.color)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(dream.clarity)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    OnThisDayView()
        .environmentObject(DreamStore())
}

// MARK: - View Extension for conditional modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
