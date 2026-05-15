//
//  EventBus.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 12/05/26.
//

import Foundation

/// Centralized EventBus for decoupling game systems.
///
/// **Feedback Contract**: The following events drive visible UI changes and MUST be observed by `HUDNode` or `GameScene`:
/// - `damageApplied`: Triggers red HP flash for 0.4s and spawning of a floating damage popup.
/// - `healApplied`: Triggers green HP flash for 0.4s and HP bar fill increment.
/// - `cycleAdvanced`: Updates any base damage labels or weapon indicators.
/// - `turnChanged`: Pulses active player's HUD side and dims screen with "Player X Turn".
/// - `skillSelected`: Grays out the used skill icon for 0.3s and makes it non-interactive.
/// - `timerTick`: Visually shrinks the timer bar from right to left; turns red at <= 2s.
class EventBus {
    static let shared = EventBus()
    
    // Simple closure-based subscription
    private var observers: [String: [(GameEvent) -> Void]] = [:]
    
    private init() {}
    
    func subscribe(to eventType: String, closure: @escaping (GameEvent) -> Void) {
        if observers[eventType] == nil {
            observers[eventType] = []
        }
        observers[eventType]?.append(closure)
    }
    
    func publish(_ event: GameEvent) {
        let eventType = String(describing: event).components(separatedBy: "(").first ?? ""
        observers[eventType]?.forEach { $0(event) }
    }
    
    func clearAll() {
        observers.removeAll()
    }
}
