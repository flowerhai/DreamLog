//
//  DreamARPhotoModeTests.swift
//  DreamLogTests - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
@testable import DreamLog

// MARK: - AR Photo Mode Tests

@MainActor
final class DreamARPhotoModeTests: XCTestCase {
    
    var photoMode: DreamARPhotoMode!
    
    override func setUp() async throws {
        photoMode = DreamARPhotoMode.shared
        // 重置状态
        photoMode.selectedFilter = .none
        photoMode.filterIntensity = 100
        photoMode.isDepthEffectEnabled = false
        photoMode.timerSeconds = 0
        photoMode.isBurstMode = false
    }
    
    override func tearDown() async throws {
        photoMode = nil
    }
    
    // MARK: - Filter Tests
    
    func testFilterSelection() {
        // 测试滤镜选择
        XCTAssertEqual(photoMode.selectedFilter, .none)
        
        photoMode.selectedFilter = .vintage
        XCTAssertEqual(photoMode.selectedFilter, .vintage)
        
        photoMode.selectedFilter = .blackWhite
        XCTAssertEqual(photoMode.selectedFilter, .blackWhite)
    }
    
    func testFilterIntensity() {
        // 测试滤镜强度范围
        photoMode.filterIntensity = 0
        XCTAssertEqual(photoMode.filterIntensity, 0)
        
        photoMode.filterIntensity = 50
        XCTAssertEqual(photoMode.filterIntensity, 50)
        
        photoMode.filterIntensity = 100
        XCTAssertEqual(photoMode.filterIntensity, 100)
    }
    
    func testAvailableFilters() {
        // 测试可用滤镜数量
        XCTAssertGreaterThan(photoMode.availableFilters.count, 0)
        
        // 测试包含原图滤镜
        XCTAssertTrue(photoMode.availableFilters.contains(.none))
        
        // 测试滤镜唯一性
        let uniqueFilters = Set(photoMode.availableFilters.map { $0.rawValue })
        XCTAssertEqual(uniqueFilters.count, photoMode.availableFilters.count)
    }
    
    func testFilterProperties() {
        // 测试滤镜属性
        let filter = ARPhotoFilter.vintage
        
        XCTAssertFalse(filter.id.isEmpty)
        XCTAssertFalse(filter.icon.isEmpty)
        XCTAssertNotNil(filter.color)
        XCTAssertFalse(filter.rawValue.isEmpty)
    }
    
    // MARK: - Depth Effect Tests
    
    func testDepthEffectToggle() {
        // 测试景深效果开关
        XCTAssertFalse(photoMode.isDepthEffectEnabled)
        
        photoMode.isDepthEffectEnabled = true
        XCTAssertTrue(photoMode.isDepthEffectEnabled)
        
        photoMode.isDepthEffectEnabled = false
        XCTAssertFalse(photoMode.isDepthEffectEnabled)
    }
    
    func testDepthBlurIntensity() {
        // 测试景深模糊强度
        photoMode.depthBlurIntensity = 0
        XCTAssertEqual(photoMode.depthBlurIntensity, 0)
        
        photoMode.depthBlurIntensity = 5
        XCTAssertEqual(photoMode.depthBlurIntensity, 5)
        
        photoMode.depthBlurIntensity = 10
        XCTAssertEqual(photoMode.depthBlurIntensity, 10)
    }
    
    // MARK: - Timer Tests
    
    func testTimerSettings() {
        // 测试定时器设置
        XCTAssertEqual(photoMode.timerSeconds, 0)
        
        photoMode.timerSeconds = 3
        XCTAssertEqual(photoMode.timerSeconds, 3)
        
        photoMode.timerSeconds = 5
        XCTAssertEqual(photoMode.timerSeconds, 5)
        
        photoMode.timerSeconds = 10
        XCTAssertEqual(photoMode.timerSeconds, 10)
    }
    
    func testCountdownState() {
        // 测试倒计时状态
        XCTAssertFalse(photoMode.isCountdownActive)
        XCTAssertEqual(photoMode.countdownRemaining, 0)
    }
    
    // MARK: - Burst Mode Tests
    
