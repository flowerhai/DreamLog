//
//  DreamTrashView.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - Dream Trash View

/// 梦境回收站视图
struct DreamTrashView: View {
    @StateObject private var trashService = DreamTrashService.shared
    @State private var trashItems: [DreamTrashItem] = []
    @State private var stats: TrashStats?
    @State private var showingEmptyConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var selectedItem: DreamTrashItem?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if trashItems.isEmpty {
                ContentUnavailableView(
                    "回收站为空",
                    systemImage: "trash.fill",
                    description: Text("删除的梦境将在此保留 30 天")
                )
            } else {
                // 统计信息
                if let stats = stats {
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("项目数")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.totalCount)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("占用空间")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(stats.totalSizeFormatted)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("即将过期")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(stats.expiringSoonCount)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(stats.expiringSoonCount > 0 ? .orange : .green)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 回收站项目列表
                Section {
                    ForEach(trashItems) { item in
                        TrashItemRow(
                            item: item,
                            onRecover: { recoverItem(item) },
                            onDelete: { showDeleteConfirm(for: item) }
                        )
                    }
                }
                
                // 批量操作
                Section {
                    Button(action: { showingEmptyConfirm = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("清空回收站")
                            Spacer()
                        }
                    }
                    .disabled(trashItems.isEmpty)
                }
            }
        }
        .navigationTitle("回收站")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: loadTrashItems) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("清空回收站", isPresented: $showingEmptyConfirm) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                emptyTrash()
            }
        } message: {
            Text("此操作将永久删除回收站中的所有梦境，无法撤销。")
        }
        .alert("永久删除", isPresented: $showingDeleteConfirm) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let item = selectedItem {
                    permanentlyDelete(item)
                }
            }
        } message: {
            Text("此操作将永久删除该梦境，无法撤销。")
        }
        .onAppear {
            loadTrashItems()
        }
    }
    
    private func loadTrashItems() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                trashItems = try trashService.getTrashItems()
                stats = try trashService.getTrashStats()
            } catch {
                errorMessage = "加载失败：\(error.localizedDescription)"
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func recoverItem(_ item: DreamTrashItem) {
        Task {
            do {
                try trashService.recoverDream(trashItemId: item.id)
                await loadTrashItems()
            } catch {
                print("恢复失败：\(error)")
            }
        }
    }
    
    private func showDeleteConfirm(for item: DreamTrashItem) {
        selectedItem = item
        showingDeleteConfirm = true
    }
    
    private func permanentlyDelete(_ item: DreamTrashItem) {
        Task {
            do {
                try trashService.permanentlyDelete(trashItemId: item.id)
                await loadTrashItems()
            } catch {
                print("删除失败：\(error)")
            }
        }
    }
    
    private func emptyTrash() {
        Task {
            do {
                let count = try trashService.emptyTrash()
                print("清空了 \(count) 个项目")
                await loadTrashItems()
            } catch {
                print("清空失败：\(error)")
            }
        }
    }
}

// MARK: - Trash Item Row

struct TrashItemRow: View {
    let item: DreamTrashItem
    let onRecover: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.orange)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.dreamTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(formatDate(item.deletedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 剩余天数
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.daysUntilDeletion) 天")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(item.daysUntilDeletion <= 7 ? .orange : .green)
                    
                    Text("后删除")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onRecover) {
                    Label("恢复", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                Button(action: onDelete) {
                    Label("删除", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        DreamTrashView()
    }
}
