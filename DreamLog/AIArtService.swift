//
//  AIArtService.swift
//  DreamLog
//
//  AI 绘画集成 - 根据梦境内容生成图像
//

import Foundation
import SwiftUI

// MARK: - 梦境艺术模型

/// 梦境艺术作品
struct DreamArt: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var dreamId: UUID
    var imageUrl: String
    var prompt: String
    var style: ArtStyle
    var createdAt: Date
    var isFavorite: Bool = false
    
    enum ArtStyle: String, Codable, CaseIterable, Identifiable {
        case realistic = "写实风格"
        case impressionist = "印象派"
        case surreal = "超现实主义"
        case anime = "动漫风格"
        case watercolor = "水彩画"
        case oil = "油画"
        case digital = "数字艺术"
        case dreamy = "梦幻风格"
        // Phase 8 新增风格
        case abstract = "抽象艺术"
        case minimalist = "极简主义"
        case cyberpunk = "赛博朋克"
        case fantasy = "奇幻风格"
        case noir = "黑色电影"
        case popArt = "波普艺术"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .realistic: return "照片般真实的渲染"
            case .impressionist: return "莫奈、雷诺阿风格"
            case .surreal: return "达利、马格利特风格"
            case .anime: return "日本动漫风格"
            case .watercolor: return "柔和的水彩效果"
            case .oil: return "古典油画质感"
            case .digital: return "现代数字绘画"
            case .dreamy: return "朦胧梦幻的视觉效果"
            case .abstract: return "抽象表现主义，色彩与形式的自由表达"
            case .minimalist: return "极简构图，留白艺术"
            case .cyberpunk: return "霓虹灯、高科技低生活、未来都市"
            case .fantasy: return "魔法、龙、中世纪奇幻世界"
            case .noir: return "黑白对比、阴影、神秘氛围"
            case .popArt: return "鲜艳色彩、大众文化、安迪沃霍尔风格"
            }
        }
        
        var promptSuffix: String {
            switch self {
            case .realistic: return ", photorealistic, highly detailed, 8k, HDR"
            case .impressionist: return ", impressionist style, soft brushstrokes, Claude Monet style, visible brushwork"
            case .surreal: return ", surrealism, dreamlike, Salvador Dali style, bizarre, unexpected juxtapositions"
            case .anime: return ", anime style, Studio Ghibli, Makoto Shinkai, cel shaded"
            case .watercolor: return ", watercolor painting, soft edges, pastel colors, wet on wet technique"
            case .oil: return ", oil painting, textured brushstrokes, classical art, impasto technique"
            case .digital: return ", digital art, concept art, ArtStation, trending on CGSociety"
            case .dreamy: return ", dreamy, ethereal, soft focus, pastel colors, magical, bokeh"
            case .abstract: return ", abstract expressionism, bold colors, geometric shapes, Kandinsky style"
            case .minimalist: return ", minimalist, clean composition, negative space, simple forms"
            case .cyberpunk: return ", cyberpunk, neon lights, futuristic city, blade runner style, high tech low life"
            case .fantasy: return ", fantasy art, magical, dragons, medieval, epic, Lord of the Rings style"
            case .noir: return ", film noir, black and white, high contrast, dramatic shadows, mystery"
            case .popArt: return ", pop art, vibrant colors, Andy Warhol style, comic book inspired"
            }
        }
        
        var negativePrompt: String {
            switch self {
            case .realistic: return "cartoon, anime, drawing, painting, blurry, low quality"
            case .impressionist: return "photorealistic, sharp details, digital art, 3d render"
            case .surreal: return "realistic, ordinary, mundane, boring, conventional"
            case .anime: return "realistic, photo, 3d, western cartoon"
            case .watercolor: return "digital, photo, sharp edges, vibrant saturated colors"
            case .oil: return "digital, photo, watercolor, sketch"
            case .digital: return "traditional art, photo, painting, low quality"
            case .dreamy: return "sharp focus, harsh lighting, realistic, mundane"
            case .abstract: return "realistic, representational, literal, clear subject"
            case .minimalist: return "cluttered, complex, detailed, busy composition"
            case .cyberpunk: return "medieval, fantasy, nature, rural, pastel colors"
            case .fantasy: return "modern, technology, urban, realistic, sci-fi"
            case .noir: return "colorful, bright, cheerful, cartoon, anime"
            case .popArt: return "muted colors, realistic, minimalist, subtle"
            }
        }
        
        var icon: String {
            switch self {
            case .realistic: return "camera.fill"
            case .impressionist: return "paintbrush.fill"
            case .surreal: return "eye.fill"
            case .anime: return "star.fill"
            case .watercolor: return "drop.fill"
            case .oil: return "palette.fill"
            case .digital: return "display.fill"
            case .dreamy: return "sparkles"
            case .abstract: return "square.split.diagonal"
            case .minimalist: return "square.dashed"
            case .cyberpunk: return "bolt.fill"
            case .fantasy: return "wand.and.stars"
            case .noir: return "moon.fill"
            case .popArt: return "circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .realistic: return "007AFF"
            case .impressionist: return "FF9500"
            case .surreal: return "AF52DE"
            case .anime: return "FF2D55"
            case .watercolor: return "5AC8FA"
            case .oil: return "FFCC00"
            case .digital: return "4CD964"
            case .dreamy: return "FF6B9D"
            case .abstract: return "FF3B30"
            case .minimalist: return "8E8E93"
            case .cyberpunk: return "00F0FF"
            case .fantasy: return "9D50DD"
            case .noir: return "1C1C1E"
            case .popArt: return "FF9F0A"
            }
        }
    }
    
    /// 图像宽高比
    enum AspectRatio: String, Codable, CaseIterable, Identifiable {
        case square = "1:1"
        case portrait = "9:16"
        case landscape = "16:9"
        case portrait4x5 = "4:5"
        case landscape4x3 = "4:3"
        
        var id: String { rawValue }
        
        var width: Int {
            switch self {
            case .square: return 1024
            case .portrait: return 576
            case .landscape: return 1024
            case .portrait4x5: return 832
            case .landscape4x3: return 1024
            }
        }
        
        var height: Int {
            switch self {
            case .square: return 1024
            case .portrait: return 1024
            case .landscape: return 576
            case .portrait4x5: return 1040
            case .landscape4x3: return 768
            }
        }
        
        var displayName: String {
            switch self {
            case .square: return "正方形 (1:1)"
            case .portrait: return "竖屏 (9:16)"
            case .landscape: return "横屏 (16:9)"
            case .portrait4x5: return "肖像 (4:5)"
            case .landscape4x3: return "风景 (4:3)"
            }
        }
    }
}