    func testBurstModeToggle() {
        // 测试连拍模式开关
        XCTAssertFalse(photoMode.isBurstMode)
        
        photoMode.isBurstMode = true
        XCTAssertTrue(photoMode.isBurstMode)
        
        photoMode.isBurstMode = false
        XCTAssertFalse(photoMode.isBurstMode)
    }
    
    func testBurstCount() {
        // 测试连拍数量
        XCTAssertEqual(photoMode.burstCount, 3)
        
        photoMode.burstCount = 5
        XCTAssertEqual(photoMode.burstCount, 5)
        
        photoMode.burstCount = 10
        XCTAssertEqual(photoMode.burstCount, 10)
    }
    
    // MARK: - Grid Display Tests
    
    func testGridDisplay() {
        // 测试网格显示
        XCTAssertFalse(photoMode.showGrid)
        
        photoMode.showGrid = true
        XCTAssertTrue(photoMode.showGrid)
        
        photoMode.showGrid = false
        XCTAssertFalse(photoMode.showGrid)
    }
    
    // MARK: - Photo Capture Tests
    
    func testPhotoCaptureInitialization() {
        // 测试照片捕获初始化
        let testImage = UIImage()
        let photo = ARPhotoCapture(
            id: UUID(),
            image: testImage,
            originalImage: testImage,
            filter: .vintage,
            filterIntensity: 75,
            depthEffectEnabled: true,
            depthBlurIntensity: 5,
            dreamId: UUID(),
            dreamTitle: "Test Dream",
            captureDate: Date()
        )
        
        XCTAssertEqual(photo.filter, .vintage)
        XCTAssertEqual(photo.filterIntensity, 75)
        XCTAssertTrue(photo.depthEffectEnabled)
        XCTAssertEqual(photo.depthBlurIntensity, 5)
        XCTAssertEqual(photo.dreamTitle, "Test Dream")
        XCTAssertFalse(photo.isBurstPhoto)
    }
    
    func testPhotoFileName() {
        // 测试照片文件名生成
        let testImage = UIImage()
        let date = Date()
        let photo = ARPhotoCapture(
            id: UUID(),
            image: testImage,
            originalImage: testImage,
            filter: .none,
            filterIntensity: 100,
            depthEffectEnabled: false,
            depthBlurIntensity: 0,
            dreamId: nil,
            dreamTitle: nil,
            captureDate: date
        )
        
        let fileName = photo.fileName
        XCTAssertTrue(fileName.hasPrefix("DreamLog_"))
        XCTAssertTrue(fileName.hasSuffix(".jpg"))
    }
    
    func testPhotoFormattedDate() {
        // 测试照片日期格式化
        let testImage = UIImage()
        let photo = ARPhotoCapture(
            id: UUID(),
            image: testImage,
            originalImage: testImage,
            filter: .none,
            filterIntensity: 100,
            depthEffectEnabled: false,
            depthBlurIntensity: 0,
            dreamId: nil,
            dreamTitle: nil,
            captureDate: Date()
        )
        
        let formattedDate = photo.formattedDate
        XCTAssertFalse(formattedDate.isEmpty)
    }
    
    // MARK: - Burst Photo Tests
    
    func testBurstPhotoProperties() {
        // 测试连拍照片属性
        let testImage = UIImage()
        let sequenceId = UUID()
        
        var photo = ARPhotoCapture(
            id: UUID(),
            image: testImage,
            originalImage: testImage,
            filter: .none,
            filterIntensity: 100,
            depthEffectEnabled: false,
            depthBlurIntensity: 0,
            dreamId: nil,
            dreamTitle: nil,
            captureDate: Date()
        )
        
        XCTAssertFalse(photo.isBurstPhoto)
        XCTAssertNil(photo.burstSequenceId)
        
        photo.isBurstPhoto = true
        photo.burstSequenceId = sequenceId
        
        XCTAssertTrue(photo.isBurstPhoto)
        XCTAssertEqual(photo.burstSequenceId, sequenceId)
    }
    
    // MARK: - Photo Service Tests
    
