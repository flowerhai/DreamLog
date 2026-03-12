//
//  DreamTimeCapsuleView.swift
//  DreamLog - Phase 27: 梦境时间胶囊
//
//  时间胶囊主界面
//

import SwiftUI
import SwiftData

struct DreamTimeCapsuleView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var service = DreamTimeCapsuleService.shared
    @State private var showingCreateSheet = false
    @State private var selectedCapsule: DreamTimeCapsule?
    @State private var showingDetail = false
    @State private var filterType: TimeCapsuleType?
    @State private var filterStatus: TimeCapsuleStatus?
    @State private var searchText = ""
    
    var filteredCapsules: [DreamTimeCapsule] {
        var result = service.capsules
        
        // 类型筛选
        if let filterType = filterType {
            result = result.filter { $0.typedCapsuleType == filterType }
        }
        
        // 状态筛选
        if let filterStatus = filterStatus {
            result = result.filter { $0.typedStatus == filterStatus }
        }
        
        // 搜索
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.message.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if service.isLoading {
                    loadingView
                } else if service.capsules.isEmpty {
                    emptyStateView
                } else {
                    capsuleListView
                }
            }
            .navigationTitle("🕰️ 时间胶囊")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Label("新建", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !service.capsules.isEmpty {
                        statsButton
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateTimeCapsuleView {
                    showingCreateSheet = false
                }
            }
            .sheet(item: $selectedCapsule) { capsule in
                TimeCapsuleDetailView(capsule: capsule, onDismiss: {
                    selectedCapsule = nil
                })
            }
            .refreshable {
                await service.loadCapsules()
            }
        }
    }
    
    // MARK: - 子视图
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("加载时间胶囊...")
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "hourglass")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("还没有时间胶囊")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("将梦境封存，在未来某个时刻重新开启")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingCreateSheet = true
            } label: {
                Label("创建第一个胶囊", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    private var capsuleListView: some View {
        List {
            // 统计概览
            statsSection
            
            // 筛选器
            filterSection
            
            // 胶囊列表
            capsulesSection
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "搜索时间胶囊")
    }
    
    private var statsSection: some View {
        Section {
            HStack(spacing: 12) {
                StatCard(
                    value: "\(service.stats.totalCapsules)",
                    label: "总数",
                    icon: "hourglass",
                    color: .orange
                )
                
                StatCard(
                    value: "\(service.stats.lockedCapsules)",
                    label: "锁定中",
                    icon: "lock",
                    color: .blue
                )
                
                StatCard(
                    value: "\(service.stats.unlockedCapsules)",
                    label: "已解锁",
                    icon: "lock.open",
                    color: .green
                )
                
                StatCard(
                    value: "\(service.stats.capsulesReadyToUnlock)",
                    label: "可解锁",
                    icon: "bell.badge",
                    color: .red
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("概览")
        }
    }
    
    private var filterSection: some View {
        Section("筛选") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "全部",
                        isSelected: filterType == nil,
                        onTap: { filterType = nil }
                    )
                    
                    ForEach(TimeCapsuleType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.icon + " " + type.displayName.replacingOccurrences(of: " ", with: ""),
                            isSelected: filterType == type,
                            onTap: { filterType = filterType == type ? nil : type }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "全部状态",
                        isSelected: filterStatus == nil,
                        onTap: { filterStatus = nil }
                    )
                    
                    ForEach(TimeCapsuleStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.displayName.replacingOccurrences(of: " ", with: ""),
                            isSelected: filterStatus == status,
                            onTap: { filterStatus = filterStatus == status ? nil : status }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var capsulesSection: some View {
        Section("时间胶囊") {
            ForEach(filteredCapsules, id: \.id) { capsule in
                CapsuleRow(capsule: capsule)
                    .onTapGesture {
                        selectedCapsule = capsule
                    }
            }
        }
    }
    
    private var statsButton: some View {
        Menu {
            Button {
                // 显示详细统计
            } label: {
                Label("详细统计", systemImage: "chart.bar")
            }
            
            Divider()
            
            Button {
                Task {
                    await service.createAutoYearlyReviewCapsules()
                }
            } label: {
                Label("生成年度回顾", systemImage: "calendar.badge.clock")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

// MARK: - 子组件

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct CapsuleRow: View {
    let capsule: DreamTimeCapsule
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            VStack {
                Image(systemName: capsule.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.title2)
                    .foregroundColor(capsule.isLocked ? .orange : .green)
                    .frame(width: 44, height: 44)
                    .background(capsule.isLocked ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(22)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(capsule.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if capsule.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if capsule.isReadyToUnlock {
                        Image(systemName: "bell.badge.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Text(capsule.typedCapsuleType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Label("\(capsule.dreamCount) 个梦境", systemImage: "moon.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(capsule.typedStatus.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                }
            }
            
            // 解锁倒计时
            if capsule.isLocked {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(capsule.daysUntilUnlock) 天")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    ProgressView(value: capsule.unlockProgress)
                        .frame(width: 50)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch capsule.typedStatus {
        case .locked: return .orange
        case .unlocked: return .green
        case .expired: return .red
        }
    }
}

// MARK: - 预览

#Preview {
    DreamTimeCapsuleView()
        .modelContainer(for: DreamTimeCapsule.self, inMemory: true)
}
