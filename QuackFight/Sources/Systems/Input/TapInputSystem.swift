//
//  TapInputSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit

/// Sistem untuk mengubah tap layar menjadi event game.
///
/// Penjelasan gampang:
/// - TapInputSystem tidak langsung mengganti state.
/// - Sistem ini hanya melihat konteks tap yang sedang aktif.
/// - Kalau tap valid, sistem mengirim event ke EventBus.
/// - Kalau tap tidak relevan di state sekarang, sistem diam saja.
final class TapInputSystem: GKComponentSystem<InputStateComponent> {

    static let shared = TapInputSystem()

    private override init() {
        super.init(componentClass: InputStateComponent.self)
    }

    /// Dipanggil dari `GameScene.touchesBegan`.
    ///
    /// Tap behavior:
    /// - `.aiming`      → post `.aimLocked`
    /// - `.power`       → post `.powerLocked`
    /// - `.turnHandoff` → post `.handoffDismissed`
    /// - `.none`        → no-op
    func handleTap() {
        switch GameManager.shared.tapContext {
        case .aiming:
            EventBus.shared.post(.aimLocked)

        case .power:
            EventBus.shared.post(.powerLocked)

        case .turnHandoff:
            EventBus.shared.post(.handoffDismissed)

        case .gameOver:
            // Rematch: reset everything and start a new match.
            GameManager.shared.tapContext = .none
            GameStateMachine.shared.enter(InitState.self)

        case .none:
            break
        }
    }
}
