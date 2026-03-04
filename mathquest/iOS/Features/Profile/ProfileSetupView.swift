import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileSetupViewModel()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.3, blue: 0.9),
                                            Color(red: 0.6, green: 0.4, blue: 0.95)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        }

                        Text("Set up your profile")
                            .font(.system(size: 28, weight: .bold))

                        Text("Tell us a bit about yourself so we can personalize your learning experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 40)

                    // Form fields
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            TextField("Enter your name", text: $viewModel.name)
                                .textInputAutocapitalization(.words)
                                .font(.system(size: 17))
                                .padding()
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        }

                        // Math level picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Math Level")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            VStack(spacing: 10) {
                                ForEach(viewModel.levels, id: \.self) { level in
                                    LevelOptionButton(
                                        level: level,
                                        description: levelDescription(for: level),
                                        icon: levelIcon(for: level),
                                        isSelected: viewModel.level == level
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.level = level
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Continue button
                    Button {
                        Task { await viewModel.submit(onComplete: onComplete) }
                    } label: {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: viewModel.canSubmit
                                    ? [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.95)]
                                    : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: viewModel.canSubmit ? Color(red: 0.4, green: 0.3, blue: 0.9).opacity(0.3) : .clear, radius: 12, y: 6)
                    }
                    .disabled(viewModel.isSubmitting || !viewModel.canSubmit)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func levelDescription(for level: String) -> String {
        switch level {
        case "Beginner":
            return "Basic arithmetic, fractions, decimals"
        case "Intermediate":
            return "Algebra, geometry, basic equations"
        case "Advanced":
            return "Calculus, trigonometry, advanced algebra"
        default:
            return ""
        }
    }

    private func levelIcon(for level: String) -> String {
        switch level {
        case "Beginner":
            return "leaf.fill"
        case "Intermediate":
            return "flame.fill"
        case "Advanced":
            return "bolt.fill"
        default:
            return "star.fill"
        }
    }
}

private struct LevelOptionButton: View {
    let level: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.95)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(level)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        isSelected
                            ? Color(red: 0.4, green: 0.3, blue: 0.9)
                            : Color.gray.opacity(0.3)
                    )
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color(red: 0.4, green: 0.3, blue: 0.9) : .clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileSetupView(onComplete: {})
}
