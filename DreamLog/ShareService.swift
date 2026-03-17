//
//  ShareService.swift
//  DreamLog
//
//  分享服务：生成和分享梦境卡片
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class ShareService: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var generatedImage: UIImage?
    @Published var error: String?
    
    // MARK: - 生成分享图片
    func generateShareImage(dream: Dream, style: ShareCardStyle) async -> UIImage? {
        isGenerating = true
        error = nil
        
        await MainActor.run {
            // 创建卡片视图
            let cardView = DreamShareCard(dream: dream, style: style)
                .frame(width: 375, height: 500)
            
            // 使用 ImageRenderer 渲染为图片
            let renderer = ImageRenderer(content: cardView)
            
            // 配置渲染
            renderer.scale = 3.0  // 高分辨率
            
            if let uiImage = renderer.uiImage {
                self.generatedImage = uiImage
                self.isGenerating = false
                return uiImage
            } else {
                self.error = "生成图片失败"
                self.isGenerating = false
                return nil
            }
        }
    }
    
    // MARK: - 保存到相册
    func saveToPhotos(image: UIImage) async -> Bool {
        await withCheckedContinuation { continuation in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            continuation.resume(returning: true)
        }
    }
    
    // MARK: - 获取分享文本
    func getShareText(dream: Dream) -> String {
        var text = "🌙 DreamLog - \(dream.title)\n\n"
        text += "日期：\(dream.date.formatted(.dateTime.year().month().day()))\n"
        text += "时间：\(dream.timeOfDay.rawValue)\n\n"
        text += "「\(dream.content)」\n\n"
        
        if !dream.tags.isEmpty {
            text += "标签：\(dream.tags.joined(separator: " "))\n"
        }
        
        if !dream.emotions.isEmpty {
            text += "情绪：\(dream.emotions.map { $0.icon + $0.rawValue }.joined(separator: " "))\n"
        }
        
        if dream.isLucid {
            text += "✨ 清醒梦\n"
        }
        
        text += "\n🌙 用 DreamLog 记录我的梦境"
        
        return text
    }
    
    // MARK: - 分享活动
    func createShareActivity(dream: Dream, style: ShareCardStyle) async -> UIActivityViewController? {
        guard let image = await generateShareImage(dream: dream, style: style) else {
            return nil
        }
        
        let shareText = getShareText(dream: dream)
        let activityVC = UIActivityViewController(
            activityItems: [image, shareText],
            applicationActivities: nil
        )
        
        return activityVC
    }
}

// MARK: - 分享视图控制器代表
struct ShareViewControllerRepresentable: UIViewControllerRepresentable {
    let activityVC: UIActivityViewController
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 分享按钮视图
struct ShareButton: View {
    let dream: Dream
    let style: ShareCardStyle
    @StateObject private var shareService = ShareService()
    @State private var showingShareSheet = false
    @State private var activityVC: UIActivityViewController?
    
    var body: some View {
        Button(action: generateAndShare) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("分享")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.accentColor)
            )
            .foregroundColor(.white)
        }
        .disabled(shareService.isGenerating)
        .sheet(isPresented: $showingShareSheet) {
            if let activityVC = activityVC {
                ShareViewControllerRepresentable(activityVC: activityVC)
            }
        }
    }
    
    private func generateAndShare() {
        Task {
            if let vc = await shareService.createShareActivity(dream: dream, style: style) {
                activityVC = vc
                showingShareSheet = true
            }
        }
    }
}

// MARK: - 快速分享按钮 (默认样式)
struct QuickShareButton: View {
    let dream: Dream
    @StateObject private var shareService = ShareService()
    @State private var showingShareSheet = false
    @State private var activityVC: UIActivityViewController?
    
    var body: some View {
        Button(action: generateAndShare) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.accentColor)
        }
        .disabled(shareService.isGenerating)
        .sheet(isPresented: $showingShareSheet) {
            if let activityVC = activityVC {
                ShareViewControllerRepresentable(activityVC: activityVC)
            }
        }
    }
    
    private func generateAndShare() {
        Task {
            // 使用梦幻样式作为默认
            if let vc = await shareService.createShareActivity(dream: dream, style: .dreamy) {
                activityVC = vc
                showingShareSheet = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ShareButton(
            dream: Dream(
                title: "海边漫步",
                content: "我梦见自己在海边散步，海浪轻轻拍打着沙滩...",
                originalText: "",
                date: Date(),
                tags: ["水", "海滩", "平静"],
                emotions: [.calm],
                clarity: 4,
                intensity: 2
            ),
            style: .dreamy
        )
        
        QuickShareButton(
            dream: Dream(
                title: "飞行体验",
                content: "我突然飞起来了，在城市上空自由翱翔...",
                originalText: "",
                date: Date(),
                tags: ["飞行", "自由"],
                emotions: [.excited, .happy],
                clarity: 5,
                intensity: 5,
                isLucid: true
            )
        )
    }
    .padding()
    .environmentObject(DreamStore())
}
