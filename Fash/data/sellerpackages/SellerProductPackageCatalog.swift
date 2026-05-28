import Foundation

/// Local catalog fallback — Android `SellerProductPackageCatalog`.
enum SellerProductPackageCatalog {
    static func defaultPackages() -> [SellerProductPackage] {
        [starter(), growth(), premium()]
    }

    static func findByCode(_ code: String) -> SellerProductPackage? {
        defaultPackages().first { $0.code.caseInsensitiveCompare(code.trimmingCharacters(in: .whitespaces)) == .orderedSame }
    }

    private static func starter() -> SellerProductPackage {
        SellerProductPackage(
            id: "00000000-0000-4000-8000-000000000001",
            code: "seller_starter",
            name: "Gói Tiết kiệm",
            description: "Bắt đầu xác minh hàng Real/Fake và làm quen công cụ dành cho người bán.",
            priceVnd: 99_000,
            durationDays: 30,
            tier: .starter,
            isReleased: false,
            isBestSeller: false,
            badgeLabel: nil,
            active: true,
            features: [
                SellerPackageFeature(id: "authenticity_verify", included: true, highlight: "3 tin / tháng", name: nil),
                SellerPackageFeature(id: "explore_boost", included: false, highlight: nil, name: nil),
                SellerPackageFeature(id: "fanpage_spotlight", included: false, highlight: nil, name: nil),
                SellerPackageFeature(id: "social_tiktok_instagram", included: false, highlight: nil, name: nil),
            ]
        )
    }

    private static func growth() -> SellerProductPackage {
        SellerProductPackage(
            id: "00000000-0000-4000-8000-000000000002",
            code: "seller_growth",
            name: "Gói Phổ biến",
            description: "Cân bằng giá và hiển thị — phù hợp shop bán đều trên Fash.",
            priceVnd: 299_000,
            durationDays: 30,
            tier: .growth,
            isReleased: false,
            isBestSeller: true,
            badgeLabel: "Phổ biến",
            active: true,
            features: [
                SellerPackageFeature(id: "authenticity_verify", included: true, highlight: "Không giới hạn tin", name: nil),
                SellerPackageFeature(id: "explore_boost", included: true, highlight: "7 ngày ưu tiên", name: nil),
                SellerPackageFeature(id: "fanpage_spotlight", included: true, highlight: "1 bài / tháng", name: nil),
                SellerPackageFeature(id: "social_tiktok_instagram", included: false, highlight: nil, name: nil),
            ]
        )
    }

    private static func premium() -> SellerProductPackage {
        SellerProductPackage(
            id: "00000000-0000-4000-8000-000000000003",
            code: "seller_premium",
            name: "Gói Đầy đủ",
            description: "Toàn bộ tiện ích: xác minh, đẩy Khám phá, fanpage Fash và quảng bá mạng xã hội.",
            priceVnd: 699_000,
            durationDays: 30,
            tier: .premium,
            isReleased: false,
            isBestSeller: false,
            badgeLabel: "Đầy đủ",
            active: true,
            features: [
                SellerPackageFeature(id: "authenticity_verify", included: true, highlight: "Ưu tiên xử lý", name: nil),
                SellerPackageFeature(id: "explore_boost", included: true, highlight: "30 ngày", name: nil),
                SellerPackageFeature(id: "fanpage_spotlight", included: true, highlight: "4 bài / tháng", name: nil),
                SellerPackageFeature(id: "social_tiktok_instagram", included: true, highlight: "TikTok + Instagram", name: nil),
            ]
        )
    }
}
