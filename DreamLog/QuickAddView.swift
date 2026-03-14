//
//  QuickAddView.swift
//  DreamLog
//
//  Phase 43 - 快速记录梦境界面
//

import SwiftUI

/// 快速记录梦境视图
struct QuickAddView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: Mood = .calm
    @State private var tags: String = ""
    @State private var isLucid = false
    @State private var clarity: Int = 3
    @State private var isRecording = false
    @State private var showSuccess = false
    
    @StateObject private var speechService = SpeechService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 标题输入
                        titleField
                        
                        // 语音输入按钮
                        voiceButton
                        
                        // 内容输入
                        contentField
                        
                        // 情绪选择
                        moodSelector
                        
                        // 标签输入
                        tagsField
                        
                        // 清醒梦开关
                        lucidToggle
                        
                        // 清晰度滑块
                        claritySlider
                        
                        // 保存按钮
                        saveButton
                    }
                    .padding()
                }
            }
            .background(Color(hex: "1A1A2E"))
            .navigationTitle("快速记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .alert("保存成功", isPresented: $showSuccess) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("梦境已保存到梦境列表")
            }
        }
    }
    
    // MARK: - 标题输入
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标题")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("给梦境起个名字（可选）", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color(hex: "16213E"))
                .cornerRadius(12)
        }
    }
    
    // MARK: - 语音输入按钮
    
    private var voiceButton: some View {
        Button(action: toggleRecording) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color(hex: "FF6B6B") : Color(hex: "9B7EBD"))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(isRecording ? "停止录音" : "语音输入")
                    .font(.caption)
                    .foregroundColor(isRecording ? Color(hex: "FF6B6B") : Color(hex: "9B7EBD"))
            }
        }
        .padding(.vertical, 10)
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        // TODO: 实现语音识别功能
    }
    
    // MARK: - 内容输入
    
    private var contentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境内容")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $content)
                .frame(minHeight: 150)
                .padding()
                .background(Color(hex: "16213E"))
                .cornerRadius(12)
        }
    }
    
    // MARK: - 情绪选择
    
    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("情绪")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    MoodButton(mood: mood, isSelected: selectedMood == mood) {
                        selectedMood = mood
                    }
                }
            }
        }
    }
    
    // MARK: - 标签输入
    
    private var tagsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("用逗号分隔多个标签", text: $tags)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color(hex: "16213E"))
                .cornerRadius(12)
        }
    }
    
    // MARK: - 清醒梦开关
    
    private var lucidToggle: some View {
        HStack {
            Text("清醒梦")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isLucid)
                .labelsHidden()
        }
        .padding()
        .background(Color(hex: "16213E"))
        .cornerRadius(12)
    }
    
    // MARK: - 清晰度滑块
    
    private var claritySlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("清晰度")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(clarity)/5")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                ForEach(1...5, id: \.self) { value in
                    Image(systemName: value <= clarity ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(value <= clarity ? Color(hex: "FFC000") : .gray)
                        .onTapGesture {
                            clarity = value
                        }
                }
            }
        }
        .padding()
        .background(Color(hex: "16213E"))
        .cornerRadius(12)
    }
    
    // MARK: - 保存按钮
    
    private var saveButton: some View {
        Button(action: saveDream) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                Text("保存梦境")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "9B7EBD"))
            .cornerRadius(12)
        }
        .disabled(content.isEmpty)
        .opacity(content.isEmpty ? 0.5 : 1.0)
    }
    
    // MARK: - 保存梦境
    
    private func saveDream() {
        let dream = Dream(
            title: title.isEmpty ? nil : title,
            content: content,
            mood: selectedMood,
            tags: tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            isLucid: isLucid,
            clarity: clarity
        )
        
        dreamStore.addDream(dream)
        showSuccess = true
        
        // 重置表单
        resetForm()
    }
    
    private func resetForm() {
        title = ""
        content = ""
        selectedMood = .calm
        tags = ""
        isLucid = false
        clarity = 3
    }
}

// MARK: - 情绪按钮

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "9B7EBD") : Color(hex: "16213E"))
            .cornerRadius(8)
        }
    }
}

// MARK: - 预览

#Preview {
    QuickAddView()
        .environmentObject(DreamStore())
}
