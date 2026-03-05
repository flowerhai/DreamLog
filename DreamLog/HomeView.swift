//
//  HomeView.swift
//  DreamLog
//
//  首页 - 梦境列表和记录入口
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var speechService: SpeechService
    @State private var showingRecordSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 快速记录区域
                QuickRecordSection(showingRecordSheet: $showingRecordSheet)
                    .padding()
                
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .onChange(of: searchText) {
                        dreamStore.filterDreams(searchText: $0)
                    }
                
                // 热门标签
                TagFilterSection(tags: dreamStore.tags) { tag in
                    dreamStore.filterByTag(tag)
                }
                .padding(.vertical, 8)
                
                // 梦境列表
                DreamListSection(dreams: dreamStore.filteredDreams)
            }
            .navigationTitle("DreamLog 🌙")
            .sheet(isPresented: $showingRecordSheet) {
                RecordView()
            }
        }
    }
}

// MARK: - 快速记录区域
struct QuickRecordSection: View {
    @Binding var showingRecordSheet: Bool
    @EnvironmentObject var speechService: SpeechService
    
    var body: some View {
        VStack(spacing: 16) {
            Text("昨晚你梦见了什么？")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            // 语音按钮
            Button(action: {
                showingRecordSheet = true
            }) {
                VStack(spacing: 12) {
                    RecordingButtonView(isRecording: speechService.isRecording)
                    
                    Text(speechService.isRecording ? "松开结束" : "按住说话")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.01)
                    .onChanged { _ in
                        speechService.startRecording()
                    }
                    .onEnded { _ in
                        speechService.stopRecording()
                    }
            )
            
            // 文字输入
            Button(action: { showingRecordSheet = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("文字输入")
                }
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索梦境、标签...", text: $text)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 标签过滤
struct TagFilterSection: View {
    let tags: [String]
    let onTagSelected: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(tags.prefix(10)), id: \.self) { tag in
                    Button(action: { onTagSelected(tag) }) {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white.opacity(0.9))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 梦境列表
struct DreamListSection: View {
    let dreams: [Dream]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dreams, id: \.id) { dream in
                    DreamCard(dream: dream)
                }
            }
            .padding()
        }
    }
}

// MARK: - 梦境卡片
struct DreamCard: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和日期
            HStack {
                Text(dream.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if dream.isLucid {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(dream.date.formatted(.dateTime.month().day().hour().minute()))
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 内容预览
            Text(String(dream.content.prefix(100)))
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            // 标签
            HStack(spacing: 8) {
                ForEach(Array(dream.tags.prefix(3)), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            
            // 情绪和指标
            HStack {
                HStack(spacing: 4) {
                    ForEach(Array(dream.emotions.prefix(2)), id: \.self) { emotion in
                        Text(emotion.icon)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(String(repeating: "⭐", count: dream.clarity))
                        .font(.caption2)
                    Text(String(repeating: "🔥", count: dream.intensity))
                        .font(.caption2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(DreamStore())
        .environmentObject(SpeechService())
}

// MARK: - 录音按钮视图
struct RecordingButtonView: View {
    let isRecording: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6B4E9A"), Color(hex: "9B7EBD")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
            
            if isRecording {
                // 录音中动画
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 80 + CGFloat(index) * 20, height: 80 + CGFloat(index) * 20)
                        .scaleEffect(1 + Double(index) * 0.2)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3)
                        )
                }
            }
            
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)
        }
    }
}


