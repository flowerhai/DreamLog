//
//  DreamSleepSoundsView.swift
//  DreamLog
//
//  睡眠音景 UI 界面 - Phase 86 梦境音乐与氛围音景 🎵💤✨
//  创建时间：2026-03-21
//

import SwiftUI

// MARK: - 睡眠音景主视图

/// 睡眠音景选择与播放界面
struct DreamSleepSoundsView: View {
    @StateObject private var soundscapeService = DreamSoundscapeService.shared
    @State private var selectedPreset: SoundscapePreset?
    @State private var showTimerSheet = false
    @State private var selectedTimer: SleepTimerConfig?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1E1B4B"), Color(hex: "312E81")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 头部统计卡片
                        headerSection
                        
                        // 搜索栏
                        searchSection
                        
                        // 分类筛选
                        categoryFilterSection
                        
                        // 推荐音景
                        recommendedSection
                        
                        // 所有音景
                        allSoundscapesSection
                    }
                    .padding()
                }
                
                // 底部播放器
                if soundscapeService.isPlaying {
                    bottomPlayer
                }
            }
            .navigationTitle("睡眠音景")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $showTimerSheet) {
                SleepTimerSelectionView { config in
                    selectedTimer = config
                    soundscapeService.setSleepTimer(config)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("🌙 好梦相伴")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("选择舒缓的音景，帮助您快速入睡")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            // 统计信息
            HStack(spacing: 20) {
                StatItem(icon: "moon.fill", value: "\(SoundscapePreset.allPresets.count)", label: "音景")
                StatItem(icon: "clock.fill", value: selectedTimer?.formattedDuration ?? "未设置", label: "定时器")
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("搜索音景...", text: $searchText)
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }
    
    // MARK: - Category Filter Section
    
    @State private var selectedCategory: SoundscapeCategory?
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部
                FilterChip(
                    title: "全部",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    color: "6366F1"
                ) {
                    selectedCategory = nil
                }
                
                // 各分类
                ForEach(SoundscapeCategory.allCases) { category in
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
    
    // MARK: - Recommended Section
    
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💤 助眠推荐")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(filteredPresets.prefix(4)) { preset in
                    SoundscapeCard(preset: preset) {
                        selectedPreset = preset
                        Task {
                            await soundscapeService.playSoundscape(preset)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - All Soundscapes Section
    
    private var allSoundscapesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎵 所有音景")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(filteredPresets) { preset in
                    SoundscapeCard(preset: preset) {
                        selectedPreset = preset
                        Task {
                            await soundscapeService.playSoundscape(preset)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Player
    
    private var bottomPlayer: some View {
        VStack {
            Divider()
            
            HStack(spacing: 16) {
                // 音景信息
                if let preset = soundscapeService.currentSoundscape {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preset.icon + " " + preset.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("正在播放")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // 播放控制
                    Button(action: {
                        if soundscapeService.isPlaying {
                            soundscapeService.pause()
                        } else {
                            soundscapeService.resume()
                        }
                    }) {
                        Image(systemName: soundscapeService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    // 定时器按钮
                    Button(action: { showTimerSheet = true }) {
                        Image(systemName: "timer")
                            .font(.system(size: 24))
                            .foregroundColor(selectedTimer != nil ? .green : .white.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Filtered Presets
    
    private var filteredPresets: [SoundscapePreset] {
        var presets = SoundscapePreset.allPresets
        
        // 分类筛选
        if let category = selectedCategory {
            presets = presets.filter { $0.category == category }
        }
        
        // 搜索筛选
        if !searchText.isEmpty {
            presets = presets.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return presets
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : Color(hex: color))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(hex: color) : Color.white.opacity(0.15))
            )
        }
    }
}

// MARK: - Soundscape Card

struct SoundscapeCard: View {
    let preset: SoundscapePreset
    let action: () -> Void
    
    @StateObject private var soundscapeService = DreamSoundscapeService.shared
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // 图标
                Text(preset.icon)
                    .font(.system(size: 32))
                
                // 名称
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // 描述
                Text(preset.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                Spacer()
                
                // 播放按钮
                HStack {
                    Spacer()
                    Image(systemName: soundscapeService.currentSoundscape?.id == preset.id && soundscapeService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: preset.color))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Sleep Timer Selection View

struct SleepTimerSelectionView: View {
    let onTimerSelected: (SleepTimerConfig) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: TimeInterval = 1800
    @State private var selectedAction: SleepTimerAction = .stop
    
    var body: some View {
        NavigationView {
            Form {
                Section("时长") {
                    ForEach(SleepTimerConfig.presets, id: \.0) { duration, label in
                        Button(action: {
                            selectedDuration = duration
                        }) {
                            HStack {
                                Text(label)
                                Spacer()
                                if selectedDuration == duration {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section("结束动作") {
                    ForEach(SleepTimerAction.allCases, id: \.rawValue) { action in
                        Button(action: {
                            selectedAction = action
                        }) {
                            HStack {
                                Text(action.rawValue)
                                Spacer()
                                if selectedAction == action {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("启动定时器") {
                        let config = SleepTimerConfig(
                            enabled: true,
                            duration: selectedDuration,
                            fadeOutDuration: 30,
                            action: selectedAction
                        )
                        onTimerSelected(config)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("睡眠定时器")
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

// MARK: - Color Extension

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
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Preview

#Preview {
    DreamSleepSoundsView()
}
