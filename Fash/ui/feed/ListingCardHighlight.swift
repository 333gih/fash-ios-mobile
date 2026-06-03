import SwiftUI

enum ListingCardHighlight {
    static func range(in text: String, highlight: String) -> Range<String.Index>? {
        let trimmed = highlight.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var candidates: [String] = [trimmed]
        let stripped = trimmed.hasPrefix("@") ? String(trimmed.dropFirst()) : trimmed
        if !stripped.isEmpty {
            candidates.append(stripped)
            candidates.append("@\(stripped)")
        }
        for candidate in candidates {
            if let r = text.range(of: candidate, options: .caseInsensitive) {
                return r
            }
        }
        for segment in text.components(separatedBy: " · ") {
            if segment.caseInsensitiveCompare(trimmed) == .orderedSame ||
                segment.dropFirst(segment.hasPrefix("@") ? 1 : 0)
                    .caseInsensitiveCompare(stripped) == .orderedSame {
                return text.range(of: segment, options: .caseInsensitive)
            }
        }
        return nil
    }

    static func parts(text: String, highlight: String?) -> [(String, Bool)] {
        guard let highlight,
              let range = range(in: text, highlight: highlight) else {
            return [(text, false)]
        }
        var result: [(String, Bool)] = []
        if range.lowerBound > text.startIndex {
            result.append((String(text[text.startIndex..<range.lowerBound]), false))
        }
        result.append((String(text[range]), true))
        if range.upperBound < text.endIndex {
            result.append((String(text[range.upperBound...]), false))
        }
        return result
    }
}

struct ListingCardHighlightedMarqueeText: View {
    let text: String
    var highlight: String? = nil
    var font: Font = FashTypography.bodySmall
    var fontWeight: Font.Weight = .regular
    var color: Color = .white
    var lineHeight: CGFloat = 16

    var body: some View {
        let segments = ListingCardHighlight.parts(text: text, highlight: highlight)
        if segments.count == 1, !segments[0].1 {
            ListingCardMarqueeText(
                text: text,
                font: font,
                fontWeight: fontWeight,
                color: color,
                lineHeight: lineHeight
            )
        } else {
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, part in
                    Text(part.0)
                        .font(font.weight(part.1 ? .semibold : fontWeight))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .padding(.horizontal, part.1 ? 2 : 0)
                        .padding(.vertical, part.1 ? 1 : 0)
                        .background(part.1 ? FashColors.brandPrimary.opacity(0.42) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: lineHeight, alignment: .leading)
            .lineLimit(1)
        }
    }
}
