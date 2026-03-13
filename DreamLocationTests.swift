//
//  DreamLocationTests.swift
//  DreamLog - 梦境位置功能单元测试
//
//  Phase 31: 梦境地图功能
//  创建时间：2026-03-13
//

import XCTest
import CoreLocation
@testable import DreamLog

@MainActor
final class DreamLocationTests: XCTestCase {
    
    var locationService: DreamLocationService!
    
    override func setUp() async throws {
        try await super.setUp()
        locationService = DreamLocationService.shared
    }
    
    override func tearDown() async throws {
        locationService = nil
        try await super.tearDown()
    }
    
    // MARK: - Data Model Tests
    
    /// 测试 DreamLocation 模型初始化
    func testDreamLocationInitialization() {
        let dreamId = UUID()
        let location = DreamLocation(
            dreamId: dreamId,
            latitude: 39.9042,
            longitude: 116.4074,
            altitude: 50.0,
            accuracy: 10.0,
            address: "长安街",
            city: "北京市",
            country: "中国",
            timestamp: Date(),
            isHome: true,
            locationName: "家"
        )
        
        XCTAssertEqual(location.dreamId, dreamId)
        XCTAssertEqual(location.latitude, 39.9042)
        XCTAssertEqual(location.longitude, 116.4074)
        XCTAssertEqual(location.altitude, 50.0)
        XCTAssertEqual(location.accuracy, 10.0)
        XCTAssertEqual(location.address, "长安街")
        XCTAssertEqual(location.city, "北京市")
        XCTAssertEqual(location.country, "中国")
        XCTAssertTrue(location.isHome)
        XCTAssertEqual(location.locationName, "家")
    }
    
    /// 测试 DreamLocation 默认值
    func testDreamLocationDefaultValues() {
        let dreamId = UUID()
        let location = DreamLocation(
            dreamId: dreamId,
            latitude: 0,
            longitude: 0
        )
        
        XCTAssertNil(location.altitude)
        XCTAssertEqual(location.accuracy, 10.0)
        XCTAssertNil(location.address)
        XCTAssertNil(location.city)
        XCTAssertNil(location.country)
        XCTAssertFalse(location.isHome)
        XCTAssertNil(location.locationName)
    }
    
    // MARK: - Location Cluster Tests
    
    /// 测试位置聚类
    func testLocationCluster() {
        let dreamId1 = UUID()
        let dreamId2 = UUID()
        
        let location1 = DreamLocation(
            dreamId: dreamId1,
            latitude: 39.9042,
            longitude: 116.4074,
            city: "北京市"
        )
        
        let location2 = DreamLocation(
            dreamId: dreamId2,
            latitude: 39.9050,
            longitude: 116.4080,
            city: "北京市"
        )
        
        let cluster = LocationCluster(dreams: [location1, location2])
        
        XCTAssertEqual(cluster.dreamCount, 2)
        XCTAssertEqual(cluster.dreamIds.count, 2)
        XCTAssertTrue(cluster.cities.contains("北京市"))
        
        // 测试中心坐标
        XCTAssertEqual(cluster.centerLatitude, (39.9042 + 39.9050) / 2, accuracy: 0.0001)
        XCTAssertEqual(cluster.centerLongitude, (116.4074 + 116.4080) / 2, accuracy: 0.0001)
    }
    
    /// 测试空聚类
    func testEmptyLocationCluster() {
        let cluster = LocationCluster(dreams: [])
        
        XCTAssertEqual(cluster.dreamCount, 0)
        XCTAssertEqual(cluster.dreamIds.count, 0)
        XCTAssertTrue(cluster.cities.isEmpty)
    }
    
    /// 测试聚类 coordinate 属性
    func testLocationClusterCoordinate() {
        let location = DreamLocation(
            dreamId: UUID(),
            latitude: 39.9042,
            longitude: 116.4074
        )
        
        let cluster = LocationCluster(dreams: [location])
        let coordinate = cluster.coordinate
        
        XCTAssertEqual(coordinate.latitude, 39.9042, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, 116.4074, accuracy: 0.0001)
    }
    
    // MARK: - Location Statistics Tests
    
