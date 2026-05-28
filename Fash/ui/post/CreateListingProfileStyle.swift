import Foundation

extension ProfileInfo {
    func hasStyleReferenceForListing() -> Bool {
        !aestheticTagSnapshots.isEmpty
            || !(referenceSize?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            || referenceMeasurementChest != nil
            || referenceMeasurementHem != nil
            || referenceMeasurementLength != nil
            || referenceMeasurementShoulders != nil
            || referenceMeasurementSleeveLength != nil
            || !gender.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

func mapProfileGenderToListingTarget(_ gender: String) -> String? {
    switch gender.trimmingCharacters(in: .whitespaces).lowercased() {
    case "women": return "women"
    case "men": return "men"
    case "non_binary": return "unisex"
    default: return nil
    }
}

private func formatMeasurementDraftValue(_ value: Double?) -> String {
    guard let value else { return "" }
    if value.truncatingRemainder(dividingBy: 1) == 0 {
        return String(Int(value))
    }
    return String(value)
}

extension CreateListingDraft {
    func applyProfileStyleIfEmpty(profile: ProfileInfo) -> CreateListingDraft {
        var next = self
        next.fillMode = .fromProfileStyle
        if selectedAestheticTagIds.isEmpty, !profile.aestheticTagSnapshots.isEmpty {
            next.selectedAestheticTagIds = Set(
                profile.aestheticTagSnapshots
                    .map(\.id)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    .prefix(maxAestheticTags)
            )
        }
        if size.trimmingCharacters(in: .whitespaces).isEmpty,
           let ref = profile.referenceSize?.trimmingCharacters(in: .whitespaces), !ref.isEmpty {
            next.size = String(ref.prefix(20))
        }
        let profileUnit = profile.referenceMeasurementUnit?.trimmingCharacters(in: .whitespaces) ?? ""
        if !profileUnit.isEmpty {
            let normalized = profileUnit.lowercased() == "in" ? "in" : "cm"
            if measurementUnit.trimmingCharacters(in: .whitespaces).isEmpty || measurementUnit == "cm" {
                next.measurementUnit = normalized
            }
        }
        if measurementHem.trimmingCharacters(in: .whitespaces).isEmpty,
           let v = formatMeasurementDraftValue(profile.referenceMeasurementHem).nonEmpty {
            next.measurementHem = v
        }
        if measurementChest.trimmingCharacters(in: .whitespaces).isEmpty,
           let v = formatMeasurementDraftValue(profile.referenceMeasurementChest).nonEmpty {
            next.measurementChest = v
        }
        if measurementLength.trimmingCharacters(in: .whitespaces).isEmpty,
           let v = formatMeasurementDraftValue(profile.referenceMeasurementLength).nonEmpty {
            next.measurementLength = v
        }
        if measurementShoulders.trimmingCharacters(in: .whitespaces).isEmpty,
           let v = formatMeasurementDraftValue(profile.referenceMeasurementShoulders).nonEmpty {
            next.measurementShoulders = v
        }
        if measurementSleeveLength.trimmingCharacters(in: .whitespaces).isEmpty,
           let v = formatMeasurementDraftValue(profile.referenceMeasurementSleeveLength).nonEmpty {
            next.measurementSleeveLength = v
        }
        if genderTarget.trimmingCharacters(in: .whitespaces).isEmpty,
           let target = mapProfileGenderToListingTarget(profile.gender) {
            next.genderTarget = target
        }
        return next
    }
}

func buildProfileStyleSummary(profile: ProfileInfo?) -> String? {
    guard let profile else { return nil }
    var parts: [String] = []
    if !profile.aestheticTagSnapshots.isEmpty {
        let names = profile.aestheticTagSnapshots.prefix(3).map { item in
            let n = item.name.trimmingCharacters(in: .whitespaces)
            return n.isEmpty ? item.id : n
        }.joined(separator: ", ")
        parts.append(L10n.postFillModeProfileTags(names))
    }
    if let size = profile.referenceSize?.trimmingCharacters(in: .whitespaces), !size.isEmpty {
        parts.append(L10n.postFillModeProfileSize(size))
    }
    if !profile.gender.isEmpty, let target = mapProfileGenderToListingTarget(profile.gender) {
        let label: String = switch target {
        case "women": L10n.genderTargetWomen
        case "men": L10n.genderTargetMen
        case "unisex": L10n.genderTargetUnisex
        default: target
        }
        parts.append(L10n.postFillModeProfileGender(label))
    }
    return parts.isEmpty ? nil : parts.joined(separator: " · ")
}

private extension String {
    var nonEmpty: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
