import SwiftUI
import UIKit

struct CarouselOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentIndex = 0

    private let slides: [CarouselSlide] = [
        .init(
            title: "Scan math in seconds",
            subtitle: "Capture equations with your camera and get guided solutions instantly.",
            icon: "camera.viewfinder",
            gradientColors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.95)]
        ),
        .init(
            title: "Learn step by step",
            subtitle: "Follow structured lessons from beginner concepts to advanced topics.",
            icon: "book.pages",
            gradientColors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.4, green: 0.8, blue: 0.95)]
        ),
        .init(
            title: "Build streaks and progress",
            subtitle: "Track consistency, complete lessons, and improve daily.",
            icon: "flame.fill",
            gradientColors: [Color(red: 0.95, green: 0.5, blue: 0.2), Color(red: 0.95, green: 0.7, blue: 0.3)]
        ),
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button("Skip") {
                    onComplete()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            TabView(selection: $currentIndex) {
                ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                    CarouselSlideView(slide: slide)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? Color(red: 0.4, green: 0.3, blue: 0.9) : Color.gray.opacity(0.3))
                        .frame(width: index == currentIndex ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }

            Button {
                if currentIndex == slides.count - 1 {
                    onComplete()
                } else {
                    withAnimation {
                        currentIndex += 1
                    }
                }
            } label: {
                Text(currentIndex == slides.count - 1 ? "Get Started" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

private struct CarouselSlideView: View {
    let slide: CarouselSlide

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.gradientColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.gradientColors.map { $0.opacity(0.25) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)

                // Main icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: slide.gradientColors[0].opacity(0.4), radius: 20, y: 10)

                Image(systemName: slide.icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Text content
            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(slide.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CarouselSlide {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
}

#Preview {
    CarouselOnboardingView(onComplete: {})
}
