import SwiftUI

/// Horizontal marquee when label overflows — Android `basicMarquee` on listing cards.
struct FashMarqueeText: View {
    let text: String
    var font: Font = FashTypography.bodySmall
    var fontWeight: Font.Weight = .regular
    var color: Color = .white
    var lineHeight: CGFloat = 16
    var initialDelayMs: UInt64 = 900
    var repeatDelayMs: UInt64 = 1_200
    var velocity: CGFloat = 35

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var marqueeTask: Task<Void, Never>?

    private var overflow: CGFloat { max(0, textWidth - containerWidth) }
    private var shouldScroll: Bool { overflow > 1 && !text.isEmpty }

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(font.weight(fontWeight))
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .background {
                    GeometryReader { textGeo in
                        Color.clear
                            .preference(key: FashMarqueeTextWidthKey.self, value: textGeo.size.width)
                    }
                }
                .offset(x: offset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .onPreferenceChange(FashMarqueeTextWidthKey.self) { width in
                    textWidth = width
                    restartMarquee()
                }
                .onAppear {
                    containerWidth = geo.size.width
                    restartMarquee()
                }
                .onChange(of: geo.size.width) { _, width in
                    containerWidth = width
                    restartMarquee()
                }
                .onChange(of: text) { _, _ in
                    restartMarquee()
                }
                .onDisappear {
                    marqueeTask?.cancel()
                    marqueeTask = nil
                    offset = 0
                }
        }
        .frame(height: lineHeight)
        .clipped()
    }

    private func restartMarquee() {
        marqueeTask?.cancel()
        offset = 0
        guard shouldScroll else { return }

        marqueeTask = Task { @MainActor in
            while !Task.isCancelled {
                offset = 0
                try? await Task.sleep(nanoseconds: initialDelayMs * 1_000_000)
                guard !Task.isCancelled, shouldScroll else { continue }

                let duration = Double(overflow / velocity)
                withAnimation(.linear(duration: duration)) {
                    offset = -overflow
                }
                let scrollNs = UInt64(duration * 1_000_000_000)
                try? await Task.sleep(nanoseconds: scrollNs + repeatDelayMs * 1_000_000)
            }
        }
    }
}

private struct FashMarqueeTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
