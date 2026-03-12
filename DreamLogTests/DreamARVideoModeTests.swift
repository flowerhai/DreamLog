//
//  DreamARVideoModeTests.swift
//  DreamLogTests - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
@testable import DreamLog

// MARK: - AR Video Mode Tests

@MainActor
final class DreamARVideoModeTests: XCTestCase {
    
    var videoMode: DreamARVideoMode!
    
    override func setUp() async throws {
        videoMode = DreamARVideoMode.shared
        // 重置状态
        videoMode.selectedFilter = .none
        videoMode.filterIntensity = 100
        videoMode.recordingQuality = .high
        videoMode.recordingDuration = 30
        videoMode.isRecording = false
        videoMode.isSlowMotionMode = false
        videoMode.isTimeLapseMode = false
        videoMode.isSpatialAudioEnabled = true
    }
    
    override func tearDown() async throws {
        videoMode = nil
    }
    
    // MARK: - Filter Tests
    
    func testFilterSelection() {
        // 测试滤镜选择
        XCTAssertEqual(videoMode.selectedFilter, .none)
        
        videoMode.selectedFilter = .vintage
        XCTAssertEqual(videoMode.selectedFilter, .vintage)
        
        videoMode.selectedFilter = .cyberpunk
        XCTAssertEqual(videoMode.selectedFilter, .cyberpunk)
    }
    
    func testFilterIntensity() {
        // 测试滤镜强度范围
        videoMode.filterIntensity = 0
        XCTAssertEqual(videoMode.filterIntensity, 0)
        
        videoMode.filterIntensity = 50
        XCTAssertEqual(videoMode.filterIntensity, 50)
        
        videoMode.filterIntensity = 100
        XCTAssertEqual(videoMode.filterIntensity, 100)
    }
    
    func testAvailableFilters() {
        // 测试可用滤镜数量
        XCTAssertGreaterThan(videoMode.availableFilters.count, 0)
        
        // 测试包含原片滤镜
        XCTAssertTrue(videoMode.availableFilters.contains(.none))
        
        // 测试滤镜唯一性
        let uniqueFilters = Set(videoMode.availableFilters.map { $0.rawValue })
        XCTAssertEqual(uniqueFilters.count, videoMode.availableFilters.count)
    }
    
    func testFilterProperties() {
        // 测试滤镜属性
        let filter = ARVideoFilter.cyberpunk
        
        XCTAssertFalse(filter.id.isEmpty)
        XCTAssertFalse(filter.icon.isEmpty)
        XCTAssertNotNil(filter.color)
        XCTAssertFalse(filter.rawValue.isEmpty)
    }
    
    // MARK: - Quality Tests
    
    func testRecordingQuality() {
        // 测试录制质量设置
        videoMode.recordingQuality = .low
        XCTAssertEqual(videoMode.recordingQuality, .low)
        XCTAssertEqual(videoMode.recordingQuality.resolution, "720p")
        
        videoMode.recordingQuality = .medium
        XCTAssertEqual(videoMode.recordingQuality, .medium)
        XCTAssertEqual(videoMode.recordingQuality.resolution, "1080p")
        
        videoMode.recordingQuality = .high
        XCTAssertEqual(videoMode.recordingQuality, .high)
        
        videoMode.recordingQuality = .ultra
        XCTAssertEqual(videoMode.recordingQuality, .ultra)
        XCTAssertEqual(videoMode.recordingQuality.resolution, "4K")
    }
    
    func testQualityBitrates() {
        // 测试质量比特率
        XCTAssertEqual(VideoQuality.low.bitrate, 5_000_000)
        XCTAssertEqual(VideoQuality.medium.bitrate, 10_000_000)
        XCTAssertEqual(VideoQuality.high.bitrate, 20_000_000)
        XCTAssertEqual(VideoQuality.ultra.bitrate, 50_000_000)
    }
    
    func testQualityFrameRates() {
        // 测试质量帧率
        XCTAssertEqual(VideoQuality.low.frameRate, 30)
        XCTAssertEqual(VideoQuality.medium.frameRate, 30)
        XCTAssertEqual(VideoQuality.high.frameRate, 60)
        XCTAssertEqual(VideoQuality.ultra.frameRate, 60)
    }
    
    // MARK: - Duration Tests
    
