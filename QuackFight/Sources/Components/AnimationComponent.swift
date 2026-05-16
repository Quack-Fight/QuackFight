//
//  AnimationComponent.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

class AnimationComponent: GKComponent {
    // Kita membuat tipe data Tuple (gabungan) untuk menyimpan aksi dan nama kuncinya
    typealias AnimationTask = (action: SKAction, key: String)
    
    // Array ini berfungsi sebagai antrean (queue)
    var animationQueue: [AnimationTask] = []
    
    override init() {
        super.init()
    }
    
    func enqueue(_ action: SKAction, key: String) {
        // Appends correctly: menambahkan animasi baru ke baris paling belakang
        let newTask = (action: action, key: key)
        animationQueue.append(newTask)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
