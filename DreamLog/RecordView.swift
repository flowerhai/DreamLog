//
//  RecordView.swift
//  DreamLog
//
//  梦境记录界面
//

import SwiftUI

struct RecordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var aiService: AIService
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedTags: [String] = []
    @State private var selectedEmotions: [Emotion] = []
    @State private var clarity: Int = 3
    @State private var intensity: Int = 3
    @State private var isLucid: Bool = false
    @State private var isSaving: Bool = false
    @State private var showingSaveSuccess = false
    
    var commonTags = ["水", "飞行", "追逐", "人", "动物", "家", "学校", "工作", "自然", "城市"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 时间和日期
                    DateTimeSection()
                    
                    // 梦境内容
                    ContentSection(
                        content: $content,
                        transcription: speechService.transcription
                    )
                    
                    // 标签选择
                    TagSection(
                        selectedTags: $selectedTags,
                        commonTags: commonTags
                    )
                    
                    // 情绪选择
                    EmotionSection(selectedEmotions: $selectedEmotions)
                    
                    // 清晰度和强度
                    MetricsSection(
                        clarity: $clarity,
                        intensity: $intensity
                    )
                    
                    // 清醒梦开关
                    LucidDreamToggle(isLucid: $isLucid)
                    
                    // AI 解析预览
                    if !content.isEmpty {
                        AIPreviewSection(content: content)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("记录梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveDream()
                    }
                    .disabled(content.isEmpty || isSaving)
                }
            }
            .overlay(
                Group {
                    if showingSaveSuccess {
                        SaveSuccessOverlay(onDismiss: {
                            showingSaveSuccess = false
                            dismiss()
                        })
                    }
                }
            )
        }
    }
    
    // MARK: - 保存梦境
    private func saveDream() {
        isSaving = true
        
        // 生成标题
        let generatedTitle = title.isEmpty ? String(content.prefix(10)) + "..." : title
        
        let dream = Dream(
            title: generatedTitle,
            content: content,
            originalText: content,
            date: Date(),
            timeOfDay: .from(date: Date()),
            tags: selectedTags,
            emotions: selectedEmotions,
            clarity: clarity,
            intensity: intensity,
            isLucid: isLucid
        )
        
        dreamStore.addDream(dream)
        
        // 显示成功动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            showingSaveSuccess = true
        }
    }
}

// MARK: - 日期时间部分
struct DateTimeSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formatted(.dateTime.weekday()))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(Date().formatted(.dateTime.year().month().day().hour().minute()))
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - 内容输入部分
struct ContentSection: View {
    @Binding var content: String
    let transcription: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境内容")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("描述你的梦境...", text: $content, axis: .vertical)
                .font(.body)
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .lineLimit(10...20)
            
            if !transcription.isEmpty {
                Divider()
                Text("语音识别：\(transcription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 标签选择部分
struct TagSection: View {
    @Binding var selectedTags: [String]
    let commonTags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("添加标签")
                .font(.headline)
                .foregroundColor(.white)
            
            FlowLayout(spacing: 8) {
                ForEach(commonTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.removeAll { $0 == tag }
                        } else {
                            selectedTags.append(tag)
                        }
                    }) {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedTags.contains(tag)
                                    ? Color.accentColor
                                    : Color.white.opacity(0.1)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 情绪选择部分
struct EmotionSection: View {
    @Binding var selectedEmotions: [Emotion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境情绪")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(Array(Emotion.allCases.prefix(6)), id: \.self) { emotion in
                    Button(action: {
                        if selectedEmotions.contains(emotion) {
                            selectedEmotions.removeAll { $0 == emotion }
                        } else {
                            selectedEmotions.append(emotion)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(emotion.icon)
                                .font(.system(size: 32))
                            Text(emotion.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .frame(width: 60)
                        .padding(.vertical, 8)
                        .background(
                            selectedEmotions.contains(emotion)
                                ? Color(hex: emotion.color)
                                : Color.white.opacity(0.1)
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 指标部分
struct MetricsSection: View {
    @Binding var clarity: Int
    @Binding var intensity: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 清晰度
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("清晰度")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(clarity)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Text(value <= clarity ? "⭐" : "☆")
                            .font(.system(size: 24))
                            .onTapGesture {
                                clarity = value
                            }
                    }
                }
            }
            
            // 强度
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("强度")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(intensity)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { value in
                        Text(value <= intensity ? "🔥" : "○")
                            .font(.system(size: 24))
                            .onTapGesture {
                                intensity = value
                            }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 清醒梦开关
struct LucidDreamToggle: View {
    @Binding var isLucid: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("清醒梦")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("你知道自己在做梦")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isLucid)
                .toggleStyle(.switch)
                .tint(.yellow)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - AI 预览部分
struct AIPreviewSection: View {
    @EnvironmentObject var aiService: AIService
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI 初步分析")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            if aiService.isAnalyzing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.accentColor)
                
                Text("正在分析梦境...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("保存后将生成详细解析")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .onAppear {
            if !content.isEmpty && !aiService.isAnalyzing {
                Task {
                    await aiService.analyzeDream(content: content, tags: [], emotions: [])
                }
            }
        }
    }
}

// MARK: - 保存成功覆盖层
struct SaveSuccessOverlay: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("🌙")
                    .font(.system(size: 80))
                    .scaleEffect(1.2)
                
                Text("梦境已记录")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("祝你好梦")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                
                Button("好的") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
            .padding(40)
            .background(Color(hex: "2D2D44"))
            .cornerRadius(24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    RecordView()
        .environmentObject(DreamStore())
        .environmentObject(SpeechService())
        .environmentObject(AIService())
}
