import SwiftUI

struct ScanningLineView: View {
    @State private var offset: CGFloat = -150

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0),
                            Color.green.opacity(0.8),
                            Color.green.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .offset(y: offset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        offset = geometry.size.height - 3
                    }
                }
        }
    }
}

struct ProcessingOverlay: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))
            }

            Text("Solving...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ScanningLineView()
    }
    .frame(height: 300)
}

#Preview("Processing") {
    ZStack {
        Color.black.opacity(0.8)
        ProcessingOverlay()
    }
}
