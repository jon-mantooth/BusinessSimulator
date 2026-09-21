import Foundation
import Testing
@testable import BusinessSimulator

@MainActor
struct DayPlaybackTests {}

// MARK: - Playback State

extension DayPlaybackTests {

    @Test
    func newPlaybackBeginsIdleWithNoProgress() {
        let playback = DayPlaybackState()

        #expect(playback.phase == .idle)
        #expect(playback.progress == 0.0)
    }

    @Test
    func startBeginsPlaybackAtNoProgress() {
        let playback = DayPlaybackState(duration: 1.0)

        playback.start()

        #expect(playback.phase == .playing)
        #expect(playback.progress >= 0.0)
        #expect(playback.progress <= 1.0)

        playback.reset()
    }

    @Test
    func progressRemainsWithinValidRange() async {
        let playback = DayPlaybackState(duration: 0.05)

        playback.start()

        while playback.phase == .playing {
            #expect(playback.progress >= 0.0)
            #expect(playback.progress <= 1.0)
            await Task.yield()
        }

        #expect(playback.progress >= 0.0)
        #expect(playback.progress <= 1.0)
    }

    @Test
    func normalCompletionEndsAtFullProgress() async throws {
        let playback = DayPlaybackState(duration: 0.01)

        playback.start()
        try await Task.sleep(for: .milliseconds(50))

        #expect(playback.phase == .completed)
        #expect(playback.progress == 1.0)
    }

    @Test
    func skipImmediatelyCompletesPlayback() {
        let playback = DayPlaybackState(duration: 1.0)
        playback.start()

        playback.skip()

        #expect(playback.phase == .completed)
        #expect(playback.progress == 1.0)
    }

    @Test
    func resetReturnsPlaybackToInitialState() {
        let playback = DayPlaybackState(duration: 1.0)
        playback.start()
        playback.skip()

        playback.reset()

        #expect(playback.phase == .idle)
        #expect(playback.progress == 0.0)
    }

    @Test
    func completingPlaybackIsIdempotent() async throws {
        let playback = DayPlaybackState(duration: 0.01)
        playback.start()
        try await Task.sleep(for: .milliseconds(50))

        playback.skip()
        try await Task.sleep(for: .milliseconds(20))

        #expect(playback.phase == .completed)
        #expect(playback.progress == 1.0)
    }
}

// MARK: - Time Conversion

extension DayPlaybackTests {

    @Test
    func zeroProgressRepresentsOpeningTime() {
        let hours = makeBusinessHours()

        #expect(
            hours.playbackMinutes(at: 0.0)
                == Double(hours.openingTime.totalMinutes)
        )
    }

    @Test
    func halfwayProgressRepresentsBusinessDayMidpoint() {
        let hours = makeBusinessHours()

        #expect(hours.playbackMinutes(at: 0.5) == 780.0)
    }

    @Test
    func fullProgressRepresentsClosingTime() {
        let hours = makeBusinessHours()

        #expect(
            hours.playbackMinutes(at: 1.0)
                == Double(hours.closingTime.totalMinutes)
        )
    }

    @Test
    func timeConversionSupportsHoursWithMinutes() {
        let hours = BusinessHours(
            openingTime: BusinessTime(hour: 8, minute: 30),
            closingTime: BusinessTime(hour: 16, minute: 45)
        )

        #expect(hours.playbackMinutes(at: 0.5) == 757.5)
    }

    @Test
    func timeConversionClampsProgressToBusinessDay() {
        let hours = makeBusinessHours()

        #expect(hours.playbackMinutes(at: -1.0) == 540.0)
        #expect(hours.playbackMinutes(at: 2.0) == 1_020.0)
    }
}

private func makeBusinessHours() -> BusinessHours {
    BusinessHours(
        openingTime: BusinessTime(hour: 9, minute: 0),
        closingTime: BusinessTime(hour: 17, minute: 0)
    )
}
