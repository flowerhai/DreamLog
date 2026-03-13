//
//  DreamLocationModels.swift
//  DreamLog - 梦境位置数据模型
//
//  Phase 31: 梦境地图功能
//  创建时间：2026-03-13
//

import Foundation
import CoreLocation
import SwiftData

// MARK: - 梦境位置数据

/// 梦境位置信息
@Model
final class DreamLocation {
    var id: UUID
    var dreamId: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var accuracy: Double
    var address: String?
    var city: String?
    var country: String?
    var timestamp: Date
    var isHome: Bool  // 是否标记为"家"的位置
    var locationName: String?  // 自定义位置名称
    
    init(
        dreamId: UUID,
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        accuracy: Double = 10.0,
        address: String? = nil,
        city: String? = nil,
        country: String? = nil,
        timestamp: Date = Date(),
        isHome: Bool = false,
        locationName: String? = nil
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
        self.address = address
        self.city = city
        self.country = country
        self.timestamp = timestamp
        self.isHome = isHome
        self.locationName = locationName
    }
}

// MARK: - 位置聚类

/// 位置聚类（用于地图上的聚合显示）
struct LocationCluster: Identifiable, Hashable {
    let id = UUID()
    let centerLatitude: Double
    let centerLongitude: Double
    let dreamCount: Int
    let dreamIds: [UUID]
    let cities: Set<String>
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }
    
    init(dreams: [DreamLocation]) {
        guard !dreams.isEmpty else {
            self.centerLatitude = 0
            self.centerLongitude = 0
            self.dreamCount = 0
            self.dreamIds = []
            self.cities = []
            return
        }
        
        self.centerLatitude = dreams.map { $0.latitude }.reduce(0, +) / Double(dreams.count)
        self.centerLongitude = dreams.map { $0.longitude }.reduce(0, +) / Double(dreams.count)
        self.dreamCount = dreams.count
        self.dreamIds = dreams.map { $0.dreamId }
        self.cities = Set(dreams.compactMap { $0.city })
    }
}

// MARK: - 位置统计

/// 位置统计数据
struct LocationStatistics {
    var totalLocations: Int
    var uniqueCities: Int
    var topCities: [(city: String, count: Int)]
    var homeLocationCount: Int
    var travelDreamCount: Int  // 非家位置的梦境数
    var countries: Set<String>
    var averageAccuracy: Double
    
    init(locations: [DreamLocation]) {
        self.totalLocations = locations.count
        self.uniqueCities = Set(locations.compactMap { $0.city }).count
        self.countries = Set(locations.compactMap { $0.country })
        
        // 计算热门城市
        let cityCounts = Dictionary(grouping: locations.compactMap { $0.city }) { $0 }
            .map { (city: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        self.topCities = Array(cityCounts.prefix(10))
        
        // 统计家和旅行
        self.homeLocationCount = locations.filter { $0.isHome }.count
        self.travelDreamCount = locations.filter { !$0.isHome }.count
        
        // 平均精度
        self.averageAccuracy = locations.map { $0.accuracy }.reduce(0, +) / Double(locations.count)
    }
}

// MARK: - 地图配置

/// 地图显示配置
enum MapDisplayMode: String, CaseIterable, Identifiable {
    case standard = "标准"
    case satellite = "卫星"
    case hybrid = "混合"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe"
        case .hybrid: return "map.fill"
        }
    }
}

/// 地图筛选选项
struct MapFilterOptions {
    var showClusters: Bool = true
    var clusterRadius: Double = 50000  // 米
    var minZoomLevel: Int = 5
    var showHomeMarker: Bool = true
    var showHeatmap: Bool = false
    var dateRange: DateRange = .all
    
    enum DateRange: String, CaseIterable, Identifiable {
        case all = "全部"
        case week = "最近 7 天"
        case month = "最近 30 天"
        case year = "今年"
        case custom = "自定义"
        
        var id: String { rawValue }
    }
}

// MARK: - 位置权限

/// 位置权限状态
enum LocationPermissionStatus {
    case notDetermined
    case restricted
    case denied
    case authorizedAlways
    case authorizedWhenInUse
    
    var canRecordLocation: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .notDetermined: return "未确定"
        case .restricted: return "受限"
        case .denied: return "已拒绝"
        case .authorizedAlways: return "始终允许"
        case .authorizedWhenInUse: return "使用期间允许"
        }
    }
}

// MARK: - 位置服务配置

/// 位置服务配置
struct LocationServiceConfig: Codable {
    var enableLocationTracking: Bool  // 是否启用位置追踪
    var autoRecordLocation: Bool  // 自动记录位置
    var showInMap: Bool  // 在地图上显示
    var privacyMode: Bool  // 隐私模式（模糊精确位置）
    var defaultLocationName: String?  // 默认位置名称
    
    static var `default`: LocationServiceConfig {
        LocationServiceConfig(
            enableLocationTracking: true,
            autoRecordLocation: false,
            showInMap: true,
            privacyMode: false,
            defaultLocationName: nil
        )
    }
}
