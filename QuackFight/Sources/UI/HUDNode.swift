//
//  HUDNode.swift
//  QuackFight
//

import SpriteKit

/// The main UI wrapper that sits over the game scene, attached to the SKCameraNode.
class HUDNode: SKNode {
    
    // MARK: - Top HUD
    private let p1HPBarBG: SKSpriteNode
    private let p2HPBarBG: SKSpriteNode
    private let p1HPFill: SKSpriteNode
    private let p2HPFill: SKSpriteNode
    private let roundLabel: SKLabelNode
    
    // MARK: - Bottom HUD
    private let bottomBackground: SKSpriteNode
    private let timerBar: SKSpriteNode
    
    // MARK: - Active Player Glow
    private let p1Glow: SKShapeNode
    private let p2Glow: SKShapeNode
    
    init(size: CGSize) {
        let halfW = size.width / 2.0
        let halfH = size.height / 2.0
        
        // Setup HP Bars
        p1HPBarBG = SKSpriteNode(imageNamed: "Goose HP")
        p1HPBarBG.position = CGPoint(x: -halfW + 160, y: halfH - 60)
        p1HPBarBG.zPosition = 900
        
        p2HPBarBG = SKSpriteNode(imageNamed: "Duck HP")
        p2HPBarBG.position = CGPoint(x: halfW - 160, y: halfH - 60)
        // Duck HP bar is naturally facing right in the asset, if not mirror it: p2HPBarBG.xScale = -1
        p2HPBarBG.zPosition = 900
        
        p1HPFill = SKSpriteNode(color: .systemGreen, size: CGSize(width: 200, height: 24))
        p1HPFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        p1HPFill.position = CGPoint(x: p1HPBarBG.position.x - 100, y: p1HPBarBG.position.y)
        p1HPFill.zPosition = 899
        
        p2HPFill = SKSpriteNode(color: .systemGreen, size: CGSize(width: 200, height: 24))
        p2HPFill.anchorPoint = CGPoint(x: 1, y: 0.5)
        p2HPFill.position = CGPoint(x: p2HPBarBG.position.x + 100, y: p2HPBarBG.position.y)
        p2HPFill.zPosition = 899
        
        // Setup Round Label
        roundLabel = SKLabelNode(fontNamed: ".SFProRounded-Bold")
        roundLabel.fontSize = 24
        roundLabel.fontColor = .white
        roundLabel.position = CGPoint(x: 0, y: halfH - 50)
        roundLabel.zPosition = 900
        
        // Setup Bottom HUD
        bottomBackground = SKSpriteNode(imageNamed: "BG")
        bottomBackground.position = CGPoint(x: 0, y: -halfH + bottomBackground.size.height / 2)
        bottomBackground.zPosition = 900
        
        timerBar = SKSpriteNode(imageNamed: "Timer")
        timerBar.anchorPoint = CGPoint(x: 1, y: 0.5)
        timerBar.position = CGPoint(x: halfW, y: bottomBackground.position.y + bottomBackground.size.height / 2 + 10)
        timerBar.zPosition = 901
        
        // Setup Active Glows (Pulsing circles behind avatars)
        p1Glow = SKShapeNode(circleOfRadius: 60)
        p1Glow.fillColor = .systemYellow
        p1Glow.strokeColor = .clear
        p1Glow.alpha = 0.0
        p1Glow.position = CGPoint(x: p1HPBarBG.position.x - 120, y: p1HPBarBG.position.y)
        p1Glow.zPosition = 898
        
        p2Glow = SKShapeNode(circleOfRadius: 60)
        p2Glow.fillColor = .systemYellow
        p2Glow.strokeColor = .clear
        p2Glow.alpha = 0.0
        p2Glow.position = CGPoint(x: p2HPBarBG.position.x + 120, y: p2HPBarBG.position.y)
        p2Glow.zPosition = 898
        
        super.init()
        
        addChild(p1HPBarBG)
        addChild(p2HPBarBG)
        addChild(p1HPFill)
        addChild(p2HPFill)
        addChild(roundLabel)
        addChild(bottomBackground)
        addChild(timerBar)
        addChild(p1Glow)
        addChild(p2Glow)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateHP(playerIndex: Int, current: Int, max: Int) {
        let percentage = CGFloat(current) / CGFloat(max)
        let fill = playerIndex == 0 ? p1HPFill : p2HPFill
        let targetWidth = 200.0 * percentage
        fill.run(SKAction.resize(toWidth: targetWidth, duration: 0.3))
    }
    
    func updateTimer(percentage: CGFloat) {
        timerBar.xScale = max(0, percentage)
        if percentage <= 0.4 {
            timerBar.color = .systemRed
            timerBar.colorBlendFactor = 1.0
        } else {
            timerBar.colorBlendFactor = 0.0
        }
    }
    
    func updateRoundCounter(round: Int) {
        roundLabel.text = "Turn \(round)/20"
    }
    
    func showActivePlayerGlow(playerIndex: Int) {
        p1Glow.removeAllActions()
        p2Glow.removeAllActions()
        p1Glow.alpha = 0
        p2Glow.alpha = 0
        
        let glow = playerIndex == 0 ? p1Glow : p2Glow
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.8),
            SKAction.fadeAlpha(to: 0.2, duration: 0.8)
        ])
        glow.run(SKAction.repeatForever(pulse))
    }
    
    func showDamagePopup(playerIndex: Int, amount: Int) {
        let label = SKLabelNode(fontNamed: ".SFProRounded-Bold")
        label.text = "-\(amount)"
        label.fontColor = .systemRed
        label.fontSize = 36
        
        // Base it roughly around the HP bar location
        let baseX = playerIndex == 0 ? p1HPBarBG.position.x : p2HPBarBG.position.x
        let baseY = p1HPBarBG.position.y - 80
        label.position = CGPoint(x: baseX, y: baseY)
        label.zPosition = 1000
        
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([group, remove]))
    }
}
