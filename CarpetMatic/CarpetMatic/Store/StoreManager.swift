import Foundation
import StoreKit
import Observation

/// StoreKit 2 wrapper for the one-off Pro unlock.
/// Free tier: 1 project, no PDF export. Pro: unlimited + export.
@Observable
final class StoreManager {
    static let proProductID = "howie.one.CarpetMatic.pro"

    private(set) var proProduct: Product?
    private(set) var isPro = false
    /// True when the product failed to load (offline / store unavailable).
    private(set) var storeUnavailable = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await self.listenForTransactions() }
        Task {
            await self.loadProduct()
            await self.refreshEntitlements()
        }
    }

    func loadProduct() async {
        do {
            proProduct = try await Product.products(for: [Self.proProductID]).first
            storeUnavailable = (proProduct == nil)
        } catch {
            storeUnavailable = true
        }
    }

    func refreshEntitlements() async {
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }

    /// Returns true if the purchase completed (verified) in this call.
    @discardableResult
    func purchasePro() async throws -> Bool {
        guard let product = proProduct else { return false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return false }
            await transaction.finish()
            isPro = true
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }
}
