import Foundation

struct Level {
    let number: Int
    let moves: Int
    let targetScore: Int
    let specialCandyGoals: [SpecialType: Int]
    let boardSize: (rows: Int, cols: Int)
    let blockedTiles: Set<GridPosition>
    
    struct GridPosition: Hashable {
        let row: Int
        let col: Int
    }
    
    // Predefined levels
    static let levels: [Level] = [
        Level(number: 1,
              moves: 20,
              targetScore: 1000,
              specialCandyGoals: [.striped: 2],
              boardSize: (rows: 9, cols: 9),
              blockedTiles: []),
        
        Level(number: 2,
              moves: 25,
              targetScore: 2000,
              specialCandyGoals: [.striped: 3, .wrapped: 1],
              boardSize: (rows: 9, cols: 9),
              blockedTiles: [GridPosition(row: 4, col: 4)]),
        
        Level(number: 3,
              moves: 30,
              targetScore: 3000,
              specialCandyGoals: [.striped: 2, .wrapped: 2, .colorBomb: 1],
              boardSize: (rows: 9, cols: 9),
              blockedTiles: [GridPosition(row: 3, col: 3),
                            GridPosition(row: 3, col: 5),
                            GridPosition(row: 5, col: 3),
                            GridPosition(row: 5, col: 5)])
    ]
} 