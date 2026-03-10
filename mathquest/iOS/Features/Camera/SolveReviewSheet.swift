import FirebaseAuth
import SwiftUI

struct SolveReviewSheet: View {
    let solveId: Int
    @Binding var isPresented: Bool

    private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

    enum ReviewStep { case stars, category, detail, thankYou }

    @State private var step: ReviewStep = .stars
    @State private var rating: Int = 0
    @State private var selectedCategory: String?
    @State private var selectedDetail: String?

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            switch step {
            case .stars:
                starsView
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .category:
                categoryView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .detail:
                detailView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .thankYou:
                thankYouView
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
    }

    // MARK: - Step 1: Stars

    private var starsView: some View {
        VStack(spacing: 20) {
            // App icon
            Image(systemName: "function")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [appPurple, appPurple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(appPurple.opacity(0.12))
                )
                .padding(.top, 24)

            Text(L10n.reviewTitle)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = star
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                step = .category
                            }
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundColor(star <= rating ? .yellow : Color(.systemGray3))
                            .scaleEffect(star <= rating ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: rating)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Step 2: Category

    private var categoryTitle: String {
        switch rating {
        case 5: return L10n.reviewWhatLiked
        case 1, 2: return L10n.reviewWhatWrong
        default: return L10n.reviewWhatBetter
        }
    }

    private var categories: [String] {
        switch rating {
        case 5:
            return [
                L10n.reviewCatCapturing,
                L10n.reviewCatSolutionAccuracy,
                L10n.reviewCatStepByStep,
                L10n.reviewCatSpeed
            ]
        case 1, 2:
            return [
                L10n.reviewCatCameraFailed,
                L10n.reviewCatWrongSolution,
                L10n.reviewCatUnclearSteps,
                L10n.reviewCatSlowBuggy
            ]
        default:
            return [
                L10n.reviewCatCameraAccuracy,
                L10n.reviewCatSolutionQuality,
                L10n.reviewCatExplanationClarity,
                L10n.reviewCatSpeedMid
            ]
        }
    }

    private var categoryView: some View {
        VStack(spacing: 16) {
            Text(categoryTitle)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            VStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        withAnimation {
                            step = .detail
                        }
                    } label: {
                        HStack {
                            Text(category)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Step 3: Detail

    private var details: [String] {
        guard let cat = selectedCategory else { return [] }

        // Positive (5 stars)
        if rating == 5 {
            if cat == L10n.reviewCatCapturing {
                return [L10n.reviewDetailRecognizedPerfect, L10n.reviewDetailFastAccurate]
            } else if cat == L10n.reviewCatSolutionAccuracy {
                return [L10n.reviewDetailCompletelyCorrect, L10n.reviewDetailGreatFormat]
            } else if cat == L10n.reviewCatStepByStep {
                return [L10n.reviewDetailEasyFollow, L10n.reviewDetailLearnedNew]
            } else {
                return [L10n.reviewDetailLightningFast, L10n.reviewDetailNoWaiting]
            }
        }

        // Negative (1-2 stars)
        if rating <= 2 {
            if cat == L10n.reviewCatCameraFailed {
                return [L10n.reviewDetailNoRecognize, L10n.reviewDetailWrongArea, L10n.reviewDetailTookLong]
            } else if cat == L10n.reviewCatWrongSolution {
                return [L10n.reviewDetailAnswerWrong, L10n.reviewDetailMissingSteps, L10n.reviewDetailIncorrectMethod]
            } else if cat == L10n.reviewCatUnclearSteps {
                return [L10n.reviewDetailStepsConfusing, L10n.reviewDetailSkippedSteps]
            } else {
                return [L10n.reviewDetailTooSlow, L10n.reviewDetailGotStuck]
            }
        }

        // Mid (3-4 stars) — reuse negative detail keys for the matching mid categories
        if cat == L10n.reviewCatCameraAccuracy {
            return [L10n.reviewDetailNoRecognize, L10n.reviewDetailWrongArea]
        } else if cat == L10n.reviewCatSolutionQuality {
            return [L10n.reviewDetailAnswerWrong, L10n.reviewDetailMissingSteps]
        } else if cat == L10n.reviewCatExplanationClarity {
            return [L10n.reviewDetailStepsConfusing, L10n.reviewDetailSkippedSteps]
        } else {
            return [L10n.reviewDetailTooSlow, L10n.reviewDetailGotStuck]
        }
    }

    private var detailView: some View {
        VStack(spacing: 16) {
            Text(selectedCategory ?? "")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            VStack(spacing: 10) {
                ForEach(details, id: \.self) { detail in
                    Button {
                        selectedDetail = detail
                        submitFeedback()
                        withAnimation {
                            step = .thankYou
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isPresented = false
                        }
                    } label: {
                        HStack {
                            Text(detail)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Thank You

    private var thankYouView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 32)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [appPurple, appPurple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(L10n.reviewThanks)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Submission

    private func submitFeedback() {
        Self.markReviewed(solveId: solveId)

        let payload: [String: Any] = [
            "solve_id": solveId,
            "rating": rating,
            "category": selectedCategory ?? "",
            "detail": selectedDetail ?? ""
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        Task {
            let client = APIClient()
            // Resolve token the same way CameraViewModel does
            let token = Self.resolvedToken()
            await client.setToken(token)
            do {
                let _: EmptyResponse = try await client.request("camera/feedback", method: "POST", body: body)
            } catch {
                #if DEBUG
                print("[SolveReview] Failed to submit feedback: \(error)")
                #endif
            }
        }
    }

    // MARK: - Gating helpers

    private static let reviewedKey = "solve_review_ids"

    static func shouldShowReview(for solveId: Int) -> Bool {
        let reviewed = UserDefaults.standard.array(forKey: reviewedKey) as? [Int] ?? []
        if reviewed.contains(solveId) { return false }
        // Show ~50% of the time
        return Bool.random()
    }

    private static func markReviewed(solveId: Int) {
        var reviewed = UserDefaults.standard.array(forKey: reviewedKey) as? [Int] ?? []
        reviewed.append(solveId)
        // Keep only last 200 to avoid unbounded growth
        if reviewed.count > 200 { reviewed = Array(reviewed.suffix(200)) }
        UserDefaults.standard.set(reviewed, forKey: reviewedKey)
    }

    private static func resolvedToken() -> String {
        if let uid = _firebaseUID() { return uid }
        if UserDefaults.standard.bool(forKey: "session_logged_in"),
           let username = UserDefaults.standard.string(forKey: "profile_username"),
           !username.isEmpty {
            return "username:\(username)"
        }
        let key = "guest_device_id"
        let id = UserDefaults.standard.string(forKey: key) ?? UUID().uuidString
        if UserDefaults.standard.string(forKey: key) == nil {
            UserDefaults.standard.set(id, forKey: key)
        }
        return "guest:\(id)"
    }

    private static func _firebaseUID() -> String? {
        Auth.auth().currentUser?.uid
    }
}

private struct EmptyResponse: Decodable {}
