//
//  DreamWidgetConfigurationView.swift
//  DreamLog
//
//  iOS 小组件配置界面 - Phase 33
//

import SwiftUI

// MARK: - 小组件配置主视图

struct DreamWidgetConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var widgetService = DreamWidgetService.shared
    
    @State private var selectedTheme: WidgetTheme = WidgetTheme.default
    @State private var selectedLayout: WidgetLayout = WidgetLayout.default
    @State private var selectedWidgetKind: DreamWidgetKind?
    @State private var showingThemeSheet = false
    @State private var showingLayoutSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // 主题配置
                Section("🎨 主题外观") {
                    Button(action: { showingThemeSheet = true }) {
                        HStack {
                            Text("当前主题")
                            Spacer()
                            Text(selectedTheme.name)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    // 主题预览
                    ThemePreviewCard(theme: selectedTheme)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 8)
                }
                
                // 布局配置
                Section("📐 布局设置") {
                    Toggle("显示标题", isOn: $selectedLayout.showTitle)
                    Toggle("显示图标", isOn: $selectedLayout.showIcon)
                    Toggle("显示日期", isOn: $selectedLayout.showDate)
                    Toggle("显示统计", isOn: $selectedLayout.showStats)
                    
                    Picker("字体大小", selection: $selectedLayout.fontSize) {
                        ForEach(WidgetLayout.WidgetFontSize.allCases, id: \.self) { size in
                            Text(size.title).tag(size)
                        }
                    }
                    
                    HStack {
                        Text("圆角大小")
                        Spacer()
                        Slider(value: $selectedLayout.cornerRadius, in: 0...24, step: 4)
                            .frame(width: 150)
                        Text("\(Int(selectedLayout.cornerRadius))")
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }
                    
                    HStack {
                        Text("内边距")
                        Spacer()
                        Slider(value: $selectedLayout.padding, in: 8...24, step: 4)
                            .frame(width: 150)
                        Text("\(Int(selectedLayout.padding))")
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                    }
                }
                
                // 小组件类型
                Section("📱 可用小组件") {
                    ForEach(DreamWidgetKind.allCases) { kind in
                        WidgetKindRow(kind: kind)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedWidgetKind = kind
                            }
                    }
                }
                
                // 实时更新
                Section("🔄 数据更新") {
                    Toggle("自动刷新", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("刷新频率")
                        Spacer()
                        Text("智能")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("立即刷新所有小组件") {
                        widgetService.reloadAllTimelines()
                    }
                    .foregroundColor(.accentColor)
                }
                
                // 重置选项
                Section {
                    Button("重置为主题默认") {
                        selectedTheme = WidgetTheme.default
                        selectedLayout = WidgetLayout.default
                        widgetService.setLayout(selectedLayout)
                        widgetService.setTheme(selectedTheme)
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("小组件配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveConfiguration()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingThemeSheet) {
                ThemeSelectionSheet(selectedTheme: $selectedTheme) {
                    selectedTheme = $0
                    widgetService.setTheme($0)
                }
            }
            .onAppear {
                selectedTheme = widgetService.getCurrentTheme()
                selectedLayout = widgetService.getCurrentLayout()
            }
        }
    }
    
    private func saveConfiguration() {
        widgetService.setTheme(selectedTheme)
        widgetService.setLayout(selectedLayout)
    }
}

// MARK: - 主题预览卡片

struct ThemePreviewCard: View {
    let theme: WidgetTheme
    
    var body: some View {
        HStack(spacing: 12) {
            // 主预览
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: theme.gradientStart) ?? .purple,
                                Color(hex: theme.gradientEnd) ?? .blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 60)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.title2)
                            Text("预览")
                                .font(.caption2)
                        }
                        .foregroundColor(Color(hex: theme.textColor) ?? .white)
                    )
                
                Text(theme.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            // 颜色样本
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ColorCircle(color: Color(hex: theme.backgroundColor) ?? .gray)
                    ColorCircle(color: Color(hex: theme.textColor) ?? .white)
                    ColorCircle(color: Color(hex: theme.accentColor) ?? .blue)
                }
                
                Text(theme.isDark ? "深色" : "浅色")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ColorCircle: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 20, height: 20)
            .overlay(
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - 主题选择工作表

struct ThemeSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTheme: WidgetTheme
    let onSelect: (WidgetTheme) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(WidgetTheme.allThemes) { theme in
                    Button(action: {
                        selectedTheme = theme
                        onSelect(theme)
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            // 主题预览
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: theme.gradientStart) ?? .purple,
                                            Color(hex: theme.gradientEnd) ?? .blue
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 40)
                                .overlay(
                                    Image(systemName: theme.isDark ? "moon.fill" : "sun.max.fill")
                                        .foregroundColor(Color(hex: theme.textColor) ?? .white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.name)
                                    .font(.headline)
                                
                                HStack(spacing: 8) {
                                    Label(theme.isDark ? "深色" : "浅色", systemImage: theme.isDark ? "moon" : "sun.max")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Circle()
                                        .fill(Color(hex: theme.accentColor) ?? .blue)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedTheme.id == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("选择主题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 小组件类型行

struct WidgetKindRow: View {
    let kind: DreamWidgetKind
    
    var body: some View {
        HStack(spacing: 12) {
            Text(kind.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.displayName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(kind.supportedFamilies, id: \.self) { family in
                        Text(familySizeName(family))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
    
    func familySizeName(_ family: WidgetFamily) -> String {
        switch family {
        case .systemSmall: return "小"
        case .systemMedium: return "中"
        case .systemLarge: return "大"
        case .accessoryCircular: return "锁屏圆"
        case .accessoryRectangular: return "锁屏长"
        default: return "未知"
        }
    }
}

// MARK: - 小组件配置预览

struct DreamWidgetConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        DreamWidgetConfigurationView()
    }
}

// Note: Color(hex:) is defined in Theme.swift to avoid duplicate declarations
