//
//  DreamPerformanceOptimizedViews.swift
//  DreamLog
//
//  Phase 89 Session 2: 列表性能优化
//  创建时间：2026-03-22
//

import SwiftUI
import SwiftData

// MARK: - 性能优化的梦境列表视图

/// 优化的梦境列表 - 使用 LazyVStack 和稳定的 ID
struct DreamListOptimized: View {
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var isLoading = true
    @State private var visibleRange: Range<Int> = 0..<0
    
    // 分页配置
    private let pageSize = 20
    @State private var displayedDreams: [Dream] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(displayedDreams.enumerated()), id: \.element.id) { index, dream in
                    DreamCardOptimized(dream: dream)
                        .id(dream.id)  // 稳定的标识符，减少不必要的重建
                        .onAppear {
                            // 预加载下一页数据
                            if index >= displayedDreams.count - 5 {
                                loadMoreDreams()
                            }
                        }
                }
                
                if isLoading {
                    LoadingProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding()
        }
        .task {
            await loadInitialDreams()
        }
        .refreshable {
            await refreshDreams()
        }
    }
    
    private func loadInitialDreams() async {
        displayedDreams = Array(dreams.prefix(pageSize))
        isLoading = false
    }
    
    private func loadMoreDreams() {
        guard !isLoading else { return }
        let nextIndex = displayedDreams.count
        guard nextIndex < dreams.count else { return }
        
        isLoading = true
        let endIndex = min(nextIndex + pageSize, dreams.count)
        displayedDreams.append(contentsOf: dreams[nextIndex..<endIndex])
        isLoading = false
    }
    
    private func refreshDreams() async {
        displayedDreams = Array(dreams.prefix(pageSize))
    }
}

// MARK: - 优化的梦境卡片

/// 性能优化的梦境卡片组件
struct DreamCardOptimized: View {
    let dream: Dream
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题行
            HStack {
                Text(dream.title ?? "无标题梦境")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // 清醒梦标记
                if dream.isLucid {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            // 内容预览
            Text(dream.content?.prefix(100) ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // 标签和情绪
            HStack {
                ForEach(dream.tags.prefix(3), id: \.self) { tag in
                    TagBadgeOptimized(tag: tag)
                }
                
                Spacer()
                
                // 日期
                Text(dream.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackground)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white
    }
}

// MARK: - 优化的标签徽章

/// 性能优化的标签徽章组件
struct TagBadgeOptimized: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.2))
            )
            .foregroundColor(.purple)
    }
}

// MARK: - 优化的梦境网格 (画廊视图)

/// 性能优化的梦境网格视图
struct DreamGridOptimized: View {
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(dreams) { dream in
                    DreamThumbnailOptimized(dream: dream)
                        .aspectRatio(1, contentMode: .fit)
                        .id(dream.id)
                }
            }
            .padding()
        }
    }
}

// MARK: - 优化的梦境缩略图

/// 性能优化的梦境缩略图
struct DreamThumbnailOptimized: View {
    let dream: Dream
    
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: 8)
                .fill(gradientBackground)
            
            if let image = image {
                // 加载完成的图片
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if isLoading {
                // 加载指示器
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                // 默认图标
                Image(systemName: "moon.stars.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .cornerRadius(8)
        .task {
            await loadImage()
        }
    }
    
    private var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func loadImage() async {
        isLoading = true
        // 使用图片缓存服务加载
        if let cachedImage = await DreamImageCacheService.shared.image(for: dream.id) {
            image = cachedImage
        }
        isLoading = false
    }
}

// MARK: - 优化的洞察卡片

/// 性能优化的洞察卡片
struct InsightCardOptimized: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 加载进度视图

/// 加载进度指示器
struct LoadingProgressView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
    }
}

// MARK: - 性能优化修饰符

/// 延迟加载修饰符 - 视图进入屏幕时才开始加载
struct LazyLoadingModifier: ViewModifier {
    @State private var hasAppeared = false
    
    let onAppear: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    onAppear()
                }
            }
    }
}

extension View {
    /// 添加延迟加载支持
    func onLazyAppear(perform action: @escaping () -> Void) -> some View {
        modifier(LazyLoadingModifier(onAppear: action))
    }
}

// MARK: - 预览

#Preview {
    NavigationStack {
        DreamListOptimized()
            .modelContainer(for: Dream.self, inMemory: true)
    }
}

#Preview("Grid") {
    NavigationStack {
        DreamGridOptimized()
            .modelContainer(for: Dream.self, inMemory: true)
    }
}
