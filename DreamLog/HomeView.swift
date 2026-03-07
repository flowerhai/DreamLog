//
//  HomeView.swift
//  DreamLog
//
//  首页 - 梦境列表和记录入口
//

import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var speechService: SpeechService
    @State private var showingRecordSheet = false
    @State private var searchText = ""
    @State private var showingAdvancedSearch = false
    @AppStorage("siriTipDismissed") private var siriTipDismissed = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 快速记录区域
                QuickRecordSection(showingRecordSheet: $showingRecordSheet)
                    .padding()
                
                // Siri 快捷指令提示
                if !siriTipDismissed {
                    SiriShortcutTipCard(onDismiss: {
                        siriTipDismissed = true
                    })
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // 搜索栏
                HStack {
                    SearchBar(text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            dreamStore.filterDreams(searchText: newValue)
                        }
                    
                    Button(action: { showingAdvancedSearch = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
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
            .sheet(isPresented: $showingAdvancedSearch) {
                AdvancedSearchView()
                    .environmentObject(dreamStore)
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
                        
                        if speechService.isRecording {
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
                        
                        Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Text(speechService.isRecording ? "松开结束" : "按住说话")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .longPressAction {
                speechService.startRecording()
            } onRelease: {
                speechService.stopRecording()
            }
            
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
                    NavigationLink(destination: DreamDetailView(dream: dream)) {
                        DreamCard(dream: dream)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - 梦境卡片
struct DreamCard: View {
    let dream: Dream
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和操作
            HStack {
                Text(dream.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if dream.isLucid {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                    }
                    
                    // 分享按钮
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
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
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(dream: dream)
        }
    }
}

// MARK: - 分享弹窗
struct ShareSheet: View {
    let dream: Dream
    @Environment(\.dismiss) var dismiss
    @StateObject private var shareService = ShareService()
    @State private var selectedStyle: ShareCardStyle = .dreamy
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 样式选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择卡片样式")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ShareCardStyle.allCases, id: \.self) { style in
                                    StyleButton(
                                        style: style,
                                        isSelected: selectedStyle == style
                                    ) {
                                        selectedStyle = style
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 卡片预览
                    if isGenerating {
                        ProgressView("生成分享图片...")
                            .progressViewStyle(.circular)
                            .tint(.accentColor)
                            .frame(height: 300)
                    } else if let image = generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 375)
                            .cornerRadius(12)
                            .shadow(radius: 20)
                    } else {
                        DreamShareCard(dream: dream, style: selectedStyle)
                            .shadow(radius: 20)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 16) {
                        Button(action: saveToPhotos) {
                            Label("保存到相册", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isGenerating || generatedImage == nil)
                        
                        Button(action: shareImage) {
                            Label("分享", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(isGenerating || generatedImage == nil)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("分享梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                generatePreview()
            }
            .onChange(of: selectedStyle) { _, _ in
                generatePreview()
            }
        }
    }
    
    private func generatePreview() {
        isGenerating = true
        Task {
            generatedImage = await shareService.generateShareImage(dream: dream, style: selectedStyle)
            isGenerating = false
        }
    }
    
    private func saveToPhotos() {
        guard let image = generatedImage else { return }
        Task {
            await shareService.saveToPhotos(image: image)
        }
    }
    
    private func shareImage() {
        guard let image = generatedImage else { return }
        let shareText = shareService.getShareText(dream: dream)
        let activityVC = UIActivityViewController(
            activityItems: [image, shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - 样式按钮
struct StyleButton: View {
    let style: ShareCardStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: style.backgroundColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    .shadow(radius: isSelected ? 8 : 4)
                
                Text(style.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(DreamStore())
        .environmentObject(SpeechService())
}
