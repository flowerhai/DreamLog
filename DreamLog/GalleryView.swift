//
//  GalleryView.swift
//  DreamLog
//
//  梦境画廊 - AI 生成的梦境图像 (支持远程图片加载)
//

import SwiftUI
import UIKit

struct GalleryView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var aiService: AIService
    @State private var selectedDream: Dream?
    @State private var showingGenerateSheet = false
    
    var dreams: [Dream] {
        dreamStore.dreams.filter { $0.aiImageUrl != nil }
    }
    
    var dreamsWithoutImages: [Dream] {
        dreamStore.dreams.filter { $0.aiImageUrl == nil }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if dreams.isEmpty {
                    EmptyStateView(
                        icon: "🎨",
                        title: "还没有梦境画作",
                        subtitle: "记录梦境后，用 AI 生成专属画作",
                        actionTitle: dreamsWithoutImages.isEmpty ? "记录梦境" : "生成画作",
                        action: {
                            if dreamsWithoutImages.isEmpty {
                                // 跳转到记录页面
                            } else {
                                showingGenerateSheet = true
                            }
                        }
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(dreams, id: \.id) { dream in
                                DreamImageCard(dream: dream)
                                    .onTapGesture {
                                        selectedDream = dream
                                    }
                            }
                            
                            // 添加新画作按钮
                            if !dreamsWithoutImages.isEmpty {
                                Button(action: { showingGenerateSheet = true }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.accentColor)
                                        Text("生成新画作")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fill)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.accentColor, lineWidth: 2)
                                            .background(Color.accentColor.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("梦境画廊 🎨")
            .sheet(item: $selectedDream) { dream in
                DreamImageView(dream: dream)
            }
            .sheet(isPresented: $showingGenerateSheet) {
                GenerateImageView(dreams: dreamsWithoutImages, aiService: aiService)
            }
        }
    }
}

// MARK: - 梦境图像卡片
struct DreamImageCard: View {
    let dream: Dream
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图像
            Group {
                if isLoading {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6B4E9A"), Color(hex: "9B7EBD")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        )
                } else if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                } else if loadFailed {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                        .aspectRatio(1, contentMode: .fill)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .cornerRadius(8)
                }
            }
            
            // 标题
            Text(dream.title)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(dream.date.formatted(.dateTime.month().day()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let urlString = dream.aiImageUrl,
              let url = URL(string: urlString) else {
            loadFailed = true
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                loadFailed = true
                isLoading = false
                return
            }
            
            loadedImage = image
        } catch {
            print("❌ 加载图片失败：\(error)")
            loadFailed = true
        }
        
        isLoading = false
    }
}

// MARK: - 梦境图像详情
struct DreamImageView: View {
    let dream: Dream
    @Environment(\.dismiss) var dismiss
    @StateObject private var shareService = ShareService()
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var showingShareSheet = false
    @State private var selectedStyle: ShareCardStyle = .dreamy
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 大图
                    Group {
                        if isLoading {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6B4E9A"), Color(hex: "9B7EBD")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .aspectRatio(1, contentMode: .fill)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                )
                        } else if let image = loadedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(16)
                                .shadow(radius: 20)
                        } else {
                            // 显示分享卡片作为备选
                            DreamShareCard(dream: dream, style: selectedStyle)
                                .shadow(radius: 20)
                        }
                    }
                    
                    // 梦境信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text(dream.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(dream.content)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 16) {
                            Label("\(dream.clarity)", systemImage: "star.fill")
                                .foregroundColor(.yellow)
                            Label("\(dream.intensity)", systemImage: "flame.fill")
                                .foregroundColor(.orange)
                        }
                        
                        if !dream.tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(dream.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // AI 解析
                    if let analysis = dream.aiAnalysis {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                Text("AI 解析")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Text(analysis)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    
                    // 操作按钮
                    HStack(spacing: 12) {
                        Button(action: { showingShareSheet = true }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        if loadedImage != nil {
                            Button(action: saveToPhotos) {
                                Label("保存", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("梦境详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(dream: dream)
            }
            .task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        guard let urlString = dream.aiImageUrl,
              let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                isLoading = false
                return
            }
            
            loadedImage = image
        } catch {
            print("❌ 加载图片失败：\(error)")
        }
        
        isLoading = false
    }
    
    private func saveToPhotos() {
        guard let image = loadedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

// MARK: - 生成图像视图
struct GenerateImageView: View {
    let dreams: [Dream]
    @EnvironmentObject var aiService: AIService
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDreamId: UUID?
    @State private var isGenerating = false
    @State private var generatedImageUrl: String?
    @State private var generationProgress: Double = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 说明
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                        
                        Text("生成梦境画作")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("选择一个梦境，AI 将为你生成专属画作")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 梦境列表
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择梦境")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(dreams, id: \.id) { dream in
                            Button(action: { selectedDreamId = dream.id }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dream.title)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Text(dream.date.formatted(.dateTime.month().day()))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedDreamId == dream.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedDreamId == dream.id ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    
                    // 生成进度
                    if isGenerating {
                        VStack(spacing: 12) {
                            ProgressView(value: generationProgress)
                                .progressViewStyle(.linear)
                                .tint(.accentColor)
                            
                            Text("正在绘制你的梦境...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // 生成按钮
                    Button(action: generateImage) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                Text("生成中...")
                            } else {
                                Image(systemName: "wand.and.stars")
                                Text("生成画作")
                            }
                            Spacer()
                        }
                        .padding()
                        .background(isGenerating || selectedDreamId == nil ? Color.secondary : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isGenerating || selectedDreamId == nil)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("生成画作")
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
    
    private func generateImage() {
        guard let dreamId = selectedDreamId,
              let dream = aiService.generateImagePromptForDream(id: dreamId) else { return }
        
        isGenerating = true
        
        Task {
            // 模拟生成进度
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                generationProgress = Double(i) / 10.0
            }
            
            // 调用 AI 服务生成图像
            let prompt = aiService.generateImagePrompt(from: dream)
            _ = await aiService.generateImage(prompt: prompt)
            
            isGenerating = false
            dismiss()
        }
    }
}

// MARK: - AIService 扩展
extension AIService {
    func generateImagePromptForDream(id: UUID) -> Dream? {
        // 这里需要从 DreamStore 获取梦境
        // 为了简化，返回 nil，实际使用时需要传入 DreamStore
        return nil
    }
}

#Preview {
    GalleryView()
        .environmentObject(DreamStore())
        .environmentObject(AIService())
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 80))
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(actionTitle) {
                action()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
