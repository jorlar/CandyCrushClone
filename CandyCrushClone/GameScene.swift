import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // Game board properties
    var rows: Int = 9
    var cols: Int = 9
    let candySize: CGFloat = 40.0
    var candies: [[Candy]] = []
    var selectedCandy: Candy?
    
    // Game state
    var score = 0
    var movesLeft = 0
    var scoreLabel: SKLabelNode!
    var movesLabel: SKLabelNode!
    var isProcessingMatches = false
    
    // Level properties
    private var currentLevel: Level {
        return LevelManager.shared.currentLevel
    }
    private var specialCandyCounts: [SpecialType: Int] = [:]
    
    // Animation properties
    let matchAnimationDuration: TimeInterval = 0.3
    let fallAnimationDuration: TimeInterval = 0.3
    
    override func didMove(to view: SKView) {
        setupGame()
        SoundManager.shared.playBackgroundMusic()
    }
    
    func setupGame() {
        // Setup background
        backgroundColor = .white
        
        // Initialize level properties
        rows = currentLevel.boardSize.rows
        cols = currentLevel.boardSize.cols
        movesLeft = currentLevel.moves
        specialCandyCounts = [:]
        
        // Setup UI
        setupUI()
        
        // Initialize game board
        setupBoard()
    }
    
    private func setupUI() {
        // Score label
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .black
        scoreLabel.position = CGPoint(x: frame.midX - 100, y: frame.maxY - 50)
        addChild(scoreLabel)
        
        // Moves label
        movesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        movesLabel.text = "Moves: \(movesLeft)"
        movesLabel.fontSize = 24
        movesLabel.fontColor = .black
        movesLabel.position = CGPoint(x: frame.midX + 100, y: frame.maxY - 50)
        addChild(movesLabel)
        
        // Level goals
        let goalsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        goalsLabel.text = "Goals:"
        goalsLabel.fontSize = 20
        goalsLabel.fontColor = .black
        goalsLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        addChild(goalsLabel)
        
        // Add goal indicators
        var yOffset: CGFloat = 130
        for (type, count) in currentLevel.specialCandyGoals {
            let goalLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
            goalLabel.text = "\(type): \(count)"
            goalLabel.fontSize = 18
            goalLabel.fontColor = .black
            goalLabel.position = CGPoint(x: frame.midX, y: frame.maxY - yOffset)
            addChild(goalLabel)
            yOffset += 25
        }
    }
    
    func setupBoard() {
        // Calculate starting position to center the board
        let startX = frame.midX - CGFloat(cols) * candySize / 2
        let startY = frame.midY - CGFloat(rows) * candySize / 2
        
        // Create candies
        for row in 0..<rows {
            var candyRow: [Candy] = []
            for col in 0..<cols {
                // Check if this is a blocked tile
                if currentLevel.blockedTiles.contains(Level.GridPosition(row: row, col: col)) {
                    let blockedTile = SKShapeNode(rectOf: CGSize(width: candySize - 4, height: candySize - 4))
                    blockedTile.fillColor = .darkGray
                    blockedTile.strokeColor = .white
                    blockedTile.position = CGPoint(x: startX + CGFloat(col) * candySize,
                                                 y: startY + CGFloat(row) * candySize)
                    addChild(blockedTile)
                    candyRow.append(nil)
                } else {
                    let candy = createCandy(at: CGPoint(x: startX + CGFloat(col) * candySize,
                                                      y: startY + CGFloat(row) * candySize))
                    candy.row = row
                    candy.col = col
                    candyRow.append(candy)
                    addChild(candy)
                }
            }
            candies.append(candyRow)
        }
        
        // Check for initial matches and refill if needed
        while findMatches().count > 0 {
            refillBoard()
        }
    }
    
    func createCandy(at position: CGPoint) -> Candy {
        let candy = Candy()
        candy.position = position
        candy.size = CGSize(width: candySize - 4, height: candySize - 4)
        return candy
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let node = nodes(at: location).first,
           node.name == "continue" {
            // Return to level select
            if let levelSelect = LevelSelectScene(fileNamed: "LevelSelectScene") {
                levelSelect.scaleMode = .aspectFill
                view?.presentScene(levelSelect, transition: SKTransition.doorway(withDuration: 1.0))
            }
            return
        }
        
        if !isProcessingMatches,
           let candy = candyAt(location) {
            selectedCandy = candy
            candy.run(SKAction.scale(to: 1.1, duration: 0.1))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let selectedCandy = selectedCandy else { return }
        
        selectedCandy.run(SKAction.scale(to: 1.0, duration: 0.1))
        
        let location = touch.location(in: self)
        if let targetCandy = candyAt(location) {
            trySwap(selectedCandy, with: targetCandy)
        }
        
        self.selectedCandy = nil
    }
    
    func candyAt(_ point: CGPoint) -> Candy? {
        for row in candies {
            for candy in row {
                if candy.contains(point) {
                    return candy
                }
            }
        }
        return nil
    }
    
    func trySwap(_ candy1: Candy, with candy2: Candy) {
        // Get positions
        let pos1 = candy1.position
        let pos2 = candy2.position
        
        // Check if candies are adjacent
        let distance = hypot(pos1.x - pos2.x, pos1.y - pos2.y)
        guard distance <= candySize * 1.1 else { return }
        
        // Decrease moves
        movesLeft -= 1
        movesLabel.text = "Moves: \(movesLeft)"
        
        // Play swap sound
        SoundManager.shared.playSound("swap")
        
        // Swap positions
        let move1 = SKAction.move(to: pos2, duration: 0.2)
        let move2 = SKAction.move(to: pos1, duration: 0.2)
        
        candy1.run(move1)
        candy2.run(move2)
        
        // Update array positions
        let tempRow = candy1.row
        let tempCol = candy1.col
        candy1.row = candy2.row
        candy1.col = candy2.col
        candy2.row = tempRow
        candy2.col = tempCol
        
        candies[candy1.row][candy1.col] = candy1
        candies[candy2.row][candy2.col] = candy2
        
        // Check for matches after swap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.checkMatches()
        }
        
        // Check if level is complete or failed
        checkLevelStatus()
    }
    
    func checkMatches() {
        isProcessingMatches = true
        
        let matches = findMatches()
        if matches.isEmpty {
            isProcessingMatches = false
            return
        }
        
        // Remove matches and update score
        removeMatches(matches)
        updateScore(matches.count)
        
        // Wait for removal animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + matchAnimationDuration) {
            self.handleFallingCandies()
        }
    }
    
    func findMatches() -> [Candy] {
        var matches: [Candy] = []
        
        // Check horizontal matches
        for row in 0..<rows {
            for col in 0..<cols-2 {
                let candy1 = candies[row][col]
                let candy2 = candies[row][col+1]
                let candy3 = candies[row][col+2]
                
                if candy1.type == candy2.type && candy2.type == candy3.type {
                    matches.append(contentsOf: [candy1, candy2, candy3])
                }
            }
        }
        
        // Check vertical matches
        for row in 0..<rows-2 {
            for col in 0..<cols {
                let candy1 = candies[row][col]
                let candy2 = candies[row+1][col]
                let candy3 = candies[row+2][col]
                
                if candy1.type == candy2.type && candy2.type == candy3.type {
                    matches.append(contentsOf: [candy1, candy2, candy3])
                }
            }
        }
        
        return Array(Set(matches)) // Remove duplicates
    }
    
    func removeMatches(_ matches: [Candy]) {
        // Play match sound
        SoundManager.shared.playSound("match")
        
        for candy in matches {
            let fadeOut = SKAction.fadeOut(withDuration: matchAnimationDuration)
            let remove = SKAction.removeFromParent()
            candy.run(SKAction.sequence([fadeOut, remove]))
            
            // Create particle effect
            if let emitter = SKEmitterNode(fileNamed: "MatchParticle") {
                emitter.position = candy.position
                addChild(emitter)
                
                // Remove particle effect after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + matchAnimationDuration) {
                    emitter.removeFromParent()
                }
            }
            
            // Check for special candy creation
            if matches.count >= 4 {
                let specialType: SpecialType = matches.count >= 5 ? .colorBomb : .striped
                candy.makeSpecial(specialType)
                SoundManager.shared.playSound("special")
            }
        }
    }
    
    func handleFallingCandies() {
        let startX = frame.midX - CGFloat(cols) * candySize / 2
        let startY = frame.midY - CGFloat(rows) * candySize / 2
        
        // Play falling sound
        SoundManager.shared.playSound("fall")
        
        // Move candies down
        for col in 0..<cols {
            var emptySpaces = 0
            
            for row in (0..<rows).reversed() {
                if candies[row][col].alpha == 0 {
                    emptySpaces += 1
                } else if emptySpaces > 0 {
                    let candy = candies[row][col]
                    let newRow = row + emptySpaces
                    
                    // Update position
                    let newPosition = CGPoint(x: startX + CGFloat(col) * candySize,
                                           y: startY + CGFloat(newRow) * candySize)
                    
                    let move = SKAction.move(to: newPosition, duration: fallAnimationDuration)
                    candy.run(move)
                    
                    // Update array
                    candies[newRow][col] = candy
                    candy.row = newRow
                }
            }
            
            // Create new candies for empty spaces
            for row in 0..<emptySpaces {
                let candy = createCandy(at: CGPoint(x: startX + CGFloat(col) * candySize,
                                                  y: startY + CGFloat(row) * candySize))
                candy.row = row
                candy.col = col
                candies[row][col] = candy
                addChild(candy)
                
                // Animate falling from above
                candy.position.y = startY + CGFloat(rows) * candySize
                let move = SKAction.move(to: CGPoint(x: candy.position.x,
                                                   y: startY + CGFloat(row) * candySize),
                                      duration: fallAnimationDuration)
                candy.run(move)
            }
        }
        
        // Check for new matches after falling
        DispatchQueue.main.asyncAfter(deadline: .now() + fallAnimationDuration) {
            self.checkMatches()
        }
    }
    
    func updateScore(_ matchCount: Int) {
        score += matchCount * 10
        scoreLabel.text = "Score: \(score)"
        
        // Animate score update
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        scoreLabel.run(SKAction.sequence([scaleUp, scaleDown]))
    }
    
    func refillBoard() {
        let startX = frame.midX - CGFloat(cols) * candySize / 2
        let startY = frame.midY - CGFloat(rows) * candySize / 2
        
        for row in 0..<rows {
            for col in 0..<cols {
                let candy = createCandy(at: CGPoint(x: startX + CGFloat(col) * candySize,
                                                  y: startY + CGFloat(row) * candySize))
                candy.row = row
                candy.col = col
                candies[row][col] = candy
                addChild(candy)
            }
        }
    }
    
    private func checkLevelStatus() {
        // Check if out of moves
        if movesLeft <= 0 {
            showLevelComplete(success: false)
            return
        }
        
        // Check if all goals are met
        var allGoalsMet = true
        for (type, requiredCount) in currentLevel.specialCandyGoals {
            if (specialCandyCounts[type] ?? 0) < requiredCount {
                allGoalsMet = false
                break
            }
        }
        
        if allGoalsMet {
            showLevelComplete(success: true)
        }
    }
    
    private func showLevelComplete(success: Bool) {
        let message = success ? "Level Complete!" : "Level Failed"
        let color = success ? UIColor.green : UIColor.red
        
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: 200),
                                   cornerRadius: 20)
        background.fillColor = color
        background.strokeColor = .white
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.alpha = 0.9
        addChild(background)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = message
        label.fontSize = 32
        label.fontColor = .white
        label.position = CGPoint(x: frame.midX, y: frame.midY + 30)
        addChild(label)
        
        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY - 20)
        addChild(scoreLabel)
        
        if success {
            LevelManager.shared.completeLevel(currentLevel, withScore: score)
        }
        
        // Add continue button
        let button = SKShapeNode(rectOf: CGSize(width: 120, height: 40),
                               cornerRadius: 10)
        button.fillColor = .white
        button.strokeColor = .clear
        button.position = CGPoint(x: frame.midX, y: frame.midY - 70)
        addChild(button)
        
        let buttonLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        buttonLabel.text = "Continue"
        buttonLabel.fontSize = 20
        buttonLabel.fontColor = color
        buttonLabel.position = CGPoint(x: frame.midX, y: frame.midY - 75)
        addChild(buttonLabel)
        
        // Add tap handler
        let tapArea = SKNode()
        tapArea.name = "continue"
        tapArea.position = CGPoint(x: frame.midX, y: frame.midY - 70)
        addChild(tapArea)
    }
} 