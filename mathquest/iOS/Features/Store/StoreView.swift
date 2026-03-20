import SafariServices
import StoreKit
import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)
private let privacyPolicyURL = URL(string: "https://docs.google.com/document/d/e/2PACX-1vSyXqkX7LWZaW8dzafSVfMRwUeZ4s1KyrLZscOtYSg_jHWjKuw8fm4BF8CbQbMJTMRld7GIFVkmzEnz/pub")!
private let standardEULAURL = URL(string: "https://docs.google.com/document/d/e/2PACX-1vRsFzCfMDLQS98kBAHaEtfS3ml_WfkaEuCtQOeNHcy5oYm99TDoA4tdoXkUxF2Fb_8Sdiigfi4xf-b7/pub")!

struct StoreView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTier: SubscriptionTier = .premium
    @State private var presentedLegalURL: LegalURLTarget?

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
                        ) {
                            selectedTier = .free
                        }

                        PlanCard(
                            tier: .premium,
                            isSelected: selectedTier == .premium,
                            isCurrent: subscriptionManager.currentTier == .premium,
                            price: subscriptionManager.product(for: .premium)?.displayPrice
                        ) {
                            selectedTier = .premium
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    featureComparison
                        .padding(.top, 24)

                    subscribeButton
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    legalLinksRow
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    legalSection
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    footer
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                .frame(maxWidth: .infinity)
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
            .sheet(item: $presentedLegalURL) { target in
                SafariSheet(url: target.url)
                    .ignoresSafeArea()
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
                FeatureHeaderRow()

                Divider().padding(.horizontal, 16)

                FeatureRow(
                    feature: L10n.storeFeatureCameraScans,
                    freeValue: L10n.storeValue3Day,
                    premiumValue: L10n.storeValueUnlimited
                )

                Divider().padding(.horizontal, 16)

                FeatureRow(
                    feature: L10n.storeFeatureLessonRewards,
                    freeValue: "100%",
                    premiumValue: "100%"
                )

                Divider().padding(.horizontal, 16)

                FeatureRow(
                    feature: L10n.storeFeatureLessonRefunds,
                    freeValue: L10n.storeValueFull,
                    premiumValue: L10n.storeValueFull
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
                if selectedTier == .premium && subscriptionManager.product(for: .premium) == nil {
                    await subscriptionManager.refreshProducts()
                }
                await subscriptionManager.purchase(selectedTier)
            }
        } label: {
            Group {
                if subscriptionManager.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else if selectedTier == .premium &&
                            subscriptionManager.isLoadingProducts &&
                            subscriptionManager.product(for: .premium) == nil {
                    Text("Loading subscription...")
                } else if selectedTier == subscriptionManager.currentTier {
                    Text(L10n.storeCurrentPlan)
                } else if selectedTier == .free {
                    Text(L10n.storeSwitchFree)
                } else if subscriptionManager.product(for: .premium) == nil {
                    Text("Try subscription again")
                } else {
                    Text(L10n.storeSubscribeTo(L10n.storePremium))
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                selectedTier == subscriptionManager.currentTier ? Color.gray : appPurple
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(
            selectedTier == subscriptionManager.currentTier ||
            subscriptionManager.isPurchasing
        )
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subscription details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 8) {
                Text(legalSummaryTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Length: 1 month")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text(legalSummaryPrice)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .padding(.horizontal, 18)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
        }
    }

    private var legalLinksRow: some View {
        HStack(spacing: 8) {
            Button("Privacy Policy") {
                presentedLegalURL = LegalURLTarget(url: privacyPolicyURL)
            }
            .buttonStyle(.plain)

            Text("|")
                .foregroundStyle(.tertiary)

            Button("Terms of Use") {
                presentedLegalURL = LegalURLTarget(url: standardEULAURL)
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(appPurple)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)

    }

    private var legalSummaryTitle: String {
        switch selectedTier {
        case .free:
            return "\(L10n.storePremium) subscription"
        case .premium:
            return "\(L10n.storePremium) subscription"
        }
    }

    private var legalSummaryPrice: String {
        if let price = subscriptionManager.product(for: .premium)?.displayPrice {
            return "Price: \(price) per month"
        }
        return "Price: Loading..."
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
        guard isSelected else { return Color(.separator) }
        switch tier {
        case .free:
            return .green
        case .premium:
            return appPurple
        }
    }

    private var tierIcon: String {
        switch tier {
        case .free:
            return "leaf.fill"
        case .premium:
            return "crown.fill"
        }
    }

    private var tierColor: Color {
        switch tier {
        case .free:
            return .green
        case .premium:
            return appPurple
        }
    }

    private var summary: String {
        switch tier {
        case .free:
            return L10n.storeSummaryFree
        case .premium:
            return L10n.storeSummaryPremium
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

                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if tier == .premium, let price {
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

private struct FeatureHeaderRow: View {
    var body: some View {
        HStack {
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(L10n.storeFree)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 84)

            Text(L10n.storePremium)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(appPurple)
                .frame(width: 100)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

private struct FeatureRow: View {
    let feature: String
    let freeValue: String?
    let premiumValue: String?

    var body: some View {
        HStack {
            Text(feature)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            tierValue(freeValue, color: .primary)
                .frame(width: 84)

            tierValue(premiumValue, color: appPurple)
                .frame(width: 100)
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
                .multilineTextAlignment(.center)
        } else {
            Image(systemName: "minus")
                .font(.system(size: 12))
                .foregroundStyle(.quaternary)
        }
    }
}

private struct LegalURLTarget: Identifiable {
    let id = UUID()
    let url: URL
}

private struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(appPurple)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    StoreView()
        .environmentObject(SubscriptionManager())
}
