import Foundation
import Observation
import SwiftUI

/// Tracks cold-start / launch prefetch progress for [FashWaitingScreen].
@Observable
@MainActor
final class LaunchWaitingProgress {
    private(set) var fraction: Double = 0
    private(set) var isActive = false

    private var homeStepTotal = 0
    private var exploreStepTotal = 0
    private var homeStepsDone = 0
    private var exploreStepsDone = 0
    private var splashBaseline: Double = 0

    func reset() {
        fraction = 0
        isActive = false
        homeStepTotal = 0
        exploreStepTotal = 0
        homeStepsDone = 0
        exploreStepsDone = 0
        splashBaseline = 0
    }

    func beginSplash() {
        isActive = true
        apply(0.04)
    }

    func markSplash(_ value: Double) {
        isActive = true
        splashBaseline = min(1, max(splashBaseline, value))
        apply(splashBaseline)
    }

    func beginWarmup(homeSteps: Int, exploreSteps: Int) {
        isActive = true
        homeStepTotal = max(1, homeSteps)
        exploreStepTotal = max(1, exploreSteps)
        homeStepsDone = 0
        exploreStepsDone = 0
        if splashBaseline > 0 {
            apply(splashBaseline)
        } else {
            apply(0.06)
        }
    }

    func completeHomeStep() {
        guard homeStepTotal > 0 else { return }
        homeStepsDone = min(homeStepTotal, homeStepsDone + 1)
        applyWarmupFraction()
    }

    func completeExploreStep() {
        guard exploreStepTotal > 0 else { return }
        exploreStepsDone = min(exploreStepTotal, exploreStepsDone + 1)
        applyWarmupFraction()
    }

    func complete() {
        isActive = true
        apply(1)
        isActive = false
    }

    private func applyWarmupFraction() {
        let homePart = Double(homeStepsDone) / Double(homeStepTotal)
        let explorePart = Double(exploreStepsDone) / Double(exploreStepTotal)
        let warmupSpan = 1 - splashBaseline
        let warmupProgress = 0.5 * homePart + 0.5 * explorePart
        apply(splashBaseline + warmupSpan * warmupProgress)
    }

    private func apply(_ value: Double) {
        let clamped = min(1, max(0, value))
        guard abs(clamped - fraction) > 0.001 else { return }
        withAnimation(.easeOut(duration: 0.28)) {
            fraction = clamped
        }
    }
}
