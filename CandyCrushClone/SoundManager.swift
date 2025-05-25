import SpriteKit
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var backgroundMusic: AVAudioPlayer?
    private var soundEffects: [String: SKAction] = [:]
    
    private init() {
        setupSounds()
    }
    
    private func setupSounds() {
        // Load sound effects
        soundEffects["match"] = SKAction.playSoundFileNamed("match.mp3", waitForCompletion: false)
        soundEffects["swap"] = SKAction.playSoundFileNamed("swap.mp3", waitForCompletion: false)
        soundEffects["special"] = SKAction.playSoundFileNamed("special.mp3", waitForCompletion: false)
        soundEffects["fall"] = SKAction.playSoundFileNamed("fall.mp3", waitForCompletion: false)
        
        // Setup background music
        if let musicURL = Bundle.main.url(forResource: "background_music", withExtension: "mp3") {
            do {
                backgroundMusic = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusic?.numberOfLoops = -1 // Loop indefinitely
                backgroundMusic?.volume = 0.5
            } catch {
                print("Could not create audio player: \(error)")
            }
        }
    }
    
    func playBackgroundMusic() {
        backgroundMusic?.play()
    }
    
    func stopBackgroundMusic() {
        backgroundMusic?.stop()
    }
    
    func playSound(_ name: String) {
        if let sound = soundEffects[name] {
            SKAction.run(sound)
        }
    }
} 