import StoreKit
import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct StoreView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionTier = .premium

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    VStack(spacing: 12) {
                        PlanCard(
                            tier: .free,
                            isSelected: selectedTier == .free,
                            isCurrent: subscriptionManager.currentTier == .free,
                            price: nil
                        ) { selectedTier = .free }

                        PlanCard(
                            tier: .premium,
                            isSelected: selectedTier == .premium,
                            isCurrent: subscriptionManager.currentTier == .premium,
                            price: subscriptionManager.product(for: .premium)?.displayPrice ?? "$6.99"
                        ) { selectedTier = .premium }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    featureComparison
                        .padding(.top, 24)

                    subscribeButton
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    legalLinks
                        .padding(.top, 12)

                    subscriptionDetails
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    footer
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .task {
                await subscriptionManager.refreshProducts()
                await subscriptionManager.syncEntitlements()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [appPurple, Color(red: 0.6, green: 0.4, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text(L10n.storeUnlockTitle)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            Text(L10n.storeUnlockSubtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.storeWhatsIncluded)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(appPurple.opacity(0.14))
                            .frame(width: 36, height: 36)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(appPurple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.storePremium)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(L10n.storeSummaryPremium)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text(L10n.storeValueUnlimited)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(appPurple)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(appPurple.opacity(0.12))
                        .clipShape(Capsule())
                }

                Divider()

                IncludedFeatureRow(
                    icon: "camera.viewfinder",
                    label: L10n.storeFeatureCameraScans,
                    value: L10n.storeValueUnlimited,
                    tint: appPurple
                )

                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.green)
                    Text("\(L10n.storeFree): \(L10n.storeValue3Day)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(appPurple.opacity(0.18), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    private var productUnavailable: Bool {
        selectedTier != .free && subscriptionManager.product(for: selectedTier) == nil
    }

    private var subscribeButton: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    if productUnavailable {
                        await subscriptionManager.refreshProducts()
                        // After refresh, attempt purchase if product is now available
                        if subscriptionManager.product(for: selectedTier) != nil {
                            await subscriptionManager.purchase(selectedTier)
                        }
                    } else {
                        await subscriptionManager.purchase(selectedTier)
                    }
                }
            } label: {
                Group {
                    if subscriptionManager.isPurchasing || subscriptionManager.isLoadingProducts {
                        ProgressView()
                            .tint(.white)
                    } else if productUnavailable {
                        Text("Retry subscription")
                    } else if selectedTier == subscriptionManager.currentTier {
                        Text(L10n.storeCurrentPlan)
                    } else if selectedTier == .free {
                        Text(L10n.storeSwitchFree)
                    } else {
                        Text("Try Free for 3 Days — then $2.99/mo")
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    selectedTier == subscriptionManager.currentTier
                        ? Color.gray
                        : appPurple
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(
                selectedTier == subscriptionManager.currentTier ||
                subscriptionManager.isPurchasing ||
                subscriptionManager.isLoadingProducts
            )

            if productUnavailable && !subscriptionManager.isLoadingProducts {
                Text("The subscription couldn’t be loaded from the App Store. Tap above to retry.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .task {
                        // Auto-retry loading products
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await subscriptionManager.refreshProducts()
                    }
            }
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 4) {
            Link("Privacy Policy", destination: URL(string: "https://id-preview--bb09b17a-5c81-49d8-aedc-ed2da9c3e42c.lovable.app/privacy")!)
                .font(.system(size: 13))
                .foregroundStyle(appPurple)
            Text("|")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            Link("Terms of Use", destination: URL(string: "https://id-preview--bb09b17a-5c81-49d8-aedc-ed2da9c3e42c.lovable.app/terms")!)
                .font(.system(size: 13))
                .foregroundStyle(appPurple)
        }
    }

    private var subscriptionDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription details")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Premium subscription")
                    .font(.system(size: 15, weight: .semibold))

                Text("$2.99 per month (after free trial)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Text("3-day free trial, then $2.99/month. 1-month auto-renewable subscription. Payment is charged to your Apple ID account at confirmation of purchase. The subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account is charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button(L10n.storeRestorePurchases) {
                Task { await subscriptionManager.restorePurchases() }
            }
            .font(.system(size: 14))
            .foregroundStyle(appPurple)
            .disabled(subscriptionManager.isPurchasing)

            if let msg = subscriptionManager.statusMessage {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Text(L10n.storeRenewNote)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

private struct PlanCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let isCurrent: Bool
    let price: String?
    let onTap: () -> Void

    private var borderColor: Color {
        isSelected ? appPurple : Color(.separator)
    }

    private var tierIcon: String {
        switch tier {
        case .free: return "leaf.fill"
        case .premium: return "crown.fill"
        }
    }

    private var tierColor: Color {
        switch tier {
        case .free: return .green
        case .premium: return appPurple
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tierColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: tierIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(tierColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(tier.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        if isCurrent {
                            Text(L10n.storeBadgeCurrent)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(tier.featureSummary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let price {
                        Text(price)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .strikethrough(true, color: .secondary)
                        Text("$2.99")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.primary)
                        Text(L10n.storePerMonth)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("3-day free trial")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    } else {
                        Text(L10n.storeFree)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct IncludedFeatureRow: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tint.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    StoreView()
        .environmentObject(SubscriptionManager())
}
