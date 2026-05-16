//
//  DamageCycleTests.swift
//  QuackFightTests
//

import XCTest
@testable import QuackFight

final class DamageCycleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DamageCycleManager.shared.reset()
    }

    func testCycleSequence() {
        // Position 0
        XCTAssertEqual(DamageCycleManager.shared.currentDamage, 10)
        XCTAssertEqual(DamageCycleManager.shared.position, 0)
        
        DamageCycleManager.shared.advance()
        
        // Position 1
        XCTAssertEqual(DamageCycleManager.shared.currentDamage, 10)
        XCTAssertEqual(DamageCycleManager.shared.position, 1)
        
        DamageCycleManager.shared.advance()
        
        // Position 2
        XCTAssertEqual(DamageCycleManager.shared.currentDamage, 15)
        XCTAssertEqual(DamageCycleManager.shared.position, 2)
        
        DamageCycleManager.shared.advance()
        
        // Position 0 (Wrapped)
        XCTAssertEqual(DamageCycleManager.shared.currentDamage, 10)
        XCTAssertEqual(DamageCycleManager.shared.position, 0)
    }
}
