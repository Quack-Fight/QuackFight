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

// MARK: - SubscriptionToken

/// Opaque reference returned by `EventBus.subscribe(_:handler:)`.
///
/// Store the token in the subscribing object and pass it to
/// `EventBus.shared.unsubscribe(_:)` when the subscription is no longer needed.
///
/// States store tokens as instance properties and unsubscribe in `willExit(to:)`
/// so that each turn's event handlers are removed when the state exits, preventing
/// stale closures from firing in later turns.
///
/// ```swift
/// private var aimToken: SubscriptionToken?
///
/// override func didEnter(from previousState: GKState?) {
///     aimToken = EventBus.shared.subscribe(.aimLockConfirmed) { [weak self] _ in
///         guard let self else { return }
///         GameStateMachine.shared.enter(PowerState.self)
///     }
/// }
///
/// override func willExit(to nextState: GKState) {
///     if let token = aimToken { EventBus.shared.unsubscribe(token) }
///     aimToken = nil
/// }
/// ```
final class SubscriptionToken {
    let id: UUID = UUID()
    fileprivate init() {}
}

// MARK: - EventBus

/// Typed publish-subscribe bus for decoupling game systems.
///
/// Systems subscribe once in their `init()` or `setupSubscriptions()`.
/// States use token-based subscriptions scoped to their active lifetime.
/// Publishers call `post(_:)` to deliver events without holding direct
/// references to subscribers.
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

    // Each key maps to an array of (id, handler) pairs so individual
    // subscriptions can be removed by token without clearing everything.
    private var observers: [GameEvent.Key: [(id: UUID, handler: (GameEvent) -> Void)]] = [:]

    // NSLock guards the observer dictionary so that VoiceInputSystem's
    // background-thread posts don't race with main-thread subscriptions.
    private let lock = NSLock()

    private init() {}

    // MARK: - Subscribe

    /// Register `handler` to be called whenever an event with the given key is posted.
    ///
    /// - Returns: A `SubscriptionToken` that can be passed to `unsubscribe(_:)` to
    ///   remove this specific handler. States should store the token and unsubscribe
    ///   in `willExit(to:)`.
    /// - Always pass `[weak self]` inside `handler` to prevent retain cycles.
    @discardableResult
    func subscribe(_ key: GameEvent.Key, handler: @escaping (GameEvent) -> Void) -> SubscriptionToken {
        let token = SubscriptionToken()
        lock.withLock {
            observers[key, default: []].append((id: token.id, handler: handler))
        }
        return token
    }

    // MARK: - Unsubscribe

    /// Remove the specific handler identified by `token`.
    ///
    /// Safe to call with a token that has already been removed (no-op).
    /// Call this in `willExit(to:)` of any `GKState` that subscribed in `didEnter(from:)`.
    func unsubscribe(_ token: SubscriptionToken) {
        lock.withLock {
            for key in observers.keys {
                observers[key]?.removeAll { $0.id == token.id }
            }
        }
    }

    // MARK: - Post

    /// Deliver `event` to all handlers registered for its key.
    ///
    /// Safe to call from any thread. Handlers are always invoked on the main thread
    /// so that SpriteKit node mutations and GameplayKit state changes stay thread-safe.
    func post(_ event: GameEvent) {
        let handlers = lock.withLock { observers[event.key]?.map { $0.handler } ?? [] }
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
    /// After clearing, every system singleton must call `setupSubscriptions()`
    /// to re-register its handlers before the new match begins.
    /// `InitState.didEnter(_:)` is responsible for orchestrating that re-setup.
    func clearAllSubscriptions() {
        lock.withLock {
            observers.removeAll()
        }
    }
}
