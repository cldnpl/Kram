import SwiftUI
import UIKit

struct CarouselOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentIndex = 0

    private let slides: [CarouselSlide] = [
        .init(
            title: "Scan math in seconds",
            subtitle: "Capture equations with your camera and get guided solutions instantly.",
            imageName: "onboarding_1"
        ),
        .init(
            title: "Learn step by step",
            subtitle: "Follow structured lessons from beginner concepts to advanced topics.",
            imageName: "onboarding_2"
        ),
        .init(
            title: "Build streaks and progress",
            subtitle: "Track consistency, complete lessons, and improve daily.",
            imageName: "onboarding_3"
        ),
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button("Skip") {
                    onComplete()
                }
                .font(.headline)
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
                        .fill(index == currentIndex ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: index == currentIndex ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }

            Button(currentIndex == slides.count - 1 ? "Continue" : "Next") {
                if currentIndex == slides.count - 1 {
                    onComplete()
                } else {
                    withAnimation {
                        currentIndex += 1
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
}

private struct CarouselSlideView: View {
    let slide: CarouselSlide

    var body: some View {
        VStack(spacing: 20) {
            Group {
                if UIImage(named: slide.imageName) != nil {
                    Image(slide.imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(.secondarySystemBackground)
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 20)

            Text(slide.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text(slide.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CarouselSlide {
    let title: String
    let subtitle: String
    let imageName: String
}

#Preview {
    CarouselOnboardingView(onComplete: {})
}
