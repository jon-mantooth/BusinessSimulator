import Foundation
import Testing
@testable import BusinessSimulator

@MainActor
struct DayTransitionTests {}

// MARK: - Initial and Reset State

extension DayTransitionTests {

    @Test
    func newTransitionStateBeginsInDaytime() {
        let transition = DayTransitionState()

        #expect(transition.phase == .daytime)
        #expect(transition.daylightSceneOpacity == 1.0)
        #expect(transition.nightSceneOpacity == 0.0)
        #expect(transition.playbackSceneOpacity == 1.0)
        #expect(transition.playbackIsInteractive)
        #expect(transition.message == nil)
    }

    @Test
    func resetCancelsTransitionAndRestoresDaytime() {
        let transition = DayTransitionState()
        transition.beginOpening(reduceMotion: false, onPlaybackReady: {})

        transition.resetToDaytime()

        #expect(transition.phase == .daytime)
        #expect(transition.daylightSceneOpacity == 1.0)
        #expect(transition.nightSceneOpacity == 0.0)
        #expect(transition.playbackSceneOpacity == 1.0)
        #expect(transition.playbackIsInteractive)
        #expect(transition.message == nil)
    }
}

// MARK: - Sunrise

extension DayTransitionTests {

    @Test
    func sunriseBeginsAtNightAndShowsDate() {
        let transition = DayTransitionState()
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        transition.beginSunrise(date: date, reduceMotion: false)

        #expect(transition.phase == .sunrise)
        #expect(transition.daylightSceneOpacity == 0.0)
        #expect(transition.nightSceneOpacity == 1.0)
        #expect(transition.message == .date(date))

        transition.resetToDaytime()
    }

    @Test
    func reducedMotionSunriseImmediatelyUsesDaylight() {
        let transition = DayTransitionState()
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        transition.beginSunrise(date: date, reduceMotion: true)

        #expect(transition.phase == .sunrise)
        #expect(transition.daylightSceneOpacity == 1.0)
        #expect(transition.nightSceneOpacity == 0.0)
        #expect(transition.message == .date(date))

        transition.resetToDaytime()
    }
}

// MARK: - Opening and Closing

extension DayTransitionTests {

    @Test
    func openingHidesPlaybackAndLocksInteraction() {
        let transition = DayTransitionState()

        transition.beginOpening(reduceMotion: false, onPlaybackReady: {})

        #expect(transition.phase == .opening)
        #expect(transition.daylightSceneOpacity == 1.0)
        #expect(transition.nightSceneOpacity == 0.0)
        #expect(transition.playbackSceneOpacity == 0.0)
        #expect(!transition.playbackIsInteractive)
        #expect(transition.message == .open)

        transition.resetToDaytime()
    }

    @Test
    func closingRevealsNightAndLocksInteraction() {
        let transition = DayTransitionState()

        transition.beginClosing(reduceMotion: false, onNightReady: {})

        #expect(transition.phase == .closing)
        #expect(transition.daylightSceneOpacity == 0.0)
        #expect(transition.nightSceneOpacity == 1.0)
        #expect(!transition.playbackIsInteractive)
        #expect(transition.message == .closed)

        transition.resetToDaytime()
    }
}