    func testPhotoServiceSharedInstance() {
        // 测试照片服务单例
        let service1 = DreamARPhotoService.shared
        let service2 = DreamARPhotoService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    // MARK: - Filter Enum Tests
    
    func testAllFilterCases() {
        // 测试所有滤镜枚举值
        let allFilters = ARPhotoFilter.allCases
        
        XCTAssertTrue(allFilters.contains(.none))
        XCTAssertTrue(allFilters.contains(.vintage))
        XCTAssertTrue(allFilters.contains(.blackWhite))
        XCTAssertTrue(allFilters.contains(.sepia))
        XCTAssertTrue(allFilters.contains(.dramatic))
        XCTAssertTrue(allFilters.contains(.fade))
        XCTAssertTrue(allFilters.contains(.instant))
        XCTAssertTrue(allFilters.contains(.chrome))
        XCTAssertTrue(allFilters.contains(.mono))
        XCTAssertTrue(allFilters.contains(.tonal))
        XCTAssertTrue(allFilters.contains(.linear))
        XCTAssertTrue(allFilters.contains(.warmth))
        XCTAssertTrue(allFilters.contains(.cool))
        XCTAssertTrue(allFilters.contains(.dreamy))
        XCTAssertTrue(allFilters.contains(.starry))
    }
    
    func testFilterIcons() {
        // 测试滤镜图标
        for filter in ARPhotoFilter.allCases {
            XCTAssertFalse(filter.icon.isEmpty, "Filter \(filter.rawValue) should have an icon")
        }
    }
    
    func testFilterColors() {
        // 测试滤镜颜色
        for filter in ARPhotoFilter.allCases {
            // Color 无法直接比较，但至少确保不崩溃
            _ = filter.color
        }
    }
    
    // MARK: - Performance Tests
    
    func testFilterApplicationPerformance() {
        // 测试滤镜应用性能
        let testImage = UIImage()
        let expectation = self.expectation(description: "Filter applied")
        
        Task {
            let result = await photoMode.applyFilters(to: testImage)
            XCTAssertNotNil(result)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Photo Management Tests
    
    func testPhotoCount() {
        // 测试照片数量
        XCTAssertEqual(photoMode.photos.count, 0)
    }
    
    func testClearAllPhotos() async {
        // 测试清除所有照片
        // 初始状态应为空
        XCTAssertEqual(photoMode.photos.count, 0)
        
        // 清除后仍应为空
        await photoMode.clearAllPhotos()
        XCTAssertEqual(photoMode.photos.count, 0)
    }
}

// MARK: - AR Photo Filter Extension Tests

final class ARPhotoFilterExtensionTests: XCTestCase {
    
    func testFilterRawValue() {
        // 测试滤镜原始值
        XCTAssertEqual(ARPhotoFilter.none.rawValue, "原图")
        XCTAssertEqual(ARPhotoFilter.vintage.rawValue, "复古")
        XCTAssertEqual(ARPhotoFilter.blackWhite.rawValue, "黑白")
    }
    
    func testFilterIdentifiable() {
        // 测试滤镜可标识性
        let filter1 = ARPhotoFilter.vintage
        let filter2 = ARPhotoFilter.vintage
        
        XCTAssertEqual(filter1.id, filter2.id)
    }
    
    func testFilterCaseIterable() {
        // 测试滤镜枚举遍历
        let filters = ARPhotoFilter.allCases
        XCTAssertGreaterThan(filters.count, 0)
    }
}

// MARK: - AR Photo Capture Codable Tests

final class ARPhotoCaptureCodableTests: XCTestCase {
    
    func testPhotoCaptureCodingKeys() {
        // 测试照片捕获编码键
        let keys = ARPhotoCapture.CodingKeys.allCases.map { $0.rawValue }
        
        XCTAssertTrue(keys.contains("id"))
        XCTAssertTrue(keys.contains("filter"))
        XCTAssertTrue(keys.contains("filterIntensity"))
        XCTAssertTrue(keys.contains("depthEffectEnabled"))
        XCTAssertTrue(keys.contains("depthBlurIntensity"))
        XCTAssertTrue(keys.contains("dreamId"))
        XCTAssertTrue(keys.contains("dreamTitle"))
        XCTAssertTrue(keys.contains("captureDate"))
    }
}