// MARK: - AI 绘画错误

enum AIArtError: LocalizedError {
    case monthlyLimitReached
    case premiumFeatureRequired
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .monthlyLimitReached:
            return "已达到本月 AI 绘画次数限制"
        case .premiumFeatureRequired:
            return "此功能需要高级版订阅"
        case .generationFailed:
            return "AI 绘画生成失败，请重试"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .monthlyLimitReached:
            return "升级至高级版可获得无限 AI 绘画，或下月继续使用"
        case .premiumFeatureRequired:
            return "升级至高级版即可解锁此功能"
        case .generationFailed:
            return "请检查网络连接后重试"
        }
    }
}

// MARK: - AI 绘画服务

@MainActor
class AIArtService: ObservableObject {
    static let shared = AIArtService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var currentDreamArt: DreamArt?
    @Published var errorMessage: String?
    
    // 本地存储的艺术作品
    @Published var dreamArts: [DreamArt] = []
    
    private let fileManager = FileManager.default
    private var artsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("DreamArts", isDirectory: true)
    }
    
    private init() {
        loadDreamArts()
    }
    
    // MARK: - 订阅检查
    
    /// 检查 AI 绘画使用限制
    private func checkAIArtUsageLimit() throws {
        // Premium 用户无限制
        if SubscriptionManager.shared.isPremium {
            return
        }
        
        // 检查免费版每月限制
        let usageTracker = DreamUsageTracker.shared
        guard usageTracker.canUseAIArt() else {
            throw AIArtError.monthlyLimitReached
        }
        
        // 记录使用
        usageTracker.recordAIArtUsage()
    }
    
    // MARK: - 生成提示词
    
    /// 从梦境内容生成 AI 绘画提示词
    func generatePrompt(from dream: Dream, style: DreamArt.ArtStyle, aspectRatio: DreamArt.AspectRatio = .square) -> String {
        var promptComponents: [String] = []
        
        // 1. 主体描述（标题 + 核心内容）
        if !dream.title.isEmpty {
            promptComponents.append("\"\(dream.title)\"")
        }
        
        // 2. 内容提取关键意象
        let contentKeywords = extractKeyImagery(from: dream.content)
        if !contentKeywords.isEmpty {
            promptComponents.append(contentsOf: contentKeywords)
        }
        
        // 3. 情绪氛围（权重增强）
        if !dream.emotions.isEmpty {
            let moodWords = dream.emotions.prefix(3).map { emotion in
                switch emotion.lowercased() {
                case "快乐", "开心", "兴奋": return "(joyful:1.3), bright, vibrant, energetic"
                case "恐惧", "害怕", "紧张": return "(dark:1.2), mysterious, tense, ominous"
                case "平静", "安宁", "放松": return "(peaceful:1.3), calm, serene, tranquil"
                case "悲伤", "难过": return "(melancholic:1.2), somber, moody, introspective"
                case "惊讶", "惊奇": return "(wondrous:1.3), magical, astonishing, awe-inspiring"
                case "愤怒", "生气": return "(intense:1.3), dramatic, fiery, powerful"
                case "困惑", "迷茫": return "(surreal:1.2), abstract, confusing, disorienting"
                case "期待", "希望": return "(hopeful:1.3), uplifting, inspirational, radiant"
                default: return "emotional, expressive"
                }
            }
            promptComponents.append(moodWords.joined(separator: ", "))
        }
        
        // 4. 时间氛围（带权重）
        switch dream.timeOfDay {
        case .morning: promptComponents.append("(morning light:1.2), sunrise, golden hour, fresh")
        case .afternoon: promptComponents.append("afternoon, bright daylight, clear sky")
        case .evening: promptComponents.append("(evening:1.2), sunset, warm colors, golden")
        case .night: promptComponents.append("(night scene:1.3), moonlight, stars, dark atmosphere")
        case .dawn: promptComponents.append("dawn, early morning, soft light, awakening")
        case .dusk: promptComponents.append("dusk, twilight, purple sky, transition")
        }
        
        // 5. 梦境清晰度影响风格
        if dream.clarity >= 4 {
            promptComponents.append("(crystal clear:1.3), sharp details, vivid, hyperdetailed")
        } else if dream.clarity <= 2 {
            promptComponents.append("(dreamy blur:1.2), hazy, soft focus, ethereal mist")
        } else {
            promptComponents.append("balanced details, moderate clarity")
        }
        
        // 6. 强度影响色彩
        if dream.intensity >= 4 {
            promptComponents.append("(vibrant colors:1.3), high contrast, dramatic lighting, bold")
        } else if dream.intensity <= 2 {
            promptComponents.append("(muted colors:1.2), soft tones, gentle, pastel palette")
        } else {
            promptComponents.append("balanced colors, natural saturation")
        }
        
        // 7. 清醒梦特殊效果
        if dream.isLucid {
            promptComponents.append("(lucid dream:1.4), glowing elements, magical realism, consciousness awareness, surreal luminescence")
        }
        
        // 8. 构图和视角
        promptComponents.append("professional composition, rule of thirds, cinematic lighting")
        
        // 9. 基础质量词（权重增强）
        promptComponents.append("(masterpiece:1.4), (best quality:1.3), (high resolution:1.2), ultra detailed")
        
        // 10. 风格后缀
        promptComponents.append(style.promptSuffix)
        
        // 11. 宽高比提示
        if aspectRatio != .square {
            promptComponents.append("aspect ratio \(aspectRatio.rawValue)")
        }
        
        return promptComponents.joined(separator: ", ")
    }
    
    /// 生成负面提示词
    func generateNegativePrompt(for style: DreamArt.ArtStyle) -> String {
        var negativeComponents: [String] = [
            "low quality", "worst quality", "blurry", "jpeg artifacts",
            "cropped", "out of frame", "watermark", "signature",
            "text", "username", "error", "missing fingers",
            "extra limbs", "disfigured", "deformed", "malformed hands"
        ]
        
        // 添加风格特定的负面提示
        negativeComponents.append(style.negativePrompt)
        
        return negativeComponents.joined(separator: ", ")
    }
    
    /// 从梦境内容提取关键意象
    private func extractKeyImagery(from content: String) -> [String] {
        let imageryKeywords: [String: [String]] = [
            "水": ["water", "ocean", "river", "lake", "stream", "waterfall"],
            "火": ["fire", "flame", "burning", "inferno"],
            "天空": ["sky", "clouds", "heaven", "firmament"],
            "山": ["mountain", "peak", "hill", "valley"],
            "树": ["tree", "forest", "woods", "grove"],
            "花": ["flower", "blossom", "garden", "petals"],
            "动物": ["animal", "creature", "beast"],
            "鸟": ["bird", "flying", "wings", "feathers"],
            "鱼": ["fish", "swimming", "aquatic"],
            "房子": ["house", "building", "home", "architecture"],
            "路": ["path", "road", "street", "journey"],
            "桥": ["bridge", "crossing", "connection"],
            "门": ["door", "gateway", "entrance"],
            "光": ["light", "glow", "radiance", "beam"],
            "影子": ["shadow", "silhouette", "darkness"],
            "镜子": ["mirror", "reflection", "glass"],
            "星星": ["star", "constellation", "celestial"],
            "月亮": ["moon", "lunar", "crescent"],
            "太阳": ["sun", "solar", "sunlight"],
            "雨": ["rain", "droplets", "storm"],
            "雪": ["snow", "winter", "ice", "frozen"],
            "风": ["wind", "breeze", "gust"]
        ]
        
        var foundImagery: [String] = []
        let lowercasedContent = content.lowercased()
        
        for (category, keywords) in imageryKeywords {
            for keyword in keywords {
                if lowercasedContent.contains(keyword) || content.contains(category) {
                    switch category {
                    case "水": foundImagery.append("flowing water, serene water element")
                    case "火": foundImagery.append("dynamic fire element, warm glow")
                    case "天空": foundImagery.append("expansive sky, atmospheric")
                    case "山": foundImagery.append("majestic mountains, landscape")
                    case "树": foundImagery.append("lush trees, natural environment")
                    case "花": foundImagery.append("beautiful flowers, botanical")
                    case "动物": foundImagery.append("mystical creature, wildlife")
                    case "鸟": foundImagery.append("graceful bird in flight")
                    case "鱼": foundImagery.append("colorful fish, underwater life")
                    case "房子": foundImagery.append("architectural structure, dwelling")
                    case "路": foundImagery.append("winding path, journey ahead")
                    case "桥": foundImagery.append("elegant bridge, connection")
                    case "门": foundImagery.append("mysterious door, portal")
                    case "光": foundImagery.append("beautiful lighting, rays of light")
                    case "影子": foundImagery.append("dramatic shadows, contrast")
                    case "镜子": foundImagery.append("mirror reflection, symmetry")
                    case "星星": foundImagery.append("twinkling stars, night sky")
                    case "月亮": foundImagery.append("glowing moon, lunar light")
                    case "太阳": foundImagery.append("bright sun, warm sunlight")
                    case "雨": foundImagery.append("gentle rain, raindrops")
                    case "雪": foundImagery.append("peaceful snow, winter wonderland")
                    case "风": foundImagery.append("flowing wind, movement")
                    default: break
                    }
                    break
                }
            }
        }
        
        return foundImagery.prefix(5).map { String($0) }
    }
    
    // MARK: - 生成图像
    
    /// 为梦境生成 AI 图像
    func generateArt(for dream: Dream, style: DreamArt.ArtStyle, aspectRatio: DreamArt.AspectRatio = .square) async throws {
        // 检查订阅状态和使用限制
        try checkAIArtUsageLimit()
        
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        // 生成提示词和负面提示词
        let prompt = generatePrompt(from: dream, style: style, aspectRatio: aspectRatio)
        let negativePrompt = generateNegativePrompt(for: style)
        
        print("🎨 正面提示词：\(prompt)")
        print("🚫 负面提示词：\(negativePrompt)")
        
        // 模拟生成过程（实际使用时替换为真实 API 调用）
        let seed = Int(dream.id.hashValue) & 0x7FFFFFFF
        let width = aspectRatio.width
        let height = aspectRatio.height
        
        // 模拟进度更新
        for i in 1...5 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
            generationProgress = Double(i) / 5.0 * 0.8 // 80% 是生成过程
        }
        
        // 使用 Picsum 作为占位图（实际应使用 Stable Diffusion API）
        let imageUrl = "https://picsum.photos/seed/\(seed)/\(width)/\(height)"
        
        generationProgress = 1.0
        
        // 创建艺术作品记录
        let art = DreamArt(
            dreamId: dream.id,
            imageUrl: imageUrl,
            prompt: prompt,
            style: style,
            createdAt: Date()
        )
        
        currentDreamArt = art
        dreamArts.insert(art, at: 0)
        saveDreamArts()
        
        print("✅ 艺术作品生成完成 - \(style.rawValue)")
    }
    
    /// 批量生成多种风格的艺术作品
    func generateBatchArt(for dream: Dream, styles: [DreamArt.ArtStyle], aspectRatio: DreamArt.AspectRatio = .square) async {
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        let totalStyles = styles.count
        
        for (index, style) in styles.enumerated() {
            generationProgress = Double(index) / Double(totalStyles)
            
            do {
                try await generateSingleArt(for: dream, style: style, aspectRatio: aspectRatio)
            } catch {
                errorMessage = "生成 \(style.rawValue) 风格时出错：\(error.localizedDescription)"
                print("❌ 生成失败 \(style.rawValue): \(error)")
            }
        }
        
        generationProgress = 1.0
        isGenerating = false
        
        print("✅ 批量生成完成 - 共 \(dreamArts.prefix(totalStyles).count) 个艺术作品")
    }
    
    /// 生成单个艺术作品（内部方法）
    private func generateSingleArt(for dream: Dream, style: DreamArt.ArtStyle, aspectRatio: DreamArt.AspectRatio) async throws {
        // 检查订阅状态和使用限制（批量生成时每个都检查）
        try checkAIArtUsageLimit()
        
        let prompt = generatePrompt(from: dream, style: style, aspectRatio: aspectRatio)
        let negativePrompt = generateNegativePrompt(for: style)
        
        let seed = Int(dream.id.hashValue &+ style.hashValue) & 0x7FFFFFFF
        let width = aspectRatio.width
        let height = aspectRatio.height
        
        // 模拟 API 调用延迟
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 秒
        
        let imageUrl = "https://picsum.photos/seed/\(seed)/\(width)/\(height)"
        
        let art = DreamArt(
            dreamId: dream.id,
            imageUrl: imageUrl,
            prompt: prompt,
            style: style,
            createdAt: Date()
        )
        
        dreamArts.insert(art, at: 0)
        saveDreamArts()
    }
    
    // MARK: - 真实 API 集成示例
    
    /// 调用 Stability AI API 生成图像
    func generateWithStabilityAI(prompt: String, style: DreamArt.ArtStyle) async throws -> Data {
        // 这是真实 API 调用的示例代码
        // 需要配置 API Key
        
        guard let apiKey = ProcessInfo.processInfo.environment["STABILITY_API_KEY"] else {
            throw NSError(domain: "AIArtService", code: 401, userInfo: [NSLocalizedDescriptionKey: "未配置 Stability AI API Key"])
        }
        
        guard let url = URL(string: "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image") else {
            throw NSError(domain: "AIArtService", code: 500, userInfo: [NSLocalizedDescriptionKey: "无效的 API URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text_prompts": [
                ["text": prompt, "weight": 1.0]
            ],
            "cfg_scale": 7,
            "height": 1024,
            "width": 1024,
            "samples": 1,
            "steps": 30
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AIArtService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API 请求失败"])
        }
        
        return data
    }
    
    // MARK: - 数据持久化
    
    private func saveDreamArts() {
        let artsFile = artsDirectory.appendingPathComponent("dream_arts.json")
        
        do {
            try fileManager.createDirectory(at: artsDirectory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(dreamArts)
            try data.write(to: artsFile)
        } catch {
            print("❌ 保存艺术作品失败：\(error)")
        }
    }
    
    private func loadDreamArts() {
        let artsFile = artsDirectory.appendingPathComponent("dream_arts.json")
        
        guard let data = try? Data(contentsOf: artsFile) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            dreamArts = try decoder.decode([DreamArt].self, from: data)
        } catch {
            print("❌ 加载艺术作品失败：\(error)")
        }
    }
    
    // MARK: - 管理操作
    
    func toggleFavorite(_ art: DreamArt) {
        if let index = dreamArts.firstIndex(where: { $0.id == art.id }) {
            dreamArts[index].isFavorite.toggle()
            saveDreamArts()
        }
    }
    
    func deleteArt(_ art: DreamArt) {
        dreamArts.removeAll { $0.id == art.id }
        saveDreamArts()
    }
    
    func getArts(for dreamId: UUID) -> [DreamArt] {
        dreamArts.filter { $0.dreamId == dreamId }
    }
}

// MARK: - 预览数据

#if DEBUG
extension DreamArt {
    static let preview: DreamArt = DreamArt(
        dreamId: UUID(),
        imageUrl: "https://picsum.photos/seed/123/1024/1024",
        prompt: "A mystical forest with glowing mushrooms, moonlight filtering through ancient trees",
        style: .dreamy,
        createdAt: Date()
    )
}
#endif
