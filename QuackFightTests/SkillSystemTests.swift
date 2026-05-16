//
//  SkillSystemTests.swift
//  QuackFightTests
//

import XCTest
@testable import QuackFight
import GameplayKit

final class SkillSystemTests: XCTestCase {

    var p1: PlayerEntity!
    var p2: PlayerEntity!
    
    // We mock a scene environment for the systems
    override func setUp() {
        super.setUp()
        DamageCycleManager.shared.reset()
        
        p1 = PlayerEntity(index: 0, throwOrigin: .zero, facing: 1)
        p2 = PlayerEntity(index: 1, throwOrigin: .zero, facing: -1)
        
        // Ensure starting HP is max
        p1.component(ofType: HealthComponent.self)?.heal(GameConstants.maxHP)
        p2.component(ofType: HealthComponent.self)?.heal(GameConstants.maxHP)
        
        // Ensure skills are reset
        p1.component(ofType: SkillComponent.self)?.reset()
        p2.component(ofType: SkillComponent.self)?.reset()
        
        // Manually register players without a full SKScene
        // Using a dummy GameScene isn't needed here if we don't spawn PhysicsEntity
        // but GameManager needs them to process damage.
        GameManager.shared.registerPlayers(p1, p2, scene: GameScene(size: CGSize(width: 800, height: 600)))
        
        // Since active player is initially index 0 (p1), we use p1 as active.
        _ = DamageSystem(player1: p1, player2: p2)
    }

    func testDamageMultiplierDoublesDamage() {
        // Base damage at position 0 is 10.
        XCTAssertEqual(DamageCycleManager.shared.currentDamage, 10)
        
        // Activate Damage Multiplier
        let skillComp = p1.component(ofType: SkillComponent.self)!
        skillComp.activate(.damageMultiplier)
        
        // Manually trigger the damage system via EventBus
        EventBus.shared.post(.throwResolved(hit: true))
        
        // P2 should take 20 damage (10 * 2)
        let p2Health = p2.component(ofType: HealthComponent.self)!
        XCTAssertEqual(p2Health.hp, GameConstants.maxHP - 20)
    }

    func testHealCapsAtMaxHP() {
        let p1Health = p1.component(ofType: HealthComponent.self)!
        
        // Damage P1 slightly so they are at 95 HP
        p1Health.takeDamage(5)
        XCTAssertEqual(p1Health.hp, GameConstants.maxHP - 5)
        
        // Activate Heal (Heals 10)
        let skillComp = p1.component(ofType: SkillComponent.self)!
        skillComp.activate(.heal)
        
        // Execute heal system
        HealSystem.shared.applyHeal()
        
        // P1 should be capped at maxHP, not maxHP + 5
        XCTAssertEqual(p1Health.hp, GameConstants.maxHP)
    }

    func testFixedHitDealsBaseDamage() {
        // Base damage at position 0 is 10.
        XCTAssertEqual(DamageCycleManager.shared.currentDamage, 10)
        
        // Activate Fixed Hit
        let skillComp = p1.component(ofType: SkillComponent.self)!
        skillComp.activate(.fixedHit)
        
        // Execute fixed hit
        FixedHitSystem.shared.applyFixedHit()
        
        // P2 should take exactly 10 damage
        let p2Health = p2.component(ofType: HealthComponent.self)!
        XCTAssertEqual(p2Health.hp, GameConstants.maxHP - 10)
    }

    func testConsumedSkillUnavailable() {
        let skillComp = p1.component(ofType: SkillComponent.self)!
        
        XCTAssertTrue(skillComp.hasSkill(.heal))
        skillComp.activate(.heal)
        
        HealSystem.shared.applyHeal()
        
        XCTAssertFalse(skillComp.hasSkill(.heal))
        XCTAssertNil(skillComp.activeSkill)
    }
}
