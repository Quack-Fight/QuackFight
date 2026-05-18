//
//  RenderSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

//  =========================================================================
//  RENDER SYSTEM ARCHITECTURE: SINGLE WRITER RULE
//  =========================================================================
//  - Avoid Race Conditions: Allowing multiple systems to directly modify
//    `SKNode.position` creates race conditions, causing visual glitches,
//    stuttering, or flickering on the screen.
//
//  - Single Source of Truth: All positional and rotational math data lives
//    exclusively within `TransformComponent`. Other systems (like Physics)
//    must only modify this component.
//
//  - One-Way Bridge: `RenderSystem` is the strict one-way bridge from ECS
//    data to SpriteKit nodes. It runs at the very end of the frame, safely
//    applying the final `TransformComponent` data to the `SpriteComponent`'s
//    visual node.
//  =========================================================================

import SpriteKit
import GameplayKit


