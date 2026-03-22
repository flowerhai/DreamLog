//
//  DreamQRShareView.swift
//  DreamLog
//
//  Dream QR Code Sharing & Web Preview UI
//  Phase 88: Enhanced Social Sharing
//

import SwiftUI
import SwiftData

// MARK: - Main QR Share View

struct DreamQRShareView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamQRShare.createdAt, order: .reverse) private var qrShares: [DreamQRShare]
    
    @State private var showingCreateSheet = false
    @State private var selectedShare: DreamQRShare?
    @State private var showingDetailSheet = false
    @State private var filter: QRShareFilter = .active
    @State private var sortBy: QRShareSort = .createdAt
    
    var body: some View {
        NavigationView {
            Group {
                if qrShares.isEmpty {
                    EmptyStateView()
                } else {
                    shareList
                }
            }
            .navigationTitle("QR 分享")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("筛选", selection: $filter) {
                            Text("全部分享").tag(QRShareFilter.all)
                            Text("有效分享").tag(QRShareFilter.active)
                            Text("已过期").tag(QRShareFilter.expired)
                        }
                        
                        Divider()
                        
                        Picker("排序", selection: $sortBy) {
                            Text("创建时间").tag(QRShareSort.createdAt)
                            Text("过期时间").tag(QRShareSort.expiresAt)
                            Text("扫描次数").tag(QRShareSort.scanCount)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateQRShareView()
            }
            .sheet(item: $selectedShare) { share in
                QRShareDetailView(share: share)
            }
        }
    }
    
    private var shareList: some View {
        List {
            Section {
                statsCard
            }
            
            Section("分享列表") {
                ForEach(filteredShares) { share in
                    QRShareRow(share: share)
                        .onTapGesture {
                            selectedShare = share
                        }
                }
                .onDelete(perform: deleteShares)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var statsCard: some View {
        let stats = calculateStats()
        
        return VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(icon: "link", value: "\(stats.active)", label: "有效", color: .green)
                StatItem(icon: "clock", value: "\(stats.expired)", label: "过期", color: .orange)
                StatItem(icon: "eye", value: "\(stats.scans)", label: "扫描", color: .blue)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var filteredShares: [DreamQRShare] {
        var shares = qrShares
        
        // Apply filter
        switch filter {
        case .all:
            break
        case .active:
            shares = shares.filter { $0.isActive && !$0.isExpired }
        case .expired:
            shares = shares.filter { $0.isExpired || !$0.isActive }
        case .byDreamId:
            break
        }
        
        // Apply sorting
        switch sortBy {
        case .createdAt:
            shares.sort { $0.createdAt > $1.createdAt }
        case .expiresAt:
            shares.sort { $0.expiresAt > $1.expiresAt }
        case .scanCount:
            shares.sort { $0.scanCount > $1.scanCount }
        case .shareCode:
            shares.sort { $0.shareCode < $1.shareCode }
        }
        
        return shares
    }
    
    private func calculateStats() -> (active: Int, expired: Int, scans: Int) {
        let active = qrShares.filter { $0.isActive && !$0.isExpired }.count
        let expired = qrShares.filter { $0.isExpired || !$0.isActive }.count
        let scans = qrShares.reduce(0) { $0 + $1.scanCount }
        return (active, expired, scans)
    }
    
    private func deleteShares(at offsets: IndexSet) {
        for index in offsets {
            let share = filteredShares[index]
            modelContext.delete(share)
        }
    }
}

// MARK: - Create QR Share View

struct CreateQRShareView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DreamLogEntry.date, order: .reverse) private var dreams: [DreamLogEntry]
    
    @State private var selectedDreamId: UUID?
    @State private var selectedTheme: QRShareTheme = .starry
    @State private var expirationDays: Int = 7
    @State private var includeAIAnalysis: Bool = true
    @State private var includeTags: Bool = true
    @State private var includeEmotions: Bool = true
    @State private var customMessage: String = ""
    @State private var isCreating: Bool = false
    @State private var createdShare: DreamQRShare?
    
    var body: some View {
        NavigationView {
            Form {
                Section("选择梦境") {
                    Picker("梦境", selection: $selectedDreamId) {
                        Text("请选择一个梦境").tag(nil as UUID?)
                        ForEach(dreams) { dream in
                            Text(dream.title ?? "无标题梦境").tag(dream.id)
                        }
                    }
                }
                
                Section("主题样式") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        ForEach(QRShareTheme.allCases) { theme in
                            ThemeSelectionButton(
                                theme: theme,
                                isSelected: selectedTheme == theme
                            ) {
                                selectedTheme = theme
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("内容选项") {
                    Toggle("包含 AI 解析", isOn: $includeAIAnalysis)
                    Toggle("包含标签", isOn: $includeTags)
                    Toggle("包含情绪", isOn: $includeEmotions)
                }
                
                Section("自定义消息") {
                    TextField("添加个性化消息（可选）", text: $customMessage, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section("有效期") {
                    Picker("有效期", selection: $expirationDays) {
                        Text("1 天").tag(1)
                        Text("3 天").tag(3)
                        Text("7 天").tag(7)
                        Text("14 天").tag(14)
                        Text("30 天").tag(30)
                        Text("永久").tag(365)
                    }
                    .pickerStyle(.segmented)
                }
                
                if let share = createdShare {
                    Section("分享码") {
                        VStack(spacing: 12) {
                            Text("✅ 创建成功！")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Text(share.shareCode)
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                            
                            Text("有效期：\(share.formattedExpiresAt)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            .navigationTitle("创建 QR 分享")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task {
                            await createShare()
                        }
                    }
                    .disabled(selectedDreamId == nil || isCreating)
                }
            }
        }
    }
    
    private func createShare() async {
        guard let dreamId = selectedDreamId else { return }
        
        isCreating = true
        
        do {
            let service = try await DreamQRShareService(modelContainer: modelContext.container)
            let share = try await service.createQRShare(
                for: dreamId,
                theme: selectedTheme,
                includeAIAnalysis: includeAIAnalysis,
                includeTags: includeTags,
                includeEmotions: includeEmotions,
                customMessage: customMessage.isEmpty ? nil : customMessage,
                expirationDays: expirationDays
            )
            
            createdShare = share
        } catch {
            print("创建 QR 分享失败：\(error)")
        }
        
        isCreating = false
    }
}

// MARK: - QR Share Detail View

struct QRShareDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let share: DreamQRShare
    
    @State private var showingShareSheet = false
    @State private var qrCodeImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // QR Code
                    if let qrData = share.qrCodeData,
                       let uiImage = UIImage(data: qrData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 250)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 10)
                    }
                    
                    // Share Code
                    VStack(spacing: 8) {
                        Text("分享码")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(share.shareCode)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.bold)
                        
                        Button("复制分享码") {
                            UIPasteboard.general.string = share.shareCode
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Status Card
                    StatusCard(share: share)
                    
                    // Statistics
                    StatisticsCard(share: share)
                    
                    // Theme Info
                    ThemeInfoCard(theme: share.theme)
                    
                    // Actions
                    ActionButtons(share: share)
                }
                .padding()
            }
            .navigationTitle("分享详情")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views

struct QRShareRow: View {
    let share: DreamQRShare
    
    var body: some View {
        HStack(spacing: 12) {
            // Theme Icon
            Text(share.theme.icon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: share.theme.gradientColors.map { Color(hex: $0) ?? .gray },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(share.shareCode)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Label("\(share.scanCount) 次扫描", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if share.isExpired {
                        Label("已过期", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Label("\(share.daysUntilExpiration) 天过期", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ThemeSelectionButton: View {
    let theme: QRShareTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(theme.icon)
                    .font(.title2)
                
                Text(theme.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors.map { Color(hex: $0) ?? .gray },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
            )
            .shadow(radius: isSelected ? 8 : 2)
        }
        .buttonStyle(.plain)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatusCard: View {
    let share: DreamQRShare
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: share.isActive && !share.isExpired ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(share.isActive && !share.isExpired ? .green : .red)
                
                Text(share.isActive && !share.isExpired ? "分享有效" : "分享已过期")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("创建时间")
                Spacer()
                Text(share.createdAt, style: .date)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("过期时间")
                Spacer()
                Text(share.expiresAt, style: .date)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("有效期")
                Spacer()
                Text("\(share.daysUntilExpiration) 天")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatisticsCard: View {
    let share: DreamQRShare
    
    var body: some View {
        VStack(spacing: 12) {
            Text("统计信息")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StatItem(icon: "eye", value: "\(share.scanCount)", label: "总扫描", color: .blue)
                StatItem(icon: "calendar", value: "\(share.daysUntilExpiration)", label: "剩余天数", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ThemeInfoCard: View {
    let theme: QRShareTheme
    
    var body: some View {
        VStack(spacing: 12) {
            Text("主题样式")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text(theme.icon)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text(theme.displayName)
                        .font(.headline)
                    Text(theme.primaryColor)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(hex: theme.primaryColor) ?? .gray)
                    .frame(width: 40, height: 40)
                    .shadow(radius: 3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ActionButtons: View {
    let share: DreamQRShare
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                // Share QR code
            } label: {
                Label("分享 QR 码", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                // Save to Photos
            } label: {
                Label("保存到相册", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if !share.isExpired {
                Button(role: .destructive) {
                    // Deactivate share
                } label: {
                    Label("停用分享", systemImage: "slash.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无 QR 分享")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("创建一个 QR 分享，\n让朋友扫描查看你的梦境")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Color Extension

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

// MARK: - Preview

#Preview {
    DreamQRShareView()
        .modelContainer(for: DreamQRShare.self, inMemory: true)
}
