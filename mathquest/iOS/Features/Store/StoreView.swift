import StoreKit
import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct StoreView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionTier = .pro

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header
                    headerSection

                    // Plan cards
                    VStack(spacing: 12) {
                        PlanCard(
                            tier: .free,
                            isSelected: selectedTier == .free,
                            isCurrent: subscriptionManager.currentTier == .free,
                            price: nil
                        ) { selectedTier = .free }

                        PlanCard(
                            tier: .pro,
                            isSelected: selectedTier == .pro,
                            isCurrent: subscriptionManager.currentTier == .pro,
                            price: subscriptionManager.product(for: .pro)?.displayPrice
                        ) { selectedTier = .pro }

                        PlanCard(
                            tier: .max,
                            isSelected: selectedTier == .max,
                            isCurrent: subscriptionManager.currentTier == .max,
                            price: subscriptionManager.product(for: .max)?.displayPrice
                        ) { selectedTier = .max }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // Feature comparison
                    featureComparison
                        .padding(.top, 24)

                    // Subscribe button
                    subscribeButton
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    // Restore + status
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

    // MARK: - Header

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

            Text("Unlock Your Full Potential")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            Text("Choose the plan that fits your learning goals")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        VStack(spacing: 0) {
            Text("What's included")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                FeatureRow(
                    feature: "Camera Scans",
                    free: "5/day",
                    pro: "10/day",
                    max: "Unlimited"
                )

                Divider().padding(.horizontal, 16)

                FeatureRow(
                    feature: "Lesson Rewards",
                    free: "25%",
                    pro: "60%",
                    max: "100%"
                )

                Divider().padding(.horizontal, 16)

                FeatureRow(
                    feature: "Lesson Refunds",
                    free: nil,
                    pro: nil,
                    max: "Full"
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Subscribe Button

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
                    Text("Current Plan")
                } else if selectedTier == .free {
                    Text("Switch to Free")
                } else {
                    Text("Subscribe to \(selectedTier.displayName)")
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

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
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

            Text("Subscriptions renew monthly. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Plan Card

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
        case .pro: return "bolt.fill"
        case .max: return "crown.fill"
        }
    }

    private var tierColor: Color {
        switch tier {
        case .free: return .green
        case .pro: return appPurple
        case .max: return .orange
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tierColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: tierIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(tierColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(tier.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        if isCurrent {
                            Text("CURRENT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        if tier == .max {
                            Text("BEST")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(tier.featureSummary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    if let price {
                        Text(price)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("/month")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Free")
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

// MARK: - Feature Row

private struct FeatureRow: View {
    let feature: String
    let free: String?
    let pro: String?
    let max: String?

    var body: some View {
        HStack {
            Text(feature)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            tierValue(free, color: .primary)
                .frame(width: 60)
            tierValue(pro, color: appPurple)
                .frame(width: 60)
            tierValue(max, color: .orange)
                .frame(width: 70)
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
