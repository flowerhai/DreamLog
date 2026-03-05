//
//  GalleryView.swift
//  DreamLog
//
//  梦境画廊 - AI 生成的梦境图像
//

import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var aiService: AIService
    @State private var selectedDream: Dream?
    
    var dreams: [Dream] {
        dreamStore.dreams.filter { $0.aiImageUrl != nil }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if dreams.isEmpty {
                    EmptyStateView(
                        icon: "🎨",
                        title: "还没有梦境画作",
                        subtitle: "记录梦境后，用 AI 生成专属画作",
                        actionTitle: "记录梦境",
                        action: {}
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
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("梦境画廊 🎨")
            .sheet(item: $selectedDream) { dream in
                DreamImageView(dream: dream)
            }
        }
    }
}

// MARK: - 梦境图像卡片
struct DreamImageCard: View {
    let dream: Dream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图像占位符
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
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                )
            
            // 标题
            Text(dream.title)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(dream.date.formatted(.dateTime.month().day()))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 梦境图像详情
struct DreamImageView: View {
    let dream: Dream
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 大图
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
                            Image(systemName: "photo")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.5))
                        )
                    
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
                            HStack(spacing: 8) {
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
        }
    }
}

#Preview {
    GalleryView()
        .environmentObject(DreamStore())
        .environmentObject(AIService())
}
