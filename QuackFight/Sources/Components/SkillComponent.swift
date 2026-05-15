//
//  SkillComponent.swift
//  QuackFight
//
//  Created by Justin Chow on 08/05/26.
//

import GameplayKit

/// Pure-data component that tracks the three one-time-use skills each player owns.
///
/// ## Skill Rules (GDD §6)
///
/// - Each player starts with exactly 3 skills: `damageMultiplier`, `heal`, `fixedHit`.
/// - A skill can be activated during `AimState` or `PowerState`.
/// - Once used, the skill is permanently consumed for that match.
/// - `heal` and `fixedHit` immediately interrupt the current turn flow.
/// - `damageMultiplier` modifies the next projectile attack without interrupting.
///
class SkillComponent: GKComponent {

    /// Skills still available to the player. Consumed skills are removed from this set.
    private(set) var availableSkills: Set<SkillType> = [.damageMultiplier, .heal, .fixedHit]

    /// The skill the player has activated for this turn, or `nil` if none.
    private(set) var activeSkill: SkillType?

    // MARK: - Init

    override init() {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for SkillComponent")
    }

    // MARK: - Skill Actions

    /// Returns `true` if the given skill is still available.
    func hasSkill(_ skill: SkillType) -> Bool {
        availableSkills.contains(skill)
    }

    /// Attempt to activate a skill. Returns `true` on success, `false` if already used.
    @discardableResult
    func activate(_ skill: SkillType) -> Bool {
        guard availableSkills.contains(skill) else { return false }
        activeSkill = skill
        return true
    }

    /// Permanently consume the currently active skill.
    /// Removes it from `availableSkills` and sets `activeSkill` to `nil`.
    func consumeActive() {
        guard let skill = activeSkill else { return }
        availableSkills.remove(skill)
        activeSkill = nil
    }

    /// Clear the active skill selection without consuming it (e.g., turn cancelled).
    func clearActive() {
        activeSkill = nil
    }

    /// Restore all three skills and clear any active selection.
    /// Call at match start from `InitState`.
    func reset() {
        availableSkills = [.damageMultiplier, .heal, .fixedHit]
        activeSkill = nil
    }
}
