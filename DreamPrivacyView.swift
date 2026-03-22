//
//  DreamPrivacyView.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - Dream Privacy View

/// 私密梦境管理视图
struct DreamPrivacyView: View {
    @StateObject private var encryptionService = DreamEncryptionService.shared
    @State private var selectedPrivacyLevel: PrivacyLevel = .normal
    @State private var showingPrivateDreams = false
    @State private var isVerified = false
    
    var body: some View {
        List {
            // MARK: - 隐私级别说明
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    PrivacyLevelCard(
                        level: .normal,
                        isSelected: selectedPrivacyLevel == .normal
                    ) {
                        selectedPrivacyLevel = .normal
                    }
                    
                    PrivacyLevelCard(
                        level: .private,
                        isSelected: selectedPrivacyLevel == .private
                    ) {
                        selectedPrivacyLevel = .private
                    }
                    
                    PrivacyLevelCard(
                        level: .hidden,
                        isSelected: selectedPrivacyLevel == .hidden
                    ) {
                        selectedPrivacyLevel = .hidden
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("隐私级别")
            } footer: {
                Text("私密梦境需要验证才能查看，隐藏梦境仅在隐藏列表中显示")
            }
            
            // MARK: - 私密梦境列表
            Section {
                if isVerified {
                    Button(action: { showingPrivateDreams = true }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundColor(.green)
                            Text("查看私密梦境")
                            Spacer()
                            Text("12 个")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button(action: verifyAndShow) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text("验证查看私密梦境")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("私密内容")
            }
            
            // MARK: - 批量操作
            Section {
                Button(action: batchSetPrivacy) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                        Text("批量设置隐私级别")
                    }
                }
                
                Button(action: exportPrivateDreams) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.purple)
                        Text("导出私密梦境")
                    }
                }
            } header: {
                Text("操作")
            }
            
            // MARK: - 安全提示
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.checkerboard")
                            .foregroundColor(.green)
                        Text("加密保护")
                    }
                    
                    Text("私密梦境使用 AES-256 加密存储，密钥保存在设备安全区域。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("隐私管理")
        .sheet(isPresented: $showingPrivateDreams) {
            PrivateDreamsListView(isVerified: $isVerified)
        }
    }
    
    private func verifyAndShow() {
        Task {
            do {
                let success = try await DreamBiometricLockService.shared.authenticateWithBiometrics(
                    reason: "验证身份以查看私密梦境"
                )
                
                if success {
                    isVerified = true
                    showingPrivateDreams = true
                }
            } catch {
                print("验证失败：\(error)")
            }
        }
    }
    
    private func batchSetPrivacy() {
        // 批量设置隐私级别功能
        print("批量设置隐私级别")
    }
    
    private func exportPrivateDreams() {
        // 导出私密梦境功能
        print("导出私密梦境")
    }
}

// MARK: - Privacy Level Card

struct PrivacyLevelCard: View {
    let level: PrivacyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: level.iconName)
                    .font(.title2)
                    .foregroundColor(levelColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.headline)
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var levelColor: Color {
        switch level {
        case .normal: return .green
        case .private: return .orange
        case .hidden: return .red
        }
    }
}

// MARK: - Private Dreams List View

struct PrivateDreamsListView: View {
    @Binding var isVerified: Bool
    @State private var privateDreams: [DreamItem] = []
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                if privateDreams.isEmpty {
                    ContentUnavailableView(
                        "暂无私密梦境",
                        systemImage: "lock.shield.fill",
                        description: Text("标记为私密的梦境将在此显示")
                    )
                } else {
                    ForEach(privateDreams.filter { dream in
                        searchText.isEmpty || dream.title.localizedCaseInsensitiveContains(searchText)
                    }) { dream in
                        PrivateDreamRow(dream: dream)
                    }
                }
            }
            .navigationTitle("私密梦境")
            .searchable(text: $searchText, prompt: "搜索私密梦境")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        isVerified = false
                    }
                }
            }
        }
        .onAppear {
            loadPrivateDreams()
        }
    }
    
    private func loadPrivateDreams() {
        // 加载私密梦境列表
        // 简化实现
        privateDreams = [
            DreamItem(id: UUID(), title: "神秘的梦境", date: Date(), privacyLevel: .private),
            DreamItem(id: UUID(), title: "隐藏的秘密", date: Date().addingTimeInterval(-86400), privacyLevel: .hidden),
        ]
    }
}

// MARK: - Private Dream Row

struct PrivateDreamRow: View {
    let dream: DreamItem
    
    var body: some View {
        HStack {
            Image(systemName: dream.privacyLevel == .hidden ? "lock.shield.fill" : "eye.slash.fill")
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dream.title)
                    .font(.body)
                Text(formatDate(dream.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Dream Item Model

struct DreamItem: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let privacyLevel: PrivacyLevel
}

// MARK: - Preview

#Preview {
    DreamPrivacyView()
}
