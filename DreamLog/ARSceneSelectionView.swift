//
//  ARSceneSelectionView.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import SwiftUI

// MARK: - AR Scene Selection View

/// AR 场景选择器 - 用于加载已保存的 AR 场景
struct ARSceneSelectionView: View {
    let onSceneSelected: (ARDreamScene) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var savedScenes: [ARDreamScene] = []
    @State private var isLoading = true
    
    var filteredScenes: [ARDreamScene] {
        if searchText.isEmpty {
            return savedScenes
        }
        return savedScenes.filter {
            $0.dreamTitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if filteredScenes.isEmpty {
                    emptyStateView
                } else {
                    sceneList
                }
            }
            .navigationTitle("选择场景")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索场景")
            .task {
                await loadSavedScenes()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Load Scenes
    
    @MainActor
    private func loadSavedScenes() async {
        isLoading = true
        
        await MainActor.run {
            savedScenes = loadScenesFromDisk()
            isLoading = false
        }
    }
    
    private func loadScenesFromDisk() -> [ARDreamScene] {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let scenesDirectory = documentsPath.appendingPathComponent("ARScenes", isDirectory: true)
        
        guard fileManager.fileExists(atPath: scenesDirectory.path) else {
            return []
        }
        
        var scenes: [ARDreamScene] = []
        
        do {
            let files = try fileManager.contentsOfDirectory(at: scenesDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            
            for file in jsonFiles {
                do {
                    let data = try Data(contentsOf: file)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let scene = try decoder.decode(ARDreamScene.self, from: data)
                    scenes.append(scene)
                } catch {
                    print("加载场景文件失败：\(file.lastPathComponent), error: \(error)")
                }
            }
        } catch {
            print("读取场景目录失败：\(error)")
        }
        
        // 按创建时间排序（最新的在前）
        return scenes.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载场景中...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Scene List
    
    private var sceneList: some View {
        List(filteredScenes) { scene in
            SceneRowView(scene: scene) {
                onSceneSelected(scene)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            if !searchText.isEmpty {
                Text("没有找到匹配的场景")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("尝试其他搜索关键词")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("没有保存的场景")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("在 AR 体验中保存场景后，\n可以在这里快速加载")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
    }
}

// MARK: - Scene Row View

struct SceneRowView: View {
    let scene: ARDreamScene
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 场景图标
                ZStack {
                    Circle()
                        .fill(scene.environment.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: scene.environment.icon)
                        .font(.system(size: 24))
                        .foregroundColor(scene.environment.color)
                }
                
                // 场景信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.dreamTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label("\(scene.elements.count)", systemImage: "cube.box")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(scene.createdAt, style: .date)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ARSceneSelectionView { _ in }
}
