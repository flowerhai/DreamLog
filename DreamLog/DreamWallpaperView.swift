//
//  DreamWallpaperView.swift
//  DreamLog
//
//  梦境壁纸生成视图
//

import SwiftUI

// MARK: - 壁纸生成主视图

struct DreamWallpaperView: View {
    let dream: Dream
    @ObservedObject private var wallpaperService = DreamWallpaperService.shared
    @State private var selectedStyle: DreamWallpaper.WallpaperStyle = .gradient
    @State private var selectedSize: DreamWallpaper.WallpaperSize = .universal
    @State private var showingGenerator = false
    @State private var showingLibrary = false
    
    var body: some View {
        NavigationView {
            Form {
                // 预览区域
                Section {
                    WallpaperPreviewCard(
                        dream: dream,
                        style: selectedStyle,
                        size: selectedSize
                    )
                }
                
                // 风格选择
                Section("壁纸风格") {
                    ForEach(DreamWallpaper.WallpaperStyle.allCases, id: \.self) { style in
                        StyleSelectionRow(
                            style: style,
                            isSelected: selectedStyle == style
                        ) {
                            selectedStyle = style
                        }
                    }
                }
                
                // 尺寸选择
                Section("设备尺寸") {
                    Picker("尺寸", selection: $selectedSize) {
                        ForEach(DreamWallpaper.WallpaperSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(selectedSize.aspectRatio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 操作按钮
                Section {
                    Button(action: startGeneration) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("生成壁纸")
                        }
                    }
                    .disabled(wallpaperService.isGenerating)
                    
                    if !wallpaperService.wallpapers.isEmpty {
                        NavigationLink(destination: WallpaperLibraryView()) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("我的壁纸库")
                                Spacer()
                                Text("\(wallpaperService.wallpapers.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 说明
                Section("提示") {
                    Text("• 壁纸将根据梦境内容和情绪自动生成")
                    Text("• 选择不同的风格来获得不同的视觉效果")
                    Text("• 生成的壁纸可以保存到相册或设置为锁屏")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("梦境壁纸")
            .sheet(isPresented: $showingGenerator) {
                WallpaperGeneratorView(
                    dream: dream,
                    style: selectedStyle,
                    size: selectedSize
                )
            }
        }
    }
    
    private func startGeneration() {
        showingGenerator = true
    }
}

// MARK: - 壁纸预览卡片

struct WallpaperPreviewCard: View {
    let dream: Dream
    let style: DreamWallpaper.WallpaperStyle
    let size: DreamWallpaper.WallpaperSize
    
    var body: some View {
        VStack(spacing: 12) {
            // 手机轮廓
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 280)
                
                // 壁纸预览
                WallpaperStylePreview(style: style, dream: dream)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .frame(width: 136, height: 276)
                
                // 边框
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 280)
            }
            
            Text("\(size.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - 风格预览

struct WallpaperStylePreview: View {
    let style: DreamWallpaper.WallpaperStyle
    let dream: Dream
    
    var body: some View {
        Group {
            switch style {
            case .minimalist:
                MinimalistPreview(dream: dream)
            case .artistic:
                ArtisticPreview(dream: dream)
            case .gradient:
                GradientPreview(dream: dream)
            case .nature:
                NaturePreview(dream: dream)
            case .abstract:
                AbstractPreview(dream: dream)
            case .cosmic:
                CosmicPreview(dream: dream)
            }
        }
    }
}

// MARK: - 各种风格预览实现

struct MinimalistPreview: View {
    let dream: Dream
    
    var body: some View {
        VStack {
            Spacer()
            Text(dream.title.isEmpty ? "梦境" : dream.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct ArtisticPreview: View {
    let dream: Dream
    
    var body: some View {
        ZStack {
            Color.purple.opacity(0.3)
            
            // 模拟艺术笔触
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(dream.primaryEmotion?.color ?? Color.purple)
                    .frame(width: CGFloat.random(in: 20...60))
                    .offset(
                        x: CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: -100...100)
                    )
                    .blur(radius: 5)
            }
        }
    }
}

struct GradientPreview: View {
    let dream: Dream
    
    var body: some View {
        LinearGradient(
            colors: [
                dream.primaryEmotion?.color ?? Color.purple,
                Color.blue.opacity(0.6),
                Color.indigo.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct NaturePreview: View {
    let dream: Dream
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.6), Color.blue.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // 模拟叶子
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "leaf.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
                    .rotationEffect(.degrees(Double.random(in: -45...45)))
                    .offset(
                        x: CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: -100...100)
                    )
            }
        }
    }
}

struct AbstractPreview: View {
    let dream: Dream
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
            
            // 几何图形
            ForEach(0..<4, id: \.self) { i in
                Group {
                    if i % 2 == 0 {
                        Rectangle()
                    } else {
                        Circle()
                    }
                }
                .stroke(dream.primaryEmotion?.color ?? Color.purple, lineWidth: 2)
                .frame(width: CGFloat.random(in: 30...80), height: CGFloat.random(in: 30...80))
                .offset(
                    x: CGFloat.random(in: -50...50),
                    y: CGFloat.random(in: -100...100)
                )
                .rotationEffect(.degrees(Double.random(in: 0...360)))
            }
        }
    }
}

struct CosmicPreview: View {
    let dream: Dream
    
    var body: some View {
        ZStack {
            Color.black
            
            // 星星
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...1.0)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...136),
                        y: CGFloat.random(in: 0...276)
                    )
            }
            
            // 星云
            RadialGradient(
                colors: [
                    Color.purple.opacity(0.4),
                    Color.blue.opacity(0.2),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 80
            )
        }
    }
}

// MARK: - 风格选择行

struct StyleSelectionRow: View {
    let style: DreamWallpaper.WallpaperStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.body)
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 壁纸生成器视图

struct WallpaperGeneratorView: View {
    let dream: Dream
    let style: DreamWallpaper.WallpaperStyle
    let size: DreamWallpaper.WallpaperSize
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var wallpaperService = DreamWallpaperService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 进度指示器
                ProgressView(value: wallpaperService.generationProgress)
                    .progressViewStyle(.linear)
                    .scaleEffect(y: 2)
                    .padding(.horizontal)
                
                // 进度百分比
                Text("\(Int(wallpaperService.generationProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // 生成步骤
                VStack(spacing: 12) {
                    GenerationStepView(
                        title: "准备画布",
                        isCompleted: wallpaperService.generationProgress >= 0.1,
                        isCurrent: wallpaperService.generationProgress >= 0 && wallpaperService.generationProgress < 0.3
                    )
                    
                    GenerationStepView(
                        title: "生成背景",
                        isCompleted: wallpaperService.generationProgress >= 0.3,
                        isCurrent: wallpaperService.generationProgress >= 0.1 && wallpaperService.generationProgress < 0.3
                    )
                    
                    GenerationStepView(
                        title: "添加梦境元素",
                        isCompleted: wallpaperService.generationProgress >= 0.6,
                        isCurrent: wallpaperService.generationProgress >= 0.3 && wallpaperService.generationProgress < 0.6
                    )
                    
                    GenerationStepView(
                        title: "应用风格效果",
                        isCompleted: wallpaperService.generationProgress >= 0.8,
                        isCurrent: wallpaperService.generationProgress >= 0.6 && wallpaperService.generationProgress < 0.8
                    )
                    
                    GenerationStepView(
                        title: "渲染最终图像",
                        isCompleted: wallpaperService.generationProgress >= 1.0,
                        isCurrent: wallpaperService.generationProgress >= 0.8 && wallpaperService.generationProgress < 1.0
                    )
                }
                .padding()
                
                Spacer()
                
                // 完成按钮
                if wallpaperService.generationProgress >= 1.0 {
                    VStack(spacing: 12) {
                        Button(action: saveToPhotos) {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: setAsWallpaper) {
                            Label("设置为锁屏", systemImage: "lock.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("生成壁纸")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if wallpaperService.generationProgress >= 1.0 {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await wallpaperService.generateWallpaper(
                        from: dream,
                        style: style,
                        size: size
                    )
                }
            }
        }
    }
    
    private func saveToPhotos() {
        guard let wallpaper = wallpaperService.currentWallpaper else { return }
        
        Task {
            do {
                try await wallpaperService.saveWallpaperToPhotos(wallpaper)
                // 显示成功提示
                print("✅ 壁纸已保存到相册")
            } catch {
                print("❌ 保存失败：\(error)")
                // 实际应该显示 alert
            }
        }
    }
    
    private func setAsWallpaper() {
        guard let wallpaper = wallpaperService.currentWallpaper else { return }
        
        // iOS 限制：需要通过分享菜单让用户手动设置
        wallpaperService.setAsWallpaper(wallpaper)
        // 提示用户通过分享功能设置壁纸
    }
}

// MARK: - 生成步骤视图

struct GenerationStepView: View {
    let title: String
    let isCompleted: Bool
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if isCurrent {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray.opacity(0.3))
            }
            
            // 标题
            Text(title)
                .foregroundColor(isCurrent ? .primary : .secondary)
                .fontWeight(isCurrent ? .semibold : .regular)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 壁纸库视图

struct WallpaperLibraryView: View {
    @ObservedObject private var wallpaperService = DreamWallpaperService.shared
    @State private var selectedWallpaper: DreamWallpaper?
    @State private var showingGrid = true
    
    var body: some View {
        Group {
            if showingGrid {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(wallpaperService.wallpapers) { wallpaper in
                        WallpaperGridItem(wallpaper: wallpaper)
                            .onTapGesture {
                                selectedWallpaper = wallpaper
                            }
                    }
                }
                .padding()
            } else {
                List(wallpaperService.wallpapers) { wallpaper in
                    WallpaperListItem(wallpaper: wallpaper)
                        .onTapGesture {
                            selectedWallpaper = wallpaper
                        }
                }
            }
        }
        .navigationTitle("我的壁纸")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingGrid.toggle() }) {
                    Image(systemName: showingGrid ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper)
        }
    }
}

// MARK: - 壁纸网格项

struct WallpaperGridItem: View {
    let wallpaper: DreamWallpaper
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                
                // 壁纸预览
                WallpaperStylePreview(style: wallpaper.style, dream: Dream.sample)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(height: 200)
            
