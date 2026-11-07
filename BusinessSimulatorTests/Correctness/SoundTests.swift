import Foundation
import Testing
@testable import BusinessSimulator

@MainActor
struct SoundTests {
    private let locationCatalog = LocationCatalog()

    // MARK: - Location Plans

    @Test
    func homeUsesNeighborhoodAmbienceWithoutLocationCues() {
        let plan = resolve(locationID: locationCatalog.home.id)

        #expect(plan.loopingSounds == [.neighborhoodAmbient])
        #expect(plan.cues.isEmpty)
    }

    @Test
    func ballparkUsesBallparkAmbienceAndHitCues() {
        let plan = resolve(locationID: locationCatalog.ballpark.id)

        #expect(plan.loopingSounds == [.ballparkAmbient])
        #expect(plan.cues.map(\.sound) == [.baseballHit, .baseballHit])
        #expect(plan.cues.map(\.window) == [.stageTwo, .stageFour])
    }

    @Test
    func beachUsesNeighborhoodAmbienceAndWaveCues() {
        let plan = resolve(locationID: locationCatalog.beach.id)

        #expect(plan.loopingSounds == [.neighborhoodAmbient])
        #expect(plan.cues.map(\.sound) == [.waveCrash, .waveCrash])
        #expect(plan.cues.map(\.window) == [.stageTwo, .stageFour])
    }

    @Test
    func farmersMarketUsesNeighborhoodAmbienceAndImmediateBell() {
        let plan = resolve(locationID: locationCatalog.farmersMarket.id)

        #expect(plan.loopingSounds == [.neighborhoodAmbient])
        #expect(plan.cues.map(\.sound) == [.marketBellChime])
        #expect(plan.cues.map(\.window) == [.stageZero])
    }

    // MARK: - Weather Layer

    @Test
    func rainAddsWeatherAmbienceWithoutReplacingLocationAudio() {
        let plan = resolve(
            locationID: locationCatalog.ballpark.id,
            weatherCondition: .rain
        )

        #expect(plan.loopingSounds.contains(.ballparkAmbient))
        #expect(plan.loopingSounds.contains(.rainAmbient))
        #expect(plan.cues.map(\.sound) == [.baseballHit, .baseballHit])
    }

    @Test
    func nonRainyWeatherDoesNotAddRainAmbience() {
        for weatherCondition in [
            WeatherCondition.sunny,
            .cloudy,
            .snow
        ] {
            let plan = resolve(
                locationID: locationCatalog.home.id,
                weatherCondition: weatherCondition
            )

            #expect(!plan.loopingSounds.contains(.rainAmbient))
        }
    }

    // MARK: - Playback Windows

    @Test
    func stageZeroIsImmediateAndOtherStagesAreOrderedAndNonOverlapping() {
        #expect(SimulationSoundWindow.stageZero.playsImmediately)
        #expect(
            SimulationSoundWindow.stageZero.progressRange
                == 0.0...0.0
        )

        let randomizedWindows: [SimulationSoundWindow] = [
            .stageOne,
            .stageTwo,
            .stageThree,
            .stageFour,
            .stageFive
        ]

        #expect(randomizedWindows.allSatisfy { !$0.playsImmediately })

        for window in randomizedWindows {
            #expect(window.progressRange.lowerBound >= 0.0)
            #expect(window.progressRange.upperBound <= 1.0)
            #expect(
                window.progressRange.lowerBound
                    < window.progressRange.upperBound
            )
        }

        for (earlier, later) in zip(
            randomizedWindows,
            randomizedWindows.dropFirst()
        ) {
            #expect(
                earlier.progressRange.upperBound
                    < later.progressRange.lowerBound
            )
        }
    }

    // MARK: - Controller Lifecycle

    @Test
    func stageZeroPlaysImmediatelyWithoutRequestingRandomProgress() {
        let soundPlayer = RecordingSoundPlayer()
        var randomProgressCallCount = 0
        let controller = SimulationAudioController(
            soundPlayer: soundPlayer,
            randomProgress: { range in
                randomProgressCallCount += 1
                return range.lowerBound
            }
        )

        controller.start(
            plan: SimulationAudioPlan(
                cues: [
                    SimulationSoundCue(
                        sound: .marketBellChime,
                        window: .stageZero
                    )
                ]
            ),
            duration: 1.0
        )

        #expect(soundPlayer.playedSounds == [.marketBellChime])
        #expect(randomProgressCallCount == 0)

        controller.stop()
    }

    @Test
    func stopCancelsPendingCuesAndStopsSimulationSounds() async throws {
        let soundPlayer = RecordingSoundPlayer()
        let controller = SimulationAudioController(
            soundPlayer: soundPlayer,
            randomProgress: { $0.lowerBound }
        )

        controller.start(
            plan: SimulationAudioPlan(
                loopingSounds: [.neighborhoodAmbient],
                cues: [
                    SimulationSoundCue(
                        sound: .baseballHit,
                        window: .stageOne
                    )
                ]
            ),
            duration: 1.0
        )
        controller.stop()

        try await Task.sleep(for: .milliseconds(100))

        #expect(soundPlayer.loopedSounds == [.neighborhoodAmbient])
        #expect(soundPlayer.playedSounds.isEmpty)
        #expect(soundPlayer.stoppedSounds.contains(.neighborhoodAmbient))
        #expect(soundPlayer.stoppedSounds.contains(.baseballHit))
    }

    @Test
    func startingNewPlanStopsAndCancelsPreviousPlan() async throws {
        let soundPlayer = RecordingSoundPlayer()
        let controller = SimulationAudioController(
            soundPlayer: soundPlayer,
            randomProgress: { $0.lowerBound }
        )

        controller.start(
            plan: SimulationAudioPlan(
                loopingSounds: [.neighborhoodAmbient],
                cues: [
                    SimulationSoundCue(
                        sound: .baseballHit,
                        window: .stageOne
                    )
                ]
            ),
            duration: 1.0
        )
        controller.start(
            plan: SimulationAudioPlan(
                loopingSounds: [.ballparkAmbient]
            ),
            duration: 1.0
        )

        try await Task.sleep(for: .milliseconds(100))

        #expect(
            soundPlayer.loopedSounds
                == [.neighborhoodAmbient, .ballparkAmbient]
        )
        #expect(soundPlayer.playedSounds.isEmpty)
        #expect(soundPlayer.stoppedSounds.contains(.neighborhoodAmbient))
        #expect(soundPlayer.stoppedSounds.contains(.baseballHit))

        controller.stop()
    }

    private func resolve(
        locationID: LocationID,
        weatherCondition: WeatherCondition = .sunny
    ) -> SimulationAudioPlan {
        SimulationAudioResolver(locationCatalog: locationCatalog).resolve(
            SimulationAudioContext(
                locationID: locationID,
                productID: .hotDogs,
                weatherCondition: weatherCondition,
                seasonOfYear: .summer
            )
        )
    }
}

@MainActor
private final class RecordingSoundPlayer: SoundPlaying {
    private(set) var playedSounds: [GameSound] = []
    private(set) var loopedSounds: [GameSound] = []
    private(set) var stoppedSounds: [GameSound] = []

    func play(_ sound: GameSound) {
        playedSounds.append(sound)
    }

    func playLooping(_ sound: GameSound) {
        loopedSounds.append(sound)
    }

    func stop(_ sound: GameSound) {
        stoppedSounds.append(sound)
    }
}
