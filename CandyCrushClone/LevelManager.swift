import Foundation

class LevelManager {
    static let shared = LevelManager()
    
    private let userDefaults = UserDefaults.standard
    private let currentLevelKey = "currentLevel"
    private let highScoresKey = "highScores"
    
    var currentLevel: Level {
        let levelIndex = userDefaults.integer(forKey: currentLevelKey)
        return Level.levels[min(levelIndex, Level.levels.count - 1)]
    }
    
    var highScores: [Int: Int] {
        get {
            return userDefaults.dictionary(forKey: highScoresKey) as? [Int: Int] ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: highScoresKey)
        }
    }
    
    private init() {}
    
    func startLevel(_ level: Level) {
        userDefaults.set(Level.levels.firstIndex(where: { $0.number == level.number }) ?? 0,
                        forKey: currentLevelKey)
    }
    
    func completeLevel(_ level: Level, withScore score: Int) {
        // Update high score
        var scores = highScores
        scores[level.number] = max(score, scores[level.number] ?? 0)
        highScores = scores
        
        // Unlock next level
        if let currentIndex = Level.levels.firstIndex(where: { $0.number == level.number }),
           currentIndex + 1 < Level.levels.count {
            userDefaults.set(currentIndex + 1, forKey: currentLevelKey)
        }
    }
    
    func isLevelUnlocked(_ level: Level) -> Bool {
        let currentIndex = userDefaults.integer(forKey: currentLevelKey)
        return level.number <= currentIndex + 1
    }
    
    func resetProgress() {
        userDefaults.set(0, forKey: currentLevelKey)
        userDefaults.set([:], forKey: highScoresKey)
    }
} 