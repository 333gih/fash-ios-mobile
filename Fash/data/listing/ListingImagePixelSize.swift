import Foundation
import ImageIO

enum ListingImagePixelSize {
    static func fromImageData(_ data: Data) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return nil }
        let w = pixelDimension(props[kCGImagePropertyPixelWidth])
        let h = pixelDimension(props[kCGImagePropertyPixelHeight])
        guard let w, let h, w > 0, h > 0, w <= 32_000, h <= 32_000 else { return nil }
        return (w, h)
    }

    private static func pixelDimension(_ value: Any?) -> Int? {
        if let n = value as? Int { return n }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }
}

struct ListingImageUploadResult: Equatable {
    let url: String
    let width: Int?
    let height: Int?
}