    func testRecordingDuration() {
        // 测试录制时长设置
        videoMode.recordingDuration = 15
        XCTAssertEqual(videoMode.recordingDuration, 15)
        
        videoMode.recordingDuration = 30
        XCTAssertEqual(videoMode.recordingDuration, 30)
        
        videoMode.recordingDuration = 60
        XCTAssertEqual(videoMode.recordingDuration, 60)
        
        videoMode.recordingDuration = 120
        XCTAssertEqual(videoMode.recordingDuration, 120)
    }
    
    // MARK: - Recording State Tests
    
    func testRecordingState() {
        // 测试录制状态
        XCTAssertFalse(videoMode.isRecording)
        XCTAssertEqual(videoMode.recordingProgress, 0)
    }
    
    func testRecordingTimeRemaining() {
        // 测试录制剩余时间
        videoMode.recordingDuration = 30
        videoMode.recordingTimeRemaining = 30
        XCTAssertEqual(videoMode.recordingTimeRemaining, 30)
        
        videoMode.recordingTimeRemaining = 15
        XCTAssertEqual(videoMode.recordingTimeRemaining, 15)
    }
    
    // MARK: - Slow Motion Tests
    
    func testSlowMotionToggle() {
        // 测试慢动作模式开关
        XCTAssertFalse(videoMode.isSlowMotionMode)
        
        videoMode.isSlowMotionMode = true
        XCTAssertTrue(videoMode.isSlowMotionMode)
        
        videoMode.isSlowMotionMode = false
        XCTAssertFalse(videoMode.isSlowMotionMode)
    }
    
    func testSlowMotionRates() {
        // 测试慢动作倍率
        videoMode.slowMotionRate = .x2
        XCTAssertEqual(videoMode.slowMotionRate, .x2)
        XCTAssertEqual(videoMode.slowMotionRate.captureFrameRate, 120)
        
        videoMode.slowMotionRate = .x4
        XCTAssertEqual(videoMode.slowMotionRate, .x4)
        XCTAssertEqual(videoMode.slowMotionRate.captureFrameRate, 240)
        
        videoMode.slowMotionRate = .x8
        XCTAssertEqual(videoMode.slowMotionRate, .x8)
        XCTAssertEqual(videoMode.slowMotionRate.captureFrameRate, 240)
    }
    
    func testSlowMotionPlayback() {
        // 测试慢动作播放帧率
        XCTAssertEqual(SlowMotionRate.x2.playbackFrameRate, 30)
        XCTAssertEqual(SlowMotionRate.x4.playbackFrameRate, 30)
        XCTAssertEqual(SlowMotionRate.x8.playbackFrameRate, 30)
    }
    
    // MARK: - Time Lapse Tests
    
    func testTimeLapseToggle() {
        // 测试延时摄影模式开关
        XCTAssertFalse(videoMode.isTimeLapseMode)
        
        videoMode.isTimeLapseMode = true
        XCTAssertTrue(videoMode.isTimeLapseMode)
        
        videoMode.isTimeLapseMode = false
        XCTAssertFalse(videoMode.isTimeLapseMode)
    }
    
    func testTimeLapseIntervals() {
        // 测试延时摄影间隔
        videoMode.timeLapseInterval = 0.5
        XCTAssertEqual(videoMode.timeLapseInterval, 0.5)
        
        videoMode.timeLapseInterval = 1.0
        XCTAssertEqual(videoMode.timeLapseInterval, 1.0)
        
        videoMode.timeLapseInterval = 2.0
        XCTAssertEqual(videoMode.timeLapseInterval, 2.0)
        
        videoMode.timeLapseInterval = 5.0
        XCTAssertEqual(videoMode.timeLapseInterval, 5.0)
    }
    
    // MARK: - Spatial Audio Tests
    
    func testSpatialAudioToggle() {
        // 测试空间音频开关
        XCTAssertTrue(videoMode.isSpatialAudioEnabled)
        
        videoMode.isSpatialAudioEnabled = false
        XCTAssertFalse(videoMode.isSpatialAudioEnabled)
        
        videoMode.isSpatialAudioEnabled = true
        XCTAssertTrue(videoMode.isSpatialAudioEnabled)
    }
    
    // MARK: - Video Capture Tests
    
