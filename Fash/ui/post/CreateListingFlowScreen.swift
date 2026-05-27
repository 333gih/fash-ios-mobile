import SwiftUI

struct CreateListingFlowScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var postVM: PostViewModel
    @Bindable var addressVM: AddressBookViewModel
    var onClose: () -> Void = {}

    @State private var showDiscardDialog = false
    @State private var showAddAddress = false

    var body: some View {
        VStack(spacing: 0) {
            CreateListingFlowHeader(
                step: postVM.step,
                canProceed: postVM.draft.canProceedFromStep(postVM.step),
                isSubmitting: postVM.isSubmitting || postVM.isUploading,
                onBack: handleBack,
                onClose: handleCloseAttempt,
                onNext: handleNext
            )
            stepContent
        }
        .background(FashColors.screen)
        .task {
            await postVM.loadCatalogIfNeeded(deps: deps)
            await addressVM.refresh(deps: deps)
        }
        .alert(L10n.createListingDiscardTitle, isPresented: $showDiscardDialog) {
            Button(L10n.createListingDiscardConfirm, role: .destructive) {
                postVM.cancel()
                onClose()
            }
            Button(L10n.createListingDiscardCancel, role: .cancel) {}
        } message: {
            Text(L10n.createListingDiscardMessage)
        }
        .sheet(isPresented: $showAddAddress) {
            AddEditAddressScreen(
                addressVM: addressVM,
                showCatalogHint: false,
                onDismiss: { showAddAddress = false },
                onSaved: { newId in
                    showAddAddress = false
                    if let newId {
                        postVM.selectShippingAddressForListing(deps: deps, addressId: newId)
                    }
                    Task { await postVM.loadShippingAddresses(deps: deps) }
                }
            )
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch postVM.step {
        case createListingModeStep:
            CreateListingModeStep(
                onManual: { Task { await postVM.selectFillMode(deps: deps, mode: .manual) } },
                onFromProfile: { Task { await postVM.selectFillMode(deps: deps, mode: .fromProfileStyle) } }
            )
        case 1...5:
            CreateListingPostSteps(postVM: postVM, step: postVM.step)
        case 6...10:
            CreateListingPostStepsPart2(
                postVM: postVM,
                addressVM: addressVM,
                step: postVM.step,
                onAddAddress: { showAddAddress = true }
            )
        default:
            EmptyView()
        }
    }

    private func handleBack() {
        if postVM.step <= createListingModeStep {
            handleCloseAttempt()
        } else {
            postVM.prevStep()
        }
    }

    private func handleCloseAttempt() {
        if hasDraftProgress() {
            showDiscardDialog = true
        } else {
            onClose()
        }
    }

    private func handleNext() {
        if postVM.step == totalPostSteps {
            Task {
                await postVM.submitListing(deps: deps) {
                    onClose()
                }
            }
        } else {
            Task { await postVM.nextStep(deps: deps) }
        }
    }

    private func hasDraftProgress() -> Bool {
        postVM.step > createListingModeStep
            || !postVM.draft.categoryId.isEmpty
            || !postVM.draft.title.isEmpty
            || postVM.draft.listingPhotoSlots.contains { $0.hasImageSelected() }
    }
}
