import StoreKit
import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        NavigationStack {
            List {
                Section("Current Plan") {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(subscriptionManager.currentTier.displayName)
                                .font(.headline)
                            Text(subscriptionManager.currentTier.featureSummary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Subscriptions") {
                    ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                        planRow(for: tier)
                    }
                }

                Section {
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                    .disabled(subscriptionManager.isPurchasing)

                    if let statusMessage = subscriptionManager.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !subscriptionManager.missingProductIDs.isEmpty {
                        Text("Missing IDs: \(subscriptionManager.missingProductIDs.joined(separator: ", "))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Use StoreKit product IDs: \(SubscriptionTier.proProductID) and \(SubscriptionTier.maxProductID).")
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await subscriptionManager.refreshProducts()
                await subscriptionManager.syncEntitlements()
            }
        }
    }

    @ViewBuilder
    private func planRow(for tier: SubscriptionTier) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.displayName)
                        .font(.headline)

                    Text(cameraLine(for: tier))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(rewardLine(for: tier))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if tier == .max {
                        Text("Lessons are almost unlimited with full lesson refunds.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if tier == subscriptionManager.currentTier {
                    Text("Current")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.14))
                        .clipShape(Capsule())
                }
            }

            HStack {
                if let paidProduct = subscriptionManager.product(for: tier) {
                    Text(paidProduct.displayPrice)
                        .font(.headline)
                } else if tier == .free {
                    Text("Included")
                        .font(.headline)
                } else {
                    Text("Unavailable")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(buttonTitle(for: tier)) {
                    Task {
                        await subscriptionManager.purchase(tier)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isButtonDisabled(for: tier))
            }
        }
        .padding(.vertical, 6)
    }

    private func cameraLine(for tier: SubscriptionTier) -> String {
        if let limit = tier.cameraDailyLimit {
            return "\(limit) images per day"
        }
        return "Unlimited daily camera usage"
    }

    private func rewardLine(for tier: SubscriptionTier) -> String {
        let sampleCost = 20
        let sampleReward = tier.rewardForLesson(cost: sampleCost)
        return "Lesson reward up to \(sampleReward)/\(sampleCost) coins"
    }

    private func buttonTitle(for tier: SubscriptionTier) -> String {
        if tier == subscriptionManager.currentTier {
            return "Active"
        }

        if tier == .free {
            return "Use Free"
        }

        return "Subscribe"
    }

    private func isButtonDisabled(for tier: SubscriptionTier) -> Bool {
        if tier == subscriptionManager.currentTier {
            return true
        }

        if subscriptionManager.isPurchasing {
            return true
        }

        if tier == .free {
            return false
        }

        return subscriptionManager.product(for: tier) == nil
    }
}

#Preview {
    StoreView()
        .environmentObject(SubscriptionManager())
}
