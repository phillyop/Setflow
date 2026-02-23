import AudioToolbox
import AVFoundation

/// Plays short feedback sounds. Rest-end uses a soft, soothing chime rather than
/// a sharp alert tone.
///
/// To use a fully custom sound: drop a short `.caf`/`.aif`/`.wav` file named
/// `rest_complete` into the app target, and it will be preferred automatically.
enum SoundManager {

    // Cached player for the bundled custom chime (if present).
    private static var restPlayer: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "rest_complete", withExtension: "caf")
                    ?? Bundle.main.url(forResource: "rest_complete", withExtension: "aif")
                    ?? Bundle.main.url(forResource: "rest_complete", withExtension: "wav")
        else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        player?.volume = 0.7
        return player
    }()

    /// Soothing rest-complete chime. Prefers a bundled custom sound; otherwise
    /// falls back to a gentle built-in tone (not the sharp default alert).
    static func playRestComplete() {
        if let player = restPlayer {
            player.currentTime = 0
            player.play()
        } else {
            // 1075 is a soft, bell-like system tone — far gentler than 1005.
            AudioServicesPlaySystemSound(1075)
        }
    }

    /// Kept for existing call sites; routes to the soothing rest chime.
    static func playCompletion() {
        playRestComplete()
    }

    /// A very light tick, e.g. for session completion celebration.
    static func playSuccess() {
        AudioServicesPlaySystemSound(1025)
    }
}
