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
    @ObservedObject private var storyService = DreamStoryService.shared
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedStory: DreamStory?
    @State private var showStoryDetail = false
    @State private var selectedStyle: DreamStory.NarrativeStyle = .firstPerson
    @State private var showStylePicker = false
    @State private var selectedDream: Dream?
    @State private var showDreamPicker = false
    @State private var showGenerationHistory = false
    
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showGenerationHistory = true }) {
                        Label("历史记录", systemImage: "clock.arrow.circlepath")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDreamPicker = true }) {
                        Label("新建故事", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showDreamPicker) {
            DreamPickerView(selectedDream: $selectedDream) { dream in
                if dream != nil {
                    showStylePicker = true
                }
            }
        }
        .sheet(isPresented: $showStylePicker) {
            if let dream = selectedDream {
                StylePickerView(dream: dream, selectedStyle: $selectedStyle) { style in
                    Task {
                        await storyService.generateStory(for: dream, style: style)
                    }
                }
            }
        }
        .sheet(isPresented: $showGenerationHistory) {
            GenerationHistoryView()
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
            
            Button(action: { showDreamPicker = true }) {
                Label("选择梦境", systemImage: "sparkles")
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            if !dreamStore.dreams.isEmpty {
                Text("你有 \(dreamStore.dreams.count) 个梦境可用于创作")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
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

// MARK: - 梦境选择器视图

struct DreamPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    @Binding var selectedDream: Dream?
    var onSelect: (Dream?) -> Void
    
    @State private var searchText = ""
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return dreamStore.dreams.sorted(by: { $0.createdAt > $1.createdAt })
        } else {
            return dreamStore.dreams.filter { dream in
                dream.content.localizedCaseInsensitiveContains(searchText) ||
                dream.title.localizedCaseInsensitiveContains(searchText) ||
                dream.emotions.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
            .sorted(by: { $0.createdAt > $1.createdAt })
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if filteredDreams.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("没有找到梦境")
                            .font(.headline)
                        Text("尝试搜索其他关键词")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                } else {
                    List(filteredDreams) { dream in
                        DreamListItem(dream: dream)
                            .onTapGesture {
                                selectedDream = dream
                                onSelect(dream)
                                dismiss()
                            }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索梦境内容")
            .navigationTitle("选择梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onSelect(nil)
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 梦境列表项
    
    private struct DreamListItem: View {
        let dream: Dream
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dream.title.isEmpty ? "无题梦境" : dream.title)
                        .font(.headline)
                    Spacer()
                    Text(formatDate(dream.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(dream.content.prefix(80))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !dream.emotions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(dream.emotions.prefix(5), id: \.self) { emotion in
                                Text(emotion)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
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
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 风格选择器视图

struct StylePickerView: View {
    @Environment(\.dismiss) var dismiss
    let dream: Dream
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .overlay {
            // 梦境预览
            VStack {
                Spacer()
                DreamPreviewCard(dream: dream, style: selectedStyle)
                    .padding()
            }
        }
    }
}

// MARK: - 梦境预览卡片

struct DreamPreviewCard: View {
    let dream: Dream
    let style: DreamStory.NarrativeStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                Text("梦境预览")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }
            
            Text(dream.content.prefix(150))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(4)
            
            HStack {
                Image(systemName: style.icon)
                    .font(.caption)
                Text("将使用 \(style.rawValue) 风格生成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(10)
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
                copyToClipboard()
            }) {
                Label("复制", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            
            Button(action: {
                showExportOptions = true
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
    
    private func copyToClipboard() {
        // 在实际 iOS 应用中，这里会使用 UIPasteboard
        print("📋 已复制故事内容到剪贴板")
        print("内容预览：\(story.content.prefix(100))...")
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
                .default(Text("EPUB")) {
                    exportAsEPUB()
                },
                .cancel()
            ]
        )
    }
    
    private func exportAsText() {
        let text = DreamStoryService.shared.exportStoryAsText(story)
        let fileName = "\(sanitizeFileName(story.title)).txt"
        
        if let url = DreamStoryService.shared.saveExportedFile(content: text, fileName: fileName) {
            showExportSuccess(message: "已保存至：\(url.lastPathComponent)")
        } else {
            showExportError(message: "导出失败")
        }
    }
    
    private func exportAsMarkdown() {
        let md = DreamStoryService.shared.exportStoryAsMarkdown(story)
        let fileName = "\(sanitizeFileName(story.title)).md"
        
        if let url = DreamStoryService.shared.saveExportedFile(content: md, fileName: fileName) {
            showExportSuccess(message: "已保存至：\(url.lastPathComponent)")
        } else {
            showExportError(message: "导出失败")
        }
    }
    
    private func exportAsEPUB() {
        let epub = DreamStoryService.shared.exportStoryAsEPUB(story)
        let fileName = "\(sanitizeFileName(story.title)).epub"
        
        if let url = DreamStoryService.shared.saveExportedFile(content: epub, fileName: fileName) {
            showExportSuccess(message: "已保存至：\(url.lastPathComponent)")
        } else {
            showExportError(message: "导出失败")
        }
    }
    
    private func showExportSuccess(message: String) {
        // 在实际 iOS 应用中，这里会显示 Toast 或 Alert
        print("✅ \(message)")
    }
    
    private func showExportError(message: String) {
        print("❌ \(message)")
    }
    
    private func sanitizeFileName(_ name: String) -> String {
        // 移除文件名中的非法字符
        let illegalChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let sanitized = name.components(separatedBy: illegalChars).joined()
        return sanitized.prefix(50).trimmingCharacters(in: .whitespaces)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 生成历史视图

struct GenerationHistoryView: View {
    @ObservedObject private var storyService = DreamStoryService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showStatistics = false
    
    var body: some View {
        NavigationView {
            Group {
                if storyService.generationHistory.isEmpty {
                    emptyHistoryView
                } else {
                    historyListView
                }
            }
            .navigationTitle("生成历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showStatistics = true }) {
                            Label("查看统计", systemImage: "chart.bar")
                        }
                        
                        Button(role: .destructive, action: {
                            storyService.clearGenerationHistory()
                        }) {
                            Label("清除历史", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showStatistics) {
                GenerationStatisticsView()
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有生成记录")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("开始创作你的第一个梦境故事吧")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
    
    private var historyListView: some View {
        List(storyService.generationHistory) { record in
            HistoryRecordItem(record: record)
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - 历史记录项

struct HistoryRecordItem: View {
    let record: DreamStoryService.GenerationRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
            Image(systemName: record.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(record.isSuccess ? .green : .red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.dreamTitle)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(formatDate(record.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Label(record.style.rawValue, systemImage: "text.book.closed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(record.wordCount)字", systemImage: "character.textbox")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(String(format: "%.1fs", record.duration), systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let errorMessage = record.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 生成统计视图

struct GenerationStatisticsView: View {
    @ObservedObject private var storyService = DreamStoryService.shared
    @Environment(\.dismiss) var dismiss
    
    private var stats: DreamStoryService.GenerationStatistics {
        storyService.getGenerationStatistics()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 总览统计
                    overviewSection
                    
                    Divider()
                    
                    // 风格分布
                    styleDistributionSection
                    
                    Divider()
                    
                    // 详细信息
                    detailsSection
                }
                .padding()
            }
            .navigationTitle("生成统计")
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
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            Text("总览")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCard(title: "总生成次数", value: "\(stats.totalGenerations)", icon: "doc.text")
                StatCard(title: "成功次数", value: "\(stats.successfulGenerations)", icon: "checkmark.circle")
                StatCard(title: "成功率", value: String(format: "%.1f%%", stats.successRate), icon: "percent")
                StatCard(title: "总字数", value: "\(stats.totalWords)", icon: "character.textbox")
            }
            
            HStack(spacing: 16) {
                StatCard(title: "平均耗时", value: String(format: "%.1fs", stats.averageDuration), icon: "timer")
            }
        }
    }
    
    private var styleDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风格分布")
                .font(.headline)
            
            ForEach(DreamStory.NarrativeStyle.allCases, id: \.self) { style in
                let count = stats.styleCounts[style] ?? 0
                let percentage = stats.totalGenerations > 0 ? Double(count) / Double(stats.totalGenerations) * 100 : 0
                
                HStack {
                    Image(systemName: style.icon)
                        .foregroundColor(.purple)
                        .frame(width: 25)
                    
                    Text(style.rawValue)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    ProgressView(value: percentage / 100)
                        .frame(width: 100)
                    
                    Text("\(count) (\(String(format: "%.1f", percentage))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细信息")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                StatRow(label: "总生成次数", value: "\(stats.totalGenerations)")
                StatRow(label: "成功生成", value: "\(stats.successfulGenerations)")
                StatRow(label: "失败次数", value: "\(stats.totalGenerations - stats.successfulGenerations)")
                StatRow(label: "成功率", value: String(format: "%.2f%%", stats.successRate))
                StatRow(label: "总字数", value: "\(stats.totalWords)")
                StatRow(label: "平均每次字数", value: "\(stats.totalGenerations > 0 ? stats.totalWords / stats.totalGenerations : 0)")
                StatRow(label: "平均耗时", value: String(format: "%.2f 秒", stats.averageDuration))
            }
        }
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - 统计行

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
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
