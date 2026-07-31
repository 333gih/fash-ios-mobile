import SwiftUI

/// Modal showing detailed measurements for a listing with size match context
struct MeasurementPreviewModal: View {
    let item: ListingWithMatch
    let onDismiss: () -> Void
    let onAddToCart: () -> Void
    
    @Environment(\.fashSpacing) private var spacing
    @State private var selectedMeasurementTab: MeasurementTab = .garment
    
    enum MeasurementTab: String, CaseIterable {
        case garment = "Garment"
        case yourProfile = "Your Profile"
        case comparison = "Comparison"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Size & Fit Details")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(spacing.spacing4)
            
            // Size match badge (if available)
            if let sizeMatch = item.sizeMatch {
                HStack(spacing: spacing.spacing2) {
                    Image(systemName: sizeMatchIcon(sizeMatch.badge))
                        .foregroundColor(sizeMatchColor(sizeMatch.badge))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(SizeMatchBadge(rawValue: sizeMatch.badge)?.displayText ?? sizeMatch.badge)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(sizeMatch.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(sizeMatch.confidence * 100))% match")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(spacing.spacing3)
                .background(sizeMatchColor(sizeMatch.badge).opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, spacing.spacing4)
                .padding(.bottom, spacing.spacing3)
            }
            
            // Tab selector
            Picker("Measurement View", selection: $selectedMeasurementTab) {
                ForEach(MeasurementTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, spacing.spacing4)
            .padding(.bottom, spacing.spacing3)
            
            Divider()
            
            // Tab content
            ScrollView {
                switch selectedMeasurementTab {
                case .garment:
                    GarmentMeasurementsView(
                        measurements: item.measurements ?? [:],
                        listingSize: item.listing.size
                    )
                case .yourProfile:
                    YourProfileMeasurementsView()
                case .comparison:
                    ComparisonView(
                        garmentMeasurements: item.measurements ?? [:],
                        sizeMatch: item.sizeMatch
                    )
                }
            }
            
            Divider()
            
            // CTA buttons
            VStack(spacing: spacing.spacing3) {
                Button(action: onAddToCart) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Add to Cart")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, spacing.spacing3)
                    .background(Color.fashPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: onDismiss) {
                    Text("Continue Shopping")
                        .fontWeight(.medium)
                        .foregroundColor(.fashPrimary)
                }
            }
            .padding(spacing.spacing4)
        }
        .background(Color.fashBackground)
    }
    
    private func sizeMatchIcon(_ badge: String) -> String {
        switch SizeMatchBadge(rawValue: badge) {
        case .yourSize: return "checkmark.circle.fill"
        case .closeFit: return "info.circle.fill"
        case .sizeUp: return "arrow.up.circle.fill"
        case .sizeDown: return "arrow.down.circle.fill"
        case .none: return "questionmark.circle.fill"
        }
    }
    
