import AVFoundation

enum GameSound: Hashable {
    case ballparkAmbient
    case distribution
    case finance
    case marketing
    case neighborhoodAmbient
    case rainAmbient
    case productionBlender
    case productionCooking
    case upgradeWhoosh

    fileprivate var resourceName: String {
        switch self {
        case .ballparkAmbient:
            "ballpark_ambient"
        case .distribution:
            "distribution_sound"
        case .finance:
            "finance_sound"
        case .marketing:
            "marketing_sound"
        case .neighborhoodAmbient:
            "neighborhood_ambient"
        case .rainAmbient:
            "rain_ambient"
        case .productionBlender:
            "production_blender"
        case .productionCooking:
            "production_cooking"
        case .upgradeWhoosh:
            "upgrade_whoosh"
        }
    }

    fileprivate var fileExtension: String {
        "wav"
    }
}

/// Plays short game sound effects without exposing AVFoundation details to
/// the rest of the app.
///
/// A class is used so each `AVAudioPlayer` remains alive for the duration of
/// playback. Players are cached so subsequent effects do not reload the file.
@MainActor
final class SoundPlayer {
    private var players: [GameSound: AVAudioPlayer] = [:]

    init() {
        configureAudioSession()
    }

    func play(_ sound: GameSound) {
        guard let player = player(for: sound) else { return }

        player.numberOfLoops = 0
        player.currentTime = 0
        player.play()
    }

    func playLooping(_ sound: GameSound) {
        guard let player = player(for: sound) else { return }

        player.numberOfLoops = -1
        player.currentTime = 0
        player.play()
    }

    func stop(_ sound: GameSound) {
        guard let player = players[sound] else { return }

        player.stop()
        player.numberOfLoops = 0
        player.currentTime = 0
    }

    private func player(for sound: GameSound) -> AVAudioPlayer? {
        if let player = players[sound] {
            return player
        }

        guard let url = soundURL(for: sound) else {
            assertionFailure(
                "Missing sound resource: \(sound.resourceName).\(sound.fileExtension)"
            )
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[sound] = player
            return player
        } catch {
            assertionFailure(
                "Unable to load sound \(sound.resourceName): \(error)"
            )
            return nil
        }
    }

    private func soundURL(for sound: GameSound) -> URL? {
        // Xcode may preserve the Sounds folder or flatten synchronized
        // resources into the bundle, so support both bundle layouts.
        Bundle.main.url(
            forResource: sound.resourceName,
            withExtension: sound.fileExtension,
            subdirectory: "Sounds"
        ) ?? Bundle.main.url(
            forResource: sound.resourceName,
            withExtension: sound.fileExtension
        )
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try audioSession.setActive(true)
        } catch {
            // A session configuration failure should never prevent gameplay.
            assertionFailure("Unable to configure game audio: \(error)")
        }
    }
}
