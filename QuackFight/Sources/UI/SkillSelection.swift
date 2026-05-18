//
//  SkillSelection.swift
//  QuackFight
//

import SpriteKit

/// A SpriteKit modal overlay for selecting a skill.
class SkillSelection: SKNode {
    
    private let background: SKSpriteNode
    private let container: SKNode
    
    private var skillButtons: [SkillType: SKSpriteNode] = [:]
    private var cancelButton: SKLabelNode
    
    private var playerIndex: Int = 0
    private var availableSkills: Set<SkillType> = []
    
    init(size: CGSize) {
        // Dark background to dim the scene
        background = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.8), size: size)
        background.zPosition = 2000 // Very high to sit over HUD
        background.isUserInteractionEnabled = true // Block touches to underlying scene
        
        container = SKNode()
        container.zPosition = 2001
        
        // Cancel Button
        cancelButton = SKLabelNode(fontNamed: ".SFProRounded-Bold")
        cancelButton.text = "Skip Skill"
        cancelButton.fontSize = 32
        cancelButton.fontColor = .white
        cancelButton.position = CGPoint(x: 0, y: -150)
        cancelButton.name = "cancelButton"
        
        super.init()
        
        addChild(background)
        addChild(container)
        container.addChild(cancelButton)
        
        self.alpha = 0.0 // Hidden by default
        self.isUserInteractionEnabled = true
        
        setupButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButtons() {
        let skills: [SkillType] = [.damageMultiplier, .heal, .fixedHit]
        let spacing: CGFloat = 120.0
        let startX: CGFloat = -CGFloat(skills.count - 1) * spacing / 2.0
        
        for (i, skill) in skills.enumerated() {
            let assetName = getAssetPrefix(for: skill) + "_Enabled"
            let btn = SKSpriteNode(imageNamed: assetName)
            btn.name = "skill_\(skill.rawValue)"
            btn.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 0)
            
            skillButtons[skill] = btn
            container.addChild(btn)
        }
    }
    
    private func getAssetPrefix(for skill: SkillType) -> String {
        switch skill {
        case .damageMultiplier: return "2x"
        case .heal: return "heal"
        case .fixedHit: return "auto hit"
        }
    }
    
    func show(forPlayer index: Int, availableSkills: Set<SkillType>) {
        self.playerIndex = index
        self.availableSkills = availableSkills
        
        for (skill, button) in skillButtons {
            if availableSkills.contains(skill) {
                button.texture = SKTexture(imageNamed: getAssetPrefix(for: skill))
                button.alpha = 1.0
            } else {
                button.texture = SKTexture(imageNamed: getAssetPrefix(for: skill) + " disabled")
                button.alpha = 0.4
            }
        }
        
        self.run(SKAction.fadeAlpha(to: 1.0, duration: 0.2))
    }
    
    func hide() {
        self.run(SKAction.fadeAlpha(to: 0.0, duration: 0.2))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.alpha > 0.5, let touch = touches.first else { return }
        
        let location = touch.location(in: container)
        let nodesAtTouch = container.nodes(at: location)
        
        for node in nodesAtTouch {
            if node.name == "cancelButton" {
                hide()
                EventBus.shared.post(.skillSkipped)
                return
            }
            
            if let name = node.name, name.hasPrefix("skill_") {
                let rawValue = String(name.dropFirst("skill_".count))
                if let skill = SkillType(rawValue: rawValue), availableSkills.contains(skill) {
                    hide()
                    EventBus.shared.post(.skillSelected(skill))
                    return
                }
            }
        }
    }
}
