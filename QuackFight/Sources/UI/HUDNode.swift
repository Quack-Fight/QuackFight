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
    private let hpFillMaxWidth: CGFloat
    
    // MARK: - Active Player Glow
    private let p1Glow: SKShapeNode
    private let p2Glow: SKShapeNode
    
    init(size: CGSize) {
        let halfW = size.width / 2.0
        let halfH = size.height / 2.0
        let topInset: CGFloat = 72
        let hpBarWidth = min(size.width * 0.37, 150)
        let hpBarHeight = hpBarWidth * 0.278
        let hpFillWidth = hpBarWidth * 0.62
        let hpFillHeight = hpBarHeight * 0.42
        let bottomHUDHeight = min(size.height * 0.22, 180)
        hpFillMaxWidth = hpFillWidth
        
        // Setup HP Bars
        p1HPBarBG = SKSpriteNode(imageNamed: "GooseHPBar")
        p1HPBarBG.size = CGSize(width: hpBarWidth, height: hpBarHeight)
        p1HPBarBG.position = CGPoint(x: -halfW + hpBarWidth / 2 + 24, y: halfH - topInset)
        p1HPBarBG.zPosition = 900
        
        p2HPBarBG = SKSpriteNode(imageNamed: "DuckHPBar")
        p2HPBarBG.size = CGSize(width: hpBarWidth, height: hpBarHeight)
        p2HPBarBG.position = CGPoint(x: halfW - hpBarWidth / 2 - 24, y: halfH - topInset)
        p2HPBarBG.zPosition = 900
        
        p1HPFill = SKSpriteNode(color: .systemGreen, size: CGSize(width: hpFillWidth, height: hpFillHeight))
        p1HPFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        p1HPFill.position = CGPoint(x: p1HPBarBG.position.x - hpFillWidth * 0.43, y: p1HPBarBG.position.y - 2)
        p1HPFill.zPosition = 899
        
        p2HPFill = SKSpriteNode(color: .systemGreen, size: CGSize(width: hpFillWidth, height: hpFillHeight))
        p2HPFill.anchorPoint = CGPoint(x: 1, y: 0.5)
        p2HPFill.position = CGPoint(x: p2HPBarBG.position.x + hpFillWidth * 0.43, y: p2HPBarBG.position.y - 2)
        p2HPFill.zPosition = 899
        
        // Round Cycle
        roundCycle = SKSpriteNode(imageNamed: "Cycle1")
        roundCycle.size = CGSize(width: 80, height: 80)
        roundCycle.position = CGPoint(x: 0, y: halfH - topInset - 8)
        roundCycle.zPosition = 901
        
        // Setup Round Label
        roundLabel = SKLabelNode(fontNamed: "SFProRounded-Black")
        roundLabel.text = "12"
        roundLabel.fontSize = 30
        roundLabel.fontColor = SKColor(named: "YellowQuack") ?? .systemYellow
        roundLabel.verticalAlignmentMode = .center
        roundLabel.position = roundCycle.position
        roundLabel.zPosition = 902
        
        // Setup Bottom HUD
        bottomBackground = SKSpriteNode(imageNamed: "BottomHUDBackground")
        bottomBackground.size = CGSize(width: size.width, height: bottomHUDHeight)
        bottomBackground.position = CGPoint(x: 0, y: -halfH + bottomHUDHeight / 2)
        bottomBackground.zPosition = 900
        
        timerBar = SKSpriteNode(imageNamed: "BottomHUDTimerBar")
        timerBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        timerBar.size = CGSize(width: size.width, height: bottomHUDHeight)
        timerBar.position = CGPoint(x: -halfW, y: bottomBackground.position.y)
        timerBar.zPosition = 901
        
        // Setup Active Glows (Pulsing circles behind avatars)
        p1Glow = SKShapeNode(circleOfRadius: 38)
        p1Glow.fillColor = .systemYellow
        p1Glow.strokeColor = .clear
        p1Glow.alpha = 0.0
        p1Glow.position = CGPoint(x: p1HPBarBG.position.x - hpBarWidth * 0.45, y: p1HPBarBG.position.y)
        p1Glow.zPosition = 898
        
        p2Glow = SKShapeNode(circleOfRadius: 38)
        p2Glow.fillColor = .systemYellow
        p2Glow.strokeColor = .clear
        p2Glow.alpha = 0.0
        p2Glow.position = CGPoint(x: p2HPBarBG.position.x + hpBarWidth * 0.45, y: p2HPBarBG.position.y)
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
        let targetWidth = hpFillMaxWidth * percentage
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
        roundLabel.text = "\(round)"
    }

    func updateCountdown(remaining: TimeInterval) {
        roundLabel.text = "\(max(0, Int(ceil(remaining))))"
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