    /// 测试位置统计
    func testLocationStatistics() {
        let locations = [
            DreamLocation(dreamId: UUID(), latitude: 39.9042, longitude: 116.4074, city: "北京市", isHome: true),
            DreamLocation(dreamId: UUID(), latitude: 31.2304, longitude: 121.4737, city: "上海市", isHome: false),
            DreamLocation(dreamId: UUID(), latitude: 39.9050, longitude: 116.4080, city: "北京市", isHome: false),
        ]
        
        let stats = LocationStatistics(locations: locations)
        
        XCTAssertEqual(stats.totalLocations, 3)
        XCTAssertEqual(stats.uniqueCities, 2)
        XCTAssertEqual(stats.homeLocationCount, 1)
        XCTAssertEqual(stats.travelDreamCount, 2)
        XCTAssertEqual(stats.countries.count, 0)  // 测试数据没有设置国家
        
        // 测试热门城市
        XCTAssertEqual(stats.topCities.count, 2)
        XCTAssertEqual(stats.topCities[0].city, "北京市")
        XCTAssertEqual(stats.topCities[0].count, 2)
        XCTAssertEqual(stats.topCities[1].city, "上海市")
        XCTAssertEqual(stats.topCities[1].count, 1)
    }
    
    /// 测试空数据统计
    func testEmptyLocationStatistics() {
        let stats = LocationStatistics(locations: [])
        
        XCTAssertEqual(stats.totalLocations, 0)
        XCTAssertEqual(stats.uniqueCities, 0)
        XCTAssertEqual(stats.homeLocationCount, 0)
        XCTAssertEqual(stats.travelDreamCount, 0)
        XCTAssertTrue(stats.topCities.isEmpty)
    }
    
    // MARK: - Map Display Mode Tests
    
    /// 测试地图显示模式枚举
    func testMapDisplayModeEnum() {
        XCTAssertEqual(MapDisplayMode.standard.id, "标准")
        XCTAssertEqual(MapDisplayMode.satellite.id, "卫星")
        XCTAssertEqual(MapDisplayMode.hybrid.id, "混合")
        
        XCTAssertEqual(MapDisplayMode.standard.icon, "map")
        XCTAssertEqual(MapDisplayMode.satellite.icon, "globe")
        XCTAssertEqual(MapDisplayMode.hybrid.icon, "map.fill")
    }
    
