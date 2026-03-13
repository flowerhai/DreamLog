//
//  DreamLocationService.swift
//  DreamLog - 梦境位置服务
//
//  Phase 31: 梦境地图功能
//  创建时间：2026-03-13
//

import Foundation
import CoreLocation
import SwiftData

/// 梦境位置服务 - 管理梦境的地理位置信息
@MainActor
class DreamLocationService: NSObject, ObservableObject {
    
    // MARK: - 单例
    
    static let shared = DreamLocationService()
    
    // MARK: - Published Properties
    
    @Published var currentLocation: CLLocation?
    @Published var permissionStatus: LocationPermissionStatus = .notDetermined
    @Published var isRecording: Bool = false
    @Published var locationError: String?
    @Published var config: LocationServiceConfig = .default
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupLocationManager()
        loadConfig()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Location Manager Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100  // 100 米更新一次
    }
    
    // MARK: - Permission Management
    
    /// 请求位置权限
    func requestPermission() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            permissionStatus = .restricted
            locationError = "位置服务受限制"
        case .denied:
            permissionStatus = .denied
            locationError = "位置服务已拒绝，请在设置中启用"
        case .authorizedAlways, .authorizedWhenInUse:
            permissionStatus = .authorizedWhenInUse
        @unknown default:
            permissionStatus = .notDetermined
        }
    }
    
    /// 检查权限状态
    func checkPermissionStatus() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            permissionStatus = .notDetermined
        case .restricted:
            permissionStatus = .restricted
        case .denied:
            permissionStatus = .denied
        case .authorizedAlways:
            permissionStatus = .authorizedAlways
        case .authorizedWhenInUse:
            permissionStatus = .authorizedWhenInUse
        @unknown default:
            permissionStatus = .notDetermined
        }
    }
    
    // MARK: - Location Recording
    
    /// 记录梦境位置
    func recordDreamLocation(dreamId: UUID, locationName: String? = nil) async throws -> DreamLocation? {
        guard config.enableLocationTracking else {
            return nil
        }
        
        guard permissionStatus.canRecordLocation else {
            throw LocationError.permissionDenied
        }
        
        isRecording = true
        
        // 获取当前位置
        let location = try await getCurrentLocation()
        
        // 反向地理编码获取地址
        let placemark = try await reverseGeocode(location)
        
        // 创建位置记录
        let dreamLocation = DreamLocation(
            dreamId: dreamId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            accuracy: location.horizontalAccuracy,
            address: placemark?.thoroughfare,
            city: placemark?.locality,
            country: placemark?.country,
            timestamp: Date(),
            isHome: isHomeLocation(location),
            locationName: locationName ?? config.defaultLocationName
        )
        
        // 保存到数据库
        if let context = modelContext {
            context.insert(dreamLocation)
            try context.save()
        }
        
        isRecording = false
        return dreamLocation
    }
    
    /// 获取当前位置
    private func getCurrentLocation() async throws -> CLLocation {
        if let location = currentLocation {
            return location
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            locationManager.requestLocation()
            
            let delegate = LocationDelegate(
                onSuccess: { location in
                    continuation.resume(returning: location)
                },
                onFailure: { error in
                    continuation.resume(throwing: error)
                }
            )
            
            // Store delegate to prevent deallocation
            objc_setAssociatedObject(locationManager, "tempDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// 反向地理编码
    private func reverseGeocode(_ location: CLLocation) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()
        return try await geocoder.reverseGeocodeLocation(location).first
    }
    
    /// 判断是否家位置
    private func isHomeLocation(_ location: CLLocation) -> Bool {
        // 简单实现：可以添加家的坐标进行比较
        // 这里暂时返回 false
        return false
    }
    
    // MARK: - Location Query
    
    /// 获取所有位置记录
    func getAllLocations() -> [DreamLocation] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<DreamLocation>()
        return try? context.fetch(descriptor) ?? []
    }
    
    /// 获取指定梦境的位置
    func getLocation(for dreamId: UUID) -> DreamLocation? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<DreamLocation>(
            predicate: #Predicate<DreamLocation> { $0.dreamId == dreamId }
        )
        return try? context.fetch(descriptor).first
    }
    
    /// 获取位置聚类（用于地图显示）
    func getLocationClusters(filter: MapFilterOptions = .init()) -> [LocationCluster] {
        var locations = getAllLocations()
        
        // 应用日期筛选
        locations = filterLocationsByDate(locations, range: filter.dateRange)
        
        guard filter.showClusters else {
            // 不聚类，每个位置一个 cluster
            return locations.map { LocationCluster(dreams: [$0]) }
        }
        
        // 简单聚类算法
        return clusterLocations(locations, radius: filter.clusterRadius)
    }
    
    /// 按日期筛选位置
    private func filterLocationsByDate(_ locations: [DreamLocation], range: MapFilterOptions.DateRange) -> [DreamLocation] {
        let now = Date()
        
        switch range {
        case .all:
            return locations
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return locations.filter { $0.timestamp >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return locations.filter { $0.timestamp >= monthAgo }
        case .year:
            let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            return locations.filter { $0.timestamp >= yearAgo }
        case .custom:
            // 自定义范围需要额外参数，这里返回全部
            return locations
        }
    }
    
    /// 聚类位置
    private func clusterLocations(_ locations: [DreamLocation], radius: Double) -> [LocationCluster] {
        // 简单实现：按城市分组
        let grouped = Dictionary(grouping: locations) { location in
            location.city ?? "Unknown"
        }
        
        return grouped.map { LocationCluster(dreams: $0.value) }
    }
    
    /// 获取位置统计
    func getLocationStatistics() -> LocationStatistics {
        let locations = getAllLocations()
        return LocationStatistics(locations: locations)
    }
    
    // MARK: - Configuration
    
    /// 加载配置
    private func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "locationServiceConfig"),
           let decoded = try? JSONDecoder().decode(LocationServiceConfig.self, from: data) {
            config = decoded
        }
    }
    
    /// 保存配置
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "locationServiceConfig")
        }
    }
    
    /// 更新配置
    func updateConfig(_ update: (inout LocationServiceConfig) -> Void) {
        update(&config)
        saveConfig()
    }
    
    // MARK: - Utility
    
    /// 开启位置更新
    func startUpdatingLocation() {
        guard config.enableLocationTracking else { return }
        locationManager.startUpdatingLocation()
    }
    
    /// 停止位置更新
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension DreamLocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                currentLocation = location
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error.localizedDescription
            isRecording = false
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkPermissionStatus()
        }
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置权限被拒绝"
        case .locationUnavailable:
            return "无法获取当前位置"
        case .geocodingFailed:
            return "地址解析失败"
        }
    }
}

// MARK: - Location Delegate Helper

private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    let onSuccess: (CLLocation) -> Void
    let onFailure: (Error) -> Void
    
    init(onSuccess: @escaping (CLLocation) -> Void, onFailure: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        super.init()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onSuccess(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onFailure(error)
    }
}
