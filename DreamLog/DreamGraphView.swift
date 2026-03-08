//
//  DreamGraphView.swift
//  DreamLog
//
//  梦境关联图谱可视化视图
//  Phase 5 - 智能增强功能
//

import SwiftUI
import UIKit

// MARK: - 梦境关联图谱主视图

struct DreamGraphView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @ObservedObject private var graphService = DreamGraphService.shared
    @State private var selectedNode: GraphNode?
    @State private var selectedEdge: GraphEdge?
    @State private var showingFilters = false
    @State private var selectedCluster: String?
    @State private var zoomLevel: CGFloat = 1.0
    @State private var showingStats = false
    
    var body: some View {
        ZStack {
            if graphService.isLoading {
                LoadingGraphView()
            } else if let graphData = graphService.graphData {
                GraphContentView(graphData: graphData)
            } else if let error = graphService.errorMessage {
                ErrorView(message: error, onRetry: {
                    Task {
                        await graphService.generateGraph(from: dreamStore.dreams)
                    }
                })
            } else {
                EmptyGraphView(onGenerate: {
                    Task {
                        await graphService.generateGraph(from: dreamStore.dreams)
                    }
                })
            }
        }
        .navigationTitle("梦境关联图谱")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingStats = true }) {
                    Label("统计", systemImage: "chart.bar")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFilters = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingStats) {
            GraphStatisticsView(statistics: graphService.graphData?.statistics)
        }
        .sheet(isPresented: $showingFilters) {
            GraphFiltersView(
                selectedCluster: $selectedCluster,
                clusters: graphService.graphData?.clusters ?? [],
                zoomLevel: $zoomLevel
            )
        }
        .onAppear {
            if graphService.graphData == nil && !graphService.isLoading {
                Task {
                    await graphService.generateGraph(from: dreamStore.dreams)
                }
            }
        }
    }
}

// MARK: - 图谱内容视图

struct GraphContentView: View {
    let graphData: DreamGraphData
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景网格
                GridBackgroundView()
                
                // 连接线
                ConnectionsView(
                    edges: graphData.edges,
                    nodePositions: nodePositions
                )
                
                // 节点
                ForEach(graphData.nodes) { node in
                    if let position = nodePositions[node.dreamId] {
                        NodeView(
                            node: node,
                            position: position,
                            isSelected: false,
                            onTap: { /* 处理点击 */ }
                        )
                    }
                }
            }
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { value in
                        lastOffset = offset
                    }
            )
            .onAppear {
                // 初始化节点位置 (力导向布局简化版)
                nodePositions = calculateNodePositions(
                    nodes: graphData.nodes,
                    edges: graphData.edges,
                    in: geometry.size
                )
            }
        }
    }
    
    // MARK: - 节点位置计算 (简化力导向布局)
    
    private func calculateNodePositions(nodes: [GraphNode], edges: [GraphEdge], in size: CGSize) -> [UUID: CGPoint] {
        var positions: [UUID: CGPoint] = [:]
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius = min(size.width, size.height) / 2 - 50
        
        // 将节点放置在圆周上，相关节点靠近
        let nodeCount = nodes.count
        
        for (index, node) in nodes.enumerated() {
            let angle = (Double(index) / Double(nodeCount)) * 2 * .pi
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            positions[node.dreamId] = CGPoint(x: x, y: y)
        }
        
        // 简单的力导向迭代优化
        for _ in 0..<30 {
            applyForceDirectedLayout(
                positions: &positions,
                nodes: nodes,
                edges: edges,
                in: size
            )
        }
        
        return positions
    }
    
    private func applyForceDirectedLayout(
        positions: inout [UUID: CGPoint],
        nodes: [GraphNode],
        edges: [GraphEdge],
        in size: CGSize
    ) {
        let repulsionForce: CGFloat = 5000
        let springLength: CGFloat = 150
        let springStrength: CGFloat = 0.01
        let damping: CGFloat = 0.85
        
        var forces: [UUID: CGPoint] = Dictionary(uniqueKeysWithValues: nodes.map { ($0.dreamId, .zero) })
        
        // 斥力 (所有节点互相排斥)
        for node1 in nodes {
            for node2 in nodes where node1.dreamId != node2.dreamId {
                guard let pos1 = positions[node1.dreamId],
                      let pos2 = positions[node2.dreamId] else { continue }
                
                let dx = pos1.x - pos2.x
                let dy = pos1.y - pos2.y
                let distance = max(sqrt(dx * dx + dy * dy), 1)
                
                let force = repulsionForce / (distance * distance)
                let fx = (dx / distance) * force
                let fy = (dy / distance) * force
                
                forces[node1.dreamId]?.x += fx
                forces[node1.dreamId]?.y += fy
            }
        }
        
        // 引力 (有连接的节点互相吸引)
        for edge in edges {
            guard let pos1 = positions[edge.sourceId],
                  let pos2 = positions[edge.targetId] else { continue }
            
            let dx = pos2.x - pos1.x
            let dy = pos2.y - pos1.y
            let distance = sqrt(dx * dx + dy * dy)
            
            let displacement = distance - springLength
            let fx = springStrength * displacement * dx
            let fy = springStrength * displacement * dy
            
            forces[edge.sourceId]?.x += fx
            forces[edge.sourceId]?.y += fy
            forces[edge.targetId]?.x -= fx
            forces[edge.targetId]?.y -= fy
        }
        
        // 应用力并更新位置
        for node in nodes {
            guard let force = forces[node.dreamId],
                  var pos = positions[node.dreamId] else { continue }
            
            pos.x += force.x * damping
            pos.y += force.y * damping
            
            // 边界约束
            pos.x = max(50, min(size.width - 50, pos.x))
            pos.y = max(50, min(size.height - 50, pos.y))
            
            positions[node.dreamId] = pos
        }
    }
}

