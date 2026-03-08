//
//  MeditationView.swift
//  DreamLog - 梦境冥想与睡眠音效主界面
//  Phase 8: 睡眠增强功能
//

import SwiftUI

struct MeditationView: View {
    @StateObject private var meditationService = MeditationService.shared
    @State private var selectedTab = 0
    @State private var showingMixer = false
    @State private var customMix: SoundMix?
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // 音效库
                SoundLibraryView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("音效库")
                    }
                    .tag(0)
                
                // 引导冥想
                GuidedMeditationListView()
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("引导冥想")
                    }
                    .tag(1)
                
                // 混音器
                SoundMixerView(customMix: $customMix)
                    .tabItem {
                        Image(systemName: "slider.horizontal.3")
                        Text("混音器")
                    }
                    .tag(2)
                
                // 我的预设
                MyPresetsView()
                    .tabItem {
                        Image(systemName: "star.fill")
                        Text("我的预设")
                    }
                    .tag(3)
            }
            .navigationTitle("🌙 梦境冥想")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if meditationService.isPlaying {
                            Button(action: {
                                meditationService.stopAll()
                            }) {
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .overlay(
                MiniPlayerView()
                    .padding(.bottom, 80)
            )
        }
    }
}

// MARK: - 音效库视图
struct SoundLibraryView: View {
    @StateObject private var meditationService = MeditationService.shared
    @State private var selectedCategory: SoundCategory? = nil
    
    var filteredSounds: [SoundType] {
        if let category = selectedCategory {
            return SoundType.allCases.filter { $0.category == category }
        }
        return SoundType.allCases
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "全部",
                            icon: "􀆮",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(SoundCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 音效列表
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                    ForEach(filteredSounds) { sound in
                        SoundCard(sound: sound)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.purple : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct SoundCard: View {
    @StateObject private var meditationService = MeditationService.shared
    let sound: SoundType
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: togglePlay) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(sound.displayName)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }
                
                Text(sound.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(sound.category.rawValue)
                        .font(.system(size: 10))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func togglePlay() {
        if isPlaying {
            meditationService.stopAll()
        } else {
            let mix = SoundMix(
                name: sound.displayName,
                sounds: [SoundMix.SoundMixItem(soundType: sound, volume: 1.0, isEnabled: true)],
                masterVolume: 1.0,
                timer: nil
            )
            meditationService.playMix(mix)
        }
        isPlaying.toggle()
    }
}

// MARK: - 引导冥想列表
struct GuidedMeditationListView: View {
    @StateObject private var meditationService = MeditationService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(GuidedMeditationType.allCases) { meditation in
                    GuidedMeditationCard(meditation: meditation)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct GuidedMeditationCard: View {
    @StateObject private var meditationService = MeditationService.shared
    let meditation: GuidedMeditationType
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: togglePlay) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meditation.displayName)
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(formatDuration(meditation.duration))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                }
                
                Text(meditation.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 脚本预览
                if !meditation.script.isEmpty {
                    Text("\"\(meditation.script.first ?? "")\"")
                        .font(.system(size: 12, design: .italic))
                        .foregroundColor(.purple.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func togglePlay() {
        if isPlaying {
            meditationService.stopAll()
        } else {
            meditationService.playGuidedMeditation(meditation)
        }
        isPlaying.toggle()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) 分钟"
    }
}

// MARK: - 混音器视图
struct SoundMixerView: View {
    @StateObject private var meditationService = MeditationService.shared
    @Binding var customMix: SoundMix?
    @State private var sounds: [SoundMix.SoundMixItem] = []
    @State private var masterVolume: Float = 1.0
    @State private var timerMinutes: Int = 30
    @State private var showingSaveSheet = false
    @State private var presetName = ""
    
    init(customMix: Binding<SoundMix?>) {
        _customMix = customMix
        _sounds = State(initialValue: SoundType.allCases.map { type in
            SoundMix.SoundMixItem(soundType: type, volume: 0.5, isEnabled: false)
        })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 主音量
                VolumeSlider(title: "总音量", volume: $masterVolume) {
                    meditationService.updateVolume($0)
                }
                
                // 定时器
                TimerPicker(selectedMinutes: $timerMinutes)
                
                Divider()
                
                // 音效列表
                Text("混合音效")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach($sounds) { $item in
                    SoundMixerRow(item: $item, masterVolume: masterVolume)
                }
                
                // 播放控制
                Button(action: playMix) {
                    HStack {
                        Image(systemName: meditationService.isPlaying ? "stop.fill" : "play.fill")
                        Text(meditationService.isPlaying ? "停止播放" : "开始播放")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(meditationService.isPlaying ? Color.red : Color.purple)
                    )
                }
                
                // 保存预设
                Button(action: { showingSaveSheet = true }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("保存为预设")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.1))
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingSaveSheet) {
            SavePresetSheet(presetName: $presetName) {
                savePreset()
            }
        }
    }
    
    private func playMix() {
        let enabledSounds = sounds.filter { $0.isEnabled }
        guard !enabledSounds.isEmpty else { return }
        
        let mix = SoundMix(
            name: "自定义混音",
            sounds: enabledSounds,
            masterVolume: masterVolume,
            timer: timerMinutes * 60
        )
        
        customMix = mix
        meditationService.playMix(mix)
    }
    
    private func savePreset() {
        guard !presetName.isEmpty else { return }
        
        let enabledSounds = sounds.filter { $0.isEnabled }
        let mix = SoundMix(
            name: presetName,
            sounds: enabledSounds,
            masterVolume: masterVolume,
            timer: timerMinutes * 60
        )
        
        meditationService.saveMixPreset(mix)
        presetName = ""
    }
}

struct VolumeSlider: View {
    let title: String
    @Binding var volume: Float
    let onChange: ((Float) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "speaker.fill")
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $volume, in: 0...1, onEditingChanged: { _ in
                onChange?(volume)
            })
            .tint(.purple)
        }
    }
}

