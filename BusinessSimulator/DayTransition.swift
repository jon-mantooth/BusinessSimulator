//
//  DayTransition.swift
//  BusinessSimulator
//

import Foundation
import Observation
import SwiftUI

enum DayTransitionPhase: Equatable {
    case daytime
    case sunrise
    case opening
    case playback
    case closing
    case nighttime
}

enum DayTransitionMessage: Equatable {
    case date(Date)
    case open
    case closed
}

@Observable
@MainActor
final class DayTransitionState {
    private static let sunriseDuration = 3.5
    private static let sceneFadeDuration = 1.5
    private static let messageFadeDuration = 0.5

    private(set) var phase: DayTransitionPhase = .daytime
    private(set) var daylightSceneOpacity = 1.0
    private(set) var nightSceneOpacity = 0.0
    private(set) var playbackSceneOpacity = 1.0
    private(set) var playbackIsInteractive = true
    private(set) var message: DayTransitionMessage?

    @ObservationIgnored
    private var transitionTask: Task<Void, Never>?

    func beginSunrise(date: Date, reduceMotion: Bool) {
        transitionTask?.cancel()
        phase = .sunrise
        daylightSceneOpacity = reduceMotion ? 1.0 : 0.0
        nightSceneOpacity = reduceMotion ? 0.0 : 1.0
        presentMessage(.date(date), reduceMotion: reduceMotion)

        transitionTask = Task { [weak self] in
            guard let self else { return }
            await Task.yield()

            if !reduceMotion {
                withAnimation(.easeInOut(duration: Self.sunriseDuration)) {
                    self.daylightSceneOpacity = 1.0
                    self.nightSceneOpacity = 0.0
                }

                guard await wait(
                    for: .seconds(Self.sunriseDuration)
                ) else { return }
            }

            guard await wait(for: .milliseconds(500)) else { return }
            dismissMessage(reduceMotion: reduceMotion)
            phase = .daytime
            transitionTask = nil
        }
    }

    func beginOpening(
        reduceMotion: Bool,
        onPlaybackReady: @escaping @MainActor () -> Void
    ) {
        transitionTask?.cancel()
        phase = .opening
        daylightSceneOpacity = 1.0
        nightSceneOpacity = 0.0
        playbackSceneOpacity = 0.0
        playbackIsInteractive = false
        presentMessage(.open, reduceMotion: reduceMotion)

        transitionTask = Task { [weak self] in
            guard let self else { return }
            guard await wait(for: .seconds(1)) else { return }

            if reduceMotion {
                playbackSceneOpacity = 1.0
            } else {
                withAnimation(.easeInOut(duration: Self.sceneFadeDuration)) {
                    self.playbackSceneOpacity = 1.0
                }

                guard await wait(
                    for: .seconds(Self.sceneFadeDuration)
                ) else { return }
            }

            dismissMessage(reduceMotion: reduceMotion)
            playbackIsInteractive = true
            phase = .playback
            transitionTask = nil
            onPlaybackReady()
        }
    }

    func beginClosing(
        reduceMotion: Bool,
        onNightReady: @escaping @MainActor () -> Void
    ) {
        guard phase != .closing && phase != .nighttime else { return }

        transitionTask?.cancel()
        phase = .closing
        playbackIsInteractive = false
        daylightSceneOpacity = 0.0
        nightSceneOpacity = 1.0
        presentMessage(.closed, reduceMotion: reduceMotion)

        transitionTask = Task { [weak self] in
            guard let self else { return }

            if reduceMotion {
                playbackSceneOpacity = 0.0
            } else {
                withAnimation(.easeInOut(duration: Self.sceneFadeDuration)) {
                    self.playbackSceneOpacity = 0.0
                }

                guard await wait(
                    for: .seconds(Self.sceneFadeDuration)
                ) else { return }
            }

            guard await wait(for: .seconds(1)) else { return }
            dismissMessage(reduceMotion: reduceMotion)
            phase = .nighttime
            transitionTask = nil
            onNightReady()
        }
    }

    func resetToDaytime() {
        transitionTask?.cancel()
        transitionTask = nil
        phase = .daytime
        daylightSceneOpacity = 1.0
        nightSceneOpacity = 0.0
        playbackSceneOpacity = 1.0
        playbackIsInteractive = true
        message = nil
    }

    private func presentMessage(
        _ newMessage: DayTransitionMessage,
        reduceMotion: Bool
    ) {
        if reduceMotion {
            message = newMessage
        } else {
            withAnimation(.easeInOut(duration: Self.messageFadeDuration)) {
                message = newMessage
            }
        }
    }

    private func dismissMessage(reduceMotion: Bool) {
        if reduceMotion {
            message = nil
        } else {
            withAnimation(.easeInOut(duration: Self.messageFadeDuration)) {
                message = nil
            }
        }
    }

    private func wait(for duration: Duration) async -> Bool {
        do {
            try await Task.sleep(for: duration)
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