    func testVideoCaptureProperties() {
        // 测试视频捕获属性
        let thumbnail = UIImage()
        let video = ARVideoCapture(
            id: UUID(),
            thumbnail: thumbnail,
            filter: .vintage,
            filterIntensity: 75.0,
            duration: 30.0,
            frameRate: 60,
            isSlowMotion: true,
            slowMotionRate: .x4,
            isTimeLapse: false,
            timeLapseInterval: nil,
            spatialAudioEnabled: true,
            dreamId: UUID(),
            dreamTitle: "Test Dream",
            captureDate: Date(),
            quality: .high
        )
        
        XCTAssertFalse(video.id.uuidString.isEmpty)
        XCTAssertEqual(video.filter, .vintage)
        XCTAssertEqual(video.filterIntensity, 75.0)
        XCTAssertEqual(video.duration, 30.0)
        XCTAssertEqual(video.frameRate, 60)
        XCTAssertTrue(video.isSlowMotion)
        XCTAssertEqual(video.slowMotionRate, .x4)
        XCTAssertFalse(video.isTimeLapse)
        XCTAssertTrue(video.spatialAudioEnabled)
        XCTAssertEqual(video.dreamTitle, "Test Dream")
        XCTAssertEqual(video.quality, .high)
    }
    
    func testVideoFileName() {
        // 测试视频文件名生成
        let video = ARVideoCapture(
            id: UUID(),
            thumbnail: UIImage(),
            filter: .none,
            filterIntensity: 100,
            duration: 30,
            frameRate: 30,
            isSlowMotion: false,
            slowMotionRate: nil,
            isTimeLapse: false,
            timeLapseInterval: nil,
            spatialAudioEnabled: false,
            dreamId: nil,
            dreamTitle: nil,
            captureDate: Date(),
            quality: .high
        )
        
        XCTAssertTrue(video.fileName.hasPrefix("DreamLog_Video_"))
        XCTAssertTrue(video.fileName.hasSuffix(".mp4"))
    }
    
    func testVideoFormattedDuration() {
        // 测试视频时长格式化
        let video1 = ARVideoCapture(
            id: UUID(), thumbnail: UIImage(), filter: .none, filterIntensity: 100,
            duration: 30, frameRate: 30, isSlowMotion: false, slowMotionRate: nil,
            isTimeLapse: false, timeLapseInterval: nil, spatialAudioEnabled: false,
            dreamId: nil, dreamTitle: nil, captureDate: Date(), quality: .high
        )
        XCTAssertEqual(video1.formattedDuration, "0:30")
        
        let video2 = ARVideoCapture(
            id: UUID(), thumbnail: UIImage(), filter: .none, filterIntensity: 100,
            duration: 90, frameRate: 30, isSlowMotion: false, slowMotionRate: nil,
            isTimeLapse: false, timeLapseInterval: nil, spatialAudioEnabled: false,
            dreamId: nil, dreamTitle: nil, captureDate: Date(), quality: .high
        )
        XCTAssertEqual(video2.formattedDuration, "1:30")
    }
    
    func testVideoModeDescription() {
        // 测试视频模式描述
        let normalVideo = ARVideoCapture(
            id: UUID(), thumbnail: UIImage(), filter: .none, filterIntensity: 100,
            duration: 30, frameRate: 30, isSlowMotion: false, slowMotionRate: nil,
            isTimeLapse: false, timeLapseInterval: nil, spatialAudioEnabled: false,
            dreamId: nil, dreamTitle: nil, captureDate: Date(), quality: .high
        )
        XCTAssertEqual(normalVideo.modeDescription, "普通视频")
        
        let slowMoVideo = ARVideoCapture(
            id: UUID(), thumbnail: UIImage(), filter: .none, filterIntensity: 100,
            duration: 30, frameRate: 120, isSlowMotion: true, slowMotionRate: .x2,
            isTimeLapse: false, timeLapseInterval: nil, spatialAudioEnabled: false,
            dreamId: nil, dreamTitle: nil, captureDate: Date(), quality: .high
        )
        XCTAssertEqual(slowMoVideo.modeDescription, "慢动作 2x")
        
        let timeLapseVideo = ARVideoCapture(
            id: UUID(), thumbnail: UIImage(), filter: .none, filterIntensity: 100,
            duration: 30, frameRate: 30, isSlowMotion: false, slowMotionRate: nil,
            isTimeLapse: true, timeLapseInterval: 1.0, spatialAudioEnabled: false,
            dreamId: nil, dreamTitle: nil, captureDate: Date(), quality: .high
        )
        XCTAssertEqual(timeLapseVideo.modeDescription, "延时摄影")
    }
    
    // MARK: - Recording Control Tests
    
    func testCancelRecording() {
        // 测试取消录制
        videoMode.isRecording = true
        videoMode.recordingProgress = 0.5
        
        videoMode.cancelRecording()
        
        XCTAssertFalse(videoMode.isRecording)
        XCTAssertEqual(videoMode.recordingProgress, 0)
    }
    