struct TimerPicker: View {
    @Binding var selectedMinutes: Int
    
    var options: [Int] { [0, 15, 30, 45, 60, 90] }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                Text("播放时长")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(selectedMinutes == 0 ? "持续播放" : "\(selectedMinutes) 分钟")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(options, id: \.self) { minutes in
                        Button(action: { selectedMinutes = minutes }) {
                            Text(minutes == 0 ? "∞" : "\(minutes) 分钟")
                                .font(.system(size: 14, weight: selectedMinutes == minutes ? .semibold : .regular))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedMinutes == minutes ? Color.purple : Color(.systemGray5))
                                )
                                .foregroundColor(selectedMinutes == minutes ? .white : .primary)
                        }
                    }
                }
            }
        }
    }
}

struct SoundMixerRow: View {
    @Binding var item: SoundMix.SoundMixItem
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: $item.isEnabled) {
                    Text(item.soundType.displayName)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                Text("\(Int(item.volume * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
            
            if item.isEnabled {
                Slider(value: $item.volume, in: 0...1)
                    .tint(.purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct SavePresetSheet: View {
    @Binding var presetName: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("预设名称", text: $presetName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    onSave()
                    dismiss()
                }) {
                    Text("保存")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple)
                        )
                }
            }
            .padding()
            .navigationTitle("保存预设")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 我的预设视图
struct MyPresetsView: View {
    @StateObject private var meditationService = MeditationService.shared
    @State private var presets: [SoundMix] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if presets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("暂无预设")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("在混音器中创建你的专属音效组合")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                } else {
                    ForEach(presets) { preset in
                        PresetCard(preset: preset)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            presets = meditationService.loadMixPresets()
        }
    }
}

struct PresetCard: View {
    @StateObject private var meditationService = MeditationService.shared
    let preset: SoundMix
    @State private var isPlaying = false
    
    var body: some View {
        Button(action: togglePlay) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(preset.name)
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                }
                
                // 显示包含的音效
                HStack(spacing: 8) {
                    ForEach(preset.sounds.filter { $0.isEnabled }.prefix(4)) { item in
                        Text(item.soundType.displayName)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if preset.sounds.filter({ $0.isEnabled }).count > 4 {
                        Text("+\(preset.sounds.filter { $0.isEnabled }.count - 4)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 定时器信息
                if let timer = preset.timer {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("\(timer / 60) 分钟后停止")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: deletePreset) {
                Label("删除预设", systemImage: "trash")
            }
        }
    }
    
    private func togglePlay() {
        if isPlaying {
            meditationService.stopAll()
        } else {
            meditationService.playMix(preset)
        }
        isPlaying.toggle()
    }
    
    private func deletePreset() {
        var presets = meditationService.loadMixPresets()
        presets.removeAll { $0.id == preset.id }
        
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: "meditation_mix_presets")
        }
    }
}

// MARK: - 迷你播放器
struct MiniPlayerView: View {
    @StateObject private var meditationService = MeditationService.shared
    
    var body: some View {
        Group {
            if meditationService.isPlaying {
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        // 播放状态图标
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                            .frame(width: 40, height: 40)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Circle())
                        
                        // 播放信息
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meditationService.currentMix?.name ?? meditationService.currentGuidedMeditation?.displayName ?? "播放中")
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                            
                            if meditationService.remainingTime > 0 {
                                Text(formatTime(meditationService.remainingTime))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 进度条
                        if meditationService.remainingTime > 0 {
                            ProgressView(value: meditationService.playbackProgress)
                                .frame(width: 80)
                        }
                        
                        // 控制按钮
                        Button(action: {
                            if meditationService.isPlaying {
                                meditationService.pause()
                            } else {
                                meditationService.resume()
                            }
                        }) {
                            Image(systemName: meditationService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.purple)
                                .frame(width: 40, height: 40)
                        }
                        
                        Button(action: {
                            meditationService.stopAll()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    MeditationView()
}
