//
//  EnhancedShareService.swift
//  DreamLog
//
//  增强分享服务：社交媒体集成、二维码分享、分享历史
//

import Foundation
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - 分享平台
enum SharePlatform: String, CaseIterable, Identifiable {
    case wechat = "微信"
    case wechatMoments = "朋友圈"
    case weibo = "微博"
    case xiaohongshu = "小红书"
    case qq = "QQ"
    case telegram = "Telegram"
    case copyLink = "复制链接"
    case saveImage = "保存图片"
    case qrCode = "二维码"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .wechat, .wechatMoments: return "message.fill"
        case .weibo: return "newspaper"
        case .xiaohongshu: return "book.fill"
        case .qq: return "bubble.left.and.bubble.right.fill"
        case .telegram: return "paperplane.fill"
        case .copyLink: return "link"
        case .saveImage: return "photo.on.rectangle"
        case .qrCode: return "qrcode"
        }
    }
    
    var color: Color {
        switch self {
        case .wechat, .wechatMoments: return Color(hex: "07C160")
        case .weibo: return Color(hex: "E6162D")
        case .xiaohongshu: return Color(hex: "FF2442")
        case .qq: return Color(hex: "12B7F5")
        case .telegram: return Color(hex: "0088CC")
        case .copyLink: return .gray
        case .saveImage: return .blue
        case .qrCode: return .purple
        }
    }
    
    var urlScheme: String? {
        switch self {
        case .wechat: return "weixin://"
        case .wechatMoments: return "weixin://"
        case .weibo: return "sinaweibo://"
        case .xiaohongshu: return "xhsdiscover://"
        case .qq: return "mqq://"
        case .telegram: return "tg://"
        default: return nil
        }
    }
    
    func canOpen() -> Bool {
        guard let scheme = urlScheme, let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - 分享历史纪录
struct ShareHistory: Identifiable, Codable {
    let id: UUID
    let dreamId: UUID
    let dreamTitle: String
    let platform: String
    let timestamp: Date
    let shareStyle: String
    
    init(dream: Dream, platform: SharePlatform, style: ShareCardStyle) {
        self.id = UUID()
        self.dreamId = dream.id
        self.dreamTitle = dream.title
        self.platform = platform.rawValue
        self.timestamp = Date()
        self.shareStyle = style.rawValue
    }
}

// MARK: - 二维码数据
struct DreamQRCodeData: Codable {
    let dreamId: UUID
    let title: String
    let content: String
    let date: Date
    let isPrivate: Bool
    let expiryDate: Date?
    
    init(dream: Dream, isPrivate: Bool = true, expiryDays: Int = 7) {
        self.dreamId = dream.id
        self.title = dream.title
        self.content = dream.content
        self.date = dream.date
        self.isPrivate = isPrivate
        self.expiryDate = isPrivate ? Calendar.current.date(byAdding: .day, value: expiryDays, to: Date()) : nil
    }
}

// MARK: - 增强分享服务
@MainActor
class EnhancedShareService: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var generatedImage: UIImage?
    @Published var qrCodeImage: UIImage?
    @Published var shareLink: String?
    @Published var error: String?
    @Published var shareHistory: [ShareHistory] = []
    
    private let context = CIContext()
    private let fileManager = FileManager.default
    
    // MARK: - 单例
    static let shared = EnhancedShareService()
    
    private init() {
        loadShareHistory()
    }
    
    // MARK: - 生成二维码
    func generateQRCode(data: DreamQRCodeData) async -> UIImage? {
        isGenerating = true
        error = nil
        
        do {
            // 编码数据为 JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            // 创建二维码滤镜
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(jsonString.utf8)
            filter.correctionLevel = "H" // 高容错率
            
            guard let ciImage = filter.outputImage else {
                throw NSError(domain: "QRCode", code: 1, userInfo: [NSLocalizedDescriptionKey: "生成二维码失败"])
            }
            
            // 缩放二维码
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledCIImage = ciImage.transformed(by: transform)
            
            // 转换为 UIImage
            guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
                throw NSError(domain: "QRCode", code: 2, userInfo: [NSLocalizedDescriptionKey: "转换图像失败"])
            }
            
            let qrImage = UIImage(cgImage: cgImage)
            
            // 添加 DreamLog logo 水印（可选）
            // let watermarkedImage = addWatermark(to: qrImage)
            
            self.qrCodeImage = qrImage
            self.isGenerating = false
            return qrImage
            
        } catch {
            self.error = error.localizedDescription
            self.isGenerating = false
            return nil
        }
    }
    
    // MARK: - 生成分享链接
    func generateShareLink(dream: Dream) async -> String {
        // 在实际应用中，这里会生成一个后端短链接
        // 现在使用本地 scheme URL
        let url = "dreamlog://dream/\(dream.id.uuidString)"
        self.shareLink = url
        return url
    }
    
    // MARK: - 分享到平台
    func shareToPlatform(_ platform: SharePlatform, dream: Dream, style: ShareCardStyle) async {
        guard let image = await generateShareImage(dream: dream, style: style) else {
            return
        }
        
        // 记录分享历史
        let history = ShareHistory(dream: dream, platform: platform, style: style)
        shareHistory.insert(history, at: 0)
        saveShareHistory()
        
        switch platform {
        case .wechat, .wechatMoments:
            await shareToWeChat(image: image, toMoments: platform == .wechatMoments, dream: dream)
        case .weibo:
            await shareToWeibo(image: image, dream: dream)
        case .xiaohongshu:
            await shareToXiaohongshu(image: image, dream: dream)
        case .qq:
            await shareToQQ(image: image, dream: dream)
        case .telegram:
            await shareToTelegram(image: image, dream: dream)
        case .copyLink:
            await copyShareLink(dream: dream)
        case .saveImage:
            await saveToPhotos(image: image)
        case .qrCode:
            _ = await generateQRCode(data: DreamQRCodeData(dream: dream))
        }
    }
    
    // MARK: - 平台分享实现
    private func shareToWeChat(image: UIImage, toMoments: Bool, dream: Dream) async {
        guard let wechatURL = URL(string: "weixin://") else { return }
        
        // 保存临时图片
        let tempPath = getTempImagePath()
        try? image.jpegData(compressionQuality: 0.9)?.write(to: URL(fileURLWithPath: tempPath))
        
        // 打开微信（实际应用中需要使用微信 SDK）
        if UIApplication.shared.canOpenURL(wechatURL) {
            UIApplication.shared.open(wechatURL)
        }
    }
    
    private func shareToWeibo(image: UIImage, dream: Dream) async {
        guard let weiboURL = URL(string: "sinaweibo://") else { return }
        
        let tempPath = getTempImagePath()
        try? image.jpegData(compressionQuality: 0.9)?.write(to: URL(fileURLWithPath: tempPath))
        
        if UIApplication.shared.canOpenURL(weiboURL) {
            UIApplication.shared.open(weiboURL)
        }
    }
    
    private func shareToXiaohongshu(image: UIImage, dream: Dream) async {
        guard let xhsURL = URL(string: "xhsdiscover://") else { return }
        
        let tempPath = getTempImagePath()
        try? image.jpegData(compressionQuality: 0.9)?.write(to: URL(fileURLWithPath: tempPath))
        
        if UIApplication.shared.canOpenURL(xhsURL) {
            UIApplication.shared.open(xhsURL)
        }
    }
    
    private func shareToQQ(image: UIImage, dream: Dream) async {
        guard let qqURL = URL(string: "mqq://") else { return }
        
        let tempPath = getTempImagePath()
        try? image.jpegData(compressionQuality: 0.9)?.write(to: URL(fileURLWithPath: tempPath))
        
        if UIApplication.shared.canOpenURL(qqURL) {
            UIApplication.shared.open(qqURL)
        }
    }
    
    private func shareToTelegram(image: UIImage, dream: Dream) async {
        guard let tgURL = URL(string: "tg://") else { return }
        
        let tempPath = getTempImagePath()
        try? image.jpegData(compressionQuality: 0.9)?.write(to: URL(fileURLWithPath: tempPath))
        
        if UIApplication.shared.canOpenURL(tgURL) {
            UIApplication.shared.open(tgURL)
        }
    }
    
    private func copyShareLink(dream: Dream) async {
        let link = await generateShareLink(dream: dream)
        UIPasteboard.general.string = link
    }
    
    private func saveToPhotos(image: UIImage) async {
        await withCheckedContinuation { continuation in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            continuation.resume()
        }
    }
    
    // MARK: - 辅助方法
    private func getTempImagePath() -> String {
        let tempDir = fileManager.temporaryDirectory.path
        return "\(tempDir)/dream_share_\(UUID().uuidString).jpg"
    }
    
    private func loadShareHistory() {
        guard let data = UserDefaults.standard.data(forKey: "ShareHistory"),
              let history = try? JSONDecoder().decode([ShareHistory].self, from: data) else {
            shareHistory = []
            return
        }
        shareHistory = history
    }
    
    private func saveShareHistory() {
        guard let data = try? JSONEncoder().encode(shareHistory) else { return }
        UserDefaults.standard.set(data, forKey: "ShareHistory")
    }
    
    // MARK: - 清理临时文件
    func cleanupTempFiles() {
        let tempDir = fileManager.temporaryDirectory.path
        let files = try? fileManager.contentsOfDirectory(atPath: tempDir)
        files?.forEach { file in
            if file.hasPrefix("dream_share_") {
                try? fileManager.removeItem(atPath: "\(tempDir)/\(file)")
            }
        }
    }
    
    // MARK: - 清除分享历史
    func clearShareHistory() {
        shareHistory = []
        UserDefaults.standard.removeObject(forKey: "ShareHistory")
    }
}

