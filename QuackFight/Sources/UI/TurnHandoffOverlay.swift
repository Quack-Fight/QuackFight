//
//  TurnHandoffOverlay.swift
//  QuackFight
//

import SpriteKit

/// Handles full-screen instructional overlays like "Goose's Turn", "Tilt to Aim", and "Shout!"
class TurnHandoffOverlay: SKNode {
    
    private let background: SKSpriteNode
    private let titleLabel: SKLabelNode
    
    init(size: CGSize) {
        // Dark background
        background = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.6), size: size)
        
        // Title Label
        titleLabel = SKLabelNode(fontNamed: "SFProRounded-Heavy")
        titleLabel.fontSize = 64
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        
        super.init()
        
        // Z-Positioning to ensure it sits on top of everything
        self.zPosition = 1000
        self.alpha = 0.0 // Hidden by default
        
        addChild(background)
        addChild(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Shows a player turn handoff
    func show(forPlayer playerIndex: Int) {
        titleLabel.text = playerIndex == 0 ? "Goose's Turn" : "Duck's Turn"
        fadeIn()
    }
    
    /// Shows a generic instruction
    func showInstruction(_ text: String) {
        titleLabel.text = text
        fadeIn()
    }
    
    private func fadeIn() {
        removeAllActions()
        self.run(SKAction.fadeAlpha(to: 1.0, duration: 0.3))
    }
    
    /// Fades out the overlay
    func hide() {
        removeAllActions()
        self.run(SKAction.fadeAlpha(to: 0.0, duration: 0.2))
    }
}
