//
//  NotionIntegrationService.swift
//  DreamLog
//
//  Phase 19 - Dream Data Export & Integration
//  Notion API integration for syncing dreams
//

import Foundation

class NotionIntegrationService {
    
    static let shared = NotionIntegrationService()
    
    private let baseURL = "https://api.notion.com/v1"
    private var config: NotionConfig {
        didSet {
            saveConfig()
        }
    }
    
    init() {
        self.config = loadConfig()
    }
    
    // MARK: - Configuration
    
    private func loadConfig() -> NotionConfig {
        guard let data = UserDefaults.standard.data(forKey: "NotionConfig"),
              let config = try? JSONDecoder().decode(NotionConfig.self, from: data) else {
            return NotionConfig()
        }
        return config
    }
    
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "NotionConfig")
        }
    }
    
    func updateConfig(apiKey: String, databaseId: String, isEnabled: Bool) {
        config = NotionConfig(apiKey: apiKey, databaseId: databaseId, isEnabled: isEnabled)
    }
    
    func testConnection() async -> Bool {
        guard config.isEnabled, !config.apiKey.isEmpty, !config.databaseId.isEmpty else {
            return false
        }
        
        // Test by querying the database
        let url = "\(baseURL)/databases/\(config.databaseId)/query"
        guard let parsedURL = URL(string: url) else {
            print("Notion: Invalid URL: \(url)")
            return false
        }
        var request = URLRequest(url: parsedURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.httpBody = "{}".data(using: .utf8)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            print("Notion connection test failed: \(error)")
            return false
        }
    }
    
    // MARK: - Sync Dreams to Notion
    
    @MainActor
    func syncDreams(_ dreams: [Dream]) async -> NotionSyncResult {
        guard config.isEnabled, !config.apiKey.isEmpty, !config.databaseId.isEmpty else {
            return NotionSyncResult(
                success: false,
                errorMessage: "Notion 集成未配置"
            )
        }
        
        var syncedCount = 0
        var failedCount = 0
        
        for dream in dreams {
            do {
                try await createDreamPage(dream: dream)
                syncedCount += 1
            } catch {
                print("Failed to sync dream \(dream.id): \(error)")
                failedCount += 1
            }
        }
        
        return NotionSyncResult(
            success: failedCount == 0,
            syncedCount: syncedCount,
            failedCount: failedCount
        )
    }
    
    private func createDreamPage(dream: Dream) async throws {
        let url = "\(baseURL)/pages"
        guard let parsedURL = URL(string: url) else {
            throw NSError(domain: "NotionSync", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(url)"])
        }
        var request = URLRequest(url: parsedURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        
        let pageProperties: [String: Any] = [
            "parent": ["database_id": config.databaseId],
            "properties": [
                "Name": ["title": [["text": ["content": dream.title]]]],
                "Date": ["date": ["start": ISO8601DateFormatter().string(from: dream.date).prefix(10)]],
                "Content": ["rich_text": [["text": ["content": dream.content]]]],
                "Tags": ["multi_select": dream.tags.map { ["name": $0] }],
                "Clarity": ["number": dream.clarity],
                "Intensity": ["number": dream.intensity],
                "Lucid Dream": ["checkbox": dream.isLucid]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: pageProperties)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw NSError(domain: "NotionSync", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create page"])
        }
    }
    
    // MARK: - Database Setup
    
    func createDatabaseTemplate() -> String {
        return """
        请在 Notion 中创建一个数据库，并添加以下属性：
        
        - Name (Title): 梦境标题
        - Date (Date): 梦境日期
        - Content (Rich Text): 梦境内容
        - Tags (Multi-select): 标签
        - Emotions (Multi-select): 情绪
        - Clarity (Number): 清晰度 (1-5)
        - Intensity (Number): 强度 (1-5)
        - Lucid Dream (Checkbox): 是否为清醒梦
        - AI Analysis (Rich Text): AI 解析
        
        创建后，将数据库 ID 填入设置中。
        """
    }
}
