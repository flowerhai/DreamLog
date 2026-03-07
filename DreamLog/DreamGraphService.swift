//
//  DreamGraphService.swift
//  DreamLog
//
//  梦境关联图谱服务 - 分析和可视化梦境之间的关联
//  Phase 5 - 智能增强功能
//

import Foundation
import SwiftUI

// MARK: - 数据模型

/// 图谱节点
struct GraphNode: Identifiable, Equatable {
    var id: UUID
    var dreamId: UUID
    var title: String
    var date: Date
    var emotions: [String]
    var tags: [String]
    var isLucid: Bool
    var clarity: Int
    
    // 视觉属性
    var color: String
    var size: CGFloat
    
    init(dream: Dream) {
        self.id = UUID()
        self.dreamId = dream.id
        self.title = dream.title
        self.date = dream.date
        self.emotions = dream.emotions.map { $0.rawValue }
        self.tags = dream.tags
        self.isLucid = dream.isLucid
        self.clarity = dream.clarity
        
        // 根据主导情绪设置颜色
        if let primaryEmotion = dream.emotions.first {
            self.color = primaryEmotion.color
        } else {
            self.color = "8E8E93"
        }
        
        // 根据清晰度和强度设置节点大小
        let clarityFactor = CGFloat(dream.clarity) / 5.0
        let intensityFactor = CGFloat(dream.intensity) / 5.0
        self.size = 20 + (clarityFactor + intensityFactor) * 15
    }
}

/// 图谱边（连接）
struct GraphEdge: Identifiable, Equatable {
    var id: UUID
    var sourceId: UUID
    var targetId: UUID
    var relationshipType: RelationshipType
    var strength: Double // 0.0 - 1.0
    var sharedElements: [String]
    
    enum RelationshipType: String, Codable, CaseIterable {
        case sharedTags = "共同标签"
        case sharedEmotions = "共同情绪"
        case similarContent = "相似内容"
        case timeProximity = "时间接近"
        case similarThemes = "相似主题"
        case lucidConnection = "清醒梦关联"
        
        var icon: String {
            switch self {
            case .sharedTags: return "tag"
            case .sharedEmotions: return "heart"
            case .similarContent: return "text.bubble"
            case .timeProximity: return "clock"
            case .similarThemes: return "brain.head.profile"
            case .lucidConnection: return "eye"
            }
        }
        
        var color: String {
            switch self {
            case .sharedTags: return "4CAF50"
            case .sharedEmotions: return "E91E63"
            case .similarContent: return "2196F3"
            case .timeProximity: return "FF9800"
            case .similarThemes: return "9C27B0"
            case .lucidConnection: return "00BCD4"
            }
        }
    }
}

/// 关联图谱数据
struct DreamGraphData {
    var nodes: [GraphNode]
    var edges: [GraphEdge]
    var clusters: [GraphCluster]
    var statistics: GraphStatistics
    
    struct GraphCluster {
        var id: String
        var name: String
        var nodeIds: [UUID]
        var color: String
        var icon: String
    }
    
    struct GraphStatistics {
        var totalNodes: Int
        var totalEdges: Int
        var averageConnections: Double
        var density: Double
        var largestCluster: Int
        var isolatedNodes: Int
    }
}

// MARK: - 梦境关联图谱服务

@MainActor
class DreamGraphService: ObservableObject {
    static let shared = DreamGraphService()
    
    @Published var isLoading = false
    @Published var graphData: DreamGraphData?
    @Published var errorMessage: String?
    
    // 配置参数
    private let minConnectionStrength = 0.3
    private let maxEdgesPerNode = 8
    private let timeProximityDays = 7.0
    
    // MARK: - 生成图谱
    
