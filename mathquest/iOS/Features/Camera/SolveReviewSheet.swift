import FirebaseAuth
import SwiftUI

struct SolveReviewSheet: View {
    let solveId: Int
    @Binding var isPresented: Bool

    private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)
    @State private var rating: Int = 0
    @State private var selectedCategory: String?
    @State private var selectedDetail: String?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: 18) {
                Text(L10n.reviewTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                starsRow

                if rating > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel(categoryTitle)

                        chipGrid(items: categories, selectedItem: selectedCategory) { category in
                            selectedCategory = category
                            selectedDetail = nil
                        }
                    }

                    if let selectedCategory {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel(selectedCategory)

                            chipGrid(items: details, selectedItem: selectedDetail) { detail in
                                guard !isSubmitting else { return }
                                selectedDetail = detail
                                submitFeedback()
                            }
                        }
                    }

                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: rating)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedCategory)
    }

    private var starsRow: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    guard !isSubmitting else { return }
                    rating = star
                    selectedCategory = nil
                    selectedDetail = nil
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 30))
                        .foregroundStyle(star <= rating ? Color.yellow : Color(.systemGray3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryTitle: String {
        switch rating {
        case 5: return L10n.reviewWhatLiked
        case 1, 2: return L10n.reviewWhatWrong
        default: return L10n.reviewWhatBetter
        }
    }

    private var categories: [String] {
        switch rating {
        case 0:
            return []
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipGrid(
        items: [String],
        selectedItem: String?,
        action: @escaping (String) -> Void
    ) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            ForEach(items, id: \.self) { item in
                let isSelected = selectedItem == item

                Button {
                    action(item)
                } label: {
                    Text(item)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? appPurple : Color(.secondarySystemGroupedBackground))
                        )
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
            }
        }
    }

    // MARK: - Submission

    private func submitFeedback() {
        guard !isSubmitting else { return }
        isSubmitting = true
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

            await MainActor.run {
                isPresented = false
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
