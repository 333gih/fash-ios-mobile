import SwiftUI
import Kingfisher

/// Remote image (Android Coil [FashAsyncImage] equivalent).
struct FashAsyncImage: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        Group {
            if let url, let imageURL = URL(string: url) {
                KFImage(imageURL)
                    .resizable()
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(FashColors.surfaceContainer)
                    }
                    .aspectRatio(contentMode: contentMode)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(FashColors.surfaceContainer)
            }
        }
    }
}
