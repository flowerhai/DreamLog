//
//  ViewImageRenderer.swift
//  DreamLog
//
//  Phase 11.5 - 视图截图和图像渲染工具
//  用于梦境回顾分享卡片图片生成
//

import SwiftUI
import UIKit

// MARK: - 视图截图工具

/// 视图截图渲染器
class ViewImageRenderer {
    
    /// 将 SwiftUI 视图渲染为 UIImage
    /// - Parameters:
    ///   - view: 要渲染的视图
    ///   - size: 渲染尺寸（可选，默认使用视图的理想尺寸）
    /// - Returns: 渲染后的 UIImage
    static func render(view: some View, size: CGSize? = nil) -> UIImage? {
        let rendererSize = size ?? CGSize(width: 375, height: 667)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: rendererSize)
        hostingController.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: rendererSize)
        
        return renderer.image { context in
            hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: rendererSize), afterScreenUpdates: true)
        }
    }
    
    /// 将 SwiftUI 视图渲染为 PNG Data
    /// - Parameters:
    ///   - view: 要渲染的视图
    ///   - size: 渲染尺寸
    /// - Returns: PNG 数据
    static func renderToPNG(view: some View, size: CGSize) -> Data? {
        guard let image = render(view: view, size: size) else { return nil }
        return image.pngData()
    }
    
    /// 将 SwiftUI 视图渲染为 JPEG Data
    /// - Parameters:
    ///   - view: 要渲染的视图
    ///   - size: 渲染尺寸
    ///   - compressionQuality: 压缩质量 (0.0-1.0)
    /// - Returns: JPEG 数据
    static func renderToJPEG(view: some View, size: CGSize, compressionQuality: CGFloat = 0.9) -> Data? {
        guard let image = render(view: view, size: size) else { return nil }
        return image.jpegData(compressionQuality: compressionQuality)
    }
}

// MARK: - UIImage 扩展

extension UIImage {
    /// 转换为 PNG Data
    func pngData() -> Data? {
        return self.pngData()
    }
    
    /// 转换为 JPEG Data
    func jpegData(compressionQuality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
    
    /// 调整图片尺寸
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// 添加圆角
    func withRoundedCorners(radius: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - 分享卡片图片生成器

/// 梦境回顾分享卡片图片生成器
class WrappedShareCardGenerator {
    
    /// 生成标准分享卡片图片 (1080x1920 - Instagram Story 尺寸)
    static func generateStandardShareCard(data: DreamWrappedData) -> UIImage? {
        let view = StandardShareCardView(wrappedData: data)
        return ViewImageRenderer.render(view: view, size: CGSize(width: 1080, height: 1920))
    }
    
    /// 生成方形分享卡片图片 (1080x1080 - Instagram Post 尺寸)
    static func generateSquareShareCard(data: DreamWrappedData) -> UIImage? {
        let view = SquareShareCardView(wrappedData: data)
        return ViewImageRenderer.render(view: view, size: CGSize(width: 1080, height: 1080))
    }
    
    /// 生成微信分享卡片图片 (1080x1350)
    static func generateWeChatShareCard(data: DreamWrappedData) -> UIImage? {
        let view = WeChatShareCardView(wrappedData: data)
        return ViewImageRenderer.render(view: view, size: CGSize(width: 1080, height: 1350))
    }
    
    /// 保存卡片图片到 Documents 目录
    static func saveCard(image: UIImage, fileName: String) -> URL? {
        guard let data = image.pngData() else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(fileName).png")
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("保存卡片图片失败：\(error)")
            return nil
        }
    }
}

// MARK: - 分享卡片视图

/// 标准分享卡片视图 (1080x1920)
struct StandardShareCardView: View {
    let wrappedData: DreamWrappedData
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667EEA"), Color(hex: "764BA2"), Color(hex: "F093FB")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // 顶部装饰
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 60)
                .padding(.top, 60)
                
                Spacer()
                
                // 主要内容
                VStack(spacing: 30) {
                    Text("我的\(wrappedData.period.displayName)梦境回顾")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(wrappedData.shareCardQuote)
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                    
                    // 统计数据
                    HStack(spacing: 50) {
                        ShareStatItemLarge(value: "\(wrappedData.totalDreams)", label: "个梦境")
                        ShareStatItemLarge(value: "\(wrappedData.lucidDreamCount)", label: "个清醒梦")
                        ShareStatItemLarge(value: "\(wrappedData.dreamStreak)", label: "天连续")
                    }
                    .padding(.vertical, 30)
                }
                
                Spacer()
                
                // 底部品牌
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 24))
                        Text("DreamLog")
                            .font(.system(size: 28, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    
                    Text("探索你的潜意识世界")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// 方形分享卡片视图 (1080x1080)
struct SquareShareCardView: View {
    let wrappedData: DreamWrappedData
    
    var body: some View {
        ZStack {
            // 径向渐变背景
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "9D50DD"), Color(hex: "6B4E9A"), Color(hex: "1A1A2E")]),
                center: .center,
                startRadius: 0,
                endRadius: 800
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 主统计
                VStack(spacing: 20) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("\(wrappedData.totalDreams)")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("个梦境")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // 副统计
                HStack(spacing: 60) {
                    VStack(spacing: 10) {
                        Text("\(wrappedData.lucidDreamCount)")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                        Text("清醒梦")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack(spacing: 10) {
                        Text("\(wrappedData.dreamStreak)")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                        Text("天连续")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // 品牌
                HStack(spacing: 12) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 28))
                    Text("DreamLog")
                        .font(.system(size: 32, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.bottom, 60)
            }
        }
    }
}