// MARK: - 分享平台选择视图
struct SharePlatformPicker: View {
    let dream: Dream
    let style: ShareCardStyle
    @ObservedObject private var shareService = EnhancedShareService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("社交媒体") {
                    ForEach([SharePlatform.wechat, .wechatMoments, .weibo, .xiaohongshu, .qq, .telegram]) { platform in
                        Button(action: { share(platform) }) {
                            HStack {
                                Image(systemName: platform.icon)
                                    .foregroundColor(platform.color)
                                    .frame(width: 30)
                                Text(platform.rawValue)
                                if !platform.canOpen() && platform.urlScheme != nil {
                                    Text("未安装")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section("其他选项") {
                    Button(action: { share(.copyLink) }) {
                        HStack {
                            Image(systemName: SharePlatform.copyLink.icon)
                                .foregroundColor(SharePlatform.copyLink.color)
                                .frame(width: 30)
                            Text(SharePlatform.copyLink.rawValue)
                        }
                    }
                    
                    Button(action: { share(.saveImage) }) {
                        HStack {
                            Image(systemName: SharePlatform.saveImage.icon)
                                .foregroundColor(SharePlatform.saveImage.color)
                                .frame(width: 30)
                            Text(SharePlatform.saveImage.rawValue)
                        }
                    }
                    
                    Button(action: { share(.qrCode) }) {
                        HStack {
                            Image(systemName: SharePlatform.qrCode.icon)
                                .foregroundColor(SharePlatform.qrCode.color)
                                .frame(width: 30)
                            Text(SharePlatform.qrCode.rawValue)
                        }
                    }
                }
                
                if !shareService.shareHistory.isEmpty {
                    Section("最近分享") {
                        ForEach(shareService.shareHistory.prefix(5)) { history in
                            HStack {
                                Text(history.dreamTitle)
                                    .lineLimit(1)
                                Spacer()
                                Text(history.platform)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("分享到")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    private func share(_ platform: SharePlatform) {
        Task {
            await shareService.shareToPlatform(platform, dream: dream, style: style)
            if platform == .qrCode {
                // 显示二维码
            }
            dismiss()
        }
    }
}

// MARK: - 二维码分享视图
struct QRCodeShareView: View {
    let dream: Dream
    @ObservedObject private var shareService = EnhancedShareService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if let qrImage = shareService.qrCodeImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    
                    Text("扫描二维码查看梦境")
                        .font(.headline)
                    
                    Text("7 天后自动失效")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let link = shareService.shareLink {
                        Text(link)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ProgressView("生成二维码中...")
                        .scaleEffect(1.5)
                }
            }
            .padding()
            .navigationTitle("二维码分享")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    _ = await shareService.generateQRCode(data: DreamQRCodeData(dream: dream))
                    _ = await shareService.generateShareLink(dream: dream)
                }
            }
        }
    }
}

// MARK: - 分享历史视图
struct ShareHistoryView: View {
    @ObservedObject private var shareService = EnhancedShareService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if shareService.shareHistory.isEmpty {
                    ContentUnavailableView(
                        "暂无分享记录",
                        systemImage: "square.and.arrow.up",
                        description: Text("分享梦境后，记录会显示在这里")
                    )
                } else {
                    ForEach(shareService.shareHistory) { history in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(history.dreamTitle)
                                .font(.headline)
                            HStack {
                                Label(history.platform, systemName: platformIcon(for: history.platform))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(history.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            shareService.shareHistory.remove(at: index)
                        }
                        shareService.saveShareHistory()
                    }
                }
            }
            .navigationTitle("分享历史")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !shareService.shareHistory.isEmpty {
                        Button("清除") {
                            shareService.clearShareHistory()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private func platformIcon(for platform: String) -> String {
        switch platform {
        case "微信", "朋友圈": return "message.fill"
        case "微博": return "newspaper"
        case "小红书": return "book.fill"
        case "QQ": return "bubble.left.and.bubble.right.fill"
        case "Telegram": return "paperplane.fill"
        default: return "link"
        }
    }
}

#Preview {
    SharePlatformPicker(
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
}
