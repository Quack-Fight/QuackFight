# Quack Fight — Game Design Document (GDD)

This document serves as a comprehensive blueprint for the "Quack Fight" game. It outlines the core mechanics, the strict ECS technical architecture, visual rules, and hardware integrations so that the game can be recreated perfectly by another developer or AI.

---

## 1. Game Overview

**Title:** Quack Fight  
**Genre:** 1v1 Turn-Based Artillery Game (e.g., Worms, Bowmasters)  
**Platform:** iOS (iPhone)  
**Core Loop:** Players take turns aiming and throwing a projectile (bread/toaster) at each other. Aiming is controlled by physically tilting the device, and throwing power is controlled by shouting into the microphone. The last bird standing wins.

---

## 2. Technical Stack & Architecture

- **Frameworks:** SpriteKit (2D Canvas, Physics, Camera, UI Nodes), GameplayKit (ECS, State Machine), CoreMotion (Gyroscope), AVFoundation (Microphone).
- **UI Paradigm:** 100% SpriteKit. SwiftUI is **NOT** used for game overlays. UI is handled via `SKNode` subclasses (e.g., `HUDNode`, `TurnHandoffOverlay`).
- **Architectural Pattern:** Strict Entity-Component-System (ECS).
    - **Entities:** Pure identifiers/containers (e.g., `PlayerEntity`, `CameraEntity`, `BreadEntity`).
    - **Components:** Pure data objects (`HealthComponent`, `TransformComponent`, `VelocityComponent`).
    - **Systems:** Logic processors that iterate over components (`PhysicsSystem`, `DamageSystem`, `InputSystem`).
    - **State Machine:** A global `GameStateMachine` rigidly controls the flow of a single turn.
    - **Event Bus:** Centralized `EventBus` for decoupling systems (e.g., `onPlayerHit`, `onSkillUsed`).

### Directory Structure Reference

The architecture must strictly follow this folder tree:

```text
QuackFight/
├── Sources/
│   ├── App/ (QuackFightApp, AppDelegate, SceneDelegate)
│   ├── Entities/ (PlayerEntity, CameraEntity, BreadEntity)
│   ├── Components/ (Health, Skill, InputState, Sprite, Animation, Transform, Velocity, Hitbox, Camera)
│   ├── Systems/
│   │   ├── Input/ (GyroscopeSystem, VoiceInputSystem, TapInputSystem)
│   │   ├── Game/ (TurnSystem, ThrowSystem, PhysicsSystem, HitDetection, Damage, Heal, FixedHit, WinCheck)
│   │   └── Render/ (RenderSystem, AnimationSystem, TrajectoryRenderSystem, CameraSystem, UISystem)
│   ├── StateMachine/ (GameStateMachine, States: Init, PreviewPan, SkillSelect, Aim, Power, ThrowResolve, HealResolve, FixedHitResolve, TurnHandoff, RoundOver, GameOver)
│   ├── Managers/ (GameManager, DamageCycleManager, RoundCounterManager, EventBus, PhysicsEngine)
│   ├── Scenes/ (GameScene, MenuScene, GameOverScene)
│   ├── UI/ (HUDNode, PowerBarNode, TrajectoryOverlayNode, SkillSelectionViewController, TurnHandoffOverlay)
│   ├── Types/ (GameTypes, GameConstants, GameErrors)
│   └── Extensions/ (CGPoint+Helpers, GKEntity+Components, SKNode+ECS)
├── Resources/
```

---

## 3. Game State Machine (Turn Flow)

The `GameStateMachine` cycles through these states every turn:

1. **`TurnHandoffState`**: A full-screen dark overlay dims the screen showing "Player 1 Turn" or "Player 2 Turn". This auto-dismisses after a short delay (no tap required).
2. **`PreviewPanState`**: The camera pans smoothly from the opponent to the active player.
3. **`AimState`**:
    - **Duration:** 5.0 seconds.
    - **Input:** CoreMotion Gyroscope. Tilting the phone adjusts the aiming angle.
    - **Visual:** A dashed line with an arrowhead indicates trajectory (`TrajectoryRenderSystem`). A screen flash with "Tilt to Aim" auto-dismisses upon entry.
    - **Skip:** Tapping the screen locks the angle immediately.