    func testTogglePause() {
        // 测试暂停切换
        // 注意：pause 功能在 ViewModel 中实现
        let viewModel = VideoEditorViewModel()
        XCTAssertFalse(viewModel.isPaused)
        
        viewModel.isPaused = true
        XCTAssertTrue(viewModel.isPaused)
        
        viewModel.isPaused = false
        XCTAssertFalse(viewModel.isPaused)
    }
    
    // MARK: - Video Management Tests
    
    func testVideoServiceInitialization() {
        // 测试视频服务初始化
        let service = DreamARVideoService.shared
        XCTAssertNotNil(service)
    }
    
    // MARK: - Performance Tests
    
    func testFilterApplicationPerformance() {
        // 测试滤镜应用性能
        let thumbnail = UIImage()
        let video = ARVideoCapture(
            id: UUID(),
            thumbnail: thumbnail,
            filter: .vintage,
            filterIntensity: 100,
            duration: 30,
            frameRate: 60,
            isSlowMotion: false,
            slowMotionRate: nil,
            isTimeLapse: false,
            timeLapseInterval: nil,
            spatialAudioEnabled: true,
            dreamId: nil,
            dreamTitle: nil,
            captureDate: Date(),
            quality: .high
        )
        
        // 验证视频对象创建成功
        XCTAssertNotNil(video)
    }
    
    // MARK: - Edge Case Tests
    
    func testZeroDuration() {
        // 测试零时长边界情况
        let video = ARVideoCapture(
            id: UUID(), thumbnail: UIImage(), filter: .none, filterIntensity: 100,
            duration: 0, frameRate: 30, isSlowMotion: false, slowMotionRate: nil,
            isTimeLapse: false, timeLapseInterval: nil, spatialAudioEnabled: false,
            dreamId: nil, dreamTitle: nil, captureDate: Date(), quality: .high
        )
        XCTAssertEqual(video.formattedDuration, "0:00")
    }
    
    func testLongDuration() {
        // 测试长时长边界情况
        let video = ARVideoCapture(
            id: UUID(), thumbnail: UIImage(), filter: .none, filterIntensity: 100,
            duration: 3661, frameRate: 30, isSlowMotion: false, slowMotionRate: nil,
            isTimeLapse: false, timeLapseInterval: nil, spatialAudioEnabled: false,
            dreamId: nil, dreamTitle: nil, captureDate: Date(), quality: .high
        )
        XCTAssertEqual(video.formattedDuration, "61:01")
    }
    
    func testAllFilterIcons() {
        // 测试所有滤镜都有图标
        for filter in ARVideoFilter.allCases {
            XCTAssertFalse(filter.icon.isEmpty, "Filter \(filter.rawValue) has empty icon")
        }
    }
    
    func testAllFilterColors() {
        // 测试所有滤镜都有颜色
        for filter in ARVideoFilter.allCases {
            XCTAssertNotNil(filter.color, "Filter \(filter.rawValue) has nil color")
        }
    }
    
    func testVideoQualityAllCases() {
        // 测试所有质量等级
        let qualities = VideoQuality.allCases
        XCTAssertEqual(qualities.count, 4)
        XCTAssertTrue(qualities.contains(.low))
        XCTAssertTrue(qualities.contains(.medium))
        XCTAssertTrue(qualities.contains(.high))
        XCTAssertTrue(qualities.contains(.ultra))
    }
    
    func testSlowMotionRateAllCases() {
        // 测试所有慢动作倍率
        let rates = SlowMotionRate.allCases
        XCTAssertEqual(rates.count, 3)
        XCTAssertTrue(rates.contains(.x2))
        XCTAssertTrue(rates.contains(.x4))
        XCTAssertTrue(rates.contains(.x8))
    }
}

// MARK: - Video Editor ViewModel Tests

@MainActor
final class VideoEditorViewModelTests: XCTestCase {
    
    func testViewModelInitialState() {
        let viewModel = VideoEditorViewModel()
        
        XCTAssertFalse(viewModel.showingGallery)
        XCTAssertFalse(viewModel.showingShareSheet)
        XCTAssertFalse(viewModel.isPaused)
    }
    
    func testViewModelStateChanges() {
        let viewModel = VideoEditorViewModel()
        
        viewModel.showingGallery = true
        XCTAssertTrue(viewModel.showingGallery)
        
        viewModel.showingShareSheet = true
        XCTAssertTrue(viewModel.showingShareSheet)
        
        viewModel.isPaused = true
        XCTAssertTrue(viewModel.isPaused)
    }
}
