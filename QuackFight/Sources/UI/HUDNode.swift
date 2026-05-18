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
    private let roundCycle: SKSpriteNode
    
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
        p1HPBarBG = SKSpriteNode(imageNamed: "GooseHPBar")
        p1HPBarBG.position = CGPoint(x: -halfW + 95, y:halfH - 80)
        p1HPBarBG.setScale(0.3)
        p1HPBarBG.zPosition = 900
        
        p2HPBarBG = SKSpriteNode(imageNamed: "DuckHPBar")
        p2HPBarBG.position = CGPoint(x: halfW - 95, y: halfH - 80)
        p2HPBarBG.setScale(0.3)
        p2HPBarBG.zPosition = 900
        
        p1HPFill = SKSpriteNode(color: .systemGreen, size: CGSize(width: 140, height: 30))
        p1HPFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        p1HPFill.position = CGPoint(x: p1HPBarBG.position.x - 50, y: p1HPBarBG.position.y - 5)
        p1HPFill.zPosition = 899
        
        p2HPFill = SKSpriteNode(color: .systemGreen, size: CGSize(width: 140, height: 30))
        p2HPFill.anchorPoint = CGPoint(x: 1, y: 0.5)
        p2HPFill.position = CGPoint(x: p2HPBarBG.position.x + 50, y: p2HPBarBG.position.y - 5)
        p2HPFill.zPosition = 899
        
        // Round Cycle
        roundCycle = SKSpriteNode(imageNamed: "Cycle1")
        roundCycle.position = CGPoint(x: 0, y: halfH - 90)
        roundCycle.setScale(0.2)
        roundCycle.zPosition = 901
        
        // Setup Round Label
        roundLabel = SKLabelNode(fontNamed: "SFProRounded-Black")
        roundLabel.text = "12"
        roundLabel.fontSize = 24
        roundLabel.fontColor = .yellowQuack
        roundLabel.position = CGPoint(x: roundCycle.position.x, y: roundCycle.position.y - 28)
        roundLabel.zPosition = 902
        
        // Group Top HUD Position
        let modifyX: CGFloat = 0
        let modifyY: CGFloat = -20
        p1HPBarBG.position.x += modifyX
        p2HPBarBG.position.x += modifyX
        p1HPFill.position.x += modifyX
        p2HPFill.position.x += modifyX
        roundCycle.position.x += modifyX
        p1HPBarBG.position.y += modifyY
        p2HPBarBG.position.y += modifyY
        p1HPFill.position.y += modifyY
        p2HPFill.position.y += modifyY
        roundCycle.position.y += modifyY
        
        
        // Setup Bottom HUD
        bottomBackground = SKSpriteNode(imageNamed: "BottomHUDBackground")
        bottomBackground.position = CGPoint(x: 0, y: -halfH + bottomBackground.size.height / 4)
        bottomBackground.setScale(0.5)
        bottomBackground.zPosition = 900
        
        timerBar = SKSpriteNode(imageNamed: "BottomHUDTimerBar")
//        timerBar.anchorPoint = CGPoint(x: 1, y: 0.5)
        timerBar.position = CGPoint(x: bottomBackground.position.x, y: bottomBackground.position.y)
        timerBar.setScale(0.5)
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
        addChild(roundCycle)
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
