//
//  PowerBarNode.swift
//  QuackFight
//

import SpriteKit

/// A vertical meter that tracks Voice Power input.
class PowerBarNode: SKNode {
    
    private let background: SKSpriteNode
    private let fillNode: SKSpriteNode
    private let micIcon: SKSpriteNode
    
    private let maxFillHeight: CGFloat = 136.0
    private let fillWidth: CGFloat = 28.0
    
    override init() {
        // Use the asset "Voice Input"
        background = SKSpriteNode(imageNamed: "VoiceInputBar")
        background.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        background.size = CGSize(width: 58, height: 226)
        background.zPosition = 950
        
        // We use a white sprite and tint it for the fill
        fillNode = SKSpriteNode(color: .white, size: CGSize(width: fillWidth, height: 0))
        fillNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        // Position it slightly above the bottom of the background to fit within the frame visually
        fillNode.position = CGPoint(x: 0, y: 58)
        fillNode.zPosition = 951
        
        micIcon = SKSpriteNode(imageNamed: "Voice Input") // We could add a separate mic icon here if needed, but the BG might already have it.
        micIcon.isHidden = true // The background asset already has the mic on it
        
        super.init()
        
        addChild(background)
        addChild(fillNode)
        
        self.alpha = 0.0 // Hidden by default
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Updates the fill level (0.0 to 1.0) and transitions color
    func updateFill(_ value: CGFloat) {
        let clamped = max(0, min(1, value))
        fillNode.size.height = maxFillHeight * clamped
        
        // 0.0-0.4 = Green, 0.4-0.7 = Yellow, 0.7-1.0 = Red
        if clamped < 0.4 {
            fillNode.color = .systemGreen
        } else if clamped < 0.7 {
            fillNode.color = .systemYellow
        } else {
            fillNode.color = .systemRed
        }
        fillNode.colorBlendFactor = 1.0
    }

    func positionForActivePlayer(_ playerIndex: Int, viewportSize: CGSize) {
        let horizontalOffset = min(viewportSize.width * 0.34, 150)
        let x = playerIndex == 0 ? -horizontalOffset : horizontalOffset
        let y = -viewportSize.height * 0.12
        position = CGPoint(x: x, y: y)
    }
    
    func show() {
        self.run(SKAction.fadeAlpha(to: 1.0, duration: 0.2))
    }
    
    func hide() {
        self.run(SKAction.fadeAlpha(to: 0.0, duration: 0.2))
        updateFill(0)
    }
}
