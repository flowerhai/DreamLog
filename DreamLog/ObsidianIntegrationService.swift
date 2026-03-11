//
//  ObsidianIntegrationService.swift
//  DreamLog
//
//  Phase 19 - Dream Data Export & Integration
//  Obsidian vault integration for exporting dreams
//

import Foundation

class ObsidianIntegrationService {
    
    static let shared = ObsidianIntegrationService()
    
    private var config: ObsidianConfig {
        didSet {
            saveConfig()
        }
    }
    
    init() {
        self.config = loadConfig()
    }
    
    // MARK: - Configuration
    
    private func loadConfig() -> ObsidianConfig {
        guard let data = UserDefaults.standard.data(forKey: "ObsidianConfig"),
              let config = try? JSONDecoder().decode(ObsidianConfig.self, from: data) else {
            return ObsidianConfig()
        }
        return config
    }
    
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "ObsidianConfig")
        }
    }
    
    func updateConfig(vaultPath: String, folderName: String, templateFile: String?, isEnabled: Bool) {
        config = ObsidianConfig(
            vaultPath: vaultPath,
            folderName: folderName,
            templateFile: templateFile,
            isEnabled: isEnabled
        )
    }
    
    // MARK: - Export to Obsidian
    
    @MainActor
    func exportToObsidian(dreams: [Dream]) async -> ObsidianSyncResult {
        guard config.isEnabled, !config.vaultPath.isEmpty else {
            return ObsidianSyncResult(
                success: false,
                errorMessage: "Obsidian 集成未配置"
            )
        }
        
        do {
            // Create dreams folder if it doesn't exist
            let dreamsFolder = URL(fileURLWithPath: config.vaultPath)
                .appendingPathComponent(config.folderName)
            
            try FileManager.default.createDirectory(at: dreamsFolder, withIntermediateDirectories: true)
            
            var exportedCount = 0
            
            for dream in dreams {
                do {
                    try exportDreamToObsidian(dream: dream, to: dreamsFolder)
                    exportedCount += 1
                } catch {
                    print("Failed to export dream \(dream.id): \(error)")
                }
            }
            
            return ObsidianSyncResult(
                success: true,
                exportedCount: exportedCount,
                outputPath: dreamsFolder.path
            )
            
        } catch {
            return ObsidianSyncResult(
                success: false,
                errorMessage: "导出失败：\(error.localizedDescription)"
            )
        }
    }
    
    private func exportDreamToObsidian(dream: Dream, to folder: URL) throws {
        let filename = generateFilename(for: dream)
        let fileURL = folder.appendingPathComponent(filename)
        
        let content = generateObsidianNote(dream: dream)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func generateFilename(for dream: Dream) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: dream.date)
        
        let safeTitle = dream.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .prefix(50)
        
        return "\(dateStr)_\(safeTitle).md"
    }
    
    private func generateObsidianNote(dream: Dream) -> String {
        var content = "---\n"
        
        // Frontmatter with YAML
        content += "tags: [\(dream.tags.joined(separator: ", "))]\n"
        
        if !dream.emotions.isEmpty {
            content += "emotions: [\(dream.emotions.map { $0.rawValue }.joined(separator: ", "))]\n"
        }
        
        content += "clarity: \(dream.clarity)\n"
        content += "intensity: \(dream.intensity)\n"
        content += "lucid: \(dream.isLucid)\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        content += "date: \(dateFormatter.string(from: dream.date))\n"
        content += "exported: \(dateFormatter.string(from: Date()))\n"
        
        content += "---\n\n"
        
        // Title
        content += "# \(dream.title)\n\n"
        
        // Content
        content += "## 梦境内容\n\n"
        content += "\(dream.content)\n\n"
        
        // Stats
        content += "## 统计\n\n"
        content += "- **清晰度**: \(String(repeating: "⭐️", count: dream.clarity)) (\(dream.clarity)/5)\n"
        content += "- **强度**: \(String(repeating: "💪", count: dream.intensity)) (\(dream.intensity)/5)\n"
        content += "- **清醒梦**: \(dream.isLucid ? "✅ 是" : "❌ 否")\n\n"
        
        // AI Analysis
        if let analysis = dream.aiAnalysis {
            content += "## AI 解析\n\n"
            content += "\(analysis)\n\n"
        }
        
        // Backlinks suggestion
        if !dream.tags.isEmpty {
            content += "## 相关链接\n\n"
            for tag in dream.tags.prefix(3) {
                content += "- [[\(tag)]]\n"
            }
            content += "\n"
        }
        
        // Footer
        content += "---\n"
        content += "_由 DreamLog 导出 | #梦境 #日记_\n"
        
        return content
    }
    
    // MARK: - Template Management
    
    func createTemplate() -> String {
        return """
        ---
        tags: [dream]
        emotions: []
        clarity: 3
        intensity: 3
        lucid: false
        date: {{date}}
        ---
        
        # {{title}}
        
        ## 梦境内容
        
        {{content}}
        
        ## 统计
        
        - **清晰度**: {{clarity}}/5
        - **强度**: {{intensity}}/5
        - **清醒梦**: {{lucid}}
        
        ## AI 解析
        
        {{aiAnalysis}}
        
        ## 相关链接
        
        {{backlinks}}
        
        ---
        _由 DreamLog 导出 | #梦境 #日记_
        """
    }
    
    func saveTemplate(to vaultPath: String) throws {
        let templateContent = createTemplate()
        let templatesFolder = URL(fileURLWithPath: vaultPath).appendingPathComponent("Templates")
        
        try FileManager.default.createDirectory(at: templatesFolder, withIntermediateDirectories: true)
        
        let templateURL = templatesFolder.appendingPathComponent("DreamLog Template.md")
        try templateContent.write(to: templateURL, atomically: true, encoding: .utf8)
    }
}
