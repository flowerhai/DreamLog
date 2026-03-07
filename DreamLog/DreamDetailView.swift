//
//  DreamDetailView.swift
//  DreamLog
//
//  梦境详情页面 - 查看完整梦境和 AI 解析
//

import SwiftUI
import UIKit

struct DreamDetailView: View {
    let dream: Dream
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    @StateObject private var shareService = ShareService()
    @StateObject private var friendService = FriendService()
    @StateObject private var aiArtService = AIArtService.shared
    @StateObject private var speechService = SpeechSynthesisService.shared
    @State private var showingShareSheet = false
    @State private var showingPrivateShareSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingGenerateArt = false
    @State private var showingArtGallery = false
    @State private var showingGenerateWallpaper = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 头部信息
                HeaderSection(dream: dream)
                
                // 梦境内容
                ContentSection(dream: dream)
                
                // 语音播放
                AudioPlaybackSection(dreamContent: dream.content)
                
                // 标签和情绪
                TagsAndEmotionsSection(dream: dream)
                
                // 指标
                DreamMetricsSection(dream: dream)
                
                // AI 解析
                if let analysis = dream.aiAnalysis {
                    AIAnalysisSection(analysis: analysis)
                }
                
                // 梦境艺术
                if !aiArtService.getArts(for: dream.id).isEmpty {
                    DreamArtPreviewSection(
                        dream: dream,
                        arts: aiArtService.getArts(for: dream.id),
                        onViewGallery: { showingArtGallery = true }
                    )
                } else {
                    GenerateArtPromptSection(
                        onGenerate: { showingGenerateArt = true }
                    )
                }
                
                // 梦境壁纸
                WallpaperPromptSection(
                    onGenerate: { showingGenerateWallpaper = true }
                )
                
                // 操作按钮
                ActionButtons(
                    onShare: { showingShareSheet = true },
                    onPrivateShare: { showingPrivateShareSheet = true },
                    onEdit: { showingEditSheet = true },
                    onDelete: { showingDeleteAlert = true }
                )
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("梦境详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(dream: dream)
        }
        .sheet(isPresented: $showingPrivateShareSheet) {
            PrivateShareView(dream: dream, friendService: friendService)
        }
        .alert("删除梦境", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                dreamStore.deleteDream(dream)
                dismiss()
            }
        } message: {
            Text("这个操作无法撤销")
        }
        .sheet(isPresented: $showingGenerateArt) {
            GenerateArtSheet(dream: dream)
        }
        .sheet(isPresented: $showingArtGallery) {
            DreamArtGalleryView()
        }
        .sheet(isPresented: $showingGenerateWallpaper) {
            DreamWallpaperView(dream: dream)
        }
    }
}

