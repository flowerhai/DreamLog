//
//  DreamARShareView.swift
//  DreamLog - Phase 22: AR Enhancement & 3D Dream World
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - Share View

/// AR 场景分享界面
struct DreamARShareView: View {
    @ObservedObject private var shareService = DreamARShareService.shared
    @ObservedObject private var socialService = DreamARSocialService.shared
    
    let sceneId: String
    let sceneTitle: String
    let sceneData: Data
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isHosting = false
    @State private var showShareSheet = false
    @State private var copiedCode = false
    @State private var shareURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 场景信息
                sceneInfoSection
                
                Divider()
                
                // 分享方式
                shareOptionsSection
                
                Divider()
                
                // 多人共享
                if isHosting {
                    multiPlayerSection
                }
                
                Spacer()
                
                // 底部按钮
                actionButtons
            }
            .padding()
            .navigationTitle("分享场景")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("分享", isPresented: $showShareSheet) {
                Button("取消", role: .cancel) {}
            } message: {
                Text("选择分享方式")
            }
        }
    }
    
    // MARK: - Scene Info Section
    
    private var sceneInfoSection: some View {
        VStack(spacing: 12) {
            // 场景图标
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "cube.box")
                    .font(.system(size: 36))
                    .foregroundColor(.purple)
            }
            
            // 场景标题
            Text(sceneTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            // 场景信息
            HStack(spacing: 16) {
                Label("\(sceneData.count / 1024)KB", systemImage: "doc")
                Label("AR 场景", systemImage: "arkit")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Share Options Section
    
    private var shareOptionsSection: some View {
        VStack(spacing: 12) {
            Text("分享方式")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 生成分享链接
            shareOptionButton(
                icon: "link",
                title: "复制链接",
                subtitle: "生成场景分享链接"
            ) {
                copyShareLink()
            }
            
            // 生成分享码
            shareOptionButton(
                icon: "qrcode",
                title: "分享码",
                subtitle: "6 位数字快速分享"
            ) {
                copyShareCode()
            }
            
            // 系统分享
            shareOptionButton(
                icon: "square.and.arrow.up",
                title: "更多分享",
                subtitle: "微信、QQ、微博等"
            ) {
                showShareSheet = true
            }
        }
    }
    
    // MARK: - Multi Player Section
    
    private var multiPlayerSection: some View {
        VStack(spacing: 16) {
            Text("多人共享")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 分享码显示
            if let code = shareService.shareCode {
                VStack(spacing: 8) {
                    Text("分享码")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(code)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    if copiedCode {
                        Text("已复制！")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button("复制分享码") {
                        copyShareCode()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // 参与者列表
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("参与者")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(shareService.participantCount) 人")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if shareService.participants.isEmpty {
                    Text("等待其他人加入...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(shareService.participants) { participant in
                        participantRow(participant)
                    }
                }
            }
            
            // 同步状态
            HStack {
                Image(systemName: shareService.syncStatus.icon)
                    .foregroundColor(shareService.syncStatus == .synced ? .green : .orange)
                
                Text(shareService.syncStatus.description)
                    .font(.caption)
                
                Spacer()
                
                if shareService.isConnected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // 停止共享按钮
            Button("停止共享") {
                stopHosting()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            if !isHosting {
                Button(action: startHosting) {
                    Label("开始共享", systemImage: "person.2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button(action: { showShareSheet = true }) {
                Label("分享", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper Views
    
    private func shareOptionButton(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private func participantRow(_ participant: ARParticipant) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Image(systemName: "person.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.peerID)
                    .font(.subheadline)
                
                Text(participant.role.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Actions
    
    private func startHosting() {
        isHosting = true
        shareService.startHosting(sceneData: sceneData)
    }
    
    private func stopHosting() {
        shareService.stopHosting()
        isHosting = false
    }
    
    private func copyShareLink() {
        if let url = socialService.generateShareLink(for: sceneId) {
            UIPasteboard.general.url = url
            copiedCode = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                copiedCode = false
            }
        }
    }
    
    private func copyShareCode() {
        if let code = shareService.shareCode {
            UIPasteboard.general.string = code
            copiedCode = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                copiedCode = false
            }
        }
    }
}

// MARK: - Scene Share Card

/// 场景分享卡片（用于预览）
struct SceneShareCard: View {
    let sceneTitle: String
    let creatorName: String
    let thumbnail: String
    let likeCount: Int
    let viewCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 缩略图
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.gradient)
                    .frame(height: 160)
                
                Image(systemName: thumbnail)
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 6) {
                Text(sceneTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("by \(creatorName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label("\(likeCount)", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Label("\(viewCount)", systemImage: "eye.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
