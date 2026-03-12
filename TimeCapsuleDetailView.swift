//
//  TimeCapsuleDetailView.swift
//  DreamLog - Phase 27: 梦境时间胶囊
//
//  时间胶囊详情与解锁界面
//

import SwiftUI
import SwiftData

struct TimeCapsuleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = DreamTimeCapsuleService.shared
    
    let capsule: DreamTimeCapsule
    let onDismiss: () -> Void
    
    @State private var showingUnlockConfirm = false
    @State private var showingDreams = false
    @State private var isUnlocking = false
    @State private var errorMessage: String?
    @State private var showSuccessAnimation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部状态卡片
                    statusCard
                    
                    // 胶囊信息
                    infoCard
                    
                    // 解锁进度（仅锁定时显示）
                    if capsule.isLocked {
                        progressCard
                    }
                    
                    // 关联梦境
                    dreamsCard
                    
                    // 操作按钮
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(capsule.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                try? await service.toggleFavorite(capsule)
                            }
                        } label: {
                            Label(capsule.isFavorite ? "取消收藏" : "收藏",
                                  systemImage: capsule.isFavorite ? "heart.slash" : "heart")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("确认删除", isPresented: $showingDeleteConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    Task {
                        try? await service.deleteCapsule(capsule)
                        dismiss()
                        onDismiss()
                    }
                }
            } message: {
                Text("此操作不可恢复")
            }
            .alert("确认解锁", isPresented: $showingUnlockConfirm) {
                Button("取消", role: .cancel) {}
                Button("解锁", action: unlockCapsule)
            } message: {
                Text("确定要现在解锁这个时间胶囊吗？")
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay(
                Group {
                    if showSuccessAnimation {
                        successOverlay
                    }
                }
            )
        }
    }
    
    // MARK: - 子视图
    
    private var statusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 60))
                .foregroundColor(statusColor)
            
            Text(capsule.typedStatus.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(statusDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(statusColor.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("胶囊信息")
                .font(.headline)
            
            InfoRow(label: "类型", value: capsule.typedCapsuleType.displayName)
            InfoRow(label: "创建时间", value: formatDate(capsule.createdAt))
            InfoRow(label: "解锁时间", value: formatDate(capsule.unlockDate))
            
            if let unlockedAt = capsule.unlockedAt {
                InfoRow(label: "解锁时间", value: formatDate(unlockedAt))
            }
            
            InfoRow(label: "梦境数量", value: "\(capsule.dreamCount) 个")
            InfoRow(label: "查看次数", value: "\(capsule.viewCount) 次")
            
            if !capsule.message.isEmpty {
                Divider()
                
                Text("留言")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(capsule.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("解锁进度")
                .font(.headline)
            
            HStack {
                Text("\(capsule.daysUntilUnlock) 天后解锁")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("\(Int(capsule.unlockProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: capsule.unlockProgress)
                .progressViewStyle(.linear)
                .tint(.orange)
            
            HStack {
                Text(formatDate(capsule.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDate(capsule.unlockDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var dreamsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("关联梦境")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingDreams = true }) {
                    Label("查看全部", systemImage: "chevron.right")
                        .font(.caption)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<min(5, capsule.dreamCount), id: \.self) { index in
                        DreamPreviewCard(index: index)
                    }
                    
                    if capsule.dreamCount > 5 {
                        MoreDreamsCard(count: capsule.dreamCount - 5)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if capsule.isReadyToUnlock {
                Button(action: { showingUnlockConfirm = true }) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("立即解锁")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            } else if capsule.isLocked {
                Button {
                    // 设置提醒
                } label: {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("解锁时提醒我")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
                }
            }
            
            Button(action: { showingDreams = true }) {
                HStack {
                    Image(systemName: "moon.fill")
                    Text("查看关联梦境")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.primary)
                .cornerRadius(16)
            }
        }
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("解锁成功！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(capsule.dreamCount) 个梦境已解锁")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - 辅助属性与方法
    
    private var statusIcon: String {
        switch capsule.typedStatus {
        case .locked: return capsule.isReadyToUnlock ? "bell.badge.fill" : "lock.fill"
        case .unlocked: return "lock.open.fill"
        case .expired: return "hourglass.badge.exclamationmark"
        }
    }
    
    private var statusColor: Color {
        switch capsule.typedStatus {
        case .locked: return capsule.isReadyToUnlock ? .red : .orange
        case .unlocked: return .green
        case .expired: return .red
        }
    }
    
    private var statusDescription: String {
        switch capsule.typedStatus {
        case .locked:
            return capsule.isReadyToUnlock ?
                "已到达解锁时间，立即回顾这些梦境吧！" :
                "将在 \(capsule.daysUntilUnlock) 天后解锁"
        case .unlocked:
            return "已于 \(formatDate(capsule.unlockedAt!)) 解锁"
        case .expired:
            return "已过期，但仍可查看"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func unlockCapsule() {
        isUnlocking = true
        
        Task {
            do {
                try await service.unlockCapsule(capsule)
                showSuccessAnimation = true
                
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                showSuccessAnimation = false
                dismiss()
                onDismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isUnlocking = false
        }
    }
    
    @State private var showingDeleteConfirm = false
}

// MARK: - 子组件

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

struct DreamPreviewCard: View {
    let index: Int
    
    var body: some View {
        VStack {
            Image(systemName: "moon.fill")
                .font(.title)
                .foregroundColor(.purple)
                .frame(width: 50, height: 50)
                .background(Color.purple.opacity(0.2))
                .cornerRadius(25)
            
            Text("梦境 \(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MoreDreamsCard: View {
    let count: Int
    
    var body: some View {
        VStack {
            Text("+\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text("更多")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    TimeCapsuleDetailView(
        capsule: DreamTimeCapsule(
            title: "2025 年度回顾",
            message: "希望这些梦境能给你带来启示",
            capsuleType: .yearlyReview,
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            dreamIds: ["1", "2", "3"]
        ),
        onDismiss: {}
    )
    .modelContainer(for: DreamTimeCapsule.self, inMemory: true)
}