// MARK: - 节点视图

struct NodeView: View {
    let node: GraphNode
    let position: CGPoint
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Circle()
            .fill(Color(hex: node.color))
            .frame(width: node.size, height: node.size)
            .position(x: position.x, y: position.y)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 1)
                    .frame(width: node.size, height: node.size)
                    .position(x: position.x, y: position.y)
            )
            .shadow(color: Color.black.opacity(0.3), radius: isSelected ? 4 : 2)
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - 连接线视图

struct ConnectionsView: View {
    let edges: [GraphEdge]
    let nodePositions: [UUID: CGPoint]
    
    var body: some View {
        Canvas { context, size in
            for edge in edges {
                guard let startPos = nodePositions[edge.sourceId],
                      let endPos = nodePositions[edge.targetId] else { continue }
                
                let path = Path { p in
                    p.move(to: startPos)
                    p.addLine(to: endPos)
                }
                
                let opacity = edge.strength * 0.8
                context.stroke(
                    path,
                    with: .color(Color(hex: edge.relationshipType.color).opacity(opacity)),
                    lineWidth: CGFloat(edge.strength) * 3
                )
            }
        }
    }
}

// MARK: - 网格背景视图

struct GridBackgroundView: View {
    var body: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 50
            let lineColor = Color.gray.opacity(0.1)
            
            // 垂直线
            for x in stride(from: 0, to: size.width, by: gridSize) {
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
            
            // 水平线
            for y in stride(from: 0, to: size.height, by: gridSize) {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - 加载视图

struct LoadingGraphView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在生成梦境关联图谱...")
                .font(.headline)
            
            Text("分析梦境之间的关联")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 空状态视图

struct EmptyGraphView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无梦境关联图谱")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("需要至少 2 条梦境才能生成关联图谱")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onGenerate) {
                Label("生成图谱", systemImage: "sparkles")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - 错误视图

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("生成图谱失败")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Label("重试", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - 统计信息视图

struct GraphStatisticsView: View {
    let statistics: DreamGraphData.GraphStatistics?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("图谱概览")) {
                    StatRow(title: "梦境节点", value: "\(statistics?.totalNodes ?? 0)", icon: "circle.fill")
                    StatRow(title: "关联边", value: "\(statistics?.totalEdges ?? 0)", icon: "line.3.horizontal")
                    StatRow(title: "平均连接", value: String(format: "%.1f", statistics?.averageConnections ?? 0), icon: "arrow.triangle.2.circlepath")
                }
                
                Section(header: Text("图谱特性")) {
                    StatRow(title: "图谱密度", value: String(format: "%.2f", (statistics?.density ?? 0) * 100) + "%", icon: "chart.bar.fill")
                    StatRow(title: "最大聚类", value: "\(statistics?.largestCluster ?? 0) 个梦境", icon: "group")
                    StatRow(title: "孤立节点", value: "\(statistics?.isolatedNodes ?? 0)", icon: "circle")
                }
                
                Section(header: Text("说明")) {
                    Text("图谱密度越高，表示梦境之间的关联越紧密。")
                    Text("孤立节点表示与其他梦境没有明显关联的梦境。")
                }
            }
            .navigationTitle("图谱统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 过滤器视图

struct GraphFiltersView: View {
    @Binding var selectedCluster: String?
    let clusters: [DreamGraphData.GraphCluster]
    @Binding var zoomLevel: CGFloat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("聚类筛选")) {
                    Button(action: { selectedCluster = nil }) {
                        HStack {
                            Text("全部显示")
                            Spacer()
                            if selectedCluster == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    ForEach(clusters) { cluster in
                        Button(action: { selectedCluster = cluster.id }) {
                            HStack {
                                Image(systemName: cluster.icon)
                                    .foregroundColor(Color(hex: cluster.color))
                                Text(cluster.name)
                                Spacer()
                                Text("\(cluster.nodeIds.count)个梦境")
                                    .foregroundColor(.secondary)
                                if selectedCluster == cluster.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("缩放级别")) {
                    Slider(value: $zoomLevel, in: 0.5...2.0, step: 0.1) {
                        Text("缩放")
                    } minimumValueLabel: {
                        Text("50%")
                    } maximumValueLabel: {
                        Text("200%")
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 颜色扩展
// Note: Color(hex:) is defined in Theme.swift to avoid redeclaration

// MARK: - 预览

#Preview {
    DreamGraphView()
}