    /// 测试地图显示模式 CaseIterable
    func testMapDisplayModeAllCases() {
        let allCases = MapDisplayMode.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.standard))
        XCTAssertTrue(allCases.contains(.satellite))
        XCTAssertTrue(allCases.contains(.hybrid))
    }
    
    // MARK: - Map Filter Options Tests
    
    /// 测试地图筛选选项默认值
    func testMapFilterOptionsDefault() {
        let options = MapFilterOptions()
        
        XCTAssertTrue(options.showClusters)
        XCTAssertEqual(options.clusterRadius, 50000)
        XCTAssertEqual(options.minZoomLevel, 5)
        XCTAssertTrue(options.showHomeMarker)
        XCTAssertFalse(options.showHeatmap)
        XCTAssertEqual(options.dateRange, .all)
    }
    
    /// 测试日期范围枚举
    func testMapFilterDateRangeEnum() {
        XCTAssertEqual(MapFilterOptions.DateRange.all.id, "全部")
        XCTAssertEqual(MapFilterOptions.DateRange.week.id, "最近 7 天")
        XCTAssertEqual(MapFilterOptions.DateRange.month.id, "最近 30 天")
        XCTAssertEqual(MapFilterOptions.DateRange.year.id, "今年")
        XCTAssertEqual(MapFilterOptions.DateRange.custom.id, "自定义")
    }
    
    /// 测试日期范围 CaseIterable
    func testMapFilterDateRangeAllCases() {
        let allCases = MapFilterOptions.DateRange.allCases
        XCTAssertEqual(allCases.count, 5)
    }
    
    // MARK: - Location Permission Tests
    
    /// 测试位置权限状态
    func testLocationPermissionStatus() {
        XCTAssertEqual(LocationPermissionStatus.notDetermined.description, "未确定")
        XCTAssertEqual(LocationPermissionStatus.restricted.description, "受限")
        XCTAssertEqual(LocationPermissionStatus.denied.description, "已拒绝")
        XCTAssertEqual(LocationPermissionStatus.authorizedAlways.description, "始终允许")
        XCTAssertEqual(LocationPermissionStatus.authorizedWhenInUse.description, "使用期间允许")
    }
    
    /// 测试位置权限 canRecordLocation
    func testLocationPermissionCanRecord() {
        XCTAssertFalse(LocationPermissionStatus.notDetermined.canRecordLocation)
        XCTAssertFalse(LocationPermissionStatus.restricted.canRecordLocation)
        XCTAssertFalse(LocationPermissionStatus.denied.canRecordLocation)
        XCTAssertTrue(LocationPermissionStatus.authorizedAlways.canRecordLocation)
        XCTAssertTrue(LocationPermissionStatus.authorizedWhenInUse.canRecordLocation)
    }
    
    // MARK: - Location Service Config Tests
    
    /// 测试位置服务配置默认值
    func testLocationServiceConfigDefault() {
        let config = LocationServiceConfig.default
        
        XCTAssertTrue(config.enableLocationTracking)
        XCTAssertFalse(config.autoRecordLocation)
        XCTAssertTrue(config.showInMap)
        XCTAssertFalse(config.privacyMode)
        XCTAssertNil(config.defaultLocationName)
    }
    
    /// 测试位置服务配置 Codable
    func testLocationServiceConfigCodable() throws {
        var config = LocationServiceConfig(
            enableLocationTracking: true,
            autoRecordLocation: true,
            showInMap: false,
            privacyMode: true,
            defaultLocationName: "测试位置"
        )
        
        // 编码
        let encoded = try JSONEncoder().encode(config)
        
        // 解码
        let decoded = try JSONDecoder().decode(LocationServiceConfig.self, from: encoded)
        
        XCTAssertEqual(decoded.enableLocationTracking, config.enableLocationTracking)
        XCTAssertEqual(decoded.autoRecordLocation, config.autoRecordLocation)
        XCTAssertEqual(decoded.showInMap, config.showInMap)
        XCTAssertEqual(decoded.privacyMode, config.privacyMode)
        XCTAssertEqual(decoded.defaultLocationName, config.defaultLocationName)
    }
    
    // MARK: - Location Error Tests
    
    /// 测试位置错误类型
    func testLocationError() {
        XCTAssertEqual(LocationError.permissionDenied.errorDescription, "位置权限被拒绝")
        XCTAssertEqual(LocationError.locationUnavailable.errorDescription, "无法获取当前位置")
        XCTAssertEqual(LocationError.geocodingFailed.errorDescription, "地址解析失败")
    }
    
    // MARK: - Performance Tests
    
    /// 测试位置聚类性能
    func testLocationClusterPerformance() {
        var locations: [DreamLocation] = []
        
        // 创建 100 个测试位置
        for i in 0..<100 {
            let location = DreamLocation(
                dreamId: UUID(),
                latitude: 39.9042 + Double(i) * 0.001,
                longitude: 116.4074 + Double(i) * 0.001,
                city: "北京市"
            )
            locations.append(location)
        }
        
        measure {
            let cluster = LocationCluster(dreams: locations)
            XCTAssertNotNil(cluster)
        }
    }
    
    /// 测试位置统计性能
    func testLocationStatisticsPerformance() {
        var locations: [DreamLocation] = []
        
        // 创建 1000 个测试位置
        for i in 0..<1000 {
            let location = DreamLocation(
                dreamId: UUID(),
                latitude: Double.random(in: 0...90),
                longitude: Double.random(in: 0...180),
                city: "城市\(i % 10)"
            )
            locations.append(location)
        }
        
        measure {
            let stats = LocationStatistics(locations: locations)
            XCTAssertEqual(stats.totalLocations, 1000)
        }
    }
}

// MARK: - CLLocation Extension for Testing

extension DreamLocation {
    convenience init(
        dreamId: UUID,
        latitude: Double,
        longitude: Double,
        city: String? = nil,
        isHome: Bool = false
    ) {
        self.init(
            dreamId: dreamId,
            latitude: latitude,
            longitude: longitude,
            city: city,
            country: nil,
            isHome: isHome
        )
    }
}
