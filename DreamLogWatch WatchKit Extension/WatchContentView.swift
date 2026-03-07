//
//  WatchContentView.swift
//  DreamLog WatchKit Extension
//
//  Apple Watch 主界面
//

import SwiftUI
import WatchKit

struct WatchContentView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var hapticFeedback: HapticFeedback
    @State private var selectedTab = 0
    @State private var isRecording = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 快速记录
            WatchRecordView(isRecording: $isRecording)
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("记录")
                }
                .tag(0)
            
            // 最近梦境
            WatchRecentDreamsView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("梦境")
                }
                .tag(1)
            
            // 统计
            WatchStatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("统计")
                }
                .tag(2)
            
            // 设置
            WatchSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(3)
        }
        .tint(Color(hex: "9B7EBD"))
    }
}

// MARK: - 快速记录视图

struct WatchRecordView: View {
    @Binding var isRecording: Bool
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var hapticFeedback: HapticFeedback
    @State private var dreamText = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 录音按钮
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color(hex: "9B7EBD"))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        
                        if isRecording {
                            Circle()
                                .stroke(Color.red.opacity(0.5), lineWidth: 4)
                                .frame(width: 80, height: 80)
                                .scaleEffect(1.2)
                                .animation(.repeat(count: .max, duration: 1.0), value: isRecording)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Text(isRecording ? "正在录音..." : "点击录音")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 文字输入
                if !isRecording {
                    TextField("梦境内容", text: $dreamText, axis: .vertical)
                        .font(.body)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .lineLimit(4, reservesSpace: true)
                    
                    Button(action: {
                        if !dreamText.isEmpty {
                            saveDream()
                        }
                    }) {
                        Label("保存", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(dreamText.isEmpty)
                }
                
                // 最近记录提示
                if dreamStore.dreams.isEmpty {
                    Text("暂无梦境记录")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
            }
            .padding()
        }
    }
    
    private func toggleRecording() {
        hapticFeedback.trigger(.light)
        isRecording.toggle()
        
        if isRecording {
            // 开始录音
            dreamText = ""
        } else {
            // 停止录音 (模拟)
            hapticFeedback.trigger(.success)
            dreamText = "梦境记录..."
        }
    }
    
    private func saveDream() {
        let dream = Dream(
            title: String(dreamText.prefix(30)),
            content: dreamText,
            tags: [],
            emotions: [],
            clarity: 3,
            intensity: 3,
            isLucid: false
        )
        
        dreamStore.addDream(dream)
        dreamText = ""
        showingConfirmation = true
        hapticFeedback.trigger(.success)
        
        // 显示成功提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingConfirmation = false
        }
    }
}

// MARK: - 最近梦境视图

struct WatchRecentDreamsView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedDream: Dream?
    
    var body: some View {
        NavigationView {
            List {
                Section("最近梦境") {
                    ForEach(dreamStore.dreams.prefix(10)) { dream in
                        Button(action: {
                            selectedDream = dream
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dream.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(dream.date, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("梦境")
            .sheet(item: $selectedDream) { dream in
                WatchDreamDetailView(dream: dream)
            }
        }
    }
}

// MARK: - 梦境详情视图

struct WatchDreamDetailView: View {
    let dream: Dream
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(dream.title)
                    .font(.headline)
                
                Text(dream.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Text(dream.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if !dream.tags.isEmpty {
                    Divider()
                    
                    FlowLayout(spacing: 4) {
                        ForEach(dream.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                if !dream.emotions.isEmpty {
                    Divider()
                    
                    HStack(spacing: 8) {
                        ForEach(dream.emotions, id: \.self) { emotion in
                            Text(emotion.icon)
                                .font(.title2)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - 统计视图

struct WatchStatsView: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var totalDreams: Int {
        dreamStore.dreams.count
    }
    
    var thisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return dreamStore.dreams.filter { $0.date >= weekAgo }.count
    }
    
    var lucidCount: Int {
        dreamStore.dreams.filter { $0.isLucid }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 总梦境数
                StatCard(
                    icon: "book.fill",
                    value: "\(totalDreams)",
                    label: "总梦境"
                )
                
                // 本周记录
                StatCard(
                    icon: "calendar",
                    value: "\(thisWeek)",
                    label: "本周"
                )
                
                // 清醒梦
                StatCard(
                    icon: "sparkles",
                    value: "\(lucidCount)",
                    label: "清醒梦"
                )
                
                // 连续记录
                StreakCard()
            }
            .padding()
        }
        .navigationTitle("统计")
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct StreakCard: View {
    @EnvironmentObject var dreamStore: DreamStore
    
    var streak: Int {
        // 简化计算连续记录天数
        return min(dreamStore.dreams.count, 7)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("\(streak) 天")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            Text("连续记录")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: min(geometry.size.width * CGFloat(streak) / 7.0, geometry.size.width), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - 设置视图

struct WatchSettingsView: View {
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("complicationEnabled") private var complicationEnabled = true
    
    var body: some View {
        Form {
            Section("反馈") {
                Toggle("触觉反馈", isOn: $hapticEnabled)
            }
            
            Section("表盘") {
                Toggle("复杂功能", isOn: $complicationEnabled)
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
    }
}

// MARK: - 预览

#Preview {
    WatchContentView()
        .environmentObject(DreamStore())
        .environmentObject(HapticFeedback.shared)
}
