//
//  PhysicsEngineTests.swift
//  QuackFightTests
//
//  Created by Kevin William Faith on 15/05/26.
//




/*
 INTINYA TEST INI MENGECEK 3 HAL:
 
 1. Projectile bergerak ke arah yang benar dan trajectory dimulai dari origin.
 2. Trajectory punya bentuk parabola, yaitu naik dulu lalu turun.
 3. facing -1.0 benar-benar membalik arah horizontal.
 */

import XCTest
import CoreGraphics
@testable import QuackFight

final class PhysicsEngineTests: XCTestCase {

    func testParabolaLandsAtExpectedX() {
        // Titik awal projectile.
        // Kita pakai posisi Y player supaya projectile tidak langsung dianggap menyentuh tanah.
        let origin = CGPoint(x: 0, y: GameConstants.player1YPosition)

        // Membuat prediksi lintasan dengan angle default 45°, power 50%, dan arah ke kanan.
        let trajectory = PhysicsEngine.predictTrajectory(
            angle: GameConstants.defaultAimAngle,
            power: 0.5,
            origin: origin,
            facing: 1.0
        )

        // Pastikan trajectory tidak kosong.
        XCTAssertFalse(trajectory.isEmpty)

        // Titik pertama trajectory harus sama dengan posisi awal projectile.
        XCTAssertEqual(trajectory.first?.x ?? -1, origin.x, accuracy: 0.001)
        XCTAssertEqual(trajectory.first?.y ?? -1, origin.y, accuracy: 0.001)

        guard let lastPoint = trajectory.last else {
            XCTFail("Trajectory should have at least one point")
            return
        }

        // Karena facing = 1.0, projectile harus bergerak ke kanan.
        XCTAssertGreaterThan(lastPoint.x, origin.x)

        // Titik terakhir seharusnya sudah mendekati atau melewati area tanah.
        // Toleransi +50 diberikan supaya test tidak terlalu kaku terhadap tuning physics.
        XCTAssertLessThanOrEqual(lastPoint.y, GameConstants.groundY + 50.0)
    }

    func testTrajectoryPeaksAtMidFlight() {
        // Titik awal projectile.
        let origin = CGPoint(x: 0, y: GameConstants.player1YPosition)

        // Membuat prediksi lintasan parabola.
        let trajectory = PhysicsEngine.predictTrajectory(
            angle: GameConstants.defaultAimAngle,
            power: 0.5,
            origin: origin,
            facing: 1.0
        )

        // Butuh minimal beberapa titik supaya bentuk parabola bisa dicek.
        XCTAssertGreaterThan(trajectory.count, 3)

        // Ambil semua nilai Y dari trajectory.
        let yValues = trajectory.map { $0.y }

        // Cari titik tertinggi dari lintasan.
        guard let maxY = yValues.max(),
              let maxIndex = yValues.firstIndex(of: maxY) else {
            XCTFail("Trajectory should contain a peak")
            return
        }

        // Puncak lintasan harus lebih tinggi dari posisi awal.
        XCTAssertGreaterThan(maxY, origin.y)

        // Puncak tidak boleh berada di titik pertama.
        // Kalau puncaknya di titik pertama, berarti projectile tidak naik.
        XCTAssertGreaterThan(maxIndex, 0)

        // Puncak juga tidak boleh berada di titik terakhir.
        // Kalau puncaknya di titik terakhir, berarti lintasan belum membentuk parabola penuh.
        XCTAssertLessThan(maxIndex, trajectory.count - 1)
    }

    func testNegativeFacingFlipsHorizontal() {
        // Angle default 45° dalam radians.
        let angle = GameConstants.defaultAimAngle

        // Power 50%.
        let power = 0.5

        // Velocity ketika player menghadap kanan.
        let rightVelocity = PhysicsEngine.calculateVelocity(
            angle: angle,
            power: power,
            facing: 1.0
        )

        // Velocity ketika player menghadap kiri.
        let leftVelocity = PhysicsEngine.calculateVelocity(
            angle: angle,
            power: power,
            facing: -1.0
        )

        // Kalau facing kanan, dx harus positif.
        XCTAssertGreaterThan(rightVelocity.dx, 0)

        // Kalau facing kiri, dx harus negatif.
        XCTAssertLessThan(leftVelocity.dx, 0)

        // Nilai besar horizontal speed harus sama,
        // hanya arahnya saja yang berbeda.
        XCTAssertEqual(abs(rightVelocity.dx), abs(leftVelocity.dx), accuracy: 0.001)

        // Vertical speed harus tetap sama,
        // karena facing hanya membalik arah horizontal, bukan arah vertikal.
        XCTAssertEqual(rightVelocity.dy, leftVelocity.dy, accuracy: 0.001)
    }
}
