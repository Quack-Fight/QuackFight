//
//  VoiceInputSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

/*
 Voice Power UX Contract

 - Voice input is active only during PowerState and only writes to livePower when InputStateComponent.phase == .power.
 - Microphone RMS amplitude is normalised into a power value between 0.1 and 1.0.
 - Silence or very low input maps to minimum power (~10%) so the throw is never completely zero.
 - Loud shouting maps toward maximum power (~100%).
 - The power bar is oscillating/live, not accumulating, so players must lock the current moment fairly.
 - Tap during PowerState or 5s timeout posts/handles GameEvent.powerLocked.
 - On lock, lockedPower uses the current livePower.
 - Fallback to minimum power (~10%) is used only if livePower was never written because no valid microphone data was received.
 - After locking, the microphone input deactivates.
 - VoiceInputSystem does not change game state or update UI directly; PowerState/GameStateMachine handles transition to ThrowResolveState, and UISystem handles power bar feedback.
 */

import Foundation