/// 微信分享卡片视图 (1080x1350)
struct WeChatShareCardView: View {
    let wrappedData: DreamWrappedData
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f3460")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 装饰圆环
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                .frame(width: 900, height: 900)
                .offset(y: -200)
            
            VStack(spacing: 40) {
                Spacer()
                
                // 标题
                VStack(spacing: 20) {
                    Text("🌙 \(wrappedData.period.displayName)梦境回顾")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(wrappedData.shareCardQuote)
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 80)
                }
                
                // 统计卡片
                VStack(spacing: 24) {
                    StatRowLarge(icon: "moon.fill", value: "\(wrappedData.totalDreams)", label: "总梦境数")
                    StatRowLarge(icon: "eye.fill", value: "\(wrappedData.lucidDreamCount)", label: "清醒梦")
                    StatRowLarge(icon: "flame.fill", value: "\(wrappedData.dreamStreak)", label: "连续记录")
                    StatRowLarge(icon: "star.fill", value: String(format: "%.1f", wrappedData.averageClarity), label: "平均清晰度")
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.1))
                )
                
                Spacer()
                
                // 品牌
                HStack(spacing: 16) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 32))
                    Text("DreamLog")
                        .font(.system(size: 36, weight: .semibold))
                    Text("· 探索潜意识")
                        .font(.system(size: 28))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 80)
            }
        }
    }
}

/// 大统计项目视图
struct ShareStatItemLarge: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(value)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

/// 统计行视图
struct StatRowLarge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 30) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 60)
            
            Text(value)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
}

// MARK: - 预览

#Preview {
    VStack {
        StandardShareCardView(wrappedData: createSampleData())
            .frame(width: 375, height: 667)
            .scaleEffect(0.5)
        
        SquareShareCardView(wrappedData: createSampleData())
            .frame(width: 375, height: 375)
            .scaleEffect(0.5)
        
        WeChatShareCardView(wrappedData: createSampleData())
            .frame(width: 375, height: 469)
            .scaleEffect(0.5)
    }
}

/// 创建示例数据用于预览
private func createSampleData() -> DreamWrappedData {
    DreamWrappedData(
        period: .year,
        generatedAt: Date(),
        totalDreams: 128,
        lucidDreamCount: 23,
        averageClarity: 7.5,
        averageIntensity: 6.8,
        topEmotions: [],
        topTags: [],
        dreamStreak: 21,
        longestStreak: 45,
        mostVividDream: nil,
        mostIntenseDream: nil,
        timeOfDayDistribution: [:],
        weeklyPattern: [],
        monthlyTrend: [],
        uniqueStats: [],
        shareCardQuote: "在年度里，我记录了 128 个梦境 🌙"
    )
}
