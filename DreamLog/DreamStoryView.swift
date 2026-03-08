//
//  DreamStoryView.swift
//  DreamLog
//
//  梦境故事生成与查看界面
//  Phase 8 - AI 增强功能
//

import SwiftUI

// MARK: - 梦境故事主视图

struct DreamStoryView: View {
    @StateObject private var storyService = DreamStoryService.shared
    @State private var selectedStory: DreamStory?
    @State private var showStoryDetail = false
    @State private var selectedStyle: DreamStory.NarrativeStyle = .firstPerson
    @State private var showStylePicker = false
    
    var body: some View {
        NavigationView {
            Group {
                if storyService.stories.isEmpty {
                    emptyStateView
                } else {
                    storyListView
                }
            }
            .navigationTitle("梦境故事")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showStylePicker = true }) {
                        Label("新建故事", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showStylePicker) {
            StylePickerView(selectedStyle: $selectedStyle) { style in
                // 这里需要传入选中的梦境
                // 暂时使用示例
            }
        }
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("还没有梦境故事")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("选择一个梦境，让它变成精彩的故事")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showStylePicker = true }) {
                Label("创建第一个故事", systemImage: "sparkles")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(40)
    }
    
    // MARK: - 故事列表视图
    
    private var storyListView: some View {
        List(storyService.stories) { story in
            StoryListItemView(story: story)
                .onTapGesture {
                    selectedStory = story
                }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - 故事列表项视图

struct StoryListItemView: View {
    let story: DreamStory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: story.narrativeStyle.icon)
                    .foregroundColor(.purple)
                
                Text(story.title)
                    .font(.headline)
                
                Spacer()
                
                if story.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Label(story.narrativeStyle.rawValue, systemImage: "text.book.closed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(story.wordCount)字", systemImage: "character.textbox")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(formatDate(story.createdAt), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !story.themes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(story.themes.prefix(5), id: \.self) { theme in
                            Text(theme)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - 风格选择器视图

struct StylePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedStyle: DreamStory.NarrativeStyle
    var onSelect: (DreamStory.NarrativeStyle) -> Void
    
    var body: some View {
        NavigationView {
            List(DreamStory.NarrativeStyle.allCases) { style in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: style.icon)
                            .foregroundColor(.purple)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(style.rawValue)
                                .font(.headline)
                            Text(style.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    selectedStyle = style
                    onSelect(style)
                    dismiss()
                }
            }
            .navigationTitle("选择叙事风格")
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
}

// MARK: - 故事详情视图

struct StoryDetailView: View {
    let story: DreamStory
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var showExportOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和元信息
                    headerSection
                    
                    Divider()
                    
                    // 章节内容
                    chaptersSection
                    
                    Divider()
                    
                    // 尾声
                    epilogueSection
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("故事详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showExportOptions = true }) {
                            Label("导出", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { showShareSheet = true }) {
                            Label("分享", systemImage: "square.and.arrow.up.on.square")
                        }
                        
                        Button(action: {
                            // 标记为收藏
                        }) {
                            Label(story.isFavorite ? "取消收藏" : "收藏", 
                                  systemImage: story.isFavorite ? "heart.slash" : "heart")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [story.content])
            }
            .actionSheet(isPresented: $showExportOptions) {
                exportActionSheet
            }
        }
    }
    
    // MARK: - 头部信息
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(story.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                Label(story.narrativeStyle.rawValue, systemImage: "text.book.closed")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                
                Label("\(story.wordCount)字", systemImage: "character.textbox")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Label(formatDate(story.createdAt), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !story.themes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(story.themes, id: \.self) { theme in
                            Text(theme)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            Text("情绪：\(story.mood)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 章节内容
    
    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(story.chapters) { chapter in
                VStack(alignment: .leading, spacing: 8) {
                    Text(chapter.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(chapter.content)
                        .font(.body)
                        .lineSpacing(6)
                    
                    HStack {
                        Spacer()
                        Text("\(chapter.wordCount)字 · \(chapter.mood)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 尾声
    
    private var epilogueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("尾声")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("这个梦境如同一面镜子，映照出内心深处的想法和情感。无论它是快乐的、恐惧的，还是神秘的，都是我们潜意识的一部分，值得我们去理解和珍惜。")
                .font(.body)
                .italic()
                .foregroundColor(.secondary)
            
            Text("—— DreamLog 梦境故事生成")
                .font(.caption)
                .foregroundColor(.purple)
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - 操作按钮
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                // 复制文本
            }) {
                Label("复制", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            
            Button(action: {
                // 导出
            }) {
                Label("导出", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - 导出选项
    
    private var exportActionSheet: ActionSheet {
        ActionSheet(
            title: Text("导出故事"),
            message: Text("选择导出格式"),
            buttons: [
                .default(Text("纯文本 (.txt)")) {
                    exportAsText()
                },
                .default(Text("Markdown (.md)")) {
                    exportAsMarkdown()
                },
                .default(Text("PDF")) {
                    // TODO: 实现 PDF 导出
                },
                .default(Text("EPUB")) {
                    // TODO: 实现 EPUB 导出
                },
                .cancel()
            ]
        )
    }
    
    private func exportAsText() {
        let text = DreamStoryService.shared.exportStoryAsText(story)
        // TODO: 保存到文件
        print("导出为文本：\(text.prefix(100))...")
    }
    
    private func exportAsMarkdown() {
        let md = DreamStoryService.shared.exportStoryAsMarkdown(story)
        // TODO: 保存到文件
        print("导出为 Markdown: \(md.prefix(100))...")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 分享视图

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 预览

#Preview {
    DreamStoryView()
}
