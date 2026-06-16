import SwiftUI

struct CreateListingFlowScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var postVM: PostViewModel
    @Bindable var addressVM: AddressBookViewModel
    var onClose: () -> Void = {}

    @State private var showDiscardDialog = false
    @State private var showAddAddress = false

    var body: some View {
        Group {
            if postVM.step == createListingModeStep {
                CreateListingModeStep(postVM: postVM, onClose: handleCloseAttempt)
            } else {
                postStepsShell
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PostListingColors.stepCanvas)
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
        .onChange(of: postVM.eventMessage) { _, message in
            guard let message, !message.isEmpty else { return }
            deps.showSnackbar(message)
            postVM.eventMessage = nil
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
            .fashEdgeBackNavigation { showAddAddress = false }
        }
        .fashEdgeBackNavigation {
            handleCreateListingEdgeBack()
        }
    }

    /// Mirrors header back / system back — prev step inside the flow, discard prompt when exiting.
    private func handleCreateListingEdgeBack() {
        if showDiscardDialog {
            showDiscardDialog = false
            return
        }
        if showAddAddress {
            showAddAddress = false
            return
        }
        if postVM.step > createListingModeStep {
            postVM.prevStep()
        } else {
            handleCloseAttempt()
        }
    }

    private var postStepsShell: some View {
        VStack(spacing: 0) {
            CreateListingFlowHeader(
                step: postVM.step,
                showBack: postVM.step > 1,
                canProceed: postVM.draft.canProceedFromStep(postVM.step),
                nextBlockedReason: postVM.draft.nextStepBlockedReason(step: postVM.step),
                isSubmitting: postVM.isSubmitting || postVM.isUploading,
                onBack: { postVM.prevStep() },
                onClose: handleCloseAttempt,
                onNext: handleNext
            )
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch postVM.step {
        case 1...5:
            CreateListingPostSteps(postVM: postVM, step: postVM.step)
        case 6...11:
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