// MARK: - 头部区域
struct HeaderSection: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dream.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if dream.isLucid {
                    Label("清醒梦", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            HStack(spacing: 16) {
                Label(dream.date.formatted(.dateTime.month().day().year()), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(dream.timeOfDay.rawValue, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 内容区域
struct ContentSection: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("梦境内容")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(dream.content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 语音播放区域
struct AudioPlaybackSection: View {
    let dreamContent: String
    @StateObject private var speechService = SpeechSynthesisService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                Text("🎧 聆听梦境")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 设置按钮
                NavigationLink(destination: SpeechSettingsView()) {
                    Image(systemName: "gear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 播放控制
            HStack(spacing: 16) {
                // 播放/暂停按钮
                Button(action: {
                    if speechService.isSpeaking {
                        speechService.togglePlayPause()
                    } else {
                        speechService.speak(dreamContent)
                    }
                }) {
                    Image(systemName: speechService.isSpeaking && !speechService.isPaused ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentColor)
                }
                
                // 状态和进度
                VStack(alignment: .leading, spacing: 4) {
                    Text(speechService.isSpeaking ? (speechService.isPaused ? "已暂停" : "播放中...") : "点击播放")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut, value: speechService.isSpeaking)
                    
                    // 波形动画
                    if speechService.isSpeaking && !speechService.isPaused {
                        HStack(spacing: 2) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.accentColor)
                                    .frame(width: 3, height: CGFloat(8 + Int.random(in: 0...8)))
                                    .animation(
                                        Animation.easeInOut(duration: 0.4)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.1),
                                        value: speechService.isSpeaking
                                    )
                            }
                        }
                        .frame(height: 20)
                    }
                }
                
                Spacer()
                
                // 停止按钮
                if speechService.isSpeaking {
                    Button(action: { speechService.stop() }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // 提示信息
            Text("💡 睡前聆听梦境，探索潜意识深处。可在设置中调整语速、音调和语音。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .onDisappear {
            speechService.stop()
        }
    }
}

// MARK: - 标签和情绪
struct TagsAndEmotionsSection: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标签
            if !dream.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(dream.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(16)
                        }
                    }
                }
            }
            
            // 情绪
            if !dream.emotions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("情绪")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(dream.emotions, id: \.rawValue) { emotion in
                            VStack(spacing: 4) {
                                Text(emotion.icon)
                                    .font(.system(size: 28))
                                Text(emotion.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 70)
                            .padding(.vertical, 8)
                            .background(Color(hex: emotion.color).opacity(0.3))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - 指标区域
struct DreamMetricsSection: View {
    let dream: Dream
    
    var body: some View {
        HStack(spacing: 20) {
            // 清晰度
            VStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { value in
                        Text(value <= dream.clarity ? "⭐" : "☆")
                            .font(.system(size: 16))
                    }
                }
                
                Text("清晰度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // 强度
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { value in
                    Text(value <= dream.intensity ? "🔥" : "○")
                        .font(.system(size: 16))
                }
            }
            
            Text("强度")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - AI 解析区域
struct AIAnalysisSection: View {
    let analysis: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI 梦境解析")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(analysis)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6B4E9A").opacity(0.3), Color(hex: "9B7EBD").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "6B4E9A").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 操作按钮
struct ActionButtons: View {
    let onShare: () -> Void
    let onPrivateShare: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 分享按钮行
            HStack(spacing: 12) {
                Button(action: onShare) {
                    Label("公开分享", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onPrivateShare) {
                    Label("好友分享", systemImage: "person.2.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            // 编辑和删除按钮行
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Label("编辑", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 50, height: 50)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - 梦境艺术预览区域
struct DreamArtPreviewSection: View {
    let dream: Dream
    let arts: [DreamArt]
    let onViewGallery: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(.pink)
                Text("梦境艺术")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onViewGallery) {
                    Text("查看全部")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            // 显示最新的艺术作品
            if let latestArt = arts.first {
                if let url = URL(string: latestArt.imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        case .failure, .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.title2)
                                        Text("点击生成梦境图像")
                                            .font(.caption)
                                    }
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                HStack {
                    Text(latestArt.style.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(arts.count) 幅作品")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "C471ED").opacity(0.2), Color(hex: "F64F59").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "C471ED").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 生成艺术提示区域
struct GenerateArtPromptSection: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI 梦境绘画")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("将你的梦境转化为精美的艺术作品")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Button(action: onGenerate) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("生成梦境图像")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "C471ED"), Color(hex: "F64F59")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6B4E9A").opacity(0.3), Color(hex: "9B7EBD").opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "6B4E9A").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationView {
        DreamDetailView(dream: Dream(
            title: "海边漫步",
            content: "我梦见自己在海边散步，海浪轻轻拍打着沙滩，阳光温暖地洒在身上，感觉非常平静和自由。远处有几只海鸥在飞翔，天空中飘着几朵白云。这个梦让我感到很放松。",
            originalText: "",
            date: Date(),
            tags: ["水", "海滩", "平静", "自由", "海鸥"],
            emotions: [.calm, .happy],
            clarity: 4,
            intensity: 3,
            aiAnalysis: "💧 水元素分析:\n水通常象征情绪和潜意识。平静的水面代表你内心平和，情绪稳定。\n\n😊 情绪分析:\n这个梦主要包含平静、快乐的情绪，反映了你近期的心理状态。\n\n💡 建议:\n1. 记录梦境时的感受\n2. 思考与现实生活的关联\n3. 关注反复出现的元素"
        ))
        .environmentObject(DreamStore())
    }
}
