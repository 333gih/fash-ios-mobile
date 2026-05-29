import SwiftUI

/// Minimal trench illustration — Android `login_hero_trench` drawable.
struct FashLoginHeroTrenchIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.90, green: 0.82, blue: 0.75))
                    .frame(width: w * 0.16, height: h * 0.19)
                    .offset(y: -h * 0.28)
                RoundedRectangle(cornerRadius: w * 0.08)
                    .fill(Color(red: 0.78, green: 0.65, blue: 0.48))
                    .frame(width: w * 0.42, height: h * 0.55)
                    .offset(y: h * 0.04)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.56, green: 0.43, blue: 0.31))
                    .frame(width: w * 0.55, height: h * 0.04)
                    .offset(y: h * 0.18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
