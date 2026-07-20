import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    @State private var purchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 8)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("CarpetMatic Pro")
                    .font(.title.bold())
                Text("One-off purchase. No subscription.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 14) {
                    benefit("infinity", "Unlimited projects")
                    benefit("square.and.arrow.up", "PDF export & sharing")
                    benefit("icloud", "Everything syncs with iCloud")
                    benefit("wrench.and.screwdriver", "All future Pro features included")
                }
                .padding(.vertical, 8)

                Spacer()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if store.storeUnavailable {
                    Text("The App Store is unavailable right now. Please try again later.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Button {
                        purchase()
                    } label: {
                        Text(purchaseTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(purchasing || store.proProduct == nil)
                }

                Button("Restore Purchases") {
                    Task {
                        await store.restorePurchases()
                        if store.isPro { dismiss() }
                    }
                }
                .font(.footnote)

                Text("Your first project is free. Pro unlocks the rest — pay once, keep it forever.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
        }
    }

    private var purchaseTitle: String {
        if purchasing { return "Purchasing…" }
        if let price = store.proProduct?.displayPrice { return "Unlock for \(price)" }
        return "Unlock"
    }

    private func benefit(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(.tint)
            Text(text)
        }
        .font(.body)
    }

    private func purchase() {
        purchasing = true
        errorMessage = nil
        Task {
            defer { purchasing = false }
            do {
                if try await store.purchasePro() {
                    dismiss()
                }
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
        }
    }
}
