import Foundation
import FirebaseAuth
import StoreKit
import UIKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var currentTier: SubscriptionTier
    @Published private(set) var productsByTier: [SubscriptionTier: Product] = [:]
    @Published private(set) var missingProductIDs: [String] = []
    @Published var isLoadingProducts = false
    @Published var isPurchasing = false
    @Published var statusMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?
    private let apiClient = APIClient()

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
            // Breve ritardo per permettere al primo frame (launch) di essere disegnato prima di StoreKit.
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 s
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
        guard !isLoadingProducts else {
            return
        }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let requestedIDs = SubscriptionTier.paidProductIDs
            print("[StoreKit] Requesting products: \(requestedIDs)")
            let products = try await Product.products(for: requestedIDs)
            print("[StoreKit] Received \(products.count) products: \(products.map { "\($0.id) (\($0.displayPrice))" })")
            var mapped: [SubscriptionTier: Product] = [:]
            let fetchedIDs = Set(products.map(\.id))
            let missingRequiredIDs = Set([SubscriptionTier.premiumProductID]).subtracting(fetchedIDs)
            missingProductIDs = Array(missingRequiredIDs).sorted()

            for product in products {
                if product.id == SubscriptionTier.premiumProductID {
                    mapped[.premium] = product
                }
            }

            productsByTier = mapped

            if !missingProductIDs.isEmpty {
                statusMessage = "Subscription unavailable in the App Store: \(missingProductIDs.joined(separator: ", "))"
            } else if mapped.isEmpty {
                statusMessage = "No subscription products were found."
            } else {
                statusMessage = nil
            }
        } catch {
            print("[StoreKit] ERROR loading products: \(error)")
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

        guard SKPaymentQueue.canMakePayments() else {
            statusMessage = "In-App Purchases are disabled on this device."
            return
        }

        guard let product = await ensureProductLoaded(for: tier) else {
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }
        statusMessage = nil

        do {
            let result: Product.PurchaseResult
            if let scene = activePurchaseScene() {
                result = try await product.purchase(confirmIn: scene)
            } else {
                result = try await product.purchase()
            }

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await syncEntitlements()
                    await syncSubscriptionToBackend(using: transaction)
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
            await syncCurrentEntitlementToBackend()
            statusMessage = "Purchases restored."
        } catch {
            statusMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func syncEntitlements() async {
        if SubscriptionTier.isDeveloperOverrideActive {
            updateTier(.premium)
            return
        }

        var resolvedTier: SubscriptionTier = .free

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            if transaction.productID == SubscriptionTier.premiumProductID {
                resolvedTier = .premium
            }
        }

        updateTier(resolvedTier)
    }

    private func updateTier(_ tier: SubscriptionTier) {
        currentTier = tier
        tier.persistAsCurrent()
    }

    private func ensureProductLoaded(for tier: SubscriptionTier) async -> Product? {
        if let product = product(for: tier) {
            return product
        }

        statusMessage = "Loading subscription details..."
        await refreshProducts()

        if let product = product(for: tier) {
            return product
        }

        if let productID = tier.storeKitProductID, missingProductIDs.contains(productID) {
            statusMessage = "The App Store product isn’t available right now. Check the subscription configuration and try again."
        } else {
            statusMessage = "Couldn’t load the subscription from the App Store. Please try again."
        }
        return nil
    }

    private func activePurchaseScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: { $0.activationState == .foregroundActive }) ??
            scenes.first(where: { $0.activationState == .foregroundInactive }) ??
            scenes.first
    }

    private func syncCurrentEntitlementToBackend() async {
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  transaction.productID == SubscriptionTier.premiumProductID else {
                continue
            }

            await syncSubscriptionToBackend(using: transaction)
            return
        }
    }

    private func syncSubscriptionToBackend(using transaction: Transaction) async {
        let environment = transaction.environment.rawValue.lowercased()
        guard environment != "xcode" else {
            return
        }

        guard let token = resolvedAuthToken() else {
            return
        }

        do {
            await apiClient.setToken(token)
            let body = try JSONEncoder().encode(
                SubscriptionVerificationRequest(
                    original_transaction_id: String(transaction.originalID),
                    product_id: transaction.productID,
                    environment: environment
                )
            )
            let response: SubscriptionVerificationResponse = try await apiClient.request(
                "subscriptions/verify",
                method: "POST",
                body: body
            )

            if let tier = normalizedTier(from: response.subscription_tier) {
                updateTier(tier)
            }
        } catch {
            print("[StoreKit] Failed to sync subscription to backend: \(error)")
        }
    }

    private func resolvedAuthToken() -> String? {
        if let uid = Auth.auth().currentUser?.uid.trimmingCharacters(in: .whitespacesAndNewlines),
           !uid.isEmpty {
            return uid
        }

        guard UserDefaults.standard.bool(forKey: "session_logged_in") else {
            return nil
        }

        let username = (UserDefaults.standard.string(forKey: "profile_username") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !username.isEmpty else {
            return nil
        }

        return "username:\(username)"
    }

    private func normalizedTier(from rawValue: String?) -> SubscriptionTier? {
        switch rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "premium", "pro", "max":
            return .premium
        case "free":
            return .free
        default:
            return nil
        }
    }
}

private struct SubscriptionVerificationRequest: Encodable {
    let original_transaction_id: String
    let product_id: String
    let environment: String
}

private struct SubscriptionVerificationResponse: Decodable {
    let subscription_tier: String?
}
