import SwiftUI

struct FashGlobalDialogHost: View {
    @Environment(AppDependencies.self) private var deps

    var body: some View {
        EmptyView()
            .alert(
                deps.uiDialog.title ?? "",
                isPresented: Binding(
                    get: { deps.uiDialog.isPresented },
                    set: { if !$0 { deps.uiDialog.dismiss() } },
                ),
            ) {
                Button(L10n.dialogOk) { deps.uiDialog.dismiss() }
            } message: {
                Text(deps.uiDialog.message ?? "")
            }
    }
}
