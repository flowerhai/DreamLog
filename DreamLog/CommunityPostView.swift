//
//  CommunityPostView.swift
//  DreamLog
//
//  发布梦境到社区
//

import SwiftUI

struct CommunityPostView: View {
    @ObservedObject var dreamStore: DreamStore
    @ObservedObject var communityService: CommunityService
    @Environment(\.dismiss) var dismiss
    @State private var selectedDream: Dream?
    @State private var isAnonymous: Bool = true
    @State private var isPosting: Bool = false
    @State private var showingSuccess = false
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                searchSection
                
                // 梦境列表
                dreamList
                
                // 发布选项
                postOptions
            }
            .navigationTitle("分享梦境")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareToCommunity) {
                        Text("分享")
                            .fontWeight(.semibold)
                    }
                    .disabled(selectedDream == nil || isPosting)
                }
            }
        }
    }
    
    // MARK: - 搜索部分
    private var searchSection: some View {
        VStack(spacing: 8) {
            Text("选择要分享的梦境")
                .font(.headline)
                .padding(.top)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索梦境标题或内容", text: $searchText)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    // MARK: - 梦境列表
    private var dreamList: some View {
        let filteredDreams = searchText.isEmpty
            ? dreamStore.dreams
            : dreamStore.dreams.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        
        return ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredDreams) { dream in
                    DreamSelectionCard(
                        dream: dream,
                        isSelected: selectedDream?.id == dream.id
                    ) {
                        selectedDream = dream
                    }
                }
                
                if filteredDreams.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("没有找到梦境")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 发布选项
    private var postOptions: some View {
        VStack(spacing: 16) {
            Divider()
            
            // 匿名选项
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("匿名分享")
                        .font(.headline)
                    Text("使用随机昵称，保护隐私")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isAnonymous)
                    .labelsHidden()
            }
            .padding(.horizontal)
            
            // 提示信息
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                Text("社区内容将公开可见，请确保不包含个人隐私信息")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 发布按钮
            Button(action: shareToCommunity) {
                HStack {
                    if isPosting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isPosting ? "正在分享..." : "分享到社区")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selectedDream == nil || isPosting ? Color.gray : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedDream == nil || isPosting)
            .padding()
        }
        .padding(.bottom)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 分享到社区
    private func shareToCommunity() {
        guard let dream = selectedDream else { return }
        
        isPosting = true
        
        Task {
            let success = await communityService.shareToCommunity(
                dream: dream,
                anonymous: isAnonymous
            )
            
            await MainActor.run {
                isPosting = false
                if success {
                    showingSuccess = true
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - 梦境选择卡片
struct DreamSelectionCard: View {
    @ObservedObject var dream: Dream
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(dream.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(dream.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // 情绪
                    if !dream.emotions.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(dream.emotions.prefix(3), id: \.self) { emotion in
                                Text(emotion.icon)
                            }
                        }
                    }
                    
                    // 标签
                    if !dream.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(dream.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 日期
                    Text(dream.date.formatted(.dateTime.month().day()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CommunityPostView(
        dreamStore: DreamStore(),
        communityService: CommunityService()
    )
}
