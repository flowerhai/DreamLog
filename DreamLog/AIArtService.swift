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
    
    enum ArtStyle: String, Codable, CaseIterable {
        case realistic = "写实风格"
        case impressionist = "印象派"
        case surreal = "超现实主义"
        case anime = "动漫风格"
        case watercolor = "水彩画"
        case oil = "油画"
        case digital = "数字艺术"
        case dreamy = "梦幻风格"
        
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
            }
        }
        
        var promptSuffix: String {
            switch self {
            case .realistic: return ", photorealistic, highly detailed, 8k"
            case .impressionist: return ", impressionist style, soft brushstrokes, Claude Monet style"
            case .surreal: return ", surrealism, dreamlike, Salvador Dali style, bizarre"
            case .anime: return ", anime style, Studio Ghibli, Makoto Shinkai"
            case .watercolor: return ", watercolor painting, soft edges, pastel colors"
            case .oil: return ", oil painting, textured brushstrokes, classical art"
            case .digital: return ", digital art, concept art, ArtStation"
            case .dreamy: return ", dreamy, ethereal, soft focus, pastel colors, magical"
            }
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
    
    // MARK: - 生成提示词
    
    /// 从梦境内容生成 AI 绘画提示词
    func generatePrompt(from dream: Dream, style: DreamArt.ArtStyle) -> String {
        var promptComponents: [String] = []
        
        // 标题
        if !dream.title.isEmpty {
            promptComponents.append(dream.title)
        }
        
        // 内容提取关键意象
        let contentKeywords = extractKeyImagery(from: dream.content)
        if !contentKeywords.isEmpty {
            promptComponents.append(contentsOf: contentKeywords)
        }
        
        // 情绪氛围
        if !dream.emotions.isEmpty {
            let moodWords = dream.emotions.prefix(3).map { emotion in
                switch emotion.lowercased() {
                case "快乐", "开心", "兴奋": return "joyful, bright, vibrant"
                case "恐惧", "害怕", "紧张": return "dark, mysterious, tense"
                case "平静", "安宁", "放松": return "peaceful, calm, serene"
                case "悲伤", "难过": return "melancholic, somber, moody"
                case "惊讶", "惊奇": return "wondrous, magical, astonishing"
                case "愤怒", "生气": return "intense, dramatic, fiery"
                case "困惑", "迷茫": return "surreal, abstract, confusing"
                case "期待", "希望": return "hopeful, uplifting, inspirational"
                default: return "emotional, expressive"
                }
            }
            promptComponents.append(moodWords.joined(separator: ", "))
        }
        
        // 时间氛围
        switch dream.timeOfDay {
        case .morning: promptComponents.append("morning light, sunrise, golden hour")
        case .afternoon: promptComponents.append("afternoon, bright daylight")
        case .evening: promptComponents.append("evening, sunset, warm colors")
        case .night: promptComponents.append("night scene, moonlight, stars, dark atmosphere")
        case .dawn: promptComponents.append("dawn, early morning, soft light")
        case .dusk: promptComponents.append("dusk, twilight, purple sky")
        }
        
        // 梦境清晰度影响风格
        if dream.clarity >= 4 {
            promptComponents.append("clear, sharp details, vivid")
        } else if dream.clarity <= 2 {
            promptComponents.append("blurry, hazy, dreamlike, soft focus")
        }
        
        // 强度影响色彩
        if dream.intensity >= 4 {
            promptComponents.append("vibrant colors, high contrast, dramatic")
        } else if dream.intensity <= 2 {
            promptComponents.append("muted colors, soft tones, gentle")
        }
        
        // 清醒梦特殊效果
        if dream.isLucid {
            promptComponents.append("lucid dream, glowing elements, magical realism, consciousness")
        }
        
        // 基础质量词
        promptComponents.append("masterpiece, best quality, high resolution")
        
        // 风格后缀
        promptComponents.append(style.promptSuffix)
        
        return promptComponents.joined(separator: ", ")
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
    func generateArt(for dream: Dream, style: DreamArt.ArtStyle) async {
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        // 生成提示词
        let prompt = generatePrompt(from: dream, style: style)
        print("🎨 生成提示词：\(prompt)")
        
        // 模拟生成过程（实际使用时替换为真实 API 调用）
        // 这里使用占位图服务作为示例
        let seed = Int(dream.id.hashValue) & 0x7FFFFFFF
        let width = 1024
        let height = 1024
        
        // 模拟进度更新
        for i in 1...5 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
            generationProgress = Double(i) / 5.0 * 0.8 // 80% 是生成过程
        }
        
        // 使用 Picsum 作为占位图（实际应使用 Stable Diffusion API）
        // 真实实现时替换为：
        // - Stability AI API
        // - Midjourney API
        // - DALL-E API
        // - 本地 Stable Diffusion 模型
        
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
        
        print("✅ 艺术作品生成完成")
    }
    
    // MARK: - 真实 API 集成示例
    
    /// 调用 Stability AI API 生成图像
    func generateWithStabilityAI(prompt: String, style: DreamArt.ArtStyle) async throws -> Data {
        // 这是真实 API 调用的示例代码
        // 需要配置 API Key
        
        guard let apiKey = ProcessInfo.processInfo.environment["STABILITY_API_KEY"] else {
            throw NSError(domain: "AIArtService", code: 401, userInfo: [NSLocalizedDescriptionKey: "未配置 Stability AI API Key"])
        }
        
        let url = URL(string: "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image")!
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
