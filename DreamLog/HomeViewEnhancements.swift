//
//  HomeViewEnhancements.swift
//  DreamLog
//
//  Phase 43 - 首页增强组件
//

import SwiftUI

// MARK: - 快捷操作卡片

struct QuickActionCard: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(action.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: action.icon)
                        .font(.title2)
                        .foregroundColor(action.color)
                }
                
                Text(action.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "16213E"))
            .cornerRadius(12)
        }
    }
}

// MARK: - 统计卡片

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Text(trend)
                        .font(.caption)
                        .foregroundColor(trend.hasPrefix("+") ? Color(hex: "70AD47") : Color(hex: "FF6B6B"))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "16213E"))
        .cornerRadius(12)
    }
}

// MARK: - 最近梦境卡片

struct RecentDreamCard: View {
    let dream: Dream
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 情绪图标
                ZStack {
                    Circle()
                        .fill(dream.mood.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(dream.mood.emoji)
                        .font(.title2)
                }
                
                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(dream.title ?? "无标题梦境")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(dream.content.prefix(50) + (dream.content.count > 50 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(dream.formattedDate)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        if dream.isLucid {
                            Label("清醒梦", systemImage: "sparkles")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "9B7EBD"))
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(hex: "16213E"))
            .cornerRadius(12)
        }
    }
}

// MARK: - 连续记录卡片

struct StreakCard: View {
    let streak: Int
    let bestStreak: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续记录")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(streak) 天")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FFC000"))
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            
            if bestStreak > streak {
                HStack {
                    Text("最佳记录：\(bestStreak) 天")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(hex: "16213E"), Color(hex: "9B7EBD").opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - 快捷入口网格

struct QuickAccessGrid: View {
    let items: [QuickAccessItem]
    let onTap: (QuickAccessItem) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items) { item in
                Button(action: { onTap(item) }) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: item.icon)
                                .font(.system(size: 18))
                                .foregroundColor(item.color)
                        }
                        
                        Text(item.title)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

// MARK: - 快捷入口项

struct QuickAccessItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView
}

extension QuickAccessItem {
    static let presets: [QuickAccessItem] = [
        QuickAccessItem(title: "日历", icon: "calendar", color: Color(hex: "5B9BD5"), destination: AnyView(CalendarView())),
        QuickAccessItem(title: "统计", icon: "chart.bar.fill", color: Color(hex: "70AD47"), destination: AnyView(InsightsView())),
        QuickAccessItem(title: "社区", icon: "globe", color: Color(hex: "ED7D31"), destination: AnyView(CommunityView(dreamStore: DreamStore()))),
        QuickAccessItem(title: "挑战", icon: "trophy.fill", color: Color(hex: "FFC000"), destination: AnyView(DreamChallengeView())),
        QuickAccessItem(title: "音乐", icon: "music.note.house.fill", color: Color(hex: "9B7EBD"), destination: AnyView(DreamMusicView())),
        QuickAccessItem(title: "冥想", icon: "music.note.house", color: Color(hex: "5B9BD5"), destination: AnyView(MeditationView())),
        QuickAccessItem(title: "画廊", icon: "photo.on.rectangle", color: Color(hex: "FF6B6B"), destination: AnyView(GalleryView())),
        QuickAccessItem(title: "助手", icon: "message.fill", color: Color(hex: "70AD47"), destination: AnyView(DreamAssistantView()))
    ]
}

// MARK: - 今日提示卡片

struct DailyTipCard: View {
    let tip: String
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color(hex: "FFC000"))
                    
                    Text("每日提示")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(hex: "16213E"))
        .cornerRadius(12)
    }
}

// MARK: - 梦境颜色扩展

extension Mood {
    var color: Color {
        switch self {
        case .calm: return Color(hex: "5B9BD5")
        case .happy: return Color(hex: "FFC000")
        case .sad: return Color(hex: "5B9BD5")
        case .fear: return Color(hex: "FF6B6B")
        case .angry: return Color(hex: "FF6B6B")
        case .surprised: return Color(hex: "ED7D31")
        case .disgusted: return Color(hex: "70AD47")
        case .anticipation: return Color(hex: "9B7EBD")
        case .trust: return Color(hex: "70AD47")
        case .confused: return Color(hex: "5B9BD5")
        }
    }
}
