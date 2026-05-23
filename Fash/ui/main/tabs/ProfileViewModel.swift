import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var displayName = ""
    func refresh() async {}
}
