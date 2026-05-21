//
//  SkillSelection.swift
//  QuackFight
//

import SpriteKit

/// A SpriteKit modal overlay for selecting a skill.
class SkillSelection: SKNode {
    
    private let container: SKNode
    private var skillButtons: [SkillType: SKSpriteNode] = [:]
    private let buttonSize: CGSize
    
    private var playerIndex: Int = 0
    private var availableSkills: Set<SkillType> = []
    
    init(size: CGSize) {
        let bottomHUDHeight = min(size.height * 0.22, 180)
        let buttonSide = min(size.width * 0.25, bottomHUDHeight * 0.58)
        buttonSize = CGSize(width: buttonSide, height: buttonSide)
        container = SKNode()
        container.zPosition = 902
        
        // Position container at bottom HUD area
        container.position = CGPoint(x: 0, y: -size.height / 2.0 + bottomHUDHeight * 0.52)
        
        super.init()
        addChild(container)
        self.isUserInteractionEnabled = true
        setupButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButtons() {
        let skills: [SkillType] = [.damageMultiplier, .heal, .fixedHit]
        let spacing = buttonSize.width + 32.0
        let startX: CGFloat = -CGFloat(skills.count - 1) * spacing / 2.0
        
        for (i, skill) in skills.enumerated() {
            let assetName = getAssetPrefix(for: skill) + "_Enabled"
            let btn = SKSpriteNode(imageNamed: assetName)
            btn.name = "skill_\(skill.rawValue)"
            btn.size = buttonSize
            btn.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 0)
            
            skillButtons[skill] = btn
            container.addChild(btn)
        }
    }
    
    private func getAssetPrefix(for skill: SkillType) -> String {
        switch skill {
        case .damageMultiplier: return "2xSkill"
        case .heal:             return "Heal"
        case .fixedHit:         return "FixedHit"
        }
    }
    
    func show(forPlayer index: Int, availableSkills: Set<SkillType>) {
        self.playerIndex = index
        self.availableSkills = availableSkills
        isHidden = false
        
        for (skill, button) in skillButtons {
            if availableSkills.contains(skill) {
                button.texture = SKTexture(imageNamed: getAssetPrefix(for: skill) + "_Enabled")
                button.alpha = 1.0
            } else {
                button.texture = SKTexture(imageNamed: getAssetPrefix(for: skill) + "_Disabled")
                button.alpha = 0.4
            }
        }
        
    }
    
    func hide() {
        isHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: container)
        let nodesAtTouch = container.nodes(at: location)
        
        for node in nodesAtTouch {
            
            if let name = node.name, name.hasPrefix("skill_") {
                let rawValue = String(name.dropFirst("skill_".count))
                if let skill = SkillType(rawValue: rawValue), availableSkills.contains(skill) {
                    EventBus.shared.post(.skillSelected(skill))
                    return
                }
            }
        }
    }
}
