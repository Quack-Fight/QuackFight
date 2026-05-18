//
//  RoundCounterTests.swift
//  QuackFightTests
//
//  Created by Justin Chow on 18/05/26.
//

import XCTest
@testable import QuackFight

final class RoundCounterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        RoundCounterManager.shared.reset()
    }

    /// isMatchOver must become true at exactly turn 20 and not before.
    func testMatchOverAt20() {
        XCTAssertFalse(
            RoundCounterManager.shared.isMatchOver,
            "Match should not be over before any turns have been played."
        )

        // Increment 19 times — one short of the cap.
        for _ in 1..<GameConstants.maxRounds {
            RoundCounterManager.shared.incrementTurn()
        }
        XCTAssertFalse(
            RoundCounterManager.shared.isMatchOver,
            "Match should not be over at turn \(GameConstants.maxRounds - 1)."
        )

        // The 20th increment must flip isMatchOver to true.
        RoundCounterManager.shared.incrementTurn()
        XCTAssertTrue(
            RoundCounterManager.shared.isMatchOver,
            "Match must be over once \(GameConstants.maxRounds) turns have elapsed."
        )
        XCTAssertEqual(
            RoundCounterManager.shared.turnsElapsed,
            GameConstants.maxRounds,
            "turnsElapsed must equal maxRounds (\(GameConstants.maxRounds)) after 20 increments."
        )
    }

    /// reset() must zero the turn counter and clear isMatchOver.
    func testResetClearsTurnCount() {
        for _ in 0..<GameConstants.maxRounds {
            RoundCounterManager.shared.incrementTurn()
        }
        XCTAssertTrue(RoundCounterManager.shared.isMatchOver)

        RoundCounterManager.shared.reset()

        XCTAssertEqual(RoundCounterManager.shared.turnsElapsed, 0)
        XCTAssertFalse(RoundCounterManager.shared.isMatchOver)
    }
}
