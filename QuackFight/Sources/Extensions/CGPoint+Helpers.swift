//
//  CGPoint+Helpers.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import CoreGraphics

extension CGPoint {
    /// Returns the Euclidean distance between this point and another point.
    func distance(to other: CGPoint) -> CGFloat {
        return hypot(self.x - other.x, self.y - other.y)
    }
    
    /// Linearly interpolates between two points.
    /// - Parameters:
    ///   - from: Starting point.
    ///   - to: Ending point.
    ///   - t: The interpolation parameter (usually 0.0 to 1.0).
    static func lerp(from: CGPoint, to: CGPoint, t: CGFloat) -> CGPoint {
        return CGPoint(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t
        )
    }
}
