//
//  DreamArtGalleryView.swift
//  DreamLog
//
//  梦境艺术画廊 - 查看和管理 AI 生成的梦境图像
//

import SwiftUI

// MARK: - 艺术画廊主视图

struct DreamArtGalleryView: View {
    @StateObject private var aiArtService = AIArtService.shared
    @State private var selectedStyle: DreamArt.ArtStyle = .dreamy
    @State private var showingGrid = true
    @State private var searchText = ""
    @State private var selectedArt: DreamArt?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            Group {
                if aiArtService.dreamArts.isEmpty {
                    EmptyGalleryView()
                } else {
                    galleryContent
                }
            }
            .navigationTitle("梦境画廊")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    viewToggleButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(item: $selectedArt) { art in
                ArtDetailView(art: art, onDelete: {
                    aiArtService.deleteArt(art)
                    selectedArt = nil
                })
            }
        }
    }
    
    private var galleryContent: some View {
        if showingGrid {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredArts) { art in
                    ArtGridItem(art: art)
                        .onTapGesture {
                            selectedArt = art
                        }
                }
            }
            .padding()
        } else {
            List(filteredArts) { art in
                ArtListItem(art: art)
                    .onTapGesture {
                        selectedArt = art
                    }
            }
        }
    }
    
    private var filteredArts: [DreamArt] {
        if searchText.isEmpty {
            return aiArtService.dreamArts
        } else {
            return aiArtService.dreamArts.filter { art in
                art.prompt.localizedCaseInsensitiveContains(searchText) ||
                art.style.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var viewToggleButton: some View {
        Button(action: { showingGrid.toggle() }) {
            Image(systemName: showingGrid ? "list.bullet" : "square.grid.2x2")
        }
    }
    
    private var filterButton: some View {
        Button(action: { }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - 空状态视图

struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有梦境艺术作品")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("在梦境详情页点击「生成梦境图像」\n开始创作你的第一幅梦境艺术")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {}) {
                Label("去记录梦境", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .padding(40)
    }
}

// MARK: - 网格项

struct ArtGridItem: View {
    let art: DreamArt
    @State private var isLoaded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图像
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                
                if let url = URL(string: art.imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // 收藏标记
                if art.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(art.style.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(truncatePrompt(art.prompt))
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(formatDate(art.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func truncatePrompt(_ prompt: String) -> String {
        if prompt.count > 50 {
            return String(prompt.prefix(50)) + "..."
        }
        return prompt
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - 列表项

struct ArtListItem: View {
    let art: DreamArt
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let url = URL(string: art.imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(art.style.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(truncatePrompt(art.prompt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(formatDate(art.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if art.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func truncatePrompt(_ prompt: String) -> String {
        if prompt.count > 40 {
            return String(prompt.prefix(40)) + "..."
        }
        return prompt
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 详情视图

struct ArtDetailView: View {
    let art: DreamArt
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 大图
                    if let url = URL(string: art.imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                    Text("加载失败")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 300)
                            case .empty:
                                ProgressView()
                                    .frame(height: 300)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 16) {
                        Button(action: { /* 保存到相册 */ }) {
                            Label("保存", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showingShareSheet = true }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: { showingDeleteConfirm = true }) {
                            Label("删除", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    
                    // 信息卡片
                    VStack(alignment: .leading, spacing: 16) {
                        // 风格
                        InfoRow(
                            icon: "paintbrush",
                            title: "艺术风格",
                            value: art.style.rawValue
                        )
                        
                        // 创作时间
                        InfoRow(
                            icon: "calendar",
                            title: "创作时间",
                            value: formatFullDate(art.createdAt)
                        )
                        
                        // 提示词
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(.secondary)
                                Text("生成提示词")
                                    .font(.headline)
                            }
                            
                            Text(art.prompt)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("梦境艺术")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { AIArtService.shared.toggleFavorite(art) }) {
                        Image(systemName: art.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(art.isFavorite ? .red : .primary)
                    }
                }
            }
            .confirmationDialog("确定删除？", isPresented: $showingDeleteConfirm) {
                Button("删除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("取消", role: .cancel)
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - 生成艺术工作表

struct GenerateArtSheet: View {
    let dream: Dream
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiArtService = AIArtService.shared
    @State private var selectedStyle: DreamArt.ArtStyle = .dreamy
    @State private var customPrompt: String = ""
    @State private var useCustomPrompt = false
    
    var body: some View {
        NavigationView {
            Form {
                // 风格选择
                Section("选择艺术风格") {
                    Picker("风格", selection: $selectedStyle) {
                        ForEach(DreamArt.ArtStyle.allCases, id: \.self) { style in
                            VStack(alignment: .leading) {
                                Text(style.rawValue)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                // 自定义提示词
                Section("提示词") {
                    Toggle("使用自定义提示词", isOn: $useCustomPrompt)
                    
                    if useCustomPrompt {
                        TextEditor(text: $customPrompt)
                            .frame(height: 100)
                            .font(.body)
                    } else {
                        Text(aiArtService.generatePrompt(from: dream, style: selectedStyle))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 预览信息
                Section("梦境信息") {
                    LabeledContent("标题", value: dream.title.isEmpty ? "无标题" : dream.title)
                    LabeledContent("情绪", value: dream.emotions.joined(separator: ", "))
                    LabeledContent("时间", value: dream.timeOfDay.rawValue)
                    LabeledContent("清晰度", value: "\(dream.clarity)/5")
                    LabeledContent("强度", value: "\(dream.intensity)/5")
                }
            }
            .navigationTitle("生成梦境图像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("生成") {
                        Task {
                            // 实际使用时传入自定义提示词或自动生成
                            await aiArtService.generateArt(for: dream, style: selectedStyle)
                            dismiss()
                        }
                    }
                    .disabled(aiArtService.isGenerating)
                }
            }
            
            // 生成中覆盖层
            if aiArtService.isGenerating {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        ProgressView(value: aiArtService.generationProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                        
                        Text("正在创作你的梦境艺术...")
                            .font(.headline)
                        
                        Text("\(Int(aiArtService.generationProgress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(40)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 20)
                    Spacer()
                }
                .background(Color.black.opacity(0.4))
            }
        }
    }
}

// MARK: - 预览

#if DEBUG
struct DreamArtGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        DreamArtGalleryView()
    }
}
#endif