4. **`PowerState`**:
    - **Duration:** 5.0 seconds.
    - **Input:** Microphone (`AVAudioEngine`). Shouting charges power.
    - **Visual:** A voice meter appears beside the player and scales vertically based on microphone decibels. A screen flash with "Shout!" auto-dismisses upon entry.
    - **Skip:** Tapping the screen locks the power immediately.
5. **`ThrowResolveState`**: Projectile is spawned, camera follows it, hits are detected by `HitDetectionSystem`, and damage is dealt by `DamageSystem`.
6. **`HealResolveState`**: Specific state triggered if the Heal skill is used.
7. **`FixedHitResolveState`**: Specific state triggered if the Fixed Hit skill is used.
8. **`RoundOverState` / `GameOverState`**: Evaluates win conditions.

---

## 4. Characters & Physics

- **Characters:** Player 1 ("Goose", left), Player 2 ("Duck", right, `xScale = -1`). Fixed height exactly `100px`. Static physics bodies.
- **Camera System:** Constrained strictly within the `Background` image boundaries. Hits a "hard wall" at the boundaries when tracking flying projectiles.

---

## 5. Combat, Weapons & Cycles

Damage scales based on the current round/cycle managed by `DamageCycleManager`. After the third cycle, it goes back to cycle 1.

- **Cycle 1 & 2:**
    - **Asset:** `BaseBread`
    - **Base Damage:** 10
- **Cycle 3:**
    - **Asset:** `BaseToaster`
    - **Base Damage:** 15

---

## 6. Skills

Each player has 3 one-time-use skills. They can be activated during `AimState` or `PowerState`.

1. **2x Damage (Asset: `2xSkill`)**
    - Modifies the next attack. Turn continues normally.
    - **Projectile Asset:** Changes to `Skill1Bread` (if cycle 1-2) or `Skill1Toaster` (if cycle 3).
    - **Animation:** Plays a "fire bread" or "fire toaster" animation from the projectile folder.
    - **Damage:** 20 (2x10) or 30 (2x15) depending on the cycle.

2. **Self Heal (Asset: `HealSkill`)**
    - Heals user by current weapon damage (10 or 15).
    - **Execution:** Immediately interrupts the turn and enters `HealResolveState`.
    - **Animation:** Plays an "eating the bread" animation on the player character, then skips to the next player's turn.

3. **Fixed Hit (Asset: `FixedHitSkill`)**
    - Unmissable attack that bypasses aiming/power.
    - **Execution:** Immediately interrupts the turn and enters `FixedHitResolveState`.
    - **Animation Sequence:**
        1. Camera pans to the enemy location.
        2. A "missile" spawns from outside the screen (Asset path: `projectile/FixedHitMissile` - a burning missile animation) and flies into the enemy.
        3. On impact, plays an explosion animation from `Player/Duck/Explode` or `Player/Goose/Explode`.
    - **Damage:** Applies current round damage (10 or 15).

---

## 7. User Interface (SpriteKit `UISystem`)

UI is built entirely using `SKNode` subclasses layered over the game scene.

- **Top HUD (HP Bars):**
    - **Asset:** `HUD/HPBar` provides a template border.
    - **Fill:** The actual health progress bar is drawn programmatically using SpriteKit shapes/code behind the border.
    - **Text:** Displays remaining HP (e.g., `90`) and floating damage text when hit (e.g., `-15`).
- **Bottom HUD (`HUDNode`):**
    - Full width background using the `BottomHUDBackground` asset.
    - **Timer Bar:** The `BottomHUDTimerBar` asset sits at the top of the HUD and visually shrinks from right-to-left based on remaining state time.
    - **Skill Buttons:** 3 buttons centered in the HUD. Use `2xSkill`, `HealSkill`, `FixedHitSkill`. When consumed, they switch to their `_Disabled` counterparts.
    - **No UI Text:** There are no timer numbers, angle numbers, or hint text on the bottom HUD.
- **Instruction Overlays:**
    - Auto-dismissing dark overlays handled by the `UISystem` for "Player 1/2 Turn", "Tilt to Aim", and "Shout!".
