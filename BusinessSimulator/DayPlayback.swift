//
//  DayPlayback.swift
//  BusinessSimulator
//

import Foundation
import Observation

enum DayPlaybackPhase: Equatable {
    case idle
    case playing
    case completed
}

@Observable
@MainActor
final class DayPlaybackState {
    private(set) var phase: DayPlaybackPhase
    private(set) var progress: Double
    private(set) var elapsedTime: TimeInterval
    let duration: TimeInterval

    @ObservationIgnored
    private var playbackTask: Task<Void, Never>?

    init(duration: TimeInterval = 16.0) {
        assert(duration > 0, "Day playback duration must be positive.")

        self.phase = .idle
        self.progress = 0.0
        self.elapsedTime = 0.0
        self.duration = duration
    }

    func start() {
        playbackTask?.cancel()
        phase = .playing
        progress = 0.0
        elapsedTime = 0.0

        let startTime = Date()

        playbackTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                elapsedTime = min(
                    Date().timeIntervalSince(startTime),
                    duration
                )
                progress = elapsedTime / duration

                if progress >= 1.0 {
                    complete()
                    return
                }

                do {
                    try await Task.sleep(for: .milliseconds(16))
                } catch {
                    return
                }
            }
        }
    }

    func skip() {
        guard phase != .completed else { return }

        playbackTask?.cancel()
        complete()
    }

    func reset() {
        playbackTask?.cancel()
        playbackTask = nil
        progress = 0.0
        elapsedTime = 0.0
        phase = .idle
    }

    private func complete() {
        guard phase != .completed else { return }

        playbackTask = nil
        progress = 1.0
        elapsedTime = duration
        phase = .completed
    }
}
