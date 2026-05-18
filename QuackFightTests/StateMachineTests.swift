//
//  StateMachineTests.swift
//  QuackFightTests
//
//  Created by Justin Chow on 18/05/26.
//

import XCTest
import GameplayKit
@testable import QuackFight

final class StateMachineTests: XCTestCase {

    // MARK: - AimState → PowerState

    /// AimState declares PowerState as its only valid successor.
    func testValidTransition_AimState_to_PowerState() {
        let aimState = AimState()
        XCTAssertTrue(
            aimState.isValidNextState(PowerState.self),
            "AimState must allow transition to PowerState (aimLockConfirmed event path)."
        )
    }

    /// AimState must not allow a direct jump to GameOverState — no such arc exists.
    func testInvalidTransition_AimState_to_GameOverState() {
        let aimState = AimState()
        XCTAssertFalse(
            aimState.isValidNextState(GameOverState.self),
            "AimState must not allow a direct transition to GameOverState."
        )
    }

    // MARK: - PowerState transitions

    /// PowerState only allows ThrowResolveState as its successor.
    func testValidTransition_PowerState_to_ThrowResolveState() {
        let powerState = PowerState()
        XCTAssertTrue(
            powerState.isValidNextState(ThrowResolveState.self),
            "PowerState must allow transition to ThrowResolveState (powerLockConfirmed event path)."
        )
    }

    /// PowerState must not loop back to AimState — transitions are one-directional.
    func testInvalidTransition_PowerState_to_AimState() {
        let powerState = PowerState()
        XCTAssertFalse(
            powerState.isValidNextState(AimState.self),
            "PowerState must not allow transition back to AimState."
        )
    }

    // MARK: - TurnHandoffState transitions

    /// TurnHandoffState routes forward to SkillSelectState or RoundOverState only.
    func testValidTransition_TurnHandoffState_to_SkillSelectState() {
        let handoffState = TurnHandoffState()
        XCTAssertTrue(
            handoffState.isValidNextState(SkillSelectState.self),
            "TurnHandoffState must allow transition to SkillSelectState (turn continues)."
        )
    }

    func testValidTransition_TurnHandoffState_to_RoundOverState() {
        let handoffState = TurnHandoffState()
        XCTAssertTrue(
            handoffState.isValidNextState(RoundOverState.self),
            "TurnHandoffState must allow transition to RoundOverState (round cap reached)."
        )
    }

    /// TurnHandoffState must not allow a direct skip to GameOverState.
    func testInvalidTransition_TurnHandoffState_to_GameOverState() {
        let handoffState = TurnHandoffState()
        XCTAssertFalse(
            handoffState.isValidNextState(GameOverState.self),
            "TurnHandoffState must not allow a direct transition to GameOverState."
        )
    }
}
