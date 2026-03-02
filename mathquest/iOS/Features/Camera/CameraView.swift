import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        VStack {
            Text("\(viewModel.usesRemaining) uses left today")
                .font(.subheadline)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(Image(systemName: "camera.fill").font(.largeTitle))
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Button("Capture") {
                Task { await viewModel.capture() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Solve Math")
    }
}

#Preview {
    NavigationStack { CameraView() }
}
