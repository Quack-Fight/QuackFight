//
//  GameErrors.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation

enum GameErrors: LocalizedError {
    case invalidState(message: String)
    case missingComponent(message: String)
    case physicsFailure(message: String)
    case audioFailure(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidState(let message):
            return "Invalid State: \(message)"
        case .missingComponent(let message):
            return "Missing Component: \(message)"
        case .physicsFailure(let message):
            return "Physics Failure: \(message)"
        case .audioFailure(let message):
            return "Audio Failure: \(message)"
        }
    }
}