    /// 生成梦境关联图谱
    func generateGraph(from dreams: [Dream]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 创建节点
            let nodes = dreams.map { GraphNode(dream: $0) }
            
            // 创建边
            let edges = try await generateEdges(from: dreams, nodes: nodes)
            
            // 聚类分析
            let clusters = performClustering(nodes: nodes, edges: edges)
            
            // 计算统计信息
            let statistics = calculateStatistics(nodes: nodes, edges: edges, clusters: clusters)
            
            self.graphData = DreamGraphData(
                nodes: nodes,
                edges: edges,
                clusters: clusters,
                statistics: statistics
            )
        } catch {
            self.errorMessage = "生成图谱失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - 生成连接边
    
    private func generateEdges(from dreams: [Dream], nodes: [GraphNode]) async throws -> [GraphEdge] {
        var edges: [GraphEdge] = []
        let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.dreamId, $0) })
        
        for (index1, dream1) in dreams.enumerated() {
            for (index2, dream2) in dreams.enumerated() where index1 < index2 {
                var connections: [(type: GraphEdge.RelationshipType, strength: Double, shared: [String])] = []
                
                // 1. 共同标签分析
                let sharedTags = Set(dream1.tags).intersection(Set(dream2.tags))
                if !sharedTags.isEmpty {
                    let tagStrength = min(Double(sharedTags.count) / max(dream1.tags.count, dream2.tags.count), 1.0)
                    if tagStrength >= minConnectionStrength {
                        connections.append((.sharedTags, tagStrength, Array(sharedTags)))
                    }
                }
                
                // 2. 共同情绪分析
                let sharedEmotions = Set(dream1.emotions.map { $0.rawValue })
                    .intersection(Set(dream2.emotions.map { $0.rawValue }))
                if !sharedEmotions.isEmpty {
                    let emotionStrength = min(Double(sharedEmotions.count) / max(dream1.emotions.count, dream2.emotions.count), 1.0)
                    if emotionStrength >= minConnectionStrength {
                        connections.append((.sharedEmotions, emotionStrength, Array(sharedEmotions)))
                    }
                }
                
                // 3. 时间接近性分析
                let timeInterval = abs(dream1.date.timeIntervalSince(dream2.date))
                let daysApart = timeInterval / (24 * 60 * 60)
                if daysApart <= timeProximityDays {
                    let timeStrength = 1.0 - (daysApart / timeProximityDays)
                    if timeStrength >= minConnectionStrength {
                        connections.append((.timeProximity, timeStrength, ["\(Int(daysApart))天间隔"]))
                    }
                }
                
                // 4. 清醒梦关联
                if dream1.isLucid && dream2.isLucid {
                    connections.append((.lucidConnection, 0.8, ["清醒梦"]))
                }
                
                // 5. 内容相似度分析 (简化版 - 基于关键词)
                let keywords1 = extractKeywords(from: dream1.content + " " + (dream1.aiAnalysis ?? ""))
                let keywords2 = extractKeywords(from: dream2.content + " " + (dream2.aiAnalysis ?? ""))
                let sharedKeywords = Set(keywords1).intersection(Set(keywords2))
                if sharedKeywords.count >= 3 {
                    let contentStrength = min(Double(sharedKeywords.count) / max(keywords1.count, keywords2.count), 1.0)
                    if contentStrength >= minConnectionStrength {
                        connections.append((.similarContent, contentStrength, Array(sharedKeywords.prefix(5))))
                    }
                }
                
                // 6. 主题相似度 (基于 AI 分析)
                if let analysis1 = dream1.aiAnalysis, let analysis2 = dream2.aiAnalysis {
                    let themes1 = extractThemes(from: analysis1)
                    let themes2 = extractThemes(from: analysis2)
                    let sharedThemes = Set(themes1).intersection(Set(themes2))
                    if !sharedThemes.isEmpty {
                        let themeStrength = min(Double(sharedThemes.count) / max(themes1.count, themes2.count), 1.0)
                        if themeStrength >= minConnectionStrength {
                            connections.append((.similarThemes, themeStrength, Array(sharedThemes)))
                        }
                    }
                }
                
                // 合并连接，取最强关联
                if !connections.isEmpty {
                    // 按类型分组，取每种类型的最高强度
                    let bestConnections = Dictionary(grouping: connections) { $0.type }
                        .compactMapValues { connections in
                            connections.max { $0.strength < $1.strength }
                        }
                    
                    // 限制每个节点对的连接数
                    let sortedConnections = bestConnections.values
                        .sorted { $0.strength > $1.strength }
                        .prefix(maxEdgesPerNode)
                    
                    for connection in sortedConnections {
                        edges.append(GraphEdge(
                            id: UUID(),
                            sourceId: dream1.id,
                            targetId: dream2.id,
                            relationshipType: connection.type,
                            strength: connection.strength,
                            sharedElements: connection.shared
                        ))
                    }
                }
            }
        }
        
        return edges
    }
    
    // MARK: - 聚类分析
    
    private func performClustering(nodes: [GraphNode], edges: [GraphEdge]) -> [DreamGraphData.GraphCluster] {
        // 基于标签的简单聚类
        var tagClusters: [String: Set<UUID>] = [:]
        
        for node in nodes {
            for tag in node.tags {
                if tagClusters[tag] == nil {
                    tagClusters[tag] = []
                }
                tagClusters[tag]?.insert(node.dreamId)
            }
        }
        
        // 选择最大的几个标签作为聚类
        let sortedTags = tagClusters.sorted { $0.value.count > $1.value.count }
            .prefix(5)
        
        var clusters: [DreamGraphData.GraphCluster] = []
        let clusterColors = ["4CAF50", "2196F3", "E91E63", "FF9800", "9C27B0"]
        let clusterIcons = ["tag", "heart", "star", "moon", "brain.head.profile"]
        
        for (index, tagEntry) in sortedTags.enumerated() {
            clusters.append(DreamGraphData.GraphCluster(
                id: tagEntry.key,
                name: tagEntry.key,
                nodeIds: Array(tagEntry.value),
                color: clusterColors[index % clusterColors.count],
                icon: clusterIcons[index % clusterIcons.count]
            ))
        }
        
        return clusters
    }
    
    // MARK: - 统计计算
    
    private func calculateStatistics(nodes: [GraphNode], edges: [GraphEdge], clusters: [DreamGraphData.GraphCluster]) -> DreamGraphData.GraphStatistics {
        let totalNodes = nodes.count
        let totalEdges = edges.count
        
        // 平均连接数
        let nodeConnections = Dictionary(grouping: edges) { edge in
            [edge.sourceId, edge.targetId]
        }.flatMap { $0 }
        let connectionCount = Dictionary(grouping: nodeConnections) { $0 }
            .mapValues { $0.count }
        let averageConnections = connectionCount.values.isEmpty ? 0 :
            Double(connectionCount.values.reduce(0, +)) / Double(connectionCount.count)
        
        // 图谱密度
        let maxPossibleEdges = Double(totalNodes * (totalNodes - 1)) / 2.0
        let density = maxPossibleEdges > 0 ? Double(totalEdges) / maxPossibleEdges : 0
        
        // 最大聚类大小
        let largestCluster = clusters.max { $0.nodeIds.count < $1.nodeIds.count }?.nodeIds.count ?? 0
        
        // 孤立节点数 (没有连接的节点)
        let connectedNodeIds = Set(edges.flatMap { [$0.sourceId, $0.targetId] })
        let isolatedNodes = nodes.filter { !connectedNodeIds.contains($0.dreamId) }.count
        
        return DreamGraphData.GraphStatistics(
            totalNodes: totalNodes,
            totalEdges: totalEdges,
            averageConnections: averageConnections,
            density: density,
            largestCluster: largestCluster,
            isolatedNodes: isolatedNodes
        )
    }
    
    // MARK: - 关键词提取
    
    private func extractKeywords(from text: String) -> [String] {
        // 简化版关键词提取
        let stopWords = Set(["的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "就", "着", "这", "那", "要", "也", "都", "都"])
        
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { $0.count > 1 }
            .filter { !stopWords.contains($0) }
        
        return words
    }
    
    // MARK: - 主题提取
    
    private func extractThemes(from analysis: String) -> [String] {
        // 从 AI 分析中提取主题关键词
        let themeKeywords = ["情绪", "压力", "焦虑", "自由", "恐惧", "希望", "变化", "成长", "挑战", "机会", "关系", "工作", "家庭", "健康", "梦想", "目标"]
        
        var themes: [String] = []
        for keyword in themeKeywords {
            if analysis.contains(keyword) {
                themes.append(keyword)
            }
        }
        
        return themes
    }
    
    // MARK: - 推荐关联
    
    /// 为指定梦境推荐最相关的其他梦境
    func recommendRelatedDreams(for dreamId: UUID, limit: Int = 5) -> [UUID] {
        guard let graphData = graphData else { return [] }
        
        let relatedEdges = graphData.edges.filter { edge in
            edge.sourceId == dreamId || edge.targetId == dreamId
        }
        .sorted { $0.strength > $1.strength }
        .prefix(limit)
        
        return relatedEdges.map { edge in
            edge.sourceId == dreamId ? edge.targetId : edge.sourceId
        }
    }
}
