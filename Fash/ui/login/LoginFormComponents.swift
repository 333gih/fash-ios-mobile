import SwiftUI

private let fieldCornerRadius: CGFloat = 16
private let iconRailWidth: CGFloat = 52

struct LoginEmailFieldWithRail: View {
    @Binding var email: String
    var enabled = true
    var onSubmit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.loginEmailLabel)
                .font(FashTypography.bodyMedium.weight(.bold))
                .foregroundStyle(FashColors.textSecondary)
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FashColors.surfaceContainerLow)
                    Image(systemName: "envelope")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(FashColors.textPrimary.opacity(0.48))
                }
                .frame(width: iconRailWidth, height: 38)
                .padding(.leading, 6)
                .padding(.vertical, 8)
                TextField(L10n.loginEmailPlaceholder, text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(FashTypography.bodyLarge)
                    .foregroundStyle(FashColors.textPrimary)
                    .submitLabel(.done)
                    .onSubmit(onSubmit)
                    .disabled(!enabled)
            }
            .background(FashColors.surfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: fieldCornerRadius, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.55), lineWidth: 1)
            )
        }
    }
}

struct LoginPasswordFieldWithRail: View {
    @Binding var password: String
    var enabled = true
    var onSubmit: () -> Void = {}
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.loginPasswordLabel)
                .font(FashTypography.bodyMedium.weight(.bold))
                .foregroundStyle(FashColors.textSecondary)
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FashColors.surfaceContainerLow)
                    Image(systemName: "lock")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(FashColors.textPrimary.opacity(0.48))
                }
                .frame(width: iconRailWidth, height: 38)
                .padding(.leading, 6)
                .padding(.vertical, 8)
                Group {
                    if isVisible {
                        TextField(L10n.loginPasswordPlaceholder, text: $password)
                    } else {
                        SecureField(L10n.loginPasswordPlaceholder, text: $password)
                    }
                }
                .textContentType(.password)
                .font(FashTypography.bodyLarge)
                .foregroundStyle(FashColors.textPrimary)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                .disabled(!enabled)
                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .font(.system(size: 18))
                        .foregroundStyle(FashColors.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(!enabled)
                .accessibilityLabel(isVisible ? L10n.loginPasswordHideCd : L10n.loginPasswordShowCd)
            }
            .background(FashColors.surfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: fieldCornerRadius, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.55), lineWidth: 1)
            )
        }
    }
}

struct LoginLegalFooter: View {
    var body: some View {
        Text(legalAttributedString)
            .font(FashTypography.bodySmall)
            .foregroundStyle(FashColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var legalAttributedString: AttributedString {
        let tag = AppLocale.currentTag
        let nbsp = "\u{00A0}"
        var result = AttributedString(L10n.loginLegalPrefix.replacingOccurrences(of: "\\u00A0", with: nbsp))
        result.foregroundColor = UIColor(FashColors.textSecondary)

        var terms = AttributedString(L10n.loginTerms)
        terms.link = URL(string: AppEnvironment.legalTermsURL(languageTag: tag))
        terms.foregroundColor = UIColor(FashColors.brandPrimary)
        terms.underlineStyle = .single

        var mid = AttributedString(L10n.loginLegalAnd.replacingOccurrences(of: "\\u00A0", with: nbsp))
        mid.foregroundColor = UIColor(FashColors.textSecondary)

        var privacy = AttributedString(L10n.loginPrivacy)
        privacy.link = URL(string: AppEnvironment.legalPrivacyURL(languageTag: tag))
        privacy.foregroundColor = UIColor(FashColors.brandPrimary)
        privacy.underlineStyle = .single

        result.append(terms)
        result.append(mid)
        result.append(privacy)
        return result
    }
}

struct LoginEntranceModifier: ViewModifier {
    let progress: CGFloat
    let offsetY: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(Double(progress))
            .offset(y: (1 - progress) * offsetY)
    }
}

extension View {
    func loginEntrance(progress: CGFloat, offsetY: CGFloat) -> some View {
        modifier(LoginEntranceModifier(progress: progress, offsetY: offsetY))
    }
}

enum LoginEmailValidation {
    static func isValid(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    /// Android `maskEmailForDisplay`.
    static func maskForDisplay(_ email: String) -> String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let at = trimmed.firstIndex(of: "@"), at != trimmed.startIndex else { return trimmed }
        let local = String(trimmed[..<at])
        let domain = String(trimmed[trimmed.index(after: at)...])
        let maskedLocal: String
        if local.isEmpty {
            maskedLocal = "•••"
        } else if local.count == 1 {
            maskedLocal = "\(local.prefix(1))••"
        } else {
            maskedLocal = "\(local.prefix(1))•••\(local.suffix(1))"
        }
        return "\(maskedLocal)@\(domain)"
    }
}
