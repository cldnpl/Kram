import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var currentTier: SubscriptionTier
    @Published private(set) var productsByTier: [SubscriptionTier: Product] = [:]
    @Published private(set) var missingProductIDs: [String] = []
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false
    @Published var statusMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        currentTier = SubscriptionTier.current

        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }

                if case .verified(let transaction) = result {
                    await transaction.finish()
                }

                await self.syncEntitlements()
            }
        }

        Task {
            await refreshProducts()
            await syncEntitlements()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func product(for tier: SubscriptionTier) -> Product? {
        productsByTier[tier]
    }

    func refreshProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: SubscriptionTier.paidProductIDs)
            var mapped: [SubscriptionTier: Product] = [:]
            let fetchedIDs = Set(products.map(\.id))
            let requestedIDs = Set(SubscriptionTier.paidProductIDs)
            missingProductIDs = Array(requestedIDs.subtracting(fetchedIDs)).sorted()

            for product in products {
                switch product.id {
                case SubscriptionTier.proProductID:
                    mapped[.pro] = product
                case SubscriptionTier.maxProductID:
                    mapped[.max] = product
                default:
                    break
                }
            }

            productsByTier = mapped

            if !missingProductIDs.isEmpty {
                statusMessage = "Products unavailable: \(missingProductIDs.joined(separator: ", "))"
            } else if mapped.isEmpty {
                statusMessage = "No subscription products were found."
            } else {
                statusMessage = nil
            }
        } catch {
            missingProductIDs = SubscriptionTier.paidProductIDs
            statusMessage = "Failed to load subscriptions: \(error.localizedDescription)"
        }
    }

    func purchase(_ tier: SubscriptionTier) async {
        guard tier != .free else {
            updateTier(.free)
            statusMessage = "Free plan active."
            return
        }

        guard let product = product(for: tier) else {
            statusMessage = "Product unavailable for \(tier.displayName)."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await syncEntitlements()
                    statusMessage = "\(currentTier.displayName) plan is now active."
                case .unverified:
                    statusMessage = "Purchase was not verified."
                }
            case .pending:
                statusMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                statusMessage = "Unknown purchase result."
            }
        } catch {
            statusMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await syncEntitlements()
            statusMessage = "Purchases restored."
        } catch {
            statusMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func syncEntitlements() async {
        var resolvedTier: SubscriptionTier = .free

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            switch transaction.productID {
            case SubscriptionTier.maxProductID:
                resolvedTier = .max
            case SubscriptionTier.proProductID where resolvedTier != .max:
                resolvedTier = .pro
            default:
                break
            }
        }

        updateTier(resolvedTier)
    }

    private func updateTier(_ tier: SubscriptionTier) {
        currentTier = tier
        tier.persistAsCurrent()
    }
}
