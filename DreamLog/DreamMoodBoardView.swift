//
//  DreamMoodBoardView.swift
//  DreamLog
//
//  梦境情绪板主界面
//  Phase 76 - 梦境情绪板功能
//

import SwiftUI
import SwiftData

// MARK: - 主界面

struct DreamMoodBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service: DreamMoodBoardService?
    
    @Query(sort: \DreamMoodBoard.updatedAt, order: .reverse)
    private var boards: [DreamMoodBoard]
    
    @State private var showingCreateSheet = false
    @State private var selectedBoard: DreamMoodBoard?
    @State private var showingStatsSheet = false
    @State private var searchText = ""
    @State private var filterTheme: MoodBoardTheme?
    @State private var showingDeleteAlert = false
    @State private var boardToDelete: DreamMoodBoard?
    
    init() {
        // Service will be initialized when view appears
        _service = StateObject(wrappedValue: nil)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if boards.isEmpty {
                    emptyStateView
                } else {
                    moodBoardListView
                }
            }
            .navigationTitle("梦境情绪板")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingStatsSheet = true }) {
                        Label("统计", systemImage: "chart.bar.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Label("新建", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜索情绪板")
            .sheet(isPresented: $showingCreateSheet) {
                CreateMoodBoardView()
            }
            .sheet(isPresented: $showingStatsSheet) {
                MoodBoardStatsView()
            }
            .navigationDestination(item: $selectedBoard) { board in
                MoodBoardDetailView(board: board)
            }
            .alert("删除情绪板", isPresented: $showingDeleteAlert, presenting: boardToDelete) { board in
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    deleteBoard(board)
                }
            } message: { board in
                Text("确定要删除\"\(board.title)\"吗？此操作无法撤销。")
            }
        }
        .onAppear {
            initializeService()
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
            
            Text("创建你的第一个情绪板")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("将相关的梦境组合成精美的视觉故事\n分享你的梦境灵感")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreateSheet = true }) {
                Label("创建情绪板", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(30)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 列表视图
    
    private var moodBoardListView: some View {
        let filteredBoards = filteredResults
        
        return ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(filteredBoards) { board in
                    MoodBoardCard(board: board)
                        .onTapGesture {
                            selectedBoard = board
                        }
                        .contextMenu {
                            Button(action: { selectedBoard = board }) {
                                Label("查看", systemImage: "eye")
                            }
                            
                            Button(action: { /* 编辑功能 */ }) {
                                Label("编辑", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(action: { boardToDelete = board }) {
                                Label("删除", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                        }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 过滤结果
    
    private var filteredResults: [DreamMoodBoard] {
        var results = boards
        
        // 搜索过滤
        if !searchText.isEmpty {
            results = results.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 主题过滤
        if let theme = filterTheme {
            results = results.filter { $0.theme == theme }
        }
        
        return results
    }
    
    // MARK: - 操作
    
    private func initializeService() {
        // Service is managed by SwiftData
    }
    
    private func deleteBoard(_ board: DreamMoodBoard) {
        modelContext.delete(board)
        try? modelContext.save()
    }
}

// MARK: - 情绪板卡片

struct MoodBoardCard: View {
    let board: DreamMoodBoard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 封面区域
            ZStack {
                // 渐变背景
                LinearGradient(
                    colors: board.theme.gradientColors.map { Color(hex: $0) ?? .purple },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                
                // 梦境数量徽章
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Label("\(board.dreamIds.count)", systemImage: "photo.on.rectangle")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(8)
                }
                
                // 公开标识
                if board.isPublic {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            // 内容区域
            VStack(alignment: .leading, spacing: 8) {
                Text(board.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(board.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(board.theme.displayName, systemImage: "paintpalette")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(board.lastUpdatedString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 创建情绪板视图

struct CreateMoodBoardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedTheme: MoodBoardTheme = .starry
    @State private var selectedLayout: MoodBoardLayout = .grid
    @State private var selectedDreams: Set<UUID> = []
    @State private var isPublic = false
    @State private var showingDreamPicker = false
    
    @Query(sort: \Dream.date, order: .reverse)
    private var dreams: [Dream]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("描述", text: $description, axis: .vertical)
                }
                
                Section("外观设置") {
                    Picker("主题", selection: $selectedTheme) {
                        ForEach(MoodBoardTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    
                    Picker("布局", selection: $selectedLayout) {
                        ForEach(MoodBoardLayout.allCases) { layout in
                            Text(layout.displayName).tag(layout)
                        }
                    }
                }
                
                Section("梦境选择") {
                    HStack {
                        Text("梦境")
                        Spacer()
                        Text("\(selectedDreams.count) 个")
                            .foregroundColor(.secondary)
                        Button("选择") {
                            showingDreamPicker = true
                        }
                    }
                }
                
                Section("隐私设置") {
                    Toggle("公开分享", isOn: $isPublic)
                    if isPublic {
                        Text("公开的的情绪板将出现在社区中")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("创建情绪板") {
                        createBoard()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(title.isEmpty || selectedDreams.isEmpty)
                }
            }
            .navigationTitle("新建情绪板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDreamPicker) {
                DreamPickerView(selectedDreams: $selectedDreams, availableDreams: dreams)
            }
        }
    }
    
    private func createBoard() {
        let config = MoodBoardCreationConfig(
            title: title,
            description: description,
            theme: selectedTheme,
            layout: selectedLayout,
            dreamIds: Array(selectedDreams),
            isPublic: isPublic
        )
        
        // 实际创建通过 Service 进行
        // 这里简化处理
        dismiss()
    }
}

// MARK: - 梦境选择器

struct DreamPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDreams: Set<UUID>
    let availableDreams: [Dream]
    
    @State private var searchText = ""
    
    var filteredDreams: [Dream] {
        if searchText.isEmpty {
            return availableDreams
        }
        return availableDreams.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredDreams, selection: $selectedDreams) { dream in
                VStack(alignment: .leading, spacing: 4) {
                    Text(dream.title)
                        .font(.headline)
                    Text(dream.content.prefix(100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    Text(dream.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .searchable(text: $searchText, prompt: "搜索梦境")
            .navigationTitle("选择梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成 (\(selectedDreams.count))") {
                        dismiss()
                    }
                    .disabled(selectedDreams.isEmpty)
                }
            }
        }
    }
}

// MARK: - 统计视图

struct MoodBoardStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var boards: [DreamMoodBoard]
    
    var stats: MoodBoardStats {
        let totalBoards = boards.count
        let publicBoards = boards.filter { $0.isPublic }.count
        let totalShares = boards.reduce(0) { $0 + $1.shareCount }
        let totalViews = boards.reduce(0) { $0 + $1.viewCount }
        let totalDreams = boards.reduce(0) { $0 + $1.dreamIds.count }
        
        return MoodBoardStats(
            totalBoards: totalBoards,
            publicBoards: publicBoards,
            privateBoards: totalBoards - publicBoards,
            totalShares: totalShares,
            totalViews: totalViews,
            averageDreamsPerBoard: totalBoards > 0 ? Double(totalDreams) / Double(totalBoards) : 0
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 概览卡片
                    statsOverviewCards
                    
                    // 主题分布
                    themeDistribution
                    
                    // 最近活动
                    recentActivity
                }
                .padding()
            }
            .navigationTitle("统计")
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
    
    private var statsOverviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MoodBoardStatCard(
                title: "总情绪板",
                value: "\(stats.totalBoards)",
                icon: "square.stack.3d.up.fill",
                color: .purple
            )
            
            MoodBoardStatCard(
                title: "公开",
                value: "\(stats.publicBoards)",
                icon: "globe",
                color: .blue
            )
            
            MoodBoardStatCard(
                title: "分享次数",
                value: "\(stats.totalShares)",
                icon: "square.and.arrow.up",
                color: .green
            )
            
            MoodBoardStatCard(
                title: "浏览次数",
                value: "\(stats.totalViews)",
                icon: "eye.fill",
                color: .orange
            )
        }
    }
    
    private var themeDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主题分布")
                .font(.headline)
            
            ForEach(MoodBoardTheme.allCases.prefix(6)) { theme in
                let count = boards.filter { $0.theme == theme }.count
                if count > 0 {
                    HStack {
                        Circle()
                            .fill(Color(hex: theme.primaryColor) ?? .purple)
                            .frame(width: 12, height: 12)
                        
                        Text(theme.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近活动")
                .font(.headline)
            
            if boards.isEmpty {
                Text("暂无活动")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(boards.prefix(5)) { board in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(board.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("包含 \(board.dreamIds.count) 个梦境")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(board.lastUpdatedString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 统计卡片组件

struct MoodBoardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 详情视图（简化）

struct MoodBoardDetailView: View {
    let board: DreamMoodBoard
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 封面
                ZStack {
                    LinearGradient(
                        colors: board.theme.gradientColors.map { Color(hex: $0) ?? .purple },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    
                    VStack {
                        Spacer()
                        Text(board.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }
                    .padding()
                }
                .cornerRadius(16)
                
                // 信息
                VStack(alignment: .leading, spacing: 12) {
                    Text(board.description)
                        .font(.body)
                    
                    HStack {
                        Label(board.theme.displayName, systemImage: "paintpalette")
                        Spacer()
                        Label(board.layout.displayName, systemImage: "rectangle.grid.1x2")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        MoodBoardStatItem(label: "梦境", value: "\(board.dreamIds.count)")
                        MoodBoardStatItem(label: "分享", value: "\(board.shareCount)")
                        MoodBoardStatItem(label: "浏览", value: "\(board.viewCount)")
                    }
                }
                .padding()
                
                // 梦境列表
                if !board.dreamIds.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("包含的梦境")
                            .font(.headline)
                        
                        ForEach(board.dreamIds, id: \.self) { dreamId in
                            DreamListItem(dreamId: dreamId)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("情绪板详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MoodBoardStatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DreamListItem: View {
    let dreamId: UUID
    
    @Query var allDreams: [Dream]
    
    var dream: Dream? {
        allDreams.first { $0.id == dreamId }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("梦境 \(dream?.title ?? dreamId.uuidString.prefix(8))")
                    .font(.subheadline)
                Text((dream?.content.prefix(50) ?? "") + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 颜色扩展

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - 预览

#Preview {
    DreamMoodBoardView()
        .modelContainer(for: DreamMoodBoard.self, inMemory: true)
}
