import SwiftUI

/// Home top-bar search with an occasional gentle shake to draw attention.
struct FashAnimatedSearchIconButton: View {
    var animateHint = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let shake = animateHint ? Self.shakeAmount(at: timeline.date.timeIntervalSinceReferenceDate) : 0
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(FashColors.textPrimary)
                    .rotationEffect(.degrees(Double(shake) * 7))
                    .offset(x: shake * 1.8)
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.searchLabel)
    }

    /// Brief wiggle burst every ~5s, then rest.
    private static func shakeAmount(at time: TimeInterval) -> CGFloat {
        let cycleMs = 5200.0
        let ms = (time * 1000).truncatingRemainder(dividingBy: cycleMs)
        if ms < 4200 || ms > 4600 { return 0 }
        let t = (ms - 4200) / 400
        return sin(t * .pi * 4) * exp(-t * 2.2)
    }
}
