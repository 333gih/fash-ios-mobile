import SwiftUI

private struct FeedCellScrollFrame: Equatable {
    let index: Int
    let minY: CGFloat
    let maxY: CGFloat
}

private struct FeedCellScrollVisibilityKey: PreferenceKey {
    static var defaultValue: [Int: FeedCellScrollFrame] = [:]

    static func reduce(value: inout [Int: FeedCellScrollFrame], nextValue: () -> [Int: FeedCellScrollFrame]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Reports cell index + vertical span in a named scroll space for scroll-position prefetch.
    func feedCellScrollVisibility(index: Int, coordinateSpace: String) -> some View {
        background {
            GeometryReader { geo in
                let frame = geo.frame(in: .named(coordinateSpace))
                Color.clear.preference(
                    key: FeedCellScrollVisibilityKey.self,
                    value: [
                        index: FeedCellScrollFrame(
                            index: index,
                            minY: frame.minY,
                            maxY: frame.maxY
                        ),
                    ]
                )
            }
            .allowsHitTesting(false)
        }
    }

    /// Prefetches when the last visible listing index is within [threshold] of the feed end — Android `snapshotFlow`.
    func feedScrollPrefetch(
        coordinateSpace: String,
        itemCount: Int,
        threshold: Int = 3,
        scrollAnchorMinY: CGFloat,
        enabled: Bool,
        isLoadingMore: Bool,
        onPrefetch: @escaping () -> Void
    ) -> some View {
        modifier(
            FeedScrollPrefetchModifier(
                coordinateSpace: coordinateSpace,
                itemCount: itemCount,
                threshold: threshold,
                scrollAnchorMinY: scrollAnchorMinY,
                enabled: enabled,
                isLoadingMore: isLoadingMore,
                onPrefetch: onPrefetch
            )
        )
    }
}

private struct FeedScrollPrefetchModifier: ViewModifier {
    let coordinateSpace: String
    let itemCount: Int
    let threshold: Int
    let scrollAnchorMinY: CGFloat
    let enabled: Bool
    let isLoadingMore: Bool
    let onPrefetch: () -> Void

    @State private var lastPrefetchItemCount = 0
    @State private var lastVisibleFrames: [Int: FeedCellScrollFrame] = [:]
    @State private var lastScrollAnchorMinY: CGFloat = 0
    @State private var debounceTask: Task<Void, Never>?

    private var viewportHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(FeedCellScrollVisibilityKey.self) { frames in
                lastVisibleFrames = frames
                schedulePrefetchEvaluation()
            }
            .onChange(of: scrollAnchorMinY) { _, newValue in
                guard abs(newValue - lastScrollAnchorMinY) > 24 else { return }
                lastScrollAnchorMinY = newValue
                schedulePrefetchEvaluation()
            }
            .onChange(of: itemCount) { _, _ in
                lastPrefetchItemCount = 0
            }
            .onChange(of: isLoadingMore) { wasLoading, loading in
                if wasLoading, !loading {
                    lastPrefetchItemCount = 0
                }
            }
            .onDisappear {
                debounceTask?.cancel()
            }
    }

    private func schedulePrefetchEvaluation() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
            evaluatePrefetch(frames: lastVisibleFrames)
        }
    }

    private func evaluatePrefetch(frames: [Int: FeedCellScrollFrame]) {
        guard enabled, !isLoadingMore, itemCount > 0 else { return }

        let scrollOffset = max(0, -scrollAnchorMinY)
        let visibleTop = scrollOffset
        let visibleBottom = scrollOffset + viewportHeight

        let lastVisibleIndex = frames.values
            .filter { frame in
                frame.maxY > visibleTop && frame.minY < visibleBottom
            }
            .map(\.index)
            .max() ?? -1

        guard lastVisibleIndex >= 0 else { return }
        guard lastVisibleIndex >= itemCount - threshold else { return }
        guard lastPrefetchItemCount != itemCount else { return }

        lastPrefetchItemCount = itemCount
        onPrefetch()
    }
}