            Text(wallpaper.style.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 壁纸列表项

struct WallpaperListItem: View {
    let wallpaper: DreamWallpaper
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            WallpaperStylePreview(style: wallpaper.style, dream: Dream.sample)
                .frame(width: 60, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.style.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(wallpaper.size.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(wallpaper.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if wallpaper.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 壁纸详情视图

struct WallpaperDetailView: View {
    let wallpaper: DreamWallpaper
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var wallpaperService = DreamWallpaperService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 大预览
                    WallpaperStylePreview(style: wallpaper.style, dream: Dream.sample)
                        .frame(height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                    
                    // 信息
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "风格", value: wallpaper.style.rawValue)
                        InfoRow(label: "尺寸", value: wallpaper.size.rawValue)
                        InfoRow(label: "比例", value: wallpaper.size.aspectRatio)
                        InfoRow(label: "创建时间", value: wallpaper.createdAt.formatted(.dateTime))
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        Button(action: toggleFavorite) {
                            Label(
                                wallpaper.isFavorite ? "取消收藏" : "收藏",
                                systemImage: wallpaper.isFavorite ? "heart.slash" : "heart"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: saveToPhotos) {
                            Label("保存到相册", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: setAsWallpaper) {
                            Label("设置为锁屏", systemImage: "lock.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: deleteWallpaper, role: .destructive) {
                            Label("删除", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("壁纸详情")
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
    
    private func toggleFavorite() {
        wallpaperService.toggleFavorite(wallpaper)
    }
    
    private func saveToPhotos() {
        Task {
            do {
                try await wallpaperService.saveWallpaperToPhotos(wallpaper)
                print("✅ 壁纸已保存到相册")
            } catch {
                print("❌ 保存失败：\(error)")
            }
        }
    }
    
    private func setAsWallpaper() {
        wallpaperService.setAsWallpaper(wallpaper)
    }
    
    private func deleteWallpaper() {
        wallpaperService.deleteWallpaper(wallpaper)
        dismiss()
    }
}

// MARK: - 信息行

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 预览

#Preview {
    DreamWallpaperView(dream: Dream.sample)
}
