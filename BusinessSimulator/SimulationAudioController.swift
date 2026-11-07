import Foundation

/// A consistent portion of day playback in which a short simulation sound
/// may begin. Stage zero plays immediately; stages one through five randomize
/// the exact start time within their respective windows.
enum SimulationSoundWindow: Equatable {
    case stageZero
    case stageOne
    case stageTwo
    case stageThree
    case stageFour
    case stageFive

    var playsImmediately: Bool {
        switch self {
        case .stageZero:
            return true
        case .stageOne, .stageTwo, .stageThree, .stageFour, .stageFive:
            return false
        }
    }

    var progressRange: ClosedRange<Double> {
        switch self {
        case .stageZero:
            return 0.0...0.0
        case .stageOne:
            return 0.05...0.15
        case .stageTwo:
            return 0.24...0.34
        case .stageThree:
            return 0.42...0.52
        case .stageFour:
            return 0.62...0.72
        case .stageFive:
            return 0.80...0.90
        }
    }
}

struct SimulationSoundCue {
    let sound: GameSound
    let window: SimulationSoundWindow
}

struct SimulationAudioPlan {
    let loopingSounds: [GameSound]
    let cues: [SimulationSoundCue]

    init(
        loopingSounds: [GameSound] = [],
        cues: [SimulationSoundCue] = []
    ) {
        self.loopingSounds = loopingSounds
        self.cues = cues
    }
}

/// The game context used to select all audio heard during one simulated day.
/// Product and season are included now so future scene-specific audio rules do
/// not require changing the controller interface.
struct SimulationAudioContext {
    let locationID: LocationID
    let productID: ProductID
    let weatherCondition: WeatherCondition
    let seasonOfYear: SeasonOfYear
}

/// Converts game context into a declarative audio plan. Timing and playback
/// remain the responsibility of `SimulationAudioController`.
struct SimulationAudioResolver {
    private let locationCatalog: LocationCatalog

    init(locationCatalog: LocationCatalog = LocationCatalog()) {
        self.locationCatalog = locationCatalog
    }

    func resolve(_ context: SimulationAudioContext) -> SimulationAudioPlan {
        let locationPlan = plan(for: context.locationID)
        var loopingSounds = locationPlan.loopingSounds

        if context.weatherCondition == .rain {
            loopingSounds.append(.rainAmbient)
        }

        return SimulationAudioPlan(
            loopingSounds: loopingSounds,
            cues: locationPlan.cues
        )
    }

    private func plan(for locationID: LocationID) -> SimulationAudioPlan {
        if locationID == locationCatalog.home.id {
            return homePlan()
        } else if locationID == locationCatalog.ballpark.id {
            return ballparkPlan()
        } else if locationID == locationCatalog.beach.id {
            return beachPlan()
        } else if locationID == locationCatalog.farmersMarket.id {
            return farmersMarketPlan()
        }

        return SimulationAudioPlan()
    }

    private func homePlan() -> SimulationAudioPlan {
        SimulationAudioPlan(loopingSounds: [.neighborhoodAmbient])
    }

    private func ballparkPlan() -> SimulationAudioPlan {
        SimulationAudioPlan(
            loopingSounds: [.ballparkAmbient],
            cues: [
                SimulationSoundCue(
                    sound: .baseballHit,
                    window: .stageTwo
                ),
                SimulationSoundCue(
                    sound: .baseballHit,
                    window: .stageFour
                )
            ]
        )
    }

    private func beachPlan() -> SimulationAudioPlan {
        SimulationAudioPlan(
            loopingSounds: [.neighborhoodAmbient],
            cues: [
                SimulationSoundCue(
                    sound: .waveCrash,
                    window: .stageTwo
                ),
                SimulationSoundCue(
                    sound: .waveCrash,
                    window: .stageFour
                )
            ]
        )
    }

    private func farmersMarketPlan() -> SimulationAudioPlan {
        SimulationAudioPlan(
            loopingSounds: [.neighborhoodAmbient],
            cues: [
                SimulationSoundCue(
                    sound: .marketBellChime,
                    window: .stageZero
                )
            ]
        )
    }
}

/// Owns simulation-only audio playback, including ambient loops and
/// cancellable short cues scheduled within randomized playback windows.
@MainActor
final class SimulationAudioController {
    typealias RandomProgress = (ClosedRange<Double>) -> Double

    private let soundPlayer: any SoundPlaying
    private let randomProgress: RandomProgress
    private var cueTasks: [Task<Void, Never>] = []
    private var activeSounds: Set<GameSound> = []

    init(
        soundPlayer: any SoundPlaying,
        randomProgress: @escaping RandomProgress = { Double.random(in: $0) }
    ) {
        self.soundPlayer = soundPlayer
        self.randomProgress = randomProgress
    }

    func start(
        plan: SimulationAudioPlan,
        duration: TimeInterval
    ) {
        precondition(duration > 0, "Simulation audio duration must be positive.")

        stop()

        plan.loopingSounds.forEach { sound in
            activeSounds.insert(sound)
            soundPlayer.playLooping(sound)
        }

        for cue in plan.cues {
            activeSounds.insert(cue.sound)

            if cue.window.playsImmediately {
                soundPlayer.play(cue.sound)
                continue
            }

            let playAtProgress = randomProgress(cue.window.progressRange)
            let delay = duration * playAtProgress

            let task = Task { [weak self] in
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch {
                    return
                }

                guard !Task.isCancelled, let self else { return }
                soundPlayer.play(cue.sound)
            }

            cueTasks.append(task)
        }
    }

    func stop() {
        cueTasks.forEach { $0.cancel() }
        cueTasks.removeAll()

        activeSounds.forEach { soundPlayer.stop($0) }
        activeSounds.removeAll()
    }
}
