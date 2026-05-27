import SwiftUI
import Kingfisher

/// Remote image with shimmer loading — Android [FashAsyncImage] / Coil.
struct FashAsyncImage: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        Group {
            if let url, !url.isEmpty, let imageURL = URL(string: url) {
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

    var body: some View {
        FashAsyncImage(url: url)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .background(FashColors.surfaceContainerHigh)
    }
}
