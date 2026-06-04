import SwiftUI

/// Reports global frames for spotlight holes — Android [FeatureTourAnchor] map.
struct FeatureTourAnchorKey: PreferenceKey {
    static var defaultValue: [FeatureTourAnchor: CGRect] = [:]

    static func reduce(value: inout [FeatureTourAnchor: CGRect], nextValue: () -> [FeatureTourAnchor: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func featureTourAnchor(_ anchor: FeatureTourAnchor, enabled: Bool) -> some View {
        background {
            if enabled {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: FeatureTourAnchorKey.self,
                        value: [anchor: proxy.frame(in: .global)]
                    )
                }
            }
        }
    }
}
