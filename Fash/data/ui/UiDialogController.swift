import Foundation

@Observable
@MainActor
final class UiDialogController {
    var title: String?
    var message: String?
    var isPresented = false

    func showError(_ message: String) {
        title = L10n.dialogTitleError
        self.message = message
        isPresented = true
    }

    func showSuccess(message: String, title: String? = nil) {
        self.title = title ?? L10n.createListingSuccessDialogTitle
        self.message = message
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }
}
