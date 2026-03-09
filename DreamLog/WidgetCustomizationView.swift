//
//  WidgetCustomizationView.swift
//  DreamLog
//
//  小组件个性化定制界面
//

import SwiftUI

struct WidgetCustomizationView: View {
    @ObservedObject private var service = WidgetConfigurationService.shared
    @State private var config: WidgetCustomizationConfig
    @State private var showingThemePreview = false
    @State private var selectedThemeIndex = 0
    @State private var showingSavePreset = false
    @State private var presetName = ""
    @State private var showingLoadPreset = false
    @State private var showingExportOptions = false
    @State private var exportedConfig: String?
    
    init() {
        _config = State(initialValue: WidgetConfigurationService.shared.currentConfig)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 主题选择
                Section(header: Label("主题风格", systemImage: "paintpalette")) {
                    // 主题预览
                    VStack(spacing: 12) {
                        themePreviewCard
                        
                        HStack {
                            Text("选择主题")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        // 主题网格
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(WidgetTheme.themes) { theme in
                                themeSelectionButton(theme: theme)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - 数据显示配置
                Section(header: Label("显示内容", systemImage: "list.bullet")) {
                    Toggle("梦境总数", isOn: $config.dataConfig.showDreamCount)
                    Toggle("最近梦境标题", isOn: $config.dataConfig.showLastDreamTitle)
                    Toggle("情绪图标", isOn: $config.dataConfig.showMood)
                    Toggle("每周目标", isOn: $config.dataConfig.showWeeklyGoal)
                    Toggle("连续记录天数", isOn: $config.dataConfig.showStreak)
                    
                    // 自定义语录
                    Toggle("显示语录", isOn: $config.dataConfig.showQuote)
                    if config.dataConfig.showQuote {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("自定义语录")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("输入激励语录...", text: $config.dataConfig.customQuote, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...5)
                            
                            if config.dataConfig.customQuote.isEmpty {
                                Text("留空则使用默认语录")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 显示模式
                    Picker("显示模式", selection: $config.dataConfig.displayMode) {
                        ForEach(WidgetDataConfig.DisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - 尺寸配置
                Section(header: Label("尺寸设置", systemImage: "viewfinder")) {
                    Picker("首选尺寸", selection: $config.sizeConfig.preferredSize) {
                        ForEach(WidgetSizeConfig.WidgetSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    
                    Toggle("支持多种尺寸", isOn: $config.sizeConfig.allowMultipleSizes)
                }
                
                // MARK: - 自定义名称
                Section(header: Label("个性化", systemImage: "tag")) {
                    TextField("小组件名称 (可选)", text: $config.customName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !config.customName.isEmpty {
                        Text("将显示为：\(config.customName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - 预设管理
                Section(header: Label("预设管理", systemImage: "folder")) {
                    Button(action: { showingSavePreset = true }) {
                        HStack {
                            Label("保存为预设", systemImage: "square.and.arrow.down")
                            Spacer()
                        }
                    }
                    
                    if !service.savedConfigs.isEmpty {
                        Button(action: { showingLoadPreset = true }) {
                            HStack {
                                Label("加载预设", systemImage: "folder.open")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Label("导出/导入配置", systemImage: "arrow.up.arrow.down")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - 重置
                Section {
                    Button(role: .destructive) {
                        config = .default
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置为默认")
                        }
                    }
                }
            }
            .navigationTitle("小组件定制")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveConfig()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingSavePreset) {
                savePresetSheet
            }
            .sheet(isPresented: $showingLoadPreset) {
                loadPresetSheet
            }
            .confirmationDialog("导出配置", isPresented: $showingExportOptions) {
                Button("复制到剪贴板") {
                    exportConfig()
                }
                Button("导入配置", role: .cancel) {
                    // Handle import
                }
            }
        }
        .onChange(of: config) { _, newValue in
            // 自动保存配置
            service.currentConfig = newValue
        }
    }
    
    // MARK: - 主题预览卡片
    var themePreviewCard: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: config.theme.colors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .shadow(color: config.theme.colors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                
                VStack(spacing: 8) {
                    Image(systemName: config.theme.iconSFSymbol)
                        .font(.system(size: 32))
                        .foregroundColor(config.theme.textColorValue)
                    
                    Text(config.theme.name)
                        .font(.headline)
                        .foregroundColor(config.theme.textColorValue)
                    
                    Text("DreamLog")
                        .font(.caption)
                        .foregroundColor(config.theme.textColorValue.opacity(0.8))
                }
            }
            
            HStack {
                Text("预览")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("全屏查看") {
                    showingThemePreview = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - 主题选择按钮
    func themeSelectionButton(theme: WidgetTheme) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                config.theme = theme
            }
        }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: theme.colors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 50)
                        .overlay(
                            Image(systemName: theme.iconSFSymbol)
                                .foregroundColor(theme.textColorValue)
                        )
                    
                    if config.theme.id == theme.id {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                            .offset(x: 15, y: -15)
                    }
                }
                
                Text(theme.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 保存预设弹窗
    var savePresetSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("预设名称")) {
                    TextField("例如：我的星空主题", text: $presetName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section {
                    Button("保存") {
                        if !presetName.isEmpty {
                            service.saveConfig(name: presetName, config: config)
                            showingSavePreset = false
                            presetName = ""
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(presetName.isEmpty)
                }
            }
            .navigationTitle("保存预设")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingSavePreset = false
                        presetName = ""
                    }
                }
            }
        }
    }
    
    // MARK: - 加载预设弹窗
    var loadPresetSheet: some View {
        NavigationView {
            List {
                ForEach(service.savedConfigs.keys.sorted(), id: \.self) { name in
                    Button(action: {
                        if let loadedConfig = service.loadConfig(name: name) {
                            config = loadedConfig
                            showingLoadPreset = false
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(name)
                                    .font(.headline)
                                Text("主题：\(service.loadConfig(name: name)?.theme.name ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "folder.badge.plus")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                if !service.savedConfigs.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            // Delete functionality could be added here
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除预设")
                            }
                        }
                    }
                }
            }
            .navigationTitle("加载预设")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingLoadPreset = false
                    }
                }
            }
        }
    }
    
    // MARK: - 功能方法
    private func saveConfig() {
        service.currentConfig = config
        // 可以在这里添加保存成功的提示
    }
    
    private func exportConfig() {
        exportedConfig = service.exportConfig()
        // 复制到剪贴板的逻辑
    }
}

// MARK: - 预览
#Preview {
    WidgetCustomizationView()
}
