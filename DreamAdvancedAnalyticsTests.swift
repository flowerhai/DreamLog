//
//  DreamAdvancedAnalyticsTests.swift
//  DreamLogTests
//
//  Phase 74: 梦境数据分析增强 📊🔍
//  高级分析单元测试
//
//  Created: 2026-03-20
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamAdvancedAnalyticsTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存模型容器
        let schema = Schema([
            DreamEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // 插入测试数据
        try await insertSampleDreams()
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 测试数据
    
    func insertSampleDreams() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // 创建 30 个测试梦境
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            let dream = DreamEntry(
                title: "测试梦境 \(i + 1)",
                content: "这是测试梦境的内容，包含一些符号和情绪。",
                date: date,
                emotion: DreamEmotion.allCases[i % DreamEmotion.allCases.count],
                clarity: Double(i % 10) / 10.0 + 0.1,
                isLucid: i % 5 == 0,
                sleepQuality: Double(i % 10) / 10.0 + 0.1,
                symbols: ["符号\(i % 5)", "符号\(i % 3)"]
            )
            
            modelContext.insert(dream)
        }
        
        try modelContext.save()
    }
    
    // MARK: - 交叉分析测试
    
    func testCrossAnalysisEmotionSymbol() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let result = try await service.performCrossAnalysis(
                dimension: .emotionSymbol,
                in: modelContext
            )
            
            XCTAssertEqual(result.dimension, .emotionSymbol)
            XCTAssertGreaterThan(result.totalDataPoints, 0)
            XCTAssertFalse(result.correlationMatrix.isEmpty)
            XCTAssertEqual(result.rowLabels.count, result.correlationMatrix.count)
            
            print("交叉分析测试通过：\(result.totalDataPoints) 个数据点")
        } catch {
            XCTFail("交叉分析失败：\(error)")
        }
    }
    
    func testCrossAnalysisDayOfWeekEmotion() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let result = try await service.performCrossAnalysis(
                dimension: .dayOfWeekEmotion,
                in: modelContext
            )
            
            XCTAssertEqual(result.dimension, .dayOfWeekEmotion)
            XCTAssertEqual(result.columnLabels.count, 7) // 一周 7 天
            
            print("星期情绪分析测试通过")
        } catch {
            XCTFail("星期情绪分析失败：\(error)")
        }
    }
    
    // MARK: - 时间序列预测测试
    
    func testTimeSeriesForecastFrequency() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let forecast = try await service.generateTimeSeriesForecast(
                type: .dreamFrequency,
                days: 7,
                in: modelContext
            )
            
            XCTAssertEqual(forecast.forecastType, .dreamFrequency)
            XCTAssertGreaterThan(forecast.historicalData.count, 0)
            XCTAssertEqual(forecast.forecastedData.count, 7)
            XCTAssertEqual(forecast.lowerBound.count, 7)
            XCTAssertEqual(forecast.upperBound.count, 7)
            
            print("频率预测测试通过：趋势 \(forecast.trendDirection.displayName)")
        } catch {
            XCTFail("频率预测失败：\(error)")
        }
    }
    
    func testTimeSeriesForecastEmotion() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let forecast = try await service.generateTimeSeriesForecast(
                type: .emotionTrend,
                days: 7,
                in: modelContext
            )
            
            XCTAssertEqual(forecast.forecastType, .emotionTrend)
            XCTAssertGreaterThan(forecast.historicalData.count, 0)
            
            print("情绪趋势预测测试通过")
        } catch {
            XCTFail("情绪趋势预测失败：\(error)")
        }
    }
    
    // MARK: - 异常检测测试
    
    func testAnomalyDetection() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let anomalies = try await service.detectAnomalies(in: modelContext)
            
            // 至少应该有一些异常（测试数据包含极端值）
            XCTAssertGreaterThanOrEqual(anomalies.count, 0)
            
            for anomaly in anomalies {
                XCTAssertGreaterThan(anomaly.anomalyScore, 0)
                XCTAssertLessThanOrEqual(anomaly.anomalyScore, 1)
                XCTAssertFalse(anomaly.description.isEmpty)
            }
            
            print("异常检测测试通过：发现 \(anomalies.count) 个异常")
        } catch {
            XCTFail("异常检测失败：\(error)")
        }
    }
    
    // MARK: - 聚类分析测试
    
    func testClusteringKMeans() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let result = try await service.performClustering(
                algorithm: .kmeans,
                clusterCount: 3,
                in: modelContext
            )
            
            XCTAssertEqual(result.algorithm, .kmeans)
            XCTAssertGreaterThan(result.clusterCount, 0)
            XCTAssertLessThanOrEqual(result.qualityScore, 1.0)
            
            for cluster in result.clusters {
                XCTAssertGreaterThan(cluster.size, 0)
                XCTAssertFalse(cluster.name.isEmpty)
            }
            
            print("K-Means 聚类测试通过：质量分数 \(result.qualityScore)")
        } catch {
            XCTFail("K-Means 聚类失败：\(error)")
        }
    }
    
    func testClusteringHierarchical() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let result = try await service.performClustering(
                algorithm: .hierarchical,
                clusterCount: 3,
                in: modelContext
            )
            
            XCTAssertEqual(result.algorithm, .hierarchical)
            XCTAssertGreaterThan(result.clusterCount, 0)
            
            print("层次聚类测试通过")
        } catch {
            XCTFail("层次聚类失败：\(error)")
        }
    }
    
    // MARK: - 分析概览测试
    
    func testAnalyticsOverview() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            let overview = try await service.getAnalyticsOverview(in: modelContext)
            
            XCTAssertEqual(overview.totalDreams, 30)
            XCTAssertGreaterThan(overview.averageClarity, 0)
            XCTAssertLessThanOrEqual(overview.averageClarity, 1)
            XCTAssertGreaterThanOrEqual(overview.lucidDreamCount, 0)
            XCTAssertFalse(overview.dominantEmotion.isEmpty)
            
            print("分析概览测试通过：\(overview.totalDreams) 个梦境，平均清晰度 \(overview.averageClarity)")
        } catch {
            XCTFail("分析概览失败：\(error)")
        }
    }
    
    // MARK: - 报告生成测试
    
    func testReportGenerationWeekly() async throws {
        let generator = DreamReportGenerator.shared
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        do {
            let report = try await generator.generateReport(
                type: .weekly,
                startDate: weekAgo,
                endDate: now,
                in: modelContext
            )
            
            XCTAssertEqual(report.type, .weekly)
            XCTAssertFalse(report.title.isEmpty)
            XCTAssertEqual(report.summary.totalDreams, 7) // 最近 7 天
            XCTAssertGreaterThan(report.insights.count, 0)
            XCTAssertGreaterThan(report.recommendations.count, 0)
            
            print("周报生成测试通过：\(report.summary.totalDreams) 个梦境")
        } catch {
            XCTFail("周报生成失败：\(error)")
        }
    }
    
    func testReportGenerationMonthly() async throws {
        let generator = DreamReportGenerator.shared
        let calendar = Calendar.current
        let now = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        do {
            let report = try await generator.generateReport(
                type: .monthly,
                startDate: monthAgo,
                endDate: now,
                in: modelContext
            )
            
            XCTAssertEqual(report.type, .monthly)
            XCTAssertFalse(report.title.isEmpty)
            
            print("月报生成测试通过")
        } catch {
            XCTFail("月报生成失败：\(error)")
        }
    }
    
    // MARK: - 缓存测试
    
    func testCacheFunctionality() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        // 第一次调用
        let result1 = try await service.performCrossAnalysis(
            dimension: .emotionSymbol,
            in: modelContext
        )
        
        // 第二次调用（应该使用缓存）
        let result2 = try await service.performCrossAnalysis(
            dimension: .emotionSymbol,
            in: modelContext
        )
        
        // 结果应该相同
        XCTAssertEqual(result1.totalDataPoints, result2.totalDataPoints)
        
        // 清除缓存
        await service.clearCache()
        
        print("缓存功能测试通过")
    }
    
    // MARK: - 错误处理测试
    
    func testInsufficientDataError() async {
        // 创建空容器
        let schema = Schema([DreamEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let emptyContainer = try! ModelContainer(for: schema, configurations: [configuration])
        let emptyContext = ModelContext(emptyContainer)
        
        let service = DreamAdvancedAnalyticsService.shared
        
        do {
            _ = try await service.generateTimeSeriesForecast(
                type: .dreamFrequency,
                days: 7,
                in: emptyContext
            )
            XCTFail("应该抛出数据不足错误")
        } catch AnalyticsError.insufficientData {
            print("数据不足错误测试通过")
        } catch {
            XCTFail("错误类型不正确：\(error)")
        }
    }
    
    // MARK: - 性能测试
    
    func testPerformanceCrossAnalysis() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        measure {
            let expectation = XCTestExpectation(description: "Cross Analysis")
            
            Task {
                do {
                    _ = try await service.performCrossAnalysis(
                        dimension: .emotionSymbol,
                        in: modelContext
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("性能测试失败：\(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testPerformanceClustering() async throws {
        let service = DreamAdvancedAnalyticsService.shared
        
        measure {
            let expectation = XCTestExpectation(description: "Clustering")
            
            Task {
                do {
                    _ = try await service.performClustering(
                        algorithm: .kmeans,
                        in: modelContext
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("性能测试失败：\(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}

// MARK: - 模型测试扩展

@available(iOS 17.0, *)
extension DreamAdvancedAnalyticsTests {
    // 测试数据模型
    func testCodableModels() throws {
        // 测试 CrossAnalysisResult
        let correlation = CrossAnalysisResult.SignificantCorrelation(
            rowLabel: "快乐",
            columnLabel: "太阳",
            strength: 0.85,
            count: 10
        )
        
        let result = CrossAnalysisResult(
            dimension: .emotionSymbol,
            totalDataPoints: 100,
            correlationMatrix: [[0.5, 0.8], [0.3, 0.9]],
            rowLabels: ["快乐", "悲伤"],
            columnLabels: ["太阳", "月亮"],
            significantCorrelations: [correlation],
            analyzedAt: Date()
        )
        
        // 测试编码
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(result)
        
        // 测试解码
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CrossAnalysisResult.self, from: data)
        
        XCTAssertEqual(result.dimension, decoded.dimension)
        XCTAssertEqual(result.totalDataPoints, decoded.totalDataPoints)
        
        print("模型编码测试通过")
    }
    
    // 测试枚举
    func testEnumCases() {
        // 测试所有枚举都有正确的 case
        XCTAssertEqual(CrossAnalysisDimension.allCases.count, 6)
        XCTAssertEqual(TimeSeriesForecast.ForecastType.allCases.count, 5)
        XCTAssertEqual(AnomalyDetectionResult.AnomalyType.allCases.count, 6)
        XCTAssertEqual(ReportType.allCases.count, 4)
        XCTAssertEqual(DreamEmotion.allCases.count, 8)
        
        print("枚举测试通过")
    }
}
