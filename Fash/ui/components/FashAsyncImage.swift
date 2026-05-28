import SwiftUI
import Kingfisher

/// Remote image with shimmer loading — Android [FashAsyncImage] / Coil.
struct FashAsyncImage: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill

    private var resolvedURL: String? {
        guard let url, !url.isEmpty else { return nil }
        let resolved = FeedImageUrl.resolveListingImageUrl(url)
        return resolved.isEmpty ? nil : resolved
    }

    var body: some View {
        Group {
            if let resolvedURL, let imageURL = URL(string: resolvedURL) {
                KFImage(imageURL)
                    .fade(duration: 0.2)
                    .placeholder { FashAsyncImagePlaceholder() }
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .background(FashAsyncImageError())
            } else {
                FashAsyncImageError()
            }
        }
    }
}

private struct FashAsyncImagePlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(FashColors.surfaceContainerHigh)
            .fashShimmer()
    }
}

private struct FashAsyncImageError: View {
    var body: some View {
        Rectangle()
            .fill(FashColors.surfaceContainerHigh)
    }
}

/// Circular avatar — Android [FashAvatarCircle] default 48pt.
struct FashAvatarCircle: View {
    let url: String?
    var size: CGFloat = 48

    private var resolvedURL: String? {
        FeedImageUrl.resolveProfileImageUrlOrNil(url)
    }

    var body: some View {
        Group {
            if let resolvedURL, !resolvedURL.isEmpty {
                FashAsyncImage(url: resolvedURL)
            } else {
                FashDefaultProfileAvatar()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(FashColors.surfaceContainerHigh)
    }
}
