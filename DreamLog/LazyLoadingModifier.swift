//
//  LazyLoadingModifier.swift
//  DreamLog
//
//  Phase 45 - 延迟加载修饰符
//  滚动检测，按需渲染，优化长列表性能
//

import SwiftUI

// MARK: - 延迟加载修饰符

/// 延迟加载视图修饰符
struct LazyLoadingModifier: ViewModifier {
    let threshold: CGFloat
    let onAppear: () -> Void
    let onDisappear: () -> Void
    
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    onAppear()
                }
            }
            .onDisappear {
                onDisappear()
            }
    }
}

extension View {
    /// 应用延迟加载
    func lazyLoading(
        threshold: CGFloat = 0,
        onAppear: @escaping () -> Void = {},
        onDisappear: @escaping () -> Void = {}
    ) -> some View {
        modifier(LazyLoadingModifier(threshold: threshold, onAppear: onAppear, onDisappear: onDisappear))
    }
}

// MARK: - 虚拟化列表

/// 虚拟化列表容器
struct VirtualizedList<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let itemHeight: CGFloat
    let content: (Item) -> Content
    
    @State private var visibleRange: Range<Int> = 0..<0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                            .frame(height: itemHeight)
                            .lazyLoading(
                                onAppear: {
                                    // 预加载逻辑
                                }
                            )
                    }
                }
            }
            .onAppear {
                updateVisibleRange(for: geometry.size)
            }
            .onChange(of: geometry.size) { newSize in
                updateVisibleRange(for: newSize)
            }
        }
    }
    
    private func updateVisibleRange(for size: CGSize) {
        let visibleCount = Int(ceil(size.height / itemHeight)) + 2
        visibleRange = 0..<min(visibleCount, items.count)
    }
}

// MARK: - 图片延迟加载

/// 图片延迟加载视图
struct LazyImageView: View {
    let url: String?
    let placeholder: Image?
    let contentMode: ContentMode
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: String?,
        placeholder: Image? = nil,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let placeholder = placeholder {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !isLoading, let url = url else { return }
        
        // 检查缓存
        if let cached = ImageCacheManager.shared.image(forKey: url) {
            image = cached
            return
        }
        
        isLoading = true
        
        // 异步加载
        Task {
            // 这里应该是实际的网络加载
            // 现在只是演示缓存加载
            isLoading = false
        }
    }
}

// MARK: - 数据分页加载

/// 分页数据加载器
@MainActor
class PaginationLoader<Item>: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var error: String?
    
    let pageSize: Int
    private let loadBlock: (Int, Int) async throws -> [Item]
    
    init(pageSize: Int = 20, loadBlock: @escaping (Int, Int) async throws -> [Item]) {
        self.pageSize = pageSize
        self.loadBlock = loadBlock
    }
    
    /// 加载第一页
    func loadFirstPage() async {
        await loadPage(0)
    }
    
    /// 加载下一页
    func loadNextPage() async {
        guard !isLoading, hasMore else { return }
        await loadPage(items.count / pageSize)
    }
    
    /// 刷新
    func refresh() async {
        items.removeAll()
        hasMore = true
        await loadFirstPage()
    }
    
    private func loadPage(_ page: Int) async {
        isLoading = true
        error = nil
        
        do {
            let newItems = try await loadBlock(page, pageSize)
            items.append(contentsOf: newItems)
            hasMore = newItems.count == pageSize
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - 滚动检测

/// 滚动检测修饰符
struct ScrollDetectionModifier: ViewModifier {
    let onReachBottom: () -> Void
    let threshold: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
                }
            )
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                if value < -threshold {
                    onReachBottom()
                }
            }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// 检测滚动到底部
    func onReachBottom(threshold: CGFloat = 100, action: @escaping () -> Void) -> some View {
        modifier(ScrollDetectionModifier(onReachBottom: action, threshold: threshold))
    }
}

// MARK: - 预加载管理器

/// 预加载管理器
@MainActor
class PrefetchManager<Item: Identifiable>: ObservableObject {
    private var prefetchQueue: [Item] = []
    private let maxPrefetchCount: Int
    
    init(maxPrefetchCount: Int = 5) {
        self.maxPrefetchCount = maxPrefetchCount
    }
    
    /// 预加载项目
    func prefetch(items: [Item], currentIndex: Int) {
        // 清理队列
        prefetchQueue.removeAll()
        
        // 添加后续项目到预加载队列
        let startIndex = currentIndex + 1
        let endIndex = min(currentIndex + maxPrefetchCount, items.count)
        
        for index in startIndex..<endIndex {
            prefetchQueue.append(items[index])
        }
        
        // 执行预加载
        Task {
            for item in prefetchQueue {
                await prefetchItem(item)
            }
        }
    }
    
    func prefetchItem(_ item: Item) async {
        // 子类实现具体预加载逻辑
    }
}
