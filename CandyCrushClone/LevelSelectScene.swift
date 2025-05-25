import SpriteKit

class LevelSelectScene: SKScene {
    private let levelsPerRow = 3
    private let levelSpacing: CGFloat = 20
    private let levelSize: CGFloat = 80
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupLevelButtons()
    }
    
    private func setupBackground() {
        backgroundColor = .white
        
        // Add title
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "Select Level"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 50)
        addChild(titleLabel)
    }
    
    private func setupLevelButtons() {
        let startX = frame.midX - CGFloat(levelsPerRow - 1) * (levelSize + levelSpacing) / 2
        let startY = frame.midY + 50
        
        for (index, level) in Level.levels.enumerated() {
            let row = index / levelsPerRow
            let col = index % levelsPerRow
            
            let button = createLevelButton(level: level,
                                        position: CGPoint(x: startX + CGFloat(col) * (levelSize + levelSpacing),
                                                        y: startY - CGFloat(row) * (levelSize + levelSpacing)))
            addChild(button)
        }
    }
    
    private func createLevelButton(level: Level, position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        
        // Create button background
        let background = SKShapeNode(rectOf: CGSize(width: levelSize, height: levelSize),
                                   cornerRadius: 10)
        background.fillColor = isLevelUnlocked(level) ? .systemBlue : .gray
        background.strokeColor = .white
        background.lineWidth = 2
        container.addChild(background)
        
        // Add level number
        let numberLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        numberLabel.text = "\(level.number)"
        numberLabel.fontSize = 24
        numberLabel.fontColor = .white
        numberLabel.verticalAlignmentMode = .center
        container.addChild(numberLabel)
        
        // Add high score if available
        if let highScore = LevelManager.shared.highScores[level.number] {
            let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            scoreLabel.text = "\(highScore)"
            scoreLabel.fontSize = 14
            scoreLabel.fontColor = .white
            scoreLabel.position = CGPoint(x: 0, y: -20)
            container.addChild(scoreLabel)
        }
        
        // Add tap handler
        let button = SKNode()
        button.name = "level_\(level.number)"
        container.addChild(button)
        
        return container
    }
    
    private func isLevelUnlocked(_ level: Level) -> Bool {
        return LevelManager.shared.isLevelUnlocked(level)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let node = nodes(at: location).first,
           let name = node.name,
           name.hasPrefix("level_") {
            let levelNumber = Int(name.replacingOccurrences(of: "level_", with: ""))!
            if let level = Level.levels.first(where: { $0.number == levelNumber }),
               isLevelUnlocked(level) {
                startLevel(level)
            }
        }
    }
    
    private func startLevel(_ level: Level) {
        LevelManager.shared.startLevel(level)
        
        if let gameScene = GameScene(fileNamed: "GameScene") {
            gameScene.scaleMode = .aspectFill
            view?.presentScene(gameScene, transition: SKTransition.doorway(withDuration: 1.0))
        }
    }
} 