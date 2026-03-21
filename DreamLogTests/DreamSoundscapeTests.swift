//
//  DreamSoundscapeTests.swift
//  DreamLogTests
//
//  氛围音景服务单元测试 - Phase 86 梦境音乐与氛围音景 🎵💤✨
//  创建时间：2026-03-21
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamSoundscapeTests: XCTestCase {
    
    var soundscapeService: DreamSoundscapeService!
    
    override func setUp() async throws {
        try await super.setUp()
        soundscapeService = DreamSoundscapeService.shared
    }
    
    override func tearDown() async throws {
        soundscapeService.stopAll()
        soundscapeService = nil
        try await super.tearDown()
    }
    
    // MARK: - SoundscapeCategory Tests
    
    func testSoundscapeCategoryCases() {
        let categories = SoundscapeCategory.allCases
        XCTAssertEqual(categories.count, 6, "应该有 6 种音景分类")
        
        let expectedCategories: [SoundscapeCategory] = [.nature, .city, .indoor, .fantasy, .whiteNoise, .meditation]
        XCTAssertEqual(categories, expectedCategories)
    }
    
    func testSoundscapeCategoryIcons() {
        XCTAssertEqual(SoundscapeCategory.nature.icon, "leaf.fill")
        XCTAssertEqual(SoundscapeCategory.city.icon, "building.2.fill")
        XCTAssertEqual(SoundscapeCategory.indoor.icon, "house.fill")
        XCTAssertEqual(SoundscapeCategory.fantasy.icon, "sparkles")
        XCTAssertEqual(SoundscapeCategory.whiteNoise.icon, "waveform")
        XCTAssertEqual(SoundscapeCategory.meditation.icon, "figure.mind.and.body")
    }
    
    func testSoundscapeCategoryColors() {
        XCTAssertEqual(SoundscapeCategory.nature.color, "34D399")
        XCTAssertEqual(SoundscapeCategory.city.color, "6B7280")
        XCTAssertEqual(SoundscapeCategory.indoor.color, "F59E0B")
        XCTAssertEqual(SoundscapeCategory.fantasy.color, "8B5CF6")
        XCTAssertEqual(SoundscapeCategory.whiteNoise.color, "9CA3AF")
        XCTAssertEqual(SoundscapeCategory.meditation.color, "6366F1")
    }
    
    // MARK: - SoundscapePreset Tests
    
    func testSoundscapePresetCount() {
        let presets = SoundscapePreset.allPresets
        XCTAssertGreaterThanOrEqual(presets.count, 12, "应该至少有 12 个预设音景")
    }
    
    func testSoundscapePresetProperties() {
        let preset = SoundscapePreset.stormyNight
        
        XCTAssertEqual(preset.name, "暴风雨夜")
        XCTAssertEqual(preset.category, .nature)
        XCTAssertEqual(preset.icon, "⛈️")
        XCTAssertEqual(preset.color, "4C1D95")
        XCTAssertGreaterThan(preset.layers.count, 0)
        XCTAssertGreaterThan(preset.recommendedMoods.count, 0)
        XCTAssertGreaterThan(preset.description.count, 0)
    }
    
    func testSoundscapePresetLayers() {
        let preset = SoundscapePreset.stormyNight
        
        for layer in preset.layers {
            XCTAssertGreaterThanOrEqual(layer.volume, 0.0)
            XCTAssertLessThanOrEqual(layer.volume, 1.0)
            XCTAssertGreaterThanOrEqual(layer.pan, -1.0)
            XCTAssertLessThanOrEqual(layer.pan, 1.0)
            XCTAssertGreaterThan(layer.fadeIn, 0)
            XCTAssertGreaterThan(layer.fadeOut, 0)
            XCTAssertTrue(layer.loop)
        }
    }
    
    func testRecommendedForMood() {
        let calmPresets = SoundscapePreset.recommendedForMood("平静")
        XCTAssertGreaterThan(calmPresets.count, 0, "应该有推荐给平静情绪的音景")
        
        let happyPresets = SoundscapePreset.recommendedForMood("快乐")
        XCTAssertGreaterThan(happyPresets.count, 0, "应该有推荐给快乐情绪的音景")
    }
    
    // MARK: - SoundscapeLayerData Tests
    
    func testSoundscapeLayerDataDefaultValues() {
        let layer = SoundscapeLayerData(soundId: "test", soundName: "测试")
        
        XCTAssertEqual(layer.soundId, "test")
        XCTAssertEqual(layer.soundName, "测试")
        XCTAssertEqual(layer.volume, 0.7)
        XCTAssertEqual(layer.pan, 0.0)
        XCTAssertEqual(layer.fadeIn, 2.0)
        XCTAssertEqual(layer.fadeOut, 2.0)
        XCTAssertTrue(layer.loop)
        XCTAssertEqual(layer.pitch, 1.0)
    }
    
    func testSoundscapeLayerDataWithVolume() {
        let layer = SoundscapeLayerData(soundId: "test", soundName: "测试", volume: 0.5)
        
        XCTAssertEqual(layer.volume, 0.5)
        
        let modifiedLayer = layer.withVolume(0.8)
        XCTAssertEqual(modifiedLayer.volume, 0.8)
        XCTAssertEqual(layer.volume, 0.5, "原图层不应被修改")
    }
    
    func testSoundscapeLayerDataVolumeClamping() {
        let layer = SoundscapeLayerData(soundId: "test", soundName: "测试", volume: 0.5)
        
        let tooHigh = layer.withVolume(1.5)
        XCTAssertEqual(tooHigh.volume, 1.0, "音量不应超过 1.0")
        
        let tooLow = layer.withVolume(-0.5)
        XCTAssertEqual(tooLow.volume, 0.0, "音量不应低于 0.0")
    }
    
    // MARK: - SleepTimerConfig Tests
    
    func testSleepTimerConfigDefaultValues() {
        let config = SleepTimerConfig()
        
        XCTAssertFalse(config.enabled)
        XCTAssertEqual(config.duration, 1800) // 30 分钟
        XCTAssertEqual(config.fadeOutDuration, 30)
        XCTAssertEqual(config.action, .stop)
    }
    
    func testSleepTimerConfigFormattedDuration() {
        var config = SleepTimerConfig(duration: 900) // 15 分钟
        XCTAssertEqual(config.formattedDuration, "15 分钟")
        
        config = SleepTimerConfig(duration: 1800) // 30 分钟
        XCTAssertEqual(config.formattedDuration, "30 分钟")
        
        config = SleepTimerConfig(duration: 3600) // 1 小时
        XCTAssertEqual(config.formattedDuration, "1 小时")
        
        config = SleepTimerConfig(duration: 5400) // 1.5 小时
        XCTAssertEqual(config.formattedDuration, "1 小时 30 分钟")
        
        config = SleepTimerConfig(duration: 7200) // 2 小时
        XCTAssertEqual(config.formattedDuration, "2 小时")
    }
    
    func testSleepTimerConfigPresets() {
        let presets = SleepTimerConfig.presets
        XCTAssertEqual(presets.count, 5, "应该有 5 个预设时长")
        
        XCTAssertEqual(presets[0].0, 900)
        XCTAssertEqual(presets[0].1, "15 分钟")
        
        XCTAssertEqual(presets[1].0, 1800)
        XCTAssertEqual(presets[1].1, "30 分钟")
    }
    
    func testSleepTimerActionCases() {
        let actions = SleepTimerAction.allCases
        XCTAssertEqual(actions.count, 3)
        
        XCTAssertEqual(actions[0], .stop)
        XCTAssertEqual(actions[1], .lowerVolume)
        XCTAssertEqual(actions[2], .switchToWhiteNoise)
    }
    
    // MARK: - Service Tests
    
    func testServiceInitialState() {
        XCTAssertFalse(soundscapeService.isPlaying)
        XCTAssertNil(soundscapeService.currentSoundscape)
        XCTAssertTrue(soundscapeService.currentLayers.isEmpty)
        XCTAssertNil(soundscapeService.sleepTimer)
    }
    
    func testPlaySoundscape() async {
        let preset = SoundscapePreset.oceanBeach
        
        await soundscapeService.playSoundscape(preset)
        
        XCTAssertEqual(soundscapeService.currentSoundscape?.id, preset.id)
        XCTAssertEqual(soundscapeService.currentLayers.count, preset.layers.count)
        XCTAssertTrue(soundscapeService.isPlaying)
    }
    
    func testPauseAndResume() async {
        let preset = SoundscapePreset.forestMorning
        
        await soundscapeService.playSoundscape(preset)
        XCTAssertTrue(soundscapeService.isPlaying)
        
        soundscapeService.pause()
        XCTAssertFalse(soundscapeService.isPlaying)
        
        soundscapeService.resume()
        XCTAssertTrue(soundscapeService.isPlaying)
    }
    
    func testStopAll() async {
        let preset = SoundscapePreset.cozyFireplace
        
        await soundscapeService.playSoundscape(preset)
        soundscapeService.setSleepTimer(SleepTimerConfig(enabled: true, duration: 60))
        
        soundscapeService.stopAll()
        
        XCTAssertFalse(soundscapeService.isPlaying)
        XCTAssertNil(soundscapeService.currentSoundscape)
        XCTAssertTrue(soundscapeService.currentLayers.isEmpty)
        XCTAssertNil(soundscapeService.sleepTimer)
    }
    
    func testUpdateMasterVolume() {
        soundscapeService.updateMasterVolume(0.5)
        XCTAssertEqual(soundscapeService.masterVolume, 0.5)
        
        soundscapeService.updateMasterVolume(1.0)
        XCTAssertEqual(soundscapeService.masterVolume, 1.0)
        
        soundscapeService.updateMasterVolume(0.0)
        XCTAssertEqual(soundscapeService.masterVolume, 0.0)
    }
    
    func testMasterVolumeClamping() {
        soundscapeService.updateMasterVolume(1.5)
        XCTAssertEqual(soundscapeService.masterVolume, 1.0, "音量不应超过 1.0")
        
        soundscapeService.updateMasterVolume(-0.5)
        XCTAssertEqual(soundscapeService.masterVolume, 0.0, "音量不应低于 0.0")
    }
    
    // MARK: - Recommendation Tests
    
    func testRecommendSoundscapeForDream() {
        let dream = Dream(
            emotion: .平静，
            content: "我在海边散步，听着海浪声",
            clarity: 4
        )
        
        let presets = soundscapeService.recommendSoundscape(for: dream)
        XCTAssertGreaterThan(presets.count, 0, "应该有声景推荐")
        
        // 应该包含海洋相关的音景
        let hasOcean = presets.contains { $0.name.contains("海") || $0.name.contains("海浪") }
        XCTAssertTrue(hasOcean, "应该推荐海洋相关的音景")
    }
    
    func testRecommendSoundscapeForDifferentEmotions() {
        let calmDream = Dream(emotion: .平静，content: "平静的梦", clarity: 3)
        let happyDream = Dream(emotion: .快乐，content: "快乐的梦", clarity: 3)
        
        let calmPresets = soundscapeService.recommendSoundscape(for: calmDream)
        let happyPresets = soundscapeService.recommendSoundscape(for: happyDream)
        
        XCTAssertGreaterThan(calmPresets.count, 0)
        XCTAssertGreaterThan(happyPresets.count, 0)
    }
    
    func testCreateCustomMix() {
        let layers = [
            SoundscapeLayerData(soundId: "rain", soundName: "雨声", volume: 0.7),
            SoundscapeLayerData(soundId: "thunder", soundName: "雷声", volume: 0.3)
        ]
        
        let customMix = soundscapeService.createCustomMix(name: "雷雨夜", layers: layers)
        
        XCTAssertEqual(customMix.name, "雷雨夜")
        XCTAssertEqual(customMix.layers.count, 2)
        XCTAssertEqual(customMix.icon, "🎵")
    }
    
    // MARK: - Performance Tests
    
    func testRecommendSoundscapePerformance() {
        let dream = Dream(emotion: .平静，content: "测试内容", clarity: 3)
        
        measure {
            _ = soundscapeService.recommendSoundscape(for: dream)
        }
    }
    
    func testPlaySoundscapePerformance() async {
        let preset = SoundscapePreset.stormyNight
        
        measure {
            Task {
                await soundscapeService.playSoundscape(preset)
            }
        }
    }
}

// MARK: - DreamEmotion Extension for Tests

extension DreamEmotion {
    init(rawValue: String) {
        self = DreamEmotion.allCases.first { $0.rawValue == rawValue } ?? .中性
    }
}
