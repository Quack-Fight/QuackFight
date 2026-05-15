//
//  EventBus.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 12/05/26.
//

import Foundation

// MARK: - Retain-Cycle Risk & [weak self] Contract
//
// EventBus.shared is a singleton — it is never deallocated.
// Every closure stored in `observers` is held strongly by the dictionary.
//
// If a subscriber captures `self` STRONGLY:
//
//   EventBus.shared.subscribe(.turnEnded) { self.doSomething() }
//
// A reference cycle forms:
//
//   EventBus (singleton, lives forever)
//       └─► observers[.turnEnded][n]   ← strong closure
//               └─► self (the system)  ← strong capture
//
// Because EventBus holds the closure and the closure holds the system,
// the system's retain count can never reach zero — it leaks forever,
// even after it has been logically removed from the game.
//
// Breaking the cycle with [weak self]:
//
//   EventBus.shared.subscribe(.turnEnded) { [weak self] event in
//       guard let self else { return }
//       self.doSomething()
//   }
//
// Now the closure holds only a WEAK reference. If nothing else references
// the system, its retain count reaches zero, it deallocates normally, and
// the closure becomes a safe no-op (self is nil, guard exits early).
//
// RULE: Every EventBus subscriber MUST use [weak self].
//
// THREADING NOTE:
// `post(_:)` dispatches handlers on the main thread when called from a
// background thread (e.g., AVAudioEngine tap in VoiceInputSystem).
// All SpriteKit and GameplayKit mutations must happen on the main thread.

/// Typed publish-subscribe bus for decoupling game systems.
///
/// Systems subscribe once in their `init()`. States post events to trigger
/// reactions across systems without holding direct references to each other.
///
/// ```swift
/// // Subscriber (in system init):
/// EventBus.shared.subscribe(.damageApplied) { [weak self] event in
///     guard let self, case .damageApplied(let amount, let target) = event else { return }
///     self.updateBar(amount, target)
/// }
///
/// // Publisher (in a system or state):
/// EventBus.shared.post(.damageApplied(amount: 20, to: 1))
/// ```
final class EventBus {

    static let shared = EventBus()

    // Dictionary keyed on GameEvent.Key → array of handler closures.
    // An array per key supports multiple independent subscribers (e.g., both
    // WinCheckSystem and UISystem subscribe to .damageApplied).
    private var observers: [GameEvent.Key: [(GameEvent) -> Void]] = [:]

    // NSLock guards the observer dictionary so that VoiceInputSystem's
    // background-thread posts don't race with main-thread subscriptions.
    private let lock = NSLock()

    private init() {}

    // MARK: - Subscribe

    /// Register `handler` to be called whenever an event with the given key is posted.
    ///
    /// - Always pass `[weak self]` inside `handler` to prevent retain cycles.
    /// - Call this once, in the subscriber's `init()`.
    func subscribe(_ key: GameEvent.Key, handler: @escaping (GameEvent) -> Void) {
        lock.withLock {
            observers[key, default: []].append(handler)
        }
    }

    // MARK: - Post

    /// Deliver `event` to all handlers registered for its key.
    ///
    /// Safe to call from any thread. Handlers are always invoked on the main thread
    /// so that SpriteKit node mutations and GameplayKit state changes stay thread-safe.
    func post(_ event: GameEvent) {
        let handlers = lock.withLock { observers[event.key] ?? [] }
        guard !handlers.isEmpty else { return }

        if Thread.isMainThread {
            handlers.forEach { $0(event) }
        } else {
            DispatchQueue.main.async {
                handlers.forEach { $0(event) }
            }
        }
    }

    // MARK: - Clear

    /// Remove all subscriptions. Called by `InitState` at match reset.
    ///
    /// Systems subscribe in `init()` and are singletons, so after calling this
    /// each system must call `setupSubscriptions()` to re-register its handlers.
    /// `GameStateMachine` is responsible for orchestrating that re-setup via
    /// `InitState.didEnter(_:)`.
    func clearAllSubscriptions() {
        lock.withLock {
            observers.removeAll()
        }
    }
}
