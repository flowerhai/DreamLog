//
//  DreamWidgetConfigurationView.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  小组件配置 UI
//

import SwiftUI

struct DreamWidgetConfigurationView: View {
    @State private var selectedTheme: WidgetTheme = .purple
    @State private var selectedStyle: WidgetStyle = .detailed
    @State private var showStats: Bool = true
    @State private var showChallenge: Bool = true
    @State private var showInsight: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                // 主题选择
                Section(header: Text("主题")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(WidgetTheme.allCases) { theme in
                            ThemeButton(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                onSelect: { selectedTheme = theme }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 样式选择
                Section(header: Text("样式")) {
                    Picker("显示样式", selection: $selectedStyle) {
                        Text("简约").tag(WidgetStyle.minimal)
                        Text("详细").tag(WidgetStyle.detailed)
                        Text("图形").tag(WidgetStyle.graphical)
                        Text("文字").tag(WidgetStyle.text)
                    }
                    .pickerStyle(.segmented)
                    
                    Text(styleDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 显示内容
                Section(header: Text("显示内容")) {
                    Toggle("统计数据", isOn: $showStats)
                    Toggle("挑战进度", isOn: $showChallenge)
                    Toggle("每日洞察", isOn: $showInsight)
                }
                
                // 预览
                Section(header: Text("预览")) {
                    WidgetPreviewCard(
                        theme: selectedTheme,
                        style: selectedStyle,
                        showStats: showStats,
                        showChallenge: showChallenge,
                        showInsight: showInsight
                    )
                    .frame(height: 200)
                    .padding(.vertical, 8)
                }
                
                // 重置
                Section {
                    Button("重置为默认") {
                        selectedTheme = .purple
                        selectedStyle = .detailed
                        showStats = true
                        showChallenge = true
                        showInsight = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("小组件配置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var styleDescription: String {
        switch selectedStyle {
        case .minimal: return "仅显示核心数据，简洁明了"
        case .detailed: return "显示完整统计和详细信息"
        case .graphical: return "以图表和图形为主展示数据"
        case .text: return "纯文本展示，无图形元素"
        }
    }
}

// MARK: - 主题按钮

struct ThemeButton: View {
    let theme: WidgetTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: theme.color))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                    )
                
                Text(theme.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 小组件预览卡片

struct WidgetPreviewCard: View {
    let theme: WidgetTheme
    let style: WidgetStyle
    let showStats: Bool
    let showChallenge: Bool
    let showInsight: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: theme.color).opacity(0.2))
            
            VStack(spacing: 12) {
                if showStats {
                    HStack(spacing: 16) {
                        StatPreview(value: "3", label: "今日", icon: "moon.fill")
                        StatPreview(value: "12", label: "连续", icon: "flame.fill")
                        StatPreview(value: "4.2", label: "清晰", icon: "star.fill")
                    }
                }
                
                if showChallenge && style != .minimal {
                    ChallengePreview(theme: theme)
                }
                
                if showInsight && style != .minimal {
                    InsightPreview(theme: theme)
                }
            }
            .padding()
        }
    }
}

// MARK: - 统计预览

struct StatPreview: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.purple)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 挑战预览

struct ChallengePreview: View {
    let theme: WidgetTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "target")
                    .font(.caption)
                Text("晨间记录者")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("60%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            ProgressView(value: 0.6)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: theme.color)))
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - 洞察预览

struct InsightPreview: View {
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("梦境模式")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("最近经常梦到水...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - 小组件主题

enum WidgetTheme: String, CaseIterable, Identifiable {
    case purple = "purple"
    case orange = "orange"
    case blue = "blue"
    case green = "green"
    case black = "black"
    case pink = "pink"
    case gold = "gold"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .purple: return "星空紫"
        case .orange: return "日落橙"
        case .blue: return "海洋蓝"
        case .green: return "森林绿"
        case .black: return "午夜黑"
        case .pink: return "玫瑰粉"
        case .gold: return "奢华金"
        case .custom: return "自定义"
        }
    }
    
    var color: String {
        switch self {
        case .purple: return "6B46C1"
        case .orange: return "ED8936"
        case .blue: return "4299E1"
        case .green: return "48BB78"
        case .black: return "1A202C"
        case .pink: return "ED64A6"
        case .gold: return "D69E2E"
        case .custom: return "6B46C1"
        }
    }
}

// MARK: - 小组件样式

enum WidgetStyle: String, CaseIterable {
    case minimal = "minimal"
    case detailed = "detailed"
    case graphical = "graphical"
    case text = "text"
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 预览

struct DreamWidgetConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        DreamWidgetConfigurationView()
    }
}