    private func sizeMatchColor(_ badge: String) -> Color {
        switch SizeMatchBadge(rawValue: badge) {
        case .yourSize: return .green
        case .closeFit: return .blue
        case .sizeUp, .sizeDown: return .orange
        case .none: return .gray
        }
    }
}

// MARK: - Garment Measurements View

struct GarmentMeasurementsView: View {
    let measurements: [String: Double]
    let listingSize: String?
    @Environment(\.fashSpacing) private var spacing
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing4) {
            if let size = listingSize {
                HStack {
                    Text("Listed Size:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(size)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, spacing.spacing4)
            }
            
            if measurements.isEmpty {
                VStack(spacing: spacing.spacing3) {
                    Image(systemName: "ruler")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No measurements available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("This seller hasn't provided detailed measurements yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, spacing.spacing6)
            } else {
                ForEach(Array(measurements.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                    MeasurementRow(
                        label: formatMeasurementKey(key),
                        value: "\(Int(value)) cm"
                    )
                }
                .padding(.horizontal, spacing.spacing4)
            }
        }
        .padding(.vertical, spacing.spacing3)
    }
    
    private func formatMeasurementKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Your Profile Measurements View

struct YourProfileMeasurementsView: View {
    @Environment(\.fashSpacing) private var spacing
    @State private var profileMeasurements: [String: Double] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing4) {
            if profileMeasurements.isEmpty {
                VStack(spacing: spacing.spacing3) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.fashPrimary)
                    
                    Text("Complete your size profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Add your measurements to get accurate size recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, spacing.spacing6)
                    
                    Button(action: {
                        // Open profile setup
                    }) {
                        Text("Set Up Profile")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, spacing.spacing4)
                            .padding(.vertical, spacing.spacing2)
                            .background(Color.fashPrimary)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, spacing.spacing6)
            } else {
                ForEach(Array(profileMeasurements.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                    MeasurementRow(
                        label: formatMeasurementKey(key),
                        value: "\(Int(value)) cm"
                    )
                }
                .padding(.horizontal, spacing.spacing4)
            }
        }
        .padding(.vertical, spacing.spacing3)
        .onAppear {
            loadProfileMeasurements()
        }
    }
    
    private func loadProfileMeasurements() {
        // TODO: Load from user profile
        profileMeasurements = [:]
    }
    
    private func formatMeasurementKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Comparison View

struct ComparisonView: View {
    let garmentMeasurements: [String: Double]
    let sizeMatch: SizeMatchInfo?
    @Environment(\.fashSpacing) private var spacing
    @State private var profileMeasurements: [String: Double] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing4) {
            if profileMeasurements.isEmpty {
                VStack(spacing: spacing.spacing3) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("Add your measurements to compare")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, spacing.spacing6)
            } else {
                ForEach(Array(garmentMeasurements.sorted(by: { $0.key < $1.key })), id: \.key) { key, garmentValue in
                    if let profileValue = profileMeasurements[key] {
                        ComparisonRow(
                            label: formatMeasurementKey(key),
                            garmentValue: garmentValue,
                            profileValue: profileValue
                        )
                    }
                }
                .padding(.horizontal, spacing.spacing4)
            }
        }
        .padding(.vertical, spacing.spacing3)
        .onAppear {
            loadProfileMeasurements()
        }
    }
    
    private func loadProfileMeasurements() {
        // TODO: Load from user profile
        profileMeasurements = [:]
    }
    
    private func formatMeasurementKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Helper Views

struct MeasurementRow: View {
    let label: String
    let value: String
    @Environment(\.fashSpacing) private var spacing
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, spacing.spacing2)
    }
}

struct ComparisonRow: View {
    let label: String
    let garmentValue: Double
    let profileValue: Double
    @Environment(\.fashSpacing) private var spacing
    
    private var difference: Double {
        garmentValue - profileValue
    }
    
    private var differenceColor: Color {
        let absDiff = abs(difference)
        if absDiff < 2 { return .green }
        if absDiff < 5 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing1) {
            Text(label)
                .font(.subheadline)
            
            HStack(spacing: spacing.spacing3) {
                // Garment measurement
                VStack(alignment: .leading, spacing: 2) {
                    Text("Garment")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(garmentValue)) cm")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                // Difference indicator
                Image(systemName: difference > 0 ? "arrow.up" : difference < 0 ? "arrow.down" : "equal")
                    .font(.caption)
                    .foregroundColor(differenceColor)
                
                // Profile measurement
                VStack(alignment: .leading, spacing: 2) {
                    Text("You")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(profileValue)) cm")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Difference value
                Text("\(difference > 0 ? "+" : "")\(Int(difference)) cm")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(differenceColor)
            }
        }
        .padding(.vertical, spacing.spacing2)
        .padding(.horizontal, spacing.spacing3)
        .background(differenceColor.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    MeasurementPreviewModal(
        item: ListingWithMatch(
            listing: ListingFeedItem(
                id: "123",
                title: "Test Item",
                coverImageURL: "",
                price: 100000,
                size: "M",
                brand: "Test Brand",
                condition: "Like New",
                isLiked: false,
                isSaved: false,
                isFollowing: false,
                sellerId: "seller1",
                sellerUsername: "testseller",
                sellerAvatar: nil,
                category: "Tops",
                location: "HCM",
                createdAt: ""
            ),
            sizeMatch: SizeMatchInfo(
                badge: "your_size",
                confidence: 0.92,
                reason: "Matches your chest and shoulder measurements"
            ),
            measurements: [
                "chest": 96.0,
                "shoulder": 44.0,
                "length": 68.0,
                "sleeve": 22.0
            ],
            recommendReason: "Perfect fit for your size profile",
            imageAspectRatio: "3:4"
        ),
        onDismiss: {},
        onAddToCart: {}
    )
}
