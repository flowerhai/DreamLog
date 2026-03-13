//
//  DreamMapView.swift
//  DreamLog - 梦境地图视图
//
//  Phase 31: 梦境地图功能
//  创建时间：2026-03-13
//

import SwiftUI
import MapKit

struct DreamMapView: View {
    @EnvironmentObject var locationService: DreamLocationService
    @State private var selectedCluster: LocationCluster?
    @State private var showFilterSheet = false
    @State private var filterOptions = MapFilterOptions()
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            // 地图视图
            if #available(iOS 17.0, *) {
                modernMapView
            } else {
                legacyMapView
            }
            
            // 悬浮控制按钮
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // 筛选按钮
                        Button(action: { showFilterSheet.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        
                        // 定位按钮
                        Button(action: { centerOnCurrentLocation() }) {
                            Image(systemName: "location")
                                .font(.title3)
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        
                        Spacer()
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 100)
                }
                
                Spacer()
            }
            
            // 统计卡片
            VStack {
                HStack {
                    LocationStatsCard(stats: locationService.getLocationStatistics())
                        .padding()
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, 80)
        }
        .onAppear {
            locationService.checkPermissionStatus()
            locationService.startUpdatingLocation()
        }
        .onDisappear {
            locationService.stopUpdatingLocation()
        }
        .sheet(isPresented: $showFilterSheet) {
            MapFilterSheet(options: $filterOptions)
        }
    }
    
    // MARK: - Modern Map View (iOS 17+)
    
    @available(iOS 17.0, *)
    private var modernMapView: some View {
        Map(position: $mapPosition, selection: $selectedCluster) {
            ForEach(locationService.getLocationClusters(filter: filterOptions)) { cluster in
                Annotation(
                    cluster.cities.first ?? "未知位置",
                    coordinate: cluster.coordinate
                ) {
                    ClusterAnnotationView(cluster: cluster, isSelected: selectedCluster?.id == cluster.id)
                        .onTapGesture {
                            selectedCluster = cluster
                        }
                }
            }
            
            // 当前位置标记
            if let location = locationService.currentLocation {
                Annotation("当前位置", coordinate: location.coordinate) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
    
    // MARK: - Legacy Map View (iOS 16)
    
    private var legacyMapView: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        ))) {
            ForEach(locationService.getLocationClusters(filter: filterOptions), id: \.id) { cluster in
                Annotation(
                    cluster.cities.first ?? "未知位置",
                    coordinate: cluster.coordinate
                ) {
                    ClusterAnnotationView(cluster: cluster, isSelected: selectedCluster?.id == cluster.id)
                        .onTapGesture {
                            selectedCluster = cluster
                        }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func centerOnCurrentLocation() {
        if let location = locationService.currentLocation {
            if #available(iOS 17.0, *) {
                mapPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ))
            }
        }
    }
}

// MARK: - Cluster Annotation View

struct ClusterAnnotationView: View {
    let cluster: LocationCluster
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.purple : Color.white)
                    .frame(width: size, height: size)
                    .shadow(radius: isSelected ? 8 : 4)
                
                Text("\(cluster.dreamCount)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(isSelected ? .white : .purple)
            }
            
            if cluster.dreamCount == 1, let city = cluster.cities.first {
                Text(city)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(4)
            }
        }
    }
    
    private var size: CGFloat {
        if cluster.dreamCount > 100 { return 60 }
        if cluster.dreamCount > 50 { return 50 }
        if cluster.dreamCount > 20 { return 40 }
        if cluster.dreamCount > 5 { return 35 }
        return 30
    }
    
    private var fontSize: CGFloat {
        if cluster.dreamCount > 100 { return 16 }
        if cluster.dreamCount > 50 { return 14 }
        if cluster.dreamCount > 20 { return 13 }
        return 12
    }
}

// MARK: - Location Stats Card

struct LocationStatsCard: View {
    let stats: LocationStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.purple)
                Text("位置统计")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatItem(icon: "map", value: "\(stats.totalLocations)", label: "位置")
                StatItem(icon: "building.2", value: "\(stats.uniqueCities)", label: "城市")
                StatItem(icon: "globe", value: "\(stats.countries.count)", label: "国家")
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.purple)
            Text(value)
                .font(.boldSystem(size: 16))
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Map Filter Sheet

struct MapFilterSheet: View {
    @Binding var options: MapFilterOptions
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("显示选项")) {
                    Toggle("显示聚类", isOn: $options.showClusters)
                    Toggle("显示家位置", isOn: $options.showHomeMarker)
                    Toggle("热力图模式", isOn: $options.showHeatmap)
                }
                
                Section(header: Text("日期范围")) {
                    Picker("时间范围", selection: $options.dateRange) {
                        ForEach(MapFilterOptions.DateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
                
                Section(header: Text("聚类设置")) {
                    Slider(value: $options.clusterRadius, in: 10000...500000, step: 10000) {
                        Text("聚类半径")
                    } minimumValueLabel: {
                        Text("\(Int(options.clusterRadius / 1000))km")
                    }
                }
            }
            .navigationTitle("地图筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DreamMapView()
        .environmentObject(DreamLocationService.shared)
}
