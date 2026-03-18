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
        VStack(spacing: 0) {
            Text(L10n.storeWhatsIncluded)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                FeatureRow(
                    feature: L10n.storeFeatureCameraScans,
                    free: L10n.storeValue3Day,
                    premium: L10n.storeValueUnlimited
                )

                Divider().padding(.horizontal, 16)

                FeatureRow(
                    feature: L10n.storeFeatureLessonRewards,
                    free: "25%",
                    premium: "100%"
                )

                Divider().padding(.horizontal, 16)

                FeatureRow(
                    feature: L10n.storeFeatureLessonRefunds,
                    free: nil,
                    premium: L10n.storeValueFull
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private var subscribeButton: some View {
        Button {
            Task {
                await subscriptionManager.purchase(selectedTier)
            }
        } label: {
            Group {
                if subscriptionManager.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else if selectedTier == subscriptionManager.currentTier {
                    Text(L10n.storeCurrentPlan)
                } else if selectedTier == .free {
                    Text(L10n.storeSwitchFree)
                } else {
                    Text(L10n.storeSubscribeTo(selectedTier.displayName))
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
            (selectedTier != .free && subscriptionManager.product(for: selectedTier) == nil)
        )
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
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(L10n.storePerMonth)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
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

private struct FeatureRow: View {
    let feature: String
    let free: String?
    let premium: String?

    var body: some View {
        HStack {
            Text(feature)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            tierValue(free, color: .primary)
                .frame(width: 60)
            tierValue(premium, color: appPurple)
                .frame(width: 84)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func tierValue(_ value: String?, color: Color) -> some View {
        if let value {
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
        } else {
            Image(systemName: "minus")
                .font(.system(size: 12))
                .foregroundStyle(.quaternary)
        }
    }
}

#Preview {
    StoreView()
        .environmentObject(SubscriptionManager())
}
