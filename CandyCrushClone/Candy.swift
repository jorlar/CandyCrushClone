import SpriteKit

enum CandyType: Int, CaseIterable {
    case red
    case blue
    case green
    case yellow
    case purple
    case orange
    
    var color: UIColor {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .purple: return .purple
        case .orange: return .orange
        }
    }
}

enum SpecialType {
    case none
    case striped
    case wrapped
    case colorBomb
    
    var texture: SKTexture? {
        switch self {
        case .none: return nil
        case .striped: return SKTexture(imageNamed: "striped")
        case .wrapped: return SKTexture(imageNamed: "wrapped")
        case .colorBomb: return SKTexture(imageNamed: "colorBomb")
        }
    }
}

class Candy: SKShapeNode {
    var type: CandyType
    var specialType: SpecialType = .none
    var row: Int = 0
    var col: Int = 0
    
    private var specialSprite: SKSpriteNode?
    
    init() {
        // Randomly select a candy type
        type = CandyType.allCases.randomElement()!
        
        super.init()
        
        // Create a rounded rectangle shape for the candy
        let rect = CGRect(x: -20, y: -20, width: 40, height: 40)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        self.path = path.cgPath
        
        // Set the candy's appearance
        self.fillColor = type.color
        self.strokeColor = .white
        self.lineWidth = 2
        
        // Add a subtle shadow
        self.shadowNode = SKShapeNode(path: path.cgPath)
        self.shadowNode?.fillColor = .black
        self.shadowNode?.alpha = 0.2
        self.shadowNode?.position = CGPoint(x: 2, y: -2)
        self.addChild(self.shadowNode!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contains(_ point: CGPoint) -> Bool {
        let convertedPoint = convert(point, from: parent!)
        return path!.contains(convertedPoint)
    }
    
    func makeSpecial(_ type: SpecialType) {
        specialType = type
        
        // Remove existing special sprite if any
        specialSprite?.removeFromParent()
        
        if let texture = type.texture {
            specialSprite = SKSpriteNode(texture: texture)
            specialSprite?.size = CGSize(width: 30, height: 30)
            specialSprite?.zPosition = 1
            addChild(specialSprite!)
        }
    }
    
    func activateSpecial(at position: CGPoint, in scene: GameScene) {
        switch specialType {
        case .striped:
            activateStriped(in: scene)
        case .wrapped:
            activateWrapped(at: position, in: scene)
        case .colorBomb:
            activateColorBomb(in: scene)
        case .none:
            break
        }
    }
    
    private func activateStriped(in scene: GameScene) {
        // Remove all candies in the same row
        for col in 0..<scene.cols {
            if let candy = scene.candies[row][col] {
                candy.removeFromParent()
                scene.candies[row][col] = nil
            }
        }
    }
    
    private func activateWrapped(at position: CGPoint, in scene: GameScene) {
        // Remove candies in a 3x3 area
        let startRow = max(0, row - 1)
        let endRow = min(scene.rows - 1, row + 1)
        let startCol = max(0, col - 1)
        let endCol = min(scene.cols - 1, col + 1)
        
        for r in startRow...endRow {
            for c in startCol...endCol {
                if let candy = scene.candies[r][c] {
                    candy.removeFromParent()
                    scene.candies[r][c] = nil
                }
            }
        }
    }
    
    private func activateColorBomb(in scene: GameScene) {
        // Remove all candies of the same type
        for r in 0..<scene.rows {
            for c in 0..<scene.cols {
                if let candy = scene.candies[r][c],
                   candy.type == type {
                    candy.removeFromParent()
                    scene.candies[r][c] = nil
                }
            }
        }
    }
} 